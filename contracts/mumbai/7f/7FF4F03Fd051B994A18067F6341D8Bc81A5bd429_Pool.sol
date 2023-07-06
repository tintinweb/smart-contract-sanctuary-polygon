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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (governance/utils/IVotes.sol)
pragma solidity ^0.8.0;

/**
 * @dev Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.
 *
 * _Available since v4.5._
 */
interface IVotesUpgradeable {
    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     */
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at the end of a past block (`blockNumber`).
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) external view returns (address);

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) external;

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
interface IERC20PermitUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
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

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

        /// @solidity memory-safe-assembly
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
     * @dev Returns the number of values in the set. O(1).
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "./governor/GovernorProposals.sol";
import "./interfaces/IService.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IToken.sol";
import "./interfaces/ITGE.sol";
import "./interfaces/ICustomProposal.sol";
import "./interfaces/registry/IRecordsRegistry.sol";
import "./libraries/ExceptionsLibrary.sol";

/**
    * @title Pool Contract
    * @notice These contracts are instances of on-chain implementations of user companies. The shareholders of the companies work with them, their addresses are used in the Registry contract as tags that allow obtaining additional legal information (before the purchase of the company by the client). They store legal data (after the purchase of the company by the client). Among other things, the contract is also the owner of the Token and TGE contracts.
    * @dev There can be an unlimited number of such contracts, including for one company owner. The contract can be in three states:
    * 1) the company was created by the administrator, a record of it is stored in the Registry, but the contract has not yet been deployed and does not have an owner (buyer) 
    * 2) the contract is deployed, the company has an owner, but there is not yet a successful (softcap primary TGE), in this state its owner has the exclusive right to recreate the TGE in case of their failure (only one TGE can be launched at the same time) 
    * 3) the primary TGE ended successfully, softcap is assembled - the company has received the status of DAO.    The owner no longer has any exclusive rights, all the actions of the company are carried out through the creation and execution of propousals after voting. In this status, the contract is also a treasury - it stores the company's values in the form of ETH and/or ERC20 tokens.
    * @dev The "Pool owner" status is temporary and is assigned to the address that has successfully purchased a company and in which there has not been a single successful TGE Governance Token. The current owner's address of the company can be obtained by referring to the owner method of the Pool contract. If the isDAO method of the same contract returns "true", then this status does not grant any privileges or exclusive rights and has more of a historical and reference nature.
    As long as the pool is not considered a DAO, the address which is having this status can interact with such methods:
    - TGEFactory.sol:createPrimaryTGE(address poolAddress, IToken.TokenInfo memory tokenInfo, ITGE.TGEInfo memory tgeInfo, string memory metadataURI, IGovernanceSettings.NewGovernanceSettings memory governanceSettings_, address[] memory addSecretary, address[] memory addExecutor) - this method allows you to create a Governance Token compatible with ERC20, with a full set of standard settings, launch a primary TGE for it by deploying the corresponding contract, and also fully configure Governance using the NewGovernanceSettings structure and arrays of addSecretary and addExecutor addresses. The rules set for Governance will become relevant immediately after the successful completion of this primary TGE.
    - Pool.sol:transferByOwner(address to, uint256 amount, address unitOfAccount) - this method allows you to withdraw ETH or any ERC20 token from the pool contract to any address specified by the owner
    Moreover, while in this status, the pool owner, who has not yet become a DAO, can create invoices without restrictions using the Invoice:createInvoice(address pool, InvoiceCore memory core) method.
    In case of a primary TGE failure, the company owner continues to use their unique status, which means they can recreate the token, TGE, and set new Governance settings within a single transaction.
    */
contract Pool is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    GovernorProposals,
    IPool
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;
    using AddressUpgradeable for address payable;
    /// @dev The company's trade mark, label, brand name. It also acts as the Name of all the Governance tokens created for this pool.
    string public trademark;

    /// @dev When a buyer acquires a company, its record disappears from the Registry contract, but before that, the company's legal data is copied to this variable.
    ICompaniesRegistry.CompanyInfo public companyInfo;

    /// @dev Mapping for Governance Token. There can be only one valid Governance token.
    mapping(IToken.TokenType => address) public tokens;

    /// @dev last proposal id for address. This method returns the proposal Id for the last proposal created by the specified address.
    mapping(address => uint256) public lastProposalIdForAddress;

    /// @dev Mapping that stores the blocks of proposal creation for this pool. The main information about the proposal is stored in variables provided by the Governor.sol contract, which is inherited by this contract.
    mapping(uint256 => uint256) public proposalCreatedAt;

    /// @dev A list of tokens belonging to this pool. There can be only one valid Governance token and several Preference tokens with different settings. The mapping key is the token type (token type encoding is specified in the IToken.sol interface). The value is an array of token identifiers.
    mapping(IToken.TokenType => address[]) public tokensFullList;

    /// @dev Mapping that stores information about the type of each token. The mapping key is the address of the token contract, and the value is the digital code of the token type.
    mapping(address => IToken.TokenType) public tokenTypeByAddress;

    /**
     * @notice This collection of addresses is part of the simplified role model of the pool and stores the addresses of accounts that have been assigned the role of pool secretary.
     * @dev Pool secretary is an internal pool role with responsibilities that include working with invoices and creating proposals. This role serves to give authority, similar to a shareholder, to an account that does not have Governance Tokens (e.g., a hired employee).
     */
    EnumerableSetUpgradeable.AddressSet poolSecretary;

    /// @dev Identifier of the last executed proposal
    uint256 public lastExecutedProposalId;

    /// @dev Mapping that stores the addresses of TGE contracts that have been deployed as part of proposal execution, using the identifiers of those proposals as keys.
    mapping(uint256 => address) public proposalIdToTGE;

    /**
     * @notice This collection of addresses is part of the simplified role model of the pool and stores the addresses of accounts that have been assigned the role of pool executor.
     * @dev Pool Executor is an internal pool role with responsibilities that include executing proposals that have ended with a "for" decision in voting and have completed their time in the delayed state.
     */
    EnumerableSetUpgradeable.AddressSet poolExecutor;

    /// @dev Operating Agreement Url
    string public OAurl;

    // EVENTS

    // MODIFIER

    /// @notice Modifier that allows the method to be called only by the Service contract.
    /// @dev It is used to transfer control of the Registry and deployable user contracts for the final configuration of the company.
    modifier onlyService() {
        require(msg.sender == address(service), ExceptionsLibrary.NOT_SERVICE);
        _;
    }

    /// @notice Modifier that allows the method to be called only by the TGEFactory contract.
    /// @dev Used during TGE creation, where the TGEFactory contract deploys contracts and informs their addresses to the pool contract for storage.
    modifier onlyTGEFactory() {
        require(
            msg.sender == address(service.tgeFactory()),
            ExceptionsLibrary.NOT_TGE_FACTORY
        );
        _;
    }

    /// @notice Modifier that allows the method to be called only by an account that has the ADMIN role in the Service contract.
    modifier onlyServiceAdmin() {
        require(
            service.hasRole(service.ADMIN_ROLE(), msg.sender),
            ExceptionsLibrary.NOT_SERVICE_OWNER
        );
        _;
    }

    // INITIALIZER AND CONFIGURATOR

    /// @custom:oz-upgrades-unsafe-allow constructor

    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initialization of a new pool and placement of user settings and data (including legal ones) in it
     * @param companyInfo_ Legal company data
     */
    function initialize(
        ICompaniesRegistry.CompanyInfo memory companyInfo_
    ) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        service = IService(msg.sender);
        companyInfo = companyInfo_;
    }

    /**
    * @notice Actions after purchasing a pool (including ownership transfer and governance settings)
    * @dev This is executed only during a successful execution of purchasePool in the Service contract. The address that is mentioned in the 'newowner' field of the transaction calldata becomes the pool owner.
    * @dev An internal pool role, relevant from the moment of purchasing a company until the first successful TGE. The sole and unchangeable wallet possessing this role is the account that paid the fee for creating the company. Once the pool becomes a DAO, this role no longer has any exclusive powers.

    The appointment of the Owner's address is done within the call to Pool.sol:setNewOwnerWithSettings(address newowner, string memory trademark_, NewGovernanceSettings memory governanceSettings_), which occurs when a new owner purchases the company.
    * @param newowner Address of the new contract owner account
    * @param trademark_ Company trademark
    * @param governanceSettings_ Governance settings (voting rules, etc.)
    */
    function setNewOwnerWithSettings(
        address newowner,
        string memory trademark_,
        NewGovernanceSettings memory governanceSettings_
    ) external onlyService {
        _transferOwnership(address(newowner));
        trademark = trademark_;
        _setGovernanceSettings(governanceSettings_);
    }

    /**
     * @notice Changing the governance settings of the pool as a result of voting or the owner's initial pool setup
     * @dev This method can be called in one of two cases:
     * - The pool has attained DAO status, and a proposal including a transaction calling this method has been executed
     * - The pool has not yet attained DAO status, and the pool owner initiates the initial TGE with new governance settings as arguments
     * @param governanceSettings_ Governance settings
     * @param secretary List of secretary addresses
     * @param executor List of executor addresses
     */
    function setSettings(
        NewGovernanceSettings memory governanceSettings_,
        address[] memory secretary,
        address[] memory executor
    ) external {
        //only tgeFactory or pool
        require(
            msg.sender == address(service.tgeFactory()) ||
                msg.sender == address(this),
            ExceptionsLibrary.NOT_TGE_FACTORY
        );
        if (msg.sender == address(service.tgeFactory())) {
            if (address(getGovernanceToken()) != address(0)) {
                require(!isDAO(), ExceptionsLibrary.IS_DAO);
                require(
                    ITGE(getGovernanceToken().lastTGE()).state() !=
                        ITGE.State.Active,
                    ExceptionsLibrary.ACTIVE_TGE_EXISTS
                );
            }
        }
        _setGovernanceSettings(governanceSettings_);

        address[] memory values = poolSecretary.values();
        for (uint256 i = 0; i < values.length; i++) {
            poolSecretary.remove(values[i]);
        }

        for (uint256 i = 0; i < secretary.length; i++) {
            poolSecretary.add(secretary[i]);
        }

        values = poolExecutor.values();
        for (uint256 i = 0; i < values.length; i++) {
            poolExecutor.remove(values[i]);
        }

        for (uint256 i = 0; i < executor.length; i++) {
            poolExecutor.add(secretary[i]);
        }
    }

    /**
     * @notice Setting legal data for the corresponding company pool
     * @dev This method is executed as part of the internal transaction in the setCompanyInfoForPool method of the Registry contract
     * @param _jurisdiction Digital code of the jurisdiction
     * @param _entityType Digital code of the organization type
     * @param _ein Government registration number of the company
     * @param _dateOfIncorporation Date of incorporation of the company
     * @param _OAuri Operating Agreement URL
     */
    function setCompanyInfo(
        uint256 _jurisdiction,
        uint256 _entityType,
        string memory _ein,
        string memory _dateOfIncorporation,
        string memory _OAuri
    ) external {
        require(
            msg.sender == address(service.registry()),
            ExceptionsLibrary.NOT_REGISTRY
        );
        companyInfo.jurisdiction = _jurisdiction;
        companyInfo.entityType = _entityType;
        companyInfo.ein = _ein;
        companyInfo.dateOfIncorporation = _dateOfIncorporation;
        OAurl = _OAuri;
    }

    // RECEIVE
    /// @dev Method for receiving an Ethereum contract that issues an event.
    receive() external payable {}

    // PUBLIC FUNCTIONS

    /**
     * @notice Method for voting "for" or "against" a given proposal
     * @dev This method calls the _castVote function defined in the Governor.sol contract.
     * @dev Since proposals in the CompanyDAO protocol can be prematurely finalized, after each successful invocation of this method, a check is performed for the occurrence of such conditions.
     * @param proposalId Pool proposal ID
     * @param support "True" for voting "for", "False" for voting "against"
     */
    function castVote(
        uint256 proposalId,
        bool support
    ) external nonReentrant whenNotPaused {
        _castVote(proposalId, support);

        service.registry().log(
            msg.sender,
            address(this),
            0,
            abi.encodeWithSelector(IPool.castVote.selector, proposalId, support)
        );
    }

    // RESTRICTED PUBLIC FUNCTIONS

    /**
     * @dev Adding a new entry about the deployed token contract to the list of tokens related to the pool.
     * @param token_ Token address
     * @param tokenType_ Token type
     */
    function setToken(
        address token_,
        IToken.TokenType tokenType_
    ) external onlyTGEFactory {
        require(token_ != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        if (tokenExists(IToken(token_))) return;
        if (tokenType_ == IToken.TokenType.Governance) {
            // Check that there is no governance tokens or tge failed
            require(
                address(getGovernanceToken()) == address(0) ||
                    ITGE(getGovernanceToken().getTGEList()[0]).state() ==
                    ITGE.State.Failed,
                ExceptionsLibrary.GOVERNANCE_TOKEN_EXISTS
            );
            tokens[IToken.TokenType.Governance] = token_;
            if (tokensFullList[tokenType_].length > 0) {
                tokensFullList[tokenType_].pop();
            }
        }
        tokensFullList[tokenType_].push(token_);
        tokenTypeByAddress[address(token_)] = tokenType_;
    }

    /**
     * @dev This method adds a record to the proposalIdToTGE mapping indicating that a TGE contract with the specified address was deployed as a result of executing the proposal with the lastExecutedProposalId identifier.
     * @param tge TGE address
     */
    function setProposalIdToTGE(address tge) external onlyTGEFactory {
        proposalIdToTGE[lastExecutedProposalId] = tge;
    }

    /**
    * @notice This method is used to initiate the execution of a proposal.
    * @dev For this method to work, the following conditions must be met:
    - The transaction sender must be a valid executor (more details in the isValidExecutor function)
    - The proposal must have the "Awaiting Execution" status.
    * @param proposalId Proposal ID
    */
    function executeProposal(uint256 proposalId) external whenNotPaused {
        require(
            isValidExecutor(msg.sender),
            ExceptionsLibrary.NOT_VALID_EXECUTOR
        );

        lastExecutedProposalId = proposalId;
        _executeProposal(proposalId, service);

        service.registry().log(
            msg.sender,
            address(this),
            0,
            abi.encodeWithSelector(IPool.executeProposal.selector, proposalId)
        );
    }

    /**
     * @notice Method for emergency cancellation of a proposal.
     * @dev Cancel a proposal, callable only by the Service contract.
     * @param proposalId Proposal ID
     */
    function cancelProposal(uint256 proposalId) external onlyService {
        _cancelProposal(proposalId);
    }

    /**
     * @dev Creating a proposal and assigning it a unique identifier to store in the list of proposals in the Governor contract.
     * @param core Proposal core data
     * @param meta Proposal meta data
     */
    function propose(
        address proposer,
        uint256 proposeType,
        IGovernor.ProposalCoreData memory core,
        IGovernor.ProposalMetaData memory meta
    ) external returns (uint256 proposalId) {
        require(
            msg.sender == address(service.customProposal()) &&
                isValidProposer(proposer),
            ExceptionsLibrary.NOT_VALID_PROPOSER
        );

        core.quorumThreshold = quorumThreshold;
        core.decisionThreshold = decisionThreshold;
        core.executionDelay = executionDelays[meta.proposalType];
        uint256 proposalId_ = _propose(
            core,
            meta,
            votingDuration,
            votingStartDelay
        );
        lastProposalIdByType[proposeType] = proposalId_;

        _setLastProposalIdForAddress(proposer, proposalId_);

        service.registry().log(
            proposer,
            address(this),
            0,
            abi.encodeWithSelector(
                IPool.propose.selector,
                proposer,
                proposeType,
                core,
                meta
            )
        );

        return proposalId_;
    }

    /**
     * @notice Transfers funds from the pool's account to a specified address.
     * @dev This method can only be called by the pool owner and only during the period before the pool becomes a DAO.
     * @param to The recipient's address
     * @param amount The transfer amount
     * @param unitOfAccount The unit of account (token contract address or address(0) for ETH)
     */
    function transferByOwner(
        address to,
        uint256 amount,
        address unitOfAccount
    ) external onlyOwner {
        //only if pool is yet DAO
        require(!isDAO(), ExceptionsLibrary.IS_DAO);

        if (unitOfAccount == address(0)) {
            require(
                address(this).balance >= amount,
                ExceptionsLibrary.WRONG_AMOUNT
            );

            (bool success, ) = payable(to).call{value: amount}("");
            require(success, ExceptionsLibrary.WRONG_AMOUNT);
        } else {
            require(
                IERC20Upgradeable(unitOfAccount).balanceOf(address(this)) >=
                    amount,
                ExceptionsLibrary.WRONG_AMOUNT
            );

            IERC20Upgradeable(unitOfAccount).safeTransferFrom(
                msg.sender,
                to,
                amount
            );
        }
    }
    // PUBLIC VIEW FUNCTIONS

    /**
     * @dev Checks if the pool has achieved DAO status.
     * A pool achieves DAO status if it has a valid governance token and the primary TGE was successful.
     * @return isDao True if the pool is a DAO, false otherwise.
     */
    function isDAO() public view returns (bool) {
        if (address(getGovernanceToken()) == address(0)) {
            return false;
        } else {
            return getGovernanceToken().isPrimaryTGESuccessful();
        }
    }

    function getCompanyFee() public view returns (uint256) {
        return companyInfo.fee;
    }

    /**
     * @dev Returns the owner of the pool.
     * @return The address of the pool owner.
     */
    function owner()
        public
        view
        override(IPool, OwnableUpgradeable)
        returns (address)
    {
        return super.owner();
    }

    /**
     * @dev Returns the list of tokens associated with the pool based on the token type.
     * @param tokenType The type of tokens to retrieve.
     * @return The array of token addresses.
     */
    function getTokens(
        IToken.TokenType tokenType
    ) external view returns (address[] memory) {
        return tokensFullList[tokenType];
    }

    /**
     * @dev Returns the governance token associated with the pool.
     * @return The governance token address.
     */
    function getGovernanceToken() public view returns (IToken) {
        return IToken(tokens[IToken.TokenType.Governance]);
    }

    /**
     * @dev Checks if a token exists in the pool.
     * @param token The token to check.
     * @return True if the token exists, false otherwise.
     */
    function tokenExists(IToken token) public view returns (bool) {
        return
            tokenTypeByAddress[address(token)] == IToken.TokenType.None
                ? false
                : true;
    }

    /**
     * @dev Returns the list of pool secretaries.
     * @return The array of pool secretary addresses.
     */
    function getPoolSecretary() external view returns (address[] memory) {
        return isDAO() ? poolSecretary.values() : new address[](0);
    }

    /**
     * @dev Returns the list of pool executors.
     * @return The array of pool executor addresses.
     */
    function getPoolExecutor() external view returns (address[] memory) {
        return isDAO() ? poolExecutor.values() : new address[](0);
    }

    /**
     * @dev Checks if an address is a pool secretary.
     * @param account The address to check.
     * @return True if the address is a pool secretary, false otherwise.
     */
    function isPoolSecretary(address account) public view returns (bool) {
        return isDAO() ? poolSecretary.contains(account) : false;
    }

    /**
     * @dev Checks if an address is a pool executor.
     * @param account The address to check.
     * @return True if the address is a pool executor, false otherwise.
     */
    function isPoolExecutor(address account) public view returns (bool) {
        return isDAO() ? poolExecutor.contains(account) : false;
    }

    /**
     * @dev Checks if an address is a valid proposer for creating proposals.
     * @param account The address to check.
     * @return True if the address is a valid proposer, false otherwise.
     */
    function isValidProposer(address account) public view returns (bool) {
        uint256 currentVotes = _getCurrentVotes(account);
        bool isValid = currentVotes > 0 &&
            (currentVotes > proposalThreshold ||
                isPoolSecretary(account) ||
                service.hasRole(service.SERVICE_MANAGER_ROLE(), msg.sender));
        return isValid;
    }

    /**
     * @dev Checks if an address is a valid executor for executing ballot proposals.
     * @param account The address to check.
     * @return True if the address is a valid executor, false otherwise.
     */
    function isValidExecutor(address account) public view returns (bool) {
        if (
            poolExecutor.length() == 0 ||
            isPoolExecutor(account) ||
            service.hasRole(service.SERVICE_MANAGER_ROLE(), account)
        ) return true;

        return false;
    }

    /**
     * @dev Checks if the last proposal of a specific type is active.
     * @param type_ The type of proposal.
     * @return True if the last proposal of the given type is active, false otherwise.
     */
    function isLastProposalIdByTypeActive(
        uint256 type_
    ) public view returns (bool) {
        if (proposalState(lastProposalIdByType[type_]) == ProposalState.Active)
            return true;

        return false;
    }

    /**
     * @dev Validates the governance settings for creating proposals.
     * @param settings The governance settings to validate.
     */
    function validateGovernanceSettings(
        NewGovernanceSettings memory settings
    ) external pure {
        _validateGovernanceSettings(settings);
    }

    /**
     * @dev Returns the available votes for a proposal at the current block.
     * @param proposalId The ID of the proposal.
     * @return The available votes for the proposal.
     */
    function availableVotesForProposal(
        uint256 proposalId
    ) external view returns (uint256) {
        if (proposals[proposalId].vote.startBlock - 1 < block.number)
            return
                _getBlockTotalVotes(proposals[proposalId].vote.startBlock - 1);
        else return _getBlockTotalVotes(block.number - 1);
    }

    /**
     * @dev Return pool paused status
     * @return Is pool paused
     */
    function paused() public view override returns (bool) {
        // Pausable
        return super.paused();
    }

    // INTERNAL FUNCTIONS

    /**
     * @dev Internal function to be called after a proposal is created.
     * @param proposalId The ID of the created proposal.
     */
    function _afterProposalCreated(uint256 proposalId) internal override {
        service.addProposal(proposalId);
    }

    /**
     * @dev Internal function to get the current votes of an account.
     * @param account The account's address.
     * @return The current votes of the account.
     */
    function _getCurrentVotes(address account) internal view returns (uint256) {
        return getGovernanceToken().getVotes(account);
    }

    /**
     * @dev Internal function to get the total votes in the pool at a specific block.
     * @param blocknumber The block number.
     * @return The total votes at the given block.
     */
    function _getBlockTotalVotes(
        uint256 blocknumber
    ) internal view override returns (uint256) {
        return
            IToken(tokens[IToken.TokenType.Governance]).getPastTotalSupply(
                blocknumber
            );
    }

    /**
     * @dev Internal function to get the past votes of an account at a specific block.
     * @param account The account's address.
     * @param blockNumber The block number.
     * @return The past votes of the account at the given block.
     */
    function _getPastVotes(
        address account,
        uint256 blockNumber
    ) internal view override returns (uint256) {
        return getGovernanceToken().getPastVotes(account, blockNumber);
    }

    /**
     * @dev Internal function to set the last proposal ID for an address.
     * @param proposer The proposer's address.
     * @param proposalId The proposal ID.
     */
    function _setLastProposalIdForAddress(
        address proposer,
        uint256 proposalId
    ) internal override {
        lastProposalIdForAddress[proposer] = proposalId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../interfaces/registry/IRegistry.sol";
import "../interfaces/registry/IRecordsRegistry.sol";
import "../interfaces/governor/IGovernanceSettings.sol";
import "../libraries/ExceptionsLibrary.sol";
/**
* @title Governance Settings Contract
* @notice This module is responsible for storing, validating, and applying Governance settings, and it inherits from the GovernorProposals contract.
*@dev This contract houses one of the most important structures of the protocol called GovernanceSettingsSet. It is used to represent various numerical parameters that universally and comprehensively describe the voting process. The module includes methods for formal data validation, which is proposed to be stored using this structure.
*/
abstract contract GovernanceSettings is IGovernanceSettings {
    // CONSTANTS

    /** 
    * @notice Denominator for shares (such as thresholds)
    * @dev The constant Service.sol:DENOM is used to work with percentage values of QuorumThreshold and DecisionThreshold thresholds, as well as for calculating the ProtocolTokenFee. In this version, it is equal to 1,000,000, for clarity stored as 100 * 10 ^ 4.
    10^4 corresponds to one percent, and 100 * 10^4 corresponds to one hundred percent.
    The value of 12.3456% will be written as 123,456, and 78.9% as 789,000.
    This notation allows specifying ratios with an accuracy of up to four decimal places in percentage notation (six decimal places in decimal notation).
    When working with the CompanyDAO frontend, the application scripts automatically convert the familiar percentage notation into the required format. When using the contracts independently, this feature of value notation should be taken into account.
    */
    uint256 private constant DENOM = 100 * 10**4;

    // STORAGE

    /**
    * @notice The minimum amount of votes required to create a proposal
    * @dev The proposal threshold is the number of votes (i.e., tokens delegated to an address) that are minimally required to create a proposal. When calling the Pool:propose method, the contract compares the number of votes of the address with this value, and if there are insufficient tokens in the delegation, the transaction ends with a revert.
    This value is stored in the Pool contract as an integer, taking into account the "Decimals" parameter of the Governance token. In the current version, for Governance tokens, this parameter is equal to 18. That is, the 18 rightmost digits of the value represent the fractional part of the number of tokens required to create a proposal.
    Each pool can set any ProposalThreshold value in the range from 0 to the maximum value allowed by the uint256 type. The setting is made in conjunction with changing other Governance Settings either by the Owner of the pool when launching the primary TGE or during the execution of "Governance Settings" proposal transactions.
    */
    uint256 public proposalThreshold;

    /** 
    * @notice The minimum amount of votes which need to participate in the proposal in order for the proposal to be considered valid, given as a percentage of all existing votes
    * @dev The quorum threshold is a percentage ratio stored in the Pool contract as an integer using the DENOM entry. It indicates the minimum share of all proposals[proposalId].vote.availableVotes that must be used in voting (regardless of whether the votes were "for" or "against", their sum matters) for the vote to be considered valid.
    Reaching the Quorum Threshold is one of several conditions required for a proposal to be accepted and executable.
    Each pool can set any QuorumThreshold value in the range from 0 to 100%. The setting is made in conjunction with changing other Governance Settings either by the Owner of the pool when launching the primary TGE or during the execution of "Governance Settings" proposal transactions.
    */
    uint256 public quorumThreshold;

    /** 
    * @notice The minimum amount of votes which are needed to approve the proposal, given as a percentage of all participating votes
    * @dev The decision threshold is a percentage ratio stored in the Pool contract as an integer using the DENOM entry. It indicates the minimum share of the votes cast by users that must be cast "for" a proposal during voting for a positive decision to be made.
    The sum of all votes cast by users during voting can be calculated using the formula:
        Pool:proposals[proposalId].vote.forVotes + Pool:proposals[proposalId].vote.againstVotes
    Reaching the Decision Threshold is one of several conditions required for a proposal to be accepted and executable.
    Each pool can set any DecisionThreshold value in the range from 0 to 100%. The setting is made in conjunction with changing other Governance Settings either by the Owner of the pool when launching the primary TGE or during the execution of "Governance Settings" proposal transactions.
    */
    uint256 public decisionThreshold;

    /// @notice The amount of time for which the proposal will remain active, given as the number of blocks which have elapsed since the creation of the proposal
    uint256 public votingDuration;

    /// @notice The threshold value for a transaction which triggers the transaction execution delay
    uint256 public transferValueForDelay;

    /// @notice Returns transaction execution delay values for different proposal types
    mapping(IRegistry.EventType => uint256) public executionDelays;

    /// @notice Delay before voting starts. In blocks
    uint256 public votingStartDelay;

    /// @notice Storage gap (for future upgrades)
    uint256[49] private __gap;

    // EVENTS

    /**
    * @notice This event emitted only when the following values (governance settings) are set for a particular pool
     * @dev The emission of this event can coincide with the purchase of a pool, the launch of an initial TGE, or the execution of a transaction prescribed by a proposal with the GovernanceSettings type.GovernanceSettings
     * @param proposalThreshold_ the proposal threshold (specified in token units with decimals taken into account)
     * @param quorumThreshold_ the quorum threshold (specified as a percentage)
     * @param decisionThreshold_ the decision threshold (specified as a percentage)
     * @param votingDuration_ the duration of the voting period (specified in blocks)
     * @param transferValueForDelay_ the minimum amount in USD for which a transfer from the pool wallet will be subject to a delay
     * @param executionDelays_ execution delays specified in blocks for different types of proposals
     * @param votingStartDelay_ the delay before voting starts for newly created proposals, specified in blocks
     */
    event GovernanceSettingsSet(
        uint256 proposalThreshold_,
        uint256 quorumThreshold_,
        uint256 decisionThreshold_,
        uint256 votingDuration_,
        uint256 transferValueForDelay_,
        uint256[4] executionDelays_,
        uint256 votingStartDelay_
    );

    // PUBLIC FUNCTIONS

    /**
     * @notice Updates governance settings
     * @param settings New governance settings
     */
    function setGovernanceSettings(NewGovernanceSettings memory settings)
        external
    {
        // The governance settings function can only be called by the pool contract
        require(msg.sender == address(this), ExceptionsLibrary.INVALID_USER);

        // Internal function to update governance settings
        _setGovernanceSettings(settings);
    }

    // INTERNAL FUNCTIONS

    /**
     * @notice Updates governance settings
     * @param settings New governance settings
     */
    function _setGovernanceSettings(NewGovernanceSettings memory settings)
        internal
    {
        // Validates the values for governance settings
        _validateGovernanceSettings(settings);

        // Apply settings
        proposalThreshold = settings.proposalThreshold;
        quorumThreshold = settings.quorumThreshold;
        decisionThreshold = settings.decisionThreshold;
        votingDuration = settings.votingDuration;
        transferValueForDelay = settings.transferValueForDelay;

        executionDelays[IRecordsRegistry.EventType.None] = settings
            .executionDelays[0];
        executionDelays[IRecordsRegistry.EventType.Transfer] = settings
            .executionDelays[1];
        executionDelays[IRecordsRegistry.EventType.TGE] = settings
            .executionDelays[2];
        executionDelays[
            IRecordsRegistry.EventType.GovernanceSettings
        ] = settings.executionDelays[3];

        votingStartDelay = settings.votingStartDelay;
    }

    // INTERNAL VIEW FUNCTIONS

    /**
     * @notice Validates governance settings
     * @param settings New governance settings
     */
    function _validateGovernanceSettings(NewGovernanceSettings memory settings)
        internal
        pure
    {
        // Check all values for sanity
        require(
            settings.quorumThreshold < DENOM,
            ExceptionsLibrary.INVALID_VALUE
        );
        require(
            settings.decisionThreshold <= DENOM,
            ExceptionsLibrary.INVALID_VALUE
        );
        require(settings.votingDuration > 0, ExceptionsLibrary.INVALID_VALUE);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "../libraries/ExceptionsLibrary.sol";
import "../interfaces/IService.sol";
import "../interfaces/IPool.sol";
import "../interfaces/governor/IGovernor.sol";
import "../interfaces/registry/IRegistry.sol";

/**
* @title Governor Contract
* @notice This contract extends the functionality of the pool contract. If the pool has been granted DAO status, Governance tokens can be used as votes during the voting process for proposals created for the pool. With this architecture, the pool can invoke methods on behalf of itself provided by this module to execute transactions prescribed by proposals.
* @dev This module provides additional methods for creating proposals, participating and observing the voting process, as well as safely and securely counting votes and executing decisions that have undergone voting.
*/
abstract contract Governor {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;
    using AddressUpgradeable for address payable;

    // CONSTANTS

    /** 
    * @notice Denominator for shares (such as thresholds)
    * @dev The constant Service.sol:DENOM is used to work with percentage values of QuorumThreshold and DecisionThreshold thresholds, as well as for calculating the ProtocolTokenFee. In this version, it is equal to 1,000,000, for clarity stored as 100 * 10 ^ 4.
    10^4 corresponds to one percent, and 100 * 10^4 corresponds to one hundred percent.
    The value of 12.3456% will be written as 123,456, and 78.9% as 789,000.
    This notation allows specifying ratios with an accuracy of up to four decimal places in percentage notation (six decimal places in decimal notation).
    When working with the CompanyDAO frontend, the application scripts automatically convert the familiar percentage notation into the required format. When using the contracts independently, this feature of value notation should be taken into account.
    */
    uint256 private constant DENOM = 100 * 10**4;

    // STORAGE

    /**
    * @notice Proposal state codes.
    * @dev Additional data type used only in this extension.
    "0" / "None" - the proposal does not exist
    "1" / "Active" - the proposal has been launched and is being voted on
    "2" / "Failed" - the voting is complete, and the result is negative
    "3" / "Delayed" - the voting is complete, the result is positive, and the system is waiting for a security timeout to complete, during which the service administrator can cancel the execution
    "4" / "AwaitingExecution" - the voting is complete, the result is positive, and the executeProposal method must be called by an account with the appropriate role
    "5" / "Executed" - the voting is complete, the result is positive, and the transaction provided by the proposal has been executed
    "6" / "Cancelled" - the voting is complete with a positive result, or it has been prematurely cancelled, and the proposal has been cancelled by the administrator
    */
    enum ProposalState {
        None,
        Active,
        Failed,
        Delayed,
        AwaitingExecution,
        Executed,
        Cancelled
    }

    /**
    * @notice This structure is used for a complete description of the proposal state.
     * @dev Each proposal has a field represented by this structure, which stores information on the progress of the voting. Note that 
    - endBlock may differ from the calculated value (currentBlock + votingDuration), since at the time of creating the proposal, it will be increased by votingStartDelay, and if the required number and ratio of votes is reached to recognize this vote as completed early with some result, this field is overwritten
    - startBlock may differ from the calculated value (currentBlock), since at the time of creating the proposal, it will be increased by votingStartDelay  
     * @param startBlock The true block start of the voting
     * @param endBlock The true block end of the voting
     * @param availableVotes The total number of available votes calculated at the time of creating the proposal
     * @param forVotes The number of votes "for" cast
     * @param againstVotes The number of votes "against" cast
     * @param executionState The digital code of the proposal state
     */
    struct ProposalVotingData {
        uint256 startBlock;
        uint256 endBlock;
        uint256 availableVotes;
        uint256 forVotes;
        uint256 againstVotes;
        ProposalState executionState;
    }

    /**
    * @notice The structure that includes all the nested structures describing the subject, state, and metadata of the voting.
     * @dev This is the format in which information about each individual proposal is stored in the contract. Since the Pool contract inherits from Governor, all proposals for an individual pool are stored separately in the public mapping(uint256 => Proposal) proposals, where the mapping key is the internal proposal identifier (which is subsequently stored in the array of records of the Registry contract).
     * @param core Data on the voting settings that were applied to this proposal
     * @param vote Cumulative information on the progress of voting on this proposal
     * @param meta Metadata on the subject of the vote
     */
    struct Proposal {
        IGovernor.ProposalCoreData core;
        ProposalVotingData vote;
        IGovernor.ProposalMetaData meta;
    }

    //// @notice Mapping that contains all the proposals launched for this pool.
    /// @dev In this mapping, the local identifier (specific to the pool's scope) is used as the key. The proposal is also registered in the Registry contract, where it is assigned a global number.
    mapping(uint256 => Proposal) public proposals;

    /// @notice These numerical codes determine which side an account took during the voting process.
    /// @dev "0" - not voted, "1" - voted "against", "2" - voted "for".
    enum Ballot {
        None,
        Against,
        For
    }

    /// @notice Mapping with the voting history.
    /// @dev The account address is used as the first key, and the proposal number is used as the second key. The stored value for these keys is described by the Ballot type.
    mapping(address => mapping(uint256 => Ballot)) public ballots;

    /// @dev Last proposal ID
    uint256 public lastProposalId;

    // EVENTS

    /**
     * @dev Event emitted on proposal creation
     * @param proposalId Proposal ID
     * @param core Proposal core data
     * @param meta Proposal meta data
     */
    event ProposalCreated(
        uint256 proposalId,
        IGovernor.ProposalCoreData core,
        IGovernor.ProposalMetaData meta
    );

    /**
     * @dev Event emitted on proposal vote cast
     * @param voter Voter address
     * @param proposalId Proposal ID
     * @param votes Amount of votes
     * @param ballot Ballot (against or for)
     */
    event VoteCast(
        address voter,
        uint256 proposalId,
        uint256 votes,
        Ballot ballot
    );

    /**
     * @dev Event emitted on proposal execution
     * @param proposalId Proposal ID
     */
    event ProposalExecuted(uint256 proposalId);

    /**
     * @dev Event emitted on proposal cancellation
     * @param proposalId Proposal ID
     */
    event ProposalCancelled(uint256 proposalId);

    // PUBLIC VIEW FUNCTIONS

    /**
    * @notice This method returns the state of the specified proposal.
     * @dev Among the Governance Settings, there is a parameter called votingDuration, which contains the number of blocks for the duration of the vote, and a parameter called votingStartDelay, which contains the number of blocks for the delay of the vote's start relative to the block of the proposal's creation.
    The start and end blocks of the vote are placed in the Pool:proposals[proposalId] entry as vote.startBlock and vote.endBlock.
        vote.startBlock = block.number + votingStartDelay
        vote.endBlock = block.number + votingStartDelay + votingDuration
    The proposal status can be obtained from the Pool:proposalState(proposalId) method. It is formed by comparing the current block with the end block, as well as from proposals[proposalId].vote.executionState, which can store irreversible state flags "Canceled" or "Executed". This value is a numerical code for one of the proposal states, with all possible state types listed in Governor.sol:ProposalState.
    Before the endBlock occurs, the proposal has an Active status, but the ability to vote (using the castVote method in the Pool contract) only appears from the startBlock. This status means that the QuorumThreshold and/or DecisionThreshold have not yet been reached, and there is still a sufficient number of unused votes, the application of which can lead to either of the two results.
    When the endBlock occurs, the proposal is no longer Active. New votes are not accepted, and the state changes to:
    - Failed if the QuorumThreshold and/or DecisionThreshold were not met by the voters
    - Delayed if both thresholds were met.
    The Failed state is irreversible and means that the decision "for" was not made, i.e., the transactions prescribed by the proposal cannot be executed.
    The Delayed state means that the necessary number of votes has been cast "for" the proposal, but the transactions prescribed by the proposal can be executed only after proposals[proposalId].core.executionDelay blocks have passed.
    The AwaitingExecution state means that the necessary number of votes has been cast "for" the proposal, the delay has ended, and the transactions prescribed by the proposal can be executed right now.
    The Canceled state means that the address assigned the ADMIN role in the Service contract used the cancelProposal method of the Service contract and canceled the execution of the proposal. This method could work only if the proposal had an Active, Delayed, or AwaitingExecution state at the time of cancellation. This state is irreversible; the proposal permanently loses the ability to accept votes, and its transactions will not be executed.
    The Executed state means that the address assigned the SERVICE_MANAGER role in the Service contract, or the address assigned the Executor role in the Pool contract, or any address if no address was assigned the Executor role in the pool, used the executeProposal method in the Pool contract. This state means that all transactions prescribed by the proposal have been successfully executed.
    * @param proposalId Идентификатор Proposal.
    * @return The state code using the ProposalState type.
     */
    function proposalState(uint256 proposalId)
        public
        view
        returns (ProposalState)
    {
        Proposal memory proposal = proposals[proposalId];

        if (proposal.vote.startBlock == 0) {
            return ProposalState.None;
        }

        // If proposal executed, cancelled or simply not started, return immediately
        if (
            proposal.vote.executionState == ProposalState.Executed ||
            proposal.vote.executionState == ProposalState.Cancelled
        ) {
            return proposal.vote.executionState;
        }
        if (
            proposal.vote.startBlock > 0 &&
            block.number < proposal.vote.startBlock
        ) {
            return ProposalState.Active;
        }
        uint256 availableVotesForStartBlock = _getBlockTotalVotes(
            proposal.vote.startBlock - 1
        );
        uint256 castVotes = proposal.vote.forVotes + proposal.vote.againstVotes;

        if (block.number >= proposal.vote.endBlock) {
            // Proposal fails if quorum threshold is not reached
            if (
                !shareReached(
                    castVotes,
                    availableVotesForStartBlock,
                    proposal.core.quorumThreshold
                )
            ) {
                return ProposalState.Failed;
            }
            // Proposal fails if decision threshold is not reched
            if (
                !shareReached(
                    proposal.vote.forVotes,
                    castVotes,
                    proposal.core.decisionThreshold
                )
            ) {
                return ProposalState.Failed;
            }
            // Otherwise succeeds, check for delay
            if (
                block.number >=
                proposal.vote.endBlock + proposal.core.executionDelay
            ) {
                return ProposalState.AwaitingExecution;
            } else {
                return ProposalState.Delayed;
            }
        } else {
            return ProposalState.Active;
        }
    }

    /**
    * @dev This method is used to work with the voting history and returns the vote code according to the Ballot type made by the specified account in the specified proposal. Additionally, using the pastVotes snapshots, it provides information about the number of votes this account had during the specified voting.
    * @param account Account address.
    * @param proposalId Proposal identifier.
    * @return ballot Vote type.
    * @return votes Number of votes cast.
    */
    function getBallot(address account, uint256 proposalId)
        public
        view
        returns (Ballot ballot, uint256 votes)
    {
        if (proposals[proposalId].vote.startBlock - 1 < block.number)
            return (
                ballots[account][proposalId],
                _getPastVotes(
                    account,
                    proposals[proposalId].vote.startBlock - 1
                )
            );
        else
            return (
                ballots[account][proposalId],
                _getPastVotes(account, block.number - 1)
            );
    }

    // INTERNAL FUNCTIONS

    /**
     * @dev Creating a proposal and assigning it a unique identifier to store in the list of proposals in the Governor contract.
     * @param core Proposal core data
     * @param meta Proposal meta data
     * @param votingDuration Voting duration in blocks
     */
    function _propose(
        IGovernor.ProposalCoreData memory core,
        IGovernor.ProposalMetaData memory meta,
        uint256 votingDuration,
        uint256 votingStartDelay
    ) internal returns (uint256 proposalId) {
        // Increment ID counter
        proposalId = ++lastProposalId;

        // Create new proposal
        proposals[proposalId] = Proposal({
            core: core,
            vote: ProposalVotingData({
                startBlock: block.number + votingStartDelay,
                endBlock: block.number + votingStartDelay + votingDuration,
                availableVotes: 0,
                forVotes: 0,
                againstVotes: 0,
                executionState: ProposalState.None
            }),
            meta: meta
        });

        // Call creation hook
        _afterProposalCreated(proposalId);

        // Emit event
        emit ProposalCreated(proposalId, core, meta);
    }

    /**
    * @notice Implementation of the voting method for the pool contract.
    * @dev This method includes a check that the proposal is still in the "Active" state and eligible for the user to cast their vote. Additionally, each invocation of this method results in an additional check for the conditions to prematurely end the voting.
    * @param proposalId Proposal ID.
    * @param support "True" for a vote "in favor/for," "False" otherwise.
    */
    function _castVote(uint256 proposalId, bool support) internal {
        // Check that voting exists, is started and not finished
        require(
            proposals[proposalId].vote.startBlock != 0,
            ExceptionsLibrary.NOT_LAUNCHED
        );
        require(
            proposals[proposalId].vote.startBlock <= block.number,
            ExceptionsLibrary.NOT_LAUNCHED
        );
        require(
            proposals[proposalId].vote.endBlock > block.number,
            ExceptionsLibrary.VOTING_FINISHED
        );
        require(
            ballots[msg.sender][proposalId] == Ballot.None,
            ExceptionsLibrary.ALREADY_VOTED
        );

        // Get number of votes
        uint256 votes = _getPastVotes(
            msg.sender,
            proposals[proposalId].vote.startBlock - 1
        );

        require(votes > 0, ExceptionsLibrary.ZERO_VOTES);

        // Account votes
        if (support) {
            proposals[proposalId].vote.forVotes += votes;
            ballots[msg.sender][proposalId] = Ballot.For;
        } else {
            proposals[proposalId].vote.againstVotes += votes;
            ballots[msg.sender][proposalId] = Ballot.Against;
        }

        // Check for voting early end
        _checkProposalVotingEarlyEnd(proposalId);

        // Emit event
        emit VoteCast(
            msg.sender,
            proposalId,
            votes,
            support ? Ballot.For : Ballot.Against
        );
    }

    /**
     * @dev Performance of the proposal with checking its status. Only the Awaiting Execution of the proposals can be executed.
     * @param proposalId Proposal ID
     * @param service Service address
     */
    function _executeProposal(uint256 proposalId, IService service) internal {
        // Check state
        require(
            proposalState(proposalId) == ProposalState.AwaitingExecution,
            ExceptionsLibrary.WRONG_STATE
        );

        // Mark as executed
        proposals[proposalId].vote.executionState = ProposalState.Executed;

        // Execute actions
        Proposal memory proposal = proposals[proposalId];
        for (uint256 i = 0; i < proposal.core.targets.length; i++) {
            if (proposal.core.callDatas[i].length == 0) {
                payable(proposal.core.targets[i]).sendValue(
                    proposal.core.values[i]
                );
            } else {
                proposal.core.targets[i].functionCallWithValue(
                    proposal.core.callDatas[i],
                    proposal.core.values[i]
                );
            }
        }

        // Add event to service
        service.addEvent(
            proposal.meta.proposalType,
            proposalId,
            proposal.meta.metaHash
        );

        // Emit contract event
        emit ProposalExecuted(proposalId);
    }

    /**
     * @dev The substitution of proposals, both active and those that have a positive voting result, but have not yet been executed.
     * @param proposalId Proposal ID
     */
    function _cancelProposal(uint256 proposalId) internal {
        // Check proposal state
        ProposalState state = proposalState(proposalId);
        require(
            state == ProposalState.Active ||
                state == ProposalState.Delayed ||
                state == ProposalState.AwaitingExecution,
            ExceptionsLibrary.WRONG_STATE
        );

        // Mark proposal as cancelled
        proposals[proposalId].vote.executionState = ProposalState.Cancelled;

        // Emit event
        emit ProposalCancelled(proposalId);
    }

    /**
     * @notice The method checks whether it is possible to end the voting early with the result fixed. If a quorum was reached and so many votes were cast in favor that even if all other available votes were cast against, or if so many votes were cast against that it could not affect the result of the vote, this function will change set the end block of the proposal to the current block
     * @dev During the voting process, a situation may arise when such a number of votes have been cast "for" or "against" a proposal that no matter how the remaining votes are distributed, the outcome of the proposal will not change.
    This can occur in the following situations:
    - The sum of "for" votes and unused votes does not exceed the DecisionThreshold of the total number of votes allowed in the voting process (occurs when there are so many "against" votes that even using the remaining votes in favor of the proposal will not allow overcoming the DecisionThreshold).
    - The number of "for" votes is no less than the DecisionThreshold of the total number of votes allowed in the voting process (occurs when there are so many "for" votes that even if all the remaining unused votes are cast "against", the proposal will still be considered accepted).
    Both of these conditions trigger ONLY when the QuorumThreshold is reached simultaneously.
    In such cases, further voting and waiting become pointless and meaningless. No subsequent vote can influence the outcome of the voting to change.
    Therefore, an additional check for triggering the conditions described above has been added to the Pool:castVote method. If the vote can be safely terminated early, the proposals[proposalId].vote.endBlock is changed to the current one during the method's execution.
    This means that the state of the proposal ceases to be Active and should change to Failed or Delayed.
     * @param proposalId Proposal ID
     */
    function _checkProposalVotingEarlyEnd(uint256 proposalId) internal {
        // Get values
        Proposal memory proposal = proposals[proposalId];
        uint256 availableVotesForStartBlock = _getBlockTotalVotes(
            proposal.vote.startBlock - 1
        );
        uint256 castVotes = proposal.vote.forVotes + proposal.vote.againstVotes;
        uint256 extraVotes = availableVotesForStartBlock - castVotes;

        // Check if quorum is reached
        if (
            !shareReached(
                castVotes,
                availableVotesForStartBlock,
                proposal.core.quorumThreshold
            )
        ) {
            return;
        }

        // Check for early guaranteed result
        if (
            !shareOvercome(
                proposal.vote.forVotes + extraVotes,
                availableVotesForStartBlock,
                proposal.core.decisionThreshold
            ) ||
            shareReached(
                proposal.vote.forVotes,
                availableVotesForStartBlock,
                proposal.core.decisionThreshold
            )
        ) {
            // Mark voting as finished
            proposals[proposalId].vote.endBlock = block.number;
        }
    }

    // INTERNAL PURE FUNCTIONS

    /**
     * @dev Checks if `amount` divided by `total` exceeds `share`
     * @param amount Amount numerator
     * @param total Amount denominator
     * @param share Share numerator
     */
    function shareReached(
        uint256 amount,
        uint256 total,
        uint256 share
    ) internal pure returns (bool) {
        return amount * DENOM >= share * total;
    }

    /**
     * @dev Checks if `amount` divided by `total` overcomes `share`
     * @param amount Amount numerator
     * @param total Amount denominator
     * @param share Share numerator
     */
    function shareOvercome(
        uint256 amount,
        uint256 total,
        uint256 share
    ) internal pure returns (bool) {
        return amount * DENOM > share * total;
    }

    // ABSTRACT FUNCTIONS

    /**
     * @dev Hook called after a proposal is created
     * @param proposalId Proposal ID
     */
    function _afterProposalCreated(uint256 proposalId) internal virtual;

    /**
     * @dev Function that returns the total amount of votes in the pool in block
     * @param blocknumber block number
     * @return Total amount of votes
     */
    function _getBlockTotalVotes(uint256 blocknumber)
        internal
        view
        virtual
        returns (uint256);

    /**
     * @dev Function that returns the amount of votes for a client adrress at any given block
     * @param account Account's address
     * @param blockNumber Block number
     * @return Account's votes at given block
     */
    function _getPastVotes(address account, uint256 blockNumber)
        internal
        view
        virtual
        returns (uint256);

    /**
     * @dev Function that set last ProposalId for a client address
     * @param proposer Proposer's address
     * @param proposalId Proposal id
     */
    function _setLastProposalIdForAddress(address proposer, uint256 proposalId)
        internal
        virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "./Governor.sol";
import "./GovernanceSettings.sol";
import "../interfaces/IPool.sol";
import "../interfaces/governor/IGovernorProposals.sol";
import "../interfaces/IService.sol";
import "../interfaces/registry/IRecordsRegistry.sol";
import "../interfaces/ITGE.sol";
import "../interfaces/IToken.sol";
import "../interfaces/ICustomProposal.sol";
import "../libraries/ExceptionsLibrary.sol";
/**
* @title Governor Proposals Contract
* @notice Contract for tracking and typing the created proposals.
* @dev The final implementation of the voting logic is placed in this module, which inherits from the Governor contract and is inherited by pool contracts.
*/
abstract contract GovernorProposals is
    Initializable,
    Governor,
    GovernanceSettings,
    IGovernorProposals
{
    // STORAGE

    /// @dev The address of the Service contract.
    IService public service;

    /// @dev last Proposal Id By Type for state checking
    mapping(uint256 => uint256) public lastProposalIdByType;

    /// @notice Numerical codes to determine the type of proposals being created.
    /// @dev The code describes the nature and degree of impact on the pool of a set of transactions that should be executed as a result of a successful vote.
    enum ProposalType {
        Transfer,
        TGE,
        GovernanceSettings
        // 3 - PoolSecretary
        // 4 - CustomTx
        // 5 - PoolExecutor
        // 6 - proposeTGEERC1155
    }

    /// @notice Storage gap (for future upgrades)
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./ITGE.sol";

import "./governor/IGovernanceSettings.sol";

interface ICustomProposal {}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
/**
 * @title Invoice Interface
 * @notice These structures are used to describe an instance of an invoice.
 * @dev The storage of invoices is managed in Invoice.sol in the `invoices` variable.
*/
interface IInvoice {
    /** 
    * @notice This interface contains a data structure that describes the payment rules for an invoice. 
    * @dev This data is used to validate the payment transaction, determine the state of the invoice, and so on. This data is formed from the input of the invoice creator.
    * @param amount Amount to be paid
    * @param unitOfAccount The address of the token contract that can be used to make the payment (a zero address assumes payment in native ETH)
    * @param expirationBlock The block at which the invoice expires
    * @param description Description of the invoice
    * @param whitelist A whitelist of payers. An empty array denotes a public invoice.
    */
    struct InvoiceCore {
        uint256 amount;
        address unitOfAccount;
        uint256 expirationBlock;
        string description;
        address[] whitelist;
    }
    /**
    * @notice This interface is used to store complete records of invoices, including their current state, metadata, and payment rules.
    * @dev This data is automatically formed when the invoice is created and changes when state-changing transactions are executed.
    * @param core Payment rules (user input)
    * @param invoiceId Invoice identifier
    * @param createdBy The creator of the invoice
    * @param isPaid Flag indicating whether the invoice has been successfully paid
    * @param isCanceled Flag indicating whether the invoice has been canceled
    */
    struct InvoiceInfo {
        InvoiceCore core;
        uint256 invoiceId;
        address createdBy;
        bool isPaid;
        bool isCanceled;
    }
    /**
    * @notice Encoding the states of an individual invoice
    * @dev None - for a non-existent invoice, Paid, Expired, Canceled - are completed invoice states where payment is not possible.
    */
    enum InvoiceState {
        None,
        Active,
        Paid,
        Expired,
        Canceled
    }

    function createInvoice(address pool, InvoiceCore memory core) external;

    function payInvoice(address pool, uint256 invoiceId) external payable;

    function cancelInvoice(address pool, uint256 invoiceId) external;

    function setInvoiceCanceled(address pool, uint256 invoiceId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IToken.sol";
import "./registry/IRegistry.sol";
import "./registry/ICompaniesRegistry.sol";

import "./governor/IGovernor.sol";
import "./governor/IGovernanceSettings.sol";
import "./governor/IGovernorProposals.sol";

interface IPool is IGovernorProposals {
    function initialize(
        ICompaniesRegistry.CompanyInfo memory companyInfo_
    ) external;

    function setNewOwnerWithSettings(
        address owner_,
        string memory trademark_,
        IGovernanceSettings.NewGovernanceSettings memory governanceSettings_
    ) external;

    function propose(
        address proposer,
        uint256 proposalType,
        IGovernor.ProposalCoreData memory core,
        IGovernor.ProposalMetaData memory meta
    ) external returns (uint256 proposalId);

    function setToken(address token_, IToken.TokenType tokenType_) external;

    function setProposalIdToTGE(address tge) external;

    function cancelProposal(uint256 proposalId) external;

    function setSettings(
        IGovernanceSettings.NewGovernanceSettings memory governanceSettings_,
        address[] memory secretary,
        address[] memory executor
    ) external;

    function owner() external view returns (address);

    function isDAO() external view returns (bool);

    function trademark() external view returns (string memory);

    function getGovernanceToken() external view returns (IToken);

    function tokenExists(IToken token_) external view returns (bool);

    function tokenTypeByAddress(
        address token_
    ) external view returns (IToken.TokenType);

    function isValidProposer(address account) external view returns (bool);

    function isPoolSecretary(address account) external view returns (bool);

    function isLastProposalIdByTypeActive(
        uint256 type_
    ) external view returns (bool);

    function validateGovernanceSettings(
        IGovernanceSettings.NewGovernanceSettings memory settings
    ) external pure;

    function getPoolSecretary() external view returns (address[] memory);

    function getPoolExecutor() external view returns (address[] memory);

    function setCompanyInfo(
        uint256 _jurisdiction,
        uint256 _entityType,
        string memory _ein,
        string memory _dateOfIncorporation,
        string memory _OAuri
    ) external;

    function castVote(uint256 proposalId, bool support) external;

    function executeProposal(uint256 proposalId) external;

    function getCompanyFee() external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlEnumerableUpgradeable.sol";
import "./ITGE.sol";
import "./ICustomProposal.sol";
import "./registry/IRecordsRegistry.sol";
import "./registry/ICompaniesRegistry.sol";
import "./registry/IRegistry.sol";
import "./IToken.sol";
import "./IInvoice.sol";
import "./IVesting.sol";
import "./ITokenFactory.sol";
import "./ITGEFactory.sol";
import "./IPool.sol";
import "./governor/IGovernanceSettings.sol";

interface IService is IAccessControlEnumerableUpgradeable {
    function ADMIN_ROLE() external view returns (bytes32);

    function WHITELISTED_USER_ROLE() external view returns (bytes32);

    function SERVICE_MANAGER_ROLE() external view returns (bytes32);

    function EXECUTOR_ROLE() external view returns (bytes32);

    function createPool(
        IRegistry.CompanyInfo memory companyInfo
    ) external returns(address);

    function addProposal(uint256 proposalId) external;

    function addEvent(
        IRecordsRegistry.EventType eventType,
        uint256 proposalId,
        string calldata metaHash
    ) external;

    function setProtocolCollectedFee(
        address _token,
        uint256 _protocolTokenFee
    ) external;

    function registry() external view returns (IRegistry);

    function vesting() external view returns (IVesting);

    function tokenFactory() external view returns (ITokenFactory);

    function tgeFactory() external view returns (ITGEFactory);

    function invoice() external view returns (IInvoice);

    function protocolTreasury() external view returns (address);

    function protocolTokenFee() external view returns (uint256);

    function getMinSoftCap() external view returns (uint256);

    function getProtocolTokenFee(
        uint256 amount
    ) external view returns (uint256);

    function getProtocolCollectedFee(
        address token_
    ) external view returns (uint256);

    function poolBeacon() external view returns (address);

    function tgeBeacon() external view returns (address);

    function tokenBeacon() external view returns (address);

    function tokenERC1155Beacon() external view returns (address);

    function customProposal() external view returns (ICustomProposal);

    function validateTGEInfo(
        ITGE.TGEInfo calldata info,
        uint256 cap,
        uint256 totalSupply,
        IToken.TokenType tokenType
    ) external view;

    function getPoolAddress(
        ICompaniesRegistry.CompanyInfo memory info
    ) external view returns (address);

    function paused() external view returns (bool);

    function addInvoiceEvent(
        address pool,
        uint256 invoiceId
    ) external returns (uint256);

    function purchasePool(
        uint256 jurisdiction,
        uint256 entityType,
        string memory trademark,
        IGovernanceSettings.NewGovernanceSettings memory governanceSettings
    ) external payable;

    function transferPurchasedPoolByService(
        address newowner,
        uint256 jurisdiction,
        uint256 entityType,
        string memory trademark,
        IGovernanceSettings.NewGovernanceSettings memory governanceSettings
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IToken.sol";
import "./ITokenERC1155.sol";
import "./IVesting.sol";

interface ITGE {
    /**
    * @notice This structure defines comprehensive TGE settings, including Vesting, Lockup, and distribution rules for these tokens.
    * @dev Initially, such a structure appears as a parameter when creating a proposal in CustomProposal, after which the data from the structure is placed in the storage of the deployed TGE contract.
    * @dev In addition, these data are used as an argument in its original form in the TGEFactory contract, including when creating the initial TGE by the pool owner without a proposal.
    * @param price The price of one token in the smallest unitOfAccount (1 wei when defining the price in ETH, 0.000001 USDT when defining the price in USDT, etc.)
    * @param hardcap The maximum number of tokens that can be sold (note the ProtocolTokenFee for Governance Tokens)
    * @param softcap The minimum number of tokens that buyers must acquire for the TGE to be considered successful
    * @param minPurchase The minimum number of tokens that can be purchased by a single account (minimum one-time purchase)
    * @param maxPurchase The maximum number of tokens that can be purchased by a single account in total during the launched TGE 
    * @param duration The duration of the event in blocks, after which the TGE status will be forcibly changed from Active to another
    * @param vestingParams Vesting settings for tokens acquired during this TGE
    * @param userWhiteList A list of addresses allowed to participate in this TGE. Leave the list empty to make the TGE public.
    * @param unitOfAccount The address of the ERC20 or compatible token contract, in the smallest units of which the price of one token is determined
    * @param lockupDuration The duration of token lockup (in blocks), one of two independent lockup conditions.
    * @param lockupTVL The minimum total pool balance in USD, one of two independent lockup conditions.
    */

    struct TGEInfo {
        uint256 price;
        uint256 hardcap;
        uint256 softcap;
        uint256 minPurchase;
        uint256 maxPurchase;
        uint256 duration;
        IVesting.VestingParams vestingParams;
        address[] userWhitelist;
        address unitOfAccount;
        uint256 lockupDuration;
        uint256 lockupTVL;
    }

    function initialize(
        address _service,
        address _token,
        uint256 _tokenId,
        string memory _uri,
        TGEInfo calldata _info,
        uint256 _protocolFee
    ) external;

    enum State {
        Active,
        Failed,
        Successful
    }

    function token() external view returns (address);

    function tokenId() external view returns (uint256);

    function state() external view returns (State);

    function getInfo() external view returns (TGEInfo memory);

    function transferUnlocked() external view returns (bool);

    function purchaseOf(address user) external view returns (uint256);

    function redeemableBalanceOf(address user) external view returns (uint256);

    function lockedBalanceOf(address account) external view returns (uint256);

    function getEnd() external view returns (uint256);

    function totalPurchased() external view returns (uint256);

    function isERC1155TGE() external view returns (bool);

    function purchase(uint256 amount) external payable;

    function transferFunds() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./ITGE.sol";
import "./IToken.sol";
import "./governor/IGovernanceSettings.sol";

interface ITGEFactory {
    function createSecondaryTGE(
        address token,
        ITGE.TGEInfo calldata tgeInfo,
        IToken.TokenInfo calldata tokenInfo,
        string memory metadataURI
    ) external;

    function createSecondaryTGEERC1155(
        address token,
        uint256 tokenId,
        string memory uri,
        ITGE.TGEInfo calldata tgeInfo,
        IToken.TokenInfo calldata tokenInfo,
        string memory metadataURI
    ) external;

    function createPrimaryTGE(
        address poolAddress,
        IToken.TokenInfo memory tokenInfo,
        ITGE.TGEInfo memory tgeInfo,
        string memory metadataURI,
        IGovernanceSettings.NewGovernanceSettings memory governanceSettings_,
        address[] memory secretary,
        address[] memory executor
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/utils/IVotesUpgradeable.sol";
import "./IService.sol";

interface IToken is IVotesUpgradeable, IERC20Upgradeable {
    /**
    * @notice This structure is used to define the parameters of ERC20 tokens issued by the protocol for pools.
    * @dev This structure is suitable for both Governance and Preference tokens if they are based on ERC20.
    * @param tokenType Numeric code for the token type
    * @param name Full name of the token
    * @param symbol Ticker symbol (short name) of the token
    * @param description Description of the token
    * @param cap Maximum allowable token issuance
    * @param decimals Number of decimal places for the token (precision)
    */
    struct TokenInfo {
        TokenType tokenType;
        string name;
        string symbol;
        string description;
        uint256 cap;
        uint8 decimals;
    }
    /**
    * @notice Token type encoding
    */
    enum TokenType {
        None,
        Governance,
        Preference
    }

    function initialize(
        IService service_,
        address pool_,
        TokenInfo memory info,
        address primaryTGE_
    ) external;

    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function cap() external view returns (uint256);

    function unlockedBalanceOf(address account) external view returns (uint256);

    function pool() external view returns (address);

    function service() external view returns (IService);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function tokenType() external view returns (TokenType);

    function lastTGE() external view returns (address);

    function getTGEList() external view returns (address[] memory);

    function isPrimaryTGESuccessful() external view returns (bool);

    function addTGE(address tge) external;

    function setTGEVestedTokens(uint256 amount) external;

    function setProtocolFeeReserved(uint256 amount) external;

    function getTotalTGEVestedTokens() external view returns (uint256);

    function getTotalProtocolFeeReserved() external view returns (uint256);

    function totalSupplyWithReserves() external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function delegate(
        address delegatee
    ) external; 
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "./IService.sol";
import "./IToken.sol";

interface ITokenERC1155 is IERC1155Upgradeable {
    function initialize(
        IService service_,
        address pool_,
        IToken.TokenInfo memory info,
        address primaryTGE_
    ) external;

    function mint(address to, uint256 tokenId, uint256 amount) external;

    function burn(address from, uint256 tokenId, uint256 amount) external;

    function cap(uint256 tokenId) external view returns (uint256);

    function unlockedBalanceOf(
        address account,
        uint256 tokenId
    ) external view returns (uint256);

    function pool() external view returns (address);

    function service() external view returns (IService);

    function decimals() external view returns (uint8);

    function lastTokenId() external view returns (uint256);

    function symbol() external view returns (string memory);

    function tokenType() external view returns (IToken.TokenType);

    function lastTGE(uint256 tokenId) external view returns (address);

    function getTGEList(
        uint256 tokenId
    ) external view returns (address[] memory);

    function isPrimaryTGESuccessful(
        uint256 tokenId
    ) external view returns (bool);

    function addTGE(address tge, uint256 tokenId) external;

    function setTGEVestedTokens(uint256 amount, uint256 tokenId) external;

    function setProtocolFeeReserved(uint256 amount, uint256 tokenId) external;

    function getTotalTGEVestedTokens(
        uint256 tokenId
    ) external view returns (uint256);

    function getTotalProtocolFeeReserved(
        uint256 tokenId
    ) external view returns (uint256);

    function totalSupplyWithReserves(
        uint256 tokenId
    ) external view returns (uint256);

    function setURI(uint256 tokenId, string memory tokenURI) external;

    function setTokenIdCap(uint256 _tokenId, uint256 _cap) external;

    function transfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) external;

    function setLastTokenId(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IToken.sol";
import "./ITokenERC1155.sol";

interface ITokenFactory {
    function createToken(
        address pool,
        IToken.TokenInfo memory info,
        address primaryTGE
    ) external returns (address token);

    function createTokenERC1155(
        address pool,
        IToken.TokenInfo memory info,
        address primaryTGE
    ) external returns (address token);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IVesting {
    /**
     * @notice This interface describes a vesting program for tokens distributed within a specific TGE.
     * @dev Such data is stored in the TGE contracts in the TGEInfo public info.
     * @param vestedShare The percentage of tokens that participate in the vesting program (not distributed until conditions are met)
     * @param cliff Cliff period (in blocks)
     * @param cliffShare The portion of tokens that are distributed
     * @param spans The number of periods for distributing the remaining tokens in vesting in equal shares
     * @param spanDuration The duration of one such period (in blocks)
     * @param spanShare The percentage of the total number of tokens in vesting that corresponds to one such period
     * @param claimTVL The minimum required TVL of the pool after which it will be possible to claim tokens from vesting. Optional parameter (0 if this condition is not needed)
     * @param resolvers A list of addresses that can cancel the vesting program for any address from the TGE participants list
     */
    struct VestingParams {
        uint256 vestedShare;
        uint256 cliff;
        uint256 cliffShare;
        uint256 spans;
        uint256 spanDuration;
        uint256 spanShare;
        uint256 claimTVL;
        address[] resolvers;
    }

    function vest(address to, uint256 amount) external;

    function cancel(address tge, address account) external;

    function validateParams(
        VestingParams memory params
    ) external pure returns (bool);

    function vested(
        address tge,
        address account
    ) external view returns (uint256);

    function totalVested(address tge) external view returns (uint256);

    function vestedBalanceOf(
        address tge,
        address account
    ) external view returns (uint256);

    function claim(address tge) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IGovernanceSettings {
    /**
     * @notice This structure specifies and stores the Governance settings for each individual pool.
     * @dev More information on the thresholds (proposal, quorum, decision) and creating proposals can be found in the "Other Entities" section.
     * @param proposalThreshold_ The proposal threshold (specified in token units with decimals taken into account)
     * @param quorumThreshold_ The quorum threshold (specified as a percentage)
     * @param decisionThreshold_ The decision threshold (specified as a percentage)
     * @param votingDuration_ The duration of the voting period (specified in blocks)
     * @param transferValueForDelay_ The minimum amount in USD for which a transfer from the pool wallet will be subject to a del
     * @param executionDelays_ List of execution delays specified in blocks for different types of proposals
     * @param votingStartDelay The delay before voting starts for newly created proposals, specified in blocks
     */
    struct NewGovernanceSettings {
        uint256 proposalThreshold;
        uint256 quorumThreshold;
        uint256 decisionThreshold;
        uint256 votingDuration;
        uint256 transferValueForDelay;
        uint256[4] executionDelays;
        uint256 votingStartDelay;
    }

    function setGovernanceSettings(
        NewGovernanceSettings memory settings
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../../interfaces/registry/IRecordsRegistry.sol";

interface IGovernor {
    /**
     * @notice Struct with proposal core data
     * @dev This interface specifies the Governance settings that existed in the pool at the time of proposal creation, as well as the service data (to which addresses and with what messages and amounts of ETH should be sent) of the scenario that should be executed in case of a positive voting outcome.
     * @param targets A list of addresses to be called in case of a positive voting outcome
     * @param values The amounts of wei to be sent to the addresses from targets
     * @param callDatas The 'calldata' messages to be attached to transactions
     * @param quorumThreshold The quorum, expressed as a percentage with DENOM taken into account
     * @param decisionThreshold The decision-making threshold, expressed as a percentage with DENOM taken into account
     * @param executionDelay The number of blocks that must pass since the creation of the proposal for it to be considered launched
     */
    struct ProposalCoreData {
        address[] targets;
        uint256[] values;
        bytes[] callDatas;
        uint256 quorumThreshold;
        uint256 decisionThreshold;
        uint256 executionDelay;
    }

    /**
     * @notice This interface specifies information about the subject of the voting, intended for human perception.
     * @dev Struct with proposal metadata
     * @param proposalType The digital code of the proposal type
     * @param description The public description of the proposal
     * @param metaHash The identifier of the private proposal description stored on the backend
     */
    struct ProposalMetaData {
        IRecordsRegistry.EventType proposalType;
        string description;
        string metaHash;
    }

    function proposalState(uint256 proposalId)
        external
        view
        returns (uint256 state);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../IService.sol";

interface IGovernorProposals {
    function service() external view returns (IService);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../ITGE.sol";
import "../IToken.sol";

interface ICompaniesRegistry {
    /**
    * @notice This is how immutable data about companies is stored
    * @dev For companies listed for sale, this data is stored in the Registry in mapping(uint256 => CompanyInfo) public companies. Additionally, this data is duplicated in the Pool contract in IRegistry.CompanyInfo public companyInfo.
    * @param jurisdiction Numeric code for the jurisdiction (region where the company is registered)
    * @param entityType Numeric code for the type of organization
    * @param ein Unique registration number (uniqueness is checked within a single jurisdiction)
    * @param dateOfIncorporation Date of company registration (in the format provided by the jurisdiction)
    * @param fee Fost of the company in wei ETH
    */ 
    struct CompanyInfo {
        uint256 jurisdiction;
        uint256 entityType;
        string ein;
        string dateOfIncorporation;
        uint256 fee;
    }

    function lockCompany(
        uint256 jurisdiction,
        uint256 entityType
    ) external returns (CompanyInfo memory);

    function createCompany(
        CompanyInfo calldata info
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IRecordsRegistry {
    /**
     * @notice In the section of the Registry contract that contains records of the type of deployed user contract, the following numeric encoding of contract types is used.
     * @dev TGE is both a type of user contract and an event for which the contract was deployed.
     **/
    enum ContractType {
        None,
        Pool,
        GovernanceToken,
        PreferenceToken,
        TGE
    }
    /**
     * @notice Encoding of the registered event type
     */
    enum EventType {
        None,
        Transfer,
        TGE,
        GovernanceSettings
    }

    /**
     * @notice This structure is used for contracts storing in the CompanyDAO ecosystem.
     * @dev The Registry contract stores data about deployed user contracts in `ContractInfo[] public contractRecords`, where records receive a sequential and pool-independent numbering.
     * @param addr Deployed contract address
     * @param contractType Digital code of contract type
     * @param description Contract description
     */
    struct ContractInfo {
        address addr;
        ContractType contractType;
        string description;
    }

    /**
     * @notice Using this data, you can refer to the contract of a specific pool to get more detailed information about the proposal.
     * @dev The Registry contract stores data about proposals launched by users in `ProposalInfo[] public proposalRecords`, where records receive a sequential and pool-independent numbering.
     * @param pool Pool contract in which the proposal was launched
     * @param proposalId Internal proposal identifier for the pool
     * @param description Proposal description
     */
    struct ProposalInfo {
        address pool;
        uint256 proposalId;
        string description;
    }

    /**
     * @dev The Registry contract stores data about all events that have taken place in `Event[] public events`, where records receive a sequential and pool-independent numbering.
     * @param eventType Code of event type
     * @param pool Address of the pool to which this event relates
     * @param eventContract Address of the event contract, if the event type implies the deployment of a separate contract
     * @param proposalId Internal proposal identifier for the pool, the execution of which led to the launch of this event
     * @param metaHash Hash identifier of the private description stored on the backend
     */
    struct Event {
        EventType eventType;
        address pool;
        address eventContract;
        uint256 proposalId;
        string metaHash;
    }

    function addContractRecord(
        address addr,
        ContractType contractType,
        string memory description
    ) external returns (uint256 index);

    function addProposalRecord(
        address pool,
        uint256 proposalId
    ) external returns (uint256 index);

    function addEventRecord(
        address pool,
        EventType eventType,
        address eventContract,
        uint256 proposalId,
        string calldata metaHash
    ) external returns (uint256 index);

    function typeOf(address addr) external view returns (ContractType);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./ICompaniesRegistry.sol";
import "./ITokensRegistry.sol";
import "./IRecordsRegistry.sol";
import "../IService.sol";

interface IRegistry is ITokensRegistry, ICompaniesRegistry, IRecordsRegistry {
    function service() external view returns (IService);

    function COMPANIES_MANAGER_ROLE() external view returns (bytes32);

    function hasRole(
        bytes32 role,
        address account
    ) external view returns (bool);

    function log(
        address sender,
        address receiver,
        uint256 value,
        bytes memory data
    ) external;

    function getPoolAddressByIndex(uint256 index) external view returns (address);

    function getAvailableCompanyAddress(
        uint256 jurisdiction,
        uint256 entityType
    ) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface ITokensRegistry {
    function isTokenWhitelisted(address token) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

library ExceptionsLibrary {
    string public constant ADDRESS_ZERO = "ADDRESS_ZERO";
    string public constant INCORRECT_ETH_PASSED = "INCORRECT_ETH_PASSED";
    string public constant NO_COMPANY = "NO_COMPANY";
    string public constant INVALID_TOKEN = "INVALID_TOKEN";
    string public constant NOT_POOL = "NOT_POOL";
    string public constant NOT_TGE = "NOT_TGE";
    string public constant NOT_Registry = "NOT_Registry";
    string public constant NOT_POOL_OWNER = "NOT_POOL_OWNER";
    string public constant NOT_SERVICE_OWNER = "NOT_SERVICE_OWNER";
    string public constant IS_DAO = "IS_DAO";
    string public constant NOT_DAO = "NOT_DAO";
    string public constant NOT_WHITELISTED = "NOT_WHITELISTED";
    string public constant NOT_SERVICE = "NOT_SERVICE";
    string public constant WRONG_STATE = "WRONG_STATE";
    string public constant TRANSFER_FAILED = "TRANSFER_FAILED";
    string public constant CLAIM_NOT_AVAILABLE = "CLAIM_NOT_AVAILABLE";
    string public constant NO_LOCKED_BALANCE = "NO_LOCKED_BALANCE";
    string public constant LOCKUP_TVL_REACHED = "LOCKUP_TVL_REACHED";
    string public constant HARDCAP_OVERFLOW = "HARDCAP_OVERFLOW";
    string public constant MAX_PURCHASE_OVERFLOW = "MAX_PURCHASE_OVERFLOW";
    string public constant HARDCAP_OVERFLOW_REMAINING_SUPPLY =
        "HARDCAP_OVERFLOW_REMAINING_SUPPLY";
    string public constant HARDCAP_AND_PROTOCOL_FEE_OVERFLOW_REMAINING_SUPPLY =
        "HARDCAP_AND_PROTOCOL_FEE_OVERFLOW_REMAINING_SUPPLY";
    string public constant MIN_PURCHASE_UNDERFLOW = "MIN_PURCHASE_UNDERFLOW";
    string public constant LOW_UNLOCKED_BALANCE = "LOW_UNLOCKED_BALANCE";
    string public constant ZERO_PURCHASE_AMOUNT = "ZERO_PURCHASE_AMOUNTs";
    string public constant NOTHING_TO_REDEEM = "NOTHING_TO_REDEEM";
    string public constant RECORD_IN_USE = "RECORD_IN_USE";
    string public constant INVALID_EIN = "INVALID_EIN";
    string public constant VALUE_ZERO = "VALUE_ZERO";
    string public constant ALREADY_SET = "ALREADY_SET";
    string public constant VOTING_FINISHED = "VOTING_FINISHED";
    string public constant ALREADY_EXECUTED = "ALREADY_EXECUTED";
    string public constant ACTIVE_TGE_EXISTS = "ACTIVE_TGE_EXISTS";
    string public constant INVALID_VALUE = "INVALID_VALUE";
    string public constant INVALID_CAP = "INVALID_CAP";
    string public constant INVALID_HARDCAP = "INVALID_HARDCAP";
    string public constant ONLY_POOL = "ONLY_POOL";
    string public constant ETH_TRANSFER_FAIL = "ETH_TRANSFER_FAIL";
    string public constant TOKEN_TRANSFER_FAIL = "TOKEN_TRANSFER_FAIL";
    string public constant SERVICE_PAUSED = "SERVICE_PAUSED";
    string public constant INVALID_PROPOSAL_TYPE = "INVALID_PROPOSAL_TYPE";
    string public constant EXECUTION_FAILED = "EXECUTION_FAILED";
    string public constant INVALID_USER = "INVALID_USER";
    string public constant NOT_LAUNCHED = "NOT_LAUNCHED";
    string public constant LAUNCHED = "LAUNCHED";
    string public constant VESTING_TVL_REACHED = "VESTING_TVL_REACHED";
    string public constant WRONG_TOKEN_ADDRESS = "WRONG_TOKEN_ADDRESS";
    string public constant GOVERNANCE_TOKEN_EXISTS = "GOVERNANCE_TOKEN_EXISTS";
    string public constant THRESHOLD_NOT_REACHED = "THRESHOLD_NOT_REACHED";
    string public constant UNSUPPORTED_TOKEN_TYPE = "UNSUPPORTED_TOKEN_TYPE";
    string public constant ALREADY_VOTED = "ALREADY_VOTED";
    string public constant ZERO_VOTES = "ZERO_VOTES";
    string public constant ACTIVE_GOVERNANCE_SETTINGS_PROPOSAL_EXISTS =
        "ACTIVE_GOVERNANCE_SETTINGS_PROPOSAL_EXISTS";
    string public constant EMPTY_ADDRESS = "EMPTY_ADDRESS";
    string public constant NOT_VALID_PROPOSER = "NOT_VALID_PROPOSER";
    string public constant SHARES_SUM_EXCEEDS_ONE = "SHARES_SUM_EXCEEDS_ONE";
    string public constant NOT_RESOLVER = "NOT_RESOLVER";
    string public constant NOT_REGISTRY = "NOT_REGISTRY";
    string public constant INVALID_TARGET = "INVALID_TARGET";
    string public constant NOT_TGE_FACTORY = "NOT_TGE_FACTORY";
    string public constant WRONG_AMOUNT = "WRONG_AMOUNT";
    string public constant WRONG_BLOCK_NUMBER = "WRONG_BLOCK_NUMBER";
    string public constant NOT_VALID_EXECUTOR = "NOT_VALID_EXECUTOR";
    string public constant POOL_PAUSED = "POOL_PAUSED";
    string public constant NOT_INVOICE_MANAGER = "NOT_INVOICE_MANAGER";
    string public constant WRONG_RESOLVER = "WRONG_RESOLVER";
    string public constant INVALID_PURCHASE_AMOUNT = "INVALID_PURCHASE_AMOUNT";
}