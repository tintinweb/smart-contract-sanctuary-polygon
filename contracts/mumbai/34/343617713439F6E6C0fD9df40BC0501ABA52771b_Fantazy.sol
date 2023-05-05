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

pragma solidity ^0.8.4;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";


pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity ^0.8.0;

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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
  }

/** @title fantasy Prize Contract.
 * @notice A contract for calculating blockfantasy fantasy 
 * player points and prize distribution using fabionacci
 */

 contract Fantazy is  Initializable, UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable
 {
     using SafeMath for uint256;
     using SafeERC20 for IERC20;

     uint256 public currenteventid;
     uint256 public currentpoolId;
     uint256 public customcurrenteventid;
     uint256 public customcurrentpoolId;
     uint256 public commission1;
     uint256 private eventuserscount;
     uint256 private totalteampoint; //make private later
     uint256 private teampoint; //make private later
     uint256 private vicemultiplier;
     uint256 private captainmultiplier;
     address public operatorAddress;
     address private we;
     address private treasury;
     uint256 private userresultcount;
     address[] private emptyaddress;
     address public multi;
     uint256[] private empty;
    //uint256[] public test100;
     string[] private emptystring;
     uint256 private bal;
     IERC20 public usdt;

     struct Event{
         uint256 eventid; //would be an increment for each new event
         string eventname;
         uint256[] eventspool;
         uint256[] playerslist;
         address[] users;
         uint256 closetime;
         uint256 matchtime;
         bool canceled;
     }

     struct CustomEvent{
         uint256 eventid; //would be an increment for each new event
         string eventname;
         uint256[] eventspool;
         uint256[] playerslist;
         address[] users;
         uint256 closetime;
         uint256 matchtime;
         bool canceled;
     }

     struct Users{
         uint256 eventid;
         address user;
         uint256 userscore;
         uint256[] teamnames;
         uint256[] userpool;
     }

    struct CustomUsers{
         uint256 eventid;
         address user;
         uint256 userscore;
         uint256[] teamnames;
         uint256[] userpool;
     }

     struct Team{
         address user;
         uint256 teamid;
         string teamname;
         uint256 selectedcaptain;
         uint256 selectedvicecaptain;
         uint256[9] selectedplayers;
         uint256 teamscore;
     }

    struct CustomTeam{
         address user;
         uint256 teamid;
         string teamname;
         uint256 selectedcaptain;
         uint256 selectedvicecaptain;
         uint256[9] selectedplayers;
         uint256 teamscore;
     }

     struct Pool{
         uint256 poolid;
         uint256[] teamsarray;
         uint256 entryfee;
         uint256 pooluserlimt;
         address[] userarray; 
         bool canceled;
         address[] playersrank;
         uint256[] prizeDistribution;
         bool prizesPaid;
         uint256 discount;
     }

     struct CustomPool{
         uint256 poolid;
         uint256[] teamsarray;
         uint256 entryfee;
         uint256 pooluserlimt;
         address[] userarray; 
         bool canceled;
         address[] playersrank;
         uint256[] prizeDistribution;
         bool prizesPaid;
     }

     struct Players{
         uint256 eventid;
         uint256 player;
         uint256 playerscore; 
     }

     struct CustomPlayers{
         uint256 eventid;
         uint256 player;
         uint256 playerscore; 
     }

     struct Teamresult{
         uint256 team;
         uint256 score;
     }
     
     struct Usercount{
        uint256[] teamcount;
     }

    struct CustomUsercount{
        uint256[] teamcount;
     }

     //mapping
     mapping(uint256 => Event) private _events;
     mapping(uint256 => Users) private _user;
     mapping(uint256 => Players) private _player;
     mapping(uint256 => mapping(uint256 => Team)) private teams;
     mapping(uint256 => Pool) private pools;
     mapping(uint256 => Teamresult) private _teamresult;
     mapping(uint256 => address) private usertoteam;
     mapping(uint256 => uint256) private _lastindex;
     mapping(uint256 => bool) private comissionpaid;
     mapping(uint256 => bool) private comissionpaidusdt;
     mapping(uint256 => mapping(uint256 => bool)) private teaminpool;
     mapping(uint256 => mapping(address => bool)) private userteamusdt;
     mapping(uint256 => mapping(address => bool)) private eventpaidforuser;
     mapping(uint256 => mapping(uint256 => uint256)) public poolbalance;
     mapping(uint256 => mapping(uint256 => uint256)) public poollimit;
     mapping(uint256 => mapping(uint256 => uint256)) public poolbalanceusdt;
     mapping(uint256 => mapping(uint256 => bool)) private claimedcanceledpool;   
     mapping(uint256 => mapping(address => bool)) private discountpaid;
     mapping(uint256 => uint256) private userinpoolcount; //this for our chainlink keeper
     mapping(uint256 => uint256) private paidcount;
     mapping(uint256 => uint256) private usdtcount;
     mapping(uint256 => uint256) private maticcount;
     mapping(uint256 => mapping(uint256 => uint256)) private playerpoints; //event to players to points
     mapping(uint256 => mapping(uint256 => uint256)) private customplayerpoints; //event to players to points
     mapping(address => mapping(uint256 => uint256[])) private selectedusers; //event to players to selected players array
     mapping(uint256 => mapping(uint256 => uint256)) private teampointforevent; //users point for a particular event     
     mapping(address => mapping(uint256 => Usercount)) private userteamcount; //used for team count required

    modifier onlyMulti {
      require(msg.sender == multi);
      _;
   }


     //events
     event NewEvent(uint256 indexed eventID, string name, uint256 starttime);
     event Newpool(uint256 indexed poolid, uint256 fee, uint256 userlimit);
     event NewCustomEvent(uint256 indexed eventID, string name, uint256 starttime);
     event NewCustompool(uint256 indexed poolid, uint256 fee, uint256 userlimit);
     event Joinedevent(address indexed player, uint256 indexed eventID, uint256 indexed pool, uint256 teamid);
     event Newteam(address indexed player, uint256 indexed eventID, uint256 indexed teamid, string teamname);
     event Editteam(address indexed player, uint256 indexed eventID, uint256 indexed teamid);
     event Editteamleaders(address indexed player, uint256 indexed eventID, uint256 indexed teamid, uint256 captain, uint256 vicecaptain);
     event Canceleventpool(uint256 indexed eventID);
     event Cancelonlyevent(uint256 indexed eventID);
     event poolcanceled(uint256 indexed poolid);
     event claimedfee(uint256 indexed poolid, uint256 indexed teamid, uint256 indexed eventID, address player);
     event updatedplayerscore(uint256 indexed eventID);
     event Poolclaimed(uint256 indexed eventID, uint256 indexed poolid);

    function initialize(address _treasury, uint256 _commission, address _multi, uint256 _currenteventid, uint256 _currentpoolId) public initializer {
         treasury = _treasury;
         commission1 = _commission;
         multi = _multi;
         currenteventid = _currenteventid;
         currentpoolId = _currentpoolId;

      ///@dev as there is no constructor, we need to initialise the OwnableUpgradeable explicitly
       __Ownable_init();
   }

     function _authorizeUpgrade(address) internal override onlyOwner {}

     function CreateEvents(
         string memory name,
         uint256[] memory playerspid,
         uint256 starttime
         ) external onlyOwner{
             require(starttime > block.timestamp, "Start time needs to be higher than the current time");
             require(playerspid.length > 0, "Add a player");
             //add requirements statement
             currenteventid++;
             _events[currenteventid] = Event({
                 eventid : currenteventid,
                 eventname : name,
                 eventspool : empty, 
                 playerslist : playerspid,
                 users : emptyaddress,
                 closetime : starttime.sub(60),
                 matchtime : starttime,
                 canceled : false

             });
             for (uint256 i = 0; i < playerspid.length; i++){
                 uint256 but = playerspid[i];
                 playerpoints[currenteventid][but] = 0; 
                 _player[currenteventid] = Players ({
                     eventid : currenteventid,
                     player : but,
                     playerscore : 0
                 });
             }

            emit NewEvent(currenteventid, name, starttime);
    }

    function Createpool(
        uint256 fee,
        uint256 eventID,
        uint256 userlimit,
        uint256 _percentage
        ) public onlyOwner {
            require(fee > 0, "Add a fee for pool");
            require(userlimit > 0, "pool must have a userlimit");
            currentpoolId++;
            pools[currentpoolId] = Pool({
                poolid : currentpoolId,
                teamsarray : empty,
                entryfee : fee,
                pooluserlimt : userlimit,
                userarray : emptyaddress,
                canceled : false,
                playersrank : emptyaddress,
                prizeDistribution: empty,
                prizesPaid : false,
                discount: _percentage
            });
            _events[eventID].eventspool.push(currentpoolId);
            poolbalance[eventID][currentpoolId] = 0;
            poollimit[eventID][currentpoolId] = userlimit;
            comissionpaid[currentpoolId] = false;
            paidcount[currentpoolId] = 0;
            usdtcount[currentpoolId] = 0;
            maticcount[currentpoolId] = 0;

            emit Newpool(currentpoolId, fee, userlimit);
        }

    function Joinevent(
        uint256 eventID,
        address user,
        string memory teamname,
        uint256 _captain,
        uint256 _vicecaptain,
        uint256[9] calldata _playersselected,
        uint256 pool,
        uint256 _teamid
    ) public payable nonReentrant{
        require(block.timestamp < _events[eventID].closetime, "Events has been closed");// check this
        require(!_events[eventID].canceled, "Event has been canceled");
        uint256[] memory fit = userteamcount[user][pool].teamcount;
        require(fit.length < 6, "User team count is more than 6");
        require(pools[pool].entryfee == msg.value, "Enter the exact entry fee");
        require(!pools[pool].canceled, "pool has been canceled");
        require(msg.sender == user, "enter your correct wallet address");
        uint256 limit = poollimit[eventID][pool];
        uint256[] memory pimp = pools[pool].teamsarray;
        require(pimp.length <= limit, "Pool count more than the limit");

        uint256 yummyindex = poolbalance[eventID][pool];
        poolbalance[eventID][pool] = yummyindex + msg.value;

        eventuserscount++;
        Createteam(user, eventID, _captain, teamname, _vicecaptain, _playersselected, _teamid, false);
        _user[eventID] = Users({
            eventid : eventID,
            user : user,
            userscore : 0,
            teamnames : empty,
            userpool : empty
        });
        userteamcount[user][pool].teamcount.push(_teamid);
        _user[eventID].teamnames.push(_teamid);
        _user[eventID].userpool.push(pool);
        _events[eventID].users.push(user);
        pools[pool].teamsarray.push(_teamid);
        pools[pool].userarray.push(user);
        claimedcanceledpool[pool][_teamid] = false;
        teaminpool[pool][_teamid] = true;
        uint currentcount = maticcount[pool];
        maticcount[pool] = currentcount + 1; 

        emit Joinedevent(msg.sender, eventID, pool, _teamid);
    }

    function Userdiscountpay(
        uint256 pool,
        address user,
        uint256 eventID
    ) public payable nonReentrant{
        uint256 percent = pools[pool].discount;
        uint256 entry = pools[pool].entryfee;
        uint256 discountfee = percent / 100 * entry;
        require(msg.value == discountfee, "Enter exact amount fot user to pay on discount");
        uint256 yummyindex1 = poolbalance[eventID][pool];
        poolbalance[eventID][pool] = yummyindex1 + msg.value;
        discountpaid[pool][user] = true;
    }

    function EditStarttime(
        uint256 starttime,
        uint256 eventID
    ) external onlyOwner{
        require(starttime > block.timestamp, "Start time needs to be higher than the current time");
             _events[eventID].closetime = starttime.sub(60);
             _events[eventID].matchtime = starttime;
    }

    function AdminDelegateJoin(
        uint256 eventID,
        address user,
        string memory teamname,
        uint256 _captain,
        uint256 _vicecaptain,
        uint256[9] calldata _playersselected,
        uint256 pool,
        uint256 _teamid
    ) external payable nonReentrant onlyMulti{
        //require(block.timestamp < _events[eventID].closetime, "Events has been closed");
        require(!_events[eventID].canceled, "Event has been canceled");
        uint256[] memory fit = userteamcount[user][pool].teamcount;
        require(fit.length < 6, "User team count is more than 6");
        require(pools[pool].entryfee == msg.value, "Enter the exact entry fee");
        require(!pools[pool].canceled, "pool has been canceled");
        uint256 limit = poollimit[eventID][pool];
        uint256[] memory pimp = pools[pool].teamsarray;
        require(pimp.length <= limit, "Pool count more than the limit");
        bool paid = discountpaid[pool][user];
        require(paid == true, "Pool count more than the limit");

        uint256 yummyindex = poolbalance[eventID][pool];
        poolbalance[eventID][pool] = yummyindex + msg.value;

        eventuserscount++;
        Createteam(user, eventID, _captain, teamname, _vicecaptain, _playersselected, _teamid, false);
        _user[eventID] = Users({
            eventid : eventID,
            user : user,
            userscore : 0,
            teamnames : empty,
            userpool : empty
        });
        userteamcount[user][pool].teamcount.push(_teamid);
        _user[eventID].teamnames.push(_teamid);
        _user[eventID].userpool.push(pool);
        _events[eventID].users.push(user);
        pools[pool].teamsarray.push(_teamid);
        pools[pool].userarray.push(user);
        claimedcanceledpool[pool][_teamid] = false;
        teaminpool[pool][_teamid] = true;
        uint currentcount = maticcount[pool];
        maticcount[pool] = currentcount + 1; 

        emit Joinedevent(msg.sender, eventID, pool, _teamid);
    }

    function Createteam(
        address useraddress,
        uint256 eventID,
        uint256 captain,
        string memory _teamname,
        uint256 vicecaptain,
        uint256[9] calldata playersselected,
        uint256 _teamid,
        bool check
        ) internal {
             require(captain > 0, "You must have a captain");
             require(vicecaptain > 0, "You must have a vice-captain");
             require(playersselected.length == 9, "You must have 11 selected players");
            //_teamid++;
            teams[eventID][_teamid] = Team({
                user : useraddress,
                teamid : _teamid,
                teamname : _teamname,
                selectedcaptain : captain,
                selectedvicecaptain : vicecaptain,
                selectedplayers : playersselected,
                teamscore : 0
            });
            selectedusers[useraddress][eventID] = playersselected;
            usertoteam[_teamid] = useraddress;
            userteamusdt[_teamid][useraddress] = check;

            emit Newteam(msg.sender, eventID, _teamid, _teamname);
        } 

    function editSelectedPlayers(uint256 eventID, uint256 team, uint256[9] calldata playersselected, address useraddress) public onlyOwner{
        require(block.timestamp < _events[eventID].closetime, "Events has been closed");
        require(useraddress == teams[eventID][team].user, "Not team owner");
        delete teams[eventID][team].selectedplayers;
        teams[eventID][team].selectedplayers = playersselected;

        emit Editteam(useraddress, eventID, team);
    }

    function editCaptainandVice(uint256 eventID, uint256 team, uint256 captain, uint256 vicecaptain, address useraddress) public onlyOwner{
        require(block.timestamp < _events[eventID].closetime, "Events has been closed");
        require(useraddress == teams[eventID][team].user, "Not team owner");
        teams[eventID][team].selectedcaptain = captain;
        teams[eventID][team].selectedvicecaptain = vicecaptain;

        emit Editteamleaders(useraddress, eventID, team, captain, vicecaptain);
    }

    function batcheditCaptainandVice(uint256 eventID, uint256[] memory _teams, uint256[] memory captains, uint256[] memory vicecaptains, address[] memory _users) external onlyOwner{
        address[] memory play = _users;
        for (uint256 i = 0; i < play.length; i++){
            editCaptainandVice(eventID, _teams[i], captains[i], vicecaptains[i], _users[i]);
        }
    }

    function canceleventandpool(uint256 eventID) public onlyOwner{
        require(!_events[eventID].canceled, "Event has been already canceled");
        _events[eventID].canceled = true;
        for(uint256 i=0; i < _events[eventID].eventspool.length; i++){
            cancelpool(_events[eventID].eventspool[i]);
        }

        emit Canceleventpool(eventID);
    }

    function canceleventthenpoolmanually(uint256 eventID) public onlyOwner{
        require(!_events[eventID].canceled, "Event has been already canceled");
        _events[eventID].canceled = true;

        emit Cancelonlyevent(eventID);
    }

    function cancelpool(uint256 poolid) public onlyOwner{
        require(!pools[poolid].canceled, "Pool has already been canceled");
        pools[poolid].canceled = true;

        emit poolcanceled(poolid);
    }

    function returnentryfee(uint256 poolid, uint256 team, uint256 eventID) internal nonReentrant{
        require(pools[poolid].canceled = true, "Pool has not been canceled");
        require(claimedcanceledpool[poolid][team] == false, "You have claimed pool"); 
        require(teaminpool[poolid][team] = true, "Team is not part of pool");
        address user = teams[eventID][team].user;
        uint256 fee = pools[poolid].entryfee;
        payable(user).transfer(fee);
        claimedcanceledpool[poolid][team] = true;

        emit claimedfee(poolid, team, eventID, msg.sender);
    }

    function returnentryfeeall(uint256 pool, uint256 eventID) external onlyOwner{
        require(pools[pool].teamsarray.length < 13, "Pool must have less than 13 players");
        uint256[] memory play = pools[pool].teamsarray;
        for (uint256 i = 0; i < play.length; i++){
            returnentryfee(pool, play[i], eventID);
        }
    }

    function returnentrynocondition(uint256[] memory _teamss, uint256 pool, uint256 eventID) external onlyOwner{
        uint256[] memory play = _teamss;
        for (uint256 i = 0; i < play.length; i++){
            returnentryfee(pool, play[i], eventID);
        }
    }

    function changecommision(uint256 rate) public onlyOwner{
        require(rate < 300, "Commission must have a value Or cannot be greater than 300");
        commission1 = rate;
    }

    function changecaptainmultiplier(uint256 _multiplier) public onlyOwner{
        captainmultiplier = _multiplier;
    }

    function changevicemultiplier(uint256 _multiplier) public onlyOwner{
        vicemultiplier = _multiplier;
    }

    function changemulti(address _multi1) public onlyOwner{
        multi = _multi1;
    }

    function changeTreasury(address _treasury) public onlyOwner{
        treasury = _treasury;
    }

    function updateplayerscore(uint256[] calldata scores, uint256 eventID) public onlyOwner{
        require(scores.length > 0, "Score array must have a value");
        uint256[] memory playerspid = _events[eventID].playerslist;
        for (uint256 i = 0; i < playerspid.length; i++){
            uint256 but = playerspid[i];
            playerpoints[eventID][but] = scores[i];
        }

        emit updatedplayerscore(eventID);
    }

    function getCommission() public view returns (uint256) {
        return commission1;
    }

    function getEvent(uint256 eventID) public view returns (string memory, uint256[] memory, uint[] memory, uint256, uint256, bool) {
        return ( _events[eventID].eventname,
        _events[eventID].eventspool,
        _events[eventID].playerslist,
        _events[eventID].closetime,
        _events[eventID].matchtime,
        _events[eventID].canceled);
    }

    function getTeamdetails(uint256 team, uint256 eventID) public view returns (address, string memory, uint256, uint256, uint256[9] memory, uint256) {
        return (teams[eventID][team].user,
        teams[eventID][team].teamname,
        teams[eventID][team].selectedcaptain,
        teams[eventID][team].selectedvicecaptain,
        teams[eventID][team].selectedplayers,
        teams[eventID][team].teamscore);
    }

    function getpooldetails(uint256 pool) public view returns (uint256[] memory, uint256, uint256, address[] memory, bool, uint256[] memory, bool) {
        return (pools[pool].teamsarray,
        pools[pool].entryfee,
        pools[pool].pooluserlimt,
        pools[pool].userarray,
        pools[pool].canceled,
        pools[pool].prizeDistribution,
        pools[pool].prizesPaid);
    }
    function getCommission(uint256 poolid) public view returns(uint256){
        //address[] memory me = pools[poolid].userarray;
        uint me = maticcount[poolid];
        return me.mul(pools[poolid].entryfee)
                        .mul(commission1)
                        .div(1000);
    }

    function getPrizePoolLessCommission(uint256 poolid) public view returns(uint256){
        address[] memory me = pools[poolid].userarray;
        uint256 totalPrizePool = (me.length
                                    .mul(pools[poolid].entryfee))
                                    .sub(getCommission(poolid));
        return totalPrizePool;
    }

    function withdrawPrizes2(address[] calldata users, uint256[] calldata amounts, uint256 eventID, uint256 poolid) external onlyOwner{
        require(!pools[poolid].prizesPaid, "The prizes have already been paid.");
        require(users.length == amounts.length,"Must be equal");
        //require(users.length <= 10,"");
        uint256[] memory me = pools[poolid].teamsarray;
        uint256 us = paidcount[poolid];
        require(us < me.length,"Must be less than");

        for(uint256 i = 0; i < users.length; i++){
            uint256 balance = poolbalance[eventID][poolid];
            if(balance > pools[poolid].entryfee){
            payable(address(uint160(users[i]))).transfer(amounts[i]);

            uint256 balance2 = poolbalance[eventID][poolid];
            uint256 taken = amounts[i];
            poolbalance[eventID][poolid] = balance2 - taken;
            }
            eventpaidforuser[eventID][users[i]] = true;
        }

        uint256 balance1 = poolbalance[eventID][poolid];

        if(balance1 < pools[poolid].entryfee){
            pools[poolid].prizesPaid = true;
        }

        paidcount[poolid] += users.length;

        emit Poolclaimed(eventID, poolid);
     }

    function withdrawunknown(IERC20 token) public onlyOwner{
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }

    function checklastindex(uint256 poolid) public view returns(uint256){
        uint256 index = _lastindex[poolid];
        return index;
    }

    function withdrawCommission(uint256 poolid, uint256 eventID) public onlyOwner{
        require(comissionpaid[poolid] == false, "Commission has been paid");
        uint mul = getCommission(poolid) * 4;
            uint get = poolbalance[eventID][poolid];
            if(get <= mul){
                payable(treasury).transfer(get);
                comissionpaid[poolid] = true;
            }
    }

     receive() external payable {}
 }