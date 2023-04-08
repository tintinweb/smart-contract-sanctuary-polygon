// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
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

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
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
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
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
            Address.functionDelegateCall(newImplementation, data);
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
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
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
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
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
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
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
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
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

import "../../utils/Address.sol";

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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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

import "../../interfaces/draft-IERC1822.sol";
import "../ERC1967/ERC1967Upgrade.sol";

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
abstract contract UUPSUpgradeable is IERC1822Proxiable, ERC1967Upgrade {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function setApprovalForAll(address operator, bool _approved) external;

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
library StorageSlot {
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

import "./math/Math.sol";

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is
    Initializable,
    ContextUpgradeable,
    ERC165Upgradeable,
    IERC721Upgradeable,
    IERC721MetadataUpgradeable
{
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721Upgradeable.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, data) returns (
                bytes4 retval
            ) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function setApprovalForAll(address operator, bool _approved) external;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { UUPSUpgradeable } from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import { RoleControl } from "@src-root/lib/RoleControl.sol";
import { VisitedByTypes } from "@src-root/lib/VisitedByTypes.sol";

// create a contract that extends the OpenZeppelin AccessControl contract
contract PoVAttributeParser is Initializable, UUPSUpgradeable, RoleControl, VisitedByTypes {
    function initialize() public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function parse(uint16 attribute) public pure returns (SpotAttribute memory) {
        SpotAttribute memory spotAttribute;
        spotAttribute.deviceType = deviceType((attribute >> 12) & 0x0f);
        spotAttribute.subType = subType((attribute >> 8) & 0x0f);
        spotAttribute.timestampType = timestampType((attribute >> 4) & 0x0f);
        spotAttribute.signatureType = signatureType(attribute & 0x0f);
        return spotAttribute;
    }

    function deviceType(uint16 attribute) public pure returns (bytes16) {
        // Device Type
        bytes16[16] memory deviceTypeTable = [
            bytes16("NfcCard"), // 0x00
            bytes16("Ble"), // 0x01
            bytes16("WiFi"), // 0x02
            bytes16(""), // 0x03
            bytes16(""), // 0x04
            bytes16(""), // 0x05
            bytes16(""), // 0x06
            bytes16(""), // 0x07
            bytes16(""), // 0x08
            bytes16(""), // 0x09
            bytes16(""), // 0x0a
            bytes16(""), // 0x0b
            bytes16(""), // 0x0c
            bytes16(""), // 0x0d
            bytes16(""), // 0x0e
            bytes16("") // 0x0f
        ];

        return deviceTypeTable[attribute];
    }

    function subType(uint16 attribute) public pure returns (bytes16) {
        // subType
        bytes16[16] memory subTypeTable = [
            bytes16(""), // 0x00
            bytes16(""), // 0x01
            bytes16(""), // 0x02
            bytes16(""), // 0x03
            bytes16(""), // 0x04
            bytes16(""), // 0x05
            bytes16(""), // 0x06
            bytes16(""), // 0x07
            bytes16(""), // 0x08
            bytes16(""), // 0x09
            bytes16(""), // 0x0a
            bytes16(""), // 0x0b
            bytes16(""), // 0x0c
            bytes16(""), // 0x0d
            bytes16(""), // 0x0e
            bytes16("") // 0x0f
        ];

        return subTypeTable[attribute];
    }

    function timestampType(uint16 attribute) public pure returns (bytes16) {
        // timestamper
        bytes16[16] memory timestampTypeTable = [
            bytes16("User"), // 0x00
            bytes16("GPS"), // 0x01
            bytes16("RTC"), // 0x02
            bytes16(""), // 0x03
            bytes16(""), // 0x04
            bytes16(""), // 0x05
            bytes16(""), // 0x06
            bytes16(""), // 0x07
            bytes16(""), // 0x08
            bytes16(""), // 0x09
            bytes16(""), // 0x0a
            bytes16(""), // 0x0b
            bytes16(""), // 0x0c
            bytes16(""), // 0x0d
            bytes16(""), // 0x0e
            bytes16("") // 0x0f
        ];

        return timestampTypeTable[attribute];
    }

    function signatureType(uint16 attribute) public pure returns (bytes16) {
        // Device Type
        bytes16[16] memory signatureTypeTable = [
            bytes16("Simplify"), // 0x00
            bytes16("Strict"), // 0x01
            bytes16(""), // 0x02
            bytes16(""), // 0x03
            bytes16(""), // 0x04
            bytes16(""), // 0x05
            bytes16(""), // 0x06
            bytes16(""), // 0x07
            bytes16(""), // 0x08
            bytes16(""), // 0x09
            bytes16(""), // 0x0a
            bytes16(""), // 0x0b
            bytes16(""), // 0x0c
            bytes16(""), // 0x0d
            bytes16(""), // 0x0e
            bytes16("") // 0x0f
        ];

        return signatureTypeTable[attribute];
    }

    /**
     * @dev change contract admin
     * @notice msg.sender should be contract admin.
     * @param admin address, new admin address
     */
    function changeContractAdministrator(address admin) public onlyAdmin {
        addAdmin(admin);
        deleteAdmin(msg.sender);
    }

    // ================================================================
    //  override functions
    // ================================================================
    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyAdmin {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { UUPSUpgradeable } from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import { VisitedBy } from "@src-root/VisitedBy.sol";
import { VSIT } from "@src-root/token/VSIT.sol";
import { VisitedByTypes } from "@src-root/lib/VisitedByTypes.sol";
import { RoleControl } from "@src-root/lib/RoleControl.sol";
import { IPoVFactory } from "@src-root/lib/interface/IPoVFactory.sol";
import { PoV5192Factory } from "@src-root/pov/ERC5192/PoV5192Factory.sol";

contract PoVFactoryRegistry is Initializable, UUPSUpgradeable, RoleControl, VisitedByTypes {
    // ================================================================
    //  usings
    // ================================================================
    using Counters for Counters.Counter;
    using Address for address;

    // ================================================================
    //  structs
    // ================================================================

    /**
     * @dev Factory record
     * @param factory IPoVFactory
     * @param factory ID uint256
     * @param author address of spot owner
     * @param cost uint256 cost
     * @param status uint16 status
     * @param tag uint80 tag
     */
    struct PoVFactoryRecord {
        IPoVFactory factory;
        uint256 factoryID;
        address author;
        uint256 cost;
        uint16 status;
        uint80 tag;
    }

    // total spot count
    Counters.Counter private _totalFactoryCount;

    // ================================================================
    //  events
    // ================================================================

    event Register(uint256 indexed factoryID, address indexed author);

    event ChangeStatus(uint256 indexed factoryID, uint16 indexed status);

    // ================================================================
    //  variables
    // ================================================================
    VSIT private _vsit;

    // ================================================================
    //  mappings
    // ================================================================

    // povFactoryID -> PoVFactoryRecord
    mapping(uint256 => PoVFactoryRecord) private povFactoryMapping;

    // ================================================================
    //  modifiers
    // ================================================================

    modifier onlyRegisteredID(uint256 povFactoryID) {
        require(address(0) != address(povFactoryMapping[povFactoryID].factory), "not registered");
        _;
    }

    modifier isPaused(uint256 povFactoryID) {
        require(((povFactoryMapping[povFactoryID].status & 0x1) == 0x0), "paused");
        _;
    }

    modifier onlyAuthor(uint256 povFactoryID) {
        // Check if the spot is owned by the sender
        require(msg.sender == povFactoryMapping[povFactoryID].author, "only author");
        _;
    }

    // ================================================================
    //  initializer
    // ================================================================
    function initialize(PoV5192Factory poV5192Factory, address _vsitTokenAddress) public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _vsit = VSIT(_vsitTokenAddress);

        // initial factories
        _register(IPoVFactory(address(poV5192Factory)), msg.sender, 0, 0x3 /* official SBT */);
    }

    // ================================================================
    //  User functions
    // ================================================================
    /**
     * @dev create new pov
     * @notice you can register PoV for your resolver.
     * @param id uint256, povFactoryID
     * @param povOwner pov owner address
     * @param resolver address, resolver address
     * @param poVInfo pov info
     * @param extraParam bytes, extra param for create new PoV
     * @return address, new pov address
     */
    function createNewPoV(uint256 id, address povOwner, address resolver, PoVInfo memory poVInfo, bytes calldata extraParam) external payable onlyRegisteredID(id) returns (address) {
        if (0 < povFactoryMapping[id].cost) {
            // author fee
            _vsit.payFee(povOwner, povFactoryMapping[id].author, povFactoryMapping[id].cost);
        }

        return povFactoryMapping[id].factory.createNewPoV(povOwner, resolver, poVInfo, povFactoryMapping[id].tag, extraParam);
    }

    function name(uint256 id) external view returns (string memory) {
        return povFactoryMapping[id].factory.name();
    }

    function tag(uint256 id) external view returns (bytes16[6] memory) {
        return tagAsReadable(povFactoryMapping[id].tag);
    }

    function tagAsReadable(uint80 _tag) public pure returns (bytes16[6] memory) {
        bytes16[6] memory tagsAsBytes16;
        uint256 saveIdx = 0;

        // tag table
        bytes16[80] memory tagTbl = [
            bytes16("Official"), // 0x00
            bytes16("SBT"), // 0x01
            bytes16("NFT"), // 0x02
            bytes16(""), // 0x03
            bytes16(""), // 0x04
            bytes16(""), // 0x05
            bytes16(""), // 0x06
            bytes16(""), // 0x07
            bytes16(""), // 0x08
            bytes16(""), // 0x09
            bytes16(""), // 0x0a
            bytes16(""), // 0x0b
            bytes16(""), // 0x0c
            bytes16(""), // 0x0d
            bytes16(""), // 0x0e
            bytes16(""), // 0x0f
            bytes16(""), // 0x10
            bytes16(""), // 0x11
            bytes16(""), // 0x12
            bytes16(""), // 0x13
            bytes16(""), // 0x14
            bytes16(""), // 0x15
            bytes16(""), // 0x16
            bytes16(""), // 0x17
            bytes16(""), // 0x18
            bytes16(""), // 0x19
            bytes16(""), // 0x1a
            bytes16(""), // 0x1b
            bytes16(""), // 0x1c
            bytes16(""), // 0x1d
            bytes16(""), // 0x1e
            bytes16(""), // 0x1f
            bytes16(""), // 0x20
            bytes16(""), // 0x21
            bytes16(""), // 0x22
            bytes16(""), // 0x23
            bytes16(""), // 0x24
            bytes16(""), // 0x25
            bytes16(""), // 0x26
            bytes16(""), // 0x27
            bytes16(""), // 0x28
            bytes16(""), // 0x29
            bytes16(""), // 0x2a
            bytes16(""), // 0x2b
            bytes16(""), // 0x2c
            bytes16(""), // 0x2d
            bytes16(""), // 0x2e
            bytes16(""), // 0x2f
            bytes16(""), // 0x30
            bytes16(""), // 0x31
            bytes16(""), // 0x32
            bytes16(""), // 0x33
            bytes16(""), // 0x34
            bytes16(""), // 0x35
            bytes16(""), // 0x36
            bytes16(""), // 0x37
            bytes16(""), // 0x38
            bytes16(""), // 0x39
            bytes16(""), // 0x3a
            bytes16(""), // 0x3b
            bytes16(""), // 0x3c
            bytes16(""), // 0x3d
            bytes16(""), // 0x3e
            bytes16(""), // 0x3f
            bytes16(""), // 0x40
            bytes16(""), // 0x41
            bytes16(""), // 0x42
            bytes16(""), // 0x43
            bytes16(""), // 0x44
            bytes16(""), // 0x45
            bytes16(""), // 0x46
            bytes16(""), // 0x47
            bytes16(""), // 0x48
            bytes16(""), // 0x49
            bytes16(""), // 0x4a
            bytes16(""), // 0x4b
            bytes16(""), // 0x4c
            bytes16(""), // 0x4d
            bytes16(""), // 0x4e
            bytes16("") // 0x4f
        ];

        for (uint256 i = 0; i < tagTbl.length; i++) {
            if (bytes16("") == tagTbl[i]) {
                break;
            }
            if (0 != (_tag & (1 << i))) {
                tagsAsBytes16[saveIdx] = tagTbl[i];
                saveIdx++;
                if (6 <= saveIdx) {
                    break;
                }
            }
        }
        return tagsAsBytes16;
    }

    function statusAsReadable(uint16 status) public pure returns (bytes16[] memory) {
        bytes16[] memory tagsAsBytes16;
        uint256 saveIdx = 0;

        // status
        bytes16[16] memory statusTbl = [
            bytes16("paused"), // 0x00
            bytes16("verified"), // 0x01
            bytes16(""), // 0x02
            bytes16(""), // 0x03
            bytes16(""), // 0x04
            bytes16(""), // 0x05
            bytes16(""), // 0x06
            bytes16(""), // 0x07
            bytes16(""), // 0x08
            bytes16(""), // 0x09
            bytes16(""), // 0x0a
            bytes16(""), // 0x0b
            bytes16(""), // 0x0c
            bytes16(""), // 0x0d
            bytes16(""), // 0x0e
            bytes16("") // 0x0f
        ];

        for (uint256 i = 0; i < statusTbl.length; i++) {
            if (bytes16("") == statusTbl[i]) {
                break;
            }
            if (0 != (status & (1 << i))) {
                tagsAsBytes16[saveIdx] = statusTbl[i];
                saveIdx++;
            }
        }
        return tagsAsBytes16;
    }

    /**
     * @dev total Factory count
     * @return uint256, total Factory count
     */
    function total() public view returns (uint256) {
        return _totalFactoryCount.current();
    }

    /**
     * @dev get PoVFactory record
     * @notice return is 0x0 if spot is not registered.
     * @param id uint256, povFactoryID
     * @return PoVFactoryRecord, spot info
     */
    function getPoVFactoryRecord(uint256 id) public view returns (PoVFactoryRecord memory) {
        return povFactoryMapping[id];
    }

    /**
     * @dev get spot pause/unpaused status
     * @notice return is false if spot is not registered.
     * @param id uint256, povFactoryID
     */
    function paused(uint256 id) public view returns (bool) {
        return (povFactoryMapping[id].status & 0x1) == 0x1;
    }

    /**
     * @dev get spot valid status
     * @notice return is false if spot is not registered.
     * @param id uint256, povFactoryID
     */
    function isRegistered(uint256 id) public view returns (bool) {
        return address(0) != address(povFactoryMapping[id].factory);
    }

    /*
     * @dev get spot author
     * @param id uint256, povFactoryID
     * @return address, author
     */
    function costOf(uint256 id) public view returns (uint256) {
        if (false == isRegistered(id)) revert("not registered");
        return povFactoryMapping[id].cost;
    }

    // ================================================================
    //  Owner functions
    // ================================================================
    /**
     * @dev Register new factory to registry
     * @notice msg.sender should be contract owner.
     * @param factory IPoVFactory, factory
     * @param author address, author who created povFactory
     * @param cost uint256, cost as wei
     * @param factoryTag uint80, factoryTag
     * @return uint256, factoryID
     */
    function register(IPoVFactory factory, address author, uint256 cost, uint80 factoryTag) public onlyAdmin returns (uint256) {
        if (10 ether < cost) revert("cost is too high");
        return _register(factory, author, cost, factoryTag);
    }

    /**
     * @dev pause factory
     * @notice msg.sender should be contract owner.
     * @param id uint256, povFactoryID
     */
    function pause(uint256 id) public onlyRegisteredID(id) onlyAdmin {
        povFactoryMapping[id].status = povFactoryMapping[id].status | 0x1;

        emit ChangeStatus(povFactoryMapping[id].factoryID, povFactoryMapping[id].status);
    }

    /**
     * @dev unpause factory
     * @notice msg.sender should be contract owner.
     * @param id uint256, povFactoryID
     */
    function unpause(uint256 id) public onlyRegisteredID(id) onlyAdmin {
        povFactoryMapping[id].status = povFactoryMapping[id].status & 0xFFFE;

        emit ChangeStatus(povFactoryMapping[id].factoryID, povFactoryMapping[id].status);
    }

    /**
     * @dev change contract admin
     * @notice msg.sender should be contract admin.
     * @param admin address, new admin address
     */
    function changeContractAdministrator(address admin) public onlyAdmin {
        addAdmin(admin);
        deleteAdmin(msg.sender);

        emit ChangeContractOwner(msg.sender, admin);
    }

    // ================================================================
    //  override functions
    // ================================================================
    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyAdmin {}

    // ================================================================
    //  internal functions
    // ================================================================
    /**
     * @dev Register new factory to registry
     * @notice msg.sender should be contract owner.
     * @param factory IPoVFactory, factory
     * @param author address, author who created povFactory
     * @param factoryTag uint80, factoryTag
     * @return uint256, factoryID
     */
    function _register(IPoVFactory factory, address author, uint256 cost, uint80 factoryTag) internal returns (uint256) {
        uint256 factoryID = _totalFactoryCount.current();
        _totalFactoryCount.increment();

        povFactoryMapping[factoryID] = PoVFactoryRecord({ factory: factory, factoryID: factoryID, author: author, cost: cost, status: 0x00, tag: factoryTag });

        emit Register(factoryID, author);
        return factoryID;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { ERC5192Upgradeable, ERC721Upgradeable } from "./lib/ERC5192Upgradeable.sol";
import { IERC721ReceiverUpgradeable } from "@openzeppelin-contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { RoleControlUpgradeable, AccessControlUpgradeable } from "@src-root/lib/RoleControlUpgradeable.sol";
import { CountersUpgradeable } from "@openzeppelin-contracts-upgradeable/utils/CountersUpgradeable.sol";

import { VisitedBy } from "@src-root/VisitedBy.sol";
import { PoVFactoryRegistry } from "@src-root/PoVFactoryRegistry.sol";
import { SpotResolverFactory } from "@src-root/SpotResolverFactory.sol";
import { PoVAttributeParser } from "@src-root/PoVAttributeParser.sol";
import { SpotResolver } from "@src-root/SpotResolver.sol";
import { SpotResolverFactory } from "@src-root/SpotResolverFactory.sol";
import { VisitedByTypes } from "@src-root/lib/VisitedByTypes.sol";

contract SpotRegistry is
    RoleControlUpgradeable,
    ERC5192Upgradeable,
    IERC721ReceiverUpgradeable,
    UUPSUpgradeable,
    VisitedByTypes
{
    // ================================================================
    //  usings
    // ================================================================
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using Address for address;

    // ================================================================
    //  structs
    // ================================================================

    /**
     * @dev Spot record
     * @param resolver address of resolver
     * @param spotOwner address of spot owner
     * @param isPaused is paused
     */
    struct SpotRecord {
        address resolver;
        address spotOwner;
        bool isPaused;
    }

    // total spot count
    CountersUpgradeable.Counter private _totalSpotCount;

    // ================================================================
    //  events
    // ================================================================

    event Pause(address indexed spotAddress, bool indexed paused);

    event ChangeSpotOwner(address indexed oldOwner, address indexed newOwner);

    // ================================================================
    //  variables
    // ================================================================
    VisitedBy private _visitedBy;
    PoVFactoryRegistry private _poVFactoryRegistry;
    SpotResolverFactory private _spotResolverFactory;
    PoVAttributeParser private _poVAttributeParser;

    // ================================================================
    //  mappings
    // ================================================================

    // spot address -> SpotRecord
    mapping(address => SpotRecord) private spotMapping;

    // resolver address -> is registered
    mapping(address => bool) private resolversMapping;

    // ================================================================
    //  modifiers
    // ================================================================

    modifier isRegstered(address spotAddress) {
        require(address(0) != spotMapping[spotAddress].resolver, "spot is not registerd.");
        _;
    }

    modifier isNotRegstered(address spotAddress) {
        require(address(0) == spotMapping[spotAddress].resolver, "spot is already registerd.");

        _;
    }

    modifier onlySpotOwner(address spotAddress) {
        SpotRecord memory _spotInfo = spotMapping[spotAddress];

        // Check if the spot is owned by the sender
        require(msg.sender == _spotInfo.spotOwner, "sender is not the spot owner.");
        _;
    }
    modifier onlyVisitedBy() {
        require(msg.sender == address(_visitedBy), "only visitedBy");
        _;
    }

    // ================================================================
    //  initializer
    // ================================================================
    function initialize(
        VisitedBy visitedBy,
        PoVFactoryRegistry poVFactoryRegistry,
        PoVAttributeParser poVAttributeParser,
        SpotResolverFactory spotResolverFactory
    ) public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        ERC721Upgradeable.__ERC721_init("CommunSPot", "CSP");
        _visitedBy = visitedBy;
        _poVFactoryRegistry = poVFactoryRegistry;
        _poVAttributeParser = poVAttributeParser;
        _spotResolverFactory = spotResolverFactory;
    }

    // ================================================================
    //  User functions
    // ================================================================
    /**
     * @dev total spot count
     * @return uint256, total spot count
     */
    function totalSpot() public view returns (uint256) {
        return _totalSpotCount.current();
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        address spotAddress = tokenIdToSpotAddress(tokenId);

        SpotRecord memory spotRecord = spotMapping[spotAddress];
        SpotResolver spotResolver = SpotResolver(spotRecord.resolver);

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(abi.encodePacked(spotResolver.contractURI()))
                )
            );
    }

    /**
     * @dev get resolver address
     * @notice return is 0x0 if spot is not registered.
     * @param spotAddress address, spot address provided by spot device
     * @return address, resolver address
     */
    function getResolver(address spotAddress) public view returns (address) {
        return spotMapping[spotAddress].resolver;
    }

    /**
     * @dev is spot owner address
     * @notice return is 0x0 if spot is not registered.
     * @param spotAddress address, spot address provided by spot device
     * @param owner address, owner address
     * @return bool, is owner
     */
    function isSpotOwner(address spotAddress, address owner) public view returns (bool) {
        return spotMapping[spotAddress].spotOwner == owner;
    }

    /**
     * @dev resolver is registered or not
     * @param resolverAddress address, resolver address
     * @return bool, is registered
     */
    function isResolver(address resolverAddress) public view returns (bool) {
        return resolversMapping[resolverAddress];
    }

    /**
     * @dev get spot pause/unpaused status
     * @notice return is false if spot is not registered.
     * @param spotAddress address, spot address provided by spot device
     */
    function isPaused(address spotAddress) public view returns (bool) {
        return spotMapping[spotAddress].isPaused;
    }

    // ================================================================
    //  VisitedBy functions
    // ================================================================
    /**
     * @dev Register new spot to registry
     * @notice msg.sender should be contract owner.
     * @param spotOwner address, spot owner address( who is the owner of spot device )
     * @param spotAddress address, spot address provided by spot device
     * @param spotInfo SpotInfo, spot info
     */
    function register(
        address spotOwner,
        address spotAddress,
        SpotInfo memory spotInfo
    ) public isNotRegstered(spotAddress) onlyVisitedBy returns (address) {
        address _spotOwner = spotOwner;
        if (_spotOwner == address(0)) {
            _spotOwner = msg.sender;
        }

        address spotResolverAddress = _spotResolverFactory.createNewSpotResolver(
            msg.sender,
            _spotOwner,
            spotAddress,
            spotInfo
        );
        SpotResolver spotResolver = SpotResolver(spotResolverAddress);

        _register(_spotOwner, spotAddress, spotResolverAddress);

        return spotResolverAddress;
    }

    /**
     * @dev Register new spot to registry for Custom Resolver
     * @notice msg.sender should be contract owner.
     * @param spotOwner address, spot owner address( who is the owner of spot device )
     * @param spotAddress address, spot address provided by spot device
     * @param spotResolver address, spot resolver address
     */
    function register(
        address spotOwner,
        address spotAddress,
        address spotResolver
    ) public isNotRegstered(spotAddress) onlyVisitedBy {
        if (Address.isContract(spotResolver) == false) revert("Invalid address");
        address _spotOwner = spotOwner;
        if (_spotOwner == address(0)) {
            _spotOwner = msg.sender;
        }
        _register(_spotOwner, spotAddress, spotResolver);
    }

    // ================================================================
    //  Owner functions
    // ================================================================
    /**
     * @dev pause spot
     * @notice msg.sender should be contract owner.
     * @param spotAddress address, spot address provided by spot device
     */
    function pauseMint(address spotAddress) public isRegstered(spotAddress) onlyAdmin {
        spotMapping[spotAddress].isPaused = true;

        emit Pause(spotAddress, true);
    }

    /**
     * @dev unpause spot
     * @notice msg.sender should be contract owner.
     * @param spotAddress address, spot address provided by spot device
     */
    function unpauseMint(address spotAddress) public isRegstered(spotAddress) onlyAdmin {
        spotMapping[spotAddress].isPaused = false;

        emit Pause(spotAddress, false);
    }

    /**
     * @dev change spot owner
     * @notice msg.sender should be contract owner.
     * @param spotAddress address, spot address provided by spot device
     * @param newSpotOwner address, new spot owner address
     */
    function changeSpotOwner(address spotAddress, address newSpotOwner) public onlyAdmin {
        address _oldOwner = spotMapping[spotAddress].spotOwner;
        spotMapping[spotAddress].spotOwner = newSpotOwner;

        super._transfer(_oldOwner, newSpotOwner, spotAddressToTokenId(spotAddress));

        emit ChangeSpotOwner(_oldOwner, newSpotOwner);
    }

    /**
     * @dev change contract admin
     * @notice msg.sender should be contract admin.
     * @param admin address, new admin address
     */
    function changeContractAdministrator(address admin) public onlyAdmin {
        addAdmin(admin);
        deleteAdmin(msg.sender);

        emit ChangeContractOwner(msg.sender, admin);
    }

    // ================================================================
    //  override functions
    // ================================================================
    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyAdmin {}

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC5192Upgradeable, AccessControlUpgradeable) returns (bool) {
        return
            super.supportsInterface(interfaceId) ||
            interfaceId == type(IERC721ReceiverUpgradeable).interfaceId;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    // ================================================================
    //  internal functions
    // ================================================================
    /**
     * @dev Register new spot to registry
     * @notice msg.sender should be contract owner.
     * @param spotOwner address, spot owner address( who is the owner of spot device )
     * @param spotAddress address, spot address provided by spot device
     * @param resolverAddress address, resolver address
     */
    function _register(address spotOwner, address spotAddress, address resolverAddress) internal {
        uint256 tokenId = spotAddressToTokenId(spotAddress);
        super._mint(spotOwner, tokenId);
        spotMapping[spotAddress] = SpotRecord({
            resolver: resolverAddress,
            spotOwner: spotOwner,
            isPaused: false
        });
        resolversMapping[resolverAddress] = true;
        _totalSpotCount.increment();
    }

    /**
     * @dev Unregister spot from registry
     * @notice msg.sender should be contract owner.
     * @param spotAddress address, spot address provided by spot device
     */
    function _unregister(address spotAddress) internal {
        uint256 tokenId = spotAddressToTokenId(spotAddress);
        super._burn(tokenId);
        SpotRecord memory spotRecord = spotMapping[spotAddress];
        resolversMapping[spotRecord.resolver] = false;
        _totalSpotCount.decrement();
    }

    /**
     * @dev convert spot address to token id
     * @param spotAddress address, spot address provided by spot device
     * @return uint256, token id
     */
    function spotAddressToTokenId(address spotAddress) public pure returns (uint256) {
        return uint256(uint160(spotAddress));
    }

    /**
     * @dev convert token id to spot address
     * @param tokenId uint256, token id
     * @return address, spot address
     */
    function tokenIdToSpotAddress(uint256 tokenId) public pure returns (address) {
        return address(uint160(tokenId));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";

import { VisitedByTypes } from "@src-root/lib/VisitedByTypes.sol";
import { PoV } from "@src-root/lib/PoV.sol";
import { PoVFactoryRegistry } from "@src-root/PoVFactoryRegistry.sol";
import { VisitedBy } from "@src-root/VisitedBy.sol";
import { RoleControl } from "@src-root/lib/RoleControl.sol";
import { PoVAttributeParser } from "@src-root/PoVAttributeParser.sol";

contract SpotResolver is RoleControl, VisitedByTypes {
    // ================================================================
    //  usings
    // ================================================================
    using Counters for Counters.Counter;
    using Strings for uint256;
    using Address for address;

    // ================================================================
    //  events
    // ================================================================

    event Pause(uint256 indexed povId, bool status);

    event MetadataUpdate(uint256 _tokenId);

    event ChangeExperience(address indexed visitor, uint256 experience);

    // ================================================================
    //  variables
    // ================================================================

    /// spot address
    address private _spotAddress;

    // Contract address
    // To restrict minting function to this address
    address private _spotOwner;

    // Contract address
    // To restrict minting function to this address
    VisitedBy private _visitedBy;

    /// count of pov
    Counters.Counter private _povCount;

    /// latitude and longitude precision
    int64 public constant POSITION_PRECISION = 100000000;

    /// invalid latitude and longitude
    int64 public constant INVALID_POSITION = 100000000000;

    SpotInfo private _spotInfo;

    PoVFactoryRegistry private _poVFactoryRegistry;

    PoVAttributeParser private _poVAttributeParser;

    bytes32 public constant SPOT_FORWARDER_ROLE = keccak256("SPOT_FORWARDER_ROLE");

    // ================================================================
    //  mappings
    // ================================================================

    /// pov mapping
    mapping(uint16 => address) private _povAddressOf;

    /// paused mapping
    mapping(uint16 => bool) private _pausedStatusOf;

    // visitor address to experience of spot
    mapping(address => uint256) private _spotExperienceOf;

    // ================================================================
    //  modifiers
    // ================================================================
    modifier onlyAdminOrSpotOwner() {
        require(_spotOwner == msg.sender || isAdmin(msg.sender), "SpotResolver: only admin or spot owner");
        _;
    }

    modifier onlySpotOwner() {
        require(_spotOwner == msg.sender, "SpotResolver: only spot owner");
        _;
    }

    modifier onlyVisitedByContract() {
        require(address(_visitedBy) == msg.sender, "SpotResolver: only visitedBy");
        _;
    }

    // ================================================================
    //  constructors
    // ================================================================

    /**
     * @dev constructor
     * @notice create special PoV contract for each spot
     * @param admin address,  address of admin
     * @param spotOwner address,  address of spot owner
     * @param spotAddress address,  address of spot
     * @param visitedBy address,  address of visitedBy contract
     * @param poVFactoryRegistry address,  address of PoVFactoryRegistry contract
     * @param poVAttributeParser address,  address of PoVAttributeParser contract
     * @param spotInfo SpotInfo,  spot info
     */
    constructor(address admin, address spotOwner, address spotAddress, VisitedBy visitedBy, PoVFactoryRegistry poVFactoryRegistry, PoVAttributeParser poVAttributeParser, SpotInfo memory spotInfo) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _spotOwner = spotOwner;
        _spotAddress = spotAddress;
        _visitedBy = visitedBy;
        _poVFactoryRegistry = poVFactoryRegistry;
        _poVAttributeParser = poVAttributeParser;

        _spotInfo = spotInfo;

        address _povAddress = _poVFactoryRegistry.createNewPoV(
            0,
            _spotOwner,
            address(this),
            PoVInfo({
                name: "",
                description: "",
                imageUrl: "",
                website: "",
                provider: spotInfo.provider,
                latitude: INVALID_POSITION,
                longitude: INVALID_POSITION,
                start: 0,
                end: 0,
                baseURI: "",
                tag1: "",
                tag2: "",
                tag3: ""
            }),
            ""
        );
        if (address(0) == _povAddress) revert("failure create PoV contract");

        _addCustomPoV(_povAddress);
    }

    // ================================================================
    //  User functions
    // ================================================================
    /**
     * @dev get PoV address
     * @notice return is 0x0 if PoV is not added.
     * @param attribute uint16, PoV attribute
     * @return SpotAttribute memory, spot attribute
     */
    function parsePoVAttribute(uint16 attribute) public view returns (SpotAttribute memory) {
        return _poVAttributeParser.parse(attribute);
    }

    /**
     * @dev get PoV address
     * @notice return is 0x0 if PoV is not added.
     * @param povId uint16, PoV id
     * @return address, PoV address
     */
    function getPovAddress(uint16 povId) public view returns (address) {
        return _povAddressOf[povId];
    }

    /**
     * @dev get experience of spot
     * @notice return is 0x0 if PoV is not added.
     * @param visitor address, caller of this function
     * @return uint256, spot experience
     */
    function spotExperienceOf(address visitor) public view returns (uint256) {
        return _spotExperienceOf[visitor];
    }

    /**
     * @dev Returns Total PoVs
     * @return PoV Count uint16, total PoV count
     */
    function getTotalPoV() public view returns (uint16) {
        return uint16(_povCount.current());
    }

    /**
     * @dev Returns spot owner address
     * @return spotOwner address, spot owner address
     */
    function spotOwnerOf() public view returns (address) {
        return _spotOwner;
    }

    /**
     * @dev Returns spot address
     * @return spotAddress address, spot address
     */
    function spotAddressOf() public view returns (address) {
        return _spotAddress;
    }

    /**
     * @dev Returns the spot metadata
     * @return metadata string, metadata of spot
     */
    function contractURI() public view returns (string memory) {
        bytes memory spotMetadata1 = abi.encodePacked(
            '{"name":"',
            string(abi.encodePacked(_spotInfo.name)),
            '",',
            '"description":"',
            string(abi.encodePacked(_spotInfo.description)),
            '",',
            '"image":"',
            string(abi.encodePacked(_spotInfo.imageUrl)),
            '",'
        );
        bytes memory spotMetadata2 = abi.encodePacked(
            '"external_link":"',
            string(abi.encodePacked(_spotInfo.website)),
            '",',
            '"provider":"',
            string(abi.encodePacked(_spotInfo.provider)),
            '",',
            '"baseURI":"',
            string(abi.encodePacked(_spotInfo.baseURI)),
            '",'
        );
        bytes memory spotMetadata3 = abi.encodePacked('"seller_fee_basis_points":0,', '"fee_recipient":"', Strings.toHexString(uint160(_spotOwner), 20), '",');

        // ===============================================================================
        // Attributes
        // ===============================================================================
        bytes memory _attributeStart = abi.encodePacked(
            '"attributes":[{"trait_type":"provider","value":"',
            string(abi.encodePacked(_spotInfo.provider)),
            '"},{"trait_type":"spot","value":"',
            Strings.toHexString(uint160(_spotAddress), 20),
            '"},'
        );
        bytes memory _attributeTag = abi.encodePacked(
            '{"trait_type":"userTag1","value":"',
            _spotInfo.tag1,
            '"},{"trait_type":"userTag2","value":"',
            _spotInfo.tag2,
            '"},{"trait_type":"userTag3","value":"',
            _spotInfo.tag3,
            '"}]}'
        );

        return string(abi.encodePacked(spotMetadata1, spotMetadata2, spotMetadata3, _attributeStart, _attributeTag));
    }

    /**
     * @dev Returns the paused status of PoV
     * @param povId uint16, PoV id
     * @return paused status of PoV
     */
    function getPaused(uint16 povId) public view returns (bool) {
        return _pausedStatusOf[povId];
    }

    function getTagAsReadable(uint80 tag) public view returns (bytes16[6] memory) {
        return _poVFactoryRegistry.tagAsReadable(tag);
    }

    // ================================================================
    //  visited contract functions
    // ================================================================
    /**
     * @dev mint new PoV with povId
     * @notice msg.sender should be visited contract.
     * @param to address, minter address
     * @param tokenId uint256, PoV token id
     * @param extended bytes32, extended data
     * @param userData bytes, user data
     */
    function mint(address to, uint256 tokenId, bytes32 extended, bytes32 userData) public onlyVisitedByContract returns (address) {
        // povId : 0xVVVV............................................................
        uint16 povId = uint16(bytes2(extended));

        if (address(0) == _povAddressOf[povId]) revert("Not available PoV ID");
        if (_pausedStatusOf[povId]) revert("PoV is paused");

        PoV pov = PoV(_povAddressOf[povId]);
        pov.mint(to, tokenId, extended, userData);

        _spotExperienceOf[to]++;
        emit ChangeExperience(to, _spotExperienceOf[to]);

        return _povAddressOf[povId];
    }

    // ================================================================
    //  visitedBy functions
    // ================================================================
    /**
     * @dev Add new pov
     * @notice msg.sender should be spot owner or admin.
     * @param povFactoryID uint256, PoV factory ID
     * @param povInfo PoVInfo, PoV info
     * @param extraParam bytes, extra param(used for factory awesome feature ;')
     * @return uint256, PoV id
     */
    function add(uint256 povFactoryID, PoVInfo memory povInfo, bytes calldata extraParam) public onlyVisitedByContract returns (uint16) {
        return _add(povFactoryID, povInfo, extraParam);
    }

    /**
     * @dev Burn PoV token
     * @notice msg.sender should be spot owner or admin.
     * @param povId uint16, PoV id
     * @param tokenId uint256, PoV token id
     */
    function burn(uint16 povId, uint256 tokenId) public onlyVisitedByContract {
        if (address(0) == _povAddressOf[povId]) revert("Not available PoV ID");

        PoV pov = PoV(_povAddressOf[povId]);
        pov.burn(tokenId);
    }

    /**
     * @dev set Spot info
     * @notice msg.sender should be spot owner or admin.
     * @param spotInfo SpotInfo, spot Info
     */
    function setSpotInfo(SpotInfo memory spotInfo) public onlyVisitedByContract {
        _spotInfo = spotInfo;
        emit MetadataUpdate(uint256(uint160(_spotAddress)));
    }

    /**
     * @dev set Spot info
     * @notice msg.sender should be spot owner or admin.
     * @param povId uint16, PoV id
     * @param poVInfo PoVInfo, pov Info
     */
    function setPoVInfo(uint16 povId, PoVInfo memory poVInfo) public onlyVisitedByContract {
        PoV pov = PoV(_povAddressOf[povId]);
        pov.setPoVInfo(poVInfo);
    }

    // ================================================================
    //  admin or spot owner functions
    // ================================================================
    /**
     * @dev set complaint for the visitor
     * @notice msg.sender should be spot owner or admin.
     * @param visitor address, visitor address
     */
    function setComplaint(address visitor) public onlyAdminOrSpotOwner {
        if (0 == _spotExperienceOf[visitor]) revert("Not visited yet");

        _visitedBy.setComplaint(msg.sender, visitor);
    }

    // ================================================================
    //  spot owner functions
    // ================================================================

    /**
     * @dev clear experience of visitor
     * @notice msg.sender should be contract owner.
     * @param visitor address, visitor address
     */
    function clearExperience(address visitor) public onlySpotOwner {
        _clearExperience(visitor);
    }

    /**
     * @dev set paused status of PoV
     * @notice msg.sender should be contract owner.
     * @param povId uint16, PoV id
     * @param status bool, paused status
     */
    function setPaused(uint16 povId, bool status) public onlySpotOwner {
        _pausedStatusOf[povId] = status;
        emit Pause(povId, status);
    }

    /**
     * @dev change spot owner
     * @notice msg.sender should be contract owner.
     * @param newSpotOwner address, new spot owner address
     */
    function changeSpotOwner(address newSpotOwner) public onlySpotOwner {
        _spotOwner = newSpotOwner;
    }

    // ================================================================
    //  admin functions
    // ================================================================

    /**
     * @dev Add new pov for custom PoV contract
     * @notice msg.sender should be spot owner or admin.
     * @param povAddress address, address of pov
     */
    function addCustomPoV(address povAddress) public onlyAdmin returns (uint16) {
        return _addCustomPoV(povAddress);
    }

    /**
     * @dev Sets the contract address to allow it to mint token
     * @param resolver address, resolver contract address
     */
    function setResolver(address resolver) external onlyAdmin {
        for (uint16 i = 0; i < _povCount.current(); i++) {
            PoV pov = PoV(_povAddressOf[i]);
            pov.setResolver(resolver);
        }
    }

    /**
     * @dev change contract admin
     * @notice msg.sender should be contract admin.
     * @param admin address, new admin address
     */
    function changeContractAdministrator(address admin) public onlyAdmin {
        addAdmin(admin);
        deleteAdmin(msg.sender);

        emit ChangeContractOwner(msg.sender, admin);
    }

    // ================================================================
    //  internal functions
    // ================================================================
    /**
     * @dev Add new pov(internal)
     * @param povFactoryID uint256, PoV factory id
     * @param povInfo PoVInfo, PoV info
     * @param extraParam bytes, extra param(used for factory awesome feature ;')
     * @return povId uint16, PoV id
     */
    function _add(uint256 povFactoryID, PoVInfo memory povInfo, bytes calldata extraParam) internal returns (uint16) {
        if (false == _poVFactoryRegistry.isRegistered(povFactoryID)) revert("Not available PoV factory ID");

        if (65535 <= _povCount.current()) revert("PoV count is over");
        uint16 povId = uint16(_povCount.current());
        _povCount.increment();
        if (address(0) != _povAddressOf[povId]) revert("Already added PoV ID");

        address _povAddress = _poVFactoryRegistry.createNewPoV(povFactoryID, _spotOwner, address(this), povInfo, extraParam);
        if (address(0) == _povAddress) revert("failure create PoV contract");

        _povAddressOf[povId] = _povAddress;

        return povId;
    }

    /**
     * @dev Add new pov for custom PoV contract (internal)
     * @notice msg.sender should be spot owner or admin.
     * @param povAddress address, address of pov
     * @return povId uint256, PoV id
     */
    function _addCustomPoV(address povAddress) internal returns (uint16) {
        if (65535 <= _povCount.current()) revert("PoV count is over");
        uint16 povId = uint16(_povCount.current());
        _povCount.increment();

        if (address(0) != _povAddressOf[povId]) revert("Already added PoV ID");
        if (address(0) == povAddress) revert("Invalid pov address");
        if (Address.isContract(povAddress) == false) revert("Invalid pov address");

        _povAddressOf[povId] = povAddress;

        return povId;
    }

    /**
     * @dev clear experience of visitor(internal)
     * @notice msg.sender should be contract owner.
     * @param visitor address, visitor address
     */
    function _clearExperience(address visitor) internal {
        if (0 == _spotExperienceOf[visitor]) revert("visitor has no experience.");

        _spotExperienceOf[visitor] = 0;
        emit ChangeExperience(visitor, _spotExperienceOf[visitor]);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { UUPSUpgradeable } from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { VisitedBy } from "@src-root/VisitedBy.sol";
import { SpotResolver } from "@src-root/SpotResolver.sol";
import { PoVFactoryRegistry } from "@src-root/PoVFactoryRegistry.sol";
import { PoVAttributeParser } from "@src-root/PoVAttributeParser.sol";
import { VisitedByTypes } from "@src-root/lib/VisitedByTypes.sol";
import { RoleControl } from "@src-root/lib/RoleControl.sol";
import { ISpotResolverFactory } from "@src-root/lib/interface/ISpotResolverFactory.sol";

contract SpotResolverFactory is
    Initializable,
    UUPSUpgradeable,
    RoleControl,
    VisitedByTypes,
    ISpotResolverFactory
{
    VisitedBy private _visitedBy;
    PoVFactoryRegistry private _poVFactoryRegistry;
    PoVAttributeParser private _poVAttributeParser;

    function initialize(
        VisitedBy visitedBy,
        PoVFactoryRegistry poVFactoryRegistry,
        PoVAttributeParser poVAttributeParser
    ) public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _visitedBy = visitedBy;
        _poVFactoryRegistry = poVFactoryRegistry;
        _poVAttributeParser = poVAttributeParser;
    }

    // ================================================================
    //  user functions
    // ================================================================
    /**
     * @dev create new Spot resolver
     * @notice you can register Spot for your resolver.
     * @param admin address, admin address
     * @param spotOwner address, Spot owner
     * @param spotAddress address, Spot address
     * @param spotInfo SpotInfo
     * @return address, new Spot resolver address
     */
    function createNewSpotResolver(
        address admin,
        address spotOwner,
        address spotAddress,
        SpotInfo memory spotInfo
    ) external override returns (address) {
        SpotResolver spotResolver = new SpotResolver(
            admin,
            spotOwner,
            spotAddress,
            _visitedBy,
            _poVFactoryRegistry,
            _poVAttributeParser,
            spotInfo
        );
        if (address(0) == address(spotResolver)) revert("Spot5192: createNewSpot failed");
        return address(spotResolver);
    }

    function name() external pure override returns (string memory) {
        return "Spot5192";
    }

    // ================================================================
    //  override  functions
    // ================================================================
    function _authorizeUpgrade(address) internal override onlyAdmin {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { UUPSUpgradeable } from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { SpotRegistry } from "@src-root/SpotRegistry.sol";
import { SpotResolver } from "@src-root/SpotResolver.sol";
import { VisitedByTypes } from "@src-root/lib/VisitedByTypes.sol";
import { RoleControl } from "@src-root/lib/RoleControl.sol";

contract SpotVerifier is Initializable, UUPSUpgradeable, RoleControl, VisitedByTypes {
    // ================================================================
    //  variables
    // ================================================================
    address private _visitedByAddress;

    bytes7 private constant _MSG_SALT = 0x18434d4d4e1310; // "\x18CMMN\x13\x10"

    // ================================================================
    //  modifiers
    // ================================================================
    modifier onlyVisitedByContract() {
        require(_visitedByAddress == msg.sender, "Not visitedBy contract.");
        _;
    }

    // ================================================================
    //  initializer
    // ================================================================
    function initialize(address visitedByAddress) public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _visitedByAddress = visitedByAddress;
    }

    // ================================================================
    //  User functions
    // ================================================================

    /**
     * @dev verify Proof of Visit NFT
     * @notice msg.sender should be contract owner.
     * @param visitor address, visitor address
     * @param spotSignature bytes, spot signature for PoV
     * @param extended bytes32, extended data
     * @return address, spot address for PoV. If not found, return address(0).
     */
    function verify(
        address visitor,
        bytes calldata spotSignature,
        bytes32 extended
    ) public view onlyVisitedByContract returns (address) {
        return _recoverSpotAddress(visitor, spotSignature, extended);
    }

    // ================================================================
    //  internal functions
    // ================================================================

    /**
     * @dev recover spot address from signature with extended data
     * @notice msg.sender should be contract owner.
     * @param minter address, minter wallet address
     * @param signature bytes, spot signature for PoV
     * @return extended bytes32, extended data
     */
    function _recoverSpotAddress(
        address minter,
        bytes calldata signature,
        bytes32 extended
    ) internal pure returns (address) {
        return _recoverSigner(sha256(abi.encodePacked(_MSG_SALT, minter, extended)), signature);
    }

    /// _recoverSigner
    function _recoverSigner(bytes32 msgHash, bytes calldata sig) internal pure returns (address) {
        (uint8 v, bytes32 r, bytes32 s) = _splitSignature(sig);
        return ecrecover(msgHash, v, r, s);
    }

    /// _splitSignature is signature methods.
    function _splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        require(sig.length == 65, "signature length must be 65");

        /* solhint-disable no-inline-assembly */
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        /* solhint-enable no-inline-assembly */

        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28, "parameter v must be 27 or 28");

        return (v, r, s);
    }

    /**
     * @dev change contract admin
     * @notice msg.sender should be contract admin.
     * @param admin address, new admin address
     */
    function changeContractAdministrator(address admin) public onlyAdmin {
        addAdmin(admin);
        deleteAdmin(msg.sender);

        emit ChangeContractOwner(msg.sender, admin);
    }

    // ================================================================
    //  override functions
    // ================================================================
    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyAdmin {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { VSIT } from "@src-root/token/VSIT.sol";
import { VisitorRegistry } from "@src-root/gasless/VisitorRegistry.sol";
import { SpotRegistry } from "@src-root/SpotRegistry.sol";
import { SpotVerifier } from "@src-root/SpotVerifier.sol";
import { SpotResolver } from "@src-root/SpotResolver.sol";
import { PoV } from "@src-root/lib/PoV.sol";
import { VisitedByTypes } from "@src-root/lib/VisitedByTypes.sol";
import { RoleControl } from "@src-root/lib/RoleControl.sol";

contract VisitedBy is Initializable, UUPSUpgradeable, RoleControl, VisitedByTypes {
    // ================================================================
    //  events
    // ================================================================

    // visitor events
    event Visited(
        address indexed visitor,
        address indexed resolver,
        address indexed pov,
        uint256 tokenId
    );
    event ChangeExperience(address indexed visitor, uint256 experience);
    event NewComplaint(address indexed visitor, address indexed resolver);

    // spot events
    event SpotRegister(
        address indexed spotAddress,
        address indexed resolver,
        address indexed spotOwner
    );
    event SpotUnregister(
        address indexed spotAddress,
        address indexed resolver,
        address indexed spotOwner
    );
    event SpotInfoUpdate(address indexed spotAddress, address indexed resolverAddress);

    // PoV events
    event PoVAdd(address indexed spotAddress, uint256 indexed povId, address indexed povAddress);
    event PoVBurn(uint256 indexed povId, address indexed povAddress, uint256 tokenId);
    event PoVInfoUpdate(
        address indexed spotAddress,
        address indexed resolverAddress,
        uint16 indexed povId
    );

    // ================================================================
    //  mappings
    // ================================================================

    // visitor address to experience
    mapping(address => uint256) private _experienceOf;

    // visitor address to complaint array
    mapping(address => address[]) private _complaintOf;

    // ================================================================
    //  variables
    // ================================================================
    VisitorRegistry private _visitorRegistry;
    SpotRegistry private _spotRegistry;
    SpotVerifier private _spotVerifier;
    VSIT private _vsit;

    uint64 public constant SECRET_TIMESTAMP = 0x0;
    uint256 public constant SECRET_TIMESTAMP_FEE = 10 * 10 ** 18;

    uint256 public constant COMPLAIN_LIMIT = 5;

    bytes32 public constant FORWARDER_ROLE = keccak256("FORWARDER_ROLE");

    IERC721 public campaignNFT = IERC721(address(0x0));
    uint64 public campaignNFTStart = 0;
    uint64 public campaignNFTEnd = 0;

    // ================================================================
    //  modifiers
    // ================================================================
    modifier onlyForwarder() {
        if (
            (false == hasRole(FORWARDER_ROLE, msg.sender)) &&
            (false == hasRole(DEFAULT_ADMIN_ROLE, msg.sender))
        ) revert("Only forwarder");
        _;
    }

    // ================================================================
    //  initializer
    // ================================================================
    function initialize(
        address visitorRegistryAddress,
        address spotRegistryAddress,
        address spotVerifierAddress,
        address vsitAddress
    ) public initializer {
        // SETUP role Hierarchy:
        // DEFAULT_ADMIN_ROLE > FORWARDER_ROLE > no role
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setRoleAdmin(FORWARDER_ROLE, DEFAULT_ADMIN_ROLE);
        _visitorRegistry = VisitorRegistry(visitorRegistryAddress);
        _spotRegistry = SpotRegistry(spotRegistryAddress);
        _spotVerifier = SpotVerifier(spotVerifierAddress);
        _vsit = VSIT(vsitAddress);
    }

    // ================================================================
    //  User functions
    // ================================================================
    /**
     * @dev mint Proof of Visit NFT with custom extended data
     * @notice msg.sender should be contract owner.
     * @param spotSignature bytes, spot signature for PoV
     * @param extended bytes32, extended data
     * @param userData bytes, user data
     * @return resolver address, resolvers address
     */
    function mint(
        bytes calldata spotSignature,
        bytes32 extended,
        bytes32 userData
    ) public returns (address) {
        address spotAddress = _spotVerifier.verify(msg.sender, spotSignature, extended);

        return
            _mint(
                _visitorRegistry.resolve(msg.sender),
                spotAddress,
                extended,
                _tokenIdOf(spotSignature),
                userData
            );
    }

    /**
     * @dev verify Proof of Visit NFT with custom extended data
     * @param visitor address, visitor address
     * @param spotSignature bytes, spot signature for PoV
     * @param extended bytes32, extended data
     * @return resolver address, resolvers address
     */
    function verify(
        address visitor,
        bytes calldata spotSignature,
        bytes32 extended
    ) external view returns (address) {
        address spotAddress = _spotVerifier.verify(visitor, spotSignature, extended);
        address resolverAddress = _spotRegistry.getResolver(spotAddress);

        return resolverAddress;
    }

    /**
     * @dev estimate reward for Proof of Visit with custom extended data
     * @param visitor address, visitor address
     * @param spotSignature bytes, spot signature for PoV
     * @param extended bytes32, extended data
     * @return resolver address, resolvers address
     */
    function estimateReward(
        address visitor,
        bytes calldata spotSignature,
        bytes32 extended
    ) external view returns (uint256) {
        address spotAddress = _spotVerifier.verify(visitor, spotSignature, extended);
        address resolverAddress = _spotRegistry.getResolver(spotAddress);
        if (address(0x0) == resolverAddress) revert("Resolver not found");
        uint16 povId = uint16(bytes2(extended));
        address povAddress = SpotResolver(resolverAddress).getPovAddress(povId);
        if (address(0x0) == povAddress) revert("PoV not found");

        uint256 _visitedExperience = _experienceOf[visitor];
        uint256 _spotExperience = SpotResolver(resolverAddress).spotExperienceOf(visitor);
        uint256 _povExperience = PoV(povAddress).getExperience(visitor);

        return
            _calcReward(visitor, _visitedExperience + 1, _spotExperience + 1, _povExperience + 1);
    }

    /**
     * @dev Returns VSIT token contract address

     * @return vsitAddress address, Token contract address
     */
    function vsitContract() external view returns (address) {
        return address(_vsit);
    }

    /**
     * @dev Returns the experience of `account`.
     * @return PoVs array address[], address array of PoVs
     */
    function experienceOf(address visitor) external view returns (uint256) {
        return _experienceOf[visitor];
    }

    /**
     * @dev Returns the complainers of `account`.
     * @param visitor address, visitor address
     * @return complainers count array address[], complainers count array of PoV
     */
    function complaintOf(address visitor) external view returns (address[] memory) {
        return _complaintOf[visitor];
    }

    /**
     * @dev Returns the complainers of `account`.
     * @param forwarder address, forwarder address
     * @return bool, true if visitor is user wallet
     */
    function isForwarder(address forwarder) external view returns (bool) {
        return hasRole(FORWARDER_ROLE, forwarder);
    }

    // ???????????????????????????????????????????????????????????????????????
    //?  Forwarder functions
    // ???????????????????????????????????????????????????????????????????????
    // ================================================================
    //  Visitor functions
    // ================================================================
    /**
     * @dev mint Proof of Visit NFT with custom extended data
     * @notice msg.sender should be forwarder.
     * @param to address, address to mint
     * @param spotSignature bytes, spot signature for PoV
     * @param extended bytes32, extended data
     * @param userData bytes, user data
     * @return resolver address, resolvers address
     */
    function mint(
        address to,
        bytes calldata spotSignature,
        bytes32 extended,
        bytes32 userData
    ) public onlyForwarder returns (address) {
        address spotAddress = _spotVerifier.verify(to, spotSignature, extended);

        return
            _mint(
                _visitorRegistry.resolve(to),
                spotAddress,
                extended,
                _tokenIdOf(spotSignature),
                userData
            );
    }

    // ================================================================
    //  Spot Owner functions
    // ================================================================
    /**
     * @dev Add new pov
     * @notice msg.sender should be spot owner or admin.
     * @param spotAddress address, spot address
     * @param povFactoryID uint256, PoV factory ID
     * @param povInfo PoVInfo, PoV info
     * @param extraParam bytes, extra param(used for factory awesome feature ;')
     * @return uint256, PoV id
     */
    function add(
        address spotAddress,
        uint256 povFactoryID,
        PoVInfo memory povInfo,
        bytes calldata extraParam
    ) public onlyForwarder returns (uint16) {
        address resolverAddress = _spotRegistry.getResolver(spotAddress);
        if (address(0) == resolverAddress) revert("invalid spot address.");

        SpotResolver resolver = SpotResolver(resolverAddress);
        uint16 povId = resolver.add(povFactoryID, povInfo, extraParam);

        emit PoVAdd(spotAddress, povId, resolver.getPovAddress(povId));

        return povId;
    }

    /**
     * @dev set Spot info
     * @notice msg.sender should be spot owner or admin.
     * @param spotInfo SpotInfo, spot Info
     */
    function setSpotInfo(address spotAddress, SpotInfo memory spotInfo) public onlyForwarder {
        address resolverAddress = _spotRegistry.getResolver(spotAddress);
        if (address(0) == resolverAddress) revert("invalid spot address.");

        SpotResolver resolver = SpotResolver(resolverAddress);
        resolver.setSpotInfo(spotInfo);

        emit SpotInfoUpdate(spotAddress, resolverAddress);
    }

    /**
     * @dev set Spot info
     * @notice msg.sender should be spot owner or admin.
     * @param povId uint16, PoV id
     * @param poVInfo PoVInfo, pov Info
     */
    function setPoVInfo(
        address spotAddress,
        uint16 povId,
        PoVInfo memory poVInfo
    ) public onlyForwarder {
        address resolverAddress = _spotRegistry.getResolver(spotAddress);
        if (address(0) == resolverAddress) revert("invalid spot address.");

        SpotResolver resolver = SpotResolver(resolverAddress);
        resolver.setPoVInfo(povId, poVInfo);

        emit PoVInfoUpdate(spotAddress, resolverAddress, povId);
    }

    // ================================================================
    //  Owner functions
    // ================================================================
    /**
     * @dev Burn new pov
     * @notice msg.sender should be spot owner or admin.
     * @param spotAddress address, spot address
     * @param povId uint16, PoV ID
     * @param tokenId uint256, PoV token ID
     */
    function burn(address spotAddress, uint16 povId, uint256 tokenId) public onlyAdmin {
        address resolverAddress = _spotRegistry.getResolver(spotAddress);
        if (address(0) == resolverAddress) revert("invalid spot address.");

        SpotResolver resolver = SpotResolver(resolverAddress);

        address povAddress = resolver.getPovAddress(povId);
        if (address(0) == povAddress) revert("Not available PoV ID");

        _vsit.payFee(PoV(povAddress).ownerOf(tokenId), address(_vsit), 10 ether);
        resolver.burn(povId, tokenId);

        emit PoVBurn(povId, resolver.getPovAddress(povId), tokenId);
    }

    /**
     * @dev Register new spot to registry
     * @notice msg.sender should be contract owner.
     * @param spotOwner address, spot owner address( who is the owner of spot device )
     * @param spotAddress address, spot address provided by spot device
     * @param spotInfo SpotInfo, spot info
     */
    function register(
        address spotOwner,
        address spotAddress,
        SpotInfo memory spotInfo
    ) public onlyAdmin returns (address) {
        address _resolver = _spotRegistry.register(spotOwner, spotAddress, spotInfo);

        emit SpotRegister(spotAddress, _resolver, spotOwner);
        emit PoVAdd(spotAddress, 0, SpotResolver(_resolver).getPovAddress(0));
        return _resolver;
    }

    /**
     * @dev Register new spot to registry for Custom Resolver
     * @notice msg.sender should be contract owner.
     * @param spotOwner address, spot owner address( who is the owner of spot device )
     * @param spotAddress address, spot address provided by spot device
     * @param spotResolver address, spot resolver address
     */
    function register(
        address spotOwner,
        address spotAddress,
        address spotResolver
    ) public onlyAdmin {
        _spotRegistry.register(spotOwner, spotAddress, spotResolver);
        emit SpotRegister(spotAddress, spotResolver, spotOwner);
        emit PoVAdd(spotAddress, 0, SpotResolver(spotResolver).getPovAddress(0));
    }

    /**
     * @dev Add new pov for custom PoV contract
     * @notice msg.sender should be spot owner or admin.
     * @param spotAddress address, spot address provided by spot device
     * @param povAddress address, address of pov
     */
    function addCustomPoV(
        address spotAddress,
        address povAddress
    ) public onlyAdmin returns (uint16) {
        address resolverAddress = _spotRegistry.getResolver(spotAddress);
        if (address(0) == resolverAddress) revert("invalid signature or caller.");

        SpotResolver resolver = SpotResolver(resolverAddress);
        uint16 povId = resolver.addCustomPoV(povAddress);

        emit PoVAdd(spotAddress, povId, resolver.getPovAddress(povId));

        return povId;
    }

    /**
     * @dev add forwarder account wallet
     * @notice msg.sender should be contract owner.
     * @param forwarder address, visitor address
     */
    function addForwarder(address forwarder) public onlyAdmin {
        grantRole(FORWARDER_ROLE, forwarder);
    }

    /**
     * @dev delete forwarder account wallet
     * @notice msg.sender should be contract owner.
     * @param forwarder address, visitor address
     */
    function deleteForwarder(address forwarder) public onlyAdmin {
        revokeRole(FORWARDER_ROLE, forwarder);
    }

    /**
     * @dev clear experience of visitor
     * @notice msg.sender should be contract owner.
     * @param visitor address, visitor address
     */
    function clearExperience(address visitor) public onlyAdmin {
        _clearExperience(visitor);
    }

    /**
     * @dev add contract admin
     * @notice msg.sender should be contract admin.
     * @param admin address, new admin address
     */
    function addAdministrator(address admin) public onlyAdmin {
        addAdmin(admin);
    }

    /**
     * @dev delete contract admin
     * @notice msg.sender should be contract admin.
     * @param admin address, delete admin address
     */
    function deleteAdministrator(address admin) public onlyAdmin {
        deleteAdmin(admin);
    }

    /**
     * @dev set campaign NFT
     * @notice msg.sender should be contract admin.
     * @param nft IERC721, campaign NFT contract
     * @param start uint64, campaign start time
     * @param end uint64, campaign end time
     */
    function setCampaignNFT(IERC721 nft, uint64 start, uint64 end) external onlyAdmin {
        if (nft.supportsInterface(0x80ac58cd) == false) revert("not support ERC721 interface.");

        campaignNFT = nft;
        campaignNFTStart = start;
        campaignNFTEnd = end;
    }

    // ================================================================
    //  Resolver functions
    // ================================================================
    /**
     * @dev Returns the complainers of `account`.
     * @param complainant address, complainant address
     * @param visitor address, visitor address
     */
    function setComplaint(address complainant, address visitor) external {
        if (false == _spotRegistry.isResolver(msg.sender)) revert("is not Resolver.");

        for (uint256 i = 0; i < _complaintOf[visitor].length; i++) {
            if (_complaintOf[visitor][i] == complainant) revert("already complaint.");
        }
        _complaintOf[visitor].push(complainant);
        if (_complaintOf[visitor].length >= COMPLAIN_LIMIT) {
            // deprivation experience of `visitor`
            delete _complaintOf[visitor];

            // burn VSIT
            _vsit.payFee(visitor, address(_vsit), _vsit.balanceOf(visitor));
        }

        emit NewComplaint(visitor, msg.sender);
    }

    // ================================================================
    //  override functions
    // ================================================================
    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyAdmin {}

    // ================================================================
    //  internal functions
    // ================================================================

    /**
     * @dev mint (internal)
     * @param spotAddress address, spot address(from SpotVerifier)
     * @param to address, receiver address
     * @param extended bytes32, extended data
     * @param tokenId uint256, PoV token id
     * @param userData bytes, user data
     * @return resolver address, resolvers address
     */
    function _mint(
        address to,
        address spotAddress,
        bytes32 extended,
        uint256 tokenId,
        bytes32 userData
    ) internal returns (address) {
        if (SECRET_TIMESTAMP == uint64(uint80(bytes10(extended)) & 0xFFFFFFFFFFFFFFFF)) {
            // timestamp is secret
            if (_vsit.balanceOf(to) < SECRET_TIMESTAMP_FEE) revert("not enough VSIT.");
            _vsit.payFee(to, address(_vsit), SECRET_TIMESTAMP_FEE);
        }
        address resolverAddress = _spotRegistry.getResolver(spotAddress);
        if (address(0) == resolverAddress) revert("invalid signature or caller.");
        if (_spotRegistry.isPaused(spotAddress)) revert("spot is paused.");

        SpotResolver resolver = SpotResolver(resolverAddress);
        address _pov = resolver.mint(to, tokenId, extended, userData);

        emit Visited(to, resolverAddress, _pov, tokenId);

        _distributeRewards(to, resolverAddress, _pov);

        return resolverAddress;
    }

    function _distributeRewards(address to, address resolverAddress, address povAddress) internal {
        // exchange reward
        _experienceOf[to] += 1;

        SpotResolver resolver = SpotResolver(resolverAddress);
        PoV pov = PoV(povAddress);
        uint256 _visitedExperience = _experienceOf[to];
        uint256 _spotExperience = resolver.spotExperienceOf(to);
        uint256 _povExperience = pov.getExperience(to);

        uint256 _reward = _calcReward(to, _visitedExperience, _spotExperience, _povExperience);

        // mint VSIT
        if (0 != _reward) _vsit.mint(to, _reward);

        emit ChangeExperience(to, _experienceOf[to]);
    }

    function _calcReward(
        address to,
        uint256 visitedExperience,
        uint256 spotExperience,
        uint256 povExperience
    ) internal view returns (uint256) {
        uint256 reward = 0;

        if (visitedExperience < 10) {
            // reward of first visit
            if (0 != visitedExperience) {
                reward = reward + (10 ** 18 / visitedExperience); // max 2.93 ether
            }
        }
        if (spotExperience < 10) {
            // reward of first visit spot
            if (0 != spotExperience) {
                reward = reward + (10 ** 18 / spotExperience); // max 2.93 ether
            }
        }
        if (povExperience < 10) {
            // reward of first visit PoV
            if (0 != povExperience) {
                reward = reward + (10 ** 18 / povExperience); // max 2.93 ether
            }
        }
        if (0 == reward) {
            // reward of luck
            reward = 1000000000; // 1 gwei
        }

        if (address(campaignNFT) != address(0)) {
            if (campaignNFT.balanceOf(to) > 0) {
                if (
                    campaignNFTStart <= uint64(block.timestamp) &&
                    uint64(block.timestamp) <= campaignNFTEnd
                ) {
                    // reward of campaign 3x
                    reward = reward * 3; // max 26.36 ether
                }
            }
        }

        return reward;
    }

    /**
     * @dev mint (internal)
     * @param spotSignature bytes calldata, spot signature from Spot device(as random k value)
     * @return tokenId uint256, PoV token id
     */
    function _tokenIdOf(bytes calldata spotSignature) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(spotSignature)));
    }

    /**
     * @dev clear experience of visitor(internal)
     * @notice msg.sender should be contract owner.
     * @param visitor address, visitor address
     */
    function _clearExperience(address visitor) internal {
        _experienceOf[visitor] = 0;

        emit ChangeExperience(visitor, 0);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import { VisitedBy } from "@src-root/VisitedBy.sol";
import { VisitedByTypes } from "@src-root/lib/VisitedByTypes.sol";

contract VisitedByMinter is VisitedByTypes {
    string public constant name = "xyz.commun.VisitedByMinter";
    bytes32 internal DOMAIN_SEPARATOR;
    address private _visitedBy;

    uint256 private constant MAX_BATCH_SIZE = 100;

    mapping(address => uint256) public nonces;

    constructor(address visitedBy) {
        uint256 chainId;
        /* solhint-disable no-inline-assembly */
        assembly {
            chainId := chainid()
        }
        /* solhint-enable no-inline-assembly */
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(0x0000000000000000000000000000000000000000)
            )
        );
        _visitedBy = visitedBy;
    }

    // keccak256("mint(address,bytes32,bytes32,uint8,bytes32,bytes32,uint256,uint256)")
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("MintPermit(address,bytes32,bytes32,uint8,bytes32,bytes32,uint256,uint256)");

    // computes the hash of a permit
    function getStructHash(MintPermit memory _permit) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    PERMIT_TYPEHASH,
                    _permit.visitor,
                    _permit.spotSignatureR,
                    _permit.spotSignatureS,
                    _permit.spotSignatureV,
                    _permit.extended,
                    _permit.userData,
                    _permit.nonce,
                    _permit.deadline
                )
            );
    }

    // computes the hash of the fully encoded EIP-712 message for the domain, which can be used to recover the signer
    function getTypedDataHash(MintPermit memory _permit) public view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, getStructHash(_permit)));
    }

    function execute(
        MintPermit memory _permit,
        uint8 visitorV,
        bytes32 visitorR,
        bytes32 visitorS
    ) public returns (address) {
        if (_permit.deadline < block.timestamp) revert("mint: expired");
        if (_permit.nonce != nonces[_permit.visitor]) revert("mint: invalid nonce");
        if (_permit.visitor != ecrecover(getTypedDataHash(_permit), visitorV, visitorR, visitorS))
            revert("mint: invalid signature");
        nonces[_permit.visitor] = _permit.nonce + 1;

        // execute mint
        return
            VisitedBy(_visitedBy).mint(
                _permit.visitor,
                abi.encodePacked(
                    _permit.spotSignatureR,
                    _permit.spotSignatureS,
                    _permit.spotSignatureV
                ),
                _permit.extended,
                _permit.userData
            );
    }

    function batchExecute(
        MintRequest[] memory _requests
    ) public returns (address[] memory _addresses) {
        if (MAX_BATCH_SIZE < _requests.length) revert("batchExecute: too many requests");
        _addresses = new address[](_requests.length);
        for (uint256 i = 0; i < _requests.length; i++) {
            _addresses[i] = execute(
                _requests[i].permit,
                _requests[i].visitorV,
                _requests[i].visitorR,
                _requests[i].visitorS
            );
        }
    }

    function getNonce(address _visitor) public view returns (uint256) {
        return nonces[_visitor];
    }

    function getBatchNonce(
        address[] memory _visitors
    ) public view returns (uint256[] memory _nonces) {
        if (MAX_BATCH_SIZE < _visitors.length) revert("getBatchNonce: too many requests");
        _nonces = new uint256[](_visitors.length);
        for (uint256 i = 0; i < _visitors.length; i++) {
            _nonces[i] = nonces[_visitors[i]];
        }
    }

    function getVisitedBy() public view returns (address) {
        return _visitedBy;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import { VisitedBy } from "@src-root/VisitedBy.sol";
import { VisitedByTypes } from "@src-root/lib/VisitedByTypes.sol";

contract VisitorRegistry is VisitedByTypes {
    string public constant name = "xyz.commun.VisitorRegistry";

    bytes32 internal DOMAIN_SEPARATOR;

    uint256 private constant MAX_BATCH_SIZE = 100;

    mapping(address => uint256) public nonces;

    mapping(address => address) private resolver;

    constructor() {
        uint256 chainId;
        /* solhint-disable no-inline-assembly */
        assembly {
            chainId := chainid()
        }
        /* solhint-enable no-inline-assembly */
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(0x0000000000000000000000000000000000000000)
            )
        );
    }

    // keccak256("register(address,address,uint256,uint256)")
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256(
            "VisitorRegisterPermit(address visitor,address owner,uint256 nonce,uint256 deadline)"
        );

    // computes the hash of a permit
    function getStructHash(VisitorRegisterPermit memory _permit) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    PERMIT_TYPEHASH,
                    _permit.visitor,
                    _permit.owner,
                    _permit.nonce,
                    _permit.deadline
                )
            );
    }

    // computes the hash of the fully encoded EIP-712 message for the domain, which can be used to recover the signer
    function getTypedDataHash(VisitorRegisterPermit memory _permit) public view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, getStructHash(_permit)));
    }

    function register(
        VisitorRegisterPermit memory _permit,
        uint8 visitorV,
        bytes32 visitorR,
        bytes32 visitorS,
        uint8 ownerV,
        bytes32 ownerR,
        bytes32 ownerS
    ) public {
        if (resolver[_permit.visitor] != address(0)) revert("register: already registered");
        if (_permit.deadline < block.timestamp) revert("register: expired");
        if (_permit.nonce != nonces[_permit.visitor]) revert("register: invalid nonce");
        if (_permit.visitor != ecrecover(getTypedDataHash(_permit), visitorV, visitorR, visitorS))
            revert("register: invalid visitor signature");
        if (_permit.owner != ecrecover(getTypedDataHash(_permit), ownerV, ownerR, ownerS))
            revert("register: invalid owner signature");
        nonces[_permit.visitor] = _permit.nonce + 1;

        resolver[_permit.visitor] = _permit.owner;
    }

    function batchRegister(VisitorRegisterRequest[] memory _requests) public {
        if (MAX_BATCH_SIZE < _requests.length) revert("batchRegister: too many requests");
        for (uint256 i = 0; i < _requests.length; i++) {
            register(
                _requests[i].permit,
                _requests[i].visitorV,
                _requests[i].visitorR,
                _requests[i].visitorS,
                _requests[i].ownerV,
                _requests[i].ownerR,
                _requests[i].ownerS
            );
        }
    }

    function resolve(address _visitor) public view returns (address) {
        address owner = resolver[_visitor];
        if (owner == address(0)) return _visitor;
        return owner;
    }

    function batchResolve(address[] memory _visitors) public view returns (address[] memory) {
        if (MAX_BATCH_SIZE < _visitors.length) revert("batchRegister: too many requests");
        address[] memory owners = new address[](_visitors.length);
        for (uint256 i = 0; i < _visitors.length; i++) {
            owners[i] = resolve(_visitors[i]);
        }
        return owners;
    }

    function getNonce(address _visitor) public view returns (uint256) {
        return nonces[_visitor];
    }

    function batchGetNonce(address[] memory _visitors) public view returns (uint256[] memory) {
        if (MAX_BATCH_SIZE < _visitors.length) revert("batchRegister: too many requests");
        uint256[] memory nonces_ = new uint256[](_visitors.length);
        for (uint256 i = 0; i < _visitors.length; i++) {
            nonces_[i] = getNonce(_visitors[i]);
        }
        return nonces_;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { ERC721Upgradeable } from "@openzeppelin-contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

import { IERC5192Upgradeable, IERC165Upgradeable } from "@src-root/lib/interface/IERC5192Upgradeable.sol";

contract ERC5192Upgradeable is ERC721Upgradeable, IERC5192Upgradeable {
    // ================================================================
    //  mappings
    // ================================================================
    /// lock mapping
    mapping(uint256 => bool) private _lockStatus;

    // ================================================================
    //  user functions
    // ================================================================

    /**
     * @dev Returns locked token
     * @param tokenId uint256, token id
     */
    function locked(uint256 tokenId) external view override returns (bool) {
        return _lockStatus[tokenId];
    }

    // ================================================================
    //  override functions
    // ================================================================
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC5192Upgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    // ================================================================
    //  prohibited functions
    // ================================================================

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address, uint256) public virtual override {
        require(msg.sender == address(0), "ERC5192: Not transferable.");
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256) public view virtual override returns (address) {
        require(msg.sender == address(0), "ERC5192: Not transferable.");

        return address(0);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address, bool) public virtual override {
        require(msg.sender == address(0), "ERC5192: Not transferable.");
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address, address) public view virtual override returns (bool) {
        require(msg.sender == address(0), "ERC5192: Not transferable.");

        return false;
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address,
        address,
        uint256
    ) public virtual override {
        require(msg.sender == address(0), "ERC5192: Not transferable.");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address,
        address,
        uint256
    ) public virtual override {
        require(msg.sender == address(0), "ERC5192: Not transferable.");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override {
        require(msg.sender == address(0), "ERC5192: Not transferable.");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import { IPoV } from "@src-root/lib/interface/IPoV.sol";
import { SpotResolver } from "@src-root/SpotResolver.sol";

abstract contract PoV is ERC721, IERC721Receiver, IPoV, Ownable {
    // ================================================================
    //  usings
    // ================================================================
    using Counters for Counters.Counter;
    using Strings for uint256;

    // ================================================================
    //  events
    // ================================================================
    /// Emitted when metadata is updated
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    // ================================================================
    //  variables
    // ================================================================
    /// PoV - Info
    PoVInfo internal _povInfo;

    /// IERC721Metadata - name
    string private _name;

    /// IERC721Metadata - symbol
    string private _symbol;

    uint80 _tag;

    /// Contract address
    /// To restrict minting function to this address
    address private _resolverContractAddress;

    // total supply count
    Counters.Counter public totalSupply;

    /// latitude and longitude precision
    int256 public constant POSITION_PRECISION = 100000000;

    // ================================================================
    //  mappings
    // ================================================================

    /// PoV - userdata
    mapping(uint256 => bytes32) private _userData;

    /// PoV - extended
    mapping(uint256 => bytes32) private _extended;

    /// PoV - experience
    mapping(address => uint256) private _experience;

    // ================================================================
    //  modifiers
    // ================================================================

    modifier onlyFromResolverContract() {
        require(_resolverContractAddress == msg.sender, "PoV: only from resolver contract");
        _;
    }

    // ================================================================
    //  constructors
    // ================================================================

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     * @notice should be called from child contract
     * @param resolverContractAddress address, resolver contract address
     */
    function _povInit(
        address spotOwner,
        address resolverContractAddress,
        PoVInfo memory povInfo,
        uint80 tag
    ) internal virtual {
        _transferOwnership(spotOwner);
        _povInfo = povInfo;
        _name = string(abi.encodePacked(_povInfo.name, " - ", _povInfo.provider));
        _symbol = _initialSymbol();
        _resolverContractAddress = resolverContractAddress;
        _tag = tag;
    }

    // ================================================================
    //  resolver functions
    // ================================================================
    function mint(
        address to,
        uint256 tokenId,
        bytes32 extended,
        bytes32 userData
    ) public virtual override onlyFromResolverContract {
        _mint(to, tokenId, extended, userData);
        totalSupply.increment();
    }

    function burn(uint256 tokenId) public virtual override onlyFromResolverContract {
        _burn(tokenId);
        totalSupply.decrement();
    }

    /**
     * @dev Sets the contract address to allow it to mint token
     * @param resolver address, resolver contract address
     */
    function setResolver(address resolver) external onlyFromResolverContract {
        _resolverContractAddress = resolver;
    }

    /**
     * @dev set PoV info
     * @notice msg.sender should be pov owner or admin.
     * @param poVInfo PoVInfo, PoV info
     */
    function setPoVInfo(PoVInfo memory poVInfo) external onlyFromResolverContract {
        _povInfo = poVInfo;
        emit BatchMetadataUpdate(
            0x0,
            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        );
    }

    // ================================================================
    //  user functions
    // ================================================================

    /**
     * @dev See {ERC721-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (address(0) == ownerOf(tokenId)) revert("PoV: URI query for nonexistent token");

        // ===============================================================================
        // Properties
        // ===============================================================================
        // separate metadata for avoiding stack too deep error
        bytes memory _properties = abi.encodePacked(
            '{"name":"',
            string(abi.encodePacked(_povInfo.name)),
            '","description":"',
            string(abi.encodePacked(_povInfo.description)),
            '","image":"',
            string(abi.encodePacked(_povInfo.imageUrl)),
            '","external_url":"',
            string(abi.encodePacked(_povInfo.website)),
            '",'
        );
        bytes memory _extraProperties = abi.encodePacked(
            '"baseURI":"',
            string(abi.encodePacked(_povInfo.baseURI)),
            '",',
            '"userData":"',
            Strings.toHexString(uint256(getUserData(tokenId))),
            '",'
        );

        // ===============================================================================
        // Attributes
        // ===============================================================================
        bytes memory _attributeStart = abi.encodePacked(
            '"attributes":[{"trait_type":"provider","value":"',
            string(abi.encodePacked(_povInfo.provider)),
            '"},{"trait_type":"spot","value":"',
            Strings.toHexString(uint160(getResolver()), 20),
            '"},'
        );

        // ----------------------------------------
        // position
        // ----------------------------------------
        if (
            (SpotResolver(_resolverContractAddress).INVALID_POSITION() != _povInfo.latitude) &&
            (SpotResolver(_resolverContractAddress).INVALID_POSITION() != _povInfo.longitude)
        ) {
            _attributeStart = abi.encodePacked(
                _attributeStart,
                '{"display_type": "number","trait_type":"latitude","value":',
                _int2string(_povInfo.latitude),
                '},{"display_type": "number","trait_type":"longitude","value":',
                _int2string(_povInfo.longitude),
                "},"
            );
        }

        // ----------------------------------------
        // timestamp
        // ----------------------------------------
        // timestamp : 0x....VVVVVVVVVVVVVVVV............................................
        uint64 _timestamp = uint64(uint80(bytes10(getExtended(tokenId))) & 0xFFFFFFFFFFFFFFFF);
        if (0 != _timestamp) {
            _attributeStart = abi.encodePacked(
                _attributeStart,
                '{"display_type": "date","trait_type":"visitedAt","value":',
                Strings.toString(_timestamp),
                "},"
            );
        }
        if (0 != _povInfo.start) {
            _attributeStart = abi.encodePacked(
                _attributeStart,
                '{"display_type": "date","trait_type":"start","value":',
                Strings.toString(_povInfo.start),
                "},"
            );
        }
        if (0 != _povInfo.end) {
            _attributeStart = abi.encodePacked(
                _attributeStart,
                '{"display_type": "date","trait_type":"end","value":',
                Strings.toString(_povInfo.end),
                "},"
            );
        }

        // ----------------------------------------
        // tag
        // ----------------------------------------
        bytes memory _attributeTag = abi.encodePacked(
            '{"trait_type":"userTag1","value":"',
            _povInfo.tag1,
            '"},{"trait_type":"userTag2","value":"',
            _povInfo.tag2,
            '"},{"trait_type":"userTag3","value":"',
            _povInfo.tag3,
            '"},'
        );
        bytes16[6] memory _tags = SpotResolver(_resolverContractAddress).getTagAsReadable(_tag);
        for (uint256 i = 0; i < _tags.length; i++) {
            if (_tags[i] != 0x0) {
                _attributeTag = abi.encodePacked(
                    _attributeTag,
                    '{"value":"',
                    _bytesToString(abi.encodePacked(_tags[i])),
                    '"},'
                );
            }
        }

        // ----------------------------------------
        // attribute
        // ----------------------------------------
        // attribute : 0x....................VV..........................................

        SpotAttribute memory _spotAttribute = SpotResolver(_resolverContractAddress)
            .parsePoVAttribute(uint16(uint96(bytes12(getExtended(tokenId))) & 0xFFFF));

        bytes memory _attributePoV = abi.encodePacked(
            '{"trait_type":"Device Type","value":"',
            _bytesToString(abi.encodePacked(_spotAttribute.deviceType)),
            '"},{"trait_type":"Sub Type","value":"',
            _bytesToString(abi.encodePacked(_spotAttribute.subType)),
            '"},{"trait_type":"Timestamp Type","value":"',
            _bytesToString(abi.encodePacked(_spotAttribute.timestampType)),
            '"},{"trait_type":"Signature Type","value":"',
            _bytesToString(abi.encodePacked(_spotAttribute.signatureType)),
            '"}]}'
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            _properties,
                            _extraProperties,
                            _attributeStart,
                            _attributeTag,
                            _attributePoV
                        )
                    )
                )
            );
    }

    function contractURI() public view virtual returns (string memory) {
        SpotResolver _resolver = SpotResolver(_resolverContractAddress);
        // ===============================================================================
        // Properties
        // ===============================================================================
        // separate metadata for avoiding stack too deep error
        bytes memory _properties = abi.encodePacked(
            '{"name":"',
            string(abi.encodePacked(_povInfo.name)),
            '","description":"',
            string(abi.encodePacked(_povInfo.description)),
            '","image":"',
            string(abi.encodePacked(_povInfo.imageUrl)),
            '","external_url":"',
            string(abi.encodePacked(_povInfo.website)),
            '",'
        );
        bytes memory _extraProperties = abi.encodePacked(
            '"seller_fee_basis_points":0,',
            '"fee_recipient":"',
            Strings.toHexString(uint160(_resolver.spotOwnerOf()), 20),
            '",'
        );

        // ===============================================================================
        // Attributes
        // ===============================================================================
        bytes memory _attributeStart = abi.encodePacked(
            '"attributes":[{"trait_type":"provider","value":"',
            string(abi.encodePacked(_povInfo.provider)),
            '"},{"trait_type":"spot","value":"',
            Strings.toHexString(uint160(getResolver()), 20),
            '"},'
        );
        // ----------------------------------------
        // timestamp
        // ----------------------------------------
        // timestamp : 0x....VVVVVVVVVVVVVVVV............................................
        if (0 != _povInfo.start) {
            _attributeStart = abi.encodePacked(
                _attributeStart,
                '{"display_type": "date","trait_type":"start","value":',
                Strings.toString(_povInfo.start),
                "},"
            );
        }
        if (0 != _povInfo.end) {
            _attributeStart = abi.encodePacked(
                _attributeStart,
                '{"display_type": "date","trait_type":"end","value":',
                Strings.toString(_povInfo.end),
                "},"
            );
        }

        // ----------------------------------------
        // tag
        // ----------------------------------------
        bytes memory _attributeTag = abi.encodePacked(
            '{"trait_type":"userTag1","value":"',
            _povInfo.tag1,
            '"},{"trait_type":"userTag2","value":"',
            _povInfo.tag2,
            '"},{"trait_type":"userTag3","value":"',
            _povInfo.tag3,
            '"},'
        );
        bytes16[6] memory _tags = _resolver.getTagAsReadable(_tag);
        for (uint256 i = 0; i < _tags.length; i++) {
            if (_tags[i] != 0x0) {
                _attributeTag = abi.encodePacked(
                    _attributeTag,
                    '{"value":"',
                    _bytesToString(abi.encodePacked(_tags[i])),
                    '"},'
                );
            }
        }

        // ----------------------------------------
        // position
        // ----------------------------------------
        string memory _latitude = _int2string(_povInfo.latitude);
        string memory _longitude = _int2string(_povInfo.longitude);

        bytes memory _attributePosision = abi.encodePacked(
            '{"display_type": "number","trait_type":"latitude","value":',
            _latitude,
            '},{"display_type": "number","trait_type":"longitude","value":',
            _longitude,
            "}]}"
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            _properties,
                            _extraProperties,
                            _attributeStart,
                            _attributeTag,
                            _attributePosision
                        )
                    )
                )
            );
    }

    /**
     * @dev Returns PoV of latitude and longitude
     * @return latitude int64, latitude of PoV
     * @return longitude int64, longitude of PoV
     */
    function getPosition() external view returns (int64, int64) {
        return (_povInfo.latitude, _povInfo.longitude);
    }

    /**
     * @dev Returns user data
     * @param tokenId uint256, token id
     * @return userData bytes32, user data
     */
    function getUserData(uint256 tokenId) public view returns (bytes32) {
        return _userData[tokenId];
    }

    /**
     * @dev Returns extended data
     * @param tokenId uint256, token id
     * @return extended uint256, extended
     */
    function getExtended(uint256 tokenId) public view returns (bytes32) {
        return _extended[tokenId];
    }

    /**
     * @dev Returns PoV experience
     * @param visitor address, visitor address
     * @return experience uint256, pov experience
     */
    function getExperience(address visitor) public view returns (uint256) {
        return _experience[visitor];
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns resolver contract address
     */
    function getResolver() public view returns (address) {
        return _resolverContractAddress;
    }

    // ================================================================
    //  owner functions
    // ================================================================

    /**
     * @dev set Name of pov
     * @notice msg.sender should be pov owner or admin.
     * @param __name string calldata, name of pov
     */
    function setName(string calldata __name) public onlyOwner {
        _povInfo.name = __name;
        emit BatchMetadataUpdate(
            0x0,
            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        );
    }

    /**
     * @dev set Description of pov
     * @notice msg.sender should be pov owner or admin.
     * @param description string calldata, description of pov
     */
    function setDescription(string calldata description) public onlyOwner {
        _povInfo.description = description;
        emit BatchMetadataUpdate(
            0x0,
            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        );
    }

    /**
     * @dev set Image Url of pov
     * @notice msg.sender should be pov owner or admin.
     * @param imageUrl string calldata, image of pov
     */
    function setImage(string calldata imageUrl) public onlyOwner {
        _povInfo.imageUrl = imageUrl;
        emit BatchMetadataUpdate(
            0x0,
            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        );
    }

    /**
     * @dev set website of pov
     * @notice msg.sender should be pov owner or admin.
     * @param website string calldata, website of pov
     */
    function setWebsite(string calldata website) public onlyOwner {
        _povInfo.website = website;
        emit BatchMetadataUpdate(
            0x0,
            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        );
    }

    /**
     * @dev set provider of pov
     * @notice msg.sender should be pov owner or admin.
     * @param provider string calldata, provider of pov
     */
    function setProvider(string calldata provider) public onlyOwner {
        _povInfo.provider = provider;
        emit BatchMetadataUpdate(
            0x0,
            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        );
    }

    /**
     * @dev set BaseURI of pov
     * @notice msg.sender should be pov owner or admin.
     * @param baseURI string calldata memory, baseURI of pov
     */
    function setBaseURI(string calldata baseURI) public onlyOwner {
        _povInfo.baseURI = baseURI;
        emit BatchMetadataUpdate(
            0x0,
            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        );
    }

    function changePosition(int64 latitude, int64 longitude) public onlyOwner {
        if (latitude < -9000000000 || latitude > 9000000000) revert("PoV: invalid latitude");
        if (longitude < -18000000000 || longitude > 18000000000) revert("PoV: invalid longitude");
        _povInfo.latitude = latitude;
        _povInfo.longitude = longitude;
        emit BatchMetadataUpdate(
            0x0,
            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        );
    }

    // ================================================================
    //  internal functions
    // ================================================================
    /**
     * @dev mint token (internal)
     * @param to address, holder address
     * @param tokenId uint256, token id
     * @param extended bytes, extended data
     * @param userData bytes, user data
     */
    function _mint(
        address to,
        uint256 tokenId,
        bytes32 extended,
        bytes32 userData
    ) internal virtual {
        if (_povInfo.start != 0 && block.timestamp < uint256(_povInfo.start))
            revert("PoV: Not started yet");
        if (_povInfo.end != 0 && uint256(_povInfo.end) < block.timestamp)
            revert("PoV: Already ended");

        super._mint(to, tokenId);

        _userData[tokenId] = userData;
        _extended[tokenId] = extended;
        _experience[to] += 1;
    }

    /**
     * @dev burn token (internal)
     * @param tokenId uint256, token id
     */
    function _burn(uint256 tokenId) internal virtual override {
        address owner = ownerOf(tokenId);

        super._burn(tokenId);

        delete _userData[tokenId];
        delete _extended[tokenId];
    }

    /**
     * @dev Returns initial symbol
     */
    function _initialSymbol() internal pure returns (string memory) {
        return "POV";
    }

    function _int2string(int256 i) internal pure returns (string memory) {
        if (i == 0) return "0";
        bool negative = i < 0;
        uint256 abs = uint256(negative ? -i : i);

        return string(abi.encodePacked(negative ? "-" : "", Strings.toString(abs)));
    }

    /**
     * @dev Returns string from bytes
     */
    function _bytesToString(bytes memory bytesData) internal pure returns (string memory) {
        // string size
        uint8 size = 0;
        for (uint256 i = 0; i < bytesData.length; i++) {
            if (bytesData[i] == 0x0) {
                size = uint8(i);
                break;
            }
        }
        bytes memory _str = new bytes(size);
        for (uint256 i = 0; i < size; i++) {
            _str[i] = bytesData[i];
        }

        return string(_str);
    }

    // ================================================================
    //  override functions
    // ================================================================

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721) returns (bool) {
        return
            interfaceId == type(IPoV).interfaceId ||
            interfaceId == type(IERC721Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Import the OpenZeppelin AccessControl contract
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

// create a contract that extends the OpenZeppelin AccessControl contract
contract RoleControl is AccessControl {
    // Create a bool check to see if a account address has the role admin
    function isAdmin(address account) public view virtual returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    // Create a modifier that can be used in other contract to make a pre-check
    // That makes sure that the sender of the transaction (msg.sender)  is a admin
    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Restricted to admins.");
        _;
    }

    // Add a user address as a admin
    function addAdmin(address account) public virtual onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    // Delete a user address as a admin
    function deleteAdmin(address account) public virtual onlyAdmin {
        revokeRole(DEFAULT_ADMIN_ROLE, account);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Import the OpenZeppelin AccessControl contract
import { AccessControlUpgradeable } from "@openzeppelin-contracts-upgradeable/access/AccessControlUpgradeable.sol";

// create a contract that extends the OpenZeppelin AccessControl contract
contract RoleControlUpgradeable is AccessControlUpgradeable {
    // Create a bool check to see if a account address has the role admin
    function isAdmin(address account) public view virtual returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    // Create a modifier that can be used in other contract to make a pre-check
    // That makes sure that the sender of the transaction (msg.sender)  is a admin
    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Restricted to admins.");
        _;
    }

    // Add a user address as a admin
    function addAdmin(address account) public virtual onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    // Delete a user address as a admin
    function deleteAdmin(address account) public virtual onlyAdmin {
        revokeRole(DEFAULT_ADMIN_ROLE, account);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface VisitedByTypes {
    event ChangeContractOwner(address indexed oldOwner, address indexed newOwner);

    /**
     * @dev Mint Request
     * @param permit MintPermit, permit
     * @param visitorV uint8, visitor signature v
     * @param visitorR bytes32, visitor signature r
     * @param visitorS bytes32, visitor signature s
     */
    struct MintRequest {
        MintPermit permit;
        uint8 visitorV;
        bytes32 visitorR;
        bytes32 visitorS;
    }

    /**
     * @dev Mint Permit
     * @param visitor address, visitor address
     * @param spotSignatureR bytes32, spot signature r
     * @param spotSignatureS bytes32, spot signature s
     * @param spotSignatureV uint8, spot signature v
     * @param extended bytes32, extended data
     * @param userData bytes32, user data
     * @param nonce uint256, nonce
     * @param deadline uint256, deadline
     */
    struct MintPermit {
        address visitor;
        bytes32 spotSignatureR;
        bytes32 spotSignatureS;
        uint8 spotSignatureV;
        bytes32 extended;
        bytes32 userData;
        uint256 nonce;
        uint256 deadline;
    }

    /**
     * @dev Visitor Register Request
     * @param permit VisitorRegisterPermit, permit
     * @param visitorV uint8, visitor signature v
     * @param visitorR bytes32, visitor signature r
     * @param visitorS bytes32, visitor signature s
     * @param ownerV uint8, owner signature v
     * @param ownerR bytes32, owner signature r
     * @param ownerS bytes32, owner signature s
     */
    struct VisitorRegisterRequest {
        VisitorRegisterPermit permit;
        uint8 visitorV;
        bytes32 visitorR;
        bytes32 visitorS;
        uint8 ownerV;
        bytes32 ownerR;
        bytes32 ownerS;
    }

    /**
     * @dev Visitor Register Permit
     * @param visitor address, visitor address
     * @param owner address, owner address
     * @param nonce uint256, nonce
     * @param deadline uint256, deadline
     */
    struct VisitorRegisterPermit {
        address visitor;
        address owner;
        uint256 nonce;
        uint256 deadline;
    }

    /**
     * @dev Spot Information
     * @param name string, name of pov
     * @param description string, description of pov
     * @param image string, image of pov
     * @param website string, url of pov website
     * @param provider string, owner of pov
     * @param baseURI string, baseURI of pov. if you want to use more information, you should set baseURI on this data.
     * @param tag1 string, tag1 of pov by user
     * @param tag2 string, tag2 of pov by user
     * @param tag3 string, tag3 of pov by user
     */
    struct SpotInfo {
        string name;
        string description;
        string imageUrl;
        string website;
        string provider;
        string baseURI;
        string tag1;
        string tag2;
        string tag3;
    }

    /**
     * @dev PoV Information
     * @param name string, name of pov
     * @param description string, description of pov
     * @param imageUrl string, image of pov
     * @param website string, url of pov website
     * @param provider string, owner of pov
     * @param latitude int64, latitude of pov
     * @param longitude int64, longitude of pov
     * @param start uint64, start of pov (unix time) 0 is no limit
     * @param end uint64, end of pov (unix time) 0 is no limit
     * @param baseURI string, baseURI of pov. if you want to use more information, you should set baseURI on this data.
     * @param tag1 string, tag1 of pov by user
     * @param tag2 string, tag2 of pov by user
     * @param tag3 string, tag3 of pov by user
     */
    struct PoVInfo {
        string name;
        string description;
        string imageUrl;
        string website;
        string provider;
        int64 latitude;
        int64 longitude;
        uint64 start;
        uint64 end;
        string baseURI;
        string tag1;
        string tag2;
        string tag3;
    }

    /**
     * @dev Add PoV Request
     * @param permit AddPoVPermit, permit
     * @param ownerV uint8, owner signature v
     * @param ownerR bytes32, owner signature r
     * @param ownerS bytes32, owner signature s
     */
    struct AddPoVRequest {
        AddPoVPermit permit;
        uint8 ownerV;
        bytes32 ownerR;
        bytes32 ownerS;
    }

    /**
     * @dev Add PoV Permit
     * @param spotAddress address, spot address
     * @param povFactoryID uint256, pov factory id
     * @param povInfo PoVInfo, pov information
     * @param extraParam bytes, extra parameter
     * @param nonce uint256, nonce
     * @param deadline uint256, deadline
     */
    struct AddPoVPermit {
        address spotAddress;
        uint256 povFactoryID;
        PoVInfo povInfo;
        bytes extraParam;
        uint256 nonce;
        uint256 deadline;
    }

    /**
     * @dev set Spot info Request
     * @param permit SetSpotInfoPermit, permit
     * @param ownerV uint8, owner signature v
     * @param ownerR bytes32, owner signature r
     * @param ownerS bytes32, owner signature s
     */
    struct SetSpotInfoRequest {
        SetSpotInfoPermit permit;
        uint8 ownerV;
        bytes32 ownerR;
        bytes32 ownerS;
    }

    /**
     * @dev Add Spot Permit
     * @param povID uint16, pov id
     * @param spotInfo SpotInfo, spot information
     * @param nonce uint256, nonce
     * @param deadline uint256, deadline
     */
    struct SetSpotInfoPermit {
        address spotAddress;
        uint16 povID;
        SpotInfo spotInfo;
        uint256 nonce;
        uint256 deadline;
    }

    /**
     * @dev set PoV info Request
     * @param permit SetPoVInfoPermit, permit
     * @param ownerV uint8, owner signature v
     * @param ownerR bytes32, owner signature r
     * @param ownerS bytes32, owner signature s
     */
    struct SetPoVInfoRequest {
        SetPoVInfoPermit permit;
        uint8 ownerV;
        bytes32 ownerR;
        bytes32 ownerS;
    }

    /**
     * @dev Add PoV Permit
     * @param povID uint16, pov id
     * @param povInfo PoVInfo, pov information
     * @param nonce uint256, nonce
     * @param deadline uint256, deadline
     */
    struct SetPoVInfoPermit {
        address spotAddress;
        uint16 povID;
        PoVInfo povInfo;
        uint256 nonce;
        uint256 deadline;
    }

    /**
     * @dev Spot Attribute
     * @param deviceType bytes16, device type
     * @param subType bytes16, sub type
     * @param timestampType bytes16, timestamp type
     * @param signatureType bytes32, signature type
     */
    struct SpotAttribute {
        bytes16 deviceType;
        bytes16 subType;
        bytes16 timestampType;
        bytes32 signatureType;
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.13;
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IERC5192 is IERC165 {
    /// @notice Emitted when the locking status is changed to locked.
    /// @dev If a token is minted and the status is locked, this event should be emitted.
    /// @param tokenId The identifier for a token.
    event Locked(uint256 tokenId);

    /// @notice Emitted when the locking status is changed to unlocked.
    /// @dev If a token is minted and the status is unlocked, this event should be emitted.
    /// @param tokenId The identifier for a token.
    event Unlocked(uint256 tokenId);

    /// @notice Returns the locking status of an Soulbound Token
    /// @dev SBTs assigned to zero address are considered invalid, and queries
    /// about them do throw.
    /// @param tokenId The identifier for an SBT.
    function locked(uint256 tokenId) external view returns (bool);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.13;
import { IERC165Upgradeable } from "@openzeppelin-contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

interface IERC5192Upgradeable is IERC165Upgradeable {
    /// @notice Emitted when the locking status is changed to locked.
    /// @dev If a token is minted and the status is locked, this event should be emitted.
    /// @param tokenId The identifier for a token.
    event Locked(uint256 tokenId);

    /// @notice Emitted when the locking status is changed to unlocked.
    /// @dev If a token is minted and the status is unlocked, this event should be emitted.
    /// @param tokenId The identifier for a token.
    event Unlocked(uint256 tokenId);

    /// @notice Returns the locking status of an Soulbound Token
    /// @dev SBTs assigned to zero address are considered invalid, and queries
    /// about them do throw.
    /// @param tokenId The identifier for an SBT.
    function locked(uint256 tokenId) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

import { VisitedByTypes } from "@src-root/lib/VisitedByTypes.sol";

interface IPoV is VisitedByTypes {
    // ================================================================
    //  interfaces
    // ================================================================
    /**
     * @dev Mint token
     * @param to address, holder address
     * @param tokenId uint256, token id
     * @param userData bytes, user data
     */
    function mint(address to, uint256 tokenId, bytes32 extended, bytes32 userData) external;

    /**
     * @dev Burn token
     * @param tokenId uint256, token id
     */
    function burn(uint256 tokenId) external;

    /**
     * @dev Returns user data
     * @param tokenId uint256, token id
     * @return userData bytes32, user data
     */
    function getUserData(uint256 tokenId) external view returns (bytes32);

    /**
     * @dev Returns extended data
     * @param tokenId uint256, token id
     * @return extended uint256, extended
     */
    function getExtended(uint256 tokenId) external view returns (bytes32);

    /**
     * @dev Returns PoV experience
     * @param visitor address, visitor address
     * @return experience uint256, pov experience
     */
    function getExperience(address visitor) external view returns (uint256);

    /**
     * @dev Returns resolver contract address
     */
    function getResolver() external view returns (address);

    /**
     * @dev Sets the contract address to allow it to mint token
     * @param resolver address, resolver contract address
     */
    function setResolver(address resolver) external;

    /**
     * @dev set PoV info
     * @notice msg.sender should be pov owner or admin.
     * @param poVInfo PoVInfo, PoV info
     */
    function setPoVInfo(PoVInfo memory poVInfo) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { VisitedByTypes } from "@src-root/lib/VisitedByTypes.sol";

interface IPoVFactory is VisitedByTypes {
    /**
     * @dev create new pov
     * @notice msg.sender should be spot owner or admin.
     * @param povOwner address, pov owner
     * @param resolver address, resolver address
     * @param poVInfo pov info
     * @param tag uint80, tag
     * @param extraParam bytes, extra param(used for factory awesome feature ;')
     * @return address, new pov address
     */
    function createNewPoV(
        address povOwner,
        address resolver,
        PoVInfo memory poVInfo,
        uint80 tag,
        bytes calldata extraParam
    ) external returns (address);

    function name() external pure returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { VisitedByTypes } from "@src-root/lib/VisitedByTypes.sol";
import { SpotResolver } from "@src-root/SpotResolver.sol";

interface ISpotResolverFactory is VisitedByTypes {
    /**
     * @dev create new Spot resolver
     * @notice you can register Spot for your resolver.
     * @param admin address, admin address
     * @param spotOwner address, Spot owner
     * @param spotAddress address, Spot address
     * @param spotInfo SpotInfo
     * @return address, new Spot resolver address
     */
    function createNewSpotResolver(
        address admin,
        address spotOwner,
        address spotAddress,
        SpotInfo memory spotInfo
    ) external returns (address);

    function name() external pure returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IERC5192, IERC165 } from "@src-root/lib/interface/IERC5192.sol";
import { PoV, ERC721 } from "@src-root/lib/PoV.sol";

contract PoV5192 is IERC5192, PoV {
    // ================================================================
    //  mappings
    // ================================================================
    /// lock mapping
    mapping(uint256 => bool) private _lockStatus;

    // ================================================================
    //  constructors
    // ================================================================

    constructor(
        address spotOwner,
        address resolverContractAddress,
        PoVInfo memory povInfo,
        uint80 tag
    ) ERC721("", "") {
        _povInit(spotOwner, resolverContractAddress, povInfo, tag);
    }

    // ================================================================
    //  user functions
    // ================================================================

    /**
     * @dev Returns locked token
     * @param tokenId uint256, token id
     */
    function locked(uint256 tokenId) external view override(IERC5192) returns (bool) {
        return _lockStatus[tokenId];
    }

    // ================================================================
    //  override  functions
    // ================================================================
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(PoV, IERC165) returns (bool) {
        return interfaceId == type(IERC5192).interfaceId || super.supportsInterface(interfaceId);
    }

    // ================================================================
    //  prohibited functions
    // ================================================================

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address, uint256) public virtual override {
        require(msg.sender == address(0), "PoV5192: Not transferable.");
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256) public view virtual override returns (address) {
        require(msg.sender == address(0), "PoV5192: Not transferable.");

        return address(0);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address, bool) public virtual override {
        require(msg.sender == address(0), "PoV5192: Not transferable.");
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address, address) public view virtual override returns (bool) {
        require(msg.sender == address(0), "PoV5192: Not transferable.");

        return false;
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address,
        address,
        uint256
    ) public virtual override {
        require(msg.sender == address(0), "PoV5192: Not transferable.");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address,
        address,
        uint256
    ) public virtual override {
        require(msg.sender == address(0), "PoV5192: Not transferable.");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override {
        require(msg.sender == address(0), "PoV5192: Not transferable.");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IPoVFactory } from "@src-root/lib/interface/IPoVFactory.sol";
import { PoV5192 } from "@src-root/pov/ERC5192/PoV5192.sol";

contract PoV5192Factory is IPoVFactory {
    // ================================================================
    //  user functions
    // ================================================================
    /**
     * @dev create new pov
     * @notice you can register PoV for your resolver.
     * @param povOwner pov owner address
     * @param resolver address, resolver address
     * @param poVInfo pov info
     * @param tag uint80, tag
     * @return address, new pov address
     */
    function createNewPoV(
        address povOwner,
        address resolver,
        PoVInfo memory poVInfo,
        uint80 tag,
        bytes calldata
    ) external override returns (address) {
        PoV5192 pov = new PoV5192(povOwner, resolver, poVInfo, tag);
        return address(pov);
    }

    function name() external pure override returns (string memory) {
        return "PoV5192";
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { RoleControl } from "@src-root/lib/RoleControl.sol";

/**
 * @title ViSItedToken
 * ViSItedToken - a contract for ViSItedToken
 */
contract VSIT is ERC20, RoleControl {
    uint256 public constant TOKEN_CAP = 20000000000000000000000000; // 20,000,000 VSIT
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant CHARGER_ROLE = keccak256("CHARGER_ROLE");

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, msg.sender), "VSIT: must have minter role to mint");
        _;
    }

    modifier onlyCharger() {
        require(hasRole(CHARGER_ROLE, msg.sender), "VSIT: must have charger role to charge");
        _;
    }

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor(address admin, uint256 initialSupply) ERC20("ViSItedToken", "VSIT") {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _mint(admin, initialSupply);
    }

    function mint(address visitor, uint256 amount) public onlyMinter returns (bool) {
        if (TOKEN_CAP < totalSupply() + amount) {
            return false;
        }
        _mint(visitor, amount);
        return true;
    }

    function burn(uint256 amount) public onlyAdmin {
        _burn(msg.sender, amount);
    }

    /**
     * @dev pay fee
     * @param from address
     * @param fee uint256
     */
    function payFee(address from, address to, uint256 fee) public onlyCharger {
        _transfer(from, to, (fee * 19) / 20);

        // burn 5% of fee
        _burn(from, (fee) / 20);
    }

    function addMinter(address minter) public onlyAdmin {
        grantRole(MINTER_ROLE, minter);
    }

    function deleteMinter(address minter) public onlyAdmin {
        revokeRole(MINTER_ROLE, minter);
    }

    function addCharger(address charger) public onlyAdmin {
        grantRole(CHARGER_ROLE, charger);
    }

    function deleteCharger(address charger) public onlyAdmin {
        revokeRole(CHARGER_ROLE, charger);
    }

    function claim() public onlyAdmin {
        _transfer(address(this), msg.sender, balanceOf(address(this)));
    }

    function claimable() public view returns (uint256) {
        return balanceOf(address(this));
    }
}