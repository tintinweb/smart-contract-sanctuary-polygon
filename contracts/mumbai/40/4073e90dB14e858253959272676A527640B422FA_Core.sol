// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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
pragma solidity 0.8.15;

enum Workflow {
    Preparatory,
    Presale,
    SaleHold,
    SaleOpen
}

uint256 constant PRICE_PACK_LEVEL1_IN_USD = 50e6;
uint256 constant PRICE_PACK_LEVEL1_IN_MFS_FIRST_BB = 200e6;
uint256 constant TWO = 2e6;
uint256 constant OVERRLAP_TIME_ACTIVITY = 3 days;
uint256 constant PACK_ACTIVITY_PERIOD = 30 days;
uint256 constant SHARE_OF_MARKETING = 60e4;
uint256 constant SHARE_OF_REWARDS = 10e4;
uint256 constant SHARE_OF_LIQUIDITY_POOL = 10e4;
uint256 constant SHARE_OF_FORSAGE_PARTICIPANTS = 5e4;
uint256 constant SHARE_OF_META_DEVELOPMENT_AND_INCENTIVE = 5e4;
uint256 constant SHARE_OF_TEAM = 5e4;
uint256 constant SHARE_OF_LIQUIDITY_LISTING = 5e4;
uint256 constant LEVELS_COUNT = 8;
uint256 constant TRANSITION_PHASE_PERIOD = 30 days;
uint256 constant ACTIVATION_COST_RATIO_TO_RENEWAL = 5e6;
uint256 constant COEFF_INCREASE_COST_PACK_FOR_NEXT_LEVEL = 2e6;
uint256 constant COEFF_DECREASE_NEXT_BB = 2e6; //2
uint256 constant COEFF_DECREASE_COST_PACK_NEXT_BB = 2e6; //2
uint256 constant COEFF_DECREASE_COST_PACK_NEXT_MB = 6e4; //0.06
uint256 constant MB_COUNT = 10;
uint256 constant COEFF_FIRST_MB = 127e4; //1.27
uint256 constant START_COEFF_DECREASE_MICROBLOCK = 124e4;
uint256 constant MARKETING_REFERRALS_TREE_ARITY = 2;

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Constants.sol";
import "./interfaces/ICoreContract.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

bytes32 constant META_FORCE_ROLE = 0xc14e9f78f822278908e3fb3a284552bdf1aa6e2fa83e322e922d0de4d1944f7c;

contract Core is Ownable, AccessControl, ICoreContract {
    using EnumerableSet for EnumerableSet.AddressSet;

    address public immutable override root;
    uint256 public override getFrozenMFSTotalAmount;
    Workflow public override getWorkflowStage;
    uint256[] public rewardsDirectReferrers = [10e4, 7e4, 4e4, 4e4];
    uint256[] public rewardsMarketingReferrers = [15e4, 15e4, 15e4, 15e4, 15e4];
    uint256 public override getDateStartSaleOpen;
    uint256 public override getEnergyConversionFactor;

    mapping(address => User) internal users;
    modifier onlyMetaForceRole() {
        if (!hasRole(META_FORCE_ROLE, _msgSender())) {
            revert MetaForceSpaceCoreNotAllowed();
        }
        _;
    }

    constructor(address _root) {
        _setupRole(META_FORCE_ROLE, _msgSender());

        root = _root;
        getEnergyConversionFactor = 1e6;
        User storage r = users[_root];
        r.referrer = _root;
        r.marketingReferrer = _root;
        for (uint256 i = 1; i <= LEVELS_COUNT; i++) {
            r.packs[i] = type(uint256).max;
        }

        emit ReferrerChanged(_root, _root);
        emit MarketingReferrerChanged(_root, _root);
    }

    function nextWorkflowStage() external override onlyOwner {
        if (getWorkflowStage == Workflow.SaleOpen) {
            revert MetaForceSpaceCoreSaleOpenIsLastWorkflowStep();
        }
        getWorkflowStage = Workflow(uint8(getWorkflowStage) + 1);
        if (getWorkflowStage == Workflow.SaleOpen) {
            getDateStartSaleOpen = block.timestamp;
        }
        emit WorkflowStageMove(getWorkflowStage);
    }

    function setReferrer(address user, address referrer) external override onlyMetaForceRole {
        _setReferrer(user, referrer);
        users[user].registrationDate = block.timestamp;
    }

    function setMarketingReferrer(address user, address marketingReferrer) external override onlyMetaForceRole {
        _setMarketingReferrer(user, marketingReferrer);
    }

    function setTypeReward(address user, TypeReward typeReward) external override onlyMetaForceRole {
        users[user].rewardType = typeReward;
    }

    function setEnergyConversionFactor(uint256 _energyConversionFactor) external override onlyOwner {
        getEnergyConversionFactor = _energyConversionFactor;
    }

    function increaseTimestampEndPack(
        address user,
        uint256 level,
        uint256 amount
    ) external override onlyMetaForceRole {
        users[user].packs[level] += amount;
        emit TimestampEndPackSet(user, level, users[user].packs[level]);
    }

    function setTimestampEndPack(
        address user,
        uint256 level,
        uint256 timestamp
    ) external override onlyMetaForceRole {
        users[user].packs[level] = timestamp;
        emit TimestampEndPackSet(user, level, users[user].packs[level]);
    }

    function increaseFrozenMFS(address user, uint256 amount) external override onlyMetaForceRole {
        users[user].mfsFrozenAmount += amount;
        getFrozenMFSTotalAmount += amount;
    }

    function decreaseFrozenMFS(address user, uint256 amount) external override onlyMetaForceRole {
        if (users[user].mfsFrozenAmount < amount) {
            revert MetaForceSpaceCoreNotEnoughFrozenMFS();
        }
        users[user].mfsFrozenAmount -= amount;
        getFrozenMFSTotalAmount -= amount;
    }

    function replaceUser(address to) external override {
        if (checkRegistration(to)) {
            revert MetaForceSpaceCoreNotAllowed();
        }
        if (_msgSender() == to) {
            revert MetaForceSpaceCoreReplaceSameAddress();
        }
        User storage f = users[_msgSender()];
        User storage t = users[to];

        t.rewardType = f.rewardType;
        // t.referrer = f.referrer;
        _setReferrer(to, f.referrer);
        // t.marketingReferrer = f.marketingReferrer;
        _setMarketingReferrer(to, f.marketingReferrer);
        t.mfsFrozenAmount = f.mfsFrozenAmount;

        for (uint256 i = LEVELS_COUNT; i > 0; i--) {
            t.packs[i] = f.packs[i];
        }

        uint256 length = f.referrals.length();
        for (uint256 i = 0; i < length; i++) {
            // users[to].referrals.add(users[from].referrals.at(i));
            _setReferrer(f.referrals.at(0), to);
        }

        length = f.marketingReferrals.length();
        for (uint256 i = 0; i < length; i++) {
            // users[to].marketingReferrals.add(users[from].marketingReferrals.at(i));
            _setMarketingReferrer(f.marketingReferrals.at(0), to);
        }

        clearInfo(_msgSender());
    }

    function replaceUserInMarketingTree(address from, address to) external override onlyMetaForceRole {
        if (isUserActive(from)) {
            revert MetaForceSpaceCoreActiveUser();
        }
        uint256 length = users[from].marketingReferrals.length();
        for (uint256 i = 0; i < length; i++) {
            _setMarketingReferrer(users[from].marketingReferrals.at(0), to);
        }
        _setMarketingReferrer(to, users[from].marketingReferrer);

        users[from].marketingReferrer = address(0);
        emit MarketingReferrerChanged(from, address(0));
    }

    function setRewardsDirectReferrers(uint256[] calldata _rewardsReferrers) external override onlyOwner {
        setRewardsReferrers(_rewardsReferrers, rewardsMarketingReferrers);
    }

    function setRewardsMarketingReferrers(uint256[] calldata _rewardsMarketingReferrers) external override onlyOwner {
        setRewardsReferrers(rewardsDirectReferrers, _rewardsMarketingReferrers);
    }

    function registration() external override {
        registration(root);
    }

    function getRewardsDirectReferrers() external view override returns (uint256[] memory) {
        return rewardsDirectReferrers;
    }

    function getRewardsMarketingReferrers() external view override returns (uint256[] memory) {
        return rewardsMarketingReferrers;
    }

    function getTypeReward(address user) external view override returns (TypeReward) {
        return users[user].rewardType;
    }

    function getAmountFrozenMFS(address user) external view override returns (uint256) {
        return users[user].mfsFrozenAmount;
    }

    function getReferrals(
        address user,
        uint256 indexStart,
        uint256 amount
    ) external view override returns (address[] memory referrals) {
        uint256 length = users[user].referrals.length();
        uint256 indexEnd = indexStart + amount;
        if (indexEnd > length) {
            revert MetaForceSpaceCoreInvalidCursor();
        }

        referrals = new address[](amount);
        for (uint256 i = indexStart; i < indexEnd; i++) {
            referrals[i - indexStart] = users[user].referrals.at(i);
        }
    }

    function getMarketingReferrals(address user) external view override returns (address[] memory) {
        return users[user].marketingReferrals.values();
    }

    function getReferrers(address user, uint256 amount) external view override returns (address[] memory referrers) {
        referrers = new address[](amount);
        address referrer = user;
        for (uint256 i = 0; i < amount; i++) {
            referrer = getReferrer(referrer);
            referrers[i] = referrer;
        }
    }

    function getMarketingReferrers(
        address user,
        uint256 level,
        uint256 amount
    ) external view override returns (address[] memory referrers) {
        referrers = new address[](amount);
        address referrer = user;
        uint256 i = 0;
        while (i < amount) {
            referrer = getMarketingReferrer(referrer);
            if (isPackActive(referrer, level)) {
                referrers[i] = referrer;
                i++;
            }
        }
    }

    function getReferralsAmount(address user) external view override returns (uint256) {
        return users[user].referrals.length();
    }

    function getRegistrationDate(address user) external view returns (uint256) {
        return users[user].registrationDate;
    }

    function registration(address referrer) public override {
        if (checkRegistration(msg.sender)) {
            revert MetaForceSpaceCoreUserAlredyRegistered();
        }
        _setReferrer(msg.sender, referrer);
        users[msg.sender].registrationDate = block.timestamp;
        emit UserIsRegistered(msg.sender, referrer);
    }

    function setRewardsReferrers(uint256[] memory _rewardsDirectReferrers, uint256[] memory _rewardsMarketingReferrers)
        public
        override
        onlyOwner
    {
        uint256 count;
        for (uint256 i = 0; i < _rewardsDirectReferrers.length; i++) {
            count += _rewardsDirectReferrers[i];
        }
        for (uint256 i = 0; i < _rewardsMarketingReferrers.length; i++) {
            count += _rewardsMarketingReferrers[i];
        }
        if (count != 100e4) {
            revert MetaForceSpaceCoreSumRewardsMustBeHundred();
        }
        if (
            keccak256(abi.encodePacked(_rewardsDirectReferrers)) ==
            keccak256(abi.encodePacked(rewardsDirectReferrers)) &&
            keccak256(abi.encodePacked(_rewardsMarketingReferrers)) ==
            keccak256(abi.encodePacked(rewardsMarketingReferrers))
        ) {
            revert MetaForceSpaceCoreRewardsIsNotChange();
        }
        if (
            keccak256(abi.encodePacked(_rewardsDirectReferrers)) == keccak256(abi.encodePacked(rewardsDirectReferrers))
        ) {
            rewardsMarketingReferrers = _rewardsMarketingReferrers;
        } else if (
            keccak256(abi.encodePacked(_rewardsMarketingReferrers)) ==
            keccak256(abi.encodePacked(rewardsMarketingReferrers))
        ) {
            rewardsDirectReferrers = _rewardsDirectReferrers;
        } else {
            rewardsDirectReferrers = _rewardsDirectReferrers;
            rewardsMarketingReferrers = _rewardsMarketingReferrers;
        }
        emit RewardsReferrerSetted();
    }

    function clearInfo(address user) public override onlyMetaForceRole {
        delete users[user];
    }

    function getReferrer(address user) public view override returns (address) {
        return users[user].referrer;
    }

    function getMarketingReferrer(address user) public view returns (address) {
        return users[user].marketingReferrer;
    }

    function checkRegistration(address user) public view override returns (bool) {
        return getReferrer(user) != address(0);
    }

    function getTimestampEndPack(address user, uint256 level) public view override returns (uint256) {
        return users[user].packs[level];
    }

    function isPackActive(address user, uint256 level) public view returns (bool) {
        return getTimestampEndPack(user, level) >= block.timestamp - OVERRLAP_TIME_ACTIVITY;
    }

    function getUserLevel(address user) public view override returns (uint256) {
        for (uint256 i = LEVELS_COUNT; i > 0; i--) {
            if (isPackActive(user, i)) {
                return i;
            }
        }
        return 0;
    }

    function isUserActive(address user) public view returns (bool) {
        for (uint256 i = 1; i <= LEVELS_COUNT; i++) {
            if (getTimestampEndPack(user, i) >= block.timestamp - PACK_ACTIVITY_PERIOD) {
                return true;
            }
        }
        return false;
    }

    function _setReferrer(address user, address referrer) internal {
        User storage u = users[user];

        users[u.referrer].referrals.remove(user);

        u.referrer = referrer;
        users[referrer].referrals.add(user);

        emit ReferrerChanged(user, referrer);
    }

    function _setMarketingReferrer(address user, address marketingReferrer) internal {
        User storage r = users[marketingReferrer];
        if (r.marketingReferrals.length() >= MARKETING_REFERRALS_TREE_ARITY) {
            revert MetaForceSpaceCoreNoMoreSpaceInTree();
        }

        User storage u = users[user];
        users[u.marketingReferrer].marketingReferrals.remove(user);

        users[user].marketingReferrer = marketingReferrer;
        r.marketingReferrals.add(user);

        emit MarketingReferrerChanged(user, marketingReferrer);
    }
}

// SPDX-License-Identifier:  MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../Constants.sol";

error MetaForceSpaceCoreNotAllowed();
error MetaForceSpaceCoreNoMoreSpaceInTree();
error MetaForceSpaceCoreInvalidCursor();
error MetaForceSpaceCoreActiveUser();
error MetaForceSpaceCoreReplaceSameAddress();
error MetaForceSpaceCoreNotEnoughFrozenMFS();
error MetaForceSpaceCoreSaleOpenIsLastWorkflowStep();
error MetaForceSpaceCoreSumRewardsMustBeHundred();
error MetaForceSpaceCoreRewardsIsNotChange();
error MetaForceSpaceCoreUserAlredyRegistered();

struct User {
    TypeReward rewardType;
    address referrer;
    address marketingReferrer;
    uint256 mfsFrozenAmount;
    mapping(uint256 => uint256) packs;
    uint256 registrationDate;
    EnumerableSet.AddressSet referrals;
    EnumerableSet.AddressSet marketingReferrals;
}

enum TypeReward {
    ONLY_MFS,
    MFS_AND_USD,
    ONLY_USD
}

interface ICoreContract {
    event ReferrerChanged(address indexed account, address indexed referrer);
    event MarketingReferrerChanged(address indexed account, address indexed marketingReferrer);
    event TimestampEndPackSet(address indexed account, uint256 level, uint256 timestamp);
    event WorkflowStageMove(Workflow workflowstage);
    event RewardsReferrerSetted();
    event UserIsRegistered(address indexed user, address indexed referrer);

    //Set referrer in referral tree
    function setReferrer(address user, address referrer) external;

    //Set referrer in Marketing tree
    function setMarketingReferrer(address user, address marketingReferrer) external;

    //Set users type reward
    function setTypeReward(address user, TypeReward typeReward) external;

    //Increase timestamp end pack of the corresponding level
    function increaseTimestampEndPack(
        address user,
        uint256 level,
        uint256 time
    ) external;

    //Set timestamp end pack of the corresponding level
    function setTimestampEndPack(
        address user,
        uint256 level,
        uint256 timestamp
    ) external;

    //increase user frozen MFS in mapping
    function increaseFrozenMFS(address user, uint256 amount) external;

    //decrease user frozen MFS in mapping
    function decreaseFrozenMFS(address user, uint256 amount) external;

    //delete user in referral tree and marketing tree
    function clearInfo(address user) external;

    // replace user (place in referral and marketing tree(refer and all referrals), frozenMFS, and packages)
    function replaceUser(address to) external;

    //replace user in marketing tree(refer and all referrals)
    function replaceUserInMarketingTree(address from, address to) external;

    function nextWorkflowStage() external;

    function setEnergyConversionFactor(uint256 _energyConversionFactor) external;

    function setRewardsDirectReferrers(uint256[] calldata _rewardsRefers) external;

    function setRewardsMarketingReferrers(uint256[] calldata _rewardsMarketingRefers) external;

    function setRewardsReferrers(uint256[] calldata _rewardsRefers, uint256[] calldata _rewardsMarketingRefers)
        external;

    function registration() external;

    function registration(address referer) external;

    // Check have referrer in referral tree
    function checkRegistration(address user) external view returns (bool);

    // Request user type reward
    function getTypeReward(address user) external view returns (TypeReward);

    // request user frozen MFS in mapping
    function getAmountFrozenMFS(address user) external view returns (uint256);

    // Request timestamp end pack of the corresponding level
    function getTimestampEndPack(address user, uint256 level) external view returns (uint256);

    // Request user referrer in referral tree
    function getReferrer(address user) external view returns (address);

    // Request user referrer in marketing tree
    function getMarketingReferrer(address user) external view returns (address);

    //Request user some referrals starting from indexStart in referral tree
    function getReferrals(
        address user,
        uint256 indexStart,
        uint256 amount
    ) external view returns (address[] memory);

    // Request user some referrers (father, grandfather, great-grandfather and etc.) in referral tree
    function getReferrers(address user, uint256 amount) external view returns (address[] memory);

    /*Request user's some referrers (father, grandfather, great-grandfather and etc.)
    in marketing tree having of the corresponding level*/
    function getMarketingReferrers(
        address user,
        uint256 level,
        uint256 amount
    ) external view returns (address[] memory);

    //Request user referrals starting from indexStart in marketing tree
    function getMarketingReferrals(address user) external view returns (address[] memory);

    //get user level (maximum active level)
    function getUserLevel(address user) external view returns (uint256);

    function getReferralsAmount(address user) external view returns (uint256);

    function getRegistrationDate(address user) external view returns (uint256);

    function getFrozenMFSTotalAmount() external view returns (uint256);

    function root() external view returns (address);

    function isPackActive(address user, uint256 level) external view returns (bool);

    function getWorkflowStage() external view returns (Workflow);

    function getRewardsDirectReferrers() external view returns (uint256[] memory);

    function getRewardsMarketingReferrers() external view returns (uint256[] memory);

    function getDateStartSaleOpen() external view returns (uint256);

    function getEnergyConversionFactor() external view returns (uint256);
}