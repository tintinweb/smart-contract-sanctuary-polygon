// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
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
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

        /// @solidity memory-safe-assembly
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
     * @dev Returns the number of values in the set. O(1).
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Array {
    function removeElement(uint256[] storage _array, uint256 _element) internal {
        for (uint256 i; i<_array.length; i++) {
            if (_array[i] == _element) {
                _array[i] = _array[_array.length - 1];
                _array.pop();
                break;
            }
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./AtiumPlan.sol";
import "./Array.sol";

error Atium_NotAmount();
error Atium_NotReceiverId();
error Atium_SavingsGoal_Not_Hit();
error Atium_NoWithdrawal();
error Atium_TransactionFailed();
error Atium_Cancelled();
error Atium_SavingsGoal_Exceeded(uint256 goal, uint256 rem);

contract Atium is AtiumPlan {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;
    using Array for uint256[];

    mapping(uint256 => bool) private savingsCancelled;
    mapping(uint256 => bool) private allowanceCancelled;
    mapping(uint256 => bool) private trustfundCancelled;
    mapping(uint256 => bool) private giftCancelled;

    mapping(uint256 => uint256) private allowanceBalance;
    mapping(uint256 => uint256) private trustfundBalance;


    ///////////////////////////////////////////////////////
    ///////////////// DEPOSIT FUNCTIONS ///////////////////
    ///////////////////////////////////////////////////////

    function save(uint256 _id, uint256 _amount) external payable inSavings(_id) {
        if (_id == 0 || _amount == 0) {
            revert Atium_ZeroInput();
        }
        if (msg.value != _amount) {
            revert Atium_NotAmount();
        }
        if (_amount + savingsById[_id].amount > savingsById[_id].goal) {
            revert Atium_SavingsGoal_Exceeded({
                goal: savingsById[_id].goal,
                rem: savingsById[_id].goal - savingsById[_id].amount
            });
        }
 
        savingsById[_id].amount += _amount;


        addrToActiveAllowance[msg.sender].remove(_id);    
        addrToActiveAllowance[msg.sender].add(_id); 

        (bool sent, ) = payable(address(this)).call{value: msg.value}("");
        if (!sent) {
            revert Atium_TransactionFailed();
        }
    }

    function allowance(uint256 _id, uint256 _amount) external payable inAllowance(_id) {
        if (_id == 0 || _amount == 0) {
            revert Atium_ZeroInput();
        }
        if (msg.value != _amount) {
            revert Atium_NotAmount();
        }

        allowanceById[_id].deposit += _amount;
        allowanceBalance[_id] += _amount;

        addrToActiveAllowance[msg.sender].remove(_id);    
        addrToActiveAllowance[msg.sender].add(_id); 

        (bool sent, ) = payable(address(this)).call{value: msg.value}("");
        if (!sent) {
            revert Atium_TransactionFailed();
        }
    }

    function trustfund(uint256 _id, uint256 _amount) external payable inTrustfund(_id) {
        if (_id == 0 || _amount == 0) {
            revert Atium_ZeroInput();
        }
        if (msg.value != _amount) {
            revert Atium_NotAmount();
        }

        trustfundById[_id].amount += _amount;
        trustfundBalance[_id] += _amount;

        addrToActiveTrustfund[msg.sender].remove(_id);    
        addrToActiveTrustfund[msg.sender].add(_id); 

        (bool sent, ) = payable(address(this)).call{value: msg.value}("");
        if (!sent) {
            revert Atium_TransactionFailed();
        }
    }

    function gift(uint256 _id, uint256 _amount) external payable inGift(_id) {
        if (_id == 0 || _amount == 0) {
            revert Atium_ZeroInput();
        }
        if (msg.value != _amount) {
            revert Atium_NotAmount();
        }

        giftById[_id].amount += _amount;

        addrToActiveGift[msg.sender].remove(_id);    
        addrToActiveGift[msg.sender].add(_id);

        (bool sent, ) = payable(address(this)).call{value: msg.value}("");
        if (!sent) {
            revert Atium_TransactionFailed();
        }
    }


    ///////////////////////////////////////////////////////////
    //////////// (RECEIVER) WITHDRAWAL FUNCTIONS //////////////
    ///////////////////////////////////////////////////////////

    function w_save(uint256 _id) external {
        if (savingsById[_id].amount < savingsById[_id].goal || block.timestamp < savingsById[_id].time) {
            revert Atium_SavingsGoal_Not_Hit();
        }
        if (savingsCancelled[_id]) {
            revert Atium_Cancelled();
        }
        userS_Ids[savingsById[_id].user].removeElement(_id);
        savingsCancelled[_id] = true;
        addrToActiveAllowance[savingsById[_id].user].remove(_id);

        (bool sent, ) = payable(savingsById[_id].user).call{value: savingsById[_id].amount}("");
        if (!sent) {
            revert Atium_TransactionFailed();
        }
    }

    function w_allowance(uint256 _id) external {
        uint256 witAmount;
        
        if (allowanceBalance[_id] == 0) {
            revert Atium_NoWithdrawal();
        }

        uint256 a = block.timestamp;
        uint256 b = allowanceDate[_id];
        uint256 c = allowanceById[_id].withdrawalInterval;

        if ((a - b) < c) {
            revert Atium_OnlyFutureDate();
        }

        uint256 d = (a - b) / c;
        allowanceDate[_id] += (d * c);
        
        if (allowanceBalance[_id] < allowanceById[_id].withdrawalAmount) {
            witAmount = allowanceBalance[_id];
        }

        if (allowanceBalance[_id] >= allowanceById[_id].withdrawalAmount) {
            witAmount = d * allowanceById[_id].withdrawalAmount;
        }

        allowanceBalance[_id] -= witAmount;
        addrToActiveAllowance[allowanceById[_id].receiver].remove(_id);    
        addrToActiveAllowance[allowanceById[_id].receiver].add(_id);

        (bool sent, ) = payable(allowanceById[_id].receiver).call{value: witAmount}("");
        if (!sent) {
            revert Atium_TransactionFailed();
        }
    }

    function w_trustfund(uint256 _id) external {
        uint256 witAmount;

        if (trustfundBalance[_id] == 0) {
            revert Atium_NoWithdrawal();
        }

        uint256 a = trustfundById[_id].startDate;
        uint256 b = trustfundDate[_id];
        uint256 c = trustfundById[_id].withdrawalInterval;

        uint256 d = (a - b) / c;
        trustfundDate[_id] += (d * c);

        if (trustfundBalance[_id] < trustfundById[_id].withdrawalAmount) {
            witAmount = trustfundBalance[_id];
        }

        if (trustfundBalance[_id] >= trustfundById[_id].withdrawalAmount) {
            witAmount = d * trustfundById[_id].withdrawalAmount;
        }

        trustfundBalance[_id] -= witAmount;
        addrToActiveTrustfund[trustfundById[_id].receiver].remove(_id);    
        addrToActiveTrustfund[trustfundById[_id].receiver].add(_id); 
        (bool sent, ) = payable(trustfundById[_id].receiver).call{value: witAmount}("");
        if (!sent) {
            revert Atium_TransactionFailed();
        }
    }

    function w_gift(uint256 _id) external {
        userG_Ids[giftById[_id].receiver].removeElement(_id);

        giftCancelled[_id] = true;
        addrToActiveGift[giftById[_id].receiver].remove(_id);    

        (bool sent, ) = payable(giftById[_id].receiver).call{value: giftById[_id].amount}("");
        if (!sent) {
            revert Atium_TransactionFailed();
        }
    }


    ///////////////////////////////////////////////////////
    ///////////////// GETTERS FUNCTIONS  //////////////////
    ///////////////////////////////////////////////////////

    function getSavingsBalance(uint256 _id) public view returns (uint256) {
        return savingsById[_id].amount;
    }

    function getAllowanceBalance(uint256 _id) public view returns (uint256) {
        return allowanceBalance[_id];
    }

    function getTrustfundBalance(uint256 _id) public view returns (uint256) {
        return trustfundBalance[_id];
    }

    function getGiftBalance(uint256 _id) public view returns (uint256) {
        return giftById[_id].amount;     
    }

    receive() payable external {}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

error Atium_NotOwnerId();
error Atium_OnlyFutureDate();
error Atium_ZeroInput();

contract AtiumPlan {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;

    Counters.Counter private _atiumId;
    Counters.Counter private _savingsId;
    Counters.Counter private _allowanceId;
    Counters.Counter private _trustfundId;
    Counters.Counter private _giftId;

    

    mapping(uint256 => AtiumList) internal atiumById;
    mapping(uint256 => SavingsList) internal savingsById;
    mapping(uint256 => AllowanceList) internal allowanceById;
    mapping(uint256 => TrustFundList) internal trustfundById;
    mapping(uint256 => GiftList) internal giftById;

    mapping(address => uint256[]) internal userS_Ids;
    mapping(address => uint256[]) internal userA_Ids;
    mapping(address => uint256[]) internal userT_Ids;
    mapping(address => uint256[]) internal userG_Ids;

    mapping(address => EnumerableSet.UintSet) internal addrToActiveSavings;
    mapping(address => EnumerableSet.UintSet) internal addrToActiveAllowance;
    mapping(address => EnumerableSet.UintSet) internal addrToActiveTrustfund;
    mapping(address => EnumerableSet.UintSet) internal addrToActiveGift;

    mapping(address => uint256[]) internal receiverA_Ids;
    mapping(address => uint256[]) internal receiverT_Ids;
    mapping(address => uint256[]) internal receiverG_Ids;


    mapping(uint256 => uint256) internal allowanceDate;
    mapping(uint256 => uint256) internal trustfundDate;

    enum Select {SAVINGS, ALLOWANCE, TRUSTFUND, GIFT}
    //SAVINGS = 0, ALLOWANCE = 1, TRUSTFUND = 2. GIFT = 3

    struct AtiumList {
        uint256 id;
        address user;
        Select select;
    }

    struct SavingsList {
        uint256 id;
        address user;
        uint256 amount;
        uint256 goal;
        uint256 time;
    }

    struct AllowanceList {
        uint256 id;
        address sender;
        address receiver;
        uint256 deposit;
        uint256 startDate;
        uint256 withdrawalAmount;
        uint256 withdrawalInterval;
    }

    struct TrustFundList {
        uint256 id;
        address sender;
        address receiver;
        uint256 amount;
        uint256 startDate;
        uint256 withdrawalAmount;
        uint256 withdrawalInterval;
    }

    struct GiftList {
        uint256 id;
        address sender;
        address receiver;
        uint256 date;
        uint256 amount;
    }

    /////////////////////////////////////////////////////////
    /////////////////  ATIUM PLANS FUNCTIONS  ///////////////
    /////////////////////////////////////////////////////////

    function savingsPlanGoal(uint256 _goal) external {
        if (_goal == 0) {
            revert Atium_ZeroInput();
        }
        _atiumId.increment();
        _savingsId.increment();

        AtiumList memory a = AtiumList ({
            id: _atiumId.current(),
            user: msg.sender,
            select: Select.SAVINGS
        });

        SavingsList memory s = SavingsList ({
            id: _savingsId.current(),
            user: msg.sender,
            amount: savingsById[_savingsId.current()].amount,
            goal: _goal,
            time: 0
        });

        atiumById[_atiumId.current()] = a;
        savingsById[_savingsId.current()] = s;
        userS_Ids[msg.sender].push(_savingsId.current());

        addrToActiveSavings[msg.sender].add(s.id);
    }

    function savingsPlanTime(uint256 _time) external {
        if (_time == 0) {
            revert Atium_ZeroInput();
        }
        _atiumId.increment();
        _savingsId.increment();
        _time += block.timestamp;

        AtiumList memory a = AtiumList ({
            id: _atiumId.current(),
            user: msg.sender,
            select: Select.SAVINGS
        });

        SavingsList memory s = SavingsList ({
            id: _savingsId.current(),
            user: msg.sender,
            amount: savingsById[_savingsId.current()].amount,
            goal: 0,
            time: _time
        });

        atiumById[_atiumId.current()] = a;
        savingsById[_savingsId.current()] = s;
        userS_Ids[msg.sender].push(_savingsId.current());

        addrToActiveSavings[msg.sender].add(s.id);
    }

    function allowancePlan(
        address _receiver, 
        uint256 _startDate, 
        uint256 _amount, 
        uint256 _interval
        ) external {
        
        if (_receiver == address(0) || _startDate == 0 || _amount == 0 || _interval == 0) {
            revert Atium_ZeroInput();
        }

        _atiumId.increment();
        _allowanceId.increment();
        _startDate += block.timestamp;

        AtiumList memory a = AtiumList ({
            id: _atiumId.current(),
            user: msg.sender,
            select: Select.ALLOWANCE
        });

        AllowanceList memory al = AllowanceList ({
            id: _allowanceId.current(),
            sender: msg.sender,
            receiver: _receiver,
            deposit: allowanceById[_allowanceId.current()].deposit,
            startDate: _startDate,
            withdrawalAmount: _amount,
            withdrawalInterval: _interval
        });

        atiumById[_atiumId.current()] = a;
        allowanceById[_allowanceId.current()] = al;
        allowanceDate[_allowanceId.current()] = _startDate;
        userA_Ids[msg.sender].push(_allowanceId.current());
        receiverA_Ids[_receiver].push(_allowanceId.current());

        addrToActiveAllowance[msg.sender].add(al.id);
    }

    function trustfundPlan(
        address _receiver, 
        uint256 _startDate, 
        uint256 _amount, 
        uint256 _interval
        ) external {

        if (_receiver == address(0) || _startDate == 0 || _amount == 0 || _interval == 0) {
            revert Atium_ZeroInput();
        }

        _atiumId.increment();
        _trustfundId.increment();
        _startDate += block.timestamp;

        AtiumList memory a = AtiumList ({
            id: _atiumId.current(),
            user: msg.sender,
            select: Select.TRUSTFUND
        });

        TrustFundList memory t = TrustFundList ({
            id: _trustfundId.current(),
            sender: msg.sender,
            receiver: _receiver,
            amount: trustfundById[_trustfundId.current()].amount,
            startDate: _startDate,
            withdrawalAmount: _amount,
            withdrawalInterval: _interval
        });

        atiumById[_atiumId.current()] = a;
        trustfundById[_trustfundId.current()] = t;
        trustfundDate[_trustfundId.current()] = _startDate;
        userT_Ids[msg.sender].push(_trustfundId.current());
        receiverT_Ids[_receiver].push(_trustfundId.current());

        addrToActiveTrustfund[msg.sender].add(t.id);
    }

    function giftPlan(address _receiver, uint256 _date) external {

        if (_receiver == address(0) || _date == 0) {
            revert Atium_ZeroInput();
        }

        _atiumId.increment();
        _giftId.increment();
        _date += block.timestamp;

        AtiumList memory a = AtiumList ({
            id: _atiumId.current(),
            user: msg.sender,
            select: Select.GIFT
        });

        GiftList memory g = GiftList ({
            id: _giftId.current(),
            sender: msg.sender,
            receiver: _receiver,
            amount: giftById[_giftId.current()].amount,
            date: _date
        });

        atiumById[_atiumId.current()] = a;
        giftById[_giftId.current()] = g;
        userG_Ids[msg.sender].push(_giftId.current());
        receiverG_Ids[_receiver].push(_giftId.current());

        addrToActiveGift[msg.sender].add(g.id);
    }

    /////////////////////////////////////////////////////
    ////////////// EDIT/UPDATE ATIUM PLANS //////////////
    /////////////////////////////////////////////////////

    function editSavingsPlanGoal(uint256 _id, uint256 _goal) public inSavings(_id) {

        SavingsList memory s = SavingsList ({
            id: _id,
            user: msg.sender,
            amount: savingsById[_id].amount,
            goal: _goal,
            time: 0
        });

        savingsById[_id] = s;

        addrToActiveSavings[msg.sender].remove(_id);    
        addrToActiveSavings[msg.sender].add(_id); 
    }

    function editSavingsPlanTime(uint256 _id, uint256 _time) public inSavings(_id) {

        _time += block.timestamp;

        SavingsList memory s = SavingsList ({
            id: _id,
            user: msg.sender,
            amount: savingsById[_id].amount,
            goal: 0,
            time: _time
        });

        savingsById[_id] = s;

        addrToActiveSavings[msg.sender].remove(_id);    
        addrToActiveSavings[msg.sender].add(_id);
    }

    function editAllowancePlan(
        uint256 _id, 
        address _receiver, 
        uint256 _startDate, 
        uint256 _amount, 
        uint256 _interval
        ) external inAllowance(_id) {

        _startDate += block.timestamp;

        AllowanceList memory al = AllowanceList ({
            id: _id,
            sender: msg.sender,
            receiver: _receiver,
            deposit: allowanceById[_id].deposit,
            startDate: _startDate += block.timestamp,
            withdrawalAmount: _amount,
            withdrawalInterval: _interval
        });

        allowanceById[_id] = al;
        allowanceDate[_id] = _startDate;

        addrToActiveAllowance[msg.sender].remove(_id);    
        addrToActiveAllowance[msg.sender].add(_id); 
    }

    function editTrustfundPlan(
        uint256 _id, 
        address _receiver, 
        uint256 _startDate, 
        uint256 _amount, 
        uint256 _interval
        ) external inTrustfund(_id) {

        _startDate += block.timestamp;

        TrustFundList memory t = TrustFundList ({
            id: _id,
            sender: msg.sender,
            receiver: _receiver,
            amount: trustfundById[_id].amount,
            startDate: _startDate,
            withdrawalAmount: _amount,
            withdrawalInterval: _interval
        });

        trustfundById[_id] = t;
        trustfundDate[_id] = _startDate;

        addrToActiveTrustfund[msg.sender].remove(_id);    
        addrToActiveTrustfund[msg.sender].add(_id); 
    }

    function editGiftPlan(uint256 _id, address _receiver, uint256 _date) external inGift(_id) {

        _date += block.timestamp;

        GiftList memory g = GiftList ({
            id: _id,
            sender: msg.sender,
            receiver: _receiver,
            amount: giftById[_id].amount,
            date: _date
        });

        giftById[_id] = g;

        addrToActiveGift[msg.sender].remove(_id);    
        addrToActiveGift[msg.sender].add(_id); 
    }

    /////////////////////////////////////////////////////
    ///////////////  GETTER FUNCTIONS ///////////////////
    /////////////////////////////////////////////////////

    function getAtium(uint256 _id) public view returns (AtiumList memory) {
        return atiumById[_id];
    }

    function getSavings(uint256 _id) public view returns (SavingsList memory) {
        return savingsById[_id];
    }

    function getAllowance(uint256 _id) public view returns (AllowanceList memory) {
        return allowanceById[_id];
    }

    function getTrustfund(uint256 _id) public view returns (TrustFundList memory) {
        return trustfundById[_id];
    }

    function getGift(uint256 _id) public view returns (GiftList memory) {
        return giftById[_id];
    }

    ///@notice - Get all active user savings
    function getAllActiveSavings() external view returns (SavingsList[] memory) {
        uint256[] memory allActiveSavings = userS_Ids[msg.sender];
        uint256 length = allActiveSavings.length;
        SavingsList[] memory allSavings = new SavingsList[](length);

        for (uint i = 0; i < length; ) {
            allSavings[i] = savingsById[allActiveSavings[i]];
            unchecked {
                ++i;
            }
        }

        return allSavings;
    }

    function getAllActiveAllowance() external view returns (AllowanceList[] memory) {
        uint256[] memory allActiveAllowance = userA_Ids[msg.sender];
        uint256 length = allActiveAllowance.length;
        AllowanceList[] memory allAllowance = new AllowanceList[](length);

        for (uint i = 0; i < length; ) {
            allAllowance[i] = allowanceById[allActiveAllowance[i]];
            unchecked {
                ++i;
            }
        }

        return allAllowance;
    }

    function getAllActiveTrustfund() external view returns (TrustFundList[] memory) {
        uint256[] memory allActiveTrustfund = userT_Ids[msg.sender];
        uint256 length = allActiveTrustfund.length;
        TrustFundList[] memory allTrustfund = new TrustFundList[](length);

        for (uint i = 0; i < length; ) {
            allTrustfund[i] = trustfundById[allActiveTrustfund[i]];
            unchecked {
                ++i;
            }
        }

        return allTrustfund;
    }

    function getAllActiveGift() external view returns (GiftList[] memory) {
        uint256[] memory allActiveGift = userG_Ids[msg.sender];
        uint256 length = allActiveGift.length;
        GiftList[] memory allGift = new GiftList[](length);

        for (uint i = 0; i < length; ) {
            allGift[i] = giftById[allActiveGift[i]];
            unchecked {
                ++i;
            }
        }

        return allGift;
    }

    ////////////////////////////////////////////////////
    ///////////////////  MODIFIERS  ////////////////////
    ////////////////////////////////////////////////////

    modifier inSavings(uint256 _id) {
        if (savingsById[_id].user != msg.sender) {
            revert Atium_NotOwnerId();
        }
        _;
    }

    modifier inAllowance(uint256 _id) {
        if (allowanceById[_id].sender != msg.sender) {
            revert Atium_NotOwnerId();
        }
        _;
    }

    modifier inTrustfund(uint256 _id) {
        if (trustfundById[_id].sender != msg.sender) {
            revert Atium_NotOwnerId();
        }
        _;
    }

    modifier inGift(uint256 _id) {
        if (giftById[_id].sender != msg.sender) {
            revert Atium_NotOwnerId();
        }
        _;
    }
}