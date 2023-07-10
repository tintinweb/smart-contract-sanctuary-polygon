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

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IERC20_EXTENDED {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

interface IUniswapRouter {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);
}

struct PlanStruct {
    uint8 planId;
    string name;
    uint256 value;
    uint256 maxLimitMultiplier;
}

struct SupportedTokensStruct {
    address contractAddress;
    string name;
    string symbol;
    uint8 decimals;
    bool isStable;
    address aggregatorAddress;
    bool isEnaled;
}

struct AccountStruct {
    uint32 userId;
    address selfAddress;
    address ibpAddress;
    address referrerAddress;
    address[] refereeAddresses;
    address[] teamAddress;
    uint32[] teamLevels;
    uint256 selfBusiness;
    uint256 directBusiness;
    uint256 teamBusiness;
    uint256 maxLimit;
    uint256 currentLimit;
    uint256 referralRewards;
    uint256 globalRewards;
    uint256 weeklyRewards;
    uint256 ibpRewards;
    bool isGlobal;
    uint32[] globalIndexes;
}

interface IVariables {
    function getCoreMembersContractAddress() external view returns (address);

    function getLevelRates() external view returns (uint16[] memory);

    function getValueBufferRate() external view returns (uint8);

    function getCoreMemberRewardRate() external view returns (uint8);

    function getPlanById(
        uint8 _planId
    ) external view returns (PlanStruct memory);

    function getAdminAddress() external view returns (address);

    function getSupportedTokenInfo(
        address _tokenContractAddress
    ) external view returns (SupportedTokensStruct memory);

    function isIBP(address _ibpAddress) external view returns (bool);

    function getRewardTokenContract() external view returns (address);

    function getStakingContract() external view returns (address);

    function getUniSwapRouterV2Address() external view returns (address);

    function getMaticUSDPriceOracle() external view returns (address);
}

interface IStaking {
    function stake(address _userAddress, uint256 _value) external;
}

interface IChainlinkOracle {
    function latestAnswer() external view returns (uint256);

    function decimals() external view returns (uint256);
}

contract ReferralV1Upgradeable is
    Initializable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    address private _variableContractAddress;
    address[] private _globalAddresses;

    uint32 private _totalUsers;

    uint256 private _totalRegistrationValue;
    uint256 private _WeeklyRewardValue;
    uint256 private _weeklyRewardClaimedTimeStamp;

    uint256 private _totalReferralPaid;
    uint256 private _totalGlobalRewardsPaid;
    uint256 private _totalWeeklyRewardsPaid;
    uint256 private _totalCoreMembershipRewardPaid;
    uint256 private _totalIBPRewardsPaid;

    mapping(address => AccountStruct) private accounts;
    mapping(uint32 => address) private idToAddress;

    event Registration(
        address userAddress,
        uint32 userId,
        uint8 planId,
        address referrerAddress
    );
    event ReferrerAdded(address referrerAddress, address refereeAddress);
    event ReferrerNotAdded(
        address referrerAddress,
        address refereeAddress,
        string reason
    );

    event IBPAdded(address ibpAddress, address userAddress);
    event IBPNotAdded(address ibpAddress, address userAddress, string reason);

    event TeamAddressAdded(
        address parentAddress,
        address referrerAddress,
        address refereeAddress,
        uint32 level
    );
    event ReferralRewardsPaid(
        address referrerAddress,
        uint256 rewardValue,
        uint32 level
    );

    event GlobalRewardsPaid(address globalAddress, uint256 rewardValue);

    event WeeklyRewardsPaid(address globalAddress, uint256 rewardValue);

    event NoRewardsPaid(address userAddress, string reason);

    event IBPRewardsPaid(address ibpAddress, uint256 rewardValue);

    event CoreMembersRewardPaid(address coreMembersContract, uint256 value);

    bool private _registerRandom;

    uint256 _WeeklyRewardValueNative;

    receive() external payable {}

    function initialize() public initializer {
        _variableContractAddress = 0x494549e00FE6598E3DC93254c5377c406dDA8579;
        _weeklyRewardClaimedTimeStamp = block.timestamp;

        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _hasReferrer(
        AccountStruct memory userAccount
    ) private pure returns (bool hasReferrer) {
        if (userAccount.referrerAddress != address(0)) {
            hasReferrer = true;
        }
    }

    function _addReferrer(
        address _referrer,
        address _referee,
        uint8 _levelLength,
        IVariables variablesContractInterface
    ) private {
        AccountStruct storage userAccount = accounts[_referee];
        AccountStruct memory firstReferrerAccount = accounts[_referee];

        require(
            firstReferrerAccount.referrerAddress != _referee,
            "Referrer Upline Cannot be referrer downline."
        );

        require(
            _referee != _referrer,
            "Referrer & User address cannot be same."
        );

        if (_referrer == address(0)) {
            emit ReferrerNotAdded(
                _referrer,
                _referee,
                "Zero address cannot be referrer. Setting default referrer."
            );

            if (!_registerRandom) {
                address defaultReferrer = variablesContractInterface
                    .getAdminAddress();
                userAccount.referrerAddress = defaultReferrer;
                emit ReferrerAdded(defaultReferrer, _referee);
            } else {
                address randomAddress = _getRandomGlobalAddress();
                userAccount.referrerAddress = randomAddress;
                emit ReferrerAdded(randomAddress, _referee);
            }

            _registerRandom = !_registerRandom;
        } else {
            userAccount.referrerAddress = _referrer;
            emit ReferrerAdded(_referrer, _referee);
        }

        for (uint8 i; i < _levelLength; i++) {
            if (userAccount.referrerAddress == address(0)) {
                break;
            }

            AccountStruct storage referrerAccount = accounts[
                userAccount.referrerAddress
            ];

            if (i == 0) {
                if (referrerAccount.ibpAddress != address(0)) {
                    userAccount.ibpAddress = referrerAccount.ibpAddress;
                    emit IBPAdded(referrerAccount.ibpAddress, _referee);
                }
            }

            referrerAccount.teamAddress.push(_referee);
            referrerAccount.teamLevels.push(i + 1);

            userAccount = referrerAccount;
        }
    }

    function _getRandomGlobalAddress() private view returns (address) {
        uint256 randomHash = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.prevrandao,
                    blockhash(block.number - 1)
                )
            )
        );
        uint256 randomIndex = randomHash % _globalAddresses.length;
        return _globalAddresses[randomIndex];
    }

    function getRandomGlobalAddress() external view returns (address) {
        return _getRandomGlobalAddress();
    }

    function _isMaxLimitReached(
        AccountStruct memory userAccount
    ) private pure returns (bool isLimitReached) {
        if (userAccount.currentLimit >= userAccount.maxLimit) {
            isLimitReached = true;
        }
    }

    function _updateCurrentLimit(
        AccountStruct storage userAccount,
        uint256 _value
    ) private returns (uint256 _valueUpdated) {
        if (userAccount.currentLimit + _value < userAccount.maxLimit) {
            _valueUpdated = _value;
            userAccount.currentLimit += _valueUpdated;
        } else if (userAccount.currentLimit + _value == userAccount.maxLimit) {
            _valueUpdated = _value;
            userAccount.currentLimit += _valueUpdated;
        } else {
            _valueUpdated = userAccount.maxLimit - userAccount.currentLimit;
            userAccount.currentLimit = userAccount.maxLimit;
        }
    }

    function _updateId(AccountStruct storage userAccount) private {
        if (userAccount.userId == 0) {
            _totalUsers++;
            userAccount.userId = _totalUsers;
            idToAddress[userAccount.userId] = userAccount.selfAddress;
        }
    }

    function _updateGlobalReward(
        address globalAddress,
        uint256 _valueInUSD
    ) private returns (uint256 globalRewardValue) {
        AccountStruct storage globalAddressAccount = accounts[globalAddress];
        globalRewardValue = _updateCurrentLimit(
            globalAddressAccount,
            (_valueInUSD * 10) / 100
        );

        if (globalRewardValue > 0) {
            globalAddressAccount.globalRewards += globalRewardValue;

            emit GlobalRewardsPaid(
                globalAddressAccount.selfAddress,
                globalRewardValue
            );

            _totalGlobalRewardsPaid += globalRewardValue;
        }
    }

    function _updateIbpReward(
        address _ibpAddress,
        uint256 _valueInUSD
    ) private returns (uint256 ibpReward) {
        AccountStruct storage ibpAccount = accounts[_ibpAddress];
        ibpReward = _updateCurrentLimit(ibpAccount, (_valueInUSD * 5) / 100);
        if (ibpReward > 0) {
            ibpAccount.ibpRewards += ibpReward;
            emit IBPRewardsPaid(_ibpAddress, ibpReward);
            _totalIBPRewardsPaid += ibpReward;
        }
    }

    function _updateReferralReward(
        IVariables _varInt,
        AccountStruct storage _referrerAccount,
        uint256 _valueInUSD,
        uint16[] memory _levelRates,
        uint32 _i
    ) private returns (uint256 referralRewardValue) {
        if (_i == 0) {
            _referrerAccount.directBusiness += _valueInUSD;

            if (
                _referrerAccount.isGlobal &&
                _referrerAccount.selfAddress != address(0) &&
                _referrerAccount.selfAddress != _varInt.getAdminAddress()
            ) {
                _globalAddresses.push(_referrerAccount.selfAddress);
                _referrerAccount.globalIndexes.push(
                    uint32(_globalAddresses.length - 1)
                );

                _referrerAccount.isGlobal = !_referrerAccount.isGlobal;
            }
        }

        _referrerAccount.teamBusiness += _valueInUSD;

        referralRewardValue = _updateCurrentLimit(
            _referrerAccount,
            (_valueInUSD * _levelRates[_i]) / 10000
        );

        if (referralRewardValue > 0) {
            _referrerAccount.referralRewards += referralRewardValue;
            emit ReferralRewardsPaid(
                _referrerAccount.selfAddress,
                referralRewardValue,
                _i + 1
            );
        }
    }

    function _updateCoreMembersReward(
        uint256 _valueInUSD,
        address _coreMembersContract
    ) private returns (uint256 coreRewardValue) {
        coreRewardValue = (_valueInUSD * 5) / 100;
        _totalCoreMembershipRewardPaid += coreRewardValue;
        emit CoreMembersRewardPaid(_coreMembersContract, coreRewardValue);
    }

    function _registration(
        address _referrer,
        address _referee,
        uint8 _planId,
        address _tokenAddress
    ) private {
        IVariables varInt = IVariables(_variableContractAddress);
        PlanStruct memory planS = varInt.getPlanById(_planId);
        require(planS.value > 0, "Value is zero. Please select correct plan.");
        SupportedTokensStruct memory tokenS = varInt.getSupportedTokenInfo(
            _tokenAddress
        );

        require(tokenS.isEnaled, "Token is not supported");
        IERC20Upgradeable iercInt = IERC20Upgradeable(_tokenAddress);

        uint16[] memory _levelRates = varInt.getLevelRates();

        iercInt.transferFrom(
            _referee,
            address(this),
            tokenS.decimals < 18
                ? _toTokenDecimals(planS.value, 18, tokenS.decimals)
                : planS.value
        );

        AccountStruct storage userAccount = accounts[_referee];

        uint256 rewardTokenBalanceThis = IERC20Upgradeable(
            varInt.getRewardTokenContract()
        ).balanceOf(address(this));

        if (
            rewardTokenBalanceThis > planS.value &&
            userAccount.selfBusiness == 0
        ) {
            uint256 stakingValue = planS.value / 2;
            IStaking(varInt.getStakingContract()).stake(_referee, stakingValue);

            IERC20Upgradeable(varInt.getRewardTokenContract()).transfer(
                varInt.getStakingContract(),
                planS.value
            );
        }

        userAccount.selfAddress = _referee;
        userAccount.selfBusiness += planS.value;
        userAccount.maxLimit += planS.value * planS.maxLimitMultiplier;

        _updateId(userAccount);

        if (!_hasReferrer(userAccount)) {
            _addReferrer(
                _referrer,
                _referee,
                uint8(_levelRates.length),
                varInt
            );
        }

        emit Registration(
            userAccount.selfAddress,
            userAccount.userId,
            _planId,
            userAccount.referrerAddress
        );

        address globalAddress = _getRandomGlobalAddress();

        if (globalAddress != address(0)) {
            uint256 globalRewardValue = _updateGlobalReward(
                globalAddress,
                planS.value
            );

            if (globalRewardValue > 0) {
                iercInt.transfer(
                    globalAddress,
                    tokenS.decimals < 18
                        ? _toTokenDecimals(
                            globalRewardValue,
                            18,
                            tokenS.decimals
                        )
                        : globalRewardValue
                );
            }
        }

        if (userAccount.ibpAddress != address(0)) {
            uint256 ibpRewardValue = _updateIbpReward(
                userAccount.ibpAddress,
                planS.value
            );

            if (ibpRewardValue > 0) {
                iercInt.transfer(
                    userAccount.ibpAddress,
                    tokenS.decimals < 18
                        ? _toTokenDecimals(ibpRewardValue, 18, tokenS.decimals)
                        : ibpRewardValue
                );
            }
        }

        uint256 totalReferralPaid;

        for (uint8 i; i < _levelRates.length; i++) {
            if (!_hasReferrer(userAccount)) {
                break;
            }

            AccountStruct storage referrerAccount = accounts[
                userAccount.referrerAddress
            ];

            uint256 referralValue = _updateReferralReward(
                varInt,
                referrerAccount,
                planS.value,
                _levelRates,
                i
            );

            if (referralValue > 0) {
                iercInt.transfer(
                    userAccount.referrerAddress,
                    tokenS.decimals < 18
                        ? _toTokenDecimals(referralValue, 18, tokenS.decimals)
                        : referralValue
                );

                totalReferralPaid += referralValue;
            }

            userAccount = referrerAccount;
        }

        _totalReferralPaid += totalReferralPaid;
        _totalRegistrationValue += planS.value;
        _WeeklyRewardValue += (planS.value * 10) / 100;

        uint256 coreMembersReward = (planS.value * 5) / 100;

        iercInt.transfer(
            varInt.getCoreMembersContractAddress(),
            tokenS.decimals < 18
                ? _toTokenDecimals(coreMembersReward, 18, tokenS.decimals)
                : coreMembersReward
        );

        _totalCoreMembershipRewardPaid += coreMembersReward;

        emit CoreMembersRewardPaid(
            varInt.getCoreMembersContractAddress(),
            tokenS.decimals < 18
                ? _toTokenDecimals(coreMembersReward, 18, tokenS.decimals)
                : tokenS.decimals
        );
    }

    function _registrationWithNative(
        address _referrer,
        address _referee,
        uint8 _planId,
        uint256 _msgValue
    ) private {
        IVariables varInt = IVariables(_variableContractAddress);
        PlanStruct memory planS = varInt.getPlanById(_planId);
        uint256 priceInUSD = _usdPrice(varInt.getMaticUSDPriceOracle());
        uint256 msgValueInUSD = _weiToUSD(_msgValue, priceInUSD);
        require(planS.value > 0, "Value is zero. Please select correct plan.");
        require(
            msgValueInUSD > planS.value - (planS.value * 5) / 100,
            "Native value is less 5% of price.s"
        );

        uint16[] memory _levelRates = varInt.getLevelRates();

        AccountStruct storage userAccount = accounts[_referee];

        uint256 rewardTokenBalanceThis = IERC20Upgradeable(
            varInt.getRewardTokenContract()
        ).balanceOf(address(this));

        if (
            rewardTokenBalanceThis > msgValueInUSD &&
            userAccount.selfBusiness == 0
        ) {
            uint256 stakingValue = msgValueInUSD / 2;
            IStaking(varInt.getStakingContract()).stake(_referee, stakingValue);

            IERC20Upgradeable(varInt.getRewardTokenContract()).transfer(
                varInt.getStakingContract(),
                msgValueInUSD
            );
        }

        userAccount.selfAddress = _referee;
        userAccount.selfBusiness += msgValueInUSD;
        userAccount.maxLimit += msgValueInUSD * planS.maxLimitMultiplier;

        _updateId(userAccount);

        if (!_hasReferrer(userAccount)) {
            _addReferrer(
                _referrer,
                _referee,
                uint8(_levelRates.length),
                varInt
            );
        }

        emit Registration(
            userAccount.selfAddress,
            userAccount.userId,
            _planId,
            userAccount.referrerAddress
        );

        address globalAddress = _getRandomGlobalAddress();

        if (globalAddress != address(0)) {
            uint256 globalRewardValueUSD = _updateGlobalReward(
                globalAddress,
                msgValueInUSD
            );

            if (globalRewardValueUSD > 0) {
                payable(globalAddress).transfer(
                    _usdToWei(globalRewardValueUSD, priceInUSD)
                );
            }
        }

        if (userAccount.ibpAddress != address(0)) {
            uint256 ibpRewardValueUSD = _updateIbpReward(
                userAccount.ibpAddress,
                _msgValue
            );

            if (ibpRewardValueUSD > 0) {
                payable(userAccount.ibpAddress).transfer(
                    _usdToWei(ibpRewardValueUSD, priceInUSD)
                );
            }
        }

        uint256 totalReferralPaid;

        for (uint8 i; i < _levelRates.length; i++) {
            if (!_hasReferrer(userAccount)) {
                break;
            }

            AccountStruct storage referrerAccount = accounts[
                userAccount.referrerAddress
            ];

            uint256 referralValueUSD = _updateReferralReward(
                varInt,
                referrerAccount,
                _msgValue,
                _levelRates,
                i
            );

            if (referralValueUSD > 0) {
                payable(userAccount.referrerAddress).transfer(
                    _usdToWei(referralValueUSD, priceInUSD)
                );
                totalReferralPaid += referralValueUSD;
            }

            userAccount = referrerAccount;
        }

        payable(varInt.getCoreMembersContractAddress()).transfer(
            _updateCoreMembersReward(
                _msgValue,
                varInt.getCoreMembersContractAddress()
            )
        );

        _totalReferralPaid += totalReferralPaid;
        _totalRegistrationValue += msgValueInUSD;
        _WeeklyRewardValueNative += (_msgValue * 10) / 100;
    }

    function registrationWithToken(
        address _referrer,
        uint8 _planId,
        address _tokenAddress
    ) external {
        address _msgSender = msg.sender;
        _registration(_referrer, _msgSender, _planId, _tokenAddress);
    }

    function registrationWithNative(
        address _referrer,
        uint8 _planId
    ) external payable {
        _registrationWithNative(_referrer, msg.sender, _planId, msg.value);
    }

    function getRegistrationsStats()
        external
        view
        returns (
            uint32 totalUser,
            uint256 totalRegistrationValue,
            uint256 totalReferralPaid,
            uint256 totalGlobalRewardsPaid,
            uint256 totalWeeklyRewardsPaid,
            uint256 totalCoreMembershipRewardPaid,
            uint256 totalIbpRewardsPaid
        )
    {
        totalUser = _totalUsers;
        totalRegistrationValue = _totalRegistrationValue;
        totalReferralPaid = _totalReferralPaid;
        totalGlobalRewardsPaid = _totalGlobalRewardsPaid;
        totalWeeklyRewardsPaid = _totalWeeklyRewardsPaid;
        totalCoreMembershipRewardPaid = _totalCoreMembershipRewardPaid;
        totalIbpRewardsPaid = _totalIBPRewardsPaid;
    }

    function getWeeklyRewardToBeDistributed()
        external
        view
        returns (uint256 _rewardValue, uint256 _remianingTime, uint256 _endTime)
    {
        _rewardValue = _WeeklyRewardValue;
        _endTime = _weeklyRewardClaimedTimeStamp + 7 days;
        uint256 _currentTime = block.timestamp;
        if (_endTime > _currentTime) {
            _remianingTime = _endTime - _currentTime;
        }
    }

    function distributeWeeklyReward(address _tokenAddress) external {
        uint256 weeklyCounterEndTime = _weeklyRewardClaimedTimeStamp + 7 days;
        uint256 _currentTime = block.timestamp;
        require(
            _currentTime >= weeklyCounterEndTime,
            "Weekly time is not over yet."
        );
        address globalAddress = _getRandomGlobalAddress();
        AccountStruct storage globalAddressAccount = accounts[globalAddress];

        IVariables variablesInterface = IVariables(_variableContractAddress);
        SupportedTokensStruct memory tokenAccount = variablesInterface
            .getSupportedTokenInfo(_tokenAddress);

        uint256 weeklyRewardValue = _updateCurrentLimit(
            globalAddressAccount,
            _WeeklyRewardValue
        );

        if (weeklyRewardValue > 0) {
            globalAddressAccount.weeklyRewards += weeklyRewardValue;

            IERC20Upgradeable(_tokenAddress).transfer(
                globalAddress,
                tokenAccount.decimals < 18
                    ? _toTokenDecimals(
                        weeklyRewardValue,
                        18,
                        tokenAccount.decimals
                    )
                    : weeklyRewardValue
            );

            _WeeklyRewardValue = 0;
            _weeklyRewardClaimedTimeStamp = block.timestamp;
            _totalWeeklyRewardsPaid += weeklyRewardValue;
            emit WeeklyRewardsPaid(globalAddress, weeklyRewardValue);
        }
    }

    function getUserAccount(
        address _userAddress
    ) external view returns (AccountStruct memory) {
        return accounts[_userAddress];
    }

    function getUserTeam(
        address _userAddress
    )
        external
        view
        returns (
            address referrer,
            address[] memory referees,
            uint256 refereeCount,
            address[] memory team,
            uint32[] memory teamLevels,
            uint256 teamCount
        )
    {
        AccountStruct memory userAccount = accounts[_userAddress];
        referrer = userAccount.referrerAddress;
        referees = userAccount.refereeAddresses;
        refereeCount = userAccount.refereeAddresses.length;
        team = userAccount.teamAddress;
        teamLevels = userAccount.teamLevels;
        teamCount = userAccount.teamAddress.length;
    }

    //getUserTotalBusiness
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
        AccountStruct memory userAccount = accounts[_userAddress];
        selfBusiness = userAccount.selfBusiness;
        directBusiness = userAccount.directBusiness;
        teamBusiness = userAccount.teamBusiness;
        totalBusiness = userAccount.teamBusiness + userAccount.selfBusiness;
    }

    //getUserRewards
    function getUserRewards(
        address _userAddress
    )
        external
        view
        returns (
            uint256 referralReward,
            uint256 globalReward,
            uint256 weeklyReward,
            uint256 ibpReward,
            uint256 totalIncome
        )
    {
        AccountStruct memory userAccount = accounts[_userAddress];
        referralReward = userAccount.referralRewards;
        globalReward = userAccount.globalRewards;
        weeklyReward = userAccount.weeklyRewards;
        ibpReward = userAccount.ibpRewards;
        totalIncome = userAccount.currentLimit;
    }

    function isUserInGlobalList(
        address _userAddress
    )
        external
        view
        returns (bool isInList, uint32[] memory indexes, uint256 totalGlobalIds)
    {
        AccountStruct memory userAccount = accounts[_userAddress];

        if (userAccount.globalIndexes.length > 0) {
            isInList = true;
        }

        indexes = userAccount.globalIndexes;
        totalGlobalIds = userAccount.globalIndexes.length;
    }

    //getUserLimits
    function getUserLimit(
        address _userAddress
    )
        external
        view
        returns (
            uint256 maxLimit,
            uint256 currentLimit,
            uint256 limitRemaingvalue
        )
    {
        AccountStruct memory userAccount = accounts[_userAddress];

        maxLimit = userAccount.maxLimit;
        currentLimit = userAccount.currentLimit;
        limitRemaingvalue = userAccount.maxLimit - userAccount.currentLimit;
    }

    //ibp functions
    function getUserIbpAddress(
        address _userAddress
    ) external view returns (address) {
        return accounts[_userAddress].ibpAddress;
    }

    function addIbpToAddressAdmin(
        address _userAddress,
        address _ibpAddress,
        uint256 _maxLimitInDecimals
    ) external onlyOwner {
        accounts[_userAddress].ibpAddress = _ibpAddress;
        accounts[_userAddress].maxLimit += _maxLimitInDecimals * 10 ** 18;
        emit IBPAdded(_ibpAddress, _userAddress);
    }

    function setWeeklyDetails(
        uint256 _valueToAddInWei,
        uint256 _timeInSeconds
    ) external onlyOwner {
        _weeklyRewardClaimedTimeStamp = _timeInSeconds;
        _WeeklyRewardValue += _valueToAddInWei;
    }

    function removeAdminAddressFromGlobalList() external {
        address adminAddress = IVariables(_variableContractAddress)
            .getAdminAddress();
        address[] memory globalList = _globalAddresses;
        uint256 globalAddressCount = globalList.length;

        for (uint256 i; i < globalAddressCount; i++) {
            if (_globalAddresses[i] == adminAddress) {
                _globalAddresses[i] = _globalAddresses[
                    _globalAddresses.length - 1
                ];
                _globalAddresses.pop();
            }

            if (i > 0 && i - 1 == _globalAddresses.length) {
                break;
            }
        }
    }

    // function updateAllAddressIBP(
    //     uint32 _idFrom,
    //     uint32 _idTo,
    //     address _ibpAddress,
    //     address _ibpAddressToIgnore
    // ) external onlyOwner {
    //     for (uint32 i = _idFrom; i <= _idTo; i++) {
    //         address userAddress = idToAddress[i];
    //         if (accounts[userAddress].ibpAddress != _ibpAddressToIgnore) {
    //             accounts[userAddress].ibpAddress = _ibpAddress;
    //             emit IBPAdded(_ibpAddress, userAddress);
    //         }
    //     }
    // }

    // function removeIbpFromAddressAdmin(
    //     address _userAddress
    // ) external onlyOwner {
    //     accounts[_userAddress].ibpAddress = IVariables(_variableContractAddress)
    //         .getAdminAddress();

    //     emit IBPAdded(
    //         IVariables(_variableContractAddress).getAdminAddress(),
    //         _userAddress
    //     );
    // }

    // function _removeReferee(
    //     AccountStruct storage _referrerAccount,
    //     address _refereeAddress
    // ) private {
    //     if (_referrerAccount.selfAddress != address(0)) {
    //         uint256 referrerRefereeCount = _referrerAccount
    //             .refereeAddresses
    //             .length;

    //         for (uint256 i; i < referrerRefereeCount; i++) {
    //             if (_referrerAccount.refereeAddresses[i] == _refereeAddress) {
    //                 _referrerAccount.refereeAddresses[i] = _referrerAccount
    //                     .refereeAddresses[
    //                         _referrerAccount.refereeAddresses.length - 1
    //                     ];
    //                 _referrerAccount.refereeAddresses.pop();
    //             }

    //             if (
    //                 _referrerAccount.refereeAddresses.length == 0 ||
    //                 i == _referrerAccount.refereeAddresses.length - 1
    //             ) {
    //                 break;
    //             }
    //         }
    //     }
    // }

    // function removeRefereeAdmin(address _refereeAddress) external onlyOwner {
    //     AccountStruct storage refereeAccount = accounts[_refereeAddress];

    //     AccountStruct storage prevReferrerAccount = accounts[
    //         refereeAccount.referrerAddress
    //     ];

    //     _removeReferee(prevReferrerAccount, _refereeAddress);
    // }

    // function _removeTeamAddress(
    //     AccountStruct storage _referrerAccount,
    //     address _teamAddress
    // ) private {
    //     if (_referrerAccount.selfAddress != address(0)) {
    //         uint256 referrerTeamCount = _referrerAccount.teamAddress.length;

    //         for (uint256 i; i < referrerTeamCount; i++) {
    //             if (_referrerAccount.refereeAddresses[i] == _teamAddress) {
    //                 _referrerAccount.teamAddress[i] = _referrerAccount
    //                     .teamAddress[_referrerAccount.teamAddress.length - 1];
    //                 _referrerAccount.teamAddress.pop();
    //             }

    //             if (
    //                 _referrerAccount.teamAddress.length == 0 ||
    //                 i == (_referrerAccount.teamAddress.length - 1)
    //             ) {
    //                 break;
    //             }
    //         }
    //     }
    // }

    // function removeTeamAddress(address _userAddress, address _teamAddress) external onlyOwner {
    //     IVariables variablesInterface = IVariables(_variableContractAddress);
    //     uint16[] memory _levelRates = variablesInterface.getLevelRates();
    //     AccountStruct storage refereeAccount = accounts[_teamAddress];

    //     AccountStruct storage prevReferrerAccount = accounts[
    //         refereeAccount.referrerAddress
    //     ];

    //     for (uint16 i; i < _levelRates.length; i++) {
    //         _removeTeamAddress(prevReferrerAccount, _teamAddress);
    //     }
    // }

    // function updateUserAccount(
    //     address _userAddress,
    //     uint256 _referralIncome,
    //     uint256 _limit,
    //     uint256 _directBusiness,
    //     uint256 _teamBusiness
    // ) external onlyOwner {
    //     AccountStruct storage userAccount = accounts[_userAddress];

    //     userAccount.directBusiness += _directBusiness;
    //     userAccount.referralRewards += _referralIncome;
    //     userAccount.currentLimit += _limit;
    //     userAccount.teamBusiness += _teamBusiness;
    // }

    // function changeReferrer(
    //     address _referrer,
    //     address _user
    // ) external onlyOwner {
    //     IVariables variablesInterface = IVariables(_variableContractAddress);
    //     AccountStruct storage userAccount = accounts[_user];

    //     uint16[] memory _levelRates = variablesInterface.getLevelRates();

    //     userAccount.referrerAddress = address(0);

    //     _addReferrer(
    //         _referrer,
    //         _user,
    //         uint8(_levelRates.length),
    //         variablesInterface
    //     );
    // }

    function getVariablesContract() external view returns (address) {
        return _variableContractAddress;
    }

    // function setVariablesContract(address _contractAddress) external onlyOwner {
    //     _variableContractAddress = _contractAddress;
    // }

    // function pushAddressToGlobal(address _userAddress) external onlyOwner {
    //     accounts[_userAddress].isGlobal = true;
    //     accounts[_userAddress].globalIndexes.push(
    //         uint32(_globalAddresses.length - 1)
    //     );
    //     _globalAddresses.push(_userAddress);
    // }

    function getGlobalAddress()
        external
        view
        returns (address[] memory globalAddress, uint256 globalAddressCount)
    {
        globalAddress = _globalAddresses;
        globalAddressCount = _globalAddresses.length;
    }

    function _toTokenDecimals(
        uint256 _value,
        uint256 _from,
        uint256 _to
    ) private pure returns (uint256) {
        return (_value * 10 ** _to) / 10 ** _from;
    }

    function _usdPrice(
        address _oracleContractAddress
    ) private view returns (uint256 _priceInWei) {
        _priceInWei =
            IChainlinkOracle(_oracleContractAddress).latestAnswer() *
            10 ** 10;
    }

    function _weiToUSD(
        uint256 _valueInWei,
        uint256 _priceInUSD
    ) private pure returns (uint256) {
        return _valueInWei * _priceInUSD;
    }

    function _usdToWei(
        uint256 _valueInUSD,
        uint256 _priceInUSD
    ) private pure returns (uint256) {
        return _valueInUSD / _priceInUSD;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}