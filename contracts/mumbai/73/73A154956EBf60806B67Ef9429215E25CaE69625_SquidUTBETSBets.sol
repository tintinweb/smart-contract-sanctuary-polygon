// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../Utils/CustomAdmin.sol";
import "../Interface/IUltiBetsToken.sol";
import "../Utils/SquidBetsCore.sol";

contract SquidUTBETSBets is SquidBetsCore {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    IUltiBetsToken private ultibetsToken;

    address public signer;
    mapping(address => uint256) nonces;

    mapping(uint256 => bool) public isWarriorEvent;

    event WarriorEventCreated(uint256 eventID);

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

    function createNewEvent(
        string memory _desc,
        uint16 _maxPlayers,
        uint256 _registerAmount,
        uint256 _registerDeadline,
        uint8 _totalRound,
        uint256 _roundAmount,
        uint8 _orgFeePercent,
        bool _isWarrior
    ) external onlyAdmin {
        totalEventNumber++;
        eventData[totalEventNumber] = EventInfo(
            totalEventNumber,
            _desc,
            0,
            0,
            _maxPlayers,
            0,
            _registerAmount,
            _roundAmount,
            _orgFeePercent,
            _totalRound,
            _registerDeadline,
            EventState.Register,
            VotingResult.Indeterminate
        );

        if (_isWarrior) {
            isWarriorEvent[totalEventNumber] = true;
            emit WarriorEventCreated(totalEventNumber);
        } else {
            emit EventCreated(totalEventNumber);
        }
    }

    /* sign functions for warrior sbc */

    function registerOnWarriorEvent(
        uint256 _eventID,
        bytes memory _signature
    ) external {
        require(
            isWarriorEvent[_eventID],
            "Can't call this function for regular sbc!"
        );
        require(verify(msg.sender, _eventID, _signature), "Invalid Signature.");
        require(
            uint16(registerIDOfBettor[msg.sender][_eventID]) == 0,
            "You are already registered for the Squid Bet Competition"
        );
        require(
            eventData[_eventID].state == EventState.Register &&
                block.timestamp <= eventData[_eventID].registerDeadline,
            "Can't register for now!"
        );
        require(
            eventData[_eventID].maxPlayers > eventData[_eventID].totalPlayers,
            "Max number of players has been reached"
        );

        eventData[_eventID].totalPlayers++;
        registerIDOfBettor[msg.sender][_eventID] = eventData[_eventID]
            .totalPlayers;
        playersByRound[_eventID][1].add(msg.sender);

        emit Register(msg.sender, _eventID);
    }

    function getMessageHash(
        address _bettor,
        uint256 _eventID
    ) public view returns (bytes32) {
        return keccak256(abi.encodePacked(_eventID, nonces[_bettor]));
    }

    function getEthSignedMessageHash(
        bytes32 _messageHash
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function verify(
        address _bettor,
        uint256 _eventID,
        bytes memory signature
    ) internal view returns (bool) {
        require(signature.length == 65, "invalid signature length");

        bytes32 messageHash = getMessageHash(_bettor, _eventID);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);

        return ecrecover(ethSignedMessageHash, v, r, s) == signer;
    }

    function splitSignature(
        bytes memory sig
    ) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function setSigner(address _signer) public onlyAdmin {
        signer = _signer;
    }

    /////////////////////////////

    function registerOnEvent(uint256 _eventID) external {
        require(
            !isWarriorEvent[_eventID],
            "Can't call this function for warrior sbc!"
        );
        uint256 amount = eventData[_eventID].registerAmount;
        require(
            registerIDOfBettor[msg.sender][_eventID] == 0,
            "You are already registered for the Squid Bet Competition"
        );
        require(
            eventData[_eventID].state == EventState.Register &&
                block.timestamp <= eventData[_eventID].registerDeadline,
            "Can't regist for now!"
        );
        require(
            ultibetsToken.balanceOf(msg.sender) >= amount,
            "Not enough for register fee!"
        );
        require(
            eventData[_eventID].maxPlayers > eventData[_eventID].totalPlayers,
            "Max number of players has been reached"
        );

        ultibetsToken.approveOrg(
            address(this),
            eventData[_eventID].registerAmount
        );
        ultibetsToken.transferFrom(
            msg.sender,
            address(this),
            eventData[_eventID].registerAmount
        );

        uint256 orgFee = (amount * eventData[_eventID].orgFeePercent) / 100;

        eventData[_eventID].totalPlayers++;
        organisatorFeeBalance[_eventID] += orgFee;
        eventData[_eventID].totalAmount += amount - orgFee;

        registerIDOfBettor[msg.sender][_eventID] = eventData[_eventID]
            .totalPlayers;

        playersByRound[_eventID][1].add(msg.sender);

        emit Register(msg.sender, _eventID);

    }

    function placeBet(uint256 _eventID, RoundResult _result) external {
        uint256 betAmount = eventData[_eventID].roundBetAmount;

        require(
            ultibetsToken.balanceOf(msg.sender) >= betAmount,
            "Not enough to bet on the round!"
        );

        ultibetsToken.approveOrg(address(this), betAmount);
        ultibetsToken.transferFrom(msg.sender, address(this), betAmount);

        _placeBet(_eventID, _result);
    }

    /// @notice function to report bet result

    function reportResult(
        uint256 _eventID,
        RoundResult _result
    ) public override {
        super.reportResult(_eventID, _result);
        uint8 currentLevel = eventData[_eventID].currentLevel;
        uint256 poolAmount = roundData[_eventID][currentLevel].yesPoolAmount +
            roundData[_eventID][currentLevel].noPoolAmount;
        ultibetsToken.transfer(prizePool, poolAmount);
    }

    ///@notice function to withdraw bet amount when bet is stopped in emergency
    function claimBetCanceledRound(uint256 _eventID) public override {
        super.claimBetCanceledRound(_eventID);
        uint256 roundBetAmount = eventData[_eventID].roundBetAmount;
        ultibetsToken.transfer(msg.sender, roundBetAmount);
    }

    function refund(address _receiver, uint256 _amount) internal override {
        ultibetsToken.transfer(_receiver, _amount);
    }

    function getNFTType(
        uint256 _eventID
    ) public view override returns (NFTType) {
        if (isWarriorEvent[_eventID]) return NFTType.Warrior;
        else return NFTType.UTBETS;
    }

    function transferOrganisatorFeetoTreasury(
        uint256 _eventID
    ) external onlyAdmin {
        require(
            eventData[_eventID].state != EventState.Register,
            "Registration is still open"
        );

        require(organisatorFeeBalance[_eventID] > 0, "No fees to withdraw");

        uint256 amount = organisatorFeeBalance[_eventID];

        organisatorFeeBalance[_eventID] = 0;
        ultibetsToken.transfer(UltibetsBetTreasury, amount / 2);
        ultibetsToken.transfer(UltibetsBuyBack, amount / 2);
    }

    function transferTotalEntryFeestoPrizePool(
        uint256 _eventID
    ) public onlyAdmin {
        require(
            eventData[_eventID].state != EventState.Register,
            "Registration is still open"
        );

        require(
            organisatorFeeBalance[_eventID] == 0,
            "Withdraw treasury fee first"
        );

        ultibetsToken.transfer(prizePool, eventData[_eventID].totalAmount);
    }

    function setUTBETSContract(IUltiBetsToken _utbets) public onlyAdmin {
        ultibetsToken = _utbets;
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

    constructor() {
        isAdmin[msg.sender] = true;
        isOracle[msg.sender] = true;
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

interface IUltiBetsToken {
    
    function allowance(address, address) external view returns(uint256);

    function approveOrg(address, uint256) external;
    
    function burn(uint256) external;

    function balanceOf(address) external view returns (uint256);

    function transfer(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);
    
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
        Register,
        Round,
        Vote,
        PickWinner,
        ClaimPrize,
        Completed
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
        uint8 currentLevel; //round1 - 5
        uint256 totalAmount;
        uint16 maxPlayers;
        uint16 totalPlayers;
        uint256 registerAmount;
        uint256 roundBetAmount;
        uint8 orgFeePercent;
        uint8 totalRound;
        uint256 registerDeadline;
        EventState state;
        VotingResult vResult;
    }

    struct RoundInfo {
        string description;
        uint256 eventID;
        uint256 yesPoolAmount;
        uint256 noPoolAmount;
        uint256 startTime;
        RoundResult result;
        RoundState state;
    }

    struct EventVote {
        uint256 startTime;
        uint16 splitPoint;
        uint16 soloPoint;
    }

    uint16 public noticeBetTime = 30 minutes; //can't bet since 30 min before the event
    uint16 public voteDeadline = 12 hours; //can't vote 12 hours after the final round result

    uint256 public totalEventNumber;

    address public prizePool; /// address of the squidBetsPrizePool contract
    address public UltibetsBetTreasury; /// address of the UltibetsBetTreasury contract
    address public UltibetsBuyBack; /// address of the UltibetsBuyback contract
    address public ultiBetsRandomGen; //random genderator contract

    mapping(uint256 => EventInfo) public eventData;
    mapping(uint256 => mapping(uint8 => RoundInfo)) public roundData;
    mapping(uint256 => uint16) public claimedWinnerNumberOfEvent;
    mapping(uint256 => uint16) public winnersNumberOfEvent;
    mapping(uint256 => uint256) public prizeOfEvent;
    mapping(address => mapping(uint256 => mapping(uint8 => RoundResult)))
        public bettorDecisionOnRound;
    mapping(uint256 => mapping(uint8 => uint256)) public deadlineOfCancelRound;

    mapping(address => mapping(uint256 => uint16)) public registerIDOfBettor;
    mapping(uint256 => uint256) organisatorFeeBalance;
    mapping(uint256 => mapping(uint8 => EnumerableSet.AddressSet)) playersByRound; // eventID => round level => player addresses
    mapping(uint256 => EnumerableSet.AddressSet) winnersOfFinalRound; // eventID => address set
    mapping(uint256 => address) public solorWinnerOfVote; //eventID => address
    mapping(address => mapping(uint256 => bool)) public playersVoteState;
    mapping(address => mapping(uint256 => bool)) public playersClaimReward;

    mapping(uint256 => EventVote) public eventVote;

    event EventCreated(uint256 eventID);
    event PickEventWinner(uint256 eventID);
    event Register(address, uint256 eventID);
    event ReportVoteResult(uint256 eventID);
    event UpdateTotalRound(uint256 eventID);
    event WinnerClaimedPrize(uint256 eventID);
    event VoteEvent(address voter, uint256 eventID, VotingResult voteResult);

    event RoundAdded(uint256 eventID, uint8 roundLevel, uint16 playersNumber);
    event BetPlaced(
        address bettor,
        uint256 eventID,
        uint8 roundLevel,
        RoundResult result
    );
    event RoundUpdated(uint256 eventID, uint8 roundLevel);
    event RoundCanceled(uint256 eventID, uint8 roundLevel);
    event RoundFinished(uint256 eventID, uint8 roundLevel);
    event RefundCanceledRound(address bettor, uint256 eventID);

    /* functions to manage event on admin side */

    function updateEventTotalRound(
        uint256 _eventID,
        uint8 _totalRound
    ) public onlyAdmin {
        require(
            _totalRound >= eventData[_eventID].currentLevel,
            "Invalid number!"
        );
        eventData[_eventID].totalRound = _totalRound;

        emit UpdateTotalRound(_eventID);
    }

    /** functions for round **/

    function addRound(
        uint256 _eventID,
        string memory _desc,
        uint256 _startTime
    ) public onlyAdmin {
        uint8 currentLevel = eventData[_eventID].currentLevel;
        uint8 newLevel = currentLevel + 1;
        require(
            eventData[_eventID].state == EventState.Register ||
                eventData[_eventID].state == EventState.Round,
            "Can't add round to this event for now!"
        );
        require(
            newLevel <= eventData[_eventID].totalRound,
            "Can't exceed total round number."
        );
        require(
            currentLevel == 0 ||
                roundData[_eventID][currentLevel].state == RoundState.Finished,
            "Current Rounds is not finished yet."
        );

        roundData[_eventID][newLevel] = RoundInfo(
            _desc,
            _eventID,
            0,
            0,
            _startTime,
            RoundResult.Indeterminate,
            RoundState.Active
        );

        if (eventData[_eventID].state == EventState.Register) {
            eventData[_eventID].state = EventState.Round;
        }

        eventData[_eventID].currentLevel = newLevel;

        uint16 playersOnRound = uint16(playersByRound[_eventID][newLevel].length());

        emit RoundAdded(_eventID, newLevel, playersOnRound);
    }

    function cancelRound(
        uint256 _eventID,
        uint8 _roundLevel,
        uint256 _deadline
    ) public onlyAdmin {
        roundData[_eventID][_roundLevel].state = RoundState.Canceled;
        deadlineOfCancelRound[_eventID][_roundLevel] = _deadline;

        emit RoundCanceled(_eventID, _roundLevel);
    }

    function reActiveCanceledRound(
        uint256 _eventID,
        uint256 _startTime,
        string memory _desc
    ) public onlyAdmin {
        uint8 currentLevel = eventData[_eventID].currentLevel;
        require(
            roundData[_eventID][currentLevel].state == RoundState.Canceled,
            "No round was canceled!"
        );

        roundData[_eventID][currentLevel] = RoundInfo(
            _desc,
            _eventID,
            0,
            0,
            _startTime,
            RoundResult.Indeterminate,
            RoundState.Active
        );

        emit RoundUpdated(_eventID, currentLevel);
    }

    function massRefundCancelRound(uint256 _eventID) external onlyAdmin {
        uint8 currentLevel = eventData[_eventID].currentLevel;
        RoundInfo memory round = roundData[_eventID][currentLevel];
        require(
            deadlineOfCancelRound[_eventID][currentLevel] < block.timestamp,
            "Not reach out deadline yet."
        );
        require(round.state == RoundState.Canceled, "Not canceled round.");
        address[] memory bettorList = unclaimCancelRoundBettorsList(_eventID);
        uint256 betAmount = eventData[_eventID].roundBetAmount;
        for (uint256 i; i < bettorList.length; i++) {
            refund(bettorList[i], betAmount);
            bettorDecisionOnRound[bettorList[i]][_eventID][
                currentLevel
            ] = RoundResult.Indeterminate;
            playersByRound[_eventID][currentLevel].remove(bettorList[i]);
        }
    }

    function refund(address _receiver, uint256 _amount) internal virtual {
        payable(_receiver).transfer(_amount);
    }

    /** ===============end================ **/

    function isWinner(
        address _address,
        uint256 _eventID,
        uint8 _level
    ) public view returns (bool) {
        require(
            roundData[_eventID][_level].result != RoundResult.Indeterminate,
            "Round result is not set yet."
        );
        return
            bettorDecisionOnRound[_address][_eventID][_level] ==
            roundData[_eventID][_level].result;
    }

    function unclaimCancelRoundBettorsList(
        uint256 _eventID
    ) public view returns (address[] memory) {
        uint8 currentLevel = eventData[_eventID].currentLevel;
        uint256 numberOfBettors = playersByRound[_eventID][currentLevel]
            .length();
        address[] memory tempList = new address[](numberOfBettors);
        uint256 cnt;
        for (uint256 i; i < numberOfBettors; i++) {
            address bettor = playersByRound[_eventID][currentLevel].at(i);
            if (
                bettorDecisionOnRound[bettor][_eventID][currentLevel] !=
                RoundResult.Indeterminate
            ) {
                tempList[cnt++] = bettor;
            }
        }
        return tempList;
    }

    /// @notice function to report bet result

    function reportResult(
        uint256 _eventID,
        RoundResult _result
    ) public virtual onlyOracle {
        uint8 currentLevel = eventData[_eventID].currentLevel;
        RoundInfo memory round = roundData[_eventID][currentLevel];
        require(
            round.state == RoundState.Active,
            "Can't report result for that round!"
        );
        require(_result != RoundResult.Indeterminate, "Invalid result value.");

        uint256 playersNumber = playersByRound[_eventID][currentLevel].length();

        for (uint256 i; i < playersNumber; i++) {
            address player = playersByRound[_eventID][currentLevel].at(i);
            if (
                bettorDecisionOnRound[player][_eventID][currentLevel] == _result
            ) {
                if (currentLevel != eventData[_eventID].totalRound)
                    playersByRound[_eventID][currentLevel + 1].add(player);
                else winnersOfFinalRound[_eventID].add(player);
            }
        }

        if (currentLevel < eventData[_eventID].totalRound) {
            uint256 nextRoundPlayersNumber = playersByRound[_eventID][
                currentLevel + 1
            ].length();
            if (nextRoundPlayersNumber == 1) {
                eventData[_eventID].totalRound = currentLevel;
                address winner = playersByRound[_eventID][currentLevel + 1].at(
                    0
                );
                winnersOfFinalRound[_eventID].add(winner);
            } else if (nextRoundPlayersNumber == 0) {
                eventData[_eventID].totalRound = currentLevel;
            }
        }

        uint256 winnersNumber = winnersOfFinalRound[_eventID].length();

        if (currentLevel == eventData[_eventID].totalRound) {
            if (winnersNumber == 1) {
                address winner = winnersOfFinalRound[_eventID].at(0);
                claimerContract.setSBCNFTClaimable(
                    winner,
                    0,
                    _eventID,
                    block.timestamp,
                    1,
                    eventData[_eventID].totalPlayers,
                    getNFTType(_eventID)
                );
                prizeOfEvent[_eventID] = eventData[_eventID].totalAmount;
                eventData[_eventID].state = EventState.ClaimPrize;
                winnersNumberOfEvent[_eventID] = 1;
            } else if (winnersNumber > 1) {
                eventVote[_eventID].startTime = block.timestamp;
                eventData[_eventID].state = EventState.Vote;
            } else {
                eventData[_eventID].state = EventState.Completed;
            }
        }

        roundData[_eventID][currentLevel].result = _result;
        roundData[_eventID][currentLevel].state = RoundState.Finished;

        emit RoundFinished(_eventID, currentLevel);
    }

    function _placeBet(uint256 _eventID, RoundResult _result) internal {
        uint8 currentLevel = eventData[_eventID].currentLevel;
        RoundInfo memory round = roundData[_eventID][currentLevel];
        require(
            round.state == RoundState.Active &&
                block.timestamp <= round.startTime - noticeBetTime,
            "Can't place bet."
        );
        require(
            playersByRound[_eventID][currentLevel].contains(msg.sender),
            "You can't bet on that round!"
        );
        require(
            bettorDecisionOnRound[msg.sender][_eventID][currentLevel] ==
                RoundResult.Indeterminate,
            "Bet placed already"
        );
        require(_result != RoundResult.Indeterminate, "Invalid Bet!");

        uint256 betAmount = eventData[_eventID].roundBetAmount;
        bettorDecisionOnRound[msg.sender][_eventID][currentLevel] = _result;
        eventData[_eventID].totalAmount += betAmount;
        if (_result == RoundResult.Yes) {
            roundData[_eventID][currentLevel].yesPoolAmount += betAmount;
        } else {
            roundData[_eventID][currentLevel].noPoolAmount += betAmount;
        }

        claimerContract.setSBCNFTClaimable(
            msg.sender,
            currentLevel,
            _eventID,
            round.startTime,
            uint16(playersByRound[_eventID][currentLevel].length()),
            eventData[_eventID].totalPlayers,
            getNFTType(_eventID)
        );

        emit BetPlaced(msg.sender, _eventID, currentLevel, _result);
    }

    function pickWinner(uint256 _eventID) public onlyAdmin {
        require(
            eventData[_eventID].vResult == VotingResult.Solo,
            "Invalid voting status."
        );

        require(
            solorWinnerOfVote[_eventID] == address(0),
            "Winner is already selected."
        );

        uint256 rand = ISquidBetRandomGen(ultiBetsRandomGen).getRandomNumber();
        uint256 _winnerNumber = rand % winnersOfFinalRound[_eventID].length();
        address winner = winnersOfFinalRound[_eventID].at(_winnerNumber);

        claimerContract.setSBCNFTClaimable(
            winner,
            0,
            _eventID,
            block.timestamp,
            1,
            eventData[_eventID].totalPlayers,
            NFTType.Normal
        );

        solorWinnerOfVote[_eventID] = winner;
        prizeOfEvent[_eventID] = eventData[_eventID].totalAmount;
        eventData[_eventID].state = EventState.ClaimPrize;
        winnersNumberOfEvent[_eventID] = 1;

        emit PickEventWinner(_eventID);
    }

    function getNFTType(uint256) public view virtual returns (NFTType) {
        //_eventID will be used in utbets
        return NFTType.Normal;
    }

    /// @notice function for bettors to  vote for preferred choice
    /// @param _playerVote enter 1 to equally split Prize Pool, 2 to randomly pick a sole winner

    function vote(VotingResult _playerVote, uint256 _eventID) external {
        require(
            winnersOfFinalRound[_eventID].contains(msg.sender) &&
                eventVote[_eventID].startTime > 0,
            "Can't vote."
        );
        require(
            block.timestamp >= eventVote[_eventID].startTime &&
                block.timestamp <= eventVote[_eventID].startTime + voteDeadline,
            "Can't vote for now!"
        );

        require(!playersVoteState[msg.sender][_eventID], "You already voted!");

        require(_playerVote != VotingResult.Indeterminate, "Invalid Vote.");

        playersVoteState[msg.sender][_eventID] = true;
        if (_playerVote == VotingResult.Split) eventVote[_eventID].splitPoint++;
        else eventVote[_eventID].soloPoint++;

        emit VoteEvent(msg.sender, _eventID, _playerVote);
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
                    getNFTType(_eventID)
                );
            }
            prizeOfEvent[_eventID] =
                eventData[_eventID].totalAmount /
                winnersOfFinalRound[_eventID].length();
            eventData[_eventID].state = EventState.ClaimPrize;
            winnersNumberOfEvent[_eventID] = uint16(
                winnersOfFinalRound[_eventID].length()
            );
        } else {
            eventData[_eventID].state = EventState.PickWinner;
            eventData[_eventID].vResult = VotingResult.Solo;
        }

        emit ReportVoteResult(_eventID);
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
        } else {
            winnerIDs = new uint16[](1);
            if (eventData[_eventID].vResult == VotingResult.Solo) {
                winnerIDs[0] = registerIDOfBettor[solorWinnerOfVote[_eventID]][
                    _eventID
                ];
            } else {
                winnerIDs[0] = registerIDOfBettor[
                    winnersOfFinalRound[_eventID].at(0)
                ][_eventID];
            }
        }
        return winnerIDs;
    }

    function isClaimable(
        address _bettor,
        uint256 _eventID
    ) public view returns (bool) {
        VotingResult voteResult = eventData[_eventID].vResult;
        require(
            eventData[_eventID].state == EventState.ClaimPrize,
            "Not claimalbe at this state."
        );
        if (!playersClaimReward[_bettor][_eventID]) {
            if (voteResult == VotingResult.Solo) {
                return _bettor == solorWinnerOfVote[_eventID];
            } else {
                return winnersOfFinalRound[_eventID].contains(_bettor);
            }
        } else return false;
    }

    ///@notice function to withdraw bet amount when bet is stopped in emergency
    function claimBetCanceledRound(uint256 _eventID) public virtual {
        uint8 currentLevel = eventData[_eventID].currentLevel;
        RoundInfo memory round = roundData[_eventID][currentLevel];
        require(round.state == RoundState.Canceled, "Event is not cancelled");
        require(
            bettorDecisionOnRound[msg.sender][_eventID][currentLevel] !=
                RoundResult.Indeterminate,
            "You did not make any bets"
        );
        require(
            block.timestamp <= deadlineOfCancelRound[_eventID][currentLevel],
            "Reach out deadline of cancel round."
        );
        bettorDecisionOnRound[msg.sender][_eventID][currentLevel] = RoundResult
            .Indeterminate;

        uint256 roundBetAmount = eventData[_eventID].roundBetAmount;
        eventData[_eventID].totalAmount -= roundBetAmount;

        emit RefundCanceledRound(msg.sender, _eventID);
    }

    function winnersClaimPrize(uint256 _eventID) public {
        require(isClaimable(msg.sender, _eventID), "You are not claimable.");

        ISquidBetPrizePool(prizePool).winnerClaimPrizePool(
            msg.sender,
            prizeOfEvent[_eventID]
        );
        playersClaimReward[msg.sender][_eventID] = true;
        claimedWinnerNumberOfEvent[_eventID] += 1;
        if (
            claimedWinnerNumberOfEvent[_eventID] ==
            winnersNumberOfEvent[_eventID]
        ) {
            eventData[_eventID].state = EventState.Completed;
        }

        emit WinnerClaimedPrize(_eventID);
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

    function setPrizePool(address _prizePool) external onlyAdmin {
        prizePool = _prizePool;
    }

    function setUltibetsBuyBack(address _buyback) external onlyAdmin {
        UltibetsBuyBack = _buyback;
    }

    function setClaimerContract(ISquidBetNFTClaimer _claimer) public onlyAdmin {
        claimerContract = _claimer;
    }

    function setRandomGenerator(address _ultiBetsRandomGen) public onlyAdmin {
        ultiBetsRandomGen = _ultiBetsRandomGen;
    }

    function setNoticeBetTime(uint16 _noticeTime) public onlyAdmin {
        noticeBetTime = _noticeTime;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ISBCNFTType {
    enum NFTType {
        Normal,
        UTBETS,
        Warrior
    }
}