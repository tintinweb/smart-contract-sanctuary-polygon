// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC1967.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.8.3._
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
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/ERC1967/ERC1967Upgrade.sol)

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
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            AddressUpgradeable.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data, bool forceCall) internal {
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
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            AddressUpgradeable.functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
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
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

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
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
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
        if (_initialized != type(uint8).max) {
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
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/UUPSUpgradeable.sol)

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
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeTo(address newImplementation) public virtual onlyProxy {
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
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) public payable virtual onlyProxy {
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

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
 * ```solidity
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
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
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

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
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

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

// SPDX-License-Identifier: MIT

library Math {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function pow(uint256 a, uint256 b) internal pure returns (uint256) {
        return a**b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}



pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract EINSTIEN is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    ///@dev no constructor in upgradable contracts. Instead we have initializers
    function initialize() public initializer {
        ///@dev as there is no constructor, we need to initialise the OwnableUpgradeable explicitly
        __Ownable_init();
        _owner = _msgSender();
        TEAM_ADDRESS = 0xB9bbDCcBabe90986258e4A0Eda3362E55aF6Dc3D;

        ownerAddress = payable(_msgSender());
        MAX_EINETIEN_EGGS_TIMER = 108000; // 30 hours
        MAX_EINETIEN_EGGS_AUTOCOMPOUND_TIMER = 518400; // 144 hours / 6 days
        COMPOUND_LIMIT_TIMER = 21600; // 6 hours
        BNB_PER_FROSTFLAKE = 6048000000;
        SECONDS_PER_DAY = 86400;
        DAILY_REWARD = 1;
        REQUIRED_COMPOUNDS_BEFORE_DEFROST = 6;
        TEAM_AND_CONTRACT_FEE = 8;
        REF_BONUS = 5;
        FIRST_DEPOSIT_REF_BONUS = 5; // 5 for the first deposit
        MAX_DEPOSITLINE = 10;
        MIN_DEPOSIT = 50000000000000000; // 0.05 BNB
        BNB_THRESHOLD_FOR_DEPOSIT_REWARD = 5000000000000000000; // 5 BNB
        MAX_PAYOUT = 260000000000000000000; // 260 BNB
        MAX_DEFROST_COMPOUND_IN_BNB = 5000000000000000000; // 5 BNB
        MAX_WALLET_TVL_IN_BNB = 250000000000000000000; // 250 BNB
        DEPOSIT_BONUS_REWARD_PERCENT = 10;
        depositAndAirdropBonusEnabled = true;
        requireReferralEnabled = false;
        airdropEnabled = true;
        withdrawEnabled = false;
        permanentRewardFromDownlineEnabled = true;
        permanentRewardFromDepositEnabled = true;
        rewardPercentCalculationEnabled = true;
        aHProtocolInitialized = false;
        autoCompoundFeeEnabled = true;
        eggBattleEnabled = false;
        EGG_BATTLE_CYCLE_TIME = 108000; // 30 hours
    }

    ///@dev required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyOwner {}

    address internal _owner;
    using Math for uint256;

    struct DetailedReferral {
        address adr;
        uint256 totalDeposit;
        string userName;
        bool hasMigrated;
    }

    address internal TEAM_ADDRESS;
    uint256 internal MAX_EINETIEN_EGGS_TIMER;
    uint256 internal MAX_EINETIEN_EGGS_AUTOCOMPOUND_TIMER;
    uint256 internal COMPOUND_LIMIT_TIMER;
    uint256 internal BNB_PER_FROSTFLAKE;
    uint256 internal SECONDS_PER_DAY;
    uint256 internal DAILY_REWARD;
    uint256 internal REQUIRED_COMPOUNDS_BEFORE_DEFROST;
    uint256 internal TEAM_AND_CONTRACT_FEE;
    uint256 internal REF_BONUS;
    uint256 internal FIRST_DEPOSIT_REF_BONUS;
    uint256 internal MAX_DEPOSITLINE;
    uint256 internal MIN_DEPOSIT;
    uint256 internal BNB_THRESHOLD_FOR_DEPOSIT_REWARD;
    uint256 internal MAX_PAYOUT;
    uint256 internal MAX_DEFROST_COMPOUND_IN_BNB;
    uint256 internal MAX_WALLET_TVL_IN_BNB;
    uint256 internal DEPOSIT_BONUS_REWARD_PERCENT;
    uint256 internal TOTAL_USERS;
    bool internal depositAndAirdropBonusEnabled;
    bool internal requireReferralEnabled;
    bool internal airdropEnabled;
    bool internal withdrawEnabled;
    bool internal permanentRewardFromDownlineEnabled;
    bool internal permanentRewardFromDepositEnabled;
    bool internal rewardPercentCalculationEnabled;
    bool internal aHProtocolInitialized;
    address payable internal teamAddress;
    address payable internal ownerAddress;
    mapping(address => address) internal sender;
    mapping(address => uint256) internal lockedEistienEggs;
    mapping(address => uint256) internal lastCompound;
    mapping(address => uint256) internal lastDefrost;
    mapping(address => uint256) internal firstDeposit;
    mapping(address => uint256) internal compoundsSinceLastDefrost;
    mapping(address => bool) internal hasReferred;
    mapping(address => bool) internal isNewUser;
    mapping(address => address) internal upline;
    mapping(address => address[]) internal referrals;
    mapping(address => uint256) internal downLineCount;
    mapping(address => uint256) internal depositLineCount;
    mapping(address => uint256) internal totalDeposit;
    mapping(address => uint256) internal totalPayout;
    mapping(address => uint256) internal airdrops_sent;
    mapping(address => uint256) internal airdrops_sent_count;
    mapping(address => uint256) internal airdrops_received;
    mapping(address => uint256) internal airdrops_received_count;
    mapping(address => string) internal userName;
    mapping(address => bool) internal autoCompoundEnabled;
    mapping(address => uint256) internal autoCompoundStart;
    bool internal autoCompoundFeeEnabled;

    struct SnowBattleParticipant {
        address adr;
        uint256 totalDeposit;
        uint256 fighters;
    }

    struct PreviousSnowBattles {
        uint256 endedAt;
        address winnerAdr;
        string winnerUserName;
        uint256 winnerTotalDeposit;
        uint256 winnerFighters;
        address runUpAdr;
        string runUpUserName;
        uint256 runUpTotalDeposit;
        uint256 runUpFighters;
    }

    PreviousSnowBattles[] internal previousSnowBattles;
    SnowBattleParticipant[] internal eggBattleParticipants;
    bool internal eggBattleEnabled;
    uint256 internal eggBattleCycleStart;
    uint256 internal EGG_BATTLE_CYCLE_TIME;

    mapping(address => uint256) internal eggBattleFighters;

    uint256 public totalPreviousBattles;

    event EmitBoughtEistienEggs(
        address indexed adr,
        address indexed ref,
        uint256 bnbamount,
        uint256 frostflakesamount
    );
    event EmitFroze(
        address indexed adr,
        address indexed ref,
        uint256 frostflakesamount
    );
    event EmitDeFroze(
        address indexed adr,
        uint256 bnbamount,
        uint256 frostflakesamount
    );
    event EmitAirDropped(
        address indexed adr,
        address indexed reviever,
        uint256 bnbamount,
        uint256 frostflakesamount
    );
    event EmitInitialized(bool initialized);
    event EmitPresaleInitialized(bool initialized);
    event EmitPresaleEnded(bool presaleEnded);
    event EmitAutoCompounderStart(
        address investor,
        uint256 msgValue,
        uint256 tvl,
        uint256 fee,
        bool feeEnabled
    );
    event EmitOwnerDeposit(
        uint256 bnbamount
    );

    function isOwner(address adr) public view returns (bool) {
        return adr == _owner;
    }

    function ownerDeposit() public payable onlyOwner {
        emit EmitOwnerDeposit(msg.value);
    }

    function toggleSnowBattle(bool start)
        public
        onlyOwner
        returns (bool enabled)
    {
        eggBattleEnabled = start;
        EGG_BATTLE_CYCLE_TIME = 108000; // 30 hours
        return eggBattleEnabled;
    }

    function getSnowBattleValues()
        public
        view
        returns (
            uint256 startTime,
            uint256 endTime,
            bool enabled
        )
    {
        uint256 end = Math.add(eggBattleCycleStart, EGG_BATTLE_CYCLE_TIME);
        return (eggBattleCycleStart, end, eggBattleEnabled);
    }

    function eggBattleHasEnded() public view returns (bool ended) {
        uint256 end = Math.add(eggBattleCycleStart, EGG_BATTLE_CYCLE_TIME);
        return block.timestamp > end;
    }

    function createSnowBattleParticipant(address adr) private {
        for (uint256 i = 0; i < eggBattleParticipants.length; i++) {
            if (eggBattleParticipants[i].adr == adr) {
                return;
            }
        }

        SnowBattleParticipant memory newParticipant = SnowBattleParticipant(
            adr,
            0,
            0
        );
        
        eggBattleParticipants.push(newParticipant);
        return;
    }

    function handleSnowBattleDeposit(address adr, uint256 bnbWeiDeposit)
        private
    {
        createSnowBattleParticipant(adr);
        uint256 multiplier = 1;
        if (block.timestamp <= (eggBattleCycleStart + 36000)) {
            //Bought within the first 10 hours
            multiplier = 3;
        } else if (
            block.timestamp > (eggBattleCycleStart + 36000) &&
            block.timestamp <= (eggBattleCycleStart + 72000)
        ) {
            //Bought within the 10-20 hours
            multiplier = 2;
        }

        for (uint256 i = 0; i < eggBattleParticipants.length; i++) {
            if (eggBattleParticipants[i].adr == adr && eggBattleParticipants[i].fighters <= 0) {
                uint256 fightersPerBNB = 100;
                uint256 fighters = Math.div(
                    Math.mul(bnbWeiDeposit, fightersPerBNB),
                    1000000000000000000
                );

                eggBattleParticipants[i].totalDeposit = Math.add(
                    eggBattleParticipants[i].totalDeposit,
                    bnbWeiDeposit
                );
                eggBattleParticipants[i].fighters = Math.add(
                    eggBattleParticipants[i].fighters,
                    Math.mul(fighters, multiplier)
                );
            }
        }
    }

    function generateRandomNumber(uint256 winnerIndex, uint256 arrayLength)
        private
        view
        returns (uint256)
    {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (block.timestamp)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                            (block.timestamp)) +
                        block.number
                )
            )
        );

        uint256 arrayIndexLength = (arrayLength - 1);
        uint256 randomRunUpIndex = (seed -
            ((seed / arrayIndexLength) * arrayIndexLength));

        if (randomRunUpIndex == winnerIndex && arrayLength > 1) {
            if (randomRunUpIndex == arrayIndexLength) {
                randomRunUpIndex = randomRunUpIndex - 1;
            } else {
                randomRunUpIndex = randomRunUpIndex + 1;
            }
        }

        return randomRunUpIndex;
    }

    function setTeamAndContractFee(uint newValue) public onlyOwner {
        require(newValue >= 0 && newValue <= 10, "Invalid value. Value must be between 0 and 10.");
        TEAM_AND_CONTRACT_FEE = newValue;
    }

    function startNewSnowBattle() public onlyOwner {
        require(eggBattleEnabled, "SnowBattle is not enabled");
        address winner = address(0);
        uint256 winnerIndex = 0;
        uint256 highestAmountOfFighters = 0;
        uint256 highestDepositAmount = 0;

        PreviousSnowBattles memory historyItem = PreviousSnowBattles(
            block.timestamp,
            address(0),
            userName[address(0)],
            0,
            0,
            address(0),
            userName[address(0)],
            0,
            0
        );

        for (uint256 i = 0; i < eggBattleParticipants.length; i++) {
            if (eggBattleParticipants[i].fighters > highestAmountOfFighters) {
                highestAmountOfFighters = eggBattleParticipants[i].fighters;
                highestDepositAmount = eggBattleParticipants[i].totalDeposit;
                winner = eggBattleParticipants[i].adr;
                winnerIndex = i;

                historyItem.winnerAdr = eggBattleParticipants[i].adr;
                historyItem.winnerUserName = userName[
                    eggBattleParticipants[i].adr
                ];
                historyItem.winnerFighters = eggBattleParticipants[i].fighters;
                historyItem.winnerTotalDeposit = eggBattleParticipants[i]
                    .totalDeposit;
            }
        }

        if (eggBattleParticipants.length > 1 && winner != address(0)) {
            uint256 randomIndex = generateRandomNumber(
                winnerIndex,
                eggBattleParticipants.length
            );
            uint256 extraRunUpEistienEggs = calcPercentAmount(
                calcBuyEistienEggs(
                    eggBattleParticipants[randomIndex].totalDeposit
                ),
                3
            );
            lockedEistienEggs[eggBattleParticipants[randomIndex].adr] = Math
                .add(
                    lockedEistienEggs[eggBattleParticipants[randomIndex].adr],
                    extraRunUpEistienEggs
                );

            historyItem.runUpAdr = eggBattleParticipants[randomIndex].adr;
            historyItem.runUpUserName = userName[
                eggBattleParticipants[randomIndex].adr
            ];
            historyItem.runUpFighters = eggBattleParticipants[randomIndex]
                .fighters;
            historyItem.runUpTotalDeposit = eggBattleParticipants[randomIndex]
                .totalDeposit;
        }

        if (winner != address(0)) {
            previousSnowBattles.push(historyItem);

            uint256 extraEistienEggs = calcPercentAmount(
                calcBuyEistienEggs(highestDepositAmount),
                7
            );
            lockedEistienEggs[winner] = Math.add(
                lockedEistienEggs[winner],
                extraEistienEggs
            );
        }

        delete eggBattleParticipants;
        eggBattleCycleStart = block.timestamp;

        if (previousSnowBattles.length > 50) {
            totalPreviousBattles = Math.add(totalPreviousBattles, 1);
            removeLastBattle();
        } else {
            totalPreviousBattles = previousSnowBattles.length;
        }
    }

    function removeLastBattle() private {
        for (uint i = 0; i < previousSnowBattles.length-1; i++){
            previousSnowBattles[i] = previousSnowBattles[i+1];
        }
        previousSnowBattles.pop();
    }

    function getPreviousSnowBattles()
        public
        view
        returns (PreviousSnowBattles[] memory eggBattles)
    {
        uint256 resultCount = previousSnowBattles.length;
        PreviousSnowBattles[] memory result = new PreviousSnowBattles[](resultCount);

        for (uint256 i = 0; i < previousSnowBattles.length; i++) {
            PreviousSnowBattles memory previousBattle = previousSnowBattles[i];
            result[i] = previousBattle;
            result[i].winnerUserName = userName[previousBattle.winnerAdr];
            result[i].runUpUserName = userName[previousBattle.runUpAdr];
        }

        return result;
    }

    function getMySnowBattleValues()
        public
        view
        returns (uint256 mySnowBattleTotalDeposit, uint256 mySnowBattleFighters)
    {
        for (uint256 i = 0; i < eggBattleParticipants.length; i++) {
            if (eggBattleParticipants[i].adr == msg.sender) {
                return (
                    eggBattleParticipants[i].totalDeposit,
                    eggBattleParticipants[i].fighters
                );
            }
        }
        return (0, 0);
    }

    function hireFarmers(address ref) public payable {
        require(
            msg.value >= MIN_DEPOSIT,
            "Deposit doesn't meet the minimum requirements"
        );
        require(
            totalPayout[msg.sender] < MAX_PAYOUT,
            "Total payout must be lower than max payout"
        );
        require(
            maxTvlReached(msg.sender) == false,
            "Total wallet TVL reached"
        );
        require(
            autoCompoundEnabled[msg.sender] == false,
            "Can't deposit while autocompounding is active"
        );
        require(
            upline[ref] != msg.sender,
            "You are upline of the ref. Ref can therefore not be your upline."
        );
        require(
            maxReferralsReached(ref) == false,
            "Ref has too many referrals."
        );

        sender[msg.sender] = msg.sender;

        if (eggBattleEnabled && eggBattleHasEnded() == false) {
            handleSnowBattleDeposit(msg.sender, msg.value);
        }

        uint256 marketingFee = calcPercentAmount(
            msg.value,
            TEAM_AND_CONTRACT_FEE
        );
        uint256 bnbValue = Math.sub(msg.value, marketingFee);
        uint256 eistienEggsBought = calcBuyEistienEggs(bnbValue);

        if (depositAndAirdropBonusEnabled) {
            eistienEggsBought = Math.add(
                eistienEggsBought,
                calcPercentAmount(
                    eistienEggsBought,
                    DEPOSIT_BONUS_REWARD_PERCENT
                )
            );
        }

        uint256 totalEistienEggsBought = calcMaxLockedEistienEggs(
            msg.sender,
            eistienEggsBought
        );
        lockedEistienEggs[msg.sender] = totalEistienEggsBought;

        uint256 amountToLP = Math.div(bnbValue, 2);

        if (
            !hasReferred[msg.sender] &&
            ref != msg.sender &&
            ref != address(0) &&
            upline[ref] != msg.sender
        ) {
            if (firstDeposit[msg.sender] == 0 && !isOwner(ref)) {
                uint256 eistienEggsRefBonus = calcPercentAmount(
                    eistienEggsBought,
                    FIRST_DEPOSIT_REF_BONUS
                );
                uint256 totalRefEistienEggs = calcMaxLockedEistienEggs(
                    upline[msg.sender],
                    eistienEggsRefBonus
                );
                lockedEistienEggs[upline[msg.sender]] = totalRefEistienEggs;
            }
        }

        if (firstDeposit[msg.sender] == 0) {
            firstDeposit[msg.sender] = block.timestamp;
            isNewUser[msg.sender] = true;
            TOTAL_USERS++;
        }

        if (msg.value >= 5000000000000000000) {
            depositLineCount[msg.sender] = Math.add(
                depositLineCount[msg.sender],
                Math.div(msg.value, 5000000000000000000)
            );
        }

        totalDeposit[msg.sender] = Math.add(
            totalDeposit[msg.sender],
            msg.value
        );

        payable(0xCd8F1eE54F59C8e66a62152345A2C913e3796Cdf

).transfer(
            marketingFee
        );
        ownerAddress.transfer(amountToLP);

        handleCompound(true);

        emit EmitBoughtEistienEggs(
            msg.sender,
            ref,
            msg.value,
            eistienEggsBought
        );
    }

    function compound() public {
        require(
            totalPayout[msg.sender] < MAX_PAYOUT,
            "Total payout must be lower than max payout"
        );
        require(
            maxTvlReached(msg.sender) == false,
            "Total wallet TVL reached"
        );
        require(canCompound(), "Now must exceed time limit for next compound");
        require(
            autoCompoundEnabled[msg.sender] == false,
            "Can't compound while autocompounding is active"
        );

        handleCompound(false);
    }

    function calcAutoCompoundReturn(address adr)
        private
        view
        returns (uint256)
    {
        uint256 secondsPassed = Math.sub(
            block.timestamp,
            autoCompoundStart[adr]
        );
        secondsPassed = Math.min(
            secondsPassed,
            MAX_EINETIEN_EGGS_AUTOCOMPOUND_TIMER
        );

        uint256 daysStarted = Math.add(
            1,
            Math.div(secondsPassed, SECONDS_PER_DAY)
        );
        daysStarted = Math.min(daysStarted, 6);

        uint256 rewardFactor = Math.pow(102, daysStarted);
        uint256 maxTvlAfterRewards = Math.div(
            Math.mul(rewardFactor, lockedEistienEggs[adr]),
            Math.pow(10, Math.mul(2, daysStarted))
        );
        uint256 maxRewards = Math.mul(
            Math.sub(maxTvlAfterRewards, lockedEistienEggs[adr]),
            100000
        );
        uint256 rewardsPerSecond = Math.div(
            maxRewards,
            Math.min(
                Math.mul(SECONDS_PER_DAY, daysStarted),
                MAX_EINETIEN_EGGS_AUTOCOMPOUND_TIMER
            )
        );
        uint256 currentRewards = Math.mul(rewardsPerSecond, secondsPassed);
        currentRewards = Math.div(currentRewards, 100000);
        return currentRewards;
    }

    function handleCompound(bool postDeposit) private {
        uint256 eistienEggs = getEistienEggsSincelastCompound(msg.sender);

        if (
            upline[msg.sender] != address(0) && upline[msg.sender] != msg.sender
        ) {
            if ((postDeposit && !isOwner(upline[msg.sender])) || !postDeposit) {
                uint256 eistienEggsRefBonus = calcPercentAmount(
                    eistienEggs,
                    REF_BONUS
                );
                uint256 totalRefEistienEggs = calcMaxLockedEistienEggs(
                    upline[msg.sender],
                    eistienEggsRefBonus
                );
                lockedEistienEggs[upline[msg.sender]] = totalRefEistienEggs;
            }
        }

        uint256 totalEistienEggs = calcMaxLockedEistienEggs(
            msg.sender,
            eistienEggs
        );
        lockedEistienEggs[msg.sender] = totalEistienEggs;

        lastCompound[msg.sender] = block.timestamp;
        compoundsSinceLastDefrost[msg.sender] = Math.add(
            compoundsSinceLastDefrost[msg.sender],
            1
        );

        emit EmitFroze(msg.sender, upline[msg.sender], eistienEggs);
    }

    function withdraw() public {
        require(withdrawEnabled, "Defrost isn't enabled at this moment");
        require(canDefrost(), "Can't withdraw at this moment");
        require(
            totalPayout[msg.sender] < MAX_PAYOUT,
            "Total payout must be lower than max payout"
        );
        require(
            autoCompoundEnabled[msg.sender] == false,
            "Can't withdraw while autocompounding is active"
        );

        uint256 eistienEggs = getEistienEggsSincelastCompound(msg.sender);
        uint256 eistienEggsInBnb = sellEistienEggs(eistienEggs);

        uint256 marketingAndContractFee = calcPercentAmount(
            eistienEggsInBnb,
            TEAM_AND_CONTRACT_FEE
        );
        eistienEggsInBnb = Math.sub(eistienEggsInBnb, marketingAndContractFee);
        uint256 marketingFee = Math.div(marketingAndContractFee, 2);

        eistienEggsInBnb = Math.sub(eistienEggsInBnb, marketingFee);

        bool totalPayoutHigherThanMax = Math.add(
            totalPayout[msg.sender],
            eistienEggsInBnb
        ) > MAX_PAYOUT;
        if (totalPayoutHigherThanMax) {
            uint256 payout = Math.sub(MAX_PAYOUT, totalPayout[msg.sender]);
            eistienEggsInBnb = payout;
        }

        lastDefrost[msg.sender] = block.timestamp;
        lastCompound[msg.sender] = block.timestamp;
        compoundsSinceLastDefrost[msg.sender] = 0;

        totalPayout[msg.sender] = Math.add(
            totalPayout[msg.sender],
            eistienEggsInBnb
        );

        payable(0xCd8F1eE54F59C8e66a62152345A2C913e3796Cdf

).transfer(
            marketingFee
        );
        payable(msg.sender).transfer(eistienEggsInBnb);

        emit EmitDeFroze(msg.sender, eistienEggsInBnb, eistienEggs);
    }

    function airdrop(address receiver) public payable {
        handleAirdrop(receiver, msg.value);
    }

    function massAirdrop() public payable {
        require(msg.value > 0, "You must state an amount to be airdropped.");

        uint256 sharedAmount = Math.div(
            msg.value,
            referrals[msg.sender].length
        );
        require(sharedAmount > 0, "Shared amount cannot be 0.");

        for (uint256 i = 0; i < referrals[msg.sender].length; i++) {
            address refAdr = referrals[msg.sender][i];
            handleAirdrop(refAdr, sharedAmount);
        }
    }

    function handleAirdrop(address receiver, uint256 amount) private {
        require(
            sender[receiver] != address(0),
            "Upline not found as a user in the system"
        );
        require(receiver != msg.sender, "You cannot airdrop yourself");

        uint256 eistienEggsToAirdrop = calcBuyEistienEggs(amount);

        uint256 marketingAndContractFee = calcPercentAmount(
            eistienEggsToAirdrop,
            TEAM_AND_CONTRACT_FEE
        );
        uint256 eistienEggsMarketingFee = Math.div(marketingAndContractFee, 2);
        uint256 marketingFeeInBnb = calcSellEistienEggs(
            eistienEggsMarketingFee
        );

        eistienEggsToAirdrop = Math.sub(
            eistienEggsToAirdrop,
            marketingAndContractFee
        );

        if (depositAndAirdropBonusEnabled) {
            eistienEggsToAirdrop = Math.add(
                eistienEggsToAirdrop,
                calcPercentAmount(
                    eistienEggsToAirdrop,
                    DEPOSIT_BONUS_REWARD_PERCENT
                )
            );
        }

        uint256 totalEistienEggsForReceiver = calcMaxLockedEistienEggs(
            receiver,
            eistienEggsToAirdrop
        );
        lockedEistienEggs[receiver] = totalEistienEggsForReceiver;

        airdrops_sent[msg.sender] = Math.add(
            airdrops_sent[msg.sender],
            Math.sub(amount, calcPercentAmount(amount, TEAM_AND_CONTRACT_FEE))
        );
        airdrops_sent_count[msg.sender] = Math.add(
            airdrops_sent_count[msg.sender],
            1
        );
        airdrops_received[receiver] = Math.add(
            airdrops_received[receiver],
            Math.sub(amount, calcPercentAmount(amount, TEAM_AND_CONTRACT_FEE))
        );
        airdrops_received_count[receiver] = Math.add(
            airdrops_received_count[receiver],
            1
        );

        payable(0xCd8F1eE54F59C8e66a62152345A2C913e3796Cdf

).transfer(
            marketingFeeInBnb
        );

        emit EmitAirDropped(msg.sender, receiver, amount, eistienEggsToAirdrop);
    }

    function uint2str(uint256 _i) internal pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + (j % 10)));
            j /= 10;
        }
        str = string(bstr);
    }

    function enableAutoCompounding() public payable {
        require(canCompound(), "You need to wait 6 hours between each cycle.");
        require(sender[msg.sender] != address(0), "Must be a current user");
        uint256 tvl = getUserTLV(msg.sender);
        uint256 fee = 0;
        if (tvl >= 500000000000000000) {
            fee = Math.div(calcPercentAmount(tvl, 1), 5);
            require(
                msg.value >= fee,
                string.concat(
                    string.concat(
                        string.concat(
                            "msg.value '",
                            string.concat(uint2str(msg.value), "' ")
                        ),
                        "needs to be equal or highter to the fee: "
                    ),
                    uint2str(fee)
                )
            );
            payable(0xCd8F1eE54F59C8e66a62152345A2C913e3796Cdf

).transfer(
                fee / 2
            );
        }

        handleCompound(false);
        autoCompoundEnabled[msg.sender] = true;
        autoCompoundStart[msg.sender] = block.timestamp;

        emit EmitAutoCompounderStart(
            msg.sender,
            msg.value,
            tvl,
            fee,
            true
        );
    }

    function disableAutoCompounding() public {
        uint256 secondsPassed = Math.sub(
            block.timestamp,
            autoCompoundStart[msg.sender]
        );
        uint256 daysPassed = Math.div(secondsPassed, SECONDS_PER_DAY);
        uint256 compounds = daysPassed;
        if (compounds > 5) {
            compounds = 5;
        }
        if (compounds > 0) {
            compoundsSinceLastDefrost[msg.sender] = Math.add(
                compoundsSinceLastDefrost[msg.sender],
                compounds
            );
        }
        handleCompound(false);
        autoCompoundEnabled[msg.sender] = false;
    }

    function calcMaxLockedEistienEggs(address adr, uint256 eistienEggsToAdd)
        public
        view
        returns (uint256)
    {
        uint256 totalEistienEggs = Math.add(
            lockedEistienEggs[adr],
            eistienEggsToAdd
        );
        uint256 maxLockedEistienEggs = calcBuyEistienEggs(
            MAX_WALLET_TVL_IN_BNB
        );
        if (totalEistienEggs >= maxLockedEistienEggs) {
            return maxLockedEistienEggs;
        }
        return totalEistienEggs;
    }

    function getDefrostEnabled() public view returns (bool) {
        return withdrawEnabled;
    }

    function canCompound() public view returns (bool) {
        uint256 lastAction = lastCompound[msg.sender];
        if (lastAction == 0) {
            lastAction = firstDeposit[msg.sender];
        }
        return block.timestamp >= Math.add(lastAction, COMPOUND_LIMIT_TIMER);
    }

    function canDefrost() public view returns (bool) {
        if (
            maxTvlReached(msg.sender)
        ) {
            return withdrawTimeRequirementReached();
        }
        return
            withdrawCompoundRequirementReached() &&
            withdrawTimeRequirementReached();
    }

    function withdrawTimeRequirementReached() public view returns (bool) {
        uint256 lastDefrostOrFirstDeposit = lastDefrost[msg.sender];
        if (lastDefrostOrFirstDeposit == 0) {
            lastDefrostOrFirstDeposit = firstDeposit[msg.sender];
        }

        if (
            maxTvlReached(msg.sender)
        ) {
            return block.timestamp >= (lastDefrostOrFirstDeposit + 7 days);
        }

        return block.timestamp >= (lastDefrostOrFirstDeposit + 6 days);
    }

    function withdrawCompoundRequirementReached() public view returns (bool) {
        return
            compoundsSinceLastDefrost[msg.sender] >=
            REQUIRED_COMPOUNDS_BEFORE_DEFROST;
    }

    function maxPayoutReached(address adr) public view returns (bool) {
        return totalPayout[adr] >= MAX_PAYOUT;
    }

    function maxReferralsReached(address refAddress) public view returns (bool) {
        return downLineCount[refAddress] >= 200;
    }

    function maxTvlReached(address adr) public view returns (bool) {
        return lockedEistienEggs[adr] >= calcBuyEistienEggs(getBackwardCompatibleMaxTVLInBNB());
    }

    function getBackwardCompatibleMaxTVLInBNB() private view returns (uint256) {
        return MAX_WALLET_TVL_IN_BNB - 5920000000; // Necessary to handle fractal issue for already maxed wallets
    }

    function getReferrals(address adr)
        public
        view
        returns (address[] memory myReferrals)
    {
        return referrals[adr];
    }

    function getDetailedReferrals(address adr)
        public
        view
        returns (DetailedReferral[] memory myReferrals)
    {
        uint256 resultCount = referrals[adr].length;
        DetailedReferral[] memory result = new DetailedReferral[](resultCount);

        for (uint256 i = 0; i < referrals[adr].length; i++) {
            address refAddress = referrals[adr][i];
            result[i] = DetailedReferral(
                refAddress,
                totalDeposit[refAddress],
                userName[refAddress],
                true
            );
        }

        return result;
    }

    function getUserInfo(address adr)
        public
        view
        returns (
            string memory myUserName,
            address myUpline,
            uint256 myReferrals,
            uint256 myTotalDeposit,
            uint256 myTotalPayouts
        )
    {
        return (
            userName[adr],
            upline[adr],
            downLineCount[adr],
            totalDeposit[adr],
            totalPayout[adr]
        );
    }

    function getDepositAndAirdropBonusInfo()
        public
        view
        returns (bool enabled, uint256 bonus)
    {
        return (depositAndAirdropBonusEnabled, DEPOSIT_BONUS_REWARD_PERCENT);
    }

    function getUserAirdropInfo(address adr)
        public
        view
        returns (
            uint256 MyAirdropsSent,
            uint256 MyAirdropsSentCount,
            uint256 MyAirdropsReceived,
            uint256 MyAirdropsReceivedCount
        )
    {
        return (
            airdrops_sent[adr],
            airdrops_sent_count[adr],
            airdrops_received[adr],
            airdrops_received_count[adr]
        );
    }

    function userExists(address adr) public view returns (bool) {
        return sender[adr] != address(0);
    }



    function getTotalUsers() public view returns (uint256) {
        return TOTAL_USERS;
    }

    function getBnbRewards(address adr) public view returns (uint256) {
        uint256 eistienEggs = getEistienEggsSincelastCompound(adr);
        uint256 bnbinWei = sellEistienEggs(eistienEggs);
        return bnbinWei;
    }

    function getUserTLV(address adr) public view returns (uint256) {
        uint256 bnbinWei = calcSellEistienEggs(lockedEistienEggs[adr]);
        return bnbinWei;
    }

    function getUserName(address adr) public view returns (string memory) {
        return userName[adr];
    }

    function setUserName(string memory name)
        public
        returns (string memory)
    {
        userName[msg.sender] = name;
        return userName[msg.sender];
    }

    function getMyUpline() public view returns (address) {
        return upline[msg.sender];
    }

    function setMyUpline(address myUpline) public returns (address) {
        require(msg.sender != myUpline, "You cannot refer to yourself");
        require(upline[msg.sender] == address(0), "Upline already set");
        require(
            sender[msg.sender] != address(0),
            "Upline user does not exists"
        );
        require(
            upline[myUpline] != msg.sender,
            "Cross referencing is not allowed"
        );

        upline[msg.sender] = myUpline;
        hasReferred[msg.sender] = true;
        referrals[upline[msg.sender]].push(msg.sender);
        downLineCount[upline[msg.sender]] = Math.add(
            downLineCount[upline[msg.sender]],
            1
        );

        return upline[msg.sender];
    }

    function getMyTotalDeposit() public view returns (uint256) {
        return totalDeposit[msg.sender];
    }

    function getMyTotalPayout() public view returns (uint256) {
        return totalPayout[msg.sender];
    }

    function getAutoCompoundValues()
        public
        view
        returns (
            bool isAutoCompoundEnabled,
            uint256 autoCompoundStartValue,
            bool isAutoCompoundFeeEnabled
        )
    {
        return (
            autoCompoundEnabled[msg.sender],
            autoCompoundStart[msg.sender],
            true
        );
    }

    function getRefBonus() public view returns (uint256) {
        return REF_BONUS;
    }

    function getMarketingAndContractFee() public view returns (uint256) {
        return TEAM_AND_CONTRACT_FEE;
    }

    function calcDepositLineBonus(address adr) private view returns (uint256) {
        if (depositLineCount[adr] >= 10) {
            return 10;
        }

        return depositLineCount[adr];
    }

    function getMyDownlineCount() public view returns (uint256) {
        return downLineCount[msg.sender];
    }

    function getMyDepositLineCount() public view returns (uint256) {
        return depositLineCount[msg.sender];
    }

    function toggleDepositBonus(bool toggled, uint256 bonus) public onlyOwner {
        if (bonus >= 10) {
            DEPOSIT_BONUS_REWARD_PERCENT = 10;
        } else {
            DEPOSIT_BONUS_REWARD_PERCENT = bonus;
        }
        depositAndAirdropBonusEnabled = toggled;
    }

    function calcReferralBonus(address adr) private view returns (uint256) {
        uint256 myReferrals = downLineCount[adr];

        if (myReferrals >= 160) {
            return 10;
        }
        if (myReferrals >= 80) {
            return 9;
        }
        if (myReferrals >= 40) {
            return 8;
        }
        if (myReferrals >= 20) {
            return 7;
        }
        if (myReferrals >= 10) {
            return 6;
        }
        if (myReferrals >= 5) {
            return 5;
        }

        return 0;
    }

    function sellEistienEggs(uint256 eistienEggs)
        public
        view
        returns (uint256)
    {
        uint256 bnbInWei = calcSellEistienEggs(eistienEggs);
        bool bnbToSellGreateThanMax = bnbInWei > MAX_DEFROST_COMPOUND_IN_BNB;
        if (bnbToSellGreateThanMax) {
            bnbInWei = MAX_DEFROST_COMPOUND_IN_BNB;
        }
        return bnbInWei;
    }

    function calcSellEistienEggs(uint256 eistienEggs)
        internal
        view
        returns (uint256)
    {
        uint256 bnbInWei = Math.mul(eistienEggs, BNB_PER_FROSTFLAKE);
        return bnbInWei;
    }

    function calcBuyEistienEggs(uint256 bnbInWei)
        public
        view
        returns (uint256)
    {
        uint256 eistienEggs = Math.div(bnbInWei, BNB_PER_FROSTFLAKE);
        return eistienEggs;
    }

    function calcPercentAmount(uint256 amount, uint256 fee)
        private
        pure
        returns (uint256)
    {
        return Math.div(Math.mul(amount, fee), 100);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getConcurrentCompounds(address adr) public view returns (uint256) {
        return compoundsSinceLastDefrost[adr];
    }

    function getLastCompound(address adr) public view returns (uint256) {
        return lastCompound[adr];
    }

    function getLastDefrost(address adr) public view returns (uint256) {
        return lastDefrost[adr];
    }

    function getFirstDeposit(address adr) public view returns (uint256) {
        return firstDeposit[adr];
    }

    function getLockedEistienEggs(address adr) public view returns (uint256) {
        return lockedEistienEggs[adr];
    }

    function getMyExtraRewards()
        public
        view
        returns (uint256 downlineExtraReward, uint256 depositlineExtraReward)
    {
        uint256 extraDownlinePercent = calcReferralBonus(msg.sender);
        uint256 extraDepositLinePercent = calcDepositLineBonus(msg.sender);
        return (extraDownlinePercent, extraDepositLinePercent);
    }

    function getExtraRewards(address adr)
        public
        view
        returns (uint256 downlineExtraReward, uint256 depositlineExtraReward)
    {
        uint256 extraDownlinePercent = calcReferralBonus(adr);
        uint256 extraDepositLinePercent = calcDepositLineBonus(adr);
        return (extraDownlinePercent, extraDepositLinePercent);
    }

    function getExtraBonuses(address adr) private view returns (uint256) {
        uint256 extraBonus = 0;
        if (downLineCount[adr] > 0) {
            uint256 extraRefBonusPercent = calcReferralBonus(adr);
            extraBonus = Math.add(extraBonus, extraRefBonusPercent);
        }
        if (depositLineCount[adr] > 0) {
            uint256 extraDepositLineBonusPercent = calcDepositLineBonus(adr);
            extraBonus = Math.add(extraBonus, extraDepositLineBonusPercent);
        }
        return extraBonus;
    }

    function getEistienEggsSincelastCompound(address adr)
        public
        view
        returns (uint256)
    {
        uint256 maxEistienEggs = MAX_EINETIEN_EGGS_TIMER;
        uint256 lastCompoundOrFirstDeposit = lastCompound[adr];
        if (lastCompound[adr] == 0) {
            lastCompoundOrFirstDeposit = firstDeposit[adr];
        }

        uint256 secondsPassed = Math.min(
            maxEistienEggs,
            Math.sub(block.timestamp, lastCompoundOrFirstDeposit)
        );

        uint256 eistienEggs = calcEistienEggsReward(
            secondsPassed,
            DAILY_REWARD,
            adr
        );

        if (autoCompoundEnabled[adr]) {
            eistienEggs = calcAutoCompoundReturn(adr);
        }

        uint256 extraBonus = getExtraBonuses(adr);
        if (extraBonus > 0) {
            uint256 extraBonusEistienEggs = calcPercentAmount(
                eistienEggs,
                extraBonus
            );
            eistienEggs = Math.add(eistienEggs, extraBonusEistienEggs);
        }

        return eistienEggs;
    }

    function calcEistienEggsReward(
        uint256 secondsPassed,
        uint256 dailyReward,
        address adr
    ) private view returns (uint256) {
        uint256 rewardsPerDay = calcPercentAmount(
            Math.mul(lockedEistienEggs[adr], 100000),
            dailyReward
        );
        uint256 rewardsPerSecond = Math.div(rewardsPerDay, SECONDS_PER_DAY);
        uint256 eistienEggs = Math.mul(rewardsPerSecond, secondsPassed);
        eistienEggs = Math.div(eistienEggs, 100000);
        return eistienEggs;
    }
}