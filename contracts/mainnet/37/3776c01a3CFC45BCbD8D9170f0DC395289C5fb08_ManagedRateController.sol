//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

/**
 * @title IPeriodic
 * @notice An interface that defines a contract containing a period.
 * @dev This typically refers to an update period.
 */
interface IPeriodic {
    /// @notice Gets the period, in seconds.
    /// @return periodSeconds The period, in seconds.
    function period() external view returns (uint256 periodSeconds);

    // @notice Gets the number of observations made every period.
    // @return granularity The number of observations made every period.
    function granularity() external view returns (uint256 granularity);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

/// @title IUpdateByToken
/// @notice An interface that defines a contract that is updateable as per the input data.
abstract contract IUpdateable {
    /// @notice Performs an update as per the input data.
    /// @param data Any data needed for the update.
    /// @return b True if anything was updated; false otherwise.
    function update(bytes memory data) public virtual returns (bool b);

    /// @notice Checks if an update needs to be performed.
    /// @param data Any data relating to the update.
    /// @return b True if an update needs to be performed; false otherwise.
    function needsUpdate(bytes memory data) public view virtual returns (bool b);

    /// @notice Check if an update can be performed by the caller (if needed).
    /// @dev Tries to determine if the caller can call update with a valid observation being stored.
    /// @dev This is not meant to be called by state-modifying functions.
    /// @param data Any data relating to the update.
    /// @return b True if an update can be performed by the caller; false otherwise.
    function canUpdate(bytes memory data) public view virtual returns (bool b);

    /// @notice Gets the timestamp of the last update.
    /// @param data Any data relating to the update.
    /// @return A unix timestamp.
    function lastUpdateTime(bytes memory data) public view virtual returns (uint256);

    /// @notice Gets the amount of time (in seconds) since the last update.
    /// @param data Any data relating to the update.
    /// @return Time in seconds.
    function timeSinceLastUpdate(bytes memory data) public view virtual returns (uint256);
}

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
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
pragma solidity >=0.5.0 <0.9.0;

library Roles {
    bytes32 public constant ADMIN = keccak256("ADMIN_ROLE");

    bytes32 public constant UPDATER_ADMIN = keccak256("UPDATER_ADMIN_ROLE");

    bytes32 public constant ORACLE_UPDATER = keccak256("ORACLE_UPDATER_ROLE");

    bytes32 public constant RATE_ADMIN = keccak256("RATE_ADMIN_ROLE");

    bytes32 public constant UPDATE_PAUSE_ADMIN = keccak256("UPDATE_PAUSE_ADMIN_ROLE");

    bytes32 public constant CONFIG_ADMIN = keccak256("CONFIG_ADMIN_ROLE");
}

//SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "./IHistoricalRates.sol";

/**
 * @title HistoricalRates
 * @notice The HistoricalRates contract is an abstract contract designed to store historical rate data for various
 * tokens on the blockchain. It provides functionalities for initializing, updating, and querying historical rate
 * data in a circular buffer with a fixed capacity.
 * @dev This contract implements the IHistoricalRates interface and maintains a mapping of tokens to their respective
 * rate buffers and metadata. Each rate buffer holds an array of Rate structs containing target rate, current rate, and
 * timestamp data. The metadata includes information about the buffer's start, end, size, maximum size, and a pause
 * flag, which can be used to pause updates in extended contracts.
 */
abstract contract HistoricalRates is IHistoricalRates {
    struct BufferMetadata {
        uint8 start;
        uint8 end;
        uint8 size;
        uint8 maxSize;
        bool pauseUpdates; // Note: this is left for extentions, but is not used in this contract.
    }

    /// @notice Event emitted when a rate buffer's capacity is increased past the initial capacity.
    /// @dev Buffer initialization does not emit an event.
    /// @param token The token for which the rate buffer's capacity was increased.
    /// @param oldCapacity The previous capacity of the rate buffer.
    /// @param newCapacity The new capacity of the rate buffer.
    event RatesCapacityIncreased(address indexed token, uint256 oldCapacity, uint256 newCapacity);

    /// @notice Event emitted when a rate buffer's capacity is initialized.
    /// @param token The token for which the rate buffer's capacity was initialized.
    /// @param capacity The capacity of the rate buffer.
    event RatesCapacityInitialized(address indexed token, uint256 capacity);

    /// @notice Event emitted when a new rate is pushed to the rate buffer.
    /// @param token The token for which the rate was pushed.
    /// @param target The target rate.
    /// @param current The current rate, which may be different from the target rate if the rate change is capped.
    /// @param timestamp The timestamp at which the rate was pushed.
    event RateUpdated(address indexed token, uint256 target, uint256 current, uint256 timestamp);

    /// @notice An error that is thrown if we try to initialize a rate buffer that has already been initialized.
    /// @param token The token for which we tried to initialize the rate buffer.
    error BufferAlreadyInitialized(address token);

    /// @notice An error that is thrown if we try to retrieve a rate at an invalid index.
    /// @param token The token for which we tried to retrieve the rate.
    /// @param index The index of the rate that we tried to retrieve.
    /// @param size The size of the rate buffer.
    error InvalidIndex(address token, uint256 index, uint256 size);

    /// @notice An error that is thrown if we try to decrease the capacity of a rate buffer.
    /// @param token The token for which we tried to decrease the capacity of the rate buffer.
    /// @param amount The capacity that we tried to decrease the rate buffer to.
    /// @param currentCapacity The current capacity of the rate buffer.
    error CapacityCannotBeDecreased(address token, uint256 amount, uint256 currentCapacity);

    /// @notice An error that is thrown if we try to increase the capacity of a rate buffer past the maximum capacity.
    /// @param token The token for which we tried to increase the capacity of the rate buffer.
    /// @param amount The capacity that we tried to increase the rate buffer to.
    /// @param maxCapacity The maximum capacity of the rate buffer.
    error CapacityTooLarge(address token, uint256 amount, uint256 maxCapacity);

    /// @notice An error that is thrown if we try to retrieve more rates than are available in the rate buffer.
    /// @param token The token for which we tried to retrieve the rates.
    /// @param size The size of the rate buffer.
    /// @param minSizeRequired The minimum size of the rate buffer that we require.
    error InsufficientData(address token, uint256 size, uint256 minSizeRequired);

    /// @notice The initial capacity of the rate buffer.
    uint8 internal immutable initialBufferCardinality;

    /// @notice Maps a token to its metadata.
    mapping(address => BufferMetadata) internal rateBufferMetadata;

    /// @notice Maps a token to a buffer of rates.
    mapping(address => RateLibrary.Rate[]) internal rateBuffers;

    /**
     * @notice Constructs the HistoricalRates contract with a specified initial buffer capacity.
     * @param initialBufferCardinality_ The initial capacity of the rate buffer.
     */
    constructor(uint8 initialBufferCardinality_) {
        initialBufferCardinality = initialBufferCardinality_;
    }

    /// @inheritdoc IHistoricalRates
    function getRateAt(address token, uint256 index) external view virtual override returns (RateLibrary.Rate memory) {
        BufferMetadata memory meta = rateBufferMetadata[token];

        if (index >= meta.size) {
            revert InvalidIndex(token, index, meta.size);
        }

        uint256 bufferIndex = meta.end < index ? meta.end + meta.size - index : meta.end - index;

        return rateBuffers[token][bufferIndex];
    }

    /// @inheritdoc IHistoricalRates
    function getRates(
        address token,
        uint256 amount
    ) external view virtual override returns (RateLibrary.Rate[] memory) {
        return _getRates(token, amount, 0, 1);
    }

    /// @inheritdoc IHistoricalRates
    function getRates(
        address token,
        uint256 amount,
        uint256 offset,
        uint256 increment
    ) external view virtual override returns (RateLibrary.Rate[] memory) {
        return _getRates(token, amount, offset, increment);
    }

    /// @inheritdoc IHistoricalRates
    function getRatesCount(address token) external view override returns (uint256) {
        return rateBufferMetadata[token].size;
    }

    /// @inheritdoc IHistoricalRates
    function getRatesCapacity(address token) external view virtual override returns (uint256) {
        uint256 maxSize = rateBufferMetadata[token].maxSize;
        if (maxSize == 0) return initialBufferCardinality;

        return maxSize;
    }

    /// @param amount The new capacity of rates for the token. Must be greater than the current capacity, but
    ///   less than 256.
    /// @inheritdoc IHistoricalRates
    function setRatesCapacity(address token, uint256 amount) external virtual {
        _setRatesCapacity(token, amount);
    }

    /**
     * @dev Internal function to set the capacity of the rate buffer for a token.
     * @param token The token for which to set the new capacity.
     * @param amount The new capacity of rates for the token. Must be greater than the current capacity, but
     * less than 256.
     */
    function _setRatesCapacity(address token, uint256 amount) internal virtual {
        BufferMetadata storage meta = rateBufferMetadata[token];

        if (amount < meta.maxSize) revert CapacityCannotBeDecreased(token, amount, meta.maxSize);
        if (amount > type(uint8).max) revert CapacityTooLarge(token, amount, type(uint8).max);

        RateLibrary.Rate[] storage rateBuffer = rateBuffers[token];

        // Add new slots to the buffer
        uint256 capacityToAdd = amount - meta.maxSize;
        for (uint256 i = 0; i < capacityToAdd; ++i) {
            // Push a dummy rate with non-zero values to put most of the gas cost on the caller
            rateBuffer.push(RateLibrary.Rate({target: 1, current: 1, timestamp: 1}));
        }

        if (meta.maxSize != amount) {
            emit RatesCapacityIncreased(token, meta.maxSize, amount);

            // Update the metadata
            meta.maxSize = uint8(amount);
        }
    }

    /**
     * @dev Internal function to get historical rates with specified amount, offset, and increment.
     * @param token The token for which to retrieve the rates.
     * @param amount The number of historical rates to retrieve.
     * @param offset The number of rates to skip before starting to collect the rates.
     * @param increment The step size between the rates to collect.
     * @return observations An array of Rate structs containing the retrieved historical rates.
     */
    function _getRates(
        address token,
        uint256 amount,
        uint256 offset,
        uint256 increment
    ) internal view virtual returns (RateLibrary.Rate[] memory) {
        if (amount == 0) return new RateLibrary.Rate[](0);

        BufferMetadata memory meta = rateBufferMetadata[token];
        if (meta.size <= (amount - 1) * increment + offset)
            revert InsufficientData(token, meta.size, (amount - 1) * increment + offset + 1);

        RateLibrary.Rate[] memory observations = new RateLibrary.Rate[](amount);

        uint256 count = 0;

        for (
            uint256 i = meta.end < offset ? meta.end + meta.size - offset : meta.end - offset;
            count < amount;
            i = (i < increment) ? (i + meta.size) - increment : i - increment
        ) {
            observations[count++] = rateBuffers[token][i];
        }

        return observations;
    }

    /**
     * @dev Internal function to initialize rate buffers for a token.
     * @param token The token for which to initialize the rate buffer.
     */
    function initializeBuffers(address token) internal virtual {
        if (rateBuffers[token].length != 0) {
            revert BufferAlreadyInitialized(token);
        }

        BufferMetadata storage meta = rateBufferMetadata[token];

        // Initialize the buffers
        RateLibrary.Rate[] storage observationBuffer = rateBuffers[token];

        for (uint256 i = 0; i < initialBufferCardinality; ++i) {
            observationBuffer.push();
        }

        // Initialize the metadata
        meta.start = 0;
        meta.end = 0;
        meta.size = 0;
        meta.maxSize = initialBufferCardinality;
        meta.pauseUpdates = false;

        emit RatesCapacityInitialized(token, meta.maxSize);
    }

    /**
     * @dev Internal function to push a new rate data into the rate buffer and update metadata accordingly.
     * @param token The token for which to push the new rate data.
     * @param rate The Rate struct containing target rate, current rate, and timestamp data to be pushed.
     */
    function push(address token, RateLibrary.Rate memory rate) internal virtual {
        BufferMetadata storage meta = rateBufferMetadata[token];

        if (meta.size == 0) {
            if (meta.maxSize == 0) {
                // Initialize the buffers
                initializeBuffers(token);
            }
        } else {
            meta.end = (meta.end + 1) % meta.maxSize;
        }

        rateBuffers[token][meta.end] = rate;

        emit RateUpdated(token, rate.target, rate.current, block.timestamp);

        if (meta.size < meta.maxSize && meta.end == meta.size) {
            // We are at the end of the array and we have not yet filled it
            meta.size++;
        } else {
            // start was just overwritten
            meta.start = (meta.start + 1) % meta.size;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "./RateLibrary.sol";

/**
 * @title IHistoricalRates
 * @notice An interface that defines a contract that stores historical rates.
 */
interface IHistoricalRates {
    /// @notice Gets an rate for a token at a specific index.
    /// @param token The address of the token to get the rates for.
    /// @param index The index of the rate to get, where index 0 contains the latest rate, and the last
    ///   index contains the oldest rate (uses reverse chronological ordering).
    /// @return rate The rate for the token at the specified index.
    function getRateAt(address token, uint256 index) external view returns (RateLibrary.Rate memory);

    /// @notice Gets the latest rates for a token.
    /// @param token The address of the token to get the rates for.
    /// @param amount The number of rates to get.
    /// @return rates The latest rates for the token, in reverse chronological order, from newest to oldest.
    function getRates(address token, uint256 amount) external view returns (RateLibrary.Rate[] memory);

    /// @notice Gets the latest rates for a token.
    /// @param token The address of the token to get the rates for.
    /// @param amount The number of rates to get.
    /// @param offset The index of the first rate to get (default: 0).
    /// @param increment The increment between rates to get (default: 1).
    /// @return rates The latest rates for the token, in reverse chronological order, from newest to oldest.
    function getRates(
        address token,
        uint256 amount,
        uint256 offset,
        uint256 increment
    ) external view returns (RateLibrary.Rate[] memory);

    /// @notice Gets the number of rates for a token.
    /// @param token The address of the token to get the number of rates for.
    /// @return count The number of rates for the token.
    function getRatesCount(address token) external view returns (uint256);

    /// @notice Gets the capacity of rates for a token.
    /// @param token The address of the token to get the capacity of rates for.
    /// @return capacity The capacity of rates for the token.
    function getRatesCapacity(address token) external view returns (uint256);

    /// @notice Sets the capacity of rates for a token.
    /// @param token The address of the token to set the capacity of rates for.
    /// @param amount The new capacity of rates for the token.
    function setRatesCapacity(address token, uint256 amount) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

/**
 * @title IRateComputer
 * @notice An interface that defines a contract that computes rates.
 */
interface IRateComputer {
    /// @notice Computes the rate for a token.
    /// @param token The address of the token to compute the rate for.
    /// @return rate The rate for the token.
    function computeRate(address token) external view returns (uint64);
}

//SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "@openzeppelin-v4/contracts/access/AccessControlEnumerable.sol";

import "./RateController.sol";
import "../access/Roles.sol";

/**
 * @title ManagedRateController
 * @notice A smart contract that extends RateController and AccessControlEnumerable to manage and update rates with
 * access control restrictions based on roles.
 */
contract ManagedRateController is RateController, AccessControlEnumerable {
    /// @notice An error that is thrown if we're missing a required role.
    /// @dev A different error is thrown when using the `onlyRole` modifier.
    /// @param requiredRole The role (hash) that we're missing.
    error MissingRole(bytes32 requiredRole);

    /**
     * @notice Modifier to make a function callable only by a certain role. In
     * addition to checking the sender's role, `address(0)` 's role is also
     * considered. Granting a role to `address(0)` is equivalent to enabling
     * this role for everyone.
     */
    modifier onlyRoleOrOpenRole(bytes32 role) {
        if (!hasRole(role, address(0)) && !hasRole(role, msg.sender)) {
            revert MissingRole(role);
        }
        _;
    }

    /**
     * @notice Constructs the ManagedRateController contract.
     * @param period_ The period for the rate controller.
     * @param initialBufferCardinality_ The initial buffer cardinality for the rate controller.
     * @param updatersMustBeEoa_ A flag indicating if updaters must be externally owned accounts.
     */
    constructor(
        uint32 period_,
        uint8 initialBufferCardinality_,
        bool updatersMustBeEoa_
    ) RateController(period_, initialBufferCardinality_, updatersMustBeEoa_) {
        initializeRoles();
    }

    /**
     * @notice Checks if the sender can update the rates.
     * @param data The data containing the token address.
     * @return b A boolean indicating if the sender is allowed to update the rates, provided that the conditions in the
     * parent contract are also met.
     */
    function canUpdate(bytes memory data) public view virtual override returns (bool b) {
        return
            // Can only update if the sender is an oracle updater or the oracle updater role is open
            (hasRole(Roles.ORACLE_UPDATER, address(0)) || hasRole(Roles.ORACLE_UPDATER, msg.sender)) &&
            super.canUpdate(data);
    }

    /// @inheritdoc IERC165
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(AccessControlEnumerable, RateController) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// @notice Requires the sender to have the RATE_ADMIN role to call setConfig.
    function checkSetConfig() internal view virtual override onlyRole(Roles.RATE_ADMIN) {}

    /// @notice Requires the sender to have the RATE_ADMIN role to call manuallyPushRate.
    function checkManuallyPushRate() internal view virtual override onlyRole(Roles.ADMIN) {}

    /// @notice Requires the sender to have the UPDATE_PAUSE_ADMIN role to call setUpdatesPaused.
    function checkSetUpdatesPaused() internal view virtual override onlyRole(Roles.UPDATE_PAUSE_ADMIN) {}

    /// @notice Requires the sender to have the ADMIN role to call setRatesCapacity.
    function checkSetRatesCapacity() internal view virtual override onlyRole(Roles.ADMIN) {}

    /// @notice Requires the sender to have the ORACLE_UPDATER role to call update.
    function checkUpdate() internal view virtual override onlyRoleOrOpenRole(Roles.ORACLE_UPDATER) {}

    /// @notice Initializes the roles hierarchy.
    function initializeRoles() internal virtual {
        // Setup admin role, setting msg.sender as admin
        _setupRole(Roles.ADMIN, msg.sender);
        _setRoleAdmin(Roles.ADMIN, Roles.ADMIN);

        // Set admin of RATE_ADMIN as ADMIN
        _setRoleAdmin(Roles.RATE_ADMIN, Roles.ADMIN);

        // Set admin of UPDATE_PAUSE_ADMIN as ADMIN
        _setRoleAdmin(Roles.UPDATE_PAUSE_ADMIN, Roles.ADMIN);

        // Set admin of UPDATER_ADMIN as ADMIN
        _setRoleAdmin(Roles.UPDATER_ADMIN, Roles.ADMIN);

        // Set admin of ORACLE_UPDATER as UPDATER_ADMIN
        _setRoleAdmin(Roles.ORACLE_UPDATER, Roles.UPDATER_ADMIN);

        // Hierarchy:
        // ADMIN
        //   - RATE_ADMIN
        //   - UPDATER_ADMIN
        //     - ORACLE_UPDATER
        //   - UPDATE_PAUSE_ADMIN
    }
}

//SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "@adrastia-oracle/adrastia-core/contracts/interfaces/IPeriodic.sol";
import "@adrastia-oracle/adrastia-core/contracts/interfaces/IUpdateable.sol";

import "@openzeppelin-v4/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin-v4/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin-v4/contracts/utils/math/SafeCast.sol";

import "./HistoricalRates.sol";
import "./IRateComputer.sol";

/// @title RateController
/// @notice A contract that periodically computes and stores rates for tokens.
/// @dev This contract is abstract because it lacks restrictions on sensitive functions. Please override checkSetConfig,
/// checkSetUpdatesPaused, checkSetRatesCapacity, and checkUpdate to add restrictions.
abstract contract RateController is ERC165, HistoricalRates, IRateComputer, IUpdateable, IPeriodic {
    using SafeCast for uint256;

    struct RateConfig {
        uint64 max;
        uint64 min;
        uint64 maxIncrease;
        uint64 maxDecrease;
        uint32 maxPercentIncrease; // 10000 = 100%
        uint16 maxPercentDecrease; // 10000 = 100%
        uint64 base;
        uint16[] componentWeights; // 10000 = 100%
        IRateComputer[] components;
    }

    /// @notice The period of the rate controller, in seconds. This is the frequency at which rates are updated.
    uint256 public immutable override period;

    /// @notice True if all rate updaters must be EOA accounts; false otherwise.
    /// @dev This is a security feature to prevent malicious contracts from updating rates.
    bool public immutable updatersMustBeEoa;

    /// @notice Maps a token to its rate configuration.
    mapping(address => RateConfig) internal rateConfigs;

    /// @notice Event emitted when a new rate is manually pushed to the rate buffer.
    /// @param token The token for which the rate was pushed.
    /// @param target The target rate.
    /// @param current The effective rate.
    /// @param timestamp The timestamp at which the rate was pushed.
    /// @param amount The amount of times the rate was pushed.
    event RatePushedManually(address indexed token, uint256 target, uint256 current, uint256 timestamp, uint256 amount);

    /// @notice Event emitted when the pause status of rate updates for a token is changed.
    /// @param token The token for which the pause status of rate updates was changed.
    /// @param areUpdatesPaused Whether rate updates are paused for the token.
    event PauseStatusChanged(address indexed token, bool areUpdatesPaused);

    /// @notice Event emitted when the rate configuration for a token is updated.
    /// @param token The token for which the rate configuration was updated.
    event RateConfigUpdated(address indexed token, RateConfig oldConfig, RateConfig newConfig);

    /// @notice An error that is thrown if we try to set a rate configuration with invalid parameters.
    /// @param token The token for which we tried to set the rate configuration.
    error InvalidConfig(address token);

    /// @notice An error that is thrown if we require a rate configuration that has not been set.
    /// @param token The token for which we require a rate configuration.
    error MissingConfig(address token);

    /// @notice An error that is thrown if we require that all rate updaters be EOA accounts, but the updater is not.
    /// @param txOrigin The address of the transaction origin.
    /// @param updater The address of the rate updater.
    error UpdaterMustBeEoa(address txOrigin, address updater);

    /// @notice Creates a new rate controller.
    /// @param period_ The period of the rate controller, in seconds. This is the frequency at which rates are updated.
    /// @param initialBufferCardinality_ The initial capacity of the rate buffer.
    /// @param updatersMustBeEoa_ True if all rate updaters must be EOA accounts; false otherwise.
    constructor(
        uint32 period_,
        uint8 initialBufferCardinality_,
        bool updatersMustBeEoa_
    ) HistoricalRates(initialBufferCardinality_) {
        period = period_;
        updatersMustBeEoa = updatersMustBeEoa_;
    }

    /// @notice Returns the rate configuration for a token.
    /// @param token The token for which to get the rate configuration.
    /// @return The rate configuration for the token.
    function getConfig(address token) external view virtual returns (RateConfig memory) {
        BufferMetadata memory meta = rateBufferMetadata[token];
        if (meta.maxSize == 0) {
            revert MissingConfig(token);
        }

        return rateConfigs[token];
    }

    /// @notice Sets the rate configuration for a token. This can only be called by the rate admin.
    /// @param token The token for which to set the rate configuration.
    /// @param config The rate configuration to set.
    function setConfig(address token, RateConfig calldata config) external virtual {
        checkSetConfig();

        if (config.components.length != config.componentWeights.length) {
            revert InvalidConfig(token);
        }

        if (config.maxPercentDecrease > 10000) {
            // The maximum percent decrease must be less than or equal to 100%.
            revert InvalidConfig(token);
        }

        if (config.max < config.min) {
            // The maximum rate must be greater than or equal to the minimum rate.
            revert InvalidConfig(token);
        }

        // Ensure that the sum of the component weights less than or equal to 10000 (100%)
        // Notice: It's possible to have the sum of the component weights be less than 10000 (100%). It's also possible
        // to have the component weights be 100% and the base rate be non-zero. This is intentional because we don't
        // have a hard cap on the rate.
        uint256 sum = 0;
        for (uint256 i = 0; i < config.componentWeights.length; ++i) {
            if (
                address(config.components[i]) == address(0) ||
                !ERC165Checker.supportsInterface(address(config.components[i]), type(IRateComputer).interfaceId)
            ) {
                revert InvalidConfig(token);
            }

            sum += config.componentWeights[i];
        }
        if (sum > 10000) {
            revert InvalidConfig(token);
        }

        // Ensure that the base rate plus the sum of the maximum component rates won't overflow
        if (uint256(config.base) + ((sum * type(uint64).max) / 10000) > type(uint64).max) {
            revert InvalidConfig(token);
        }

        RateConfig memory oldConfig = rateConfigs[token];

        rateConfigs[token] = config;

        emit RateConfigUpdated(token, oldConfig, config);

        BufferMetadata memory meta = rateBufferMetadata[token];
        if (meta.maxSize == 0) {
            // We require that the buffer is initialized before allowing rate updates to occur
            initializeBuffers(token);
        }
    }

    /// @notice Manually pushes new rates for a token, bypassing the update logic, clamp logic, pause logic, and
    /// other restrictions.
    /// @dev WARNING: This function is very powerful and should only be used in emergencies. It is intended to be used
    /// to manually push rates when the rate controller is in a bad state. It should not be used to push rates
    /// regularly. Make sure to lock it down with the highest level of security.
    /// @param token The token for which to push rates.
    /// @param target The target rate to push.
    /// @param current The current rate to push.
    /// @param amount The number of times to push the rate.
    function manuallyPushRate(address token, uint64 target, uint64 current, uint256 amount) external {
        checkManuallyPushRate();

        BufferMetadata storage meta = rateBufferMetadata[token];
        if (meta.maxSize == 0) {
            // Uninitialized buffer means that the rate config is missing
            revert MissingConfig(token);
        }

        // Note: We don't check the pause status here because we want to allow rate updates to be manually pushed even
        // if rate updates are paused.

        RateLibrary.Rate memory rate = RateLibrary.Rate({
            target: target,
            current: current,
            timestamp: uint32(block.timestamp)
        });

        for (uint256 i = 0; i < amount; ++i) {
            push(token, rate);
        }

        if (amount > 0) {
            emit RatePushedManually(token, target, current, block.timestamp, amount);
        }
    }

    /// @notice Determines whether rate updates are paused for a token.
    /// @param token The token for which to determine whether rate updates are paused.
    /// @return Whether rate updates are paused for the given token.
    function areUpdatesPaused(address token) external view virtual returns (bool) {
        return rateBufferMetadata[token].pauseUpdates;
    }

    /// @notice Changes the pause state of rate updates for a token. This can only be called by the update pause admin.
    /// @param token The token for which to change the pause state.
    /// @param paused Whether rate updates should be paused.
    function setUpdatesPaused(address token, bool paused) external virtual {
        checkSetUpdatesPaused();

        BufferMetadata storage meta = rateBufferMetadata[token];
        if (meta.maxSize == 0) {
            // Uninitialized buffer means that the rate config is missing
            // It doesn't make sense to pause updates if they can't occur in the first place
            // Plus, buffer initialization sets the pause state to false, so setting it beforehand can cause confusion
            revert MissingConfig(token);
        }

        if (meta.pauseUpdates != paused) {
            meta.pauseUpdates = paused;

            emit PauseStatusChanged(token, paused);
        }
    }

    /// @inheritdoc IRateComputer
    function computeRate(address token) external view virtual override returns (uint64) {
        return computeRateInternal(token);
    }

    /// @inheritdoc IPeriodic
    function granularity() external view virtual override returns (uint256) {
        return 1;
    }

    /// @inheritdoc IUpdateable
    function update(bytes memory data) public virtual override returns (bool b) {
        checkUpdate();

        if (needsUpdate(data)) return performUpdate(data);

        return false;
    }

    /// @inheritdoc IUpdateable
    function needsUpdate(bytes memory data) public view virtual override returns (bool b) {
        address token = abi.decode(data, (address));

        BufferMetadata memory meta = rateBufferMetadata[token];

        // Requires that:
        //   0. The update period has elapsed.
        //   1. The buffer is initialized. We do this to prevent zero values from being pushed to the buffer.
        //   2. Updates are not paused.
        //   3. Something will change. Otherwise, updating is a waste of gas.
        return
            timeSinceLastUpdate(data) >= period && meta.maxSize > 0 && !meta.pauseUpdates && willAnythingChange(data);
    }

    /// @inheritdoc IUpdateable
    function canUpdate(bytes memory data) public view virtual override returns (bool b) {
        return
            // Can only update if the update is needed
            needsUpdate(data) &&
            // Can only update if the sender is an EOA or the contract allows EOA updates
            (!updatersMustBeEoa || msg.sender == tx.origin);
    }

    /// @inheritdoc IUpdateable
    function lastUpdateTime(bytes memory data) public view virtual override returns (uint256) {
        address token = abi.decode(data, (address));

        return getLatestRate(token).timestamp;
    }

    /// @inheritdoc IUpdateable
    function timeSinceLastUpdate(bytes memory data) public view virtual override returns (uint256) {
        return block.timestamp - lastUpdateTime(data);
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IHistoricalRates).interfaceId ||
            interfaceId == type(IRateComputer).interfaceId ||
            interfaceId == type(IUpdateable).interfaceId ||
            interfaceId == type(IPeriodic).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Internal function to set the capacity of the rate buffer for a token. Only callable by the admin because the
     * updating logic is O(n) on the capacity. Only callable when the rate config is set.
     * @param token The token for which to set the new capacity.
     * @param amount The new capacity of rates for the token. Must be greater than the current capacity, but
     * less than 256.
     */
    function _setRatesCapacity(address token, uint256 amount) internal virtual override {
        checkSetRatesCapacity();

        BufferMetadata storage meta = rateBufferMetadata[token];
        if (meta.maxSize == 0) {
            // Buffer is not initialized yet
            // Buffer can only be initialized when the rate config is set
            revert MissingConfig(token);
        }

        super._setRatesCapacity(token, amount);
    }

    /// @notice Determines if any changes will occur in the rate buffer after a new rate is added.
    /// @dev This function is used to reduce the amount of gas used by updaters when the rate is not changing.
    /// @param data A bytes array containing the token address to be decoded.
    /// @return bool A boolean value indicating whether any changes will occur in the rate buffer.
    function willAnythingChange(bytes memory data) internal view virtual returns (bool) {
        address token = abi.decode(data, (address));

        BufferMetadata memory meta = rateBufferMetadata[token];

        // If the buffer has empty slots, they can be filled
        if (meta.size != meta.maxSize) return true;

        // All current rates in the buffer should match the next rate. Otherwise, the rate will change.
        // We don't check target rates because if the rate is capped, the current rate may never reach the target rate.
        (, uint64 nextRate) = computeRateAndClamp(token);
        RateLibrary.Rate[] memory rates = _getRates(token, meta.size, 0, 1);
        for (uint256 i = 0; i < rates.length; ++i) {
            if (rates[i].current != nextRate) return true;
        }

        return false;
    }

    /// @notice Gets the latest rate for a token. If the buffer is empty, returns a zero rate.
    /// @param token The token to get the latest rate for.
    /// @return The latest rate for the token, or a zero rate if the buffer is empty.
    function getLatestRate(address token) internal view virtual returns (RateLibrary.Rate memory) {
        BufferMetadata storage meta = rateBufferMetadata[token];

        if (meta.size == 0) {
            // If the buffer is empty, return the default (zero) rate
            return RateLibrary.Rate({target: 0, current: 0, timestamp: 0});
        }

        return rateBuffers[token][meta.end];
    }

    /// @notice Computes the rate for the given token.
    /// @dev This function calculates the rate for the specified token by summing its base rate
    /// and the weighted rates of its components. The component rates are computed using the `computeRate`
    /// function of each component and multiplied by the corresponding weight, then divided by 10,000.
    /// @param token The address of the token for which to compute the rate.
    /// @return uint64 The computed rate for the given token.
    function computeRateInternal(address token) internal view virtual returns (uint64) {
        RateConfig memory config = rateConfigs[token];

        uint64 rate = config.base;

        for (uint256 i = 0; i < config.componentWeights.length; ++i) {
            uint64 componentRate = ((uint256(config.components[i].computeRate(token)) * config.componentWeights[i]) /
                10000).toUint64();

            rate += componentRate;
        }

        return rate;
    }

    /// @notice Computes the target rate and clamps it based on the specified token's rate configuration.
    /// @dev This function calculates the target rate by calling `computeRateInternal`. It then clamps the new rate
    /// to ensure it is within the specified bounds for maximum constant and percentage increases or decreases.
    /// This helps to prevent sudden or extreme rate fluctuations.
    /// @param token The address of the token for which to compute the clamped rate.
    /// @return target The computed target rate for the given token.
    /// @return newRate The clamped rate for the given token, taking into account the maximum increase and decrease
    /// constraints.
    function computeRateAndClamp(address token) internal view virtual returns (uint64 target, uint64 newRate) {
        // Compute the target rate
        target = computeRateInternal(token);
        newRate = target;

        RateConfig memory config = rateConfigs[token];

        // Clamp the rate to the minimum and maximum rates
        // We do this before clamping the rate to the maximum constant and percentage increases or decreases because
        // we don't want a change in the minimum or maximum rate to cause a sudden change in the rate.
        if (newRate < config.min) {
            // The new rate is too low, so we change it to the minimum rate
            newRate = config.min;
        } else if (newRate > config.max) {
            // The new rate is too high, so we change it to the maximum rate
            newRate = config.max;
        }

        BufferMetadata memory meta = rateBufferMetadata[token];
        if (meta.size > 0) {
            // We have a previous rate, so let's make sure we don't change it too much

            uint64 last = rateBuffers[token][meta.end].current;

            if (newRate > last) {
                // Clamp the rate to the maximum constant increase
                if (newRate - last > config.maxIncrease) {
                    // The new rate is too high, so we change it by the maximum increase
                    newRate = last + config.maxIncrease;
                }

                // Clamp the rate to the maximum percentage increase
                uint256 maxIncreaseAbsolute = (uint256(last) * config.maxPercentIncrease) / 10000;
                if (newRate - last > maxIncreaseAbsolute) {
                    // The new rate is too high, so we change it by the maximum percentage increase
                    newRate = last + uint64(maxIncreaseAbsolute);
                }
            } else if (newRate < last) {
                // Clamp the rate to the maximum constant decrease
                if (last - newRate > config.maxDecrease) {
                    // The new rate is too low, so we change it by the maximum decrease
                    newRate = last - config.maxDecrease;
                }

                // Clamp the rate to the maximum percentage decrease
                uint256 maxDecreaseAbsolute = (uint256(last) * config.maxPercentDecrease) / 10000;
                if (last - newRate > maxDecreaseAbsolute) {
                    // The new rate is too low, so we change it by the maximum percentage decrease
                    newRate = last - uint64(maxDecreaseAbsolute);
                }
            }
        }
    }

    /// @notice Performs an update of the token's rate based on the provided data.
    /// @dev This function ensures that only EOAs (Externally Owned Accounts) can update the rate
    /// if `updatersMustBeEoa` is set to true. It decodes the token address from the input data, computes
    /// the new clamped rate using `computeRateAndClamp`, and then pushes the new rate to the rate buffer.
    /// @param data The input data, containing the token address to be updated.
    /// @return bool Returns true if the update is successful.
    function performUpdate(bytes memory data) internal virtual returns (bool) {
        if (updatersMustBeEoa && msg.sender != tx.origin) {
            // Only EOA can update
            revert UpdaterMustBeEoa(tx.origin, msg.sender);
        }

        address token = abi.decode(data, (address));

        // Compute the new target rate and clamp it
        (uint64 target, uint64 newRate) = computeRateAndClamp(token);

        // Push the new rate
        push(token, RateLibrary.Rate({target: target, current: newRate, timestamp: uint32(block.timestamp)}));

        return true;
    }

    /// @notice Checks if the caller is authorized to set the configuration.
    /// @dev This function should contain the access control logic for the setConfig function.
    function checkSetConfig() internal view virtual;

    /// @notice Checks if the caller is authorized to manually push rates.
    /// @dev This function should contain the access control logic for the manuallyPushRate function.
    /// WARNING: The manuallyPushRate function is very dangerous and should only be used in emergencies. Ensure that
    /// this function is implemented correctly and that the access control logic is sufficient to prevent abuse.
    function checkManuallyPushRate() internal view virtual;

    /// @notice Checks if the caller is authorized to pause or resume updates.
    /// @dev This function should contain the access control logic for the setUpdatesPaused function.
    function checkSetUpdatesPaused() internal view virtual;

    /// @notice Checks if the caller is authorized to set the rates capacity.
    /// @dev This function should contain the access control logic for the setRatesCapacity function.
    function checkSetRatesCapacity() internal view virtual;

    /// @notice Checks if the caller is authorized to perform an update.
    /// @dev This function should contain the access control logic for the update function.
    function checkUpdate() internal view virtual;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

pragma experimental ABIEncoderV2;

library RateLibrary {
    struct Rate {
        uint64 target;
        uint64 current;
        uint32 timestamp;
    }
}