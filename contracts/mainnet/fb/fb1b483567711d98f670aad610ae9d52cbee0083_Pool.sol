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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

////////////////////////////////////////////////////////////////////////////////
// Monetary Types and Their Helpers
////////////////////////////////////////////////////////////////////////////////

/// Time value represented by uint32 unix timestamp.
type Time is uint32;
function mt_t_add_t(Time a, Time b) pure returns (Time) { return Time.wrap(Time.unwrap(a) + Time.unwrap(b)); }
function mt_t_sub_t(Time a, Time b) pure returns (Time) { return Time.wrap(Time.unwrap(a) - Time.unwrap(b)); }
using { mt_t_add_t as +, mt_t_sub_t as - } for Time global;

/// Monetary value represented with signed integer.
type Value is int256;
function mt_v_add_v(Value a, Value b) pure returns (Value) {
    return Value.wrap(Value.unwrap(a) + Value.unwrap(b));
}
function mt_v_sub_v(Value a, Value b) pure returns (Value) {
    return Value.wrap(Value.unwrap(a) - Value.unwrap(b));
}
using { mt_v_add_v as +, mt_v_sub_v as - } for Value global;

/// Unit value represented with half the size of `Value`.
type Unit is int128;
function mt_u_add_u(Unit a, Unit b) pure returns (Unit) {
    return Unit.wrap(Unit.unwrap(a) + Unit.unwrap(b));
}
function mt_u_sub_u(Unit a, Unit b) pure returns (Unit) {
    return Unit.wrap(Unit.unwrap(a) - Unit.unwrap(b));
}
using { mt_u_add_u as +, mt_u_sub_u as - } for Unit global;

/**
 * @dev FlowRate value represented with half the size of `Value`.
 *
 * It is important to make sure that `FlowRate` multiplying with either `Time`
 * or `Unit` does not exceed the range of `Value`.
 */
type FlowRate is int128;
function mt_r_add_r(FlowRate a, FlowRate b) pure returns (FlowRate) {
    return FlowRate.wrap(FlowRate.unwrap(a) + FlowRate.unwrap(b));
}
function mt_r_sub_r(FlowRate a, FlowRate b) pure returns (FlowRate) {
    return FlowRate.wrap(FlowRate.unwrap(a) - FlowRate.unwrap(b));
}
using { mt_r_add_r as +, mt_r_sub_r as - } for FlowRate global;

/**
 * @dev Additional helper functions for the monetary types
 *
 * Note that due to solidity current limitations, operators for mixed user defined value types
 * are not supported, hence the need of this library.
 * Read more at: https://github.com/ethereum/solidity/issues/11969#issuecomment-1448445474
 */
library AdditionalMonetaryTypeHelpers {
    function inv(Value x) internal pure returns (Value) {
        return Value.wrap(-Value.unwrap(x));
    }
    function mul(Value a, Unit b) internal pure returns (Value) {
        return Value.wrap(Value.unwrap(a) * int256(Unit.unwrap(b)));
    }
    function div(Value a, Unit b) internal pure returns (Value) {
        return Value.wrap(Value.unwrap(a) / int256(Unit.unwrap(b)));
    }

    function inv(FlowRate r) internal pure returns (FlowRate) {
        return FlowRate.wrap(-FlowRate.unwrap(r));
    }

    function mul(FlowRate r, Time t) internal pure returns (Value) {
        return Value.wrap(FlowRate.unwrap(r) * int(uint(Time.unwrap(t))));
    }
    function mul(FlowRate r, Unit u) internal pure returns (FlowRate) {
        return FlowRate.wrap(FlowRate.unwrap(r) * Unit.unwrap(u));
    }
    function div(FlowRate a, Unit b) internal pure returns (FlowRate) {
        return FlowRate.wrap(FlowRate.unwrap(a) / Unit.unwrap(b));
    }
    function quotRem(FlowRate r, Unit u) internal pure returns (FlowRate nr, FlowRate er) {
        // quotient and remainder
        nr = FlowRate.wrap(FlowRate.unwrap(r) / Unit.unwrap(u));
        er = FlowRate.wrap(FlowRate.unwrap(r) % Unit.unwrap(u));
    }
    function mul_quotRem(FlowRate r, Unit u1, Unit u2) internal pure returns (FlowRate nr, FlowRate er) {
        return r.mul(u1).quotRem(u2);
    }
}
using AdditionalMonetaryTypeHelpers for Time global;
using AdditionalMonetaryTypeHelpers for Value global;
using AdditionalMonetaryTypeHelpers for FlowRate global;
using AdditionalMonetaryTypeHelpers for Unit global;

////////////////////////////////////////////////////////////////////////////////
// Basic particle
////////////////////////////////////////////////////////////////////////////////
/**
 * @dev Basic particle: the building block for payment primitives.
 */
struct BasicParticle {
    Time     settled_at;
    Value    settled_value;
    FlowRate flow_rate;
}

////////////////////////////////////////////////////////////////////////////////
// Proportional Distribution Pool Data Structures.
//
// Such pool has one index and many members.
////////////////////////////////////////////////////////////////////////////////
/**
 * @dev Proportional distribution pool index data.
 */
struct PDPoolIndex {
    Unit          total_units;
    // The value here are usually measured per unit
    BasicParticle wrapped_particle;
}

/**
 * @dev Proportional distribution pool member data.
 */
struct PDPoolMember {
    Unit          owned_unit;
    Value         settled_value;
    // It is a copy of the wrapped_particle of the index at the time an operation is performed.
    BasicParticle synced_particle;
}

/**
 * @dev Proportional distribution pool "monetary unit" for a member.
 */
struct PDPoolMemberMU {
    PDPoolIndex  i;
    PDPoolMember m;
}

/**
 * @dev Semantic Money Library: providing generalized payment primitives.
 *
 * Notes:
 *
 * - Basic payment 2-primitives include shift2 and flow2.
 * - As its name suggesting, 2-primitives work over two parties, each party is represented by an "index".
 * - A universal index is BasicParticle plus being a Monoid. It is universal in the sense that every monetary
 * unit should have one and only one such index.
 * - Proportional distribution pool has one index per pool.
 * - This solidity library provides 2-primitives for `UniversalIndex-to-UniversalIndex` and
 *   `UniversalIndex-to-ProportionalDistributionPoolIndex`.
 */
library SemanticMoney {
    //
    // Basic Particle Operations
    //

    /// Pure data clone function.
    function clone(BasicParticle memory a) internal pure returns (BasicParticle memory b) {
        // TODO memcpy
        b.settled_at = a.settled_at;
        b.settled_value = a.settled_value;
        b.flow_rate = a.flow_rate;
    }

    /// Monetary unit settle function for basic particle/universal index.
    function settle(BasicParticle memory a, Time t) internal pure returns (BasicParticle memory b) {
        b = a.clone();
        b.settled_value = rtb(a, t);
        b.settled_at = t;
    }

    /// Monetary unit rtb function for basic particle/universal index.
    function rtb(BasicParticle memory a, Time t) internal pure returns (Value v) {
        return a.flow_rate.mul(t - a.settled_at) + a.settled_value;
    }

    function shift1(BasicParticle memory a, Value x) internal pure returns (BasicParticle memory b) {
        b = a.clone();
        b.settled_value = b.settled_value + x;
    }

    function flow1(BasicParticle memory a, FlowRate r) internal pure returns (BasicParticle memory b) {
        b = a.clone();
        b.flow_rate = r;
    }

    //
    // Universal Index Additional Operations
    //

    // Note: the identity element is trivial, the default BasicParticle value will do.

    /// Monoid binary operator for basic particle/universal index.
    function mappend(BasicParticle memory a, BasicParticle memory b)
        internal pure returns (BasicParticle memory c) {
        // Note that the original spec abides the monoid laws even when time value is negative.
        Time t = Time.unwrap(a.settled_at) > Time.unwrap(b.settled_at) ? a.settled_at : b.settled_at;
        BasicParticle memory a1 = a.settle(t);
        BasicParticle memory b1 = b.settle(t);
        c.settled_at = t;
        c.settled_value = a1.settled_value + b1.settled_value;
        c.flow_rate = a1.flow_rate + b1.flow_rate;
    }

    //
    // Universal Index to Universal Index 2-primitives
    //

    function shift2(BasicParticle memory a, BasicParticle memory b, Value x) internal pure
        returns (BasicParticle memory m, BasicParticle memory n) {
        m = a.shift1(x.inv());
        n = b.shift1(x);
    }

    function flow2(BasicParticle memory a, BasicParticle memory b, FlowRate r, Time t) internal pure
        returns (BasicParticle memory m, BasicParticle memory n) {
        m = a.settle(t).flow1(r.inv());
        n = b.settle(t).flow1(r);
    }

    //
    // Proportional Distribution Pool Index Operations
    //

    /// Pure data clone function.
    function clone(PDPoolIndex memory a) internal pure returns (PDPoolIndex memory b) {
        b.total_units = a.total_units;
        b.wrapped_particle = a.wrapped_particle.clone();
    }

    /// Monetary unit settle function for pool index.
    function settle(PDPoolIndex memory a, Time t) internal pure
        returns (PDPoolIndex memory m)
    {
        m = a.clone();
        m.wrapped_particle = m.wrapped_particle.settle(t);
    }

    function shift2(BasicParticle memory a, PDPoolIndex memory b, Value x) internal pure
        returns (BasicParticle memory m, PDPoolIndex memory n, Value x1) {
        if (Unit.unwrap(b.total_units) != 0) {
            x1 = x.div(b.total_units).mul(b.total_units);
            m = a.shift1(x1.inv());
            n = b.clone();
            n.wrapped_particle = b.wrapped_particle.shift1(x1.div(b.total_units));
        } else {
            m = a.clone();
            n = b.clone();
        }
    }

    function flow2(BasicParticle memory a, PDPoolIndex memory b, FlowRate r, Time t) internal pure
        returns (BasicParticle memory m, PDPoolIndex memory n, FlowRate r1)
    {
        if (Unit.unwrap(b.total_units) != 0) {
            r1 = r.div(b.total_units).mul(b.total_units);
            m = a.settle(t).flow1(r1.inv());
            n = b.settle(t);
            n.wrapped_particle = n.wrapped_particle.flow1(r1.div(b.total_units));
        } else {
            m = a.settle(t).flow1(FlowRate.wrap(0));
            n = b.settle(t);
            n.wrapped_particle = n.wrapped_particle.flow1(FlowRate.wrap(0));
        }
    }

    //
    // Proportional Distribution Pool Member Operations
    //

    /// Pure data clone function.
    function clone(PDPoolMember memory a) internal pure returns (PDPoolMember memory b) {
        b.owned_unit = a.owned_unit;
        b.settled_value = a.settled_value;
        b.synced_particle = a.synced_particle.clone();
    }

    /// Monetary unit settle function for pool member.
    function settle(PDPoolMemberMU memory a, Time t) internal pure
        returns (PDPoolMemberMU memory b)
    {
        // TODO b.i doesn't actually change, some optimization may be desired
        b.i = a.i.clone();
        b.m = a.m.clone();
        b.m.settled_value = (a.i.wrapped_particle.rtb(t) - a.m.synced_particle.rtb(t))
            .mul(a.m.owned_unit);
    }

    /// Monetary unit rtb function for pool member.
    function rtb(PDPoolMemberMU memory a, Time t) internal pure
        returns (Value v)
    {
        return a.m.settled_value +
            (a.i.wrapped_particle.rtb(t) - a.m.synced_particle.rtb(a.m.synced_particle.settled_at))
            .mul(a.m.owned_unit);
    }

    /// Update the unit amount of the member of the pool
    function pool_member_update(PDPoolMemberMU memory b1, BasicParticle memory a, Unit u, Time t)
        internal pure
        returns (PDPoolIndex memory p, PDPoolMember memory p1, BasicParticle memory b)
    {
        Unit oldTotalUnit = b1.i.total_units;
        Unit newTotalUnit = oldTotalUnit + u - b1.m.owned_unit;
        PDPoolMemberMU memory b1s = PDPoolMemberMU(b1.i.settle(t), b1.m).settle(t);

        // align "a" because of the change of total units of the pool
        FlowRate nr = b1s.i.wrapped_particle.flow_rate;
        FlowRate er;
        if (Unit.unwrap(newTotalUnit) != 0) {
            (nr, er) = nr.mul_quotRem(oldTotalUnit, newTotalUnit);
            er = er;
        } else {
            er = nr.mul(oldTotalUnit);
            nr = FlowRate.wrap(0);
        }
        b1s.i.wrapped_particle = b1s.i.wrapped_particle.flow1(nr);
        b1s.i.total_units = newTotalUnit;
        b = a.settle(t).flow1(a.flow_rate + er);

        p = b1s.i;
        p1 = b1s.m;
        p1.owned_unit = u;
        p1.synced_particle = b1s.i.wrapped_particle.clone();
    }
}
using SemanticMoney for BasicParticle global;
using SemanticMoney for PDPoolIndex global;
using SemanticMoney for PDPoolMember global;
using SemanticMoney for PDPoolMemberMU global;

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@superfluid-finance/solidity-semantic-money/src/SemanticMoney.sol";


type FlowId is uint32;

/**
 * @dev A proportional distribution pool.
 */
contract Pool is Ownable {
    address public distributor;
    PDPoolIndex internal _index;
    mapping (address member => PDPoolMember member_data) internal _members;

    constructor (address distributor_) Ownable() {
        distributor = distributor_;
    }

    // NOTE: Solidity public function for the storage fields do not support structs.
    //       They are added manually instead.

    function getIndex() external view returns (PDPoolIndex memory) { return _index; }
    function setIndex(PDPoolIndex calldata index) onlyOwner external { _index = index; }
    function getMember(address member) external view returns (PDPoolMember memory) { return _members[member]; }

    function updatePoolMember(address member, Unit unit) external returns (bool) {
        require(Unit.unwrap(unit) >= 0, "Negative unit number not supported");
        require(msg.sender == distributor, "not the distributor!");
        Time t = Time.wrap(uint32(block.timestamp));
        BasicParticle memory p;
        (_index, _members[member], p) = PDPoolMemberMU(_index, _members[member]).pool_member_update(p, unit, t);
        SuperToken(owner()).absorb(distributor, p);
        return true;
    }

    // claim()
}

/**
 * @dev A very special super token for testing and fun.
 *
 * Features:
 * - Pure super token, no ERC20 wrapping business.
 * - Negative account is allowed,
 * - no permission control for account going negative.
 */
contract SuperToken is IERC20 {
    using EnumerableSet for EnumerableSet.AddressSet;

    // immutable internal Pool _POOL_IMPLEMENTATION;
    //FlowId constant public ALL_FLOWS_FLOW_ID = FlowId.wrap(type(uint32).max);

    mapping (address owner => BasicParticle) public uIndexes;
    mapping (bytes32 flowAddress => FlowRate) public flowRates;
    mapping (Pool pool => bool exist) public pools;
    mapping (address owner => EnumerableSet.AddressSet) internal _connectionsMap;
    mapping(address => mapping(address => uint256)) private _allowances;

    string public constant name = "GoldFOMO";
    string public constant symbol = "GF";

    ////////////////////////////////////////////////////////////////////////////////
    // ERC20 operations
    ////////////////////////////////////////////////////////////////////////////////

    function totalSupply() external pure returns (uint256) {
        // Yes, I mean it.
        return 0;
    }

    function balanceOf(address account) external view returns (uint256) {
        Time t = Time.wrap(uint32(block.timestamp));
        int256 x = Value.unwrap(uIndexes[account].rtb(t));
        EnumerableSet.AddressSet storage connections = _connectionsMap[account];
        for (uint i = 0; i < connections.length(); ++i) {
            address p = connections.at(i);
            x += Value.unwrap(PDPoolMemberMU(Pool(p).getIndex(), Pool(p).getMember(account)).rtb(t));
        }
        return x > 0 ? uint256(x) : 0;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        return _transferFrom(from, to, amount);
    }

    function _transferFrom(address from, address to, uint256 amount) internal returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        // Make updates
        (uIndexes[from], uIndexes[to]) = uIndexes[from].shift2(uIndexes[to], Value.wrap(int256(amount)));
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    ////////////////////////////////////////////////////////////////////////////////
    // Generalized Payment Primitives
    ////////////////////////////////////////////////////////////////////////////////

    // This is the non-ERC20 version of instant transfer, that can trigger actions defined by "to"
    function iTransfer(address from, address to, Value amount) external
        returns (bool success) {
        require(Value.unwrap(amount) >= 0, "don't even try");
        return _transferFrom(from, to, uint256(Value.unwrap(amount)));
    }

    // flowRef??? = keccack256(abi.encode(block.chainId, from, to, subFlowId));

    function flow(address from, address to, FlowId flowId, FlowRate flowRate) external
        returns (bool success) {
        Time t = Time.wrap(uint32(block.timestamp));
        bytes32 flowAddress = keccak256(abi.encode(from, to, flowId));
        // FIXME: plug permission controls
        require(msg.sender == from);
        // Make updates
        (uIndexes[from], uIndexes[to]) = uIndexes[from].flow2(uIndexes[to], flowRate, t);
        flowRates[flowAddress] = flowRate;
        return true;
    }

    function distribute(address from, Pool to, Value reqAmount) external
        returns (bool success, Value actualAmount) {
        require(pools[to], "Not a pool!");
        // FIXME: plug permission controls
        require(msg.sender == from);
        require(to.distributor() == from, "Not the distributor!");
        // Make updates
        PDPoolIndex memory pdidx = to.getIndex();
        (uIndexes[from], pdidx, actualAmount) = uIndexes[from].shift2(pdidx, reqAmount);
        to.setIndex(pdidx);
        success = true;
    }

    function distributeFlow(address from, Pool to, FlowId flowId, FlowRate reqFlowRate) external
        returns (bool success, FlowRate actualFlowRate) {
        require(pools[to], "Not a pool!");
        Time t = Time.wrap(uint32(block.timestamp));
        bytes32 flowAddress = keccak256(abi.encode(from, to, flowId));
        // FIXME: plug permission controls
        require(msg.sender == from);
        require(to.distributor() == from, "Not the distributor!");
        // Make updates
        PDPoolIndex memory pdidx = to.getIndex();
        (uIndexes[from], pdidx, actualFlowRate) = uIndexes[from].flow2(pdidx, reqFlowRate, t);
        to.setIndex(pdidx);
        flowRates[flowAddress] = actualFlowRate;
        success = true;
    }

    function connectPool(Pool to) external
        returns (bool success) {
        return connectPool(to, true);
    }

    function disconnectPool(Pool to) external
        returns (bool success) {
        return connectPool(to, false);
    }

    function connectPool(Pool to, bool doConnect) public
        returns (bool success) {
        if (doConnect) {
            _connectionsMap[msg.sender].add(address(to));
        } else {
            _connectionsMap[msg.sender].remove(address(to));
        }
        return true;
    }

    // Desirable option: isPool(to) ? without lookup table, O(1) !! NOT POSSIBLE !!
    // Other options:
    //   a) use flowId
    //   b) split into two functions: flow, distributeFlow

    ////////////////////////////////////////////////////////////////////////////////
    // Pool Operations
    ////////////////////////////////////////////////////////////////////////////////

    function createPool() external returns (Pool pool) {
        pool = new Pool(msg.sender);
        pools[pool] = true;
    }

    function absorb(address account, BasicParticle calldata p) external {
        require(pools[Pool(msg.sender)], "Only absorbing from pools");
        uIndexes[account] = uIndexes[account].mappend(p);
    }

    ////////////////////////////////////////////////////////////////////////////////
    // ERC20-style approval/allowance System for shift2
    ////////////////////////////////////////////////////////////////////////////////

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = _allowances[owner][spender];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

}