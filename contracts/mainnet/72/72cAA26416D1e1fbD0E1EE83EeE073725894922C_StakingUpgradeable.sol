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
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

interface IERC20_EXTENDED {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

interface IUniswapRouter {
    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

struct StructTeam {
    address teamAddress;
    uint8 levelIndex;
}

struct StructAccount {
    uint32 id;
    address selfAddress;
    address referrerAddress;
    bool isStaked;
    uint256 valueInUSD;
    uint256 startTime;
    uint256 rewardClaimedInUSD;
    uint256 pricipalClaimed;
    uint256 pricipalClaimedTimestamp;
    StructPlan stakingPlan;
    // uint8 stakingPlanId;
    address[] referee;
    StructTeam[] team;
    uint256 directBusiness;
    uint256 teamBusiness;
    uint256 referralPaidInToken;
    uint256 rewardReferralPaidInToken;
}

struct StructPlan {
    uint32 id;
    uint256 minValue;
    uint256 maxValue;
    uint8 monthlyRewardRate;
    string name;
}

contract StakingUpgradeable is
    Initializable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    address[] private _stakers;
    uint256 private _valueStaked;
    uint256 private _principalClaimed;
    uint256 private _rewardsDistributed;
    uint256 private _referralPaidInToken;

    uint256 private _initialRewardsLockTimeLimit;
    uint256 private _principalClaimTimeLimit;
    uint256 private _principalClaimRate;
    uint256 private _providerFees;
    address private _providerAddress;

    uint16[] private _stakingReferralRates;
    uint16[] private _stakingRewardReferralRates;
    uint16 private _decimals;

    address private _uniswapV2RouterAddress;
    address private _tokenAddress;
    address private _baseCurrencyAddress;

    bool private _isPayReferral;

    mapping(address => StructAccount) private mappingAccount;
    mapping(uint8 => StructPlan) private mappingPlan;

    event SelfAddressUpdated(
        address indexed prevAddress,
        address indexed newAddress
    );
    event ReferrerAdded(
        address indexed referrerAddress,
        address indexed userAddress
    );

    event ReferrerNotAdded(string reason);

    event TeamAddressAdded(
        address indexed parentAddress,
        uint32 indexed level,
        address indexed referrerAddress,
        address userAddress
    );

    event ReferralPaidInToken(
        address indexed beneficiary,
        uint256 indexed valueInWei,
        uint8 indexed level,
        address tokenContractAddress
    );

    event ReferralStakingRewardPaidInToken(
        address indexed beneficiary,
        uint256 indexed valueInWei,
        uint8 indexed level,
        address tokenContractAddress
    );

    event Stake(
        address indexed userAddress,
        uint256 indexed valueStaked,
        StructPlan stakingPlan
    );

    event StakingRewardClaimed(
        address indexed userAddress,
        uint256 indexed rewardInToken
    );

    event PrincipalClaimed(
        address indexed userAddress,
        uint256 indexed valueInToken
    );

    event UnStake(address indexed userAddress, uint256 indexed valueInUSD);

    function initialize() public initializer {
        _initialRewardsLockTimeLimit = 60 days;

        _principalClaimRate = 25;
        _decimals = 1000;
        _principalClaimTimeLimit = 30 days;
        _providerFees = 100;
        _providerAddress = 0x64b909a2C51AA62F30e75010b726a8CE863285fA;

        _stakingRewardReferralRates = [50, 20, 10, 10, 10];
        _stakingReferralRates = [50, 20, 10, 9, 8, 7, 8, 9, 10, 20];
        _isPayReferral = true;

        _uniswapV2RouterAddress = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
        _tokenAddress = 0x32F81F5fa147027F990b6a35e14b41b5990fCE1a;
        _baseCurrencyAddress = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;

        _stakers.push(address(0));

        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    // function initialize() public initializer {
    //     //BSC Testnet
    //     _initialRewardsLockTimeLimit = 60 days;

    //     _principalClaimRate = 25;
    //     _decimals = 1000;
    //     _principalClaimTimeLimit = 30 days;
    //     _providerFees = 80;
    //     _providerAddress = msg.sender;

    //     _stakingRewardReferralRates = [50, 20, 10, 10, 10];
    //     _stakingReferralRates = [50, 20, 10, 9, 8, 7, 8, 9, 10, 20];

    //     _uniswapV2RouterAddress = 0xDE2Db97D54a3c3B008a097B2260633E6cA7DB1AF;
    //     _tokenAddress = 0x07fd92CDa316fEf52c7d4d76Fe21f658e46c211D;
    //     _baseCurrencyAddress = 0xe6ffee89beb3bee2785eE88deD4Da74F8a082A78;

    //     _stakers.push(address(0));

    //     __Pausable_init();
    //     __Ownable_init();
    //     __UUPSUpgradeable_init();
    // }

    receive() external payable {}

    function _userAccountMap(
        address _userAddress
    ) private view returns (StructAccount memory) {
        return mappingAccount[_userAddress];
    }

    function userAccountMap(
        address _userAddress
    ) external view returns (StructAccount memory) {
        return mappingAccount[_userAddress];
    }

    function getPlan(uint8 _planId) external view returns (StructPlan memory) {
        return mappingPlan[_planId];
    }

    function setPlan(
        uint8[] memory _planId,
        uint256[] memory _minValueInDecimals,
        uint256[] memory _maxValueInDecimals,
        uint8[] memory _monthlyRewardRate,
        string[] calldata _name
    ) external onlyOwner {
        for (uint8 i; i < _planId.length; i++) {
            mappingPlan[_planId[i]] = StructPlan(
                _planId[i],
                _minValueInDecimals[i] * 10 ** 18,
                _maxValueInDecimals[i] * 10 ** 18,
                _monthlyRewardRate[i],
                _name[i]
            );
        }
    }

    function _getPlanIdByValue(
        uint256 _value
    ) private view returns (StructPlan memory stakingPlan) {
        for (uint8 i; i < 15; ++i) {
            StructPlan memory planAccount = mappingPlan[i];
            if (
                _value >= planAccount.minValue && _value < planAccount.maxValue
            ) {
                stakingPlan = planAccount;
                break;
            }
        }
    }

    function getPlanIdByValue(
        uint256 _valueInWei
    ) external view returns (StructPlan memory stakingPlan) {
        return _getPlanIdByValue(_valueInWei);
    }

    function _addReferrer(
        StructAccount storage referrerAccount,
        StructAccount storage userAccount,
        uint16[] memory _levels
    ) private {
        require(
            userAccount.selfAddress != referrerAccount.selfAddress,
            "You cannot refer yourself."
        );

        require(
            referrerAccount.referrerAddress != userAccount.selfAddress,
            "You cannot be the upline of your referrer."
        );

        userAccount.referrerAddress = referrerAccount.selfAddress;

        emit ReferrerAdded(
            referrerAccount.selfAddress,
            userAccount.selfAddress
        );

        referrerAccount.referee.push(userAccount.referrerAddress);

        referrerAccount.team.push(
            StructTeam({teamAddress: userAccount.selfAddress, levelIndex: 1})
        );

        for (uint8 i; i < _levels.length; ++i) {
            if (referrerAccount.referrerAddress == address(0)) {
                break;
            }

            StructAccount storage parentAccount = mappingAccount[
                referrerAccount.referrerAddress
            ];

            parentAccount.team.push(StructTeam(userAccount.selfAddress, i + 1));

            emit TeamAddressAdded(
                parentAccount.selfAddress,
                i + 1,
                userAccount.referrerAddress,
                userAccount.selfAddress
            );

            referrerAccount = parentAccount;
        }
    }

    function _payReferralStakingReward(
        StructAccount storage userAccount,
        uint256 _valueInWei,
        uint16[] memory _levels,
        uint16 _levelDecimals,
        address _tokenContractAddress
    ) private {
        uint256 totalReferralPaidInToken;

        for (uint8 i; i < _levels.length; i++) {
            if (userAccount.referrerAddress == address(0)) {
                break;
            }

            StructAccount storage referrerAccount = mappingAccount[
                userAccount.referrerAddress
            ];

            uint256 referralValueInToken = (_valueInWei * _levels[i]) /
                _levelDecimals;

            IERC20Upgradeable(_tokenContractAddress).transfer(
                referrerAccount.selfAddress,
                referralValueInToken
            );

            referrerAccount.rewardReferralPaidInToken += referralValueInToken;

            totalReferralPaidInToken += referralValueInToken;

            emit ReferralStakingRewardPaidInToken(
                referrerAccount.selfAddress,
                referralValueInToken,
                i + 1,
                _tokenContractAddress
            );

            userAccount = referrerAccount;
        }

        _referralPaidInToken += totalReferralPaidInToken;
    }

    function _payReferral(
        StructAccount storage userAccount,
        uint256 _valueInWei,
        uint256 _valueInUSD,
        uint16[] memory _levels,
        uint16 _levelDecimals,
        address _tokenContractAddress
    ) private {
        uint256 totalReferralPaidInToken;

        for (uint8 i; i < _levels.length; i++) {
            if (userAccount.referrerAddress == address(0)) {
                break;
            }

            StructAccount storage referrerAccount = mappingAccount[
                userAccount.referrerAddress
            ];

            if (i == 1) {
                referrerAccount.directBusiness += _valueInUSD;
            }

            referrerAccount.teamBusiness += _valueInUSD;

            uint256 referralValueInToken = (_valueInWei * _levels[i]) /
                _levelDecimals;

            IERC20Upgradeable(_tokenContractAddress).transfer(
                referrerAccount.selfAddress,
                referralValueInToken
            );

            referrerAccount.referralPaidInToken += referralValueInToken;

            totalReferralPaidInToken += referralValueInToken;

            emit ReferralPaidInToken(
                referrerAccount.selfAddress,
                referralValueInToken,
                i + 1,
                _tokenContractAddress
            );

            userAccount = referrerAccount;
        }

        _referralPaidInToken += totalReferralPaidInToken;
    }

    function _stake(
        StructAccount storage userAccount,
        uint256 _valueInUSD,
        StructPlan memory _stakingPlan
    ) private {
        if (userAccount.id == 0) {
            userAccount.id = uint32(_stakers.length);
            _stakers.push(userAccount.selfAddress);
        }

        if (!userAccount.isStaked) {
            userAccount.isStaked = true;
        }

        userAccount.startTime = block.timestamp;
        userAccount.valueInUSD += _valueInUSD;
        userAccount.stakingPlan = _stakingPlan;

        _valueStaked += _valueInUSD;

        emit Stake(userAccount.selfAddress, _valueInUSD, _stakingPlan);
    }

    function stake(address _referrerAddress, uint256 _valueInWei) external {
        address _msgSender = msg.sender;
        require(
            _referrerAddress != address(0),
            "Referrer should not be address zero"
        );

        require(_referrerAddress != _msgSender, "You cannot refer you.");
        uint16[] memory referralRates = _stakingReferralRates;
        uint16 levelDecimals = _decimals;
        address[] memory currenciesArray = new address[](2);
        currenciesArray[0] = _tokenAddress;
        currenciesArray[1] = _baseCurrencyAddress;

        uint256[] memory valuesOut = IUniswapRouter(_uniswapV2RouterAddress)
            .getAmountsOut(1 * 10 ** 18, currenciesArray);

        StructAccount storage userAccount = mappingAccount[_msgSender];
        StructAccount storage referrerAccount = mappingAccount[
            _referrerAddress
        ];

        if (userAccount.selfAddress == address(0)) {
            userAccount.selfAddress = _msgSender;
            emit SelfAddressUpdated(address(0), _msgSender);
        }

        if (referrerAccount.selfAddress == address(0)) {
            referrerAccount.selfAddress = _referrerAddress;
            emit SelfAddressUpdated(address(0), _referrerAddress);
        }

        StructPlan memory stakingPlan = _getPlanIdByValue(
            _convertDecimals(
                valuesOut[1],
                IERC20_EXTENDED(currenciesArray[1]).decimals(),
                18
            )
        );

        require(
            stakingPlan.id == userAccount.stakingPlan.id ||
                stakingPlan.id > userAccount.stakingPlan.id,
            "You cannot demote the plan."
        );

        IERC20Upgradeable(currenciesArray[0]).transferFrom(
            _msgSender,
            address(this),
            _valueInWei
        );

        _stake(
            userAccount,
            _convertDecimals(
                valuesOut[1],
                IERC20_EXTENDED(currenciesArray[1]).decimals(),
                18
            ),
            stakingPlan
        );

        if (userAccount.referrerAddress == address(0)) {
            _addReferrer(referrerAccount, userAccount, referralRates);
        }

        if (_isPayReferral && userAccount.referrerAddress != address(0)) {
            _payReferral(
                userAccount,
                _valueInWei,
                _convertDecimals(
                    valuesOut[1],
                    IERC20_EXTENDED(currenciesArray[1]).decimals(),
                    18
                ),
                referralRates,
                levelDecimals,
                currenciesArray[0]
            );
        }

        IERC20Upgradeable(currenciesArray[0]).transfer(
            _providerAddress,
            (_valueInWei * _providerFees) / levelDecimals
        );
    }

    function _getStakingReward(
        StructAccount memory userAccount
    ) private view returns (uint256 stakingReward) {
        if (userAccount.isStaked) {
            uint256 currentTime = block.timestamp;
            uint256 stakingTimePassed = currentTime - userAccount.startTime;

            uint256 totalStakingRewardInUSD = (((userAccount.valueInUSD *
                userAccount.stakingPlan.monthlyRewardRate) / 100) / 30 days) *
                stakingTimePassed;

            uint256 currentStakingReward = totalStakingRewardInUSD -
                userAccount.rewardClaimedInUSD;

            uint256 valueRemaining = userAccount.valueInUSD -
                userAccount.pricipalClaimed;

            stakingReward = valueRemaining > currentStakingReward
                ? currentStakingReward
                : valueRemaining;
        }
    }

    function getStakingReward(
        address _userAddress
    ) external view returns (uint256) {
        StructAccount memory userAccount = mappingAccount[_userAddress];
        return _getStakingReward(userAccount);
    }

    function getUserPrincipalValue(
        address _userAddress
    ) external view returns (uint256) {
        StructAccount memory userAccount = mappingAccount[_userAddress];
        uint256 valueRemaining = userAccount.valueInUSD -
            userAccount.pricipalClaimed;
        return valueRemaining;
    }

    function _claimStakingReward(address _userAddress) private {
        StructAccount storage userAccount = mappingAccount[_userAddress];
        uint256 currentTime = block.timestamp;
        uint16 decimals = _decimals;
        require(userAccount.valueInUSD > 0, "You have not staked yet");
        // require(
        //     currentTime - userAccount.startTime > _initialRewardsLockTimeLimit,
        //     "Initial claim lock time is not over yet."
        // );

        // require(
        //     currentTime - userAccount.pricipalClaimedTimestamp >
        //         _principalClaimTimeLimit,
        //     "Reward claim time limit is not over yet."
        // );

        uint256 stakingRewardUSD = _getStakingReward(userAccount);
        uint256 principleClaimValueUSD = (userAccount.valueInUSD *
            _principalClaimRate) / decimals;

        uint256 valueRemaining = userAccount.valueInUSD -
            userAccount.pricipalClaimed;

        uint256 claimablePrincipleUSD = valueRemaining > principleClaimValueUSD
            ? principleClaimValueUSD
            : valueRemaining;

        address[] memory currenciesArray = new address[](2);
        currenciesArray[0] = _baseCurrencyAddress;
        currenciesArray[1] = _tokenAddress;

        uint256[] memory valuesOutStakingReward = IUniswapRouter(
            _uniswapV2RouterAddress
        ).getAmountsOut(stakingRewardUSD, currenciesArray);

        uint256[] memory valuesOutPrincipal = IUniswapRouter(
            _uniswapV2RouterAddress
        ).getAmountsOut(claimablePrincipleUSD, currenciesArray);

        uint256 valueOutPrinciple = valuesOutPrincipal[1];

        uint256 totalClaimInToken = valuesOutStakingReward[1] +
            valueOutPrinciple;

        userAccount.rewardClaimedInUSD += stakingRewardUSD;
        userAccount.pricipalClaimed += claimablePrincipleUSD;
        userAccount.pricipalClaimedTimestamp = currentTime;

        if (
            userAccount.pricipalClaimed == userAccount.valueInUSD ||
            userAccount.pricipalClaimed > userAccount.valueInUSD
        ) {
            userAccount.pricipalClaimed = userAccount.valueInUSD;
            userAccount.isStaked = false;
            emit UnStake(_userAddress, userAccount.valueInUSD);
        }

        IERC20Upgradeable(_tokenAddress).transfer(
            _userAddress,
            totalClaimInToken
        );

        emit StakingRewardClaimed(_userAddress, valuesOutStakingReward[1]);
        emit PrincipalClaimed(_userAddress, valueOutPrinciple);

        if (_isPayReferral) {
            _payReferralStakingReward(
                userAccount,
                valuesOutStakingReward[1],
                _stakingRewardReferralRates,
                decimals,
                currenciesArray[1]
            );
        }
    }

    function claimStakingReward() external {
        _claimStakingReward(msg.sender);
    }

    function getUserTeam(
        address _userAddress
    )
        external
        view
        returns (
            address referrer,
            address[] memory referee,
            uint256 refereeCount,
            StructTeam[] memory teamWithIndex
        )
    {
        StructAccount memory userAccount = mappingAccount[_userAddress];
        referrer = userAccount.referrerAddress;
        referee = userAccount.referee;
        refereeCount = userAccount.referee.length;
        teamWithIndex = userAccount.team;
    }

    function getUserBusiness(
        address _userAddress
    )
        external
        view
        returns (
            uint256 selfBusiness,
            uint256 directBusiness,
            uint256 teamBusiness,
            uint256 totalBusiness
        )
    {
        StructAccount memory userAccount = mappingAccount[_userAddress];

        selfBusiness = userAccount.valueInUSD;
        directBusiness = userAccount.directBusiness;
        teamBusiness = userAccount.teamBusiness;
        totalBusiness = selfBusiness + teamBusiness;
    }

    function getUserRewards(
        address _userAddress
    )
        external
        view
        returns (uint256 stakingRewardClaimed, uint256 referralReward)
    {
        StructAccount memory userAccount = mappingAccount[_userAddress];
        stakingRewardClaimed = userAccount.rewardClaimedInUSD;
        referralReward = userAccount.referralPaidInToken;
    }

    function getStakersList()
        external
        view
        returns (address[] memory stakers, uint32 stakesCount)
    {
        stakers = _stakers;
        stakesCount = uint32(stakers.length);
    }

    function getContractDefaults()
        external
        view
        returns (
            uint256 valueStaked,
            uint256 principalClaimed,
            uint256 rewardDistributed,
            uint256 referralPaidInToken,
            uint256 initialRewardsLockTimeLimit,
            uint256 principalClaimTimeLimit,
            uint256 principalClaimRate,
            uint16[] memory stakingReferralRates,
            uint16[] memory stakingRewardReferralRates,
            uint16 levelDecimals,
            bool isPayReferral,
            address tokenAddress,
            address baseCurrencyAddress,
            address uniswapV2RouterAddress
        )
    {
        valueStaked = _valueStaked;
        principalClaimed = _principalClaimed;
        rewardDistributed = _rewardsDistributed;
        referralPaidInToken = _referralPaidInToken;
        initialRewardsLockTimeLimit = _initialRewardsLockTimeLimit;
        principalClaimTimeLimit = _principalClaimTimeLimit;
        principalClaimRate = _principalClaimRate;
        stakingReferralRates = _stakingReferralRates;
        stakingRewardReferralRates = _stakingRewardReferralRates;
        levelDecimals = _decimals;
        isPayReferral = _isPayReferral;
        tokenAddress = _tokenAddress;
        baseCurrencyAddress = _baseCurrencyAddress;
        uniswapV2RouterAddress = _uniswapV2RouterAddress;
    }

    function setSupportedCurrencies(
        address _tokenContractAddress,
        address _baseCurrencyContractAddress
    ) external onlyOwner {
        _tokenAddress = _tokenContractAddress;
        _baseCurrencyAddress = _baseCurrencyContractAddress;
    }

    function setIsPayReferral(bool _trueOrFalse) external onlyOwner {
        _isPayReferral = _trueOrFalse;
    }

    function _convertDecimals(
        uint256 _value,
        uint8 _decimalsFrom,
        uint8 _decimalsTo
    ) private pure returns (uint256 _convertedValue) {
        if (_decimalsFrom != _decimalsTo) {
            _convertedValue = (_value * 10 ** _decimalsTo  / 10 ** _decimalsFrom);
        } else {
            _convertedValue = _value;
        }
    }

    function changeProviderAddress(address _address) external onlyOwner {
        _providerAddress = _address;
    }

    function withdrawTokens(
        address _token,
        address _receiver,
        uint256 _value
    ) external onlyOwner returns (bool) {
        IERC20Upgradeable(_token).transfer(_receiver, _value);
        return true;
    }

    function withdrawNativeFunds(
        address _receiver,
        uint256 _value
    ) external onlyOwner returns (bool) {
        payable(_receiver).transfer(_value);
        return true;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function _getCurrentTime() private view returns (uint256 currentTime) {
        currentTime = block.timestamp;
        return currentTime;
    }

    function _min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}