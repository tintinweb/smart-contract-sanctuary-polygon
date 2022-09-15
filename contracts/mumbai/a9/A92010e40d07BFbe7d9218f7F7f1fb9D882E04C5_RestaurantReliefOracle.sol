// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;



// File: Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// File: EnumerableSet.sol

// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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

// File: EnumerableUint256Set.sol

library EnumerableUint256Set {
    struct Uint256Set {
        uint256[] values;
        mapping(uint256 => uint256) indexes;
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Uint256Set storage _set, uint256 _value) internal view returns (bool) {
        return _set.indexes[_value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(Uint256Set storage _set) internal view returns (uint256) {
        return _set.values.length;
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
    function at(Uint256Set storage _set, uint256 _index) internal view returns (uint256) {
        return _set.values[_index];
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Uint256Set storage _set, uint256 _value) internal returns (bool) {
        if (!contains(_set, _value)) {
            _set.values.push(_value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            _set.indexes[_value] = _set.values.length;
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
    function remove(Uint256Set storage _set, uint256 _value) internal returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = _set.indexes[_value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = _set.values.length - 1;

            if (lastIndex != toDeleteIndex) {
                uint256 lastvalue = _set.values[lastIndex];

                // Move the last value to the index where the value to delete is
                _set.values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                _set.indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            _set.values.pop();

            // Delete the index for the deleted slot
            delete _set.indexes[_value];

            return true;
        } else {
            return false;
        }
    }

    function asList(Uint256Set storage _set) internal view returns (uint256[] memory) {
        return _set.values;
    }
}
// File: IAccessControl.sol

// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// File: IERC165.sol

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: IERC20.sol

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

// File: IRestaurantReliefOracle.sol

struct RestaurantInfo {
    uint256 restaurantId;
    bytes32 restaurantName;
    bytes32 restaurantName2;
    bytes32 location;
    bytes32 amountRaised;
    uint256 votes;
}

interface IRestaurantReliefOracle {
    function getRestaurantCount() external view returns (uint256);

    function getRestaurantAtIndex(uint256 index)
        external
        view
        returns (RestaurantInfo memory);

    function getRestaurantById(uint256 restaurantId)
        external
        view
        returns (RestaurantInfo memory);

    function progress() external view returns (string memory);

    function restaurantNominatedBy(uint256 tokenId)
        external
        view
        returns (RestaurantInfo memory);

    function restaurantVotedBy(uint256 tokenId)
        external
        view
        returns (RestaurantInfo memory);
}

// File: Strings.sol

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// File: AccessManagement.sol

interface ChainalysisSanctionsList {
    function isSanctioned(address addr) external view returns (bool);
}

contract EmptySanctionsList is ChainalysisSanctionsList {
    function isSanctioned(address) external pure override returns (bool) {
        return false;
    }
}

/**
 * @dev Library to externalize the access control features to cut down on deployed
 * bytecode in the main contract.
 * @dev see {ViciAccess}
 * @dev Moving all of this code into this library cut the size of ViciAccess, and all of
 * the contracts that extend from it, by about 4kb.
 */
library AccessManagement {
    using Strings for string;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    struct AccessManagementState {
        address contractOwner;
        ChainalysisSanctionsList sanctionsList;
        bool sanctionsComplianceEnabled;
        mapping(bytes32 => EnumerableSet.AddressSet) roleMembers;
        mapping(bytes32 => RoleData) roles;
    }

    /**
     * @dev Emitted when `previousOwner` transfers ownership to `newOwner`.
     */
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    function DEFAULT_ADMIN_ROLE() public pure returns (bytes32) {
        return 0x00;
    }

    function BANNED_ROLE_NAME() public pure returns (bytes32) {
        return "banned";
    }

    function MODERATOR_ROLE_NAME() public pure returns (bytes32) {
        return "moderator";
    }

    function initSanctions(AccessManagementState storage ams) external {
        require(
            address(ams.sanctionsList) == address(0),
            "already initialized"
        );
        // The official contract is deployed at the same address on each of
        // these blockchains.
        if (
            block.chainid == 137 || // Polygon
            block.chainid == 1 || // Ethereum
            block.chainid == 56 || // Binance Smart Chain
            block.chainid == 250 || // Fantom
            block.chainid == 10 || // Optimism
            block.chainid == 42161 || // Arbitrum
            block.chainid == 43114 || // Avalanche
            block.chainid == 25 || // Cronos
            false
        ) {
            _setSanctions(
                ams,
                ChainalysisSanctionsList(
                    address(0x40C57923924B5c5c5455c48D93317139ADDaC8fb)
                )
            );
        } else if (block.chainid == 80001) {
            _setSanctions(
                ams,
                ChainalysisSanctionsList(
                    address(0x07342d7d152dd01325f777f41FeDe5D4ACc4F8EC)
                )
            );
        } else {
            _setSanctions(ams, new EmptySanctionsList());
        }

        ams.sanctionsComplianceEnabled = true;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function setContractOwner(
        AccessManagementState storage ams,
        address _newOwner
    ) external {
        if (ams.contractOwner != address(0)) {
            enforceIsContractOwner(ams, msg.sender);
        }

        enforceIsNotBanned(ams, _newOwner);
        require(_newOwner != ams.contractOwner, "AccessControl: already owner");
        _grantRole(ams, DEFAULT_ADMIN_ROLE(), _newOwner);
        address oldOwner = ams.contractOwner;
        ams.contractOwner = _newOwner;

        if (oldOwner != address(0)) {
            emit OwnershipTransferred(oldOwner, _newOwner);
        }
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function getContractOwner(AccessManagementState storage ams)
        public
        view
        returns (address)
    {
        return ams.contractOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    function enforceIsContractOwner(
        AccessManagementState storage ams,
        address account
    ) public view {
        require(account == ams.contractOwner, "AccessControl: not owner");
    }

    /**
     * @dev reverts if called by an account that is not the owner and doesn't 
     *     have the moderator role.
     */
    function enforceIsModerator(
        AccessManagementState storage ams,
        address account
    ) public view {
        require(
            account == ams.contractOwner ||
                hasRole(ams, MODERATOR_ROLE_NAME(), account),
            "AccessControl: not moderator"
        );
    }

    /**
     * @dev Reverts if called by a banned or sanctioned account.
     */
    function enforceIsNotBanned(
        AccessManagementState storage ams,
        address account
    ) public view {
        enforceIsNotSanctioned(ams, account);
        require(!isBanned(ams, account), "AccessControl: banned");
    }

    /**
     * @dev Reverts if called by an account on the OFAC sanctions list.
     */
    function enforceIsNotSanctioned(
        AccessManagementState storage ams,
        address addr
    ) public view {
        if (ams.sanctionsComplianceEnabled) {
            require(
                !ams.sanctionsList.isSanctioned(addr),
                "OFAC sanctioned address"
            );
        }
    }

    /**
     * @dev reverts if called by an account that is not the owner and doesn't 
     *     have the required role.
     */
    function enforceOwnerOrRole(
        AccessManagementState storage ams,
        bytes32 _role,
        address _account
    ) public view {
        if (_account != ams.contractOwner) {
            checkRole(ams, _role, _account);
        }
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(
        AccessManagementState storage ams,
        bytes32 _role,
        address _account
    ) public view returns (bool) {
        return ams.roles[_role].members[_account];
    }

    /**
     * @dev Throws if `_account` does not have `_role`.
     */
    function checkRole(
        AccessManagementState storage ams,
        bytes32 _role,
        address _account
    ) public view {
        if (!hasRole(ams, _role, _account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(_account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(_role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(AccessManagementState storage ams, bytes32 role)
        public
        view
        returns (bytes32)
    {
        return ams.roles[role].adminRole;
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function setRoleAdmin(
        AccessManagementState storage ams,
        bytes32 role,
        bytes32 adminRole
    ) public {
        enforceOwnerOrRole(ams, getRoleAdmin(ams, role), msg.sender);
        bytes32 previousAdminRole = getRoleAdmin(ams, role);
        ams.roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `_role` to `_account`.
     */
    function grantRole(
        AccessManagementState storage ams,
        bytes32 _role,
        address _account
    ) external {
        enforceIsNotBanned(ams, msg.sender);
        if (_role == BANNED_ROLE_NAME()) {
            enforceIsModerator(ams, msg.sender);
            require(_account != ams.contractOwner, "AccessControl: ban owner");
        } else {
            enforceIsNotBanned(ams, _account);
            if (msg.sender != ams.contractOwner) {
                checkRole(ams, getRoleAdmin(ams, _role), msg.sender);
            }
        }

        _grantRole(ams, _role, _account);
    }

    /**
     * @dev Returns `true` if `_account` is banned.
     */
    function isBanned(AccessManagementState storage ams, address _account)
        public
        view
        returns (bool)
    {
        return hasRole(ams, BANNED_ROLE_NAME(), _account);
    }

    /**
     * @dev Revokes `_role` from `_account`.
     */
    function revokeRole(
        AccessManagementState storage ams,
        bytes32 _role,
        address _account
    ) external {
        enforceIsNotBanned(ams, msg.sender);
        require(
            _role != DEFAULT_ADMIN_ROLE() || _account != ams.contractOwner,
            "AccessControl: revoke admin from owner"
        );
        if (_role == BANNED_ROLE_NAME()) {
            enforceIsModerator(ams, msg.sender);
        } else {
            enforceOwnerOrRole(ams, getRoleAdmin(ams, _role), msg.sender);
        }

        _revokeRole(ams, _role, _account);
    }

    /**
     * @dev Revokes `_role` from the calling account.
     */
    function renounceRole(AccessManagementState storage ams, bytes32 _role)
        external
    {
        require(
            _role != DEFAULT_ADMIN_ROLE() || msg.sender != ams.contractOwner,
            "AccessControl: owner renounce admin"
        );
        require(_role != BANNED_ROLE_NAME(), "AccessControl: self unban");
        checkRole(ams, _role, msg.sender);
        _revokeRole(ams, _role, msg.sender);
    }

    /**
     * @dev Returns one of the accounts that have `_role`. `_index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     */
    function getRoleMember(
        AccessManagementState storage ams,
        bytes32 _role,
        uint256 _index
    ) external view returns (address) {
        return ams.roleMembers[_role].at(_index);
    }

    /**
     * @dev Returns the number of accounts that have `_role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(
        AccessManagementState storage ams,
        bytes32 _role
    ) external view returns (uint256) {
        return ams.roleMembers[_role].length();
    }

    /**
     * @notice returns whether the address is sanctioned.
     */
    function isSanctioned(AccessManagementState storage ams, address addr)
        public
        view
        returns (bool)
    {
        return
            ams.sanctionsComplianceEnabled &&
            ams.sanctionsList.isSanctioned(addr);
    }

    /**
     * @notice Sets the sanction list oracle
     * @notice Reverts unless the contract is running on a local HardHat or
     *      Ganache chain.
     * @param _sanctionsList the oracle address
     */
    function setSanctions(
        AccessManagementState storage ams,
        ChainalysisSanctionsList _sanctionsList
    ) external {
        require(block.chainid == 31337 || block.chainid == 1337, "Not testnet");
        _setSanctions(ams, _sanctionsList);
    }

    /**
     * @notice returns the address of the OFAC sanctions oracle.
     */
    function getSanctionsOracle(AccessManagementState storage ams)
        public
        view
        returns (address)
    {
        return address(ams.sanctionsList);
    }

    /**
     * @notice toggles the sanctions compliance flag
     * @notice this flag should only be turned off during testing or if there
     *     is some problem with the sanctions oracle.
     *
     * Requirements:
     * - Caller must be the contract owner
     */
    function toggleSanctionsCompliance(AccessManagementState storage ams)
        public
    {
        ams.sanctionsComplianceEnabled = !ams.sanctionsComplianceEnabled;
    }

    /**
     * @dev returns true if sanctions compliance is enabled.
     */
    function isSanctionsComplianceEnabled(AccessManagementState storage ams)
        public
        view
        returns (bool)
    {
        return ams.sanctionsComplianceEnabled;
    }

    function _setSanctions(
        AccessManagementState storage ams,
        ChainalysisSanctionsList _sanctionsList
    ) internal {
        ams.sanctionsList = _sanctionsList;
    }

    function _grantRole(
        AccessManagementState storage ams,
        bytes32 _role,
        address _account
    ) private {
        if (!hasRole(ams, _role, _account)) {
            ams.roles[_role].members[_account] = true;
            ams.roleMembers[_role].add(_account);
            emit RoleGranted(_role, _account, msg.sender);
        }
    }

    function _revokeRole(
        AccessManagementState storage ams,
        bytes32 _role,
        address _account
    ) private {
        if (hasRole(ams, _role, _account)) {
            ams.roles[_role].members[_account] = false;
            ams.roleMembers[_role].remove(_account);
            emit RoleRevoked(_role, _account, msg.sender);
        }
    }
}

// File: ERC165.sol

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: IAccessControlEnumerable.sol

// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// File: IERC1155.sol

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// File: IERC721.sol

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: Pausable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: ViciAccess.sol

/**
 * @title ViciAccess
 * @author Josh Davis <[email protected]>
 */
abstract contract ViciAccess is IAccessControlEnumerable, Context, ERC165 {
    using AccessManagement for AccessManagement.AccessManagementState;

    AccessManagement.AccessManagementState ams;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    // Role for banned users.
    bytes32 public constant BANNED_ROLE_NAME = "banned";

    // Role for moderator.
    bytes32 public constant MODERATOR_ROLE_NAME = "moderator";

    /**
     * @dev Emitted when `previousOwner` transfers ownership to `newOwner`.
     */
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        ams.setContractOwner(msg.sender);
        ams.initSanctions();
        ams.setRoleAdmin(BANNED_ROLE_NAME, MODERATOR_ROLE_NAME);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            interfaceId == type(IAccessControlEnumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev reverts if called by an account that is not the owner and doesn't 
     *     have the required role.
     */
    modifier onlyOwnerOrRole(bytes32 role) {
        if (_msgSender() != owner()) {
            _checkRole(role, _msgSender());
        }
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        ams.enforceIsContractOwner(_msgSender());
        _;
    }

    /**
     * @dev reverts if the caller is banned or on the OFAC sanctions list.
     */
    modifier noBannedAccounts() {
        ams.enforceIsNotBanned(_msgSender());
        _;
    }

    /**
     * @dev reverts if the account is banned or on the OFAC sanctions list.
     */
    modifier notBanned(address account) {
        ams.enforceIsNotBanned(account);
        _;
    }

    /**
     * @dev Revert if the address is on the OFAC sanctions list
     */
    modifier notSanctioned(address addr) {
        ams.enforceIsNotSanctioned(addr);
        _;
    }

    /**
     * @dev returns true if the account is banned.
     */
    function isBanned(address account) public view virtual returns (bool) {
        return hasRole(BANNED_ROLE_NAME, account);
    }

    /**
     * @dev returns true if the account is on the OFAC sanctions list.
     */
    function isSanctioned(address account) public view virtual returns (bool) {
        return ams.isSanctioned(account);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        public
        view
        override
        returns (bool)
    {
        return ams.hasRole(role, account);
    }

    /**
     * @notice toggles the sanctions compliance flag
     * @notice this flag should only be turned off during testing or if there
     *     is some problem with the sanctions oracle.
     *
     * Requirements:
     * - Caller must be the contract owner
     */
    function toggleSanctionsCompliance() public onlyOwner {
        ams.toggleSanctionsCompliance();
    }

    /**
     * @dev returns true if sanctions compliance is enabled.
     */
    function sanctionsComplianceEnabled() public view returns (bool) {
        return ams.isSanctionsComplianceEnabled();
    }

    /**
     * @notice Sets the sanction list oracle
     * @notice Reverts unless the contract is running on a local HardHat or
     *      Ganache chain.
     * @param _sanctionsList the oracle address
     */
    function setSanctions(ChainalysisSanctionsList _sanctionsList) public {
        ams.setSanctions(_sanctionsList);
    }

    /**
     * @notice returns the address of the OFAC sanctions oracle.
     */
    function sanctionsOracle() public view returns (address) {
        return ams.getSanctionsOracle();
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        ams.checkRole(role, account);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return ams.getRoleAdmin(role);
    }

    /**
     * @dev Sets the admin role that controls a role.
     * 
     * Requirements:
     * - caller MUST be the owner or have the admin role.
     */
    function setRoleAdmin(bytes32 role, bytes32 adminRole)
        public
        onlyOwnerOrRole(DEFAULT_ADMIN_ROLE)
    {
        ams.setRoleAdmin(role, adminRole);
    }

    /**
     *  Requirements:
     *
     * - Calling user MUST have the admin role
     * - If `role` is banned, calling user MUST be the owner
     *   and `address` MUST NOT be the owner.
     * - If `role` is not banned, `account` MUST NOT be under sanctions.
     *
     * @inheritdoc IAccessControl
     */
    function grantRole(bytes32 role, address account) public virtual override {
        ams.grantRole(role, account);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return ams.getContractOwner();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index)
        public
        view
        override
        returns (address)
    {
        return ams.getRoleMember(role, index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role)
        public
        view
        override
        returns (uint256)
    {
        return ams.getRoleMemberCount(role);
    }

    /**
     * Make another account the owner of this contract.
     * @param newOwner the new owner.
     *
     * Requirements:
     *
     * - Calling user MUST be owner.
     * - `newOwner` MUST NOT have the banned role.
     */
    function transferOwnership(address newOwner) public virtual {
        ams.setContractOwner(newOwner);
    }

    /**
     * Take the role away from the account. This will throw an exception
     * if you try to take the admin role (0x00) away from the owner.
     *
     * Requirements:
     *
     * - Calling user has admin role.
     * - If `role` is admin, `address` MUST NOT be owner.
     * - if `role` is banned, calling user MUST be owner.
     *
     * @inheritdoc IAccessControl
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        ams.revokeRole(role, account);
    }

    /**
     * Take a role away from yourself. This will throw an exception if you
     * are the contract owner and you are trying to renounce the admin role (0x00).
     *
     * Requirements:
     *
     * - if `role` is admin, calling user MUST NOT be owner.
     * - `account` is ignored.
     * - `role` MUST NOT be banned.
     *
     * @inheritdoc IAccessControl
     */
    function renounceRole(bytes32 role, address) public virtual override {
        ams.renounceRole(role);
    }

    /**
     * Take a role away from yourself. This will throw an exception if you
     * are the contract owner and you are trying to renounce the admin role (0x00).
     *
     * Requirements:
     *
     * - if `role` is admin, calling user MUST NOT be owner.
     * - `role` MUST NOT be banned.
     */
    function renounceRole(bytes32 role) public virtual {
        ams.renounceRole(role);
    }
}

// File: BaseViciContract.sol

abstract contract BaseViciContract is ViciAccess, Pausable {
	constructor() {
	}

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - Calling user MUST be owner.
     * - The contract must not be paused.
     */
	function pause() external onlyOwner {
		_pause();
	}

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - Calling user MUST be owner.
     * - The contract must be paused.
     */
	function unpause() external onlyOwner {
		_unpause();
	}
	
	function _withdrawERC20(
		uint256 amount,
		address payable toAddress,
		IERC20 tokenContract
	) internal virtual {
		tokenContract.transfer(toAddress, amount);
	}
	
	function withdrawERC20(
		uint256 amount,
		address payable toAddress,
		IERC20 tokenContract
	) public onlyOwner virtual {
		_withdrawERC20(amount, toAddress, tokenContract);
	}
	
	function _withdrawERC721(
		uint256 tokenId,
		address payable toAddress,
		IERC721 tokenContract
	) internal virtual {
		tokenContract.safeTransferFrom(address(this), toAddress, tokenId);
	}
	
	function withdrawERC721(
		uint256 tokenId,
		address payable toAddress,
		IERC721 tokenContract
	) public virtual onlyOwner {
		_withdrawERC721(tokenId, toAddress, tokenContract);
	}
	
	function _withdrawERC1155(
		uint256 tokenId,
		uint256 amount,
		address payable toAddress,
        bytes calldata data,
		IERC1155 tokenContract
	) internal virtual {
		tokenContract.safeTransferFrom(
			address(this), toAddress, tokenId, amount, data
		);
	}
	
	function withdrawERC1155(
		uint256 tokenId,
		uint256 amount,
		address payable toAddress,
        bytes calldata data,
		IERC1155 tokenContract
	) public virtual onlyOwner {
		_withdrawERC1155(tokenId, amount, toAddress, data, tokenContract);
	}
	
	function _withdraw(
		address payable toAddress
	) internal virtual {
		toAddress.transfer(address(this).balance);
	}
	
	function withdraw(
		address payable toAddress
	) public virtual onlyOwner {
		_withdraw(toAddress);
	}

	receive() external payable virtual {}
}
// File: GenericOracle.sol

/**
 * @title Generic Oracle
 * @notice stores arbitrary key-value pairs for a topic.
 * @notice like the oracles of antiquity, it is up to the petitioner to 
 *     interpret the results.
 * @dev Use a subclass. This contract has no public functions for retrieving 
 *     the data.
 */
contract GenericOracle is BaseViciContract {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableUint256Set for EnumerableUint256Set.Uint256Set;

    bytes32 public constant ORACLE = keccak256(bytes("oracle"));

    EnumerableUint256Set.Uint256Set allTopics;
    EnumerableSet.Bytes32Set allKeys;

    mapping(uint256 => mapping(bytes32 => bytes32)) database;

    /* Enumerating functions */

    /**
     * @notice Returns the number of keys.
     * @notice use with keyAtIndex() to enumerate
     */
    function keyCount() public view returns (uint256) {
        return allKeys.length();
    }

    /**
     * @notice Returns the key at the index.
     * @notice use with keyCount() to enumerate
     */
    function keyAtIndex(uint256 index) public view returns (bytes32) {
        return allKeys.at(index);
    }

    /**
     * @notice Returns the number of topics.
     * @notice use with topicAtIndex() to enumerate
     */
    function topicCount() public view returns (uint256) {
        return allTopics.length();
    }

    /**
     * @notice Returns the topic at the index.
     * @notice use with topicCount() to enumerate
     */
    function topicAtIndex(uint256 index) public view returns (uint256) {
        return allTopics.at(index);
    }

    /* Maintenance functions */

    /**
     * @notice adds the keys to the publically enumerable set
     * 
     * Requirements:
     * - caller MUST be the contract owner or have the ORACLE role.
     */
    function defineKeys(bytes32[] memory keys) public onlyOwnerOrRole(ORACLE) {
        for (uint256 i = 0; i < keys.length; i++) {
            allKeys.add(keys[i]);
        }
    }

    /**
     * @notice sets the data for the topic.
     * @notice Use this to insert a new topic or update several things about a
     *     topic at once.
     * @notice adds the topic to the publicly enumerable set if new.
     * @notice overwrites data for previously set keys.
     * @notice does not clear data for keys not included in the call.
     * 
     * @param topic identifies the topic
     * @param keys the list of keys to set
     * @param values the corresponding list of values to set
     * 
     * Requirements:
     * - `keys` and `values` MUST have the same length.
     * - caller MUST be the contract owner or have the ORACLE role.
     */
    function setDataset(
        uint256 topic,
        bytes32[] memory keys,
        bytes32[] memory values
    ) public onlyOwnerOrRole(ORACLE) {
        require(
            keys.length == values.length,
            "keys and values lengths mismatch"
        );

        allTopics.add(topic);
        for (uint256 i = 0; i < keys.length; i++) {
            database[topic][keys[i]] = values[i];
        }
    }

    /**
     * @notice sets values of a key for a set of topics
     * @notice use this to push updates to lots of topics at once.
     * @notice does not add any missing topics to the enumerable list.
     * @notice adds the key to the enumerable list if missing.
     * 
     * @param topics identifies the topics
     * @param key the key to set
     * @param values the corresponding list of values to set
     * 
     * Requirements:
     * - `topics` and `values` MUST have the same length.
     * - caller MUST be the contract owner or have the ORACLE role.
     */
    function setValues(
        uint256[] memory topics,
        bytes32 key,
        bytes32[] memory values
    ) public onlyOwnerOrRole(ORACLE) {
        require(
            topics.length == values.length,
            "topics and values lengths mismatch"
        );

        allKeys.add(key);

        for (uint256 i = 0; i < topics.length; i++) {
            database[topics[i]][key] = values[i];
        }
    }

    /**
     * @notice sets or overwrites a specific value for a topic.
     * @notice use this to update a single value.
     * @notice does not add the topic to the enumerable list if missing.
     * 
     * @param topic identifies the topic
     * @param key the key to set
     * @param value the value to set
     * 
     * Requirements:
     * - caller MUST be the contract owner or have the ORACLE role.
     */
    function update(
        uint256 topic,
        bytes32 key,
        bytes32 value
    ) public onlyOwnerOrRole(ORACLE) {
        database[topic][key] = value;
    }

    /* Internal lookup functions */

    /**
     * @dev returns one piece of data about a topic
     * @param topic topic identifier
     * @param key the data point
     */
    function _lookupData(uint256 topic, bytes32 key)
        internal
        view
        returns (bytes32)
    {
        return database[topic][key];
    }

    /**
     * @dev returns the requested data about a topic
     * @param topic topic identifier
     * @param keys the list of data point
     */
    function _lookupDataset(uint256 topic, bytes32[] memory keys)
        internal
        view
        returns (bytes32[] memory result)
    {
        result = new bytes32[](keys.length);
        for (uint256 i = 0; i < keys.length; i++) {
            result[i] = database[topic][keys[i]];
        }
    }
}

// File: PublicOracle.sol

/**
 * @title Public Oracle
 * @dev subclass of the GenericOracle with public lookup functions.
 */
contract PublicOracle is GenericOracle {
    /**
     * @dev returns one piece of data about a topic
     * @param topic topic identifier
     * @param key the data point
     */
    function lookupData(uint256 topic, bytes32 key)
        public
        view
        returns (bytes32)
    {
        return _lookupData(topic, key);
    }

    /**
     * @notice returns the requested data about a topic
     * @param topic topic identifier
     * @param keys the list of data point
     */
    function lookupDataset(uint topic, bytes32[] memory keys)
        public
        view
        returns (bytes32[] memory)
    {
        return _lookupDataset(topic, keys);
    }
}

// File: RestaurantReliefOracle.sol

contract RestaurantReliefOracle is PublicOracle, IRestaurantReliefOracle {
    using EnumerableUint256Set for EnumerableUint256Set.Uint256Set;

    bytes32 public constant NOM_KEY = keccak256(bytes("nominated"));
    bytes32 public constant VOTE_KEY = keccak256(bytes("voted"));

    mapping(uint256 => RestaurantInfo) restaurants;
    EnumerableUint256Set.Uint256Set restaurantIds;

    string public goal;
    string public progress = "$0";

    bool public votingOpen = false;

    function getRestaurantCount() public view returns (uint256) {
        return restaurantIds.length();
    }

    function getRestaurantAtIndex(uint256 index)
        public
        view
        returns (RestaurantInfo memory)
    {
        return restaurants[restaurantIds.at(index)];
    }

    function getRestaurantById(uint256 restaurantId)
        public
        view
        returns (RestaurantInfo memory)
    {
        return restaurants[restaurantId];
    }

    function addRestaurant(RestaurantInfo memory restaurant)
        public
        onlyOwnerOrRole(ORACLE)
    {
        _addRestaurant(restaurant);
    }

    function addRestaurants(RestaurantInfo[] memory newRestaurants)
        public
        onlyOwnerOrRole(ORACLE)
    {
        for (uint256 i = 0; i < newRestaurants.length; i++) {
            _addRestaurant(newRestaurants[i]);
        }
    }

    function removeRestaurant(uint256 restaurantId)
        public
        onlyOwnerOrRole(ORACLE)
    {
        restaurantIds.remove(restaurantId);
        delete restaurants[restaurantId];
    }

    function recordVoteAndProgress(
        uint256 tokenId,
        uint256 restaurantId,
        bytes32 amountRaised,
        string memory updatedProgress,
        bytes32 voteType
    ) public onlyOwnerOrRole(ORACLE) {
        RestaurantInfo storage restaurant = restaurants[restaurantId];
        _recordVoteAndProgress(tokenId, restaurant, amountRaised, voteType);
        _setProgress(updatedProgress);
    }

    function recordVotesAndProgress(
        uint256[] memory _tokenIds,
        uint256[] memory _restaurantIds,
        bytes32[] memory _amountsRaised,
        string memory _updatedProgress,
        bytes32 _voteType
    ) public onlyOwnerOrRole(ORACLE) {
        require(
            _tokenIds.length == _restaurantIds.length,
            "array length mismatch"
        );
        require(
            _amountsRaised.length == 0 ||
                _tokenIds.length == _amountsRaised.length,
            "array length mismatch"
        );
        for (uint256 i = 0; i < _restaurantIds.length; i++) {
            RestaurantInfo storage restaurant = restaurants[_restaurantIds[i]];

            if (_amountsRaised.length == 0) {
                _recordVote(_tokenIds[i], restaurant, _voteType);
            } else {
                _recordVoteAndProgress(
                    _tokenIds[i],
                    restaurant,
                    _amountsRaised[i],
                    _voteType
                );
            }
        }
        _setProgress(_updatedProgress);
    }

    function clearVotes() public onlyOwnerOrRole(ORACLE) {
        for (uint256 i = 0; i < restaurantIds.length(); i++) {
            restaurants[restaurantIds.at(i)].votes = 0;
        }
    }

    function restaurantNominatedBy(uint256 tokenId)
        public
        view
        returns (RestaurantInfo memory)
    {
        return _restaurantByKey(tokenId, NOM_KEY);
    }

    function restaurantVotedBy(uint256 tokenId)
        public
        view
        returns (RestaurantInfo memory)
    {
        return _restaurantByKey(tokenId, VOTE_KEY);
    }

    function setGoal(string memory updatedGoal) public onlyOwnerOrRole(ORACLE) {
        goal = updatedGoal;
    }

    function setProgress(string memory updatedProgress)
        public
        onlyOwnerOrRole(ORACLE)
    {
        _setProgress(updatedProgress);
    }

    function _addRestaurant(RestaurantInfo memory restaurant) internal {
        restaurants[restaurant.restaurantId] = restaurant;
        restaurantIds.add(restaurant.restaurantId);
    }

    function _recordVote(
        uint256 tokenId,
        RestaurantInfo storage restaurant,
        bytes32 voteType
    ) internal {
        require(restaurant.restaurantId != 0, "invalid restaurant");

        uint256 existingVote = uint256(lookupData(tokenId, voteType));
        if (existingVote != 0) {
            RestaurantInfo storage r = restaurants[existingVote];
            if (r.votes > 0) {
                r.votes -= 1;
            }
        }

        restaurant.votes += 1;
        update(tokenId, voteType, bytes32(restaurant.restaurantId));
    }

    function _recordVoteAndProgress(
        uint256 tokenId,
        RestaurantInfo storage restaurant,
        bytes32 amountRaised,
        bytes32 voteType
    ) internal {
        _recordVote(tokenId, restaurant, voteType);
        if (amountRaised != bytes32(0)) {
            restaurant.amountRaised = amountRaised;
        }
    }

    function _setProgress(string memory updatedProgress) internal {
        if (bytes(updatedProgress).length != 0) {
            progress = updatedProgress;
        }
    }

    function _restaurantByKey(uint256 tokenId, bytes32 key)
        internal
        view
        returns (RestaurantInfo memory)
    {
        uint256 restaurantId = uint256(lookupData(tokenId, key));
        return getRestaurantById(restaurantId);
    }
}