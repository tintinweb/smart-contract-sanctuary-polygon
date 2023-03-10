// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../Utils/CustomAdmin.sol";

interface ISquidBetRandomGen {
    function getRandomNumber() external view returns (uint256);
}

interface ISquidBetNFTClaimer {
    function setSBCNFTClaimable(
        address,
        uint8,
        uint256,
        uint256,
        uint16,
        uint16,
        bool,
        bool
    ) external;
}

interface ISquidBetPrizePool {
    function winnerClaimPrizePool(address, uint256) external;
}

contract SquidBets is CustomAdmin, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;

    ISquidBetNFTClaimer private claimerContract;

    enum EventState {
        Inactive,
        RegistStart,
        OnRound,
        OnVote,
        FinishVote,
        Finished
    }

    enum RoundState {
        Active,
        ReActive,
        Canceled,
        Finished
    }

    enum RoundResult {
        Biden,
        Trump,
        Indeterminate
    }

    enum VotingResult {
        Split,
        Solo,
        Indeterminate
    }

    struct EventInfo {
        uint256 EventID;
        string Description;
        uint256 FirstRound;
        uint256 CurrentRound;
        uint256 TotalAmount;
        uint256 MaxPlayers;
        uint16 TotalPlayers;
        uint256 RegisterFee;
        uint256 RoundFee;
        uint8 OrgFeePercent;
        uint8 TotalRound;
        EventState State;
        VotingResult VResult; //true: divide by winners false: random number mode
    }

    struct RoundInfo {
        uint256 RoundID;
        uint256 EventID;
        uint256 BettingAmount;
        string Description;
        uint256 Date;
        RoundResult Result;
        uint8 Level; //1 -> round1 2->round2
        RoundState State;
    }

    uint256 public eventID;
    uint256 public roundID;

    address public immutable prizePool; /// address of the squidBetsPrizePool contract
    address public immutable UltibetsBetTreasury; /// address of the UltibetsBetTreasury contract
    address public UltibetsBuyBack; /// address of the UltibetsBuyback contract

    address private betRandomGenerator;

    mapping(uint256 => EventInfo) public eventData;
    mapping(uint256 => RoundInfo) public roundData;
    mapping(address => mapping(uint256 => RoundResult)) betByBettor;
    mapping(address => mapping(uint256 => bool)) isBetOnRound;
    mapping(uint256 => uint256) deadlineOfCancelRound;

    mapping(address => mapping(uint256 => uint16)) registerIDOfBettor;
    mapping(uint256 => uint256) organisatorFeeBalance;
    mapping(uint256 => EnumerableSet.AddressSet) playersByRound;
    mapping(uint256 => EnumerableSet.AddressSet) winnersOfFinalRound; // eventID => address set
    mapping(uint256 => address) selectedWinnerOfVote; //eventID => address
    mapping(address => mapping(uint256 => bool)) playersVoteState;
    mapping(address => mapping(uint256 => bool)) playersClaimReward;
    mapping(uint256 => int256) eventVote;

    event BetPlaced(
        address bettor,
        uint256 roundID,
        uint256 amount,
        uint256 time
    );

    event Results(uint256 roundID, RoundResult result);

    event EventCreated(uint256 _eventID);
    event RegisterStarted(uint256 _eventID);
    event RegisterStopped(uint256 _eventID);
    event VoteStarted(uint256 _eventID);
    event VoteFinished(uint256 _eventID);
    event EventFinished(uint256 _eventID);

    event RoundAdded(uint256 _roundID);
    event RoundUpdated(uint256 _roundID);
    event RoundCanceled(uint256 _roundID, uint256 _deadline);
    event RoundFinished(uint256 _roundID);

    constructor(
        address _prizePool,
        address _ultibetsTreasury,
        address _ultibetsBuyBack
    ) {
        require(_prizePool != address(0), "invalid address");
        UltibetsBetTreasury = _ultibetsTreasury;
        UltibetsBuyBack = _ultibetsBuyBack;
        prizePool = _prizePool;
    }

    receive() external payable {}

    function registerOnEvent(uint256 _eventID) external payable {
        uint256 firstRound = eventData[_eventID].FirstRound;
        require(
            !playersByRound[firstRound].contains(msg.sender),
            "You are already registered for the Squid Bet Competition"
        );
        require(
            eventData[_eventID].State == EventState.RegistStart,
            "Can't regist for now!"
        );
        require(
            msg.value == eventData[_eventID].RegisterFee,
            "Not enough for register fee!"
        );
        require(
            eventData[_eventID].MaxPlayers > eventData[_eventID].TotalPlayers,
            "Max number of players has been reached"
        );

        uint256 amount = msg.value;
        uint256 orgFee = (amount * eventData[_eventID].OrgFeePercent) / 100;

        eventData[_eventID].TotalPlayers++;
        organisatorFeeBalance[_eventID] += orgFee;
        eventData[_eventID].TotalAmount += amount - orgFee;

        registerIDOfBettor[msg.sender][_eventID] = eventData[_eventID]
            .TotalPlayers;

        playersByRound[eventData[_eventID].FirstRound].add(msg.sender);
    }

    function transferOrganisatorFeetoTreasury(uint256 _eventID)
        external
        onlyAdmin
    {
        require(
            eventData[_eventID].State != EventState.RegistStart,
            "Registration is still open"
        );

        require(organisatorFeeBalance[_eventID] > 0, "No fees to withdraw");

        uint256 amount = organisatorFeeBalance[_eventID];

        organisatorFeeBalance[_eventID] = 0;
        payable(UltibetsBetTreasury).transfer(amount / 2);
        payable(UltibetsBuyBack).transfer(amount / 2);
    }

    function transferTotalEntryFeestoPrizePool(uint256 _eventID)
        external
        onlyAdmin
    {
        require(
            eventData[_eventID].State != EventState.RegistStart,
            "Registration is still open"
        );

        require(
            organisatorFeeBalance[_eventID] == 0,
            "Withdraw treasury fee first"
        );

        payable(prizePool).transfer(eventData[_eventID].TotalAmount);
    }

    function setUltibetsBuyBack(address _buyback) external onlyAdmin {
        UltibetsBuyBack = _buyback;
    }

    function createNewEvent(
        string memory _desc,
        uint256 _maxPlayers,
        uint256 _registerFee,
        uint8 _totalRound,
        uint256 _roundFee,
        uint8 _orgFeePercent
    ) external onlyAdmin {
        eventID++;
        eventData[eventID] = EventInfo(
            eventID,
            _desc,
            roundID + 1,
            roundID,
            0,
            _maxPlayers,
            0,
            _registerFee,
            _roundFee,
            _orgFeePercent,
            _totalRound,
            EventState.Inactive,
            VotingResult.Indeterminate
        );

        emit EventCreated(eventID);
    }

    /// @notice view function to check if address is a winner
    /// @return _winners as true if address is a winner

    /// @notice view function to check round total balance
    /// @return round balance balance
    function getRoundBalance(uint256 _roundID) public view returns (uint256) {
        return roundData[_roundID].BettingAmount;
    }

    function getResult(uint256 _roundID)
        public
        view
        returns (RoundResult _win)
    {
        _win = roundData[_roundID].Result;
    }

    function setClaimerContract(ISquidBetNFTClaimer _claimer) public onlyAdmin {
        claimerContract = _claimer;
    }

    function openEvent(uint256 _eventID) public onlyAdmin {
        eventData[_eventID].State = EventState.RegistStart;

        emit RegisterStarted(_eventID);
    }

    function finishEvent(uint256 _eventID) public onlyAdmin {
        eventData[_eventID].State = EventState.Finished;

        emit EventFinished(_eventID);
    }

    function finishRegist(uint256 _eventID) public onlyAdmin {
        eventData[_eventID].State = EventState.OnRound;

        emit RegisterStopped(_eventID);
    }

    function voteEvent(uint256 _eventID) public onlyAdmin {
        eventData[_eventID].State = EventState.OnVote;

        emit VoteStarted(_eventID);
    }

    function cancelRound(uint256 _roundID, uint256 _deadline) public onlyAdmin {
        roundData[_roundID].State = RoundState.Canceled;
        deadlineOfCancelRound[_roundID] = _deadline;

        emit RoundCanceled(_roundID, _deadline);
    }

    function finishRound(uint256 _roundID) public onlyAdmin {
        roundData[_roundID].State = RoundState.Finished;

        emit RoundFinished(_roundID);
    }

    function updateEventTotalRound(uint256 _eventID, uint8 _totalRound)
        public
        onlyAdmin
    {
        require(
            _totalRound >= roundData[eventData[_eventID].CurrentRound].Level,
            "Invalid number!"
        );
        eventData[_eventID].TotalRound = _totalRound;
    }

    function addRound(uint256 _eventID, string memory _desc) public onlyAdmin {
        uint256 currentRound = eventData[_eventID].CurrentRound;
        require(
            eventData[_eventID].State == EventState.OnRound,
            "Can't add round to this event for now!"
        );
        require(
            roundData[currentRound].Level + 1 <= eventData[_eventID].TotalRound,
            "Can't exceed total round number."
        );
        require(
            eventData[_eventID].FirstRound > eventData[_eventID].CurrentRound ||
                roundData[currentRound].State == RoundState.Finished,
            "Current Rounds is not finished yet."
        );
        roundID++;
        roundData[roundID] = RoundInfo(
            roundID,
            _eventID,
            0,
            _desc,
            block.timestamp,
            RoundResult.Indeterminate,
            roundData[currentRound].Level + 1,
            RoundState.Active
        );

        eventData[_eventID].CurrentRound = roundID;
    }

    function reActiveRound(uint256 _roundID, string memory _desc)
        public
        onlyAdmin
    {
        require(
            roundData[_roundID].State == RoundState.Canceled,
            "That is not canceled round!"
        );
        roundData[_roundID].BettingAmount = 0;
        roundData[_roundID].Description = _desc;
        roundData[_roundID].State = RoundState.ReActive;

        emit RoundUpdated(_roundID);
    }

    ///@notice function to place bets
    ///@param _roundID is the roundID, _result is the decision

    function placeBet(uint256 _roundID, RoundResult _result) external payable {
        require(
            roundData[_roundID].State == RoundState.Active ||
                roundData[_roundID].State == RoundState.ReActive,
            "Non available state!"
        );
        require(
            playersByRound[_roundID].contains(msg.sender),
            "You can't bet on that round!"
        );
        require(!isBetOnRound[msg.sender][_roundID], "Bet placed already");
        uint256 eventId = roundData[_roundID].EventID;
        require(
            msg.value == eventData[eventId].RoundFee,
            "Not enough to bet on the round!"
        );

        require(_result != RoundResult.Indeterminate, "Invalid Bet!");

        uint256 betAmount = msg.value;
        isBetOnRound[msg.sender][_roundID] = true;
        betByBettor[msg.sender][_roundID] = _result;
        eventData[roundData[_roundID].EventID].TotalAmount += betAmount;
        roundData[_roundID].BettingAmount += betAmount;

        if (roundData[_roundID].State == RoundState.Active) {
            setNFTClaimable(
                msg.sender,
                _roundID,
                eventId,
                false,
                roundData[_roundID].Date
            );
        }

        emit BetPlaced(msg.sender, _roundID, msg.value, block.timestamp);
    }

    function setNFTClaimable(
        address bettor,
        uint256 _roundID,
        uint256 _eventId,
        bool _isFinal,
        uint256 _date
    ) internal {
        if (_isFinal) {
            claimerContract.setSBCNFTClaimable(
                bettor,
                0,
                _eventId,
                _date,
                uint16(playersByRound[_roundID].length()),
                eventData[_eventId].TotalPlayers,
                true,
                false
            );
        } else {
            claimerContract.setSBCNFTClaimable(
                bettor,
                roundData[_roundID].Level,
                _eventId,
                _date,
                uint16(playersByRound[_roundID].length()),
                eventData[_eventId].TotalPlayers,
                true,
                false
            );
        }
    }

    function isWinner(address _address, uint256 _roundID)
        public
        view
        returns (bool)
    {
        require(
            roundData[_roundID].Result != RoundResult.Indeterminate,
            "Round result is not set yet."
        );
        return betByBettor[_address][_roundID] == roundData[_roundID].Result;
    }

    ///@notice function to withdraw bet amount when bet is stopped in emergency
    function claimBetCanceledRound(uint256 _roundID) external nonReentrant {
        require(
            roundData[_roundID].State == RoundState.Canceled,
            "Event is not cancelled"
        );
        require(
            isBetOnRound[msg.sender][_roundID],
            "You did not make any bets"
        );
        require(
            block.timestamp <= deadlineOfCancelRound[_roundID],
            "Reach out deadline of cancel round."
        );
        isBetOnRound[msg.sender][_roundID] = false;

        uint256 roundFee = eventData[roundData[_roundID].EventID].RoundFee;
        roundData[_roundID].BettingAmount -= roundFee;
        eventData[roundData[_roundID].EventID].TotalAmount -= roundFee;

        payable(msg.sender).transfer(roundFee);
    }

    function massRefundCancelRound(uint256 _roundID) external onlyAdmin {
        require(
            deadlineOfCancelRound[_roundID] < block.timestamp,
            "Not reach out deadline yet."
        );
        require(
            roundData[_roundID].State == RoundState.Canceled,
            "Not canceled round."
        );
        address[] memory list = unclaimCanceleEnvetBettorsList(_roundID);
        uint256 roundFee = eventData[roundData[_roundID].EventID].RoundFee;
        for (uint256 i; i < list.length; i++) {
            payable(list[i]).transfer(roundFee);
            isBetOnRound[list[i]][_roundID] = false;
            playersByRound[_roundID].remove(list[i]);
        }
    }

    function unclaimCanceleEnvetBettorsList(uint256 _roundID)
        public
        view
        returns (address[] memory)
    {
        uint256 roundFee = eventData[roundData[_roundID].EventID].RoundFee;
        uint256 numberOfBettors = roundData[_roundID].BettingAmount / roundFee;
        address[] memory tempList = new address[](numberOfBettors);
        uint256 cnt;
        for (uint256 i; i < playersByRound[_roundID].length(); i++) {
            address bettor = playersByRound[_roundID].at(i);
            if (isBetOnRound[bettor][_roundID]) {
                tempList[cnt++] = bettor;
            }
        }
        return tempList;
    }

    /// @notice function to report bet result

    function reportResult(uint256 _roundID, RoundResult _result)
        external
        OnlyOracle
    {
        require(
            roundData[_roundID].State == RoundState.Finished,
            "event must be stopped first"
        );
        require(_result != RoundResult.Indeterminate, "Invalid result value.");

        roundData[_roundID].Result = _result;

        for (uint256 i; i < playersByRound[_roundID].length(); i++) {
            if (
                betByBettor[playersByRound[_roundID].at(i)][_roundID] == _result
            ) {
                if (
                    roundData[_roundID].Level !=
                    eventData[roundData[_roundID].EventID].TotalRound
                )
                    playersByRound[_roundID + 1].add(
                        playersByRound[_roundID].at(i)
                    );
                else
                    winnersOfFinalRound[roundData[_roundID].EventID].add(
                        playersByRound[_roundID].at(i)
                    );
            }
        }

        payable(prizePool).transfer(roundData[_roundID].BettingAmount);

        emit Results(_roundID, _result);
    }

    /// @notice function for bettors to  vote for preferred choice
    /// @param _playerVote enter 1 to equally split Prize Pool, 2 to randomly pick a sole winner

    function Vote(uint8 _playerVote, uint256 _eventID) external {
        require(
            eventData[_eventID].State == EventState.OnVote,
            "Can't vote for now!"
        );
        require(
            winnersOfFinalRound[_eventID].contains(msg.sender),
            "You are not a winner of final round."
        );
        require(_playerVote == 1 || _playerVote == 2, "Voting choice invalid");
        require(!playersVoteState[msg.sender][_eventID], "You already voted!");

        playersVoteState[msg.sender][_eventID] = true;
        if (_playerVote == 1) eventVote[_eventID]++;
        else eventVote[_eventID]--;
    }

    /// @notice function fo admin to close voting

    function stopVote(uint256 _eventID) internal {
        eventData[_eventID].State = EventState.FinishVote;
        emit VoteFinished(_eventID);
    }

    function setRandomGenerator(address _betRandomGenerator) public onlyAdmin {
        betRandomGenerator = _betRandomGenerator;
    }

    /// @notice function for admin to report voting results

    function resultVote(uint256 _eventID) external onlyAdmin {
        stopVote(_eventID);

        if (eventVote[_eventID] > 0) {
            eventData[_eventID].VResult = VotingResult.Split;
            for (uint256 i; i < winnersOfFinalRound[_eventID].length(); i++) {
                uint256 roundId = eventData[_eventID].CurrentRound;
                setNFTClaimable(
                    winnersOfFinalRound[_eventID].at(i),
                    roundId,
                    _eventID,
                    true,
                    roundData[roundId].Date + 1 days
                );
            }
        } else {
            eventData[_eventID].VResult = VotingResult.Solo;
        }
    }

    function pickWinner(uint256 _eventID) public onlyAdmin {
        require(
            eventData[_eventID].VResult == VotingResult.Solo ||
                winnersOfFinalRound[_eventID].length() == 1,
            "Invalid voting status."
        );

        require(
            selectedWinnerOfVote[_eventID] == address(0),
            "Winner is already selected."
        );
        require(
            betRandomGenerator != address(0),
            "Please set random number generator!"
        );
        address winner;
        uint256 roundId = eventData[_eventID].CurrentRound;

        if (winnersOfFinalRound[_eventID].length() == 1) {
            winner = winnersOfFinalRound[_eventID].at(0);
            setNFTClaimable(
                winner,
                eventData[_eventID].CurrentRound,
                _eventID,
                true,
                roundData[roundId].Date
            );
        } else {
            uint256 rand = ISquidBetRandomGen(betRandomGenerator)
                .getRandomNumber();
            uint256 _winnerNumber = rand %
                winnersOfFinalRound[_eventID].length();
            winner = winnersOfFinalRound[_eventID].at(_winnerNumber);
            setNFTClaimable(
                winner,
                eventData[_eventID].CurrentRound,
                _eventID,
                true,
                roundData[roundId].Date + 1 days
            );
        }

        selectedWinnerOfVote[_eventID] = winner;
    }

    function getWinners(uint256 _eventID)
        public
        view
        returns (address[] memory)
    {
        VotingResult result = eventData[_eventID].VResult;
        require(result != VotingResult.Indeterminate, "No result for now.");
        address[] memory winners;
        if (eventData[_eventID].VResult == VotingResult.Split) {
            winners = new address[](winnersOfFinalRound[_eventID].length());
            for (uint256 i; i < winnersOfFinalRound[_eventID].length(); i++) {
                winners[i] = winnersOfFinalRound[_eventID].at(i);
            }
        } else {
            winners = new address[](1);
            winners[0] = selectedWinnerOfVote[_eventID];
        }
        return winners;
    }

    function isClaimable(address _bettor, uint256 _eventID)
        public
        view
        returns (bool)
    {
        VotingResult result = eventData[_eventID].VResult;
        require(result != VotingResult.Indeterminate, "No result for now.");
        if (!playersClaimReward[_bettor][_eventID]) {
            if (result == VotingResult.Split) {
                return winnersOfFinalRound[_eventID].contains(_bettor);
            } else {
                return _bettor == selectedWinnerOfVote[_eventID];
            }
        } else return false;
    }

    function winnersClaimPrize(uint256 _eventID) public nonReentrant {
        require(isClaimable(msg.sender, _eventID), "You are not claimable.");
        uint256 prize = eventData[_eventID].TotalAmount /
            getWinners(_eventID).length;
        playersClaimReward[msg.sender][_eventID] = true;
        ISquidBetPrizePool(prizePool).winnerClaimPrizePool(msg.sender, prize);
    }

    function getRegisterID(uint256 _eventID, address _bettor)
        public
        view
        returns (uint16)
    {
        return registerIDOfBettor[_bettor][_eventID];
    }

    function getPlayersByRound(uint256 _roundID)
        public
        view
        returns (address[] memory)
    {
        address[] memory bettors = new address[](
            playersByRound[_roundID].length()
        );
        for (uint256 i; i < playersByRound[_roundID].length(); i++) {
            bettors[i] = playersByRound[_roundID].at(i);
        }
        return bettors;
    }

    function getFinalRoundWinnersByEvent(uint256 _eventID)
        public
        view
        returns (address[] memory)
    {
        address[] memory bettors = new address[](
            winnersOfFinalRound[_eventID].length()
        );
        for (uint256 i; i < winnersOfFinalRound[_eventID].length(); i++) {
            bettors[i] = winnersOfFinalRound[_eventID].at(i);
        }
        return bettors;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";

///@title This contract enables to create multiple contract administrators.
contract CustomAdmin is Ownable {
    mapping(address => bool) public admins;
    mapping(address => bool) public Oracles;

    event AdminAdded(address indexed _address);
    event AdminRemoved(address indexed _address);
    event OracleAdded(address indexed _address);
    event OracleRemoved(address indexed _address);

    ///@notice Validates if the sender is actually an administrator.
    modifier onlyAdmin() {
        require(
            admins[msg.sender] || msg.sender == owner(),
            "Only Admin and Owner can perform this function"
        );
        _;
    }

    modifier OnlyOracle() {
        require(
            Oracles[msg.sender] || msg.sender == owner(),
            "Only Oracle and Owner can perform this function"
        );
        _;
    }

    ///@notice Labels the specified address as an admin.
    ///@param _address The address to add as admin.
    function addAdmin(address _address) public onlyAdmin {
        require(_address != address(0));
        require(!admins[_address]);

        //The owner is already an admin and cannot be added.
        require(_address != owner());

        admins[_address] = true;

        emit AdminAdded(_address);
    }

    ///@notice Labels the specified address as an oracle.
    ///@param _address The address to add as oracle.
    function addOracle(address _address) public onlyAdmin {
        require(_address != address(0));
        require(!Oracles[_address]);

        //The owner is already an Oracle and cannot be added.
        require(_address != owner());

        Oracles[_address] = true;

        emit OracleAdded(_address);
    }

    ///@notice Adds multiple addresses to be admins.
    ///@param _accounts The wallet addresses to add as admins.
    function addManyAdmins(address[] memory _accounts) external onlyAdmin {
        for (uint8 i = 0; i < _accounts.length; i++) {
            address account = _accounts[i];

            ///Zero address cannot be an admin.
            ///The owner is already an admin and cannot be assigned.
            ///The address cannot be an existing admin.
            if (
                account != address(0) && !admins[account] && account != owner()
            ) {
                admins[account] = true;

                emit AdminAdded(_accounts[i]);
            }
        }
    }

    ///@notice Adds multiple addresses to be oracles.
    ///@param _accounts The wallet addresses to add as oracles.
    function addManyOracle(address[] memory _accounts) external onlyAdmin {
        for (uint8 i = 0; i < _accounts.length; i++) {
            address account = _accounts[i];

            ///Zero address cannot be an Oracle.
            ///The owner is already an admin and cannot be assigned.
            ///The address cannot be an existing Oracle.
            if (
                account != address(0) && !Oracles[account] && account != owner()
            ) {
                Oracles[account] = true;

                emit OracleAdded(_accounts[i]);
            }
        }
    }

    ///@notice Removes admin status from the specific address.
    ///@param _address The address to remove as admin.
    function removeAdmin(address _address) external onlyAdmin {
        require(_address != address(0));
        require(admins[_address]);

        //The owner cannot be removed as admin.
        require(_address != owner());

        admins[_address] = false;
        emit AdminRemoved(_address);
    }

    ///@notice Removes oracle status from the specific address.
    ///@param _address The address to remove as oracle.
    function removeOracle(address _address) external onlyAdmin {
        require(_address != address(0));
        require(Oracles[_address]);

        //The owner cannot be removed as Oracle.
        require(_address != owner());

        Oracles[_address] = false;
        emit OracleRemoved(_address);
    }

    ///@notice Removes admin status from the provided addresses.
    ///@param _accounts The addresses to remove as admin.
    function removeManyAdmins(address[] memory _accounts) external onlyAdmin {
        for (uint8 i = 0; i < _accounts.length; i++) {
            address account = _accounts[i];

            ///Zero address can neither be added or removed.
            ///The owner is the super admin and cannot be removed.
            ///The address must be an existing admin in order for it to be removed.
            if (
                account != address(0) && admins[account] && account != owner()
            ) {
                admins[account] = false;

                emit AdminRemoved(_accounts[i]);
            }
        }
    }

    ///@notice Removes oracle status from the provided addresses.
    ///@param _accounts The addresses to remove as oracle.
    function removeManyOracles(address[] memory _accounts) external onlyAdmin {
        for (uint8 i = 0; i < _accounts.length; i++) {
            address account = _accounts[i];

            ///Zero address can neither be added or removed.
            ///The address must be an existing oracle in order for it to be removed.
            if (
                account != address(0) && Oracles[account] && account != owner()
            ) {
                Oracles[account] = false;

                emit OracleRemoved(_accounts[i]);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}