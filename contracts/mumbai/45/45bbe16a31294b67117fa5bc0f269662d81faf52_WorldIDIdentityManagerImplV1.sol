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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
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
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2StepUpgradeable is Initializable, OwnableUpgradeable {
    function __Ownable2Step_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable2Step_init_unchained() internal onlyInitializing {
    }
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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

// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// The following Pairing library is a modified version adapted to Semaphore.
//
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Pairing {
    error InvalidProof();

    // The prime q in the base field F_q for G1
    uint256 constant BASE_MODULUS = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    // The prime moludus of the scalar field of G1.
    uint256 constant SCALAR_MODULUS = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

    struct G1Point {
        uint256 X;
        uint256 Y;
    }

    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint256[2] X;
        uint256[2] Y;
    }

    /// @return the generator of G1
    function P1() public pure returns (G1Point memory) {
        return G1Point(1, 2);
    }

    /// @return the generator of G2
    function P2() public pure returns (G2Point memory) {
        return
            G2Point(
                [
                    11559732032986387107991004021392285783925812861821192530917403151452391805634,
                    10857046999023057135944570762232829481370756359578518086990519993285655852781
                ],
                [
                    4082367875863433681332203403145435568316851327593401208105741076214120093531,
                    8495653923123431417604973247489272438418190587263600148770280649306958101930
                ]
            );
    }

    /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) public pure returns (G1Point memory r) {
        if (p.X == 0 && p.Y == 0) {
            return G1Point(0, 0);
        }

        // Validate input or revert
        if (p.X >= BASE_MODULUS || p.Y >= BASE_MODULUS) {
            revert InvalidProof();
        }

        // We know p.Y > 0 and p.Y < BASE_MODULUS.
        return G1Point(p.X, BASE_MODULUS - p.Y);
    }

    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) public view returns (G1Point memory r) {
        // By EIP-196 all input is validated to be less than the BASE_MODULUS and form points
        // on the curve.
        uint256[4] memory input;

        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;

        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
        }

        if (!success) {
            revert InvalidProof();
        }
    }

    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint256 s) public view returns (G1Point memory r) {
        // By EIP-196 the values p.X and p.Y are verified to less than the BASE_MODULUS and
        // form a valid point on the curve. But the scalar is not verified, so we do that explicitelly.
        if (s >= SCALAR_MODULUS) {
            revert InvalidProof();
        }

        uint256[3] memory input;

        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;

        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
        }

        if (!success) {
            revert InvalidProof();
        }
    }

    /// Asserts the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should succeed
    function pairingCheck(G1Point[] memory p1, G2Point[] memory p2) public view {
        // By EIP-197 all input is verified to be less than the BASE_MODULUS and form elements in their
        // respective groups of the right order.
        if (p1.length != p2.length) {
            revert InvalidProof();
        }

        uint256 elements = p1.length;
        uint256 inputSize = elements * 6;
        uint256[] memory input = new uint256[](inputSize);

        for (uint256 i = 0; i < elements; i++) {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }

        uint256[1] memory out;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
        }

        if (!success || out[0] != 1) {
            revert InvalidProof();
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../base/Pairing.sol";

/// @title SemaphoreVerifier contract interface.
interface ISemaphoreVerifier {
    struct VerificationKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[] IC;
    }

    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }

    /// @dev Verifies whether a Semaphore proof is valid.
    /// @param merkleTreeRoot: Root of the Merkle tree.
    /// @param nullifierHash: Nullifier hash.
    /// @param signal: Semaphore signal.
    /// @param externalNullifier: External nullifier.
    /// @param proof: Zero-knowledge proof.
    /// @param merkleTreeDepth: Depth of the tree.
    function verifyProof(
        uint256 merkleTreeRoot,
        uint256 nullifierHash,
        uint256 signal,
        uint256 externalNullifier,
        uint256[8] calldata proof,
        uint256 merkleTreeDepth
    ) external view;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {WorldIDImpl} from "./abstract/WorldIDImpl.sol";

import {IWorldID} from "./interfaces/IWorldID.sol";
import {ITreeVerifier} from "./interfaces/ITreeVerifier.sol";
import {ISemaphoreVerifier} from "semaphore/interfaces/ISemaphoreVerifier.sol";
import {IBridge} from "./interfaces/IBridge.sol";

import {SemaphoreTreeDepthValidator} from "./utils/SemaphoreTreeDepthValidator.sol";
import {VerifierLookupTable} from "./data/VerifierLookupTable.sol";

/// @title WorldID Identity Manager Implementation Version 1
/// @author Worldcoin
/// @notice An implementation of a batch-based identity manager for the WorldID protocol.
/// @dev The manager is based on the principle of verifying externally-created Zero Knowledge Proofs
///      to perform the insertions.
/// @dev This is the implementation delegated to by a proxy.
contract WorldIDIdentityManagerImplV1 is WorldIDImpl, IWorldID {
    ///////////////////////////////////////////////////////////////////////////////
    ///                   A NOTE ON IMPLEMENTATION CONTRACTS                    ///
    ///////////////////////////////////////////////////////////////////////////////

    // This contract is designed explicitly to operate from behind a proxy contract. As a result,
    // there are a few important implementation considerations:
    //
    // - All updates made after deploying a given version of the implementation should inherit from
    //   the latest version of the implementation. This prevents storage clashes.
    // - All functions that are less access-restricted than `private` should be marked `virtual` in
    //   order to enable the fixing of bugs in the existing interface.
    // - Any function that reads from or modifies state (i.e. is not marked `pure`) must be
    //   annotated with the `onlyProxy` and `onlyInitialized` modifiers. This ensures that it can
    //   only be called when it has access to the data in the proxy, otherwise results are likely to
    //   be nonsensical.
    // - This contract deals with important data for the WorldID system. Ensure that all newly-added
    //   functionality is carefully access controlled using `onlyOwner`, or a more granular access
    //   mechanism.
    // - Do not assign any contract-level variables at the definition site unless they are
    //   `constant`.
    //
    // Additionally, the following notes apply:
    //
    // - Initialisation and ownership management are not protected behind `onlyProxy` intentionally.
    //   This ensures that the contract can safely be disposed of after it is no longer used.
    // - Carefully consider what data recovery options are presented as new functionality is added.
    //   Care must be taken to ensure that a migration plan can exist for cases where upgrades
    //   cannot recover from an issue or vulnerability.

    ///////////////////////////////////////////////////////////////////////////////
    ///                    !!!!! DATA: DO NOT REORDER !!!!!                     ///
    ///////////////////////////////////////////////////////////////////////////////

    // To ensure compatibility between upgrades, it is exceedingly important that no reordering of
    // these variables takes place. If reordering happens, a storage clash will occur (effectively a
    // memory safety error).

    /// @notice The address of the contract authorized to perform identity management operations.
    /// @dev The identity operator defaults to being the same as the owner.
    address internal _identityOperator;

    /// @notice The latest root of the identity merkle tree.
    uint256 internal _latestRoot;

    /// @notice A mapping from the value of the merkle tree root to the timestamp at which the root
    ///         was superseded by a newer one.
    mapping(uint256 => uint128) internal rootHistory;

    /// @notice The amount of time an outdated root is considered as valid.
    /// @dev This prevents proofs getting invalidated in the mempool by another tx modifying the
    ///      group.
    uint256 internal rootHistoryExpiry;

    /// @notice Represents the initial leaf in an empty merkle tree.
    /// @dev Prevents the empty leaf from being inserted into the root history.
    uint256 internal constant EMPTY_LEAF = uint256(0);

    /// @notice The `r` for the finite field `Fr` under which arithmetic is done on the proof input.
    /// @dev Used internally to ensure that the proof input is scaled to within the field `Fr`.
    uint256 internal constant SNARK_SCALAR_FIELD =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    /// @notice The table of verifiers for verifying batch identity insertions.
    VerifierLookupTable internal batchInsertionVerifiers;

    /// @notice The table of verifiers for verifying batch identity insertions.
    VerifierLookupTable internal identityUpdateVerifiers;

    /// @notice The verifier instance needed for operating within the semaphore protocol.
    ISemaphoreVerifier internal semaphoreVerifier;

    /// @notice The interface of the bridge contract from L1 to supported target chains.
    IBridge internal _stateBridge;

    /// @notice Boolean flag to enable/disable the state bridge.
    bool internal _isStateBridgeEnabled;

    /// @notice The depth of the Semaphore merkle tree.
    uint8 internal treeDepth;

    ///////////////////////////////////////////////////////////////////////////////
    ///                               PUBLIC TYPES                              ///
    ///////////////////////////////////////////////////////////////////////////////

    /// @notice Provides information about a merkle tree root.
    ///
    /// @param root The value of the merkle tree root.
    /// @param supersededTimestamp The timestamp at which the root was inserted into the history.
    ///        This may be 0 if the requested root is the current root (which has not yet been
    ///        inserted into the history).
    /// @param isValid Whether or not the root is valid (has not expired).
    struct RootInfo {
        uint256 root;
        uint128 supersededTimestamp;
        bool isValid;
    }

    /// @notice Represents the kind of element that has not been provided in reduced form.
    enum UnreducedElementType {
        PreRoot,
        IdentityCommitment,
        PostRoot
    }

    /// @notice Represents the kind of change that is made to the root of the tree.
    enum TreeChange {
        Insertion,
        Update
    }

    /// @notice Represents the kinds of dependencies that can be updated.
    enum Dependency {
        StateBridge,
        InsertionVerifierLookupTable,
        UpdateVerifierLookupTable,
        SemaphoreVerifier
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                             CONSTANT FUNCTIONS                          ///
    ///////////////////////////////////////////////////////////////////////////////

    /// @notice A constant representing a root that doesn't exist.
    /// @dev Can be checked against when querying for root data.
    function NO_SUCH_ROOT() public pure returns (RootInfo memory rootInfo) {
        return RootInfo(0x0, 0x0, false);
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                                  ERRORS                                 ///
    ///////////////////////////////////////////////////////////////////////////////

    /// @notice Thrown when encountering an element that should be reduced as a member of `Fr` but
    ///         is not.
    /// @dev `r` in this case is given by `SNARK_SCALAR_FIELD`.
    ///
    /// @param elementType The kind of element that was encountered unreduced.
    /// @param element The value of that element.
    error UnreducedElement(UnreducedElementType elementType, uint256 element);

    /// @notice Thrown when trying to execute a privileged action without being the contract
    ///         manager.
    ///
    /// @param user The user that attempted the action that they were not authorised for.
    error Unauthorized(address user);

    /// @notice Thrown when one or more of the identity commitments to be inserted is invalid.
    ///
    /// @param index The index in the array of identity commitments where the invalid commitment was
    ///        found.
    error InvalidCommitment(uint256 index);

    /// @notice Thrown when the provided proof cannot be verified for the accompanying inputs.
    error ProofValidationFailure();

    /// @notice Thrown when the provided root is not the very latest root.
    ///
    /// @param providedRoot The root that was provided as the `preRoot` for a transaction.
    /// @param latestRoot The actual latest root at the time of the transaction.
    error NotLatestRoot(uint256 providedRoot, uint256 latestRoot);

    /// @notice Thrown when attempting to enable the bridge when it is already enabled.
    error StateBridgeAlreadyEnabled();

    /// @notice Thrown when attempting to disable the bridge when it is already disabled.
    error StateBridgeAlreadyDisabled();

    /// @notice Thrown when attempting to set the state bridge address to the zero address.
    error InvalidStateBridgeAddress();

    /// @notice Thrown when Semaphore tree depth is not supported.
    ///
    /// @param depth Passed tree depth.
    error UnsupportedTreeDepth(uint8 depth);

    /// @notice Thrown when the inputs to `removeIdentities` or `updateIdentities` do not match in
    ///         length.
    error MismatchedInputLengths();

    ///////////////////////////////////////////////////////////////////////////////
    ///                                  EVENTS                                 ///
    ///////////////////////////////////////////////////////////////////////////////

    /// @notice Emitted when the current root of the tree is updated.
    ///
    /// @param preRoot The value of the tree's root before the update.
    /// @param kind Either "insertion" or "update", the kind of alteration that was made to the
    ///        tree.
    /// @param postRoot The value of the tree's root after the update.
    event TreeChanged(uint256 indexed preRoot, TreeChange indexed kind, uint256 indexed postRoot);

    /// @notice Emitted when a dependency's address is updated via an admin action.
    ///
    /// @param kind The kind of dependency that was updated.
    /// @param oldAddress The old address of that dependency.
    /// @param newAddress The new address of that dependency.
    event DependencyUpdated(
        Dependency indexed kind, address indexed oldAddress, address indexed newAddress
    );

    /// @notice Emitted when the state bridge is enabled or disabled.
    ///
    /// @param isEnabled Set to `true` if the event comes from the state bridge being enabled,
    ///        `false` otherwise.
    event StateBridgeStateChange(bool indexed isEnabled);

    /// @notice Emitted when the root history expiry time is changed.
    ///
    /// @param oldExpiryTime The expiry time prior to the change.
    /// @param newExpiryTime The expiry time after the change.
    event RootHistoryExpirySet(uint256 indexed oldExpiryTime, uint256 indexed newExpiryTime);

    /// @notice Emitted when the identity operator is changed.
    ///
    /// @param oldOperator The address of the old identity operator.
    /// @param newOperator The address of the new identity operator.
    event IdentityOperatorChanged(address indexed oldOperator, address indexed newOperator);

    /// @notice Emitter when the WorldIDIdentityManagerImpl is initialized.

    /// @param _treeDepth The depth of the MerkeTree
    /// @param initialRoot The initial value for the `latestRoot` in the contract. When deploying
    ///        this should be set to the root of the empty tree.
    /// @param _enableStateBridge Whether or not the state bridge should be enabled when
    ///        initialising the identity manager.
    /// @param __stateBridge The initial state bridge contract to use.
    event WorldIDIdentityManagerImplInitialized(
        uint8 _treeDepth, uint256 initialRoot, bool _enableStateBridge, IBridge __stateBridge
    );

    ///////////////////////////////////////////////////////////////////////////////
    ///                             INITIALIZATION                              ///
    ///////////////////////////////////////////////////////////////////////////////

    /// @notice Constructs the contract.
    constructor() {
        // When called in the constructor, this is called in the context of the implementation and
        // not the proxy. Calling this thereby ensures that the contract cannot be spuriously
        // initialized on its own.
        _disableInitializers();
    }

    /// @notice Initializes the contract.
    /// @dev Must be called exactly once.
    /// @dev This is marked `reinitializer()` to allow for updated initialisation steps when working
    ///      with upgrades based upon this contract. Be aware that there are only 256 (zero-indexed)
    ///      initialisations allowed, so decide carefully when to use them. Many cases can safely be
    ///      replaced by use of setters.
    /// @dev This function is explicitly not virtual as it does not make sense to override even when
    ///      upgrading. Create a separate initializer function instead.
    ///
    /// @param _treeDepth The depth of the MerkeTree
    /// @param initialRoot The initial value for the `latestRoot` in the contract. When deploying
    ///        this should be set to the root of the empty tree.
    /// @param _batchInsertionVerifiers The verifier lookup table for batch insertions.
    /// @param _batchUpdateVerifiers The verifier lookup table for batch updates.
    /// @param _semaphoreVerifier The verifier to use for semaphore protocol proofs.
    /// @param _enableStateBridge Whether or not the state bridge should be enabled when
    ///        initialising the identity manager.
    /// @param __stateBridge The initial state bridge contract to use.
    ///
    /// @custom:reverts string If called more than once at the same initialisation number.
    /// @custom:reverts UnsupportedTreeDepth If passed tree depth is not among defined values.
    function initialize(
        uint8 _treeDepth,
        uint256 initialRoot,
        VerifierLookupTable _batchInsertionVerifiers,
        VerifierLookupTable _batchUpdateVerifiers,
        ISemaphoreVerifier _semaphoreVerifier,
        bool _enableStateBridge,
        IBridge __stateBridge
    ) public reinitializer(1) {
        // First, ensure that all of the parent contracts are initialised.
        __delegateInit();

        if (!SemaphoreTreeDepthValidator.validate(_treeDepth)) {
            revert UnsupportedTreeDepth(_treeDepth);
        }

        // Now perform the init logic for this contract.
        treeDepth = _treeDepth;
        rootHistoryExpiry = 1 hours;
        _latestRoot = initialRoot;
        batchInsertionVerifiers = _batchInsertionVerifiers;
        identityUpdateVerifiers = _batchUpdateVerifiers;
        semaphoreVerifier = _semaphoreVerifier;
        _stateBridge = __stateBridge;
        _isStateBridgeEnabled = _enableStateBridge;
        _identityOperator = owner();

        // Say that the contract is initialized.
        __setInitialized();

        emit WorldIDIdentityManagerImplInitialized(
            _treeDepth, initialRoot, _enableStateBridge, __stateBridge
        );
    }

    /// @notice Responsible for initialising all of the supertypes of this contract.
    /// @dev Must be called exactly once.
    /// @dev When adding new superclasses, ensure that any initialization that they need to perform
    ///      is accounted for here.
    ///
    /// @custom:reverts string If called more than once.
    function __delegateInit() internal virtual onlyInitializing {
        __WorldIDImpl_init();
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                           IDENTITY MANAGEMENT                           ///
    ///////////////////////////////////////////////////////////////////////////////

    /// @notice Registers identities into the WorldID system.
    /// @dev Can only be called by the owner.
    /// @dev Registration is performed off-chain and verified on-chain via the `insertionProof`.
    ///      This saves gas and time over inserting identities one at a time.
    ///
    /// @param insertionProof The proof that given the conditions (`preRoot`, `startIndex` and
    ///        `identityCommitments`), insertion into the tree results in `postRoot`. Elements 0 and
    ///        1 are the `x` and `y` coordinates for `ar` respectively. Elements 2 and 3 are the `x`
    ///        coordinate for `bs`, and elements 4 and 5 are the `y` coordinate for `bs`. Elements 6
    ///        and 7 are the `x` and `y` coordinates for `krs`.
    /// @param preRoot The value for the root of the tree before the `identityCommitments` have been
    ////       inserted. Must be an element of the field `Kr`.
    /// @param startIndex The position in the tree at which the insertions were made.
    /// @param identityCommitments The identities that were inserted into the tree starting at
    ///        `startIndex` and `preRoot` to give `postRoot`. All of the commitments must be
    ///        elements of the field `Kr`.
    /// @param postRoot The root obtained after inserting all of `identityCommitments` into the tree
    ///        described by `preRoot`. Must be an element of the field `Kr`.
    ///
    /// @custom:reverts Unauthorized If the message sender is not authorised to add identities.
    /// @custom:reverts InvalidCommitment If one or more of the provided commitments is invalid.
    /// @custom:reverts NotLatestRoot If the provided `preRoot` is not the latest root.
    /// @custom:reverts ProofValidationFailure If `insertionProof` cannot be verified using the
    ///                 provided inputs.
    /// @custom:reverts UnreducedElement If any of the `preRoot`, `postRoot` and
    ///                 `identityCommitments` is not an element of the field `Kr`. It describes the
    ///                 type and value of the unreduced element.
    /// @custom:reverts VerifierLookupTable.NoSuchVerifier If the batch sizes doesn't match a known
    ///                 verifier.
    /// @custom:reverts VerifierLookupTable.BatchTooLarge If the batch size exceeds the maximum
    ///                 batch size.
    function registerIdentities(
        uint256[8] calldata insertionProof,
        uint256 preRoot,
        uint32 startIndex,
        uint256[] calldata identityCommitments,
        uint256 postRoot
    ) public virtual onlyProxy onlyInitialized onlyIdentityOperator {
        // We can only operate on the latest root in reduced form.
        if (!isInputInReducedForm(preRoot)) {
            revert UnreducedElement(UnreducedElementType.PreRoot, preRoot);
        }
        if (preRoot != _latestRoot) {
            revert NotLatestRoot(preRoot, _latestRoot);
        }

        // As the `startIndex` is restricted to a uint32, where
        // `type(uint32).max <<< SNARK_SCALAR_FIELD`, we are safe not to check this. As verified in
        // the tests, a revert happens if you pass a value larger than `type(uint32).max` when
        // calling outside the type-checker's protection.

        // We need the post root to be in reduced form.
        if (!isInputInReducedForm(postRoot)) {
            revert UnreducedElement(UnreducedElementType.PostRoot, postRoot);
        }

        // We can only operate on identities that are valid and in reduced form.
        validateIdentityCommitmentsForRegistration(identityCommitments);

        // Having validated the preconditions we can now check the proof itself.
        bytes32 inputHash = calculateIdentityRegistrationInputHash(
            startIndex, preRoot, postRoot, identityCommitments
        );

        // No matter what, the inputs can result in a hash that is not an element of the scalar
        // field in which we're operating. We reduce it into the field before handing it to the
        // verifier.
        uint256 reducedElement = reduceInputElementInSnarkScalarField(uint256(inputHash));

        // We need to look up the correct verifier before we can verify.
        ITreeVerifier insertionVerifier =
            batchInsertionVerifiers.getVerifierFor(identityCommitments.length);

        // With that, we can properly try and verify.
        try insertionVerifier.verifyProof(
            [insertionProof[0], insertionProof[1]],
            [[insertionProof[2], insertionProof[3]], [insertionProof[4], insertionProof[5]]],
            [insertionProof[6], insertionProof[7]],
            [reducedElement]
        ) returns (bool verifierResult) {
            // If the proof did not verify, we revert with a failure.
            if (!verifierResult) {
                revert ProofValidationFailure();
            }

            // If it did verify, we need to update the contract's state. We set the currently valid
            // root to the root after the insertions.
            _latestRoot = postRoot;

            // We also need to add the previous root to the history, and set the timestamp at
            // which it was expired.
            rootHistory[preRoot] = uint128(block.timestamp);

            // With the update confirmed, we send the root across multiple chains to ensure sync.
            sendRootToStateBridge();

            emit TreeChanged(preRoot, TreeChange.Insertion, postRoot);
        } catch Error(string memory errString) {
            /// This is not the revert we're looking for.
            revert(errString);
        } catch {
            // If we reach here we know it's the internal error, as the tree verifier only uses
            // `require`s otherwise, which will be re-thrown above.
            revert ProofValidationFailure();
        }
    }

    /// @notice Updates identities in the WorldID system.
    /// @dev Can only be called by the owner.
    /// @dev The update is performed off-chain and verified on-chain via the `updateProof`. This
    ///      saves gas and time over removing identities one at a time.
    /// @dev This function can perform arbitrary identity alterations and does not require any
    ///      preconditions on the inputs other than that the identities are in reduced form.
    ///
    /// @param updateProof The proof that, given the conditions (`preRoot`, `startIndex` and
    ///        `removedIdentities`), updates in the tree results in `postRoot`. Elements 0 and 1 are
    ///        the `x` and `y` coordinates for `ar` respectively. Elements 2 and 3 are the `x`
    ///        coordinate for `bs`, and elements 4 and 5 are the `y` coordinate for `bs`. Elements 6
    ///        and 7 are the `x` and `y` coordinates for `krs`.
    /// @param preRoot The value for the root of the tree before the `updatedIdentities` have been
    ////       altered. Must be an element of the field `Kr`.
    /// @param leafIndices The array of leaf indices at which the update operations take place in
    ///        the tree. Elements in this array are extended to 256 bits when encoding.
    /// @param oldIdentities The array of old values for the identities. Length must match that of
    ///        `leafIndices`.
    /// @param newIdentities The array of new values for the identities. Length must match that of
    ///        `leafIndices`.
    /// @param postRoot The root obtained after removing all of `removedIdentities` from the tree
    ///        described by `preRoot`. Must be an element of the field `Kr`.
    ///
    /// The arrays `leafIndices`, `oldIdentities` and `newIdentities` are arranged such that the
    /// triple at an element `i` in those arrays corresponds to one update operation.
    ///
    /// @custom:reverts Unauthorized If the message sender is not authorised to update identities.
    /// @custom:reverts NotLatestRoot If the provided `preRoot` is not the latest root.
    /// @custom:reverts MismatchedInputLengths If the provided arrays for `leafIndices`,
    ///                 `oldIdentities` and `newIdentities` do not match in length.
    /// @custom:reverts ProofValidationFailure If `removalProof` cannot be verified using the
    ///                 provided inputs.
    /// @custom:reverts UnreducedElement If any of the `preRoot`, `postRoot` and `identities` is not
    ///                 an element of the field `Kr`. It describes the type and value of the
    ///                 unreduced element.
    /// @custom:reverts NoSuchVerifier If the batch sizes doesn't match a known verifier.
    function updateIdentities(
        uint256[8] calldata updateProof,
        uint256 preRoot,
        uint32[] calldata leafIndices,
        uint256[] calldata oldIdentities,
        uint256[] calldata newIdentities,
        uint256 postRoot
    ) public virtual onlyProxy onlyInitialized onlyIdentityOperator {
        // We can only operate on the latest root in reduced form.
        if (!isInputInReducedForm(preRoot)) {
            revert UnreducedElement(UnreducedElementType.PreRoot, preRoot);
        }
        if (preRoot != _latestRoot) {
            revert NotLatestRoot(preRoot, _latestRoot);
        }

        // We also need the post root to be in reduced form.
        if (!isInputInReducedForm(postRoot)) {
            revert UnreducedElement(UnreducedElementType.PostRoot, postRoot);
        }

        // We also need the arrays to be of the same length.
        if (
            leafIndices.length != oldIdentities.length || leafIndices.length != newIdentities.length
        ) {
            revert MismatchedInputLengths();
        }

        // We only operate on identities that are in reduced form.
        validateIdentitiesForUpdate(oldIdentities, newIdentities);

        // With valid preconditions we can calculate the input to the proof.
        bytes32 inputHash = calculateIdentityUpdateInputHash(
            preRoot, postRoot, leafIndices, oldIdentities, newIdentities
        );

        // No matter what, the input hashing process can result in a hash that is not an element of
        // the field Fr. We reduce it into the field to give it safely to the verifier.
        uint256 reducedInputHash = reduceInputElementInSnarkScalarField(uint256(inputHash));

        // We have to look up the correct verifier before we can verify.
        ITreeVerifier updateVerifier = identityUpdateVerifiers.getVerifierFor(leafIndices.length);

        // Now we delegate to another function in order to avoid the limit on stack variables.
        performIdentityUpdate(updateVerifier, updateProof, reducedInputHash, preRoot, postRoot);
    }

    /// @notice Performs the verification of the identity update proof.
    /// @dev This function only exists because `updateIdentities` ended up with more than 16 local
    ///      variables, and hence ran into the limit on the EVM. It will be called as a direct call
    ///      and is hence relatively cheap.
    /// @dev Can only be called by the owner.
    /// @dev The update is performed off-chain and verified on-chain via the `updateProof`. This
    ///      saves gas and time over removing identities one at a time.
    /// @dev This function can perform arbitrary identity alterations and does not require any
    ///      preconditions on the inputs other than that the identities are in reduced form.
    ///
    /// @param updateVerifier The merkle tree verifier to use for updates of the correct batch size.
    /// @param updateProof The proof that, given the conditions (`preRoot`, `startIndex` and
    ///        `removedIdentities`), updates in the tree results in `postRoot`. Elements 0 and 1 are
    ///        the `x` and `y` coordinates for `ar` respectively. Elements 2 and 3 are the `x`
    ///        coordinate for `bs`, and elements 4 and 5 are the `y` coordinate for `bs`. Elements 6
    ///        and 7 are the `x` and `y` coordinates for `krs`.
    /// @param inputHash The input hash for the update operation.
    /// @param preRoot The value for the root of the tree before the `updatedIdentities` have been
    ////       altered. Must be an element of the field `Kr`.
    /// @param postRoot The root obtained after removing all of `removedIdentities` from the tree
    ///        described by `preRoot`. Must be an element of the field `Kr`.
    ///
    /// @custom:reverts ProofValidationFailure If `removalProof` cannot be verified using the
    ///                 provided inputs.
    function performIdentityUpdate(
        ITreeVerifier updateVerifier,
        uint256[8] calldata updateProof,
        uint256 inputHash,
        uint256 preRoot,
        uint256 postRoot
    ) internal virtual onlyProxy onlyInitialized onlyIdentityOperator {
        // Pull out the proof terms and verifier input.
        uint256[2] memory ar = [updateProof[0], updateProof[1]];
        uint256[2][2] memory bs =
            [[updateProof[2], updateProof[3]], [updateProof[4], updateProof[5]]];
        uint256[2] memory krs = [updateProof[6], updateProof[7]];
        uint256[1] memory proofInput = [inputHash];

        // Now it's possible to verify the proof.
        try updateVerifier.verifyProof(ar, bs, krs, proofInput) returns (bool verifierResult) {
            // If the proof did not verify, we revert with a failure.
            if (!verifierResult) {
                revert ProofValidationFailure();
            }

            // If it did verify, we need to update the contract's state. We set the currently valid
            // root to the root after the insertions.
            _latestRoot = postRoot;

            // We also need to add the previous root to the history, and set the timestamp at which
            // it was expired.
            rootHistory[preRoot] = uint128(block.timestamp);

            // With the update confirmed, we send the root across multiple chains to ensure sync.
            sendRootToStateBridge();

            emit TreeChanged(preRoot, TreeChange.Update, postRoot);
        } catch Error(string memory errString) {
            /// This is not the revert we're looking for.
            revert(errString);
        } catch {
            // If we reach here we know it's the internal error, as the tree verifier only uses
            // `require`s otherwise, which will be re-thrown above.
            revert ProofValidationFailure();
        }
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                             UTILITY FUNCTIONS                           ///
    ///////////////////////////////////////////////////////////////////////////////

    /// @notice Calculates the input hash for the identity registration verifier.
    /// @dev Implements the computation described below.
    ///
    /// @param startIndex The index in the tree from which inserting started.
    /// @param preRoot The root value of the tree before these insertions were made.
    /// @param postRoot The root value of the tree after these insertions were made.
    /// @param identityCommitments The identities that were added to the tree to produce `postRoot`.
    ///
    /// @return hash The input hash calculated as described below.
    ///
    /// We keccak hash all input to save verification gas. Inputs are arranged as follows:
    ///
    /// StartIndex || PreRoot || PostRoot || IdComms[0] || IdComms[1] || ... || IdComms[batchSize-1]
    ///     32	   ||   256   ||   256    ||    256     ||    256     || ... ||     256 bits
    function calculateIdentityRegistrationInputHash(
        uint32 startIndex,
        uint256 preRoot,
        uint256 postRoot,
        uint256[] calldata identityCommitments
    ) public view virtual onlyProxy onlyInitialized returns (bytes32 hash) {
        bytes memory bytesToHash =
            abi.encodePacked(startIndex, preRoot, postRoot, identityCommitments);

        hash = keccak256(bytesToHash);
    }

    /// @notice Calculates the input hash for the identity update verifier.
    /// @dev Implements the computation described below.
    ///
    /// @param preRoot The root value of the tree before the updates were made.
    /// @param postRoot The root value of the tree after the updates were made.
    /// @param leafIndices The array of leaf indices at which the update operations take place in
    ///        the tree. Elements in this array are extended to 256 bits when encoding.
    /// @param oldIdentities The array of old values for the identities. Length must match that of
    ///        `leafIndices`.
    /// @param newIdentities The array of new values for the identities. Length must match that of
    ///        `leafIndices`.
    ///
    /// @return hash The input hash calculated as described below.
    ///
    /// The arrays `leafIndices`, `oldIdentities` and `newIdentities` are arranged such that the
    /// triple at an element `i` in those arrays corresponds to one update operation.
    ///
    /// We keccak hash all input to save verification gas. The inputs are arranged as follows:
    ///
    /// preRoot || postRoot || ix[0] || ... || ix[n] || oi[0] || ... || oi[n] || ni[0] || ... || ni[n] ||
    ///   256   ||    256   ||  256  || ... ||  256  ||  256  || ... ||  256  ||  256  || ... ||  256  ||
    ///
    /// where:
    /// - `ix[i] == leafIndices[i]`
    /// - `oi[i] == oldIdentities[i]`
    /// - `ni[i] == newIdentities[i]`
    /// - `id[i] == identities[i]`
    /// - `n == batchSize - 1`
    function calculateIdentityUpdateInputHash(
        uint256 preRoot,
        uint256 postRoot,
        uint32[] calldata leafIndices,
        uint256[] calldata oldIdentities,
        uint256[] calldata newIdentities
    ) public view virtual onlyProxy onlyInitialized returns (bytes32 hash) {
        bytes memory bytesToHash =
            abi.encodePacked(preRoot, postRoot, leafIndices, oldIdentities, newIdentities);

        hash = keccak256(bytesToHash);
    }

    /// @notice Allows a caller to query the latest root.
    ///
    /// @return root The value of the latest tree root.
    function latestRoot() public view virtual onlyProxy onlyInitialized returns (uint256) {
        return _latestRoot;
    }

    /// @notice Sends the latest root to the state bridge.
    /// @dev Only sends if the state bridge address is not the zero address.
    ///
    function sendRootToStateBridge() internal virtual onlyProxy onlyInitialized {
        if (_isStateBridgeEnabled && address(_stateBridge) != address(0)) {
            _stateBridge.sendRootMultichain(_latestRoot);
        }
    }

    /// @notice Allows a caller to query the address of the current stateBridge.
    ///
    /// @return stateBridgeContract The address of the currently used stateBridge
    function stateBridge()
        public
        view
        virtual
        onlyProxy
        onlyInitialized
        returns (IBridge stateBridgeContract)
    {
        return _stateBridge;
    }

    /// @notice Allows a caller to upgrade the stateBridge.
    /// @dev Only the owner of the contract can call this function.
    ///
    /// @param newStateBridge The new stateBridge contract
    function setStateBridge(IBridge newStateBridge)
        public
        virtual
        onlyProxy
        onlyInitialized
        onlyOwner
    {
        if (address(newStateBridge) == address(0)) {
            revert InvalidStateBridgeAddress();
        }

        if (!_isStateBridgeEnabled) {
            enableStateBridge();
        }

        IBridge oldStateBridge = _stateBridge;
        _stateBridge = newStateBridge;

        emit DependencyUpdated(
            Dependency.StateBridge, address(oldStateBridge), address(newStateBridge)
        );
    }

    /// @notice Enables the state bridge.
    /// @dev Only the owner of the contract can call this function.
    function enableStateBridge() public virtual onlyProxy onlyInitialized onlyOwner {
        if (!_isStateBridgeEnabled) {
            _isStateBridgeEnabled = true;
            emit StateBridgeStateChange(true);
        } else {
            revert StateBridgeAlreadyEnabled();
        }
    }

    /// @notice Disables the state bridge.
    /// @dev Only the owner of the contract can call this function.
    function disableStateBridge() public virtual onlyProxy onlyInitialized onlyOwner {
        if (_isStateBridgeEnabled) {
            _isStateBridgeEnabled = false;
            emit StateBridgeStateChange(false);
        } else {
            revert StateBridgeAlreadyDisabled();
        }
    }

    /// @notice Allows a caller to query the root history for information about a given root.
    /// @dev Should be used sparingly as the query can be quite expensive.
    ///
    /// @param root The root for which you are querying information.
    /// @return rootInfo The information about `root`, or `NO_SUCH_ROOT` if `root` does not exist.
    ///         Note that if the queried root is the current, the timestamp will be invalid as the
    ///         root has not been superseded.
    function queryRoot(uint256 root)
        public
        view
        virtual
        onlyProxy
        onlyInitialized
        returns (RootInfo memory)
    {
        if (root == _latestRoot) {
            return RootInfo(_latestRoot, 0, true);
        } else {
            uint128 rootTimestamp = rootHistory[root];

            if (rootTimestamp == 0) {
                return NO_SUCH_ROOT();
            }

            bool isValid = !(block.timestamp - rootTimestamp > rootHistoryExpiry);
            return RootInfo(root, rootTimestamp, isValid);
        }
    }

    /// @notice Validates an array of identity commitments, reverting if it finds one that is
    ///         invalid or has not been reduced.
    /// @dev Identities are not valid if an identity is a non-zero element that occurs after a zero
    ///      element in the array.
    ///
    /// @param identityCommitments The array of identity commitments to be validated.
    ///
    /// @custom:reverts Reverts with `InvalidCommitment` if one or more of the provided commitments
    ///                 is invalid.
    /// @custom:reverts Reverts with `UnreducedElement` if one or more of the provided commitments
    ///                 is not in reduced form.
    function validateIdentityCommitmentsForRegistration(uint256[] calldata identityCommitments)
        internal
        view
        virtual
    {
        bool previousIsZero = false;

        for (uint256 i = 0; i < identityCommitments.length; ++i) {
            uint256 commitment = identityCommitments[i];
            if (previousIsZero && commitment != EMPTY_LEAF) {
                revert InvalidCommitment(i);
            }
            if (!isInputInReducedForm(commitment)) {
                revert UnreducedElement(UnreducedElementType.IdentityCommitment, commitment);
            }
            previousIsZero = commitment == EMPTY_LEAF;
        }
    }

    /// @notice Validates the array of identities for each of the old and new commitments being in
    ///         reduced form.
    /// @dev Must be called with arrays of the same length.
    ///
    /// @param oldIdentities The array of old values for the identities.
    /// @param newIdentities The array of new values for the identities.
    ///
    /// @custom:reverts UnreducedElement If one or more of the provided commitments is not in
    ////                reduced form.
    function validateIdentitiesForUpdate(
        uint256[] calldata oldIdentities,
        uint256[] calldata newIdentities
    ) internal view virtual {
        for (uint256 i = 0; i < oldIdentities.length; ++i) {
            uint256 oldIdentity = oldIdentities[i];
            uint256 newIdentity = newIdentities[i];
            if (!isInputInReducedForm(oldIdentity)) {
                revert UnreducedElement(UnreducedElementType.IdentityCommitment, oldIdentity);
            }
            if (!isInputInReducedForm(newIdentity)) {
                revert UnreducedElement(UnreducedElementType.IdentityCommitment, newIdentity);
            }
        }
    }

    /// @notice Checks if the provided `input` is in reduced form within the field `Fr`.
    /// @dev `r` in this case is given by `SNARK_SCALAR_FIELD`.
    ///
    /// @param input The input to check for being in reduced form.
    /// @return isInReducedForm Returns `true` if `input` is in reduced form, `false` otherwise.
    function isInputInReducedForm(uint256 input)
        public
        view
        virtual
        onlyProxy
        onlyInitialized
        returns (bool)
    {
        return input < SNARK_SCALAR_FIELD;
    }

    /// @notice Reduces the `input` element into the finite field `Fr` using the modulo operation.
    /// @dev `r` in this case is given by `SNARK_SCALAR_FIELD`.
    ///
    /// @param input The number to reduce into `Fr`.
    /// @return elem The value of `input` reduced to be an element of `Fr`.
    function reduceInputElementInSnarkScalarField(uint256 input)
        internal
        pure
        virtual
        returns (uint256)
    {
        return input % SNARK_SCALAR_FIELD;
    }

    /// @notice Reverts if the provided root value is not valid.
    /// @dev A root is valid if it is either the latest root, or not the latest root but has not
    ///      expired.
    ///
    /// @param root The root of the merkle tree to check for validity.
    ///
    /// @custom:reverts ExpiredRoot If the provided `root` has expired.
    /// @custom:reverts NonExistentRoot If the provided `root` does not exist in the history.
    function requireValidRoot(uint256 root) public view virtual onlyProxy onlyInitialized {
        // The latest root is always valid.
        if (root == _latestRoot) {
            return;
        }

        // Otherwise, we need to check things via the timestamp.
        uint128 rootTimestamp = rootHistory[root];

        // A root does not exist if it has no associated timestamp.
        if (rootTimestamp == 0) {
            revert NonExistentRoot();
        }

        // A root is no longer valid if it has expired.
        if (block.timestamp - rootTimestamp > rootHistoryExpiry) {
            revert ExpiredRoot();
        }
    }

    /// @notice Gets the address for the lookup table of merkle tree verifiers used for identity
    ///         registrations.
    ///
    /// @return addr The address of the contract being used as the verifier lookup table.
    function getRegisterIdentitiesVerifierLookupTableAddress()
        public
        view
        virtual
        onlyProxy
        onlyInitialized
        returns (address)
    {
        return address(batchInsertionVerifiers);
    }

    /// @notice Sets the address for the lookup table of merkle tree verifiers used for identity
    ///         registrations.
    /// @dev Only the owner of the contract can call this function.
    ///
    /// @param newTable The new verifier lookup table to be used for verifying identity
    ///        registrations.
    function setRegisterIdentitiesVerifierLookupTable(VerifierLookupTable newTable)
        public
        virtual
        onlyProxy
        onlyInitialized
        onlyOwner
    {
        VerifierLookupTable oldTable = batchInsertionVerifiers;
        batchInsertionVerifiers = newTable;
        emit DependencyUpdated(
            Dependency.InsertionVerifierLookupTable, address(oldTable), address(newTable)
        );
    }

    /// @notice Gets the address for the lookup table of merkle tree verifiers used for identity
    ///         updates.
    /// @dev The update verifier is also used for member removals.
    ///
    /// @return addr The address of the contract being used as the verifier lookup table.
    function getIdentityUpdateVerifierLookupTableAddress()
        public
        view
        virtual
        onlyProxy
        onlyInitialized
        returns (address)
    {
        return address(identityUpdateVerifiers);
    }

    /// @notice Sets the address for the lookup table of merkle tree verifiers to be used for
    ///         verification of identity updates.
    /// @dev Only the owner of the contract can call this function.
    /// @dev The update verifier is also used for member removals.
    ///
    /// @param newTable The new lookup table instance to be used for verifying identity updates.
    function setIdentityUpdateVerifierLookupTable(VerifierLookupTable newTable)
        public
        virtual
        onlyProxy
        onlyInitialized
        onlyOwner
    {
        VerifierLookupTable oldTable = identityUpdateVerifiers;
        identityUpdateVerifiers = newTable;
        emit DependencyUpdated(
            Dependency.UpdateVerifierLookupTable, address(oldTable), address(newTable)
        );
    }

    /// @notice Gets the address of the verifier used for verification of semaphore proofs.
    ///
    /// @return addr The address of the contract being used as the verifier.
    function getSemaphoreVerifierAddress()
        public
        view
        virtual
        onlyProxy
        onlyInitialized
        returns (address)
    {
        return address(semaphoreVerifier);
    }

    /// @notice Sets the address for the semaphore verifier to be used for verification of
    ///         semaphore proofs.
    /// @dev Only the owner of the contract can call this function.
    ///
    /// @param newVerifier The new verifier instance to be used for verifying semaphore proofs.
    function setSemaphoreVerifier(ISemaphoreVerifier newVerifier)
        public
        virtual
        onlyProxy
        onlyInitialized
        onlyOwner
    {
        ISemaphoreVerifier oldVerifier = semaphoreVerifier;
        semaphoreVerifier = newVerifier;
        emit DependencyUpdated(
            Dependency.SemaphoreVerifier, address(oldVerifier), address(newVerifier)
        );
    }

    /// @notice Gets the current amount of time used to expire roots in the history.
    ///
    /// @return expiryTime The amount of time it takes for a root to expire.
    function getRootHistoryExpiry()
        public
        view
        virtual
        onlyProxy
        onlyInitialized
        returns (uint256)
    {
        return rootHistoryExpiry;
    }

    /// @notice Sets the time to wait before expiring a root from the root history.
    /// @dev Only the owner of the contract can call this function.
    ///
    /// @param newExpiryTime The new time to use to expire roots.
    function setRootHistoryExpiry(uint256 newExpiryTime)
        public
        virtual
        onlyProxy
        onlyInitialized
        onlyOwner
    {
        if (newExpiryTime == 0) {
            revert("Expiry time cannot be zero.");
        }
        uint256 oldExpiry = rootHistoryExpiry;
        rootHistoryExpiry = newExpiryTime;

        _stateBridge.setRootHistoryExpiry(newExpiryTime);

        emit RootHistoryExpirySet(oldExpiry, newExpiryTime);
    }

    /// @notice Gets the Semaphore tree depth the contract was initialized with.
    ///
    /// @return initializedTreeDepth Tree depth.
    function getTreeDepth() public view virtual onlyProxy onlyInitialized returns (uint8) {
        return treeDepth;
    }

    /// @notice Gets the address that is authorised to perform identity operations on this identity
    ///         manager instance.
    ///
    /// @return _ The address authorized to perform identity operations.
    function identityOperator() public view virtual onlyProxy onlyInitialized returns (address) {
        return _identityOperator;
    }

    /// @notice Sets the address that is authorised to perform identity operations on this identity
    ///         manager instance.
    ///
    /// @param newIdentityOperator The address of the new identity operator.
    ///
    /// @return _ The address of the old identity operator.
    function setIdentityOperator(address newIdentityOperator)
        public
        virtual
        onlyProxy
        onlyInitialized
        onlyOwner
        returns (address)
    {
        address oldOperator = _identityOperator;
        _identityOperator = newIdentityOperator;
        emit IdentityOperatorChanged(oldOperator, newIdentityOperator);
        return oldOperator;
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                    SEMAPHORE PROOF VALIDATION LOGIC                     ///
    ///////////////////////////////////////////////////////////////////////////////

    /// @notice A verifier for the semaphore protocol.
    /// @dev Note that a double-signaling check is not included here, and should be carried by the
    ///      caller.
    ///
    /// @param root The of the Merkle tree
    /// @param signalHash A keccak256 hash of the Semaphore signal
    /// @param nullifierHash The nullifier hash
    /// @param externalNullifierHash A keccak256 hash of the external nullifier
    /// @param proof The zero-knowledge proof
    ///
    /// @custom:reverts string If the zero-knowledge proof cannot be verified for the public inputs.
    function verifyProof(
        uint256 root,
        uint256 signalHash,
        uint256 nullifierHash,
        uint256 externalNullifierHash,
        uint256[8] calldata proof
    ) public view virtual onlyProxy onlyInitialized {
        // Check the preconditions on the inputs.
        requireValidRoot(root);

        // With that done we can now verify the proof.
        semaphoreVerifier.verifyProof(
            root, nullifierHash, signalHash, externalNullifierHash, proof, treeDepth
        );
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                    SEMAPHORE PROOF VALIDATION LOGIC                     ///
    ///////////////////////////////////////////////////////////////////////////////

    /// @notice Ensures that the guarded operation can only be performed by the authorized identity
    ///         operator contract.
    ///
    /// @custom:reverts Unauthorized If the caller is not the identity operator.
    modifier onlyIdentityOperator() {
        if (msg.sender != _identityOperator) {
            revert Unauthorized(msg.sender);
        }

        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {CheckInitialized} from "../utils/CheckInitialized.sol";

import {Ownable2StepUpgradeable} from "contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {UUPSUpgradeable} from "contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @title WorldID Proxy Contract Implementation
/// @author Worldcoin
/// @notice A router component that can dispatch group numbers to the correct identity manager
///         implementation.
/// @dev This is base class for implementations delegated to by a proxy.
abstract contract WorldIDImpl is Ownable2StepUpgradeable, UUPSUpgradeable, CheckInitialized {
    ///////////////////////////////////////////////////////////////////////////////
    ///                   A NOTE ON IMPLEMENTATION CONTRACTS                    ///
    ///////////////////////////////////////////////////////////////////////////////

    // This contract is designed explicitly to operate from behind a proxy contract. As a result,
    // there are a few important implementation considerations:
    //
    // - All updates made after deploying a given version of the implementation should inherit from
    //   the latest version of the implementation. This prevents storage clashes.
    // - All functions that are less access-restricted than `private` should be marked `virtual` in
    //   order to enable the fixing of bugs in the existing interface.
    // - Any function that reads from or modifies state (i.e. is not marked `pure`) must be
    //   annotated with the `onlyProxy` and `onlyInitialized` modifiers. This ensures that it can
    //   only be called when it has access to the data in the proxy, otherwise results are likely to
    //   be nonsensical.
    // - This contract deals with important data for the WorldID system. Ensure that all newly-added
    //   functionality is carefully access controlled using `onlyOwner`, or a more granular access
    //   mechanism.
    // - Do not assign any contract-level variables at the definition site unless they are
    //   `constant`.
    //
    // Additionally, the following notes apply:
    //
    // - Initialisation and ownership management are not protected behind `onlyProxy` intentionally.
    //   This ensures that the contract can safely be disposed of after it is no longer used.
    // - Carefully consider what data recovery options are presented as new functionality is added.
    //   Care must be taken to ensure that a migration plan can exist for cases where upgrades
    //   cannot recover from an issue or vulnerability.

    ///////////////////////////////////////////////////////////////////////////////
    ///                             INITIALIZATION                              ///
    ///////////////////////////////////////////////////////////////////////////////

    /// @notice Performs the initialisation steps necessary for the base contracts of this contract.
    /// @dev Must be called during `initialize` before performing any additional steps.
    function __WorldIDImpl_init() internal virtual onlyInitializing {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                                 ERRORS                                  ///
    ///////////////////////////////////////////////////////////////////////////////

    /// @notice Thrown when an attempt is made to renounce ownership.
    error CannotRenounceOwnership();

    ///////////////////////////////////////////////////////////////////////////////
    ///                             AUTHENTICATION                              ///
    ///////////////////////////////////////////////////////////////////////////////

    /// @notice Is called when upgrading the contract to check whether it should be performed.
    ///
    /// @param newImplementation The address of the implementation being upgraded to.
    ///
    /// @custom:reverts string If the upgrade should not be performed.
    function _authorizeUpgrade(address newImplementation)
        internal
        virtual
        override
        onlyProxy
        onlyOwner
    {
        // No body needed as `onlyOwner` handles it.
    }

    /// @notice Ensures that ownership of WorldID implementations cannot be renounced.
    /// @dev This function is intentionally not `virtual` as we do not want it to be possible to
    ///      renounce ownership for any WorldID implementation.
    /// @dev This function is marked as `onlyOwner` to maintain the access restriction from the base
    ///      contract.
    function renounceOwnership() public view override onlyOwner {
        revert CannotRenounceOwnership();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Ownable2Step} from "openzeppelin-contracts/access/Ownable2Step.sol";

import {ITreeVerifier} from "../interfaces/ITreeVerifier.sol";

/// @title Batch Lookup Table
/// @author Worldcoin
/// @notice A table that provides the correct tree verifier based on the provided batch size.
/// @dev It should be used to query the correct verifier before using that verifier for verifying a
///      tree modification proof.
contract VerifierLookupTable is Ownable2Step {
    ////////////////////////////////////////////////////////////////////////////////
    ///                                   DATA                                   ///
    ////////////////////////////////////////////////////////////////////////////////

    /// The null address.
    address internal constant nullAddress = address(0x0);

    /// The null verifier.
    ITreeVerifier internal constant nullVerifier = ITreeVerifier(nullAddress);

    /// The lookup table for routing batches.
    ///
    /// As we expect to only have a few batch sizes per contract, a mapping is used due to its
    /// natively sparse storage.
    mapping(uint256 => ITreeVerifier) internal verifier_lut;

    ////////////////////////////////////////////////////////////////////////////////
    ///                                  ERRORS                                  ///
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Raised if a batch size is requested that the lookup table doesn't know about.
    error NoSuchVerifier();

    /// @notice Raised if an attempt is made to add a verifier for a batch size that already exists.
    error VerifierExists();

    /// @notice Thrown when an attempt is made to renounce ownership.
    error CannotRenounceOwnership();

    ////////////////////////////////////////////////////////////////////////////////
    ///                                  EVENTS                                  ///
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Emitted when a verifier is added to the lookup table.
    ///
    /// @param batchSize The size of the batch that the verifier has been added for.
    /// @param verifierAddress The address of the verifier that was associated with `batchSize`.
    event VerifierAdded(uint256 indexed batchSize, address indexed verifierAddress);

    /// @notice Emitted when a verifier is updated in the lookup table.
    ///
    /// @param batchSize The size of the batch that the verifier has been updated for.
    /// @param oldVerifierAddress The address of the old verifier for `batchSize`.
    /// @param newVerifierAddress The address of the new verifier for `batchSize`.
    event VerifierUpdated(
        uint256 indexed batchSize,
        address indexed oldVerifierAddress,
        address indexed newVerifierAddress
    );

    /// @notice Emitted when a verifier is disabled in the lookup table.
    ///
    /// @param batchSize The batch size that had its verifier disabled.
    event VerifierDisabled(uint256 indexed batchSize);

    ////////////////////////////////////////////////////////////////////////////////
    ///                               CONSTRUCTION                               ///
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Constructs a new batch lookup table.
    /// @dev It is initially constructed without any verifiers.
    constructor() Ownable2Step() {}

    ////////////////////////////////////////////////////////////////////////////////
    ///                                ACCESSORS                                 ///
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Obtains the verifier for the provided `batchSize`.
    ///
    /// @param batchSize The batch size to get the associated verifier for.
    ///
    /// @return verifier The tree verifier for the provided `batchSize`.
    ///
    /// @custom:reverts NoSuchVerifier If there is no verifier associated with the `batchSize`.
    function getVerifierFor(uint256 batchSize) public view returns (ITreeVerifier verifier) {
        // Check the preconditions for querying the verifier.
        validateVerifier(batchSize);

        // With the preconditions checked, we can return the verifier.
        verifier = verifier_lut[batchSize];
    }

    /// @notice Adds a verifier for the provided `batchSize`.
    ///
    /// @param batchSize The batch size to add the verifier for.
    /// @param verifier The verifier for a batch of size `batchSize`.
    ///
    /// @custom:reverts VerifierExists If `batchSize` already has an associated verifier.
    /// @custom:reverts string If the caller is not the owner.
    function addVerifier(uint256 batchSize, ITreeVerifier verifier) public onlyOwner {
        // Check that there is no entry for that batch size.
        if (verifier_lut[batchSize] != nullVerifier) {
            revert VerifierExists();
        }

        // Add the verifier.
        updateVerifier(batchSize, verifier);
        emit VerifierAdded(batchSize, address(verifier));
    }

    /// @notice Updates the verifier for the provided `batchSize`.
    ///
    /// @param batchSize The batch size to add the verifier for.
    /// @param verifier The verifier for a batch of size `batchSize`.
    ///
    /// @return oldVerifier The old verifier instance associated with this batch size.
    ///
    /// @custom:reverts string If the caller is not the owner.
    function updateVerifier(uint256 batchSize, ITreeVerifier verifier)
        public
        onlyOwner
        returns (ITreeVerifier oldVerifier)
    {
        oldVerifier = verifier_lut[batchSize];
        verifier_lut[batchSize] = verifier;
        emit VerifierUpdated(batchSize, address(oldVerifier), address(verifier));
    }

    /// @notice Disables the verifier for the provided batch size.
    ///
    /// @param batchSize The batch size to disable the verifier for.
    ///
    /// @return oldVerifier The old verifier associated with the batch size.
    ///
    /// @custom:reverts string If the caller is not the owner.
    function disableVerifier(uint256 batchSize)
        public
        onlyOwner
        returns (ITreeVerifier oldVerifier)
    {
        oldVerifier = updateVerifier(batchSize, ITreeVerifier(nullAddress));
        emit VerifierDisabled(batchSize);
    }

    ////////////////////////////////////////////////////////////////////////////////
    ///                          INTERNAL FUNCTIONALITY                          ///
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Checks if the entry for the provided `batchSize` is a valid verifier.
    ///
    /// @param batchSize The batch size to check.
    ///
    /// @custom:reverts NoSuchVerifier If `batchSize` does not have an associated verifier.
    /// @custom:reverts BatchTooLarge If `batchSize` exceeds the maximum batch size.
    function validateVerifier(uint256 batchSize) internal view {
        if (verifier_lut[batchSize] == nullVerifier) {
            revert NoSuchVerifier();
        }
    }

    ////////////////////////////////////////////////////////////////////////////////
    ///                           OWNERSHIP MANAGEMENT                           ///
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Ensures that ownership of the lookup table cannot be renounced.
    /// @dev This function is intentionally not `virtual` as we do not want it to be possible to
    ///      renounce ownership for the lookup table.
    /// @dev This function is marked as `onlyOwner` to maintain the access restriction from the base
    ///      contract.
    function renounceOwnership() public view override onlyOwner {
        revert CannotRenounceOwnership();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title Base WorldID interface
/// @author Worldcoin
/// @notice The interface providing basic types across various WorldID contracts.
interface IBaseWorldID {
    ///////////////////////////////////////////////////////////////////////////////
    ///                                  ERRORS                                 ///
    ///////////////////////////////////////////////////////////////////////////////

    /// @notice Thrown when attempting to validate a root that has expired.
    error ExpiredRoot();

    /// @notice Thrown when attempting to validate a root that has yet to be added to the root
    ///         history.
    error NonExistentRoot();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IBridge {
    /// @notice Sends the latest Semaphore root to Optimism.
    /// @dev Calls this method on the L1 Proxy contract to relay the latest root to all supported networks
    /// @param root The latest Semaphore root.
    function sendRootMultichain(uint256 root) external;

    /// @notice Sets the root history expiry for OpWorldID (on Optimism) and PolygonWorldID (on Polygon)
    /// @param expiryTime The new root history expiry for OpWorldID and PolygonWorldID
    /// @dev gated by onlyWorldIDIdentityManager modifier
    function setRootHistoryExpiry(uint256 expiryTime) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title Tree Verifier Interface
/// @author Worldcoin
/// @notice An interface representing a merkle tree verifier.
interface ITreeVerifier {
    /// @notice Verifies the provided proof data for the provided public inputs.
    /// @dev It is highly recommended that the implementation is restricted to `view` if possible.
    ///
    /// @param a The first G1Point of the proof (ar).
    /// @param b The G2Point for the proof (bs).
    /// @param c The second G1Point of the proof (kr).
    /// @param input The public inputs to the function, reduced such that it is a member of the
    ///              field `Fr` where `r` is `SNARK_SCALAR_FIELD`.
    ///
    /// @return result True if the proof verifies successfully, false otherwise.
    /// @custom:reverts string If the proof elements are not < `PRIME_Q` or if the `input` is not
    ///                 less than `SNARK_SCALAR_FIELD`.
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[1] memory input
    ) external returns (bool result);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IBaseWorldID} from "./IBaseWorldID.sol";

/// @title WorldID Interface
/// @author Worldcoin
/// @notice The interface to the proof verification for WorldID.
interface IWorldID is IBaseWorldID {
    /// @notice Verifies a WorldID zero knowledge proof.
    /// @dev Note that a double-signaling check is not included here, and should be carried by the
    ///      caller.
    /// @dev It is highly recommended that the implementation is restricted to `view` if possible.
    ///
    /// @param root The of the Merkle tree
    /// @param signalHash A keccak256 hash of the Semaphore signal
    /// @param nullifierHash The nullifier hash
    /// @param externalNullifierHash A keccak256 hash of the external nullifier
    /// @param proof The zero-knowledge proof
    ///
    /// @custom:reverts string If the `proof` is invalid.
    function verifyProof(
        uint256 root,
        uint256 signalHash,
        uint256 nullifierHash,
        uint256 externalNullifierHash,
        uint256[8] calldata proof
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Initializable} from "contracts-upgradeable/proxy/utils/Initializable.sol";

/// @title Initialization Checker
/// @author Worldcoin
/// @notice A contract that represents the ability to initialize a proxy-based contract but also to
///         check that said contract is initialized.
contract CheckInitialized is Initializable {
    /// @notice Whether the initialization has been completed.
    /// @dev This relies on the fact that a default-init `bool` is `false` here.
    bool private _initialized;

    /// @notice Thrown when attempting to call a function while the implementation has not been
    ///         initialized.
    error ImplementationNotInitialized();

    /// @notice Sets the contract as initialized.
    function __setInitialized() internal onlyInitializing {
        _initialized = true;
    }

    /// @notice Asserts that the annotated function can only be called once the contract has been
    ///         initialized.
    modifier onlyInitialized() {
        if (!_initialized) {
            revert ImplementationNotInitialized();
        }
        _;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title Semaphore tree depth validator
/// @author Worldcoin
/// @notice
library SemaphoreTreeDepthValidator {
    /// @notice Checks if the provided `treeDepth` is amoung supported depths.
    ///
    /// @param treeDepth The tree depth to validate.
    /// @return supportedDepth Returns `true` if `treeDepth` is between 16 and 32 - depths supported by the Semaphore
    function validate(uint8 treeDepth) internal pure returns (bool supportedDepth) {
        uint8 minDepth = 16;
        uint8 maxDepth = 32;
        return treeDepth >= minDepth && treeDepth <= maxDepth;
    }
}