// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../interfaces/Stargate/IStargateRouter.sol";

import "../interfaces/Zorro/controllers/IControllerXChain.sol";

import "../interfaces/Zorro/vaults/IVault.sol";

import "../libraries/LPUtility.sol";

import "../libraries/SafeSwap.sol";

// TODO: Make pausable

/// @title ControllerXChain
/// @notice Controls all cross chain operations
contract ControllerXChain is
    IControllerXChain,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    /* Constants */

    uint256 public constant BP_DENOMINATOR = 10000; // Basis point denominator

    /* Libraries */

    using SafeSwapUni for IAMMRouter02;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using LPUtility for IAMMRouter02;

    /* Constructor */

    /// @notice Constructor
    /// @param _initVal A ControllerXChainInit struct
    /// @param _timelockOwner The designated owner of this contract (usually a timelock)
    function initialize(
        ControllerXChainInit memory _initVal,
        address _timelockOwner
    ) public initializer {
        // Set state variables
        layerZeroEndpoint = _initVal.layerZeroEndpoint;
        stargateRouter = _initVal.stargateRouter;
        currentChain = _initVal.currentChain;
        sgPoolId = _initVal.sgPoolId;

        router = _initVal.router;
        stablecoin = _initVal.stablecoin;
        stablecoinPriceFeed = AggregatorV3Interface(
            _initVal.stablecoinPriceFeed
        );

        // Transfer ownership
        _transferOwnership(_timelockOwner);
    }

    /* State */

    // Infra
    address public layerZeroEndpoint;
    address public stargateRouter;
    uint16 public currentChain;
    uint256 public sgPoolId;

    // Swaps
    address public router;
    address public stablecoin;
    AggregatorV3Interface public stablecoinPriceFeed;

    /* Setters */

    /// @notice Sets key cross chain contract addresses
    /// @param _lzEndpoint LayerZero endpoint address
    /// @param _sgRouter Stargate Router address
    /// @param _chain LZ chain ID
    /// @param _sgPoolId Stargate Pool ID
    function setKeyXChainParams(
        address _lzEndpoint,
        address _sgRouter,
        uint16 _chain,
        uint256 _sgPoolId
    ) external onlyOwner {
        layerZeroEndpoint = _lzEndpoint;
        stargateRouter = _sgRouter;
        currentChain = _chain;
        sgPoolId = _sgPoolId;
    }

    /// @notice Sets swap parameters
    /// @param _router Router address
    /// @param _stablecoin Stablecoin address
    /// @param _stablecoinPriceFeed Price feed of stablecoin associated with this chain/endpoint on Stargate
    function setSwapParams(
        address _router,
        address _stablecoin,
        address _stablecoinPriceFeed
    ) external onlyOwner {
        router = _router;
        stablecoin = _stablecoin;
        stablecoinPriceFeed = AggregatorV3Interface(_stablecoinPriceFeed);
    }

    /* Modifiers */

    /// @notice Ensures cross chain request is coming only from a LZ endpoint or STG router address
    modifier onlyRegEndpoint() {
        require(
            msg.sender == layerZeroEndpoint || msg.sender == stargateRouter,
            "Unrecog xchain sender"
        );
        _;
    }

    /* Deposits */

    /// @inheritdoc	IControllerXChain
    function encodeDepositRequest(
        address _vault,
        uint256 _valueUSD,
        uint256 _slippageFactor,
        address _wallet
    ) external pure returns (bytes memory payload) {
        // Calculate method signature
        bytes4 _sig = this.receiveDepositRequest.selector;

        // Calculate abi encoded bytes for input args
        bytes memory _inputs = abi.encode(
            _vault,
            _valueUSD,
            _slippageFactor,
            _wallet
        );

        // Concatenate bytes of signature and inputs
        payload = bytes.concat(_sig, _inputs);

        require(payload.length > 0, "Invalid xchain payload");
    }

    /// @inheritdoc	IControllerXChain
    function getDepositQuote(
        uint16 _dstChain,
        bytes calldata _dstContract,
        bytes calldata _payload,
        uint256 _dstGasForCall
    ) external view returns (uint256 nativeFee) {
        // Init empty LZ object
        IStargateRouter.lzTxObj memory _lzTxParams;

        // Tack on xchain contract gas fee
        _lzTxParams.dstGasForCall = _dstGasForCall;

        // Calculate native gas fee and ZRO token fee (Layer Zero token)
        (nativeFee, ) = IStargateRouter(stargateRouter).quoteLayerZeroFee(
            _dstChain,
            1,
            _dstContract,
            _payload,
            _lzTxParams
        );
    }

    /// @inheritdoc	IControllerXChain
    function sendDepositRequest(
        uint16 _dstChain,
        uint256 _dstPoolId,
        bytes calldata _remoteControllerXChain,
        address _vault,
        address _dstWallet,
        uint256 _amountUSD,
        uint256 _slippageFactor,
        uint256 _dstGasForCall
    ) external payable nonReentrant {
        // Require funds to be submitted with this message
        require(msg.value > 0, "No fees submitted");
        require(_amountUSD > 0, "No USD submitted");

        // Transfer USD into this contract
        IERC20Upgradeable(stablecoin).safeTransferFrom(
            msg.sender,
            address(this),
            _amountUSD
        );

        // Check balances
        uint256 _balUSD = IERC20Upgradeable(stablecoin).balanceOf(
            address(this)
        );

        // Generate payload
        bytes memory _payload = this.encodeDepositRequest(
            _vault,
            _balUSD,
            _slippageFactor,
            _dstWallet
        );

        // Call stargate to initiate bridge
        _callStargateSwapUSD(
            _dstChain,
            _dstPoolId,
            _balUSD,
            _balUSD * _slippageFactor / BP_DENOMINATOR,
            _remoteControllerXChain,
            _dstGasForCall,
            _payload
        );
    }

    /// @inheritdoc	IControllerXChain
    function receiveDepositRequest(
        address _vault,
        uint256 _valueUSD,
        uint256 _slippageFactor,
        address _wallet
    ) public onlyRegEndpoint {
        // Revert to make sure this function never gets called
        require(false, "dummyfunc");

        // Satisfy compiler warnings (no execution)
        _receiveDepositRequest(_vault, _valueUSD, _slippageFactor, _wallet);
    }

    /// @notice Internal function for receiving and processing deposit request
    /// @param _vault Address of the vault on the remote chain to deposit into
    /// @param _valueUSD The amount of USD to deposit
    /// @param _slippageFactor Acceptable degree of slippage on any transaction (e.g. 9500 = 5%, 9900 = 1% etc.)
    /// @param _wallet The wallet on the current (receiving) chain that should receive the vault token upon deposit
    function _receiveDepositRequest(
        address _vault,
        uint256 _valueUSD,
        uint256 _slippageFactor,
        address _wallet
    ) internal {
        // Read vault stablecoin
        address _vaultStablecoin = IVault(_vault).stablecoin();

        // Approve spending
        IERC20Upgradeable(_vaultStablecoin).safeIncreaseAllowance(
            _vault,
            _valueUSD
        );

        // Deposit USD into vault
        IVault(_vault).depositUSD(_valueUSD, _slippageFactor);

        // Get quantity of received shares
        uint256 _receivedShares = IERC20Upgradeable(_vault).balanceOf(
            address(this)
        );

        // Send resulting shares to specified wallet
        IERC20Upgradeable(_vault).safeTransfer(_wallet, _receivedShares);
    }

    /* Withdrawals */

    /// @inheritdoc	IControllerXChain
    function encodeWithdrawalRequest(
        address _dstWallet
    ) external pure returns (bytes memory payload) {
        // Calculate method signature
        bytes4 _sig = this.receiveWithdrawalRequest.selector;

        // Calculate abi encoded bytes for input args
        bytes memory _inputs = abi.encode(_dstWallet);

        // Concatenate bytes of signature and inputs
        payload = bytes.concat(_sig, _inputs);

        require(payload.length > 0, "Invalid xchain payload");
    }

    /// @inheritdoc	IControllerXChain
    function getWithdrawalQuote(
        uint16 _dstChain,
        bytes calldata _dstContract,
        bytes calldata _payload,
        uint256 _dstGasForCall
    ) external view returns (uint256 nativeFee) {
        // Init empty LZ object
        IStargateRouter.lzTxObj memory _lzTxParams;

        // Tack on xchain contract gas fee
        _lzTxParams.dstGasForCall = _dstGasForCall;

        // Calculate native gas fee
        (nativeFee, ) = IStargateRouter(stargateRouter).quoteLayerZeroFee(
            _dstChain,
            1,
            _dstContract,
            _payload,
            _lzTxParams
        );
    }

    /// @inheritdoc	IControllerXChain
    function sendWithdrawalRequest(
        uint16 _dstChain,
        uint256 _dstPoolId,
        bytes calldata _remoteControllerXChain,
        address _vault,
        uint256 _shares,
        uint256 _slippageFactor,
        address _dstWallet,
        uint256 _dstGasForCall
    ) external payable nonReentrant {
        // Safe transfer IN the vault tokens
        IERC20Upgradeable(_vault).safeTransferFrom(
            _msgSender(),
            address(this),
            _shares
        );

        // Approve spending
        IERC20Upgradeable(_vault).safeIncreaseAllowance(_vault, _shares);

        // Perform withdraw USD operation
        IVault(_vault).withdrawUSD(_shares, _slippageFactor);

        // Get USD balance
        uint256 _balUSD = IERC20Upgradeable(stablecoin).balanceOf(
            address(this)
        );
        require(_balUSD > 0, "no USD withdrawn");

        // Get withdrawal payload
        bytes memory _payload = this.encodeWithdrawalRequest(_dstWallet);

        // Call Stargate Swap operation
        // Call stargate to initiate bridge
        _callStargateSwapUSD(
            _dstChain,
            _dstPoolId,
            _balUSD,
            _balUSD * _slippageFactor / BP_DENOMINATOR,
            _remoteControllerXChain,
            _dstGasForCall,
            _payload
        );
    }

    /// @inheritdoc	IControllerXChain
    function receiveWithdrawalRequest(address _wallet) public onlyRegEndpoint {
        // Revert to make sure this function never gets called
        require(false, "dummyfunc");

        // Satisfy compiler warnings (no execution)
        _receiveWithdrawalRequest(_wallet, address(0));
    }

    /// @notice Internal function for receiving and processing withdrawal request
    /// @param _wallet The address to send the tokens from the cross chain swap to
    /// @param _token The address of the token received in the cross chain swap
    function _receiveWithdrawalRequest(
        address _wallet,
        address _token
    ) internal {
        // Get current balance
        uint256 _balToken = IERC20Upgradeable(_token).balanceOf(address(this));

        // Send tokens to wallet
        IERC20Upgradeable(_token).safeTransfer(_wallet, _balToken);
    }

    /* Receive XChain */

    /// @inheritdoc	IStargateReceiver
    function sgReceive(
        uint16 _chainId,
        bytes memory _srcAddress,
        uint256 _nonce,
        address _token,
        uint256 amountLD,
        bytes memory payload
    ) external onlyRegEndpoint nonReentrant {
        // Prechecks / authorization
        require(_chainId >= 0);
        require(_srcAddress.length > 0);
        require(_nonce >= 0);

        // Amounts
        uint256 _tokenBal = IERC20Upgradeable(_token).balanceOf(address(this));
        require(amountLD <= _tokenBal, "amountLD exceeds bal");

        // Determine function based on signature
        // Get func signature
        bytes4 _funcSig = bytes4(payload);
        // Get params payload only
        bytes memory _paramsPayload = this.extractParamsPayload(payload);

        // Match to appropriate func
        if (this.receiveDepositRequest.selector == _funcSig) {
            // Decode params
            (address _vault, , uint256 _slippageFactor, address _wallet) = abi
                .decode(_paramsPayload, (address, uint256, uint256, address));

            // Determine stablecoin expected by vault
            address _vaultStablecoin = IVault(_vault).stablecoin();

            // Swap to default stablecoin for this vault (if applicable)
            if (_token != _vaultStablecoin) {
                // Calculate swap path
                address[] memory _swapPath = new address[](2);
                _swapPath[0] = _token;
                _swapPath[1] = _vaultStablecoin;

                // Perform swap
                IAMMRouter02(router).safeSwap(
                    _tokenBal,
                    _token,
                    _vaultStablecoin,
                    _swapPath,
                    stablecoinPriceFeed,
                    IVault(_vault).priceFeeds(_vaultStablecoin),
                    _slippageFactor,
                    address(this)
                );
            }

            // Determine bal of stablecoin for vault
            uint256 _balVaultStablecoin = IERC20Upgradeable(_vaultStablecoin)
                .balanceOf(address(this));

            // Call receiving function for cross chain deposits
            // Replace _valueUSD to account for any slippage during bridging
            _receiveDepositRequest(
                _vault,
                _balVaultStablecoin,
                _slippageFactor,
                _wallet
            );
        } else if (this.receiveWithdrawalRequest.selector == _funcSig) {
            // Decode params from payload
            address _wallet = abi.decode(_paramsPayload, (address));

            // Forward request to distribution function
            _receiveWithdrawalRequest(_wallet, _token);
        } else {
            revert("Unrecognized func");
        }
    }

    /// @notice Internal function for making swap calls to Stargate
    /// @dev IMPORTANT: This function assumes that the input token is the same as the `stablecoin` value on this contract
    /// @param _dstChainId The destination LZ chain Id
    /// @param _dstPoolId The Stargate pool on the destination chain to swap with
    /// @param _amountUSD The amount of input token (USD) on this chain to swap
    /// @param _minAmountLD The minimal amount of output token expected on the destination chain
    /// @param _dstControllerXChain Zorro cross chain controller address on the destination chain
    /// @param _dstGasForCall How much gas to reserve for the remote chain function execution
    /// @param _payload Payload for function execution on the remote chain
    function _callStargateSwapUSD(
        uint16 _dstChainId,
        uint256 _dstPoolId,
        uint256 _amountUSD,
        uint256 _minAmountLD,
        bytes calldata _dstControllerXChain,
        uint256 _dstGasForCall,
        bytes memory _payload
    ) internal {
        // Approve spending by Stargate
        IERC20Upgradeable(stablecoin).safeIncreaseAllowance(
            stargateRouter,
            _amountUSD
        );

        // Specify gas for cross chain message
        IStargateRouter.lzTxObj memory _lzTxObj;
        _lzTxObj.dstGasForCall = _dstGasForCall;

        // Swap call
        IStargateRouter(stargateRouter).swap{value: msg.value}(
            _dstChainId,
            sgPoolId,
            _dstPoolId,
            payable(_msgSender()),
            _amountUSD,
            _minAmountLD,
            _lzTxObj,
            _dstControllerXChain,
            _payload
        );
    }

    /* Utilities */

    /// @notice Removes function signature from ABI encoded payload
    /// @param _payloadWithSig ABI encoded payload with function selector
    /// @return paramsPayload Payload with params only
    function extractParamsPayload(
        bytes calldata _payloadWithSig
    ) public pure returns (bytes memory paramsPayload) {
        paramsPayload = _payloadWithSig[4:];
    }

    /// @notice For owner to recover ERC20 tokens on this contract if stuck
    /// @dev Does not permit usage for the Zorro token
    /// @param _token ERC20 token address
    /// @param _amount token quantity
    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount
    ) public onlyOwner {
        IERC20Upgradeable(_token).safeTransfer(_msgSender(), _amount);
    }

    /* Proxy implementations */
    
    function _authorizeUpgrade(address) internal override onlyOwner {}
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.7.6;

interface IStargateReceiver {
    /// @notice Function for composable logic on the destination chain
    /// @dev See https://stargateprotocol.gitbook.io/stargate/interfaces/evm-solidity-interfaces/istargatereceiver.sol
    /// @param _chainId Origin LayerZero chain ID that sent the tokens
    /// @param _srcAddress The remote bridge address
    /// @param _nonce Nonce to track transaction
    /// @param _token The token contract on the local chain
    /// @param amountLD The qty of local _token contract tokens
    /// @param payload Payload sent from source chain to be executed here
    function sgReceive(
        uint16 _chainId,
        bytes memory _srcAddress,
        uint256 _nonce,
        address _token,
        uint256 amountLD,
        bytes memory payload
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.7.6;
pragma abicoder v2;

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function addLiquidity(
        uint256 _poolId,
        uint256 _amountLD,
        address _to
    ) external;

    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    function redeemRemote(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        uint256 _minAmountLD,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function instantRedeemLocal(
        uint16 _srcPoolId,
        uint256 _amountLP,
        address _to
    ) external returns (uint256);

    function redeemLocal(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function sendCredits(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress
    ) external payable;

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.12 <0.9.0;

interface IAMMRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.12 <0.9.0;

import "./IAMMRouter01.sol";

interface IAMMRouter02 is IAMMRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "../../Stargate/IStargateReceiver.sol";

/// @title IControllerXChain
/// @notice Interface for cross chain controller
interface IControllerXChain is IStargateReceiver {
    /* Events */

    /* Structs */ 

    struct ControllerXChainInit {
        address layerZeroEndpoint;
        address stargateRouter;
        uint16 currentChain;
        uint256 sgPoolId;

        address router;
        address stablecoin;
        address stablecoinPriceFeed;
    }

    /* State */

    // Infra

    /// @notice Gets Layer Zero cross chain endpoint address
    /// @return Address of endpoint
    function layerZeroEndpoint() external view returns (address);

    /// @notice Gets Stargate Router address
    /// @return Address of router
    function stargateRouter() external view returns (address);

    /// @notice Gets the LZ chain ID associated with this chain/contract
    /// @return Chain ID
    function currentChain() external view returns (uint16);

    /// @notice Gets the Stargate Pool ID associated with this chain/contract
    /// @return Pool ID
    function sgPoolId() external view returns (uint256);

    // Swaps

    /// @notice Gets Uni compatible router address (for swaps etc.)
    /// @return Address of router
    function router() external view returns (address);

    /// @notice Gets default stablecoin used on this chain/contract
    /// @return Address of stablecoin
    function stablecoin() external view returns (address);

    /// @notice Gets Uni compatible router address (for swaps etc.)
    /// @return Address of router
    function stablecoinPriceFeed() external view returns (AggregatorV3Interface);

    /* Deposits */ 

    /// @notice Encodes payload for deposit request
    /// @param _vault The vault address on the destination chain, to receive deposit
    /// @param _valueUSD Value of stablecoin to deposit on this chain, to be transferred to remote chain for deposit
    /// @param _slippageFactor Acceptable degree of slippage on any transaction (e.g. 9500 = 5%, 9900 = 1% etc.)
    /// @param _wallet Address on destination chain to send vault tokens to post-deposit
    function encodeDepositRequest(
        address _vault,
        uint256 _valueUSD,
        uint256 _slippageFactor,
        address _wallet
    ) external view returns (bytes memory);

    /// @notice Checks to see how much a cross chain deposit will cost
    /// @param _dstChain The LayerZero Chain ID
    /// @param _dstContract The remote chain's Zorro ControllerXChain contract
    /// @param _payload The byte encoded cross chain payload (use encodeXChainDepositPayload() above)
    /// @param _dstGasForCall The amount of gas to send on the destination chain for composable contract execution
    /// @return nativeFee Expected fee to pay for bridging/cross chain execution
    function getDepositQuote(
        uint16 _dstChain,
        bytes calldata _dstContract,
        bytes calldata _payload,
        uint256 _dstGasForCall
    ) external view returns (uint256 nativeFee);

    /// @notice Prepares and sends a cross chain deposit request. Takes care of necessary financial ops (transfer/locking USD)
    /// @dev Requires appropriate fee to be paid via msg.value
    /// @param _dstChain LZ chain ID of the destination chain
    /// @param _dstPoolId The Stargate Pool ID to swap with on the remote chain
    /// @param _remoteControllerXChain Zorro ControllerXChain contract address on remote chain
    /// @param _vault Address of the vault on the remote chain to deposit into
    /// @param _dstWallet Address on destination chain to send vault tokens to post-deposit
    /// @param _amountUSD The amount of USD to deposit
    /// @param _slippageFactor Slippage tolerance for destination deposit function (9900 = 1%)
    /// @param _dstGasForCall Amount of gas to spend on the cross chain transaction
    function sendDepositRequest(
        uint16 _dstChain,
        uint256 _dstPoolId,
        bytes memory _remoteControllerXChain,
        address _vault,
        address _dstWallet,
        uint256 _amountUSD,
        uint256 _slippageFactor,
        uint256 _dstGasForCall
    ) external payable;

    /// @notice Dummy function for receiving deposit request
    /// @dev Necessary for type safety when matching function signatures. Actual logic is in internal _receiveDepositRequest() func.
    /// @param _vault Address of the vault on the remote chain to deposit into
    /// @param _valueUSD The amount of USD to deposit
    /// @param _slippageFactor Acceptable degree of slippage on any transaction (e.g. 9500 = 5%, 9900 = 1% etc.)
    /// @param _wallet The wallet on the current (receiving) chain that should receive the vault token upon deposit
    function receiveDepositRequest(
        address _vault,
        uint256 _valueUSD,
        uint256 _slippageFactor,
        address _wallet
    ) external;

    /* Withdrawals */

    /// @notice Encodes payload for making cross chan withdrawal
    /// @param _dstWallet The address on the remote chain to send bridged funds to
    function encodeWithdrawalRequest(
        address _dstWallet
    ) external view returns (bytes memory payload);

    /// @notice Gets quote for bridging withdrawn assets to another chain and sending to wallet
    /// @param _dstChain The LZ chain ID of the remote chain
    /// @param _dstContract The ControllerXChain contract on the remote chain
    /// @param _payload The payload to execute a function call on the remote chain
    /// @param _dstGasForCall Amount of gas to spend on the cross chain transaction
    /// @return nativeFee The fee in native coin to send to the router for the cross chain bridge
    function getWithdrawalQuote(
        uint16 _dstChain,
        bytes calldata _dstContract,
        bytes calldata _payload,
        uint256 _dstGasForCall
    ) external view returns (uint256 nativeFee);

    /// @notice Withdraws funds on chain and bridges to a destination wallet on a remote chain
    /// @param _dstChain The remote LZ chain ID to bridge funds to
    /// @param _dstPoolId The pool ID to swap tokens on the remote chain
    /// @param _remoteControllerXChain The ControllerXChain contract on the remote chain
    /// @param _vault Vault address on current chain to withdraw funds from
    /// @param _shares Number of shares of the vault to withdraw
    /// @param _slippageFactor Acceptable degree of slippage on any transaction (e.g. 9500 = 5%, 9900 = 1% etc.)
    /// @param _dstWallet The address on the remote chain to send bridged funds to
    /// @param _dstGasForCall Amount of gas to spend on the cross chain transaction
    function sendWithdrawalRequest(
        uint16 _dstChain,
        uint256 _dstPoolId,
        bytes calldata _remoteControllerXChain,
        address _vault,
        uint256 _shares,
        uint256 _slippageFactor,
        address _dstWallet,
        uint256 _dstGasForCall
    ) external payable;

    /// @notice Dummy function for receiving withdrawn funds on a remote chain
    /// @dev Necessary for type safety when matching function signatures. Actual logic is in internal _receiveWithdrawalRequest() func.
    /// @param _wallet Address for where to send withdrawn funds on-chain
    function receiveWithdrawalRequest(
        address _wallet
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @title IVault
/// @notice Interface for all vaults
interface IVault is IERC20Upgradeable {
    /* Events */

    event DepositAsset(
        address indexed _pool,
        uint256 indexed _amount,
        uint256 indexed _sharesAdded
    );

    event DepositUSD(
        address indexed _pool,
        uint256 indexed _amountUSD,
        uint256 indexed _sharesAdded,
        uint256 _maxSlippageFactor
    );

    event WithdrawAsset(
        address indexed _pool,
        uint256 indexed _shares,
        uint256 indexed _amountAssetRemoved,
        bool withdrewWithoutEarn
    );

    event WithdrawUSD(
        address indexed _pool,
        uint256 indexed _amountUSD,
        uint256 indexed _sharesRemoved,
        bool withdrewWithoutEarn,
        uint256 _maxSlippageFactor
    );

    event ReinvestEarnings(
        uint256 indexed _amtReinvested,
        address indexed _assetToken
    );

    /* Structs */

    struct VaultInit {
        address treasury;
        address router;
        address stablecoin;
        uint256 entranceFeeFactor;
        uint256 withdrawFeeFactor;
    }

    /* Functions */

    // Key wallets/contracts

    /// @notice The Treasury (where fees get sent to)
    /// @return The address of the Treasury
    function treasury() external view returns (address);

    /// @notice The Uniswap compatible router
    /// @return The address of the router
    function router() external view returns (address);

    /// @notice The default stablecoin (e.g. USDC, BUSD)
    /// @return The address of the stablecoin
    function stablecoin() external view returns (address);

    // Accounting & Fees

    /// @notice Entrance fee - goes to treasury
    /// @dev 9990 results in a 0.1% deposit fee (1 - 9990/10000)
    /// @return The entrance fee factor
    function entranceFeeFactor() external view returns (uint256);

    /// @notice Withdrawal fee - goes to treasury
    /// @return The withdrawal fee factor
    function withdrawFeeFactor() external view returns (uint256);

    /// @notice Default value for slippage if not overridden by a specific func
    /// @dev 9900 results in 1% slippage (1 - 9900/10000)
    /// @return The slippage factor numerator
    function defaultSlippageFactor() external view returns (uint256);

    // Governor

    /// @notice Governor address for non timelock admin operations
    /// @return The address of the governor
    function gov() external view returns (address);

    // Cash flow operations

    /// @notice Converts USD* to main asset and deposits it
    /// @param _amountUSD The amount of USD to deposit
    /// @param _maxSlippageFactor Max amount of slippage tolerated per AMM operation (9900 = 1%)
    function depositUSD(
        uint256 _amountUSD,
        uint256 _maxSlippageFactor
    ) external;

    /// @notice Withdraws main asset, converts to USD*, and sends back to sender
    /// @param _shares The number of shares of the main asset to withdraw
    /// @param _maxSlippageFactor Max amount of slippage tolerated per AMM operation (9900 = 1%)
    function withdrawUSD(uint256 _shares, uint256 _maxSlippageFactor) external;

    // Token operations

    /// @notice Shows swap paths for a given start and end token
    /// @param _startToken The origin token to swap from
    /// @param _endToken The destination token to swap to
    /// @param _index The index of the swap path to retrieve the token for
    /// @return The token address
    function swapPaths(
        address _startToken,
        address _endToken,
        uint256 _index
    ) external view returns (address);

    /// @notice Shows the length of the swap path for a given start and end token
    /// @param _startToken The origin token to swap from
    /// @param _endToken The destination token to swap to
    /// @return The length of the swap paths
    function swapPathLength(
        address _startToken,
        address _endToken
    ) external view returns (uint16);

    /// @notice Returns a Chainlink-compatible price feed for a provided token address, if it exists
    /// @param _token The token to return a price feed for
    /// @return An AggregatorV3 price feed
    function priceFeeds(
        address _token
    ) external view returns (AggregatorV3Interface);

    // Maintenance

    /// @notice Pauses key contract operations
    function pause() external;

    /// @notice Resumes key contract operations
    function unpause() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../interfaces/Uniswap/IAMMRouter02.sol";

/// @title LPUtility
/// @notice Library for adding/removing liquidity from LP pools
library LPUtility {
    /* Libraries */

    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* Functions */

    /// @notice For adding liquidity to an LP pool
    /// @param _uniRouter Uniswap V2 router
    /// @param _token0 Address of the first token
    /// @param _token1 Address of the second token
    /// @param _token0Amt Quantity of Token0 to add
    /// @param _token1Amt Quantity of Token1 to add
    /// @param _maxSlippageFactor The max slippage allowed for swaps. 1000 = 0 %, 995 = 0.5%, etc.
    /// @param _recipient The recipient of the LP token
    function joinPool(
        IAMMRouter02 _uniRouter,
        address _token0,
        address _token1,
        uint256 _token0Amt,
        uint256 _token1Amt,
        uint256 _maxSlippageFactor,
        address _recipient
    ) internal {
        // Approve spending
        IERC20Upgradeable(_token0).safeIncreaseAllowance(address(_uniRouter), _token0Amt);
        IERC20Upgradeable(_token1).safeIncreaseAllowance(address(_uniRouter), _token1Amt);

        // Add liquidity
        _uniRouter.addLiquidity(
            _token0,
            _token1,
            _token0Amt,
            _token1Amt,
            (_token0Amt * _maxSlippageFactor) / 10000,
            (_token1Amt * _maxSlippageFactor) / 10000,
            _recipient,
            block.timestamp + 600
        );
    }

    /// @notice For removing liquidity from an LP pool
    /// @dev NOTE: Assumes LP token is already on contract
    /// @param _uniRouter Uniswap V2 router
    /// @param _amountLP The amount of LP tokens to remove
    /// @param _maxSlippageFactor The max slippage allowed for swaps. 10000 = 0 %, 9950 = 0.5%, etc.
    /// @param _recipient The recipient of the underlying tokens upon pool exit
    function exitPool(
        IAMMRouter02 _uniRouter,
        uint256 _amountLP,
        address _pool,
        address _token0,
        address _token1,
        uint256 _maxSlippageFactor,
        address _recipient
    ) internal {
        // Init
        uint256 _amount0Min;
        uint256 _amount1Min;

        {
            _amount0Min = _calcMinAmt(
                _amountLP,
                _token0,
                _pool,
                _maxSlippageFactor
            );
            _amount1Min = _calcMinAmt(
                _amountLP,
                _token1,
                _pool,
                _maxSlippageFactor
            );
        }

        // Approve
        IERC20Upgradeable(_pool).safeIncreaseAllowance(
                address(_uniRouter),
                _amountLP
            );

        // Remove liquidity
        _uniRouter.removeLiquidity(
            _token0,
            _token1,
            _amountLP,
            _amount0Min,
            _amount1Min,
            _recipient,
            block.timestamp + 300
        );
    }

    /// @notice Calculates minimum amount out for exiting LP pool
    /// @param _amountLP LP token qty
    /// @param _token Address of one of the tokens in the pair
    /// @param _pool Address of LP pair
    /// @param _slippageFactor Slippage (9900 = 1% etc.)
    function _calcMinAmt(
        uint256 _amountLP,
        address _token,
        address _pool,
        uint256 _slippageFactor
    ) private view returns (uint256) {
        // Get total supply and calculate min amounts desired based on slippage
        uint256 _totalSupply = IERC20Upgradeable(_pool).totalSupply();

        // Get balance of token in pool
        uint256 _balance = IERC20Upgradeable(_token).balanceOf(_pool);

        // Return min token amount out
        return
            (_amountLP * _balance * _slippageFactor) /
            (10000 * _totalSupply);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @title PriceFeed
/// @notice Library for getting exchange rates from price feeds, and other utilties
library PriceFeed {
    /* Functions */

    /// @notice Calculates exchange rate vs USD for a given priceFeed
    /// @dev Assumes price feed is in USD. If not, either multiply obtained exchange rate with another, or override this func.
    /// @param _priceFeed The Chainlink price feed
    /// @return uint256 Exchange rate vs USD, multiplied by 1e12
    function getExchangeRate(AggregatorV3Interface _priceFeed)
        internal
        view
        returns (uint256)
    {
        // Use price feed to determine exchange rates
        uint8 _decimals = _priceFeed.decimals();
        (, int256 _price, , , ) = _priceFeed.latestRoundData();

        // Safeguard on signed integers
        require(_price >= 0, "neg prices not allowed");

        // Get the price of the token times 1e12, accounting for decimals
        return (uint256(_price) * 1e12) / 10**_decimals;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "./PriceFeed.sol";

import "../interfaces/Uniswap/IAMMRouter02.sol";

/// @title SafeSwapUni
/// @notice Library for safe swapping of ERC20 tokens for Uniswap/Pancakeswap style protocols
library SafeSwapUni {
    /* Libraries */

    using PriceFeed for AggregatorV3Interface;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* Structs */

    struct SafeSwapParams {
        uint256 amountIn;
        uint256 priceToken0;
        uint256 priceToken1;
        address token0;
        address token1;
        uint256 maxMarketMovementAllowed;
        address[] path;
        address destination;
    }

    /* Functions */

    /// @notice Safely swaps from one token to another
    /// @dev Tries to use a Chainlink price feed oracle if one exists
    /// @param _uniRouter Uniswap V2 router
    /// @param _amountIn The quantity of the origin token to swap
    /// @param _startToken The origin token (to swap FROM)
    /// @param _endToken The destination token (to swap TO)
    /// @param _swapPath The array of tokens representing the swap path
    /// @param _priceFeedStart The Chainlink compatible price feed of the start token
    /// @param _priceFeedEnd The Chainlink compatible price feed of the end token
    /// @param _maxSlippageFactor The max slippage factor tolerated (9900 = 1%)
    /// @param _destination Where to send the swapped token to
    function safeSwap(
        IAMMRouter02 _uniRouter,
        uint256 _amountIn,
        address _startToken,
        address _endToken,
        address[] memory _swapPath,
        AggregatorV3Interface _priceFeedStart,
        AggregatorV3Interface _priceFeedEnd,
        uint256 _maxSlippageFactor,
        address _destination
    ) internal {
        // Get price data
        (
            uint256[] memory _priceTokens,
            uint8[] memory _decimals
        ) = _preparePriceData(
                _startToken,
                _endToken,
                _priceFeedStart,
                _priceFeedEnd
            );

        // Safe transfer
        IERC20Upgradeable(_startToken).safeIncreaseAllowance(
            address(_uniRouter),
            _amountIn
        );

        // Perform swap
        _safeSwap(
            _uniRouter,
            _amountIn,
            _priceTokens,
            _maxSlippageFactor,
            _swapPath,
            _decimals,
            _destination,
            block.timestamp + 300
        );
    }

    /// @notice Internal function for safely swapping tokens (lower level than above func)
    /// @param _uniRouter Uniswap V2 router
    /// @param _amountIn The quantity of the origin token to swap
    /// @param _priceTokens Array of prices of tokenIn in USD, times 1e12, then tokenOut
    /// @param _slippageFactor The maximum slippage factor tolerated for this swap
    /// @param _path The path to take for the swap
    /// @param _decimals The number of decimals for _amountIn, _amountOut
    /// @param _to The destination to send the swapped token to
    /// @param _deadline How much time to allow for the transaction
    function _safeSwap(
        IAMMRouter02 _uniRouter,
        uint256 _amountIn,
        uint256[] memory _priceTokens,
        uint256 _slippageFactor,
        address[] memory _path,
        uint8[] memory _decimals,
        address _to,
        uint256 _deadline
    ) private {
        // Requirements
        require(_decimals.length == 2, "invalid dec");
        require(_path[0] != _path[_path.length - 1], "same token swap");
        require(_amountIn > 0, "amountIn zero");

        // Get min amount OUT
        uint256 _amountOut = _getAmountOut(
            _uniRouter,
            _amountIn,
            _path,
            _decimals,
            _priceTokens,
            _slippageFactor
        );

        // Safety
        require(_amountOut > 0, "amountOut zero");

        // Perform swap
        _uniRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amountIn,
            _amountOut,
            _path,
            _to,
            _deadline
        );
    }

    /// @notice Used to check if a swap will succeed or not before attempting
    /// @dev Call before .safeSwap()
    /// @param _uniRouter Uniswap V2 router
    /// @param _amountIn The quantity of the origin token to swap
    /// @param _startToken The origin token (to swap FROM)
    /// @param _endToken The destination token (to swap TO)
    /// @param _swapPath The array of tokens representing the swap path
    /// @param _priceFeedStart The Chainlink compatible price feed of the start token
    /// @param _priceFeedEnd The Chainlink compatible price feed of the end token
    /// @param _maxSlippageFactor The max slippage factor tolerated (9900 = 1%)
    /// @return isSwappable If true, can swap
    function checkIsSwappable(
        IAMMRouter02 _uniRouter,
        uint256 _amountIn,
        address _startToken,
        address _endToken,
        address[] memory _swapPath,
        AggregatorV3Interface _priceFeedStart,
        AggregatorV3Interface _priceFeedEnd,
        uint256 _maxSlippageFactor
    ) internal view returns (bool isSwappable) {
        // Preflight check
        require(_swapPath.length > 1, "invalid swappath");
        require(_startToken != address(0), "invalid token0");
        require(_endToken != address(0), "invalid token1");

        // First check amount IN
        if (_amountIn == 0) {
            return isSwappable;
        }

        // Check if tokens are same
        if (_swapPath[0] == _swapPath[_swapPath.length - 1]) {
            return isSwappable;
        }

        // Get decimals, and prices
        (
            uint256[] memory _priceTokens,
            uint8[] memory _decimals
        ) = _preparePriceData(
                _startToken,
                _endToken,
                _priceFeedStart,
                _priceFeedEnd
            );

        // Check output amount and ensure > 0
        uint256 _amountOut = _getAmountOut(
            _uniRouter,
            _amountIn,
            _swapPath,
            _decimals,
            _priceTokens,
            _maxSlippageFactor
        );
        if (_amountOut == 0) {
            return isSwappable;
        }

        // If all above checks passed, return true
        isSwappable = true;
    }

    /// @notice Prepares token price data by attempting to use price feed oracle
    /// @dev Will assign price of zero in the absence of a feed. Subsequent funcs will need to recognize this and use the AMM price or some other source
    /// @param _startToken The origin token (to swap FROM)
    /// @param _endToken The destination token (to swap TO)
    /// @param _priceFeedStart The Chainlink compatible price feed of the start token
    /// @param _priceFeedEnd The Chainlink compatible price feed of the end token
    /// @return priceTokens Array of prices for each token in swap (length: 2). Zero if price feed could not be found
    /// @return decimals Array of ERC20 decimals for each token in swap (length: 2)
    function _preparePriceData(
        address _startToken,
        address _endToken,
        AggregatorV3Interface _priceFeedStart,
        AggregatorV3Interface _priceFeedEnd
    )
        private
        view
        returns (uint256[] memory priceTokens, uint8[] memory decimals)
    {
        // Get exchange rates of each token
        priceTokens = new uint256[](2);

        // If price feed exists, use latest round data. If not, assign zero
        if (address(_priceFeedStart) == address(0)) {
            priceTokens[0] = 0;
        } else {
            priceTokens[0] = _priceFeedStart.getExchangeRate();
        }
        if (address(_priceFeedEnd) == address(0)) {
            priceTokens[1] = 0;
        } else {
            priceTokens[1] = _priceFeedEnd.getExchangeRate();
        }

        // Get decimals
        decimals = new uint8[](2);
        decimals[0] = ERC20Upgradeable(_startToken).decimals();
        decimals[1] = ERC20Upgradeable(_endToken).decimals();
    }

    /// @notice Calculate min amount out (account for slippage)
    /// @dev Tries to calculate based on price feed oracle if present, or via the AMM router
    /// @param _uniRouter Uniswap V2 router
    /// @param _amountIn The quantity of the origin token to swap
    /// @param _path The path to take for the swap
    /// @param _decimals The number of decimals for _amountIn, _amountOut
    /// @param _priceTokens Array of prices of tokenIn in USD, times 1e12, then tokenOut
    /// @param _slippageFactor The maximum slippage factor tolerated for this swap
    /// @return amountOut Minimum amount of output token to expect
    function _getAmountOut(
        IAMMRouter02 _uniRouter,
        uint256 _amountIn,
        address[] memory _path,
        uint8[] memory _decimals,
        uint256[] memory _priceTokens,
        uint256 _slippageFactor
    ) private view returns (uint256 amountOut) {
        if (_priceTokens[0] == 0 || _priceTokens[1] == 0) {
            // If no exchange rates provided, use on-chain functions provided by router (not ideal)
            amountOut = _getAmountOutWithoutExchangeRates(
                _uniRouter,
                _amountIn,
                _path,
                _slippageFactor,
                _decimals
            );
        } else {
            amountOut = _getAmountOutWithExchangeRates(
                _amountIn,
                _priceTokens[0],
                _priceTokens[1],
                _slippageFactor,
                _decimals
            );
        }
    }

    /// @notice Gets amounts out using provided exchange rates
    /// @param _amountIn The quantity of tokens as input to the swap
    /// @param _priceTokenIn Price of input token in USD, quoted in the number of decimals of the price feed
    /// @param _priceTokenOut Price of output token in USD, quoted in the number of decimals of the price feed
    /// @param _slippageFactor Slippage tolerance (9900 = 1%)
    /// @param _decimals Array (length 2) of decimal of price feed for each token
    /// @return amountOut The quantity of tokens expected to receive as output
    function _getAmountOutWithExchangeRates(
        uint256 _amountIn,
        uint256 _priceTokenIn,
        uint256 _priceTokenOut,
        uint256 _slippageFactor,
        uint8[] memory _decimals
    ) internal pure returns (uint256 amountOut) {
        amountOut =
            (_amountIn * _priceTokenIn * _slippageFactor * 10 ** _decimals[1]) /
            (10000 * _priceTokenOut * 10 ** _decimals[0]);
    }

    /// @notice Gets amounts out when exchange rates are not provided (uses router)
    /// @param _uniRouter The Uniswap V2 compatible router
    /// @param _amountIn The quantity of tokens as input to the swap
    /// @param _path Array of tokens representing the swap path from input to output token
    /// @param _slippageFactor Slippage tolerance (9900 = 1%)
    /// @param _decimals Array (length 2) of decimal of price feed for each token
    /// @return amountOut The quantity of tokens expected to receive as output
    function _getAmountOutWithoutExchangeRates(
        IAMMRouter02 _uniRouter,
        uint256 _amountIn,
        address[] memory _path,
        uint256 _slippageFactor,
        uint8[] memory _decimals
    ) internal view returns (uint256 amountOut) {
        uint256[] memory amounts = _uniRouter.getAmountsOut(_amountIn, _path);
        amountOut =
            (amounts[amounts.length - 1] *
                _slippageFactor *
                10 ** _decimals[1]) /
            (10000 * (10 ** _decimals[0]));
    }
}