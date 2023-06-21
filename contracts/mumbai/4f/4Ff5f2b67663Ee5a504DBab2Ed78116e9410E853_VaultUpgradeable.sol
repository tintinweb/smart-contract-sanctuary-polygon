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
// OpenZeppelin Contracts (last updated v4.8.3) (interfaces/IERC1967.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.9._
 */
interface IERC1967Upgradeable {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);
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
// OpenZeppelin Contracts (last updated v4.8.3) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/IERC1967Upgradeable.sol";
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
abstract contract ERC1967UpgradeUpgradeable is Initializable, IERC1967Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts (last updated v4.9.0) (access/AccessControl.sol)

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
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
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
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
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
                        Strings.toHexString(account),
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
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
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IMarketHubRegistrar} from "../IMarketHubRegistrar.sol";

/// @title Interface for ColleCollection
/// @notice This interface includes the necessary methods for managing ColleCollection NFTs.
interface IColleCollection is IMarketHubRegistrar, IERC721 {
    /**
     * @dev Emitted when a token is minted, we freeze the URI per OpenSea's metadata standard.
     */
    event PermanentURI(string _value, uint256 indexed _id);

    /**
     * @dev Emitted when the off-chain metadata for a token has been updated.
     */
    event SecondaryMetadataIPFS(string _ipfsHash, uint256 indexed _id);

    /// @notice Mints a new NFT.
    /// @param _uri The URI of the NFT's metadata.
    /// @param _receiver The address to receive the minted NFT.
    function mint(string memory _uri, address _receiver) external;

    /// @notice Updates the sale metadata of a specific NFT.
    /// @param _tokenId The ID of the NFT to update.
    /// @param _uri The new URI of the sale metadata.
    function updateSaleMetadata(uint256 _tokenId, string memory _uri) external;

    /// @notice Gets the sale metadata of a specific NFT.
    /// @param _tokenId The ID of the NFT to query.
    /// @return The URI of the sale metadata.
    function getSaleMetadata(uint256 _tokenId) external view returns (string memory);

    /// @notice Checks if the sale metadata of a specific NFT is set.
    /// @param _tokenId The ID of the NFT to query.
    /// @return True if the sale metadata is set, false otherwise.
    function isSaleMetadataSet(uint256 _tokenId) external view returns (bool);

    /// @notice Allows a signer to approve a transfer on their behalf using a signature.
    /// @param _from The owner address of the NFT to approve.
    /// @param _to The approved address.
    /// @param _tokenId The ID of the NFT to approve.
    /// @param _deadline The time until the approval is valid.
    /// @param _signature The signature proving the signer's intent.
    function permitApprove(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _deadline,
        bytes memory _signature
    ) external;

    /// @notice Allows a signer to transfer a NFT on their behalf using a signature.
    /// @param _from The current owner address of the NFT.
    /// @param _to The address to receive the NFT.
    /// @param _tokenId The ID of the NFT to transfer.
    /// @param _deadline The time until the transfer is valid.
    /// @param _signature The signature proving the signer's intent.
    function permitSafeTransfer(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _deadline,
        bytes memory _signature
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {IColleCollection} from "./IColleCollection.sol";

/// @title ICollectionRegistry
/// @notice Interface for the CollectionRegistry contract.
/// @dev This interface lists all the external functions implemented in the CollectionRegistry contract.
interface ICollectionRegistry {
    /**
     * @dev Emitted when a collection is registered.
     */
    event RegisteredCollection(address collection);

    /**
     * @dev Emitted when a collection is unregistered.
     */
    event UnregisteredCollection(address collection);

    /// @notice Registers a new collection.
    /// @param _collection The address of the collection to register.
    function registerCollection(address _collection) external;

    /// @notice Unregisters an existing collection.
    /// @param _collection The address of the collection to unregister.
    function unregisterCollection(address _collection) external;

    /// @notice Checks if a collection is registered.
    /// @param _collection The address of the collection to check.
    /// @return A boolean indicating whether the collection is registered or not.
    function isERC721Registered(address _collection) external view returns (bool);

    /// @notice Returns the collection interface for a registered collection.
    /// @param _collection The address of the collection.
    /// @return The interface of the registered collection.
    function getCollection(address _collection) external view returns (IColleCollection);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {MarketHubRegistrar, AccessControl} from "../MarketHubRegistrar.sol";
import {ICurrency, IERC20, IERC165} from "./ICurrency.sol";

/// @title BaseCurrency
/// @notice This contract is an abstraction for any ERC20 token to convert any value to a USDC equivalency for market calculations.
abstract contract BaseCurrency is ICurrency, MarketHubRegistrar {
    // The ERC20 token to be used as the currency
    IERC20 internal immutable erc20;

    /// @notice Constructor sets the address for the ERC20 token.
    /// @param _erc20 The address of the ERC20 token to be used as the currency.
    constructor(address _erc20) {
        erc20 = IERC20(_erc20);
    }

    /// @notice Returns the ERC20 token that is being used as the currency.
    /// @return The ERC20 token being used as the currency.
    function getERC20() public view returns (IERC20) {
        return erc20;
    }

    /**
     * @notice Checks if the contract implements an interface.
     * @param _interfaceId The ID of the interface.
     * @return True if the contract implements the interface, false otherwise.
     */
    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual override(AccessControl, IERC165) returns (bool) {
        return
            _interfaceId == type(ICurrency).interfaceId ||
            _interfaceId == type(IERC165).interfaceId ||
            AccessControl.supportsInterface(_interfaceId);
    }

    /// @notice Returns the estimated value in USDC of an amount of the currency.
    /// @dev This function is virtual and must be implemented in child contracts.
    /// @param _amount The amount of currency to estimate the value of.
    /// @return The estimated value in USDC of the specified amount of currency.
    function getEstimatedUSDCValue(uint256 _amount) public view virtual returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/// @title ICurrency
/// @notice This interface represents an abstraction for any ERC20 token to convert any value to a USDC equivalency for market calculations.
interface ICurrency is IERC165 {
    /// @notice Returns the ERC20 token that is being used as the currency.
    /// @return The ERC20 token being used as the currency.
    function getERC20() external view returns (IERC20);

    /// @notice Returns the estimated value in USDC of an amount of the currency.
    /// @dev This function is virtual and must be implemented in child contracts.
    /// @param _amount The amount of currency to estimate the value of.
    /// @return The estimated value in USDC of the specified amount of currency.
    function getEstimatedUSDCValue(uint256 _amount) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {BaseCurrency} from "./BaseCurrency.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title ICurrencyRegistry
/// @notice This is the interface for the Currency Registry contract.
interface ICurrencyRegistry {
    /**
     * @dev Emitted when a currency is registered.
     */
    event RegisteredCurrency(address currency, address erc20);

    /**
     * @dev Emitted when a currency is unregistered.
     */
    event UnregisteredCurrency(address currency, address erc20);

    /// @notice Registers an ERC20 token as a base currency.
    /// @param _currency The address of the BaseCurrency contract associated with the ERC20 token.
    function registerERC20(address _currency) external;

    /// @notice Unregisters an ERC20 token from being a base currency.
    /// @param _currency The address of the BaseCurrency contract associated with the ERC20 token.
    function unregisterERC20(address _currency) external;

    /// @notice Retrieves the BaseCurrency contract associated with a specific ERC20 token.
    /// @param _erc20 The address of the ERC20 token.
    /// @return The BaseCurrency contract associated with the ERC20 token.
    function getCurrencyByERC20(address _erc20) external view returns (BaseCurrency);

    /// @notice Retrieves the ERC20 token associated with a specific BaseCurrency contract.
    /// @param _currency The address of the BaseCurrency contract.
    /// @return The ERC20 token associated with the BaseCurrency contract.
    function getERC20ByCurrency(address _currency) external view returns (IERC20);

    /// @notice Checks if an ERC20 token is registered as a base currency.
    /// @param _erc20 The address of the ERC20 token.
    /// @return true if the ERC20 token is registered, false otherwise.
    function isERC20Registered(address _erc20) external view returns (bool);

    /// @notice Gets all registered ERC20 tokens.
    /// @return An array of addresses of the registered ERC20 tokens.
    function getERC20s() external view returns (address[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {IMarketHubRegistrar} from "../IMarketHubRegistrar.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IEscrow
 * @notice This interface outlines the functions necessary for an escrow system in a marketplace trading ERC721 and ERC20 tokens.
 * @dev Any contract implementing this interface can act as an escrow in the marketplace.
 */
interface IEscrow is IMarketHubRegistrar, IERC165 {
    /**
     * @dev Emitted when a sale is created.
     */
    event CreateSale(
        uint256 saleId,
        State state,
        address buyer,
        address spender,
        address erc20,
        uint256 price,
        address seller,
        address erc721,
        uint256 tokenId,
        string metadata
    );

    /**
     * @dev Emitted when a sale's state is updated.
     */
    event UpdateSale(uint256 saleId, State newState);

    /**
     * @dev Emitted when a royalty is paid out.
     */
    event RoyaltyPayout(uint256 saleId, address receiver, uint256 amount);

    /**
     * @dev Emitted when a commission is paid out.
     */
    event CommissionPayout(uint256 saleId, address receiver, uint256 amount);

    /**
     * @dev Emitted when a sale is complete.
     */
    event SaleComplete(uint256 saleId, uint256 payoutAmount);

    /**
     * @dev Emitted when a sale is cancelled.
     */
    event SaleCancelled(uint256 saleId, address erc20ReturnedTo, address erc721ReturnedTo);

    /**
     * @dev Emitted when the challenge window for buyers is changed.
     */
    event BuyerChallengeWindowChanged(uint256 numberOfHours);

    /**
     * @dev Emitted when the funding window for a sale is changed.
     */
    event SaleFundingWindowChanged(uint256 numberOfHours);

    /**
     * @notice Represents the different states a sale can be in.
     */
    enum State {
        AwaitingSettlement,
        AwaitingERC20Deposit,
        PendingSale,
        ProcessingSale,
        ShippingToBuyer,
        Received,
        ShippingToColleForAuthentication,
        ColleProcessingSale,
        ShippingToColleForDispute,
        IssueWithDelivery,
        IssueWithProduct,
        SaleCancelled,
        SaleSuccess
    }

    /**
     * @notice Represents a sale.
     */
    struct Sale {
        uint256 id;
        address buyer;
        address spender;
        address erc20;
        uint256 price;
        address seller;
        address erc721;
        uint256 tokenId;
        State state;
        uint256 createdTimestamp;
        uint256 receivedTimestamp;
    }

    /**
     * @notice Sets the time window during which buyers can challenge a sale.
     * @param _hours The new challenge window in hours.
     */
    function setBuyerChallengeWindow(uint256 _hours) external;

    /**
     * @notice Returns the current challenge window for buyers.
     * @return uint256 The challenge window in hours.
     */
    function buyerChallengeWindow() external view returns (uint256);

    /**
     * @notice Sets the time window during which a sale can be funded.
     * Can only be called by the colle.
     * @param _hours The new funding window in hours.
     */
    function setSaleFundingWindow(uint256 _hours) external;

    /**
     * @notice Returns the current funding window for buyers.
     * @return uint256 The funding window in hours.
     */
    function saleFundingWindow() external view returns (uint256);

    /**
     * @notice Creates a new sale.
     * @param _buyer The buyer's address.
     * @param _spender The address spending the ERC20 tokens.
     * @param _erc20 The address of the ERC20 token being used as currency.
     * @param _price The price in ERC20 tokens.
     * @param _seller The seller's address.
     * @param _erc721 The address of the ERC721 token being sold.
     * @param _tokenId The id of the ERC721 token being sold.
     * @param _payNow Whether the buyer pays immediately or not.
     */
    function createSale(
        address _buyer,
        address _spender,
        address _erc20,
        uint256 _price,
        address _seller,
        address _erc721,
        uint256 _tokenId,
        bool _payNow
    ) external;

    /**
     * @notice Returns details of a sale.
     * @param _saleId The id of the sale.
     * @return Sale The details of the sale.
     */
    function getSale(uint256 _saleId) external view returns (Sale memory);

    /**
     * @notice Checks if a particular ERC721 token is currently part of an active sale.
     * @param _erc721 The address of the ERC721 token.
     * @param _tokenId The id of the ERC721 token.
     * @return bool Whether the token is part of an active sale or not.
     */
    function hasActiveSale(address _erc721, uint256 _tokenId) external view returns (bool);

    /**
     * @notice Updates the state of a sale.
     * @param _saleId The id of the sale.
     * @param _newState The new state of the sale.
     */
    function updateSale(uint256 _saleId, State _newState) external;

    /**
     * @notice Allows a signer to permit the update of a sale's state.
     * @param _signer The address of the signer.
     * @param _saleId The id of the sale.
     * @param _newState The new state of the sale.
     * @param _deadline The time by which the update must be done.
     * @param _signature The signer's signature.
     */
    function permitUpdateSale(
        address _signer,
        uint256 _saleId,
        State _newState,
        uint256 _deadline,
        bytes memory _signature
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {IEscrow} from "./IEscrow.sol";

/**
 * @title IEscrowRegistry
 * @notice Interface for fetching the market's Escrow contract
 */
interface IEscrowRegistry {
    /**
     * @dev Emitted when a escrow is registered.
     */
    event RegisteredEscrow(address escrow);

    /**
     * @notice Returns the market's Escrow contract
     * @return The market's Escrow contract
     */
    function getEscrow() external view returns (IEscrow);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {IMarketRegistry} from "./markets/IMarketRegistry.sol";
import {ICurrencyRegistry} from "./currencies/ICurrencyRegistry.sol";
import {IRoyaltyRegistry} from "./royalties/IRoyaltyRegistry.sol";
import {IKYCRegistry} from "./kycs/IKYCRegistry.sol";
import {IVaultRegistry} from "./vaults/IVaultRegistry.sol";
import {IEscrowRegistry} from "./escrow/IEscrowRegistry.sol";
import {IUpgradeGatekeeper} from "./upgrade-gatekeeper/IUpgradeGatekeeper.sol";
import {ICollectionRegistry} from "./collections/ICollectionRegistry.sol";

/**
 * @title IMarketHub
 * @dev The IMarketHub contract provides an interface that encompasses
 * various other registries like Market, Currency, Royalty, KYC, Vault, Escrow, Collection
 * and some additional functionalities specifically for managing the MarketHub.
 */
interface IMarketHub is
    IMarketRegistry,
    ICurrencyRegistry,
    IRoyaltyRegistry,
    IKYCRegistry,
    IVaultRegistry,
    IEscrowRegistry,
    ICollectionRegistry
{
    /**
     * @dev Emitted when a upgradeGatekeeper is registered.
     */
    event RegisteredUpgradeGatekeeper(address upgradeGatekeeper);

    /**
     * @dev Emitted when the minimum price is changed.
     */
    event MinimumPriceChanged(uint256 _minUSDCPrice);

    /**
     * @dev Notifies that a particular sale for a ERC721 has closed (i.e. successfully sold, fault/not as described, or lost/damaged in shipment)
     * @param _saleId The id of the sale that has closed.
     */
    function notifySaleClosed(uint256 _saleId) external;

    /**
     * @dev Sets the minimum price in USDC for an asset.
     * @param _minUSDCPrice Minimum price in USDC.
     */
    function setMinUSDCPrice(uint256 _minUSDCPrice) external;

    /**
     * @dev Returns the current minimum price in USDC for an asset.
     * @return Minimum price in USDC.
     */
    function getMinUSDCPrice() external view returns (uint256);

    /**
     * @dev Returns the address of the Upgrade Gatekeeper contract.
     * @return Address of the Upgrade Gatekeeper.
     */
    function getUpgradeGatekeeper() external view returns (IUpgradeGatekeeper);

    /**
     * @dev Checks if new sales are allowed in the market.
     * @return Boolean value representing if new sales are allowed.
     */
    function allowNewSales() external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

/**
 * @title IMarketHubRegistrar
 * @dev This contract defines the interface for registering and unregistering to the MarketHub.
 */
interface IMarketHubRegistrar {
    /**
     * @dev Emitted when a marketHub is registered.
     */
    event RegisteredMarketHub(address marketHub);

    /**
     * @dev Emitted when a marketHub is registered.
     */
    event UnregisteredMarketHub(address marketHub);

    /**
     * @dev Register the calling contract to the MarketHub.
     * Only contracts that meet certain criteria may successfully register.
     */
    function register() external;

    /**
     * @dev Unregister the calling contract from the MarketHub.
     * Only contracts that are currently registered can successfully unregister.
     */
    function unregister() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

enum AccountStatus {
    ACTIVE,
    HAULTED,
    BANNED
}

struct Account {
    address account;
    bytes32 tier; // e.g. keccak("Black"), keccak("Gold"), keccak("Platinum"), keccak("Green")
    AccountStatus status;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Account, AccountStatus} from "./Account.sol";

/// @title KYC Registry interface
/// @dev This interface includes all the functions to manage KYC verified accounts.
interface IKYCRegistry {
    /**
     * @dev Emitted when a account is registered.
     */
    event RegisteredAccount(address account, bytes32 tier);

    /**
     * @dev Emitted when a account's tier is updated
     */
    event UpdatedAccountTier(address account, bytes32 tier);

    /**
     * @dev Emitted when a account's status is updated
     */
    event UpdatedAccountStatus(address account, AccountStatus status);

    /// @notice Register a new account for KYC process
    /// @dev Register a new account and associate it with a tier
    /// @param _account The address of the account to register
    /// @param _tier The tier level of the account
    function registerAccount(address _account, bytes32 _tier) external;

    /// @notice Update the tier level of an existing account
    /// @dev Updates the tier level of a registered account
    /// @param _account The address of the account to update
    /// @param _tier The new tier level of the account
    function updateTier(address _account, bytes32 _tier) external;

    /// @notice Temporarily disable an account
    /// @dev Temporarily haults an account
    /// @param _account The address of the account to hault
    function haultAccount(address _account) external;

    /// @notice Reactivate a temporarily disabled account
    /// @dev Unhaults a haulted account
    /// @param _account The address of the account to unhault
    function unhaultAccount(address _account) external;

    /// @notice Permanently ban an account
    /// @dev Bans an account from the system
    /// @param _account The address of the account to ban
    function banAccount(address _account) external;

    /// @notice Unban a previously banned account
    /// @dev Unbans a banned account
    /// @param _account The address of the account to unban
    function unbanAccount(address _account) external;

    /// @notice Get the details of an account
    /// @dev Fetches the Account details for the given account address
    /// @param _account The address of the account
    /// @return The Account struct containing account details
    function getAccount(address _account) external view returns (Account memory);

    /// @notice Checks if an account is registered
    /// @dev Checks the registry if an account address is registered
    /// @param _account The address of the account
    /// @return A boolean value indicating if the account is registered
    function isAccountRegistered(address _account) external view returns (bool);

    /// @notice Checks if an account is active
    /// @dev Checks the status of an account if it is active
    /// @param _account The address of the account
    /// @return A boolean value indicating if the account is active
    function isAccountActive(address _account) external view returns (bool);

    /// @notice Checks if an account is haulted
    /// @dev Checks the status of an account if it is haulted
    /// @param _account The address of the account
    /// @return A boolean value indicating if the account is haulted
    function isAccountHaulted(address _account) external view returns (bool);

    /// @notice Checks if an account is banned
    /// @dev Checks the status of an account if it is banned
    /// @param _account The address of the account
    /// @return A boolean value indicating if the account is banned
    function isAccountBanned(address _account) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {IMarketHub} from "./IMarketHub.sol";
import {MarketAccess, AccessControl} from "../utils/MarketAccess.sol";
import {IMarketHubRegistrar} from "./IMarketHubRegistrar.sol";

/**
 * @title MarketHubRegistrar
 * @dev This contract provides the functionality to register and unregister to the MarketHub.
 * Contracts that inherit from this contract can be registered and unregistered from the MarketHub.
 */
contract MarketHubRegistrar is IMarketHubRegistrar, MarketAccess {
    // The instance of the MarketHub that the contract is registered to
    IMarketHub public marketHub;

    /**
     * @dev Modifier to allow only the MarketHub contract to perform certain actions.
     */
    modifier onlyMarketHub() {
        require(msg.sender == address(marketHub), "Only MarketHub can call this function");
        _;
    }

    /**
     * @dev Registers the calling contract to the MarketHub.
     * Reverts if the contract is already registered.
     */
    function register() public virtual {
        require(address(marketHub) == address(0), "Market already registered");
        emit RegisteredMarketHub(msg.sender);
        marketHub = IMarketHub(msg.sender);
    }

    /**
     * @dev Unregisters the calling contract from the MarketHub.
     * Reverts if the contract is not registered.
     */
    function unregister() public virtual onlyMarketHub {
        emit UnregisteredMarketHub(address(marketHub));
        marketHub = IMarketHub(address(0));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IMarketHub} from "./IMarketHub.sol";
import {MarketAccessUpgradeable, AccessControlUpgradeable} from "../utils/MarketAccessUpgradeable.sol";
import {IMarketHubRegistrar} from "./IMarketHubRegistrar.sol";

/**
 * @title MarketHubRegistrarUpgradeable
 * @dev This abstract contract provides the functionality to register and unregister to the MarketHub.
 * Contracts that inherit from this contract can be registered and unregistered from the MarketHub.
 */
abstract contract MarketHubRegistrarUpgradeable is IMarketHubRegistrar, MarketAccessUpgradeable {
    // The instance of the MarketHub that the contract is registered to
    IMarketHub public marketHub;

    /**
     * @dev Initializes the contract, sets the initializing state and initial roles.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __MarketHubRegistrar_init() internal onlyInitializing {
        __MarketAccess_init();
    }

    /**
     * @dev Modifier to allow only the MarketHub contract to perform certain actions.
     */
    modifier onlyMarketHub() {
        require(msg.sender == address(marketHub), "Only MarketHub can call this function");
        _;
    }

    /**
     * @dev Registers the calling contract to the MarketHub.
     * Reverts if the contract is already registered.
     */
    function register() public virtual {
        require(address(marketHub) == address(0), "Market already registered");
        emit RegisteredMarketHub(msg.sender);
        marketHub = IMarketHub(msg.sender);
    }

    /**
     * @dev Unregisters the calling contract from the MarketHub.
     * Reverts if the contract is not registered.
     */
    function unregister() public virtual onlyMarketHub {
        emit UnregisteredMarketHub(address(marketHub));
        marketHub = IMarketHub(address(0));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IMarketHubRegistrar} from "../IMarketHubRegistrar.sol";

/// @title Market Interface
/// @dev Interface for the functionality of a market contract
interface IMarket is IMarketHubRegistrar, IERC165 {
    /**
     * @notice Handles when a token is no longer available
     * @dev Notifies that a particular sale for a ERC721 has closed (i.e. successfully sold, fault/not as described, or lost/damaged in shipment)
     * @param _saleId The id of the sale that has closed.
     */
    function handleSaleClosed(uint256 _saleId) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {IMarket} from "./IMarket.sol";

/// @title Market Registry interface
/// @dev An interface that defines the methods for the Market Registry
interface IMarketRegistry {
    /**
     * @dev Emitted when a market is registered.
     */
    event RegisteredMarket(address market, bytes32 name);

    /**
     * @dev Emitted when a market is unregistered.
     */
    event UnregisteredMarket(address market, bytes32 name);

    /// @notice Registers a new market
    /// @dev Adds the market to the registry
    /// @param _marketAddress The address of the market to register
    /// @param _marketName The name of the market
    function registerMarket(address _marketAddress, bytes32 _marketName) external;

    /// @notice Unregisters a market
    /// @dev Removes the market from the registry
    /// @param _marketAddress The address of the market to unregister
    /// @param _marketName The name of the market
    function unregisterMarket(address _marketAddress, bytes32 _marketName) external;

    /// @notice Retrieves the address of a market
    /// @dev Finds the market in the registry by its name
    /// @param _marketName The name of the market
    /// @return The address of the market
    function getMarket(bytes32 _marketName) external view returns (address);

    /// @notice Retrieves the names of all markets
    /// @dev Gets a list of all market names in the registry
    /// @return An array of market names
    function getMarketNames() external view returns (bytes32[] memory);

    /// @notice Checks if an address is a registered market
    /// @dev Looks up if a market is in the registry by its address
    /// @param _marketAddress The address of the market
    /// @return A boolean indicating if the market is registered
    function isMarket(address _marketAddress) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {MarketHubRegistrar, AccessControl} from "../MarketHubRegistrar.sol";
import {IRoyalty, IERC165} from "./IRoyalty.sol";

/**
 * @title BaseRoyalty
 * @dev Abstract contract for managing royalties. This contract provides the basis for creating
 * custom royalties models by enabling the derivation of subclasses.
 */
abstract contract BaseRoyalty is IRoyalty, MarketHubRegistrar {
    /**
     * @dev Calculates the basis points for the royalty pool
     * @param _erc20 The address of the ERC20 token
     * @param _totalAmount The total amount of tokens
     * @return royaltyPoolBasisPoints The calculated basis points for the royalty pool
     */
    function getRoyaltyPoolBasisPoints(
        address _erc20,
        uint256 _totalAmount
    ) external view virtual returns (uint256 royaltyPoolBasisPoints);

    /**
     * @dev Calculates the commission basis points
     * @param _erc20 The address of the ERC20 token
     * @param _totalAmount The total amount of tokens
     * @return commissionBasisPoints The calculated commission basis points
     */
    function getCommissionBasisPoints(
        address _erc20,
        uint256 _totalAmount
    ) external view virtual returns (uint256 commissionBasisPoints);

    /**
     * @dev Calculates the royalty and commission amounts
     * @param _erc20 The address of the ERC20 token
     * @param _totalAmount The total amount of tokens
     * @return _royaltyPoolAmount The calculated amount for the royalty pool
     * @return _comissionAmount The calculated commission amount
     */
    function getRoyaltyBreakdown(
        address _erc20,
        uint256 _totalAmount
    ) public view returns (uint256 _royaltyPoolAmount, uint256 _comissionAmount) {
        uint256 royaltyPoolBasisPoints = this.getRoyaltyPoolBasisPoints(_erc20, _totalAmount);
        uint256 commissionBasisPoints = this.getCommissionBasisPoints(_erc20, _totalAmount);

        // We never intend to come close to these numbers
        // but we needed to guard to ensure basis points never exceed 100%
        // If the guard is required, we might as well make it a reasonable-ish number
        // rather than just guard that its under 100% fees
        require(royaltyPoolBasisPoints <= 1000, "Royalty pool basis points cannot be greater than 10%");
        require(commissionBasisPoints <= 2500, "Commission basis points cannot be greater than 25%");

        _royaltyPoolAmount = (_totalAmount * royaltyPoolBasisPoints) / 10000;
        _comissionAmount = (_totalAmount * commissionBasisPoints) / 10000;
    }

    /**
     * @notice Checks if the contract implements an interface.
     * @param _interfaceId The ID of the interface.
     * @return True if the contract implements the interface, false otherwise.
     */
    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual override(AccessControl, IERC165) returns (bool) {
        return
            _interfaceId == type(IRoyalty).interfaceId ||
            _interfaceId == type(IERC165).interfaceId ||
            AccessControl.supportsInterface(_interfaceId);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IRoyalty
 * @dev Interface for managing royalties. This interface provides the basis for creating
 * custom royalties models by enabling the derivation of subclasses.
 */
interface IRoyalty is IERC165 {
    /**
     * @dev Calculates the basis points for the royalty pool
     * @param _erc20 The address of the ERC20 token
     * @param _totalAmount The total amount of tokens
     * @return royaltyPoolBasisPoints The calculated basis points for the royalty pool
     */
    function getRoyaltyPoolBasisPoints(
        address _erc20,
        uint256 _totalAmount
    ) external view returns (uint256 royaltyPoolBasisPoints);

    /**
     * @dev Calculates the commission basis points
     * @param _erc20 The address of the ERC20 token
     * @param _totalAmount The total amount of tokens
     * @return commissionBasisPoints The calculated commission basis points
     */
    function getCommissionBasisPoints(
        address _erc20,
        uint256 _totalAmount
    ) external view returns (uint256 commissionBasisPoints);

    /**
     * @dev Calculates the royalty and commission amounts
     * @param _erc20 The address of the ERC20 token
     * @param _totalAmount The total amount of tokens
     * @return _royaltyPoolAmount The calculated amount for the royalty pool
     * @return _comissionAmount The calculated commission amount
     */
    function getRoyaltyBreakdown(
        address _erc20,
        uint256 _totalAmount
    ) external view returns (uint256 _royaltyPoolAmount, uint256 _comissionAmount);

    /**
     * @dev Determines whether a product sold through this royalty tier requires manual authentication or not
     * @return True if the product requires manual authentication, false otherwise
     */
    function requiresManualAuthentication() external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IRoyaltyPool
 * @dev Interface for managing a pool of previous owners to pay royalties to. The pool includes an initial owner and recent owners.
 */
interface IRoyaltyPool is IERC165 {
    /**
     * @notice Emitted when the weight initial owners get in the pool is updated
     */
    event InitialOwnerWeight(uint weight);

    /**
     * @notice Emitted when the initial owner or recent owners updates for a token
     */
    event PoolUpdated(address indexed _erc721, uint256 indexed _tokenId, address initialOwner, address[4] recentOwners);

    /**
     * @dev Set initial owner's weight
     * @param _weight New weight to set for initial owner
     */
    function setInitialOwnerWeight(uint _weight) external;

    /**
     * @dev Tracks a new owner of a token
     * @param _erc721 The address of the token
     * @param _tokenId The ID of the token
     * @param _owner The address of the new owner
     */
    function trackNewOwner(address _erc721, uint256 _tokenId, address _owner) external;

    /**
     * @dev Returns the weight of the initial owner
     */
    function getInitialOwnerWeight() external view returns (uint);

    /**
     * @dev Returns the initial owner of a given token
     * @param _erc721 The address of the token
     * @param _tokenId The ID of the token
     */
    function getInitialOwner(address _erc721, uint256 _tokenId) external view returns (address);

    /**
     * @dev Returns the recent owners of a given token
     * @param _erc721 The address of the token
     * @param _tokenId The ID of the token
     */
    function getRecentOwners(address _erc721, uint256 _tokenId) external view returns (address[4] memory);

    /**
     * @dev Returns the total pool shares for a given token
     * @param _erc721 The address of the token
     * @param _tokenId The ID of the token
     */
    function totalPoolShares(address _erc721, uint256 _tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {BaseRoyalty} from "./BaseRoyalty.sol";
import {RoyaltyPool} from "./RoyaltyPool.sol";

/**
 * @title IRoyaltyRegistry
 * @dev This interface describes the functions exposed by the royalty registry.
 */
interface IRoyaltyRegistry {
    /**
     * @dev Emitted when a royalty is registered.
     */
    event RegisteredRoyalty(address royalty, bytes32 accountTier);

    /**
     * @dev Emitted when a royalty is unregistered.
     */
    event UnregisteredRoyalty(address royalty, bytes32 accountTier);

    /**
     * @dev Emitted when a royalty pool is registered.
     */
    event RegisteredRoyaltyPool(address royaltyPool);

    /**
     * @dev Emitted when the comission payout address has been updated.
     */
    event UpdatedColleComissions(address colleComission);

    /**
     * @dev Register a new royalty.
     * @param _accountTier The tier of the account for which to register the royalty.
     * @param _royalty The address of the royalty contract.
     */
    function registerRoyalty(bytes32 _accountTier, address _royalty) external;

    /**
     * @dev Unregister an existing royalty.
     * @param _accountTier The tier of the account for which to unregister the royalty.
     */
    function unregisterRoyalty(bytes32 _accountTier) external;

    /**
     * @dev Register a new royalty pool.
     * @param _royaltyPool The address of the royalty pool contract.
     */
    function registerRoyaltyPool(address _royaltyPool) external;

    /**
     * @dev Register a new colleCommissions.
     * @param _colleCommissions The address of the colleCommissions contract.
     */
    function registerColleCommissions(address _colleCommissions) external;

    /**
     * @dev Get the royalty of a specific account tier.
     * @param _accountTier The tier of the account for which to get the royalty.
     * @return The royalty contract of the specified account tier.
     */
    function getRoyalty(bytes32 _accountTier) external view returns (BaseRoyalty);

    /**
     * @dev Get the royalty pool.
     * @return The royalty pool contract.
     */
    function getRoyaltyPool() external view returns (RoyaltyPool);

    /**
     * @dev Get the colleComissions.
     * @return The address of the colleComissions contract.
     */
    function getColleComissions() external view returns (address);

    /**
     * @dev Check if a royalty is registered for a specific account tier.
     * @param _accountTier The tier of the account for which to check the royalty.
     * @return True if a royalty is registered for the specified account tier, false otherwise.
     */
    function isRoyaltyRegistered(bytes32 _accountTier) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {MarketHubRegistrar, AccessControl} from "../MarketHubRegistrar.sol";
import {IRoyaltyPool, IERC165} from "./IRoyaltyPool.sol";

/**
 * @title RoyaltyPool
 * @dev Contract for managing a pool of previous owners to pay royalties to. The pool includes an initial owner and recent owners.
 */
contract RoyaltyPool is IRoyaltyPool, MarketHubRegistrar {
    // Structure representing a Pool with initial owner and recent owners
    struct Pool {
        address initialOwner;
        address[4] recentOwners;
    }

    // Mapping from token address to token Id to Pool
    mapping(address => mapping(uint256 => Pool)) private pools;
    uint private initialOwnerWeight;

    /**
     * @dev Sets initial owner weight as 1 upon contract creation
     */
    constructor() {
        initialOwnerWeight = 1;
        emit InitialOwnerWeight(initialOwnerWeight);
    }

    modifier onlyEscrow() {
        require(msg.sender == address(marketHub.getEscrow()), "Caller is not the escrow");
        _;
    }

    /**
     * @dev Set initial owner's weight
     * @param _weight New weight to set for initial owner
     */
    function setInitialOwnerWeight(uint _weight) external onlyAdmin {
        initialOwnerWeight = _weight;
        emit InitialOwnerWeight(_weight);
    }

    /**
     * @dev Tracks a new owner of a token
     * @param _erc721 The address of the token
     * @param _tokenId The ID of the token
     * @param _owner The address of the new owner
     */
    function trackNewOwner(address _erc721, uint256 _tokenId, address _owner) external onlyEscrow {
        if (pools[_erc721][_tokenId].initialOwner == address(0)) {
            pools[_erc721][_tokenId].initialOwner = _owner;
            emit PoolUpdated(
                _erc721,
                _tokenId,
                pools[_erc721][_tokenId].initialOwner,
                pools[_erc721][_tokenId].recentOwners
            );
            return;
        }

        // If there is no one else in the pool AND the owner is the initialOwner, do not track them as a new owner
        if (pools[_erc721][_tokenId].initialOwner == _owner && pools[_erc721][_tokenId].recentOwners[3] == address(0)) {
            return;
        }

        // Shift the array to the left
        for (uint i = 0; i < 3; i++) {
            pools[_erc721][_tokenId].recentOwners[i] = pools[_erc721][_tokenId].recentOwners[i + 1];
        }
        // Add the new owner to the end
        pools[_erc721][_tokenId].recentOwners[3] = _owner;
        emit PoolUpdated(
            _erc721,
            _tokenId,
            pools[_erc721][_tokenId].initialOwner,
            pools[_erc721][_tokenId].recentOwners
        );
    }

    /**
     * @dev Returns the weight of the initial owner
     */
    function getInitialOwnerWeight() external view returns (uint) {
        return initialOwnerWeight;
    }

    /**
     * @dev Returns the initial owner of a given token
     * @param _erc721 The address of the token
     * @param _tokenId The ID of the token
     */
    function getInitialOwner(address _erc721, uint256 _tokenId) external view returns (address) {
        return pools[_erc721][_tokenId].initialOwner;
    }

    /**
     * @dev Returns the recent owners of a given token
     * @param _erc721 The address of the token
     * @param _tokenId The ID of the token
     */
    function getRecentOwners(address _erc721, uint256 _tokenId) external view returns (address[4] memory) {
        return pools[_erc721][_tokenId].recentOwners;
    }

    /**
     * @dev Returns the total pool shares for a given token
     * @param _erc721 The address of the token
     * @param _tokenId The ID of the token
     */
    function totalPoolShares(address _erc721, uint256 _tokenId) external view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < 4; i++) {
            if (pools[_erc721][_tokenId].recentOwners[i] != address(0)) {
                count++;
            }
        }
        return count + initialOwnerWeight;
    }

    /**
     * @notice Checks if the contract implements an interface.
     * @param _interfaceId The ID of the interface.
     * @return True if the contract implements the interface, false otherwise.
     */
    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual override(AccessControl, IERC165) returns (bool) {
        return
            _interfaceId == type(IRoyaltyPool).interfaceId ||
            _interfaceId == type(IERC165).interfaceId ||
            AccessControl.supportsInterface(_interfaceId);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IUpgradeGatekeeper
 * @dev Interface for the Upgrade Gatekeeper, which manages upgrade targets for contract proxies.
 */
interface IUpgradeGatekeeper is IERC165 {
    /**
     * @dev Emitted when an upgrade target is set for a specific proxy.
     * @param _proxy The address of the proxy.
     * @param _target The address of the upgrade target.
     */
    event UpgradeTargetSet(address indexed _proxy, address indexed _target);

    /**
     * @dev Sets an upgrade target for a specific proxy.
     * @param _proxy The address of the proxy.
     * @param _target The address of the upgrade target.
     */
    function setUpgradeTarget(address _proxy, address _target) external;

    /**
     * @dev Retrieves the current upgrade target for a specific proxy.
     * @param _proxy The address of the proxy.
     * @return The address of the upgrade target.
     */
    function getUpgradeTarget(address _proxy) external view returns (address);

    /**
     * @dev Resets the upgrade target.
     */
    function resetUpgradeTarget() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IMarketHubRegistrar} from "../IMarketHubRegistrar.sol";

/**
 * @title IVault
 * @dev IVault interface defines the functions for managing ERC20 and ERC721 assets.
 * @notice It includes events that are emitted for each function that alters the state of the contract.
 */
interface IVault is IMarketHubRegistrar, IERC165 {
    /**
     * @dev Emitted when an ERC20 token is deposited into the vault.
     */
    event DepositedERC20(address indexed erc20, uint256 amount);

    /**
     * @dev Emitted when an ERC20 token is withdrawn from the vault.
     */
    event WithdrawERC20(address indexed erc20, uint256 amount);

    /**
     * @dev Emitted when an ERC721 token is deposited into the vault.
     */
    event DepositERC721(address indexed erc721, uint256 tokenId);

    /**
     * @dev Emitted when an ERC721 token is withdrawn from the vault.
     */
    event WithdrawERC721(address indexed erc721, uint256 tokenId);

    /**
     * @dev Deposits ERC20 token into the vault.
     * @param _erc20 Address of the ERC20 token.
     * @param _amount Amount of the ERC20 token.
     * @param _sender Address of the sender.
     */
    function depositERC20(address _erc20, uint256 _amount, address _sender) external;

    /**
     * @dev Deposits ERC721 token into the vault.
     * @param _erc721 Address of the ERC721 token.
     * @param _tokenId Token Id of the ERC721 token.
     * @param _sender Address of the sender.
     */
    function depositColleNFT(address _erc721, uint256 _tokenId, address _sender) external;

    /**
     * @dev Withdraws ERC20 token from the vault.
     * @param _erc20 Address of the ERC20 token.
     * @param _amount Amount of the ERC20 token.
     * @param _receiver Address of the receiver.
     */
    function withdrawERC20(address _erc20, uint256 _amount, address _receiver) external;

    /**
     * @dev Withdraws ERC721 token from the vault.
     * @param _erc721 Address of the ERC721 token.
     * @param _tokenId Token Id of the ERC721 token.
     * @param _receiver Address of the receiver.
     */
    function withdrawColleNFT(address _erc721, uint256 _tokenId, address _receiver) external;

    /**
     * @dev Checks the balance of ERC20 token in the vault.
     * @param _erc20 Address of the ERC20 token.
     * @return Returns the balance of the ERC20 token.
     */
    function erc20Balances(address _erc20) external view returns (uint256);

    /**
     * @dev Checks if an ERC721 token is in the vault.
     * @param _erc721 Address of the ERC721 token.
     * @param _tokenId Token Id of the ERC721 token.
     * @return Returns true if the ERC721 token is in the vault, otherwise false.
     */
    function erc721Balances(address _erc721, uint256 _tokenId) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {IVault} from "./IVault.sol";

/**
 * @title IVaultRegistry
 * @dev This interface defines a function to get the instance of the deployed vault contract.
 * @notice This registry provides the address of the Vault contract which manages the ERC20 and ERC721 assets.
 */
interface IVaultRegistry {
    /**
     * @dev Emitted when a vault is registered.
     */
    event RegisteredVault(address vault);

    /**
     * @dev Returns the instance of the deployed vault contract.
     * @return Returns the instance of the IVault.
     */
    function getVault() external view returns (IVault);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IERC721ReceiverUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IColleCollection} from "../collections/IColleCollection.sol";
import {MarketHubRegistrarUpgradeable, AccessControlUpgradeable} from "../MarketHubRegistrarUpgradeable.sol";
import {IVault, IERC165} from "./IVault.sol";

/**
 * @title VaultUpgradeable
 * @dev The Vault contract that manages the ERC20 and ERC721 assets.
 * The Vault contract is upgradeable and makes use of the OpenZeppelin's UUPSUpgradeable contracts.
 * The contract implements the IVault interface and inherits from the MarketHubRegistrarUpgradeable and IERC721ReceiverUpgradeable contracts.
 */
contract VaultUpgradeable is IVault, MarketHubRegistrarUpgradeable, UUPSUpgradeable, IERC721ReceiverUpgradeable {
    mapping(address => uint256) public erc20Balances;
    mapping(address => mapping(uint256 => bool)) public erc721Balances;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        // Prevents implementation contract from being hijacked
        initialize();
    }

    /**
     * @dev Initialize function that replaces the constructor
     */
    function initialize() public initializer {
        __UUPSUpgradeable_init();
        __MarketHubRegistrar_init();
    }

    /**
     * @dev Internal function to authorize upgrades, verifies if the new implementation address matches the one provided by the upgrade gatekeeper.
     * @param newImplementation The address of the new implementation.
     */
    function _authorizeUpgrade(address newImplementation) internal override {
        require(
            marketHub.getUpgradeGatekeeper().getUpgradeTarget(address(this)) == newImplementation,
            "Given implementation is not the target implementation"
        );
        marketHub.getUpgradeGatekeeper().resetUpgradeTarget();
    }

    modifier onlyEscrow() {
        require((msg.sender == address(marketHub.getEscrow())), "Only Escrow can call this function");
        _;
    }

    /**
     * @dev Deposits the given amount of ERC20 token to the vault contract.
     * @param _erc20 The address of the ERC20 token.
     * @param _amount The amount of the ERC20 token to deposit.
     * @param _sender The address of the sender.
     */
    function depositERC20(address _erc20, uint256 _amount, address _sender) external virtual override onlyEscrow {
        require(_erc20 != address(0), "ERC20 address cannot be 0");
        require(_amount > 0, "ERC20 amount must be greater than 0");

        IERC20 erc20 = IERC20(_erc20);
        require(erc20.allowance(_sender, address(this)) >= _amount, "ERC20 allowance too low");

        erc20Balances[_erc20] += _amount;
        emit DepositedERC20(_erc20, _amount);

        // Uses arbitrary from in transferFrom
        // Guarded by onlyEscrow, which is only the registered Escrow contract of the marketplace
        // Precautions have been taken to ensure that the Escrow contract is secure
        require(erc20.transferFrom(_sender, address(this), _amount), "ERC20 transfer failed");
    }

    /**
     * @dev Deposits the given ERC721 token to the vault contract.
     * @param _erc721 The address of the ERC721 token.
     * @param _tokenId The ID of the ERC721 token to deposit.
     * @param _sender The address of the sender.
     */
    function depositColleNFT(address _erc721, uint256 _tokenId, address _sender) external virtual override onlyEscrow {
        require(_erc721 != address(0), "ERC721 address cannot be 0");

        IColleCollection erc721 = IColleCollection(_erc721);
        require(erc721.ownerOf(_tokenId) == _sender, "ERC721 owner is not the sender");

        erc721Balances[_erc721][_tokenId] = true;
        emit DepositERC721(_erc721, _tokenId);

        erc721.safeTransferFrom(_sender, address(this), _tokenId);
    }

    /**
     * @dev Withdraws the given amount of ERC20 token from the vault contract.
     * @param _erc20 The address of the ERC20 token.
     * @param _amount The amount of the ERC20 token to withdraw.
     * @param _receiver The address of the receiver.
     */
    function withdrawERC20(address _erc20, uint256 _amount, address _receiver) external virtual override onlyEscrow {
        require(_erc20 != address(0), "ERC20 address cannot be 0");
        require(_amount > 0, "ERC20 amount must be greater than 0");

        IERC20 erc20 = IERC20(_erc20);
        require(erc20Balances[_erc20] >= _amount, "ERC20 balance too low");

        erc20Balances[_erc20] -= _amount;
        emit WithdrawERC20(_erc20, _amount);

        require(erc20.transfer(_receiver, _amount), "ERC20 transfer failed");
    }

    /**
     * @dev Withdraws the given ERC721 token from the vault contract.
     * @param _erc721 The address of the ERC721 token.
     * @param _tokenId The ID of the ERC721 token to withdraw.
     * @param _receiver The address of the receiver.
     */
    function withdrawColleNFT(
        address _erc721,
        uint256 _tokenId,
        address _receiver
    ) external virtual override onlyEscrow {
        require(_erc721 != address(0), "ERC721 address cannot be 0");

        IColleCollection erc721 = IColleCollection(_erc721);
        require(erc721Balances[_erc721][_tokenId], "ERC721 is not deposited");

        erc721Balances[_erc721][_tokenId] = false;
        emit WithdrawERC721(_erc721, _tokenId);

        erc721.safeTransferFrom(address(this), _receiver, _tokenId);
    }

    /**
     * @dev Function that is called when an ERC721 token is received.
     * @param _operator The address of the operator, which must be the Vault itself
     * @notice _from, _tokenId and _data parameters are exist per standard but are unused
     */
    function onERC721Received(
        address _operator,
        address /*_from*/,
        uint256 /*_tokenId*/,
        bytes calldata /*_data*/
    ) external view override returns (bytes4) {
        require(_operator == address(this), "ERC721 received from unauthenticated contract");
        return this.onERC721Received.selector;
    }

    /**
     * @notice Checks if the contract implements an interface.
     * @param _interfaceId The ID of the interface.
     * @return True if the contract implements the interface, false otherwise.
     */
    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual override(AccessControlUpgradeable, IERC165) returns (bool) {
        return
            _interfaceId == type(IVault).interfaceId ||
            _interfaceId == type(IERC165).interfaceId ||
            AccessControlUpgradeable.supportsInterface(_interfaceId);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/// @title MarketAccess
/// @dev This contract provides a role-based access control for the marketplace.
/// It extends OpenZeppelin's AccessControl for role management.
contract MarketAccess is AccessControl {
    /// @notice Role identifier for Relayer role
    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");

    /// @notice Sets the deployer as the initial admin
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Checks if an address is assigned the Relayer role
    /// @param _address The address to check
    /// @return bool Returns true if the address has the Relayer role, false otherwise.
    function isRelayer(address _address) internal view returns (bool) {
        return hasRole(RELAYER_ROLE, _address);
    }

    /// @notice Modifier to restrict the access to only addresses with the Relayer role
    modifier onlyRelayer() {
        require(hasRole(RELAYER_ROLE, msg.sender), "Caller is not a relayer");
        _;
    }

    /// @notice Modifier to restrict the access to only addresses with the Relayer role
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not a admin");
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/// @title MarketAccessUpgradeable
/// @dev This contract provides role-based access control for the marketplace.
/// It extends the AccessControlUpgradeable contract from OpenZeppelin for role management in an upgradeable manner.
abstract contract MarketAccessUpgradeable is AccessControlUpgradeable {
    /// @notice Role identifier for the Colle role
    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");

    /// @notice Sets the deployer as the initial admin and colle.
    /// @dev This function should be called in the initialize function of the contract implementing this abstract contract.
    // solhint-disable-next-line func-name-mixedcase
    function __MarketAccess_init() internal onlyInitializing {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Checks if an address is assigned the Relayer role
    /// @param _address The address to check
    /// @return bool Returns true if the address has the Relayer role, false otherwise.
    function isRelayer(address _address) internal view returns (bool) {
        return hasRole(RELAYER_ROLE, _address);
    }

    /// @notice Modifier to restrict the access to only addresses with the Relayer role
    modifier onlyRelayer() {
        require(hasRole(RELAYER_ROLE, msg.sender), "Caller is not a relayer");
        _;
    }

    /// @notice Modifier to restrict the access to only addresses with the Relayer role
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not a admin");
        _;
    }
}