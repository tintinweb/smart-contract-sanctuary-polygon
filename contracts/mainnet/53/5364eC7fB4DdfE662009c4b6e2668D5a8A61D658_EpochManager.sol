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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165CheckerUpgradeable {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165Upgradeable).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165Upgradeable.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
     * @dev Returns the number of values in the set. O(1).
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/IEpochManager.sol";
import "./interfaces/IVotingManager.sol";
import "./interfaces/IRewardManager.sol";
import "./interfaces/IIdeaManager.sol";
import "./interfaces/IRegistry.sol";
import "./utils/AdminableUpgradeable.sol";

contract EpochManager is
    AdminableUpgradeable,
    IEpochManager,
    PausableUpgradeable,
    ERC165Upgradeable,
    UUPSUpgradeable
{
    using ERC165CheckerUpgradeable for address;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    bytes4 public constant IID_IEPOCHMANAGER = type(IEpochManager).interfaceId;

    address public registry;
    address public rewardManager;
    address public ideaManager;
    address public votingManager;

    uint256 public minEpochLength;
    uint256 public maxEpochLength;
    uint256 public minDurationFromNow;
    uint256 public maxNumOfIdeasPerEpoch;

    Epoch private _thisEpoch;

    Epoch[] private _epochs; // epochId -> epoch

    CountersUpgradeable.Counter private _epochCounter; // epoch counter
    EnumerableSetUpgradeable.UintSet private _ideaSet; // a set of active ideas in this epoch

    mapping(uint256 => IdeaIdPool) private _ideaIdPools; // epochId -> IdeaPool

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _registry) external initializer {
        require(
            _registry != address(0) &&
                _registry.supportsInterface(type(IRegistry).interfaceId),
            "EpochM: invalid address"
        );
        __Adminable_init();
        __Pausable_init();
        __ERC165_init();
        __UUPSUpgradeable_init();

        registry = _registry;
        minEpochLength = 3 * 24 * 3600; // 3 days
        maxEpochLength = 30 * 24 * 3600; // 30 days
        minDurationFromNow = 300; // 5 minutes
        maxNumOfIdeasPerEpoch = 100; // At most 100 ideas per epoch

        Epoch memory zeroEpoch;
        _epochs.push(zeroEpoch); // Skipping epoch 0
    }

    function startNewEpoch(uint256[] calldata _ideaIds, uint256 _duration)
        external
        override
        onlyAdmin
        whenNotPaused
    {
        uint256 nIdeas = _ideaIds.length;
        require(
            nIdeas > 0 && nIdeas <= maxNumOfIdeasPerEpoch,
            "EpochM: invalid ideas"
        );
        require(
            _duration >= minEpochLength && _duration <= maxEpochLength,
            "EpochM: invalid duration"
        );
        require(isThisEpochEnded(), "EpochM: last epoch has not ended");
        require(_validateIdeaIds(_ideaIds), "EpochM: invalid ideas");

        if (_thisEpoch.epochId != 0) {
            _emptyIdeaSet(_thisEpoch.epochId);
        }

        _epochIdIncrement();

        _addToIdeaSet(_ideaIds);

        require(_ideaSet.length() == nIdeas, "EpochM: duplicated ideaIds");

        uint256 _epochId = getCurEpochId();

        _addIdeas(_epochId, _ideaIds);

        _thisEpoch = Epoch({
            startingTime: block.timestamp,
            endingTime: block.timestamp + _duration,
            epochId: _epochId
        });

        _onEpochStarted();

        emit EpochStarted(_epochId, nIdeas, _duration);
    }

    function updateEpoch(uint256[] calldata _ideaIds, uint256 _durationFromNow)
        external
        override
        onlyAdmin
    {
        uint256 nIdeas = _ideaIds.length;
        require(
            nIdeas > 0 && nIdeas <= maxNumOfIdeasPerEpoch,
            "EpochM: invalid ideas"
        );
        require(
            _durationFromNow >= minDurationFromNow,
            "EpochM: duration is less than minimum"
        );
        require(!isThisEpochEnded(), "EpochM: epoch already ended");
        require(_validateIdeaIds(_ideaIds), "EpochM: invalid ideas");

        uint256 _epochId = getCurEpochId();

        assert(_thisEpoch.epochId == _epochId); // note: this should never fail

        _emptyIdeaSet(_epochId);
        _addToIdeaSet(_ideaIds);

        require(
            _ideaSet.length() == _ideaIds.length,
            "EpochM: duplicated ideaIds"
        );

        delete _ideaIdPools[_epochId];
        _addIdeas(_epochId, _ideaIds);

        _thisEpoch.endingTime = block.timestamp + _durationFromNow;

        _epochs[_epochs.length - 1] = _thisEpoch;

        emit EpochUpdated(_epochId, nIdeas, _durationFromNow);
    }

    function setMinEpochLength(uint256 _minEpochLength)
        external
        override
        onlyAdmin
    {
        require(_minEpochLength > 0, "EpochM: invalid parameter");
        uint256 oldMinEpochLength = minEpochLength;
        minEpochLength = _minEpochLength;

        emit MinEpochLengthSet(oldMinEpochLength, minEpochLength);
    }

    function setMaxEpochLength(uint256 _maxEpochLength)
        external
        override
        onlyAdmin
    {
        require(_maxEpochLength > 0, "EpochM: invalid parameter");
        uint256 oldMaxEpochLength = maxEpochLength;
        maxEpochLength = _maxEpochLength;

        emit MaxEpochLengthSet(oldMaxEpochLength, maxEpochLength);
    }

    function setMaxNumOfIdeasPerEpoch(uint256 _maxNumOfIdeasPerEpoch)
        external
        override
        onlyAdmin
    {
        require(_maxNumOfIdeasPerEpoch > 0, "EpochM: invalid parameter");
        uint256 oldMaxNumOfIdeasPerEpoch = maxNumOfIdeasPerEpoch;
        maxNumOfIdeasPerEpoch = _maxNumOfIdeasPerEpoch;

        emit MaxNumOfIdeasPerEpochSet(
            oldMaxNumOfIdeasPerEpoch,
            maxNumOfIdeasPerEpoch
        );
    }

    function setMinDurationFromNow(uint256 _minDurationFromNow)
        external
        override
        onlyAdmin
    {
        require(_minDurationFromNow > 0, "EpochM: invalid parameter");
        uint256 oldMinDurationFromNow = minDurationFromNow;
        minDurationFromNow = _minDurationFromNow;

        emit MinDurationFromNowSet(oldMinDurationFromNow, minDurationFromNow);
    }

    function setContracts() external override onlyAdmin {
        require(registry != address(0), "EpochM: invalid Registry");
        ideaManager = IRegistry(registry).ideaManager();
        votingManager = IRegistry(registry).votingManager();
        rewardManager = IRegistry(registry).rewardManager();
        require(ideaManager != address(0), "EpochM: invalid IdeaManager");
        require(votingManager != address(0), "EpochM: invalid VotingManager");
        require(rewardManager != address(0), "EpochM: invalid RewardManager");

        emit ContractsSet(ideaManager, votingManager, rewardManager);
    }

    function pause() external override onlyAdmin {
        require(!isThisEpochEnded(), "EpochM: epoch already ended");
        _thisEpoch.endingTime = block.timestamp + 30 * 24 * 3600;
        _epochs.pop();
        _epochs.push(_thisEpoch);
        _pause();
    }

    function unpause(uint256 _duration) external override onlyAdmin {
        require(_duration > 0, "EpochM: invalid duration");
        _thisEpoch.endingTime = block.timestamp + _duration;
        _epochs.pop();
        _epochs.push(_thisEpoch);
        _unpause();
    }

    function paused()
        public
        view
        override(IEpochManager, PausableUpgradeable)
        returns (bool)
    {
        return PausableUpgradeable.paused();
    }

    function getThisEpoch() external view override returns (Epoch memory) {
        return _thisEpoch;
    }

    function epoch(uint256 _epochId)
        external
        view
        override
        returns (Epoch memory)
    {
        if (_epochId < _epochs.length) {
            return _epochs[_epochId];
        } else {
            return Epoch({startingTime: 0, endingTime: 0, epochId: _epochId});
        }
    }

    function getIdeaIds(uint256 _epochId)
        external
        view
        override
        returns (uint256[] memory)
    {
        return _ideaIdPools[_epochId].ideaIds;
    }

    function isIdeaActive(uint256 _ideaId)
        external
        view
        override
        returns (bool)
    {
        if (_ideaId == 0) return false;
        if (_ideaId == 1) return true;
        return _ideaSet.contains(_ideaId);
    }

    function isThisEpochEnded() public view override returns (bool) {
        return _thisEpoch.endingTime < block.timestamp;
    }

    function getNumOfIdeas(uint256 _epochId)
        external
        view
        override
        returns (uint256)
    {
        return _ideaIdPools[_epochId].ideaIds.length;
    }

    function getCurEpochId() public view override returns (uint256) {
        return _epochCounter.current();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IERC165Upgradeable, ERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IEpochManager).interfaceId ||
            ERC165Upgradeable.supportsInterface(interfaceId);
    }

    function _validateIdeaIds(uint256[] memory _ideaIds)
        private
        view
        returns (bool)
    {
        uint256 nIdeas = _ideaIds.length;
        for (uint256 i = 0; i < nIdeas; i++) {
            if (!_exists(_ideaIds[i])) {
                return false;
            } else if (_ideaIds[i] == 1) {
                return false;
            }
        }
        return true;
    }

    function _exists(uint256 _ideaId) private view returns (bool) {
        return IIdeaManager(ideaManager).exists(_ideaId);
    }

    function _emptyIdeaSet(uint256 _epochId) private {
        uint256[] memory _ideaIds = _ideaIdPools[_epochId].ideaIds;
        uint256 nIdeas = _ideaIds.length;

        for (uint256 i = 0; i < nIdeas; i++) {
            _ideaSet.remove(_ideaIds[i]);
        }

        assert(_ideaSet.length() == 0);
    }

    function _addToIdeaSet(uint256[] memory _ideaIds) private {
        uint256 nIdeas = _ideaIds.length;
        for (uint256 i = 0; i < nIdeas; i++) {
            _ideaSet.add(_ideaIds[i]);
        }
    }

    function _addIdeas(uint256 _epochId, uint256[] memory _ideaIds) private {
        uint256 nIdeas = _ideaIds.length;
        for (uint256 i = 0; i < nIdeas; i++) {
            _ideaIdPools[_epochId].ideaIds.push(_ideaIds[i]);
        }
    }

    function _onEpochStarted() private {
        IRewardManager(rewardManager).reload();
        IVotingManager(votingManager).onEpochStarted();
        _epochs.push(_thisEpoch);
    }

    function _epochIdIncrement() private {
        _epochCounter.increment();
    }

    // solhint-disable-next-line
    function _authorizeUpgrade(address) internal view override onlyAdmin {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

interface IEpochManager is IERC165Upgradeable {
    struct Epoch {
        uint256 startingTime; // starting timestamp of an epoch
        uint256 endingTime; // ending timestamp of an epoch
        uint256 epochId; // epochId
    }

    struct IdeaIdPool {
        uint256[] ideaIds; // an array of ideaIds
    }

    /**
     * @dev Emitted when `ideaManger`, `votingManager` and `
     * rewardManager` contracts are set.
     */
    event ContractsSet(
        address ideaManger,
        address votingManager,
        address rewardManager
    );

    /**
     * @dev Emitted when the epoch with `epochId` is started with
     * `nIdeas` and `duration`.
     */
    event EpochStarted(uint256 epochId, uint256 nIdeas, uint256 duration);

    /**
     * @dev Emitted when the epoch with `epochId` is updated with
     * `nIdeas` and `duration`.
     */
    event EpochUpdated(uint256 epochId, uint256 nIdeas, uint256 duration);

    /**
     * @dev Emitted when the minEpochLength `oldLength` is updated with
     * a new length `newLength`.
     */
    event MinEpochLengthSet(uint256 oldLength, uint256 newLength);

    /**
     * @dev Emitted when the old maxEpochLength `oldLength` is updated with
     * a new length `newLength`.
     */
    event MaxEpochLengthSet(uint256 oldLength, uint256 newLength);

    /**
     * @dev Emitted when the old minDurationFromNow `oldMinDurationFromNow`
     * is updated with a new length `minDurationFromNow`.
     */
    event MinDurationFromNowSet(
        uint256 oldMinDurationFromNow,
        uint256 minDurationFromNow
    );

    /**
     * @dev Emitted when the maxNumOfIdeasPerEpoch `oldNumber` is updated
     * with a new number `newNumber`.
     */
    event MaxNumOfIdeasPerEpochSet(uint256 oldNumber, uint256 newNumber);

    /**
     * @dev Starts a new epoch if the refresh condition is met with an
     * array of `ideaIds` and the epoch `endTimestamp`.
     *
     * Conditions:
     * - An array of qualified ideas with valid `ideaIds` are provided.
     *
     * Requirements:
     * - only the admin can call this function.
     */
    function startNewEpoch(uint256[] calldata ideaIds, uint256 endTimestamp)
        external;

    /**
     * @dev Modifies the parameters of the current epoch with an
     * array of `ideaIds` and `endTimestamp`.
     *
     * Requirements:
     * - only the admin can call this function.
     */
    function updateEpoch(uint256[] calldata ideaIds, uint256 endTimestamp)
        external;

    /**
     * @dev Sets `minEpochLength` for epochs.
     *
     * Requirements:
     * - only the admin can call this function.
     */
    function setMinEpochLength(uint256 minEpochLength) external;

    /**
     * @dev Sets `maxEpochLength` for epochs.
     *
     * Requirements:
     * - only the admin can call this function.
     */
    function setMaxEpochLength(uint256 maxEpochLength) external;

    /**
     * @dev Sets `minDurationFromNow` for epochs.
     *
     * Requirements:
     * - only the admin can call this function.
     */
    function setMinDurationFromNow(uint256 minDurationFromNow) external;

    /**
     * @dev Sets `maxNumOfIdeasPerEpoch` for epochs.
     *
     * Requirements:
     * - only the admin can call this function.
     */
    function setMaxNumOfIdeasPerEpoch(uint256 maxNumOfIdeasPerEpoch) external;

    /**
     * @dev Sets contracts by retrieving addresses from the
     * registry contract.
     */
    function setContracts() external;

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() external;

    /**
     * @dev Returns to normal state provided a new `duration`.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause(uint256 duration) external;

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() external view returns (bool);

    /**
     * @dev Returns the `Epoch` information given the lookup `epochId`.
     */
    function epoch(uint256 epochId) external view returns (Epoch memory);

    /**
     * @dev Returns the `Epoch` information for the current active epoch.
     */
    function getThisEpoch() external view returns (Epoch memory);

    /**
     * @dev Returns the array of ideaIds for a given `epochId`.
     */
    function getIdeaIds(uint256 epochId)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Returns the total number of ideas for a given `epochId`.
     */
    function getNumOfIdeas(uint256 epochId) external view returns (uint256);

    /**
     * @dev Returns if a given `ideaId` is active in the current epoch.
     */
    function isIdeaActive(uint256 ideaId) external view returns (bool);

    /**
     * @dev Returns if this epoch is already ended.
     */
    function isThisEpochEnded() external view returns (bool);

    /**
     * @dev Returns the current value of epochCounter as the next
     * possible `epochId`.
     */
    function getCurEpochId() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

interface IIdeaManager is IERC165Upgradeable {
    struct Idea {
        bytes32 contentHash; // the hash of content metadata
        uint256 metaverseId; // metaverse id
    }

    struct IdeaInfo {
        Idea idea;
        address ideator; // ideator's address
    }

    /**
     * @dev Emitted when an idea `ideaId` with transaction hash `contentHash`,
     * for the metaverse `metaverseId` is published.
     */
    event IdeaPublished(
        uint256 ideaId,
        bytes32 contentHash,
        uint256 metaverseId,
        address ideator
    );

    /**
     * @dev Emitted when a new `metaverseManger` contract address is set.
     */
    event ContractsSet(address metaverseManger);

    /**
     * @dev Emitted when a new `wallet` address is set.
     */
    event WalletSet(address wallet);

    /**
     * @dev Emitted when a new proposal fee `newFee` is set to replace an
     * old proposal fee `oldFee`.
     */
    event ProposalFeeSet(uint256 oldFee, uint256 newFee);

    /**
     * @dev Sets a new proposal `fee` for submitting an idea. The fee is
     * denominated by the DAO token specified by `feeToken` state variable.
     */
    function setProposalFee(uint256 fee) external;

    /**
     * @dev Sets a new `wallet` address.
     */
    function setWallet(address wallet) external;

    /**
     * @dev Sets contracts by retrieving addresses from the
     * registry contract.
     */
    function setContracts() external;

    /**
     * @dev Publishes an `_idea`.
     *
     * Requirements:
     * - anyone who has a valid idea and pays a submission fee.
     */
    function publishIdea(Idea calldata _idea) external;

    /**
     * @dev Returns if an idea with `ideaId` exists.
     */
    function exists(uint256 ideaId) external view returns (bool);

    /**
     * @dev Returns the Idea struct object for an idea with `ideaId`.
     */
    function getIdeaInfo(uint256 ideaId)
        external
        view
        returns (IdeaInfo memory);

    /**
     * @dev Returns the protocol-level idea proposal fee.
     */
    function getProposalFee() external view returns (uint256);

    /**
     * @dev Returns the current ideaId.
     */
    function getCurIdeaId() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IRegistry is IERC165 {
    /**
     * @dev Emitted when a new `ideaManger` contract address is set.
     */
    event IdeaManagerSet(address ideaManger);

    /**
     * @dev Emitted when a new `metaverseManager` contract address is set.
     */
    event MetaverseManagerSet(address metaverseManager);

    /**
     * @dev Emitted when a new epoch manager contract `epochManager`
     * is set.
     */
    event EpochManagerSet(address epochManager);

    /**
     * @dev Emitted when a new voting manager contract `votingManager`
     * is set.
     */
    event VotingManagerSet(address votingManager);

    /**
     * @dev Emitted when a new reward pool `rewardPool` is set.
     */
    event RewardPoolSet(address rewardPool);

    /**
     * @dev Emitted when a new `rewardManger` contract address is set.
     */
    event RewardManagerSet(address rewardManger);

    /**
     * @dev Emitted when a new reward vesting manager constract
     * `rewardVestingManager` is set.
     */
    event RewardVestingManagerSet(address rewardVestingManager);

    /**
     * @dev Emitted when a new allocation manager contract
     * `allocationManager` is set.
     */
    event AllocationManagerSet(address allocationManager);

    /**
     * @dev Sets a new `ideaManager` contract address.
     */
    function setIdeaManager(address ideaManager) external;

    /**
     * @dev Sets a new `metaverseManager` address.
     */
    function setMetaverseManager(address metaverseManager) external;

    /**
     * @dev Sets a new `epochManager` contract address.
     *
     * Requirements: only the admin can make this update.
     */
    function setEpochManager(address epochManager) external;

    /**
     * @dev Sets a new `votingManager` contract address.
     *
     * Requirements: only the admin can call this function.
     */
    function setVotingManager(address votingManager) external;

    /**
     * @dev Sets a new `rewardPool` contract address.
     *
     * Requirements: only the admin can make this update.
     */
    function setRewardPool(address rewardPool) external;

    /**
     * @dev Sets a new `rewardManager` contract address.
     */
    function setRewardManager(address rewardManager) external;

    /**
     * @dev Sets a new `rewardVestingManager` contract address.
     *
     * Requirements: only the admin can make this update.
     */
    function setRewardVestingManager(address rewardVestingManager) external;

    /**
     * @dev Sets a new `allocationManager` contract address.
     *
     * Requirements: only the admin can make this update.
     */
    function setAllocationManager(address allocationManager) external;

    /**
     * @dev Returns the idea manager contract address.
     */
    function ideaManager() external view returns (address);

    /**
     * @dev Returns the metaverse manager contract address.
     */
    function metaverseManager() external view returns (address);

    /**
     * @dev Returns the epoch manager contract address.
     */
    function epochManager() external view returns (address);

    /**
     * @dev Returns the voting manager contract address.
     */
    function votingManager() external view returns (address);

    /**
     * @dev Returns the reward pool contract address.
     */
    function rewardPool() external view returns (address);

    /**
     * @dev Returns the reward manager contract address.
     */
    function rewardManager() external view returns (address);

    /**
     * @dev Returns the reward vesting manager contract address.
     */
    function rewardVestingManager() external view returns (address);

    /**
     * @dev Returns the allocation manager contract address.
     */
    function allocationManager() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

interface IRewardManager is IERC165Upgradeable {
    struct RewardAmount {
        uint256 total; // Total amount of reward for an epoch
        uint256 unallocated; // Unallocated amount of reward for the same epoch
    }

    /**
     * @dev Emitted when contract addressses are set.
     */
    event ContractsSet(
        address rewardPool,
        address votingManager,
        address epochManager,
        address allocationManager,
        address rewardVestingManager
    );

    /**
     * @dev Emitted when the reward manager gets reloaded with a
     * new supply of tokens of this `amount` from the reward pool
     * for `epochId`.
     */
    event Reloaded(uint256 epochId, uint256 amount);

    /**
     * @dev Emitted when `account` claims `amount` of reward
     * for `epochId`.
     */
    event Claimed(address account, uint256 epochId, uint256 amount);

    /**
     * @dev Emitted when a new `amount` of reward per epoch is updated.
     */
    event RewardAmountPerEpochUpdated(uint256 amount);

    /**
     * @dev Emitted when a new `amount` for the next epoch with
     * `nextEpochId` is (manually) updated.
     */
    event RewardAmountForNextEpochSet(uint256 amount, uint256 nextEpochId);

    /**
     * @dev Emitted when a new `rewardAmount` for the epoch with `epochId`
     * is (algorithmically) updated.
     */
    event RewardAmountUpdated(uint256 epochId, uint256 rewardAmount);

    /**
     * @dev Emitted when the status of algo rewarding is toggled to
     * be `isAlgoRewardingOn`.
     */
    event AlgoRewardingToggled(bool isAlgoRewardingOn);

    /**
     * @dev Emitted when the epoch ended locker is toggled to
     * be `isEpochEndedLockerOn`.
     */
    event EpochEndedLockerToggled(bool isEpochEndedLockerOn);

    /**
     * @dev Reloads the reward amount for the next epoch by retrieving
     * tokens from the reward pool.
     *
     * Requirements: only EpochManager can call this function.
     */
    function reload() external;

    /**
     * @dev Updates the reward amount for the next epoch manually.
     *
     * Requirements: only admin can call this function.
     */
    function updateRewardAmount() external;

    /**
     * @dev Claims the reward for `account` in `epochId` to the
     * reward vesting manager contract.
     */
    function claimRewardForEpoch(address account, uint256 epochId) external;

    /**
     * @dev Claims the rewards for `account` in an array of `epochIds`
     * to the reward vesting manager contract.
     */
    function claimRewardsForEpochs(address account, uint256[] calldata epochIds)
        external;

    /**
     * @dev Updates metrics when the current epoch is ended.
     *
     * Requirements: only the voting manager can call this function.
     */
    function onEpochEnded() external;

    /**
     * @dev Updates the reward amount per epoch with a new `amount`.
     *
     * Requirements: only the admin can make this update.
     */
    function setRewardAmountPerEpoch(uint256 amount) external;

    /**
     * @dev Sets contracts by retrieving contracts from the
     * registry contract.
     */
    function setContracts() external;

    /**
     * @dev Toggles the status of algo rewarding from true to false or
     * from false to true.
     *
     * Requirements: only the admin can call this function.
     */
    function toggleAlgoRewarding() external;

    /**
     * @dev Toggles the epoch ended locker from true to false or
     * from false to true. This is only used in emergency.
     *
     * Requirements: only the admin can call this function.
     */
    function toggleEpochEndedLocker() external;

    /**
     * @dev Returns the system paramter reward amount per epoch.
     */
    function rewardAmountPerEpoch() external view returns (uint256);

    /**
     * @dev Returns if `account` has claimed reward for `epochId`.
     */
    function hasClaimedRewardForEpoch(address account, uint256 epochId)
        external
        view
        returns (bool);

    /**
     * @dev Returns the eligible amount for `account` to claim given
     * `epochId`.
     */
    function amountEligibleForEpoch(address account, uint256 epochId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the unclaimed amount of tokens in this contract.
     */
    function amountUnclaimed() external view returns (uint256);

    /**
     * @dev Returns the reward amount for `account`.
     */
    function getClaimedRewardAmount(address account)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the reward amount for `epochId`.
     */
    function getRewardAmountForEpoch(uint256 epochId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the unallocated reward amount for `epochId`.
     */
    function getUnallocatedRewardAmountForEpoch(uint256 epochId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the allocated reward amount for `epochId`.
     */
    function getAmountOfAllocatedReward(uint256 epochId)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

interface IVeContractListener is IERC165Upgradeable {
    /**
     * @dev Updates the voting power for `account` when voting power is
     * added or changed on the voting escrow contract directly.
     *
     * Requirements:
     *
     * - only the voting escrow contract can call this contract.
     */
    function onVotingPowerUpdated(address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IEpochManager.sol";
import "./IVeContractListener.sol";

interface IVotingManager is IVeContractListener {
    struct EpochInfo {
        uint256[] epochIds; // epochs that a voter has participated in
    }

    struct Vote {
        uint256 ideaId; // Vote for ideaId
        uint256 percentage; // % of voting power allocated to this vote
    }

    struct Ballot {
        uint256 total; // Total amount of voting power for a ballot
        Vote[] votes; // Array of votes
    }

    /**
     * @dev Emitted when contract addresses are set.
     */
    event ContractsSet(
        address ideaManager,
        address epochManager,
        address rewardManager
    );

    /**
     * @dev Emitted when the voting power is updated for `account` to a new
     * total amount `votingPower`. This can happen when tokens are being
     * locked in the voting escrow contract.
     */
    event VotingPowerUpdated(address account, uint256 votingPower);

    /**
     * @dev Emitted when `oldVotingPowerThreshold` is replaced by a
     * new `votingPowerThreshold`.
     */
    event VotingPowerThresholdSet(
        uint256 oldVotingPowerThreshold,
        uint256 votingPowerThreshold
    );

    /**
     * @dev Emitted when `oldMaxNumOfVotesPerBallot` is replaced by a
     * new `maxNumOfVotesPerBallot`.
     */
    event MaxNumOfVotesPerBallotSet(
        uint256 oldMaxNumOfVotesPerBallot,
        uint256 maxNumOfVotesPerBallot
    );

    /**
     * @dev Emitted when `account` submits a ballot in `epochId` with
     * `votes` and a total amount of `votingPower`.
     */
    event BallotSubmitted(
        address account,
        uint256 epochId,
        Vote[] votes,
        uint256 votingPower
    );

    /**
     * @dev Emitted when the denied status for `account` is toggled.
     */
    event AccountDeniedStatusToggled(address account);

    /**
     * @dev Emitted when the total voting power is updated in `epochId`
     * to a new total amount `totalVotingPower`.
     */
    event TotalVotingPowerUpdated(uint256 epochId, uint256 totalVotingPower);

    /**
     * @dev Submits a ballot with ideas in `votes`.
     */
    function submitBallot(Vote[] calldata votes) external;

    /**
     * @dev Calls this function when a new epoch is started to record the
     * total voting power.
     *
     * Requirements: only the EpochManager contract can call this function.
     */
    function onEpochStarted() external;

    /**
     * @dev Ends this epoch and updates the metrics for the previous epoch.
     */
    function endThisEpoch() external;

    /**
     * @dev Sets new contract addresses.
     *
     * Requirements: only the admin can call this function.
     */
    function setContracts() external;

    /**
     * @dev Sets `newThreshold` for the voting power threshold.
     *
     * Requirements: only the admin can call this function.
     */
    function setVotingPowerThreshold(uint256 newThreshold) external;

    /**
     * @dev Sets `newNumber` for the maximum number of votes permited
     * per ballot.
     *
     * Requirements: only the admin can call this function.
     */
    function setMaxNumOfVotesPerBallot(uint256 newNumber) external;

    /**
     * @dev Toggles the denied status for an `account`.
     *
     * Requirements: only the admin can call this function.
     */
    function toggleDenied(address account) external;

    /**
     * @dev Returns the Epoch information for this epoch by reading from
     * EpochManager.
     */
    function getThisEpoch() external view returns (IEpochManager.Epoch memory);

    /**
     * @dev Returns the Ballot information for `account` in epoch with
     * `epochId`.
     */
    function getBallot(address account, uint256 epochId)
        external
        view
        returns (Ballot memory);

    /**
     * @dev Returns the array of epochIds that `account` has participated in.
     */
    function getEpochsParticipated(address account)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Returns the total amount of voting power that
     * `account` has allocated for the current active epoch.
     */
    function getVotingPowerForCurrentEpoch(address account)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the system parameter `PERCENTAGES_MULTIPLE`.
     */
    function PERCENTAGES_MULTIPLE() external view returns (uint256);

    /**
     * @dev Returns the weight of voting power `account` has gained
     * in `epochId` among all voters.
     */
    function getWeightInVotingPower(address account, uint256 epochId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the amount of consumed voting power in `epochId`.
     */
    function getEpochVotingPower(uint256 epochId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the total amount of voting power available for `epochId`,
     * including the amount that has not been consumed in `epochId`.
     */
    function getTotalVotingPowerForEpoch(uint256 epochId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the voting power consumption rate for `epochId`.
     * It is calculated by comparing the consumed amount with the
     * total available amount of voting power.
     */
    function getVotingPowerConsumptionRate(uint256 epochId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the absolute amount of voting power for `ideaId`
     * in epoch `epochId`.
     */
    function getIdeaVotingPower(uint256 ideaId, uint256 epochId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the absolute amount of voting power for `metaverseId`
     * in epoch `epochId`.
     */
    function getMetaverseVotingPower(uint256 metaverseId, uint256 epochId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns if an array of `votes` is a valid ballot.
     */
    function isValidBallot(Vote[] calldata votes) external view returns (bool);

    /**
     * @dev Returns if `voter` is denied from voting.
     */
    function isDenied(address voter) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an admin) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the admin account will be the one that deploys the contract. This
 * can later be changed with {transferAdminship}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyAdmin`, which can be applied to your functions to restrict their use to
 * the admin.
 *
 * This contract is only required for intermediate, library-like contracts.
 *
 * This is a direct copy of OpenZeppelin's Ownable at:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
 */

abstract contract AdminableUpgradeable is Initializable, ContextUpgradeable {
    address private _admin;

    event AdminshipTransferred(
        address indexed previousAdmin,
        address indexed newAdmin
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial admin.
     */
    function __Adminable_init() internal onlyInitializing {
        __Adminable_init_unchained();
    }

    function __Adminable_init_unchained() internal onlyInitializing {
        _transferAdminship(_msgSender());
    }

    /**
     * @dev Returns the address of the current admin.
     */
    function admin() public view virtual returns (address) {
        return _admin;
    }

    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        // solhint-disable-next-line reason-string
        require(admin() == _msgSender(), "Adminable: caller is not the admin");
        _;
    }

    /**
     * @dev Leaves the contract without admin. It will not be possible to call
     * `onlyAdmin` functions anymore. Can only be called by the current admin.
     *
     * NOTE: Renouncing adminship will leave the contract without an admin,
     * thereby removing any functionality that is only available to the admin.
     */
    function renounceAdminship() public virtual onlyAdmin {
        _transferAdminship(address(0));
    }

    /**
     * @dev Transfers adminship of the contract to a new account (`newAdmin`).
     * Can only be called by the current admin.
     */
    function transferAdminship(address newAdmin) public virtual onlyAdmin {
        // solhint-disable-next-line reason-string
        require(
            newAdmin != address(0),
            "Adminable: new admin is the zero address"
        );
        _transferAdminship(newAdmin);
    }

    /**
     * @dev Transfers adminship of the contract to a new account (`newAdmin`).
     * Internal function without access restriction.
     */
    function _transferAdminship(address newAdmin) internal virtual {
        address oldAdmin = _admin;
        _admin = newAdmin;
        emit AdminshipTransferred(oldAdmin, newAdmin);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}