// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

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
                        StringsUpgradeable.toHexString(account),
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

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
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

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
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 52
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Elliptic Curve Library
 * @dev Library providing arithmetic operations over elliptic curves.
 * This library does not check whether the inserted points belong to the curve
 * `isOnCurve` function should be used by the library user to check the aforementioned statement.
 * @author Witnet Foundation
 */
library EllipticCurve {
    // CONSTANTS FOR CURVE secp256k1
    uint256 internal constant CurveGx =
        0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798; // x-coordinate of generator point P
    uint256 internal constant CurveGy =
        0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8; // y-coordinate of generator point P
    uint256 internal constant CurveA = 0; // a in y^2 = x^3 + ax + b
    uint256 internal constant CurveB = 7; // b in y^2 = x^3 + ax + b
    uint256 internal constant CurveP =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F; // Modulo p

    // Pre-computed constant for 2 ** 255
    uint256 private constant U255_MAX_PLUS_1 =
        57896044618658097711785492504343953926634992332820282019728792003956564819968;

    /// @dev Modular euclidean inverse of a number (mod p).
    /// @param _x The number
    /// @param _pp The modulus
    /// @return q such that x*q = 1 (mod _pp)
    function invMod(uint256 _x, uint256 _pp) internal pure returns (uint256) {
        require(_x != 0 && _x != _pp && _pp != 0, "Invalid number");
        uint256 q = 0;
        uint256 newT = 1;
        uint256 r = _pp;
        uint256 t;
        while (_x != 0) {
            t = r / _x;
            (q, newT) = (newT, addmod(q, (_pp - mulmod(t, newT, _pp)), _pp));
            (r, _x) = (_x, r - t * _x);
        }

        return q;
    }

    /// @dev Modular exponentiation, b^e % _pp.
    /// Source: https://github.com/androlo/standard-contracts/blob/master/contracts/src/crypto/ECCMath.sol
    /// @param _base base
    /// @param _exp exponent
    /// @param _pp modulus
    /// @return r such that r = b**e (mod _pp)
    function expMod(
        uint256 _base,
        uint256 _exp,
        uint256 _pp
    ) internal pure returns (uint256) {
        require(_pp != 0, "Modulus is zero");

        if (_base == 0) return 0;
        if (_exp == 0) return 1;

        uint256 r = 1;
        uint256 bit = U255_MAX_PLUS_1;
        assembly {
            for {

            } gt(bit, 0) {

            } {
                r := mulmod(
                    mulmod(r, r, _pp),
                    exp(_base, iszero(iszero(and(_exp, bit)))),
                    _pp
                )
                r := mulmod(
                    mulmod(r, r, _pp),
                    exp(_base, iszero(iszero(and(_exp, div(bit, 2))))),
                    _pp
                )
                r := mulmod(
                    mulmod(r, r, _pp),
                    exp(_base, iszero(iszero(and(_exp, div(bit, 4))))),
                    _pp
                )
                r := mulmod(
                    mulmod(r, r, _pp),
                    exp(_base, iszero(iszero(and(_exp, div(bit, 8))))),
                    _pp
                )
                bit := div(bit, 16)
            }
        }

        return r;
    }

    /// @dev Converts a point (x, y, z) expressed in Jacobian coordinates to affine coordinates (x', y', 1).
    /// @param _x coordinate x
    /// @param _y coordinate y
    /// @param _z coordinate z
    /// @param _pp the modulus
    /// @return (x', y') affine coordinates
    function toAffine(
        uint256 _x,
        uint256 _y,
        uint256 _z,
        uint256 _pp
    ) internal pure returns (uint256, uint256) {
        uint256 zInv = invMod(_z, _pp);
        uint256 zInv2 = mulmod(zInv, zInv, _pp);
        uint256 x2 = mulmod(_x, zInv2, _pp);
        uint256 y2 = mulmod(_y, mulmod(zInv, zInv2, _pp), _pp);

        return (x2, y2);
    }

    /// @dev Derives the y coordinate from a compressed-format point x [[SEC-1]](https://www.secg.org/SEC1-Ver-1.0.pdf).
    /// @param _prefix parity byte (0x02 even, 0x03 odd)
    /// @param _x coordinate x
    /// @param _aa constant of curve
    /// @param _bb constant of curve
    /// @param _pp the modulus
    /// @return y coordinate y
    function deriveY(
        uint8 _prefix,
        uint256 _x,
        uint256 _aa,
        uint256 _bb,
        uint256 _pp
    ) internal pure returns (uint256) {
        require(
            _prefix == 0x02 || _prefix == 0x03,
            "Invalid compressed EC point prefix"
        );

        // x^3 + ax + b
        uint256 y2 = addmod(
            mulmod(_x, mulmod(_x, _x, _pp), _pp),
            addmod(mulmod(_x, _aa, _pp), _bb, _pp),
            _pp
        );
        y2 = expMod(y2, (_pp + 1) / 4, _pp);
        // uint256 cmp = yBit ^ y_ & 1;
        uint256 y = (y2 + _prefix) % 2 == 0 ? y2 : _pp - y2;

        return y;
    }

    /// @dev Check whether point (x,y) is on curve defined by a, b, and _pp.
    /// @param _x coordinate x of P1
    /// @param _y coordinate y of P1
    /// @param _aa constant of curve
    /// @param _bb constant of curve
    /// @param _pp the modulus
    /// @return true if x,y in the curve, false else
    function isOnCurve(
        uint256 _x,
        uint256 _y,
        uint256 _aa,
        uint256 _bb,
        uint256 _pp
    ) internal pure returns (bool) {
        if (0 == _x || _x >= _pp || 0 == _y || _y >= _pp) {
            return false;
        }
        // y^2
        uint256 lhs = mulmod(_y, _y, _pp);
        // x^3
        uint256 rhs = mulmod(mulmod(_x, _x, _pp), _x, _pp);
        if (_aa != 0) {
            // x^3 + a*x
            rhs = addmod(rhs, mulmod(_x, _aa, _pp), _pp);
        }
        if (_bb != 0) {
            // x^3 + a*x + b
            rhs = addmod(rhs, _bb, _pp);
        }

        return lhs == rhs;
    }

    /// @dev Calculate inverse (x, -y) of point (x, y).
    /// @param _x coordinate x of P1
    /// @param _y coordinate y of P1
    /// @param _pp the modulus
    /// @return (x, -y)
    function ecInv(
        uint256 _x,
        uint256 _y,
        uint256 _pp
    ) internal pure returns (uint256, uint256) {
        return (_x, (_pp - _y) % _pp);
    }

    /// @dev Add two points (x1, y1) and (x2, y2) in affine coordinates.
    /// @param _x1 coordinate x of P1
    /// @param _y1 coordinate y of P1
    /// @param _x2 coordinate x of P2
    /// @param _y2 coordinate y of P2
    /// @param _aa constant of the curve
    /// @param _pp the modulus
    /// @return (qx, qy) = P1+P2 in affine coordinates
    function ecAdd(
        uint256 _x1,
        uint256 _y1,
        uint256 _x2,
        uint256 _y2,
        uint256 _aa,
        uint256 _pp
    ) internal pure returns (uint256, uint256) {
        uint256 x = 0;
        uint256 y = 0;
        uint256 z = 0;

        // Double if x1==x2 else add
        if (_x1 == _x2) {
            // y1 = -y2 mod p
            if (addmod(_y1, _y2, _pp) == 0) {
                return (0, 0);
            } else {
                // P1 = P2
                (x, y, z) = jacDouble(_x1, _y1, 1, _aa, _pp);
            }
        } else {
            (x, y, z) = jacAdd(_x1, _y1, 1, _x2, _y2, 1, _pp);
        }
        // Get back to affine
        return toAffine(x, y, z, _pp);
    }

    /// @dev Substract two points (x1, y1) and (x2, y2) in affine coordinates.
    /// @param _x1 coordinate x of P1
    /// @param _y1 coordinate y of P1
    /// @param _x2 coordinate x of P2
    /// @param _y2 coordinate y of P2
    /// @param _aa constant of the curve
    /// @param _pp the modulus
    /// @return (qx, qy) = P1-P2 in affine coordinates
    function ecSub(
        uint256 _x1,
        uint256 _y1,
        uint256 _x2,
        uint256 _y2,
        uint256 _aa,
        uint256 _pp
    ) internal pure returns (uint256, uint256) {
        // invert square
        (uint256 x, uint256 y) = ecInv(_x2, _y2, _pp);
        // P1-square
        return ecAdd(_x1, _y1, x, y, _aa, _pp);
    }

    /// @dev Multiply point (x1, y1, z1) times d in affine coordinates.
    /// @param _k scalar to multiply
    /// @param _x coordinate x of P1
    /// @param _y coordinate y of P1
    /// @param _aa constant of the curve
    /// @param _pp the modulus
    /// @return (qx, qy) = d*P in affine coordinates
    function ecMul(
        uint256 _k,
        uint256 _x,
        uint256 _y,
        uint256 _aa,
        uint256 _pp
    ) internal pure returns (uint256, uint256) {
        // Jacobian multiplication
        (uint256 x1, uint256 y1, uint256 z1) = jacMul(_k, _x, _y, 1, _aa, _pp);
        // Get back to affine
        return toAffine(x1, y1, z1, _pp);
    }

    /// @dev Adds two points (x1, y1, z1) and (x2 y2, z2).
    /// @param _x1 coordinate x of P1
    /// @param _y1 coordinate y of P1
    /// @param _z1 coordinate z of P1
    /// @param _x2 coordinate x of square
    /// @param _y2 coordinate y of square
    /// @param _z2 coordinate z of square
    /// @param _pp the modulus
    /// @return (qx, qy, qz) P1+square in Jacobian
    function jacAdd(
        uint256 _x1,
        uint256 _y1,
        uint256 _z1,
        uint256 _x2,
        uint256 _y2,
        uint256 _z2,
        uint256 _pp
    )
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        if (_x1 == 0 && _y1 == 0) return (_x2, _y2, _z2);
        if (_x2 == 0 && _y2 == 0) return (_x1, _y1, _z1);

        // We follow the equations described in https://pdfs.semanticscholar.org/5c64/29952e08025a9649c2b0ba32518e9a7fb5c2.pdf Section 5
        uint256[4] memory zs; // z1^2, z1^3, z2^2, z2^3
        zs[0] = mulmod(_z1, _z1, _pp);
        zs[1] = mulmod(_z1, zs[0], _pp);
        zs[2] = mulmod(_z2, _z2, _pp);
        zs[3] = mulmod(_z2, zs[2], _pp);

        // u1, s1, u2, s2
        zs = [
            mulmod(_x1, zs[2], _pp),
            mulmod(_y1, zs[3], _pp),
            mulmod(_x2, zs[0], _pp),
            mulmod(_y2, zs[1], _pp)
        ];

        // In case of zs[0] == zs[2] && zs[1] == zs[3], double function should be used
        require(
            zs[0] != zs[2] || zs[1] != zs[3],
            "Use jacDouble function instead"
        );

        uint256[4] memory hr;
        //h
        hr[0] = addmod(zs[2], _pp - zs[0], _pp);
        //r
        hr[1] = addmod(zs[3], _pp - zs[1], _pp);
        //h^2
        hr[2] = mulmod(hr[0], hr[0], _pp);
        // h^3
        hr[3] = mulmod(hr[2], hr[0], _pp);
        // qx = -h^3  -2u1h^2+r^2
        uint256 qx = addmod(mulmod(hr[1], hr[1], _pp), _pp - hr[3], _pp);
        qx = addmod(qx, _pp - mulmod(2, mulmod(zs[0], hr[2], _pp), _pp), _pp);
        // qy = -s1*z1*h^3+r(u1*h^2 -x^3)
        uint256 qy = mulmod(
            hr[1],
            addmod(mulmod(zs[0], hr[2], _pp), _pp - qx, _pp),
            _pp
        );
        qy = addmod(qy, _pp - mulmod(zs[1], hr[3], _pp), _pp);
        // qz = h*z1*z2
        uint256 qz = mulmod(hr[0], mulmod(_z1, _z2, _pp), _pp);
        return (qx, qy, qz);
    }

    /// @dev Doubles a points (x, y, z).
    /// @param _x coordinate x of P1
    /// @param _y coordinate y of P1
    /// @param _z coordinate z of P1
    /// @param _aa the a scalar in the curve equation
    /// @param _pp the modulus
    /// @return (qx, qy, qz) 2P in Jacobian
    function jacDouble(
        uint256 _x,
        uint256 _y,
        uint256 _z,
        uint256 _aa,
        uint256 _pp
    )
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        if (_z == 0) return (_x, _y, _z);

        // We follow the equations described in https://pdfs.semanticscholar.org/5c64/29952e08025a9649c2b0ba32518e9a7fb5c2.pdf Section 5
        // Note: there is a bug in the paper regarding the m parameter, M=3*(x1^2)+a*(z1^4)
        // x, y, z at this point represent the squares of _x, _y, _z
        uint256 x = mulmod(_x, _x, _pp); //x1^2
        uint256 y = mulmod(_y, _y, _pp); //y1^2
        uint256 z = mulmod(_z, _z, _pp); //z1^2

        // s
        uint256 s = mulmod(4, mulmod(_x, y, _pp), _pp);
        // m
        uint256 m = addmod(
            mulmod(3, x, _pp),
            mulmod(_aa, mulmod(z, z, _pp), _pp),
            _pp
        );

        // x, y, z at this point will be reassigned and rather represent qx, qy, qz from the paper
        // This allows to reduce the gas cost and stack footprint of the algorithm
        // qx
        x = addmod(mulmod(m, m, _pp), _pp - addmod(s, s, _pp), _pp);
        // qy = -8*y1^4 + M(S-T)
        y = addmod(
            mulmod(m, addmod(s, _pp - x, _pp), _pp),
            _pp - mulmod(8, mulmod(y, y, _pp), _pp),
            _pp
        );
        // qz = 2*y1*z1
        z = mulmod(2, mulmod(_y, _z, _pp), _pp);

        return (x, y, z);
    }

    /// @dev Multiply point (x, y, z) times d.
    /// @param _d scalar to multiply
    /// @param _x coordinate x of P1
    /// @param _y coordinate y of P1
    /// @param _z coordinate z of P1
    /// @param _aa constant of curve
    /// @param _pp the modulus
    /// @return (qx, qy, qz) d*P1 in Jacobian
    function jacMul(
        uint256 _d,
        uint256 _x,
        uint256 _y,
        uint256 _z,
        uint256 _aa,
        uint256 _pp
    )
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        // Early return in case that `_d == 0`
        if (_d == 0) {
            return (_x, _y, _z);
        }

        uint256 remaining = _d;
        uint256 qx = 0;
        uint256 qy = 0;
        uint256 qz = 1;

        // Double and add algorithm
        while (remaining != 0) {
            if ((remaining & 1) != 0) {
                (qx, qy, qz) = jacAdd(qx, qy, qz, _x, _y, _z, _pp);
            }
            remaining = remaining / 2;
            (_x, _y, _z) = jacDouble(_x, _y, _z, _aa, _pp);
        }
        return (qx, qy, qz);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {PebbleImplementationManager} from "src/PebbleImplementationManager/PebbleImplementationManager.sol";
import {PebbleSignManager} from "src/PebbleSignManager/PebbleSignManager.sol";
import {PebbleGroupManager} from "src/PebbleGroupManager/PebbleGroupManager.sol";
import {PebbleRoleManager} from "src/PebbleRoleManager/PebbleRoleManager.sol";
import {PebbleDelegatee} from "src/PebbleDelegatee.sol";

contract Pebble is
    PebbleRoleManager,
    PebbleImplementationManager,
    PebbleSignManager,
    PebbleGroupManager
{
    // Constructor
    constructor() PebbleImplementationManager() {}

    /**
    @dev Initializer function
    @param _pebbleVersion Version of this implementation contract
    @param _pebbleAdmins Array of Pebble admins
    @param _delegatees Array of delegatees trusted for subscriptions
     */
    function initialize(
        string calldata _pebbleVersion,
        address[] calldata _pebbleAdmins,
        address[] calldata _delegatees
    ) external initializer {
        __PebbleRoleManager_init_unchained(_pebbleAdmins, _delegatees);
        __PebbleImplementatationManager_init_unchained();
        __PebbleSignMananger_init_unchained(_pebbleVersion);
        __PebbleGroupManager_init_unchained();
    }

    /**
    @dev Re-Initializer function; only Pebble admins can re-initialize proxy
    @param _pebbleVersion New version of this implementation contract; OLD ROLES NEED TO BE MANUALLY REVOKED
    @param _pebbleAdmins New array of Pebble admins; OLD ROLES NEED TO BE MANUALLY REVOKED
    @param _delegatees New array of delegatees trusted for subscriptions
     */
    function reinitialize(
        string calldata _pebbleVersion,
        address[] calldata _pebbleAdmins,
        address[] calldata _delegatees
    ) external onlyPebbleAdmin reinitializer(_getInitializedVersion() + 1) {
        __PebbleRoleManager_init_unchained(_pebbleAdmins, _delegatees);
        __PebbleImplementatationManager_init_unchained();
        __PebbleSignMananger_init_unchained(_pebbleVersion);
        __PebbleGroupManager_init_unchained();
    }

    /**
    @dev Deploys and assigns Delegatee role to a new Delegatee contract
    @param _delegateFeesBasis Delegate fees (in basis) to use
    @return pebbleDelegatee New pebble delegatee contract deployed
     */
    function deployAndAssignDelegateeContract(uint256 _delegateFeesBasis)
        external
        returns (PebbleDelegatee pebbleDelegatee)
    {
        pebbleDelegatee = new PebbleDelegatee(_delegateFeesBasis);
        grantPebbleDelegateeRole(address(pebbleDelegatee));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

contract DelagateVerificationInternals {
    // CONSTANTS
    uint256 private constant DELEGATOR_TO_NONCE_SLOT =
        uint256(keccak256("PEBBLE:DELEGATOR_TO_NONCE_SLOT"));

    // Data
    mapping(address => uint256) private __delegatorToNonceMapping;

    // Modifiers
    modifier delegatorNonceCorrect(address _delegator, uint256 _nonceToCheck) {
        require(
            _getAndUpdateDelegatorNonce(_delegator) == _nonceToCheck,
            "PEBBLE: DELEGATOR NONCE INCORRECT"
        );
        _;
    }

    // Functions

    /**
    @dev Gets a delegator's next allowed nonce
    @param _delegator Address of delegator
    @return nonce Delegator's next allowed nonce
     */
    function _getDelegatorNonce(address _delegator)
        internal
        view
        returns (uint256 nonce)
    {
        nonce = _getDelegatorToNonceMapping()[_delegator];
    }

    /**
    @dev Updates (increments) a delegator's next allowed nonce
    @param _delegator Address of delegator
     */
    function _updateDelegatorNonce(address _delegator) internal {
        ++_getDelegatorToNonceMapping()[_delegator];
    }

    /**
    @dev Gets and updates (increments) a delegator's next allowed nonce
    @param _delegator Address of delegator
    @return nonce Delegator's next allowed nonce
     */
    function _getAndUpdateDelegatorNonce(address _delegator)
        internal
        returns (uint256 nonce)
    {
        nonce = _getDelegatorToNonceMapping()[_delegator];
        _updateDelegatorNonce(_delegator);
    }

    ///////////////
    // SLOT HELPERS
    ///////////////

    /**
    @dev Gets delegator to their next allowed nonce mapping at correct slot
     */
    function _getDelegatorToNonceMapping()
        private
        view
        returns (mapping(address => uint256) storage)
    {
        mapping(address => uint256)
            storage delegatorToNonceMapping = __delegatorToNonceMapping;
        uint256 slotNum = DELEGATOR_TO_NONCE_SLOT;

        assembly {
            delegatorToNonceMapping.slot := slotNum
        }

        return delegatorToNonceMapping;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {PebbleRoleManager} from "src/PebbleRoleManager/PebbleRoleManager.sol";
import {DelagateVerificationInternals} from "./DelagateVerificationInternals.sol";

contract PebbleDelagateVerificationManager is
    PebbleRoleManager,
    DelagateVerificationInternals
{
    /**
    @dev Gets a delegator's next allowed nonce
    @dev Delegators must use this to sign anything
    @param _delegator Address of delegator
    @return nonce Delegator's allowed nonce
     */
    function getDelegatorNonce(address _delegator)
        external
        view
        returns (uint256 nonce)
    {
        nonce = _getDelegatorNonce(_delegator);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {Pebble} from "src/Pebble.sol";

contract PebbleDelegatee {
    // DATA
    Pebble public pebbleProxy;
    mapping(address => uint256) public addressToFundsMapping;
    uint256 public delegateFeesBasis;

    // MODIFIERS

    /**
    @dev Checks to see if caller is role admin of Delegatee role in Pebble proxy contract
     */
    modifier onlyPebbleDelegateeAdmins() {
        require(
            pebbleProxy.hasRole(
                pebbleProxy.getRoleAdmin(pebbleProxy.PEBBLE_DELEGATEE_ROLE()),
                msg.sender
            ),
            "PEBBLE DELEGATEE: NOT AN ADMIN"
        );
        _;
    }

    /**
    @dev Augments function with delegatee gas spent calculation + compensation
    @param _delegator Delegator on who's behalf delegatee is executing transaction
     */
    modifier delegateFor(address _delegator) {
        // Store gas units sent
        uint256 gasUnitsReceived = gasleft();

        // Perform actual function
        _;

        // Calculate gas spent
        uint256 gasSpent;
        assembly {
            gasSpent := mul(sub(gasUnitsReceived, gas()), gasprice())
        }

        // Move fund from delegator to delegatee to compensate + reward delegatee
        _moveFundsFromDelegatorToDelegatee(_delegator, msg.sender, gasSpent);
    }

    // FUNCTIONS

    /**
    @dev Constructor
    @param _delegateFeesBasis Delegate fees (in basis) to use
     */
    constructor(uint256 _delegateFeesBasis) {
        pebbleProxy = Pebble(msg.sender);
        delegateFeesBasis = _delegateFeesBasis;
    }

    /**
    @dev Sets delegate fees (basis)
    @param _delegateFeesBasisNew New delegate fees (basis) to set
     */
    function setDelegateFeesBasis(
        uint16 _delegateFeesBasisNew
    ) external onlyPebbleDelegateeAdmins {
        delegateFeesBasis = _delegateFeesBasisNew;
    }

    /**
    @dev Adds funds sent by caller
     */
    function addFunds() external payable {
        _addFunds(msg.sender, msg.value);
    }

    /**
    @dev Withdraws all funds available for caller
     */
    function withdrawFunds() external {
        _withdrawFunds(msg.sender);
    }

    /**
    @dev Withdraws specified funds available for caller
    @param _value Deposited value to withdraw
     */
    function withdrawFunds(uint256 _value) external {
        _withdrawFunds(msg.sender, _value);
    }

    /**
    @dev If funds are directly sent, add them against caller
     */
    fallback() external payable {
        _addFunds(msg.sender, msg.value);
    }

    /**
    @dev If funds are directly sent, add them against caller
     */
    receive() external payable {
        _addFunds(msg.sender, msg.value);
    }

    /**
    @dev Creates a new group on behalf of delegator, and sets it up for accepting (i.e, arriving at the final penultimate shared key)
    @param _groupCreator Address of the group creator (Delegator in this case)
    @param _groupParticipantsOtherThanCreator Array of group participants other than group creator
    @param _initialPenultimateSharedKeyForCreatorX X coordinate of initial value of penultimate shared key to use for creator, i.e, RANDOM * G
    @param _initialPenultimateSharedKeyForCreatorY Y coordinate of initial value of penultimate shared key to use for creator, i.e, RANDOM * G
    @param _initialPenultimateSharedKeyFromCreatorX X coordinate of initial value of penultimate shared key to use for all participants other than creator, i.e, Creator private key * RANDOM * G
    @param _initialPenultimateSharedKeyFromCreatorY Y coordinate of initial value of penultimate shared key to use for all participants other than creator, i.e, Creator private key * RANDOM * G
    @param _groupCreatorDelegatorNonce Group creator's delegator nonce
    @param _signatureFromDelegator Signature from delegator against which to confirm input params against
    @return groupId New group's ID
     */
    function createGroupForDelegator(
        address _groupCreator,
        address[] calldata _groupParticipantsOtherThanCreator,
        uint256 _initialPenultimateSharedKeyForCreatorX,
        uint256 _initialPenultimateSharedKeyForCreatorY,
        uint256 _initialPenultimateSharedKeyFromCreatorX,
        uint256 _initialPenultimateSharedKeyFromCreatorY,
        uint256 _groupCreatorDelegatorNonce,
        bytes calldata _signatureFromDelegator
    ) external delegateFor(_groupCreator) returns (uint256 groupId) {
        groupId = pebbleProxy.createGroupForDelegator(
            _groupCreator,
            _groupParticipantsOtherThanCreator,
            _initialPenultimateSharedKeyForCreatorX,
            _initialPenultimateSharedKeyForCreatorY,
            _initialPenultimateSharedKeyFromCreatorX,
            _initialPenultimateSharedKeyFromCreatorY,
            _groupCreatorDelegatorNonce,
            _signatureFromDelegator
        );
    }

    /**
    @dev Creates a new group on behalf of delegator, and sets it up for accepting (i.e, arriving at the final penultimate shared key)
    @param _groupCreator Address of the group creator (Delegator in this case)
    @param _groupParticipantsOtherThanCreator Array of group participants other than group creator
    @param _initialPenultimateSharedKeyForCreatorX X coordinate of initial value of penultimate shared key to use for creator, i.e, RANDOM * G
    @param _initialPenultimateSharedKeyForCreatorY Y coordinate of initial value of penultimate shared key to use for creator, i.e, RANDOM * G
    @param _initialPenultimateSharedKeyFromCreatorX X coordinate of initial value of penultimate shared key to use for all participants other than creator, i.e, Creator private key * RANDOM * G
    @param _initialPenultimateSharedKeyFromCreatorY Y coordinate of initial value of penultimate shared key to use for all participants other than creator, i.e, Creator private key * RANDOM * G
    @param _groupCreatorDelegatorNonce Group creator's delegator nonce
    @param _signatureFromDelegator_v v component of signature from delegator against which to confirm input params against
    @param _signatureFromDelegator_r v component of signature from delegator against which to confirm input params against
    @param _signatureFromDelegator_s v component of signature from delegator against which to confirm input params against
    @return groupId New group's ID
     */
    function createGroupForDelegator(
        address _groupCreator,
        address[] calldata _groupParticipantsOtherThanCreator,
        uint256 _initialPenultimateSharedKeyForCreatorX,
        uint256 _initialPenultimateSharedKeyForCreatorY,
        uint256 _initialPenultimateSharedKeyFromCreatorX,
        uint256 _initialPenultimateSharedKeyFromCreatorY,
        uint256 _groupCreatorDelegatorNonce,
        uint8 _signatureFromDelegator_v,
        bytes32 _signatureFromDelegator_r,
        bytes32 _signatureFromDelegator_s
    ) external delegateFor(_groupCreator) returns (uint256 groupId) {
        groupId = pebbleProxy.createGroupForDelegator(
            _groupCreator,
            _groupParticipantsOtherThanCreator,
            _initialPenultimateSharedKeyForCreatorX,
            _initialPenultimateSharedKeyForCreatorY,
            _initialPenultimateSharedKeyFromCreatorX,
            _initialPenultimateSharedKeyFromCreatorY,
            _groupCreatorDelegatorNonce,
            _signatureFromDelegator_v,
            _signatureFromDelegator_r,
            _signatureFromDelegator_s
        );
    }

    /**
    @dev Accepts invititation to a group
    @param _groupId Group id of the group to accept invite for
    @param _groupParticipant Group participant who wants to accept group invite
    @param _penultimateKeysFor Addresses for which updated penultimate shared keys are meant for
    @param _penultimateKeysXUpdated Array of X coordinates of updated penultimate shared key corresponding to `_penultimateKeysFor`
    @param _penultimateKeysYUpdated Array of Y coordinates of updated penultimate shared key corresponding to `_penultimateKeysFor`
    @param _timestampForWhichUpdatedKeysAreMeant Timestamp at which the invitee checked the last updated penultimate keys
    @param _groupParticipantDelegatorNonce Group participant's delegator nonce
    @param _signatureFromGroupParticipant Signature from participant against which to confirm input params against
    */
    function acceptGroupInviteForDelegator(
        uint256 _groupId,
        address _groupParticipant,
        address[] calldata _penultimateKeysFor,
        uint256[] calldata _penultimateKeysXUpdated,
        uint256[] calldata _penultimateKeysYUpdated,
        uint256 _timestampForWhichUpdatedKeysAreMeant,
        uint256 _groupParticipantDelegatorNonce,
        bytes calldata _signatureFromGroupParticipant
    ) external delegateFor(_groupParticipant) {
        pebbleProxy.acceptGroupInviteForDelegator(
            _groupId,
            _groupParticipant,
            _penultimateKeysFor,
            _penultimateKeysXUpdated,
            _penultimateKeysYUpdated,
            _timestampForWhichUpdatedKeysAreMeant,
            _groupParticipantDelegatorNonce,
            _signatureFromGroupParticipant
        );
    }

    /**
    @dev Accepts invititation to a group
    @param _groupId Group id of the group to accept invite for
    @param _groupParticipant Group participant who wants to accept group invite
    @param _penultimateKeysFor Addresses for which updated penultimate shared keys are meant for
    @param _penultimateKeysXUpdated Array of X coordinates of updated penultimate shared key corresponding to `_penultimateKeysFor`
    @param _penultimateKeysYUpdated Array of Y coordinates of updated penultimate shared key corresponding to `_penultimateKeysFor`
    @param _timestampForWhichUpdatedKeysAreMeant Timestamp at which the invitee checked the last updated penultimate keys
    @param _groupParticipantDelegatorNonce Group participant's delegator nonce
    @param _signatureFromGroupParticipant_v v component of signature from participant against which to confirm input params against
    @param _signatureFromGroupParticipant_r r component of signature from participant against which to confirm input params against
    @param _signatureFromGroupParticipant_s s component of signature from participant against which to confirm input params against
    */
    function acceptGroupInviteForDelegator(
        uint256 _groupId,
        address _groupParticipant,
        address[] calldata _penultimateKeysFor,
        uint256[] calldata _penultimateKeysXUpdated,
        uint256[] calldata _penultimateKeysYUpdated,
        uint256 _timestampForWhichUpdatedKeysAreMeant,
        uint256 _groupParticipantDelegatorNonce,
        uint8 _signatureFromGroupParticipant_v,
        bytes32 _signatureFromGroupParticipant_r,
        bytes32 _signatureFromGroupParticipant_s
    ) external delegateFor(_groupParticipant) {
        pebbleProxy.acceptGroupInviteForDelegator(
            _groupId,
            _groupParticipant,
            _penultimateKeysFor,
            _penultimateKeysXUpdated,
            _penultimateKeysYUpdated,
            _timestampForWhichUpdatedKeysAreMeant,
            _groupParticipantDelegatorNonce,
            _signatureFromGroupParticipant_v,
            _signatureFromGroupParticipant_r,
            _signatureFromGroupParticipant_s
        );
    }

    /**
    @dev Sends a message from Sender in a group
    @param _groupId Group id of the group to send message in
    @param _sender Sender who wants to send message
    @param _encryptedMessage Encrypted message to send (MUST BE ENCRYPTED BY SHARED KEY, NOT PENULTIMATE SHARED KEY; SHARED KEY = SENDER PRIVATE KEY * SENDER PENULTIMATE SHARED KEY; THIS MUST BE CALCULATED LOCALLY)
    @param _senderDelegatorNonce Sender's delegator nonce
    @param _signatureFromSender Signature from sender against which to confirm input params against
     */
    function sendMessageInGroupForDelegator(
        uint256 _groupId,
        address _sender,
        bytes calldata _encryptedMessage,
        uint256 _senderDelegatorNonce,
        bytes calldata _signatureFromSender
    ) external delegateFor(_sender) {
        pebbleProxy.sendMessageInGroupForDelegator(
            _groupId,
            _sender,
            _encryptedMessage,
            _senderDelegatorNonce,
            _signatureFromSender
        );
    }

    /**
    @dev Sends a message from Sender in a group
    @param _groupId Group id of the group to send message in
    @param _sender Sender who wants to send message
    @param _encryptedMessage Encrypted message to send (MUST BE ENCRYPTED BY SHARED KEY, NOT PENULTIMATE SHARED KEY; SHARED KEY = SENDER PRIVATE KEY * SENDER PENULTIMATE SHARED KEY; THIS MUST BE CALCULATED LOCALLY)
    @param _senderDelegatorNonce Sender's delegator nonce
    @param _signatureFromSender_v v component of signature from sender against which to confirm input params against
    @param _signatureFromSender_r r component of signature from sender against which to confirm input params against
    @param _signatureFromSender_s s component of signature from sender against which to confirm input params against
     */
    function sendMessageInGroupForDelegator(
        uint256 _groupId,
        address _sender,
        bytes calldata _encryptedMessage,
        uint256 _senderDelegatorNonce,
        uint8 _signatureFromSender_v,
        bytes32 _signatureFromSender_r,
        bytes32 _signatureFromSender_s
    ) external delegateFor(_sender) {
        pebbleProxy.sendMessageInGroupForDelegator(
            _groupId,
            _sender,
            _encryptedMessage,
            _senderDelegatorNonce,
            _signatureFromSender_v,
            _signatureFromSender_r,
            _signatureFromSender_s
        );
    }

    // INTERNALS
    /**
    @dev Adds funds sent by an address
    @param _depositor Address of depositor
    @param _value Deposited value
     */
    function _addFunds(address _depositor, uint256 _value) internal {
        addressToFundsMapping[_depositor] += _value;
    }

    /**
    @dev Withdraws all funds available for an address
    @param _withdrawer Address of withdrawer
     */
    function _withdrawFunds(address _withdrawer) internal {
        uint256 fundsToWithdraw = addressToFundsMapping[_withdrawer];
        require(
            fundsToWithdraw != 0,
            "PEBBLE DELEGATEE: DEPOSITOR HAS NO FUNDS"
        );
        addressToFundsMapping[_withdrawer] = 0;
        (bool success, ) = _withdrawer.call{value: fundsToWithdraw}("");
        require(success, "PEBBLE DELEGATEE: WITHDRAW FAILED");
    }

    /**
    @dev Withdraws specified funds available for an address
    @param _withdrawer Address of withdrawer
    @param _value Deposited value to withdraw
     */
    function _withdrawFunds(address _withdrawer, uint256 _value) internal {
        require(
            _value != 0,
            "PEBBLE DELEGATEE: VALUE MUST BE GREATER THAN ZERO"
        );
        addressToFundsMapping[_withdrawer] -= _value;
        (bool success, ) = _withdrawer.call{value: _value}("");
        require(success, "PEBBLE DELEGATEE: WITHDRAW FAILED");
    }

    /**
    @dev Moves funds from delegator to delegatee; to be used after delegatee has finished delegation task
    @dev This takes delegate fees into account
    @param _delegator Address of delegator
    @param _delegatee Address of delegatee
    @param _valueToMove Value of deposit to move from delegator to delegatee (exclusive of delegator fees)
     */
    function _moveFundsFromDelegatorToDelegatee(
        address _delegator,
        address _delegatee,
        uint256 _valueToMove
    ) internal {
        uint256 valueToMoveWithFees;
        unchecked {
            valueToMoveWithFees =
                _valueToMove +
                ((_valueToMove * delegateFeesBasis) / 10000);
        }
        addressToFundsMapping[_delegator] -= valueToMoveWithFees;
        unchecked {
            addressToFundsMapping[_delegatee] += valueToMoveWithFees;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {PebbleMath} from "src/Utils/Math.sol";
import {PebbleSignManager} from "src/PebbleSignManager/PebbleSignManager.sol";

contract GroupInternals is PebbleSignManager {
    // Structs
    struct Group {
        address creator;
        address[] participantsOtherThanCreator;
    }

    struct PenultimateSharedKey {
        uint256 penultimateSharedKeyX; // X coordinate of shared key point on curve
        uint256 penultimateSharedKeyY; // Y coordinate of shared key point on curve
    }

    // Constants
    uint256 constant GROUP_NONCE_SLOT =
        uint256(keccak256("PEBBLE:GROUP_NONCE_SLOT"));
    uint256 constant GROUP_NUMBER_TO_GROUP_MAPPING_SLOT =
        uint256(keccak256("PEBBLE:GROUP_NUMBER_TO_GROUP_MAPPING_SLOT"));
    uint256 constant GROUP_ID_TO_GROUP_PARTICIPANT_TO_PENULTIMATE_SHARED_KEY_MAPPING_SLOT =
        uint256(
            keccak256(
                "PEBBLE:GROUP_ID_TO_GROUP_PARTICIPANT_TO_PENULTIMATE_SHARED_KEY_MAPPING_SLOT"
            )
        );
    uint256 constant GROUP_ID_TO_PENULTIMATE_SHARED_KEY_UPDATE_TIMESTAMP_MAPPING_SLOT =
        uint256(
            keccak256(
                "PEBBLE:GROUP_ID_TO_PENULTIMATE_SHARED_KEY_UPDATE_TIMESTAMP_MAPPING_SLOT"
            )
        );
    uint256 constant GROUP_ID_TO_PARTICIPANT_TO_DID_ACCEPT_INVITE_MAPPING_SLOT =
        uint256(
            keccak256(
                "PEBBLE:GROUP_ID_TO_PARTICIPANT_TO_DID_ACCEPT_INVITE_MAPPING_SLOT"
            )
        );

    // Events

    /**
    @dev Fired when a new group is created, and participants have to invited
     */
    event Invite(
        uint256 indexed groupId,
        address indexed creator,
        address indexed participant
    );

    /**
    @dev Fired when all invitees have accepted invitation to a group
     */
    event AllInvitesAccepted(uint256 indexed groupId);

    /**
    @dev Fired when group participant needs to send a message
     */
    event SendMessage(
        uint256 indexed groupId,
        address indexed sender,
        bytes encryptedMessage
    );

    // Data
    mapping(address => uint256[]) private __groupParticipantToGroupIdsMapping; // Maps a group participant to array of group ids; DON'T USE DIRECTLY; USE SLOT HELPER
    mapping(uint256 => Group) private __groupIdToGroupMapping; // Maps a group id to group data; DON'T USE DIRECTLY; USE SLOT HELPER
    mapping(uint256 => mapping(address => PenultimateSharedKey))
        private __groupIdToGroupParticipantToPenultimateSharedKeyMapping; // Maps a group id to participant to penultimate shared key; DON'T USE DIRECTLY; USE SLOT HELPER
    mapping(uint256 => uint256)
        private __groupIdToPenultimateSharedKeyUpdateTimestampMapping; // Maps a Group ID to the timestamp its penultimate shared keys were last updated; DON'T USE DIRECTLY; USE SLOT HELPER
    mapping(uint256 => mapping(address => uint256)) __groupIdToParticipantToDidAcceptInvite; // Maps a group ID to a participant to whether the participant accepted group invite; 0 = no, 1 = yes

    // Functions

    /**
    @dev Gets group nonce mapping at correct slot
    @return groupNonce Current group nonce
     */
    function _getGroupNonce() private view returns (uint256 groupNonce) {
        uint256 slotNum = GROUP_NONCE_SLOT;

        assembly {
            groupNonce := sload(slotNum)
        }
    }

    /**
    @dev Increments previous group nonce and then returns it, all at correct slot
    @return groupNonce Group nonce BEFORE being incremented. Use this returned value directly.
     */
    function _getAndIncrementGroupNonce()
        internal
        returns (uint256 groupNonce)
    {
        uint256 slotNum = GROUP_NONCE_SLOT;

        assembly {
            groupNonce := sload(slotNum)
            sstore(slotNum, add(groupNonce, 1))
        }
    }

    /**
    @dev Gets group from group id
    @param _groupId Group id to query with
    @return group Group corresponding the the group id
     */
    function _getGroupFromGroupId(uint256 _groupId)
        internal
        view
        returns (Group memory)
    {
        return _getGroupIdToGroupMapping()[_groupId];
    }

    /**
    @dev Get rooms a participant is present in
    @param _groupId Group id to setup new Group at
    @param _groupData Corresponding group data to set
     */
    function _setupGroup(uint256 _groupId, Group memory _groupData) internal {
        _getGroupIdToGroupMapping()[_groupId] = _groupData;
    }

    /**
    @dev Gets a participant's penultimate shared key for a group id
    @param _groupId Group id to use to fetch penultimate shared key
    @param _groupParticipant Group participant for whom to fetch the penultimate shared key
    @return penultimateSharedKey Penultimate shared key of group participant
     */
    function _getParticipantGroupPenultimateSharedKey(
        uint256 _groupId,
        address _groupParticipant
    ) internal view returns (PenultimateSharedKey memory penultimateSharedKey) {
        penultimateSharedKey = _getGroupIdToGroupParticipantToPenultimateSharedKeyMapping()[
            _groupId
        ][_groupParticipant];
    }

    /**
    @dev Updates a participant's penultimate shared key for a group id
    @param _groupId Group id to use to update key in
    @param _groupParticipant Group participant for whom to set the penultimate shared key
    @param _newParticipantGroupPenultimateSharedKey Updated penultimate shared key to set for participant
     */
    function _updateParticipantGroupPenultimateSharedKey(
        uint256 _groupId,
        address _groupParticipant,
        PenultimateSharedKey memory _newParticipantGroupPenultimateSharedKey
    ) internal {
        _getGroupIdToGroupParticipantToPenultimateSharedKeyMapping()[_groupId][
            _groupParticipant
        ] = _newParticipantGroupPenultimateSharedKey;
    }

    /**
    @dev Searches through group and finds all other group participants (excluding the participant who's invoking this)
    @param _groupId Group id of the group
    @param _filterOutAddress Address of the participant to exclude while searching
    @return otherParticipants Array of other group participants
     */
    function _getOtherGroupParticipants(
        uint256 _groupId,
        address _filterOutAddress
    ) internal view returns (address[] memory otherParticipants) {
        // Check if _filterOutAddress even exists
        require(
            _canParticipantAcceptGroupInvite(_groupId, _filterOutAddress),
            "PEBBLE: NOT INVITED"
        );

        Group memory group = _getGroupFromGroupId(_groupId);
        address groupCreator = group.creator;
        address[] memory participantsOtherThanCreator = group
            .participantsOtherThanCreator;
        uint256 participantsOtherThanCreatorNum = group
            .participantsOtherThanCreator
            .length;
        otherParticipants = new address[](participantsOtherThanCreatorNum);
        uint256 storeIndex;

        // Add group creator to result if they are not excluded
        if (groupCreator != _filterOutAddress) {
            otherParticipants[0] = groupCreator;
            ++storeIndex;
        }

        // Add participants other than group creator if they are not excluded
        for (
            uint256 participantsOtherThanCreatorIndex;
            participantsOtherThanCreatorIndex < participantsOtherThanCreatorNum;
            ++participantsOtherThanCreatorIndex
        ) {
            if (
                participantsOtherThanCreator[
                    participantsOtherThanCreatorIndex
                ] != _filterOutAddress
            ) {
                otherParticipants[storeIndex] = participantsOtherThanCreator[
                    participantsOtherThanCreatorIndex
                ];
                ++storeIndex;
            }
        }
    }

    /**
    @dev Gets timestamp when a group's penultimate shared keys were last updated
    @param _groupId Group id of the group
    @return timestamp Timestamp when a group's penultimate shared keys were last updated
     */
    function _getGroupPenultimateSharedKeyLastUpdateTimestamp(uint256 _groupId)
        internal
        view
        returns (uint256 timestamp)
    {
        timestamp = _getGroupIdToPenultimateSharedKeyUpdateTimestampMapping()[
            _groupId
        ];
    }

    /**
    @dev Updates timestamp for a group's penultimate shared keys update
    @param _groupId Group id of the group
     */
    function _updateGroupPenultimateSharedKeyLastUpdateTimestamp(
        uint256 _groupId
    ) internal {
        _getGroupIdToPenultimateSharedKeyUpdateTimestampMapping()[
            _groupId
        ] = block.timestamp;
    }

    /**
    @dev Checks to see if a participant can accept invite to a group
    @param _groupId Group Id of the group the participant wants to join
    @param _groupParticipant Address of participant to check
     */
    function _canParticipantAcceptGroupInvite(
        uint256 _groupId,
        address _groupParticipant
    ) internal view returns (bool) {
        // Get group
        address[]
            memory participantsOtherThanCreator = _getGroupIdToGroupMapping()[
                _groupId
            ].participantsOtherThanCreator;

        // Check to see if participant is present in Group
        uint256 participantsOtherThanCreatorNum = participantsOtherThanCreator
            .length;
        for (uint256 i; i < participantsOtherThanCreatorNum; ++i) {
            if (participantsOtherThanCreator[i] == _groupParticipant) {
                return true;
            }
        }

        return false;
    }

    /**
    @dev Checks to see if a participant accepted a group id
    @param _groupId Group id of the group to check in
    @param _participant Participant to check for
    @return didParticipantAcceptGroupInvite True if yes
     */
    function _didParticipantAcceptGroupInvite(
        uint256 _groupId,
        address _participant
    ) internal view returns (bool) {
        return
            _getGroupIdToParticipantToDidAcceptInviteMapping()[_groupId][
                _participant
            ] == 1;
    }

    /**
    @dev Checks to see if a group's invitees have all accepted group invite
    @dev If true, group conversation can begin, else not.
    @param _groupId Group id to use for query
    @return hasAllParticipantsAcceptedInvite True if a group's invitees have all accepted group invite
     */
    function _didAllParticipantsAcceptInvite(uint256 _groupId)
        internal
        view
        returns (bool)
    {
        address[] memory participantsOtherThanCreator = _getGroupFromGroupId(
            _groupId
        ).participantsOtherThanCreator;
        uint256 participantsOtherThanCreatorNum = participantsOtherThanCreator
            .length;
        for (uint256 i; i < participantsOtherThanCreatorNum; ++i) {
            if (
                !_didParticipantAcceptGroupInvite(
                    _groupId,
                    participantsOtherThanCreator[i]
                )
            ) {
                return false;
            }
        }
        return true;
    }

    /**
    @dev Marks a participant acceptance to group invite
    @param _groupId Group id of the group to use
    @param _participant Participant that accept invite
     */
    function _markParticipantAcceptanceToGroupInvite(
        uint256 _groupId,
        address _participant
    ) internal {
        _getGroupIdToParticipantToDidAcceptInviteMapping()[_groupId][
            _participant
        ] = 1;
    }

    /**
    @dev Creates a new group, and sets it up for accepting (i.e, arriving at the final penultimate shared key)
    @param _groupCreator Address of the group creator
    @param _groupParticipantsOtherThanCreator Array of group participants other than group creator
    @param _initialPenultimateSharedKeyForCreator Initial value of penultimate shared key to use for creator, i.e, RANDOM * G
    @param _initialPenultimateSharedKeyFromCreator Initial value of penultimate shared key to use for all participants other than creator, i.e, Creator private key * RANDOM * G
    @return groupId New group's ID
     */
    function _createGroup(
        address _groupCreator,
        address[] memory _groupParticipantsOtherThanCreator,
        PenultimateSharedKey memory _initialPenultimateSharedKeyForCreator,
        PenultimateSharedKey memory _initialPenultimateSharedKeyFromCreator
    ) internal returns (uint256 groupId) {
        // Create new group object
        Group memory group = Group({
            creator: _groupCreator,
            participantsOtherThanCreator: _groupParticipantsOtherThanCreator
        });

        // Store group
        groupId = _getAndIncrementGroupNonce();
        _setupGroup(groupId, group);

        // Update penultimate shared keys + Send invites
        require(
            PebbleMath.isPublicKeyOnCurve(
                _initialPenultimateSharedKeyForCreator.penultimateSharedKeyX,
                _initialPenultimateSharedKeyForCreator.penultimateSharedKeyY
            ),
            "PEBBLE: INITIAL PENULTIMATE SHARED KEY FOR CREATOR NOT ON CURVE"
        );
        require(
            PebbleMath.isPublicKeyOnCurve(
                _initialPenultimateSharedKeyFromCreator.penultimateSharedKeyX,
                _initialPenultimateSharedKeyFromCreator.penultimateSharedKeyY
            ),
            "PEBBLE: INITIAL PENULTIMATE SHARED KEY FROM CREATOR NOT ON CURVE"
        );

        // Update penultimate shared keys for creator
        _updateParticipantGroupPenultimateSharedKey(
            groupId,
            _groupCreator,
            _initialPenultimateSharedKeyForCreator
        );

        // Update penultimate shared keys from creator
        uint256 groupParticipantsOtherThanCreatorNum = _groupParticipantsOtherThanCreator
                .length;
        address groupParticipantOtherThanCreator;
        for (uint256 i; i < groupParticipantsOtherThanCreatorNum; ++i) {
            groupParticipantOtherThanCreator = _groupParticipantsOtherThanCreator[
                i
            ];

            // Update penultimate shared keys from creator
            _updateParticipantGroupPenultimateSharedKey(
                groupId,
                groupParticipantOtherThanCreator,
                _initialPenultimateSharedKeyFromCreator
            );

            // Send invites to participants
            emit Invite(
                groupId,
                _groupCreator,
                groupParticipantOtherThanCreator
            );
        }

        // Mark group creator as participant
        _markParticipantAcceptanceToGroupInvite(groupId, _groupCreator);
    }

    /**
    @dev Accepts invititation to a group
    @param _groupId Group id of the group to accept invite for
    @param _groupParticipant Group participant who wants to accept group invite
    @param _penultimateKeysFor Addresses for which updated penultimate shared keys are meant for
    @param _penultimateKeysXUpdated Array of X coordinates of updated penultimate shared key corresponding to `_penultimateKeysFor`
    @param _penultimateKeysYUpdated Array of Y coordinates of updated penultimate shared key corresponding to `_penultimateKeysFor`
    @param _timestampForWhichUpdatedKeysAreMeant Timestamp at which the invitee checked the last updated penultimate keys
    */
    function _acceptGroupInvite(
        uint256 _groupId,
        address _groupParticipant,
        address[] memory _penultimateKeysFor,
        uint256[] memory _penultimateKeysXUpdated,
        uint256[] memory _penultimateKeysYUpdated,
        uint256 _timestampForWhichUpdatedKeysAreMeant
    ) internal {
        // Check if participant can enter group
        require(
            _canParticipantAcceptGroupInvite(_groupId, _groupParticipant),
            "PEBBLE: NOT INVITED"
        );
        require(
            !_didParticipantAcceptGroupInvite(_groupId, _groupParticipant),
            "PEBBLE: ALREADY ACCEPTED INVITE"
        );

        // Check array lengths
        uint256 penultimateKeysForLength = _penultimateKeysFor.length;
        require(
            penultimateKeysForLength == _penultimateKeysXUpdated.length,
            "PEBBLE: INCORRECT ARRAY LENGTH"
        );
        require(
            penultimateKeysForLength == _penultimateKeysYUpdated.length,
            "PEBBLE: INCORRECT ARRAY LENGTH"
        );
        require(
            penultimateKeysForLength ==
                _getGroupFromGroupId(_groupId)
                    .participantsOtherThanCreator
                    .length,
            "PEBBLE: INCORRECT ARRAY LENGTH"
        );

        // Check and update timestamp
        require(
            _getGroupPenultimateSharedKeyLastUpdateTimestamp(_groupId) ==
                _timestampForWhichUpdatedKeysAreMeant,
            "PEBBLE: KEY UPDATES BASED ON EXPIRED DATA"
        );
        _updateGroupPenultimateSharedKeyLastUpdateTimestamp(_groupId);

        // Update penultimate shared keys for intended participants
        for (uint256 i; i < penultimateKeysForLength; ++i) {
            require(
                PebbleMath.isPublicKeyOnCurve(
                    _penultimateKeysXUpdated[i],
                    _penultimateKeysYUpdated[i]
                ),
                "PEBBLE: UPDATED PENULTIMATE SHARED KEY NOT ON CURVE"
            );

            _updateParticipantGroupPenultimateSharedKey(
                _groupId,
                _penultimateKeysFor[i],
                PenultimateSharedKey(
                    _penultimateKeysXUpdated[i],
                    _penultimateKeysYUpdated[i]
                )
            );
        }

        // Mark participant's acceptance to group invite
        _markParticipantAcceptanceToGroupInvite(_groupId, _groupParticipant);

        // If all invitees have accepted group invite, fire event
        if (_didAllParticipantsAcceptInvite(_groupId)) {
            emit AllInvitesAccepted(_groupId);
        }
    }

    /**
    @dev Sends a message from Sender in a group
    @param _groupId Group id of the group to send message in
    @param _sender Sender who wants to send message
    @param _encryptedMessage Encrypted message to send (MUST BE ENCRYPTED BY SHARED KEY, NOT PENULTIMATE SHARED KEY)
     */
    function _sendMessageInGroup(
        uint256 _groupId,
        address _sender,
        bytes memory _encryptedMessage
    ) internal {
        // Check if Group is ready (all invitees have accepted invites)
        require(
            _didAllParticipantsAcceptInvite(_groupId),
            "PEBBLE: PARTICIPANTS YET TO ACCEPT GROUP INVITE"
        );

        // Check is sender is a group participant
        require(
            _didParticipantAcceptGroupInvite(_groupId, _sender),
            "PEBBLE: SENDER NOT A PARTICIPANT"
        );

        // Emit message
        emit SendMessage(_groupId, _sender, _encryptedMessage);
    }

    /**
    @dev Gets param hash needed for Creating group as delegatee
    @param _groupCreator Address of the group creator (Delegator in this case)
    @param _groupParticipantsOtherThanCreator Array of group participants other than group creator
    @param _initialPenultimateSharedKeyForCreatorX X coordinate of initial value of penultimate shared key to use for creator, i.e, RANDOM * G
    @param _initialPenultimateSharedKeyForCreatorY Y coordinate of initial value of penultimate shared key to use for creator, i.e, RANDOM * G
    @param _initialPenultimateSharedKeyFromCreatorX X coordinate of initial value of penultimate shared key to use for all participants other than creator, i.e, Creator private key * RANDOM * G
    @param _initialPenultimateSharedKeyFromCreatorY Y coordinate of initial value of penultimate shared key to use for all participants other than creator, i.e, Creator private key * RANDOM * G
    @param _groupCreatorDelegatorNonce Group creator's delegator nonce
    @param _CREATE_GROUP_FOR_DELEGATOR_TYPEHASH Typehash for delegate function
    @return paramsDigest Param hash
     */
    function _getCreateGroupForDelegatorParamHash(
        address _groupCreator,
        address[] memory _groupParticipantsOtherThanCreator,
        uint256 _initialPenultimateSharedKeyForCreatorX,
        uint256 _initialPenultimateSharedKeyForCreatorY,
        uint256 _initialPenultimateSharedKeyFromCreatorX,
        uint256 _initialPenultimateSharedKeyFromCreatorY,
        uint256 _groupCreatorDelegatorNonce,
        bytes32 _CREATE_GROUP_FOR_DELEGATOR_TYPEHASH
    ) internal view returns (bytes32 paramsDigest) {
        paramsDigest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    _CREATE_GROUP_FOR_DELEGATOR_TYPEHASH,
                    _groupCreator,
                    keccak256(abi.encode(_groupParticipantsOtherThanCreator)),
                    keccak256(
                        abi.encode(_initialPenultimateSharedKeyForCreatorX)
                    ),
                    keccak256(
                        abi.encode(_initialPenultimateSharedKeyForCreatorY)
                    ),
                    keccak256(
                        abi.encode(_initialPenultimateSharedKeyFromCreatorX)
                    ),
                    keccak256(
                        abi.encode(_initialPenultimateSharedKeyFromCreatorY)
                    ),
                    _groupCreatorDelegatorNonce
                )
            )
        );
    }

    /**
    @dev Gets params hash for accepting invite via delegation
    @param _groupId Group id of the group to accept invite for
    @param _groupParticipant Group participant who wants to accept group invite
    @param _penultimateKeysFor Addresses for which updated penultimate shared keys are meant for
    @param _penultimateKeysXUpdated Array of X coordinates of updated penultimate shared key corresponding to `_penultimateKeysFor`
    @param _penultimateKeysYUpdated Array of Y coordinates of updated penultimate shared key corresponding to `_penultimateKeysFor`
    @param _timestampForWhichUpdatedKeysAreMeant Timestamp at which the invitee checked the last updated penultimate keys
    @param _groupParticipantDelegatorNonce Group participant's delegator nonce
    @param _ACCEPT_GROUP_INVITE_FOR_DELEGATOR_TYPEHASH Typehash for delegate function
    */
    function _getAcceptGroupInviteForDelegatorParamHash(
        uint256 _groupId,
        address _groupParticipant,
        address[] memory _penultimateKeysFor,
        uint256[] memory _penultimateKeysXUpdated,
        uint256[] memory _penultimateKeysYUpdated,
        uint256 _timestampForWhichUpdatedKeysAreMeant,
        uint256 _groupParticipantDelegatorNonce,
        bytes32 _ACCEPT_GROUP_INVITE_FOR_DELEGATOR_TYPEHASH
    ) internal view returns (bytes32 paramsDigest) {
        paramsDigest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    _ACCEPT_GROUP_INVITE_FOR_DELEGATOR_TYPEHASH,
                    _groupId,
                    _groupParticipant,
                    abi.encode(_penultimateKeysFor),
                    abi.encode(_penultimateKeysXUpdated),
                    abi.encode(_penultimateKeysYUpdated),
                    _timestampForWhichUpdatedKeysAreMeant,
                    _groupParticipantDelegatorNonce
                )
            )
        );
    }

    /**
    @dev Gets param hash for sending message in group via delegation
    @param _groupId Group id of the group to send message in
    @param _sender Sender who wants to send message
    @param _encryptedMessage Encrypted message to send (MUST BE ENCRYPTED BY SHARED KEY, NOT PENULTIMATE SHARED KEY; SHARED KEY = SENDER PRIVATE KEY * SENDER PENULTIMATE SHARED KEY; THIS MUST BE CALCULATED LOCALLY)
    @param _senderDelegatorNonce Sender's delegator nonce
    @param _SEND_MESSAGE_IN_GROUP_FOR_DELEGATOR_TYPEHASH Typehash for delegate function
     */
    function _getSendMessageInGroupForDelegatorParamsHash(
        uint256 _groupId,
        address _sender,
        bytes memory _encryptedMessage,
        uint256 _senderDelegatorNonce,
        bytes32 _SEND_MESSAGE_IN_GROUP_FOR_DELEGATOR_TYPEHASH
    ) internal view returns (bytes32 paramHash) {
        paramHash = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    _SEND_MESSAGE_IN_GROUP_FOR_DELEGATOR_TYPEHASH,
                    _groupId,
                    _sender,
                    keccak256(_encryptedMessage),
                    _senderDelegatorNonce
                )
            )
        );
    }

    ////////////////
    // SLOT HELPERS
    ////////////////

    /**
    @dev Gets group id to Group mapping at correct slot
     */
    function _getGroupIdToGroupMapping()
        private
        view
        returns (mapping(uint256 => Group) storage groupIdToGroupMapping)
    {
        groupIdToGroupMapping = __groupIdToGroupMapping;

        uint256 slotNum = GROUP_NUMBER_TO_GROUP_MAPPING_SLOT;

        assembly {
            groupIdToGroupMapping.slot := slotNum
        }
    }

    /**
    @dev Gets a mapping from group ids to participants to their penultimate shared key at correct slot
     */
    function _getGroupIdToGroupParticipantToPenultimateSharedKeyMapping()
        private
        view
        returns (
            mapping(uint256 => mapping(address => PenultimateSharedKey))
                storage groupIdToGroupParticipantToPenultimateSharedKeyMapping
        )
    {
        groupIdToGroupParticipantToPenultimateSharedKeyMapping = __groupIdToGroupParticipantToPenultimateSharedKeyMapping;

        uint256 slotNum = GROUP_ID_TO_GROUP_PARTICIPANT_TO_PENULTIMATE_SHARED_KEY_MAPPING_SLOT;

        assembly {
            groupIdToGroupParticipantToPenultimateSharedKeyMapping.slot := slotNum
        }
    }

    /**
    @dev Gets a mapping from group ids to participants to their penultimate shared key at correct slot
     */
    function _getGroupIdToPenultimateSharedKeyUpdateTimestampMapping()
        private
        view
        returns (
            mapping(uint256 => uint256)
                storage groupIdToPenultimateSharedKeyUpdateTimestampMapping
        )
    {
        groupIdToPenultimateSharedKeyUpdateTimestampMapping = __groupIdToPenultimateSharedKeyUpdateTimestampMapping;

        uint256 slotNum = GROUP_ID_TO_PENULTIMATE_SHARED_KEY_UPDATE_TIMESTAMP_MAPPING_SLOT;

        assembly {
            groupIdToPenultimateSharedKeyUpdateTimestampMapping.slot := slotNum
        }
    }

    /**
    @dev Gets a mapping from group ids to participants to whether they accepted group invite, at correct slot
     */
    function _getGroupIdToParticipantToDidAcceptInviteMapping()
        private
        view
        returns (
            mapping(uint256 => mapping(address => uint256))
                storage groupIdToParticipantToDidAcceptInvite
        )
    {
        groupIdToParticipantToDidAcceptInvite = __groupIdToParticipantToDidAcceptInvite;

        uint256 slotNum = GROUP_ID_TO_PARTICIPANT_TO_DID_ACCEPT_INVITE_MAPPING_SLOT;

        assembly {
            groupIdToParticipantToDidAcceptInvite.slot := slotNum
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {PebbleRoleManager} from "src/PebbleRoleManager/PebbleRoleManager.sol";
import {PebbleDelagateVerificationManager} from "src/PebbleDelagateVerificationManager/PebbleDelagateVerificationManager.sol";
import {GroupInternals} from "./GroupInternals.sol";
import {PebbleMath} from "src/Utils/Math.sol";
import {ECDSAUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

contract PebbleGroupManager is
    PebbleRoleManager,
    PebbleDelagateVerificationManager,
    GroupInternals
{
    // CONSTANTS
    bytes32 constant CREATE_GROUP_FOR_DELEGATOR_TYPEHASH =
        keccak256(
            "createGroupForDelegator(address _groupCreator,address[] _groupParticipantsOtherThanCreator,uint256 _initialPenultimateSharedKeyForCreatorX,uint256 _initialPenultimateSharedKeyForCreatorY,uint256 _initialPenultimateSharedKeyFromCreatorX,uint256 _initialPenultimateSharedKeyFromCreatorY,uint256 _groupCreatorDelegatorNonce)"
        );
    bytes32 constant ACCEPT_GROUP_INVITE_FOR_DELEGATOR_TYPEHASH =
        keccak256(
            "acceptGroupInviteForDelegator(uint256 _groupId,address _groupParticipant,address[] _penultimateKeysFor,uint256[] _penultimateKeysXUpdated,uint256[] _penultimateKeysYUpdated,uint256 _timestampForWhichUpdatedKeysAreMeant,uint256 _groupParticipantDelegatorNonce)"
        );
    bytes32 constant SEND_MESSAGE_IN_GROUP_FOR_DELEGATOR_TYPEHASH =
        keccak256(
            "sendMessageInGroupForDelegator(uint256 _groupId,address _sender,bytes _encryptedMessage,uint256 _senderDelegatorNonce)"
        );

    /**
    @dev Initialization method
     */
    function __PebbleGroupManager_init_unchained() internal onlyInitializing {}

    // Functions

    /**
    @dev Creates a new group, and sets it up for accepting (i.e, arriving at the final penultimate shared key)
    @param _groupParticipantsOtherThanCreator Array of group participants other than group creator
    @param _initialPenultimateSharedKeyForCreatorX X coordinate of initial value of penultimate shared key to use for creator, i.e, RANDOM * G
    @param _initialPenultimateSharedKeyForCreatorY Y coordinate of initial value of penultimate shared key to use for creator, i.e, RANDOM * G
    @param _initialPenultimateSharedKeyFromCreatorX X coordinate of initial value of penultimate shared key to use for all participants other than creator, i.e, Creator private key * RANDOM * G
    @param _initialPenultimateSharedKeyFromCreatorY Y coordinate of initial value of penultimate shared key to use for all participants other than creator, i.e, Creator private key * RANDOM * G
    @return groupId New group's ID
     */
    function createGroup(
        address[] calldata _groupParticipantsOtherThanCreator,
        uint256 _initialPenultimateSharedKeyForCreatorX,
        uint256 _initialPenultimateSharedKeyForCreatorY,
        uint256 _initialPenultimateSharedKeyFromCreatorX,
        uint256 _initialPenultimateSharedKeyFromCreatorY
    ) external returns (uint256 groupId) {
        groupId = _createGroup(
            msg.sender,
            _groupParticipantsOtherThanCreator,
            PenultimateSharedKey(
                _initialPenultimateSharedKeyForCreatorX,
                _initialPenultimateSharedKeyForCreatorY
            ),
            PenultimateSharedKey(
                _initialPenultimateSharedKeyFromCreatorX,
                _initialPenultimateSharedKeyFromCreatorY
            )
        );
    }

    /**
    @dev Creates a new group on behalf of delegator, and sets it up for accepting (i.e, arriving at the final penultimate shared key)
    @param _groupCreator Address of the group creator (Delegator in this case)
    @param _groupParticipantsOtherThanCreator Array of group participants other than group creator
    @param _initialPenultimateSharedKeyForCreatorX X coordinate of initial value of penultimate shared key to use for creator, i.e, RANDOM * G
    @param _initialPenultimateSharedKeyForCreatorY Y coordinate of initial value of penultimate shared key to use for creator, i.e, RANDOM * G
    @param _initialPenultimateSharedKeyFromCreatorX X coordinate of initial value of penultimate shared key to use for all participants other than creator, i.e, Creator private key * RANDOM * G
    @param _initialPenultimateSharedKeyFromCreatorY Y coordinate of initial value of penultimate shared key to use for all participants other than creator, i.e, Creator private key * RANDOM * G
    @param _groupCreatorDelegatorNonce Group creator's delegator nonce
    @param _signatureFromDelegator Signature from delegator against which to confirm input params against
    @return groupId New group's ID
     */
    function createGroupForDelegator(
        address _groupCreator,
        address[] calldata _groupParticipantsOtherThanCreator,
        uint256 _initialPenultimateSharedKeyForCreatorX,
        uint256 _initialPenultimateSharedKeyForCreatorY,
        uint256 _initialPenultimateSharedKeyFromCreatorX,
        uint256 _initialPenultimateSharedKeyFromCreatorY,
        uint256 _groupCreatorDelegatorNonce,
        bytes calldata _signatureFromDelegator
    )
        external
        onlyPebbleDelegatee
        delegatorNonceCorrect(_groupCreator, _groupCreatorDelegatorNonce)
        returns (uint256 groupId)
    {
        // Verify signature
        bytes32 paramsDigest = _getCreateGroupForDelegatorParamHash(
            _groupCreator,
            _groupParticipantsOtherThanCreator,
            _initialPenultimateSharedKeyForCreatorX,
            _initialPenultimateSharedKeyForCreatorY,
            _initialPenultimateSharedKeyFromCreatorX,
            _initialPenultimateSharedKeyFromCreatorY,
            _groupCreatorDelegatorNonce,
            CREATE_GROUP_FOR_DELEGATOR_TYPEHASH
        );
        require(
            _groupCreator ==
                ECDSAUpgradeable.recover(paramsDigest, _signatureFromDelegator),
            "PEBBLE: INCORRECT SIGNATURE"
        );

        // Create group
        groupId = _createGroup(
            _groupCreator,
            _groupParticipantsOtherThanCreator,
            PenultimateSharedKey(
                _initialPenultimateSharedKeyForCreatorX,
                _initialPenultimateSharedKeyForCreatorY
            ),
            PenultimateSharedKey(
                _initialPenultimateSharedKeyFromCreatorX,
                _initialPenultimateSharedKeyFromCreatorY
            )
        );
    }

    /**
    @dev Creates a new group on behalf of delegator, and sets it up for accepting (i.e, arriving at the final penultimate shared key)
    @param _groupCreator Address of the group creator (Delegator in this case)
    @param _groupParticipantsOtherThanCreator Array of group participants other than group creator
    @param _initialPenultimateSharedKeyForCreatorX X coordinate of initial value of penultimate shared key to use for creator, i.e, RANDOM * G
    @param _initialPenultimateSharedKeyForCreatorY Y coordinate of initial value of penultimate shared key to use for creator, i.e, RANDOM * G
    @param _initialPenultimateSharedKeyFromCreatorX X coordinate of initial value of penultimate shared key to use for all participants other than creator, i.e, Creator private key * RANDOM * G
    @param _initialPenultimateSharedKeyFromCreatorY Y coordinate of initial value of penultimate shared key to use for all participants other than creator, i.e, Creator private key * RANDOM * G
    @param _groupCreatorDelegatorNonce Group creator's delegator nonce
    @param _signatureFromDelegator_v v component of signature from delegator against which to confirm input params against
    @param _signatureFromDelegator_r r component of signature from delegator against which to confirm input params against
    @param _signatureFromDelegator_s s component of signature from delegator against which to confirm input params against
    @return groupId New group's ID
     */
    function createGroupForDelegator(
        address _groupCreator,
        address[] calldata _groupParticipantsOtherThanCreator,
        uint256 _initialPenultimateSharedKeyForCreatorX,
        uint256 _initialPenultimateSharedKeyForCreatorY,
        uint256 _initialPenultimateSharedKeyFromCreatorX,
        uint256 _initialPenultimateSharedKeyFromCreatorY,
        uint256 _groupCreatorDelegatorNonce,
        uint8 _signatureFromDelegator_v,
        bytes32 _signatureFromDelegator_r,
        bytes32 _signatureFromDelegator_s
    )
        external
        onlyPebbleDelegatee
        delegatorNonceCorrect(_groupCreator, _groupCreatorDelegatorNonce)
        returns (uint256 groupId)
    {
        // Verify signature
        bytes32 paramsDigest = _getCreateGroupForDelegatorParamHash(
            _groupCreator,
            _groupParticipantsOtherThanCreator,
            _initialPenultimateSharedKeyForCreatorX,
            _initialPenultimateSharedKeyForCreatorY,
            _initialPenultimateSharedKeyFromCreatorX,
            _initialPenultimateSharedKeyFromCreatorY,
            _groupCreatorDelegatorNonce,
            CREATE_GROUP_FOR_DELEGATOR_TYPEHASH
        );
        require(
            _groupCreator ==
                ECDSAUpgradeable.recover(
                    paramsDigest,
                    _signatureFromDelegator_v,
                    _signatureFromDelegator_r,
                    _signatureFromDelegator_s
                ),
            "PEBBLE: INCORRECT SIGNATURE"
        );

        // Create group
        groupId = _createGroup(
            _groupCreator,
            _groupParticipantsOtherThanCreator,
            PenultimateSharedKey(
                _initialPenultimateSharedKeyForCreatorX,
                _initialPenultimateSharedKeyForCreatorY
            ),
            PenultimateSharedKey(
                _initialPenultimateSharedKeyFromCreatorX,
                _initialPenultimateSharedKeyFromCreatorY
            )
        );
    }

    /**
    @dev Accepts invititation to a group
    @param _groupId Group id of the group to accept invite for
    @param _penultimateKeysFor Addresses for which updated penultimate shared keys are meant for
    @param _penultimateKeysXUpdated Array of X coordinates of updated penultimate shared key corresponding to `_penultimateKeysFor`
    @param _penultimateKeysYUpdated Array of Y coordinates of updated penultimate shared key corresponding to `_penultimateKeysFor`
    @param _timestampForWhichUpdatedKeysAreMeant Timestamp at which the invitee checked the last updated penultimate keys
    */
    function acceptGroupInvite(
        uint256 _groupId,
        address[] calldata _penultimateKeysFor,
        uint256[] calldata _penultimateKeysXUpdated,
        uint256[] calldata _penultimateKeysYUpdated,
        uint256 _timestampForWhichUpdatedKeysAreMeant
    ) external {
        _acceptGroupInvite(
            _groupId,
            msg.sender,
            _penultimateKeysFor,
            _penultimateKeysXUpdated,
            _penultimateKeysYUpdated,
            _timestampForWhichUpdatedKeysAreMeant
        );
    }

    /**
    @dev Accepts invititation to a group
    @param _groupId Group id of the group to accept invite for
    @param _groupParticipant Group participant who wants to accept group invite
    @param _penultimateKeysFor Addresses for which updated penultimate shared keys are meant for
    @param _penultimateKeysXUpdated Array of X coordinates of updated penultimate shared key corresponding to `_penultimateKeysFor`
    @param _penultimateKeysYUpdated Array of Y coordinates of updated penultimate shared key corresponding to `_penultimateKeysFor`
    @param _timestampForWhichUpdatedKeysAreMeant Timestamp at which the invitee checked the last updated penultimate keys
    @param _groupParticipantDelegatorNonce Group participant's delegator nonce
    @param _signatureFromGroupParticipant Signature from participant against which to confirm input params against
    */
    function acceptGroupInviteForDelegator(
        uint256 _groupId,
        address _groupParticipant,
        address[] calldata _penultimateKeysFor,
        uint256[] calldata _penultimateKeysXUpdated,
        uint256[] calldata _penultimateKeysYUpdated,
        uint256 _timestampForWhichUpdatedKeysAreMeant,
        uint256 _groupParticipantDelegatorNonce,
        bytes calldata _signatureFromGroupParticipant
    )
        external
        onlyPebbleDelegatee
        delegatorNonceCorrect(
            _groupParticipant,
            _groupParticipantDelegatorNonce
        )
    {
        // Verify signature
        bytes32 paramsDigest = _getAcceptGroupInviteForDelegatorParamHash(
            _groupId,
            _groupParticipant,
            _penultimateKeysFor,
            _penultimateKeysXUpdated,
            _penultimateKeysYUpdated,
            _timestampForWhichUpdatedKeysAreMeant,
            _groupParticipantDelegatorNonce,
            ACCEPT_GROUP_INVITE_FOR_DELEGATOR_TYPEHASH
        );
        require(
            _groupParticipant ==
                ECDSAUpgradeable.recover(
                    paramsDigest,
                    _signatureFromGroupParticipant
                ),
            "PEBBLE: INCORRECT SIGNATURE"
        );

        // Accept invite
        _acceptGroupInvite(
            _groupId,
            _groupParticipant,
            _penultimateKeysFor,
            _penultimateKeysXUpdated,
            _penultimateKeysYUpdated,
            _timestampForWhichUpdatedKeysAreMeant
        );
    }

    /**
    @dev Accepts invititation to a group
    @param _groupId Group id of the group to accept invite for
    @param _groupParticipant Group participant who wants to accept group invite
    @param _penultimateKeysFor Addresses for which updated penultimate shared keys are meant for
    @param _penultimateKeysXUpdated Array of X coordinates of updated penultimate shared key corresponding to `_penultimateKeysFor`
    @param _penultimateKeysYUpdated Array of Y coordinates of updated penultimate shared key corresponding to `_penultimateKeysFor`
    @param _timestampForWhichUpdatedKeysAreMeant Timestamp at which the invitee checked the last updated penultimate keys
    @param _groupParticipantDelegatorNonce Group participant's delegator nonce
    @param _signatureFromGroupParticipant_v v component of signature from participant against which to confirm input params against
    @param _signatureFromGroupParticipant_r r component of signature from participant against which to confirm input params against
    @param _signatureFromGroupParticipant_s s component of signature from participant against which to confirm input params against
    */
    function acceptGroupInviteForDelegator(
        uint256 _groupId,
        address _groupParticipant,
        address[] calldata _penultimateKeysFor,
        uint256[] calldata _penultimateKeysXUpdated,
        uint256[] calldata _penultimateKeysYUpdated,
        uint256 _timestampForWhichUpdatedKeysAreMeant,
        uint256 _groupParticipantDelegatorNonce,
        uint8 _signatureFromGroupParticipant_v,
        bytes32 _signatureFromGroupParticipant_r,
        bytes32 _signatureFromGroupParticipant_s
    )
        external
        onlyPebbleDelegatee
        delegatorNonceCorrect(
            _groupParticipant,
            _groupParticipantDelegatorNonce
        )
    {
        // Verify signature
        bytes32 paramsDigest = _getAcceptGroupInviteForDelegatorParamHash(
            _groupId,
            _groupParticipant,
            _penultimateKeysFor,
            _penultimateKeysXUpdated,
            _penultimateKeysYUpdated,
            _timestampForWhichUpdatedKeysAreMeant,
            _groupParticipantDelegatorNonce,
            ACCEPT_GROUP_INVITE_FOR_DELEGATOR_TYPEHASH
        );
        require(
            _groupParticipant ==
                ECDSAUpgradeable.recover(
                    paramsDigest,
                    _signatureFromGroupParticipant_v,
                    _signatureFromGroupParticipant_r,
                    _signatureFromGroupParticipant_s
                ),
            "PEBBLE: INCORRECT SIGNATURE"
        );

        // Accept invite
        _acceptGroupInvite(
            _groupId,
            _groupParticipant,
            _penultimateKeysFor,
            _penultimateKeysXUpdated,
            _penultimateKeysYUpdated,
            _timestampForWhichUpdatedKeysAreMeant
        );
    }

    /**
    @dev Searches through group and finds all other group participants (excluding the participant who's invoking this)
    @param _groupId Group id of the group
    @return otherParticipants Array of other group participants
     */
    function getOtherGroupParticipants(
        uint256 _groupId
    ) external view returns (address[] memory otherParticipants) {
        otherParticipants = _getOtherGroupParticipants(_groupId, msg.sender);
    }

    /**
    @dev Gets timestamp when a group's penultimate shared keys were last updated
    @param _groupId Group id of the group
    @return timestamp Timestamp when a group's penultimate shared keys were last updated
     */
    function getGroupPenultimateSharedKeyLastUpdateTimestamp(
        uint256 _groupId
    ) external view returns (uint256 timestamp) {
        timestamp = _getGroupPenultimateSharedKeyLastUpdateTimestamp(_groupId);
    }

    /**
    @dev Gets a participant's penultimate shared key for a group id
    @param _groupId Group id to use to fetch penultimate shared key
    @param _groupParticipant Group participant for whom to fetch the penultimate shared key
    @return penultimateSharedKeyX X coordinate of penultimate shared key of group participant; Participant 1 * Participant 2 ... * RANDOM * G
    @return penultimateSharedKeyY Y coordinate of penultimate shared key of group participant; Participant 1 * Participant 2 ... * RANDOM * G
     */
    function getParticipantGroupPenultimateSharedKey(
        uint256 _groupId,
        address _groupParticipant
    )
        external
        view
        returns (uint256 penultimateSharedKeyX, uint256 penultimateSharedKeyY)
    {
        PenultimateSharedKey
            memory penultimateSharedKey = _getParticipantGroupPenultimateSharedKey(
                _groupId,
                _groupParticipant
            );
        (penultimateSharedKeyX, penultimateSharedKeyY) = (
            penultimateSharedKey.penultimateSharedKeyX,
            penultimateSharedKey.penultimateSharedKeyY
        );
    }

    /**
    @dev Gets a participant's penultimate shared key for a group id
    @param _groupId Group id to use to fetch penultimate shared key
    @param _groupParticipants Array of group participants for whom to fetch the penultimate shared keys
    @return penultimateSharedKeysX Array of X coordinate of penultimate shared keys of group participants; Participant 1 * Participant 2 ... * RANDOM * G
    @return penultimateSharedKeysY Array of Y coordinate of penultimate shared keys of group participants; Participant 1 * Participant 2 ... * RANDOM * G
     */
    function getParticipantsGroupPenultimateSharedKey(
        uint256 _groupId,
        address[] memory _groupParticipants
    )
        external
        view
        returns (
            uint256[] memory penultimateSharedKeysX,
            uint256[] memory penultimateSharedKeysY
        )
    {
        uint256 groupParticipantsNum = _groupParticipants.length;
        (penultimateSharedKeysX, penultimateSharedKeysY) = (
            new uint256[](groupParticipantsNum),
            new uint256[](groupParticipantsNum)
        );
        PenultimateSharedKey memory penultimateSharedKey;
        for (uint256 i; i < groupParticipantsNum; ++i) {
            penultimateSharedKey = _getParticipantGroupPenultimateSharedKey(
                _groupId,
                _groupParticipants[i]
            );
            (penultimateSharedKeysX[i], penultimateSharedKeysY[i]) = (
                penultimateSharedKey.penultimateSharedKeyX,
                penultimateSharedKey.penultimateSharedKeyY
            );
        }
    }

    /**
     * @dev Returns `true` if a participant has accepted a group invite
     * @param _groupId Group id of the group to check in
     * @param _participant Participant whose acceptance is to be checked
     */
    function didParticipantAcceptGroupInvite(
        uint256 _groupId,
        address _participant
    ) external view returns (bool) {
        return _didParticipantAcceptGroupInvite(_groupId, _participant);
    }

    /**
    @dev Sends a message from Sender in a group
    @param _groupId Group id of the group to send message in
    @param _encryptedMessage Encrypted message to send (MUST BE ENCRYPTED BY SHARED KEY, NOT PENULTIMATE SHARED KEY; SHARED KEY = SENDER PRIVATE KEY * SENDER PENULTIMATE SHARED KEY; THIS MUST BE CALCULATED LOCALLY)
     */
    function sendMessageInGroup(
        uint256 _groupId,
        bytes calldata _encryptedMessage
    ) external {
        _sendMessageInGroup(_groupId, msg.sender, _encryptedMessage);
    }

    /**
    @dev Sends a message from Sender in a group
    @param _groupId Group id of the group to send message in
    @param _sender Sender who wants to send message
    @param _encryptedMessage Encrypted message to send (MUST BE ENCRYPTED BY SHARED KEY, NOT PENULTIMATE SHARED KEY; SHARED KEY = SENDER PRIVATE KEY * SENDER PENULTIMATE SHARED KEY; THIS MUST BE CALCULATED LOCALLY)
    @param _senderDelegatorNonce Sender's delegator nonce
    @param _signatureFromSender Signature from sender against which to confirm input params against
     */
    function sendMessageInGroupForDelegator(
        uint256 _groupId,
        address _sender,
        bytes calldata _encryptedMessage,
        uint256 _senderDelegatorNonce,
        bytes calldata _signatureFromSender
    )
        external
        onlyPebbleDelegatee
        delegatorNonceCorrect(_sender, _senderDelegatorNonce)
    {
        // Verify signature
        bytes32 paramsDigest = _getSendMessageInGroupForDelegatorParamsHash(
            _groupId,
            _sender,
            _encryptedMessage,
            _senderDelegatorNonce,
            SEND_MESSAGE_IN_GROUP_FOR_DELEGATOR_TYPEHASH
        );
        require(
            _sender ==
                ECDSAUpgradeable.recover(paramsDigest, _signatureFromSender),
            "PEBBLE: INCORRECT SIGNATURE"
        );

        // Send message
        _sendMessageInGroup(_groupId, _sender, _encryptedMessage);
    }

    /**
    @dev Sends a message from Sender in a group
    @param _groupId Group id of the group to send message in
    @param _sender Sender who wants to send message
    @param _encryptedMessage Encrypted message to send (MUST BE ENCRYPTED BY SHARED KEY, NOT PENULTIMATE SHARED KEY; SHARED KEY = SENDER PRIVATE KEY * SENDER PENULTIMATE SHARED KEY; THIS MUST BE CALCULATED LOCALLY)
    @param _senderDelegatorNonce Sender's delegator nonce
    @param _signatureFromSender_v v component of signature from sender against which to confirm input params against
    @param _signatureFromSender_r r component of signature from sender against which to confirm input params against
    @param _signatureFromSender_s s component of signature from sender against which to confirm input params against
     */
    function sendMessageInGroupForDelegator(
        uint256 _groupId,
        address _sender,
        bytes calldata _encryptedMessage,
        uint256 _senderDelegatorNonce,
        uint8 _signatureFromSender_v,
        bytes32 _signatureFromSender_r,
        bytes32 _signatureFromSender_s
    )
        external
        onlyPebbleDelegatee
        delegatorNonceCorrect(_sender, _senderDelegatorNonce)
    {
        // Verify signature
        bytes32 paramsDigest = _getSendMessageInGroupForDelegatorParamsHash(
            _groupId,
            _sender,
            _encryptedMessage,
            _senderDelegatorNonce,
            SEND_MESSAGE_IN_GROUP_FOR_DELEGATOR_TYPEHASH
        );
        require(
            _sender ==
                ECDSAUpgradeable.recover(
                    paramsDigest,
                    _signatureFromSender_v,
                    _signatureFromSender_r,
                    _signatureFromSender_s
                ),
            "PEBBLE: INCORRECT SIGNATURE"
        );

        // Send message
        _sendMessageInGroup(_groupId, _sender, _encryptedMessage);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {PebbleRoleManager} from "src/PebbleRoleManager/PebbleRoleManager.sol";

contract PebbleImplementationManager is
    Initializable,
    PebbleRoleManager,
    UUPSUpgradeable
{
    // Constructor
    constructor() {
        _disableInitializers();
    }

    // Initializer
    function __PebbleImplementatationManager_init_unchained()
        internal
        onlyInitializing
    {
        __UUPSUpgradeable_init_unchained();
    }

    // Checks to see if an upgrade is authorised, i.e, made by Pebble admin
    function _authorizeUpgrade(address) internal override onlyPebbleAdmin {}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract PebbleRoleManager is AccessControlUpgradeable {
    // ROLES
    bytes32 public constant PEBBLE_ADMIN_ROLE =
        keccak256(abi.encodePacked("PEBBLE:PEBBLE_ADMIN_ROLE"));
    bytes32 public constant PEBBLE_DELEGATEE_ROLE =
        keccak256(abi.encodePacked("PEBBLE:PEBBLE_DELEGATEE_ROLE"));

    // Modifiers

    /**
    @dev Check if sender is a Pebble admin
     */
    modifier onlyPebbleAdmin() {
        _checkRole(PEBBLE_ADMIN_ROLE);
        _;
    }

    /**
    @dev Check if caller is a Pebble delegatee
     */
    modifier onlyPebbleDelegatee() {
        _checkRole(PEBBLE_DELEGATEE_ROLE);
        _;
    }

    // Functions

    /**
    @dev Initializer
    @param _pebbleAdmins Array of Pebble admins
    @param _delegatees Array of delegatees
     */
    function __PebbleRoleManager_init_unchained(
        address[] memory _pebbleAdmins,
        address[] memory _delegatees
    ) internal onlyInitializing {
        __AccessControl_init_unchained();

        // Set role admins
        _setRoleAdmin(PEBBLE_ADMIN_ROLE, PEBBLE_ADMIN_ROLE);
        _setRoleAdmin(PEBBLE_DELEGATEE_ROLE, PEBBLE_ADMIN_ROLE);

        // Assign roles
        uint256 pebbleAdminNum = _pebbleAdmins.length;
        uint256 delegateesNum = _delegatees.length;

        for (uint256 i; i < pebbleAdminNum; ++i) {
            _grantRole(PEBBLE_ADMIN_ROLE, _pebbleAdmins[i]);
        }

        for (uint256 i; i < delegateesNum; ++i) {
            _grantRole(PEBBLE_DELEGATEE_ROLE, _delegatees[i]);
        }
    }

    /**
    @dev Grants Pebble admin role to an address
    @dev Can only be called by Role admin of Pebble admin role, for obvious reasons
    @param _pebbleAdminNew New address to be granted Pebble admin role
     */
    function grantPebbleAdminRole(address _pebbleAdminNew) public {
        grantRole(PEBBLE_ADMIN_ROLE, _pebbleAdminNew);
    }

    /**
    @dev Grants Pebble Delegatee role to an address
    @dev Can only be called by Role admin of Delegatee role, for obvious reasons
    @param _delegateeNew New address to be granted Delegatee role
     */
    function grantPebbleDelegateeRole(address _delegateeNew) public {
        grantRole(PEBBLE_DELEGATEE_ROLE, _delegateeNew);
    }

    /**
    @dev Revokes Pebble admin role from an address
    @dev Can only be called by Role admin of Pebble admin role, for obvious reasons
    @param _pebbleAdminToRevoke Pebble admin role holder to revoke
     */
    function revokePebbleAdminRole(address _pebbleAdminToRevoke) public {
        revokeRole(PEBBLE_ADMIN_ROLE, _pebbleAdminToRevoke);
    }

    /**
    @dev Revokes Delegatee role from an address
    @dev Can only be called by Role admin of Delegatee role, for obvious reasons
    @param _delegateeToRevoke Delegatee role to revoke
     */
    function revokePebbleDelegateeRole(address _delegateeToRevoke) public {
        revokeRole(PEBBLE_DELEGATEE_ROLE, _delegateeToRevoke);
    }

    // Internals
    /**
    @dev Grants Delegatee role to an address
    @dev DOES NO CHECK FOR ROLE ADMIN
    @param _delegateeNew New address to be granted Delegatee role
     */
    function _grantPebbleDelegateeRole(address _delegateeNew) internal {
        _grantRole(PEBBLE_DELEGATEE_ROLE, _delegateeNew);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import {SignInternals} from "./SignInternals.sol";

contract PebbleSignManager is EIP712Upgradeable, SignInternals {
    // Init function
    function __PebbleSignMananger_init_unchained(string memory _version)
        internal
        onlyInitializing
    {
        __EIP712_init_unchained("PEBBLE", _version);
        _setVersion(_version);
    }

    // Functions
    /**
    @dev Gets contract version, at correct slot
    @return version Contract version
     */
    function getVersion() external pure returns (string memory) {
        return _getVersion();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

contract SignInternals {
    // Constants
    uint256 constant VERSION_SLOT = uint256(keccak256("PEBBLE:VERSION_SLOT"));

    // Internals

    /**
    @dev Gets contract version, at correct slot
    @return version Contract version
     */
    function _getVersion() internal pure returns (string storage version) {
        uint256 slotNum = VERSION_SLOT;
        assembly {
            version.slot := slotNum
        }
    }

    /**
    @dev Changes contract version, at correct slot
    @param _versionNew New version to store
     */
    function _setVersion(string memory _versionNew) internal {
        uint256 slotNum = VERSION_SLOT;
        assembly {
            sstore(
                slotNum,
                or(mload(add(_versionNew, 0x20)), mul(2, mload(_versionNew)))
            )
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {EllipticCurve} from "src/Libraries/EllipticCurve.sol";

library PebbleMath {
    /**
    @dev Returns the minimum of 2 numbers
     */
    function min(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a < _b ? _a : _b;
    }

    /**
    @dev Checks to see if the input points for a Public key are on secp256k1 curve
    @param _publicKeyX X coodinate of Public key
    @param _publicKeyY Y coodinate of Public key
    @return isPublicKeyOnGraph True, if the public key is on curve, else False.
     */
    function isPublicKeyOnCurve(uint256 _publicKeyX, uint256 _publicKeyY)
        internal
        pure
        returns (bool)
    {
        return
            EllipticCurve.isOnCurve(
                _publicKeyX,
                _publicKeyY,
                EllipticCurve.CurveA,
                EllipticCurve.CurveB,
                EllipticCurve.CurveP
            );
    }
}