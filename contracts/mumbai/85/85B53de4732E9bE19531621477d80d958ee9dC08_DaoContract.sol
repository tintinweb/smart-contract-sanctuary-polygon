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
import {StructForDao} from "./StructForDao.sol";
import {SortList} from "./SortList.sol";

contract BaseContract is Ownable, TimeForDay, StructForDao, SortList {
    mapping(uint256 => EnumerableSet.AddressSet) internal DaoSetList;
    // 节点地址列表
    EnumerableSet.AddressSet internal NodeSet;
    // 最近100个地址列表
    EnumerableSet.AddressSet internal Last100Addresses;
    // 总共的份额分配信息
    ShareItem internal totalShareAllocation;

    // DAO代币地址
    address internal daoToken;
    address internal daoNftToken;
    //调整时间参数,可将下午5点计算成第二天的零点，每天下午5点结算排行榜
    uint256 internal adjustHour = 15;
    uint256[10] internal daoAmountList = [5 * 1e4 * 1e18, 20 * 1e4 * 1e18, 100 * 1e4 * 1e18, 500 * 1e4 * 1e18, 1000 * 1e4 * 1e18];
    string[10] internal daoEventList = ["RewardNewDao1", "RewardNewDao2", "RewardNewDao3", "RewardNewDao4", "RewardNewDao5", "RewardNewDao6", "RewardNewDao7", "RewardNewDao8", "RewardNewDao9", "RewardNewDao10"];
    uint256 internal maxForNum = 100;
    // 总补偿金额
    uint256 internal totalCompensation;
    // 总投资次数
    uint256 internal investIndex;
    //结算索引
    uint256 internal investEndIndex;
    // 总投资金额
    uint256 internal tatalInvestAmount;
    // 剩余授信额度
    uint256 internal remainingCredit;
    //最后一次入金时间
    uint256 internal lastInvestTime;
    uint256 internal maxDaoType = 5;
    uint256 internal rewardNew;
    //连续超过这个时间，没有用户入金，补偿池的资金会自动补偿给最后的用户
    uint256 internal compensationInterval = 3600 * 24;

    // 总奖励比例
    uint256 internal rewardAllRateList = 10 ** 12;
    // 奖励比例列表
    uint256[10] internal rewardRateListForDao = [50, 30, 20, 20, 15];
    uint256[20] internal rewardRateList = [220000000000, 100000000000, 50000000000, 25000000000, 12500000000, 6250000000, 3125000000, 1562500000, 781250000, 390625000, 195312500, 97656250];
    // 奖励比例列表
    uint256[20] internal rewardRateListForInviteRanking = [40, 10, 10, 10, 5, 5, 5, 5, 5, 5];
    // 奖励比例列表
    uint256[20] internal rewardRateListForInvestRanking = [40, 30, 20, 10];
    // 地址配置信息
    AddressItem internal addressConfig;
    //可升级参数
    TotalItemList internal totalConfig;
    BaseItem3 internal daoRewardData;

    //周投资奖
    //    uint256 internal weekRewardForInvest;
    //    //周邀请奖
    //    uint256 internal weekRewardForInvite;


    //平台总投资人数
    uint256 internal totalInvestMember;

    // 总共的份额分配列表
    mapping(uint256 => ShareItem) internal totalShareAllocationList;
    // 邀请排行榜每日排名列表
    //    mapping(uint256 => EnumerableSet.AddressSet) internal rankingPerDayForInvite;
    //    // 投资排行榜每日排名列表
    //    mapping(uint256 => EnumerableSet.AddressSet) internal rankingPerDayForInvest;
    // 用户信息列表
    mapping(address => UserInfo) internal userInfoList;
    // 用户投资信息列表
    //    mapping(address => UserInvestItem) internal userInvestList;
    //    // 用户DAO信息列表
    //    mapping(address => UserDaoItem) internal userDaoList;
    //    //用户节点数据
    //    mapping(address => UserNodeItem) internal userNodeList;
    // 下级推荐人列表
    mapping(address => address[]) public referrals;
    //有效的下级推荐人列表
    mapping(address => address[]) public effectiveReferrals;
    // 上级推荐人列表
    mapping(address => address[]) public allReferrers;
    // 每日投资列表
    //    mapping(uint256 => mapping(address => uint256)) internal listPerDayForInvest;
    //    // 每日邀请列表
    //    mapping(uint256 => mapping(address => uint256)) internal listPerDayForInvite;
    // 每日投资排名奖励
    //    mapping(uint256 => uint256) internal DayRewardForInvestRankings;
    //    // 每日邀请排名奖励
    //    mapping(uint256 => uint256) internal DayRewardForInviteRankings;
    //    //    mapping(uint256 => InvestInfoItem) public investInfoList;
    //    //每日的邀请排行榜是否已分配
    //    mapping(uint256 => bool) internal DayRewardForInviteRankingStatus;
    //    //每日的大单排行榜是否已发放
    //    mapping(uint256 => bool) internal DayRewardForInvestRankingStatus;


    //每周的大单排行榜是否已发放
    //    mapping(uint256 => bool) internal WeekRewardForInvestRankingStatus;
    //用户是否是白名单
    mapping(address => bool) internal whiteList;
    //用户是否是黑名单
    mapping(address => bool) internal blackList;
    //已经用户最大的最大区网体入金
    mapping(address => uint256) internal bigNetAmountList;

    //某类型的日榜地址列表
    mapping(string => mapping(uint256 => EnumerableSet.AddressSet)) internal dayRewardAddressList;
    //记录某类型每天用户的数据
    mapping(string => mapping(uint256 => mapping(address => uint256))) internal dayRewardUserDataList;
    //记录某类型每天的奖励总额
    mapping(string => mapping(uint256 => uint256)) internal DayRewardTotalAmountList;
    //记录某类型的每天是否已分配
    mapping(string => mapping(uint256 => bool)) internal DayRewardStatusList;

    //统计dao所有奖励和已发放的奖励
    mapping(string => uint256) internal weekReWardList;
    //记录进入周榜的用户的邀请人和入金
    mapping(string => uint256[]) internal weekDataList;
    //记录进入周榜的地址列表
    mapping(string => address[]) internal weekAddressList;
    //记录周榜的7个日期
    mapping(string => uint256[]) internal weekDayList;

    //记录绑定推荐人信息，包括用户地址、推荐人地址、索引、日期、时间戳
    event BindEvent(address _user, address _referrerAddress, uint256 _index, uint256 _day, uint256 _time);
    //记录入金信息，包括用户地址、入金索引、日期、时间戳、入金数量、当天总入金、用户剩余授信额度
    event InvestEvent(address _user, uint256 _index, uint256 _day, uint256 _time, uint256 _amount, uint256 _totalAmount, uint256 _remainingCredit);
    event ClaimRewardEvent(address _user, uint256 _index, uint256 _day, uint256 _time, string _type, uint256 _remainingCredit);
    //记录分配信息,包括日期、时间、类型、理论分配金额、实际分配金额
    event DistributeEvent(uint256 _day, uint256 _time, string _type, uint256 _toShareAmount, uint256 _totalAmount, uint256 _totalUser, uint256 _gasUsed, address _topAddress);
    event UpgradeDaoEvent(address _user, uint256 _time, uint256 _investIndex, uint256 _type);
    event DistributeInvitationRewardEvent(address _user, uint256 _time, uint256 _investIndex, string _type, uint256 _amount);
    event RewardNewEvent(uint256 _timestamp, uint256 _investIndex, string _type, uint256 _amount);
    event GasEvent(string _type, uint256 _gas);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IERC20Metadata as IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {BaseContract} from "./BaseContract.sol";

interface IERC1155 {
    function mint(address _to, uint256 _id, uint256 _amount) external;
}

contract DaoContract is BaseContract {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    /**
      * @dev 绑定推荐人，并递归查找所有的推荐人，并将它们添加到调用者的所有推荐人列表中,后补的推荐人不算
      * @param _referrerAddress 推荐人地址
    */
    function bind(address _referrerAddress) external {
        // 获取调用者地址
        address _user = msg.sender;
        //用户自己的网体人数+1
        userInfoList[_user]._referrerNet += 1;
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
        //推荐人的网体人数+1;
        userInfoList[_referrerAddress]._referrerNet += 1;
        // 递归查找所有的推荐人，并将它们添加到调用者的所有推荐人列表中
        address _referrer0 = _referrerAddress;
        allReferrers[_user].push(_referrer0);
        while (userInfoList[_referrer0]._referrer != address(0)) {
            _referrer0 = userInfoList[_referrer0]._referrer;
            //所有上级的网体人数都+1
            userInfoList[_referrer0]._referrerNet += 1;
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
        require(daoNftToken != address(0), "NFT address cannot be zero");
        //保证是整数倍投入
        uint256 _minAmount = 1000 * 1e18;
        uint256 _rate = _amount / _minAmount;
        require(_amount == _minAmount * _rate, "The investment amount must be a multiple of 1000");
        _amount = _minAmount * _rate;
        require(_amount >= _minAmount, "must more than 1000");
        investEndIndex = investIndex;
        address _user = msg.sender;
        IERC1155(daoNftToken).mint(_user, 1, _rate);
        address _referrer = userInfoList[_user]._referrer;
        require(IERC20(daoToken).balanceOf(_user) >= _amount, "Insufficient balance");
        //必须有推荐人
        require(_referrer != address(0), "Referrer address cannot be zero");
        InvestItem memory skip = new InvestItem[](1)[0];
        //todo 分配每日大单排行榜、每日推荐排行榜、补偿池
        _distributeAll();
        //todo 更新静态奖励指数
        if (investIndex == 0) {
            uint256 _leftAmount = _amount * 20 / 100;
            rewardNew += _leftAmount;
            emit RewardNewEvent(block.timestamp, investIndex, "RewardNewStaticReward", _leftAmount / 1e18);
            //todo 全网首单还有结余
            skip.currentASA = 0;
        } else {
            //todo 20% 全球全球静态分红
            skip.currentASA = remainingCredit == 0 ? 0 : ((_amount * 20 / 100) * 1e18 / remainingCredit);
        }
        totalShareAllocation._totalASA += skip.currentASA;
        totalShareAllocationList[investEndIndex]._totalASA = totalShareAllocation._totalASA;
        //todo 5% 节点收益分配
        {
            uint256 _nodeNum = NodeSet.length();
            uint256 _leftAmount = _amount * 5 / 100;
            if (_nodeNum > 0) {
                uint256 currentNodeASA = _leftAmount / _nodeNum;
                totalShareAllocation._totalNodeASA += currentNodeASA;
                totalShareAllocationList[investEndIndex]._totalNodeASA = totalShareAllocation._totalNodeASA;
            } else {
                rewardNew += _leftAmount;
                emit RewardNewEvent(block.timestamp, investIndex, "RewardNewNodeReward", _leftAmount / 1e18);
            }
        }

        //todo 13.5% 更新dao收益,如果此处等级的人数为零会有结余
        for (uint256 i = 0; i < 5; i++) {
            _updateTotalADAList(_amount, i + 1);
        }
        //如果是不是第一次入金,需要更新所有奖励
        if (userInfoList[_user]._userInvestItem._remainingCredit > 0) {
            _updateStaticRewad(_user);
        }
        //记录用户的剩余授权额度
        skip._userRemainingCredit = _getUserRemainingCredit(_user) + _amount * 2;
        userInfoList[_user]._userInvestItem = UserInvestItem(investEndIndex, skip._userRemainingCredit);

        skip._techFee = _amount * 2 / 100;
        skip._marketFee = _amount * 3 / 100;
        skip._daoFee = _amount * 5 / 100;
        skip._leftFee = _amount - skip._techFee - skip._marketFee - skip._daoFee;
        //todo 2% 分配给技术
        if (addressConfig._techAddress != address(0)) {
            IERC20(daoToken).transferFrom(_user, addressConfig._techAddress, skip._techFee);
        }
        //todo 3% 分配给市场
        if (addressConfig._marketAddress != address(0)) {
            IERC20(daoToken).transferFrom(_user, addressConfig._marketAddress, skip._marketFee);
        }
        //todo 5% 给后续分配
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
        //todo 42% 分配推广奖励和更新各级推荐人的DAO数据(直推22%+间推10%+团队10%) --此处会产生结余
        _distributeInvitationReward(_amount, _user);
        skip._adjustHour = adjustHour;
        skip._timestamp = block.timestamp;
        skip._day = getYearMonthDay(skip._timestamp, skip._adjustHour);
        skip._nextDay = getYearMonthDay(skip._timestamp + 3600 * 24, skip._adjustHour);
        //无论是第一次入金还是复投,都算一次有效入金
        lastInvestTime = skip._timestamp;
        //如果是第一次入金，则计入上级推荐人的当日推荐榜数据
        if (userInfoList[_user]._firstInvestTime == 0) {
            //每次新入金用户都计入新客户
            totalInvestMember += 1;
            _updateRanking(skip._day, _referrer, 1, 20, "Invite", dayRewardUserDataList, dayRewardAddressList);
            //最新更新的第一次入金时间
            userInfoList[_user]._firstInvestTime = skip._timestamp;
            //记录上级推荐人的有效会员
            effectiveReferrals[_referrer].push(_user);
        }
        //用户参与当日的大单排行榜
        _updateRanking(skip._day, _user, _amount, 20, "Invest", dayRewardUserDataList, dayRewardAddressList);
        //记录平台最后100个用户,当一天没有用户时，会从补偿池给用户分配
        _updateLast100UserSet(_user);

        //todo 3% 的资金进入每日大单奖励池
        DayRewardTotalAmountList["Invest"][skip._day] += _amount * 15 / 1000;
        DayRewardTotalAmountList["Invest"][skip._nextDay] += _amount * 15 / 1000;
        //todo 3%的资金进入每日的推荐奖励池
        DayRewardTotalAmountList["Invite"][skip._day] += _amount * 15 / 1000;
        DayRewardTotalAmountList["Invite"][skip._nextDay] += _amount * 15 / 1000;

        //todo 1.5% 进入周奖，每次只发50%
        weekReWardList["Invest"] += _amount * 75 / 10000;
        weekReWardList["Invite"] += _amount * 75 / 10000;
        //todo 2% 进入补偿池 更新总补偿池数据
        totalCompensation += _amount * 2 / 100;
        //记录入金信息,包括用户地址、入金索引、日期、时间戳、入金数量、当天总入金、用户剩余授信额度
        //        investInfoList[investIndex] = InvestInfoItem({
        //        _user : _user,
        //        _investIndex : investIndex,
        //        _amount : _amount,
        //        _totalASA : totalShareAllocationList[investEndIndex]._totalASA,
        //        _totalDaoASAList : totalShareAllocationList[investEndIndex]._totalDaoASAList,
        //        _timestamp : skip._timestamp,
        //        _day : skip._day,
        //        _remainingCredit : skip._userRemainingCredit
        //        });
        emit InvestEvent(_user, investIndex, skip._day, skip._timestamp, _amount / 1e18, dayRewardUserDataList["Invest"][skip._day][_user] / 1e18, _getUserRemainingCredit(_user) / 1e18);
        //入金索引+1
        investIndex += 1;
    }

    function _forInvite(uint256 _amount, uint256 _day, address[] memory _list, uint256 _num, uint256 _startIndex, uint256 _endIndex, uint256 _rewardRate) private returns (uint256){
        uint256 _totalR;
        uint256 _rewardAmount;
        // 如果开始地址索引大于等于地址数量，则直接返回
        if (_startIndex >= _num) {
            return 0;
        }
        // 如果结束地址索引大于等于地址数量，则将其设置为地址数量
        if (_endIndex >= _num) {
            _endIndex = _num;
        }
        // 计算所有地址在某一天的邀请数量之和
        for (uint256 k = _startIndex; k < _endIndex; k++) {
            _totalR += dayRewardUserDataList["Invite"][_day][_list[k]];
        }
        // 计算每个地址应该获得的奖励金额，并将其添加到用户信息中
        for (uint256 k = _startIndex; k < _endIndex; k++) {
            // 计算每个地址应该获得的奖励金额
            uint256 _rewardAmountItem = _amount * _rewardRate * dayRewardUserDataList["Invite"][_day][_list[k]] / (100 * _totalR);
            // 将计算出的奖励金额添加到用户信息中
            userInfoList[_list[k]]._userDataItem._updatedRankingInvite += _rewardAmountItem;
            // 将计算出的奖励金额添加到总奖励金额中
            _rewardAmount += _rewardAmountItem;
        }
        // 返回总奖励金额
        return _rewardAmount;
    }

    struct _distributeDayRewardItem {
        uint256 _gas0;
        uint256 _timestamp;
        uint256 _day;
        uint256 _maxRewardUsers;
        uint256 _amount;
        uint256 _num;
        uint256 _totalAmount;
        uint256 _gas1;
    }

    //Invest的_typeId为0,Invite的_typeId为1
    function _distributeDayReward(string memory _type, uint256 _typeId) private {
        _distributeDayRewardItem memory x = new _distributeDayRewardItem[](1)[0];
        x._gas0 = gasleft();
        x._timestamp = block.timestamp;
        x._day = getYearMonthDay(x._timestamp - 3600 * 24, adjustHour);
        //大单取前四,邀请取前10
        x._maxRewardUsers = _typeId == 0 ? 4 : 10;
        if (DayRewardStatusList[_type][x._day]) {
            return;
        }
        x._amount = DayRewardTotalAmountList[_type][x._day];
        if (x._amount == 0) {
            return;
        }
        x._num = dayRewardAddressList[_type][x._day].length();
        if (x._num == 0) {
            return;
        }
        if (x._num > x._maxRewardUsers) {
            x._num = x._maxRewardUsers;
        }
        address[] memory _list = dayRewardAddressList[_type][x._day].values();
        (_list,) = _sortRanking(_list, x._day, dayRewardUserDataList[_type]);
        address firstAddress = _list[0];
        //将第一名加入到周排行榜地址
        weekAddressList[_type].push(firstAddress);
        weekDayList[_type].push(x._day);
        weekDataList[_type].push(dayRewardUserDataList[_type][x._day][firstAddress]);
        //weekTop1AddressListForInvite.push(_list[0]);
        //x._totalAmount;
        if (_typeId == 0) {
            for (uint256 i = 0; i < x._num; i++) {
                address _user = _list[i];
                uint256 _amountShare = x._amount * rewardRateListForInvestRanking[i] / 100;
                x._totalAmount += _amountShare;
                userInfoList[_user]._userDataItem._updatedRankingInvest += _amountShare;
            }
        }
        if (_typeId == 1) {
            //第1名
            x._totalAmount += _forInvite(x._amount, x._day, _list, x._num, 0, 1, 40);
            //第2、3、4
            x._totalAmount += _forInvite(x._amount, x._day, _list, x._num, 1, 4, 30);
            //第5、6、7、8、9、10
            x._totalAmount += _forInvite(x._amount, x._day, _list, x._num, 4, 10, 30);
        }
        if (x._amount > x._totalAmount) {
            uint256 _leftAmount = x._amount - x._totalAmount;
            rewardNew += _leftAmount;
            emit RewardNewEvent(x._timestamp, investEndIndex, _concatStrings("RewardNewDayReward", _type), _leftAmount / 1e18);
        }
        DayRewardStatusList[_type][x._day] = true;
        x._gas1 = gasleft();
        emit DistributeEvent(x._day, x._timestamp, _concatStrings("_distributeDayReward", _type), x._amount / 1e18, x._totalAmount / 1e18, x._num, x._gas0 - x._gas1, firstAddress);
    }

    //    function _distributeDayRewardForInviteRanking() private {
    //        uint256 _gas0 = gasleft();
    //        uint256 _timestamp = block.timestamp;
    //        uint256 _day = getYearMonthDay(_timestamp - 3600 * 24, adjustHour);
    //        if (DayRewardForInviteRankingStatus[_day]) {
    //            return;
    //        }
    //        uint256 _amount = DayRewardForInviteRankings[_day];
    //        if (_amount == 0) {
    //            return;
    //        }
    //        uint256 _num = rankingPerDayForInvite[_day].length();
    //        if (_num == 0) {
    //            return;
    //        }
    //        if (_num > 10) {
    //            _num = 10;
    //        }
    //        address[] memory _list = rankingPerDayForInvite[_day].values();
    //        (_list,) = _sortRanking(_list, _day, listPerDayForInvite);
    //        address firstAddress = _list[0];
    //        //将第一名加入到周排行榜地址
    //        weekAddressList["Invite"].push(firstAddress);
    //        weekDayList["Invite"].push(_day);
    //        weekDataList["Invite"].push(listPerDayForInvite[_day][firstAddress]);
    //        //weekTop1AddressListForInvite.push(_list[0]);
    //        uint256 _totalAmount;
    //        //第1名
    //        _totalAmount += _forInvite(_amount, _day, _list, _num, 0, 1, 40);
    //        //第2、3、4
    //        _totalAmount += _forInvite(_amount, _day, _list, _num, 1, 4, 30);
    //        //第5、6、7、8、9、10
    //        _totalAmount += _forInvite(_amount, _day, _list, _num, 4, 10, 30);
    //        if (_amount > _totalAmount) {
    //            uint256 _leftAmount = _amount - _totalAmount;
    //            rewardNew += _leftAmount;
    //            emit RewardNewEvent(block.timestamp, investEndIndex, "RewardNewInviteRanking", _leftAmount / 1e18);
    //        }
    //        DayRewardForInviteRankingStatus[_day] = true;
    //        uint256 _gas1 = gasleft();
    //        emit DistributeEvent(_day, _timestamp, "_distributeDayRewardForInviteRanking", _amount / 1e18, _totalAmount / 1e18, _num, _gas0 - _gas1, firstAddress);
    //    }

    //    function _distributeDayRewardForInvestRanking() private {
    //        uint256 _gas0 = gasleft();
    //        uint256 _timestamp = block.timestamp;
    //        uint256 _day = getYearMonthDay(_timestamp - 3600 * 24, adjustHour);
    //        if (DayRewardForInvestRankingStatus[_day]) {
    //            return;
    //        }
    //        uint256 _amount = DayRewardForInvestRankings[_day];
    //        if (_amount == 0) {
    //            return;
    //        }
    //        uint256 _num = rankingPerDayForInvest[_day].length();
    //        if (_num == 0) {
    //            return;
    //        }
    //        if (_num > 4) {
    //            _num = 4;
    //        }
    //        address[] memory _list = rankingPerDayForInvest[_day].values();
    //        (_list,) = _sortRanking(_list, _day, listPerDayForInvest);
    //        address firstAddress = _list[0];
    //        //记录周榜第一名数据
    //        weekAddressList["Invest"].push(firstAddress);
    //        weekDayList["Invest"].push(_day);
    //        weekDataList["Invest"].push(listPerDayForInvest[_day][firstAddress]);
    //        uint256 _totalAmount;
    //        for (uint256 i = 0; i < _num; i++) {
    //            address _user = _list[i];
    //            uint256 _amountShare = _amount * rewardRateListForInvestRanking[i] / 100;
    //            _totalAmount += _amountShare;
    //            userInfoList[_user]._userDataItem._updatedRankingInvest += _amountShare;
    //        }
    //        if (_amount > _totalAmount) {
    //            uint256 _leftAmount = _amount - _totalAmount;
    //            rewardNew += _leftAmount;
    //            emit RewardNewEvent(block.timestamp, investEndIndex, "RewardNewInvestRanking", _leftAmount / 1e18);
    //        }
    //        DayRewardForInvestRankingStatus[_day] = true;
    //        uint256 _gas1 = gasleft();
    //        emit DistributeEvent(_day, _timestamp, "_distributeDayRewardForInvestRanking", _amount / 1e18, _totalAmount / 1e18, _num, _gas0 - _gas1, firstAddress);
    //    }

    // 用于分发补偿奖励
    function _distributeCompensation() private {
        uint256 _gas0 = gasleft();
        if (block.timestamp < lastInvestTime + compensationInterval) {
            return;
        }
        uint256 _timestamp = block.timestamp;
        uint256 _day = getYearMonthDay(_timestamp, adjustHour);
        uint256 _num = Last100Addresses.length();
        if (totalCompensation == 0 || lastInvestTime == 0 || _num == 0) {
            return;
        }
        if (_num > 100) {
            _num = 100;
        }
        address[] memory _list = new address[](_num);
        for (uint256 i = 0; i < _num; i++) {
            _list[i] = Last100Addresses.at(Last100Addresses.length() - i - 1);
        }
        uint256 _amount = totalCompensation / 2;
        totalCompensation -= _amount;
        uint256 _amountForTop = _amount * 50 / 100;
        address firstAddress = _list[0];
        userInfoList[firstAddress]._userDataItem._updatedCompensation += _amountForTop;
        if (_num > 1) {
            uint256 _amountForOther = (_amount - _amountForTop) / (_num - 1);
            for (uint256 i = 1; i < _num; i++) {
                userInfoList[_list[i]]._userDataItem._updatedCompensation += _amountForOther;
            }
        }
        uint256 _gas1 = gasleft();
        emit DistributeEvent(_day, _timestamp, "_distributeCompensation", _amount / 1e18, _amount / 1e18, _num, _gas0 - _gas1, firstAddress);
    }


    function _concatStrings(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    // 分配本周奖励
    function _distributeWeekReward(string memory _type) private {
        uint256 _gas0 = gasleft();
        uint256 _timestamp = block.timestamp;
        uint256 _day = getYearMonthDay(_timestamp, adjustHour);
        uint256 _num = weekAddressList[_type].length;
        uint256 _amount = weekReWardList[_type] * 50 / 100;
        // 如果本周排名人数小于7人，不进行奖励分配
        if (_num < 7) {
            return;
        }
        // 检查前7个地址是否全部相同，只有在这种情况下才会进行奖励分配
        address firstAddress = weekAddressList[_type][0];
        bool _canDistribute = true;
        for (uint256 i = 1; i < 7; i++) {
            if (weekAddressList[_type][i] != firstAddress) {
                _canDistribute = false;
                break;
            }
        }
        if (_canDistribute) {
            // 对第一名进行奖励分配
            userInfoList[firstAddress]._userDataItem._updatedWeeKReward += _amount;
            weekReWardList[_type] -= _amount;
        } else {
            //不分配是不是留到下一次或者截留
        }
        uint256 _gas1 = gasleft();
        emit DistributeEvent(_day, _timestamp, _concatStrings("_distributeWeekReward", _type), _amount / 1e18, _amount / 1e18, _num, _gas0 - _gas1, firstAddress);
        weekAddressList[_type] = new address[](0);
        weekDayList[_type] = new uint256[](0);
        weekDataList[_type] = new uint256[](0);
    }

    // 分配本周奖励
    //    function _distributeWeekRewardForInvest() private {
    //        uint256 _gas0 = gasleft();
    //        uint256 _timestamp = block.timestamp;
    //        uint256 _day = getYearMonthDay(_timestamp, adjustHour);
    //        uint256 _num = weekAddressList["Invest"].length;
    //        uint256 _amount = weekReWardList["invest"] * 50 / 100;
    //        // 如果本周排名人数小于7人，不进行奖励分配
    //        if (_num < 7) {
    //            return;
    //        }
    //        // 检查前7个地址是否全部相同，只有在这种情况下才会进行奖励分配
    //        address firstAddress = weekAddressList["Invest"][0];
    //        bool _canDistribute = true;
    //        for (uint256 i = 1; i < 7; i++) {
    //            if (weekAddressList["Invest"][i] != firstAddress) {
    //                _canDistribute = false;
    //                break;
    //            }
    //        }
    //        if (_canDistribute) {
    //            // 对第一名进行奖励分配
    //            userInfoList[firstAddress]._userDataItem._updatedWeeKReward += _amount;
    //            weekReWardList["Invest"] -= _amount;
    //        } else {
    //            //不分配是不是留到下一次或者截留
    //        }
    //        uint256 _gas1 = gasleft();
    //        emit DistributeEvent(_day, _timestamp, "_distributeWeekRewardForInvest", _amount / 1e18, _amount / 1e18, _num, _gas0 - _gas1, firstAddress);
    //        weekAddressList["Invest"] = new address[](0);
    //        weekDayList["Invest"] = new uint256[](0);
    //        weekDataList["Invest"] = new uint256[](0);
    //    }
    //
    //    // 分配本周奖励
    //    function _distributeWeekRewardForInvite() private {
    //        uint256 _gas0 = gasleft();
    //        uint256 _timestamp = block.timestamp;
    //        uint256 _day = getYearMonthDay(_timestamp, adjustHour);
    //        uint256 _num = weekAddressList["Invite"].length;
    //        uint256 _amount = weekReWardList["Invite"] * 50 / 100;
    //        // 如果本周排名人数小于7人，不进行奖励分配
    //        if (_num < 7) {
    //            return;
    //        }
    //        // 检查前7个地址是否全部相同，只有在这种情况下才会进行奖励分配
    //        address firstAddress = weekAddressList["Invite"][0];
    //        bool _canDistribute = true;
    //        for (uint256 i = 1; i < 7; i++) {
    //            if (weekAddressList["Invite"][i] != firstAddress) {
    //                _canDistribute = false;
    //                break;
    //            }
    //        }
    //        if (_canDistribute) {
    //            // 对第一名进行奖励分配
    //            userInfoList[firstAddress]._userDataItem._updatedWeeKReward += _amount;
    //            weekReWardList["Invite"] -= _amount;
    //        } else {
    //            //是否截留
    //        }
    //        uint256 _gas1 = gasleft();
    //        emit DistributeEvent(_day, _timestamp, "_distributeWeekRewardForInvite", _amount / 1e18, _amount / 1e18, _num, _gas0 - _gas1, firstAddress);
    //        // 清空地址数组
    //        //        weekTop1AddressListForInvite = new address[](0);
    //        weekAddressList["Invite"] = new address[](0);
    //        weekDayList["Invite"] = new uint256[](0);
    //        weekDataList["Invite"] = new uint256[](0);
    //    }

    function distributeAll() external {
        _distributeAll();
    }

    function _distributeAll() private {
        _distributeDayReward("Invest", 0);
        _distributeDayReward("Invite", 1);
        //todo 连续24小时没有入金，补偿池的50%分配给最后入金的100个地址
        _distributeCompensation();
        //todo 分配周排名奖励，连续7天第一名
        _distributeWeekReward("Invest");
        _distributeWeekReward("Invite");
    }

    // 给以下代码加上中文注释
    function _updateTotalADAList(uint256 _amount, uint256 _type) private {
        if (_type > maxDaoType || _type < 1) {
            return;
        }
        // 定义num、rate和currentADA变量
        uint256 num = DaoSetList[_type - 1].length();
        uint256 rate = rewardRateListForDao[_type - 1];
        uint256 currentADA;
        // 如果num为0，则将currentADA设置为0，否则计算currentADA
        if (num == 0) {
            uint256 _leftAmount = _amount * rate / 1000;
            rewardNew += _leftAmount;
            emit RewardNewEvent(block.timestamp, investEndIndex, daoEventList[_type - 1], _leftAmount / 1e18);
            // 如果num为0，则将currentADA设置为0
            currentADA = 0;
        } else {
            daoRewardData._allDaoRewardList[_type - 1] += _amount * rate / 1000;
            // 计算currentADA
            currentADA = (_amount * rate / 1000) / num;
            totalShareAllocation._totalDaoASAList[_type - 1] += currentADA;
            totalShareAllocationList[investEndIndex]._totalDaoASAList[_type - 1] = totalShareAllocation._totalDaoASAList[_type - 1];
        }
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

    function claimNewReward() external {
        //todo 等待更新
    }

    // 领取静态奖励
    function claimStaticReward() external {
        // 获取用户地址
        address _user = msg.sender;
        _updateStaticRewad(_user);
        // 更新所有奖励
        //_updateAllRewards(_user);
        // 获取待领取的静态奖励
        uint256 _pendingReward = userInfoList[_user]._userDataItem._updatedStaticReward;
        // 获取用户剩余的授信额度
        uint256 _userRemainingCredit = _getUserRemainingCredit(_user);
        // 如果待领取奖励大于用户剩余授信额度，则将待领取奖励设为用户剩余授信额度
        if (_pendingReward > _userRemainingCredit) {
            _pendingReward = _userRemainingCredit;
        }
        require(_pendingReward > 0, "The rewarded amount must be greater than 0");
        // 转移奖励给用户
        _transferReward(_user, _pendingReward, "claimStaticReward");
        // 更新用户已领取的静态奖励
        userInfoList[_user]._userDataItem._claimedStaticReward += _pendingReward;
        // 更新用户待领取的静态奖励
        userInfoList[_user]._userDataItem._updatedStaticReward -= _pendingReward;
    }

    function setNode(address[] memory _nodeList, bool _status) external onlyOwner {
        uint256 _num = _nodeList.length;
        address _user;
        for (uint256 i = 0; i < _num; i++) {
            _user = _nodeList[i];
            if (_status && !NodeSet.contains(_user)) {
                NodeSet.add(_user);
                userInfoList[_user]._userNodeItem = UserNodeItem(investEndIndex, 1);
            }
            if (!_status && NodeSet.contains(_user)) {
                //移除前结清node收益
                _updateNodeReward(_user);
                NodeSet.remove(_user);
                userInfoList[_user]._userNodeItem = UserNodeItem(investEndIndex, 0);
            }
        }
    }

    function claimNodeReward() external {
        // 获取用户地址
        address _user = msg.sender;
        _updateNodeReward(_user);
        // 更新所有奖励
        //_updateAllRewards(_user);
        // 获取待领取的静态奖励
        uint256 _pendingReward = userInfoList[_user]._userDataItem._updatedNodeReward;
        require(_pendingReward > 0, "The rewarded amount must be greater than 0");
        // 转移奖励给用户
        IERC20(daoToken).transfer(_user, _pendingReward * 97 / 100);
        IERC20(daoToken).transfer(addressConfig._marketAddress, _pendingReward * 3 / 100);
        // 更新用户已领取的静态奖励
        userInfoList[_user]._userDataItem._claimedNodeReward += _pendingReward;
        // 更新用户待领取的静态奖励
        userInfoList[_user]._userDataItem._updatedNodeReward = 0;
        userInfoList[_user]._userNodeItem._nodeStartIndex = investEndIndex;
        //        UserNodeItem memory x = userInfoList[_user]._userNodeItem;
        //        uint256 _nodeType = x._nodeType;
        //        userInfoList[_user]._userNodeItem = UserNodeItem(investEndIndex, _nodeType);
    }

    // 领取直接邀请奖励
    function claimDirectReferralReward() external {
        // 获取用户地址
        address _user = msg.sender;
        // 更新所有奖励
        //_updateAllRewards(_user);
        _updateStaticRewad(_user);
        // 获取待领取的邀请奖励
        uint256 _pendingReward = userInfoList[_user]._userDataItem._updatedDirectReferralReward;
        // 获取用户剩余的授信额度
        uint256 _userRemainingCredit = _getUserRemainingCredit(_user);
        // 如果待领取奖励大于用户剩余授信额度，则将待领取奖励设为用户剩余授信额度
        if (_pendingReward > _userRemainingCredit) {
            _pendingReward = _userRemainingCredit;
        }
        require(_pendingReward > 0, "The rewarded amount must be greater than 0");
        // 转移奖励给用户
        _transferReward(_user, _pendingReward, "claimDirectReferralReward");
        // 更新用户已领取的邀请奖励
        userInfoList[_user]._userDataItem._claimedDirectReferralReward += _pendingReward;
        // 更新用户待领取的邀请奖励
        userInfoList[_user]._userDataItem._updatedDirectReferralReward -= _pendingReward;
    }

    function claimTeamReward() external {
        // 获取用户地址
        address _user = msg.sender;
        // 更新所有奖励
        _updateStaticRewad(_user);
        // 获取待领取的邀请奖励
        uint256 _pendingReward = userInfoList[_user]._userDataItem._updatedTeamReward;
        // 获取用户剩余的授信额度
        uint256 _userRemainingCredit = _getUserRemainingCredit(_user);
        // 如果待领取奖励大于用户剩余授信额度，则将待领取奖励设为用户剩余授信额度
        if (_pendingReward > _userRemainingCredit) {
            _pendingReward = _userRemainingCredit;
        }
        require(_pendingReward > 0, "The rewarded amount must be greater than 0");
        // 转移奖励给用户
        _transferReward(_user, _pendingReward, "claimTeamReward");
        // 更新用户已领取的邀请奖励
        userInfoList[_user]._userDataItem._claimedTeamReward += _pendingReward;
        // 更新用户待领取的邀请奖励
        userInfoList[_user]._userDataItem._updatedTeamReward -= _pendingReward;
    }

    // 领取间接邀请奖励
    function claimIndirectReferralReward() external {
        // 获取用户地址
        address _user = msg.sender;
        // 更新所有奖励
        _updateStaticRewad(_user);
        //_updateAllRewards(_user);
        // 获取待领取的邀请奖励
        uint256 _pendingReward = userInfoList[_user]._userDataItem._updatedIndirectReferralReward;
        // 获取用户剩余的授信额度
        uint256 _userRemainingCredit = _getUserRemainingCredit(_user);
        // 如果待领取奖励大于用户剩余授信额度，则将待领取奖励设为用户剩余授信额度
        if (_pendingReward > _userRemainingCredit) {
            _pendingReward = _userRemainingCredit;
        }
        require(_pendingReward > 0, "The rewarded amount must be greater than 0");
        // 转移奖励给用户
        _transferReward(_user, _pendingReward, "claimIndirectReferralReward");
        // 更新用户已领取的邀请奖励
        userInfoList[_user]._userDataItem._claimedIndirectReferralReward += _pendingReward;
        // 更新用户待领取的邀请奖励
        userInfoList[_user]._userDataItem._updatedIndirectReferralReward -= _pendingReward;
    }

    // 领取DAO奖励
    function _claimDaoReward(address _user, uint256 _type) private {
        if (_type < 1 || _type > maxDaoType) {
            return;
        }
        // 确保_type的范围在1到4之间，且investIndex大于0
        _updateDaoRewad(_user, _type);
        // 获取待领取的DAO奖励
        uint256 _pendingReward;
        _pendingReward = userInfoList[_user]._userDataItem._updatedDaoRewardList[_type - 1];
        // 获取用户剩余的授信额度
        uint256 _userRemainingCredit = _getUserRemainingCredit(_user);
        // 如果待领取奖励大于用户剩余授信额度，则将待领取奖励设为用户剩余授信额度
        if (_pendingReward > _userRemainingCredit) {
            _pendingReward = _userRemainingCredit;
        }
        // 根据_type更新用户已领取的DAO奖励和待领取的DAO奖励
        daoRewardData._claimedDaoRewardList[_type - 1] += _pendingReward;
        userInfoList[_user]._userDataItem._claimedDaoRewardList[_type - 1] += _pendingReward;
        userInfoList[_user]._userDataItem._updatedDaoRewardList[_type - 1] -= _pendingReward;
        // 转移奖励给用户
        _transferReward(_user, _pendingReward, "claimDaoReward");
        // 更新用户的DAO信息
        //        UserDaoItem memory x = userInfoList[_user]._userDaoItem;
        //        uint256 _daoType = x._daoType;
        //        userInfoList[_user]._userDaoItem = UserDaoItem(investIndex - 1, _daoType);
        //升级之后领取之前的奖励不需要更新
        if (userInfoList[_user]._userDaoItem._daoType == _type) {
            userInfoList[_user]._userDaoItem._daoStartIndex = investEndIndex;
        }
    }

    function claimDaoReward(uint256 _type) external {
        //必须1-5之间
        require(_type > 0 && _type < maxDaoType + 1, "Bad Request");
        address _user = msg.sender;
        _updateStaticRewad(_user);
        uint256 b0 = IERC20(daoToken).balanceOf(_user);
        _claimDaoReward(_user, _type);
        uint256 b1 = IERC20(daoToken).balanceOf(_user);
        require(b1 - b0 > 0, "The rewarded amount must be greater than 0");
    }

    function claimAllDaoReward() external {
        address _user = msg.sender;
        _updateStaticRewad(_user);
        uint256 b0 = IERC20(daoToken).balanceOf(_user);
        for (uint56 i = 0; i < maxDaoType; i++) {
            _claimDaoReward(_user, i + 1);
        }
        uint256 b1 = IERC20(daoToken).balanceOf(_user);
        require(b1 - b0 > 0, "The rewarded amount must be greater than 0");
    }

    // 领取本周奖励
    function claimWeekReward() external {
        address _user = msg.sender;
        // 获取用户待领取的奖励金额
        uint256 _pendingReward = userInfoList[_user]._userDataItem._updatedWeeKReward;
        require(_pendingReward > 0, "The rewarded amount must be greater than 0");
        // 将奖励转账给用户
        IERC20(daoToken).transfer(_user, _pendingReward * 97 / 100);
        IERC20(daoToken).transfer(addressConfig._marketAddress, _pendingReward * 3 / 100);
        // 更新用户已领取的奖励金额
        userInfoList[_user]._userDataItem._claimedWeekReward += _pendingReward;
        // 清空用户待领取的奖励金额
        userInfoList[_user]._userDataItem._updatedWeeKReward -= _pendingReward;
    }

    // 对于邀请奖励，用户可以调用此函数来领取排名奖励
    function claimRankingForInvite() external {
        // 获取调用者的地址
        address _user = msg.sender;
        // 获取用户未领取的邀请奖励数量
        uint256 _pendingReward = userInfoList[_user]._userDataItem._updatedRankingInvite;
        require(_pendingReward > 0, "The rewarded amount must be greater than 0");
        // 调用合约中的 transfer 函数，将奖励发送给用户
        IERC20(daoToken).transfer(_user, _pendingReward * 97 / 100);
        IERC20(daoToken).transfer(addressConfig._marketAddress, _pendingReward * 3 / 100);
        // 将用户未领取的邀请奖励数量设为 0
        userInfoList[_user]._userDataItem._updatedRankingInvite = 0;
        // 将用户已领取的邀请奖励数量增加
        userInfoList[_user]._userDataItem._claimedRankingInvite += _pendingReward;
    }

    // 对于投资奖励，用户可以调用此函数来领取排名奖励
    function claimRankingForInvest() external {
        // 获取调用者的地址
        address _user = msg.sender;
        // 获取用户未领取的投资奖励数量
        uint256 _pendingReward = userInfoList[_user]._userDataItem._updatedRankingInvest;
        require(_pendingReward > 0, "The rewarded amount must be greater than 0");
        // 调用合约中的 transfer 函数，将奖励发送给用户
        IERC20(daoToken).transfer(_user, _pendingReward * 97 / 100);
        IERC20(daoToken).transfer(addressConfig._marketAddress, _pendingReward * 3 / 100);
        // 将用户未领取的投资奖励数量设为 0
        userInfoList[_user]._userDataItem._updatedRankingInvest = 0;
        // 将用户已领取的投资奖励数量增加
        userInfoList[_user]._userDataItem._claimedRankingInvest += _pendingReward;
    }

    // 用户可以调用此函数来领取补偿奖励
    function claimCompensation() external {
        // 获取调用者的地址
        address _user = msg.sender;
        // 获取用户未领取的补偿奖励数量
        uint256 _pendingReward = userInfoList[_user]._userDataItem._updatedCompensation;
        require(_pendingReward > 0, "The rewarded amount must be greater than 0");
        // 调用合约中的 transfer 函数，将奖励发送给用户
        IERC20(daoToken).transfer(_user, _pendingReward * 97 / 100);
        IERC20(daoToken).transfer(addressConfig._marketAddress, _pendingReward * 3 / 100);
        // 将用户未领取的补偿奖励数量设为 0
        userInfoList[_user]._userDataItem._updatedCompensation = 0;
        // 将用户已领取的补偿奖励数量增加
        userInfoList[_user]._userDataItem._claimedCompensation += _pendingReward;
    }

    /**
      * @dev 转移用户的奖励
      * @param _user 用户地址
      * @param _pendingReward 待转移的奖励数量
     */
    function _transferReward(address _user, uint256 _pendingReward, string memory _type) private {
        // 待转移的奖励数量必须大于0
        if (_pendingReward == 0) {
            return;
        }
        // 将待转移的奖励转移到用户地址
        IERC20(daoToken).transfer(_user, _pendingReward * 97 / 100);
        IERC20(daoToken).transfer(addressConfig._marketAddress, _pendingReward * 3 / 100);
        // 将转移的奖励数量添加到用户的总领取奖励中
        userInfoList[_user]._totalClaiRewardAmount += _pendingReward;
        // 计算用户剩余的授信额度
        uint256 _userRemainingCredit = _getUserRemainingCredit(_user);
        emit ClaimRewardEvent(_user, investEndIndex, getYearMonthDay(block.timestamp, adjustHour), block.timestamp, _type, _userRemainingCredit / 1e18);
        // 更新用户的投资列表
        userInfoList[_user]._userInvestItem = UserInvestItem(investEndIndex, _userRemainingCredit);
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
        userInfoList[_user]._userDataItem._updatedStaticReward += _totalReward;
    }

    /**
     * @dev 更新用户在指定类型的DAO中的奖励
     * @param _user 用户地址
     * @param _type DAO类型
      */
    function _updateDaoRewad(address _user, uint256 _type) private {
        //_type必须在1-5之间
        if (_type < 1 || _type > maxDaoType) {
            return;
        }
        uint256 _totalReward = _getDaoReward(_user, _type);
        userInfoList[_user]._userDataItem._updatedDaoRewardList[_type - 1] += _totalReward;
    }

    function _updateNodeReward(address _user) private {
        uint256 _totalReward = _getNodeReward(_user);
        userInfoList[_user]._userDataItem._updatedNodeReward += _totalReward;
    }

    function _updateBigNetAmountList(address _user) private {
        address _referrer = userInfoList[_user]._referrer;
        if (userInfoList[_user]._totalNetInvestment >= bigNetAmountList[_referrer]) {
            bigNetAmountList[_referrer] = userInfoList[_user]._totalNetInvestment;
        }
    }

    // 分发邀请奖励
    function _distributeInvitationReward(uint256 _amount, address _user) private {
        // 获取用户的所有推荐人列表和数量
        address[] memory _allReferrers = allReferrers[_user];
        uint256 _allReferrersNum = _allReferrers.length;
        // 初始化奖励金额和循环变量
        uint256 _rewardAmount;
        //第一次入金时自己的有效人数人数+1
        if (userInfoList[_user]._firstInvestTime == 0) {
            userInfoList[_user]._effectiveReferrerNet += 1;
            //直接上级的有效直推加1
            userInfoList[_allReferrers[0]]._effectiveDirectReferrals += 1;
        }
        uint256 _totalAmount;
        for (uint256 i = 0; i < _allReferrersNum; i++) {
            address _ferrer = _allReferrers[i];
            //用户第一次入金
            if (userInfoList[_user]._firstInvestTime == 0) {
                //所有推荐的有效网体人数+1
                userInfoList[_ferrer]._effectiveReferrerNet += 1;
            }
            //只分配给前12级,要求必须有直推3人才有奖励
            if (i < 12) {
                // 计算当前推荐人的奖励金额
                _rewardAmount = _amount * rewardRateList[i] / rewardAllRateList;
                // 更新当前推荐人的邀请奖励和网体投资额
                if (i == 0) {
                    userInfoList[_ferrer]._userDataItem._updatedDirectReferralReward += _rewardAmount;
                    _totalAmount += _rewardAmount;
                    emit DistributeInvitationRewardEvent(_ferrer, block.timestamp, investIndex, "updatedDirectReferralReward", _rewardAmount / 1e18);
                } else {
                    //二级间推要求有推荐人
                    if (i == 1 || (i > 1 && referrals[_ferrer].length > 2)) {
                        _totalAmount += _rewardAmount;
                        if (i == 1) {
                            userInfoList[_ferrer]._userDataItem._updatedIndirectReferralReward += _rewardAmount;
                            emit DistributeInvitationRewardEvent(_ferrer, block.timestamp, investIndex, "updatedIndirectReferralReward", _rewardAmount / 1e18);
                        } else {
                            userInfoList[_ferrer]._userDataItem._updatedTeamReward += _rewardAmount;
                            emit DistributeInvitationRewardEvent(_ferrer, block.timestamp, investIndex, "updatedTeamReward", _rewardAmount / 1e18);
                        }
                    }
                }
            }
            userInfoList[_ferrer]._totalNetInvestment += _amount;
            //更新推荐人上级的最大网体
            _updateBigNetAmountList(_ferrer);
            // 更新当前推荐人的 Dao 等级和奖励列表
            _updateDao(_ferrer, investIndex);
        }
        uint256 _leftAmount = _amount * 42 / 100 - _totalAmount;
        rewardNew += _leftAmount;
        emit RewardNewEvent(block.timestamp, investEndIndex, "RewardNewInvite", _leftAmount / 1e18);
        //更新推荐人的最大网体
        _updateBigNetAmountList(_user);
    }

    //根据记录的最大网体直接判断是否可以升级
    function _canUpgrade2(address _user, uint256 _allNetAmount, uint256 _daoAmount) private view returns (bool) {
        if (_daoAmount == 0) {
            return false;
        }
        uint256 okAmount = bigNetAmountList[_user];
        uint256 totalSmallAmount = _allNetAmount - okAmount;
        if (okAmount >= _daoAmount && totalSmallAmount >= _daoAmount) {
            return true;
        } else {
            return false;
        }
    }

    //此段代码实现梯级升级模式，必须从4到1依次升级
    function _updateDao(address _user, uint256 _investStartIndex) private {
        // 获取用户的推荐人列表和推荐人数
        uint256 _num = referrals[_user].length;
        //获取用户当前等级
        uint256 _daoType = userInfoList[_user]._userDaoItem._daoType;
        // 如果用户推荐人数小于3或者已经达到最高等级，则直接返回
        if (_num < 3 || _daoType >= maxDaoType) {
            return;
        }
        // 计算用户的总净投资额，如果不足以达到升级到下一个等级的门槛，则直接返回
        uint256 _allNetAmount = userInfoList[_user]._totalNetInvestment - userInfoList[_user]._depositAmount;
        //总业绩达不到下一级升级标准
        if (_allNetAmount < daoAmountList[_daoType] * 2) {
            return;
        }
        bool canUpgrade_ = _canUpgrade2(_user, _allNetAmount, daoAmountList[_daoType]);
        if (canUpgrade_) {
            if (_daoType > 0) {
                DaoSetList[_daoType - 1].remove(_user);
            }
            DaoSetList[_daoType].add(_user);
            _updateDaoRewad(_user, _daoType);
            userInfoList[_user]._userDaoItem = UserDaoItem(_investStartIndex, _daoType + 1);
            emit UpgradeDaoEvent(_user, block.timestamp, _investStartIndex, _daoType + 1);
        }
    }

    function _updateRanking(uint256 _day, address _user, uint256 _addAmount, uint256 _takeNum, string memory _type, mapping(string => mapping(uint256 => mapping(address => uint256))) storage _data, mapping(string => mapping(uint256 => EnumerableSet.AddressSet)) storage _set) private {
        uint256 _newAmount = _data[_type][_day][_user] + _addAmount;
        _data[_type][_day][_user] = _newAmount;
        if (_set[_type][_day].contains(_user)) {
            return;
        }
        uint256 _num = _set[_type][_day].length();
        if (_num < _takeNum) {
            _set[_type][_day].add(_user);
        } else {
            address[] memory x = _set[_type][_day].values();
            for (uint256 i = 0; i < _takeNum; i++) {
                address _addressItem = x[i];
                if (_data[_type][_day][_addressItem] < _newAmount) {
                    _set[_type][_day].remove(_addressItem);
                    _set[_type][_day].add(_user);
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
            Last100Addresses.remove(sender);
        }
        // 如果集合中已经有100个地址，则移除第一个地址。
        if (Last100Addresses.length() == 100) {
            Last100Addresses.remove(Last100Addresses.at(0));
        }
        // 将新地址添加到集合中。
        Last100Addresses.add(sender);
    }

    function _getNodeReward(address _user) internal view returns (uint256) {
        // 如果总投资次数为0，则返回0
        if (investIndex == 0) {
            return 0;
        }
        // 获取用户的投资信息
        UserNodeItem memory x = userInfoList[_user]._userNodeItem;
        uint256 _nodeStartIndex = x._nodeStartIndex;
        uint256 _nodeType = x._nodeType;
        if (_nodeType == 0) {
            return 0;
        }
        if (_nodeStartIndex == 0) {
            return totalShareAllocationList[investEndIndex]._totalNodeASA;
        }
        // 获取用户的静态收益
        uint256 _totalNodeASA = totalShareAllocationList[investEndIndex]._totalNodeASA - totalShareAllocationList[_nodeStartIndex]._totalNodeASA;
        return _totalNodeASA;
    }

    function _getStaticReward(address _user) internal view returns (uint256) {
        // 如果总投资次数为0，则返回0
        if (investIndex == 0) {
            return 0;
        }
        // 获取用户的投资信息
        UserInvestItem memory x = userInfoList[_user]._userInvestItem;
        uint256 _investStartIndex = x._investStartIndex;
        uint256 _remainingCredit = x._remainingCredit;
        // 获取用户的静态收益
        uint256 _totalASA = totalShareAllocationList[investEndIndex]._totalASA - totalShareAllocationList[_investStartIndex]._totalASA;
        uint256 _totalReward = _remainingCredit * _totalASA / 1e18;
        return _totalReward;
    }

    function _getDaoReward(address _user, uint256 _type) internal view returns (uint256) {
        // 如果总投资数为0或类型不在1到4之间或用户没有加入任何DAO，则返回0
        if (investIndex == 0 || _type < 1 || _type > 5 || userInfoList[_user]._userDaoItem._daoType == 0) {
            return 0;
        }
        // 获取用户的DAO信息
        UserDaoItem memory x = userInfoList[_user]._userDaoItem;
        uint256 _daoStartIndex = x._daoStartIndex;
        uint256 _daoType = x._daoType;
        // 获取用户在指定类型的DAO中的奖励
        uint256 _totalReward;
        if (_daoType == _type) {
            _totalReward = totalShareAllocationList[investEndIndex]._totalDaoASAList[_type - 1] - totalShareAllocationList[_daoStartIndex]._totalDaoASAList[_type - 1];
        }
        return _totalReward;
    }

    //借助中间结构体实现排序
    function _sortRanking(address[] memory _List, uint256 _day, mapping(uint256 => mapping(address => uint256))  storage data) internal view returns (address[] memory y, uint256[] memory w){
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

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

contract SortList {
    function sortUint256List(uint256[] memory a) internal pure returns (uint256[] memory) {
        uint256 num = a.length;
        uint256[] memory b = new uint256[](num);
        for (uint256 i = 0; i < num; i++) {
            b[i] = a[i];
        }
        for (uint256 i = 1; i < num; i++) {
            uint256 temp = b[i];
            uint256 j = i;
            for (; j > 0 && temp > b[j - 1]; j--) {
                b[j] = b[j - 1];
            }
            b[j] = temp;
        }
        return b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

contract StructForDao {
    enum SetType {
        Last100Addresses,
        NodeSet
    }

    struct ShareItem {
        uint256 _totalASA; //累积静态分配指数
        uint256 _totalNodeASA; //累积节点收益
        uint256[10] _totalDaoASAList;
    }

    struct UserInvestItem {
        uint256 _investStartIndex;
        uint256 _remainingCredit;
    }

    struct UserNodeItem {
        uint256 _nodeStartIndex;
        uint256 _nodeType; //0为非节点,1为节点
    }

    struct UserDaoItem {
        uint256 _daoStartIndex;
        uint256 _daoType;
    }

    struct AddressItem {
        address _techAddress; //2%
        address _marketAddress; //3%
        address _daoAddress;  //5%
    }

    struct UserDataItem {
        //跟剩余额度挂钩的更新数据
        uint256 _updatedStaticReward;
        uint256 _updatedDirectReferralReward;
        uint256 _updatedIndirectReferralReward;
        uint256 _updatedTeamReward;
        uint256[10] _updatedDaoRewardList;
        //跟剩余额度无关的更新数据
        uint256 _updatedNodeReward;
        uint256 _updatedWeeKReward;
        uint256 _updatedRankingInvite;
        uint256 _updatedRankingInvest;
        uint256 _updatedCompensation;
        //跟剩余额度挂钩的已领取数据
        uint256 _claimedStaticReward;
        uint256 _claimedDirectReferralReward;
        uint256 _claimedIndirectReferralReward;
        uint256 _claimedTeamReward;
        uint256[10] _claimedDaoRewardList;
        //跟剩余额度无关的已领取数据
        uint256 _claimedNodeReward;
        uint256 _claimedWeekReward;
        uint256 _claimedRankingInvite;
        uint256 _claimedRankingInvest;
        uint256 _claimedCompensation;
    }

    struct UserInfo {
        address _referrer; //推荐人
        uint256 _referrerNet; //总网体人数
        uint256 _effectiveReferrerNet;  //有效网体人数
        uint256 _effectiveDirectReferrals; //有效直推人数
        uint256 _referTime; //绑定推荐人的时间
        uint256 _depositAmount; //自己的总入金
        uint256 _totalNetInvestment; //网体总入金
        uint256 _totalClaiRewardAmount; //已经领取的收益总额
        uint256 _firstInvestTime; //第一次入金时间
        UserDataItem _userDataItem;
        UserInvestItem _userInvestItem;
        UserDaoItem _userDaoItem;
        UserNodeItem _userNodeItem;
    }

    struct BaseItem3 {
        uint256[10] _allDaoRewardList;
        uint256[10] _claimedDaoRewardList;
    }

    struct SortItem {
        address _address;
        uint256 _num;
    }

    struct InvestItem {
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

    struct InvestInfoItem {
        address _user;
        uint256 _investIndex;
        uint256 _amount;
        uint256 _totalASA; //累积静态分配指数
        uint256[10] _totalDaoASAList;
        uint256 _timestamp;
        uint256 _day;
        uint256 _remainingCredit;
    }

    //todo 结构体的容量为256
    struct OnlyReadItem {
        address daoToken;
        address daoNftToken;
        uint256 adjustHour;
        uint256[10] daoAmountList;
        string[10] daoEventList;
        uint256 totalCompensation;
        uint256 investIndex;
        uint256 investEndIndex;
        uint256 tatalInvestAmount;
        uint256 remainingCredit;
        uint256 lastInvestTime;
        uint256 maxDaoType;
        uint256 rewardNew;
        uint256 compensationInterval;
        uint256 rewardAllRateList;
        uint256 weekRewardForInvest;
        uint256 weekRewardForInvite;
        uint256 totalInvestMember;
        //日数据
        uint256 poolOfDayRewardForInvestRankings;
        uint256 poolOfDayRewardForInviteRankings;
        uint256 poolOfDayRewardForInvestRankings2; //上一天数据
        uint256 poolOfDayRewardForInviteRankings2; //上一天数据
        //周数据
        uint256[] weekDataListForInvest;
        uint256[] weekDataListForInvite;
        address[] weekAddressListForInvest;
        address[] weekAddressListForInvite;
        uint256[] weekDayListForInvest;
        uint256[] weekDayListForInvite;

        uint256[10] rewardRateListForDao;
        uint256[20] rewardRateList;
        uint256[20] rewardRateListForInviteRanking;
        uint256[20] rewardRateListForInvestRanking;
        uint256[10] daoNumberList;
        AddressItem addressConfig;
        TotalItemList totalConfig;
        BaseItem3 daoRewardData;
    }

    struct OnlyReadItemForUser {
        bool blackList;
        bool whiteList;
        uint256 daoBalance;
        uint256 gasBalance;
        uint256 _staticReward;
        uint256 _nodeReward;
        uint256[10] _daoRewardList;
        uint256 bigNetAmountList;
        UserInfo userInfoList;
        DaoInfoItem DaoInfoItem_;
        DaoInfoItem[] DaoInfoItemList_;
        address[] referrals_;
        address[] allReferrers_;
        address[] effectiveReferrals_;
    }

    struct TotalUint256Item {
        uint256 a1;
        uint256 a2;
        uint256 a3;
        uint256 a4;
        uint256 a5;
        uint256 a6;
        uint256 a7;
        uint256 a8;
        uint256 a9;
        uint256 a10;
        uint256 a11;
        uint256 a12;
    }

    struct TotalAddressItem {
        address b1;
        address b2;
        address b3;
        address b4;
        address b5;
        address b6;
        address b7;
        address b8;
        address b9;
        address b10;
        address b11;
        address b12;
    }

    struct TotalBoolItem {
        bool c1;
        bool c2;
        bool c3;
        bool c4;
        bool c5;
        bool c6;
        bool c7;
        bool c8;
        bool c9;
        bool c10;
        bool c11;
        bool c12;
    }

    struct TotalItemList {
        TotalUint256Item _totalUint256Item;
        TotalAddressItem _totalAddressItem;
        TotalBoolItem _totalBoolItem;
    }

    struct DaoInfoItem {
        address _user;
        uint256 _daoType;
        uint256 _depositAmount; //自己的入金
        uint256 _totalNetInvestment; //网体总入金(包含自己的入金)
        uint256 _bigAmount; //最大区入金
        uint256 _otherAmounts; //其他小区入金总和
        uint256 _referrerNet; //总网体人数
        uint256 _effectiveReferrerNet;  //有效网体人数
        uint256 _referralsNumber;
        uint256 _effectiveDirectReferrals; //有效直推人数
    }
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

    function getYearMonthDay2(uint256 _timestamp, uint256 _adjustHour) internal pure returns (_DateTime memory dt) {
        dt = parseTimestamp(_timestamp + _adjustHour * 3600);
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