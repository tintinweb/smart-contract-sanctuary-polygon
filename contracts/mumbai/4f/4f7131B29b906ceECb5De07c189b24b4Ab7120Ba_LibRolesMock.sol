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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

/// @author Amit Molek
/// @dev Implements Diamond Storage for access control logic
/// Based on OpenZeppelin's Access Control
library LibRoles {
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    struct DiamondStorage {
        mapping(bytes32 => RoleData) roles;
    }

    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("antic.storage.LibRoles");

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x0;

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 storagePosition = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := storagePosition
        }
    }

    /// @return Returns `true` if `account` has been granted `role`
    function _hasRole(bytes32 role, address account)
        internal
        view
        returns (bool)
    {
        DiamondStorage storage ds = diamondStorage();
        return ds.roles[role].members[account];
    }

    /// @return Returns the admin role of `role`
    function _getRoleAdmin(bytes32 role) internal view returns (bytes32) {
        DiamondStorage storage ds = diamondStorage();
        return ds.roles[role].adminRole;
    }

    /// @dev Reverts if the caller was not granted with `role`
    function _roleGuard(bytes32 role) internal view {
        LibRoles._roleGuard(role, msg.sender);
    }

    /// @dev Reverts if `account` was not granted with `role`
    function _roleGuard(bytes32 role, address account) internal view {
        if (!_hasRole(role, account)) {
            bytes memory err = abi.encodePacked(
                "RolesFacet: ",
                account,
                " lacks role: ",
                role
            );
            revert(string(err));
        }
    }

    /// @dev Use this to change the `role`'s admin role
    /// @param role the role you want to change the admin role
    /// @param adminRole the new admin role you want `role` to have
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
        LibRoles.DiamondStorage storage ds = LibRoles.diamondStorage();

        bytes32 oldAdminRole = _getRoleAdmin(role);
        ds.roles[role].adminRole = adminRole;

        emit RoleAdminChanged(role, oldAdminRole, adminRole);
    }

    /// @dev Use to grant `role` to `account`
    /// No access restriction
    function _grantRole(bytes32 role, address account) internal {
        LibRoles.DiamondStorage storage ds = LibRoles.diamondStorage();

        // Early exist if the account already has role
        if (_hasRole(role, account)) {
            return;
        }

        ds.roles[role].members[account] = true;

        emit RoleGranted(role, account, msg.sender);
    }

    /// @dev Use to revoke `role` to `account`
    /// No access restriction
    function _revokeRole(bytes32 role, address account) internal {
        LibRoles.DiamondStorage storage ds = LibRoles.diamondStorage();

        if (!_hasRole(role, account)) {
            return;
        }

        ds.roles[role].members[account] = false;

        emit RoleRevoked(role, account, msg.sender);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {LibRoles} from "../../libraries/LibRoles.sol";

contract LibRolesMock {
    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool)
    {
        return LibRoles._hasRole(role, account);
    }

    function getRoleAdmin(bytes32 role) external view returns (bytes32) {
        return LibRoles._getRoleAdmin(role);
    }

    function roleGuard(bytes32 role) external view {
        LibRoles._roleGuard(role);
    }

    function roleGuard(bytes32 role, address account) external view {
        LibRoles._roleGuard(role, account);
    }

    function setRoleAdmin(bytes32 role, bytes32 adminRole) external {
        return LibRoles._setRoleAdmin(role, adminRole);
    }

    function grantRole(bytes32 role, address account) external {
        return LibRoles._grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) external {
        return LibRoles._revokeRole(role, account);
    }
}