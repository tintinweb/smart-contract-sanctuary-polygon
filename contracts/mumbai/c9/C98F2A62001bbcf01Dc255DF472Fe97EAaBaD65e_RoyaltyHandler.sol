// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

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
        _checkRole(role);
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
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
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
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

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
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

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
pragma solidity ^0.8.18;

library LibPart {
    bytes32 public constant TYPE_HASH = keccak256("Part(address account,uint96 value)");

    struct Part {
        address payable account;
        uint96 value;
    }
    function hash(Part memory part) internal pure returns (bytes32){
        return keccak256(abi.encode(TYPE_HASH, part.account,  part.value));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
pragma abicoder v2;

import "./LibPart.sol";

interface RoyaltiesV2 {
    event RoyaltiesSet(uint256 tokenId, LibPart.Part[] royalties);

    function getRaribleV2Royalties(uint256 id) external view returns (LibPart.Part[] memory);
}

//         ╩╝                                  ▓╝
//         ╥╕   ,╓[email protected]@╥,     ╓[email protected]@╥, ╓╥       ╥  ╥² =╥      ╥∞
//         ╟▌  ▓╝²    ╙▓⌐  ▓╩    ▓@ ▐▓    ,▓╝  ▓P   ▐@  g▓`
//         ╟▌ ╞▓       ▐▓ j▓         ▐▓  ,▓╜   ▓P    ]▓▓Ç
//         ╟▌  ▓W     ╓▓▓ j▓          ▐▓,▓`    ▓P  ,@╝  ╚▓,
//         ╟▌   ╙╙╩Ñ╩╝`╘╨ "╨           ╙╨`     ╨ⁿ *╨      ╙*
//        ,▓M
//       ╙╙         ***** WEB3 CREATORS STUDIO *****
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "jarvix-solidity-utils/contracts/SecurityUtils.sol";
import "jarvix-solidity-utils/contracts/NumberUtils.sol";
// import "jarvix-solidity-utils/contracts/testlib.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
// Cannot use Rarible provided npm package as it is compiled using below 0.8.0 solidity version compliance
import "./@rarible/royalties/contracts/RoyaltiesV2.sol";
// Needed by Opensea Creator Earnings Enforcement
import "operator-filter-registry/src/UpdatableOperatorFilterer.sol";
import {CANONICAL_CORI_SUBSCRIPTION, CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS} from "operator-filter-registry/src/lib/Constants.sol";
import "jarvix-solidity-utils/contracts/ProxyUtils.sol";


/**
 * @title  UpdatableDefaultOperatorFilterer
 * @notice Inherits from UpdatableOperatorFilterer and automatically subscribes to the default OpenSea subscription.
 * Note that OpenSea will disable creator earnings enforcement if filtered operators begin fulfilling orders on-chain,
 * eg, if the registry is revoked or bypassed.
 */
abstract contract UpdatableDefaultOperatorFilterer is UpdatableOperatorFilterer
{
    /// @dev The constructor that is called when the contract is being deployed.
    constructor() UpdatableOperatorFilterer(CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS, CANONICAL_CORI_SUBSCRIPTION, true)
    {}
}

interface IRoyalty
{
    function getRoyalty() external view returns(DecimalsType.Number_uint32 memory rate);
    function royaltyInfo(address receiver_, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount);
    function getRaribleV2Royalties(address receiver_) external view returns (LibPart.Part[] memory);
}

/**
 * @title This is the Jarvix royalty management contract.
 * @dev This is the contract to import/extends if you want to your NFT collection to apply royalties when an NTF is sold
 * on participating market places:
 * For Opensea, the behavior is to provided collection owner using `Ownable` and use the owner to connect onto their platform
 * and manage the collection when royalty can be defined
 * For Rarible/Mintable, implementing RoyaltiesV2/IERC2981 is requested in order to return applicable royalty rate/amount.
 * Royalty receiver will also be the owner of the contract in order to be consistent with opensea implementation
 * see: https://cryptomarketpool.com/erc721-contract-that-supports-sales-royalties/
 * @author tazous
 */
contract RoyaltyHandler is IRoyalty, AccessControlImpl
{
    /** Role definition necessary to be able to manage prices */
    bytes32 public constant PRICES_ADMIN_ROLE = keccak256("PRICES_ADMIN_ROLE");
    /** IRoyalty interface ID definition */
    bytes4 public constant IRoyaltyInterfaceId = type(IRoyalty).interfaceId;

    using DecimalsInt for uint256;
    using DecimalsInt for uint32;
    using DecimalsInt for DecimalsType.Number_uint256;
    using DecimalsInt for DecimalsType.Number_uint32;
    /** @dev Royalty rate applicable on participating market places in %, which mean that {"value":250, "decimals":2}
     * for instance should be understood as 2.5% */
    DecimalsType.Number_uint32 private _rate;

    /**
     * @dev Event emitted whenever royalty is changed
     * 'admin' Address of the administrator that changed royalty
     * 'rate' New applicable royalty rate in %, which mean that {"value":250, "decimals":2} for instance should be
     * understood as 2.5%
     */
    event RoyaltyChanged(address indexed admin, DecimalsType.Number_uint32 rate);

    /**
     * @dev Contract constructor
     * @param rate_ Royalty rate applicable on participating market places in %, which mean that {"value":250, "decimals":2}
     * for instance should be understood as 2.5%
     * @param decimals_ Royalty rate applicable decimals
     */
    constructor(uint32 rate_, uint8 decimals_)
    {
        _setRoyalty(rate_.to_uint32(decimals_));
    }

    /**
     * Getter of the royalty rate. Royalty rate is in %, which mean that if returned value is {"value":250, "decimals":2} for instance,
     * this should be understood as 2.5%
     */
    function getRoyalty() external view returns(DecimalsType.Number_uint32 memory rate)
    {
        return _rate;
    }
    /**
     * Setter of the royalty rate and applicable decimals in %, which mean that {"value":250, "decimals":2} for instance should
     * be understood as 2.5%
     */
    function setRoyalty(uint32 rate, uint8 decimals) external onlyRole(PRICES_ADMIN_ROLE)
    {
        _setRoyalty(rate.to_uint32(decimals));
    }
    /**
     * Setter of the royalty rate in %, which mean that {"value":250, "decimals":2} for instance should be understood as 2.5%
     */
    function _setRoyalty(DecimalsType.Number_uint32 memory rate) internal
    {
        if(rate.value == 0)
        {
            rate.decimals = 0;
        }
        _rate = rate;
        emit RoyaltyChanged(msg.sender, _rate);
    }
    /**
     * @dev Method derivated from the one in IERC2981 to get royalty amount and receiver for a token ID & a sale price.
     * This implementation will use defined royalty rate to apply it on given sale price whatever the token ID might be
     * (which is why it is not provided as parameter) and calculate royalty amount
     * @param receiver_ Expected receiver of the royalty
     * @param salePrice Sale price to be used to calculated royalty amount
     */
    function royaltyInfo(address receiver_, uint256 salePrice) public view returns (address receiver, uint256 royaltyAmount)
    {
        if(_rate.value == 0 || receiver_ == address(0))
        {
            return (address(0), 0);
        }
        return (receiver_, salePrice.to_uint256(0).mul(_rate.to_uint256()).div(DecimalsType.Number_uint256(100, 0), 0).value);
    }
    /**
     * @dev Method derivated from the one in RoyaltiesV2 to get applicable royalty percentage basis points and receiver
     * for a token ID. This implementation will use defined royalty rate whatever the token ID might be (which is why it
     * is not available as parameter)
     * @param receiver_ Expected receiver of the royalty
     */
    function getRaribleV2Royalties(address receiver_) public view returns (LibPart.Part[] memory royalties)
    {
        royalties = new LibPart.Part[](1);
        if(_rate.value == 0 || receiver_ == address(0))
        {
            return royalties;
        }
        royalties[0].account = payable(receiver_);
        royalties[0].value = _rate.toPrecision(2).value;
        return royalties;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool)
    {
        return AccessControlEnumerable.supportsInterface(interfaceId) ||
               interfaceId == IRoyaltyInterfaceId;
    }
}

/**
 * @dev Base royalty contract external implementer, ie will externalize behavior into another contract (ie a deployed
 * RoyaltyHandler), acting as a proxy. Will declare itself as royalty manager for most participating market places:
 * 
 * For Opensea, the behavior is to provided collection owner using `Ownable` and use the owner to connect onto their platform
 * and manage the collection when royalty can be defined.
 * 
 * After 2023/01/01, OpenSea will enforce royalties management, by using RoyaltyRegistry to get royalties to be applied on an NFT,
 * and by checking that transfer is not allowed if initiated by platforms that don't apply creator's royalties on sells. That is
 * why it is mandatory for implementing contracts to block any transfer using onlyAllowedOperator modifier 
 * 
 * For Rarible/Mintable, implementing RoyaltiesV2/RoyaltiesV2 is requested in order to return applicable royalty rate/amount.
 * Royalty receiver will also be the owner of the contract in order to be consistent with opensea implementation
 * see: https://cryptomarketpool.com/erc721-contract-that-supports-sales-royalties/
 */
abstract contract RoyaltyImplementerProxy is ProxyDiamond, Ownable, IERC2981, RoyaltiesV2, UpdatableDefaultOperatorFilterer
{
    /**
     * @dev Contract constructor. For final implementers, do not forget to call ProxyDiamond constructor first in order
     * to initialize address of the ProxyHub used to reference proxies
     * @param royaltyHandlerAddress_ Address of the contract handling royalty data & process
     */
    constructor(address royaltyHandlerAddress_)
    {
        _setRoyaltyHandlerProxy(royaltyHandlerAddress_);
    }

    /**
     * Getter of the contract handling royalty data & process
     */
    function getRoyaltyHandler() internal view returns(RoyaltyHandler)
    {
        return RoyaltyHandler(getProxyAddress(type(IRoyalty).interfaceId));
    }
    /**
     * Setter of address of the contract handling royalty data & process
     */
    function _setRoyaltyHandlerProxy(address royaltyHandlerAddress_) virtual internal
    {
        _setProxy(type(IRoyalty).interfaceId, royaltyHandlerAddress_, type(IRoyalty).interfaceId, false, true, true);
    }

    /**
     * Getter of the royalty rate and applicable decimals in %, which mean that {"value":250, "decimals":2}
     * for instance should be understood as 2.5%
     */
    function getRoyalty() external view returns(DecimalsType.Number_uint32 memory)
    {
        return getRoyaltyHandler().getRoyalty();
    }
    /**
     * @dev Method from IERC2981 to get royalty amount and receiver for a token ID & a sale price. This implementation
     * will use defined royalty rate to apply it on sale price whatever the token ID is and get royalty amount. Receiver
     * will be the current owner of the contract. First parameter aka 'tokenId' is needed by IERC2981 interface inherited
     * method but meaningless in our implementation
     * @param salePrice Sale price to be used to calculated royalty amount
     */
    function royaltyInfo(uint256 , uint256 salePrice) override external view returns (address receiver, uint256 royaltyAmount)
    {
        return getRoyaltyHandler().royaltyInfo(owner(), salePrice);
    }
    /**
     * @dev Method from RoyaltiesV2 to get royalty applicable percentage basis points and receiver for a token ID. This
     * implementation will use defined royalty rate whatever the token ID is. Receiver will be the current owner of the
     * contract. First parameter aka 'tokenId' is needed by RoyaltiesV2 interface inherited method but meaningless in our
     * implementation
     */
    function getRaribleV2Royalties(uint256) override external view returns (LibPart.Part[] memory)
    {
        return getRoyaltyHandler().getRaribleV2Royalties(owner());
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ProxyDiamond, IERC165) returns (bool)
    {
        return super.supportsInterface(interfaceId) ||
               interfaceId == type(IERC2981).interfaceId || // = 0x2a55205a Interface ID for Royalties from IERC2981, 0x2a55205a=bytes4(keccak256("royaltyInfo(uint256,uint256)"))
               interfaceId == type(RoyaltiesV2).interfaceId;// = 0xcad96cca Interface ID for Royalties from Rarible RoyaltiesV2, 0xcad96cca=bytes4(keccak256("getRaribleV2Royalties(uint256)"))
    }
    
    function owner() public view virtual override(Ownable, UpdatableOperatorFilterer) returns (address)
    {
        return Ownable.owner();
    }
}

/**
 * @dev Base royalty contract internal implementer, ie will directly extend RoyaltyHandler contract. Will declare itself as royalty
 * manager for most participating market places:
 * 
 * For Opensea, the behavior is to provided collection owner using `Ownable` and use the owner to connect onto their platform
 * and manage the collection when royalty can be defined.
 * 
 * After 2023/01/01, OpenSea will enforce royalties management, by using RoyaltyRegistry to get royalties to be applied on an NFT,
 * and by checking that transfer is not allowed if initiated by platforms that don't apply creator's royalties on sells. That is
 * why it is mandatory for implementing contracts to block any transfer using onlyAllowedOperator modifier 
 * 
 * For Rarible/Mintable, implementing RoyaltiesV2/RoyaltiesV2 is requested in order to return applicable royalty rate/amount.
 * Royalty receiver will also be the owner of the contract in order to be consistent with opensea implementation
 * see: https://cryptomarketpool.com/erc721-contract-that-supports-sales-royalties/
 */
abstract contract RoyaltyImplementerDirect is RoyaltyHandler, Ownable, IERC2981, RoyaltiesV2, UpdatableDefaultOperatorFilterer
{

    /**
     * @dev Contract constructor
     * @param rate_ Royalty rate applicable on participating market places
     * @param decimals_ Royalty rate applicable decimals
     */
    constructor(uint32 rate_, uint8 decimals_) RoyaltyHandler(rate_, decimals_)
    {
    }

    /**
     * @dev Method from IERC2981 to get royalty amount and receiver for a token ID & a sale price. This implementation
     * will use defined royalty rate to apply it on sale price whatever the token ID is and get royalty amount. Receiver
     * will be the current owner of the contract. First parameter aka 'tokenId' is needed by IERC2981 interface inherited
     * method but meaningless in our implementation
     * @param salePrice Sale price to be used to calculated royalty amount
     */
    function royaltyInfo(uint256 , uint256 salePrice) override external view returns (address receiver, uint256 royaltyAmount)
    {
        return royaltyInfo(owner(), salePrice);
    }
    /**
     * @dev Method from RoyaltiesV2 to get royalty applicable percentage basis points and receiver for a token ID. This
     * implementation will use defined royalty rate whatever the token ID is. Receiver will be the current owner of the
     * contract. First parameter aka 'tokenId' is needed by RoyaltiesV2 interface inherited method but meaningless in our
     * implementation
     */
    function getRaribleV2Royalties(uint256) override external view returns (LibPart.Part[] memory)
    {
        return getRaribleV2Royalties(owner());
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(RoyaltyHandler, IERC165) returns (bool)
    {
        return RoyaltyHandler.supportsInterface(interfaceId) ||
               interfaceId == type(IERC2981).interfaceId || // = 0x2a55205a Interface ID for Royalties from IERC2981, 0x2a55205a=bytes4(keccak256("royaltyInfo(uint256,uint256)"))
               interfaceId == type(RoyaltiesV2).interfaceId; // = 0xcad96cca Interface ID for Royalties from Rarible RoyaltiesV2, 0xcad96cca=bytes4(keccak256("getRaribleV2Royalties(uint256)"))
    }
    
    function owner() public view virtual override(Ownable, UpdatableOperatorFilterer) returns (address)
    {
        return Ownable.owner();
    }
}

//         ╩╝                                  ▓╝
//         ╥╕   ,╓[email protected]@╥,     ╓[email protected]@╥, ╓╥       ╥  ╥² =╥      ╥∞
//         ╟▌  ▓╝²    ╙▓⌐  ▓╩    ▓@ ▐▓    ,▓╝  ▓P   ▐@  g▓`
//         ╟▌ ╞▓       ▐▓ j▓         ▐▓  ,▓╜   ▓P    ]▓▓Ç
//         ╟▌  ▓W     ╓▓▓ j▓          ▐▓,▓`    ▓P  ,@╝  ╚▓,
//         ╟▌   ╙╙╩Ñ╩╝`╘╨ "╨           ╙╨`     ╨ⁿ *╨      ╙*
//        ,▓M
//       ╙╙         ***** WEB3 CREATORS STUDIO *****
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title Interface that lists decimals types definitions.
 * @author tazous
 */
library DecimalsType
{
    /**
     * @dev Decimal number structure, based on a uint256 value and its applicable decimals number
     */
    struct Number_uint256
    {
        uint256 value;
        uint8 decimals;
    }
    /**
     * @dev Decimal number structure, based on a uint32 value and its applicable decimals number
     */
    struct Number_uint32
    {
        uint32 value;
        uint8 decimals;
    }
}

/**
 * @title Decimals library to be used internally by contracts.
 * @author tazous
 */
library DecimalsInt
{

    function to_uint32(uint32 value, uint8 decimals) internal pure returns(DecimalsType.Number_uint32 memory)
    {
        return DecimalsType.Number_uint32(value, decimals);
    }
    function to_uint32(DecimalsType.Number_uint32 memory number) internal pure returns(DecimalsType.Number_uint32 memory)
    {
        return DecimalsType.Number_uint32(number.value, number.decimals);
    }
    function to_uint32(DecimalsType.Number_uint256 memory number) internal pure returns(DecimalsType.Number_uint32 memory)
    {
        return DecimalsType.Number_uint32(uint32(number.value), number.decimals);
    }
    function to_uint256(uint256 value, uint8 decimals) internal pure returns(DecimalsType.Number_uint256 memory)
    {
        return DecimalsType.Number_uint256(value, decimals);
    }
    function to_uint256(DecimalsType.Number_uint32 memory number) internal pure returns(DecimalsType.Number_uint256 memory)
    {
        return DecimalsType.Number_uint256(number.value, number.decimals);
    }
    function to_uint256(DecimalsType.Number_uint256 memory number) internal pure returns(DecimalsType.Number_uint256 memory)
    {
        return DecimalsType.Number_uint256(number.value, number.decimals);
    }

    function round(DecimalsType.Number_uint256 memory number, uint8 precision) internal pure returns(DecimalsType.Number_uint256 memory)
    {
        if(number.decimals > precision)
        {
            number.value = number.value / 10**(number.decimals - precision);
            number.decimals = precision;
        }
        return number;
    }
    function round(DecimalsType.Number_uint32 memory number, uint8 precision) internal pure returns(DecimalsType.Number_uint32 memory)
    {
        return to_uint32(round(to_uint256(number), precision));
    }
    function toPrecision(DecimalsType.Number_uint256 memory number, uint8 precision) internal pure returns(DecimalsType.Number_uint256 memory)
    {
        if(number.decimals < precision)
        {
            number.value = number.value * 10**(precision - number.decimals);
            number.decimals = precision;
        }
        else if(number.decimals > precision)
        {
            number = round(number, precision);
        }
        return number;
    }
    function toPrecision(DecimalsType.Number_uint32 memory number, uint8 precision) internal pure returns(DecimalsType.Number_uint32 memory)
    {
        return to_uint32(toPrecision(to_uint256(number), precision));
    }

    /**
     * @dev Utility methods that allows to clean unnecessary trailing zeros to reduce size of values
     */
    function cleanFromTrailingZeros(DecimalsType.Number_uint256 memory number) internal pure returns(DecimalsType.Number_uint256 memory)
    {
        if(number.value == 0)
        {
            return to_uint256(0, 0);
        }
        while(number.decimals > 0 && number.value % 10 == 0)
        {
            number.decimals--;
            number.value = number.value/10;
        }
        return number;
    }
    /**
     * @dev Utility methods that allows to clean unnecessary trailing zeros to reduce size of values
     */
    function cleanFromTrailingZeros(DecimalsType.Number_uint32 memory number) internal pure returns(DecimalsType.Number_uint32 memory)
    {
        return to_uint32(cleanFromTrailingZeros(to_uint256(number)));
    }

    function alignDecimals(DecimalsType.Number_uint256 memory number1, DecimalsType.Number_uint256 memory number2) internal pure
    returns(DecimalsType.Number_uint256 memory result1, DecimalsType.Number_uint256 memory result2)
    {
        // First reduce values while they both have trailing zeros
        while(number1.decimals > 0 && number1.value % 10 == 0 && number2.decimals > 0 && number2.value % 10 == 0)
        {
            number1.decimals--;
            number1.value = number1.value/10;
            number2.decimals--;
            number2.value = number2.value/10;
        }
        // Then reduce decimals nb if one has trailing zeros and more decimals than the other
        while(number1.decimals > 0 && number1.value % 10 == 0 && number1.decimals > number2.decimals)
        {
            number1.decimals--;
            number1.value = number1.value/10;
        }
        while(number2.decimals > 0 && number2.value % 10 == 0 && number2.decimals > number1.decimals)
        {
            number2.decimals--;
            number2.value = number2.value/10;
        }
        // Finally add decimals to the one that as the least
        if(number1.decimals < number2.decimals)
        {
            number1 = toPrecision(number1, number2.decimals);
        }
        else if(number2.decimals < number1.decimals)
        {
            number2 = toPrecision(number2, number1.decimals);
        }
        return (number1, number2);
    }
    function alignDecimals(DecimalsType.Number_uint32 memory number1, DecimalsType.Number_uint32 memory number2) internal pure
    returns(DecimalsType.Number_uint32 memory result1, DecimalsType.Number_uint32 memory result2)
    {
        (DecimalsType.Number_uint256 memory result1_, DecimalsType.Number_uint256 memory result2_) = alignDecimals(to_uint256(number1), to_uint256(number2));
        return (to_uint32(result1_), to_uint32(result2_));
    }

    function add(DecimalsType.Number_uint256 memory number1, DecimalsType.Number_uint256 memory number2) internal pure
    returns(DecimalsType.Number_uint256 memory)
    {
        (number1, number2) = alignDecimals(number1, number2);
        return cleanFromTrailingZeros(to_uint256(number1.value+number2.value, number1.decimals));
    }
    function add(DecimalsType.Number_uint32 memory number1, DecimalsType.Number_uint32 memory number2) internal pure
    returns(DecimalsType.Number_uint32 memory)
    {
        (number1, number2) = alignDecimals(number1, number2);
        return cleanFromTrailingZeros(to_uint32(number1.value+number2.value, number1.decimals));
    }
    function sub(DecimalsType.Number_uint256 memory number1, DecimalsType.Number_uint256 memory number2) internal pure
    returns(DecimalsType.Number_uint256 memory)
    {
        (number1, number2) = alignDecimals(number1, number2);
        return cleanFromTrailingZeros(to_uint256(number1.value-number2.value, number1.decimals));
    }
    function sub(DecimalsType.Number_uint32 memory number1, DecimalsType.Number_uint32 memory number2) internal pure
    returns(DecimalsType.Number_uint32 memory)
    {
        (number1, number2) = alignDecimals(number1, number2);
        return cleanFromTrailingZeros(to_uint32(number1.value-number2.value, number1.decimals));
    }
    function mul(DecimalsType.Number_uint256 memory number1, DecimalsType.Number_uint256 memory number2) internal pure
    returns(DecimalsType.Number_uint256 memory)
    {
        number1 = cleanFromTrailingZeros(number1);
        number2 = cleanFromTrailingZeros(number2);
        return cleanFromTrailingZeros(to_uint256(number1.value*number2.value, number1.decimals+number2.decimals));
    }
    function mul(DecimalsType.Number_uint32 memory number1, DecimalsType.Number_uint32 memory number2) internal pure
    returns(DecimalsType.Number_uint32 memory)
    {
        number1 = cleanFromTrailingZeros(number1);
        number2 = cleanFromTrailingZeros(number2);
        return cleanFromTrailingZeros(to_uint32(number1.value*number2.value, number1.decimals+number2.decimals));
    }
    
    function div(DecimalsType.Number_uint256 memory number1, DecimalsType.Number_uint256 memory number2, uint8 precision) internal pure
    returns(DecimalsType.Number_uint256 memory)
    {
        (number1, number2) = alignDecimals(number1, number2);
        uint256 result = number1.value / number2.value;
        uint8 decimals = 0;
        uint256 mod = number1.value % number2.value;
        while(mod != 0 && decimals < precision)
        {
            result = result * 10;
            mod = mod * 10;
            decimals++;
            result+= mod/number2.value;
            mod = mod % number2.value;
        }
        return cleanFromTrailingZeros(to_uint256(result, decimals));
    }
    function div(DecimalsType.Number_uint32 memory number1, DecimalsType.Number_uint32 memory number2, uint8 precision) internal pure
    returns(DecimalsType.Number_uint32 memory)
    {
        return to_uint32(div(to_uint256(number1), to_uint256(number2), precision));
    }
}
/**
 * @title Decimals library to be linked externally by contracts.
 * @author tazous
 */
library DecimalsExt
{
    using DecimalsInt for uint256;
    using DecimalsInt for uint32;
    using DecimalsInt for DecimalsType.Number_uint256;
    using DecimalsInt for DecimalsType.Number_uint32;

    function to_uint32(uint32 value, uint8 decimals) external pure returns(DecimalsType.Number_uint32 memory)
    {
        return value.to_uint32(decimals);
    }
    function to_uint32(DecimalsType.Number_uint32 memory number) external pure returns(DecimalsType.Number_uint32 memory)
    {
        return number.to_uint32();
    }
    function to_uint32(DecimalsType.Number_uint256 memory number) external pure returns(DecimalsType.Number_uint32 memory)
    {
        return number.to_uint32();
    }
    function to_uint256(uint256 value, uint8 decimals) external pure returns(DecimalsType.Number_uint256 memory)
    {
        return value.to_uint256(decimals);
    }
    function to_uint256(DecimalsType.Number_uint32 memory number) external pure returns(DecimalsType.Number_uint256 memory)
    {
        return number.to_uint256();
    }
    function to_uint256(DecimalsType.Number_uint256 memory number) external pure returns(DecimalsType.Number_uint256 memory)
    {
        return number.to_uint256();
    }

    function round(DecimalsType.Number_uint256 memory number, uint8 precision) external pure returns(DecimalsType.Number_uint256 memory)
    {
        return number.round(precision);
    }
    function round(DecimalsType.Number_uint32 memory number, uint8 precision) external pure returns(DecimalsType.Number_uint32 memory)
    {
        return number.round(precision);
    }
    function toPrecision(DecimalsType.Number_uint256 memory number, uint8 precision) external pure returns(DecimalsType.Number_uint256 memory)
    {
        return number.toPrecision(precision);
    }
    function toPrecision(DecimalsType.Number_uint32 memory number, uint8 precision) external pure returns(DecimalsType.Number_uint32 memory)
    {
        return number.toPrecision(precision);
    }

    /**
     * @dev Utility methods that allows to clean unnecessary trailing zeros to reduce size of values
     */
    function cleanFromTrailingZeros(DecimalsType.Number_uint256 memory number) external pure returns(DecimalsType.Number_uint256 memory)
    {
        return number.cleanFromTrailingZeros();
    }
    /**
     * @dev Utility methods that allows to clean unnecessary trailing zeros to reduce size of values
     */
    function cleanFromTrailingZeros(DecimalsType.Number_uint32 memory number) external pure returns(DecimalsType.Number_uint32 memory)
    {
        return number.cleanFromTrailingZeros();
    }

    function alignDecimals(DecimalsType.Number_uint256 memory number1, DecimalsType.Number_uint256 memory number2) external pure
    returns(DecimalsType.Number_uint256 memory result1, DecimalsType.Number_uint256 memory result2)
    {
        return number1.alignDecimals(number2);
    }
    function alignDecimals(DecimalsType.Number_uint32 memory number1, DecimalsType.Number_uint32 memory number2) external pure
    returns(DecimalsType.Number_uint32 memory result1, DecimalsType.Number_uint32 memory result2)
    {
        return number1.alignDecimals(number2);
    }

    function add(DecimalsType.Number_uint256 memory number1, DecimalsType.Number_uint256 memory number2) external pure
    returns(DecimalsType.Number_uint256 memory)
    {
        return number1.add(number2);
    }
    function add(DecimalsType.Number_uint32 memory number1, DecimalsType.Number_uint32 memory number2) external pure
    returns(DecimalsType.Number_uint32 memory)
    {
        return number1.add(number2);
    }
    function sub(DecimalsType.Number_uint256 memory number1, DecimalsType.Number_uint256 memory number2) external pure
    returns(DecimalsType.Number_uint256 memory)
    {
        return number1.sub(number2);
    }
    function sub(DecimalsType.Number_uint32 memory number1, DecimalsType.Number_uint32 memory number2) external pure
    returns(DecimalsType.Number_uint32 memory)
    {
        return number1.sub(number2);
    }
    function mul(DecimalsType.Number_uint256 memory number1, DecimalsType.Number_uint256 memory number2) external pure
    returns(DecimalsType.Number_uint256 memory)
    {
        return number1.mul(number2);
    }
    function mul(DecimalsType.Number_uint32 memory number1, DecimalsType.Number_uint32 memory number2) external pure
    returns(DecimalsType.Number_uint32 memory)
    {
        return number1.mul(number2);
    }
    
    function div(DecimalsType.Number_uint256 memory number1, DecimalsType.Number_uint256 memory number2, uint8 precision) external pure
    returns(DecimalsType.Number_uint256 memory)
    {
        return number1.div(number2, precision);
    }
    function div(DecimalsType.Number_uint32 memory number1, DecimalsType.Number_uint32 memory number2, uint8 precision) external pure
    returns(DecimalsType.Number_uint32 memory)
    {
        return number1.div(number2, precision);
    }
}

//         ╩╝                                  ▓╝
//         ╥╕   ,╓[email protected]@╥,     ╓[email protected]@╥, ╓╥       ╥  ╥² =╥      ╥∞
//         ╟▌  ▓╝²    ╙▓⌐  ▓╩    ▓@ ▐▓    ,▓╝  ▓P   ▐@  g▓`
//         ╟▌ ╞▓       ▐▓ j▓         ▐▓  ,▓╜   ▓P    ]▓▓Ç
//         ╟▌  ▓W     ╓▓▓ j▓          ▐▓,▓`    ▓P  ,@╝  ╚▓,
//         ╟▌   ╙╙╩Ñ╩╝`╘╨ "╨           ╙╨`     ╨ⁿ *╨      ╙*
//        ,▓M
//       ╙╙         ***** WEB3 CREATORS STUDIO *****
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./SecurityUtils.sol";

error ProxyHub_ContractIsNull();
error ProxyHub_ContractIsInvalid(bytes4 interfaceId);
error ProxyHub_KeyNotDefined(address user, bytes4 key);
error ProxyHub_NotUpdatable();
error ProxyHub_NotAdminable();
error ProxyHub_CanOnlyBeRestricted();
error ProxyHub_CanOnlyBeAdminableIfUpdatable();

/**
 * @dev As solidity contracts are size limited, and in order to ease modularity and potential upgrades, contracts could/should
 * be divided into smaller contracts in charge of specific functional processes. Links between those contracts and their "users"
 * can be seen as 'proxies', a way to call and delegate part of a treatment. Instead of having every user contract referencing
 * and managing links to those proxies, this part has been delegated to following ProxyHub. User contract might then declare
 * themselves as ProxyDiamond to easily store and access their own proxies
 */
contract ProxyHub is PausableImpl
{
    struct ProxyEntry
    {
        address user;
        bytes4 key;
    }
    /**
     * @dev Proxy definition data structure
     * 'proxyAddress' Address of the proxied contract
     * 'interfaceId' ID of the interface the proxied contract should comply to (ERC165)
     * 'nullable' Can the proxied address be null
     * 'updatable' Can the proxied address be updated by its user
     * 'adminable' Can the proxied address be updated by a proxy hub administrator
     * 'adminRole' Role that proxy hub administrator should be granted if adminable is activated
     */
    struct Proxy
    {
        address proxyAddress;
        bytes4 interfaceId;
        bool nullable;
        bool updatable;
        bool adminable;
        bytes32 adminRole;
    }
    /** @dev Proxies defined for users on keys */
    mapping(address => mapping(bytes4 => Proxy)) private _proxies;
    /** @dev Enumerable set used to reference every defined users */
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _users;
    /** @dev Enumerable sets used to reference every defined keys by users */
    using EnumerableSet for EnumerableSet.Bytes32Set;
    mapping(address => EnumerableSet.Bytes32Set) private _keys;

    /**
     * @dev Event emitted whenever a proxy is defined
     * 'admin' Address of the administrator that defined the proxied contract (will be the user if directly managed)
     * 'user' Address of the of the user for which a proxy was defined
     * 'key' Key by which the proxy was defined and referenced
     * 'proxyAddress' Address of the proxied contract
     * 'nullable' Can the proxied address be null
     * 'updatable' Can the proxied address be updated by its user
     * 'adminable' Can the proxied address be updated by a proxy hub administrator
     * 'adminRole' Role that proxy hub administrator should be granted if adminable is activated
     */
    event ProxyDefined(address indexed admin, address indexed user, bytes4 indexed key, address proxyAddress,
                       bytes4 interfaceId, bool nullable, bool updatable, bool adminable, bytes32 adminRole);

    /**
     * @dev Default constructor
     */
    constructor() {}

    /**
     * @dev Search for the existing proxy defined by given user on provided key
     * @param user User that should have defined the proxy being searched for
     * @param key Key by which the proxy being searched for should have been defined
     * @return Found existing proxy defined by given user on provided key
     */
    function findProxyFor(address user, bytes4 key) public view returns (Proxy memory)
    {
        return _proxies[user][key];
    }
    /**
     * @dev Search for the existing proxy defined by caller on provided key
     * @param key Key by which the proxy being searched for should have been defined
     * @return Found existing proxy defined by caller on provided key
     */
    function findProxy(bytes4 key) public view returns (Proxy memory)
    {
        return findProxyFor(msg.sender, key);
    }
    /**
     * @dev Search for the existing proxy address defined by given user on provided key
     * @param user User that should have defined the proxy being searched for
     * @param key Key by which the proxy being searched for should have been defined
     * @return Found existing proxy address defined by given user on provided key
     */
    function findProxyAddressFor(address user, bytes4 key) external view returns (address)
    {
        return findProxyFor(user, key).proxyAddress;
    }
    /**
     * @dev Search for the existing proxy address defined by caller on provided key
     * @param key Key by which the proxy being searched for should have been defined
     * @return Found existing proxy address defined by caller on provided key
     */
    function findProxyAddress(bytes4 key) external view returns (address)
    {
        return findProxy(key).proxyAddress;
    }
    /**
     * @dev Search if proxy has been defined by given user on provided key
     * @param user User that should have defined the proxy being searched for
     * @param key Key by which the proxy being searched for should have been defined
     * @return True if proxy has been defined by given user on provided key, false otherwise
     */
    function isKeyDefinedFor(address user, bytes4 key) public view returns (bool)
    {
        // A proxy can have only been initialized whether with a null address AND nullable value set to true OR a not null
        // address (When a structure has not yet been initialized, all boolean value are false)
        return _proxies[user][key].proxyAddress != address(0) || _proxies[user][key].nullable;
    }
    /**
     * @dev Check if proxy has been defined by given user on provided key. Will revert with ProxyHub_KeyNotDefined if not
     * @param user User that should have defined the proxy being searched for
     * @param key Key by which the proxy being searched for should have been defined
     */
    function checkKeyIsDefinedFor(address user, bytes4 key) internal view
    {
        if(!isKeyDefinedFor(user, key)) revert ProxyHub_KeyNotDefined(user, key);
    }
    /**
     * @dev Get the existing proxy defined by given user on provided key. Will revert with ProxyHub_KeyNotDefined if not
     * found
     * @param user User that should have defined the proxy being searched for
     * @param key Key by which the proxy being searched for should have been defined
     * @return Found existing proxy defined by given user on provided key
     */
    function getProxyFor(address user, bytes4 key) public view returns (Proxy memory)
    {
        checkKeyIsDefinedFor(user, key);
        return _proxies[user][key];
    }
    /**
     * @dev Get the existing proxy defined by caller on provided key. Will revert with ProxyHub_KeyNotDefined if not found
     * @param key Key by which the proxy being searched for should have been defined
     * @return Found existing proxy defined by caller on provided key
     */
    function getProxy(bytes4 key) public view returns (Proxy memory)
    {
        return getProxyFor(msg.sender, key);
    }
    /**
     * @dev Get the existing proxy address defined by given user on provided key. Will revert with ProxyHub_KeyNotDefined
     * if not found
     * @param user User that should have defined the proxy being searched for
     * @param key Key by which the proxy being searched for should have been defined
     * @return Found existing proxy address defined by given user on provided key
     */
    function getProxyAddressFor(address user, bytes4 key) public view returns (address)
    {
        return getProxyFor(user, key).proxyAddress;
    }
    /**
     * @dev Get the existing proxy address defined by caller on provided key. Will revert with ProxyHub_KeyNotDefined if
     * not found
     * @param key Key by which the proxy being searched for should have been defined
     * @return Found existing proxy address defined by caller on provided key
     */
    function getProxyAddress(bytes4 key) external view virtual returns (address)
    {
        return getProxy(key).proxyAddress;
    }

    /**
     * @dev Set already existing proxy defined by given user on provided key. Will revert with ProxyHub_KeyNotDefined if
     * not found, with ProxyHub_NotAdminable if not allowed to be modified by administrator, with ProxyHub_CanOnlyBeRestricted
     * if given options are less restrictive that existing ones and with ProxyHub_ContractIsNull when given address is null
     * and null not allowed
     * @param user User that should have defined the proxy being modified
     * @param key Key by which the proxy being modified should have been defined
     * @param proxyAddress Address of the proxy being defined
     * @param interfaceId ID of the interface the proxy being defined should comply to (ERC165)
     * @param nullable Can the proxied address be null
     * @param updatable Can the proxied address be updated by its user
     * @param adminable Can the proxied address be updated by a proxy hub administrator
     */
    function setProxyFor(address user, bytes4 key, address proxyAddress, bytes4 interfaceId,
                         bool nullable, bool updatable, bool adminable) public
    {
        _setProxy(msg.sender, user, key, proxyAddress, interfaceId, nullable, updatable, adminable, DEFAULT_ADMIN_ROLE);
    }
    /**
     * @dev Define proxy for caller on provided key. Will revert with ProxyHub_NotUpdatable if not allowed to be modified,
     * with ProxyHub_CanOnlyBeRestricted if given options are less restrictive that existing ones and with ProxyHub_ContractIsNull
     * when given address is null and null not allowed
     * @param key Key by which the proxy should be defined for the caller
     * @param proxyAddress Address of the proxy being defined
     * @param interfaceId ID of the interface the proxy being defined should comply to (ERC165)
     * @param nullable Can the proxied address be null
     * @param updatable Can the proxied address be updated by its user
     * @param adminable Can the proxied address be updated by a proxy hub administrator
     * @param adminRole Role that proxy hub administrator should be granted if adminable is activated
     */
    function setProxy(bytes4 key, address proxyAddress, bytes4 interfaceId,
                      bool nullable, bool updatable, bool adminable, bytes32 adminRole) external
    {
        _setProxy(msg.sender, msg.sender, key, proxyAddress, interfaceId, nullable, updatable, adminable, adminRole);
    }

    function _setProxy(address admin, address user, bytes4 key, address proxyAddress, bytes4 interfaceId,
                       bool nullable, bool updatable, bool adminable, bytes32 adminRole) internal whenNotPaused()
    {
        if(!updatable && adminable) revert ProxyHub_CanOnlyBeAdminableIfUpdatable();
        // Check if we are in update mode and perform updatability validation
        if(isKeyDefinedFor(user, key))
        {
            Proxy memory proxy = _proxies[user][key];
            // Proxy is being updated directly by its user
            if(admin == user)
            {
                if(!proxy.updatable) revert ProxyHub_NotUpdatable();
            }
            // Proxy is being updated "externally" by an administrator
            else
            {
                if(!proxy.adminable && admin != user) revert ProxyHub_NotAdminable();
                _checkRole(proxy.adminRole, admin);
                // Admin role is never given in that case, should then be retrieved
                adminRole = _proxies[user][key].adminRole;
            }
            if(proxy.interfaceId != interfaceId || proxy.adminRole != adminRole) revert ProxyHub_CanOnlyBeRestricted();
            // No update to be performed
            if(proxy.proxyAddress == proxyAddress && proxy.nullable == nullable &&
               proxy.updatable == updatable && proxy.adminable == adminable)
            {
                return;
            }
            if((!_proxies[user][key].nullable && nullable) ||
               (!_proxies[user][key].updatable && updatable) ||
               (!_proxies[user][key].adminable && adminable))
            {
                revert ProxyHub_CanOnlyBeRestricted();
            }
        }
        // Proxy cannot be initiated by administration
        else if(admin != user) revert ProxyHub_KeyNotDefined(user, key);
        // Proxy reference is being created
        else
        {
            _users.add(user);
            _keys[user].add(key);
        }
        // Check Proxy depending on its address
        if(proxyAddress == address(0))
        {
            // Proxy address cannot be set to null
            if(!nullable) revert ProxyHub_ContractIsNull();
        }
        // Interface ID is defined
        else if(interfaceId != 0x00)
        {
            // Proxy should support requested interface
            if(!ERC165(proxyAddress).supportsInterface(interfaceId)) revert ProxyHub_ContractIsInvalid(interfaceId);
        }

        _proxies[user][key] = Proxy(proxyAddress, interfaceId, nullable, updatable, adminable, adminRole);
        emit ProxyDefined(admin, user, key, proxyAddress, interfaceId, nullable, updatable, adminable, adminRole);
    }

    /**
     * @dev This method returns the number of users defined in this contract.
     * Can be used together with {getUserAt} to enumerate all users defined in this contract.
     */
    function getUserCount() public view returns (uint256)
    {
        return _users.length();
    }
    /**
     * @dev This method returns one of the users defined in this contract.
     * `index` must be a value between 0 and {getUserCount}, non-inclusive.
     * Users are not sorted in any particular way, and their ordering may change at any point.
     * WARNING: When using {getUserAt} and {getUserCount}, make sure you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     * @param index Index at which to search for the user
     */
    function getUserAt(uint256 index) public view returns (address)
    {
        return _users.at(index);
    }
    /**
     * @dev This method returns the number of keys defined in this contract for a user.
     * Can be used together with {getKeyAt} to enumerate all keys defined in this contract for a user.
     * @param user User for which to get defined number of keys
     */
    function getKeyCount(address user) public view returns (uint256)
    {
        return _keys[user].length();
    }
    /**
     * @dev This method returns one of the keys defined in this contract for a user.
     * `index` must be a value between 0 and {getKeyCount}, non-inclusive.
     * Keys are not sorted in any particular way, and their ordering may change at any point.
     * WARNING: When using {getKeyAt} and {getKeyCount}, make sure you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     * @param user User for which to get key at defined index
     * @param index Index at which to search for the key of defined user
     */
    function getKeyAt(address user, uint256 index) public view returns (bytes4)
    {
        return bytes4(_keys[user].at(index));
    }

    function getProxies() public view returns (ProxyEntry[] memory proxyEntries, Proxy[] memory proxies)
    {
        uint256 userCount = getUserCount();
        for(uint256 i = 0 ; i < userCount ; i++)
        {
            address user = getUserAt(i);
            uint256 keyCount = getKeyCount(user);
            if(i == 0)
            {
                proxyEntries = new ProxyEntry[](keyCount);
            }
            else
            {
                ProxyEntry[] memory __proxyEntries = proxyEntries;
                proxyEntries = new ProxyEntry[](keyCount + __proxyEntries.length);
                for(uint256 j = 0 ; j < __proxyEntries.length ; j++)
                {
                    proxyEntries[j] = __proxyEntries[j];
                }
            }
            for(uint256 j = 0 ; j < keyCount ; j++)
            {
                proxyEntries[proxyEntries.length - (keyCount-j)] = ProxyEntry(user, getKeyAt(user, j));
            }
        }
        proxies = new Proxy[](proxyEntries.length);
        for(uint256 i = 0 ; i < proxyEntries.length ; i++)
        {
            proxies[i] = getProxyFor(proxyEntries[i].user, proxyEntries[i].key);
        }
    }
}

/**
 * @title Simple proxy diamond interface.
 * @author tazous
 */
interface IProxyDiamond
{
    /**
     * @dev Should return the address of the proxy defined by current proxy diamond on provided key. Should revert with ProxyHub_KeyNotDefined
     * if not found
     * @param key Key on which searched proxied address should be defined by diamond
     * @return Found existing proxy address defined by diamond on provided key
     */
    function getProxyAddress(bytes4 key) external view returns (address);
}

/**
 * @dev This is the contract to extend in order to easily store and access a proxy. Does not directly implement
 * ERC165 to prevent further linearization of inheritance issues
 */
contract ProxyDiamond is IProxyDiamond
{
    /** @dev Address of the Hub where proxies are stored */
    address public immutable proxyHubAddress;
    /** IProxyDiamond interface ID definition */
    bytes4 public constant IProxyDiamondInterfaceId = type(IProxyDiamond).interfaceId;

    /**
     * @dev Default constructor
     * @param proxyHubAddress_ Address of the Hub where proxies are stored
     */
    constructor(address proxyHubAddress_)
    {
        proxyHubAddress = proxyHubAddress_;
    }

    /**
     * @dev Returns the address of the proxy defined by current proxy diamond on provided key. Will revert with ProxyHub_KeyNotDefined
     * if not found
     * @param key Key on which searched proxied address should be defined by diamond
     * @return Found existing proxy address defined by diamond on provided key
     */
    function getProxyAddress(bytes4 key) public virtual view returns (address)
    {
        return ProxyHub(proxyHubAddress).getProxyAddress(key);
    }
    /**
     * @dev Define proxy for diamond on provided key. Will revert with ProxyHub_NotUpdatable if not allowed to be modified,
     * with ProxyHub_CanOnlyBeRestricted if given options are less restrictive that existing ones and with ProxyHub_ContractIsNull
     * when given address is null and null not allowed
     * @param key Key by which the proxy should be defined for the caller
     * @param proxyAddress Address of the proxy being defined
     * @param interfaceId ID of the interface the proxy being defined should comply to (ERC165)
     * @param nullable Can the proxied address be null
     * @param updatable Can the proxied address be updated by its user
     * @param adminable Can the proxied address be updated by a proxy hub administrator
     * @param adminRole Role that proxy hub administrator should be granted if adminable is activated
     */
    function _setProxy(bytes4 key, address proxyAddress, bytes4 interfaceId,
                       bool nullable, bool updatable, bool adminable, bytes32 adminRole) internal virtual
    {
        ProxyHub(proxyHubAddress).setProxy(key, proxyAddress, interfaceId, nullable, updatable, adminable, adminRole);
    }
    /**
     * @dev Define proxy for diamond on provided key. Will revert with ProxyHub_NotUpdatable if not allowed to be modified,
     * with ProxyHub_CanOnlyBeRestricted if given options are less restrictive that existing ones and with ProxyHub_ContractIsNull
     * when given address is null and null not allowed. Administrator role will be the default one returned by getProxyAdminRole()
     * @param key Key by which the proxy should be defined for the caller
     * @param proxyAddress Address of the proxy being defined
     * @param interfaceId ID of the interface the proxy being defined should comply to (ERC165)
     * @param nullable Can the proxied address be null
     * @param updatable Can the proxied address be updated by its user
     * @param adminable Can the proxied address be updated by a proxy hub administrator
     */
    function _setProxy(bytes4 key, address proxyAddress, bytes4 interfaceId,
                       bool nullable, bool updatable, bool adminable) internal virtual
    {
        _setProxy(key, proxyAddress, interfaceId, nullable, updatable, adminable, getProxyAdminRole());
    }
    /**
     * @dev Default proxy hub administrator role
     */
    function getProxyAdminRole() public virtual returns (bytes32)
    {
        return 0x00;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool)
    {
        return interfaceId == IProxyDiamondInterfaceId;
    }
}


contract ProxyDiamondInternalHub is ProxyDiamond, ProxyHub
{
    constructor() ProxyDiamond(address(0)){}

    function getProxyAddress(bytes4 key) public view virtual override (ProxyDiamond, ProxyHub) returns (address)
    {
        return ProxyHub.getProxyAddressFor(address(this), key);
    }
    function _setProxy(bytes4 key, address proxyAddress, bytes4 interfaceId,
                       bool nullable, bool updatable, bool adminable, bytes32 adminRole) internal virtual override
    {
        ProxyHub._setProxy(address(this), address(this), key, proxyAddress, interfaceId, nullable, updatable, adminable, adminRole);
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override (ProxyDiamond, AccessControlEnumerable) returns (bool)
    {
        return ProxyDiamond.supportsInterface(interfaceId) ||
               AccessControlEnumerable.supportsInterface(interfaceId);
    }
}

//         ╩╝                                  ▓╝
//         ╥╕   ,╓[email protected]@╥,     ╓[email protected]@╥, ╓╥       ╥  ╥² =╥      ╥∞
//         ╟▌  ▓╝²    ╙▓⌐  ▓╩    ▓@ ▐▓    ,▓╝  ▓P   ▐@  g▓`
//         ╟▌ ╞▓       ▐▓ j▓         ▐▓  ,▓╜   ▓P    ]▓▓Ç
//         ╟▌  ▓W     ╓▓▓ j▓          ▐▓,▓`    ▓P  ,@╝  ╚▓,
//         ╟▌   ╙╙╩Ñ╩╝`╘╨ "╨           ╙╨`     ╨ⁿ *╨      ╙*
//        ,▓M
//       ╙╙         ***** WEB3 CREATORS STUDIO *****
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

error AccessControl_MissingRole(address account, bytes32 role);
error AccessControl_EmptyRole();
error AccessControl_NotEmptyRole();
error AccessControl_NoMoreAdminRole();

/**
 * @dev Default implementation to use when role based access control is requested. It extends openzeppelin implementation
 * in order to use 'error' instead of 'string message' when checking roles and to be able to attribute admin role for each
 * defined role (and not rely exclusively on the DEFAULT_ADMIN_ROLE)
 */
abstract contract AccessControlImpl is AccessControlEnumerable
{
    /** Role that will not be able to be granted to anyone. To be used to block/burn any existing role */
    bytes32 public constant NO_MORE_ADMIN_ROLE = 0x9999999999999999999999999999999999999999999999999999999999999999;
    
    /**
     * @dev Default constructor
     */
    constructor()
    {
        // To be done at initialization otherwise it will never be accessible again
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // Block NO_MORE_ADMIN_ROLE so it can never be granted to anyone
        blockRole(NO_MORE_ADMIN_ROLE);
    }

    /**
     * @dev Should return true if given role is forever blocked, ie no more role granting/revoking or admin role update
     * @param role Role for which blocked status should be checked
     */
    function isRoleBlocked(bytes32 role) public view returns (bool)
    {
        return getRoleAdmin(role) == NO_MORE_ADMIN_ROLE;
    }
    /**
     * @dev Should return true if given role is considered forever burnt, ie blocked without any member granted to
     * @param role Role for which burnt status should be checked
     */
    function isRoleBurnt(bytes32 role) public view returns (bool)
    {
        return isRoleBlocked(role) && getRoleMemberCount(role) == 0;
    }
    /**
     * @dev Revert with AccessControl_MissingRole error if `account` is missing `role` instead of a string generated message
     */
    function _checkRole(bytes32 role, address account) internal view virtual override
    {
        if(!hasRole(role, account)) revert AccessControl_MissingRole(account, role);
    }
    /**
     * @dev Should check if given account is an admin for provided Revert with AccessControl_MissingRole error if `account` is missing
     * `role`'s admin role or DEFAULT_ADMIN_ROLE
     * @param role Role for which admin role should be checked
     * @param account Account to be checked against given role's admin role
     */
    function _checkRoleAdmin(bytes32 role, address account) internal view virtual
    {
        // Should be an admin of given role
        if(!hasRole(getRoleAdmin(role), account) && !hasRole(DEFAULT_ADMIN_ROLE, account))
        {
            revert AccessControl_MissingRole(account, getRoleAdmin(role));
        }
    }
    /**
     * @dev Prevent from emptying DEFAULT_ADMIN_ROLE. 
     */
    function _revokeRole(bytes32 role, address account) internal virtual override
    {
        super._revokeRole(role, account);
        // Cannot empty default admin role
        if(role == DEFAULT_ADMIN_ROLE && getRoleMemberCount(role) == 0)
        {
            revert AccessControl_EmptyRole();
        }
    }
    /**
     * @dev Sets `adminRole` as `role`'s admin role. Revert with AccessControl_NoMoreAdminRole if it somehow implies NO_MORE_ADMIN_ROLE
     * or with AccessControl_MissingRole error if message sender is missing current `role`'s admin role or DEFAULT_ADMIN_ROLE
     */
    function setRoleAdmin(bytes32 role, bytes32 adminRole) public
    {
        // NO_MORE_ADMIN_ROLE should not be implied in any way. No need to also directly test role or adminRole as if equals
        // to NO_MORE_ADMIN_ROLE, their admin role would also be NO_MORE_ADMIN_ROLE
        if(isRoleBlocked(role) || isRoleBlocked(adminRole))
        {
            revert AccessControl_NoMoreAdminRole();
        }
        // Should be an admin to define new admin role
        _checkRoleAdmin(role, _msgSender());
        _setRoleAdmin(role, adminRole);
    }
    /**
     * @dev This method should be used to forever block a role from any more update (role granting or revoking or admin role update)
     * @param role Role to be forever blocked
     */
    function blockRole(bytes32 role) public
    {
        // NO_MORE_ADMIN_ROLE is already applied
        if(isRoleBlocked(role)) return;
        // Should be an admin to block a role
        _checkRoleAdmin(role, _msgSender());
        // Define non manageable new admin role to block given role from any new administration (granting/revoking roles or defining a
        // new admin role)
        _setRoleAdmin(role, NO_MORE_ADMIN_ROLE);
    }
    /**
     * @dev This method should be used to forever "burn" a role from any more update (role granting or revoking or admin role update).
     * A burnt role is a blocked role without any user granted to it
     * @param role Role to be forever burnt
     */
    function burnRole(bytes32 role) public
    {
        // Role should be empty to be considered burnt
        if(getRoleMemberCount(role) != 0)
        {
            revert AccessControl_NotEmptyRole();
        }
        blockRole(role);
    }
}

/**
 * @dev Default implementation to use when contract should be pausable (role based access control is then requested in order
 * to grant access to pause/unpause actions). It extends openzeppelin implementation in order to define publicly accessible
 * and role protected pause/unpause methods
 */
abstract contract PausableImpl is AccessControlImpl, Pausable
{
    /** Role definition necessary to be able to pause contract */
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Default constructor
     */
    constructor() {}

    /**
     * @dev Pause the contract if message sender has PAUSER_ROLE role. Action protected with whenNotPaused() or with
     * _requireNotPaused() will not be available anymore until contract is unpaused again
     */
    function pause() public onlyRole(PAUSER_ROLE)
    {
        _pause();
    }
    /**
     * @dev Unpause the contract if message sender has PAUSER_ROLE role. Action protected with whenPaused() or with
     * _requirePaused() will not be available anymore until contract is paused again
     */
    function unpause() public onlyRole(PAUSER_ROLE)
    {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    /**
     * @notice Returns true if operator is not filtered for a given token, either by address or codeHash. Also returns
     *         true if supplied registrant address is not registered.
     */
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);

    /**
     * @notice Registers an address with the registry. May be called by address itself or by EIP-173 owner.
     */
    function register(address registrant) external;

    /**
     * @notice Registers an address with the registry and "subscribes" to another address's filtered operators and codeHashes.
     */
    function registerAndSubscribe(address registrant, address subscription) external;

    /**
     * @notice Registers an address with the registry and copies the filtered operators and codeHashes from another
     *         address without subscribing.
     */
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;

    /**
     * @notice Unregisters an address with the registry and removes its subscription. May be called by address itself or by EIP-173 owner.
     *         Note that this does not remove any filtered addresses or codeHashes.
     *         Also note that any subscriptions to this registrant will still be active and follow the existing filtered addresses and codehashes.
     */
    function unregister(address addr) external;

    /**
     * @notice Update an operator address for a registered address - when filtered is true, the operator is filtered.
     */
    function updateOperator(address registrant, address operator, bool filtered) external;

    /**
     * @notice Update multiple operators for a registered address - when filtered is true, the operators will be filtered. Reverts on duplicates.
     */
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;

    /**
     * @notice Update a codeHash for a registered address - when filtered is true, the codeHash is filtered.
     */
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;

    /**
     * @notice Update multiple codeHashes for a registered address - when filtered is true, the codeHashes will be filtered. Reverts on duplicates.
     */
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;

    /**
     * @notice Subscribe an address to another registrant's filtered operators and codeHashes. Will remove previous
     *         subscription if present.
     *         Note that accounts with subscriptions may go on to subscribe to other accounts - in this case,
     *         subscriptions will not be forwarded. Instead the former subscription's existing entries will still be
     *         used.
     */
    function subscribe(address registrant, address registrantToSubscribe) external;

    /**
     * @notice Unsubscribe an address from its current subscribed registrant, and optionally copy its filtered operators and codeHashes.
     */
    function unsubscribe(address registrant, bool copyExistingEntries) external;

    /**
     * @notice Get the subscription address of a given registrant, if any.
     */
    function subscriptionOf(address addr) external returns (address registrant);

    /**
     * @notice Get the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscribers(address registrant) external returns (address[] memory);

    /**
     * @notice Get the subscriber at a given index in the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscriberAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Copy filtered operators and codeHashes from a different registrantToCopy to addr.
     */
    function copyEntriesOf(address registrant, address registrantToCopy) external;

    /**
     * @notice Returns true if operator is filtered by a given address or its subscription.
     */
    function isOperatorFiltered(address registrant, address operator) external returns (bool);

    /**
     * @notice Returns true if the hash of an address's code is filtered by a given address or its subscription.
     */
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);

    /**
     * @notice Returns true if a codeHash is filtered by a given address or its subscription.
     */
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);

    /**
     * @notice Returns a list of filtered operators for a given address or its subscription.
     */
    function filteredOperators(address addr) external returns (address[] memory);

    /**
     * @notice Returns the set of filtered codeHashes for a given address or its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);

    /**
     * @notice Returns the filtered operator at the given index of the set of filtered operators for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Returns the filtered codeHash at the given index of the list of filtered codeHashes for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);

    /**
     * @notice Returns true if an address has registered
     */
    function isRegistered(address addr) external returns (bool);

    /**
     * @dev Convenience method to compute the code hash of an arbitrary contract
     */
    function codeHashOf(address addr) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

address constant CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS = 0x000000000000AAeB6D7670E522A718067333cd4E;
address constant CANONICAL_CORI_SUBSCRIPTION = 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";

/**
 * @title  UpdatableOperatorFilterer
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry. This contract allows the Owner to update the
 *         OperatorFilterRegistry address via updateOperatorFilterRegistryAddress, including to the zero address,
 *         which will bypass registry checks.
 *         Note that OpenSea will still disable creator earnings enforcement if filtered operators begin fulfilling orders
 *         on-chain, eg, if the registry is revoked or bypassed.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 */
abstract contract UpdatableOperatorFilterer {
    /// @dev Emitted when an operator is not allowed.
    error OperatorNotAllowed(address operator);
    /// @dev Emitted when someone other than the owner is trying to call an only owner function.
    error OnlyOwner();

    event OperatorFilterRegistryAddressUpdated(address newRegistry);

    IOperatorFilterRegistry public operatorFilterRegistry;

    /// @dev The constructor that is called when the contract is being deployed.
    constructor(address _registry, address subscriptionOrRegistrantToCopy, bool subscribe) {
        IOperatorFilterRegistry registry = IOperatorFilterRegistry(_registry);
        operatorFilterRegistry = registry;
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(registry).code.length > 0) {
            if (subscribe) {
                registry.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    registry.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    registry.register(address(this));
                }
            }
        }
    }

    /**
     * @dev A helper function to check if the operator is allowed.
     */
    modifier onlyAllowedOperator(address from) virtual {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    /**
     * @dev A helper function to check if the operator approval is allowed.
     */
    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    /**
     * @notice Update the address that the contract will make OperatorFilter checks against. When set to the zero
     *         address, checks will be bypassed. OnlyOwner.
     */
    function updateOperatorFilterRegistryAddress(address newRegistry) public virtual {
        if (msg.sender != owner()) {
            revert OnlyOwner();
        }
        operatorFilterRegistry = IOperatorFilterRegistry(newRegistry);
        emit OperatorFilterRegistryAddressUpdated(newRegistry);
    }

    /**
     * @dev Assume the contract has an owner, but leave specific Ownable implementation up to inheriting contract.
     */
    function owner() public view virtual returns (address);

    /**
     * @dev A helper function to check if the operator is allowed.
     */
    function _checkFilterOperator(address operator) internal view virtual {
        IOperatorFilterRegistry registry = operatorFilterRegistry;
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(registry) != address(0) && address(registry).code.length > 0) {
            // under normal circumstances, this function will revert rather than return false, but inheriting contracts
            // may specify their own OperatorFilterRegistry implementations, which may behave differently
            if (!registry.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}