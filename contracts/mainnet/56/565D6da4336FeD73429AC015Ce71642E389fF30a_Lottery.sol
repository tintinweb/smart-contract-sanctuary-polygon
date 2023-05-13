// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
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
pragma solidity ^0.8.0;


/// @dev Timestamp of the first Saturday evening in seconds since the Unix Epoch. It's used to align
/// the allowed drawing windows with Saturday evenings.
uint constant FIRST_SATURDAY_EVENING = 244800;

/// @dev Width of the drawing window.
uint constant DRAWING_WINDOW_WIDTH = 4 hours;


library Drawing {
  /// @dev Floors the current timestamp to the last time a drawing window started. Note that the
  ///   drawing window may not have elapsed yet. The returned value is independent of whether or not
  ///   a draw has been triggered.
  function getCurrentDrawingWindow() public view returns (uint) {
    return FIRST_SATURDAY_EVENING + (block.timestamp - FIRST_SATURDAY_EVENING) / 7 days * 7 days;
  }

  /// @return True iff a drawing window is ongoing.
  function insideDrawingWindow() public view returns (bool) {
    return block.timestamp < getCurrentDrawingWindow() + DRAWING_WINDOW_WIDTH;
  }

  function _ceil(uint time, uint window) private pure returns (uint) {
    return (time + window - 1) / window * window;
  }

  /// @dev Ceils the current timestamp to the next time a drawing window starts. The returned value
  ///   is independent of whether or not a drawing window is ongoing or a draw has been triggered.
  function getNextDrawingWindow() public view returns (uint) {
    return FIRST_SATURDAY_EVENING + _ceil(block.timestamp - FIRST_SATURDAY_EVENING, 7 days);
  }

  /// @dev Takes a 256-bit random word provided by the ChainLink VRF and extracts 6 different random
  ///   numbers in the range [1, 90] from it. The implementation uses a modified version of the
  ///   Fisher-Yates shuffle algorithm.
  function getRandomNumbersWithoutRepetitions(uint256 randomness)
      public pure returns (uint8[6] memory numbers)
  {
    uint8[90] memory source;
    for (uint8 i = 1; i <= 90; i++) {
      source[i - 1] = i;
    }
    for (uint i = 0; i < 6; i++) {
      uint j = i + randomness % (90 - i);
      randomness /= 90;
      numbers[i] = source[j];
      source[j] = source[i];
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol';

import './Drawing.sol';
import './TicketIndex.sol';
import './UserTickets.sol';


/// @dev This is in USD cents, so it's $1.50
uint constant BASE_TICKET_PRICE_USD = 150;

/// @dev ChainLink USD price feed on Polygon (8 decimals)
address constant USD_PRICE_FEED = 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0;

/// @dev The ChainLink VRF will wait for this number of block confirmations before invoking our
///   callback with the randomness.
uint16 constant VRF_REQUEST_CONFIRMATIONS = 10;

/// @dev ChainLink VRF callback gas limit.
uint32 constant VRF_CALLBACK_GAS_LIMIT = 1000000;


contract Lottery is UUPSUpgradeable, OwnableUpgradeable, PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
  using AddressUpgradeable for address payable;
  using TicketIndex for mapping(uint256 => uint);
  using UserTickets for TicketData[];

  struct RoundData {
    /// @dev Price of a 6-number ticket in wei.
    uint256 baseTicketPrice;

    /// @dev Indexes tickets by played numbers. This data structure is used with the `TicketIndex`
    ///   library. See the note on that library for more information on how it works.
    mapping(uint256 => uint) ticketIndex;

    /// @dev Prizes for each winning category. `prizes[0]` is the prize for the 2-match category,
    ///   `prizes[1]` for the 3-match category, etc., and `prizes[4]` is the jackpot. Each entry is
    ///   the whole sum allocated for a category, so that each winner in that category will be able
    ///   to withdraw that sum divided by the number of winners in the category.
    uint256[5] prizes;

    /// @dev This stash accumulates 6% of the ticket sales and is used to fund the next round in
    ///   case one or more tickets match all 6 numbers. This way the jackpot is never zero.
    uint256 stash;

    /// @dev Total number of 6-combinations played in the round. Tickets with 6 numbers add 1
    ///   combination to this count, tickets with 7 numbers add 7, tickets with 8 add 28, and so on.
    uint totalCombinations;

    /// @dev Keeps track of the number of 6-combinations sold with each referral code. Partners can
    ///   then withdraw a corresponding share of the revenue.
    mapping(bytes32 => uint) combinationsByReferralCode;

    /// @dev Block number of the transaction that called the `draw` method.
    uint256 drawBlockNumber;

    /// @dev VRF request ID, returned by the VRF coordinator invocation. For security reasons, the
    ///   callback checks the received request ID against this value and reverts if they differ.
    uint256 vrfRequestId;

    /// @dev The 6 drawn numbers.
    uint8[6] numbers;

    /// @dev Block number of the transaction that closed the round. This transaction is triggered by
    ///   the ChainLink VRF
    uint256 closureBlockNumber;

    /// @dev How many winning 6-combinations in each category. `winners[0]` is the number of
    ///   2-matches, `winners[1]` is for 3-matches, etc. `totalCombinations` is the sum of these 5
    ///   numbers.
    /// @dev Note that each winning ticket of category i can withdraw a prize of
    ///   `prizes[i] / winners[i]`.
    uint[5] winners;
  }

  /// @notice ChainLink VRF coordinator.
  VRFCoordinatorV2Interface public vrfCoordinator;

  /// @dev Associates each user account with the list of tickets that user bought.
  /// @dev The `TicketData` objects in each array are ordered by ticket ID in ascending order. This
  ///   is a consequence of the fact that the ID is incremental.
  mapping(address => TicketData[]) private _ticketsByPlayer;

  /// @notice Indices are ticket IDs, values are player addresses. The first element is unused
  ///   because ticket ID 0 is considered invalid.
  address payable[] public playersByTicket;

  /// @dev Stores per-round data. The last element of this array represents the current round,
  ///   therefore the information it contains is incomplete most of the time. See the `RoundData`
  ///   struct for more details.
  RoundData[] private _rounds;

  /// @dev True indicates that the ticket sales are open. False indicates that a drawing is in
  ///   progress (the lottery is waiting for the ChainLink VRF to return the random numbers). This
  ///   is open most of the time.
  bool private _open;

  /// @dev Start time of the next allowed drawing window.
  uint private _nextDrawTime;

  /// @notice Associates referral codes to partner accounts.
  mapping(bytes32 => address) public partnersByReferralCode;

  /// @notice Associates partner accounts to the list of their respective referral codes.
  mapping(address => bytes32[]) public referralCodesByPartner;

  /// @dev Number of the last round for which the fees associated to each referral code have been
  ///   withdrawn. Note that round 0 is invalid and each entry of this map is initially 0, so the
  ///   initial state is that no fees have been withdrawn for any referral code.
  mapping(bytes32 => uint) private _lastWithdrawRoundByReferralCode;

  error ReferralCodeAlreadyExistsError(bytes32 referralCode);
  error SalesAreClosedError();
  error InvalidNumbersError(uint8[] numbers);
  error InvalidValueError(uint8[] numbers, uint256 expectedValue, uint256 actualValue);
  error InvalidReferralCodeError(bytes32 referralCode);
  error InvalidStateError();
  error OnlyCoordinatorCanFulfill(address got, address want);
  error VRFRequestError(uint256 requestId, uint256 expectedRequestId);
  error InvalidRoundNumberError(uint round);
  error NoPrizeError(uint ticketId);
  error PrizeAlreadyWithdrawnError(uint ticketId);

  event NewRound(uint indexed round, uint256 baseTicketPrice, uint256[5] prizes, uint256 stash);
  event ClaimReferralCode(bytes32 code, address partner);

  event Ticket(
      uint indexed round,
      address indexed player,
      uint indexed id,
      uint8[] numbers,
      bytes32 referralCode);
  event Ticket6(
      uint indexed round,
      address indexed player,
      uint indexed id,
      uint8[6] numbers,
      bytes32 referralCode);

  event VRFRequest(uint indexed round, uint256 subscriptionId, uint256 requestId);

  event Draw(
      uint indexed round,
      uint totalCombinations,
      uint8[6] numbers,
      uint[5] winners,
      uint256[5] prizes);

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function __Lottery_init_unchained(address _vrfCoordinator) private onlyInitializing {
    vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
    playersByTicket.push();  // skip slot 0 because ticket ID 0 is invalid
    _rounds.push();  // skip slot 0 because round 0 is invalid.
    _rounds.push();
    RoundData storage round = _rounds[1];
    round.baseTicketPrice = _getNewBaseTicketPrice();
    _open = true;
    _nextDrawTime = Drawing.getNextDrawingWindow();
    emit NewRound(1, round.baseTicketPrice, round.prizes, round.stash);
  }

  function initialize(address _vrfCoordinator) public initializer {
    __UUPSUpgradeable_init();
    __Ownable_init();
    __Pausable_init();
    __ReentrancyGuard_init();
    __Lottery_init_unchained(_vrfCoordinator);
  }

  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

  /// @dev Calculates the binomial coefficient (n choose 6).
  function _choose6(uint n) private pure returns (uint) {
    if (n < 6) {
      return 0;
    }
    return n * (n - 1) * (n - 2) * (n - 3) * (n - 4) * (n - 5) / 720;
  }

  /// @dev Calculates the binomial coefficient (n choose k).
  function _choose(uint n, uint k) private pure returns (uint) {
    if (k > n) {
      return 0;
    } else if (k == 0) {
      return 1;
    } else if (k * 2 > n) {
      return _choose(n, n - k);
    } else {
      return n * _choose(n - 1, k - 1) / k;
    }
  }

  /// @notice For emergency response.
  function pause() public onlyOwner {
    _pause();
  }

  /// @notice For emergency response.
  function unpause() public onlyOwner {
    _unpause();
  }

  /// @notice Associates the specified referral code with the provided address. Reverts if the
  ///   referral code is already associated to an account. After association, the code becomes
  ///   usable for buying tickets.
  function claimReferralCode(bytes32 code, address partner) public whenNotPaused {
    if (code == 0 || partnersByReferralCode[code] != address(0)) {
      revert ReferralCodeAlreadyExistsError(code);
    }
    partnersByReferralCode[code] = partner;
    referralCodesByPartner[partner].push(code);
    emit ClaimReferralCode(code, partner);
  }

  /// @notice Generates a new referral code and associates it to the provided account as per
  ///   `claimReferralCode`.
  function makeReferralCode(address partner) public whenNotPaused returns (bytes32) {
    bytes32 code = keccak256(abi.encodePacked('ExaLotto_Referral', block.timestamp, partner));
    claimReferralCode(code, partner);
    return code;
  }

  /// @dev Called at the beginning of every round to update the base ticket price for the round. The
  ///   base ticket price is the price of a 6-number ticket.
  function _getNewBaseTicketPrice() private view returns (uint256) {
    AggregatorV3Interface priceFeed = AggregatorV3Interface(USD_PRICE_FEED);
    (, int256 price, , , ) = priceFeed.latestRoundData();
    return BASE_TICKET_PRICE_USD * uint256(10 ** (16 + priceFeed.decimals())) / uint256(price);
  }

  /// @notice Returns the number of the current round.
  function getCurrentRound() public view returns (uint) {
    return _rounds.length - 1;
  }

  function _getCurrentRoundData() private view returns (RoundData storage) {
    return _rounds[_rounds.length - 1];
  }

  /// @notice Returns true if ticket sales are open, false if a drawing is in progress.
  function isOpen() public view returns (bool) {
    return _open;
  }

  /// @notice Accept funds from ICO and/or other sources.
  function fund() public payable whenNotPaused {
    uint currentRound = getCurrentRound();
    uint256 stash = msg.value * 60 / 248;
    _rounds[currentRound].prizes[4] += msg.value - stash;
    _rounds[currentRound].stash += stash;
  }

  /// @notice Returns the latest prizes for each winning category. The value returned at index 0 is
  ///   the prize for the 2-match category, the value at index 1 is for the 3-match category, etc.
  /// @notice These values are updated in real time as users buy tickets, so they can be queried at
  ///   every new block.
  function getPrizes() public view returns (uint256[5] memory prizes) {
    RoundData storage round = _getCurrentRoundData();
    uint256 value = round.baseTicketPrice * round.totalCombinations;
    value -= value / 10 * 2;
    prizes = round.prizes;
    prizes[0] += value * 188 / 1000;
    prizes[1] += value * 188 / 1000;
    prizes[2] += value * 188 / 1000;
    prizes[3] += value * 188 / 1000;
    prizes[4] += value * 188 / 1000;
  }

  /// @notice Returns the latest jackpot; that is, the highest prize for the 6-match category. This
  ///   value is updated in real time as users buy tickets, so it can be queried at every new block.
  function getJackpot() public view returns (uint256) {
    RoundData storage round = _getCurrentRoundData();
    uint256 value = round.baseTicketPrice * round.totalCombinations;
    value -= value / 10 * 2;
    return round.prizes[4] + value * 188 / 1000;
  }

  /// @notice Returns the amount stashed to fund the jackpot of the next round in case someone
  ///   matches all 6 numbers (this amount is accumulated from 6% of the value of every ticket
  ///   sold).
  function getStash() public view returns (uint256) {
    RoundData storage round = _getCurrentRoundData();
    uint256 value = round.baseTicketPrice * round.totalCombinations;
    value -= value / 10 * 2;
    return round.stash + value - value * 188 / 1000 * 5;
  }

  /// @notice Returns the owner fees collected so far in the current round.
  function getOwnerRevenue() public view returns (uint256) {
    RoundData storage round = _getCurrentRoundData();
    uint256 ownerFees = round.baseTicketPrice * round.totalCombinations / 10;
    uint256 referralFees = round.baseTicketPrice * round.combinationsByReferralCode[0] / 10;
    return ownerFees + referralFees;
  }

  /// @notice Returns the partner fees collected so far in the current round.
  function getPartnerRevenue(bytes32 referralCode) public view returns (uint256) {
    RoundData storage round = _getCurrentRoundData();
    return round.baseTicketPrice * round.combinationsByReferralCode[referralCode] / 10;
  }

  /// @notice Returns the total fees collected so far in the current round. This is equivalent to
  ///   `getOwnerRevenue()` plus `getPartnerRevenue()` for all existing referral codes.
  function getTotalRevenue() public view returns (uint256) {
    RoundData storage round = _getCurrentRoundData();
    uint256 totalValue = round.baseTicketPrice * round.totalCombinations;
    return totalValue / 10 * 2;
  }

  /// @notice Returns the sum of all the fees associated to the specified referral code that haven't
  ///   been withdrawn yet, for all rounds but the current one. This is the amount that can
  ///   currently be withdrawn with `withdrawPartnerRevenue(referralCode)`, and does not include the
  ///   fees for the current round (i.e. `getPartnerRevenue(referralCode)`).
  function getUnclaimedPartnerRevenue(bytes32 referralCode) public view returns (uint256 revenue) {
    revenue = 0;
    for (uint i = _lastWithdrawRoundByReferralCode[referralCode] + 1; i < _rounds.length - 1; i++) {
      RoundData storage round = _rounds[i];
      revenue += round.baseTicketPrice * round.combinationsByReferralCode[referralCode] / 10;
    }
  }

  /// @notice Allows the partner account associated to the specified referral code to withdraw its
  ///   revenue.
  function withdrawPartnerRevenue(bytes32 referralCode) public whenNotPaused nonReentrant {
    if (referralCode == 0) {
      // The "owner" part of the referral fees cannot be withdrawn here because it's managed
      // differently: it's transferred to the owner along with the owner fees as part of the drawing
      // process.
      revert InvalidReferralCodeError(referralCode);
    }
    address payable partnerAccount = payable(partnersByReferralCode[referralCode]);
    if (partnerAccount == address(0)) {
      revert InvalidReferralCodeError(referralCode);
    }
    uint256 revenue = getUnclaimedPartnerRevenue(referralCode);
    _lastWithdrawRoundByReferralCode[referralCode] = _rounds.length - 2;
    partnerAccount.sendValue(revenue);
  }

  /// @notice Returns the total number of tickets ever sold, through all rounds.
  function getTotalTicketCount() public view returns (uint) {
    // subtract 1 because ID 0 is invalid / slot 0 is unused
    return playersByTicket.length - 1;
  }

  function _validateTicket(uint8[] calldata numbers) private view {
    if (!_open) {
      revert SalesAreClosedError();
    }
    if (numbers.length < 6 || numbers.length > 90) {
      revert InvalidNumbersError(numbers);
    }
    for (uint i = 0; i < numbers.length; i++) {
      if (numbers[i] < 1 || numbers[i] > 90) {
        revert InvalidNumbersError(numbers);
      }
      for (uint j = i + 1; j < numbers.length; j++) {
        if (numbers[i] == numbers[j]) {
          revert InvalidNumbersError(numbers);
        }
      }
    }
  }

  /// @notice Returns the price of a 6-number ticket for the current round.
  function getBaseTicketPrice() public view returns (uint256) {
    return _getCurrentRoundData().baseTicketPrice;
  }

  /// @notice Returns the price in wei of a ticket with the specified numbers. It also performs some
  ///   validation on the numbers (e.g. it checks that there are no duplicates and every number is
  ///   in the range [1, 90]) and reverts if validation fails.
  function getTicketPrice(uint8[] calldata numbers) public view returns (uint256) {
    _validateTicket(numbers);
    return _getCurrentRoundData().baseTicketPrice * _choose6(numbers.length);
  }

  /// @notice Buys a lottery ticket. The ticket will be associated to `msg.sender`, which will be
  ///   the only account able to withdraw any prizes attributed to the ticket. `msg.value` MUST be
  ///   the value returned by `getTicketPrice()` with the same numbers.
  /// @param referralCode An optional referral code; if specified it must be valid, i.e. it must
  ///   have been claimed using `claimReferralCode` or `makeReferralCode`.
  /// @param numbers The numbers of the ticket. Must be at least 6 and at most 90, and all must be
  ///   in the range [1, 90].
  function buyTicket(bytes32 referralCode, uint8[] calldata numbers) public payable whenNotPaused {
    _validateTicket(numbers);
    uint combinations = _choose6(numbers.length);
    uint currentRound = getCurrentRound();
    uint256 price = _rounds[currentRound].baseTicketPrice * combinations;
    if (msg.value != price) {
      revert InvalidValueError(numbers, price, msg.value);
    }
    address partnerAccount = partnersByReferralCode[referralCode];
    if (referralCode != 0 && partnerAccount == address(0)) {
      revert InvalidReferralCodeError(referralCode);
    }
    uint ticketId = playersByTicket.length;
    uint256 hash = _rounds[currentRound].ticketIndex.indexTicket(numbers);
    _ticketsByPlayer[msg.sender].push(TicketData({
      hash: hash,
      blockNumber: uint128(block.number),
      id: uint64(ticketId),
      round: uint32(currentRound),
      cardinality: uint16(numbers.length),
      withdrawn: false
    }));
    playersByTicket.push(payable(msg.sender));
    _rounds[currentRound].totalCombinations += combinations;
    _rounds[currentRound].combinationsByReferralCode[referralCode] += combinations;
    emit Ticket(currentRound, msg.sender, ticketId, numbers, referralCode);
  }

  /// @notice Buys a lottery ticket with 6 numbers. This is exactly the same as calling `buyTicket`
  ///   with 6 numbers, but consumes a bit less gas.
  function buyTicket6(bytes32 referralCode, uint8[6] calldata numbers)
      public payable whenNotPaused
  {
    require(_open);
    uint currentRound = getCurrentRound();
    require(msg.value == _rounds[currentRound].baseTicketPrice);
    address partnerAccount = partnersByReferralCode[referralCode];
    require(referralCode == 0 || partnerAccount != address(0));
    for (uint i = 0; i < numbers.length; i++) {
      require(numbers[i] > 0 && numbers[i] <= 90);
      for (uint j = i + 1; j < numbers.length; j++) {
        require(numbers[i] != numbers[j]);
      }
    }
    uint ticketId = playersByTicket.length;
    uint256 hash = _rounds[currentRound].ticketIndex.indexTicket6(numbers);
    _ticketsByPlayer[msg.sender].push(TicketData({
      hash: hash,
      blockNumber: uint128(block.number),
      id: uint64(ticketId),
      round: uint32(currentRound),
      cardinality: uint16(numbers.length),
      withdrawn: false
    }));
    playersByTicket.push(payable(msg.sender));
    _rounds[currentRound].totalCombinations++;
    _rounds[currentRound].combinationsByReferralCode[referralCode]++;
    emit Ticket6(currentRound, msg.sender, ticketId, numbers, referralCode);
  }

  /// @notice Returns the IDs of all the ticket ever bought by a player.
  function getTicketIds(address player) public view returns (uint[] memory ids) {
    return _ticketsByPlayer[player].getTicketIds();
  }

  /// @notice Returns the IDs of the tickets a player bought at the specified round.
  function getTicketIdsForRound(address player, uint round)
      public view returns (uint[] memory ids)
  {
    if (round == 0 || round >= _rounds.length) {
      revert InvalidRoundNumberError(round);
    }
    return _ticketsByPlayer[player].getTicketIdsForRound(round);
  }

  /// @notice Returns information about the ticket with the specified ID.
  /// @return player The account who bought the ticket.
  /// @return round The number of the round when the ticket was bought.
  /// @return blockNumber The block number at which the ticket was bought.
  /// @return numbers The numbers of the ticket.
  function getTicket(uint ticketId) public view returns (
      address player, uint round, uint256 blockNumber, uint8[] memory numbers)
  {
    player = playersByTicket[ticketId];
    if (player == address(0)) {
      revert InvalidTicketIdError(ticketId);
    }
    TicketData storage ticket;
    (ticket, numbers) = _ticketsByPlayer[player].getTicketAndNumbers(ticketId);
    round = ticket.round;
    blockNumber = ticket.blockNumber;
    return (player, round, blockNumber, numbers);
  }

  /// @notice Returns information about a round. Reverts if `roundNumber` is 0 or refers to the
  ///   current round or higher. The information about the current round is incomplete and cannot be
  ///   obtained, but other methods can be used to query the available parts.
  /// @return baseTicketPrice The price in wei of a 6-number ticket for this round.
  /// @return prizes The prizes for each of the 5 winning category: `prizes[0]` is the prize
  ///   allocated for the 2-match category, `prizes[1]` for the 3-match category, and so on.
  ///   `prizes[4]` is the jackpot.
  /// @return stash A stash of money collected by withholding a percentage of the ticket sales.
  ///   This is used to fund the jackpot of the next round in case someone matches all 6 numbers. It
  ///   is simply carried over otherwise.
  /// @return totalCombinations The total number of played 6-combinations.
  /// @return drawBlockNumber The number of the block containing the `draw` method call
  ///   transaction.
  /// @return vrfRequestId The ChainLink VRF request ID.
  /// @return numbers The 6 drawn numbers.
  /// @return closureBlockNumber The number of the block containing the VRF callback transaction.
  /// @return winners The number of winning 6-combinations in each category. `winners[0]` is the
  ///   number of combinations with 2 matches, `winners[1]` is the number of combinations with 3
  ///   matches, and so on. One or more of these numbers may be zero. if `winners[4] > 0` it means
  ///   someone won the jackpot.
  function getRoundData(uint roundNumber) public view returns (
      uint256 baseTicketPrice,
      uint256[5] memory prizes,
      uint256 stash,
      uint totalCombinations,
      uint256 drawBlockNumber,
      uint256 vrfRequestId,
      uint8[6] memory numbers,
      uint256 closureBlockNumber,
      uint[5] memory winners)
  {
    if (roundNumber == 0 || roundNumber >= _rounds.length - 1) {
      revert InvalidRoundNumberError(roundNumber);
    }
    RoundData storage round = _rounds[roundNumber];
    baseTicketPrice = round.baseTicketPrice;
    prizes = round.prizes;
    stash = round.stash;
    totalCombinations = round.totalCombinations;
    drawBlockNumber = round.drawBlockNumber;
    vrfRequestId = round.vrfRequestId;
    numbers = round.numbers;
    closureBlockNumber = round.closureBlockNumber;
    winners = round.winners;
  }

  /// @notice Returns the number of referrals for the specified code and round. Note that this is
  ///   the number of 6-combinations sold with the code, not the number of tickets.
  function getReferrals(bytes32 referralCode, uint roundNumber) public view returns (uint) {
    if (referralCode != 0 && partnersByReferralCode[referralCode] == address(0)) {
      revert InvalidReferralCodeError(referralCode);
    }
    if (roundNumber == 0 || roundNumber >= _rounds.length - 1) {
      revert InvalidRoundNumberError(roundNumber);
    }
    return _rounds[roundNumber].combinationsByReferralCode[referralCode];
  }

  /// @notice Indicates whether a draw can be triggered at this time. True iff we are in a drawing
  ///   window and no drawing has been triggered in this window.
  function canDraw() public view returns (bool) {
    return _open && block.timestamp >= _nextDrawTime && Drawing.insideDrawingWindow();
  }

  /// @notice Returns the time of next draw, which may be in the past if we are currently in a
  ///   drawing window and the draw hasn't been triggered yet.
  function getNextDrawTime() public view returns (uint) {
    if (canDraw()) {
      return Drawing.getCurrentDrawingWindow();
    } else {
      return Drawing.getNextDrawingWindow();
    }
  }

  /// @notice Triggers the drawing process. Fails if called outside of a drawing window.
  function draw(uint64 vrfSubscriptionId, bytes32 vrfKeyHash) public onlyOwner {
    if (!canDraw()) {
      revert InvalidStateError();
    }
    _open = false;
    _nextDrawTime = Drawing.getNextDrawingWindow();
    RoundData storage round = _getCurrentRoundData();
    round.drawBlockNumber = block.number;
    round.vrfRequestId = vrfCoordinator.requestRandomWords(
        vrfKeyHash,
        vrfSubscriptionId,
        VRF_REQUEST_CONFIRMATIONS,
        VRF_CALLBACK_GAS_LIMIT,
        /*numWords=*/1);
    emit VRFRequest(getCurrentRound(), vrfSubscriptionId, round.vrfRequestId);
  }

  /// @notice Cancels a failed drawing, i.e. one for which the ChainLink VRF never responded. Can
  ///   only be invoked after the end of a drawing window. This method resets the state of the
  ///   current round as if no drawing had been attempted at all. As a result, should ChainLink ever
  ///   decide to finalize the pending request, the VRF callback will fail.
  function cancelFailedDrawing() public onlyOwner {
    if (!_open && !Drawing.insideDrawingWindow()) {
      _open = true;
    } else {
      revert InvalidStateError();
    }
  }

  /// @dev Initializes a new round, calculating the new ticket price and carrying over the prizes
  ///   and stash.
  function _createNewRound() private {
    RoundData storage previousRound = _getCurrentRoundData();
    _rounds.push();
    RoundData storage newRound = _getCurrentRoundData();
    newRound.baseTicketPrice = _getNewBaseTicketPrice();
    if (previousRound.winners[0] == 0) newRound.prizes[0] = previousRound.prizes[0];
    if (previousRound.winners[1] == 0) newRound.prizes[1] = previousRound.prizes[1];
    if (previousRound.winners[2] == 0) newRound.prizes[2] = previousRound.prizes[2];
    if (previousRound.winners[3] == 0) newRound.prizes[3] = previousRound.prizes[3];
    if (previousRound.winners[4] > 0) {
      newRound.prizes[4] = previousRound.stash;
    } else {
      newRound.prizes[4] = previousRound.prizes[4];
      newRound.stash = previousRound.stash;
    }
  }

  /// @notice ChainLink VRF callback.
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
      external whenNotPaused
  {
    if (msg.sender != address(vrfCoordinator)) {
      revert OnlyCoordinatorCanFulfill(msg.sender, address(vrfCoordinator));
    }
    if (_open) {
      revert InvalidStateError();
    }
    uint roundNumber = getCurrentRound();
    RoundData storage round = _getCurrentRoundData();
    if (requestId != round.vrfRequestId) {
      revert VRFRequestError(requestId, round.vrfRequestId);
    }
    round.closureBlockNumber = block.number;
    uint8[6] memory numbers = Drawing.getRandomNumbersWithoutRepetitions(randomWords[0]);
    round.prizes = getPrizes();
    round.stash = getStash();
    round.numbers = numbers;
    round.winners = round.ticketIndex.findWinners(numbers);
    uint256 ownerRevenue = getOwnerRevenue();
    _createNewRound();
    _open = true;
    payable(owner()).sendValue(ownerRevenue);
    emit Draw(roundNumber, round.totalCombinations, round.numbers, round.winners, round.prizes);
  }

  /// @dev Returns the prize assigned to a ticket, which may be zero, along with other information.
  function _getPrizeData(uint ticketId)
      private view returns (address payable player, TicketData storage ticket, uint256 prize)
  {
    if (ticketId >= playersByTicket.length) {
      revert InvalidTicketIdError(ticketId);
    }
    player = playersByTicket[ticketId];
    ticket = _ticketsByPlayer[player].getTicket(ticketId);
    if (ticket.round >= getCurrentRound()) {
      // The data for the current round is incomplete, so we can't calculate the prize for this
      // ticket.
      revert InvalidRoundNumberError(ticket.round);
    }
    RoundData storage round = _rounds[ticket.round];
    uint8 matches = 0;
    if (ticket.hash % TicketIndex.getPrime(round.numbers[0]) == 0) matches++;
    if (ticket.hash % TicketIndex.getPrime(round.numbers[1]) == 0) matches++;
    if (ticket.hash % TicketIndex.getPrime(round.numbers[2]) == 0) matches++;
    if (ticket.hash % TicketIndex.getPrime(round.numbers[3]) == 0) matches++;
    if (ticket.hash % TicketIndex.getPrime(round.numbers[4]) == 0) matches++;
    if (ticket.hash % TicketIndex.getPrime(round.numbers[5]) == 0) matches++;
    prize = 0;
    for (uint i = 2; i <= matches; i++) {
      uint weight = _choose(matches, i) * _choose(ticket.cardinality - matches, 6 - i);
      if (weight > 0) {
        prize += round.prizes[i - 2] * weight / round.winners[i - 2];
      }
    }
  }

  /// @notice Returns the prize won by a ticket, which may be zero, and a boolean indicating whether
  ///   it has been withdrawn. Reverts if the ticket ID is invalid or refers to a ticket played in
  ///   the current round.
  /// @return player The address the prize can be sent to.
  /// @return prize The prize won by the ticket.
  /// @return withdrawn Whether the prize has been withdrawn by the user.
  function getTicketPrize(uint ticketId)
      public view returns (address player, uint256 prize, bool withdrawn)
  {
    TicketData storage ticket;
    (player, ticket, prize) = _getPrizeData(ticketId);
    withdrawn = ticket.withdrawn;
  }

  /// @notice Allows a user to withdraw the prize won by the specified ticket. Reverts if the ticket
  ///   ID is invalid, the ticket has no prize, or the prize has already been withdrawn.
  function withdrawPrize(uint ticketId) public whenNotPaused nonReentrant {
    (address payable player, TicketData storage ticket, uint256 prize) = _getPrizeData(ticketId);
    if (prize == 0) {
      revert NoPrizeError(ticketId);
    }
    if (ticket.withdrawn) {
      revert PrizeAlreadyWithdrawnError(ticketId);
    }
    ticket.withdrawn = true;
    player.sendValue(prize);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/// @notice This library manages an index data structure that allows retrieving the tickets that
///   played a given combination of numbers efficiently in O(1).
/// @notice The data structure is stored as a `mapping(uint256 => uint)` whose keys are "hashes" of
///   ticket numbers and the values are the number of times those numbers have been played in a
///   ticket. The hashes are calculated by multiplying the prime numbers corresponding to the played
///   numbers: for instance, the map key corresponding to three numbers `n0`, `n1`, and `n2`, is
///   `getPrime(n0) * getPrime(n1) * getPrime(n2)`. The use of prime numbers allows indexing all
///   combinations of a ticket independently of the order of the numbers.
library TicketIndex {
  bytes32 constant _WORD1 = 0x01020305070b0d1113171d1f25292b2f353b3d4347494f53596165676b6d717f;
  bytes32 constant _WORD2 = 0x83898b95979da3a7adb3b5bfc1c5c7d3dfe3e5e9eff1fb000000000000000000;
  bytes32 constant _WORD3 = 0x01010107010d010f01150119011b0125013301370139013d014b0151015b015d;
  bytes32 constant _WORD4 = 0x01610167016f0175017b017f0185018d0191019901a301a501af01b101b701bb;
  bytes32 constant _WORD5 = 0x01c101c901cd01cf000000000000000000000000000000000000000000000000;

  error UnknownPrimeError(uint8 i);

  /// @dev Returns the i-th prime. `i` must be less than or equal to 90.
  function getPrime(uint8 i) internal pure returns (uint16) {
    if (i <= 31) return uint8(bytes1(_WORD1 << (i * 8)));
    if (i <= 54) return uint8(bytes1(_WORD2 << ((i - 32) * 8)));
    if (i <= 70) return uint16(bytes2(_WORD3 << ((i - 55) * 16)));
    if (i <= 86) return uint16(bytes2(_WORD4 << ((i - 71) * 16)));
    if (i <= 90) return uint16(bytes2(_WORD5 << ((i - 87) * 16)));
    revert UnknownPrimeError(i);
  }

  /// @dev Returns the binomial coefficient (n choose 2).
  function _choose2(uint n) private pure returns (uint) {
    if (n <= 1) {
      return 0;
    }
    return n * (n - 1) / 2;
  }

  /// @dev Returns the binomial coefficient (n choose 3).
  function _choose3(uint n) private pure returns (uint) {
    if (n <= 2) {
      return 0;
    }
    return n * (n - 1) * (n - 2) / 6;
  }

  /// @dev Returns the binomial coefficient (n choose 4).
  function _choose4(uint n) private pure returns (uint) {
    if (n <= 3) {
      return 0;
    }
    return n * (n - 1) * (n - 2) * (n - 3) / 24;
  }

  /// @notice Indexes a ticket in the `index`.
  /// @param index The data structure where the ticket is indexed.
  /// @param numbers The numbers in the ticket (must be at least 6).
  function indexTicket(
      mapping(uint256 => uint) storage index,
      uint8[] calldata numbers) public returns (uint256 hash)
  {
    uint combinations2 = _choose4(numbers.length - 2);
    uint combinations3 = _choose3(numbers.length - 3);
    uint combinations4 = _choose2(numbers.length - 4);
    uint combinations5 = numbers.length - 5;
    uint256[] memory p = new uint256[](numbers.length);
    hash = 1;
    for (uint i = 0; i < numbers.length; i++) {
      uint256 prime = getPrime(numbers[i]);
      p[i] = prime;
      hash *= prime;
    }
    for (uint i0 = 0; i0 < p.length; i0++) {
      for (uint i1 = i0 + 1; i1 < p.length; i1++) {
        index[p[i0] * p[i1]] += combinations2;
        for (uint i2 = i1 + 1; i2 < p.length; i2++) {
          index[p[i0] * p[i1] * p[i2]] += combinations3;
          for (uint i3 = i2 + 1; i3 < p.length; i3++) {
            index[p[i0] * p[i1] * p[i2] * p[i3]] += combinations4;
            for (uint i4 = i3 + 1; i4 < p.length; i4++) {
              index[p[i0] * p[i1] * p[i2] * p[i3] * p[i4]] += combinations5;
              for (uint i5 = i4 + 1; i5 < p.length; i5++) {
                index[p[i0] * p[i1] * p[i2] * p[i3] * p[i4] * p[i5]]++;
              }
            }
          }
        }
      }
    }
  }

  /// @notice Indexes a 6-number ticket in the `index`. This is exactly the same as calling
  ///   `indexTicket` with 6 numbers, only it's a bit more gas-efficient because it's optimized for
  ///   tickets with 6 numbers.
  /// @param index The data structure where the ticket is indexed.
  /// @param numbers The 6 numbers in the ticket.
  function indexTicket6(
      mapping(uint256 => uint) storage index,
      uint8[6] calldata numbers) public returns (uint256 hash)
  {
    uint256 p0 = getPrime(numbers[0]);
    uint256 p1 = getPrime(numbers[1]);
    uint256 p2 = getPrime(numbers[2]);
    uint256 p3 = getPrime(numbers[3]);
    uint256 p4 = getPrime(numbers[4]);
    uint256 p5 = getPrime(numbers[5]);
    hash = p0 * p1 * p2 * p3 * p4 * p5;
    index[p0 * p1]++;
    index[p0 * p2]++;
    index[p0 * p3]++;
    index[p0 * p4]++;
    index[p0 * p5]++;
    index[p1 * p2]++;
    index[p1 * p3]++;
    index[p1 * p4]++;
    index[p1 * p5]++;
    index[p2 * p3]++;
    index[p2 * p4]++;
    index[p2 * p5]++;
    index[p3 * p4]++;
    index[p3 * p5]++;
    index[p4 * p5]++;
    index[p0 * p1 * p2]++;
    index[p0 * p1 * p3]++;
    index[p0 * p1 * p4]++;
    index[p0 * p1 * p5]++;
    index[p0 * p2 * p3]++;
    index[p0 * p2 * p4]++;
    index[p0 * p2 * p5]++;
    index[p0 * p3 * p4]++;
    index[p0 * p3 * p5]++;
    index[p0 * p4 * p5]++;
    index[p1 * p2 * p3]++;
    index[p1 * p2 * p4]++;
    index[p1 * p2 * p5]++;
    index[p1 * p3 * p4]++;
    index[p1 * p3 * p5]++;
    index[p1 * p4 * p5]++;
    index[p2 * p3 * p4]++;
    index[p2 * p3 * p5]++;
    index[p2 * p4 * p5]++;
    index[p3 * p4 * p5]++;
    index[p0 * p1 * p2 * p3]++;
    index[p0 * p1 * p2 * p4]++;
    index[p0 * p1 * p2 * p5]++;
    index[p0 * p1 * p3 * p4]++;
    index[p0 * p1 * p3 * p5]++;
    index[p0 * p1 * p4 * p5]++;
    index[p0 * p2 * p3 * p4]++;
    index[p0 * p2 * p3 * p5]++;
    index[p0 * p2 * p4 * p5]++;
    index[p0 * p3 * p4 * p5]++;
    index[p1 * p2 * p3 * p4]++;
    index[p1 * p2 * p3 * p5]++;
    index[p1 * p2 * p4 * p5]++;
    index[p1 * p3 * p4 * p5]++;
    index[p2 * p3 * p4 * p5]++;
    index[p0 * p1 * p2 * p3 * p4]++;
    index[p0 * p1 * p2 * p3 * p5]++;
    index[p0 * p1 * p2 * p4 * p5]++;
    index[p0 * p1 * p3 * p4 * p5]++;
    index[p0 * p2 * p3 * p4 * p5]++;
    index[p1 * p2 * p3 * p4 * p5]++;
    index[p0 * p1 * p2 * p3 * p4 * p5]++;
  }

  /// @notice Calculates the number of winning 6-combinations in each winning category given the 6
  ///   drawn numbers. `winners[0]` is the number of combinations with 2 matches, `winners[1]` is
  ///   the number of combinations with 3 matches, etc. Some of the returned numbers may be 0. This
  ///   is a fundamental piece of the lottery because when a user withdraws the prize of a ticket it
  ///   must be calculated as the prize allocated for the category divided by the number of winners
  ///   in the category.
  /// @param index The index data structure where all tickets for the round have been indexed (see
  ///   the `indexTicket` and `indexTicket6` methods).
  /// @param numbers The 6 drawn numbers.
  function findWinners(
      mapping(uint256 => uint) storage index,
      uint8[6] memory numbers) public view returns (uint[5] memory winners)
  {
    winners = [
      uint(0),  // tickets matching exactly 2 numbers
      0,        // tickets matching exactly 3 numbers
      0,        // tickets matching exactly 4 numbers
      0,        // tickets matching exactly 5 numbers
      0         // tickets matching exactly 6 numbers
    ];
    uint256[6] memory p = [
      uint256(getPrime(numbers[0])),
      uint256(getPrime(numbers[1])),
      uint256(getPrime(numbers[2])),
      uint256(getPrime(numbers[3])),
      uint256(getPrime(numbers[4])),
      uint256(getPrime(numbers[5]))
    ];
    for (uint i0 = 0; i0 < 6; i0++) {
      for (uint i1 = i0 + 1; i1 < 6; i1++) {
        winners[0] += index[p[i0] * p[i1]];
        for (uint i2 = i1 + 1; i2 < 6; i2++) {
          winners[1] += index[p[i0] * p[i1] * p[i2]];
          for (uint i3 = i2 + 1; i3 < 6; i3++) {
            winners[2] += index[p[i0] * p[i1] * p[i2] * p[i3]];
            for (uint i4 = i3 + 1; i4 < 6; i4++) {
              winners[3] += index[p[i0] * p[i1] * p[i2] * p[i3] * p[i4]];
              for (uint i5 = i4 + 1; i5 < 6; i5++) {
                winners[4] += index[p[i0] * p[i1] * p[i2] * p[i3] * p[i4] * p[i5]];
              }
            }
          }
        }
      }
    }
    delete p;
    winners[3] -= winners[4] * 6;
    winners[2] -= winners[3] * 5 + winners[4] * 15;
    winners[1] -= winners[2] * 4 + winners[3] * 10 + winners[4] * 20;
    winners[0] -= winners[1] * 3 + winners[2] * 6 + winners[3] * 10 + winners[4] * 15;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './TicketIndex.sol';


struct TicketData {
  /// @dev This is not properly a "hash": it's calculated by multiplying the prime numbers
  ///   corresponding to the numbers of the ticket. See the note on `TicketIndex` for more details.
  ///   The resulting value allows retrieving all the numbers in the ticket and it's more efficient
  ///   than storing them separately.
  uint256 hash;

  /// @dev The block number of the transaction that bought the ticket.
  uint128 blockNumber;

  /// @dev The unique ID of the ticket.
  uint64 id;

  /// @dev The round number of the ticket.
  uint32 round;

  /// @dev The number of numbers in the ticket, e.g. 6 for a 6-number ticket. Note that `hash` is
  ///   the product of `cardinality` different primes.
  uint16 cardinality;

  /// @dev Whether or not the prize attributed to the ticket has been withdrawn by the user.
  bool withdrawn;
}


error InvalidTicketIdError(uint ticketId);


library UserTickets {
  function _lowerBound(TicketData[] storage tickets, uint round) private view returns (uint) {
    uint i = 0;
    uint j = tickets.length;
    while (j > i) {
      uint k = i + ((j - i) >> 1);
      if (round > tickets[k].round) {
        i = k + 1;
      } else {
        j = k;
      }
    }
    return i;
  }

  function _upperBound(TicketData[] storage tickets, uint round) private view returns (uint) {
    uint i = 0;
    uint j = tickets.length;
    while (j > i) {
      uint k = i + ((j - i) >> 1);
      if (round < tickets[k].round) {
        j = k;
      } else {
        i = k + 1;
      }
    }
    return j;
  }

  function getTicketIds(TicketData[] storage tickets) public view returns (uint[] memory ids) {
    ids = new uint[](tickets.length);
    for (uint i = 0; i < tickets.length; i++) {
      ids[i] = tickets[i].id;
    }
  }

  function getTicketIdsForRound(TicketData[] storage tickets, uint round)
      public view returns (uint[] memory ids)
  {
    uint min = _lowerBound(tickets, round);
    uint max = _upperBound(tickets, round);
    if (max < min) {
      max = min;
    }
    ids = new uint[](max - min);
    for (uint i = min; i < max; i++) {
      ids[i - min] = tickets[i].id;
    }
  }

  function getTicket(TicketData[] storage tickets, uint ticketId)
      public view returns (TicketData storage)
  {
    uint i = 0;
    uint j = tickets.length;
    while (j > i) {
      uint k = i + ((j - i) >> 1);
      if (ticketId < tickets[k].id) {
        j = k;
      } else if (ticketId > tickets[k].id) {
        i = k + 1;
      } else {
        return tickets[k];
      }
    }
    revert InvalidTicketIdError(ticketId);
  }

  function _getTicketNumbers(TicketData storage ticket)
      private view returns (uint8[] memory numbers)
  {
    numbers = new uint8[](ticket.cardinality);
    uint i = 0;
    for (uint8 j = 1; j <= 90; j++) {
      if (ticket.hash % TicketIndex.getPrime(j) == 0) {
        numbers[i++] = j;
      }
    }
  }

  function getTicketAndNumbers(
      TicketData[] storage tickets, uint ticketId)
      public view returns (TicketData storage, uint8[] memory numbers)
  {
    TicketData storage ticket = getTicket(tickets, ticketId);
    return (ticket, _getTicketNumbers(ticket));
  }
}