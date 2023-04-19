// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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
pragma solidity =0.8.13;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IERC20Metadata as IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract TimeForDay {
    struct _DateTime {
        uint256 year;
        uint256 month;
        uint256 day;
        uint256 hour;
        uint256 minute;
        uint256 second;
        uint256 weekday;
    }

    uint256 constant DAY_IN_SECONDS = 86400;
    uint256 constant YEAR_IN_SECONDS = 31536000;
    uint256 constant LEAP_YEAR_IN_SECONDS = 31622400;
    uint256 constant HOUR_IN_SECONDS = 3600;
    uint256 constant MINUTE_IN_SECONDS = 60;
    uint256 constant ORIGIN_YEAR = 1970;

    function isLeapYear(uint256 year) private pure returns (bool) {
        if (year % 4 != 0) {
            return false;
        }
        if (year % 100 != 0) {
            return true;
        }
        if (year % 400 != 0) {
            return false;
        }
        return true;
    }

    function leapYearsBefore(uint256 year) private pure returns (uint256) {
        year -= 1;
        return year / 4 - year / 100 + year / 400;
    }

    function getDaysInMonth(uint256 month, uint256 year) private pure returns (uint256) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            return 31;
        }
        else if (month == 4 || month == 6 || month == 9 || month == 11) {
            return 30;
        }
        else if (isLeapYear(year)) {
            return 29;
        }
        else {
            return 28;
        }
    }

    function getYearMonthDay(uint256 _timestamp) internal pure returns (uint256) {
        _DateTime memory dt = parseTimestamp(_timestamp + 3600 * 8);
        return dt.year * (10 ** 6) + dt.month * (10 ** 4) + dt.day * 10;
    }

    function parseTimestamp(uint256 timestamp) private pure returns (_DateTime memory dt) {
        uint256 secondsAccountedFor = 0;
        uint256 buf;
        uint256 i;

        dt.year = getYear(timestamp);
        buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
        secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

        uint256 secondsInMonth;
        for (i = 1; i <= 12; i++) {
            secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
            if (secondsInMonth + secondsAccountedFor > timestamp) {
                dt.month = i;
                break;
            }
            secondsAccountedFor += secondsInMonth;
        }

        for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
            if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                dt.day = i;
                break;
            }
            secondsAccountedFor += DAY_IN_SECONDS;
        }
        dt.hour = getHour(timestamp);
        dt.minute = getMinute(timestamp);
        dt.second = getSecond(timestamp);
        dt.weekday = getWeekday(timestamp);
    }

    function getYear(uint256 timestamp) private pure returns (uint256) {
        uint256 secondsAccountedFor = 0;
        uint256 year;
        uint256 numLeapYears;

        year = uint256(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
        numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
        secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

        while (secondsAccountedFor > timestamp) {
            if (isLeapYear(uint256(year - 1))) {
                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
            }
            else {
                secondsAccountedFor -= YEAR_IN_SECONDS;
            }
            year -= 1;
        }
        return year;
    }

    function getMonth(uint256 timestamp) private pure returns (uint256) {
        return parseTimestamp(timestamp).month;
    }

    function getDay(uint256 timestamp) private pure returns (uint256) {
        return parseTimestamp(timestamp).day;
    }

    function getHour(uint256 timestamp) private pure returns (uint256) {
        return uint256((timestamp / 60 / 60) % 24);
    }

    function getMinute(uint256 timestamp) private pure returns (uint256) {
        return uint256((timestamp / 60) % 60);
    }

    function getSecond(uint timestamp) private pure returns (uint8) {
        return uint8(timestamp % 60);
    }

    function getWeekday(uint timestamp) private pure returns (uint8) {
        return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
    }
}

contract SortList {
    function sortUint256List(uint256[] memory a) internal pure returns (uint256[] memory){
        uint256 _num = a.length;
        for (uint i = 1; i < _num; i++) {
            uint temp = a[i];
            uint j = i;
            while ((j >= 1) && (temp > a[j - 1])) {
                a[j] = a[j - 1];
                j--;
            }
            a[j] = temp;
        }
        return (a);
    }
}


contract T222 is Ownable, TimeForDay, SortList {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    EnumerableSet.AddressSet private Dao1Set;
    EnumerableSet.AddressSet private Dao2Set;
    EnumerableSet.AddressSet private Dao3Set;
    EnumerableSet.AddressSet private Dao4Set;
    ShareItem public totalShareAllocation;

    struct ShareItem {
        uint256 _totalASA; //累积静态分配指数
        uint256[4] _totalADAList; //累积Dao1,Dao2,Dao3,Dao4指数
    }

    mapping(uint256 => ShareItem) public totalShareAllocationList; //记录每次操作时的参数

    address public daoToken;

    mapping(uint256 => mapping(uint256 => EnumerableSet.AddressSet)) private Day_InviteNum_AddressList; //记录每天每个推荐数的前20个地址
    mapping(uint256 => uint256[]) public Day_Top20InviteNum; //记录每天的推荐数前20名

    //统计最后100名入金用户
    EnumerableSet.AddressSet private last100Addresses;


    uint256 public tatalInvestNumber; //入金次数
    uint256 public tatalInvestAmount; //入金总金额
    uint256 public remainingCredit; //剩余权益（入金总金额*2-已领取的推荐收益-已领取的dao收益-已领取的静态收益）
    mapping(address => UserInfo) public userInfoList;
    addressItem public addressConfig;

    mapping(uint256 => InvestItem) public InvestList;

    uint256[12] public rewardRateList = [250000000000, 100000000000, 50000000000, 25000000000, 12500000000, 6250000000, 3125000000, 1562500000, 781250000, 390625000, 195312500, 97656250];
    uint256 public rewardAllRateList = 10 ** 12;

    struct UserInvestItem {
        uint256 _investId;
        uint256 _remainingCredit;
    }

    struct UserDaoItem {
        uint256 _investId;
        uint256 _daoType;
    }

    mapping(address => UserInvestItem) public userInvestList; //记录用户的每次入金
    mapping(address => UserDaoItem) public userDaoList; //记录用户的Dao记录


    struct InvestItem {
        uint256 _investId;
        uint256 _dao4Num;
        uint256 _dao3Num;
        uint256 _dao2Num;
        uint256 _dao1Num;
        uint256 _tatalInvestAmount; //总入金数
        uint256 _staticIncomePerShare; //每份入金的收益
        uint256 _rewardPerShareForDao4; //每个dao4的奖励
        uint256 _rewardPerShareForDao3; //每个dao3的奖励
        uint256 _rewardPerShareForDao2; //每个dao2的奖励
        uint256 _rewardPerShareForDao1; //每个dao1的奖励
    }

    struct addressItem {
        address _techAddress; //2%
        address _marketAddress; //3%
        address _daoAddress;  //5%
    }

    struct daoItem {
        bool isDao4;
        bool isDao3;
        bool isDao2;
        bool isDao1;
        uint256 beDao4;
        uint256 beDao3;
        uint256 beDao2;
        uint256 beDao1;
    }

    struct UserInfo {
        address _referrer; //推荐人
        address[] _allReferrers; //上级推荐人列表
        address[] _referrals; //直推下线列表
        uint256 _referTime; //绑定推荐人的时间
        uint256 _depositAmount; //自己的总入金
        uint256 _totalNetAmount; //网体总入金
        //uint256 _maxRewardAmount; // 最高领取权益
        uint256 _totalClaiRewardAmount; //已经领取的收益总额
        uint256 _updatedReward;
        uint256 _updatedDaoReward;
        uint256 _referReward; //推荐收入
        uint256 _firstInvestTime; //第一次入金时间
        uint256 _daoRewardAmount;
        daoItem _daoItem;
        // //每天推荐人数(每日推荐新人榜)
        mapping(uint256 => uint256) InviteNumPerDay;
        // //每天的入金总额(每日大单榜)
        mapping(uint256 => uint256) InvestAmountPerDay;
        //mapping(uint256 => uint256) InvestList;
    }

    function setDaoToken(address _daoToken) external onlyOwner {
        daoToken = _daoToken;
    }

    function setAddressConfig(
        address _techAddress, //2%
        address _marketAddress, //3%
        address _daoAddress  //5%
    ) external onlyOwner {
        addressConfig._techAddress = _techAddress;
        addressConfig._marketAddress = _marketAddress;
        addressConfig._daoAddress = _daoAddress;
    }

    function blind(address _referrerAddress) public {
        address _user = msg.sender;
        require(_referrerAddress != address(0), "e001");
        require(_referrerAddress != _user, "e001");
        require(userInfoList[_user]._referrer == address(0), "e002");
        userInfoList[_user]._referrer = _referrerAddress;
        userInfoList[_user]._referrals.push(_user);
        address _referrer0 = _referrerAddress;
        userInfoList[_user]._allReferrers.push(_referrer0);
        while (userInfoList[_referrer0]._referrer != address(0)) {
            _referrer0 = userInfoList[_referrer0]._referrer;
            require(_referrer0 != _user, "e003");
            userInfoList[_user]._allReferrers.push(_referrer0);
        }
        userInfoList[_user]._referTime = getYearMonthDay(block.timestamp);
    }

    function Invest(uint256 _amount) external {
        address _user = msg.sender;

        /*
        计算用法静态收益,只要计算 最新的accshareList[最新的入金索引]-accshareList[入金时的索引],然后乘以入金数就可以得到奖励
        */
        //剩余总权益 = 总tatalInvestAmount*2-（已领的推荐奖励+dao奖励+静态奖励） 剩余总权益去计算分红
        uint256 currentASA;
        // uint256 currentAD1A;
        // uint256 currentAD2A;
        // uint256 currentAD3A;
        // uint256 currentAD4A;

        if (tatalInvestNumber == 0) {
            currentASA = 0;
        } else {
            currentASA = remainingCredit == 0 ? 0 : ((_amount * 25 / 100) * (10 ** 18) / remainingCredit);
        }
        totalShareAllocation._totalASA += currentASA;
        totalShareAllocationList[tatalInvestNumber]._totalASA = totalShareAllocation._totalASA;

        updateTotalADAList(_amount, 0);
        updateTotalADAList(_amount, 1);
        updateTotalADAList(_amount, 2);
        updateTotalADAList(_amount, 3);

        //用户的总入金*2-所有已领的奖励
        uint256 _userRemainingCredit = (userInfoList[_user]._depositAmount * 2 + _amount * 2) - userInfoList[_user]._totalClaiRewardAmount;

        if (userInvestList[_user]._remainingCredit > 0) {
            //结清之前的剩余权益在本次的分红
            userInfoList[_user]._updatedReward += (userInfoList[_user]._depositAmount * 2 - userInfoList[_user]._totalClaiRewardAmount) * currentASA / 10 ** 18;
            //更新用户的收益
            updateStaticRewad(_user);
        }

        //计算剩余权益
        userInvestList[_user] = UserInvestItem(tatalInvestNumber, _userRemainingCredit);


        //此处要改成剩余权益,一旦领取收益,之前所有的记录清除，重新生成一个（新的剩余权益,对应的总share）


        //        uint256 _day = getYearMonthDay(block.timestamp);
        //        address _referrer = userInfoList[_user]._referrer;
        //
        //        //10%给技术、市场和dao
        uint256 _techFee = _amount * 2 / 100;
        uint256 _marketFee = _amount * 3 / 100;
        uint256 _daoFee = _amount * 5 / 100;
        uint256 _leftFee = _amount - _techFee - _marketFee - _daoFee;

        //   IERC20(daoToken).transferFrom(_user, addressConfig._techAddress, _techFee);
        //   IERC20(daoToken).transferFrom(_user, addressConfig._marketAddress, _marketFee);
        //   IERC20(daoToken).transferFrom(_user, addressConfig._daoAddress, _daoFee);
        IERC20(daoToken).transferFrom(_user, address(this), _leftFee);

        //平台总入金
        tatalInvestAmount += _amount;
        remainingCredit += _amount * 2;


        //        //个人总入金
        userInfoList[_user]._depositAmount += _amount;
        //        //个人网体业绩增加(减去自己的是网体贡献业绩)
        userInfoList[_user]._totalNetAmount += _amount;
        //        //个人总权益
        //        userInfoList[_user]._maxRewardAmount += _amount * 2;
        //
        //        //更新自己和团队的状态数据以及推荐奖励分配
        if (userInfoList[_user]._firstInvestTime != 0) {
            updateDao(_user, tatalInvestNumber);
        }
        distributeReferrReward(_amount, _user);
        //
        //        //todo 日推荐榜 3%(当天+上一天)
        //        if (userInfoList[_user]._firstInvestTime == 0) {
        //            updateReferBangList(_day, _referrer);
        //        }
        //
        //        //todo 统计当日入金排名前4名  单天入金
        //        userInfoList[_user].InvestAmountPerDay[_day] += _amount;
        //        //todo 当日大单奖 日推荐榜 3%(当天+上一天)
        //
        //
        //        //todo 管理奖分配 12%,采取静态分配的方法去处理管理奖
        //
        //
        //        //todo 2% 补偿池
        //        updateLast100UserSet(_user);
        //平台入金次数
        tatalInvestNumber += 1;
    }

    function updateTotalADAList(uint256 _amount, uint256 _type) private {
        uint256 num;
        uint256 rate;
        uint256 currentADA;
        if (_type == 0) {
            num = Dao1Set.length();
            rate = 5;
        }
        if (_type == 1) {
            num = Dao2Set.length();
            rate = 4;
        }
        if (_type == 2) {
            num = Dao3Set.length();
            rate = 3;
        }
        if (_type == 3) {
            num = Dao4Set.length();
            rate = 2;
        }
        if (num == 0) {
            currentADA = 0;
        } else {
            currentADA = (_amount * rate / 100) / num;
        }
        totalShareAllocationList[tatalInvestNumber]._totalADAList[_type] += currentADA;
    }

    function addDaoSet(address _user, uint256 _type) external onlyOwner {
        uint256 _tatalInvestNumber = (tatalInvestNumber == 0) ? 0 : (tatalInvestNumber - 1);
        if (_type == 0) {
            Dao1Set.add(_user);
            userDaoList[_user] = UserDaoItem(_tatalInvestNumber, 0);
        }
        if (_type == 1) {
            Dao2Set.add(_user);
            userDaoList[_user] = UserDaoItem(_tatalInvestNumber, 1);
        }
        if (_type == 2) {
            Dao3Set.add(_user);
            userDaoList[_user] = UserDaoItem(_tatalInvestNumber, 2);
        }
        if (_type == 3) {
            Dao4Set.add(_user);
            userDaoList[_user] = UserDaoItem(_tatalInvestNumber, 3);
        }
    }

    function claimStaticReward() external {
        address _user = msg.sender;
        uint256 _penddingReward = getStaticReward(_user) + userInfoList[_user]._updatedReward;
        updateRewardItem(_user, _penddingReward);
        userInfoList[_user]._updatedReward = 0;
    }

    function claimReferrReward() external {
        address _user = msg.sender;
        uint256 _penddingReward = userInfoList[_user]._referReward;
        updateRewardItem(_user, _penddingReward);
        //领取完之后推荐奖励归零
        userInfoList[_user]._referReward = 0;
    }

    function updateRewardItem(address _user, uint256 _penddingReward) private {
        IERC20(daoToken).transfer(_user, _penddingReward);
        userInfoList[_user]._totalClaiRewardAmount += _penddingReward;
        uint256 _userRemainingCredit = (userInfoList[_user]._depositAmount * 2) - userInfoList[_user]._totalClaiRewardAmount;
        userInvestList[_user] = UserInvestItem(tatalInvestNumber - 1, _userRemainingCredit);
        require(remainingCredit >= _penddingReward, "e002");
        remainingCredit -= _penddingReward;
    }

    function updateStaticRewad(address _user) private {
        uint256 _totalReward = getStaticReward(_user);
        userInfoList[_user]._updatedReward += _totalReward;
    }

    //查看用户的总静态收益
    function getStaticReward(address _user) public view returns (uint256) {
        if (tatalInvestNumber == 0) {
            return 0;
        }
        UserInvestItem memory x = userInvestList[_user];
        uint256 _investId = x._investId;
        uint256 _remainingCredit = x._remainingCredit;
        uint256 _totalReward = _remainingCredit * (totalShareAllocationList[tatalInvestNumber - 1]._totalASA - totalShareAllocationList[_investId]._totalASA) / (10 ** 18);
        return _totalReward;
    }

    //获取用户最新Dao收益
    function getDaoReward(address _user, uint256 _type) public view returns (uint256) {
        bool isDao = (userInfoList[_user]._daoItem.isDao1 || userInfoList[_user]._daoItem.isDao2 || userInfoList[_user]._daoItem.isDao3 || userInfoList[_user]._daoItem.isDao4) ? true : false;
        UserDaoItem memory x = userDaoList[_user];
        uint256 _investId = x._investId;
        uint256 _daoType = x._daoType;
        if (tatalInvestNumber == 0 || _type > 3 || !isDao || _type != _daoType) {
            return 0;
        }
        uint256 _totalReward = totalShareAllocationList[tatalInvestNumber - 1]._totalADAList[_type] - totalShareAllocationList[_investId]._totalADAList[_type];
        return _totalReward;
    }

    //用户升级dao时,需要更新之前的收益
    function updateDaoRewad(address _user, uint256 _type) private {
        uint256 _totalReward = getDaoReward(_user, _type);
        userInfoList[_user]._updatedDaoReward += _totalReward;
    }

    //领取用户的dao收益
    function claimDaoReward(uint256 _type) external {
        require(_type < 4 && tatalInvestNumber > 0, "e001");
        address _user = msg.sender;
        uint256 _penddingReward = getDaoReward(_user, _type) + userInfoList[_user]._updatedDaoReward;
        updateRewardItem(_user, _penddingReward);
        userInfoList[_user]._updatedDaoReward = 0;
        userDaoList[_user] = UserDaoItem(tatalInvestNumber - 1, _type);
    }

    function getpPenddingReward(address _user) public view returns (uint256) {
        uint256 _totalReward = getStaticReward(_user);
        return _totalReward + userInfoList[_user]._updatedReward;
    }

    function distributeReferrReward(uint256 _amount, address _user) private {
        address[] memory _allReferrers = userInfoList[_user]._allReferrers;
        uint256 _allReferrersNum = _allReferrers.length;
        //最近不超过12级
        if (_allReferrersNum > 12) {
            _allReferrersNum = 12;
        }
        //todo 推荐奖励 45% 直推25%,如果没有二级和其它层级的推荐人 则20%的代币分配不出去
        uint256 _rewardAmount;
        for (uint256 i = 0; i < _allReferrersNum; i++) {
            _rewardAmount = _amount * rewardRateList[i] / rewardAllRateList;
            userInfoList[_allReferrers[i]]._referReward += _rewardAmount;
            //每一级的网体业绩都增加
            userInfoList[_allReferrers[i]]._totalNetAmount += _amount;
            updateDao(_allReferrers[i], tatalInvestNumber);
        }
    }

    function updateDao(address _user, uint256 _investId) private {
        //直推不足3个不更新
        address[] memory _referrals = userInfoList[_user]._referrals;
        uint256 _num = _referrals.length;
        if (_num < 3) {
            return;
        }
        //已经是dao1,直接忽略
        if (userInfoList[_user]._daoItem.isDao1) {
            return;
        }

        uint256[] memory _netAmountList = new uint256[](_num);
        for (uint256 i = 0; i < _num; i++) {
            uint256 _netAmount = userInfoList[_referrals[i]]._totalNetAmount;
            _netAmountList[i] = _netAmount;
        }
        _netAmountList = sortUint256List(_netAmountList);
        uint256 bigAmount = _netAmountList[0];
        uint256 totalSmallAmount = userInfoList[_user]._totalNetAmount - userInfoList[_user]._depositAmount - bigAmount;
        if (bigAmount >= 500 * 10 ** 22 && totalSmallAmount >= 500 * 10 ** 22) {
            //升级dao1
            userInfoList[_user]._daoItem.isDao1 = true;
            if (Dao2Set.contains(_user)) {
                updateDaoRewad(_user, 1);
                Dao2Set.remove(_user);
            }
            if (Dao3Set.contains(_user)) {
                updateDaoRewad(_user, 2);
                Dao3Set.remove(_user);
            }
            if (Dao4Set.contains(_user)) {
                updateDaoRewad(_user, 3);
                Dao4Set.remove(_user);
            }
            Dao1Set.add(_user);
            userDaoList[_user] = UserDaoItem(_investId, 0);
        } else if (bigAmount >= 100 * 10 ** 22 && totalSmallAmount >= 100 * 10 ** 22) {
            //升级dao2
            if (!userInfoList[_user]._daoItem.isDao2) {
                userInfoList[_user]._daoItem.isDao2 = true;
                if (Dao3Set.contains(_user)) {
                    updateDaoRewad(_user, 2);
                    Dao3Set.remove(_user);
                }
                if (Dao4Set.contains(_user)) {
                    updateDaoRewad(_user, 3);
                    Dao4Set.remove(_user);
                }
                Dao2Set.add(_user);
                userDaoList[_user] = UserDaoItem(_investId, 1);
            }
        } else if (bigAmount >= 20 * 10 ** 22 && totalSmallAmount >= 20 * 10 ** 22) {
            //升级dao3
            if (!userInfoList[_user]._daoItem.isDao3) {
                userInfoList[_user]._daoItem.isDao3 = true;
                if (Dao4Set.contains(_user)) {
                    updateDaoRewad(_user, 3);
                    Dao4Set.remove(_user);
                }
                Dao3Set.add(_user);
                userDaoList[_user] = UserDaoItem(_investId, 2);
            }
        } else if (bigAmount >= 5 * 10 ** 22 && totalSmallAmount >= 5 * 10 ** 22) {
            //升级dao4
            if (!userInfoList[_user]._daoItem.isDao4) {
                userInfoList[_user]._daoItem.isDao4 = true;
                Dao4Set.add(_user);
                userDaoList[_user] = UserDaoItem(_investId, 3);
            }
        }
    }

    // //更新每日新增推荐排行榜数据
    function updateReferBangList(uint256 _day, address _referrer) private {
        //推荐当前的推荐人数
        uint256 _inviteNum0 = userInfoList[_referrer].InviteNumPerDay[_day];
        if (_inviteNum0 > 0) {
            if (Day_InviteNum_AddressList[_day][_inviteNum0].contains(_referrer)) {
                Day_InviteNum_AddressList[_day][_inviteNum0].remove(_referrer);
            }
        }
        //更新后的推荐人数
        uint256 _inviteNum1 = _inviteNum0.add(1);
        userInfoList[_referrer].InviteNumPerDay[_day] = _inviteNum1;
        //同一推荐人数的地址列表长度
        uint256 _num = Day_InviteNum_AddressList[_day][_inviteNum1].length();
        //如果排行榜不足20,该推荐数直接上榜,并更新拥有同一推荐数的地址
        if (Day_Top20InviteNum[_day].length < 20) {
            Day_Top20InviteNum[_day].push(_inviteNum1);
            Day_Top20InviteNum[_day] = sortUint256List(Day_Top20InviteNum[_day]);
            if (_num < 20) {
                Day_InviteNum_AddressList[_day][_inviteNum1].add(_referrer);
            }
        } else {
            uint256 _min = Day_Top20InviteNum[_day][19];
            //排行榜满20人,如果推荐数大于最小数,则上榜，并更新拥有同一推荐数的地址
            if (_inviteNum1 > _min) {
                Day_Top20InviteNum[_day][19] = _inviteNum1;
                Day_Top20InviteNum[_day] = sortUint256List(Day_Top20InviteNum[_day]);
                if (_num < 20) {
                    Day_InviteNum_AddressList[_day][_inviteNum1].add(_referrer);
                }
            }
        }
    }

    //更新补偿池的用户列表
    function updateLast100UserSet(address sender) private {
        if (last100Addresses.contains(sender)) {
            last100Addresses.remove(sender);
        }
        if (last100Addresses.length() == 100) {
            last100Addresses.remove(last100Addresses.at(0));
        }
        last100Addresses.add(sender);
    }

    receive() external payable {}
}