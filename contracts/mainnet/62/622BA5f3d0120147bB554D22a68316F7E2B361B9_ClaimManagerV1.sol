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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import './IBountyCore.sol';

/// @title IAtomicBounty
/// @author FlacoJones
/// @notice Interface defining AtomicBounty specific methods
interface IAtomicBounty is IBountyCore {
    /// @notice Changes bounty status from 0 (OPEN) to 1 (CLOSED)
    /// @param _payoutAddress The closer of the bounty
    /// @param _closerData ABI-encoded data about the claimant and claimant asset
    /// @dev _closerData (address,string,address,string,uint256)
    /// @dev _closerData (bountyAddress, externalUserId, closer, claimantAsset, tier)
    function close(address _payoutAddress, bytes calldata _closerData) external;

    /// @notice Transfers full balance of _tokenAddress from bounty to _payoutAddress
    /// @param _tokenAddress ERC20 token address or Zero Address for protocol token
    /// @param _payoutAddress The destination address for the funds
    function claimBalance(address _payoutAddress, address _tokenAddress)
        external
        returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import './IAtomicBounty.sol';
import './ITieredFixedBounty.sol';

/// @title IBounty
/// @author FlacoJones
/// @notice Interface aggregating all bounty type interfaces for use in OpenQ, ClaimManager and DepositManager
interface IBounty is IAtomicBounty, ITieredFixedBounty {

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import '../../Library/OpenQDefinitions.sol';
import '@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol';

/// @title IBountyCore
/// @author FlacoJones
/// @notice Interface defining BountyCore methods shared across all bounty types
interface IBountyCore {
    /// @notice Initializes a bounty proxy with initial state
    /// @param _bountyId The unique bounty identifier
    /// @param _issuer The sender of the mint bounty transaction
    /// @param _organization The organization associated with the bounty
    /// @param _openQ The OpenQProxy address
    /// @param _claimManager The Claim Manager proxy address
    /// @param _depositManager The Deposit Manager proxy address
    /// @param _operation The ABI encoded data determining the type of bounty being initialized and associated data
    /// @dev ATOMIC
    /// @dev _operation (bool,address,uint256,bool,bool,bool,string,string,string)
    /// @dev _operation (hasFundingGoal, fundingToken, fundingGoal, invoiceRequired, kycRequired, supportingDocumentsRequired, issuerExternalUserId, alternativeLogo, alternativeName)
    /// @dev ONGOING
    /// @dev _operation (address,uint256,bool,address,uint256,bool,bool,bool,string,string,string)
    /// @dev _operation (payoutTokenAddress, payoutVolume, hasFundingGoal, fundingToken, fundingGoal, invoiceRequired, kycRequired, supportingDocumentsRequired, issuerExternalUserId, alternativeName, alternativeLogo)
    /// @dev TIERED PERCENTAGE
    /// @dev _operation (uint256[],bool,address,uint256,bool,bool,bool,string,string,string)
    /// @dev _operation (payoutSchedule, hasFundingGoal, fundingToken, fundingGoal, invoiceRequired, kycRequired, supportingDocumentsRequired, issuerExternalUserId, alternativeName, alternativeLogo)
    /// @dev TIERED FIXED
    /// @dev _operation (uint256[],address,bool,bool,bool,string,string,string)
    /// @dev _operation (payoutSchedule, payoutTokenAddress, invoiceRequired, kycRequired, supportingDocumentsRequired, issuerExternalUserId, alternativeName, alternativeLogo)
    function initialize(
        string memory _bountyId,
        address _issuer,
        string memory _organization,
        address _openQ,
        address _claimManager,
        address _depositManager,
        OpenQDefinitions.InitOperation memory _operation
    ) external;

    /// @notice Creates a deposit and transfers tokens from msg.sender to this contract
    /// @param _funder The funder's address
    /// @param _tokenAddress The ERC20 token address (ZeroAddress if funding with protocol token)
    /// @param _volume The volume of token to transfer
    /// @param _expiration The duration until the deposit becomes refundable
    /// @return (depositId, volumeReceived) Returns the deposit id and the amount transferred to bounty
    function receiveFunds(
        address _funder,
        address _tokenAddress,
        uint256 _volume,
        uint256 _expiration
    ) external payable returns (bytes32, uint256);

    /// @notice Transfers volume of deposit from bounty to funder
    /// @param _depositId The deposit to refund
    /// @param _funder The initial funder of the deposit
    /// @param _volume The volume to be refunded
    function refundDeposit(
        bytes32 _depositId,
        address _funder,
        uint256 _volume
    ) external;

    /// @notice Extends deposit duration
    /// @param _depositId The deposit to extend
    /// @param _seconds Number of seconds to extend deposit
    /// @param _funder The initial funder of the deposit
    function extendDeposit(
        bytes32 _depositId,
        uint256 _seconds,
        address _funder
    ) external returns (uint256);

    /// @notice Sets the funding goal
    /// @param _fundingToken Token address for funding goal
    /// @param _fundingGoal Token volume for funding goal
    function setFundingGoal(address _fundingToken, uint256 _fundingGoal)
        external;

    /// @notice Whether or not KYC is required to fund and claim the bounty
    /// @param _kycRequired Whether or not KYC is required to fund and claim the bounty
    function setKycRequired(bool _kycRequired) external;

    /// @notice Whether or not the Bounty is invoiceRequired
    /// @param _invoiceRequired Whether or not the Bounty is invoiceRequired
    function setInvoiceRequired(bool _invoiceRequired) external;

    /// @notice Whether or not KYC is required to fund and claim the bounty
    /// @param _supportingDocumentsRequired Whether or not KYC is required to fund and claim the bounty
    function setSupportingDocumentsRequired(bool _supportingDocumentsRequired)
        external;

    /// @notice Whether or not invoice has been completed
    /// @param _data ABI encoded data
    /// @dev _data (ATOMIC): (bool):(invoiceComplete)
    /// @dev _data (TIERED): (uint256,bool):(tier,invoiceComplete)
    /// @dev _data (ONGOING): (bytes32,bool):(claimId, invoiceComplete)
    function setInvoiceComplete(bytes calldata _data) external;

    /// @notice Whether or not supporting documents have been completed
    /// @param _data ABI encoded data
    /// @dev _data (ATOMIC): (bool):(supportingDocumentsComplete)
    /// @dev _data (TIERED): (uint256,bool):(tier,supportingDocumentsComplete)
    /// @dev _data (ONGOING): (bytes32,bool):(claimId, supportingDocumentsComplete)
    function setSupportingDocumentsComplete(bytes calldata _data) external;

    /// @notice Generic method that returns the ABI encoded supporting documents completion data from all bounty types
    /// @dev See the getSupportingDocumentsComplete defined on each bounty type to see the encoding
    function getSupportingDocumentsComplete()
        external
        view
        returns (bytes memory);

    /// @notice Generic method that returns the ABI encoded invoice completion data from all bounty types
    /// @dev See the getInvoiceComplete defined on each bounty type to see the encoding
    function getInvoiceComplete() external view returns (bytes memory);

    /// @notice Returns token balance for both ERC20 or protocol token
    /// @param _tokenAddress Address of an ERC20 or Zero Address for protocol token
    function getTokenBalance(address _tokenAddress)
        external
        view
        returns (uint256);

    /// @notice Returns an array of all ERC20 token addresses which have funded this bounty
    /// @return tokenAddresses An array of all ERC20 token addresses which have funded this bounty
    function getTokenAddresses() external view returns (address[] memory);

    /// @notice Returns the total number of unique tokens deposited on the bounty
    /// @return tokenAddressesCount The length of the array of all ERC20 token addresses which have funded this bounty
    function getTokenAddressesCount() external view returns (uint256);

    // PUBLIC GETTERS
    function bountyId() external view returns (string memory);

    function bountyCreatedTime() external view returns (uint256);

    function bountyClosedTime() external view returns (uint256);

    function issuer() external view returns (address);

    function organization() external view returns (string memory);

    function closer() external view returns (address);

    function status() external view returns (uint256);

    function funder(bytes32) external view returns (address);

    function tokenAddress(bytes32) external view returns (address);

    function volume(bytes32) external view returns (uint256);

    function depositTime(bytes32) external view returns (uint256);

    function refunded(bytes32) external view returns (bool);

    function payoutAddress(bytes32) external view returns (address);

    function tokenId(bytes32) external view returns (uint256);

    function expiration(bytes32) external view returns (uint256);

    function deposits(uint256) external view returns (bytes32);

    function closerData() external view returns (bytes memory);

    function bountyType() external view returns (uint256);

    function hasFundingGoal() external view returns (bool);

    function fundingToken() external view returns (address);

    function fundingGoal() external view returns (uint256);

    function invoiceRequired() external view returns (bool);

    function kycRequired() external view returns (bool);

    function supportingDocumentsRequired() external view returns (bool);

    function issuerExternalUserId() external view returns (string memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import './IBountyCore.sol';

/// @title ITieredBounty
/// @author FlacoJones
/// @notice Interface defining TieredBounty methods shared between TieredPercentageBounty and TieredFixedBounty
interface ITieredBounty is IBountyCore {
    /// @notice Sets a winner for a particular tier
    /// @param _tier The tier they won
    /// @param _winner The external UUID (e.g. an OpenQ User UUID) that won this tier
    function setTierWinner(string memory _winner, uint256 _tier) external;

    /// @notice Sets the payout schedule
    /// @param _payoutSchedule An array of payout volumes for each tier
    function setPayoutSchedule(uint256[] calldata _payoutSchedule) external;

    /// @notice Similar to close() for single priced bounties. closeCompetition() freezes the current funds for the competition.
    function closeCompetition() external;

    /// @notice Sets tierClaimed to true for the given tier
    /// @param _tier The tier being claimed
    function setTierClaimed(uint256 _tier) external;

    /// @notice Transfers the tiered percentage of the token balance of _tokenAddress from bounty to _payoutAddress
    /// @param _payoutAddress The destination address for the fund
    /// @param _tier The ordinal of the claimant (e.g. 1st place, 2nd place)
    /// @param _tokenAddress The token address being claimed
    function claimTiered(
        address _payoutAddress,
        uint256 _tier,
        address _tokenAddress
    ) external returns (uint256);

    // PUBLIC GETTERS
    function tierClaimed(uint256 _tier) external view returns (bool);

    function tierWinners(uint256) external view returns (string memory);

    function invoiceComplete(uint256) external view returns (bool);

    function supportingDocumentsComplete(uint256) external view returns (bool);

    function tier(bytes32) external view returns (uint256);

    function getPayoutSchedule() external view returns (uint256[] memory);

    function getTierWinners() external view returns (string[] memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import './IBountyCore.sol';
import './ITieredBounty.sol';

/// @title ITieredFixedBounty
/// @author FlacoJones
/// @notice Interface defining TieredFixedBounty specific methods
interface ITieredFixedBounty is IBountyCore, ITieredBounty {
    /// @notice Sets the payout schedule
    /// @param _payoutSchedule An array of payout volumes for each tier
    /// @param _payoutTokenAddress The address of the token to be used for the payout
    function setPayoutScheduleFixed(
        uint256[] calldata _payoutSchedule,
        address _payoutTokenAddress
    ) external;

    /// @notice Transfers the fixed amount of balance associated with the tier
    /// @param _payoutAddress The destination address for the fund
    /// @param _tier The ordinal of the claimant (e.g. 1st place, 2nd place)
    function claimTieredFixed(address _payoutAddress, uint256 _tier)
        external
        returns (uint256);

    function payoutTokenAddress() external returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import '../Storage/ClaimManagerStorage.sol';
import '../../Bounty/Interfaces/IAtomicBounty.sol';
import '../../Bounty/Interfaces/ITieredBounty.sol';

/// @title ClaimManagerV1
/// @author FlacoJones
/// @notice Sole contract authorized to attempt claims on all bounty types
/// @dev Emitter of all claim-related events
/// @dev Some claim methods are onlyOracle protected, others have exclusively on-chain claim criteria
contract ClaimManagerV1 is ClaimManagerStorageV1 {
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the ClaimManager implementation with oracle address
    /// @param _oracle The address of the oracle authorized to call onlyOracle methods (e.g. claimBounty)
    /// @dev Can only be called once thanks to initializer (https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializers)
    function initialize(
        address _oracle,
        address _openQ,
        address _kyc
    ) external initializer onlyProxy {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __Oraclize_init(_oracle);
        __Pausable_init();

        openQ = _openQ;
        kyc = _kyc;
    }

    /// @notice Calls appropriate claim method based on bounty type
    /// @param _bountyAddress The payout address of the bounty
    /// @param _closer The payout address of the claimant
    /// @param _closerData ABI Encoded data associated with this claim
    /// @dev see IAtomicBounty.close(_closerData) for _closerData ABI encoding schema
    function claimBounty(
        address _bountyAddress,
        address _closer,
        bytes calldata _closerData
    ) external onlyOracle onlyProxy {
        IBounty bounty = IBounty(payable(_bountyAddress));
        uint256 _bountyType = bounty.bountyType();

        if (_bountyType == OpenQDefinitions.ATOMIC) {
            // Decode to ensure data meets closerData schema before emitting any events
            abi.decode(_closerData, (address, string, address, string));

            _claimAtomicBounty(bounty, _closer, _closerData);
            bounty.close(_closer, _closerData);

            emit BountyClosed(
                bounty.bountyId(),
                _bountyAddress,
                bounty.organization(),
                _closer,
                block.timestamp,
                bounty.bountyType(),
                _closerData,
                VERSION_1
            );
        } else if (_bountyType == OpenQDefinitions.TIERED_FIXED) {
            _claimTieredFixedBounty(bounty, _closer, _closerData);
        } else {
            revert(Errors.UNKNOWN_BOUNTY_TYPE);
        }

        emit ClaimSuccess(block.timestamp, _bountyType, _closerData, VERSION_1);
    }

    /// @notice Used for claimants who have:
    /// @notice A) Completed KYC with KYC DAO for their tier
    /// @notice B) Uploaded invoicing information for their tier
    /// @notice C) Uploaded any necessary financial forms for their tier
    /// @param _bountyAddress The payout address of the bounty
    /// @param _closerData ABI Encoded data associated with this claim
    function permissionedClaimTieredBounty(
        address _bountyAddress,
        bytes calldata _closerData
    ) external onlyProxy whenNotPaused {
        IBounty bounty = IBounty(payable(_bountyAddress));

        (, , , , uint256 _tier) = abi.decode(
            _closerData,
            (address, string, address, string, uint256)
        );

        string memory closer = IOpenQ(openQ).addressToExternalUserId(
            msg.sender
        );

        require(
            keccak256(abi.encodePacked(closer)) !=
                keccak256(abi.encodePacked('')),
            Errors.NO_ASSOCIATED_ADDRESS
        );

        require(
            keccak256(abi.encode(closer)) ==
                keccak256(abi.encode(bounty.tierWinners(_tier))),
            Errors.CLAIMANT_NOT_TIER_WINNER
        );

        if (bounty.bountyType() == OpenQDefinitions.TIERED_FIXED) {
            _claimTieredFixedBounty(bounty, msg.sender, _closerData);
        } else {
            revert(Errors.NOT_A_COMPETITION_CONTRACT);
        }

        emit ClaimSuccess(
            block.timestamp,
            bounty.bountyType(),
            _closerData,
            VERSION_1
        );
    }

    /// @notice Claim method for AtomicBounty
    /// @param _bounty The payout address of the bounty
    /// @param _closer The payout address of the claimant
    /// @param _closerData ABI Encoded data associated with this claim
    /// @dev See IAtomicBounty
    function _claimAtomicBounty(
        IAtomicBounty _bounty,
        address _closer,
        bytes calldata _closerData
    ) internal {
        _eligibleToClaimAtomicBounty(_bounty, _closer);

        for (uint256 i = 0; i < _bounty.getTokenAddresses().length; i++) {
            uint256 volume = _bounty.claimBalance(
                _closer,
                _bounty.getTokenAddresses()[i]
            );

            emit TokenBalanceClaimed(
                _bounty.bountyId(),
                address(_bounty),
                _bounty.organization(),
                _closer,
                block.timestamp,
                _bounty.getTokenAddresses()[i],
                volume,
                _bounty.bountyType(),
                _closerData,
                VERSION_1
            );
        }
    }

    /// @notice Claim method for TieredFixedBounty
    /// @param _bounty The payout address of the bounty
    /// @param _closer The payout address of the claimant
    /// @param _closerData ABI Encoded data associated with this claim
    function _claimTieredFixedBounty(
        IBounty _bounty,
        address _closer,
        bytes calldata _closerData
    ) internal {
        (, , , , uint256 _tier) = abi.decode(
            _closerData,
            (address, string, address, string, uint256)
        );

        _eligibleToClaimTier(_bounty, _tier, _closer);

        if (_bounty.status() == 0) {
            _bounty.closeCompetition();

            emit BountyClosed(
                _bounty.bountyId(),
                address(_bounty),
                _bounty.organization(),
                address(0),
                block.timestamp,
                _bounty.bountyType(),
                new bytes(0),
                VERSION_1
            );
        }

        uint256 volume = _bounty.claimTieredFixed(_closer, _tier);

        emit TokenBalanceClaimed(
            _bounty.bountyId(),
            address(_bounty),
            _bounty.organization(),
            _closer,
            block.timestamp,
            _bounty.payoutTokenAddress(),
            volume,
            _bounty.bountyType(),
            _closerData,
            VERSION_1
        );
    }

    /// @notice Override for UUPSUpgradeable._authorizeUpgrade(address newImplementation) to enforce onlyOwner upgrades
    function _authorizeUpgrade(address) internal override onlyOwner {}

    /// @notice Exposes internal method Oraclize._transferOracle(address) restricted to onlyOwner called via proxy
    /// @param _newOracle The new oracle address
    function transferOracle(address _newOracle) external onlyProxy onlyOwner {
        require(_newOracle != address(0), Errors.NO_ZERO_ADDRESS);
        _transferOracle(_newOracle);
    }

    /// @notice Sets the OpenQProxy address used for checking IOpenQ(openQ).addressToExternalUserId
    function setOpenQ(address _openQ) external onlyProxy onlyOwner {
        openQ = _openQ;
    }

    /// @notice Sets the KYC DAO contract address
    /// @param _kyc The KYC DAO contract address
    function setKyc(address _kyc) external onlyProxy onlyOwner {
        kyc = _kyc;
    }

    /// @notice Checks the current KYC DAO contract address (kyc)to see if user has a valid KYC NFT or not
    /// @return True if address is KYC with KYC DAO, false otherwise
    function hasKYC(address _address) public view returns (bool) {
        return IKycValidity(kyc).hasValidToken(_address);
    }

    /// @notice Runs all require statements to determine if the claimant can claim the specified tier on the tiered bounty
    function _eligibleToClaimTier(
        ITieredBounty _bounty,
        uint256 _tier,
        address _closer
    ) internal view {
        require(!_bounty.tierClaimed(_tier), Errors.TIER_ALREADY_CLAIMED);

        if (_bounty.invoiceRequired()) {
            require(
                _bounty.invoiceComplete(_tier),
                Errors.INVOICE_NOT_COMPLETE
            );
        }

        if (_bounty.supportingDocumentsRequired()) {
            require(
                _bounty.supportingDocumentsComplete(_tier),
                Errors.SUPPORTING_DOCS_NOT_COMPLETE
            );
        }

        if (_bounty.kycRequired()) {
            require(hasKYC(_closer), Errors.ADDRESS_LACKS_KYC);
        }
    }

    /// @notice Runs all require statements to determine if the claimant can claim the atomic bounty
    function _eligibleToClaimAtomicBounty(IAtomicBounty bounty, address _closer)
        internal
        view
    {
        require(
            bounty.status() == OpenQDefinitions.OPEN,
            Errors.CONTRACT_IS_NOT_CLAIMABLE
        );

        if (bounty.invoiceRequired()) {
            bool _invoiceComplete = abi.decode(
                bounty.getInvoiceComplete(),
                (bool)
            );
            require(_invoiceComplete, Errors.INVOICE_NOT_COMPLETE);
        }

        if (bounty.supportingDocumentsRequired()) {
            bool _supportingDocumentsComplete = abi.decode(
                bounty.getSupportingDocumentsComplete(),
                (bool)
            );
            require(
                _supportingDocumentsComplete,
                Errors.SUPPORTING_DOCS_NOT_COMPLETE
            );
        }

        if (bounty.kycRequired()) {
            require(hasKYC(_closer), Errors.ADDRESS_LACKS_KYC);
        }
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/// @title IClaimManager
/// @author FlacoJones
/// @notice Interface for ClaimManager defining all events
interface IClaimManager {
    /// @notice Emitted when any bounty type is closed
    /// @param bountyId Unique bounty id
    /// @param bountyAddress Address of the bounty associated with the event
    /// @param organization Address of the bounty associated with the event
    /// @param closer Address of the recipient of the funds
    /// @param bountyClosedTime Block timestamp of the close
    /// @param bountyType The type of bounty closed. See OpenQDefinitions.sol
    /// @param data ABI encoded data associated with the BountyClosed event. Specific to each bounty type.
    /// @param version Which version of ClaimManager emitted the event. Increments with each ClaimManager release to instruct data decoding
    event BountyClosed(
        string bountyId,
        address bountyAddress,
        string organization,
        address closer,
        uint256 bountyClosedTime,
        uint256 bountyType,
        bytes data,
        uint256 version
    );

    /// @notice Emitted when a claim occurs on any bounty type
    /// @param claimTime The block timestamp in which the claim occurred
    /// @param bountyType The type of bounty closed. See OpenQDefinitions.sol
    /// @param data ABI encoded data associated with the ClaimSuccess event. Specific to each bounty type.
    /// @param version Which version of ClaimManager emitted the event. Increments with each ClaimManager release to instruct data decoding
    event ClaimSuccess(
        uint256 claimTime,
        uint256 bountyType,
        bytes data,
        uint256 version
    );

    /// @notice Emitted any time a volume of tokens is claimed
    /// @param bountyId Unique bounty id
    /// @param bountyAddress Address of the bounty associated with the event
    /// @param organization Address of the bounty associated with the event
    /// @param closer Address of the recipient of the funds
    /// @param payoutTime Block timestamp of the claim
    /// @param tokenAddress Address of the token
    /// @param volume Volume of the token claim
    /// @param bountyType The type of bounty closed. See OpenQDefinitions.sol
    /// @param data ABI encoded data associated with the TokenBalanceClaimed event. Specific to each bounty type.
    /// @param version Which version of ClaimManager emitted the event. Increments with each ClaimManager release to instruct data decoding
    event TokenBalanceClaimed(
        string bountyId,
        address bountyAddress,
        string organization,
        address closer,
        uint256 payoutTime,
        address tokenAddress,
        uint256 volume,
        uint256 bountyType,
        bytes data,
        uint256 version
    );

    /// @notice
    /// @param bountyId Unique bounty id
    /// @param bountyAddress Address of the bounty associated with the event
    /// @param organization Address of the bounty associated with the event
    /// @param closer Address of the recipient of the funds
    /// @param payoutTime Block timestamp of the claim
    /// @param tokenAddress Address of the token
    /// @param tokenId Token ID of the NFT claimed
    /// @param bountyType The type of bounty closed. See OpenQDefinitions.sol
    /// @param data ABI encoded data associated with the NFTClaimed event. Specific to each bounty type.
    /// @param version Which version of ClaimManager emitted the event. Increments with each ClaimManager release to instruct data decoding
    event NFTClaimed(
        string bountyId,
        address bountyAddress,
        string organization,
        address closer,
        uint256 payoutTime,
        address tokenAddress,
        uint256 tokenId,
        uint256 bountyType,
        bytes data,
        uint256 version
    );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';

import '../Interfaces/IClaimManager.sol';
import '../../OpenQ/Interfaces/IOpenQ.sol';
import '../../Library/OpenQDefinitions.sol';
import '../../Oracle/Oraclize.sol';
import '../../Bounty/Interfaces/IBounty.sol';
import '../../Library/Errors.sol';
import '../../KYC/IKycValidity.sol';

/// @title ClaimManagerStorageV1
/// @author FlacoJones
/// @notice Backwards compatible, append-only chain of storage contracts inherited by all ClaimManager implementations
/// @dev Add new variables for upgrades in a new, derived abstract contract that inherits from the previous storage contract version (see: https://forum.openzeppelin.com/t/to-inherit-version1-to-version2-or-to-copy-code-inheritance-order-from-version1-to-version2/28069)
abstract contract ClaimManagerStorageV1 is
    IClaimManager,
    Oraclize,
    OwnableUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    uint256 public constant VERSION_1 = 1;
    address public openQ;
    address public kyc;

    uint256[50] private __gap;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/// @title IKycValidity
/// @author FlacoJones
/// @notice An interface for checking whether an address has a valid kycNFT token
/// @dev This interface integrates with KYC DAO (https://docs.kycdao.xyz/smartcontracts/evm/#adding-on-chain-kycnft-checks)
interface IKycValidity {
    /// @dev Check whether a given address has a valid kycNFT token
    /// @param _addr Address to check for kycNFT token
    /// @return valid Whether the address has a valid kycNFT token
    function hasValidToken(address _addr) external view returns (bool valid);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/// @title Errors
/// @author FlacoJones
/// @notice Revert message constants
library Errors {
    string constant BOUNTY_ALREADY_EXISTS = 'BOUNTY_ALREADY_EXISTS';
    string constant CALLER_NOT_ISSUER = 'CALLER_NOT_ISSUER';
    string constant CALLER_NOT_ISSUER_OR_ORACLE = 'CALLER_NOT_ISSUER_OR_ORACLE';
    string constant CONTRACT_NOT_CLOSED = 'CONTRACT_NOT_CLOSED';
    string constant CONTRACT_ALREADY_CLOSED = 'CONTRACT_ALREADY_CLOSED';
    string constant TOKEN_NOT_ACCEPTED = 'TOKEN_NOT_ACCEPTED';
    string constant NOT_A_COMPETITION_CONTRACT = 'NOT_A_COMPETITION_CONTRACT';
    string constant NOT_A_TIERED_FIXED_BOUNTY = 'NOT_A_TIERED_FIXED_BOUNTY';
    string constant TOKEN_TRANSFER_IN_OVERFLOW = 'TOKEN_TRANSFER_IN_OVERFLOW';
    string constant NOT_AN_ONGOING_CONTRACT = 'NOT_AN_ONGOING_CONTRACT';
    string constant NO_EMPTY_BOUNTY_ID = 'NO_EMPTY_BOUNTY_ID';
    string constant NO_EMPTY_ORGANIZATION = 'NO_EMPTY_ORGANIZATION';
    string constant ZERO_VOLUME_SENT = 'ZERO_VOLUME_SENT';
    string constant CONTRACT_IS_CLOSED = 'CONTRACT_IS_CLOSED';
    string constant TIER_ALREADY_CLAIMED = 'TIER_ALREADY_CLAIMED';
    string constant DEPOSIT_ALREADY_REFUNDED = 'DEPOSIT_ALREADY_REFUNDED';
    string constant CALLER_NOT_FUNDER = 'CALLER_NOT_FUNDER';
    string constant NOT_A_TIERED_BOUNTY = 'NOT_A_TIERED_BOUNTY';
    string constant NOT_A_FIXED_TIERED_BOUNTY = 'NOT_A_FIXED_TIERED_BOUNTY';
    string constant PREMATURE_REFUND_REQUEST = 'PREMATURE_REFUND_REQUEST';
    string constant NO_ZERO_ADDRESS = 'NO_ZERO_ADDRESS';
    string constant CONTRACT_IS_NOT_CLAIMABLE = 'CONTRACT_IS_NOT_CLAIMABLE';
    string constant TOO_MANY_TOKEN_ADDRESSES = 'TOO_MANY_TOKEN_ADDRESSES';
    string constant NO_ASSOCIATED_ADDRESS = 'NO_ASSOCIATED_ADDRESS';
    string constant ADDRESS_LACKS_KYC = 'ADDRESS_LACKS_KYC';
    string constant TOKEN_NOT_ALREADY_WHITELISTED =
        'TOKEN_NOT_ALREADY_WHITELISTED';
    string constant ETHER_SENT = 'ETHER_SENT';
    string constant INVALID_STRING = 'INVALID_STRING';
    string constant TOKEN_ALREADY_WHITELISTED = 'TOKEN_ALREADY_WHITELISTED';
    string constant CLAIMANT_NOT_TIER_WINNER = 'CLAIMANT_NOT_TIER_WINNER';
    string constant INVOICE_NOT_COMPLETE = 'INVOICE_NOT_COMPLETE';
    string constant UNKNOWN_BOUNTY_TYPE = 'UNKNOWN_BOUNTY_TYPE';
    string constant SUPPORTING_DOCS_NOT_COMPLETE =
        'SUPPORTING_DOCS_NOT_COMPLETE';
    string constant EXPIRATION_NOT_GREATER_THAN_ZERO =
        'EXPIRATION_NOT_GREATER_THAN_ZERO';
    string constant PAYOUT_SCHEDULE_MUST_ADD_TO_100 =
        'PAYOUT_SCHEDULE_MUST_ADD_TO_100';
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/// @title OpenQDefinitions
/// @author FlacoJones
/// @notice Constants for common operations
library OpenQDefinitions {
    /// @title OpenQDefinitions
    /// @author FlacoJones
    /// @param operationType The bounty type
    /// @param data ABI encoded data used to initialize the bounty
    struct InitOperation {
        uint32 operationType;
        bytes data;
    }

    /// @notice Bounty types
    uint32 internal constant ATOMIC = 0;
    uint32 internal constant TIERED_FIXED = 3;

    uint32 internal constant OPEN = 0;
    uint32 internal constant CLOSED = 1;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/// @title IOpenQ
/// @author FlacoJones
/// @notice Interface declaring OpenQ events and methods used by other contracts
interface IOpenQ {
    function externalUserIdToAddress(string calldata)
        external
        returns (address);

    function addressToExternalUserId(address) external returns (string memory);

    function bountyAddressToBountyId(address) external returns (string memory);

    event TierClaimed(
        address bountyAddress,
        address claimant,
        bytes data,
        uint256 version
    );

    event BountyCreated(
        string bountyId,
        string organization,
        address issuerAddress,
        address bountyAddress,
        uint256 bountyMintTime,
        uint256 bountyType,
        bytes data,
        uint256 version
    );

    event FundingGoalSet(
        address bountyAddress,
        address fundingGoalTokenAddress,
        uint256 fundingGoalVolume,
        uint256 bountyType,
        bytes data,
        uint256 version
    );

    event PayoutSet(
        address bountyAddress,
        address payoutTokenAddress,
        uint256 payoutTokenVolume,
        uint256 bountyType,
        bytes data,
        uint256 version
    );

    event PayoutScheduleSet(
        address bountyAddress,
        address payoutTokenAddress,
        uint256[] payoutSchedule,
        uint256 bountyType,
        bytes data,
        uint256 version
    );

    event KYCRequiredSet(
        address bountyAddress,
        bool kycRequired,
        uint256 bountyType,
        bytes data,
        uint256 version
    );

    event InvoiceRequiredSet(
        address bountyAddress,
        bool invoiceRequired,
        uint256 bountyType,
        bytes data,
        uint256 version
    );

    event SupportingDocumentsRequiredSet(
        address bountyAddress,
        bool supportingDocuments,
        uint256 bountyType,
        bytes data,
        uint256 version
    );

    event InvoiceCompleteSet(
        address bountyAddress,
        uint256 bountyType,
        bytes data,
        uint256 version
    );

    event SupportingDocumentsCompleteSet(
        address bountyAddress,
        uint256 bountyType,
        bytes data,
        uint256 version
    );

    event BountyClosed(
        string bountyId,
        address bountyAddress,
        string organization,
        address closer,
        uint256 bountyClosedTime,
        uint256 bountyType,
        bytes data,
        uint256 version
    );

    event TierWinnerSelected(
        address bountyAddress,
        string[] tierWinners,
        bytes data,
        uint256 version
    );

    event ExternalUserIdAssociatedWithAddress(
        string newExternalUserId,
        address newAddress,
        string formerExternalUserId,
        address formerAddress,
        bytes data,
        uint256 version
    );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import '@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol';

/// @title Oraclize
/// @author FlacoJones
/// @notice Restricts access for method calls to oracle address
abstract contract Oraclize is ContextUpgradeable {
    /// @notice Oracle address
    address internal _oracle;

    event OracleTransferred(
        address indexed previousOracle,
        address indexed newOracle
    );

    /// @notice Initializes child contract with _initialOracle. Only callabel during initialization.
    /// @param _initialOracle The initial oracle address
    function __Oraclize_init(address _initialOracle) internal onlyInitializing {
        _oracle = _initialOracle;
    }

    /// @notice Transfers oracle of the contract to a new account (`newOracle`).
    function _transferOracle(address newOracle) internal virtual {
        address oldOracle = _oracle;
        _oracle = newOracle;
        emit OracleTransferred(oldOracle, newOracle);
    }

    /// @notice Returns the address of _oracle
    function oracle() external view virtual returns (address) {
        return _oracle;
    }

    /// @notice Modifier to restrict access of methods to _oracle address
    modifier onlyOracle() {
        require(
            _oracle == _msgSender(),
            'Oraclize: caller is not the current OpenQ Oracle'
        );
        _;
    }

    uint256[50] private __gap;
}