// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {AccessControlStorage} from './AccessControlStorage.sol';
import {LibAccessControl} from './LibAccessControl.sol';
import {Array} from '../utils/Array.sol';

struct SetRoleItem {
	address user;
	bytes32 role;
	bool hasRole;
}

library AccessControlError {
	string public constant MissingRequiredRole = 'MISSING_REQUIRED_ROLE';
	string public constant NoRenounceOthers = 'NO_RENOUNCE_OTHERS';
}

/// @title Role-based access control for limiting access to some functions of the contract
/// @notice Assign roles to grant access to otherwise limited functions of the contract
contract AccessControlFacet {
	event MeemRoleGranted(bytes32 indexed role, address indexed user);
	event MeemRoleRevoked(bytes32 indexed role, address indexed user);

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

	event RoleSet(
		bytes32 indexed role,
		address[] indexed account,
		address indexed sender
	);

	/// @notice An admin of the contract.
	/// @return Hashed value that represents this role.
	function ADMIN_ROLE() public pure returns (bytes32) {
		return AccessControlStorage.ADMIN_ROLE;
	}

	/// @notice A contract upgrader
	/// @return Hashed value that represents this role.
	function UPGRADER_ROLE() public pure returns (bytes32) {
		return AccessControlStorage.UPGRADER_ROLE;
	}

	function canUpgradeContract(address upgrader) public view returns (bool) {
		AccessControlFacet ac = AccessControlFacet(address(this));
		if (ac.hasRole(ac.UPGRADER_ROLE(), upgrader)) {
			return true;
		}

		return false;
	}

	function bulkSetRoles(SetRoleItem[] memory items) public {
		AccessControlFacet ac = AccessControlFacet(address(this));
		ac.requireRole(AccessControlStorage.ADMIN_ROLE, msg.sender);

		for (uint256 i = 0; i < items.length; i++) {
			SetRoleItem memory item = items[i];
			if (item.hasRole) {
				LibAccessControl._grantRole(item.role, item.user);
			} else {
				LibAccessControl._revokeRole(item.role, item.user);
			}
		}
	}

	/// @notice Grant a role to a user. The granting user must have the ADMIN_ROLE
	/// @param user The wallet address of the user to grant the role to
	/// @param role The role to grant
	function grantRole(bytes32 role, address user) public {
		AccessControlFacet ac = AccessControlFacet(address(this));
		ac.requireRole(AccessControlStorage.ADMIN_ROLE, msg.sender);
		LibAccessControl._grantRole(role, user);
		emit MeemRoleGranted(role, user);
	}

	/// @notice Grant a role to a user. The granting user must have the ADMIN_ROLE
	/// @param user The wallet address of the user to revoke the role from
	/// @param role The role to revoke
	function revokeRole(bytes32 role, address user) public {
		AccessControlFacet ac = AccessControlFacet(address(this));
		ac.requireRole(AccessControlStorage.ADMIN_ROLE, msg.sender);
		LibAccessControl._revokeRole(role, user);
		emit MeemRoleRevoked(role, user);
	}

	/// @notice Grant a role to a user. The granting user must have the ADMIN_ROLE
	/// @param user The wallet address of the user to revoke the role from
	/// @param role The role to revoke
	function hasRole(bytes32 role, address user) public view returns (bool) {
		return AccessControlStorage.dataStore().roles[role].members[user];
	}

	function getRoles(bytes32 role) public view returns (address[] memory) {
		return AccessControlStorage.dataStore().rolesList[role];
	}

	function requireRole(bytes32 role, address user) public view {
		AccessControlFacet ac = AccessControlFacet(address(this));
		if (!ac.hasRole(role, user)) {
			revert(AccessControlError.MissingRequiredRole);
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library AccessControlStorage {
	bytes32 internal constant STORAGE_SLOT =
		keccak256('meem.contracts.storage.AccessControl');

	bytes32 constant ADMIN_ROLE = keccak256('ADMIN_ROLE');
	bytes32 constant UPGRADER_ROLE = keccak256('UPGRADER_ROLE');

	struct RoleData {
		mapping(address => bool) members;
	}

	struct DataStore {
		// /** Keeps track of assigned roles */
		mapping(bytes32 => RoleData) roles;
		mapping(bytes32 => address[]) rolesList;
		mapping(bytes32 => mapping(address => uint256)) rolesListIndex;
	}

	function dataStore() internal pure returns (DataStore storage l) {
		bytes32 slot = STORAGE_SLOT;
		assembly {
			l.slot := slot
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Array} from '../utils/Array.sol';
import {AccessControlStorage} from './AccessControlStorage.sol';
import {AccessControlFacet} from './AccessControlFacet.sol';

library LibAccessControl {
	function _grantRole(bytes32 role, address account) internal {
		AccessControlFacet ac = AccessControlFacet(address(this));
		AccessControlStorage.DataStore storage s = AccessControlStorage
			.dataStore();
		if (!ac.hasRole(role, account)) {
			s.roles[role].members[account] = true;
			s.rolesList[role].push(account);
			s.rolesListIndex[role][account] = s.rolesList[role].length - 1;
		}
	}

	function _revokeRole(bytes32 role, address account) internal {
		AccessControlFacet ac = AccessControlFacet(address(this));
		AccessControlStorage.DataStore storage s = AccessControlStorage
			.dataStore();
		if (ac.hasRole(role, account)) {
			s.roles[role].members[account] = false;
			uint256 idx = s.rolesListIndex[role][account];
			Array.removeAt(s.rolesList[role], idx);
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library Array {
	function removeAt(uint256[] storage array, uint256 index)
		internal
		returns (uint256[] memory)
	{
		if (index >= array.length) {
			revert('Index out of range');
		}

		for (uint256 i = index; i < array.length - 1; i++) {
			array[i] = array[i + 1];
		}
		array.pop();
		return array;
	}

	function removeAt(address[] storage array, uint256 index)
		internal
		returns (address[] memory)
	{
		if (index >= array.length) {
			revert('Index out of range');
		}

		for (uint256 i = index; i < array.length - 1; i++) {
			array[i] = array[i + 1];
		}
		array.pop();
		return array;
	}

	function removeAt(string[] storage array, uint256 index)
		internal
		returns (string[] memory)
	{
		if (index >= array.length) {
			revert('Index out of range');
		}

		for (uint256 i = index; i < array.length - 1; i++) {
			array[i] = array[i + 1];
		}
		array.pop();
		return array;
	}

	function isEqual(address[] memory arr1, address[] memory arr2)
		internal
		pure
		returns (bool)
	{
		if (arr1.length != arr2.length) {
			return false;
		}

		for (uint256 i = 0; i < arr1.length; i++) {
			if (arr1[i] != arr2[i]) {
				return false;
			}
		}

		return true;
	}
}