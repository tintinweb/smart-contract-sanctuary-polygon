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
pragma solidity ^0.8.9;
interface IERC20 {  
    function decimals() external view returns(uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
interface IERC721 {  
    function balanceOf(address owner) external view returns (uint256 balance);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IGame {
   function getEndGame(uint256 _gameType,uint256 _poolBalance,uint256 _money,uint256[] memory selectArr,address[] memory selectAddr) external view returns(uint256 ,address[] memory ,uint256[] memory,uint256);
   function lootPrize(uint256) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISetting{
    struct BankerInfo{
         uint256 maxCount;
         uint256 money;
         uint256 lowerMoney;
         uint256 count;
         uint256 maxWinMoney;
         address[] erc20Address;
         uint256[] erc20;
         uint256 fee;
         address[] erc721Address;
         uint256[] erc721;
    }
    function room2Game(uint256) external view returns(address);
    function room2GameNo(uint256) external view returns(uint256);
    function game2Type(uint256) external view returns(uint256);
    function maxJoinNumber(uint256) external view returns(uint256);
    function time(uint256) external view returns(uint256);
    function joinMoney(uint256) external view returns(uint256);
    function delay(uint256) external view returns(uint256);
    function platformRate(uint256) external view returns(uint256);
    function platformor() external view returns(address);
    function getBankerInfo() external view returns(BankerInfo memory);
    function approveMoney(uint256) external view returns(uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISubRouter{
    function signIns(address) external view returns(bool);
    function getShareFee(address _invitee,uint256 _amount) external  returns(uint256,address[] memory,uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IERC20} from "./interface/IERC20.sol";
import {IERC721} from "./interface/IERC721.sol";
import {IGame} from "./interface/IGame.sol";
import {ISubRouter} from "./interface/ISubRouter.sol";
import {ISetting} from "./interface/ISetting.sol";
// import 'hardhat/console.sol';

contract MainRouter is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    //结构体
    struct GameInfo{
         uint256 roomType;//房间编号
         IGame   game;//游戏地址
         uint256 gameNo;//游戏编号
         uint256 gameId;//游戏id     
         uint256 money;//入场卷
         uint256 status;//游戏状态  1 进行中  2 已结束
         uint256 startTime;//开始时间
         uint256 endTime;//结束时间
         uint256 maxNumber; //最大参与人数
         address banker;//庄家地址
         bool isBanker;//是否是庄家的游戏      
         uint256 poolBalance;//奖池余额        
         Result  result;// 游戏结果
    } 
    //结构体
    struct Result{
         uint256 approveMoney;//授权额度
         uint256 gameType;//游戏类型
         uint256 platformRate;//平台费率
         uint256 gameResult;//游戏结果
         uint256 lootPrize;//抢开奖奖励     
         address[] winners;//赢家列表
         uint256[] winnerMoney;//赢钱列表
         address[] joinList;//参加列表
         uint256[] selectNumber;//选择数字 
         uint256 totalCost;//总花费
    }
    //用户参与信息
    struct UserGameInfo{
         GameInfo gameInfo;
         bool  isWinner;
         uint256 betAmount;
         bool isJoin;//是否加入
         uint256 selectNumber;//选择数字    
    }
    //其他合约
    ISubRouter public subRouter;
    ISetting public setting;
    IERC20 public  coin;
    bool public pause;
    //-------------游戏记录相关---------------
    //用户的分红奖励 (地址=>roomType=>gameId=>分红)
    // mapping(address=>mapping(uint256=>mapping(uint256=>uint256)))  public userActul;
    //用户参与记录
    mapping(address=>GameInfo[]) public userJoinRecord;
    //对应游戏记录
    mapping(uint256=>mapping(uint256=>GameInfo)) public gameInfos;
    //---------房间相关-----------------
    uint256 constant public rateStandards=100000;

    //总房间列表(当前的)
    mapping(uint256=>GameInfo) public currentGameList;
    //总共的平台费
    uint256 public totalPlatformFee;
    //-----------抢庄相关--------------------------
    //房间抢庄信息(房间=>抢庄地址，房间=>是否抢庄)
    mapping(uint256=>address) public game2BackerAddr; 
    mapping(uint256=>bool) public game2Backer; 
    //用户当庄次数
    mapping(address=>uint256) public user2Backer;
    //用户参与次数  
    mapping(address=>uint256) public userJoinCount;
    // 用户是否是庄家
    mapping(address=>bool) public userIsBacker;
    // ----------奖池相关------------
    //奖池
    mapping(uint256=>uint256) public pools;
    //用户抢庄质押池子
    mapping(address=>uint256)  public  bankerPools;
    //---------------初始化方法-----------------------
    modifier isPause{
        require(pause,"contract has paused");
        _;
    }
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(ISubRouter _subRouter,IERC20 _coin,ISetting _setting) initializer public {
        _init(_subRouter,_coin,_setting);
        __Ownable_init();
        __UUPSUpgradeable_init();
    }
    function _init(ISubRouter _subRouter,IERC20 _coin,ISetting _setting) internal{
          subRouter=_subRouter;
          coin=_coin;
          setting=_setting; 
          pause=true;
          //---------测试使用-------------
        //   game2BackerAddr[1]=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        //   game2Backer[1]=true;
        //   bankerPools[0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266]=12345*10**18;
          //设置16个房间开局
          for(uint256 i=0;i<16;i++){     
             startGame(i,1);         
          }
    }
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
    //----------主要方法-------------
    function startGame(uint256 _roomType,uint256 _gameId) internal {
        GameInfo memory gameInfo;
        ISetting  currentSetting=setting;     
        ISetting.BankerInfo memory currentBankerInfo=currentSetting.getBankerInfo();
        gameInfo.result.gameType=currentSetting.game2Type(_roomType);
        gameInfo.roomType=_roomType;//设置游戏类型
        gameInfo.game=IGame(currentSetting.room2Game(_roomType));//设置游戏种类(地址)
        gameInfo.gameNo=currentSetting.room2GameNo(_roomType);//设置类型id
        gameInfo.gameId=_gameId;//设置游戏id
        gameInfo.money=currentSetting.joinMoney(_roomType);//设置加入门槛
        gameInfo.result.approveMoney=currentSetting.approveMoney(_roomType);//设置授权额度
        gameInfo.status=1;//设置游戏状态
        gameInfo.maxNumber=currentSetting.maxJoinNumber(_roomType);//设置最大参与人数
        gameInfo.startTime=block.timestamp+currentSetting.delay(_roomType);//设置开始时间
        gameInfo.endTime=gameInfo.startTime+currentSetting.time(_roomType);//设置结束时间
        // gameInfo.poolBalance=pools[_roomType];//设置当前奖池
        gameInfo.result.platformRate=currentSetting.platformRate(_roomType);//设置平台费率
        gameInfo.result.lootPrize=gameInfo.game.lootPrize(gameInfo.gameNo);//设置抢开奖奖励
        //获取抢庄信息
        gameInfo.isBanker=game2Backer[_roomType];//是否是庄家游戏
        if(gameInfo.isBanker){
            address banker=game2BackerAddr[_roomType];
            uint256 balance=bankerPools[banker];
            //高于或低于金额下庄 或者当庄次数满足 就下庄
            if(balance>=currentBankerInfo.maxWinMoney||balance<=currentBankerInfo.lowerMoney || user2Backer[gameInfo.banker]>= currentBankerInfo.count){
                //重置条件
                delete(user2Backer[banker]);//重置用户当庄次数
                delete(game2Backer[_roomType]);   //房间没有庄家               
                gameInfo.isBanker=false;  //此局游戏没有庄家
                delete(userJoinCount[banker]);//用户加入次数
                //给庄家发送钱
                coin.transfer(banker, balance);
                delete(bankerPools[banker]);
                delete(userIsBacker[banker]);//修改用户下庄
                // console.log("enter delete");
            }else{
                //设置此局游戏的庄家地址
                gameInfo.banker=banker;
                //设置庄家余额
                // gameInfo.bankerBalance=balance;
                //用户上装次数+1
                user2Backer[gameInfo.banker]+=1;
            }
        }
        // console.log("start game %s  %s",_roomType,gameInfo.gameId);
        currentGameList[_roomType]=gameInfo;
    }
    //加入游戏
    function joinGame(uint256 _roomType,uint256 _gameId,uint256 _money,uint256 _number) external isPause{
        GameInfo memory info=currentGameList[_roomType];
        //判断条件 
        require(subRouter.signIns(msg.sender),"user not signIn");
        //判断当前房间是否已经开始(结束)
        require(info.startTime<=block.timestamp,"game not start");

        // require(info.endTime>=block.timestamp,"game is end");
        //加入金额错误 
         require(_money== info.money,"join money  error");
         //判断是否加入过游戏   
         for(uint256 i=0;i<info.result.joinList.length;i++){
            require(info.result.joinList[i]!=msg.sender,"user already joined");
         }
         //是否是当局游戏
         require(info.gameId==_gameId,"gameId error");
         //判断房间人数满没满
         require(info.maxNumber!=info.result.joinList.length,"room number already full");
         //用户余额转账
         coin.transferFrom(msg.sender, address(this),_money);
        //判断当前游戏是庄家的还是奖池的,是庄家的进庄家，不是进奖池
        if(info.isBanker){
            bankerPools[info.banker]+=_money;
            //修改当前房间奖池余额
            // currentGameList[_roomType].bankerBalance+=_money;
        }else{
            pools[_roomType]+=_money;
            //修改当前房间奖池余额
            // currentGameList[_roomType].poolBalance+=_money;
        }
         //加入房间
         currentGameList[_roomType].result.joinList.push(msg.sender);
         currentGameList[_roomType].result.selectNumber.push(_number);
         //用户游戏次数加1(当用户不是庄家时)
         if(!userIsBacker[msg.sender]){
            userJoinCount[msg.sender]+=1;
         }
         //判断结算过程(触发结算)    满10个人  时间到了 
         if(info.maxNumber-1==info.result.joinList.length || info.endTime<=block.timestamp){
             endGame(_roomType,_gameId);
         }
    }
    //结算游戏
    function endGame(uint256 _roomType,uint256 _gameId) public {
        //获取当前游戏完整信息
        GameInfo memory info=currentGameList[_roomType];
        //判断游戏是否结束 如果人数满员了 也可以过验证
        require(info.endTime<=block.timestamp || info.result.joinList.length==info.maxNumber,"game not end");
        //判断结果 并转钱 
        // 找到对应游戏并获取结果
        uint256 poolBalance= info.isBanker?bankerPools[info.banker]:pools[info.roomType];
        (info.result.gameResult,info.result.winners,info.result.winnerMoney,info.result.lootPrize)  =info.game.getEndGame(info.gameNo,poolBalance, info.money, info.result.selectNumber, info.result.joinList);
        //--------------测试打印代码--------------
        // for(uint256 i=0;i<info.result.winners.length;i++){
        //     console.log("<winner>:%s  <money>:%s",info.result.winners[i],info.result.winnerMoney[i]/10**18);
        // }
        uint256 cost=info.result.lootPrize; 
        //转账给抢开奖人
        coin.transfer(msg.sender, info.result.lootPrize);
        //分发奖励(未做上级人处理) todo
        for(uint256 i=0;i<info.result.winners.length;i++){
            uint256 realMoney= sharePrize(info,info.result.winners[i],info.result.winnerMoney[i]);
            cost+=info.result.winnerMoney[i];
            //修改为分红奖励后的数据 如果赢家是开奖人 把抢开奖的奖励也给赢家
            if(info.result.winners[i]==msg.sender){
                realMoney+=info.result.lootPrize;
            }
            info.result.winnerMoney[i]=realMoney;
        }
        uint256 currentPoolBalance;
        //记账处理
        if(info.isBanker){
            currentPoolBalance= bankerPools[info.banker];
            bankerPools[info.banker]=currentPoolBalance-cost;
            //把记录更新
            info.poolBalance=currentPoolBalance-cost;
        }else{
            currentPoolBalance= pools[_roomType];
            pools[_roomType]=currentPoolBalance-cost;
            //把记录更新
            info.poolBalance= currentPoolBalance-cost;
        } 

        //修改游戏状态
        info.status=2; 
        //修改总花费
        info.result.totalCost=cost;
        //记录用户游戏记录
        for(uint256 i=0;i<info.result.joinList.length;i++){
            userJoinRecord[info.result.joinList[i]].push(info);
        }
  
        //记录游戏信息
        gameInfos[_roomType][_gameId]=info;
        
        //重置游戏
        startGame(_roomType,_gameId+1);         
    }
    //分红处理 平台费处理
    function sharePrize( GameInfo memory _info,address _user,uint256 _amount) internal returns(uint256){
          //平台费
          uint256 platformFee=_info.result.platformRate*_amount/rateStandards;
          totalPlatformFee+=platformFee;
          //分红费
          (uint256 shareBonus,address[] memory sharerList,uint256[] memory shareMoneyList)= subRouter.getShareFee(_user,_amount);    
        //   console.log("<zong fen hong>:%s",shareBonus); 
          //记录用户的当局游戏的分红
        //   userActul[_user][_info.roomType][_info.gameId]=shareBonus;
          //给分红人转钱
          for(uint256 i=0;i<sharerList.length;i++){
              if(sharerList[i]!=address(0x00) && shareMoneyList[i] > 0){
                // console.log("<fen hong>:%s  <number>:%s",sharerList[i],shareMoneyList[i]/10**16);
                coin.transfer(sharerList[i], shareMoneyList[i]);
              }
          }
          //给赢家转钱
          uint256 realMoney=_amount-platformFee-shareBonus;
          coin.transfer(_user,realMoney);
          return realMoney;
    }
    //-------------抢庄方法-------------------------
    //抢庄
    function lootBanker(uint256 _roomType) external {
          ISetting.BankerInfo memory info=setting.getBankerInfo();
          //此房间有没有被抢庄
          require(!game2Backer[_roomType],"the room have been looted");
          //用户参与游戏次数够不够
          require(userJoinCount[msg.sender]>=info.maxCount,"user game count not enough");
          //查看用户额度是否足够
        //   console.log("<%s>,<%s>",coin.balanceOf(msg.sender),info.money);
          require(coin.balanceOf(msg.sender)>=info.money,"user balance not enough");
          //减少gas
          delete(userJoinCount[msg.sender]);//用户参加游戏次数
          delete(user2Backer[msg.sender]);//用户当庄次数
          //是否收取手续费
          bool  takeFlag;
          //手续费相关(免手续费)
          //20币判断
          for(uint256 i=0;i<info.erc20Address.length;i++){
             if(IERC20(info.erc20Address[i]).balanceOf(msg.sender)>=info.erc20[i]){
                takeFlag=true;
             }
          }   
          //721币判断
          for(uint256 i=0;i<info.erc721Address.length;i++){
             if(IERC721(info.erc721Address[i]).balanceOf(msg.sender)>=info.erc721[i]){
                takeFlag=true;
             }
          }
          //转移费用   
          coin.transferFrom(msg.sender, address(this), info.money);
          uint256 actualValut=info.money;
          //收取手续费
          if(!takeFlag){
              uint256 fee=info.money*info.fee/rateStandards;
              actualValut-=fee;
              //手续费给到平台费总额里
              totalPlatformFee+=fee;
          }
          userIsBacker[msg.sender]=true;//修改用户已抢庄
          game2BackerAddr[_roomType]=msg.sender;  //游戏庄家地址
          game2Backer[_roomType]=true; //当前游戏是否有庄家
          bankerPools[msg.sender]=actualValut; //庄家余额
    }
    //下庄
    // function loseBanker(uint256 _roomType) external {
    //      ISetting.BankerInfo memory info=setting.getBankerInfo();
    //      //判断是否是当前用户当庄
    //      require(game2BackerAddr[_roomType]==msg.sender,"user not permission");   
    //      //判断当庄次数
    //      require(user2Backer[msg.sender]>=info.count,"closeBanker count not enough");      
    //      delete(userJoinCount[msg.sender]);
    //      delete(user2Backer[msg.sender]);
    //      game2Backer[_roomType]=false; 
    //      //给庄家发送钱
    //      coin.transfer(msg.sender, bankerPools[msg.sender]);
    //      delete(bankerPools[msg.sender]);
    // }
    //-------------查看方法-------------------
    function getGameInfos(uint256 _roomType,uint256 _gameId) external view returns(GameInfo memory){
           return gameInfos[_roomType][_gameId];
    }
    // function getUserActul(address _user,uint256 _gameType,uint256 _gameId) external view returns(uint256) {
    //       return userActul[_user][_gameType][_gameId];
    // }
    function getCurrentGameList(uint256 _roomType) external view returns(GameInfo memory){
          return currentGameList[_roomType];
    }
    function getPools(uint256 _roomType) external view returns(uint256){
          return pools[_roomType];
    }
    function getBankerPools(address _banker) external view returns(uint256){
          return bankerPools[_banker];
    }
    function getUserJoinRecord(address _user) external view returns(GameInfo[] memory){
          return  userJoinRecord[_user];
    }
    function getRateStandards() external pure returns(uint256){
          return rateStandards;
    }
    function getBankerInfo(address _user) external view returns(ISetting.BankerInfo memory,uint256,uint256,uint256){
        return  (setting.getBankerInfo(),user2Backer[_user],userJoinCount[_user],rateStandards);
    }



    // ------------设置方法--------------------
    //设置游戏代币
    function setCoin(IERC20 _token) external onlyOwner{
         coin=_token;
    }
    //提取平台费和池子  _type=true 提取平台费  _type=false 提取奖池费用
    function withDrawPlatformFee(bool _type,uint256 _roomType,uint256 _amount) external onlyOwner{
       address  platformor=setting.platformor();
       require(platformor!=address(0x00),"invalid platformor address");   
       if(_type){
          totalPlatformFee-=_amount;
       }else{
          pools[_roomType]-=_amount;
       }
       coin.transfer(platformor, _amount);
    }
    //给奖池添加余额
    function addPoolBalance(uint256 _roomType,uint256 _amount) external onlyOwner{
        coin.transferFrom(msg.sender, address(this), _amount);
        pools[_roomType]+=_amount;
    }
    // 主合约暂停
    function setPause(bool _status) external onlyOwner{
        pause=_status;
    }
}