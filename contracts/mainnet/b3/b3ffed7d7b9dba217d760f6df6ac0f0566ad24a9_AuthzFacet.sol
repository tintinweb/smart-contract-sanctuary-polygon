/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../../diamond/IDiamondFacet.sol";
import "../../diamond/IAuthz.sol";
import "../../facets/rbac/RBACLib.sol";
import "./AuthzInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract AuthzFacet is IDiamondFacet, IAuthz {

    modifier onlyAuthzAdmin() {
        require(RBACLib._hasRole(msg.sender, AuthzLib.ROLE_AUTHZ_ADMIN), "AUTHZF:MR");
        _;
    }

    modifier onlyAuthzAdminOrDomainAdmin(bytes32 domainId) {
        if (domainId == AuthzInternal._global()) {
            // NOTE: Only authz admin can modify the global domain
            require(RBACLib._hasRole(msg.sender, AuthzLib.ROLE_AUTHZ_ADMIN), "AUTHZF:MR");
        }
        if (!RBACLib._hasRole(msg.sender, AuthzLib.ROLE_AUTHZ_ADMIN)) {
            require(AuthzInternal._isDomainAdmin(domainId, msg.sender), "AUTHZF:NADA");
        }
        _;
    }

    function getFacetName() external pure override returns (string memory) {
        return "authz";
    }

    function getFacetVersion() external pure override returns (string memory) {
        return "3.1.0";
    }

    function getFacetPI() external pure override returns (string[] memory) {
        string[] memory pi = new string[](27);
        pi[ 0] = "global()";
        pi[ 1] = "getDomains()";
        pi[ 2] = "isDomainDisabled(bytes32)";
        pi[ 3] = "disableDomain(string,uint256,bytes32)";
        pi[ 4] = "enableDomain(bytes32)";
        pi[ 5] = "isDomainAdmin(bytes32,address)";
        pi[ 6] = "addDomainAdmin(string,uint256,bytes32,address)";
        pi[ 7] = "removeDomainAdmin(string,uint256,bytes32,address)";
        pi[ 8] = "permissionExists(bytes32,bytes32)";
        pi[ 9] = "getPermission(bytes32,bytes32)";
        pi[10] = "getPermissions(bytes32)";
        pi[11] = "addPermission(bytes32,bytes32[],uint256[],uint256[],string)";
        pi[12] = "updatePermissionData(bytes32,bytes32,string)";
        pi[13] = "getIdentities(bytes32)";
        pi[14] = "getDomainRoles(bytes32)";
        pi[15] = "getRoleMembers(bytes32,bytes32)";
        pi[16] = "getRoleInfo(bytes32,bytes32)";
        pi[17] = "setRoleParent(bytes32,bytes32,bytes32)";
        pi[18] = "updateRoleMembers(bytes32,bytes32[],bytes32)";
        pi[19] = "getIdentityRoles(bytes32,bytes32)";
        pi[20] = "getDomainPermissions(bytes32)";
        pi[21] = "updateDomainPermissions(string,uint256,bytes32,bytes32[])";
        pi[22] = "getRolePermissions(bytes32,bytes32)";
        pi[23] = "updateRolePermissions(bytes32,bytes32[],bytes32)";
        pi[24] = "getIdentityPermissions(bytes32,bytes32)";
        pi[25] = "updateIdentityPermissions(bytes32,bytes32[],bytes32)";
        pi[26] = "authorize(bytes32,bytes32,bytes32[],uint256[])";
        return pi;
    }

    function getFacetProtectedPI() external pure override returns (string[] memory) {
        // NOTE: This facet is not an ordinary facet and this function is not used at all.
        //       This facet must be added to a special diamond and that diamond has its
        //       own method (role-based via task manager) in order to protect functions.
        string[] memory pi = new string[](0);
        return pi;
    }

    function supportsInterface(bytes4 interfaceId)
      external view override virtual returns (bool) {
        return interfaceId == type(IDiamondFacet).interfaceId ||
               interfaceId == type(IAuthz).interfaceId;
    }

    function global() external pure returns (bytes32) {
        return AuthzInternal._global();
    }

    function getDomains() external view returns (bytes32[] memory) {
        return AuthzInternal._getDomains();
    }

    function isDomainDisabled(
        bytes32 domainId
    ) external view returns (bool) {
        return AuthzInternal._isDomainDisabled(domainId);
    }

    function disableDomain(
        string memory taskManagerKey,
        uint256 taskId,
        bytes32 domainId
    ) external onlyAuthzAdmin {
        AuthzInternal._disableDomain(taskManagerKey, taskId, domainId);
    }

    function enableDomain(
        bytes32 domainId
    ) external onlyAuthzAdmin {
        AuthzInternal._enableDomain(domainId);
    }

    function isDomainAdmin(bytes32 domainId, address account) public view returns (bool) {
        return AuthzInternal._isDomainAdmin(domainId, account);
    }

    function addDomainAdmin(
        string memory taskManagerKey,
        uint256 taskId,
        bytes32 domainId,
        address account
    ) public onlyAuthzAdmin {
        AuthzInternal._addDomainAdmin(taskManagerKey, taskId, domainId, account);
    }

    function removeDomainAdmin(
        string memory taskManagerKey,
        uint256 taskId,
        bytes32 domainId,
        address account
    ) public onlyAuthzAdmin {
        AuthzInternal._removeDomainAdmin(taskManagerKey, taskId, domainId, account);
    }

    function permissionExists(
        bytes32 domainId,
        bytes32 permissionId
    ) external view returns (bool) {
        return AuthzInternal._permissionExists(domainId, permissionId);
    }

    function getPermission(
        bytes32 domainId,
        bytes32 id
    ) external view returns (
        bytes32[] memory,
        uint256[] memory,
        uint256[] memory,
        string memory
    ) {
        return AuthzInternal._getPermission(domainId, id);
    }

    function getPermissions(
        bytes32 domainId
    ) external view returns (bytes32[] memory) {
        return AuthzInternal._getPermissions(domainId);
    }

    function addPermission(
        bytes32 domainId,
        bytes32[] memory targets,
        uint256[] memory ops,
        uint256[] memory actions,
        string memory data
    ) external onlyAuthzAdminOrDomainAdmin(domainId) {
        AuthzInternal._addPermission(
            domainId,
            targets,
            ops,
            actions,
            data
        );
    }

    function updatePermissionData(
        bytes32 domainId,
        bytes32 permissionId,
        string memory data
    ) external onlyAuthzAdminOrDomainAdmin(domainId) {
        AuthzInternal._updatePermissionData(domainId, permissionId, data);
    }

    function getIdentities(
        bytes32 domainId
    ) external view returns (bytes32[] memory) {
        return AuthzInternal._getIdentities(domainId);
    }

    function getDomainRoles(
        bytes32 domainId
    ) external view returns (bytes32[] memory) {
        return AuthzInternal._getDomainRoles(domainId);
    }

    function getRoleMembers(
        bytes32 domainId,
        bytes32 role
    ) external view returns (bytes32[] memory) {
        return AuthzInternal._getRoleMembers(domainId, role);
    }

    function getRoleInfo(
        bytes32 domainId,
        bytes32 role
    ) external view returns (
        bytes32, /* parent role */
        bytes32[] memory /* chilren */
    ) {
        return AuthzInternal._getRoleInfo(domainId, role);
    }

    function setRoleParent(
        bytes32 domainId,
        bytes32 role,
        bytes32 parentRole
    ) external {
        AuthzInternal._setRoleParent(domainId, role, parentRole);
    }

    function updateRoleMembers(
        bytes32 domainId,
        bytes32[] memory identityIds,
        bytes32 role
    ) external onlyAuthzAdminOrDomainAdmin(domainId) {
        AuthzInternal._updateRoleMembers(
            domainId,
            identityIds,
            role
        );
    }

    function getIdentityRoles(
        bytes32 domainId,
        bytes32 identityId
    ) external view returns (bytes32[] memory) {
        return AuthzInternal._getIdentityRoles(domainId, identityId);
    }

    function getDomainPermissions(
        bytes32 domainId
    ) external view returns (bytes32[] memory) {
        return AuthzInternal._getDomainPermissions(domainId);
    }

    function updateDomainPermissions(
        string memory taskManagerKey,
        uint256 taskId,
        bytes32 domainId,
        bytes32[] memory permissionIds
    ) external onlyAuthzAdminOrDomainAdmin(domainId) {
        AuthzInternal._updateDomainPermissions(
            taskManagerKey, taskId, domainId, permissionIds);
    }

    function getRolePermissions(
        bytes32 domainId,
        bytes32 role
    ) external view returns (bytes32[] memory) {
        return AuthzInternal._getRolePermissions(domainId, role);
    }

    function updateRolePermissions(
        bytes32 domainId,
        bytes32[] memory permissionIds,
        bytes32 role
    ) external onlyAuthzAdminOrDomainAdmin(domainId) {
        AuthzInternal._updateRolePermissions(
            domainId,
            permissionIds,
            role
        );
    }

    function getIdentityPermissions(
        bytes32 domainId,
        bytes32 identityId
    ) external view returns (bytes32[] memory) {
        return AuthzInternal._getIdentityPermissions(domainId, identityId);
    }

    function updateIdentityPermissions(
        bytes32 domainId,
        bytes32[] memory permissionIds,
        bytes32 identityId
    ) external onlyAuthzAdminOrDomainAdmin(domainId) {
        AuthzInternal._updateIdentityPermissions(
            domainId,
            permissionIds,
            identityId
        );
    }

    function authorize(
        bytes32 domainId,
        bytes32 identityId,
        bytes32[] memory targets,
        uint256[] memory ops
    ) external view override returns (uint256[] memory) {
        return AuthzInternal._authorize(domainId, identityId, targets, ops);
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/interfaces/IERC165.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
interface IDiamondFacet is IERC165 {

    // NOTE: The override MUST remain 'pure'.
    function getFacetName() external pure returns (string memory);

    // NOTE: The override MUST remain 'pure'.
    function getFacetVersion() external pure returns (string memory);

    // NOTE: The override MUST remain 'pure'.
    function getFacetPI() external pure returns (string[] memory);

    // NOTE: The override MUST remain 'pure'.
    function getFacetProtectedPI() external pure returns (string[] memory);
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

library AuthzLib {

    uint256 public constant ROLE_AUTHZ_DIAMOND_ADMIN = uint256(keccak256(bytes("ROLE_AUTHZ_DIAMOND_ADMIN")));
    uint256 public constant ROLE_AUTHZ_ADMIN = uint256(keccak256(bytes("ROLE_AUTHZ_ADMIN")));

    bytes32 constant public GLOBAL_DOMAIN_ID = keccak256(abi.encodePacked("global"));
    bytes32 constant public MATCH_ALL_WILDCARD_HASH = keccak256(abi.encodePacked("*"));

    // operations
    uint256 constant public CALL_OP = 5000;
    uint256 constant public MATCH_ALL_WILDCARD_OP = 9999;

    // actions
    uint256 constant public ACCEPT_ACTION = 1;
    uint256 constant public REJECT_ACTION = 100;
}

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
interface IAuthz {

    function authorize(
        bytes32 domainHash,
        bytes32 identityHash,
        bytes32[] memory targets,
        uint256[] memory ops
    ) external view returns (uint256[] memory);
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./RBACInternal.sol";

library RBACLib {

    function _hasRole(
        address account,
        uint256 role
    ) internal view returns (bool) {
        return RBACInternal._hasRole(account, role);
    }

    function _unsafeGrantRole(
        address account,
        uint256 role
    ) internal {
        RBACInternal._unsafeGrantRole(account, role);
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

// import "hardhat/console.sol";

import "../../diamond/IAuthz.sol";
import "../task-executor/TaskExecutorLib.sol";
import "./AuthzStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library AuthzInternal {

    event AdminAdd(
        bytes32 domain,
        address account
    );
    event AdminRemove(
        bytes32 domain,
        address account
    );
    event PermissionAdd(
        bytes32 domain,
        bytes32 permissionId
    );
    event RoleAdd(
        bytes32 domain,
        bytes32 role
    );
    event RoleParentSet(
        bytes32 domain,
        bytes32 role,
        bytes32 parentRole
    );
    event DomainPermissionsUpdate(
        bytes32 domainId,
        bytes32[] permissionIds
    );
    event RolePermissionsUpdate(
        bytes32 domain,
        bytes32[] permissionIds,
        bytes32 role
    );
    event IdentityPermissionsUpdate(
        bytes32 domain,
        bytes32[] permissionIds,
        bytes32 identity
    );
    event RoleMembersUpdate(
        bytes32 domain,
        bytes32[] identities,
        bytes32 role
    );

    function _global() internal pure returns (bytes32) {
        return AuthzLib.GLOBAL_DOMAIN_ID;
    }

    function _getDomains() internal view returns (bytes32[] memory) {
        return __s().domainIds;
    }

    function _isDomainDisabled(
        bytes32 domainId
    ) internal view returns (bool) {
        __findDomain(domainId, false);
        return __s().disabledDomains[domainId];
    }

    function _disableDomain(
        string memory taskManagerKey,
        uint256 taskId,
        bytes32 domainId
    ) internal {
        __touchDomain(domainId, false);
        __s().disabledDomains[domainId] = true;
        TaskExecutorLib._executeTask(taskManagerKey, taskId);
    }

    function _enableDomain(bytes32 domainId) internal {
        __touchDomain(domainId, false);
        __s().disabledDomains[domainId] = false;
    }

    function _isDomainAdmin(bytes32 domainId, address account) internal view returns (bool) {
        AuthzStorage.Domain storage domain = __findDomain(domainId, false);
        return domain.admins[account];
    }

    function _addDomainAdmin(
        string memory taskManagerKey,
        uint256 taskId,
        bytes32 domainId,
        address account
    ) internal {
        require(domainId != AuthzLib.GLOBAL_DOMAIN_ID, "AUTHZI:DNS");
        AuthzStorage.Domain storage domain = __touchDomain(domainId, false);
        domain.admins[account] = true;
        emit AdminAdd(domainId, account);
        TaskExecutorLib._executeTask(taskManagerKey, taskId);
    }

    function _removeDomainAdmin(
        string memory taskManagerKey,
        uint256 taskId,
        bytes32 domainId,
        address account
    ) internal {
        require(domainId != AuthzLib.GLOBAL_DOMAIN_ID, "AUTHZI:DNS");
        AuthzStorage.Domain storage domain = __touchDomain(domainId, false);
        domain.admins[account] = false;
        emit AdminRemove(domainId, account);
        TaskExecutorLib._executeTask(taskManagerKey, taskId);
    }

    function _permissionExists(
        bytes32 domainId,
        bytes32 permissionId
    ) internal view returns (bool) {
        if (__s().domains[domainId].id == 0 || __s().disabledDomains[domainId]) {
            return false;
        }
        AuthzStorage.Domain storage domain = __s().domains[domainId];
        return __permissionExists(domain, permissionId);
    }

    function _getPermission(
        bytes32 domainId,
        bytes32 permissionId
    ) internal view returns (
        bytes32[] memory,
        uint256[] memory,
        uint256[] memory,
        string memory
    ) {
        AuthzStorage.Domain storage domain = __findDomain(domainId, false);
        AuthzStorage.Permission storage permission = __findPermission(domain, permissionId);
        return (
            permission.targets,
            permission.ops,
            permission.actions,
            permission.data
        );
    }

    function _getPermissions(
        bytes32 domainId
    ) internal view returns (bytes32[] memory) {
        AuthzStorage.Domain storage domain = __findDomain(domainId, false);
        return domain.permissions;
    }

    function _addPermission(
        bytes32 domainId,
        bytes32[] memory targets,
        uint256[] memory ops,
        uint256[] memory actions,
        string memory data
    ) internal {
        require(targets.length > 0, "AUTHZI:ZL");
        require(actions.length > 0, "AUTHZI:ZL2");
        AuthzStorage.Domain storage domain = __touchDomain(domainId, true);
        bytes32 id = keccak256(abi.encode(targets, ops, actions));
        require(domain.permissionsMap[id].id == 0, "AUTHZI:EP");
        domain.permissionsMap[id].id = id;
        domain.permissionsMap[id].targets = targets;
        domain.permissionsMap[id].ops = ops;
        domain.permissionsMap[id].actions = actions;
        domain.permissionsMap[id].data = data;
        domain.permissions.push(id);
        emit PermissionAdd(domainId, id);
    }

    function _updatePermissionData(
        bytes32 domainId,
        bytes32 permissionId,
        string memory data
    ) internal {
        AuthzStorage.Domain storage domain = __findDomain(domainId, false);
        AuthzStorage.Permission storage permission = __findPermission(domain, permissionId);
        permission.data = data;
    }

    function _getIdentities(
        bytes32 domainId
    ) internal view returns (bytes32[] memory) {
        AuthzStorage.Domain storage domain = __findDomain(domainId, false);
        return domain.identities;
    }

    function _getDomainRoles(
        bytes32 domainId
    ) internal view returns (bytes32[] memory) {
        AuthzStorage.Domain storage domain = __findDomain(domainId, false);
        return domain.roles;
    }

    function _getRoleMembers(
        bytes32 domainId,
        bytes32 role
    ) internal view returns (bytes32[] memory) {
        AuthzStorage.Domain storage domain = __findDomain(domainId, false);
        return domain.roleMembers[role];
    }

    function _getRoleInfo(
        bytes32 domainId,
        bytes32 role
    ) internal view returns (
        bytes32, /* parent role */
        bytes32[] memory /* chilren */
    ) {
        AuthzStorage.Domain storage domain = __findDomain(domainId, false);
        uint256 childCount = 0;
        for (uint256 i = 0; i < domain.roles.length; i++) {
            if (domain.roleParents[domain.roles[i]] == role) {
                childCount += 1;
            }
        }
        bytes32[] memory children = new bytes32[](childCount);
        uint256 j = 0;
        for (uint256 i = 0; i < domain.roles.length; i++) {
            if (domain.roleParents[domain.roles[i]] == role) {
                children[j] = domain.roles[i];
                j += 1;
            }
        }
        return (
            domain.roleParents[role],
            children
        );
    }

    function _setRoleParent(
        bytes32 domainId,
        bytes32 role,
        bytes32 parentRole
    ) internal {
        AuthzStorage.Domain storage domain = __touchDomain(domainId, true);
        __touchRole(domain, role);
        __touchRole(domain, parentRole);
        domain.roleParents[role] = parentRole;
        emit RoleParentSet(domainId, role, parentRole);
    }

    function _updateRoleMembers(
        bytes32 domainId,
        bytes32[] memory identityIds,
        bytes32 role
    ) internal {
        AuthzStorage.Domain storage domain = __touchDomain(domainId, true);
        __touchRole(domain, role);
        bytes32[] memory oldMembers = domain.roleMembers[role];
        delete domain.roleMembers[role];
        for (uint256 i = 0; i < identityIds.length; i++) {
            bytes32 identityId = identityIds[i];
            __touchIdentity(domain, identityId);
            __addIdentityToRole(domain, identityId, role);
        }
        for (uint256 i = 0; i < oldMembers.length; i++) {
            __updateRoles(domain, oldMembers[i]);
        }
        emit RoleMembersUpdate(domainId, identityIds, role);
    }

    function _getIdentityRoles(
        bytes32 domainId,
        bytes32 identityId
    ) internal view returns (bytes32[] memory) {
        AuthzStorage.Domain storage domain = __findDomain(domainId, false);
        return domain.identityRoles[identityId];
    }

    function _getDomainPermissions(
        bytes32 domainId
    ) internal view returns (bytes32[] memory) {
        AuthzStorage.Domain storage domain = __findDomain(domainId, true);
        return domain.domainPermissions;
    }

    function _updateDomainPermissions(
        string memory taskManagerKey,
        uint256 taskId,
        bytes32 domainId,
        bytes32[] memory permissionIds
    ) internal {
        AuthzStorage.Domain storage domain = __touchDomain(domainId, true);
        delete domain.domainPermissions;
        for (uint256 i = 0; i < permissionIds.length; i++) {
            __findPermission(domain, permissionIds[i]);
            bool found = false;
            for (uint256 j = 0; j < domain.domainPermissions.length; j++) {
                if (permissionIds[i] == domain.domainPermissions[j]) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                domain.domainPermissions.push(permissionIds[i]);
            }
        }
        emit DomainPermissionsUpdate(domainId, permissionIds);
        TaskExecutorLib._executeTask(taskManagerKey, taskId);
    }

    function _getRolePermissions(
        bytes32 domainId,
        bytes32 role
    ) internal view returns (bytes32[] memory) {
        AuthzStorage.Domain storage domain = __findDomain(domainId, true);
        return domain.rolePermissions[role];
    }

    function _updateRolePermissions(
        bytes32 domainId,
        bytes32[] memory permissionIds,
        bytes32 role
    ) internal {
        AuthzStorage.Domain storage domain = __touchDomain(domainId, true);
        __touchRole(domain, role);
        delete domain.rolePermissions[role];
        for (uint256 i = 0; i < permissionIds.length; i++) {
            __findPermission(domain, permissionIds[i]);
            bool found = false;
            for (uint256 j = 0; j < domain.rolePermissions[role].length; j++) {
                if (permissionIds[i] == domain.rolePermissions[role][j]) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                domain.rolePermissions[role].push(permissionIds[i]);
            }
        }
        emit RolePermissionsUpdate(domainId, permissionIds, role);
    }

    function _getIdentityPermissions(
        bytes32 domainId,
        bytes32 identityId
    ) internal view returns (bytes32[] memory) {
        AuthzStorage.Domain storage domain = __findDomain(domainId, true);
        return domain.identityPermissions[identityId];
    }

    function _updateIdentityPermissions(
        bytes32 domainId,
        bytes32[] memory permissionIds,
        bytes32 identityId
    ) internal {
        AuthzStorage.Domain storage domain = __touchDomain(domainId, true);
        __touchIdentity(domain, identityId);
        delete domain.identityPermissions[identityId];
        for (uint256 i = 0; i < permissionIds.length; i++) {
            __findPermission(domain, permissionIds[i]);
            bool found = false;
            for (uint256 j = 0; j < domain.identityPermissions[identityId].length; j++) {
                if (permissionIds[i] == domain.identityPermissions[identityId][j]) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                domain.identityPermissions[identityId].push(permissionIds[i]);
            }
        }
        emit IdentityPermissionsUpdate(domainId, permissionIds, identityId);
    }

    function _authorize(
        bytes32 domainId,
        bytes32 identityId,
        bytes32[] memory targets,
        uint256[] memory ops
    ) internal view returns (uint256[] memory) {
        AuthzStorage.Domain storage domain = __findDomain(domainId, true);
        return __authorize(domain, identityId, targets, ops);
    }

    // ------------------------------- Private methods -----------------------------

    function __touchDomain(
        bytes32 domainId,
        bool checkDisabledState
    ) private returns (AuthzStorage.Domain storage) {
        if (__s().domains[domainId].id == 0) {
            __s().domains[domainId].id = domainId;
            __s().domainIds.push(domainId);
        }
        require(
            !checkDisabledState ||
            !__s().disabledDomains[domainId], "AUTHZI:DD");
        return __s().domains[domainId];
    }

    function __findDomain(
        bytes32 domainId,
        bool checkDisabledState
    ) private view returns (AuthzStorage.Domain storage) {
        require(__s().domains[domainId].id != 0, "AUTHZI:NED");
        require(
            !checkDisabledState ||
            !__s().disabledDomains[domainId], "AUTHZI:DD");
        return __s().domains[domainId];
    }

    function __permissionExists(
        AuthzStorage.Domain storage domain,
        bytes32 permissionId
    ) private view returns (bool) {
        return domain.permissionsMap[permissionId].id != 0;
    }

    function __findPermission(
        AuthzStorage.Domain storage domain,
        bytes32 permissionId
    ) private view returns (AuthzStorage.Permission storage) {
        require(domain.permissionsMap[permissionId].id != 0, "AUTHZI:NEP");
        return domain.permissionsMap[permissionId];
    }

    function __touchIdentity(
        AuthzStorage.Domain storage domain,
        bytes32 identityId
    ) private {
        for (uint256 i = 0; i < domain.identities.length; i++) {
            if (domain.identities[i] == identityId) {
                return;
            }
        }
        domain.identities.push(identityId);
    }

    function __touchRole(
        AuthzStorage.Domain storage domain,
        bytes32 role
    ) private {
        require(role != bytes3(0), "AUTHZI:ZR");
        for (uint256 i = 0; i < domain.roles.length; i++) {
            if (domain.roles[i] == role) {
                return;
            }
        }
        domain.roles.push(role);
        emit RoleAdd(domain.id, role);
    }

    function __addIdentityToRole(
        AuthzStorage.Domain storage domain,
        bytes32 identityId,
        bytes32 role
    ) private {
        bool found = false;
        for (uint256 i = 0; i < domain.roleMembers[role].length; i++) {
            if (domain.roleMembers[role][i] == identityId) {
                found = true;
                break;
            }
        }
        if (!found) {
            domain.roleMembers[role].push(identityId);
        }
        found = false;
        for (uint256 i = 0; i < domain.identityRoles[identityId].length; i++) {
            if (domain.identityRoles[identityId][i] == role) {
                found = true;
                break;
            }
        }
        if (!found) {
            domain.identityRoles[identityId].push(role);
        }
    }

    function __updateRoles(
        AuthzStorage.Domain storage domain,
        bytes32 identityId
    ) private {
        bytes32[] memory oldRolees = domain.identityRoles[identityId];
        delete domain.identityRoles[identityId];
        for (uint256 i = 0; i < oldRolees.length; i++) {
            bytes32 role = oldRolees[i];
            bool found = false;
            for (uint256 j = 0; j < domain.roleMembers[role].length; j++) {
                if (domain.roleMembers[role][j] == identityId) {
                    found = true;
                    break;
                }
            }
            if (found) {
                domain.identityRoles[identityId].push(role);
            }
        }
    }

    function __authorize(
        AuthzStorage.Domain storage domain,
        bytes32 identityId,
        bytes32[] memory targets,
        uint256[] memory ops
    ) private view returns (uint256[] memory) {
        uint256[] memory results = new uint256[](1);
        // 1. check identity permissions
        bytes32[] memory identityPermissionIds = domain.identityPermissions[identityId];
        for (uint256 i = 0; i < identityPermissionIds.length; i++) {
            (bool matched, uint256[] memory actions) =
                __matchPermission(domain, identityPermissionIds[i], targets, ops);
            if (matched) {
                return actions;
            }
        }
        // 2. check identity's roles
        bytes32[] memory identityRoles = domain.identityRoles[identityId];
        for (uint256 i = 0; i < identityRoles.length; i++) {
            bytes32 identityRole = identityRoles[i];
            bytes32 role = identityRole;
            do {
                bytes32[] memory rolePermissionIds = domain.rolePermissions[role];
                for (uint256 j = 0; j < rolePermissionIds.length; j++) {
                    (bool matched, uint256[] memory actions) =
                        __matchPermission(domain, rolePermissionIds[j], targets, ops);
                    if (matched) {
                        return actions;
                    }
                }
                role = domain.roleParents[role];
            } while (role != bytes32(0));
        }
        // 3. check domain's permissions
        for (uint256 i = 0; i < domain.domainPermissions.length; i++) {
            (bool matched, uint256[] memory actions) =
                __matchPermission(domain, domain.domainPermissions[i], targets, ops);
            if (matched) {
                return actions;
            }
        }
        // 4. check global domain's permissions
        if (__s().domains[_global()].id != 0) {
            AuthzStorage.Domain storage globalDomain = __findDomain(_global(), true);
            for (uint256 i = 0; i < globalDomain.domainPermissions.length; i++) {
                (bool matched, uint256[] memory actions) =
                    __matchPermission(globalDomain, globalDomain.domainPermissions[i], targets, ops);
                if (matched) {
                    return actions;
                }
            }
        }
        // 5. nothing found! reject the request.
        results[0] = AuthzLib.REJECT_ACTION;
        return results;
    }

    function __matchPermission(
        AuthzStorage.Domain storage domain,
        bytes32 permissionId,
        bytes32[] memory targets,
        uint256[] memory ops
    ) private view returns (bool, uint256[] memory) {
        require(domain.permissionsMap[permissionId].id != 0, "AUTHZI:NEP");
        uint256[] memory emptyActions = new uint256[](0);
        AuthzStorage.Permission storage permission = domain.permissionsMap[permissionId];
        if (permission.targets.length != targets.length) {
            return (false, emptyActions);
        }
        for (uint256 i = 0; i < permission.targets.length; i++) {
            if (
                permission.targets[i] != AuthzLib.MATCH_ALL_WILDCARD_HASH &&
                permission.targets[i] != targets[i]
            ) {
                return (false, emptyActions);
            }
        }
        if (permission.ops.length != ops.length) {
            return (false, emptyActions);
        }
        for (uint256 i = 0; i < permission.ops.length; i++) {
            if (
                permission.ops[i] != AuthzLib.MATCH_ALL_WILDCARD_OP &&
                permission.ops[i] != ops[i]
            ) {
                return (false, emptyActions);
            }
        }
        return (true, permission.actions);
    }

    function __s() private pure returns (AuthzStorage.Layout storage) {
        return AuthzStorage.layout();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../task-executor/TaskExecutorLib.sol";
import "./RBACStorage.sol";

library RBACInternal {

    event RoleGrant(uint256 role, address account);
    event RoleRevoke(uint256 role, address account);

    function _hasRole(
        address account,
        uint256 role
    ) internal view returns (bool) {
        return __s().roles[role][account];
    }

    // ATTENTION! this function MUST NEVER get exposed via a facet
    function _unsafeGrantRole(
        address account,
        uint256 role
    ) internal {
        require(!__s().roles[role][account], "RBACI:AHR");
        __s().roles[role][account] = true;
        emit RoleGrant(role, account);
    }

    function _grantRole(
        uint256 taskId,
        string memory taskManagerKey,
        address account,
        uint256 role
    ) internal {
        _unsafeGrantRole(account, role);
        TaskExecutorLib._executeTask(taskManagerKey, taskId);
    }

    function _revokeRole(
        uint256 taskId,
        string memory taskManagerKey,
        address account,
        uint256 role
    ) internal {
        require(__s().roles[role][account], "RBACI:DHR");
        __s().roles[role][account] = false;
        emit RoleRevoke(role, account);
        TaskExecutorLib._executeTask(taskManagerKey, taskId);
    }

    function __s() private pure returns (RBACStorage.Layout storage) {
        return RBACStorage.layout();
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./TaskExecutorInternal.sol";

library TaskExecutorLib {

    function _initialize(
        address newTaskManager
    ) internal {
        TaskExecutorInternal._initialize(newTaskManager);
    }

    function _getTaskManager(
        string memory taskManagerKey
    ) internal view returns (address) {
        return TaskExecutorInternal._getTaskManager(taskManagerKey);
    }

    function _executeTask(
        string memory key,
        uint256 taskId
    ) internal {
        TaskExecutorInternal._executeTask(key, taskId);
    }

    function _executeAdminTask(
        string memory key,
        uint256 adminTaskId
    ) internal {
        TaskExecutorInternal._executeAdminTask(key, adminTaskId);
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library RBACStorage {

    struct Layout {
        // role > address > true if granted
        mapping (uint256 => mapping(address => bool)) roles;
        mapping(bytes32 => bytes) extra;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("qomet-tech.contracts.facets.rbac.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "../hasher/HasherLib.sol";
import "./ITaskExecutor.sol";
import "./TaskExecutorStorage.sol";

library TaskExecutorInternal {

    event TaskManagerSet (
        string key,
        address taskManager
    );

    function _initialize(
        address newTaskManager
    ) internal {
        require(!__s().initialized, "TFI:AI");
        __setTaskManager("DEFAULT", newTaskManager);
        __s().initialized = true;
    }

    function _getTaskManagerKeys() internal view returns (string[] memory) {
        return __s().keys;
    }

    function _getTaskManager(string memory key) internal view returns (address) {
        bytes32 keyHash = HasherLib._hashStr(key);
        require(__s().keysIndex[keyHash] > 0, "TFI:KNF");
        return __s().taskManagers[keyHash];
    }

    function _setTaskManager(
        uint256 adminTaskId,
        string memory key,
        address newTaskManager
    ) internal {
        require(__s().initialized, "TFI:NI");
        bytes32 keyHash = HasherLib._hashStr(key);
        address oldTaskManager = __s().taskManagers[keyHash];
        __setTaskManager(key, newTaskManager);
        if (oldTaskManager != address(0)) {
            ITaskExecutor(oldTaskManager).executeAdminTask(msg.sender, adminTaskId);
        } else {
            address defaultTaskManager = _getTaskManager("DEFAULT");
            require(defaultTaskManager != address(0), "TFI:ZDTM");
            ITaskExecutor(defaultTaskManager).executeAdminTask(msg.sender, adminTaskId);
        }
    }

    function _executeTask(
        string memory key,
        uint256 taskId
    ) internal {
        require(__s().initialized, "TFI:NI");
        address taskManager = _getTaskManager(key);
        require(taskManager != address(0), "TFI:ZTM");
        ITaskExecutor(taskManager).executeTask(msg.sender, taskId);
    }

    function _executeAdminTask(
        string memory key,
        uint256 adminTaskId
    ) internal {
        require(__s().initialized, "TFI:NI");
        address taskManager = _getTaskManager(key);
        require(taskManager != address(0), "TFI:ZTM");
        ITaskExecutor(taskManager).executeAdminTask(msg.sender, adminTaskId);
    }

    function __setTaskManager(
        string memory key,
        address newTaskManager
    ) internal {
        require(newTaskManager != address(0), "TFI:ZA");
        require(IERC165(newTaskManager).supportsInterface(type(ITaskExecutor).interfaceId),
            "TFI:IC");
        bytes32 keyHash = HasherLib._hashStr(key);
        if (__s().keysIndex[keyHash] == 0) {
            __s().keys.push(key);
            __s().keysIndex[keyHash] = __s().keys.length;
        }
        __s().taskManagers[keyHash] = newTaskManager;
        emit TaskManagerSet(key, newTaskManager);
    }

    function __s() private pure returns (TaskExecutorStorage.Layout storage) {
        return TaskExecutorStorage.layout();
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

library HasherLib {

    function _hashAddress(address addr) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(addr));
    }

    function _hashStr(string memory str) internal pure returns (bytes32) {
        return keccak256(bytes(str));
    }

    function _hashInt(uint256 num) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("INT", num));
    }

    function _hashAccount(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("ACCOUNT", account));
    }

    function _hashVault(address vault) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("VAULT", vault));
    }

    function _hashReserveId(uint256 reserveId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("RESERVEID", reserveId));
    }

    function _hashContract(address contractAddr) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("CONTRACT", contractAddr));
    }

    function _hashTokenId(uint256 tokenId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("TOKENID", tokenId));
    }

    function _hashRole(string memory roleName) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("ROLE", roleName));
    }

    function _hashLedgerId(uint256 ledgerId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("LEDGERID", ledgerId));
    }

    function _mixHash2(
        bytes32 d1,
        bytes32 d2
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("MIX2_", d1, d2));
    }

    function _mixHash3(
        bytes32 d1,
        bytes32 d2,
        bytes32 d3
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("MIX3_", d1, d2, d3));
    }

    function _mixHash4(
        bytes32 d1,
        bytes32 d2,
        bytes32 d3,
        bytes32 d4
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("MIX4_", d1, d2, d3, d4));
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
interface ITaskExecutor {

    event TaskExecuted(address finalizer, address executor, uint256 taskId);

    function executeTask(address executor, uint256 taskId) external;

    function executeAdminTask(address executor, uint256 taskId) external;
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library TaskExecutorStorage {

    struct Layout {
        // list of the keys
        string[] keys;
        mapping(bytes32 => uint256) keysIndex;
        // keccak256(key) > task manager address
        mapping(bytes32 => address) taskManagers;
        // true if default task manager has been set
        bool initialized;
        mapping(bytes32 => bytes) extra;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("qomet-tech.contracts.facets.task-finalizer.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library AuthzStorage {

    struct Permission {
        // ID is the keccak256 hash of the packed encoding of the following
        // fields in the given order:
        //   - targets
        //   - ops
        //   - actions
        bytes32 id;

        // a permission is identitied by the following fields
        bytes32[] targets;
        uint256[] ops;
        uint256[] actions;

        // extra data to store for the permission
        string data;

        // reserved for the future use
        mapping(bytes32 => bytes) extra;
    }

    struct Domain {
        // unique ID of the domain
        bytes32 id;

        // list of all identities
        bytes32[] identities;

        // mapping of permissions
        mapping(bytes32 => Permission) permissionsMap;
        // list of all identities
        bytes32[] permissions;

        // list of roles
        bytes32[] roles;
        // role > parent role
        mapping(bytes32 => bytes32) roleParents;
        // identity members of a role
        mapping(bytes32 => bytes32[]) roleMembers;
        // roles of a given identity
        mapping(bytes32 => bytes32[]) identityRoles;

        // permissions of a domain
        bytes32[]  domainPermissions;
        // permissions of a role
        mapping(bytes32 => bytes32[]) rolePermissions;
        // permissions of an identity
        mapping(bytes32 => bytes32[]) identityPermissions;

        // admins
        mapping(address => bool) admins;

        // reserved for the future use
        mapping(bytes32 => bytes) extra;
    }

    struct Layout {
        bytes32[] domainIds;
        mapping(bytes32 => Domain) domains;
        mapping(bytes32 => bool) disabledDomains;
        // reserved for the future use
        mapping(bytes32 => bytes) extra;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("qomet-tech.contracts.diamond.facets.authz.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}