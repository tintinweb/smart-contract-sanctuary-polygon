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
import {TimeForDay} from "./TimeForDay.sol";
import {SortList} from "./SortList.sol";
import {StructForDao} from "./StructForDao.sol";

contract BaseContract is Ownable, TimeForDay, SortList, StructForDao {
    // DAO1地址列表
    EnumerableSet.AddressSet internal Dao1Set;
    // DAO2地址列表
    EnumerableSet.AddressSet internal Dao2Set;
    // DAO3地址列表
    EnumerableSet.AddressSet internal Dao3Set;
    // DAO4地址列表
    EnumerableSet.AddressSet internal Dao4Set;
    // 最近100个地址列表
    EnumerableSet.AddressSet internal Last100Addresses;
    // 总共的份额分配信息
    ShareItem public totalShareAllocation;

    // DAO代币地址
    address public daoToken;
    //调整时间参数,可将下午5点计算成第二天的零点，每天下午5点结算排行榜
    uint256 public adjustHour = 15;
    // DAO1的升级基数
    uint256 internal dao1Amount = 5000 * 10 ** 18;
    // DAO2的升级基数
    uint256 internal dao2Amount = 1000 * 10 ** 18;
    // DAO3的升级基数
    uint256 internal dao3Amount = 500 * 10 ** 18;
    // DAO4的升级基数
    uint256 internal dao4Amount = 100 * 10 ** 18;
    // 总补偿金额
    uint256 public totalCompensation;
    // 总投资次数
    uint256 public investIndex;
    //结算索引
    uint256 public investEndIndex;
    // 总投资金额
    uint256 public tatalInvestAmount;
    // 剩余授信额度
    uint256 public remainingCredit;
    //最后一次入金时间
    uint256 public lastInvestTime;
    //连续超过这个时间，没有用户入金，补偿池的资金会自动补偿给最后的用户
    uint256 public compensationInterval = 3600 * 24;

    // 总奖励比例
    uint256 public rewardAllRateList = 10 ** 12;
    // 奖励比例列表
    uint256[20] public rewardRateList = [250000000000, 100000000000, 50000000000, 25000000000, 12500000000, 6250000000, 3125000000, 1562500000, 781250000, 390625000, 195312500, 97656250];
    // 奖励比例列表
    uint256[20] public rewardRateListForInviteRanking = [40, 10, 10, 10, 5, 5, 5, 5, 5, 5];
    // 奖励比例列表
    uint256[20] public rewardRateListForInvestRanking = [40, 30, 20, 10];
    // 地址配置信息
    AddressItem public addressConfig;

    // 总共的份额分配列表
    mapping(uint256 => ShareItem) public totalShareAllocationList;
    // 邀请排行榜每日排名列表
    mapping(uint256 => EnumerableSet.AddressSet) internal rankingPerDayForInvite;
    // 投资排行榜每日排名列表
    mapping(uint256 => EnumerableSet.AddressSet) internal rankingPerDayForInvest;
    // 用户信息列表
    mapping(address => UserInfo) public userInfoList;
    // 用户投资信息列表
    mapping(address => UserInvestItem) public userInvestList;
    // 用户DAO信息列表
    mapping(address => UserDaoItem) public userDaoList;
    // 下级推荐人列表
    mapping(address => address[]) public referrals;
    // 上级推荐人列表
    mapping(address => address[]) public allReferrers;
    // 每日投资列表
    mapping(uint256 => mapping(address => uint256)) public listPerDayForInvest;
    // 每日邀请列表
    mapping(uint256 => mapping(address => uint256)) public listPerDayForInvite;
    // 每日投资排名奖励
    mapping(uint256 => uint256) public DayRewardForInvestRankings;
    // 每日邀请排名奖励
    mapping(uint256 => uint256) public DayRewardForInviteRankings;
    // 每日补偿奖励
    mapping(uint256 => uint256) public DayRewardForCompensation;
    // 每周投资排名奖励
    mapping(uint256 => uint256) public WeekRewardForInvestRankings;
    //每日的邀请排行榜是否已分配
    mapping(uint256 => bool) public DayRewardForInviteRankingStatus;
    //每日的大单排行榜是否已发放
    mapping(uint256 => bool) public DayRewardForInvestRankingStatus;
    //每周的大单排行榜是否已发放
    mapping(uint256 => bool) public WeekRewardForInvestRankingStatus;
    //记录绑定推荐人信息，包括用户地址、推荐人地址、索引、日期、时间戳
    event BindEvent(address _user, address _referrerAddress, uint256 _index, uint256 _day, uint256 _time);
    //记录入金信息，包括用户地址、入金索引、日期、时间戳、入金数量、当天总入金、用户剩余授信额度
    event InvestEvent(address _user, uint256 _index, uint256 _day, uint256 _time, uint256 _amount, uint256 _totalAmount, uint256 _remainingCredit);
    event ClaimRewardEvent(address _user, uint256 _index, uint256 _day, uint256 _time, string _type, uint256 _remainingCredit);
    //记录分配信息,包括日期、时间、类型、理论分配金额、实际分配金额
    event DistributeEvent(uint256 _day, uint256 _time, string _type, uint256 _toShareAmount, uint256 _totalAmount, uint256 _totalUser, uint256 _gasUsed);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

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

// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

contract StructForDao {
    enum SetType {
        Last100Addresses,
        Dao1Set,
        Dao2Set,
        Dao3Set,
        Dao4Set
    }

    struct ShareItem {
        uint256 _totalASA; //累积静态分配指数
        uint256 _totalAD1A; //累积Dao1
        uint256 _totalAD2A; //累积Dao2
        uint256 _totalAD3A; //累积Dao3
        uint256 _totalAD4A; //累积Dao4
    }

    struct UserInvestItem {
        uint256 _investStartIndex;
        uint256 _remainingCredit;
    }

    struct UserDaoItem {
        uint256 _investStartIndex;
        uint256 _daoType;
    }

    struct AddressItem {
        address _techAddress; //2%
        address _marketAddress; //3%
        address _daoAddress;  //5%
    }

    struct DaoItem {
        bool isDao1;
        bool isDao2;
        bool isDao3;
        bool isDao4;
    }

    struct UpdatedRewardItem {
        uint256 _updatedStaticReward;
        uint256 _updatedDirectReferralReward;
        uint256 _updatedIndirectReferralReward;
        //uint256 _updatedInvitationReward;
        uint256 _updatedDao1Reward;
        uint256 _updatedDao2Reward;
        uint256 _updatedDao3Reward;
        uint256 _updatedDao4Reward;
    }

    struct ClaimedRewardItem {
        uint256 _claimedStaticReward;
        uint256 _claimedDirectReferralReward;
        uint256 _claimedIndirectReferralReward;
        uint256 _claimedDao1Reward;
        uint256 _claimedDao2Reward;
        uint256 _claimedDao3Reward;
        uint256 _claimedDao4Reward;
    }

    struct RankingRewardItem {
        uint256 _updatedRankingInvite;
        uint256 _updatedRankingInvest;
        uint256 _updatedCompensation;
        uint256 _claimedRankingInvite;
        uint256 _claimedRankingInvest;
        uint256 _claimedCompensation;
    }

    struct UserInfo {
        address _referrer; //推荐人
        uint256 _referTime; //绑定推荐人的时间
        uint256 _depositAmount; //自己的总入金
        uint256 _totalNetInvestment; //网体总入金
        uint256 _totalClaiRewardAmount; //已经领取的收益总额
        //uint256 _invitationReward; //推荐收入
        uint256 _firstInvestTime; //第一次入金时间
        UpdatedRewardItem _updatedRewardItem;
        ClaimedRewardItem _claimedRewardItem;
        RankingRewardItem _rankingRewardItem;
        DaoItem _daoItem;
    }


    struct BaseItem {
        address daoToken;
        uint256 totalCompensation;
        uint256 investIndex;
        uint256 tatalInvestAmount;
        uint256 remainingCredit;
        uint256 lastInvestTime;
        uint256 investEndIndex;
        uint256 compensationInterval;
        uint256 rewardAllRateList;
        uint256[20] rewardRateList;
        uint256[20] rewardRateListForInviteRanking;
        uint256[20] rewardRateListForInvestRanking;
        AddressItem addressConfig;
    }

    struct SortItem {
        address _address;
        uint256 _num;
    }

    struct investItem {
        uint256 currentASA;
        uint256 _userRemainingCredit;
        uint256 _techFee;
        uint256 _marketFee;
        uint256 _daoFee;
        uint256 _leftFee;
        uint256 _adjustHour;
        uint256 _timestamp;
        uint256 _day;
        uint256 _nextDay;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IERC20Metadata as IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {BaseContract} from "./BaseContract.sol";

contract T222 is BaseContract {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    function setDaoToken(address _daoToken) external onlyOwner {
        daoToken = _daoToken;
    }

    /**
     * @dev 设置地址配置信息，只有合约所有者可以调用
     * @param _techAddress 技术地址
     * @param _marketAddress 市场地址
     * @param _daoAddress DAO地址
     */
    function setAddressConfig(
        address _techAddress,
        address _marketAddress,
        address _daoAddress
    ) external onlyOwner {
        // 设置技术地址
        addressConfig._techAddress = _techAddress;
        // 设置市场地址
        addressConfig._marketAddress = _marketAddress;
        // 设置DAO地址
        addressConfig._daoAddress = _daoAddress;
    }

    function setAdjustHour(uint256 _adjustHour) external onlyOwner {
        adjustHour = _adjustHour;
    }

    function setCompensationInterval(uint256 _compensationInterval) external onlyOwner {
        compensationInterval = _compensationInterval;
    }

    /**
      * @dev 绑定推荐人，并递归查找所有的推荐人，并将它们添加到调用者的所有推荐人列表中
      * @param _referrerAddress 推荐人地址
    */
    function bind(address _referrerAddress) external {
        // 获取调用者地址
        address _user = msg.sender;
        // 推荐人地址不能为0地址
        require(_referrerAddress != address(0), "Referrer address cannot be zero");
        // 推荐人地址不能为调用者地址
        require(_referrerAddress != _user, "Referrer address cannot be the same as the user address");
        // 调用者的推荐人地址必须为空
        require(userInfoList[_user]._referrer == address(0), "User has already been referred");
        // 设置调用者的推荐人地址
        userInfoList[_user]._referrer = _referrerAddress;
        // 将调用者添加到推荐人的推荐列表中
        referrals[_referrerAddress].push(_user);
        // 递归查找所有的推荐人，并将它们添加到调用者的所有推荐人列表中
        address _referrer0 = _referrerAddress;
        allReferrers[_user].push(_referrer0);
        while (userInfoList[_referrer0]._referrer != address(0)) {
            _referrer0 = userInfoList[_referrer0]._referrer;
            // 推荐人不能为调用者本身
            require(_referrer0 != _user, "Circular reference detected");
            allReferrers[_user].push(_referrer0);
        }
        // 设置调用者的推荐时间为当前时间
        uint256 _day = getYearMonthDay(block.timestamp, adjustHour);
        userInfoList[_user]._referTime = _day;
        emit BindEvent(_user, _referrerAddress, investIndex, _day, block.timestamp);
        _distributeAll();
    }

    function invest(uint256 _amount) external {
        investEndIndex = investIndex;
        address _user = msg.sender;
        investItem memory skip = new investItem[](1)[0];
        //todo 分配每日大单排行榜、每日推荐排行榜、补偿池
        _distributeAll();
        //todo 更新静态奖励指数
        if (investIndex == 0) {
            skip.currentASA = 0;
        } else {
            skip.currentASA = remainingCredit == 0 ? 0 : ((_amount * 25 / 100) * (10 ** 18) / remainingCredit);
        }
        totalShareAllocation._totalASA += skip.currentASA;
        totalShareAllocationList[investEndIndex]._totalASA = totalShareAllocation._totalASA;
        //todo 更新dao4奖励指数
        _updateTotalADAList(_amount, 4);
        //todo 更新dao3奖励指数
        _updateTotalADAList(_amount, 3);
        //todo 更新dao2奖励指数
        _updateTotalADAList(_amount, 2);
        //todo 更新dao1奖励指数
        _updateTotalADAList(_amount, 1);

        //如果是不是第一次入金,需要更新所有奖励
        if (userInvestList[_user]._remainingCredit > 0) {
            _updateAllRewards(_user);
        }
        //记录用户的剩余授权额度
        skip._userRemainingCredit = _getUserRemainingCredit(_user) + _amount * 2;
        userInvestList[_user] = UserInvestItem(investIndex, skip._userRemainingCredit);

        skip._techFee = _amount * 2 / 100;
        skip._marketFee = _amount * 3 / 100;
        skip._daoFee = _amount * 5 / 100;
        skip._leftFee = _amount - skip._techFee - skip._marketFee - skip._daoFee;
        //todo 分配2%给技术
        if (addressConfig._techAddress != address(0)) {
            IERC20(daoToken).transferFrom(_user, addressConfig._techAddress, skip._techFee);
        }
        //todo 分配3%给市场
        if (addressConfig._marketAddress != address(0)) {
            IERC20(daoToken).transferFrom(_user, addressConfig._marketAddress, skip._marketFee);
        }
        //todo 分配5%给dao
        if (addressConfig._daoAddress != address(0)) {
            IERC20(daoToken).transferFrom(_user, addressConfig._daoAddress, skip._daoFee);
        }
        //todo 其它资金进入合约进行二次分配
        IERC20(daoToken).transferFrom(_user, address(this), skip._leftFee);
        //更新平台总投资金额
        tatalInvestAmount += _amount;
        //更新总剩余授信额度
        remainingCredit += _amount * 2;
        //更新用户的投资金额
        userInfoList[_user]._depositAmount += _amount;
        //更新用户的网体业绩
        userInfoList[_user]._totalNetInvestment += _amount;
        //如果不是第一入金，更新用的Dao数据
        if (userInfoList[_user]._firstInvestTime != 0) {
            _updateDao(_user, investIndex);
        }
        //todo 分配推广奖励和更新各级推荐人的DAO数据
        _distributeInvitationReward(_amount, _user);
        skip._adjustHour = adjustHour;
        skip._timestamp = block.timestamp;
        skip._day = getYearMonthDay(skip._timestamp, skip._adjustHour);
        skip._nextDay = getYearMonthDay(skip._timestamp + 3600 * 24, skip._adjustHour);
        //无论是第一次入金还是复投,都算一次有效入金
        lastInvestTime = skip._timestamp;
        //如果是第一次入金，则计入上级推荐人的当日推荐榜数据
        if (userInfoList[_user]._firstInvestTime == 0) {
            address _referrer = userInfoList[_user]._referrer;
            if (_referrer != address(0)) {
                _updateRanking(skip._day, _referrer, 1, 20, listPerDayForInvite, rankingPerDayForInvite);
            }
            //最新更新的第一次入金时间
            userInfoList[_user]._firstInvestTime = skip._timestamp;
        }
        //用户参与当日的大单排行榜
        _updateRanking(skip._day, _user, _amount, 20, listPerDayForInvest, rankingPerDayForInvest);
        //记录平台最后100个用户,当一天没有用户时，会从补偿池给用户分配
        _updateLast100UserSet(_user);

        //todo 3%的资金进入每日大单奖励池
        DayRewardForInvestRankings[skip._day] += _amount * 15 / 1000;
        DayRewardForInvestRankings[skip._nextDay] += _amount * 15 / 1000;
        //todo 3%的资金进入每日的推荐奖励池
        DayRewardForInviteRankings[skip._day] += _amount * 15 / 1000;
        DayRewardForInviteRankings[skip._nextDay] += _amount * 15 / 1000;
        //todo 2%的资金进入每日的补偿池
        DayRewardForCompensation[skip._day] += _amount * 20 / 1000;
        //更新总补偿池数据
        totalCompensation += _amount * 2 / 100;
        //记录入金信息,包括用户地址、入金索引、日期、时间戳、入金数量、当天总入金、用户剩余授信额度
        emit InvestEvent(_user, investIndex, skip._day, skip._timestamp, _amount, listPerDayForInvest[skip._day][_user], _getUserRemainingCredit(_user));
        //入金索引+1
        investIndex += 1;
    }

    function _distributeDayRewardForInviteRanking() private {
        uint256 _gas0 = gasleft();
        uint256 _timestamp = block.timestamp;
        uint256 _day = getYearMonthDay(_timestamp - 3600 * 24, adjustHour);
        if (DayRewardForInviteRankingStatus[_day]) {
            return;
        }
        uint256 _amount = DayRewardForInviteRankings[_day];
        if (_amount == 0) {
            return;
        }
        uint256 _num = rankingPerDayForInvite[_day].length();
        if (_num == 0) {
            return;
        }
        if (_num > 10) {
            _num = 10;
        }
        address[] memory _list = rankingPerDayForInvite[_day].values();
        (_list,) = getDayTop2(_list, _day, listPerDayForInvite);
        uint256 _totalAmount;
        for (uint256 i = 0; i < _num; i++) {
            address _user = _list[i];
            uint256 _amountShare = (_amount * rewardRateListForInviteRanking[i]) / 100;
            _totalAmount += _amountShare;
            userInfoList[_user]._rankingRewardItem._updatedRankingInvite += _amountShare;
        }
        DayRewardForInviteRankingStatus[_day] = true;
        uint256 _gas1 = gasleft();
        emit DistributeEvent(_day, _timestamp, "_distributeDayRewardForInviteRanking", _amount, _totalAmount, _num, _gas0 - _gas1);
    }

    function _distributeDayRewardForInvestRanking() private {
        uint256 _gas0 = gasleft();
        uint256 _timestamp = block.timestamp;
        uint256 _day = getYearMonthDay(_timestamp - 3600 * 24, adjustHour);
        if (DayRewardForInvestRankingStatus[_day]) {
            return;
        }
        uint256 _amount = DayRewardForInvestRankings[_day];
        if (_amount == 0) {
            return;
        }
        uint256 _num = rankingPerDayForInvest[_day].length();
        if (_num == 0) {
            return;
        }
        if (_num > 4) {
            _num = 4;
        }
        address[] memory _list = rankingPerDayForInvest[_day].values();
        (_list,) = getDayTop2(_list, _day, listPerDayForInvest);
        uint256 _totalAmount;
        for (uint256 i = 0; i < _num; i++) {
            address _user = _list[i];
            uint256 _amountShare = _amount * rewardRateListForInvestRanking[i] / 100;
            _totalAmount += _amountShare;
            userInfoList[_user]._rankingRewardItem._updatedRankingInvest += _amountShare;
        }
        DayRewardForInvestRankingStatus[_day] = true;
        uint256 _gas1 = gasleft();
        emit DistributeEvent(_day, _timestamp, "_distributeDayRewardForInvestRanking", _amount, _totalAmount, _num, _gas0 - _gas1);
    }

    // 用于分发补偿奖励
    function _distributeCompensation() private {
        uint256 _gas0 = gasleft();
        uint256 _timestamp = block.timestamp;
        uint256 _day = getYearMonthDay(_timestamp, adjustHour);

        // 如果当前时间大于上一次投资时间加上补偿间隔，则不进行分发
        if (block.timestamp < lastInvestTime + compensationInterval) {
            return;
        }
        // 如果总补偿金额为0或者上一次投资时间为0，则不进行分发
        if (totalCompensation == 0 || lastInvestTime == 0) {
            return;
        }
        // 获取最近100个地址的数量
        uint256 _num = Last100Addresses.length();
        // 如果最近100个地址的数量为0，则不进行分发
        if (_num == 0) {
            return;
        }
        // 获取最近100个地址的列表
        address[] memory _list = Last100Addresses.values();
        // 将总补偿金额的一半分配给最近100个地址
        uint256 _amount = totalCompensation / 2;
        totalCompensation -= _amount;
        // 将一半的补偿金额的50%分配给排名第一的地址
        uint256 _amountForTop = _amount * 50 / 100;
        userInfoList[_list[0]]._rankingRewardItem._updatedCompensation += _amountForTop;
        // 如果最近100个地址的数量大于1，则将剩余的补偿金额平均分配给其他地址
        if (_num > 1) {
            uint256 _amountForOther = (_amount - _amountForTop) / (_num - 1);
            for (uint256 i = 1; i < _num; i++) {
                userInfoList[_list[i]]._rankingRewardItem._updatedCompensation += _amountForOther;
            }
        }
        uint256 _gas1 = gasleft();
        emit DistributeEvent(_day, _timestamp, "_distributeCompensation", _amount, _amount, _num, _gas0 - _gas1);
    }

    function distributeDayRewardForInviteRanking() external {
        _distributeDayRewardForInviteRanking();
    }

    function distributeDayRewardForInvestRanking() external {
        _distributeDayRewardForInvestRanking();
    }

    function distributeCompensation() external {
        _distributeCompensation();
    }

    function _distributeAll() private {
        //todo 分配前一日的邀请排行奖励
        _distributeDayRewardForInviteRanking();
        //todo 分配前一日的大单排行奖励
        _distributeDayRewardForInvestRanking();
        //todo 连续24小时没有入金，补偿池的50%分配给最后入金的100个地址
        _distributeCompensation();
    }

    // 给以下代码加上中文注释
    function _updateTotalADAList(uint256 _amount, uint256 _type) private {
        // 定义num、rate和currentADA变量
        uint256 num;
        uint256 rate;
        uint256 currentADA;
        // 根据传入的_type参数，设置num和rate的值
        if (_type == 1) {
            // 获取Dao1Set数组的长度
            num = Dao1Set.length();
            // 设置rate为5
            rate = 5;
        } else if (_type == 2) {
            // 获取Dao2Set数组的长度
            num = Dao2Set.length();
            // 设置rate为4
            rate = 4;
        } else if (_type == 3) {
            // 获取Dao3Set数组的长度
            num = Dao3Set.length();
            // 设置rate为3
            rate = 3;
        } else if (_type == 4) {
            // 获取Dao4Set数组的长度
            num = Dao4Set.length();
            // 设置rate为2
            rate = 2;
        } else {
            // 如果_type参数不是1、2、3、4中的任何一个，则直接返回
            return;
        }
        // 如果num为0，则将currentADA设置为0，否则计算currentADA
        if (num == 0) {
            // 如果num为0，则将currentADA设置为0
            currentADA = 0;
        } else {
            // 计算currentADA
            currentADA = (_amount * rate / 100) / num;
            // 根据传入的_type参数，更新totalShareAllocation和totalShareAllocationList中对应的值
            if (_type == 1) {
                totalShareAllocation._totalAD1A += currentADA;
                totalShareAllocationList[investEndIndex]._totalAD1A = totalShareAllocation._totalAD1A;
            } else if (_type == 2) {
                totalShareAllocation._totalAD2A += currentADA;
                totalShareAllocationList[investEndIndex]._totalAD2A = totalShareAllocation._totalAD2A;
            } else if (_type == 3) {
                totalShareAllocation._totalAD3A += currentADA;
                totalShareAllocationList[investEndIndex]._totalAD3A = totalShareAllocation._totalAD3A;
            } else if (_type == 4) {
                totalShareAllocation._totalAD4A += currentADA;
                totalShareAllocationList[investEndIndex]._totalAD4A = totalShareAllocation._totalAD4A;
            }
        }
    }

    // 更新所有奖励
    function _updateAllRewards(address _user) private {
        // 更新DAO1奖励
        _updateDaoRewad(_user, 1);
        // 更新DAO2奖励
        _updateDaoRewad(_user, 2);
        // 更新DAO3奖励
        _updateDaoRewad(_user, 3);
        // 更新DAO4奖励
        _updateDaoRewad(_user, 4);
        // 更新静态奖励
        _updateStaticRewad(_user);
    }

    /**
      * @dev 获取用户剩余的授信额度
      * @param _user 用户地址
      * @return 用户剩余的授信额度
     */
    function _getUserRemainingCredit(address _user) private view returns (uint256) {
        // 计算用户剩余的授信额度
        return userInfoList[_user]._depositAmount * 2 - userInfoList[_user]._totalClaiRewardAmount;
    }

    // 领取静态奖励
    function claimStaticReward() external {
        // 获取用户地址
        address _user = msg.sender;
        // 更新所有奖励
        _updateAllRewards(_user);
        // 获取待领取的静态奖励
        uint256 _pendingReward = userInfoList[_user]._updatedRewardItem._updatedStaticReward;
        // 获取用户剩余的授信额度
        uint256 _userRemainingCredit = _getUserRemainingCredit(_user);
        // 如果待领取奖励大于用户剩余授信额度，则将待领取奖励设为用户剩余授信额度
        if (_pendingReward > _userRemainingCredit) {
            _pendingReward = _userRemainingCredit;
        }
        // 转移奖励给用户
        _transferReward(_user, _pendingReward, "claimStaticReward");
        // 更新用户已领取的静态奖励
        userInfoList[_user]._claimedRewardItem._claimedStaticReward += _pendingReward;
        // 更新用户待领取的静态奖励
        userInfoList[_user]._updatedRewardItem._updatedStaticReward -= _pendingReward;
    }

    // 领取直接邀请奖励
    function claimDirectReferralReward() external {
        // 获取用户地址
        address _user = msg.sender;
        // 更新所有奖励
        _updateAllRewards(_user);
        // 获取待领取的邀请奖励
        uint256 _pendingReward = userInfoList[_user]._updatedRewardItem._updatedDirectReferralReward;
        // 获取用户剩余的授信额度
        uint256 _userRemainingCredit = _getUserRemainingCredit(_user);
        // 如果待领取奖励大于用户剩余授信额度，则将待领取奖励设为用户剩余授信额度
        if (_pendingReward > _userRemainingCredit) {
            _pendingReward = _userRemainingCredit;
        }
        // 转移奖励给用户
        _transferReward(_user, _pendingReward, "claimDirectReferralReward");
        // 更新用户已领取的邀请奖励
        userInfoList[_user]._claimedRewardItem._claimedDirectReferralReward += _pendingReward;
        // 更新用户待领取的邀请奖励
        userInfoList[_user]._updatedRewardItem._updatedDirectReferralReward -= _pendingReward;
    }

    // 领取间接邀请奖励
    function claimIndirectReferralReward() external {
        // 获取用户地址
        address _user = msg.sender;
        // 更新所有奖励
        _updateAllRewards(_user);
        // 获取待领取的邀请奖励
        uint256 _pendingReward = userInfoList[_user]._updatedRewardItem._updatedIndirectReferralReward;
        // 获取用户剩余的授信额度
        uint256 _userRemainingCredit = _getUserRemainingCredit(_user);
        // 如果待领取奖励大于用户剩余授信额度，则将待领取奖励设为用户剩余授信额度
        if (_pendingReward > _userRemainingCredit) {
            _pendingReward = _userRemainingCredit;
        }
        // 转移奖励给用户
        _transferReward(_user, _pendingReward, "claimIndirectReferralReward");
        // 更新用户已领取的邀请奖励
        userInfoList[_user]._claimedRewardItem._claimedIndirectReferralReward += _pendingReward;
        // 更新用户待领取的邀请奖励
        userInfoList[_user]._updatedRewardItem._updatedIndirectReferralReward -= _pendingReward;
    }

    // 领取DAO奖励
    function claimDaoReward(uint256 _type) external {
        // 确保_type的范围在1到4之间，且investIndex大于0
        require(_type > 0 && _type < 5 && investIndex > 0, "e001");
        // 获取用户地址
        address _user = msg.sender;
        // 更新所有奖励
        _updateAllRewards(_user);
        // 获取待领取的DAO奖励
        uint256 _pendingReward;
        if (_type == 1) {
            _pendingReward = userInfoList[_user]._updatedRewardItem._updatedDao1Reward;
        } else if (_type == 2) {
            _pendingReward = userInfoList[_user]._updatedRewardItem._updatedDao2Reward;
        } else if (_type == 3) {
            _pendingReward = userInfoList[_user]._updatedRewardItem._updatedDao3Reward;
        } else if (_type == 4) {
            _pendingReward = userInfoList[_user]._updatedRewardItem._updatedDao4Reward;
        }
        // 获取用户剩余的授信额度
        uint256 _userRemainingCredit = _getUserRemainingCredit(_user);
        // 如果待领取奖励大于用户剩余授信额度，则将待领取奖励设为用户剩余授信额度
        if (_pendingReward > _userRemainingCredit) {
            _pendingReward = _userRemainingCredit;
        }
        // 根据_type更新用户已领取的DAO奖励和待领取的DAO奖励
        if (_type == 1) {
            userInfoList[_user]._claimedRewardItem._claimedDao1Reward += _pendingReward;
            userInfoList[_user]._updatedRewardItem._updatedDao1Reward -= _pendingReward;
        } else if (_type == 2) {
            userInfoList[_user]._claimedRewardItem._claimedDao2Reward += _pendingReward;
            userInfoList[_user]._updatedRewardItem._updatedDao2Reward -= _pendingReward;
        } else if (_type == 3) {
            userInfoList[_user]._claimedRewardItem._claimedDao3Reward += _pendingReward;
            userInfoList[_user]._updatedRewardItem._updatedDao3Reward -= _pendingReward;
        } else if (_type == 4) {
            userInfoList[_user]._claimedRewardItem._claimedDao4Reward += _pendingReward;
            userInfoList[_user]._updatedRewardItem._updatedDao4Reward -= _pendingReward;
        }
        // 转移奖励给用户
        _transferReward(_user, _pendingReward, "claimDaoReward");
        // 更新用户的DAO信息
        UserDaoItem memory x = userDaoList[_user];
        uint256 _daoType = x._daoType;
        userDaoList[_user] = UserDaoItem(investIndex - 1, _daoType);
    }

    // 对于邀请奖励，用户可以调用此函数来领取排名奖励
    function claimRankingForInvite() external {
        // 获取调用者的地址
        address _user = msg.sender;
        // 获取用户未领取的邀请奖励数量
        uint256 _pendingReward = userInfoList[_user]._rankingRewardItem._updatedRankingInvite;
        // 调用合约中的 transfer 函数，将奖励发送给用户
        IERC20(daoToken).transfer(_user, _pendingReward);
        // 将用户未领取的邀请奖励数量设为 0
        userInfoList[_user]._rankingRewardItem._updatedRankingInvite = 0;
        // 将用户已领取的邀请奖励数量增加
        userInfoList[_user]._rankingRewardItem._claimedRankingInvite += _pendingReward;
    }

    // 对于投资奖励，用户可以调用此函数来领取排名奖励
    function claimRankingForInvest() external {
        // 获取调用者的地址
        address _user = msg.sender;
        // 获取用户未领取的投资奖励数量
        uint256 _pendingReward = userInfoList[_user]._rankingRewardItem._updatedRankingInvest;
        // 调用合约中的 transfer 函数，将奖励发送给用户
        IERC20(daoToken).transfer(_user, _pendingReward);
        // 将用户未领取的投资奖励数量设为 0
        userInfoList[_user]._rankingRewardItem._updatedRankingInvest = 0;
        // 将用户已领取的投资奖励数量增加
        userInfoList[_user]._rankingRewardItem._claimedRankingInvest += _pendingReward;
    }

    // 用户可以调用此函数来领取补偿奖励
    function claimCompensation() external {
        // 获取调用者的地址
        address _user = msg.sender;
        // 获取用户未领取的补偿奖励数量
        uint256 _pendingReward = userInfoList[_user]._rankingRewardItem._updatedCompensation;
        // 调用合约中的 transfer 函数，将奖励发送给用户
        IERC20(daoToken).transfer(_user, _pendingReward);
        // 将用户未领取的补偿奖励数量设为 0
        userInfoList[_user]._rankingRewardItem._updatedCompensation = 0;
        // 将用户已领取的补偿奖励数量增加
        userInfoList[_user]._rankingRewardItem._claimedCompensation += _pendingReward;
    }

    /**
      * @dev 转移用户的奖励
      * @param _user 用户地址
      * @param _pendingReward 待转移的奖励数量
     */
    function _transferReward(address _user, uint256 _pendingReward, string memory _type) private {
        // 待转移的奖励数量必须大于0
        require(_pendingReward > 0, "The amount to be transferred must be greater than zero");
        // 将待转移的奖励转移到用户地址
        IERC20(daoToken).transfer(_user, _pendingReward);
        // 将转移的奖励数量添加到用户的总领取奖励中
        userInfoList[_user]._totalClaiRewardAmount += _pendingReward;
        // 计算用户剩余的授信额度
        uint256 _userRemainingCredit = _getUserRemainingCredit(_user);
        emit ClaimRewardEvent(_user, investIndex - 1, getYearMonthDay(block.timestamp, adjustHour), block.timestamp, _type, _userRemainingCredit);
        // 更新用户的投资列表
        userInvestList[_user] = UserInvestItem(investIndex - 1, _userRemainingCredit);
        // 剩余授信额度必须大于等于待转移的奖励数量
        require(remainingCredit >= _pendingReward, "Insufficient remaining credit for transfer");
        // 减去已转移的奖励数量
        remainingCredit -= _pendingReward;
    }

    /**
     * @dev 更新用户的静态奖励
     * @param _user 用户地址
     */
    function _updateStaticRewad(address _user) private {
        // 获取用户的静态奖励
        uint256 _totalReward = _getStaticReward(_user);
        // 将用户的静态奖励添加到更新后的奖励项中
        userInfoList[_user]._updatedRewardItem._updatedStaticReward += _totalReward;
    }

    /**
     * @dev 更新用户在指定类型的DAO中的奖励
     * @param _user 用户地址
     * @param _type DAO类型
      */
    function _updateDaoRewad(address _user, uint256 _type) private {
        // 获取用户在指定类型的DAO中的奖励
        uint256 _totalReward = _getDaoReward(_user, _type);
        // 根据DAO类型更新用户的奖励
        if (_type == 1) {
            userInfoList[_user]._updatedRewardItem._updatedDao1Reward += _totalReward;
        } else if (_type == 2) {
            userInfoList[_user]._updatedRewardItem._updatedDao2Reward += _totalReward;
        } else if (_type == 3) {
            userInfoList[_user]._updatedRewardItem._updatedDao3Reward += _totalReward;
        } else if (_type == 4) {
            userInfoList[_user]._updatedRewardItem._updatedDao4Reward += _totalReward;
        }
    }

    function _getStaticReward(address _user) private view returns (uint256) {
        // 如果总投资次数为0，则返回0
        if (investIndex == 0) {
            return 0;
        }
        // 获取用户的投资信息
        UserInvestItem memory x = userInvestList[_user];
        uint256 _investStartIndex = x._investStartIndex;
        uint256 _remainingCredit = x._remainingCredit;
        // 获取用户的静态收益
        uint256 _totalASA = totalShareAllocationList[investEndIndex]._totalASA - totalShareAllocationList[_investStartIndex]._totalASA;
        uint256 _totalReward = _remainingCredit * _totalASA / 1e18;
        return _totalReward;
    }

    function _getDaoReward(address _user, uint256 _type) private view returns (uint256) {
        // 如果总投资数为0或类型不在1到4之间或用户没有加入任何DAO，则返回0
        if (investIndex == 0 || _type < 1 || _type > 4 || userDaoList[_user]._daoType == 0) {
            return 0;
        }
        // 获取用户的DAO信息
        UserDaoItem memory x = userDaoList[_user];
        uint256 _investStartIndex = x._investStartIndex;
        uint256 _daoType = x._daoType;
        // 获取用户在指定类型的DAO中的奖励
        uint256 _totalReward;
        if (_daoType == _type) {
            if (_type == 1) {
                _totalReward = totalShareAllocationList[investEndIndex]._totalAD1A - totalShareAllocationList[_investStartIndex]._totalAD1A;
            } else if (_type == 2) {
                _totalReward = totalShareAllocationList[investEndIndex]._totalAD2A - totalShareAllocationList[_investStartIndex]._totalAD2A;
            } else if (_type == 3) {
                _totalReward = totalShareAllocationList[investEndIndex]._totalAD3A - totalShareAllocationList[_investStartIndex]._totalAD3A;
            } else if (_type == 4) {
                _totalReward = totalShareAllocationList[investEndIndex]._totalAD4A - totalShareAllocationList[_investStartIndex]._totalAD4A;
            }
        }
        return _totalReward;
    }

    function _getAllStaticReward(address _user) private view returns (uint256) {
        // 获取用户的静态收益
        uint256 _totalReward = _getStaticReward(_user);
        // 返回用户的静态收益加上已更新的静态收益
        return _totalReward + userInfoList[_user]._updatedRewardItem._updatedStaticReward;
    }

    function _getAllDaoReward(address _user, uint256 _type) private view returns (uint256) {
        // 获取用户在指定类型的DAO中的奖励
        uint256 _totalReward = _getDaoReward(_user, _type);
        // 根据不同的类型返回用户在该类型DAO中的奖励加上已更新的奖励
        if (_type == 1) {
            _totalReward += userInfoList[_user]._updatedRewardItem._updatedDao1Reward;
        } else if (_type == 2) {
            _totalReward += userInfoList[_user]._updatedRewardItem._updatedDao2Reward;
        } else if (_type == 3) {
            _totalReward += userInfoList[_user]._updatedRewardItem._updatedDao3Reward;
        } else if (_type == 4) {
            _totalReward += userInfoList[_user]._updatedRewardItem._updatedDao4Reward;
        }
        return _totalReward;
    }

    // 分发邀请奖励
    function _distributeInvitationReward(uint256 _amount, address _user) private {
        // 获取用户的所有推荐人列表和数量
        address[] memory _allReferrers = allReferrers[_user];
        uint256 _allReferrersNum = _allReferrers.length;
        // 如果推荐人数量大于 12，只取前 12 个进行奖励分配
        if (_allReferrersNum > 12) {
            _allReferrersNum = 12;
        }
        // 初始化奖励金额和循环变量
        uint256 _rewardAmount;
        for (uint256 i = 0; i < _allReferrersNum; i++) {
            // 计算当前推荐人的奖励金额
            _rewardAmount = _amount * rewardRateList[i] / rewardAllRateList;
            // 更新当前推荐人的邀请奖励和网体投资额
            if (i == 0) {
                userInfoList[_allReferrers[i]]._updatedRewardItem._updatedDirectReferralReward += _rewardAmount;
            } else {
                userInfoList[_allReferrers[i]]._updatedRewardItem._updatedIndirectReferralReward += _rewardAmount;
            }
            userInfoList[_allReferrers[i]]._totalNetInvestment += _amount;
            // 更新当前推荐人的 Dao 等级和奖励列表
            _updateDao(_allReferrers[i], investIndex);
        }
    }

    // 更新用户的 Dao 等级和奖励
    function _updateDao(address _user, uint256 _investStartIndex) private {
        // 获取用户的推荐人列表和数量
        address[] memory _referrals = referrals[_user];
        uint256 _num = _referrals.length;
        // 如果用户的推荐人数量小于 3 或者已经是 Dao1，直接返回
        if (_num < 3 || userInfoList[_user]._daoItem.isDao1) {
            return;
        }
        // 获取用户推荐人的净投资额列表并按降序排序
        uint256[] memory _netAmountList = new uint256[](_num);
        for (uint256 i = 0; i < _num; i++) {
            _netAmountList[i] = userInfoList[_referrals[i]]._totalNetInvestment;
        }
        _netAmountList = sortUint256List(_netAmountList);
        // 获取用户推荐人中净投资额最小的一个值和除此之外的净投资额总和
        uint256 bigAmount = _netAmountList[0];
        uint256 totalSmallAmount = userInfoList[_user]._totalNetInvestment - userInfoList[_user]._depositAmount - bigAmount;
        // 如果用户满足 Dao1 的条件，更新用户的 Dao 等级、奖励和奖励列表
        if (bigAmount >= dao1Amount && totalSmallAmount >= dao1Amount) {
            userInfoList[_user]._daoItem.isDao1 = true;
            Dao1Set.add(_user);
            userDaoList[_user] = UserDaoItem(_investStartIndex, 1);
            if (Dao2Set.contains(_user)) {
                _updateDaoRewad(_user, 2);
                Dao2Set.remove(_user);
            }
            if (Dao3Set.contains(_user)) {
                _updateDaoRewad(_user, 3);
                Dao3Set.remove(_user);
            }
            if (Dao4Set.contains(_user)) {
                _updateDaoRewad(_user, 4);
                Dao4Set.remove(_user);
            }
            // 如果用户满足 Dao2 的条件，更新用户的 Dao 等级、奖励和奖励列表
        } else if (bigAmount >= dao2Amount && totalSmallAmount >= dao2Amount) {
            if (!userInfoList[_user]._daoItem.isDao2) {
                userInfoList[_user]._daoItem.isDao2 = true;
                Dao2Set.add(_user);
                userDaoList[_user] = UserDaoItem(_investStartIndex, 2);
                if (Dao3Set.contains(_user)) {
                    _updateDaoRewad(_user, 3);
                    Dao3Set.remove(_user);
                }
                if (Dao4Set.contains(_user)) {
                    _updateDaoRewad(_user, 4);
                    Dao4Set.remove(_user);
                }
            }

            // 如果用户满足 Dao3 的条件，更新用户的 Dao 等级、奖励和奖励列表
        } else if (bigAmount >= dao3Amount && totalSmallAmount >= dao3Amount) {
            if (!userInfoList[_user]._daoItem.isDao3) {
                userInfoList[_user]._daoItem.isDao3 = true;
                Dao3Set.add(_user);
                userDaoList[_user] = UserDaoItem(_investStartIndex, 3);

                if (Dao4Set.contains(_user)) {
                    _updateDaoRewad(_user, 4);
                    Dao4Set.remove(_user);
                }
            }

            // 如果用户满足 Dao4 的条件，更新用户的 Dao 等级、奖励和奖励列表
        } else if (bigAmount >= dao4Amount && totalSmallAmount >= dao4Amount) {
            if (!userInfoList[_user]._daoItem.isDao4) {
                userInfoList[_user]._daoItem.isDao4 = true;
                Dao4Set.add(_user);
                userDaoList[_user] = UserDaoItem(_investStartIndex, 4);
            }
        }
    }

    function _updateRanking(uint256 _day, address _user, uint256 _addAmount, uint256 _takeNum, mapping(uint256 => mapping(address => uint256)) storage _data, mapping(uint256 => EnumerableSet.AddressSet) storage _set) private {
        uint256 _newAmount = _data[_day][_user] + _addAmount;
        _data[_day][_user] = _newAmount;
        if (_set[_day].contains(_user)) {
            return;
        }
        uint256 _num = _set[_day].length();
        if (_num < _takeNum) {
            _set[_day].add(_user);
        } else {
            address[] memory x = _set[_day].values();
            for (uint256 i = 0; i < _takeNum; i++) {
                address _addressItem = x[i];
                if (_data[_day][_addressItem] < _newAmount) {
                    _set[_day].remove(_addressItem);
                    _set[_day].add(_user);
                    break;
                }
            }
        }
    }

    /**
     * @dev 更新最近100个用户地址集合。
     * @param sender 要添加到集合中的地址。
     */
    function _updateLast100UserSet(address sender) private {
        // 如果集合中已经包含了该地址，则直接返回，不做任何操作。
        if (Last100Addresses.contains(sender)) {
            return;
        }
        // 如果集合中已经有100个地址，则移除第一个地址。
        if (Last100Addresses.length() == 100) {
            Last100Addresses.remove(Last100Addresses.at(0));
        }
        // 将新地址添加到集合中。
        Last100Addresses.add(sender);
    }

    //测试专用
    function addLast100(address[] memory _addressList) external onlyOwner {
        uint256 _num = _addressList.length;
        for (uint256 i = 0; i < _num; i++) {
            if (Last100Addresses.length() < 100) {
                Last100Addresses.add(_addressList[i]);
            }
        }
    }

    function addRankingPerDayForInvite20(address[] memory _addressList) external onlyOwner {
        uint256 _num = _addressList.length;
        uint256 _day = getYearMonthDay(block.timestamp, adjustHour);
        for (uint256 i = 0; i < _num; i++) {
            if (rankingPerDayForInvite[_day].length() < 20) {
                rankingPerDayForInvite[_day].add(_addressList[i]);
                listPerDayForInvite[_day][_addressList[i]] = i + 1;
            }
        }
    }

    function addRankingPerDayForInvest10(address[] memory _addressList) external onlyOwner {
        uint256 _num = _addressList.length;
        uint256 _day = getYearMonthDay(block.timestamp, adjustHour);
        for (uint256 i = 0; i < _num; i++) {
            if (rankingPerDayForInvest[_day].length() < 10) {
                rankingPerDayForInvest[_day].add(_addressList[i]);
                listPerDayForInvest[_day][_addressList[i]] = (i + 1) * 10 ** 20;
            }
        }
    }

    function getSets(SetType _type) external view returns (address[] memory _setList) {
        if (_type == SetType.Last100Addresses) {
            _setList = Last100Addresses.values();
        } else if (_type == SetType.Dao1Set) {
            _setList = Dao1Set.values();
        } else if (_type == SetType.Dao2Set) {
            _setList = Dao2Set.values();
        } else if (_type == SetType.Dao3Set) {
            _setList = Dao3Set.values();
        } else if (_type == SetType.Dao4Set) {
            _setList = Dao4Set.values();
        }
    }

    //借助中间结构体实现排序
    function getDayTop2(address[] memory _List, uint256 _day, mapping(uint256 => mapping(address => uint256))  storage data) private view returns (address[] memory y, uint256[] memory w){
        uint256 _num = _List.length;
        uint256[] memory x = new  uint256[](_num);
        SortItem[] memory z = new SortItem[](_num);
        for (uint256 i = 0; i < _num; i++) {
            uint256 _newVaue = data[_day][_List[i]] * 100 + i * 3;
            x[i] = _newVaue;
            z[i] = SortItem(_List[i], _newVaue);
        }
        x = sortUint256List(x);
        y = new address[](_num);
        w = new uint256[](_num);
        uint256 _p;
        for (uint256 t = 0; t < _num; t++) {
            for (uint256 u = 0; u < _num; u++) {
                if (x[t] == z[u]._num) {
                    y[_p] = z[u]._address;
                    w[_p] = data[_day][z[u]._address];
                    _p += 1;
                    break;
                }
            }
        }
    }

    function getDayTop(uint256 _timestamp, uint256 _type) external view returns (address[] memory _List, uint256 _day, uint256[] memory t) {
        // 如果未传入时间戳，则使用当前区块的时间戳
        if (_timestamp == 0) {
            _timestamp = block.timestamp;
        }
        // 获取时间戳对应的年月日
        _day = getYearMonthDay(_timestamp, adjustHour);
        // 如果类型为20，则获取邀请排行榜中当天的排名前N名
        if (_type == 20) {
            _List = rankingPerDayForInvite[_day].values();
            (_List, t) = getDayTop2(_List, _day, listPerDayForInvite);
            // 如果类型为10，则获取投资排行榜中当天的排名前N名
        } else if (_type == 10) {
            _List = rankingPerDayForInvest[_day].values();
            (_List, t) = getDayTop2(_List, _day, listPerDayForInvest);
        }
    }

    // 获取用户数据
    function getUserData(address _user, bool _returnReferrals, bool _returnAllReferrers) external view returns (uint256 _day, UserInfo memory UserInfo_, UserInvestItem memory UserInvestItem_, UserDaoItem memory UserDaoItem_, address[] memory referrals_, address[] memory allReferrers_, uint256 _staticReward, uint256[] memory _daoRewardList, BaseItem memory baseItem_) {
        // 获取当前时间的年月日
        _day = getYearMonthDay(block.timestamp, adjustHour);
        // 获取用户的基本信息、投资信息和 Dao 信息
        UserInfo_ = userInfoList[_user];
        UserInvestItem_ = userInvestList[_user];
        UserDaoItem_ = userDaoList[_user];
        // 如果需要返回用户的推荐人列表，则获取推荐人列表
        if (_returnReferrals) {
            referrals_ = referrals[_user];
        }
        // 如果需要返回用户的所有推荐人列表，则获取所有推荐人列表
        if (_returnAllReferrers) {
            allReferrers_ = allReferrers[_user];
        }
        // 获取用户的静态收益总额
        _staticReward = _getAllStaticReward(_user);
        // 初始化 Dao 奖励列表并计算每个 Dao 等级的奖励总额
        _daoRewardList = new uint256[](4);
        _daoRewardList[0] = _getAllDaoReward(_user, 1);
        _daoRewardList[1] = _getAllDaoReward(_user, 2);
        _daoRewardList[2] = _getAllDaoReward(_user, 3);
        _daoRewardList[3] = _getAllDaoReward(_user, 4);
        baseItem_ = BaseItem(daoToken, totalCompensation, investIndex, tatalInvestAmount, remainingCredit, lastInvestTime, investEndIndex, compensationInterval, rewardAllRateList, rewardRateList, rewardRateListForInviteRanking, rewardRateListForInvestRanking, addressConfig);
    }

    function getToday(uint256 _timstamp, uint256 _adjustHour) external view returns (uint256 _lastDay, uint256 _toDay, uint256 _nextDay) {
        if (_timstamp == 0) {
            _timstamp = block.timestamp;
        }
        _lastDay = getYearMonthDay(_timstamp - 3600 * 24, _adjustHour);
        _toDay = getYearMonthDay(_timstamp, _adjustHour);
        _nextDay = getYearMonthDay(_timstamp + 3600 * 24, _adjustHour);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

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

    function getYearMonthDay(uint256 _timestamp, uint256 _adjustHour) internal pure returns (uint256) {
        _DateTime memory dt = parseTimestamp(_timestamp + _adjustHour * 3600);
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