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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMathUpgradeable {
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

pragma solidity ^0.8.17;

// import 'streamr-contracts/packages/network-contracts/contracts/StreamRegistry/StreamRegistryV4.sol';
// https://github.com/streamr-dev/network-contracts/blob/master/packages/network-contracts/contracts/StreamRegistry/StreamRegistryV4.sol

interface IStreamRegistry {
    enum PermissionType {
        Edit,
        Delete,
        Publish,
        Subscribe,
        Grant
    }

    function createStream(string calldata streamIdPath, string calldata metadataJsonString) external;

    function grantPublicPermission(string calldata streamId, PermissionType permissionType) external;

    function grantPermission(string calldata streamId, address user, PermissionType permissionType) external;

    function revokePermission(string calldata streamId, address user, PermissionType permissionType) external;

    function exists(string calldata streamId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.4;

import {MathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import {SignedMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SignedMathUpgradeable.sol";

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
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMathUpgradeable.abs(value))));
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
     * @dev Converts a `int256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(int256 value) internal pure returns (string memory) {
        unchecked {
            return string(abi.encodePacked(value < 0 ? "-" : "", toHexString(SignedMathUpgradeable.abs(value))));
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/* Signature Verification

How to Sign and Verify
# Signing
1. Create message to sign
2. Hash the message
3. Sign the hash (off chain, keep your private key secret)

# Verify
1. Recreate hash from the original message
2. Recover signer from signature and hash
3. Compare recovered signer to claimed signer
*/

library VerifySignature {
    function verify(address signer, bytes32 message, bytes memory signature) public pure returns (bool) {
        if (signature.length != 65) {
            return false;
        }

        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(message);

        address recovered = ecrecover(ethSignedMessageHash, v, r, s);

        return signer == recovered;
    }

    function splitSignature(bytes memory sig) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

// Open Zeppelin libraries for controlling upgradability and access.
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {IStreamRegistry} from "./interfaces/StreamRegistry.sol";
import {StringsUpgradeable} from "./lib/StringsUpgradeable.sol";
import {LogStoreManager} from "./StoreManager.sol";
import {LogStoreQueryManager} from "./QueryManager.sol";
import {LogStoreReportManager} from "./ReportManager.sol";

contract LogStoreNodeManager is Initializable, UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    string public constant LOGSTORE_SYSTEM_STREAM_ID_PATH = "/system";
    /* solhint-disable quotes */
    string public constant LOGSTORE_SYSTEM_STREAM_METADATA_JSON_STRING = '{ "partitions": 1 }';
    /* solhint-enable quotes */

    event NodeUpdated(address indexed nodeAddress, string metadata, bool indexed isNew, uint lastSeen);
    event NodeRemoved(address indexed nodeAddress);
    event StakeDelegateUpdated(
        address indexed delegate,
        address indexed node,
        uint amount,
        uint totalStake,
        uint totalDelegated,
        bool delegated
    );
    event NodeWhitelistApproved(address indexed nodeAddress);
    event NodeWhitelistRejected(address indexed nodeAddress);
    event RequiresWhitelistChanged(bool indexed value);
    event ReportProcessed(string id);

    enum WhitelistState {
        None,
        Approved,
        Rejected
    }

    struct Node {
        uint index; // index of node address
        string metadata; // Connection metadata, for example wss://node-domain-name:port
        uint lastSeen; // what's the best way to store timestamps in smart contracts?
        address next;
        address prev;
        uint256 stake;
    }

    modifier onlyWhitelist() {
        require(!requiresWhitelist || whitelist[msg.sender] == WhitelistState.Approved, "error_notApproved");
        _;
    }

    modifier onlyStaked() {
        require(isStaked(msg.sender), "error_stakeRequired");
        _;
    }

    bool public requiresWhitelist;
    uint256 public totalSupply;
    uint256 public treasurySupply;
    uint256 public stakeRequiredAmount;
    address public stakeTokenAddress;
    uint256 public totalNodes;
    uint256 public startBlockNumber; // A block number for when the Log Store process starts
    mapping(address => Node) public nodes;
    mapping(address => WhitelistState) public whitelist;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public delegatesOf;
    address public headNode;
    address public tailNode;
    string internal systemStreamId;
    IERC20Upgradeable internal stakeToken;
    LogStoreManager private _storeManager;
    LogStoreQueryManager private _queryManager;
    LogStoreReportManager private _reportManager;
    IStreamRegistry private streamrRegistry;

    function initialize(
        address owner_,
        bool requiresWhitelist_,
        address stakeTokenAddress_,
        uint256 stakeRequiredAmount_,
        address streamrRegistryAddress_,
        address[] memory initialNodes,
        string[] calldata initialMetadata
    ) public initializer {
        require(initialNodes.length == initialMetadata.length, "error_badTrackerData");
        require(stakeTokenAddress_ != address(0) && stakeRequiredAmount_ > 0, "error_badTrackerData");

        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        requiresWhitelist = requiresWhitelist_;
        stakeToken = IERC20Upgradeable(stakeTokenAddress_);
        stakeTokenAddress = stakeTokenAddress_;
        stakeRequiredAmount = stakeRequiredAmount_;
        streamrRegistry = IStreamRegistry(streamrRegistryAddress_);

        streamrRegistry.createStream(LOGSTORE_SYSTEM_STREAM_ID_PATH, LOGSTORE_SYSTEM_STREAM_METADATA_JSON_STRING);
        systemStreamId = string(
            abi.encodePacked(StringsUpgradeable.toHexString(address(this)), LOGSTORE_SYSTEM_STREAM_ID_PATH)
        );
        streamrRegistry.grantPublicPermission(systemStreamId, IStreamRegistry.PermissionType.Subscribe);

        for (uint i = 0; i < initialNodes.length; i++) {
            upsertNodeAdmin(initialNodes[i], initialMetadata[i]);
        }
        transferOwnership(owner_);
    }

    /// @dev required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyOwner {}

    function registerStoreManager(address contractAddress) public onlyOwner {
        _storeManager = LogStoreManager(contractAddress);
    }

    function registerQueryManager(address contractAddress) public onlyOwner {
        _queryManager = LogStoreQueryManager(contractAddress);
    }

    function registerReportManager(address contractAddress) public onlyOwner {
        _reportManager = LogStoreReportManager(contractAddress);
    }

    function upsertNodeAdmin(address node, string calldata metadata_) public onlyOwner {
        _upsertNode(node, metadata_);
    }

    function removeNodeAdmin(address nodeAddress) public onlyOwner {
        _removeNode(nodeAddress);
    }

    function treasuryWithdraw(uint256 amount) public onlyOwner {
        require(amount <= treasurySupply, "error_notEnoughStake");

        totalSupply -= amount;
        treasurySupply -= amount;

        bool success = stakeToken.transfer(msg.sender, amount);
        require(success == true, "error_unsuccessfulWithdraw");
    }

    function whitelistApproveNode(address nodeAddress) public onlyOwner {
        whitelist[nodeAddress] = WhitelistState.Approved;
        emit NodeWhitelistApproved(nodeAddress);
    }

    function whitelistRejectNode(address nodeAddress) public onlyOwner {
        whitelist[nodeAddress] = WhitelistState.Rejected;
        emit NodeWhitelistRejected(nodeAddress);
    }

    function kickNode(address nodeAddress) public onlyOwner {
        whitelistRejectNode(nodeAddress);
        removeNodeAdmin(nodeAddress);
    }

    function setRequiresWhitelist(bool value) public onlyOwner {
        requiresWhitelist = value;
        emit RequiresWhitelistChanged(value);
    }

    // recieve report data broken up into a series of arrays
    function processReport(string calldata id) public onlyStaked {
        LogStoreReportManager.Report memory report = _reportManager.getReport(id);

        require(report._processed == false, "error_reportAlreadyProcessed");

        for (uint256 i = 0; i < report.streams.length; i++) {
            if (report.streams[i].writeBytes > 0) {
                _storeManager.capture(
                    report.streams[i].id,
                    report.streams[i].writeCapture,
                    report.streams[i].writeBytes
                );
                totalSupply += report.streams[i].writeCapture;
            }
        }
        for (uint256 i = 0; i < report.consumers.length; i++) {
            if (report.consumers[i].readBytes > 0) {
                _queryManager.capture(
                    report.consumers[i].id,
                    report.consumers[i].readCapture,
                    report.consumers[i].readBytes
                );
                totalSupply += report.consumers[i].readCapture;
            }
        }
        for (uint256 i = 0; i < report.nodes.length; i++) {
            address reportNodeAddress = report.nodes[i].id;
            int256 reportNodeAmountChange = report.nodes[i].amount;
            int256 newNodeAmount = int(nodes[reportNodeAddress].stake) + reportNodeAmountChange;
            if (newNodeAmount > 0) {
                nodes[reportNodeAddress].stake = uint(newNodeAmount);
            } else {
                nodes[reportNodeAddress].stake = 0;
            }
            _checkAndGrantAccess(reportNodeAddress);
        }
        for (uint256 i = 0; i < report.delegates.length; i++) {
            address reportDelegateAddress = report.delegates[i].id;
            for (uint256 j = 0; j < report.delegates[i].nodes.length; j++) {
                address delegateNodeAddress = report.delegates[i].nodes[j].id;
                int256 delegateNodeChange = report.delegates[i].nodes[j].amount;

                int256 newDelegateAmount = int(delegatesOf[reportDelegateAddress][delegateNodeAddress]) +
                    delegateNodeChange;
                if (newDelegateAmount > 0) {
                    delegatesOf[reportDelegateAddress][delegateNodeAddress] = uint(newDelegateAmount);
                } else {
                    delegatesOf[reportDelegateAddress][delegateNodeAddress] = 0;
                }
            }
        }
        int256 newTreasurySupply = int(treasurySupply) + report.treasury;
        if (newTreasurySupply > 0) {
            treasurySupply = uint(newTreasurySupply);
        } else {
            treasurySupply = 0;
        }

        _reportManager.processReport(id);
        emit ReportProcessed(id);
    }

    // Nodes can join the network, but they will not earn rewards or participate unless they're staked.
    function upsertNode(string calldata metadata_) public onlyWhitelist {
        _upsertNode(msg.sender, metadata_);
    }

    function removeNode() public {
        _removeNode(msg.sender);
    }

    function join(uint amount, string calldata metadata_) public {
        upsertNode(metadata_);
        stake(amount);
        delegate(amount, msg.sender);
    }

    function leave() public {
        undelegate(delegatesOf[msg.sender][msg.sender], msg.sender);
        withdraw(balanceOf[msg.sender]);
        removeNode();
    }

    function stake(uint amount) public nonReentrant {
        require(amount > 0, "error_insufficientStake");
        require(stakeToken.balanceOf(msg.sender) >= amount, "error_insufficientBalance");

        balanceOf[msg.sender] += amount;
        totalSupply += amount;

        bool success = stakeToken.transferFrom(msg.sender, address(this), amount);
        require(success == true, "error_unsuccessfulStake");
    }

    function delegate(uint amount, address node) public {
        require(amount > 0, "error_insufficientDelegateAmount");
        require(nodes[node].lastSeen > 0, "error_invalidNode");

        balanceOf[msg.sender] -= amount;
        delegatesOf[msg.sender][node] += amount;
        nodes[node].stake += amount;

        _checkAndGrantAccess(node);

        emit StakeDelegateUpdated(msg.sender, node, amount, nodes[node].stake, delegatesOf[msg.sender][node], true);
    }

    function undelegate(uint amount, address node) public {
        require(amount > 0, "error_insufficientDelegateAmount");
        require(nodes[node].lastSeen > 0, "error_invalidNode");

        delegatesOf[msg.sender][node] -= amount;
        nodes[node].stake -= amount;
        balanceOf[msg.sender] += amount;

        _checkAndGrantAccess(node);

        emit StakeDelegateUpdated(msg.sender, node, amount, nodes[node].stake, delegatesOf[msg.sender][node], false);
    }

    function stakeAndDelegate(uint amount, address node) public {
        stake(amount);
        delegate(amount, node);
    }

    function withdraw(uint amount) public {
        require(amount <= balanceOf[msg.sender], "error_notEnoughStake");

        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;

        bool success = stakeToken.transfer(msg.sender, amount);
        require(success == true, "error_unsuccessfulWithdraw");
    }

    function undelegateWithdraw(uint amount, address node) public {
        undelegate(amount, node);
        withdraw(amount);
    }

    function _upsertNode(address nodeAddress, string calldata metadata_) internal {
        Node storage foundNode = nodes[nodeAddress];
        bool isNew = false;

        if (foundNode.lastSeen == 0) {
            isNew = true;
            if (headNode == address(0)) {
                headNode = nodeAddress;
                startBlockNumber = block.number;
            } else {
                nodes[tailNode].next = nodeAddress;
                foundNode.prev = tailNode;
                foundNode.index = totalNodes;
            }
            tailNode = nodeAddress;
            totalNodes += 1;
        }

        // update this fields for create or update operations
        foundNode.metadata = metadata_;
        foundNode.lastSeen = block.timestamp;

        emit NodeUpdated(nodeAddress, foundNode.metadata, isNew, foundNode.lastSeen);
    }

    function _removeNode(address nodeAddress) internal {
        Node storage removedNode = nodes[nodeAddress];
        require(removedNode.lastSeen != 0, "error_notFound");

        if (removedNode.prev != address(0)) {
            nodes[removedNode.prev].next = removedNode.next;
        }
        if (removedNode.next != address(0)) {
            nodes[removedNode.next].prev = removedNode.prev;
        }
        if (headNode == nodeAddress) {
            headNode = removedNode.next;
        }
        if (tailNode == nodeAddress) {
            tailNode = removedNode.prev;
        }

        // Delete before loop as to no conflict
        delete nodes[nodeAddress];

        totalNodes -= 1;

        // Go through all the nodes after the removed one
        // and reduce the index value to account for a deduction
        address nextNodeAddress = removedNode.next;
        while (nextNodeAddress != address(0)) {
            nodes[nextNodeAddress].index--;
            nextNodeAddress = nodes[nextNodeAddress].next;
        }

        // Reset startBlockNumber if all nodes are removed.
        if (headNode == address(0)) {
            startBlockNumber = 0;
        }

        emit NodeRemoved(nodeAddress);
    }

    function _checkAndGrantAccess(address node) internal {
        if (nodes[node].stake >= stakeRequiredAmount) {
            streamrRegistry.grantPermission(systemStreamId, node, IStreamRegistry.PermissionType.Publish);
        } else {
            streamrRegistry.revokePermission(systemStreamId, node, IStreamRegistry.PermissionType.Publish);
        }
    }

    function nodeAddresses() public view returns (address[] memory resultAddresses) {
        resultAddresses = new address[](totalNodes);

        if (headNode == address(0)) {
            return resultAddresses;
        }

        address tailAddress = headNode;
        uint256 index = 0;
        do {
            resultAddresses[index] = tailAddress;

            tailAddress = nodes[tailAddress].next;
            index++;
        } while (tailAddress != address(0));

        return resultAddresses;
    }

    function nodeStake(address node) public view returns (uint256) {
        return nodes[node].stake;
    }

    function isStaked(address node) public view returns (bool) {
        return stakeRequiredAmount > 0 && nodes[node].stake >= stakeRequiredAmount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

// Open Zeppelin libraries for controlling upgradability and access.
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

// Owned by the NodeManager Contract
contract LogStoreQueryManager is Initializable, UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    event DataQueried(address indexed consumer, uint256 fees, uint256 bytesProcessed);
    event Stake(address indexed consumer, uint amount);
    event CaptureOverflow(address consumer, uint stake, uint capture, uint overflow);
    event SupplyOverflow(uint supply, uint capture, uint overflow);

    modifier onlyParent() {
        require(_msgSender() == parent, "error_onlyParent");
        _;
    }

    uint256 public totalSupply;
    address public stakeTokenAddress;
    mapping(address => uint256) public balanceOf; // map of addresses and their total balanace
    IERC20Upgradeable internal stakeToken;
    address internal parent;

    function initialize(address owner_, address parent_, address stakeTokenAddress_) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        require(stakeTokenAddress_ != address(0), "error_badTrackerData");
        stakeToken = IERC20Upgradeable(stakeTokenAddress_);
        stakeTokenAddress = stakeTokenAddress_;
        setParent(parent_);
        transferOwnership(owner_);
    }

    /// @dev required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyOwner {}

    function setParent(address _parent) public onlyOwner {
        parent = _parent;
    }

    /// Capture funds for a given query
    /// Only the LogStore Contract can call the capture method
    /// @param amount amount of tokens to capture
    /// @param consumer address of the data consumer
    /// @param bytesProcessed number of bytes in the response
    function capture(address consumer, uint256 amount, uint256 bytesProcessed) public nonReentrant onlyParent {
        require(balanceOf[consumer] > 0, "error_invalidConsumerAddress");

        uint256 amountToTransfer = amount;
        if (balanceOf[consumer] < amount) {
            emit CaptureOverflow(consumer, balanceOf[consumer], amount, amount - balanceOf[consumer]);
            amountToTransfer = balanceOf[consumer];
            balanceOf[consumer] = 0;
        } else {
            balanceOf[consumer] -= amount;
        }
        if (totalSupply < amount) {
            emit SupplyOverflow(totalSupply, amount, amount - totalSupply);
            totalSupply = 0;
        } else {
            totalSupply -= amount;
        }

        require(amountToTransfer <= stakeToken.balanceOf(address(this)), "error_insufficientStake");

        bool success = stakeToken.transfer(msg.sender, amountToTransfer);
        require(success == true, "error_unsuccessfulCapture");

        emit DataQueried(consumer, amount, bytesProcessed);
    }

    function stake(uint amount) public nonReentrant {
        require(amount > 0, "error_insufficientStake");

        balanceOf[msg.sender] += amount;
        totalSupply += amount;

        bool success = stakeToken.transferFrom(msg.sender, address(this), amount);
        require(success == true, "error_unsuccessfulStake");
        emit Stake(msg.sender, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

// Open Zeppelin libraries for controlling upgradability and access.
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {LogStoreNodeManager} from "./NodeManager.sol";
import {VerifySignature} from "./lib/VerifySignature.sol";
import {StringsUpgradeable} from "./lib/StringsUpgradeable.sol";

contract LogStoreReportManager is Initializable, UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    uint256 public constant MATH_PRECISION = 10 ** 10;

    event ReportAccepted(string id);

    struct Consumer {
        address id;
        uint256 readCapture;
        uint256 readBytes;
    }

    struct Stream {
        string id;
        uint256 writeCapture;
        uint256 writeBytes;
    }

    struct Node {
        address id;
        int256 amount;
    }

    struct Delegate {
        address id;
        Node[] nodes;
    }

    struct Report {
        string id; // key inside of bundle
        uint256 height;
        int256 treasury;
        Stream[] streams;
        Node[] nodes;
        Delegate[] delegates;
        Consumer[] consumers;
        address _reporter;
        bool _processed;
    }

    struct Proof {
        address signer;
        bytes signature;
        uint256 timestamp;
    }

    modifier onlyStaked() {
        require(_nodeManager.isStaked(_msgSender()), "error_stakeRequired");
        _;
    }

    modifier onlyParent() {
        require(_msgSender() == parent, "error_onlyParent");
        _;
    }

    uint256 public reportTimeBuffer;
    mapping(address => uint256) public reputationOf;
    string internal lastReportId;
    mapping(string => Report) internal reports;
    mapping(string => Proof[]) internal reportProofs;
    LogStoreNodeManager private _nodeManager;
    address internal parent;

    // used for unit testing time-dependent code
    // block.timestamp is a miner-dependent variable that progresses over time. accuracy of time isn't. simply it's guarantee of increment for each block.
    uint256 private _test_block_timestamp;

    function initialize(
        address owner_,
        address parent_,
        uint256 reportTimeBuffer_,
        uint256 __test_block_timestamp
    ) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        reportTimeBuffer = reportTimeBuffer_ * MATH_PRECISION;
        _test_block_timestamp = __test_block_timestamp * 1000 * MATH_PRECISION;

        setParent(parent_);
        transferOwnership(owner_);
    }

    /// @dev required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyOwner {}

    function setParent(address _parent) public onlyOwner {
        parent = _parent;
        _nodeManager = LogStoreNodeManager(_parent);
    }

    function setReportTimeBuffer(uint256 _reportTimeBuffer) public onlyOwner {
        reportTimeBuffer = _reportTimeBuffer * MATH_PRECISION;
    }

    function getReport(string calldata id) public view returns (Report memory) {
        return reports[id];
    }

    function getLastReport() public view returns (Report memory) {
        return reports[lastReportId];
    }

    function getProofOfReport(string calldata id) public view returns (Proof[] memory) {
        return reportProofs[id];
    }

    /**
     * This method will return the same array every time unless reputations are changed after a successfully accepted report.
     * use bubble sort to sort the node addresses
     */
    function getReporters() public view returns (address[] memory reporters) {
        reporters = _nodeManager.nodeAddresses();
        uint256 reportersCount = reporters.length;

        for (uint256 i = 0; i < reportersCount - 1; i++) {
            for (uint256 j = 0; j < reportersCount - i - 1; j++) {
                if (reputationOf[reporters[j + 1]] > reputationOf[reporters[j]]) {
                    (reporters[j], reporters[j + 1]) = (reporters[j + 1], reporters[j]);
                }
            }
        }
    }

    function processReport(string calldata id) public onlyParent {
        reports[id]._processed = true;
    }

    // Verifies a report and adds it to its accepted reports mapping
    function report(
        string calldata id,
        uint256 blockHeight,
        string[] calldata streams,
        uint256[] calldata writeCaptureAmounts,
        uint256[] calldata writeBytes,
        address[] calldata readConsumerAddresses,
        uint256[] calldata readCaptureAmounts,
        uint256[] calldata readBytes,
        address[] calldata nodes,
        int256[] calldata nodeChanges,
        address[] calldata delegates,
        address[][] calldata delegateNodes,
        int256[][] calldata delegateNodeChanges,
        int256 treasurySupplyChange,
        // Arrays of addresses, proofTimestamps, and signatures for verification of reporter & report data
        address[] calldata addresses,
        uint256[] calldata proofTimestamps,
        bytes[] calldata signatures
    ) public onlyStaked {
        require(reports[id]._processed == false, "error_reportAlreadyProcessed");
        require(blockHeight <= block.number && blockHeight > reports[lastReportId].height, "error_invalidReport");
        require(
            addresses.length * 3 == addresses.length + proofTimestamps.length + signatures.length,
            "error_invalidProofs"
        );

        address[] memory orderedReportersList = getReporters();

        // validate that enough members are paritipating to proceed
        require(quorumIsMet(addresses, orderedReportersList), "error_quorumNotMet");

        // validate that the current reporter can submit the report based on the current block.timestamp and quorum proofTimestamps
        require(_canReport(_msgSender(), orderedReportersList, proofTimestamps), "error_invalidReporter");

        // produce the pack based on parameters to use in consensus
        bytes memory pack;
        Stream[] memory rStreams = new Stream[](streams.length);
        for (uint256 i = 0; i < streams.length; i++) {
            pack = abi.encodePacked(
                pack,
                streams[i],
                StringsUpgradeable.toHexString(writeCaptureAmounts[i]),
                writeBytes[i]
            );
            rStreams[i] = Stream({id: streams[i], writeCapture: writeCaptureAmounts[i], writeBytes: writeBytes[i]});
        }

        Consumer[] memory rConsumers = new Consumer[](readConsumerAddresses.length);
        for (uint256 i = 0; i < readConsumerAddresses.length; i++) {
            pack = abi.encodePacked(
                pack,
                readConsumerAddresses[i],
                StringsUpgradeable.toHexString(readCaptureAmounts[i]),
                readBytes[i]
            );
            rConsumers[i] = Consumer({
                id: readConsumerAddresses[i],
                readCapture: readCaptureAmounts[i],
                readBytes: readBytes[i]
            });
        }

        Node[] memory rNodes = new Node[](nodes.length);
        for (uint256 i = 0; i < nodes.length; i++) {
            pack = abi.encodePacked(pack, nodes[i], StringsUpgradeable.toHexString(nodeChanges[i]));
            rNodes[i] = Node({id: nodes[i], amount: nodeChanges[i]});
        }

        Delegate[] memory rDelegates = new Delegate[](delegates.length);
        for (uint256 i = 0; i < delegates.length; i++) {
            bytes memory dPack;

            Node[] memory rDelegateNodes = new Node[](delegateNodes[i].length);
            for (uint256 j = 0; j < delegateNodes[i].length; j++) {
                dPack = abi.encodePacked(
                    dPack,
                    delegateNodes[i][j],
                    StringsUpgradeable.toHexString(delegateNodeChanges[i][j])
                );

                rDelegateNodes[j] = Node({id: delegateNodes[i][j], amount: delegateNodeChanges[i][j]});
            }
            pack = abi.encodePacked(pack, delegates[i], dPack);

            rDelegates[i] = Delegate({id: delegates[i], nodes: rDelegateNodes});
        }

        // Verify signatures, ordered by the reporter list and then adjust reputations
        // Start by ensuring all proofs provided belong to valid reporters.
        reportProofs[id] = new Proof[](0); // ordered by reporter list
        bool leadReporterReputationAdjusted = false;
        uint256 consensusCount;
        uint256 minConsensusCount = (orderedReportersList.length * MATH_PRECISION) / 2;

        for (uint256 i = 0; i < orderedReportersList.length; i++) {
            Proof memory proof; // The proof of the reporter
            for (uint256 j = 0; j < addresses.length; j++) {
                // Validate that the proof provided belongs to an address that's actually inside of the reporter list
                if (orderedReportersList[i] == addresses[j]) {
                    proof.signer = addresses[j];
                    proof.signature = signatures[j];
                    proof.timestamp = proofTimestamps[j];
                }
            }

            bytes32 timeBasedOneTimeHash = keccak256(
                abi.encodePacked(
                    id,
                    blockHeight,
                    pack,
                    StringsUpgradeable.toHexString(treasurySupplyChange),
                    proof.timestamp
                )
            );
            bool verified = VerifySignature.verify(proof.signer, timeBasedOneTimeHash, proof.signature);
            if (verified == true) {
                reportProofs[id].push(proof);

                consensusCount += 1 * MATH_PRECISION;

                // Increase rep of reporter if they're the sender
                // Otherwise, if this report was produced by a reporter that is NOT in the lead, decrease their reputation
                // Finally, if they're participating and NOT in the lead, minor increase rep of reporter
                if (_msgSender() == proof.signer) {
                    reputationOf[_msgSender()] += 10;
                    leadReporterReputationAdjusted = true;
                } else if (leadReporterReputationAdjusted == false) {
                    reputationOf[proof.signer] -= reputationOf[proof.signer] >= 5 ? 5 : reputationOf[proof.signer];
                } else {
                    reputationOf[proof.signer] += 1;
                }
            } else {
                // Bad proofs reset reputation to 0
                reputationOf[addresses[i]] = 0;
            }
        }

        require(consensusCount >= minConsensusCount, "error_consensusNotMet");

        // once consensus is reached among reporters, accept the report
        Report memory currentReport = Report({
            id: id,
            height: blockHeight,
            treasury: treasurySupplyChange,
            streams: rStreams,
            nodes: rNodes,
            delegates: rDelegates,
            consumers: rConsumers,
            _reporter: _msgSender(),
            _processed: false
        });

        reports[currentReport.id] = currentReport;
        lastReportId = currentReport.id;

        emit ReportAccepted(currentReport.id);
    }

    /**
     * Check to ensure that the addresses signing off on the report are >= minimum required nodes - ie. >= 50% of nodes
     */
    function quorumIsMet(
        address[] memory participants,
        address[] memory totalMembers
    ) public pure returns (bool isMet) {
        uint256 count;
        uint256 minCount = (totalMembers.length * MATH_PRECISION) / 2;

        for (uint256 i = 0; i < totalMembers.length; i++) {
            for (uint256 j = 0; j < participants.length; j++) {
                if (totalMembers[i] == participants[j]) {
                    count += 1 * MATH_PRECISION;
                    break;
                }
            }
            if (count >= minCount) {
                isMet = true;
                break;
            }
        }
    }

    function canReport(uint256[] memory timestamps) public view returns (bool) {
        address[] memory reporterList = getReporters();
        return _canReport(_msgSender(), reporterList, timestamps);
    }

    /**
     * Accepts an array of timestamps and evaluates the mean timestamp with precision
     */
    function aggregateTimestamps(uint256[] memory timestamps) public pure returns (uint256) {
        uint256 sum;
        for (uint256 i = 0; i < timestamps.length; i++) {
            sum += timestamps[i] * MATH_PRECISION;
        }
        uint256 mean = sum / timestamps.length;
        return mean;
    }

    function blockTimestamp() public view returns (uint256) {
        if (_test_block_timestamp > 0) {
            return _test_block_timestamp;
        }
        return block.timestamp * 1000 * MATH_PRECISION;
    }

    function _canReport(
        address reporter,
        address[] memory reporterList,
        uint256[] memory timestamps
    ) internal view returns (bool validReporter) {
        // Use all timestamps - as the more consistent the mean is as an anchor, the better.
        // Validators will subscibe to ProofOfReports to slash brokers that are working against the interests of the network.
        uint256 meanProofTimestamp = aggregateTimestamps(timestamps);
        uint256 preciseBlockTs = blockTimestamp();
        uint256 cycleTime = reportTimeBuffer * reporterList.length;
        uint256 cycle = 0; // first cycle
        while (preciseBlockTs >= ((cycle + 1) * cycleTime) + meanProofTimestamp) {
            // Is the current blockTs greater then the time of a full?
            // Set the current cycle based on this condition
            cycle += 1;
        }
        uint256 fromTime = (cycle * cycleTime) + meanProofTimestamp;

        for (uint256 i = 0; i < reporterList.length; i++) {
            if (reporterList[i] == reporter) {
                uint256 start = (i * reportTimeBuffer) + fromTime;
                uint256 end = ((i + 1) * reportTimeBuffer) + fromTime;

                validReporter = preciseBlockTs >= start && preciseBlockTs < end;
                break;
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

// Open Zeppelin libraries for controlling upgradability and access.
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {IStreamRegistry} from "./interfaces/StreamRegistry.sol";
import {StringsUpgradeable} from "./lib/StringsUpgradeable.sol";

// Owned by the NodeManager Contract
contract LogStoreManager is Initializable, UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    event StoreUpdated(string store, bool isNew, uint256 amount);
    event DataStored(string store, uint256 fees, uint256 bytesStored);
    event CaptureOverflow(string store, uint stake, uint capture, uint overflow);
    event SupplyOverflow(uint supply, uint capture, uint overflow);

    modifier onlyParent() {
        require(_msgSender() == parent, "error_onlyParent");
        _;
    }

    uint256 public totalSupply;
    address public stakeTokenAddress;
    mapping(string => uint256) public stores; // map of stores and their total balance
    mapping(string => address[]) public storeStakeholders; // map of stores and their stakeholders.
    mapping(address => uint256) public balanceOf; // map of addresses and their total balanace
    mapping(address => mapping(string => uint256)) public storeBalanceOf; // map of addresses and the stores they're staked in
    IERC20Upgradeable internal stakeToken;
    IStreamRegistry internal streamrRegistry;
    address internal parent;

    function initialize(
        address owner_,
        address parent_,
        address stakeTokenAddress_,
        address streamrRegistryAddress_
    ) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        require(stakeTokenAddress_ != address(0), "error_badTrackerData");
        streamrRegistry = IStreamRegistry(streamrRegistryAddress_);
        stakeToken = IERC20Upgradeable(stakeTokenAddress_);
        stakeTokenAddress = stakeTokenAddress_;

        setParent(parent_);
        transferOwnership(owner_);
    }

    /// @dev required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyOwner {}

    function setParent(address _parent) public onlyOwner {
        parent = _parent;
    }

    function exists(string calldata streamId) public view returns (bool) {
        return stores[streamId] > 0;
    }

    // Only the LogStore Contract can call the capture method
    function capture(string memory streamId, uint256 amount, uint256 bytesStored) public nonReentrant onlyParent {
        require(stores[streamId] > 0, "error_invalidStreamId");

        // Prevent overflow errors On-Chain
        // An overflow is where more data was processed than what has been staked for the relevant stream/store
        // Validators to index and manage any overflows.
        uint256 amountToTransfer = amount;
        if (stores[streamId] < amount) {
            emit CaptureOverflow(streamId, stores[streamId], amount, amount - stores[streamId]);
            amountToTransfer = stores[streamId];

            // Reset all stakeholders balances relative to the stream to 0
            address[] memory stakeholders = storeStakeholders[streamId];
            for (uint256 i = 0; i < stakeholders.length; i++) {
                address stakeholder = stakeholders[i];
                // Remove stake is stream from stakeholder balance, otherwise reset to 0 if balances are off.
                if (balanceOf[stakeholder] < storeBalanceOf[stakeholder][streamId]) {
                    balanceOf[stakeholder] = 0;
                } else {
                    balanceOf[stakeholder] -= storeBalanceOf[stakeholder][streamId];
                }
                storeBalanceOf[stakeholder][streamId] = 0;
            }
            // Remove all stakeholders from the stream since it's stake has been set to 0
            storeStakeholders[streamId] = new address[](0);

            // Set stake of stream to 0
            stores[streamId] = 0;
        } else {
            address[] memory stakeholders = storeStakeholders[streamId];
            // Determine the fee amounts proportional to each stakeholder stake amount
            for (uint256 i = 0; i < stakeholders.length; i++) {
                address stakeholder = stakeholders[i];
                uint256 stakeOwnership = storeBalanceOf[stakeholder][streamId] / stores[streamId];
                uint256 deduction = stakeOwnership * amount;
                if (balanceOf[stakeholder] < deduction) {
                    balanceOf[stakeholder] = 0;
                } else {
                    balanceOf[stakeholder] -= deduction;
                }
                if (storeBalanceOf[stakeholder][streamId] < deduction) {
                    storeBalanceOf[stakeholder][streamId] = 0;
                } else {
                    storeBalanceOf[stakeholder][streamId] -= deduction;
                }
                // if stake of a user is finished then remove from the list of delegates
                if (storeBalanceOf[stakeholder][streamId] == 0) {
                    storeStakeholders[streamId] = new address[](0);
                    for (uint256 j = 0; j < stakeholders.length; j++) {
                        if (stakeholders[j] != stakeholder) {
                            storeStakeholders[streamId].push(stakeholder);
                        }
                    }
                }
            }

            stores[streamId] -= amount;
        }

        if (totalSupply < amount) {
            emit SupplyOverflow(totalSupply, amount, amount - totalSupply);
            totalSupply = 0;
        } else {
            totalSupply -= amount;
        }

        require(amountToTransfer <= stakeToken.balanceOf(address(this)), "error_insufficientStake");

        bool transferSuccess = stakeToken.transfer(msg.sender, amountToTransfer);
        require(transferSuccess == true, "error_unsuccessfulCapture");

        emit DataStored(streamId, amount, bytesStored);
    }

    function stake(string memory streamId, uint amount) public {
        // Validate stream is inside of StreamrRegiststry
        require(streamrRegistry.exists(streamId), "error_invalidStream");
        require(amount > 0, "error_insufficientStake");

        bool success = stakeToken.transferFrom(msg.sender, address(this), amount);
        require(success == true, "error_unsuccessfulStake");

        bool isNew = false;
        if (stores[streamId] == 0) {
            isNew = true;
        }
        stores[streamId] += amount;
        balanceOf[msg.sender] += amount;
        if (storeBalanceOf[msg.sender][streamId] == 0) {
            storeStakeholders[streamId].push(msg.sender);
        }
        storeBalanceOf[msg.sender][streamId] += amount;
        totalSupply += amount;
        emit StoreUpdated(streamId, isNew, amount);
    }
}