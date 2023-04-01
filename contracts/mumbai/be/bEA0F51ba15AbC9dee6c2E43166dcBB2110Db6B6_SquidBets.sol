// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../Utils/SquidBetsCore.sol";

contract SquidBets is SquidBetsCore, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    constructor(
        address _prizePool,
        address _ultibetsTreasury,
        address _ultibetsBuyBack
    ) {
        require(_prizePool != address(0), "invalid address");
        UltibetsBetTreasury = _ultibetsTreasury;
        UltibetsBuyBack = _ultibetsBuyBack;
        prizePool = _prizePool;
        isAdmin[msg.sender] = true;
        isOracle[msg.sender] = true;
    }

    receive() external payable {}

    function createNewEvent(
        string memory _desc,
        uint256 _maxPlayers,
        uint256 _registerAmount,
        uint256 _registerDeadline,
        uint8 _totalRound,
        uint256 _roundAmount,
        uint8 _orgFeePercent
    ) external virtual onlyAdmin {
        totalEventNumber++;
        eventData[totalEventNumber] = EventInfo(
            totalEventNumber,
            _desc,
            0,
            0,
            0,
            _maxPlayers,
            0,
            _registerAmount,
            _roundAmount,
            _orgFeePercent,
            _totalRound,
            EventState.RegisterStart,
            VotingResult.Indeterminate
        );
        registerDeadlineOfEvent[totalEventNumber] = _registerDeadline;

        liveEvents.add(totalEventNumber);

        emit EventCreated(totalEventNumber);
    }

    function registerOnEvent(uint256 _eventID) external payable {
        require(
            uint16(registerIDOfBettor[msg.sender][_eventID]) == 0,
            "You are already registered for the Squid Bet Competition"
        );
        require(
            eventData[_eventID].state == EventState.RegisterStart &&
                block.timestamp <= registerDeadlineOfEvent[_eventID],
            "Can't register for now!"
        );
        require(
            msg.value == eventData[_eventID].registerAmount,
            "Not enough for register fee!"
        );
        require(
            eventData[_eventID].maxPlayers > eventData[_eventID].totalPlayers,
            "Max number of players has been reached"
        );

        uint256 amount = msg.value;
        uint256 orgFee = (amount * eventData[_eventID].orgFeePercent) / 100;

        eventData[_eventID].totalPlayers++;
        organisatorFeeBalance[_eventID] += orgFee;
        eventData[_eventID].totalAmount += amount - orgFee;

        registerIDOfBettor[msg.sender][_eventID] = eventData[_eventID]
            .totalPlayers;

        playersByRound[_eventID][1].add(msg.sender);
    }

    ///@notice function to place bets
    ///@param _roundID is the roundID, _result is the decision

    function placeBet(uint256 _roundID, RoundResult _result) external payable {
        RoundInfo memory round = roundData[_roundID];
        uint256 eventId = round.eventID;
        require(
            round.state == RoundState.Active &&
                block.timestamp <= round.startTime - noticeBetTime,
            "Can't place bet."
        );
        require(
            playersByRound[eventId][round.level].contains(msg.sender),
            "You can't bet on that round!"
        );
        require(
            betByBettor[msg.sender][_roundID] == RoundResult.Indeterminate,
            "Bet placed already"
        );
        require(
            msg.value == eventData[eventId].roundBetAmount,
            "Not enough to bet on the round!"
        );

        require(_result != RoundResult.Indeterminate, "Invalid Bet!");

        uint256 betAmount = msg.value;
        betByBettor[msg.sender][_roundID] = _result;
        eventData[eventId].totalAmount += betAmount;
        roundData[_roundID].poolAmount += betAmount;
        roundData[_roundID].eventPoolAmount += betAmount;
        if (_result == RoundResult.Yes) {
            roundData[_roundID].yesPoolAmount += betAmount;
        } else {
            roundData[_roundID].noPoolAmount += betAmount;
        }

        claimerContract.setSBCNFTClaimable(
            msg.sender,
            round.level,
            eventId,
            round.startTime,
            uint16(playersByRound[eventId][round.level].length()),
            eventData[eventId].totalPlayers,
            NFTType.Normal
        );

        emit BetPlaced(msg.sender, _roundID, msg.value, _result);
    }

    function pickWinner(uint256 _eventID) public onlyAdmin {
        require(
            eventData[_eventID].vResult == VotingResult.Solo,
            "Invalid voting status."
        );

        require(
            selectedWinnerOfVote[_eventID] == address(0),
            "Winner is already selected."
        );

        address winner;
        uint256 rand = ISquidBetRandomGen(betRandomGenerator).getRandomNumber();
        uint256 _winnerNumber = rand % winnersOfFinalRound[_eventID].length();
        winner = winnersOfFinalRound[_eventID].at(_winnerNumber);

        claimerContract.setSBCNFTClaimable(
            winner,
            0,
            _eventID,
            block.timestamp,
            1,
            eventData[_eventID].totalPlayers,
            NFTType.Normal
        );

        selectedWinnerOfVote[_eventID] = winner;
        eventData[_eventID].state = EventState.Finished;
    }

    /// @notice function for admin to report voting results

    function resultVote(uint256 _eventID) external onlyAdmin {
        if (eventVote[_eventID].splitPoint > eventVote[_eventID].soloPoint) {
            eventData[_eventID].vResult = VotingResult.Split;
            for (uint256 i; i < winnersOfFinalRound[_eventID].length(); i++) {
                claimerContract.setSBCNFTClaimable(
                    winnersOfFinalRound[_eventID].at(i),
                    0,
                    _eventID,
                    block.timestamp,
                    uint16(winnersOfFinalRound[_eventID].length()),
                    eventData[_eventID].totalPlayers,
                    NFTType.Normal
                );
            }
            eventData[_eventID].state = EventState.Finished;
        } else {
            eventData[_eventID].vResult = VotingResult.Solo;
        }
    }

    ///@notice function to withdraw bet amount when bet is stopped in emergency
    function claimBetCanceledRound(uint256 _roundID) external {
        RoundInfo memory round = roundData[_roundID];
        require(round.state == RoundState.Canceled, "Event is not cancelled");
        require(
            betByBettor[msg.sender][_roundID] != RoundResult.Indeterminate,
            "You did not make any bets"
        );
        require(
            block.timestamp <= deadlineOfCancelRound[_roundID],
            "Reach out deadline of cancel round."
        );
        betByBettor[msg.sender][_roundID] = RoundResult.Indeterminate;

        uint256 roundBetAmount = eventData[round.eventID].roundBetAmount;
        roundData[_roundID].poolAmount -= roundBetAmount;
        roundData[_roundID].eventPoolAmount -= roundBetAmount;
        eventData[round.eventID].totalAmount -= roundBetAmount;

        payable(msg.sender).transfer(roundBetAmount);
    }

    /// @notice function to report bet result

    function reportResult(
        uint256 _roundID,
        RoundResult _result
    ) public override {
        super.reportResult(_roundID, _result);
        payable(prizePool).transfer(roundData[_roundID].poolAmount);

        RoundInfo memory round = roundData[_roundID];
        if (
            round.level == eventData[round.eventID].totalRound &&
            winnersOfFinalRound[round.eventID].length() == 1
        ) {
            address winner = winnersOfFinalRound[round.eventID].at(0);
            claimerContract.setSBCNFTClaimable(
                winner,
                0,
                round.eventID,
                block.timestamp,
                1,
                eventData[round.eventID].totalPlayers,
                NFTType.Normal
            );
            eventData[round.eventID].state = EventState.Finished;
        }

        if (
            round.level < eventData[round.eventID].totalRound &&
            playersByRound[round.eventID][round.level + 1].length() == 1
        ) {
            eventData[round.eventID].totalRound = round.level;
            address winner = playersByRound[round.eventID][round.level + 1].at(
                0
            );
            winnersOfFinalRound[round.eventID].add(winner);
            claimerContract.setSBCNFTClaimable(
                winner,
                0,
                round.eventID,
                block.timestamp,
                1,
                eventData[round.eventID].totalPlayers,
                NFTType.Normal
            );
            eventData[round.eventID].state = EventState.Finished;
        }
    }

    function transferOrganisatorFeetoTreasury(
        uint256 _eventID
    ) external onlyAdmin {
        require(
            eventData[_eventID].state != EventState.RegisterStart,
            "Registration is still open"
        );

        require(organisatorFeeBalance[_eventID] > 0, "No fees to withdraw");

        uint256 amount = organisatorFeeBalance[_eventID];

        organisatorFeeBalance[_eventID] = 0;
        payable(UltibetsBetTreasury).transfer(amount / 2);
        payable(UltibetsBuyBack).transfer(amount / 2);
    }

    function transferTotalEntryFeesToPrizePool(
        uint256 _eventID
    ) public onlyAdmin {
        require(
            eventData[_eventID].state != EventState.RegisterStart,
            "Registration is still open"
        );

        require(
            organisatorFeeBalance[_eventID] == 0,
            "Withdraw treasury fee first"
        );

        payable(prizePool).transfer(eventData[_eventID].totalAmount);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./CustomAdmin.sol";
import "../Interface/ISBCNFTType.sol";

interface ISquidBetRandomGen {
    function getRandomNumber() external view returns (uint256);
}

interface ISquidBetNFTClaimer is ISBCNFTType {
    function setSBCNFTClaimable(
        address,
        uint8,
        uint256,
        uint256,
        uint16,
        uint16,
        NFTType
    ) external;
}

interface ISquidBetPrizePool {
    function winnerClaimPrizePool(address, uint256) external;
}

contract SquidBetsCore is ISBCNFTType, CustomAdmin {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    ISquidBetNFTClaimer public claimerContract;

    enum EventState {
        RegisterStart,
        OnRound,
        Finished
    }

    enum RoundState {
        Active,
        Canceled,
        Finished
    }

    enum RoundResult {
        Indeterminate,
        Yes,
        No
    }

    enum VotingResult {
        Indeterminate,
        Split,
        Solo
    }

    struct EventInfo {
        uint256 eventID;
        string description;
        uint256 currentRound;
        uint256 firstRound;
        uint256 totalAmount;
        uint256 maxPlayers;
        uint16 totalPlayers;
        uint256 registerAmount;
        uint256 roundBetAmount;
        uint8 orgFeePercent;
        uint8 totalRound;
        EventState state;
        VotingResult vResult;
    }

    struct RoundInfo {
        uint256 roundID;
        uint256 eventID;
        uint256 poolAmount;
        uint256 eventPoolAmount;
        uint256 yesPoolAmount;
        uint256 noPoolAmount;
        string description;
        uint256 startTime;
        RoundResult result;
        uint8 level; //1 -> round1 2->round2
        RoundState state;
    }

    struct EventVote {
        uint256 startTime;
        uint16 splitPoint;
        uint16 soloPoint;
    }

    struct RoundTotalView {
        RoundInfo round;
        uint256 playersNumber;
        uint256 roundBetAmount;
    }

    uint16 public noticeBetTime = 30 minutes; //can't bet since 30 min before the event
    uint16 public voteDeadline = 12 hours; //can't vote 12 hours after the final round result

    uint256 public totalEventNumber;
    uint256 public totalRoundNumber;

    address public prizePool; /// address of the squidBetsPrizePool contract
    address public UltibetsBetTreasury; /// address of the UltibetsBetTreasury contract
    address public UltibetsBuyBack; /// address of the UltibetsBuyback contract

    address public betRandomGenerator;

    mapping(uint256 => EventInfo) public eventData;
    mapping(uint256 => uint256) public registerDeadlineOfEvent;
    EnumerableSet.UintSet liveEvents;
    mapping(uint256 => uint256) public claimedWinnerNumberOfEvent;
    mapping(uint256 => RoundInfo) public roundData;
    mapping(address => mapping(uint256 => RoundResult)) public betByBettor;
    mapping(uint256 => uint256) deadlineOfCancelRound;

    mapping(address => mapping(uint256 => uint16)) public registerIDOfBettor;
    mapping(uint256 => uint256) organisatorFeeBalance;
    mapping(uint256 => mapping(uint8 => EnumerableSet.AddressSet)) playersByRound; // eventID => round level => player addresses
    mapping(uint256 => EnumerableSet.AddressSet) winnersOfFinalRound; // eventID => address set
    mapping(uint256 => address) public selectedWinnerOfVote; //eventID => address
    mapping(address => mapping(uint256 => bool)) public playersVoteState;
    mapping(address => mapping(uint256 => bool)) public playersClaimReward;

    mapping(uint256 => EventVote) public eventVote;

    event BetPlaced(
        address bettor,
        uint256 roundID,
        uint256 amount,
        RoundResult VotingResult
    );

    event Results(uint256 roundID, RoundResult result);

    event EventCreated(uint256 _eventID);
    event EventFinished(uint256 _eventID);

    event RoundAdded(uint256 _roundID);
    event RoundUpdated(uint256 _roundID);
    event RoundCanceled(uint256 _roundID, uint256 _deadline);
    event RoundFinished(uint256 _roundID);

    /* functions to manage event on admin side */

    function updateEventTotalRound(
        uint256 _eventID,
        uint8 _totalRound
    ) public onlyAdmin {
        require(
            _totalRound >= roundData[eventData[_eventID].currentRound].level,
            "Invalid number!"
        );
        eventData[_eventID].totalRound = _totalRound;
    }

    /** =========end========== **/

    /** functions for round **/

    function addRound(
        uint256 _eventID,
        string memory _desc,
        uint256 _startTime
    ) public onlyAdmin {
        uint256 currentRound = eventData[_eventID].currentRound;
        require(
            eventData[_eventID].state == EventState.RegisterStart ||
                eventData[_eventID].state == EventState.OnRound,
            "Can't add round to this event for now!"
        );
        require(
            roundData[currentRound].level + 1 <= eventData[_eventID].totalRound,
            "Can't exceed total round number."
        );
        require(
            currentRound == 0 ||
                roundData[currentRound].state == RoundState.Finished,
            "Current Rounds is not finished yet."
        );

        totalRoundNumber++;
        roundData[totalRoundNumber] = RoundInfo(
            totalRoundNumber,
            _eventID,
            0,
            eventData[_eventID].totalAmount,
            0,
            0,
            _desc,
            _startTime,
            RoundResult.Indeterminate,
            roundData[currentRound].level + 1,
            RoundState.Active
        );

        if (eventData[_eventID].state == EventState.RegisterStart) {
            eventData[_eventID].state = EventState.OnRound;
            eventData[_eventID].firstRound = totalRoundNumber;
        }

        eventData[_eventID].currentRound = totalRoundNumber;
    }

    function cancelRound(uint256 _roundID, uint256 _deadline) public onlyAdmin {
        roundData[_roundID].state = RoundState.Canceled;
        deadlineOfCancelRound[_roundID] = _deadline;

        emit RoundCanceled(_roundID, _deadline);
    }

    function getResult(
        uint256 _roundID
    ) public view returns (RoundResult _win) {
        _win = roundData[_roundID].result;
    }

    function reActiveRound(
        uint256 _roundID,
        uint256 _startTime,
        string memory _desc
    ) public onlyAdmin {
        require(
            roundData[_roundID].state == RoundState.Canceled,
            "That is not canceled round!"
        );
        roundData[_roundID].poolAmount = 0;
        uint256 eventId = roundData[_roundID].eventID;
        roundData[_roundID].eventPoolAmount = eventData[eventId].totalAmount;
        roundData[_roundID].description = _desc;
        roundData[_roundID].state = RoundState.Active;
        roundData[_roundID].startTime = _startTime;

        emit RoundUpdated(_roundID);
    }

    /** ===============end================ **/

    function isWinner(
        address _address,
        uint256 _roundID
    ) public view returns (bool) {
        require(
            roundData[_roundID].result != RoundResult.Indeterminate,
            "Round result is not set yet."
        );
        return betByBettor[_address][_roundID] == roundData[_roundID].result;
    }

    function massRefundCancelRound(uint256 _roundID) external onlyAdmin {
        RoundInfo memory round = roundData[_roundID];
        require(
            deadlineOfCancelRound[_roundID] < block.timestamp,
            "Not reach out deadline yet."
        );
        require(round.state == RoundState.Canceled, "Not canceled round.");
        address[] memory list = unclaimCancelEnvetBettorsList(_roundID);
        uint256 roundAmount = eventData[round.eventID].roundBetAmount;
        for (uint256 i; i < list.length; i++) {
            refund(list[i], roundAmount);
            betByBettor[list[i]][_roundID] = RoundResult.Indeterminate;
        }
        delete playersByRound[round.eventID][round.level];
    }

    function refund(address _receiver, uint256 _amount) internal virtual {
        payable(_receiver).transfer(_amount);
    }

    function unclaimCancelEnvetBettorsList(
        uint256 _roundID
    ) public view returns (address[] memory) {
        RoundInfo memory round = roundData[_roundID];
        uint256 numberOfBettors = playersByRound[round.eventID][round.level]
            .length();
        address[] memory tempList = new address[](numberOfBettors);
        uint256 cnt;
        for (uint256 i; i < numberOfBettors; i++) {
            address bettor = playersByRound[round.eventID][round.level].at(i);
            if (betByBettor[bettor][_roundID] != RoundResult.Indeterminate) {
                tempList[cnt++] = bettor;
            }
        }
        return tempList;
    }

    /// @notice function to report bet result

    function reportResult(
        uint256 _roundID,
        RoundResult _result
    ) public virtual onlyOracle {
        RoundInfo memory round = roundData[_roundID];
        require(_roundID <= totalRoundNumber, "Invalid Round ID.");
        require(
            round.state == RoundState.Active,
            "event must be stopped first"
        );
        require(_result != RoundResult.Indeterminate, "Invalid result value.");

        roundData[_roundID].result = _result;
        if (round.level == eventData[round.eventID].totalRound) {
            eventVote[round.eventID].startTime = block.timestamp;
        }
        uint256 playersNumber = playersByRound[round.eventID][round.level]
            .length();

        for (uint256 i; i < playersNumber; i++) {
            address player = playersByRound[round.eventID][round.level].at(i);
            if (betByBettor[player][_roundID] == _result) {
                if (round.level != eventData[round.eventID].totalRound)
                    playersByRound[round.eventID][round.level + 1].add(player);
                else winnersOfFinalRound[round.eventID].add(player);
            }
        }

        roundData[_roundID].state = RoundState.Finished;

        emit Results(_roundID, _result);
    }

    /// @notice function for bettors to  vote for preferred choice
    /// @param _playerVote enter 1 to equally split Prize Pool, 2 to randomly pick a sole winner

    function Vote(uint8 _playerVote, uint256 _eventID) external {
        require(
            winnersOfFinalRound[_eventID].length() > 0,
            "Only one winner, No need vote!"
        );
        require(
            block.timestamp >= eventVote[_eventID].startTime &&
                block.timestamp <= eventVote[_eventID].startTime + voteDeadline,
            "Can't vote for now!"
        );
        require(
            winnersOfFinalRound[_eventID].contains(msg.sender),
            "You are not a winner of final round."
        );
        require(_playerVote == 1 || _playerVote == 2, "Voting choice invalid");
        require(!playersVoteState[msg.sender][_eventID], "You already voted!");

        playersVoteState[msg.sender][_eventID] = true;
        if (_playerVote == 1) eventVote[_eventID].splitPoint++;
        else eventVote[_eventID].soloPoint++;
    }

    function getWinnerIDs(
        uint256 _eventID
    ) public view returns (uint16[] memory) {
        VotingResult result = eventData[_eventID].vResult;
        uint256 winnersLength = winnersOfFinalRound[_eventID].length();
        require(
            result != VotingResult.Indeterminate || winnersLength == 1,
            "No result for now."
        );
        uint16[] memory winnerIDs;
        if (eventData[_eventID].vResult == VotingResult.Split) {
            winnerIDs = new uint16[](winnersLength);
            for (uint256 i; i < winnersOfFinalRound[_eventID].length(); i++) {
                winnerIDs[i] = registerIDOfBettor[
                    winnersOfFinalRound[_eventID].at(i)
                ][_eventID];
            }
        } else if (eventData[_eventID].vResult == VotingResult.Solo) {
            winnerIDs = new uint16[](1);
            winnerIDs[0] = registerIDOfBettor[selectedWinnerOfVote[_eventID]][
                _eventID
            ];
        } else {
            winnerIDs = new uint16[](1);
            winnerIDs[0] = registerIDOfBettor[
                winnersOfFinalRound[_eventID].at(0)
            ][_eventID];
        }
        return winnerIDs;
    }

    function isClaimable(
        address _bettor,
        uint256 _eventID
    ) public view returns (bool) {
        VotingResult result = eventData[_eventID].vResult;
        require(
            eventData[_eventID].state == EventState.Finished,
            "Event is not finished yet."
        );
        if (!playersClaimReward[_bettor][_eventID]) {
            if (result == VotingResult.Solo) {
                return _bettor == selectedWinnerOfVote[_eventID];
            } else {
                return winnersOfFinalRound[_eventID].contains(_bettor);
            }
        } else return false;
    }

    function winnersClaimPrize(uint256 _eventID) public {
        require(isClaimable(msg.sender, _eventID), "You are not claimable.");
        VotingResult result = eventData[_eventID].vResult;
        uint256 winnerNumber = 0;
        if (result == VotingResult.Solo) {
            winnerNumber = 1;
        } else {
            winnerNumber = winnersOfFinalRound[_eventID].length();
        }
        uint256 prize = eventData[_eventID].totalAmount / winnerNumber;
        playersClaimReward[msg.sender][_eventID] = true;
        ISquidBetPrizePool(prizePool).winnerClaimPrizePool(msg.sender, prize);

        claimedWinnerNumberOfEvent[_eventID]++;
        if (claimedWinnerNumberOfEvent[_eventID] == winnerNumber) {
            liveEvents.remove(_eventID);
        }
    }

    function removeExpiredEvent(uint256 _eventID) external onlyAdmin {
        require(
            winnersOfFinalRound[_eventID].length() == 0 &&
                eventData[_eventID].state == EventState.Finished,
            "Can't remove live event!"
        );
        liveEvents.remove(_eventID);
    }

    function getPlayersByRound(
        uint256 _roundID
    ) public view returns (address[] memory) {
        RoundInfo memory round = roundData[_roundID];
        uint256 playersNumber = playersByRound[round.eventID][round.level]
            .length();
        address[] memory bettors = new address[](playersNumber);
        for (uint256 i; i < playersNumber; i++) {
            bettors[i] = playersByRound[round.eventID][round.level].at(i);
        }
        return bettors;
    }

    function getRoundTotalInfo(
        uint256 _roundID
    ) public view returns (RoundTotalView memory) {
        RoundInfo memory round = roundData[_roundID];
        uint256 roundPlayersNumber = playersByRound[round.eventID][round.level]
            .length();
        uint256 roundBetAmount = eventData[round.eventID].roundBetAmount;
        return RoundTotalView(round, roundPlayersNumber, roundBetAmount);
    }

    function getEventList()
        external
        view
        returns (EventInfo[] memory, uint256[] memory)
    {
        uint256 numberOfEvents = liveEvents.length();
        EventInfo[] memory eventList = new EventInfo[](numberOfEvents);
        uint256[] memory registerDeadlines = new uint256[](numberOfEvents);
        for (uint i; i < numberOfEvents; i++) {
            EventInfo memory eData = eventData[liveEvents.at(i)];
            eventList[i] = eData;
            registerDeadlines[i] = registerDeadlineOfEvent[liveEvents.at(i)];
        }

        return (eventList, registerDeadlines);
    }

    function getFinalRoundWinnersByEvent(
        uint256 _eventID
    ) public view returns (address[] memory) {
        address[] memory bettors = new address[](
            winnersOfFinalRound[_eventID].length()
        );
        for (uint256 i; i < winnersOfFinalRound[_eventID].length(); i++) {
            bettors[i] = winnersOfFinalRound[_eventID].at(i);
        }
        return bettors;
    }

    function setUltibetsBuyBack(address _buyback) external onlyAdmin {
        UltibetsBuyBack = _buyback;
    }

    function setClaimerContract(ISquidBetNFTClaimer _claimer) public onlyAdmin {
        claimerContract = _claimer;
    }

    function setRandomGenerator(address _betRandomGenerator) public onlyAdmin {
        betRandomGenerator = _betRandomGenerator;
    }

    function setNoticeBetTime(uint16 _noticeTime) public onlyAdmin {
        noticeBetTime = _noticeTime;
    }

    function setVoteDeadline(uint16 _voteDeadline) public onlyAdmin {
        voteDeadline = _voteDeadline;
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";

contract CustomAdmin is Ownable {
    mapping(address => bool) public isAdmin;
    mapping(address => bool) public isOracle;

    ///@notice Validates if the sender is actually an administrator.
    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "You are not admin.");
        _;
    }

    modifier onlyOracle() {
        require(isOracle[msg.sender], "You are not oracle.");
        _;
    }

    function addOracle(address _oracle) external onlyAdmin {
        isOracle[_oracle] = true;
    }

    function addAdmin(address _admin) external onlyAdmin {
        isAdmin[_admin] = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ISBCNFTType {
    enum NFTType {
        Normal,
        UTBETS,
        Warrior
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