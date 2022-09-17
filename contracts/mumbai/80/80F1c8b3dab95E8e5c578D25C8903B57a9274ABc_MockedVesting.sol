// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;
pragma experimental ABIEncoderV2;

import "../Vesting.sol";

contract MockedVesting is Vesting {
    uint256 public mockedTimestamp;

    constructor(address token_, address owner_) Vesting(token_, owner_) {
        mockedTimestamp = block.timestamp;
    }

    function increaseTime(uint256 count) external onlyOwnerOrOperator returns (bool) {
        mockedTimestamp += count;
        return true;
    }

    function getTimestamp() internal override(Vesting) view returns (uint256) {
        return mockedTimestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

abstract contract TwoStageOwnable {
    address private _nominatedOwner;
    address private _owner;

    function nominatedOwner() public view returns (address) {
        return _nominatedOwner;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    event OwnerChanged(address indexed newOwner);
    event OwnerNominated(address indexed nominatedOwner);

    constructor(address owner_) {
        require(owner_ != address(0), "Owner is zero");
        _setOwner(owner_);
    }

    function acceptOwnership() external returns (bool success) {
        require(msg.sender == _nominatedOwner, "Not nominated to ownership");
        _setOwner(_nominatedOwner);
        return true;
    }

    function nominateNewOwner(address owner_) external onlyOwner returns (bool success) {
        _nominateNewOwner(owner_);
        return true;
    }

    modifier onlyOwner {
        require(msg.sender == _owner, "Not owner");
        _;
    }

    function _nominateNewOwner(address owner_) internal {
        if (_nominatedOwner == owner_) return;
        require(_owner != owner_, "Already owner");
        _nominatedOwner = owner_;
        emit OwnerNominated(owner_);
    }

    function _setOwner(address newOwner) internal {
        if (_owner == newOwner) return;
        _owner = newOwner;
        _nominatedOwner = address(0);
        emit OwnerChanged(newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/utils/Context.sol";
import "./TwoStageOwnable.sol";

abstract contract Operator is TwoStageOwnable {
    address private _operator;

    function operator() public virtual view returns (address) {
        return _operator;
    }

    event OperatorUpdated(address operator_);

    constructor(address owner_) TwoStageOwnable(owner_) {
        _setOperator(owner_);
    }

    function setOperator(address operator_) public virtual onlyOwner returns (bool) {
        _setOperator(operator_);
        return true;
    }

    function _setOperator(address operator_) private {
        require(operator_ != address(0), "Operator is zero address");
        _operator = operator_;
        emit OperatorUpdated(operator_);
    }

    modifier onlyOperator() {
        require(_operator == msg.sender, "Operator: caller is not operator");
        _;
    }

    modifier onlyOwnerOrOperator() {
        require(_operator == msg.sender || owner() == msg.sender, "Operator: caller is not operator or owner");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./access/Operator.sol";

/**
 * @title Contract for create vesting token
 * @notice You can use this contract for create vesting and claim tokens
 */
contract Vesting is Operator {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct VestingSchedule {
        uint256 amount;
        uint256 monthlyAmount;
        uint256 vesting;
        uint256 cliff;
        uint256 claimAmount;
    }

    uint256 public constant MONTH = 30 days;
    IERC20 public immutable token;

    uint256 private _totalAmountVested;
    uint256 private _totalAmountClaimed;
    uint256 private _startTimestamp;
    EnumerableSet.AddressSet private _vesters;

    mapping(address => VestingSchedule[]) private _vests;

    /**
     * @notice Returns a boolean value that indicates whether the account is a vestor
     * @param account Account address
     */
    function isVester(address account) external view returns (bool) {
        return _vesters.contains(account);
    }

    /**
     * @notice Returns start timestamp vesting
     */
    function startTimestamp() external view returns (uint256) {
        return _startTimestamp;
    }

    /**
     * @notice Returns the total amount claimed tokens
     */
    function totalAmountClaimed() external view returns (uint256) {
        return _totalAmountClaimed;
    }

    /**
     * @notice Returns the total amount vested tokens
     */
    function totalAmountVested() external view returns (uint256) {
        return _totalAmountVested;
    }

    /**
     * @notice Returns a vest data by account and vesting id
     * @param account Account address
     * @param vestId Vesting identifier
     */
    function vest(address account, uint256 vestId) external view returns (VestingSchedule memory) {
        return _vests[account][vestId];
    }

    /**
     * @notice Returns a vest data by account and vesting id
     * @param index Vest index
     */
    function vester(uint256 index) external view returns (address) {
        return _vesters.at(index);
    }

    /**
     * @notice Returns a vesters count
     */
    function vestersCount() external view returns (uint256) {
        return _vesters.length();
    }

    /**
     * @notice Returns a vests by account
     * @param account Account address
     * @param offset Number of skipped elements
     * @param limit Number of items requested
     */
    function vests(
        address account,
        uint256 offset,
        uint256 limit
    ) external view returns (VestingSchedule[] memory vestsData) {
        uint256 vestsCount_ = _vests[account].length;
        if (offset >= vestsCount_) return new VestingSchedule[](0);
        uint256 to = offset + limit;
        if (vestsCount_ < to) to = vestsCount_;
        vestsData = new VestingSchedule[](to - offset);
        for (uint256 i = 0; i < vestsData.length; i++) vestsData[i] = _vests[account][offset + i];
    }

    /**
     * @notice Returns a vests length by account
     * @param account Account address
     */
    function vestsCount(address account) external view returns (uint256) {
        return _vests[account].length;
    }

    /**
     * @notice Returns count possible to claim token
     * @param account Account address
     * @param vestId Vesting identifier
     */
    function possibleToClaim(address account, uint256 vestId) public view returns (uint256 possibleToClaimAmount) {
        if (_startTimestamp == 0) return 0;
        VestingSchedule memory vestingItem = _vests[account][vestId];
        uint256 timestamp = getTimestamp();
        uint256 startTimestampVesting = _startTimestamp + vestingItem.cliff;
        uint256 endTimestampVesting = startTimestampVesting + vestingItem.vesting;
        if (timestamp > startTimestampVesting && timestamp < endTimestampVesting) {
            uint256 closeMonths = (timestamp - startTimestampVesting) / MONTH;
            possibleToClaimAmount = closeMonths * vestingItem.monthlyAmount;
            possibleToClaimAmount -= vestingItem.claimAmount;
        } else if (timestamp >= endTimestampVesting) {
            possibleToClaimAmount = vestingItem.amount - vestingItem.claimAmount;
        }
    }

    event Claimed(address[] recipients, uint256[] amounts, uint256[] vestIds);
    event StartTimestampSetted(uint256 timestamp);
    event TokenWithdrawn(address recipient, uint256 amount);
    event VestingsCreated(address[] recipients, uint256[] amounts, uint256[] vestings, uint256[] cliffs);

    /**
     * @notice Initializes Vesting contract
     * @dev Initializes a new Staking instance
     * @param token_ address token vesting
     * @param owner_ address owner vesting contract
     */
    constructor(address token_, address owner_) Operator(owner_) {
        token = IERC20(token_);
    }

    /**
     * @notice Method for branding tokens that are already available
     * @param recipients Accounts that received tokens
     * @param amounts Number of tokens to transfer
     * @param vestIds Vestings ids
     * @return boolean value indicating whether the operation succeeded
     * Emits a {Claimed} event
     */
    function claim(
        address[] memory recipients,
        uint256[] memory amounts,
        uint256[] memory vestIds
    ) external returns (bool) {
        require(recipients.length == amounts.length && recipients.length == vestIds.length, "Invalid params length");
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Recipient is zero address");
            require(vestIds[i] < _vests[recipients[i]].length, "Invalid vest id");
            require(amounts[i] > 0, "Amount is not positive");
            uint256 possibleAmount = possibleToClaim(recipients[i], vestIds[i]);
            uint256 claimAmount;
            require(possibleAmount > 0, "Possible amount is not positive");
            VestingSchedule storage vestItem = _vests[recipients[i]][vestIds[i]];
            if (amounts[i] > possibleAmount) {
                vestItem.claimAmount += possibleAmount;
                claimAmount = possibleAmount;
            } else {
                vestItem.claimAmount += amounts[i];
                claimAmount = amounts[i];
            }
            _totalAmountClaimed += claimAmount;
            token.transfer(recipients[i], claimAmount);
        }
        emit Claimed(recipients, amounts, vestIds);
        return true;
    }

    /**
     * @notice Method for assigning the required number of tokens to an account
     * @param recipients Recipient of tokens after vesting
     * @param amounts Amount token paste vesting
     * @param vestings Vesting token period
     * @param cliffs Delay before starting vesting token period
     * @return boolean value indicating whether the operation succeeded
     * Emits a {VestingsCreated} event
     */
    function createVestings(
        address[] memory recipients,
        uint256[] memory amounts,
        uint256[] memory vestings,
        uint256[] memory cliffs
    ) external onlyOperator returns (bool) {
        uint256 length = recipients.length;
        uint256 balance = token.balanceOf(address(this));
        require(
            length == amounts.length && length == cliffs.length && length == vestings.length,
            "Invalid params length"
        );
        for (uint256 i = 0; i < length; i++) {
            require(balance >= _totalAmountVested - _totalAmountClaimed + amounts[i], "Insufficient balance");
            require(recipients[i] != address(0), "Recipient is zero address");
            require(amounts[i] > 0, "Amount is not positive");
            VestingSchedule memory vestingItem;
            vestingItem.amount += amounts[i];
            if (cliffs[i] == 0 && vestings[i] == 0) {
                token.transfer(recipients[i], amounts[i]);
                _totalAmountClaimed += amounts[i];
                vestingItem.claimAmount = amounts[i];
            } else {
                vestingItem.monthlyAmount = vestingItem.amount / vestings[i];
                vestingItem.vesting = vestings[i] * MONTH;
                vestingItem.cliff = cliffs[i] * MONTH;
            }
            _vests[recipients[i]].push(vestingItem);
            _vesters.add(recipients[i]);
            _totalAmountVested += amounts[i];
        }
        emit VestingsCreated(recipients, amounts, vestings, cliffs);
        return true;
    }

    /**
     * @notice Method for started vesting
     * @param start Timestamp started
     * @return boolean value indicating whether the operation succeeded
     * Emits a {StartTimestampSetted} event
     */
    function setStartTimestamp(uint256 start) external onlyOwner returns (bool) {
        uint256 timestamp = getTimestamp();
        require(start >= timestamp, "Timestamp is not positive");
        require(_startTimestamp < timestamp || _startTimestamp == 0, "Vesting launched");
        _startTimestamp = start;
        emit StartTimestampSetted(start);
        return true;
    }

    /**
     * @notice Withdraw token from contract to recipient
     * @param recipient Recipient account
     * @param amount Amount for withdraw
     * @return boolean value indicating whether the operation succeeded
     * Emits a {TokenWithdrawn} event
     */
    function withdrawToken(address recipient, uint256 amount) external onlyOwner returns (bool) {
        require(amount > 0, "Amount is not positive");
        require(
            amount <= token.balanceOf(address(this)) - (_totalAmountVested - _totalAmountClaimed),
            "Insufficient balance"
        );
        token.transfer(recipient, amount);
        emit TokenWithdrawn(recipient, amount);
        return true;
    }

    /**
     * @notice Returns current timestamp
     */
    function getTimestamp() internal virtual view returns (uint256) {
        return block.timestamp;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}