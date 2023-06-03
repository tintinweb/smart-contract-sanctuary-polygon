// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "../utils/structs/EnumerableSetUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal onlyInitializing {
    }

    function __AccessControlEnumerable_init_unchained() internal onlyInitializing {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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
library EnumerableSetUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

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

pragma solidity 0.8.9;

import {AccessControlEnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "./../../core/libs/Errors.sol";

/**
 * @dev Extension of {AccessControlEnumerable} that offer support for maintainer and admin role.
 */
contract StandardAccessControlEnumerableUpgradeable is
    AccessControlEnumerableUpgradeable
{
    struct Roles {
        address admin;
        address maintainer;
    }

    /// @notice Role to allow specific operations on contracts that can be performed by this role
    bytes32 public constant MAINTAINER_ROLE = keccak256("Maintainer");

    /// @notice Storage gaps to avoid issue in future due to upgradability
    uint256[50] private __gap_standardAccessControl;

    /// @notice Modifier to ensure that caller has "MAINTAINER_ROLE" role
    modifier onlyMaintainer() {
        _require(
            hasRole(MAINTAINER_ROLE, msg.sender),
            Errors.CALLER_NOT_MAINTAINER
        );
        _;
    }

    /// @notice Modifier to ensure that caller has "DEFAULT_ADMIN_ROLE" role
    modifier onlyAdmin() {
        _require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            Errors.CALLER_NOT_ADMIN
        );
        _;
    }

    /// @notice setting up DEFAULT_ADMIN_ROLE role and assigning role to _account
    /// @param _account address to assign role to
    function _setMAdmin(address _account) internal {
        _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setupRole(DEFAULT_ADMIN_ROLE, _account);
    }

    /// @notice setting up MAINTAINER_ROLE role and assigning role to _account
    /// @param _account address to assign role to
    function _setMaintainer(address _account) internal {
        _setRoleAdmin(MAINTAINER_ROLE, DEFAULT_ADMIN_ROLE);
        _setupRole(MAINTAINER_ROLE, _account);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

// import {PropertyToken2} from "./propertyToken.sol";
// import {Identity} from "@onchain-id/solidity/contracts/Identity.sol";
// import {ImplementationAuthority} from "@onchain-id/solidity/contracts/proxy/ImplementationAuthority.sol";
// import {IdentityProxy} from "@onchain-id/solidity/contracts/proxy/IdentityProxy.sol";

/**
 * @title Stores common interface names used throughout 0xequity.
 */
library ZeroXInterfaces {
    bytes32 public constant RENT_SHARE = "RentShare";
    bytes32 public constant PRICE_FEED = "PriceFeed";
    bytes32 public constant PROPERTY_TOKEN = "PropertyToken";
    bytes32 public constant IDENTITY = "Identity";
    bytes32 public constant IMPLEMENTATION_AUTHORITY =
        "ImplementationAuthority";
    bytes32 public constant IDENTITY_PROXY = "IdentityProxy";
    bytes32 public constant MAINTAINER_ROLE = keccak256("Maintainer");
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant REWARD_TOKEN = "RewardToken";
    bytes32 public constant SBT = "SBT";
    bytes32 public constant MARKETPLACE = "Marketplace";
    bytes32 public constant TRUSTED_FORWARDER = "TrustedForwarder";
    bytes32 public constant FEEMANAGER = "FeeManager";
    bytes32 public constant XEQ = "XEQ";
    bytes32 public constant OCLROUTER = "OCLRouter";
    bytes32 public constant XJTRY = "XJTRY";
    bytes32 public constant XUSDC = "XUSDC";
    bytes32 public constant SWAPCONTROLLER = "SwapController";
    bytes32 public constant JTRYVAULT = "ERC4626StakingPoolJTRY";
    bytes32 public constant CUSTOMVAULTJTRY = "CustomVaultJTRY";
    bytes32 public constant USDCVAULT = "ERC4626StakingPoolUSDC";
    bytes32 public constant CUSTOMVAULTUSDC = "CustomVaultUSDC";
    bytes32 public constant MANAGER = "Manager";
    bytes32 public constant DFX = "Dfx";
    bytes32 public constant JARVISDEX = "JarvisDex";
    bytes32 public constant TOKENSWHITELIST = "TokensWhitelist";
    bytes32 public constant USDC = "Usdc";
    bytes32 public constant VTRY = "Vtry";
}

// library ZeroXBtyeCodes {
//     bytes public constant PropertyToken = type(PropertyToken2).creationCode;
//     bytes public constant identity = type(Identity).creationCode;
//     bytes public constant implementationAuthority =
//         type(ImplementationAuthority).creationCode;
//     bytes public constant identityProxy = type(IdentityProxy).creationCode;
// }

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

/**
 * @title Provides addresses of the contracts implementing certain interfaces.
 */
interface IFinder {
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
    function getImplementationAddress(
        bytes32 interfaceName
    ) external view returns (address);

    function changeImplementationBytecode(
        bytes32 interfaceName,
        bytes calldata implementationBytecode
    ) external;

    function getImplementationBytecode(
        bytes32 interfaceName
    ) external view returns (bytes memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

interface IManager {
    /**
     * @notice Allow to add roles in contracts
     * @param contracts contracts where to grant the role
     * @param roles Roles id
     * @param accounts Addresses to which give the grant
     */
    function grantRoles(
        address[] calldata contracts,
        bytes32[] calldata roles,
        address[] calldata accounts
    ) external;

    /**
     * @notice Allow to revoke roles in contracts
     * @param contracts where to revoke role from
     * @param roles Roles id
     * @param accounts Addresses to which revoke the grant
     */
    function revokeRoles(
        address[] calldata contracts,
        bytes32[] calldata roles,
        address[] calldata accounts
    ) external;

    /**
     * @notice Allow to renounce roles in contracts
     * @param contracts contracts
     * @param roles Roles id
     */
    function renounceRoles(
        address[] calldata contracts,
        bytes32[] calldata roles
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

/**
 * @title An interface to track a whitelist of addresses.
 */
interface ITokensWhitelist {
    /**
     * @notice Adds an address to the whitelist.
     * @param newToken the new address to add.
     */
    function addToWhitelist(address newToken) external;

    /**
     * @notice Removes an address from the whitelist.
     * @param tokenToRemove The existing address to remove.
     */
    function removeFromWhitelist(address tokenToRemove) external;

    /**
     * @notice Checks whether an address is on the whitelist.
     * @param tokenToCheck The address to check.
     * @return True if `tokenToCheck` is on the whitelist, or False.
     */
    function isOnWhitelist(address tokenToCheck) external view returns (bool);

    /**
     * @notice Gets all addresses that are currently included in the whitelist.
     * @return The list of addresses on the whitelist.
     */
    function getWhitelist() external view returns (address[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {IFinder} from "../interfaces/IFinder.sol";
import {IManager} from "../interfaces/IManager.sol";
import {ZeroXInterfaces} from "../Constants.sol";

/**
 * @title Stores functiions for getting from the finder instances of 0xEquity contracts
 */
library FinderLib {
    /**
     * @param _finder Address of finder
     * @return address of Manager.sol
     */
    function getManager(IFinder _finder) internal view returns (IManager) {
        return
            IManager(_finder.getImplementationAddress(ZeroXInterfaces.MANAGER));
    }

    /**
     * @param _finder Address of finder
     * @return address of Rewardtoken (vTRY for now)
     */
    function getPropertyRentToken(
        IFinder _finder
    ) internal view returns (address) {
        return _finder.getImplementationAddress(ZeroXInterfaces.REWARD_TOKEN);
    }

    /**
     * @param _finder Address of finder
     * @return address of RentShare.sol
     */
    function getRentShareAddress(
        IFinder _finder
    ) internal view returns (address) {
        return _finder.getImplementationAddress(ZeroXInterfaces.RENT_SHARE);
    }

    /**
     * @param _finder Address of finder
     * @return address of DFXRouter deployed by DFX
     */
    function getDFXAddress(IFinder _finder) internal view returns (address) {
        return _finder.getImplementationAddress(ZeroXInterfaces.DFX);
    }

    /**
     * @param _finder Address of finder
     * @return address of JarvisDex.sol
     */
    function getJarvisDexAddress(
        IFinder _finder
    ) internal view returns (address) {
        return _finder.getImplementationAddress(ZeroXInterfaces.JARVISDEX);
    }

    /**
     * @param _finder Address of finder
     * @return address of TokensWhitelist.sol
     */
    function getTokensWhitelistAddress(
        IFinder _finder
    ) internal view returns (address) {
        return
            _finder.getImplementationAddress(ZeroXInterfaces.TOKENSWHITELIST);
    }

    /**
     * @param _finder Address of finder
     * @return address of USDC
     */
    function getUSDC(IFinder _finder) internal view returns (address) {
        return _finder.getImplementationAddress(ZeroXInterfaces.USDC);
    }

    /**
     * @param _finder Address of finder
     * @return address of vTRY
     */
    function getVTRY(IFinder _finder) internal view returns (address) {
        return _finder.getImplementationAddress(ZeroXInterfaces.VTRY);
    }

    /**
     * @param _finder Address of finder
     * @return address of OCLRouter.sol
     */
    function getOclrAddress(IFinder _finder) internal view returns (address) {
        return _finder.getImplementationAddress(ZeroXInterfaces.OCLROUTER);
    }

    /**
     * @param _finder Address of finder
     * @return address of Marketplace.sol
     */
    function getMarketplaceAddress(
        IFinder _finder
    ) internal view returns (address) {
        return _finder.getImplementationAddress(ZeroXInterfaces.MARKETPLACE);
    }

    /**
     * @param _finder Address of finder
     * @return address of xUSDC deployed by 0xEquity
     */
    function getXUSDCAddress(IFinder _finder) internal view returns (address) {
        return _finder.getImplementationAddress(ZeroXInterfaces.XUSDC);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.9;

// solhint-disable

/**
 * @dev Reverts if `condition` is false, with a revert reason containing `errorCode`. Only codes up to 999 are
 * supported.
 * Uses the default '0XEQ' prefix for the error code
 */
function _require(bool condition, uint256 errorCode) pure {
    if (!condition) _revert(errorCode);
}

/**
 * @dev Reverts with a revert reason containing `errorCode`. Only codes up to 999 are supported.
 * Uses the default '0XEQ' prefix for the error code
 */
function _revert(uint256 errorCode) pure {
    _revert(errorCode, 0x584551); // This is the raw byte representation of "0XEQ"
}

/**
 * @dev Reverts with a revert reason containing `errorCode`. Only codes up to 999 are supported.
 */
function _revert(uint256 errorCode, bytes3 prefix) pure {
    uint256 prefixUint = uint256(uint24(prefix));
    // We're going to dynamically create a revert string based on the error code, with the following format:
    // '0XEQ#{errorCode}'
    // where the code is left-padded with zeroes to three digits (so they range from 000 to 999).
    //
    // We don't have revert strings embedded in the contract to save bytecode size: it takes much less space to store a
    // number (8 to 16 bits) than the individual string characters.
    //
    // The dynamic string creation algorithm that follows could be implemented in Solidity, but assembly allows for a
    // much denser implementation, again saving bytecode size. Given this function unconditionally reverts, this is a
    // safe place to rely on it without worrying about how its usage might affect e.g. memory contents.
    assembly {
        // First, we need to compute the ASCII representation of the error code. We assume that it is in the 0-999
        // range, so we only need to convert three digits. To convert the digits to ASCII, we add 0x30, the value for
        // the '0' character.

        let units := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let tenths := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let hundreds := add(mod(errorCode, 10), 0x30)

        // With the individual characters, we can now construct the full string.
        // We first append the '#' character (0x23) to the prefix. In the case of '0XEQ', it results in 0x584551 ('0XEQ#')
        // Then, we shift this by 24 (to provide space for the 3 bytes of the error code), and add the
        // characters to it, each shifted by a multiple of 8.
        // The revert reason is then shifted left by 200 bits (256 minus the length of the string, 7 characters * 8 bits
        // per character = 56) to locate it in the most significant part of the 256 slot (the beginning of a byte
        // array).
        let formattedPrefix := shl(24, add(0x23, shl(8, prefixUint)))

        let revertReason := shl(
            200,
            add(
                formattedPrefix,
                add(add(units, shl(8, tenths)), shl(16, hundreds))
            )
        )

        // We can now encode the reason in memory, which can be safely overwritten as we're about to revert. The encoded
        // message will have the following layout:
        // [ revert reason identifier ] [ string location offset ] [ string length ] [ string contents ]

        // The Solidity revert reason identifier is 0x08c739a0, the function selector of the Error(string) function. We
        // also write zeroes to the next 28 bytes of memory, but those are about to be overwritten.
        mstore(
            0x0,
            0x08c379a000000000000000000000000000000000000000000000000000000000
        )
        // Next is the offset to the location of the string, which will be placed immediately after (20 bytes away).
        mstore(
            0x04,
            0x0000000000000000000000000000000000000000000000000000000000000020
        )
        // The string length is fixed: 7 characters.
        mstore(0x24, 7)
        // Finally, the string itself is stored.
        mstore(0x44, revertReason)

        // Even if the string is only 7 bytes long, we need to return a full 32 byte slot containing it. The length of
        // the encoded message is therefore 4 + 32 + 32 + 32 = 100.
        revert(0, 100)
    }
}

library Errors {
    // ACCESS CONTROL

    uint256 internal constant CALLER_NOT_ADMIN = 0;
    uint256 internal constant CALLER_NOT_MAINTAINER = 1;
    uint256 internal constant CALLER_NOT_MINTER = 2;
    uint256 internal constant CALLER_NOT_BURNER = 3;
    uint256 internal constant CALLER_NOT_MARKETPLACE = 4;
    uint256 internal constant CALLER_NOT_VAULT = 5;
    uint256 internal constant CALLER_NOT_MARKETPLACE_BORROWER = 6;

    // COMMON

    uint256 internal constant ARRAY_LENGTH_MISMATCH = 100;
    uint256 internal constant ZERO_ADDRESS = 101;
    uint256 internal constant ZERO_LENGTH_ARRAY = 102;
    uint256 internal constant ZERO_AMOUNT = 103;
    uint256 internal constant NON_ZERO_NUMBER_REQUIRED = 104;
    uint256 internal constant ERROR_IN_TRUST_FORWARDER_CALL = 105;
    uint256 internal constant SAFE_TRANSFER_FAILED = 106;
    uint256 internal constant SAFE_TRANSFER_FROM_FAILED = 107;
    uint256 internal constant SAFE_APPROVE_FAILED = 108;
    uint256 internal constant SAME_TOKENS = 109;
    uint256 internal constant NON_KYC = 110;
    uint256 internal constant INVALID_TOKEN = 111;
    uint256 internal constant RECEIVER_ON_BLACKLIST = 112;
    uint256 internal constant SENDER_ON_BLACKLIST = 113;

    // SBT

    uint256 internal constant CANT_MINT_TWICE = 200;
    uint256 internal constant WRONG_COMMUNITY_NAME = 201;
    uint256 internal constant TRANSFER_NOT_ALLOWED = 202;
    uint256 internal constant COMMUNITY_DOES_NOT_EXIST = 203;
    uint256 internal constant ALREADY_APPROVED_COMMUNITY = 204;
    uint256 internal constant INPUT_LENGTH_IS_GREATER_THAN_TOTAL = 205;

    // FINDER

    uint256 internal constant IMPLEMENTATION_NOT_FOUND = 300;
    uint256 internal constant EMPTY_BYTECODE = 301;

    // TOKENWHITELIST

    uint256 internal constant TOKEN_ALREADY_WHITELISTED = 400;
    uint256 internal constant TOKEN_NOT_WHITELISTED = 401;

    //MARKETPLACE

    uint256 internal constant ZERO_BALANCE = 500;
    uint256 internal constant PROPERTY_DOES_NOT_EXIST = 501;
    uint256 internal constant PROPERTY_ALREADY_EXIST = 502;
    uint256 internal constant EXCEED_TOTAL_LEGAL_SHARES = 503;
    uint256 internal constant WHOLE_NUMBER_REQUIRED = 504;
    uint256 internal constant BUY_PAUSED = 505;
    uint256 internal constant SELL_PAUSED = 506;
    uint256 internal constant INVALID_CURRENCY = 507;
    uint256 internal constant INVALID_BASE_CURRENCY = 508;
    uint256 internal constant INVALID_OUTPUT_CURRENCY = 509;
    uint256 internal constant INVALID_CASE = 510;
    uint256 internal constant INVALID_FEE_PERCENTAGE = 511;
    uint256 internal constant CALL_IDENTITY_FAILED = 512;
    uint256 internal constant LOCK_AMOUNT_LESS_THAN_TOTAL = 513;
    uint256 internal constant INSUFFICIENT_WLEGAL_LIQUIDITY = 514;
    uint256 internal constant INSUFFICIENT_WLEGAL_LIQUIDITY_MP = 515;

    // PRICEFEED

    uint256 internal constant INVALID_DECIMALS = 600;
    uint256 internal constant INVALID_PAIR_NAME = 601;

    // RENTSHARE

    uint256 internal constant CLAIMING_TWICE_A_WEEK = 700;
    uint256 internal constant SAME_SYMBOL = 701;

    // CUSTOMGAUGE

    uint256 internal constant RE_ENTRANCY = 800;
    uint256 internal constant CALLER_NOT_ACCOUNT = 801;
    uint256 internal constant TOO_MANY_REWARD_TOKENS = 802;
    uint256 internal constant REWARD_RATE_IS_ZERO = 803;
    uint256 internal constant PROVIDED_REWARD_TOO_HIGH = 804;

    // VAULTS
    uint256 internal constant WITHDRAWING_BEFORE_TIME = 900;
    uint256 internal constant ALREADY_INITIALIZED = 901;
    uint256 internal constant INVALID_CONTROLLER = 902;
    uint256 internal constant ZERO_SHARES = 903;
    uint256 internal constant ZERO_ASSETS = 904;
    uint256 internal constant ADDRESS_NOT_REGISTERED = 905;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface IDFXRouter {
    /// @notice view how much target amount a fixed origin amount will swap for
    /// @param _quoteCurrency the address of the quote currency (usually USDC)
    /// @param _origin the address of the origin
    /// @param _target the address of the target
    /// @param _originAmount the origin amount
    /// @return targetAmount_ the amount of target that will be returned
    function viewOriginSwap(
        address _quoteCurrency,
        address _origin,
        address _target,
        uint256 _originAmount
    ) external view returns (uint256 targetAmount_);

    /// @notice swap a dynamic origin amount for a fixed target amount
    /// @param _quoteCurrency the address of the quote currency (usually USDC)
    /// @param _origin the address of the origin
    /// @param _target the address of the target
    /// @param _originAmount the origin amount
    /// @param _minTargetAmount the minimum target amount
    /// @param _deadline deadline in block number after which the trade will not execute
    /// @return targetAmount_ the amount of target that has been swapped for the origin amount
    function originSwap(
        address _quoteCurrency,
        address _origin,
        address _target,
        uint256 _originAmount,
        uint256 _minTargetAmount,
        uint256 _deadline
    ) external returns (uint256 targetAmount_);

    /// @notice view how much of the origin currency the target currency will take
    /// @param _quoteCurrency the address of the quote currency (usually USDC)
    /// @param _origin the address of the origin
    /// @param _target the address of the target
    /// @param _targetAmount the target amount
    /// @return originAmount_ the amount of target that has been swapped for the origin
    function viewTargetSwap(
        address _quoteCurrency,
        address _origin,
        address _target,
        uint256 _targetAmount
    ) external view returns (uint256 originAmount_);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface IJarvisDex {
    /**
     * @notice Mint synthetic tokens using fixed amount of collateral
     * @notice This calculate the price using on chain price feed
     * @notice User must approve collateral transfer for the mint request to succeed
     * @param mintParams Input parameters for minting (see MintParams struct)
     * @return syntheticTokensMinted Amount of synthetic tokens minted by a user
     * @return feePaid Amount of collateral paid by the user as fee
     */
    function mint(
        MintParams calldata mintParams
    ) external returns (uint256 syntheticTokensMinted, uint256 feePaid);

    // For JARVIS_DEX contract
    function mint(
        MintParams calldata mintParams,
        address poolAddress
    ) external returns (uint256 syntheticTokensMinted, uint256 feePaid);

    /**
     * @notice Redeem amount of collateral using fixed number of synthetic token
     * @notice This calculate the price using on chain price feed
     * @notice User must approve synthetic token transfer for the redeem request to succeed
     * @param redeemParams Input parameters for redeeming (see RedeemParams struct)
     * @return collateralRedeemed Amount of collateral redeem by user
     * @return feePaid Amount of collateral paid by user as fee
     */
    function redeem(
        RedeemParams calldata redeemParams
    ) external returns (uint256 collateralRedeemed, uint256 feePaid);

    // For JARVIS_DEX contract
    function redeem(
        RedeemParams calldata redeemParams,
        address poolAddress
    ) external returns (uint256 collateralRedeemed, uint256 feePaid);

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
     * @notice Returns the collateral amount will be received and fees will be paid in exchange for an input amount of synthetic tokens
     * @notice This function is only trading-informative, it doesn't check edge case conditions like lending manager dust and undercap of one or more LPs
     * @param  _syntTokensAmount Amount of synthetic tokens to be exchanged
     * @return collateralAmountReceived Collateral amount will be received by the user
     * @return feePaid Collateral fee will be paid
     */
    function getRedeemTradeInfo(
        uint256 _syntTokensAmount
    ) external view returns (uint256 collateralAmountReceived, uint256 feePaid);

    /**
     * @notice Returns the synthetic tokens will be received and fees will be paid in exchange for an input collateral amount
     * @notice This function is only trading-informative, it doesn't check edge case conditions like lending manager dust and reverting due to dust splitting
     * @param _collateralAmount Input collateral amount to be exchanged
     * @return synthTokensReceived Synthetic tokens will be minted
     * @return feePaid Collateral fee will be paid
     */
    function getMintTradeInfo(
        uint256 _collateralAmount
    ) external view returns (uint256 synthTokensReceived, uint256 feePaid);

    /**
     * @return return token that is used as collateral
     */
    function collateralToken() external view returns (address);

    /**
     * @return return token that will be minted agaisnt collateral
     */
    function syntheticToken() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;
import {SelfPermitUpgradeable} from "./../SelfPermit/SelfPermitUpgradeable.sol";
import "./../core/interfaces/IFinder.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ZeroXInterfaces} from "./../core/Constants.sol";
import {StandardAccessControlEnumerableUpgradeable} from "./../common/roles/StandardAccessControlEnumerableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {SafeERC20Upgradeable, IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./../Interfaces/IMarketplace.sol";
import {FinderLib} from "./../core/libs/CoreLibs.sol";
import "./../core/libs/Errors.sol";
import "./IDFXRouter.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./../Interfaces/IMetaTx.sol";

import "./../Interfaces/IPriceFeed.sol";
import "./../Interfaces/IOCLRouter.sol";
import "./../core/interfaces/ITokensWhitelist.sol";
import "./IJarvisDex.sol";

import {ERC2771ContextUpgradeable, ContextUpgradeable} from "./../utils/ERC2771ContextUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

// import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import "./../Vaults/CustomVault.sol";

/**
 * @title Enables to Buy/Sell Property on Marketplace, swapping of JTRY/USDC, with Simple and Permit/Metatx appoach
 */
contract OCLRouter is
    IOCLRouter,
    Initializable,
    UUPSUpgradeable,
    StandardAccessControlEnumerableUpgradeable,
    ERC2771ContextUpgradeable,
    SelfPermitUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using FinderLib for IFinder;

    /// @notice Role required to Upgrade the contract
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /// @notice Representation of 100%. Equals t0 10000 that means 100 = 1%
    uint public PERCENTAGE_BASED_POINT;

    /// @notice address of finder to fetch addresses
    address public finder;

    //----------------------------------------
    //  EVENTS
    //----------------------------------------

    event MintOnJarvis(DexSwapArgs swapArgs);
    event RedeemOnJarvis(DexSwapArgs swapArgs);
    event PropertyBought(
        IMarketplace.swapArgs swapArgs,
        uint amountSpent,
        bool isFeeInXeq
    );
    event PropertySold(IMarketplace.swapArgs swapArgs, bool isFeeInXeq);

    event SwappedOnDfx(DexSwapArgs swapArgs, uint swappedAmount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the contract.
     * @param _finder address of finder to fetch protocol's used addresses
     */
    function initialize(address _finder) public initializer nonReentrant {
        __AccessControlEnumerable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        finder = _finder;
        address manager = address(IFinder(finder).getManager());
        _grantRole(DEFAULT_ADMIN_ROLE, manager);
        _grantRole(UPGRADER_ROLE, manager);
        _grantRole(MAINTAINER_ROLE, _msgSender());
        PERCENTAGE_BASED_POINT = 10000; // 100 is 1%
    }

    /**
     * @notice Allows user to sell property using Permit and get USDC as output currency
     * @param _metaTxArgsSell args to perform metaTx on Property token
     * @param _swapArgs details to sell property see IMarketplace.swapArgs
     * @param _dexSwapArgs to swap tokens(Jtry) recieved from Marketplace to USDC
     * @param _isFeeInXeq true: fee to be deducted in XEQ, false: fee to be duducted in traded currency
     * @param _jTry address of property baseCurrency
     * @return amount od USDC received by user after selling Property Token
     */
    function sellPropertyWithPermitInUSDC(
        IMetaTx.MetaTxPermitArgs memory _metaTxArgsSell,
        IMarketplace.swapArgs memory _swapArgs,
        DexSwapArgs memory _dexSwapArgs,
        bool _isFeeInXeq,
        address _marketplace,
        address _jTry
    ) external returns (uint) {
        IMetaTx(_swapArgs.from).permit(
            _metaTxArgsSell.owner,
            _metaTxArgsSell.spender,
            _metaTxArgsSell.value,
            _metaTxArgsSell.deadline,
            _metaTxArgsSell.v,
            _metaTxArgsSell.r,
            _metaTxArgsSell.s
        );
        return
            sellPropertyInUSDC(
                _swapArgs,
                _dexSwapArgs,
                _isFeeInXeq,
                _marketplace,
                _jTry
            );
    }

    /**
     * @notice Allows user to sell property and get USDC as output currency
     * @param _swapArgs details to sell property see IMarketplace.swapArgs
     * @param _dexSwapArgs to swap tokens(Jtry) recieved from Marketplace to USDC
     * @param _isFeeInXeq true: fee to be deducted in XEQ, false: fee to be duducted in traded currency
     * @param _jTry address of property baseCurrency
     * @return amount od USDC received by user after selling Property Token
     */
    function sellPropertyInUSDC(
        IMarketplace.swapArgs memory _swapArgs,
        DexSwapArgs memory _dexSwapArgs,
        bool _isFeeInXeq,
        address _marketplace,
        address _jTry
    ) public returns (uint) {
        _require(_jTry != _swapArgs.to, Errors.SAME_TOKENS);
        address tokensWhitelist = IFinder(finder).getImplementationAddress(
            ZeroXInterfaces.TOKENSWHITELIST
        );
        _require(
            ITokensWhitelist(tokensWhitelist).isOnWhitelist(_swapArgs.to),
            Errors.TOKEN_NOT_WHITELISTED
        );
        address orignalToAddress = _swapArgs.to;
        _swapArgs.to = _jTry;
        address orignalReceipient = _swapArgs.recipient;
        _swapArgs.recipient = address(this);

        uint tokensReceived = sellProperty(
            _swapArgs,
            _marketplace,
            _isFeeInXeq
        );

        uint usdcAmount;
        _dexSwapArgs._origin = _jTry;
        _dexSwapArgs._target = orignalToAddress;
        _dexSwapArgs._originAmount = tokensReceived;
        _dexSwapArgs._receipient = address(this);
        // DexSwapArgs memory _dexSwapArgs;
        if (_dexSwapArgs._isSwapOnDfx) {
            _dexSwapArgs._quoteCurrency = orignalToAddress;
            IERC20Upgradeable(_jTry).safeIncreaseAllowance(
                IFinder(finder).getDFXAddress(),
                tokensReceived
            );
            usdcAmount = _dfxSwapHelper(_dexSwapArgs);
        } else {
            IERC20Upgradeable(_jTry).safeIncreaseAllowance(
                IFinder(finder).getJarvisDexAddress(),
                tokensReceived
            );
            usdcAmount = _mintAndRedeemHelper(_dexSwapArgs);
        }

        IERC20Upgradeable(orignalToAddress).safeTransfer(
            orignalReceipient,
            usdcAmount
        );
        return usdcAmount;
    }

    /**
     * @notice Allows user to sell property using Permit and get propertyBase Curreny as output token
     * @param _metaTxArgsSell args to perform metaTx on Property token
     * @param _swapArgs details to sell property see IMarketplace.swapArgs
     * @param _isFeeInXeq true: fee to be deducted in XEQ, false: fee to be duducted in traded currency
     * @param _marketplace address of marketplace to swap tokens from
     * @return amount baseCurrency tokens received by user after selling Property Token
     */
    function approveAndSellProperty(
        IMetaTx.MetaTxPermitArgs memory _metaTxArgsSell,
        IMarketplace.swapArgs memory _swapArgs,
        bool _isFeeInXeq,
        address _marketplace
    ) external returns (uint) {
        IMetaTx(_swapArgs.from).permit(
            _metaTxArgsSell.owner,
            _metaTxArgsSell.spender,
            _metaTxArgsSell.value,
            _metaTxArgsSell.deadline,
            _metaTxArgsSell.v,
            _metaTxArgsSell.r,
            _metaTxArgsSell.s
        );
        return sellProperty(_swapArgs, _marketplace, _isFeeInXeq);
    }

    /**
     * @notice Allows user to sell property with baseCurrency
     * @param _swapArgs details to sell property see IMarketplace.swapArgs
     * @param _marketplace address of marketplace to swap tokens from
     * @param _isFeeInXeq true: fee to be deducted in XEQ, false: fee to be duducted in traded currency
     * @return amount baseCurrency tokens received by user after selling Property Token
     */
    function sellProperty(
        IMarketplace.swapArgs memory _swapArgs,
        address _marketplace,
        bool _isFeeInXeq
    ) public nonReentrant returns (uint) {
        address tokensWhitelist = IFinder(finder).getImplementationAddress(
            ZeroXInterfaces.TOKENSWHITELIST
        );
        _require(
            ITokensWhitelist(tokensWhitelist).isOnWhitelist(_swapArgs.to),
            Errors.TOKEN_NOT_WHITELISTED
        );
        IERC20Upgradeable(_swapArgs.from).safeTransferFrom(
            _msgSender(),
            address(this),
            _swapArgs.amountOfShares
        );

        IERC20Upgradeable(_swapArgs.from).safeIncreaseAllowance(
            _marketplace,
            _swapArgs.amountOfShares
        );

        emit PropertySold(_swapArgs, _isFeeInXeq);
        // now buying property
        return IMarketplace(_marketplace).swap(_swapArgs, _isFeeInXeq);
    }

    /**
     * @notice Allows user to swap from USDC to JTRY
     * @param _metaTxArgs args to perform metaTx on USDC
     * @param _swapArgs details of where to perform the swap
     * @return amount of JTRY received
     */
    function swapWithMetaTx(
        IMetaTx.MetaTxExecuteArgs calldata _metaTxArgs,
        DexSwapArgs memory _swapArgs
    ) external returns (uint) {
        IMetaTx(_swapArgs._origin).executeMetaTransaction(
            _metaTxArgs.userAddress,
            _metaTxArgs.functionSignature,
            _metaTxArgs.sigR,
            _metaTxArgs.sigS,
            _metaTxArgs.sigV
        );

        return
            _swapArgs._isSwapOnDfx
                ? swapOnDfx(_swapArgs)
                : mintOrRedeemOnJaris(_swapArgs);
    }

    /**
     * @notice Allows user to swap from JTRY to USDC
     * @param _metaTxArgs args to perform permit on JTRY
     * @param _swapArgs details of where to perform the swap
     * @return amount of USDC received
     */
    function swapWithPermit(
        IMetaTx.MetaTxPermitArgs calldata _metaTxArgs,
        DexSwapArgs memory _swapArgs
    ) external returns (uint) {
        IMetaTx(_swapArgs._origin).permit(
            _metaTxArgs.owner,
            _metaTxArgs.spender,
            _metaTxArgs.value,
            _metaTxArgs.deadline,
            _metaTxArgs.v,
            _metaTxArgs.r,
            _metaTxArgs.s
        );

        return
            _swapArgs._isSwapOnDfx
                ? swapOnDfx(_swapArgs)
                : mintOrRedeemOnJaris(_swapArgs);
    }

    /**
     * @notice Allows user to swap assets using DFX
     * @param _swapArgs details the swap
     * @return amount of target token received
     */
    function swapOnDfx(
        DexSwapArgs memory _swapArgs
    ) public nonReentrant returns (uint) {
        address tokensWhitelist = IFinder(finder).getImplementationAddress(
            ZeroXInterfaces.TOKENSWHITELIST
        );

        _require(
            ITokensWhitelist(tokensWhitelist).isOnWhitelist(_swapArgs._origin),
            Errors.TOKEN_NOT_WHITELISTED
        );
        _require(
            ITokensWhitelist(tokensWhitelist).isOnWhitelist(_swapArgs._target),
            Errors.TOKEN_NOT_WHITELISTED
        );

        IERC20Upgradeable(_swapArgs._origin).safeTransferFrom(
            _msgSender(),
            address(this),
            _swapArgs._originAmount
        );
        address DFX_ROUTER = IFinder(finder).getDFXAddress();
        IERC20Upgradeable(_swapArgs._origin).safeIncreaseAllowance(
            address(DFX_ROUTER),
            _swapArgs._originAmount
        );

        uint swappedAmount = _dfxSwapHelper(_swapArgs);

        IERC20Upgradeable(_swapArgs._target).safeTransfer(
            _swapArgs._receipient,
            swappedAmount
        );
        return swappedAmount;
    }

    function _dfxSwapHelper(
        DexSwapArgs memory _swapArgs
    ) private returns (uint) {
        address DFX_ROUTER = IFinder(finder).getDFXAddress();
        uint swappedAmount = IDFXRouter(DFX_ROUTER).originSwap(
            _swapArgs._quoteCurrency,
            _swapArgs._origin,
            _swapArgs._target,
            _swapArgs._originAmount,
            _swapArgs._minTargetAmount,
            _swapArgs._deadline
        );
        emit SwappedOnDfx(_swapArgs, swappedAmount);
        return swappedAmount;
    }

    /**
     * @notice Allows user to mint and redeem pairs of assets on Jarvis' synthereumMultiLpLiquidityPool
     * @param _swapArgs details the swap
     * @return amount minted or redeemed received
     */
    function mintOrRedeemOnJaris(
        DexSwapArgs memory _swapArgs
    ) public nonReentrant returns (uint) {
        address tokensWhitelist = IFinder(finder).getImplementationAddress(
            ZeroXInterfaces.TOKENSWHITELIST
        );

        _require(
            ITokensWhitelist(tokensWhitelist).isOnWhitelist(_swapArgs._origin),
            Errors.TOKEN_NOT_WHITELISTED
        );
        _require(
            ITokensWhitelist(tokensWhitelist).isOnWhitelist(_swapArgs._target),
            Errors.TOKEN_NOT_WHITELISTED
        );

        IERC20Upgradeable(_swapArgs._origin).safeTransferFrom(
            _msgSender(),
            address(this),
            _swapArgs._originAmount
        );
        IERC20Upgradeable(_swapArgs._origin).safeIncreaseAllowance(
            IFinder(finder).getJarvisDexAddress(),
            _swapArgs._originAmount
        );
        return _mintAndRedeemHelper(_swapArgs);
    }

    function _mintAndRedeemHelper(
        DexSwapArgs memory _swapArgs
    ) private returns (uint) {
        address poolCollateralToken = IJarvisDex(_swapArgs._quoteCurrency)
            .collateralToken();
        // if _origin is pool's collateral means we need to mint else we need to redeem
        address JARVIS_DEX = IFinder(finder).getJarvisDexAddress();
        uint swappedAmount;
        if (poolCollateralToken == _swapArgs._origin) {
            IJarvisDex.MintParams memory mintParams = IJarvisDex.MintParams(
                _swapArgs._minTargetAmount,
                _swapArgs._originAmount,
                _swapArgs._deadline,
                _swapArgs._receipient
            );
            (swappedAmount, ) = IJarvisDex(JARVIS_DEX).mint(
                mintParams,
                _swapArgs._quoteCurrency
            );
            emit MintOnJarvis(_swapArgs);
        } else {
            IJarvisDex.RedeemParams memory redeemParams = IJarvisDex
                .RedeemParams(
                    _swapArgs._originAmount,
                    _swapArgs._minTargetAmount,
                    _swapArgs._deadline,
                    _swapArgs._receipient
                );
            (swappedAmount, ) = IJarvisDex(JARVIS_DEX).redeem(
                redeemParams,
                _swapArgs._quoteCurrency
            );
            emit RedeemOnJarvis(_swapArgs);
        }
        return swappedAmount;
    }

    /// @notice view how much target amount a fixed origin amount will swap for
    /// @param _quoteCurrency the address of the quote currency (usually USDC)
    /// @param _origin the address of the origin
    /// @param _target the address of the target
    /// @param _originAmount the origin amount
    /// @return the amount of target that will be returned
    function getMinTargetAmount(
        address _quoteCurrency,
        address _origin,
        address _target,
        uint256 _originAmount
    ) external view returns (uint) {
        address DFX_ROUTER = IFinder(finder).getDFXAddress();
        return
            IDFXRouter(DFX_ROUTER).viewOriginSwap(
                _quoteCurrency,
                _origin,
                _target,
                _originAmount
            );
    }

    /**
     * @notice Allows user to buy property using USDC using Metatx
     * @param _metaTxArgsBuy args to perform metaTx on payment(USDC) token
     * @param _swapArgs details to buy property see IMarketplace.swapArgs
     * @param _isFeeInXeq true: fee to be deducted in XEQ, false: fee to be duducted in traded currency
     * @param _marketplace address of marketplace to swap tokens from
     * @return amount paid to buy property tokens
     */
    function approveAndBuyPropertyWithMetaTx(
        IMetaTx.MetaTxExecuteArgs memory _metaTxArgsBuy,
        IMarketplace.swapArgs memory _swapArgs,
        bool _isFeeInXeq,
        address _marketplace
    ) external returns (uint) {
        address tokensWhitelist = IFinder(finder).getImplementationAddress(
            ZeroXInterfaces.TOKENSWHITELIST
        );

        _require(
            ITokensWhitelist(tokensWhitelist).isOnWhitelist(_swapArgs.from),
            Errors.TOKEN_NOT_WHITELISTED
        );

        // // first executing approve on 'from' address from signature
        IMetaTx(_swapArgs.from).executeMetaTransaction(
            _metaTxArgsBuy.userAddress,
            _metaTxArgsBuy.functionSignature,
            _metaTxArgsBuy.sigR,
            _metaTxArgsBuy.sigS,
            _metaTxArgsBuy.sigV
        );

        return buyProperty(_swapArgs, _marketplace, _isFeeInXeq);
    }

    /**
     * @notice Allows user to buy property using jtry using permit
     * @param _metaTxArgs args to perform metaTx on jtry token
     * @param _swapArgs details to buy property see IMarketplace.swapArgs
     * @param _isFeeInXeq true: fee to be deducted in XEQ, false: fee to be duducted in traded currency
     * @param _marketplace address of marketplace to swap tokens from
     * @return amount paid to buy property tokens
     */
    function approveAndBuyPropertyWithPermit(
        IMetaTx.MetaTxPermitArgs memory _metaTxArgs,
        IMarketplace.swapArgs memory _swapArgs,
        bool _isFeeInXeq,
        address _marketplace
    ) external returns (uint) {
        IMetaTx(_swapArgs.from).permit(
            _metaTxArgs.owner,
            _metaTxArgs.spender,
            _metaTxArgs.value,
            _metaTxArgs.deadline,
            _metaTxArgs.v,
            _metaTxArgs.r,
            _metaTxArgs.s
        );
        return buyProperty(_swapArgs, _marketplace, _isFeeInXeq);
    }

    /**
     * @notice Allows user to buy property with USDC. Converts USDC to JTRY then buys from jtry
     * @param _swapArgs details to buy property see IMarketplace.swapArgs
     * @param _marketplace address of marketplace to swap tokens from
     * @param _isFeeInXeq true: fee to be deducted in XEQ, false: fee to be duducted in traded currency
     * @param jtry propertyBase currency address
     * @param _dexSwapArgs details to mint jtry on SynthereumMultiLpLiquidityPool
     * @return amount paid to buy property tokens
     */
    function buyPropertyWithUSDC(
        IMarketplace.swapArgs memory _swapArgs,
        address _marketplace,
        bool _isFeeInXeq,
        address jtry,
        DexSwapArgs memory _dexSwapArgs
    ) external nonReentrant returns (uint) {
        address tokensWhitelist = IFinder(finder).getImplementationAddress(
            ZeroXInterfaces.TOKENSWHITELIST
        );

        _require(
            ITokensWhitelist(tokensWhitelist).isOnWhitelist(_swapArgs.from),
            Errors.TOKEN_NOT_WHITELISTED
        );
        uint amountTaTransferFromUser = getPropertyPriceWithFees(
            _marketplace,
            _swapArgs.from,
            _swapArgs.to,
            true,
            _swapArgs.amountOfShares,
            0 // set to zero because it does not matter as we are buying
        );

        IERC20Upgradeable(_swapArgs.from).safeTransferFrom(
            _msgSender(),
            address(this),
            amountTaTransferFromUser
        );
        address JARVIS_DEX = IFinder(finder).getJarvisDexAddress();
        IERC20Upgradeable(_swapArgs.from).safeIncreaseAllowance(
            JARVIS_DEX,
            amountTaTransferFromUser
        );
        _dexSwapArgs._receipient = address(this);
        _dexSwapArgs._originAmount = amountTaTransferFromUser;
        uint amountOfJtry = _mintAndRedeemHelper(_dexSwapArgs);
        IERC20Upgradeable(jtry).safeIncreaseAllowance(
            _marketplace,
            amountOfJtry
        );
        _swapArgs.from = jtry;
        // now buying property
        uint amountPaid = IMarketplace(_marketplace).swap(
            _swapArgs,
            _isFeeInXeq
        );

        emit PropertyBought(_swapArgs, amountOfJtry, _isFeeInXeq);
        return amountPaid;
    }

    /**
     * @notice Allows user to buy property with USDC and baseCurrency directly on Marketplace.
     * @param _swapArgs details to buy property see IMarketplace.swapArgs
     * @param _marketplace address of marketplace to swap tokens from
     * @param _isFeeInXeq true: fee to be deducted in XEQ, false: fee to be duducted in traded currency
     * @return amount paid to buy property tokens
     */
    function buyProperty(
        IMarketplace.swapArgs memory _swapArgs,
        address _marketplace,
        bool _isFeeInXeq
    ) public nonReentrant returns (uint) {
        address tokensWhitelist = IFinder(finder).getImplementationAddress(
            ZeroXInterfaces.TOKENSWHITELIST
        );

        _require(
            ITokensWhitelist(tokensWhitelist).isOnWhitelist(_swapArgs.from),
            Errors.TOKEN_NOT_WHITELISTED
        );
        uint amountToTransferFromUser = getPropertyPriceWithFees(
            _marketplace,
            _swapArgs.from,
            _swapArgs.to,
            true,
            _swapArgs.amountOfShares,
            0 // set to zero because it does not matter as we are buying
        );
        IERC20Upgradeable(_swapArgs.from).safeTransferFrom(
            _msgSender(),
            address(this),
            amountToTransferFromUser
        );

        IERC20Upgradeable(_swapArgs.from).safeIncreaseAllowance(
            _marketplace,
            amountToTransferFromUser
        );
        // now buying property
        uint amount = IMarketplace(_marketplace).swap(_swapArgs, _isFeeInXeq);

        emit PropertyBought(_swapArgs, amountToTransferFromUser, _isFeeInXeq);

        return amount;
    }

    /**
     * @param _marketplace address of marketplace to swap tokens from
     * @param from token to buy property tokens from
     * @param to property tokens address
     * @param isBuyProperty true: buying property, false: sell property
     * @param amountOfTokens amount of property tokens to buy/sell
     * @param buyBackPoolFeesPercentage fees charged by ERC4626Vault on property sell
     * @return amount received or paid to sell or buy property repectively with fees
     */
    function getPropertyPriceWithFees(
        address _marketplace,
        address from,
        address to,
        bool isBuyProperty,
        uint amountOfTokens,
        uint buyBackPoolFeesPercentage
    ) public view returns (uint) {
        (
            IPriceFeed.Property memory _property,
            address _priceFeed,
            address _currencyToFeed
        ) = IMarketplace(_marketplace).getPropertyPrice(from, to);
        uint priceWithFees;

        _property.price = IMarketplace(_marketplace).propertyQuotePrice(
            IMarketplace.QuotePriceParams(
                amountOfTokens,
                _property.currency,
                from,
                _property.priceFeed,
                _currencyToFeed,
                _property.price,
                _priceFeed
            )
        );

        uint feePercentage;
        uint propertyPrice = _property.price;

        if (isBuyProperty) {
            feePercentage = IMarketplace(_marketplace).getBuyFeePercentage();
            priceWithFees =
                propertyPrice +
                ((propertyPrice * feePercentage) / 10000);
        } else {
            feePercentage =
                IMarketplace(_marketplace).getSellFeePercentage() +
                buyBackPoolFeesPercentage;
            priceWithFees =
                propertyPrice -
                ((propertyPrice * feePercentage) / 10000);
        }
        return priceWithFees;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {}

    /**
     * @param _tokenAddress token to rescue
     * @param _amount amount to rescue
     */
    function rescueToken(
        address _tokenAddress,
        uint256 _amount
    ) external onlyMaintainer nonReentrant {
        IERC20Upgradeable(_tokenAddress).safeTransfer(_msgSender(), _amount);
    }

    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }

    /**
     * @notice Check if an address is the trusted forwarder
     * @param  _forwarder Address to check
     * @return True is the input address is the trusted forwarder, otherwise false
     */

    function isTrustedForwarder(
        address _forwarder
    ) public view override returns (bool) {
        try
            IFinder(finder).getImplementationAddress(
                ZeroXInterfaces.TRUSTED_FORWARDER
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
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.9;

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

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import {IPriceFeed} from "./IPriceFeed.sol";

/// @dev interface
interface IMarketplace {
    event NewPropertyAdded(address legalToken, address wLegalToken);
    event PriceUpdated(address token, uint256 price);
    event NewIdentity(address Identity);
    event Swaped(address from, address to, uint256 amountIn, uint256 amountOut);
    event NewBid(
        address token,
        address bidder,
        uint256 amount,
        uint256 amountPerToken
    );
    event BuyFeesUpdated(uint newPercentage);
    event SellFeesUpdated(uint newPercentage);
    event FeeReceiverUpdated(address feeReceiver);
    event LiquidityWithdrawed(
        address to,
        address wLegalToken,
        uint amountToSend
    );

    event MarketplaceBorrowerUpdated(address _mpBorrower);

    event PropertyMigrated(address legalToken, address WLegalShares);

    enum State {
        Active,
        Paused
    }

    event BuyStateChanged(State);
    event SellStateChanged(State);
    event newAsk(
        address token,
        address offerer,
        uint256 amount,
        uint256 amountPerToken
    );
    struct property {
        address WLegalShares;
        uint256 totalLegalShares;
        uint256 lockedLegalShares;
        uint256 tokensPerLegalShares;
    }
    struct offer {
        uint256 amount;
        uint256 amountPerToken;
    }
    struct swapArgs {
        address from;
        address to;
        uint256 amountOfShares;
        address recipient;
    }

    struct Storage {
        uint256 PERCENTAGE_BASED_POINT;
        State buyState;
        State sellState;
        uint256 identityCount;
        uint256 poolId;
        address finder;
        address identity;
        address IAuthority;
        uint256 buyFeePercentage;
        uint256 sellFeePercentage;
        address feeReceiver;
        mapping(address => property) legalToProperty;
        mapping(bytes => bool) salts;
        mapping(address => uint256) tokenPrice;
        mapping(address => bool) tokenExisits;
        mapping(address => uint256) wLegalToPoolId;
        address[] legalProperties;
        mapping(address => mapping(address => uint256)) wLegalToTokens;
        address marketPlaceBorrower;
        address baseCurrency;
        address tokenWhitelist;
        mapping(address => mapping(BuySellState => State)) propertyToBuySellState;
        uint maxFeePercentage;
        uint pendingWithdrawalRequestTimestamp;
    }

    enum BuySellState {
        BuyState,
        SellState
    }

    struct ConstructorParams {
        address finder;
        uint256 buyFeePercentage;
        uint256 sellFeePercentage;
        address feeReceiver;
        address baseCurrency;
    }

    struct InitializationParams {
        uint256 PERCENTAGE_BASED_POINT;
        State buyState;
        State sellState;
        address finder;
        uint256 buyFeePercentage;
        uint256 sellFeePercentage;
        address feeReceiver;
        address baseCurrency;
    }

    struct AddPropertyParams {
        address legalToken;
        uint256 legalSharesToLock;
        uint256 tokensPerLegalShares;
        uint256 totalLegalShares;
        IPriceFeed.Property propertyDetails;
    }

    struct AddPropertyParams2 {
        address legalToken;
        uint256 legalSharesToLock;
        uint256 tokensPerLegalShares;
        uint256 totalLegalShares;
        IPriceFeed.Property propertyDetails;
        address WLegalShares;
    }

    struct QuotePriceParams {
        uint256 amountOfShares;
        address propertyCurrency;
        address quoteCurrency;
        address propertyPriceFeed;
        address quotePriceFeed;
        uint256 propertyPrice;
        address priceFeed;
    }

    struct TransferPropertyParams {
        uint256 amountOfShares;
        address to;
        address from;
        bool isBuying;
        uint256 quotePrice;
    }

    function swap(
        swapArgs memory args,
        bool isFeeInXEQ
    ) external returns (uint256);

    function getPropertyPrice(
        address from,
        address to
    )
        external
        view
        returns (
            IPriceFeed.Property memory,
            address _priceFeed,
            address _currencyToFeed
        );

    function getBuyFeePercentage() external view returns (uint256);

    function getSellFeePercentage() external view returns (uint256);

    function propertyQuotePrice(
        IMarketplace.QuotePriceParams memory _quoteParams
    ) external view returns (uint256 quotePrice);

    // function getLegalProperties()
    //     external
    //     view
    //     returns (address[] memory properties);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

interface IMetaTx {
    struct MetaTxExecuteArgs {
        address userAddress;
        bytes functionSignature;
        bytes32 sigR;
        bytes32 sigS;
        uint8 sigV;
    }

    struct MetaTxPermitArgs {
        address owner;
        address spender;
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) external payable returns (bytes memory);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "./IMetaTx.sol";

interface IOCLRouter {
    // structs
    struct DexSwapArgs {
        address _quoteCurrency;
        address _origin;
        address _target;
        uint256 _originAmount;
        uint256 _minTargetAmount;
        uint256 _deadline;
        address _receipient;
        bool _isSwapOnDfx;
    }

    function swapOnDfx(
        DexSwapArgs memory _swapArgs
    ) external returns (uint swappedAmount);

    function mintOrRedeemOnJaris(
        DexSwapArgs memory _swapArgs
    ) external returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IPriceFeed {
    struct Property {
        uint256 price;
        address currency;
        address priceFeed;
    }

    struct ScalePriceParams {
        int256 price;
        uint8 priceDecimals;
        uint8 decimals;
    }

    struct Storage {
        mapping(string => IPriceFeed.Property) propertyDetails;
        mapping(address => address) currencyToFeed;
        mapping(string => address) nameToFeed;
    }

    function feedPriceChainlink(
        address _of
    ) external view returns (uint256 latestPrice);


    function getSharePriceInBaseCurrency(
        string memory _propertySymbol,
        address currency
    ) external view returns (uint256);

    //---------------------------------------------------------------------
    function setPropertyDetails(
        string memory _propertySymbol,
        Property calldata _propertyDetails
    ) external;

    function getPropertyDetail(
        string memory _propertySymbol
    ) external view returns (Property memory property);

    //---------------------------------------------------------------------

    // function setCurrencyToFeed(address _currency, address _feed) external;

    function getCurrencyToFeed(
        address _currency
    ) external view returns (address);
    //---------------------------------------------------------------------
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.9;

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
pragma solidity 0.8.9;

import {ISelfPermit} from "./../Interfaces/ISelfPermit.sol";
import {IERC20PermitAllowed} from "./../Interfaces/IERC20PermitAllowed.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import {ERC2771ContextUpgradeable} from "./../utils/ERC2771ContextUpgradeable.sol";

/// @title Self Permit
/// @notice Functionality to call permit on any EIP-2612-compliant token for use in the route
/// @dev These functions are expected to be embedded in multicalls to allow EOAs to approve a contract and call a function
/// that requires an approval in a single transaction.
abstract contract SelfPermitUpgradeable is ISelfPermit, ERC2771ContextUpgradeable {
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
            IERC20(token).allowance(_msgSender(), address(this)) <
            type(uint256).max
        ) selfPermitAllowed(token, nonce, expiry, v, r, s);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771ContextUpgradeable is ContextUpgradeable {
    function isTrustedForwarder(
        address forwarder
    ) public view virtual returns (bool);

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

    function _msgData()
        internal
        view
        virtual
        override
        returns (bytes calldata)
    {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}