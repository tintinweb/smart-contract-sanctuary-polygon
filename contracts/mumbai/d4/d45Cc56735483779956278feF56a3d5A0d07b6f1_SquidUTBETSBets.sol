// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../Utils/CustomAdmin.sol";
import "../Interface/IUltiBetsToken.sol";
import "../Utils/SquidBetsCore.sol";

contract SquidUTBETSBets is SquidBetsCore {
    using EnumerableSet for EnumerableSet.AddressSet;

    IUltiBetsToken private ultibetsToken;

    address public signer;
    mapping(address => uint256) nonces;

    mapping(uint256 => bool) public isWarriorEvent;

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
        uint256 firstRound = eventData[_eventID].firstRound;
        require(
            !playersByRound[firstRound].contains(msg.sender),
            "You are already registered for the Squid Bet Competition"
        );
        require(
            eventData[_eventID].state == EventState.RegisterStart,
            "Can't regist for now!"
        );
        require(
            eventData[_eventID].maxPlayers > eventData[_eventID].totalPlayers,
            "Max number of players has been reached"
        );

        eventData[_eventID].totalPlayers++;
        registerIDOfBettor[msg.sender][_eventID] = eventData[_eventID]
            .totalPlayers;
        playersByRound[eventData[_eventID].firstRound].add(msg.sender);
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
        bytes32 messageHash = getMessageHash(_bettor, _eventID);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == signer;
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
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

        // implicitly return (r, s, v)
    }

    function setSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    /////////////////////////////

    function registerOnEvent(uint256 _eventID) external {
        require(
            !isWarriorEvent[_eventID],
            "Can't call this function for warrior sbc!"
        );
        uint256 firstRound = eventData[_eventID].firstRound;
        uint256 amount = eventData[_eventID].registerAmount;
        require(
            !playersByRound[firstRound].contains(msg.sender),
            "You are already registered for the Squid Bet Competition"
        );
        require(
            eventData[_eventID].state == EventState.RegisterStart,
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

        playersByRound[eventData[_eventID].firstRound].add(msg.sender);
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
        ultibetsToken.transfer(UltibetsBetTreasury, amount / 2);
        ultibetsToken.transfer(UltibetsBuyBack, amount / 2);
    }

    function transferTotalEntryFeestoPrizePool(uint256 _eventID) public onlyAdmin {
        require(
            eventData[_eventID].state != EventState.RegisterStart,
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

    ///@notice function to place bets
    ///@param _roundID is the roundID, _result is the decision

    function placeBet(uint256 _roundID, RoundResult _result) external {
        uint256 eventId = roundData[_roundID].eventID;
        uint256 amount = eventData[eventId].roundBetAmount;
        require(
            roundData[_roundID].state == RoundState.Active ||
                roundData[_roundID].state == RoundState.ReActive,
            "Non available state!"
        );
        require(
            playersByRound[_roundID].contains(msg.sender),
            "You can't bet on that round!"
        );
        require(!isBetOnRound[msg.sender][_roundID], "Bet placed already");
        require(
            ultibetsToken.balanceOf(msg.sender) >= amount,
            "Not enough to bet on the round!"
        );

        require(_result != RoundResult.Indeterminate, "Invalid Bet!");

        ultibetsToken.approveOrg(address(this), amount);
        ultibetsToken.transferFrom(msg.sender, address(this), amount);

        isBetOnRound[msg.sender][_roundID] = true;
        betByBettor[msg.sender][_roundID] = _result;
        eventData[roundData[_roundID].eventID].totalAmount += amount;
        roundData[_roundID].bettingAmount += amount;

        bool isWarrior = isWarriorEvent[roundData[_roundID].eventID];

        if (roundData[_roundID].state == RoundState.Active) {
            setNFTClaimable(
                msg.sender,
                _roundID,
                eventId,
                false,
                roundData[_roundID].date,
                isWarrior
            );
        }

        emit BetPlaced(msg.sender, _roundID, amount, block.timestamp);
    }

    ///@notice function to withdraw bet amount when bet is stopped in emergency
    function claimBetCanceledRound(uint256 _roundID) external {
        require(
            roundData[_roundID].state == RoundState.Canceled,
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

        uint256 roundFee = eventData[roundData[_roundID].eventID]
            .roundBetAmount;
        roundData[_roundID].bettingAmount -= roundFee;
        eventData[roundData[_roundID].eventID].totalAmount -= roundFee;

        ultibetsToken.transfer(msg.sender, roundFee);
    }

    function refund(address _receiver, uint256 _amount) internal override {
        ultibetsToken.transfer(_receiver, _amount);
    }

    /// @notice function to report bet result

    function reportResult(
        uint256 _roundID,
        RoundResult _result
    ) public override {
        super.reportResult(_roundID, _result);
        ultibetsToken.transfer(prizePool, roundData[_roundID].bettingAmount);
    }

    function pickWinner(uint256 _eventID) public onlyAdmin {
        require(
            eventData[_eventID].vResult == VotingResult.Solo ||
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
        uint256 roundId = eventData[_eventID].currentRound;
        bool isWarrior = isWarriorEvent[_eventID];

        if (winnersOfFinalRound[_eventID].length() == 1) {
            winner = winnersOfFinalRound[_eventID].at(0);
            setNFTClaimable(
                winner,
                eventData[_eventID].currentRound,
                _eventID,
                true,
                roundData[roundId].date,
                isWarrior
            );
        } else {
            uint256 rand = ISquidBetRandomGen(betRandomGenerator)
                .getRandomNumber();
            uint256 _winnerNumber = rand %
                winnersOfFinalRound[_eventID].length();
            winner = winnersOfFinalRound[_eventID].at(_winnerNumber);
            setNFTClaimable(
                winner,
                eventData[_eventID].currentRound,
                _eventID,
                true,
                roundData[roundId].date + 1 days,
                isWarrior
            );
        }

        selectedWinnerOfVote[_eventID] = winner;
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

contract SquidBetsCore is CustomAdmin {
    using EnumerableSet for EnumerableSet.AddressSet;

    ISquidBetNFTClaimer private claimerContract;

    enum EventState {
        Inactive,
        RegisterStart,
        OnRound,
        OnVote,
        FinishVote,
        Finished
    }

    enum RoundState {
        Active,
        Canceled,
        ReActive,
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
        uint256 eventID;
        string description;
        uint256 firstRound;
        uint256 currentRound;
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
        uint256 bettingAmount;
        string description;
        uint256 date;
        RoundResult result;
        uint8 level; //1 -> round1 2->round2
        RoundState state;
    }

    uint256 public totalEventNumber;
    uint256 public totalRoundNumber;

    address public prizePool; /// address of the squidBetsPrizePool contract
    address public UltibetsBetTreasury; /// address of the UltibetsBetTreasury contract
    address public UltibetsBuyBack; /// address of the UltibetsBuyback contract

    address public betRandomGenerator;

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

    /* functions to manage event on admin side */
    function createNewEvent(
        string memory _desc,
        uint256 _maxPlayers,
        uint256 _registerFee,
        uint8 _totalRound,
        uint256 _roundFee,
        uint8 _orgFeePercent
    ) external virtual onlyAdmin {
        totalEventNumber++;
        eventData[totalEventNumber] = EventInfo(
            totalEventNumber,
            _desc,
            totalRoundNumber + 1,
            totalRoundNumber,
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

        emit EventCreated(totalEventNumber);
    }

    function openEvent(uint256 _eventID) public onlyAdmin {
        eventData[_eventID].state = EventState.RegisterStart;

        emit RegisterStarted(_eventID);
    }

    function finishEvent(uint256 _eventID) public onlyAdmin {
        eventData[_eventID].state = EventState.Finished;

        emit EventFinished(_eventID);
    }

    function finishRegist(uint256 _eventID) public onlyAdmin {
        eventData[_eventID].state = EventState.OnRound;

        emit RegisterStopped(_eventID);
    }

    function voteEvent(uint256 _eventID) public onlyAdmin {
        eventData[_eventID].state = EventState.OnVote;

        emit VoteStarted(_eventID);
    }

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

    function addRound(uint256 _eventID, string memory _desc) public onlyAdmin {
        uint256 currentRound = eventData[_eventID].currentRound;
        require(
            eventData[_eventID].state == EventState.OnRound,
            "Can't add round to this event for now!"
        );
        require(
            roundData[currentRound].level + 1 <= eventData[_eventID].totalRound,
            "Can't exceed total round number."
        );
        require(
            eventData[_eventID].firstRound > eventData[_eventID].currentRound ||
                roundData[currentRound].state == RoundState.Finished,
            "Current Rounds is not finished yet."
        );
        totalRoundNumber++;
        roundData[totalRoundNumber] = RoundInfo(
            totalRoundNumber,
            _eventID,
            0,
            _desc,
            block.timestamp,
            RoundResult.Indeterminate,
            roundData[currentRound].level + 1,
            RoundState.Active
        );

        eventData[_eventID].currentRound = totalRoundNumber;
    }

    function cancelRound(uint256 _roundID, uint256 _deadline) public onlyAdmin {
        roundData[_roundID].state = RoundState.Canceled;
        deadlineOfCancelRound[_roundID] = _deadline;

        emit RoundCanceled(_roundID, _deadline);
    }

    function finishRound(uint256 _roundID) public onlyAdmin {
        roundData[_roundID].state = RoundState.Finished;

        emit RoundFinished(_roundID);
    }

    function getRoundBalance(uint256 _roundID) public view returns (uint256) {
        return roundData[_roundID].bettingAmount;
    }

    function getResult(
        uint256 _roundID
    ) public view returns (RoundResult _win) {
        _win = roundData[_roundID].result;
    }

    function reActiveRound(
        uint256 _roundID,
        string memory _desc
    ) public onlyAdmin {
        require(
            roundData[_roundID].state == RoundState.Canceled,
            "That is not canceled round!"
        );
        roundData[_roundID].bettingAmount = 0;
        roundData[_roundID].description = _desc;
        roundData[_roundID].state = RoundState.ReActive;

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
        require(
            deadlineOfCancelRound[_roundID] < block.timestamp,
            "Not reach out deadline yet."
        );
        require(
            roundData[_roundID].state == RoundState.Canceled,
            "Not canceled round."
        );
        address[] memory list = unclaimCanceleEnvetBettorsList(_roundID);
        uint256 roundFee = eventData[roundData[_roundID].eventID]
            .roundBetAmount;
        for (uint256 i; i < list.length; i++) {
            refund(list[i], roundFee);
            isBetOnRound[list[i]][_roundID] = false;
            playersByRound[_roundID].remove(list[i]);
        }
    }

    function refund(address _receiver, uint256 _amount) internal virtual {
        payable(_receiver).transfer(_amount);
    }

    function unclaimCanceleEnvetBettorsList(
        uint256 _roundID
    ) public view returns (address[] memory) {
        uint256 roundFee = eventData[roundData[_roundID].eventID]
            .roundBetAmount;
        uint256 numberOfBettors = roundData[_roundID].bettingAmount / roundFee;
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

    function reportResult(
        uint256 _roundID,
        RoundResult _result
    ) public virtual OnlyOracle {
        require(
            roundData[_roundID].state == RoundState.Finished,
            "event must be stopped first"
        );
        require(_result != RoundResult.Indeterminate, "Invalid result value.");

        roundData[_roundID].result = _result;

        for (uint256 i; i < playersByRound[_roundID].length(); i++) {
            if (
                betByBettor[playersByRound[_roundID].at(i)][_roundID] == _result
            ) {
                if (
                    roundData[_roundID].level !=
                    eventData[roundData[_roundID].eventID].totalRound
                )
                    playersByRound[_roundID + 1].add(
                        playersByRound[_roundID].at(i)
                    );
                else
                    winnersOfFinalRound[roundData[_roundID].eventID].add(
                        playersByRound[_roundID].at(i)
                    );
            }
        }

        emit Results(_roundID, _result);
    }

    /// @notice function for bettors to  vote for preferred choice
    /// @param _playerVote enter 1 to equally split Prize Pool, 2 to randomly pick a sole winner

    function Vote(uint8 _playerVote, uint256 _eventID) external {
        require(
            eventData[_eventID].state == EventState.OnVote,
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
        eventData[_eventID].state = EventState.FinishVote;
        emit VoteFinished(_eventID);
    }

    function setRandomGenerator(address _betRandomGenerator) public onlyAdmin {
        betRandomGenerator = _betRandomGenerator;
    }

    /// @notice function for admin to report voting results

    function resultVote(uint256 _eventID) external onlyAdmin {
        stopVote(_eventID);

        if (eventVote[_eventID] > 0) {
            eventData[_eventID].vResult = VotingResult.Split;
            for (uint256 i; i < winnersOfFinalRound[_eventID].length(); i++) {
                uint256 roundId = eventData[_eventID].currentRound;
                setNFTClaimable(
                    winnersOfFinalRound[_eventID].at(i),
                    roundId,
                    _eventID,
                    true,
                    roundData[roundId].date + 1 days,
                    false
                );
            }
        } else {
            eventData[_eventID].vResult = VotingResult.Solo;
        }
    }

    function getWinners(
        uint256 _eventID
    ) public view returns (address[] memory) {
        VotingResult result = eventData[_eventID].vResult;
        require(result != VotingResult.Indeterminate, "No result for now.");
        address[] memory winners;
        if (eventData[_eventID].vResult == VotingResult.Split) {
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

    function isClaimable(
        address _bettor,
        uint256 _eventID
    ) public view returns (bool) {
        VotingResult result = eventData[_eventID].vResult;
        require(result != VotingResult.Indeterminate, "No result for now.");
        if (!playersClaimReward[_bettor][_eventID]) {
            if (result == VotingResult.Split) {
                return winnersOfFinalRound[_eventID].contains(_bettor);
            } else {
                return _bettor == selectedWinnerOfVote[_eventID];
            }
        } else return false;
    }

    function winnersClaimPrize(uint256 _eventID) public {
        require(isClaimable(msg.sender, _eventID), "You are not claimable.");
        uint256 prize = eventData[_eventID].totalAmount /
            getWinners(_eventID).length;
        playersClaimReward[msg.sender][_eventID] = true;
        ISquidBetPrizePool(prizePool).winnerClaimPrizePool(msg.sender, prize);
    }

    function getRegisterID(
        uint256 _eventID,
        address _bettor
    ) public view returns (uint16) {
        return registerIDOfBettor[_bettor][_eventID];
    }

    function getPlayersByRound(
        uint256 _roundID
    ) public view returns (address[] memory) {
        address[] memory bettors = new address[](
            playersByRound[_roundID].length()
        );
        for (uint256 i; i < playersByRound[_roundID].length(); i++) {
            bettors[i] = playersByRound[_roundID].at(i);
        }
        return bettors;
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

    function setNFTClaimable(
        address bettor,
        uint256 _roundID,
        uint256 _eventId,
        bool _isFinal,
        uint256 _date,
        bool _isWarrior
    ) internal {
        if (_isFinal) {
            claimerContract.setSBCNFTClaimable(
                bettor,
                0,
                _eventId,
                _date,
                uint16(playersByRound[_roundID].length()),
                eventData[_eventId].totalPlayers,
                true,
                _isWarrior
            );
        } else {
            claimerContract.setSBCNFTClaimable(
                bettor,
                roundData[_roundID].level,
                _eventId,
                _date,
                uint16(playersByRound[_roundID].length()),
                eventData[_eventId].totalPlayers,
                true,
                _isWarrior
            );
        }
    }

    function setUltibetsBuyBack(address _buyback) external onlyAdmin {
        UltibetsBuyBack = _buyback;
    }

    function setClaimerContract(ISquidBetNFTClaimer _claimer) public onlyAdmin {
        claimerContract = _claimer;
    }

    function getEventList(
        uint256 _pageNumber,
        uint256 _pageSize
    ) external view returns (EventInfo[] memory) {
        require(
            (_pageNumber - 1) * _pageSize < totalEventNumber,
            "Invalid Params!"
        );

        uint256 numberOfEvents;
        if (totalEventNumber < _pageNumber * _pageSize) {
            numberOfEvents = totalEventNumber - (_pageNumber - 1) * _pageSize;
        } else {
            numberOfEvents = _pageSize;
        }

        EventInfo[] memory events = new EventInfo[](numberOfEvents);

        for (uint i; i < numberOfEvents; i++) {
            events[i] = eventData[(_pageNumber - 1) * totalEventNumber + i + 1];
        }

        return events;
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