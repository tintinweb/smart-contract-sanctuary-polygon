// SPDX-License-Identifier: MIT

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
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
     * If the calling account had been granted `role`, emits a {RoleRevoked}
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

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
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
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

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

// SPDX-License-Identifier: MIT

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

pragma solidity 0.8.9;

import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {SynthereumFinderLib} from '../../core/libs/CoreLibs.sol';
import {
  AccessControlEnumerable
} from '../../../@openzeppelin/contracts/access/AccessControlEnumerable.sol';

/**
 * @dev Extension of {AccessControlEnumerable} that offer support for maintainer role.
 */
contract StandardAccessControlEnumerable is AccessControlEnumerable {
  using SynthereumFinderLib for ISynthereumFinder;

  struct Roles {
    address admin;
    address maintainer;
  }

  bytes32 public constant MAINTAINER_ROLE = keccak256('Maintainer');

  modifier onlyMaintainer() {
    require(
      hasRole(MAINTAINER_ROLE, msg.sender),
      'Sender must be the maintainer'
    );
    _;
  }

  function _setAdmin(address _account) internal {
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, _account);
  }

  function _setMaintainer(address _account) internal {
    _setRoleAdmin(MAINTAINER_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(MAINTAINER_ROLE, _account);
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/**
 * @title Provides addresses of the contracts implementing certain interfaces.
 */
interface ISynthereumFinder {
  /**
   * @notice Updates the address of the contract that implements `interfaceName`.
   * @param interfaceName bytes32 encoding of the interface name that is either changed or registered.
   * @param implementationAddress address of the deployed contract that implements the interface.
   */
  function changeImplementationAddress(
    bytes32 interfaceName,
    address implementationAddress
  ) external;

  /**
   * @notice Gets the address of the contract that implements the given `interfaceName`.
   * @param interfaceName queried interface.
   * @return implementationAddress Address of the deployed contract that implements the interface.
   */
  function getImplementationAddress(bytes32 interfaceName)
    external
    view
    returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {ISynthereumFinder} from '../interfaces/IFinder.sol';
import {ISynthereumDeployer} from '../interfaces/IDeployer.sol';
import {ISynthereumRegistry} from '../registries/interfaces/IRegistry.sol';
import {
  ISynthereumFactoryVersioning
} from '../interfaces/IFactoryVersioning.sol';
import {ISynthereumManager} from '../interfaces/IManager.sol';
import {
  ISynthereumCollateralWhitelist
} from '../interfaces/ICollateralWhitelist.sol';
import {
  ISynthereumIdentifierWhitelist
} from '../interfaces/IIdentifierWhitelist.sol';
import {
  IMintableBurnableTokenFactory
} from '../../tokens/factories/interfaces/IMintableBurnableTokenFactory.sol';
import {
  IJarvisBuybackFactory
} from '../../jarvis-token/interfaces/IBuybackFactory.sol';
import {
  ICreditLineController
} from '../../self-minting/v2/interfaces/ICreditLineController.sol';
import {
  ISynthereumPriceFeed
} from '../../oracle/common/interfaces/IPriceFeed.sol';
import {
  ILendingManager
} from '../../lending-module/interfaces/ILendingManager.sol';
import {
  ILendingStorageManager
} from '../../lending-module/interfaces/ILendingStorageManager.sol';
import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IJarvisBrrrrr} from '../../central-bank/interfaces/IJarvisBrrrrr.sol';
import {
  IMoneyMarketManager
} from '../../central-bank/interfaces/IMoneyMarketManager.sol';
import {
  ISynthereumOnChainLiquidityRouter
} from '../../atomic-swap/interfaces/IOnChainLiquidityRouter.sol';
import {
  IPoolSwap
} from '../../atomic-swap/implementations/interfaces/IPoolSwap.sol';
import {
  IFixedRateSwap
} from '../../atomic-swap/implementations/interfaces/IFixedRateSwap.sol';
import {
  SynthereumInterfaces,
  FactoryVersioningInterfaces
} from '../Constants.sol';

/**
 * @title Stores functiions for getting from the finder instances of Synthereum contracts
 */
library SynthereumFinderLib {
  function getDeployer(ISynthereumFinder _finder)
    internal
    view
    returns (ISynthereumDeployer)
  {
    return
      ISynthereumDeployer(
        _finder.getImplementationAddress(SynthereumInterfaces.Deployer)
      );
  }

  function getPoolRegistry(ISynthereumFinder _finder)
    internal
    view
    returns (ISynthereumRegistry)
  {
    return
      ISynthereumRegistry(
        _finder.getImplementationAddress(SynthereumInterfaces.PoolRegistry)
      );
  }

  function getFixedRateRegistry(ISynthereumFinder _finder)
    internal
    view
    returns (ISynthereumRegistry)
  {
    return
      ISynthereumRegistry(
        _finder.getImplementationAddress(SynthereumInterfaces.FixedRateRegistry)
      );
  }

  function getSelfMintingRegistry(ISynthereumFinder _finder)
    internal
    view
    returns (ISynthereumRegistry)
  {
    return
      ISynthereumRegistry(
        _finder.getImplementationAddress(
          SynthereumInterfaces.SelfMintingRegistry
        )
      );
  }

  function getFactoryVersioning(ISynthereumFinder _finder)
    internal
    view
    returns (ISynthereumFactoryVersioning)
  {
    return
      ISynthereumFactoryVersioning(
        _finder.getImplementationAddress(SynthereumInterfaces.FactoryVersioning)
      );
  }

  function getManager(ISynthereumFinder _finder)
    internal
    view
    returns (ISynthereumManager)
  {
    return
      ISynthereumManager(
        _finder.getImplementationAddress(SynthereumInterfaces.Manager)
      );
  }

  function getCollateralWhitelist(ISynthereumFinder _finder)
    internal
    view
    returns (ISynthereumCollateralWhitelist)
  {
    return
      ISynthereumCollateralWhitelist(
        _finder.getImplementationAddress(
          SynthereumInterfaces.CollateralWhitelist
        )
      );
  }

  function getIdentifierWhitelist(ISynthereumFinder _finder)
    internal
    view
    returns (ISynthereumIdentifierWhitelist)
  {
    return
      ISynthereumIdentifierWhitelist(
        _finder.getImplementationAddress(
          SynthereumInterfaces.IdentifierWhitelist
        )
      );
  }

  function getTokenFactory(ISynthereumFinder _finder)
    internal
    view
    returns (IMintableBurnableTokenFactory)
  {
    return
      IMintableBurnableTokenFactory(
        _finder.getImplementationAddress(SynthereumInterfaces.TokenFactory)
      );
  }

  function getBuybackFactory(ISynthereumFinder _finder)
    internal
    view
    returns (IJarvisBuybackFactory)
  {
    return
      IJarvisBuybackFactory(
        _finder.getImplementationAddress(SynthereumInterfaces.BuybackFactory)
      );
  }

  function getCreditLineController(ISynthereumFinder _finder)
    internal
    view
    returns (ICreditLineController)
  {
    return
      ICreditLineController(
        _finder.getImplementationAddress(
          SynthereumInterfaces.CreditLineController
        )
      );
  }

  function getPriceFeed(ISynthereumFinder _finder)
    internal
    view
    returns (ISynthereumPriceFeed)
  {
    return
      ISynthereumPriceFeed(
        _finder.getImplementationAddress(SynthereumInterfaces.PriceFeed)
      );
  }

  function getLendingManager(ISynthereumFinder _finder)
    internal
    view
    returns (ILendingManager)
  {
    return
      ILendingManager(
        _finder.getImplementationAddress(SynthereumInterfaces.LendingManager)
      );
  }

  function getLendingStorageManager(ISynthereumFinder _finder)
    internal
    view
    returns (ILendingStorageManager)
  {
    return
      ILendingStorageManager(
        _finder.getImplementationAddress(
          SynthereumInterfaces.LendingStorageManager
        )
      );
  }

  function getCommissionReceiver(ISynthereumFinder _finder)
    internal
    view
    returns (address)
  {
    return
      _finder.getImplementationAddress(SynthereumInterfaces.CommissionReceiver);
  }

  function getLendingRewardsReceiver(ISynthereumFinder _finder)
    internal
    view
    returns (address)
  {
    return
      _finder.getImplementationAddress(
        SynthereumInterfaces.LendingRewardsReceiver
      );
  }

  function getJarvisToken(ISynthereumFinder _finder)
    internal
    view
    returns (IERC20)
  {
    return
      IERC20(
        _finder.getImplementationAddress(SynthereumInterfaces.JarvisToken)
      );
  }

  function getVeJarvisToken(ISynthereumFinder _finder)
    internal
    view
    returns (IERC20)
  {
    return
      IERC20(
        _finder.getImplementationAddress(SynthereumInterfaces.veJarvisToken)
      );
  }

  function getJarvisBrrrrr(ISynthereumFinder _finder)
    internal
    view
    returns (IJarvisBrrrrr)
  {
    return
      IJarvisBrrrrr(
        _finder.getImplementationAddress(SynthereumInterfaces.JarvisBrrrrr)
      );
  }

  function getMoneyMarketManager(ISynthereumFinder _finder)
    internal
    view
    returns (IMoneyMarketManager)
  {
    return
      IMoneyMarketManager(
        _finder.getImplementationAddress(
          SynthereumInterfaces.MoneyMarketManager
        )
      );
  }

  function getAtomicSwap(ISynthereumFinder _finder)
    internal
    view
    returns (ISynthereumOnChainLiquidityRouter)
  {
    return
      ISynthereumOnChainLiquidityRouter(
        _finder.getImplementationAddress(SynthereumInterfaces.AtomicSwap)
      );
  }

  function getPoolSwapModule(ISynthereumFinder _finder)
    internal
    view
    returns (IPoolSwap)
  {
    return
      IPoolSwap(
        _finder.getImplementationAddress(SynthereumInterfaces.PoolSwapModule)
      );
  }

  function getFixedRateSwapModule(ISynthereumFinder _finder)
    internal
    view
    returns (IFixedRateSwap)
  {
    return
      IFixedRateSwap(
        _finder.getImplementationAddress(
          SynthereumInterfaces.FixedRateSwapModule
        )
      );
  }

  function getTrustedForwarder(ISynthereumFinder _finder)
    internal
    view
    returns (address)
  {
    return
      _finder.getImplementationAddress(SynthereumInterfaces.TrustedForwarder);
  }
}

library SynthereumFactoryVersioningLib {
  function getPoolFactory(
    ISynthereumFactoryVersioning _factoryVersioning,
    uint8 _version
  ) internal view returns (address) {
    return
      _factoryVersioning.getFactoryVersion(
        FactoryVersioningInterfaces.PoolFactory,
        _version
      );
  }

  function getFixedRateFactory(
    ISynthereumFactoryVersioning _factoryVersioning,
    uint8 _version
  ) internal view returns (address) {
    return
      _factoryVersioning.getFactoryVersion(
        FactoryVersioningInterfaces.FixedRateFactory,
        _version
      );
  }

  function getSelfMintingFactory(
    ISynthereumFactoryVersioning _factoryVersioning,
    uint8 _version
  ) internal view returns (address) {
    return
      _factoryVersioning.getFactoryVersion(
        FactoryVersioningInterfaces.SelfMintingFactory,
        _version
      );
  }

  function numberOfPoolVersions(ISynthereumFactoryVersioning _factoryVersioning)
    internal
    view
    returns (uint8)
  {
    return
      _factoryVersioning.numberOfFactoryVersions(
        FactoryVersioningInterfaces.PoolFactory
      );
  }

  function numberOfFixedRateVersions(
    ISynthereumFactoryVersioning _factoryVersioning
  ) internal view returns (uint8) {
    return
      _factoryVersioning.numberOfFactoryVersions(
        FactoryVersioningInterfaces.FixedRateFactory
      );
  }

  function numberOfSelfMintingVersions(
    ISynthereumFactoryVersioning _factoryVersioning
  ) internal view returns (uint8) {
    return
      _factoryVersioning.numberOfFactoryVersions(
        FactoryVersioningInterfaces.SelfMintingFactory
      );
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ISynthereumDeployment} from '../../common/interfaces/IDeployment.sol';
import {
  SynthereumPoolMigrationFrom
} from '../../synthereum-pool/common/migration/PoolMigrationFrom.sol';

/**
 * @title Provides interface with functions of Synthereum deployer
 */
interface ISynthereumDeployer {
  /**
   * @notice Deploy a new pool
   * @param _poolVersion Version of the pool contract
   * @param _poolParamsData Input params of pool constructor
   * @return pool Pool contract deployed
   */
  function deployPool(uint8 _poolVersion, bytes calldata _poolParamsData)
    external
    returns (ISynthereumDeployment pool);

  /**
   * @notice Migrate storage of an existing pool to e new deployed one
   * @param _migrationPool Pool from which migrate storage
   * @param _poolVersion Version of the pool contract to create
   * @param _migrationParamsData Input params of migration (if needed)
   * @return pool Pool contract deployed
   */
  function migratePool(
    SynthereumPoolMigrationFrom _migrationPool,
    uint8 _poolVersion,
    bytes calldata _migrationParamsData
  ) external returns (ISynthereumDeployment pool);

  /**
   * @notice Remove from the registry an existing pool
   * @param _pool Pool to remove
   */
  function removePool(ISynthereumDeployment _pool) external;

  /**
   * @notice Deploy a new self minting derivative contract
   * @param _selfMintingDerVersion Version of the self minting derivative contract
   * @param _selfMintingDerParamsData Input params of self minting derivative constructor
   * @return selfMintingDerivative Self minting derivative contract deployed
   */
  function deploySelfMintingDerivative(
    uint8 _selfMintingDerVersion,
    bytes calldata _selfMintingDerParamsData
  ) external returns (ISynthereumDeployment selfMintingDerivative);

  /**
   * @notice Remove from the registry an existing self-minting derivativ contract
   * @param _selfMintingDerivative Self-minting derivative to remove
   */
  function removeSelfMintingDerivative(
    ISynthereumDeployment _selfMintingDerivative
  ) external;

  /**
   * @notice Deploy a new fixed rate wrapper contract
   * @param _fixedRateVersion Version of the fixed rate wrapper contract
   * @param _fixedRateParamsData Input params of fixed rate wrapper constructor
   * @return fixedRate Fixed rate wrapper contract deployed
   */
  function deployFixedRate(
    uint8 _fixedRateVersion,
    bytes calldata _fixedRateParamsData
  ) external returns (ISynthereumDeployment fixedRate);

  /**
   * @notice Remove from the registry a fixed rate wrapper
   * @param _fixedRate Fixed-rate to remove
   */
  function removeFixedRate(ISynthereumDeployment _fixedRate) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {IERC20} from '../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
 * @title Provides interface with functions of SynthereumRegistry
 */

interface ISynthereumRegistry {
  /**
   * @notice Allow the deployer to register an element
   * @param syntheticTokenSymbol Symbol of the syntheticToken of the element to register
   * @param collateralToken Collateral ERC20 token of the element to register
   * @param version Version of the element to register
   * @param element Address of the element to register
   */
  function register(
    string calldata syntheticTokenSymbol,
    IERC20 collateralToken,
    uint8 version,
    address element
  ) external;

  /**
   * @notice Allow the deployer to unregister an element
   * @param syntheticTokenSymbol Symbol of the syntheticToken of the element to unregister
   * @param collateralToken Collateral ERC20 token of the element to unregister
   * @param version Version of the element  to unregister
   * @param element Address of the element  to unregister
   */
  function unregister(
    string calldata syntheticTokenSymbol,
    IERC20 collateralToken,
    uint8 version,
    address element
  ) external;

  /**
   * @notice Returns if a particular element exists or not
   * @param syntheticTokenSymbol Synthetic token symbol of the element
   * @param collateralToken ERC20 contract of collateral currency
   * @param version Version of the element
   * @param element Contract of the element to check
   * @return isElementDeployed Returns true if a particular element exists, otherwise false
   */
  function isDeployed(
    string calldata syntheticTokenSymbol,
    IERC20 collateralToken,
    uint8 version,
    address element
  ) external view returns (bool isElementDeployed);

  /**
   * @notice Returns all the elements with partcular symbol, collateral and version
   * @param syntheticTokenSymbol Synthetic token symbol of the element
   * @param collateralToken ERC20 contract of collateral currency
   * @param version Version of the element
   * @return List of all elements
   */
  function getElements(
    string calldata syntheticTokenSymbol,
    IERC20 collateralToken,
    uint8 version
  ) external view returns (address[] memory);

  /**
   * @notice Returns all the synthetic token symbol used
   * @return List of all synthetic token symbol
   */
  function getSyntheticTokens() external view returns (string[] memory);

  /**
   * @notice Returns all the versions used
   * @return List of all versions
   */
  function getVersions() external view returns (uint8[] memory);

  /**
   * @notice Returns all the collaterals used
   * @return List of all collaterals
   */
  function getCollaterals() external view returns (address[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/**
 * @title Provides addresses of different versions of pools factory and derivative factory
 */
interface ISynthereumFactoryVersioning {
  /** @notice Sets a Factory
   * @param factoryType Type of factory
   * @param version Version of the factory to be set
   * @param factory The pool factory address to be set
   */
  function setFactory(
    bytes32 factoryType,
    uint8 version,
    address factory
  ) external;

  /** @notice Removes a factory
   * @param factoryType The type of factory to be removed
   * @param version Version of the factory to be removed
   */
  function removeFactory(bytes32 factoryType, uint8 version) external;

  /** @notice Gets a factory contract address
   * @param factoryType The type of factory to be checked
   * @param version Version of the factory to be checked
   * @return factory Address of the factory contract
   */
  function getFactoryVersion(bytes32 factoryType, uint8 version)
    external
    view
    returns (address factory);

  /** @notice Gets the number of factory versions for a specific type
   * @param factoryType The type of factory to be checked
   * @return numberOfVersions Total number of versions for a specific factory
   */
  function numberOfFactoryVersions(bytes32 factoryType)
    external
    view
    returns (uint8 numberOfVersions);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {
  IEmergencyShutdown
} from '../../common/interfaces/IEmergencyShutdown.sol';
import {
  ISynthereumLendingSwitch
} from '../../synthereum-pool/common/interfaces/ILendingSwitch.sol';
import {
  ISynthereumBuybackPool
} from '../../synthereum-pool/common/interfaces/IBuybackPool.sol';
import {
  IJarvisBuybackVault
} from '../../jarvis-token/interfaces/IBuybackVault.sol';

interface ISynthereumManager {
  /**
   * @notice Allow to add roles in derivatives and synthetic tokens contracts
   * @param contracts Derivatives or Synthetic role contracts
   * @param roles Roles id
   * @param accounts Addresses to which give the grant
   */
  function grantSynthereumRole(
    address[] calldata contracts,
    bytes32[] calldata roles,
    address[] calldata accounts
  ) external;

  /**
   * @notice Allow to revoke roles in derivatives and synthetic tokens contracts
   * @param contracts Derivatives or Synthetic role contracts
   * @param roles Roles id
   * @param accounts Addresses to which revoke the grant
   */
  function revokeSynthereumRole(
    address[] calldata contracts,
    bytes32[] calldata roles,
    address[] calldata accounts
  ) external;

  /**
   * @notice Allow to renounce roles in derivatives and synthetic tokens contracts
   * @param contracts Derivatives or Synthetic role contracts
   * @param roles Roles id
   */
  function renounceSynthereumRole(
    address[] calldata contracts,
    bytes32[] calldata roles
  ) external;

  /**
   * @notice Allow to call emergency shutdown in a pool or self-minting derivative
   * @param contracts Contracts to shutdown
   */
  function emergencyShutdown(IEmergencyShutdown[] calldata contracts) external;

  /**
   * @notice Set new lending protocol for a list of pool
   * @param lendingIds Name of the new lending modules of the pools
   * @param bearingTokens Tokens of the lending mosule to be used for intersts accrual in the pools
   */
  function switchLendingModule(
    ISynthereumLendingSwitch[] calldata pools,
    string[] calldata lendingIds,
    address[] calldata bearingTokens
  ) external;

  /**
   * @notice Migrate buybackVault of a list of pools
   * @param pools List of the pools
   * @return List of new buybackVault migrated for each pool in the list
   */
  function migrateBuybackVault(ISynthereumBuybackPool[] calldata pools)
    external
    returns (IJarvisBuybackVault[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/**
 * @title An interface to track a whitelist of addresses.
 */
interface ISynthereumCollateralWhitelist {
  /**
   * @notice Adds an address to the whitelist.
   * @param newCollateral the new address to add.
   */
  function addToWhitelist(address newCollateral) external;

  /**
   * @notice Removes an address from the whitelist.
   * @param collateralToRemove The existing address to remove.
   */
  function removeFromWhitelist(address collateralToRemove) external;

  /**
   * @notice Checks whether an address is on the whitelist.
   * @param collateralToCheck The address to check.
   * @return True if `collateralToCheck` is on the whitelist, or False.
   */
  function isOnWhitelist(address collateralToCheck)
    external
    view
    returns (bool);

  /**
   * @notice Gets all addresses that are currently included in the whitelist.
   * @return The list of addresses on the whitelist.
   */
  function getWhitelist() external view returns (address[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/**
 * @title An interface to track a whitelist of identifiers.
 */
interface ISynthereumIdentifierWhitelist {
  /**
   * @notice Adds an identifier to the whitelist.
   * @param newIdentifier the new identifier to add.
   */
  function addToWhitelist(bytes32 newIdentifier) external;

  /**
   * @notice Removes an identifier from the whitelist.
   * @param identifierToRemove The existing identifier to remove.
   */
  function removeFromWhitelist(bytes32 identifierToRemove) external;

  /**
   * @notice Checks whether an address is on the whitelist.
   * @param identifierToCheck The address to check.
   * @return True if `identifierToCheck` is on the whitelist, or False.
   */
  function isOnWhitelist(bytes32 identifierToCheck)
    external
    view
    returns (bool);

  /**
   * @notice Gets all identifiers that are currently included in the whitelist.
   * @return The list of identifiers on the whitelist.
   */
  function getWhitelist() external view returns (bytes32[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;
import {
  BaseControlledMintableBurnableERC20
} from '../../BaseControlledMintableBurnableERC20.sol';

/**
 * @title Interface for interacting with the MintableBurnableTokenFactory contract
 */
interface IMintableBurnableTokenFactory {
  /** @notice Calls the deployment of a new ERC20 token
   * @param tokenName The name of the token to be deployed
   * @param tokenSymbol The symbol of the token that will be deployed
   * @param tokenDecimals Number of decimals for the token to be deployed
   */
  function createToken(
    string memory tokenName,
    string memory tokenSymbol,
    uint8 tokenDecimals
  ) external returns (BaseControlledMintableBurnableERC20 newToken);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {IJarvisBuybackVault} from './IBuybackVault.sol';
import {JarvisBuybackVault} from '../BuybackVault.sol';

interface IJarvisBuybackFactory {
  function createVault(address _referencePool, uint256 _maxEpochsClaim)
    external
    returns (JarvisBuybackVault vault);

  function migrateVault(
    IJarvisBuybackVault _migrationVault,
    bytes calldata _extraInputParams
  )
    external
    returns (IJarvisBuybackVault migrationVaultUsed, JarvisBuybackVault vault);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {IERC20} from '../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ICreditLineStorage} from './ICreditLineStorage.sol';
import {
  FixedPoint
} from '../../../../@uma/core/contracts/common/implementation/FixedPoint.sol';

/** @title Interface for interacting with the SelfMintingController
 */
interface ICreditLineController {
  /**
   * @notice Allow to set collateralRequirement percentage on a list of registered self-minting derivatives
   * @param selfMintingDerivatives Self-minting derivatives
   * @param collateralRequirements Over collateralization percentage for self-minting derivatives
   */
  function setCollateralRequirement(
    address[] calldata selfMintingDerivatives,
    uint256[] calldata collateralRequirements
  ) external;

  /**
   * @notice Allow to set capMintAmount on a list of registered self-minting derivatives
   * @param selfMintingDerivatives Self-minting derivatives
   * @param capMintAmounts Mint cap amounts for self-minting derivatives
   */
  function setCapMintAmount(
    address[] calldata selfMintingDerivatives,
    uint256[] calldata capMintAmounts
  ) external;

  /**
   * @notice Allow to set fee percentages on a list of registered self-minting derivatives
   * @param selfMintingDerivatives Self-minting derivatives
   * @param feePercentages fee percentages for self-minting derivatives
   */
  function setFeePercentage(
    address[] calldata selfMintingDerivatives,
    uint256[] calldata feePercentages
  ) external;

  /**
   * @notice Update the addresses and weight of recipients for generated fees
   * @param selfMintingDerivatives Derivatives to update
   * @param feeRecipients A two-dimension array containing for each derivative the addresses of fee recipients
   * @param feeProportions An array of the proportions of fees generated each recipient will receive
   */
  function setFeeRecipients(
    address[] calldata selfMintingDerivatives,
    address[][] calldata feeRecipients,
    uint32[][] calldata feeProportions
  ) external;

  /**
   * @notice Update the liquidation reward percentage
   * @param selfMintingDerivatives Derivatives to update
   * @param _liquidationRewards Percentage of reward for correct liquidation by a liquidator
   */
  function setLiquidationRewardPercentage(
    address[] calldata selfMintingDerivatives,
    uint256[] calldata _liquidationRewards
  ) external;

  /**
   * @notice Gets the over collateralization percentage of a self-minting derivative
   * @param selfMintingDerivative Derivative to read value of
   * @return the collateralRequirement percentage
   */
  function getCollateralRequirement(address selfMintingDerivative)
    external
    view
    returns (uint256);

  /**
   * @notice Gets the set liquidtion reward percentage of a self-minting derivative
   * @param selfMintingDerivative Self-minting derivative
   * @return liquidation Reward percentage
   */
  function getLiquidationRewardPercentage(address selfMintingDerivative)
    external
    view
    returns (uint256);

  /**
   * @notice Gets the set CapMintAmount of a self-minting derivative
   * @param selfMintingDerivative Self-minting derivative
   * @return capMintAmount Limit amount for minting
   */
  function getCapMintAmount(address selfMintingDerivative)
    external
    view
    returns (uint256 capMintAmount);

  /**
   * @notice Gets the fee params of a self-minting derivative
   * @param selfMintingDerivative Self-minting derivative
   * @return fee fee info (percent + recipient + proportions)
   */
  function getFeeInfo(address selfMintingDerivative)
    external
    view
    returns (ICreditLineStorage.Fee memory fee);

  /**
   * @notice Gets the fee percentage of a self-minting derivative
   * @param selfMintingDerivative Self-minting derivative
   * @return feePercentage value
   */
  function feePercentage(address selfMintingDerivative)
    external
    view
    returns (uint256);

  /**
   * @notice Returns fee recipients info
   * @return Addresses, weigths and total of weigtht
   */
  function feeRecipientsInfo(address selfMintingDerivative)
    external
    view
    returns (
      address[] memory,
      uint32[] memory,
      uint256
    );
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

interface ISynthereumPriceFeed {
  /**
   * @notice Get last chainlink oracle price for a given price identifier
   * @param _priceIdentifier Price feed identifier
   * @return price Oracle price
   */
  function getLatestPrice(bytes32 _priceIdentifier)
    external
    view
    returns (uint256 price);

  /**
   * @notice Return if price identifier is supported
   * @param _priceIdentifier Price feed identifier
   * @return isSupported True if price is supported otherwise false
   */
  function isPriceSupported(bytes32 _priceIdentifier)
    external
    view
    returns (bool isSupported);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ILendingStorageManager} from './ILendingStorageManager.sol';
import {
  ISynthereumOnChainLiquidityRouter
} from '../../atomic-swap/interfaces/IOnChainLiquidityRouter.sol';

interface ILendingManager {
  struct ReturnValues {
    uint256 poolInterest; //accumulated pool interest since last state-changing operation;
    uint256 daoInterest; //acccumulated dao interest since last state-changing operation;
    uint256 tokensOut; //amount of collateral used for a money market operation
    uint256 tokensTransferred; //amount of tokens finally transfered/received from money market (after eventual fees)
    uint256 prevTotalCollateral; //total collateral in the pool (users + LPs) before new operation
  }

  struct InterestSplit {
    uint256 poolInterest; // share of the total interest generated to the LPs;
    uint256 jrtInterest; // share of the total interest generated for jrt buyback;
    uint256 commissionInterest; // share of the total interest generated as dao commission;
  }

  struct MigrateReturnValues {
    uint256 prevTotalCollateral; // prevDepositedCollateral collateral deposited (without last interests) before the migration
    uint256 poolInterest; // poolInterests collateral interests accumalated before the migration
    uint256 actualTotalCollateral; // actualCollateralDeposited collateral deposited after the migration
  }

  event BatchBuyback(
    uint256 indexed collateralIn,
    uint256 JRTOut,
    address receiver
  );

  event BatchCommissionClaim(uint256 indexed collateralOut, address receiver);

  /**
   * @notice deposits collateral into the pool's associated money market
   * @dev calculates and return the generated interest since last state-changing operation
   * @param _collateralAmount amount of collateral to deposit
   * @return returnValues check struct
   */
  function deposit(uint256 _collateralAmount)
    external
    returns (ReturnValues memory returnValues);

  /**
   * @notice transfer bearing tokens in the destination pool during the atomic swap exchange
   * @dev calculates and return the generated interest since last state-changing operation
   * @param _collateralAmount amount of collateral to deposit
   * @return returnValues check struct
   */
  function crossDeposit(uint256 _collateralAmount)
    external
    returns (ReturnValues memory returnValues);

  /**
   * @notice withdraw collateral from the pool's associated money market
   * @dev calculates and return the generated interest since last state-changing operation
   * @param _interestTokenAmount amount of interest tokens to redeem
   * @param _recipient the address receiving the collateral from money market
   * @return returnValues check struct
   */
  function withdraw(uint256 _interestTokenAmount, address _recipient)
    external
    returns (ReturnValues memory returnValues);

  /**
   * @notice keep on the lending manager bearing tokens received by the source pool during atomic-swap exchange
   * @dev calculates and return the generated interest since last state-changing operation
   * @param _interestTokenAmount amount of interest tokens to redeem
   * @return returnValues check struct
   */
  function crossWithdraw(uint256 _interestTokenAmount)
    external
    returns (ReturnValues memory returnValues);

  /**
   * @notice calculate, split and update the generated interest of the caller pool since last state-changing operation
   * @return returnValues check struct
   */
  function updateAccumulatedInterest()
    external
    returns (ReturnValues memory returnValues);

  /**
   * @notice batches calls to redeem poolData.commissionInterest from multiple pools
   * @dev calculates and update the generated interest since last state-changing operation
   * @param _pools array of pools to redeem commissions from
   * @param _collateralAmounts array of amount of commission to redeem for each pool (matching pools order)
   */
  function batchClaimCommission(
    address[] calldata _pools,
    uint256[] calldata _collateralAmounts
  ) external;

  /**
   * @notice batches calls to redeem poolData.jrtInterest from multiple pools
   * @notice and executes a swap to buy Jarvis Reward Token
   * @dev calculates and update the generated interest since last state-changing operation
   * @param _pools array of pools to redeem collateral from
   * @param _collateralAmounts array of amount of commission to redeem for each pool (matching pools order)
   * @param _collateralAddress address of the pools collateral token (all pools must have the same collateral)
   * @param _dexImplementationId string identifying the atomic swap module (dex) to use
   * @param _swapParams ISynthereumOnChainLiquidityRouter struct param for the swap
   */
  function batchBuyback(
    address[] calldata _pools,
    uint256[] calldata _collateralAmounts,
    address _collateralAddress,
    string calldata _dexImplementationId,
    ISynthereumOnChainLiquidityRouter.SwapParams calldata _swapParams
  ) external;

  /**
   * @notice sets the address of the implementation of a lending module and its extraBytes
   * @param _id associated to the lending module to be set
   * @param _lendingInfo see lendingInfo struct
   */
  function setLendingModule(
    string calldata _id,
    ILendingStorageManager.LendingInfo calldata _lendingInfo
  ) external;

  /**
   * @notice sets an address as the swap module associated to a specific collateral
   * @dev the swapModule must implement the IJRTSwapModule interface
   * @param _collateral collateral address associated to the swap module
   * @param _swapModule IJRTSwapModule implementer contract
   */
  function setSwapModule(address _collateral, address _swapModule) external;

  /**
   * @notice set shares on interest generated by a pool collateral on the lending storage manager
   * @param _pool pool address to set shares on
   * @param _daoInterestShare share of total interest generated assigned to the dao
   * @param _jrtBuybackShare share of the total dao interest used to buyback jrt from an AMM
   */
  function setShares(
    address _pool,
    uint64 _daoInterestShare,
    uint64 _jrtBuybackShare
  ) external;

  /**
   * @notice migrates liquidity from one lending module (and money market), to a new one
   * @dev calculates and return the generated interest since last state-changing operation.
   * @dev The new lending module info must be have been previously set in the storage manager
   * @param _newLendingID id associated to the new lending module info
   * @param _newInterestBearingToken address of the interest token of the new money market
   * @param _interestTokenAmount total amount of interest token to migrate from old to new money market
   * @return migrateReturnValues check struct
   */
  function migrateLendingModule(
    string memory _newLendingID,
    address _newInterestBearingToken,
    uint256 _interestTokenAmount
  ) external returns (MigrateReturnValues memory);

  /**
   * @notice migrates pool storage from a deployed pool to a new pool
   * @param _migrationPool Pool from which the storage is migrated
   * @param _newPool address of the new pool
   * @return sourceCollateralAmount Collateral amount of the pool to migrate
   * @return actualCollateralAmount Collateral amount of the new deployed pool
   */
  function migratePool(address _migrationPool, address _newPool)
    external
    returns (uint256 sourceCollateralAmount, uint256 actualCollateralAmount);

  /**
   * @notice Claim leinding protocol rewards of a list of pools
   * @notice _pools List of pools from which claim rewards
   */
  function claimLendingRewards(address[] calldata _pools) external;

  /**
   * @notice returns the conversion between interest token and collateral of a specific money market
   * @param _pool reference pool to check conversion
   * @param _interestTokenAmount amount of interest token to calculate conversion on
   * @return collateralAmount amount of collateral after conversion
   * @return interestTokenAddr address of the associated interest token
   */
  function interestTokenToCollateral(
    address _pool,
    uint256 _interestTokenAmount
  ) external view returns (uint256 collateralAmount, address interestTokenAddr);

  /**
   * @notice returns accumulated interest of a pool since state-changing last operation
   * @dev does not update state
   * @param _pool reference pool to check accumulated interest
   * @return poolInterest amount of interest generated for the pool after splitting the dao share
   * @return commissionInterest amount of interest generated for the dao commissions
   * @return buybackInterest amount of interest generated for the buyback
   * @return collateralDeposited total amount of collateral currently deposited by the pool
   */
  function getAccumulatedInterest(address _pool)
    external
    view
    returns (
      uint256 poolInterest,
      uint256 commissionInterest,
      uint256 buybackInterest,
      uint256 collateralDeposited
    );

  /**
   * @notice returns the conversion between collateral and interest token of a specific money market
   * @param _pool reference pool to check conversion
   * @param _collateralAmount amount of collateral to calculate conversion on
   * @return interestTokenAmount amount of interest token after conversion
   * @return interestTokenAddr address of the associated interest token
   */
  function collateralToInterestToken(address _pool, uint256 _collateralAmount)
    external
    view
    returns (uint256 interestTokenAmount, address interestTokenAddr);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

interface ILendingStorageManager {
  struct PoolStorage {
    bytes32 lendingModuleId; // hash of the lending module id associated with the LendingInfo the pool currently is using
    uint256 collateralDeposited; // amount of collateral currently deposited in the MoneyMarket
    uint256 unclaimedDaoJRT; // amount of interest to be claimed to buyback JRT
    uint256 unclaimedDaoCommission; // amount of interest to be claimed as commission (in collateral)
    address collateral; // collateral address of the pool
    uint64 jrtBuybackShare; // share of dao interest used to buyback JRT
    address interestBearingToken; // interest token address of the pool
    uint64 daoInterestShare; // share of total interest generated by the pool directed to the DAO
  }

  struct PoolLendingStorage {
    address collateralToken; // address of the collateral token of a pool
    address interestToken; // address of interest token of a pool
  }

  struct LendingInfo {
    address lendingModule; // address of the ILendingModule interface implementer
    bytes args; // encoded args the ILendingModule implementer might need
  }

  /**
   * @notice sets a ILendingModule implementer info
   * @param _id string identifying a specific ILendingModule implementer
   * @param _lendingInfo see lendingInfo struct
   */
  function setLendingModule(
    string calldata _id,
    LendingInfo calldata _lendingInfo
  ) external;

  /**
   * @notice Add a swap module to the whitelist
   * @param _swapModule Swap module to add
   */
  function addSwapProtocol(address _swapModule) external;

  /**
   * @notice Remove a swap module from the whitelist
   * @param _swapModule Swap module to remove
   */
  function removeSwapProtocol(address _swapModule) external;

  /**
   * @notice sets an address as the swap module associated to a specific collateral
   * @dev the swapModule must implement the IJRTSwapModule interface
   * @param _collateral collateral address associated to the swap module
   * @param _swapModule IJRTSwapModule implementer contract
   */
  function setSwapModule(address _collateral, address _swapModule) external;

  /**
   * @notice set shares on interest generated by a pool collateral on the lending storage manager
   * @param _pool pool address to set shares on
   * @param _daoInterestShare share of total interest generated assigned to the dao
   * @param _jrtBuybackShare share of the total dao interest used to buyback jrt from an AMM
   */
  function setShares(
    address _pool,
    uint64 _daoInterestShare,
    uint64 _jrtBuybackShare
  ) external;

  /**
   * @notice store data for lending manager associated to a pool
   * @param _lendingID string identifying the associated ILendingModule implementer
   * @param _pool pool address to set info
   * @param _collateral collateral address of the pool
   * @param _interestBearingToken address of the interest token in use
   * @param _daoInterestShare share of total interest generated assigned to the dao
   * @param _jrtBuybackShare share of the total dao interest used to buyback jrt from an AMM
   */
  function setPoolStorage(
    string calldata _lendingID,
    address _pool,
    address _collateral,
    address _interestBearingToken,
    uint64 _daoInterestShare,
    uint64 _jrtBuybackShare
  ) external;

  /**
   * @notice assign oldPool storage information and state to newPool address and deletes oldPool storage slot
   * @dev is used when a pool is redeployed and the liquidity transferred over
   * @param _oldPool address of old pool to migrate storage from
   * @param _newPool address of the new pool receiving state of oldPool
   * @param _newCollateralDeposited Amount of collateral deposited in the new pool after the migration
   */
  function migratePoolStorage(
    address _oldPool,
    address _newPool,
    uint256 _newCollateralDeposited
  ) external;

  /**
   * @notice sets new lending info on a pool
   * @dev used when migrating liquidity from one lending module (and money market), to a new one
   * @dev The new lending module info must be have been previously set in the storage manager
   * @param _newLendingID id associated to the new lending module info
   * @param _pool address of the pool whose associated lending module is being migrated
   * @param _newInterestToken address of the interest token of the new Lending Module (can be set blank)
   * @return poolData with the updated state
   * @return lendingInfo of the new lending module
   */
  function migrateLendingModule(
    string calldata _newLendingID,
    address _pool,
    address _newInterestToken
  ) external returns (PoolStorage memory, LendingInfo memory);

  /**
   * @notice updates storage of a pool
   * @dev should be callable only by LendingManager after state-changing operations
   * @param _pool address of the pool to update values
   * @param _collateralDeposited updated amount of collateral deposited
   * @param _daoJRT updated amount of unclaimed interest for JRT buyback
   * @param _daoInterest updated amount of unclaimed interest as dao commission
   */
  function updateValues(
    address _pool,
    uint256 _collateralDeposited,
    uint256 _daoJRT,
    uint256 _daoInterest
  ) external;

  /**
   * @notice Returns info about a supported lending module
   * @param _id Name of the module
   * @return lendingInfo Address and bytes associated to the lending mdodule
   */
  function getLendingModule(string calldata _id)
    external
    view
    returns (LendingInfo memory lendingInfo);

  /**
   * @notice reads PoolStorage of a pool
   * @param _pool address of the pool to read storage
   * @return poolData pool struct info
   */
  function getPoolStorage(address _pool)
    external
    view
    returns (PoolStorage memory poolData);

  /**
   * @notice reads PoolStorage and LendingInfo of a pool
   * @param _pool address of the pool to read storage
   * @return poolData pool struct info
   * @return lendingInfo information of the lending module associated with the pool
   */
  function getPoolData(address _pool)
    external
    view
    returns (PoolStorage memory poolData, LendingInfo memory lendingInfo);

  /**
   * @notice reads lendingStorage and LendingInfo of a pool
   * @param _pool address of the pool to read storage
   * @return lendingStorage information of the addresses of collateral and intrestToken
   * @return lendingInfo information of the lending module associated with the pool
   */
  function getLendingData(address _pool)
    external
    view
    returns (
      PoolLendingStorage memory lendingStorage,
      LendingInfo memory lendingInfo
    );

  /**
   * @notice Return the list containing every swap module supported
   * @return List of swap modules
   */
  function getSwapModules() external view returns (address[] memory);

  /**
   * @notice reads the JRT Buyback module associated to a collateral
   * @param _collateral address of the collateral to retrieve module
   * @return swapModule address of interface implementer of the IJRTSwapModule
   */
  function getCollateralSwapModule(address _collateral)
    external
    view
    returns (address swapModule);

  /**
   * @notice reads the interest beaaring token address associated to a pool
   * @param _pool address of the pool to retrieve interest token
   * @return interestTokenAddr address of the interest token
   */
  function getInterestBearingToken(address _pool)
    external
    view
    returns (address interestTokenAddr);

  /**
   * @notice reads the shares used for splitting interests between pool, dao and buyback
   * @param _pool address of the pool to retrieve interest token
   * @return jrtBuybackShare Percentage of interests claimable by th DAO
   * @return daoInterestShare Percentage of interests used for the buyback
   */
  function getShares(address _pool)
    external
    view
    returns (uint256 jrtBuybackShare, uint256 daoInterestShare);

  /**
   * @notice reads the last collateral amount deposited in the pool
   * @param _pool address of the pool to retrieve collateral amount
   * @return collateralAmount Amount of collateral deposited in the pool
   */
  function getCollateralDeposited(address _pool)
    external
    view
    returns (uint256 collateralAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >0.8.0;
import {
  IMintableBurnableERC20
} from '../../tokens/interfaces/IMintableBurnableERC20.sol';

interface IJarvisBrrrrr {
  struct AccessContract {
    string contractName;
    address contractAddress;
  }

  /**
   * @notice Add a contract to the withelist containing names of the contracts that have access to this contract
   * @notice Only maintainer can call this function
   * @param _contractName Name of the contract to add
   */
  function addAccessContract(string calldata _contractName) external;

  /**
   * @notice Remove a contract from the withelist containing names of the contracts that have access to this contract
   * @notice Only maintainer can call this function
   * @param _contractName Name of the contract to remove
   */
  function removeAccessContract(string calldata _contractName) external;

  /**
   * @notice Sets the max circulating supply that can be minted for a specific token - only manager can set this
   * @notice Only maintainer can call this function
   * @param _token Synthetic token address to set
   * @param _newMaxSupply New Max supply value of the token
   */
  function setMaxSupply(IMintableBurnableERC20 _token, uint256 _newMaxSupply)
    external;

  /**
   * @notice Mints synthetic token without collateral to a pre-defined address (SynthereumMoneyMarketManager)
   * @param _token Synthetic token address to mint
   * @param _amount Amount of tokens to mint
   * @return newCirculatingSupply New circulating supply in Money Market
   */
  function mint(IMintableBurnableERC20 _token, uint256 _amount)
    external
    returns (uint256 newCirculatingSupply);

  /**
   * @notice Burns synthetic token without releasing collateral from the pre-defined address (SynthereumMoneyMarketManager)
   * @param _token Synthetic token address to burn
   * @param _amount Amount of tokens to burn
   * @return newCirculatingSupply New circulating supply in Money Market
   */
  function redeem(IMintableBurnableERC20 _token, uint256 _amount)
    external
    returns (uint256 newCirculatingSupply);

  /**
   * @notice Returns the max circulating supply of a synthetic token
   * @param _token Synthetic token address
   * @return maxCircSupply Max supply of the token
   */
  function maxSupply(IMintableBurnableERC20 _token)
    external
    view
    returns (uint256 maxCircSupply);

  /**
   * @notice Returns the circulating supply of a synthetic token
   * @param _token Synthetic token address
   * @return circSupply Circulating supply of the token
   */
  function supply(IMintableBurnableERC20 _token)
    external
    view
    returns (uint256 circSupply);

  /**
   * @notice Returns the list of contracts that has access to this contract
   * @return List of contracts (name and address from the finder)
   */
  function accessContractWhitelist()
    external
    view
    returns (AccessContract[] memory);

  /**
   * @notice Returns if a contract name has access to this contract
   * @return hasAccess True if has access otherwise false
   */
  function hasContractAccess(string calldata _contractName)
    external
    view
    returns (bool hasAccess);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {
  IMintableBurnableERC20
} from '../../tokens/interfaces/IMintableBurnableERC20.sol';
import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IMoneyMarketManager {
  // implementation variables
  struct Implementation {
    address implementationAddr;
    bytes moneyMarketArgs;
  }

  /**
   * @notice Registers an address implementing the IJarvisBrrMoneyMarket interface
   * @param _id Identifier of the implementation
   * @param _implementation Address of the implementation
   * @param _extraArgs bytes Encoded args for the implementation
   */
  function registerMoneyMarketImplementation(
    string calldata _id,
    address _implementation,
    bytes calldata _extraArgs
  ) external;

  /**
   * @notice deposits printed jSynth into the money market
   * @param _jSynthAsset address of the jSynth token to deposit
   * @param _amount of jSynth to deposit
   * @param _moneyMarketId identifier of the money market implementation contract to withdraw the tokens from money market
   * @param _implementationCallArgs bytes encoded arguments necessary for this specific implementation call (ie cToken)
   * @return tokensOut amount of eventual tokens received from money market
   */
  function deposit(
    IMintableBurnableERC20 _jSynthAsset,
    uint256 _amount,
    string calldata _moneyMarketId,
    bytes calldata _implementationCallArgs
  ) external returns (uint256 tokensOut);

  /**
   * @notice withdraw jSynth from the money market
   * @dev the same amount must be burned in the same tx
   * @param _jSynthAsset address of the jSynth token to withdraw
   * @param _interestTokenAmount of interest tokens to withdraw
   * @param _moneyMarketId identifier of the money market implementation contract to withdraw the tokens from money market
   * @param _implementationCallArgs bytes encoded arguments necessary for this specific implementation call (ie cToken)
   * @return jSynthOut amount of j Synth in output
   */
  function withdraw(
    IMintableBurnableERC20 _jSynthAsset,
    uint256 _interestTokenAmount,
    string calldata _moneyMarketId,
    bytes calldata _implementationCallArgs
  ) external returns (uint256 jSynthOut);

  /**
   * @notice withdraw generated interest from deposits in money market and sends them to dao
   * @param _jSynthAsset address of the jSynth token to get revenues of
   * @param _recipient address of recipient of revenues
   * @param _moneyMarketId identifier of the money market implementation contract
   * @param _implementationCallArgs bytes encoded arguments necessary for this specific implementation call (ie cToken)
   * @return jSynthOut amount of jSynth sent to the DAO
   */
  function withdrawRevenue(
    IMintableBurnableERC20 _jSynthAsset,
    address _recipient,
    string memory _moneyMarketId,
    bytes memory _implementationCallArgs
  ) external returns (uint256 jSynthOut);

  /**
   * @notice reads the amount of jSynth currently minted + deposited into a money market
   * @param _moneyMarketId identifier of the money market implementation contract
   * @param _jSynthAsset address of the jSynth token to get amount
   * @return amount amount of jSynth currently minted + deposited into moneyMarketId
   */
  function getMoneyMarketDeposited(
    string calldata _moneyMarketId,
    address _jSynthAsset
  ) external view returns (uint256 amount);

  /**
   * @notice reads implementation data of a supported money market
   * @param _moneyMarketId identifier of the money market implementation contract
   * @return implementation Address of the implementation and global data bytes
   */
  function getMoneyMarketImplementation(string calldata _moneyMarketId)
    external
    view
    returns (Implementation memory implementation);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import {
  ISynthereumUserPool
} from '../../synthereum-pool/common/interfaces/IUserPool.sol';
import {
  ISynthereumAtomicSwapPool
} from '../../synthereum-pool/common/interfaces/IAtomicSwapPool.sol';
import {
  ISynthereumFixedRateUserWrapper
} from '../../fixed-rate/common/interfaces/IFixedRateUserWrapper.sol';

interface ISynthereumOnChainLiquidityRouter {
  enum SwapType {ERC20_TO_ERC20, NATIVE_TO_ERC20, ERC20_TO_NATIVE}

  enum SenderType {STD, ATOMIC_SWAP}

  enum OperationType {SWAP, MINT, REDEEM, WRAP, UNWRAP, EXCHANGE}

  enum PermitType {
    PERMIT,
    PERMIT_ALLOWED,
    NECESSARY_PERMIT,
    NECESSARY_PERMIT_ALLOWED
  }

  struct ReturnValues {
    address sender;
    address recipient;
    address inputToken;
    address outputToken;
    uint256 inputAmount;
    uint256 outputAmount;
  }

  struct SwapParams {
    SwapType swapType;
    uint256 exactAmount;
    uint256 minOut;
    bytes extraData;
    uint256 expiration;
    address recipient;
  }

  struct ExchangeParams {
    uint256 exactAmount;
    uint256 minOut;
    uint256 expiration;
    address recipient;
  }

  struct FixedRateParams {
    uint256 amount;
    address recipient;
  }

  struct DexImplementationInfo {
    address implementation;
    bytes args;
  }

  struct Operation {
    OperationType operationType;
    bytes data;
  }

  struct Permit {
    PermitType permitType;
    bytes data;
  }

  function setDexImplementation(
    string calldata _identifier,
    address _implementation,
    bytes calldata _info
  ) external;

  function dexSwap(
    SenderType _senderType,
    string calldata _implementationId,
    SwapParams calldata _inputDexParams
  ) external payable returns (ReturnValues memory returnValues);

  function mintSynthTokens(
    SenderType _senderType,
    ISynthereumUserPool _pool,
    ISynthereumUserPool.MintParams calldata _inputPoolParams
  ) external returns (ReturnValues memory returnValues);

  function redeemSynthTokens(
    SenderType _senderType,
    ISynthereumUserPool _pool,
    ISynthereumUserPool.RedeemParams calldata _inputPoolParams
  ) external returns (ReturnValues memory returnValues);

  function exchangeSynthTokens(
    SenderType _senderType,
    ISynthereumAtomicSwapPool _sourcePool,
    ISynthereumAtomicSwapPool _destPool,
    ExchangeParams calldata _exchangeParams
  ) external returns (ReturnValues memory returnValues);

  function wrapFixedRateTokens(
    SenderType _senderType,
    ISynthereumFixedRateUserWrapper _wrapper,
    FixedRateParams calldata _inputFixedRateParams
  ) external returns (ReturnValues memory returnValues);

  function unwrapFixedRateTokens(
    SenderType _senderType,
    ISynthereumFixedRateUserWrapper _wrapper,
    FixedRateParams calldata _inputFixedRateParams
  ) external returns (ReturnValues memory returnValues);

  function permitAndMultiOperations(
    Permit memory _permit,
    Operation[] memory _operations
  ) external payable returns (ReturnValues memory returnValues);

  function multiOperations(Operation[] memory _operations)
    external
    payable
    returns (ReturnValues memory returnValues);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {
  ISynthereumUserPool
} from '../../../synthereum-pool/common/interfaces/IUserPool.sol';
import {
  ISynthereumAtomicSwapPool
} from '../../../synthereum-pool/common/interfaces/IAtomicSwapPool.sol';
import {
  ISynthereumOnChainLiquidityRouter
} from '../../interfaces/IOnChainLiquidityRouter.sol';

interface IPoolSwap {
  function mint(
    address _msgSender,
    ISynthereumUserPool _pool,
    ISynthereumUserPool.MintParams calldata _inputParams
  )
    external
    returns (
      ISynthereumOnChainLiquidityRouter.ReturnValues memory returnValues
    );

  function redeem(
    address _msgSender,
    ISynthereumUserPool _pool,
    ISynthereumUserPool.RedeemParams calldata _inputParams
  )
    external
    returns (
      ISynthereumOnChainLiquidityRouter.ReturnValues memory returnValues
    );

  function exchange(
    address _msgSender,
    ISynthereumAtomicSwapPool _sourcePool,
    ISynthereumAtomicSwapPool _destPool,
    ISynthereumOnChainLiquidityRouter.ExchangeParams calldata _exchangeParams
  )
    external
    returns (
      ISynthereumOnChainLiquidityRouter.ReturnValues memory returnValues
    );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {
  ISynthereumFixedRateUserWrapper
} from '../../../fixed-rate/v1/interfaces/IFixedRateWrapper.sol';
import {
  ISynthereumOnChainLiquidityRouter
} from '../../interfaces/IOnChainLiquidityRouter.sol';

interface IFixedRateSwap {
  function wrap(
    address _msgSender,
    ISynthereumFixedRateUserWrapper _wrapper,
    ISynthereumOnChainLiquidityRouter.FixedRateParams calldata _inputParams
  )
    external
    returns (
      ISynthereumOnChainLiquidityRouter.ReturnValues memory returnValues
    );

  function unwrap(
    address _msgSender,
    ISynthereumFixedRateUserWrapper _wrapper,
    ISynthereumOnChainLiquidityRouter.FixedRateParams calldata _inputParams
  )
    external
    returns (
      ISynthereumOnChainLiquidityRouter.ReturnValues memory returnValues
    );
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

/**
 * @title Stores common interface names used throughout Synthereum.
 */
library SynthereumInterfaces {
  bytes32 public constant Deployer = 'Deployer';
  bytes32 public constant PoolRegistry = 'PoolRegistry';
  bytes32 public constant FixedRateRegistry = 'FixedRateRegistry';
  bytes32 public constant SelfMintingRegistry = 'SelfMintingRegistry';
  bytes32 public constant FactoryVersioning = 'FactoryVersioning';
  bytes32 public constant Manager = 'Manager';
  bytes32 public constant CollateralWhitelist = 'CollateralWhitelist';
  bytes32 public constant IdentifierWhitelist = 'IdentifierWhitelist';
  bytes32 public constant TokenFactory = 'TokenFactory';
  bytes32 public constant BuybackFactory = 'BuybackFactory';
  bytes32 public constant CreditLineController = 'CreditLineController';
  bytes32 public constant PriceFeed = 'PriceFeed';
  bytes32 public constant LendingManager = 'LendingManager';
  bytes32 public constant LendingStorageManager = 'LendingStorageManager';
  bytes32 public constant CommissionReceiver = 'CommissionReceiver';
  bytes32 public constant LendingRewardsReceiver = 'LendingRewardsReceiver';
  bytes32 public constant JarvisToken = 'JarvisToken';
  bytes32 public constant veJarvisToken = 'veJarvisToken';
  bytes32 public constant JarvisBrrrrr = 'JarvisBrrrrr';
  bytes32 public constant MoneyMarketManager = 'MoneyMarketManager';
  bytes32 public constant AtomicSwap = 'AtomicSwap';
  bytes32 public constant PoolSwapModule = 'PoolSwapModule';
  bytes32 public constant FixedRateSwapModule = 'FixedRateSwapModule';
  bytes32 public constant TrustedForwarder = 'TrustedForwarder';
}

library FactoryVersioningInterfaces {
  bytes32 public constant PoolFactory = 'PoolFactory';
  bytes32 public constant SelfMintingFactory = 'SelfMintingFactory';
  bytes32 public constant FixedRateFactory = 'FixedRateFactory';
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';

/**
 * @title Interface that a pool MUST have in order to be included in the deployer
 */
interface ISynthereumDeployment {
  /**
   * @notice Get Synthereum finder of the pool/self-minting derivative
   * @return finder Returns finder contract
   */
  function synthereumFinder() external view returns (ISynthereumFinder finder);

  /**
   * @notice Get Synthereum version
   * @return contractVersion Returns the version of this pool/self-minting derivative
   */
  function version() external view returns (uint8 contractVersion);

  /**
   * @notice Get the collateral token of this pool/self-minting derivative
   * @return collateralCurrency The ERC20 collateral token
   */
  function collateralToken() external view returns (IERC20 collateralCurrency);

  /**
   * @notice Get the synthetic token associated to this pool/self-minting derivative
   * @return syntheticCurrency The ERC20 synthetic token
   */
  function syntheticToken() external view returns (IERC20 syntheticCurrency);

  /**
   * @notice Get the synthetic token symbol associated to this pool/self-minting derivative
   * @return symbol The ERC20 synthetic token symbol
   */
  function syntheticTokenSymbol() external view returns (string memory symbol);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {ISynthereumFinder} from '../../../core/interfaces/IFinder.sol';
import {SynthereumPoolMigration} from './PoolMigration.sol';

/**
 * @title Abstract contract inherit by pools for moving storage from one pool to another
 */
abstract contract SynthereumPoolMigrationFrom is SynthereumPoolMigration {
  /**
   * @notice Migrate storage from this pool resetting and cleaning data
   * @notice This can be called only by a pool factory
   * @return poolVersion Version of the pool
   * @return price Actual price of the pair
   * @return storageBytes Pool storage encoded in bytes
   */
  function migrateStorage()
    external
    virtual
    onlyPoolFactory(finder)
    nonReentrant
    returns (
      uint8 poolVersion,
      uint256 price,
      bytes memory storageBytes
    )
  {
    _modifyStorageFrom();
    (poolVersion, price, storageBytes) = _encodeStorage();
    _cleanStorage();
  }

  /**
   * @notice Transfer all bearing tokens to another address
   * @notice Only the lending manager can call the function
   * @param _recipient Address receving bearing amount
   * @return migrationAmount Total balance of the pool in bearing tokens before migration
   */
  function migrateTotalFunds(address _recipient)
    external
    virtual
    onlyLendingManager
    nonReentrant
    returns (uint256 migrationAmount)
  {
    migrationAmount = _migrateTotalFunds(_recipient);
  }

  /**
   * @notice Function to implement for modifying storage before the encoding
   */
  function _modifyStorageFrom() internal virtual;

  /**
   * @notice Function to implement for cleaning and resetting the storage to the initial state
   */
  function _cleanStorage() internal virtual;

  /**
   * @notice Transfer all bearing tokens to another address
   * @notice Only the lending manager can call the function
   * @param _recipient Address receving bearing amount
   * @return migrationAmount Total balance of the pool in bearing tokens before migration
   */
  function _migrateTotalFunds(address _recipient)
    internal
    virtual
    returns (uint256 migrationAmount);

  /**
   * @notice Function to implement for encoding storage in bytes
   * @return poolVersion Version of the pool
   * @return price Actual price of the pair
   * @return storageBytes Pool storage encoded in bytes
   */
  function _encodeStorage()
    internal
    view
    virtual
    returns (
      uint8 poolVersion,
      uint256 price,
      bytes memory storageBytes
    );
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {ISynthereumFinder} from '../../../core/interfaces/IFinder.sol';
import {SynthereumFinderLib} from '../../../core/libs/CoreLibs.sol';
import {SynthereumFactoryAccess} from '../../../common/libs/FactoryAccess.sol';
import {
  ReentrancyGuard
} from '../../../../@openzeppelin/contracts/security/ReentrancyGuard.sol';

/**
 * @title Abstract contract inherited by pools for moving storage from one pool to another
 */
contract SynthereumPoolMigration is ReentrancyGuard {
  using SynthereumFinderLib for ISynthereumFinder;
  ISynthereumFinder internal finder;

  modifier onlyPoolFactory(ISynthereumFinder _finder) virtual {
    SynthereumFactoryAccess._onlyPoolFactory(_finder);
    _;
  }

  modifier onlyLendingManager() {
    require(
      msg.sender == address(finder.getLendingManager()),
      'Sender must be the lending manager'
    );
    _;
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {
  ISynthereumFactoryVersioning
} from '../../core/interfaces/IFactoryVersioning.sol';
import {FactoryVersioningInterfaces} from '../../core/Constants.sol';
import {
  SynthereumFinderLib,
  SynthereumFactoryVersioningLib
} from '../../core/libs/CoreLibs.sol';

/** @title Library to use for controlling the access of a functions from the factories
 */
library SynthereumFactoryAccess {
  using SynthereumFinderLib for ISynthereumFinder;
  using SynthereumFactoryVersioningLib for ISynthereumFactoryVersioning;

  /**
   * @notice Revert if caller is not a Pool factory
   * @param _finder Synthereum finder
   */
  function _onlyPoolFactory(ISynthereumFinder _finder) internal view {
    ISynthereumFactoryVersioning factoryVersioning =
      _finder.getFactoryVersioning();

    uint8 numberOfPoolFactories =
      factoryVersioning.numberOfFactoryVersions(
        FactoryVersioningInterfaces.PoolFactory
      );
    require(
      _checkSenderIsFactory(
        factoryVersioning,
        numberOfPoolFactories,
        FactoryVersioningInterfaces.PoolFactory
      ),
      'Not allowed'
    );
  }

  /**
   * @notice Revert if caller is not a Buyback vault factory
   * @param _finder Synthereum finder
   */
  function _onlyBuybackFactory(ISynthereumFinder _finder) internal view {
    require(msg.sender == address(_finder.getBuybackFactory()), 'Not allowed');
  }

  /**
   * @notice Revert if caller is not a Pool factory or a Fixed rate factory
   * @param _finder Synthereum finder
   */
  function _onlyPoolFactoryOrFixedRateFactory(ISynthereumFinder _finder)
    internal
    view
  {
    ISynthereumFactoryVersioning factoryVersioning =
      _finder.getFactoryVersioning();
    uint8 numberOfPoolFactories = factoryVersioning.numberOfPoolVersions();
    uint8 numberOfFixedRateFactories =
      factoryVersioning.numberOfFixedRateVersions();
    bool isPoolFactory =
      _checkSenderIsFactory(
        factoryVersioning,
        numberOfPoolFactories,
        FactoryVersioningInterfaces.PoolFactory
      );
    if (isPoolFactory) {
      return;
    }
    bool isFixedRateFactory =
      _checkSenderIsFactory(
        factoryVersioning,
        numberOfFixedRateFactories,
        FactoryVersioningInterfaces.FixedRateFactory
      );
    if (isFixedRateFactory) {
      return;
    }
    revert('Sender must be a Pool or FixedRate factory');
  }

  /**
   * @notice Check if sender is a factory
   * @param _factoryVersioning SynthereumFactoryVersioning contract
   * @param _numberOfFactories Total number of versions of a factory type
   * @param _factoryKind Type of the factory
   * @return isFactory True if sender is a factory, otherwise false
   */
  function _checkSenderIsFactory(
    ISynthereumFactoryVersioning _factoryVersioning,
    uint8 _numberOfFactories,
    bytes32 _factoryKind
  ) private view returns (bool isFactory) {
    uint8 counterFactory;
    for (uint8 i = 0; counterFactory < _numberOfFactories; i++) {
      try _factoryVersioning.getFactoryVersion(_factoryKind, i) returns (
        address factory
      ) {
        if (msg.sender == factory) {
          isFactory = true;
          break;
        } else {
          counterFactory++;
          if (counterFactory == _numberOfFactories) {
            isFactory = false;
          }
        }
      } catch {}
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

interface IEmergencyShutdown {
  /**
   * @notice Shutdown the pool or self-minting-derivative in case of emergency
   * @notice Only Synthereum manager contract can call this function
   * @return timestamp Timestamp of emergency shutdown transaction
   * @return price Price of the pair at the moment of shutdown execution
   */
  function emergencyShutdown()
    external
    returns (uint256 timestamp, uint256 price);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/**
 * @title Pool interface for making lending manager interacting with the pool
 */
interface ISynthereumLendingSwitch {
  /**
  * @notice Set new lending protocol for this pool
  * @notice This can be called only by the maintainer
  * @param _lendingId Name of the new lending module
  * @param _bearingToken Token of the lending mosule to be used for intersts accrual
            (used only if the lending manager doesn't automatically find the one associated to the collateral fo this pool)
  */
  function switchLendingModule(
    string calldata _lendingId,
    address _bearingToken
  ) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {
  IJarvisBuybackVault
} from '../../../jarvis-token/interfaces/IBuybackVault.sol';
import {ISynthereumTypesPool} from './ITypesPool.sol';

/**
 * @title Pool interface for making intercation of the pool with buyback vaults
 */
interface ISynthereumBuybackPool is ISynthereumTypesPool {
  /**
   * @notice Migrate actual buyback vault associated to this pool with a new one
   * @notice Only the synthereum manager can call the function
   * @return newBuyBackVault new buyback vault after migration
   */
  function migrateBuybackVault()
    external
    returns (IJarvisBuybackVault newBuyBackVault);

  /**
   * @notice Returns the buyback vault contract associated to this pool
   * @return buyBackVault buyback vault contract
   */
  function buybackVault()
    external
    view
    returns (IJarvisBuybackVault buyBackVault);

  /**
   * @notice Returns the LP base parametrs info (address, collateral, tokens and overcollateralization) for every active LP
   * @return info Info of every active LP (see LPPositionExtended struct)
   */
  function baseLPsInfo()
    external
    view
    returns (LPPositionExtented[] memory info);

  /**
   * @notice Returns the LP base parametrs info (address, collateral, tokens and overcollateralization) without dynamic update (intrests + P&L) for every active LP
   * @return info Info of every active LP (see LPPositionExtended struct)
   */
  function baseStaticLPsInfo()
    external
    view
    returns (LPPositionExtented[] memory info);

  /**
   * @notice Returns the percentage of overcollateralization to which a liquidation can triggered
   * @return requirement Thresold percentage on a liquidation can be triggered
   */
  function collateralRequirement() external view returns (uint256 requirement);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {
  ISynthereumBuybackPool
} from '../../synthereum-pool/common/interfaces/IBuybackPool.sol';
import {
  ISynthereumTypesPool
} from '../../synthereum-pool/common/interfaces/ITypesPool.sol';
import {IJarvisBuybackVaultLendingManager} from './IBuybackLendingManager.sol';

interface IJarvisBuybackVault is IJarvisBuybackVaultLendingManager {
  struct LPData {
    uint256 lastLiquidityAmount;
    uint256 lastLeverage;
    uint256 lastTimestamp;
    uint256 lastClaimEpoch;
    uint256 cumulativeAverage;
  }

  struct Reward {
    uint256 rewardAmount;
    uint256 finalTotalAverage;
    mapping(address => uint256) lpAverage;
  }

  event AddLP(address lp, uint256 liquidity, uint256 leverage);
  event RemoveLP(address lp);
  event FirstEpoch(uint256 rewards, uint256 timestamp, uint256 totalLiquidity);
  event EpochEnd(uint256 epoch, uint256 timestamp, uint256 rewards);
  event ClaimRewards(address lp, uint256 amount);

  /**
   * @notice Constructor function as per EIP1167
   * @dev Callable only once
   * @param _finder the synthereum finder contract
   * @param _referencePool address of MultiLP pool the buyback vault is associated with
   * @param _maxEpochsClaim Initial max number of epochs for rewards to be claimable
   */
  function initialize(
    ISynthereumFinder _finder,
    address _referencePool,
    uint256 _maxEpochsClaim
  ) external;

  /**
   * @notice Add a new LP with associated data
   * @dev only the reference pool should be able to trigger it
   * @dev only after the beginning of the first epoch
   * @dev updates state of other LPs
   * @param updatedPosition the lps updated positions (see pool struct)
   * @param otherPositions the rest of the lps updated positions (see pool struct)
   */
  function addLP(
    ISynthereumTypesPool.LPPositionExtented memory updatedPosition,
    ISynthereumTypesPool.LPPositionExtented[] memory otherPositions
  ) external;

  /**
   * @notice Remove an existing LP and associated data
   * @dev only the reference pool should be able to trigger it
   * @dev updates state of other LPs
   * @param lp the lp address to remove
   * @param otherPositions the rest of the lps updated positions (see pool struct)
   */
  function removeLP(
    address lp,
    ISynthereumTypesPool.LPPositionExtented[] memory otherPositions
  ) external;

  /**
   * @notice Triggers calculation of liquidity time weighted average of all the registered LPs
   * @dev Boost from ve token and leverage are taken into account
   * @return updatedAverages the up-to-date cumulative averages of the LPs
   */
  function updateLPs() external returns (uint256[] memory updatedAverages);

  /**
   * @notice Triggers calculation of liquidity time weighted average of all the registered LPs
   * @dev Boost from ve token and leverage are taken into account
   * @dev Only reference pool can invoke this method by passing the updated positions
   * @param updatedPositions the lps updated positions (see pool struct)
   * @return updatedAverages the up-to-date cumulative averages of the LPs
   */
  function poolUpdateLPs(
    ISynthereumTypesPool.LPPositionExtented[] memory updatedPositions
  ) external returns (uint256[] memory updatedAverages);

  /**
   * @notice Harvest all available rewards of an LP
   * @dev loops up to MAX_EPOCHS of accumulated rewards not yet claimed
   * @param lp The LP claiming the rewards
   * @return amountClaimed Total amount of tokens transferred to LP
   */
  function claimRewards(address lp) external returns (uint256 amountClaimed);

  /**
   * @notice View function to simulate amplified liquidity from ve boost
   * @dev do not update any state
   * @param _lp The LP to check boost
   * @param liquidity The LP liquidity
   * @return amplifiedLiquidity Curve-style boosted liquidity
   */
  function boost(address _lp, uint256 liquidity)
    external
    view
    returns (uint256 amplifiedLiquidity);

  /**
   * @notice Allows the pool factory to set a new reference pool for the buyback
   * @dev only pool factory is supposed to do this
   */
  function setReferencePool(address pool) external;

  /**
   * @notice Return the current epoch starting timestamp
   * @return timestamp Vault starting timestamp
   */
  function getEpochStartingTime() external view returns (uint256 timestamp);

  /**
   * @notice Return the current total liquidity participating in the program
   * @return liquidity Total liquidity
   */
  function getTotalLiquidity() external view returns (uint256 liquidity);

  /**
   * @notice Return the multi lp pool the buyback interacts with
   * @return pool Address of the synthereum pool
   */
  function referencePool() external view returns (ISynthereumBuybackPool pool);

  /**
   * @notice Return an epoch rewards amount
   * @return reward Total rewards of an epoch
   * @return totalAvg Total lp average of the epoch
   */
  function getEpochRewards(uint256 epoch)
    external
    view
    returns (uint256 reward, uint256 totalAvg);

  /**
   * @notice Return the lp rewards of a specific epoch
   * @param lp The LP to check rewards
   * @param epoch The epoch to check rewards
   * @return amount LP rewards of the epoch
   */
  function getLpEpochReward(address lp, uint256 epoch)
    external
    view
    returns (uint256 amount);

  /**
   * @notice Return the list of participating LPs
   * @return lps Listo of LP addresses
   */
  function getLPs() external view returns (address[] memory lps);

  /**
   * @notice Retrieve the storage data associated to an LP
   * @return data LPData struct
   */
  function getLPData(address lp) external view returns (LPData memory data);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/**
 * @title Pool interface containing pool structs
 */

interface ISynthereumTypesPool {
  struct LPPosition {
    // Actual collateral owned
    uint256 actualCollateralAmount;
    // Number of tokens collateralized
    uint256 tokensCollateralized;
    // Overcollateralization percentage
    uint128 overCollateralization;
  }

  struct LPPositionExtented {
    // Address of the LP
    address lp;
    // Position of the LP
    LPPosition lpPosition;
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

// interface to interact with a buyback vault from a lending manager
interface IJarvisBuybackVaultLendingManager {
  /**
   * @notice Triggers the first epoch and the beginning of the program
   * @dev It retrieves from the reference pool all lp positions currently active
   * @param _rewardsAmount An extra bonus rewards added for the first epoc
   */
  function triggerFirstEpoch(uint256 _rewardsAmount) external;

  /**
   * @notice Signal the end of an epoch - triggered with the buyback tx
   * @dev updates all LPs averages and store final epoch reward shares
   * @param rewardsAmount The amount of tokens to be distributed to lps
   */
  function triggerEpochEnd(uint256 rewardsAmount) external;

  /**
   * @notice Return the current epoch number of the program
   * @return epoch Vault current epoch
   */
  function getCurrentEpoch() external view returns (uint256 epoch);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from '../../@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {IMintableBurnableERC20} from './interfaces/IMintableBurnableERC20.sol';

/**
 * @title ERC20 interface that includes burn mint and roles methods.
 */
abstract contract BaseControlledMintableBurnableERC20 is
  IMintableBurnableERC20,
  ERC20
{
  uint8 private _decimals;

  /**
   * @notice Constructs the ERC20 token contract
   * @param _tokenName Name of the token
   * @param _tokenSymbol Token symbol
   * @param _tokenDecimals Number of decimals for token
   */
  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint8 _tokenDecimals
  ) ERC20(_tokenName, _tokenSymbol) {
    _setupDecimals(_tokenDecimals);
  }

  /**
   * @notice Add Minter role to an account
   * @param account Address to which Minter role will be added
   */
  function addMinter(address account) external virtual;

  /**
   * @notice Add Burner role to an account
   * @param account Address to which Burner role will be added
   */
  function addBurner(address account) external virtual;

  /**
   * @notice Add Admin role to an account
   * @param account Address to which Admin role will be added
   */
  function addAdmin(address account) external virtual;

  /**
   * @notice Add Admin, Minter and Burner roles to an account
   * @param account Address to which Admin, Minter and Burner roles will be added
   */
  function addAdminAndMinterAndBurner(address account) external virtual;

  /**
   * @notice Add Admin, Minter and Burner roles to an account
   * @param account Address to which Admin, Minter and Burner roles will be added
   */
  /**
   * @notice Self renounce the address calling the function from minter role
   */
  function renounceMinter() external virtual;

  /**
   * @notice Self renounce the address calling the function from burner role
   */
  function renounceBurner() external virtual;

  /**
   * @notice Self renounce the address calling the function from admin role
   */
  function renounceAdmin() external virtual;

  /**
   * @notice Self renounce the address calling the function from admin, minter and burner role
   */
  function renounceAdminAndMinterAndBurner() external virtual;

  /**
   * @notice Returns the number of decimals used to get its user representation.
   */
  function decimals()
    public
    view
    virtual
    override(ERC20, IMintableBurnableERC20)
    returns (uint8)
  {
    return _decimals;
  }

  /**
   * @dev Sets {decimals} to a value other than the default one of 18.
   *
   * WARNING: This function should only be called from the constructor. Most
   * applications that interact with token contracts will not expect
   * {decimals} to ever change, and may work incorrectly if it does.
   */
  function _setupDecimals(uint8 decimals_) internal {
    _decimals = decimals_;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

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
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
 * @title ERC20 interface that includes burn mint and roles methods.
 */
interface IMintableBurnableERC20 is IERC20 {
  /**
   * @notice Burns a specific amount of the caller's tokens.
   * @dev This method should be permissioned to only allow designated parties to burn tokens.
   */
  function burn(uint256 value) external;

  /**
   * @notice Mints tokens and adds them to the balance of the `to` address.
   * @dev This method should be permissioned to only allow designated parties to mint tokens.
   */
  function mint(address to, uint256 value) external returns (bool);

  /**
   * @notice Returns the number of decimals used to get its user representation.
   */
  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {PreciseUnitMath} from '../base/utils/PreciseUnitMath.sol';
import {IJarvisBuybackVault} from './interfaces/IBuybackVault.sol';
import {BuybackVaultMigration} from './BuybackMigration.sol';
import {
  ISynthereumBuybackPool
} from '../synthereum-pool/common/interfaces/IBuybackPool.sol';
import {
  ISynthereumTypesPool
} from '../synthereum-pool/common/interfaces/ITypesPool.sol';
import {ISynthereumFinder} from '../core/interfaces/IFinder.sol';
import {SynthereumFactoryAccess} from '../common/libs/FactoryAccess.sol';
import {IERC20} from '../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {
  SafeERC20
} from '../../@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {SynthereumFinderLib} from '../core/libs/CoreLibs.sol';
import {
  Initializable
} from '../../@openzeppelin/contracts/proxy/utils/Initializable.sol';
import {
  ReentrancyGuard
} from '../../@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract JarvisBuybackVault is
  IJarvisBuybackVault,
  ReentrancyGuard,
  Initializable,
  BuybackVaultMigration
{
  using PreciseUnitMath for uint256;
  using SafeERC20 for IERC20;
  using SynthereumFinderLib for ISynthereumFinder;

  uint256 public constant TOKENLESS_PRODUCTION = 40;
  uint256 public MAX_LEVERAGE;

  uint256 public MAX_EPOCHS_CLAIM;
  uint256 public startingTimestamp;
  uint256 public currentEpoch;
  uint256 public totalLiquidity;

  IERC20 public veJarvisToken;
  IERC20 public jarvisToken;
  ISynthereumBuybackPool public referencePool;

  mapping(address => LPData) public lp_data;
  mapping(uint256 => Reward) public epoch_rewards;
  address[] public lps;

  modifier onlyPool() {
    require(msg.sender == address(referencePool), 'Only pool');
    _;
  }

  modifier onlyPoolFactory() {
    SynthereumFactoryAccess._onlyPoolFactory(finder);
    _;
  }

  modifier onlyLendingManager() {
    require(msg.sender == address(finder.getLendingManager()), 'Not allowed');
    _;
  }

  modifier ifStarted() {
    if (currentEpoch > 0) {
      _;
    } else {
      return;
    }
  }

  function initialize(
    ISynthereumFinder _finder,
    address _referencePool,
    uint256 _maxEpochsClaim
  ) external override nonReentrant initializer {
    finder = _finder;
    veJarvisToken = _finder.getVeJarvisToken();
    jarvisToken = _finder.getJarvisToken();
    referencePool = ISynthereumBuybackPool(_referencePool);
    lps = new address[](0);
    MAX_LEVERAGE = PreciseUnitMath.PRECISE_UNIT.div(
      referencePool.collateralRequirement()
    );
    MAX_EPOCHS_CLAIM = _maxEpochsClaim;
  }

  // from pool activateLP
  function addLP(
    ISynthereumTypesPool.LPPositionExtented memory updatedPosition,
    ISynthereumTypesPool.LPPositionExtented[] memory otherPositions
  ) external override ifStarted onlyPool {
    address lp = updatedPosition.lp;

    require(currentEpoch > 0, 'Not initiated yet');
    require(lp_data[lp].lastTimestamp == 0, 'Already present');

    lps.push(lp);

    // store lp position from pool
    ISynthereumTypesPool.LPPosition memory lpInfo = updatedPosition.lpPosition;

    uint256 liquidity = lpInfo.actualCollateralAmount;
    uint256 leverage =
      PreciseUnitMath.PRECISE_UNIT.div(lpInfo.overCollateralization);

    lp_data[lp] = LPData(liquidity, leverage, block.timestamp, 0, 0);
    totalLiquidity = totalLiquidity + liquidity;

    // trigger update of others
    for (uint256 i = 0; i < otherPositions.length; i++) {
      lp = otherPositions[i].lp;

      // get LP last data in storage
      LPData storage lpData = lp_data[lp];

      // update lp data and totalLiquidity
      _updateLP(lp, lpData, otherPositions[i].lpPosition);
    }

    emit AddLP(lp, liquidity, leverage);
  }

  // from pool removeLP
  function removeLP(
    address lp,
    ISynthereumTypesPool.LPPositionExtented[] memory otherPositions
  ) external override ifStarted onlyPool {
    require(lp_data[lp].lastTimestamp != 0, 'Not present');
    totalLiquidity = totalLiquidity - lp_data[lp].lastLiquidityAmount;

    delete lp_data[lp];
    uint256 index;
    for (uint256 i = 0; i < lps.length; i++) {
      if (lps[i] == lp) {
        index = i;
        break;
      }
    }
    lps[index] = lps[lps.length - 1];
    lps.pop();

    // trigger update of others
    for (uint256 i = 0; i < otherPositions.length; i++) {
      address otherLp = otherPositions[i].lp;

      // get LP last data in storage
      LPData storage lpInfo = lp_data[otherLp];

      // update lp data and totalLiquidity
      _updateLP(otherLp, lpInfo, otherPositions[i].lpPosition);
    }

    emit RemoveLP(lp);
  }

  function updateLPs()
    external
    override
    ifStarted
    returns (uint256[] memory updatedAverages)
  {
    // get LPs updated pool position data
    ISynthereumTypesPool.LPPositionExtented[] memory updatedPositions =
      referencePool.baseLPsInfo();

    uint256 length = updatedPositions.length;
    updatedAverages = new uint256[](length);

    for (uint256 i = 0; i < length; i++) {
      address lp = updatedPositions[i].lp;

      // get LP last data in storage
      LPData storage lpInfo = lp_data[lp];

      // update lp reward state
      updatedAverages[i] = _updateLP(
        lp,
        lpInfo,
        updatedPositions[i].lpPosition
      );
    }
  }

  function poolUpdateLPs(
    ISynthereumTypesPool.LPPositionExtented[] memory updatedPositions
  ) external ifStarted onlyPool returns (uint256[] memory updatedAverages) {
    uint256 length = updatedPositions.length;
    updatedAverages = new uint256[](length);

    for (uint256 i = 0; i < length; i++) {
      address lp = updatedPositions[i].lp;

      // get LP last data in storage
      LPData storage lpInfo = lp_data[lp];

      // update lp reward state
      updatedAverages[i] = _updateLP(
        lp,
        lpInfo,
        updatedPositions[i].lpPosition
      );
    }
  }

  // triggered manually by maintainer/lendingmanager
  function triggerFirstEpoch(uint256 _rewardsAmount)
    external
    override
    onlyLendingManager
  {
    require(currentEpoch == 0, 'Already started');
    currentEpoch = 1;

    // initialise lp storage
    // get LPs updated pool position data
    ISynthereumTypesPool.LPPositionExtented[] memory updatedPositions =
      referencePool.baseLPsInfo();

    for (uint256 i = 0; i < updatedPositions.length; i++) {
      address lp = updatedPositions[i].lp;
      lps.push(lp);

      // get LP last data in storage
      LPData storage lpInfo = lp_data[lp];

      // update lp data
      _updateLP(lp, lpInfo, updatedPositions[i].lpPosition);
    }

    epoch_rewards[currentEpoch].rewardAmount = _rewardsAmount;

    // trigger epoch
    startingTimestamp = block.timestamp;

    emit FirstEpoch(_rewardsAmount, startingTimestamp, totalLiquidity);
  }

  // trigger in the buyback tx
  function triggerEpochEnd(uint256 rewardsAmount)
    external
    override
    ifStarted
    onlyLendingManager
  {
    uint256 finalTotalAverage;
    Reward storage epochReward = epoch_rewards[currentEpoch];

    // get LPs updated pool position data
    ISynthereumTypesPool.LPPositionExtented[] memory updatedPositions =
      referencePool.baseStaticLPsInfo();

    for (uint256 i = 0; i < updatedPositions.length; i++) {
      address lp = updatedPositions[i].lp;

      // get LP last data in storage
      LPData storage lpInfo = lp_data[lp];

      // update lp data and totalLiquidity
      uint256 lpAverage = _updateLP(lp, lpInfo, updatedPositions[i].lpPosition);
      finalTotalAverage += lpAverage;
      epochReward.lpAverage[lp] = lpAverage;
    }

    // store epoch data needed for claiming
    epochReward.finalTotalAverage = finalTotalAverage;
    epochReward.rewardAmount += rewardsAmount;

    // advance to next epoch
    startingTimestamp = block.timestamp;

    emit EpochEnd(currentEpoch, startingTimestamp, epochReward.rewardAmount);

    currentEpoch += 1;
  }

  function claimRewards(address lp)
    external
    override
    returns (uint256 amountClaimed)
  {
    uint256 lastClaimEpoch = lp_data[lp].lastClaimEpoch;
    uint256 epochToLoop =
      PreciseUnitMath.min(currentEpoch - lastClaimEpoch, MAX_EPOCHS_CLAIM);

    for (uint256 i = 1; i <= epochToLoop; i++) {
      Reward storage epochReward = epoch_rewards[lastClaimEpoch + i];

      if (epochReward.finalTotalAverage > 0) {
        amountClaimed += epochReward.rewardAmount.mul(
          epochReward.lpAverage[lp].div(epochReward.finalTotalAverage)
        );
      }
    }

    lp_data[lp].lastClaimEpoch += epochToLoop - 1;
    jarvisToken.safeTransfer(lp, amountClaimed);

    emit ClaimRewards(lp, amountClaimed);
  }

  function setReferencePool(address pool) external override onlyPoolFactory {
    referencePool = ISynthereumBuybackPool(pool);
  }

  function boost(address _lp, uint256 liquidity)
    external
    view
    override
    returns (uint256 amplifiedLiquidity)
  {
    return _boost(_lp, liquidity);
  }

  function getCurrentEpoch() external view override returns (uint256 epoch) {
    epoch = currentEpoch;
  }

  function getEpochStartingTime()
    external
    view
    override
    returns (uint256 timestamp)
  {
    timestamp = startingTimestamp;
  }

  function getTotalLiquidity()
    external
    view
    override
    returns (uint256 liquidity)
  {
    liquidity = totalLiquidity;
  }

  function getEpochRewards(uint256 epoch)
    external
    view
    override
    returns (uint256 reward, uint256 totalAvg)
  {
    Reward storage epochReward = epoch_rewards[epoch];
    reward = epochReward.rewardAmount;
    totalAvg = epochReward.finalTotalAverage;
  }

  function getLpEpochReward(address lp, uint256 epoch)
    external
    view
    override
    returns (uint256 amount)
  {
    Reward storage epochReward = epoch_rewards[epoch];
    if (epochReward.finalTotalAverage > 0) {
      amount = epochReward.rewardAmount.mul(
        epochReward.lpAverage[lp].div(epochReward.finalTotalAverage)
      );
    }
  }

  function getLPs() external view override returns (address[] memory) {
    return lps;
  }

  function getLPData(address lp)
    external
    view
    override
    returns (LPData memory data)
  {
    data = lp_data[lp];
  }

  function _migrateStorageFrom(address _oldVault, bytes memory)
    internal
    override
  {
    IJarvisBuybackVault oldVault = IJarvisBuybackVault(_oldVault);

    // copy global variable
    currentEpoch = oldVault.getCurrentEpoch();
    totalLiquidity = oldVault.getTotalLiquidity();
    startingTimestamp = oldVault.getEpochStartingTime();

    // copy lps
    lps = oldVault.getLPs();

    // copy lp position data
    for (uint256 i = 0; i < lps.length; i++) {
      address lp = lps[i];
      lp_data[lp] = oldVault.getLPData(lp);
    }
  }

  function _updateLP(
    address lp,
    LPData storage lpInfo,
    ISynthereumTypesPool.LPPosition memory updatedPosition
  ) internal returns (uint256 updatedAverage) {
    if (currentEpoch > 0) {
      uint256 lastLiquidity = lpInfo.lastLiquidityAmount;
      uint256 lastLeverage = lpInfo.lastLeverage;
      uint256 lastTimestamp = lpInfo.lastTimestamp;

      uint256 currentTime = block.timestamp;
      uint256 epochTimespan = currentTime - startingTimestamp;
      uint256 liquidityTimespan = currentTime - lastTimestamp;

      // update cumulative average
      uint256 leveragedLiquidity =
        lastLiquidity.mul(lastLeverage).div(MAX_LEVERAGE);

      updatedAverage =
        (lpInfo.cumulativeAverage *
          (lastTimestamp - startingTimestamp) +
          _boost(lp, leveragedLiquidity) *
          liquidityTimespan) /
        epochTimespan;

      // update storage
      lpInfo.cumulativeAverage = updatedAverage;
      lpInfo.lastTimestamp = currentTime;

      uint256 newLpLiquidity = updatedPosition.actualCollateralAmount;
      if (newLpLiquidity != lastLiquidity) {
        lpInfo.lastLiquidityAmount = newLpLiquidity;
        totalLiquidity = totalLiquidity + newLpLiquidity - lastLiquidity;
      }

      uint256 newLeverage =
        PreciseUnitMath.PRECISE_UNIT.div(updatedPosition.overCollateralization);
      if (lastLeverage != newLeverage) {
        lpInfo.lastLeverage = newLeverage;
      }
    }
  }

  function _boost(address lp, uint256 liquidity)
    internal
    view
    returns (uint256 amplifiedLiquidity)
  {
    uint256 votingBalance = veJarvisToken.balanceOf(lp);
    uint256 votingTotal = veJarvisToken.totalSupply();
    uint256 lim = liquidity.mul(TOKENLESS_PRODUCTION).div(100);
    if (votingTotal > 0) {
      uint256 lpVotingShare = votingBalance.div(votingTotal);
      lim += totalLiquidity.mul(lpVotingShare).mul(
        (100 - TOKENLESS_PRODUCTION).div(100)
      );
    }
    amplifiedLiquidity = PreciseUnitMath.min(liquidity, lim);
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

/**
 * @title PreciseUnitMath
 * @author Synthereum Protocol
 *
 * Arithmetic for fixed-point numbers with 18 decimals of precision.
 *
 */
library PreciseUnitMath {
  // The number One in precise units.
  uint256 internal constant PRECISE_UNIT = 10**18;

  // Max unsigned integer value
  uint256 internal constant MAX_UINT_256 = type(uint256).max;

  /**
   * @dev Getter function since constants can't be read directly from libraries.
   */
  function preciseUnit() internal pure returns (uint256) {
    return PRECISE_UNIT;
  }

  /**
   * @dev Getter function since constants can't be read directly from libraries.
   */
  function maxUint256() internal pure returns (uint256) {
    return MAX_UINT_256;
  }

  /**
   * @dev Multiplies value a by value b (result is rounded down). It's assumed that the value b is the significand
   * of a number with 18 decimals precision.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    return (a * b) / PRECISE_UNIT;
  }

  /**
   * @dev Multiplies value a by value b (result is rounded up). It's assumed that the value b is the significand
   * of a number with 18 decimals precision.
   */
  function mulCeil(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }
    return (((a * b) - 1) / PRECISE_UNIT) + 1;
  }

  /**
   * @dev Divides value a by value b (result is rounded down).
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return (a * PRECISE_UNIT) / b;
  }

  /**
   * @dev Divides value a by value b (result is rounded up or away from 0).
   */
  function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, 'Cant divide by 0');

    return a > 0 ? (((a * PRECISE_UNIT) - 1) / b) + 1 : 0;
  }

  /**
   * @dev Performs the power on a specified value, reverts on overflow.
   */
  function safePower(uint256 a, uint256 pow) internal pure returns (uint256) {
    require(a > 0, 'Value must be positive');

    uint256 result = 1;
    for (uint256 i = 0; i < pow; i++) {
      uint256 previousResult = result;

      result = previousResult * a;
    }

    return result;
  }

  /**
   * @dev The minimum of `a` and `b`.
   */
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  /**
   * @dev The maximum of `a` and `b`.
   */
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a > b ? a : b;
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {ISynthereumFinder} from '../core/interfaces/IFinder.sol';
import {SynthereumFactoryAccess} from '../common/libs/FactoryAccess.sol';
import {
  ReentrancyGuard
} from '../../@openzeppelin/contracts/security/ReentrancyGuard.sol';

/**
 * @title Abstract contract inherited by buyback vaults for moving storage from one vault to another
 */
abstract contract BuybackVaultMigration is ReentrancyGuard {
  ISynthereumFinder internal finder;

  modifier onlyBuybackFactory(ISynthereumFinder _finder) virtual {
    SynthereumFactoryAccess._onlyBuybackFactory(_finder);
    _;
  }

  function migrateStorageFrom(address _oldVault, bytes memory extraStorage)
    external
    virtual
    onlyBuybackFactory(finder)
    nonReentrant
  {
    _migrateStorageFrom(_oldVault, extraStorage);
  }

  function _migrateStorageFrom(address _oldVault, bytes memory extraStorage)
    internal
    virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ISynthereumFinder} from '../../../core/interfaces/IFinder.sol';
import {IStandardERC20} from '../../../base/interfaces/IStandardERC20.sol';
import {
  IMintableBurnableERC20
} from '../../../tokens/interfaces/IMintableBurnableERC20.sol';
import {
  FixedPoint
} from '../../../../@uma/core/contracts/common/implementation/FixedPoint.sol';

interface ICreditLineStorage {
  // Describe fee structure
  struct Fee {
    // Fees charged when a user mints, redeem and exchanges tokens
    uint256 feePercentage;
    // Recipient receiving fees
    address[] feeRecipients;
    // Proportion for each recipient
    uint32[] feeProportions;
    // Used with individual proportions to scale values
    uint256 totalFeeProportions;
  }

  struct FeeStatus {
    // Track the fee gained to be withdrawn by an address
    mapping(address => FixedPoint.Unsigned) feeGained;
    // Total amount of fees to be withdrawn
    FixedPoint.Unsigned totalFeeAmount;
  }

  // Represents a single sponsor's position. All collateral is held by this contract.
  // This struct acts as bookkeeping for how much of that collateral is allocated to each sponsor.
  struct PositionData {
    FixedPoint.Unsigned tokensOutstanding;
    FixedPoint.Unsigned rawCollateral;
  }

  struct GlobalPositionData {
    // Keep track of the total collateral and tokens across all positions
    FixedPoint.Unsigned totalTokensOutstanding;
    // Similar to the rawCollateral in PositionData, this value should not be used directly.
    //_getFeeAdjustedCollateral(), _addCollateral() and _removeCollateral() must be used to access and adjust.
    FixedPoint.Unsigned rawTotalPositionCollateral;
  }

  struct PositionManagerData {
    // SynthereumFinder contract
    ISynthereumFinder synthereumFinder;
    // Collateral token
    IStandardERC20 collateralToken;
    // Synthetic token created by this contract.
    IMintableBurnableERC20 tokenCurrency;
    // Unique identifier for DVM price feed ticker.
    bytes32 priceIdentifier;
    // Minimum number of tokens in a sponsor's position.
    FixedPoint.Unsigned minSponsorTokens;
    // Expiry price pulled from Chainlink in the case of an emergency shutdown.
    FixedPoint.Unsigned emergencyShutdownPrice;
    // Timestamp used in case of emergency shutdown.
    uint256 emergencyShutdownTimestamp;
    // The excessTokenBeneficiary of any excess tokens added to the contract.
    address excessTokenBeneficiary;
    // Version of the self-minting derivative
    uint8 version;
  }

  /**
   * @notice Construct the PerpetualPositionManager.
   * @dev Deployer of this contract should consider carefully which parties have ability to mint and burn
   * the synthetic tokens referenced by `_tokenAddress`. This contract's security assumes that no external accounts
   * can mint new tokens, which could be used to steal all of this contract's locked collateral.
   * We recommend to only use synthetic token contracts whose sole Owner role (the role capable of adding & removing roles)
   * is assigned to this contract, whose sole Minter role is assigned to this contract, and whose
   * total supply is 0 prior to construction of this contract.
   * @param collateralAddress ERC20 token used as collateral for all positions.
   * @param tokenAddress ERC20 token used as synthetic token.
   * @param priceFeedIdentifier registered in the ChainLink Oracle for the synthetic.
   * @param minSponsorTokens minimum amount of collateral that must exist at any time in a position.
   * @param timerAddress Contract that stores the current time in a testing environment. Set to 0x0 for production.
   * @param excessTokenBeneficiary Beneficiary to send all excess token balances that accrue in the contract.
   * @param version Version of the self-minting derivative
   * @param synthereumFinder The SynthereumFinder contract
   */
  struct PositionManagerParams {
    IStandardERC20 collateralToken;
    IMintableBurnableERC20 syntheticToken;
    bytes32 priceFeedIdentifier;
    FixedPoint.Unsigned minSponsorTokens;
    address excessTokenBeneficiary;
    uint8 version;
    ISynthereumFinder synthereumFinder;
  }

  struct LiquidationData {
    address sponsor;
    address liquidator;
    uint256 liquidationTime;
    uint256 numTokensBurnt;
    uint256 liquidatedCollateral;
  }

  struct ExecuteLiquidationData {
    FixedPoint.Unsigned tokensToLiquidate;
    FixedPoint.Unsigned collateralValueLiquidatedTokens;
    FixedPoint.Unsigned collateralLiquidated;
    FixedPoint.Unsigned liquidatorReward;
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "../../../../../@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../../../../@openzeppelin/contracts/utils/math/SignedSafeMath.sol";

/**
 * @title Library for fixed point arithmetic on uints
 */
library FixedPoint {
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    // Supports 18 decimals. E.g., 1e18 represents "1", 5e17 represents "0.5".
    // For unsigned values:
    //   This can represent a value up to (2^256 - 1)/10^18 = ~10^59. 10^59 will be stored internally as uint256 10^77.
    uint256 private constant FP_SCALING_FACTOR = 10**18;

    // --------------------------------------- UNSIGNED -----------------------------------------------------------------------------
    struct Unsigned {
        uint256 rawValue;
    }

    /**
     * @notice Constructs an `Unsigned` from an unscaled uint, e.g., `b=5` gets stored internally as `5*(10**18)`.
     * @param a uint to convert into a FixedPoint.
     * @return the converted FixedPoint.
     */
    function fromUnscaledUint(uint256 a) internal pure returns (Unsigned memory) {
        return Unsigned(a.mul(FP_SCALING_FACTOR));
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if equal, or False.
     */
    function isEqual(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue == fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if equal, or False.
     */
    function isEqual(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue == b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue > fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue >= fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue < fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a < b`, or False.
     */
    function isLessThan(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue <= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue <= fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue <= b.rawValue;
    }

    /**
     * @notice The minimum of `a` and `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the minimum of `a` and `b`.
     */
    function min(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return a.rawValue < b.rawValue ? a : b;
    }

    /**
     * @notice The maximum of `a` and `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the maximum of `a` and `b`.
     */
    function max(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return a.rawValue > b.rawValue ? a : b;
    }

    /**
     * @notice Adds two `Unsigned`s, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the sum of `a` and `b`.
     */
    function add(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.add(b.rawValue));
    }

    /**
     * @notice Adds an `Unsigned` to an unscaled uint, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the sum of `a` and `b`.
     */
    function add(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return add(a, fromUnscaledUint(b));
    }

    /**
     * @notice Subtracts two `Unsigned`s, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the difference of `a` and `b`.
     */
    function sub(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.sub(b.rawValue));
    }

    /**
     * @notice Subtracts an unscaled uint256 from an `Unsigned`, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the difference of `a` and `b`.
     */
    function sub(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return sub(a, fromUnscaledUint(b));
    }

    /**
     * @notice Subtracts an `Unsigned` from an unscaled uint256, reverting on overflow.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return the difference of `a` and `b`.
     */
    function sub(uint256 a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return sub(fromUnscaledUint(a), b);
    }

    /**
     * @notice Multiplies two `Unsigned`s, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mul(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        // There are two caveats with this computation:
        // 1. Max output for the represented number is ~10^41, otherwise an intermediate value overflows. 10^41 is
        // stored internally as a uint256 ~10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 1.4 * 2e-18 = 2.8e-18, which
        // would round to 3, but this computation produces the result 2.
        // No need to use SafeMath because FP_SCALING_FACTOR != 0.
        return Unsigned(a.rawValue.mul(b.rawValue) / FP_SCALING_FACTOR);
    }

    /**
     * @notice Multiplies an `Unsigned` and an unscaled uint256, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the product of `a` and `b`.
     */
    function mul(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.mul(b));
    }

    /**
     * @notice Multiplies two `Unsigned`s and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mulCeil(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        uint256 mulRaw = a.rawValue.mul(b.rawValue);
        uint256 mulFloor = mulRaw / FP_SCALING_FACTOR;
        uint256 mod = mulRaw.mod(FP_SCALING_FACTOR);
        if (mod != 0) {
            return Unsigned(mulFloor.add(1));
        } else {
            return Unsigned(mulFloor);
        }
    }

    /**
     * @notice Multiplies an `Unsigned` and an unscaled uint256 and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mulCeil(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        // Since b is an int, there is no risk of truncation and we can just mul it normally
        return Unsigned(a.rawValue.mul(b));
    }

    /**
     * @notice Divides one `Unsigned` by an `Unsigned`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        // There are two caveats with this computation:
        // 1. Max value for the number dividend `a` represents is ~10^41, otherwise an intermediate value overflows.
        // 10^41 is stored internally as a uint256 10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 2 / 3 = 0.6 repeating, which
        // would round to 0.666666666666666667, but this computation produces the result 0.666666666666666666.
        return Unsigned(a.rawValue.mul(FP_SCALING_FACTOR).div(b.rawValue));
    }

    /**
     * @notice Divides one `Unsigned` by an unscaled uint256, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.div(b));
    }

    /**
     * @notice Divides one unscaled uint256 by an `Unsigned`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a uint256 numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(uint256 a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return div(fromUnscaledUint(a), b);
    }

    /**
     * @notice Divides one `Unsigned` by an `Unsigned` and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divCeil(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        uint256 aScaled = a.rawValue.mul(FP_SCALING_FACTOR);
        uint256 divFloor = aScaled.div(b.rawValue);
        uint256 mod = aScaled.mod(b.rawValue);
        if (mod != 0) {
            return Unsigned(divFloor.add(1));
        } else {
            return Unsigned(divFloor);
        }
    }

    /**
     * @notice Divides one `Unsigned` by an unscaled uint256 and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divCeil(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        // Because it is possible that a quotient gets truncated, we can't just call "Unsigned(a.rawValue.div(b))"
        // similarly to mulCeil with a uint256 as the second parameter. Therefore we need to convert b into an Unsigned.
        // This creates the possibility of overflow if b is very large.
        return divCeil(a, fromUnscaledUint(b));
    }

    /**
     * @notice Raises an `Unsigned` to the power of an unscaled uint256, reverting on overflow. E.g., `b=2` squares `a`.
     * @dev This will "floor" the result.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return output is `a` to the power of `b`.
     */
    function pow(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory output) {
        output = fromUnscaledUint(1);
        for (uint256 i = 0; i < b; i = i.add(1)) {
            output = mul(output, a);
        }
    }

    // ------------------------------------------------- SIGNED -------------------------------------------------------------
    // Supports 18 decimals. E.g., 1e18 represents "1", 5e17 represents "0.5".
    // For signed values:
    //   This can represent a value up (or down) to +-(2^255 - 1)/10^18 = ~10^58. 10^58 will be stored internally as int256 10^76.
    int256 private constant SFP_SCALING_FACTOR = 10**18;

    struct Signed {
        int256 rawValue;
    }

    function fromSigned(Signed memory a) internal pure returns (Unsigned memory) {
        require(a.rawValue >= 0, "Negative value provided");
        return Unsigned(uint256(a.rawValue));
    }

    function fromUnsigned(Unsigned memory a) internal pure returns (Signed memory) {
        require(a.rawValue <= uint256(type(int256).max), "Unsigned too large");
        return Signed(int256(a.rawValue));
    }

    /**
     * @notice Constructs a `Signed` from an unscaled int, e.g., `b=5` gets stored internally as `5*(10**18)`.
     * @param a int to convert into a FixedPoint.Signed.
     * @return the converted FixedPoint.Signed.
     */
    function fromUnscaledInt(int256 a) internal pure returns (Signed memory) {
        return Signed(a.mul(SFP_SCALING_FACTOR));
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a int256.
     * @return True if equal, or False.
     */
    function isEqual(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue == fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if equal, or False.
     */
    function isEqual(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue == b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue > fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue >= fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue < fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a < b`, or False.
     */
    function isLessThan(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue <= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue <= fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue <= b.rawValue;
    }

    /**
     * @notice The minimum of `a` and `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the minimum of `a` and `b`.
     */
    function min(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return a.rawValue < b.rawValue ? a : b;
    }

    /**
     * @notice The maximum of `a` and `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the maximum of `a` and `b`.
     */
    function max(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return a.rawValue > b.rawValue ? a : b;
    }

    /**
     * @notice Adds two `Signed`s, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the sum of `a` and `b`.
     */
    function add(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.add(b.rawValue));
    }

    /**
     * @notice Adds an `Signed` to an unscaled int, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the sum of `a` and `b`.
     */
    function add(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return add(a, fromUnscaledInt(b));
    }

    /**
     * @notice Subtracts two `Signed`s, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the difference of `a` and `b`.
     */
    function sub(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.sub(b.rawValue));
    }

    /**
     * @notice Subtracts an unscaled int256 from an `Signed`, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the difference of `a` and `b`.
     */
    function sub(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return sub(a, fromUnscaledInt(b));
    }

    /**
     * @notice Subtracts an `Signed` from an unscaled int256, reverting on overflow.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return the difference of `a` and `b`.
     */
    function sub(int256 a, Signed memory b) internal pure returns (Signed memory) {
        return sub(fromUnscaledInt(a), b);
    }

    /**
     * @notice Multiplies two `Signed`s, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mul(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        // There are two caveats with this computation:
        // 1. Max output for the represented number is ~10^41, otherwise an intermediate value overflows. 10^41 is
        // stored internally as an int256 ~10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 1.4 * 2e-18 = 2.8e-18, which
        // would round to 3, but this computation produces the result 2.
        // No need to use SafeMath because SFP_SCALING_FACTOR != 0.
        return Signed(a.rawValue.mul(b.rawValue) / SFP_SCALING_FACTOR);
    }

    /**
     * @notice Multiplies an `Signed` and an unscaled int256, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the product of `a` and `b`.
     */
    function mul(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.mul(b));
    }

    /**
     * @notice Multiplies two `Signed`s and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mulAwayFromZero(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        int256 mulRaw = a.rawValue.mul(b.rawValue);
        int256 mulTowardsZero = mulRaw / SFP_SCALING_FACTOR;
        // Manual mod because SignedSafeMath doesn't support it.
        int256 mod = mulRaw % SFP_SCALING_FACTOR;
        if (mod != 0) {
            bool isResultPositive = isLessThan(a, 0) == isLessThan(b, 0);
            int256 valueToAdd = isResultPositive ? int256(1) : int256(-1);
            return Signed(mulTowardsZero.add(valueToAdd));
        } else {
            return Signed(mulTowardsZero);
        }
    }

    /**
     * @notice Multiplies an `Signed` and an unscaled int256 and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mulAwayFromZero(Signed memory a, int256 b) internal pure returns (Signed memory) {
        // Since b is an int, there is no risk of truncation and we can just mul it normally
        return Signed(a.rawValue.mul(b));
    }

    /**
     * @notice Divides one `Signed` by an `Signed`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        // There are two caveats with this computation:
        // 1. Max value for the number dividend `a` represents is ~10^41, otherwise an intermediate value overflows.
        // 10^41 is stored internally as an int256 10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 2 / 3 = 0.6 repeating, which
        // would round to 0.666666666666666667, but this computation produces the result 0.666666666666666666.
        return Signed(a.rawValue.mul(SFP_SCALING_FACTOR).div(b.rawValue));
    }

    /**
     * @notice Divides one `Signed` by an unscaled int256, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b an int256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.div(b));
    }

    /**
     * @notice Divides one unscaled int256 by an `Signed`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a an int256 numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(int256 a, Signed memory b) internal pure returns (Signed memory) {
        return div(fromUnscaledInt(a), b);
    }

    /**
     * @notice Divides one `Signed` by an `Signed` and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divAwayFromZero(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        int256 aScaled = a.rawValue.mul(SFP_SCALING_FACTOR);
        int256 divTowardsZero = aScaled.div(b.rawValue);
        // Manual mod because SignedSafeMath doesn't support it.
        int256 mod = aScaled % b.rawValue;
        if (mod != 0) {
            bool isResultPositive = isLessThan(a, 0) == isLessThan(b, 0);
            int256 valueToAdd = isResultPositive ? int256(1) : int256(-1);
            return Signed(divTowardsZero.add(valueToAdd));
        } else {
            return Signed(divTowardsZero);
        }
    }

    /**
     * @notice Divides one `Signed` by an unscaled int256 and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b an int256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divAwayFromZero(Signed memory a, int256 b) internal pure returns (Signed memory) {
        // Because it is possible that a quotient gets truncated, we can't just call "Signed(a.rawValue.div(b))"
        // similarly to mulCeil with an int256 as the second parameter. Therefore we need to convert b into an Signed.
        // This creates the possibility of overflow if b is very large.
        return divAwayFromZero(a, fromUnscaledInt(b));
    }

    /**
     * @notice Raises an `Signed` to the power of an unscaled uint256, reverting on overflow. E.g., `b=2` squares `a`.
     * @dev This will "floor" the result.
     * @param a a FixedPoint.Signed.
     * @param b a uint256 (negative exponents are not allowed).
     * @return output is `a` to the power of `b`.
     */
    function pow(Signed memory a, uint256 b) internal pure returns (Signed memory output) {
        output = fromUnscaledInt(1);
        for (uint256 i = 0; i < b; i = i.add(1)) {
            output = mul(output, a);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;
import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IStandardERC20 is IERC20 {
  /**
   * @dev Returns the name of the token.
   */
  function name() external view returns (string memory);

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() external view returns (string memory);

  /**
   * @dev Returns the number of decimals used to get its user representation.
   * For example, if `decimals` equals `2`, a balance of `505` tokens should
   * be displayed to a user as `5,05` (`505 / 10 ** 2`).
   *
   * Tokens usually opt for a value of 18, imitating the relationship between
   * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
   * called.
   *
   * NOTE: This information is only used for _display_ purposes: it in
   * no way affects any of the arithmetic of the contract, including
   * {IERC20-balanceOf} and {IERC20-transfer}.
   */
  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SignedSafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SignedSafeMath {
    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ITypology} from '../../../common/interfaces/ITypology.sol';
import {
  ISynthereumDeployment
} from '../../../common/interfaces/IDeployment.sol';

/**
 * @title Pool interface for making user interaction with pools
 */
interface ISynthereumUserPool is ITypology, ISynthereumDeployment {
  struct MintParams {
    // Minimum amount of synthetic tokens that a user wants to mint using collateral (anti-slippage)
    uint256 minNumTokens;
    // Amount of collateral that a user wants to spend for minting
    uint256 collateralAmount;
    // Expiration time of the transaction
    uint256 expiration;
    // Address to which send synthetic tokens minted
    address recipient;
  }

  struct RedeemParams {
    // Amount of synthetic tokens that user wants to use for redeeming
    uint256 numTokens;
    // Minimium amount of collateral that user wants to redeem (anti-slippage)
    uint256 minCollateral;
    // Expiration time of the transaction
    uint256 expiration;
    // Address to which send collateral tokens redeemed
    address recipient;
  }

  /**
   * @notice Mint synthetic tokens using fixed amount of collateral
   * @notice This calculate the price using on chain price feed
   * @notice User must approve collateral transfer for the mint request to succeed
   * @param _mintParams Input parameters for minting (see MintParams struct)
   * @return syntheticTokensMinted Amount of synthetic tokens minted by a user
   * @return feePaid Amount of collateral paid by the user as fee
   */
  function mint(MintParams calldata _mintParams)
    external
    returns (uint256 syntheticTokensMinted, uint256 feePaid);

  /**
   * @notice Redeem amount of collateral using fixed number of synthetic token
   * @notice This calculate the price using on chain price feed
   * @notice User must approve synthetic token transfer for the redeem request to succeed
   * @param _redeemParams Input parameters for redeeming (see RedeemParams struct)
   * @return collateralRedeemed Amount of collateral redeem by user
   * @return feePaid Amount of collateral paid by user as fee
   */
  function redeem(RedeemParams calldata _redeemParams)
    external
    returns (uint256 collateralRedeemed, uint256 feePaid);

  /**
   * @notice Returns the synthetic tokens will be received and fees will be paid in exchange for an input collateral amount
   * @notice This function is only trading-informative, it doesn't check edge case conditions like lending manager dust and reverting due to dust splitting
   * @param _collateralAmount Input collateral amount to be exchanged
   * @return synthTokensReceived Synthetic tokens will be minted
   * @return feePaid Collateral fee will be paid
   */
  function getMintTradeInfo(uint256 _collateralAmount)
    external
    view
    returns (uint256 synthTokensReceived, uint256 feePaid);

  /**
   * @notice Returns the collateral amount will be received and fees will be paid in exchange for an input amount of synthetic tokens
   * @notice This function is only trading-informative, it doesn't check edge case conditions like lending manager dust
   * @param  _syntTokensAmount Amount of synthetic tokens to be exchanged
   * @return collateralAmountReceived Collateral amount will be received by the user
   * @return feePaid Collateral fee will be paid
   */
  function getRedeemTradeInfo(uint256 _syntTokensAmount)
    external
    view
    returns (uint256 collateralAmountReceived, uint256 feePaid);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ITypology} from '../../../common/interfaces/ITypology.sol';
import {
  ISynthereumDeployment
} from '../../../common/interfaces/IDeployment.sol';

/**
 * @title Pool interface for making atomic swap interaction with pools
 */
interface ISynthereumAtomicSwapPool is ITypology, ISynthereumDeployment {
  struct CrossMintParams {
    // Minimum amount of synthetic tokens that a user wants to mint using collateral (anti-slippage)
    uint256 minNumTokens;
    // Amount of collateral that a user wants to spend for minting
    uint256 collateralAmount;
    // Expiration time of the transaction
    uint256 expiration;
    // Address to which send synthetic tokens minted
    address recipient;
  }

  struct CrossRedeemParams {
    // Amount of synthetic tokens that user wants to use for redeeming
    uint256 numTokens;
    // Minimium amount of collateral that user wants to redeem (anti-slippage)
    uint256 minCollateral;
    // Expiration time of the transaction
    uint256 expiration;
  }

  /**
   * @notice Mint synthetic tokens using fixed amount of collateral
   * @notice This calculate the price using on chain price feed
   * @notice Only the atomic-swap can call the function
   * @param _crossMintParams Input parameters for minting (see MintParams struct)
   * @return syntheticTokensMinted Amount of synthetic tokens minted by the atomic swap on behalf of the user
   * @return feePaid Amount of collateral paid by the atomic swap as fee on behalf of the user
   */
  function crossMint(CrossMintParams calldata _crossMintParams)
    external
    returns (uint256 syntheticTokensMinted, uint256 feePaid);

  /**
   * @notice Redeem amount of collateral using fixed number of synthetic token
   * @notice This calculate the price using on chain price feed
   * @notice User must approve synthetic token transfer for the redeem request to succeed
   * @notice Only the atomic-swap can call the function
   * @param _crossRedeemParams Input parameters for redeeming (see RedeemParams struct)
   * @return collateralRedeemed Amount of collateral redeem by the atomic swap on behalf of the user
   * @return feePaid Amount of collateral paid by the atomic swap on behalf of the user
   */
  function crossRedeem(CrossRedeemParams calldata _crossRedeemParams)
    external
    returns (uint256 collateralRedeemed, uint256 feePaid);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ITypology} from '../../../common/interfaces/ITypology.sol';
import {
  ISynthereumDeployment
} from '../../../common/interfaces/IDeployment.sol';

interface ISynthereumFixedRateUserWrapper is ITypology, ISynthereumDeployment {
  /** @notice This function is used to mint new fixed rate synthetic tokens by depositing peg collateral tokens
   * @notice The conversion is based on a fixed rate
   * @param _collateral The amount of peg collateral tokens to be deposited
   * @param _recipient The address of the recipient to receive the newly minted fixed rate synthetic tokens
   * @return amountTokens The amount of newly minted fixed rate synthetic tokens
   */
  function wrap(uint256 _collateral, address _recipient)
    external
    returns (uint256 amountTokens);

  /** @notice This function is used to burn fixed rate synthetic tokens and receive the underlying peg collateral tokens
   * @notice The conversion is based on a fixed rate
   * @param _tokenAmount The amount of fixed rate synthetic tokens to be burned
   * @param _recipient The address of the recipient to receive the underlying peg collateral tokens
   * @return amountCollateral The amount of peg collateral tokens withdrawn
   */
  function unwrap(uint256 _tokenAmount, address _recipient)
    external
    returns (uint256 amountCollateral);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

interface ITypology {
  /**
   * @notice Return typology of the contract
   */
  function typology() external view returns (string memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {
  ISynthereumFixedRateUserWrapper
} from '../../common/interfaces/IFixedRateUserWrapper.sol';

interface ISynthereumFixedRateWrapper is ISynthereumFixedRateUserWrapper {
  /** @notice A function that allows a maintainer to pause the execution of some functions in the contract
   * @notice This function suspends minting of new fixed rate synthetic tokens
   * @notice Pausing does not affect redeeming the peg collateral by burning the fixed rate synthetic tokens
   * @notice Pausing the contract is necessary in situations to prevent an issue with the smart contract or if the rate
   * between the fixed rate synthetic token and the peg collateral token changes
   */
  function pauseContract() external;

  /** @notice A function that allows a maintainer to resume the execution of all functions in the contract
   * @notice After the resume contract function is called minting of new fixed rate synthetic assets is open again
   */
  function resumeContract() external;

  /** @notice Check the conversion rate between peg-collateral and fixed-rate synthetic token
   * @return Coversion rate
   */
  function conversionRate() external view returns (uint256);

  /** @notice Amount of peg collateral stored in the contract
   * @return Total peg collateral deposited
   */
  function totalPegCollateral() external view returns (uint256);

  /** @notice Amount of synthetic tokens minted from the contract
   * @return Total synthetic tokens minted so far
   */
  function totalSyntheticTokensMinted() external view returns (uint256);

  /** @notice Check if wrap can be performed or not
   * @return True if minting is paused, otherwise false
   */
  function isPaused() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {ISynthereumFinder} from './interfaces/IFinder.sol';
import {
  StandardAccessControlEnumerable
} from '../common/roles/StandardAccessControlEnumerable.sol';

/**
 * @title Provides addresses of contracts implementing certain interfaces.
 */
contract SynthereumFinder is
  ISynthereumFinder,
  StandardAccessControlEnumerable
{
  //----------------------------------------
  // Storage
  //----------------------------------------

  mapping(bytes32 => address) public interfacesImplemented;

  //----------------------------------------
  // Events
  //----------------------------------------

  event InterfaceImplementationChanged(
    bytes32 indexed interfaceName,
    address indexed newImplementationAddress
  );

  //----------------------------------------
  // Constructors
  //----------------------------------------

  constructor(Roles memory roles) {
    _setAdmin(roles.admin);
    _setMaintainer(roles.maintainer);
  }

  //----------------------------------------
  // External view
  //----------------------------------------

  /**
   * @notice Updates the address of the contract that implements `interfaceName`.
   * @param interfaceName bytes32 of the interface name that is either changed or registered.
   * @param implementationAddress address of the implementation contract.
   */
  function changeImplementationAddress(
    bytes32 interfaceName,
    address implementationAddress
  ) external override onlyMaintainer {
    interfacesImplemented[interfaceName] = implementationAddress;

    emit InterfaceImplementationChanged(interfaceName, implementationAddress);
  }

  /**
   * @notice Gets the address of the contract that implements the given `interfaceName`.
   * @param interfaceName queried interface.
   * @return implementationAddress Address of the defined interface.
   */
  function getImplementationAddress(bytes32 interfaceName)
    external
    view
    override
    returns (address)
  {
    address implementationAddress = interfacesImplemented[interfaceName];
    require(implementationAddress != address(0x0), 'Implementation not found');
    return implementationAddress;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {ISynthereumFinder} from '../core/interfaces/IFinder.sol';
import {
  ISynthereumOnChainLiquidityRouter
} from './interfaces/IOnChainLiquidityRouter.sol';
import {
  ISynthereumUserPool
} from '../synthereum-pool/common/interfaces/IUserPool.sol';
import {
  ISynthereumAtomicSwapPool
} from '../synthereum-pool/common/interfaces/IAtomicSwapPool.sol';
import {
  ISynthereumFixedRateUserWrapper
} from '../fixed-rate/common/interfaces/IFixedRateUserWrapper.sol';
import {IOCLRBase} from './implementations/dex/interfaces/IOCLRBase.sol';
import {IPoolSwap} from './implementations/interfaces/IPoolSwap.sol';
import {IFixedRateSwap} from './implementations/interfaces/IFixedRateSwap.sol';
import {SynthereumInterfaces} from '../core/Constants.sol';
import {Address} from '../../@openzeppelin/contracts/utils/Address.sol';
import {SynthereumFinderLib} from '../core/libs/CoreLibs.sol';
import {ERC2771Context} from '../common/ERC2771Context.sol';
import {Context} from '../../@openzeppelin/contracts/utils/Context.sol';
import {
  StandardAccessControlEnumerable
} from '../common/roles/StandardAccessControlEnumerable.sol';
import {
  ReentrancyGuard
} from '../../@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {SelfPermit} from '../base/utils/permit/SelfPermit.sol';

contract SynthereumOnChainLiquidityRouter is
  ISynthereumOnChainLiquidityRouter,
  ERC2771Context,
  StandardAccessControlEnumerable,
  ReentrancyGuard,
  SelfPermit
{
  using Address for address;
  using SynthereumFinderLib for ISynthereumFinder;

  ISynthereumFinder public immutable synthereumFinder;

  mapping(bytes32 => DexImplementationInfo) public idToDexImplementationInfo;

  event DexImplementationSet(string id, address implementation, bytes info);

  event Swapped(string indexed implementationId, ReturnValues returnValues);

  event PoolMinted(address indexed pool, ReturnValues returnValues);

  event PoolRedeemed(address indexed pool, ReturnValues returnValues);

  event PoolExchanged(
    address _sourcePool,
    address _destPool,
    ReturnValues returnValues
  );

  event FixedRateWrapped(address indexed wrapper, ReturnValues returnValues);

  event FixedRateUnwrapped(address indexed wrapper, ReturnValues returnValues);

  event MultiOperations(ReturnValues returnValues);

  constructor(ISynthereumFinder _synthereumFinder, Roles memory _roles) {
    synthereumFinder = _synthereumFinder;

    _setAdmin(_roles.admin);
    _setMaintainer(_roles.maintainer);
  }

  receive() external payable {}

  /// @notice Stores information abount an OCLR implementation under an id
  /// @param _identifier: string identifier of the OCLR implementation. Registering an existing id will result in an overwrite.
  /// @param _implementation: address of the OCLR implementation smart contract.
  /// @param _info: bytes encoded info useful when calling the OCLR implementation.
  function setDexImplementation(
    string calldata _identifier,
    address _implementation,
    bytes calldata _info
  ) external override onlyMaintainer nonReentrant {
    bytes32 identifierId = keccak256(abi.encode(_identifier));
    require(identifierId != 0x00, 'Wrong implementation identifier');

    idToDexImplementationInfo[identifierId] = DexImplementationInfo(
      _implementation,
      _info
    );

    emit DexImplementationSet(_identifier, _implementation, _info);
  }

  function dexSwap(
    SenderType _senderType,
    string calldata _implementationId,
    SwapParams calldata _inputDexParams
  )
    external
    payable
    override
    nonReentrant
    returns (ReturnValues memory returnValues)
  {
    returnValues = _dexSwap(_senderType, _implementationId, _inputDexParams);
  }

  function mintSynthTokens(
    SenderType _senderType,
    ISynthereumUserPool _pool,
    ISynthereumUserPool.MintParams calldata _inputPoolParams
  ) external override nonReentrant returns (ReturnValues memory returnValues) {
    returnValues = _mintSynthTokens(_senderType, _pool, _inputPoolParams);
  }

  function redeemSynthTokens(
    SenderType _senderType,
    ISynthereumUserPool _pool,
    ISynthereumUserPool.RedeemParams calldata _inputPoolParams
  ) external override nonReentrant returns (ReturnValues memory returnValues) {
    returnValues = _redeemSynthTokens(_senderType, _pool, _inputPoolParams);
  }

  function exchangeSynthTokens(
    SenderType _senderType,
    ISynthereumAtomicSwapPool _sourcePool,
    ISynthereumAtomicSwapPool _destPool,
    ExchangeParams calldata _exchangeParams
  ) external override nonReentrant returns (ReturnValues memory returnValues) {
    returnValues = _exchangeSynthTokens(
      _senderType,
      _sourcePool,
      _destPool,
      _exchangeParams
    );
  }

  function wrapFixedRateTokens(
    SenderType _senderType,
    ISynthereumFixedRateUserWrapper _wrapper,
    FixedRateParams calldata _inputFixedRateParams
  ) external override nonReentrant returns (ReturnValues memory returnValues) {
    returnValues = _wrapFixedRateTokens(
      _senderType,
      _wrapper,
      _inputFixedRateParams
    );
  }

  function unwrapFixedRateTokens(
    SenderType _senderType,
    ISynthereumFixedRateUserWrapper _wrapper,
    FixedRateParams calldata _inputFixedRateParams
  ) external override nonReentrant returns (ReturnValues memory returnValues) {
    returnValues = _unwrapFixedRateTokens(
      _senderType,
      _wrapper,
      _inputFixedRateParams
    );
  }

  function permitAndMultiOperations(
    Permit memory _permit,
    Operation[] memory _operations
  )
    external
    payable
    override
    nonReentrant
    returns (ReturnValues memory returnValues)
  {
    _executePermit(_permit);
    returnValues = _multiOperations(_operations);
  }

  function multiOperations(Operation[] memory _operations)
    external
    payable
    override
    nonReentrant
    returns (ReturnValues memory returnValues)
  {
    returnValues = _multiOperations(_operations);
  }

  /**
   * @notice Check if an address is the trusted forwarder
   * @param  _forwarder Address to check
   * @return True is the input address is the trusted forwarder, otherwise false
   */
  function isTrustedForwarder(address _forwarder)
    public
    view
    override
    returns (bool)
  {
    try
      synthereumFinder.getImplementationAddress(
        SynthereumInterfaces.TrustedForwarder
      )
    returns (address trustedForwarder) {
      if (_forwarder == trustedForwarder) {
        return true;
      } else {
        return false;
      }
    } catch {
      return false;
    }
  }

  function _dexSwap(
    SenderType _senderType,
    string memory _implementationId,
    SwapParams memory _inputDexParams
  ) internal returns (ReturnValues memory returnValues) {
    DexImplementationInfo storage dexImplementation =
      idToDexImplementationInfo[keccak256(abi.encode(_implementationId))];
    address implementation = dexImplementation.implementation;
    require(implementation != address(0), 'Implementation id not registered');

    bytes memory result =
      implementation.functionDelegateCall(
        abi.encodeWithSelector(
          IOCLRBase.swap.selector,
          _senderType == SenderType.STD ? _msgSender() : address(this),
          dexImplementation.args,
          _inputDexParams
        )
      );

    returnValues = abi.decode(result, (ReturnValues));

    emit Swapped(_implementationId, returnValues);
  }

  function _mintSynthTokens(
    SenderType _senderType,
    ISynthereumUserPool _pool,
    ISynthereumUserPool.MintParams memory _inputPoolParams
  ) internal returns (ReturnValues memory returnValues) {
    address implementation = address(synthereumFinder.getPoolSwapModule());

    bytes memory result =
      implementation.functionDelegateCall(
        abi.encodeWithSelector(
          IPoolSwap.mint.selector,
          _senderType == SenderType.STD ? _msgSender() : address(this),
          _pool,
          _inputPoolParams
        )
      );

    returnValues = abi.decode(result, (ReturnValues));

    emit PoolMinted(address(_pool), returnValues);
  }

  function _redeemSynthTokens(
    SenderType _senderType,
    ISynthereumUserPool _pool,
    ISynthereumUserPool.RedeemParams memory _inputPoolParams
  ) internal returns (ReturnValues memory returnValues) {
    address implementation = address(synthereumFinder.getPoolSwapModule());

    bytes memory result =
      implementation.functionDelegateCall(
        abi.encodeWithSelector(
          IPoolSwap.redeem.selector,
          _senderType == SenderType.STD ? _msgSender() : address(this),
          _pool,
          _inputPoolParams
        )
      );

    returnValues = abi.decode(result, (ReturnValues));

    emit PoolRedeemed(address(_pool), returnValues);
  }

  function _exchangeSynthTokens(
    SenderType _senderType,
    ISynthereumAtomicSwapPool _sourcePool,
    ISynthereumAtomicSwapPool _destPool,
    ExchangeParams memory _exchangeParams
  ) internal returns (ReturnValues memory returnValues) {
    address implementation = address(synthereumFinder.getPoolSwapModule());

    bytes memory result =
      implementation.functionDelegateCall(
        abi.encodeWithSelector(
          IPoolSwap.exchange.selector,
          _senderType == SenderType.STD ? _msgSender() : address(this),
          _sourcePool,
          _destPool,
          _exchangeParams
        )
      );

    returnValues = abi.decode(result, (ReturnValues));

    emit PoolExchanged(address(_sourcePool), address(_destPool), returnValues);
  }

  function _wrapFixedRateTokens(
    SenderType _senderType,
    ISynthereumFixedRateUserWrapper _wrapper,
    FixedRateParams memory _inputFixedRateParams
  ) internal returns (ReturnValues memory returnValues) {
    address implementation = address(synthereumFinder.getFixedRateSwapModule());

    bytes memory result =
      implementation.functionDelegateCall(
        abi.encodeWithSelector(
          IFixedRateSwap.wrap.selector,
          _senderType == SenderType.STD ? _msgSender() : address(this),
          _wrapper,
          _inputFixedRateParams
        )
      );

    returnValues = abi.decode(result, (ReturnValues));

    emit FixedRateWrapped(address(_wrapper), returnValues);
  }

  function _unwrapFixedRateTokens(
    SenderType _senderType,
    ISynthereumFixedRateUserWrapper _wrapper,
    FixedRateParams memory _inputFixedRateParams
  ) internal returns (ReturnValues memory returnValues) {
    address implementation = address(synthereumFinder.getFixedRateSwapModule());

    bytes memory result =
      implementation.functionDelegateCall(
        abi.encodeWithSelector(
          IFixedRateSwap.unwrap.selector,
          _senderType == SenderType.STD ? _msgSender() : address(this),
          _wrapper,
          _inputFixedRateParams
        )
      );

    returnValues = abi.decode(result, (ReturnValues));

    emit FixedRateUnwrapped(address(_wrapper), returnValues);
  }

  function _multiOperations(Operation[] memory _operations)
    internal
    returns (ReturnValues memory returnValues)
  {
    ReturnValues memory prevReturnValues;
    ReturnValues memory newReturnValues;

    for (uint256 i = 0; i < _operations.length; i++) {
      bool isFirstOperation = i == 0;
      ReturnValues memory result =
        !isFirstOperation
          ? _excuteOperation(_operations[i], prevReturnValues.outputAmount)
          : _executeFirstOperation(_operations[i]);
      if (isFirstOperation) {
        prevReturnValues = result;
        returnValues.sender = prevReturnValues.sender;
        returnValues.inputToken = prevReturnValues.inputToken;
        returnValues.inputAmount = prevReturnValues.inputAmount;
      } else {
        newReturnValues = result;
        require(
          prevReturnValues.recipient == newReturnValues.sender,
          'Sender does not match'
        );
        require(
          prevReturnValues.outputToken == newReturnValues.inputToken,
          'Token does not match'
        );
        require(
          prevReturnValues.outputAmount == newReturnValues.inputAmount,
          'Amount does not match'
        );
        prevReturnValues = newReturnValues;
      }

      returnValues.recipient = prevReturnValues.recipient;
      returnValues.outputToken = prevReturnValues.outputToken;
      returnValues.outputAmount = prevReturnValues.outputAmount;

      emit MultiOperations(returnValues);
    }
  }

  function _executePermit(Permit memory _permit) internal {
    if (
      _permit.permitType == PermitType.PERMIT ||
      _permit.permitType == PermitType.NECESSARY_PERMIT
    ) {
      (
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
      ) =
        abi.decode(
          _permit.data,
          (address, uint256, uint256, uint8, bytes32, bytes32)
        );
      _permit.permitType == PermitType.PERMIT
        ? selfPermit(token, value, deadline, v, r, s)
        : selfPermitIfNecessary(token, value, deadline, v, r, s);
    } else {
      (
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
      ) =
        abi.decode(
          _permit.data,
          (address, uint256, uint256, uint8, bytes32, bytes32)
        );
      _permit.permitType == PermitType.PERMIT_ALLOWED
        ? selfPermitAllowed(token, nonce, expiry, v, r, s)
        : selfPermitAllowedIfNecessary(token, nonce, expiry, v, r, s);
    }
  }

  function _executeFirstOperation(Operation memory _operation)
    internal
    returns (ReturnValues memory result)
  {
    if (_operation.operationType == OperationType.SWAP) {
      (
        SenderType senderType,
        string memory implementationId,
        SwapParams memory swapParams
      ) = abi.decode(_operation.data, (SenderType, string, SwapParams));
      result = _dexSwap(senderType, implementationId, swapParams);
    } else if (_operation.operationType == OperationType.MINT) {
      (
        SenderType senderType,
        ISynthereumUserPool pool,
        ISynthereumUserPool.MintParams memory mintParams
      ) =
        abi.decode(
          _operation.data,
          (SenderType, ISynthereumUserPool, ISynthereumUserPool.MintParams)
        );
      result = _mintSynthTokens(senderType, pool, mintParams);
    } else if (_operation.operationType == OperationType.REDEEM) {
      (
        SenderType senderType,
        ISynthereumUserPool pool,
        ISynthereumUserPool.RedeemParams memory redeemParams
      ) =
        abi.decode(
          _operation.data,
          (SenderType, ISynthereumUserPool, ISynthereumUserPool.RedeemParams)
        );
      result = _redeemSynthTokens(senderType, pool, redeemParams);
    } else if (_operation.operationType == OperationType.EXCHANGE) {
      (
        SenderType senderType,
        ISynthereumAtomicSwapPool sourcePool,
        ISynthereumAtomicSwapPool destPool,
        ExchangeParams memory exchangeParams
      ) =
        abi.decode(
          _operation.data,
          (
            SenderType,
            ISynthereumAtomicSwapPool,
            ISynthereumAtomicSwapPool,
            ExchangeParams
          )
        );
      result = _exchangeSynthTokens(
        senderType,
        sourcePool,
        destPool,
        exchangeParams
      );
    } else {
      (
        SenderType senderType,
        ISynthereumFixedRateUserWrapper wrapper,
        FixedRateParams memory fixedRateParams
      ) =
        abi.decode(
          _operation.data,
          (SenderType, ISynthereumFixedRateUserWrapper, FixedRateParams)
        );
      result = _operation.operationType == OperationType.WRAP
        ? _wrapFixedRateTokens(senderType, wrapper, fixedRateParams)
        : _unwrapFixedRateTokens(senderType, wrapper, fixedRateParams);
    }
  }

  function _excuteOperation(Operation memory _operation, uint256 _inputAmount)
    internal
    returns (ReturnValues memory result)
  {
    if (_operation.operationType == OperationType.SWAP) {
      (
        SenderType senderType,
        string memory implementationId,
        SwapParams memory swapParams
      ) = abi.decode(_operation.data, (SenderType, string, SwapParams));
      swapParams.exactAmount = _inputAmount;
      result = _dexSwap(senderType, implementationId, swapParams);
    } else if (_operation.operationType == OperationType.MINT) {
      (
        SenderType senderType,
        ISynthereumUserPool pool,
        ISynthereumUserPool.MintParams memory mintParams
      ) =
        abi.decode(
          _operation.data,
          (SenderType, ISynthereumUserPool, ISynthereumUserPool.MintParams)
        );
      mintParams.collateralAmount = _inputAmount;
      result = _mintSynthTokens(senderType, pool, mintParams);
    } else if (_operation.operationType == OperationType.REDEEM) {
      (
        SenderType senderType,
        ISynthereumUserPool pool,
        ISynthereumUserPool.RedeemParams memory redeemParams
      ) =
        abi.decode(
          _operation.data,
          (SenderType, ISynthereumUserPool, ISynthereumUserPool.RedeemParams)
        );
      redeemParams.numTokens = _inputAmount;
      result = _redeemSynthTokens(senderType, pool, redeemParams);
    } else if (_operation.operationType == OperationType.EXCHANGE) {
      (
        SenderType senderType,
        ISynthereumAtomicSwapPool sourcePool,
        ISynthereumAtomicSwapPool destPool,
        ExchangeParams memory exchangeParams
      ) =
        abi.decode(
          _operation.data,
          (
            SenderType,
            ISynthereumAtomicSwapPool,
            ISynthereumAtomicSwapPool,
            ExchangeParams
          )
        );
      exchangeParams.exactAmount = _inputAmount;
      result = _exchangeSynthTokens(
        senderType,
        sourcePool,
        destPool,
        exchangeParams
      );
    } else {
      (
        SenderType senderType,
        ISynthereumFixedRateUserWrapper wrapper,
        FixedRateParams memory fixedRateParams
      ) =
        abi.decode(
          _operation.data,
          (SenderType, ISynthereumFixedRateUserWrapper, FixedRateParams)
        );
      fixedRateParams.amount = _inputAmount;
      result = _operation.operationType == OperationType.WRAP
        ? _wrapFixedRateTokens(senderType, wrapper, fixedRateParams)
        : _unwrapFixedRateTokens(senderType, wrapper, fixedRateParams);
    }
  }

  function _msgSender()
    internal
    view
    override(ERC2771Context, Context)
    returns (address sender)
  {
    return ERC2771Context._msgSender();
  }

  function _msgData()
    internal
    view
    override(ERC2771Context, Context)
    returns (bytes calldata)
  {
    return ERC2771Context._msgData();
  }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity >=0.8.0;

import {
  ISynthereumOnChainLiquidityRouter
} from '../../../interfaces/IOnChainLiquidityRouter.sol';

/// @notice general interface that OCLR implementations must adhere to
/// @notice in order to be callable through the proxy pattern
interface IOCLRBase {
  function swap(
    address _msgSender,
    bytes calldata _info,
    ISynthereumOnChainLiquidityRouter.SwapParams calldata _inputParams
  )
    external
    payable
    returns (
      ISynthereumOnChainLiquidityRouter.ReturnValues memory returnValues
    );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {Context} from '../../@openzeppelin/contracts/utils/Context.sol';

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
  function isTrustedForwarder(address forwarder)
    public
    view
    virtual
    returns (bool);

  function _msgSender()
    internal
    view
    virtual
    override
    returns (address sender)
  {
    if (isTrustedForwarder(msg.sender)) {
      // The assembly code is more direct than the Solidity version using `abi.decode`.
      assembly {
        sender := shr(96, calldataload(sub(calldatasize(), 20)))
      }
    } else {
      return super._msgSender();
    }
  }

  function _msgData() internal view virtual override returns (bytes calldata) {
    if (isTrustedForwarder(msg.sender)) {
      return msg.data[0:msg.data.length - 20];
    } else {
      return super._msgData();
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import {IERC20} from '../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {
  IERC20Permit
} from '../../../../@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol';
import {ISelfPermit} from './interfaces/ISelfPermit.sol';
import {IERC20PermitAllowed} from './interfaces/IERC20PermitAllowed.sol';
import {ERC2771Context} from '../../../common/ERC2771Context.sol';

/// @title Self Permit
/// @notice Functionality to call permit on any EIP-2612-compliant token for use in the route
/// @dev These functions are expected to be embedded in multicalls to allow EOAs to approve a contract and call a function
/// that requires an approval in a single transaction.
abstract contract SelfPermit is ISelfPermit, ERC2771Context {
  /// @inheritdoc ISelfPermit
  function selfPermit(
    address token,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public payable override {
    IERC20Permit(token).permit(
      _msgSender(),
      address(this),
      value,
      deadline,
      v,
      r,
      s
    );
  }

  /// @inheritdoc ISelfPermit
  function selfPermitAllowed(
    address token,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public payable override {
    IERC20PermitAllowed(token).permit(
      _msgSender(),
      address(this),
      nonce,
      expiry,
      true,
      v,
      r,
      s
    );
  }

  /// @inheritdoc ISelfPermit
  function selfPermitIfNecessary(
    address token,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public payable override {
    if (IERC20(token).allowance(_msgSender(), address(this)) < value)
      selfPermit(token, value, deadline, v, r, s);
  }

  /// @inheritdoc ISelfPermit
  function selfPermitAllowedIfNecessary(
    address token,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public payable override {
    if (
      IERC20(token).allowance(_msgSender(), address(this)) < type(uint256).max
    ) selfPermitAllowed(token, nonce, expiry, v, r, s);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

/// @title Self Permit
/// @notice Functionality to call permit on any EIP-2612-compliant token for use in the route
interface ISelfPermit {
  /// @notice Permits this contract to spend a given token from `msg.sender`
  /// @dev The `owner` is always msg.sender and the `spender` is always address(this).
  /// @param token The address of the token spent
  /// @param value The amount that can be spent of token
  /// @param deadline A timestamp, the current blocktime must be less than or equal to this timestamp
  /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
  /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
  /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
  function selfPermit(
    address token,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external payable;

  /// @notice Permits this contract to spend the sender's tokens for permit signatures that have the `allowed` parameter
  /// @dev The `owner` is always msg.sender and the `spender` is always address(this)
  /// @param token The address of the token spent
  /// @param nonce The current nonce of the owner
  /// @param expiry The timestamp at which the permit is no longer valid
  /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
  /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
  /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
  function selfPermitAllowed(
    address token,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external payable;

  /// @notice Permits this contract to spend a given token from `msg.sender`
  /// @dev The `owner` is always msg.sender and the `spender` is always address(this).
  /// Can be used instead of #selfPermit to prevent calls from failing due to a frontrun of a call to #selfPermit
  /// @param token The address of the token spent
  /// @param value The amount that can be spent of token
  /// @param deadline A timestamp, the current blocktime must be less than or equal to this timestamp
  /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
  /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
  /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
  function selfPermitIfNecessary(
    address token,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external payable;

  /// @notice Permits this contract to spend the sender's tokens for permit signatures that have the `allowed` parameter
  /// @dev The `owner` is always msg.sender and the `spender` is always address(this)
  /// Can be used instead of #selfPermitAllowed to prevent calls from failing due to a frontrun of a call to #selfPermitAllowed.
  /// @param token The address of the token spent
  /// @param nonce The current nonce of the owner
  /// @param expiry The timestamp at which the permit is no longer valid
  /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
  /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
  /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
  function selfPermitAllowedIfNecessary(
    address token,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Interface for permit
/// @notice Interface used by DAI/CHAI for permit
interface IERC20PermitAllowed {
  /// @notice Approve the spender to spend some tokens via the holder signature
  /// @dev This is the permit interface used by DAI and CHAI
  /// @param holder The address of the token holder, the token owner
  /// @param spender The address of the token spender
  /// @param nonce The holder's nonce, increases at each call to permit
  /// @param expiry The timestamp at which the permit is no longer valid
  /// @param allowed Boolean that sets approval amount, true for type(uint256).max and false for 0
  /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
  /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
  /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
  function permit(
    address holder,
    address spender,
    uint256 nonce,
    uint256 expiry,
    bool allowed,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {ISynthereumDeployment} from '../../common/interfaces/IDeployment.sol';
import {
  ISynthereumUserPool
} from '../../synthereum-pool/common/interfaces/IUserPool.sol';
import {
  ISynthereumAtomicSwapPool
} from '../../synthereum-pool/common/interfaces/IAtomicSwapPool.sol';
import {
  ISynthereumRegistry
} from '../../core/registries/interfaces/IRegistry.sol';
import {
  ISynthereumOnChainLiquidityRouter
} from '../interfaces/IOnChainLiquidityRouter.sol';
import {IPoolSwap} from './interfaces/IPoolSwap.sol';
import {
  ILendingStorageManager
} from '../../lending-module/interfaces/ILendingStorageManager.sol';
import {
  SafeERC20
} from '../../../@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {SynthereumFinderLib} from '../../core/libs/CoreLibs.sol';

contract PoolSwap is IPoolSwap {
  using SafeERC20 for IERC20;
  using SynthereumFinderLib for ISynthereumFinder;

  ISynthereumFinder public immutable synthereumFinder;

  constructor(ISynthereumFinder _synthereumFinder) {
    synthereumFinder = _synthereumFinder;
  }

  function mint(
    address _msgSender,
    ISynthereumUserPool _pool,
    ISynthereumUserPool.MintParams calldata _inputParams
  )
    external
    override
    returns (ISynthereumOnChainLiquidityRouter.ReturnValues memory returnValues)
  {
    IERC20 collateralToken = _checkPoolRegistry(_pool);

    returnValues.sender = _msgSender;
    returnValues.recipient = _inputParams.recipient;
    returnValues.inputToken = address(collateralToken);
    returnValues.outputToken = address(_pool.syntheticToken());
    returnValues.inputAmount = _inputParams.collateralAmount;

    if (_msgSender != address(this)) {
      collateralToken.safeTransferFrom(
        _msgSender,
        address(this),
        _inputParams.collateralAmount
      );
    }

    collateralToken.safeIncreaseAllowance(
      address(_pool),
      _inputParams.collateralAmount
    );

    (returnValues.outputAmount, ) = _pool.mint(_inputParams);
  }

  function redeem(
    address _msgSender,
    ISynthereumUserPool _pool,
    ISynthereumUserPool.RedeemParams calldata _inputParams
  )
    external
    override
    returns (ISynthereumOnChainLiquidityRouter.ReturnValues memory returnValues)
  {
    returnValues.outputToken = address(_checkPoolRegistry(_pool));

    IERC20 synthToken = _pool.syntheticToken();

    returnValues.sender = _msgSender;
    returnValues.recipient = _inputParams.recipient;
    returnValues.inputToken = address(synthToken);
    returnValues.inputAmount = _inputParams.numTokens;

    if (_msgSender != address(this)) {
      synthToken.safeTransferFrom(
        _msgSender,
        address(this),
        _inputParams.numTokens
      );
    }

    synthToken.safeIncreaseAllowance(address(_pool), _inputParams.numTokens);

    (returnValues.outputAmount, ) = _pool.redeem(_inputParams);
  }

  function exchange(
    address _msgSender,
    ISynthereumAtomicSwapPool _sourcePool,
    ISynthereumAtomicSwapPool _destPool,
    ISynthereumOnChainLiquidityRouter.ExchangeParams calldata _exchangeParams
  )
    external
    override
    returns (ISynthereumOnChainLiquidityRouter.ReturnValues memory returnValues)
  {
    IERC20 sourceCollateralToken = _checkPoolRegistry(_sourcePool);
    IERC20 destCollateralToken = _checkPoolRegistry(_destPool);
    require(
      sourceCollateralToken == destCollateralToken,
      'Source and destination collaterals do not match'
    );

    ILendingStorageManager lendingStorageManager =
      synthereumFinder.getLendingStorageManager();
    require(
      _getInterestToken(lendingStorageManager, _sourcePool) ==
        _getInterestToken(lendingStorageManager, _destPool),
      'Source and destination interest tokens do not match'
    );

    IERC20 sourceSynthToken = _sourcePool.syntheticToken();
    IERC20 destSynthToken = _destPool.syntheticToken();

    returnValues.sender = _msgSender;
    returnValues.recipient = _exchangeParams.recipient;
    returnValues.inputToken = address(sourceSynthToken);
    returnValues.inputAmount = _exchangeParams.exactAmount;
    returnValues.outputToken = address(destSynthToken);

    if (_msgSender != address(this)) {
      sourceSynthToken.safeTransferFrom(
        _msgSender,
        address(this),
        _exchangeParams.exactAmount
      );
    }

    sourceSynthToken.safeIncreaseAllowance(
      address(_sourcePool),
      _exchangeParams.exactAmount
    );

    (returnValues.outputAmount, ) = _sourcePool.crossRedeem(
      ISynthereumAtomicSwapPool.CrossRedeemParams(
        _exchangeParams.exactAmount,
        0,
        _exchangeParams.expiration
      )
    );

    (returnValues.outputAmount, ) = _destPool.crossMint(
      ISynthereumAtomicSwapPool.CrossMintParams(
        _exchangeParams.minOut,
        returnValues.outputAmount,
        _exchangeParams.expiration,
        _exchangeParams.recipient
      )
    );
  }

  function _checkPoolRegistry(ISynthereumDeployment pool)
    internal
    view
    returns (IERC20 collateralToken)
  {
    collateralToken = pool.collateralToken();
    require(
      synthereumFinder.getPoolRegistry().isDeployed(
        pool.syntheticTokenSymbol(),
        collateralToken,
        pool.version(),
        address(pool)
      ),
      'Pool not registered'
    );
  }

  function _getInterestToken(
    ILendingStorageManager _lendingStorageManager,
    ISynthereumDeployment _pool
  ) internal view returns (address interestToken) {
    interestToken = _lendingStorageManager.getInterestBearingToken(
      address(_pool)
    );
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {
  ISynthereumFixedRateUserWrapper
} from '../../fixed-rate/common/interfaces/IFixedRateUserWrapper.sol';
import {
  ISynthereumRegistry
} from '../../core/registries/interfaces/IRegistry.sol';
import {
  ISynthereumOnChainLiquidityRouter
} from '../interfaces/IOnChainLiquidityRouter.sol';
import {IFixedRateSwap} from './interfaces/IFixedRateSwap.sol';
import {
  SafeERC20
} from '../../../@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {SynthereumFinderLib} from '../../core/libs/CoreLibs.sol';

contract FixedRateSwap is IFixedRateSwap {
  using SafeERC20 for IERC20;
  using SynthereumFinderLib for ISynthereumFinder;

  ISynthereumFinder public immutable synthereumFinder;

  constructor(ISynthereumFinder _synthereumFinder) {
    synthereumFinder = _synthereumFinder;
  }

  function wrap(
    address _msgSender,
    ISynthereumFixedRateUserWrapper _wrapper,
    ISynthereumOnChainLiquidityRouter.FixedRateParams calldata _inputParams
  )
    external
    override
    returns (ISynthereumOnChainLiquidityRouter.ReturnValues memory returnValues)
  {
    IERC20 pegToken = checkFixedRateRegistry(_wrapper);

    returnValues.sender = _msgSender;
    returnValues.recipient = _inputParams.recipient;
    returnValues.inputToken = address(pegToken);
    returnValues.outputToken = address(_wrapper.syntheticToken());
    returnValues.inputAmount = _inputParams.amount;

    if (_msgSender != address(this)) {
      pegToken.safeTransferFrom(_msgSender, address(this), _inputParams.amount);
    }

    pegToken.safeIncreaseAllowance(address(_wrapper), _inputParams.amount);

    returnValues.outputAmount = _wrapper.wrap(
      _inputParams.amount,
      _inputParams.recipient
    );
  }

  function unwrap(
    address _msgSender,
    ISynthereumFixedRateUserWrapper _wrapper,
    ISynthereumOnChainLiquidityRouter.FixedRateParams calldata _inputParams
  )
    external
    override
    returns (ISynthereumOnChainLiquidityRouter.ReturnValues memory returnValues)
  {
    returnValues.outputToken = address(checkFixedRateRegistry(_wrapper));

    IERC20 fixedRateToken = _wrapper.syntheticToken();

    returnValues.sender = _msgSender;
    returnValues.recipient = _inputParams.recipient;
    returnValues.inputToken = address(fixedRateToken);
    returnValues.inputAmount = _inputParams.amount;

    if (_msgSender != address(this)) {
      fixedRateToken.safeTransferFrom(
        _msgSender,
        address(this),
        _inputParams.amount
      );
    }

    fixedRateToken.safeIncreaseAllowance(
      address(_wrapper),
      _inputParams.amount
    );

    returnValues.outputAmount = _wrapper.unwrap(
      _inputParams.amount,
      _inputParams.recipient
    );
  }

  function checkFixedRateRegistry(
    ISynthereumFixedRateUserWrapper fixedRateWrapper
  ) internal view returns (IERC20 collateralToken) {
    collateralToken = fixedRateWrapper.collateralToken();
    require(
      synthereumFinder.getFixedRateRegistry().isDeployed(
        fixedRateWrapper.syntheticTokenSymbol(),
        collateralToken,
        fixedRateWrapper.version(),
        address(fixedRateWrapper)
      ),
      'Fixed rate wrapper not registered'
    );
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {
  ISwapRouter
} from '../../../../@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import {IUniswapV3Router} from './interfaces/IUniswapV3Router.sol';
import {IWETH9} from './interfaces/IWETH9.sol';
import {IERC20} from '../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {
  ISynthereumOnChainLiquidityRouter
} from '../../interfaces/IOnChainLiquidityRouter.sol';
import {IOCLRBase} from './interfaces/IOCLRBase.sol';
import {AtomicSwapConstants} from '../../lib/AtomicSwapConstants.sol';
import {
  SafeERC20
} from '../../../../@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

contract OCLRV2UniswapV3 is IOCLRBase {
  using SafeERC20 for IERC20;

  function swap(
    address _msgSender,
    bytes calldata _info,
    ISynthereumOnChainLiquidityRouter.SwapParams calldata _inputParams
  )
    external
    payable
    override
    returns (ISynthereumOnChainLiquidityRouter.ReturnValues memory returnValues)
  {
    IUniswapV3Router uniswapV3Router =
      IUniswapV3Router(decodeImplementationInfo(_info));

    (uint24[] memory fees, address[] memory tokenSwapPath) =
      decodeExtraParams(_inputParams.extraData);

    uint256 lastTokenIndex = tokenSwapPath.length - 1;

    returnValues.sender = _msgSender;
    returnValues.recipient = _inputParams.recipient;
    returnValues.inputAmount = _inputParams.exactAmount;

    if (
      _inputParams.swapType ==
      ISynthereumOnChainLiquidityRouter.SwapType.ERC20_TO_ERC20
    ) {
      returnValues.inputToken = address(tokenSwapPath[0]);

      returnValues.outputToken = address(tokenSwapPath[lastTokenIndex]);

      if (_msgSender != address(this)) {
        IERC20(tokenSwapPath[0]).safeTransferFrom(
          _msgSender,
          address(this),
          _inputParams.exactAmount
        );
      }
      IERC20(tokenSwapPath[0]).safeIncreaseAllowance(
        address(uniswapV3Router),
        _inputParams.exactAmount
      );

      returnValues.outputAmount = uniswapV3Router.exactInput(
        ISwapRouter.ExactInputParams(
          encodeSwapData(tokenSwapPath, fees),
          _inputParams.recipient,
          _inputParams.expiration,
          _inputParams.exactAmount,
          _inputParams.minOut
        )
      );
    } else if (
      _inputParams.swapType ==
      ISynthereumOnChainLiquidityRouter.SwapType.NATIVE_TO_ERC20
    ) {
      returnValues.inputToken = AtomicSwapConstants.NATIVE_ADDR;

      returnValues.outputToken = address(tokenSwapPath[lastTokenIndex]);

      returnValues.outputAmount = uniswapV3Router.exactInput{
        value: _inputParams.exactAmount
      }(
        ISwapRouter.ExactInputParams(
          encodeSwapData(tokenSwapPath, fees),
          _inputParams.recipient,
          _inputParams.expiration,
          _inputParams.exactAmount,
          _inputParams.minOut
        )
      );
    } else {
      returnValues.inputToken = address(tokenSwapPath[0]);

      returnValues.outputToken = AtomicSwapConstants.NATIVE_ADDR;

      if (_msgSender != address(this)) {
        IERC20(tokenSwapPath[0]).safeIncreaseAllowance(
          address(uniswapV3Router),
          _inputParams.exactAmount
        );
      }

      returnValues.outputAmount = uniswapV3Router.exactInput(
        ISwapRouter.ExactInputParams(
          encodeSwapData(tokenSwapPath, fees),
          address(uniswapV3Router),
          _inputParams.expiration,
          _inputParams.exactAmount,
          _inputParams.minOut
        )
      );

      uint256 preRecipientBalance = _inputParams.recipient.balance;
      uniswapV3Router.unwrapWETH9(
        returnValues.outputAmount,
        _inputParams.recipient
      );
      uint256 postRecipientBalance = _inputParams.recipient.balance;
      returnValues.outputAmount = postRecipientBalance - preRecipientBalance;
    }
  }

  function decodeImplementationInfo(bytes calldata info)
    internal
    pure
    returns (address router)
  {
    router = abi.decode(info, (address));
  }

  function decodeExtraParams(bytes memory params)
    internal
    pure
    returns (uint24[] memory, address[] memory)
  {
    return abi.decode(params, (uint24[], address[]));
  }

  function encodeSwapData(address[] memory addresses, uint24[] memory fees)
    internal
    pure
    returns (bytes memory data)
  {
    require(
      addresses.length == fees.length + 1,
      'Mismatch between tokens and fees'
    );

    for (uint256 i = 0; i < addresses.length - 1; i++) {
      data = abi.encodePacked(data, addresses[i], fees[i]);
    }
    data = abi.encodePacked(data, addresses[addresses.length - 1]);
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '../../../../@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity >=0.8.0;

import {
  ISwapRouter
} from '../../../../../@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import {
  IPeripheryPayments
} from '../../../../../@uniswap/v3-periphery/contracts/interfaces/IPeripheryPayments.sol';

interface IUniswapV3Router is ISwapRouter, IPeripheryPayments {
  function WETH9() external returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import '../../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @title Interface for WETH9
interface IWETH9 is IERC20 {
  /// @notice Deposit ether to get wrapped ether
  function deposit() external payable;

  /// @notice Withdraw wrapped ether to get ether
  function withdraw(uint256) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/**
 * @title Stores common constants used in AtomicSwap
 */
library AtomicSwapConstants {
  address public constant NATIVE_ADDR =
    0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of ETH
interface IPeripheryPayments {
    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;

    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundETH() external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {
  IUniswapV2Router02
} from '../../../../@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import {IERC20} from '../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {
  ISynthereumOnChainLiquidityRouter
} from '../../interfaces/IOnChainLiquidityRouter.sol';
import {IOCLRBase} from './interfaces/IOCLRBase.sol';
import {AtomicSwapConstants} from '../../lib/AtomicSwapConstants.sol';
import {
  SafeERC20
} from '../../../../@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

contract OCLRV2UniswapV2 is IOCLRBase {
  using SafeERC20 for IERC20;

  function swap(
    address _msgSender,
    bytes calldata _info,
    ISynthereumOnChainLiquidityRouter.SwapParams calldata _inputParams
  )
    external
    payable
    override
    returns (ISynthereumOnChainLiquidityRouter.ReturnValues memory returnValues)
  {
    IUniswapV2Router02 uniswapV2Router =
      IUniswapV2Router02(decodeImplementationInfo(_info));

    address[] memory tokenSwapPath = decodeExtraParams(_inputParams.extraData);

    uint256 lastTokenIndex = tokenSwapPath.length - 1;

    returnValues.sender = _msgSender;
    returnValues.recipient = _inputParams.recipient;
    returnValues.inputAmount = _inputParams.exactAmount;

    if (
      _inputParams.swapType ==
      ISynthereumOnChainLiquidityRouter.SwapType.ERC20_TO_ERC20
    ) {
      returnValues.inputToken = address(tokenSwapPath[0]);

      returnValues.outputToken = address(tokenSwapPath[lastTokenIndex]);

      if (_msgSender != address(this)) {
        IERC20(tokenSwapPath[0]).safeTransferFrom(
          _msgSender,
          address(this),
          _inputParams.exactAmount
        );
      }

      IERC20(tokenSwapPath[0]).safeIncreaseAllowance(
        address(uniswapV2Router),
        _inputParams.exactAmount
      );

      returnValues.outputAmount = uniswapV2Router.swapExactTokensForTokens(
        _inputParams.exactAmount,
        _inputParams.minOut,
        tokenSwapPath,
        _inputParams.recipient,
        _inputParams.expiration
      )[lastTokenIndex];
    } else if (
      _inputParams.swapType ==
      ISynthereumOnChainLiquidityRouter.SwapType.NATIVE_TO_ERC20
    ) {
      returnValues.inputToken = AtomicSwapConstants.NATIVE_ADDR;

      returnValues.outputToken = address(tokenSwapPath[lastTokenIndex]);

      returnValues.outputAmount = uniswapV2Router.swapExactETHForTokens{
        value: _inputParams.exactAmount
      }(
        _inputParams.minOut,
        tokenSwapPath,
        _inputParams.recipient,
        _inputParams.expiration
      )[lastTokenIndex];
    } else {
      returnValues.inputToken = address(tokenSwapPath[0]);

      returnValues.outputToken = AtomicSwapConstants.NATIVE_ADDR;

      if (_msgSender != address(this)) {
        IERC20(tokenSwapPath[0]).safeTransferFrom(
          _msgSender,
          address(this),
          _inputParams.exactAmount
        );
      }

      IERC20(tokenSwapPath[0]).safeIncreaseAllowance(
        address(uniswapV2Router),
        _inputParams.exactAmount
      );

      returnValues.outputAmount = uniswapV2Router.swapExactTokensForETH(
        _inputParams.exactAmount,
        _inputParams.minOut,
        tokenSwapPath,
        _inputParams.recipient,
        _inputParams.expiration
      )[lastTokenIndex];
    }
  }

  function decodeImplementationInfo(bytes calldata info)
    internal
    pure
    returns (address router)
  {
    router = abi.decode(info, (address));
  }

  function decodeExtraParams(bytes memory params)
    internal
    pure
    returns (address[] memory)
  {
    return abi.decode(params, (address[]));
  }
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {IDMMExchangeRouter} from './interfaces/IKyberRouter.sol';
import {IERC20} from '../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {
  ISynthereumOnChainLiquidityRouter
} from '../../interfaces/IOnChainLiquidityRouter.sol';
import {IOCLRBase} from './interfaces/IOCLRBase.sol';
import {AtomicSwapConstants} from '../../lib/AtomicSwapConstants.sol';
import {
  SafeERC20
} from '../../../../@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

contract OCLRV2Kyber is IOCLRBase {
  using SafeERC20 for IERC20;

  function swap(
    address _msgSender,
    bytes calldata _info,
    ISynthereumOnChainLiquidityRouter.SwapParams calldata _inputParams
  )
    external
    payable
    override
    returns (ISynthereumOnChainLiquidityRouter.ReturnValues memory returnValues)
  {
    IDMMExchangeRouter kyberRouter =
      IDMMExchangeRouter(decodeImplementationInfo(_info));

    (address[] memory poolsPath, IERC20[] memory tokenSwapPath) =
      decodeExtraParams(_inputParams.extraData);

    uint256 lastTokenIndex = tokenSwapPath.length - 1;

    require(
      poolsPath.length == lastTokenIndex,
      'Pools and tokens length mismatch'
    );

    returnValues.sender = _msgSender;
    returnValues.recipient = _inputParams.recipient;
    returnValues.inputAmount = _inputParams.exactAmount;

    if (
      _inputParams.swapType ==
      ISynthereumOnChainLiquidityRouter.SwapType.ERC20_TO_ERC20
    ) {
      returnValues.inputToken = address(tokenSwapPath[0]);

      returnValues.outputToken = address(tokenSwapPath[lastTokenIndex]);

      if (_msgSender != address(this)) {
        IERC20(tokenSwapPath[0]).safeTransferFrom(
          _msgSender,
          address(this),
          _inputParams.exactAmount
        );
      }

      tokenSwapPath[0].safeIncreaseAllowance(
        address(kyberRouter),
        _inputParams.exactAmount
      );

      returnValues.outputAmount = kyberRouter.swapExactTokensForTokens(
        _inputParams.exactAmount,
        _inputParams.minOut,
        poolsPath,
        tokenSwapPath,
        _inputParams.recipient,
        _inputParams.expiration
      )[lastTokenIndex];
    } else if (
      _inputParams.swapType ==
      ISynthereumOnChainLiquidityRouter.SwapType.NATIVE_TO_ERC20
    ) {
      returnValues.inputToken = AtomicSwapConstants.NATIVE_ADDR;

      returnValues.outputToken = address(tokenSwapPath[lastTokenIndex]);

      returnValues.outputAmount = kyberRouter.swapExactETHForTokens{
        value: _inputParams.exactAmount
      }(
        _inputParams.minOut,
        poolsPath,
        tokenSwapPath,
        _inputParams.recipient,
        _inputParams.expiration
      )[lastTokenIndex];
    } else {
      returnValues.inputToken = address(tokenSwapPath[0]);

      returnValues.outputToken = AtomicSwapConstants.NATIVE_ADDR;

      if (_msgSender != address(this)) {
        IERC20(tokenSwapPath[0]).safeTransferFrom(
          _msgSender,
          address(this),
          _inputParams.exactAmount
        );
      }

      tokenSwapPath[0].safeIncreaseAllowance(
        address(kyberRouter),
        _inputParams.exactAmount
      );

      returnValues.outputAmount = kyberRouter.swapExactTokensForETH(
        _inputParams.exactAmount,
        _inputParams.minOut,
        poolsPath,
        tokenSwapPath,
        _inputParams.recipient,
        _inputParams.expiration
      )[lastTokenIndex];
    }
  }

  function decodeImplementationInfo(bytes calldata info)
    internal
    pure
    returns (address router)
  {
    router = abi.decode(info, (address));
  }

  // generic function that each OCLR implementation can implement
  // in order to receive extra params
  function decodeExtraParams(bytes memory params)
    internal
    pure
    returns (address[] memory, IERC20[] memory)
  {
    return abi.decode(params, (address[], IERC20[]));
  }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity >=0.8.0;

import {IERC20} from '../../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IDMMExchangeRouter {
  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata poolsPath,
    IERC20[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata poolsPath,
    IERC20[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] calldata poolsPath,
    IERC20[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata poolsPath,
    IERC20[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata poolsPath,
    IERC20[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapETHForExactTokens(
    uint256 amountOut,
    address[] calldata poolsPath,
    IERC20[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function getAmountsOut(
    uint256 amountIn,
    address[] calldata poolsPath,
    IERC20[] calldata path
  ) external view returns (uint256[] memory amounts);

  function getAmountsIn(
    uint256 amountOut,
    address[] calldata poolsPath,
    IERC20[] calldata path
  ) external view returns (uint256[] memory amounts);
}