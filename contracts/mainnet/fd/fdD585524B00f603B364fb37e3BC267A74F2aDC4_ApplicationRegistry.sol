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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IWorkspaceRegistry.sol";
import "./interfaces/IGrant.sol";
import "./interfaces/IApplicationRegistry.sol";
import "./interfaces/IApplicationReviewRegistry.sol";
import "./interfaces/IUtilityRegistry.sol";

/// @title Registry for all the grant applications used for updates on application
/// and requesting funds/milestone approvals
contract ApplicationRegistry is Initializable, UUPSUpgradeable, OwnableUpgradeable, IApplicationRegistry {
    /// @notice Number of applications submitted
    uint96 public applicationCount;

    /// @notice possible states of an application milestones
    enum MilestoneState {
        Submitted,
        Requested,
        Approved
    }

    /// @notice possible states of an application
    enum ApplicationState {
        Submitted,
        Resubmit,
        Approved,
        Rejected,
        Complete
    }

    /// @notice types of reward disbursals
    enum DisbursalType {
        LockedAmount,
        P2P
    }

    /// @notice structure holding each application data
    struct Application {
        uint96 id;
        uint96 workspaceId;
        address grant;
        address owner;
        uint48 milestoneCount;
        uint48 milestonesDone;
        string metadataHash;
        ApplicationState state;
    }

    /// @notice mapping to store applicationId along with application
    mapping(uint96 => Application) public applications;

    /// @dev mapping to store application owner along with grant address
    /// ex: for application id - 0, grant addr - 0x0
    /// applicantGrant[0][0x0] will be = true, this is used to prevent duplicate entry
    mapping(address => mapping(address => bool)) private applicantGrant;

    /// @notice mapping to store applicationId along with milestones
    mapping(uint96 => mapping(uint48 => MilestoneState)) public applicationMilestones;

    /// @notice interface for using external functionalities like checking workspace admin
    IWorkspaceRegistry public workspaceReg;

    /// @notice interface for using external functionalities like assigning reviewers
    IApplicationReviewRegistry public applicationReviewReg;

    /// @notice mapping from wallet address to scwAddress of the applicant
    /// Deprecated: this is deprecated and is retained to preserve upgradability
    mapping(bytes32 => address) public walletAddressMapping;

    /// @notice mapping from eoa wallet address to scwAddress of the applicant, per grant program
    mapping(bytes32 => mapping(address => address)) public eoaToScw;

    IUtilityRegistry public utilityReg;

    // --- Events ---
    /// @notice Emitted when a new application is submitted
    event ApplicationSubmitted(
        uint96 indexed applicationId,
        address grant,
        address owner,
        string metadataHash,
        uint48 milestoneCount,
        uint256 time
    );

    /// @notice Emitted when a new application is updated
    event ApplicationUpdated(
        uint96 indexed applicationId,
        address owner,
        string metadataHash,
        ApplicationState state,
        uint48 milestoneCount,
        uint256 time
    );

    /// @notice Emitted when the EOA wallet address is updated
    event WalletAddressUpdated(uint96 indexed applicationId, address grant, bytes32 walletAddress, uint256 time);

    event ApplicationMigrate(uint96 indexed applicationId, address newApplicantAddress, uint256 time);

    /// @notice Emitted when application milestone is updated
    event MilestoneUpdated(uint96 _id, uint96 _milestoneId, MilestoneState _state, string _metadataHash, uint256 time);

    modifier onlyWorkspaceAdmin(uint96 _workspaceId) {
        require(workspaceReg.isWorkspaceAdmin(_workspaceId, msg.sender), "Unauthorised: Not an admin");
        _;
    }

    /**
     * @notice Calls initialize on the base contracts
     *
     * @dev This acts as a constructor for the upgradeable proxy contract
     */
    function initialize() external initializer {
        __Ownable_init();
    }

    /**
     * @notice Override of UUPSUpgradeable virtual function
     *
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     */
    function _authorizeUpgrade(address) internal view override onlyOwner {}

    /**
     * @notice sets workspace registry contract interface
     * @param _workspaceReg WorkspaceRegistry interface
     */
    function setWorkspaceReg(IWorkspaceRegistry _workspaceReg) external onlyOwner {
        workspaceReg = _workspaceReg;
    }

    /**
     * @notice sets application review registry contract interface
     * @param _applicationReviewReg ApplicationReviewRegistry interface
     */
    function setApplicationReviewReg(IApplicationReviewRegistry _applicationReviewReg) external onlyOwner {
        applicationReviewReg = _applicationReviewReg;
    }

    /**
     * @notice sets utility registry contract interface
     * @param _utilityReg UtilityRegistry interface
     */
    function setUtilityRegistry(IUtilityRegistry _utilityReg) external onlyOwner {
        utilityReg = _utilityReg;
    }

    /**
     * @notice Migrate the user's wallet to a new address
     *
     * @param fromWallet Current wallet address of the user
     * @param toWallet The new wallet address to migrate to
     */
    function migrateWallet(address fromWallet, address toWallet) external override {
        require(
            msg.sender == fromWallet || msg.sender == address(workspaceReg),
            "Only fromWallet/workspaceReg can migrate"
        );

        for (uint96 i = 0; i < applicationCount; i++) {
            Application storage app = applications[i];
            if (app.owner == fromWallet) {
                app.owner = toWallet;

                emit ApplicationMigrate(app.id, toWallet, block.timestamp);
            }

            applicationReviewReg.migrateWallet(fromWallet, toWallet, app.id);
        }
    }

    /**
     * @notice Update linked wallet address
     * @param _applicationId target applicationId which needs to be updated
     * @param _applicantAddress updated wallet address where they would want to receive funds
     */
    function updateWalletAddress(uint96 _applicationId, bytes32 _applicantAddress) public {
        Application storage application = applications[_applicationId];
        require(application.owner == msg.sender, "ApplicationUpdate: Unauthorised");
        eoaToScw[_applicantAddress][application.grant] = msg.sender;

        emit WalletAddressUpdated(_applicationId, application.grant, _applicantAddress, block.timestamp);
    }

    /**
     * @notice Create/submit application
     * @param _grant address of Grant for which the application is submitted
     * @param _workspaceId workspaceId to which the grant belongs
     * @param _metadataHash application metadata pointer to IPFS file
     * @param _milestoneCount number of milestones under the application
     * @param _applicantAddress address of the applicant where they would want to receive funds
     */
    function submitApplication(
        address _grant,
        uint96 _workspaceId,
        string memory _metadataHash,
        uint48 _milestoneCount,
        bytes32 _applicantAddress
    ) external {
        require(!applicantGrant[msg.sender][_grant], "ApplicationSubmit: Already applied to grant once");
        require(
            _applicantAddress == bytes32(0) ||
                (_applicantAddress != bytes32(0) && eoaToScw[_applicantAddress][_grant] == address(0)),
            "ApplicationSubmit: Cannot receive funds to the same address"
        );
        IGrant grantRef = IGrant(_grant);
        require(grantRef.active(), "ApplicationSubmit: Invalid grant");
        uint96 _id = applicationCount;
        assert(applicationCount + 1 > applicationCount);
        applicationCount += 1;
        applications[_id] = Application(
            _id,
            _workspaceId,
            _grant,
            msg.sender,
            _milestoneCount,
            0,
            _metadataHash,
            ApplicationState.Submitted
        );
        applicantGrant[msg.sender][_grant] = true;
        emit ApplicationSubmitted(_id, _grant, msg.sender, _metadataHash, _milestoneCount, block.timestamp);

        utilityReg.createProfile(" ");
        grantRef.incrementApplicant();
        updateWalletAddress(_id, _applicantAddress);
    }

    /**
     * @notice Update application
     * @param _applicationId target applicationId which needs to be updated
     * @param _metadataHash updated application metadata pointer to IPFS file
     */
    function updateApplicationMetadata(
        uint96 _applicationId,
        string memory _metadataHash,
        uint48 _milestoneCount,
        bytes32 _applicantAddress
    ) external {
        Application storage application = applications[_applicationId];
        require(application.owner == msg.sender, "ApplicationUpdate: Unauthorised");
        require(
            application.state == ApplicationState.Resubmit || application.state == ApplicationState.Submitted,
            "ApplicationUpdate: Invalid state"
        );
        /// @dev we need to reset milestone state of all the milestones set previously
        for (uint48 i = 0; i < application.milestoneCount; i++) {
            applicationMilestones[_applicationId][i] = MilestoneState.Submitted;
        }
        application.milestoneCount = _milestoneCount;
        application.metadataHash = _metadataHash;
        application.state = ApplicationState.Submitted;
        emit ApplicationUpdated(
            _applicationId,
            msg.sender,
            _metadataHash,
            ApplicationState.Submitted,
            _milestoneCount,
            block.timestamp
        );

        updateWalletAddress(_applicationId, _applicantAddress);
    }

    /**
     * @notice Update application state
     * @param _applicationId target applicationId for which state needs to be updated
     * @param _workspaceId workspace id of application's grant
     * @param _state updated state
     * @param _reasonMetadataHash metadata file hash with state change reason
     */
    function updateApplicationState(
        uint96 _applicationId,
        uint96 _workspaceId,
        ApplicationState _state,
        string memory _reasonMetadataHash
    ) public onlyWorkspaceAdmin(_workspaceId) {
        Application storage application = applications[_applicationId];
        require(application.workspaceId == _workspaceId, "ApplicationStateUpdate: Invalid workspace");
        /// @notice grant creator can only make below transitions
        /// @notice Submitted => Resubmit
        /// @notice Submitted => Approved
        /// @notice Submitted => Rejected
        if (
            (application.state == ApplicationState.Submitted && _state == ApplicationState.Resubmit) ||
            (application.state == ApplicationState.Submitted && _state == ApplicationState.Approved) ||
            (application.state == ApplicationState.Submitted && _state == ApplicationState.Rejected)
        ) {
            application.state = _state;
        } else {
            revert("ApplicationStateUpdate: Invalid state transition");
        }
        emit ApplicationUpdated(
            _applicationId,
            msg.sender,
            _reasonMetadataHash,
            _state,
            application.milestoneCount,
            block.timestamp
        );
    }

    /**
     * @notice Batch update application state
     * @param _applicationIds an array of target applicationIds for which state needs to be updated
     * @param _applicationStates an array of updated states for the applications
     * @param _workspaceId workspace id of application's grant
     */
    function batchUpdateApplicationState(
        uint96[] memory _applicationIds,
        ApplicationState[] memory _applicationStates,
        uint96 _workspaceId,
        string[] memory feedbackHashes
    ) external onlyWorkspaceAdmin(_workspaceId) {
        require(
            _applicationIds.length == _applicationStates.length,
            "applicationIds and applicationStates array length mismatch"
        );
        require(_applicationIds.length == feedbackHashes.length, "applicationIds and feedbacks array length mismatch");
        for (uint256 i = 0; i < _applicationIds.length; i++) {
            updateApplicationState(_applicationIds[i], _workspaceId, _applicationStates[i], feedbackHashes[i]);
        }
    }

    /**
     * @notice Mark application as complete
     * @param _applicationId target applicationId which needs to be marked as complete
     * @param _workspaceId workspace id of application's grant
     * @param _reasonMetadataHash metadata file hash with application overall feedback
     */
    function completeApplication(
        uint96 _applicationId,
        uint96 _workspaceId,
        string memory _reasonMetadataHash
    ) external onlyWorkspaceAdmin(_workspaceId) {
        Application storage application = applications[_applicationId];
        require(application.workspaceId == _workspaceId, "ApplicationStateUpdate: Invalid workspace");
        require(
            application.milestonesDone == application.milestoneCount,
            "CompleteApplication: Invalid milestones state"
        );

        application.state = ApplicationState.Complete;

        emit ApplicationUpdated(
            _applicationId,
            msg.sender,
            _reasonMetadataHash,
            ApplicationState.Complete,
            application.milestoneCount,
            block.timestamp
        );
    }

    /**
     * @notice Update application milestone state
     * @param _applicationId target applicationId for which milestone needs to be updated
     * @param _milestoneId target milestoneId which needs to be updated
     * @param _reasonMetadataHash metadata file hash with state change reason
     */
    function requestMilestoneApproval(
        uint96 _applicationId,
        uint48 _milestoneId,
        string memory _reasonMetadataHash
    ) external {
        Application memory application = applications[_applicationId];
        require(application.owner == msg.sender, "MilestoneStateUpdate: Unauthorised");
        require(application.state == ApplicationState.Approved, "MilestoneStateUpdate: Invalid application state");
        require(_milestoneId < application.milestoneCount, "MilestoneStateUpdate: Invalid milestone id");
        require(
            applicationMilestones[_applicationId][_milestoneId] == MilestoneState.Submitted,
            "MilestoneStateUpdate: Invalid state transition"
        );
        applicationMilestones[_applicationId][_milestoneId] = MilestoneState.Requested;
        emit MilestoneUpdated(
            _applicationId,
            _milestoneId,
            MilestoneState.Requested,
            _reasonMetadataHash,
            block.timestamp
        );
    }

    /**
     * @notice Update application milestone state
     * @param _applicationId target applicationId for which milestone needs to be updated
     * @param _milestoneId target milestoneId which needs to be updated
     * @param _workspaceId workspace id of application's grant
     * @param _reasonMetadataHash metadata file hash with state change reason
     */
    function approveMilestone(
        uint96 _applicationId,
        uint48 _milestoneId,
        uint96 _workspaceId,
        string memory _reasonMetadataHash
    ) external onlyWorkspaceAdmin(_workspaceId) {
        Application storage application = applications[_applicationId];
        require(application.workspaceId == _workspaceId, "ApplicationStateUpdate: Invalid workspace");
        require(application.state == ApplicationState.Approved, "MilestoneStateUpdate: Invalid application state");
        require(_milestoneId < application.milestoneCount, "MilestoneStateUpdate: Invalid milestone id");
        MilestoneState currentState = applicationMilestones[_applicationId][_milestoneId];
        /// @notice grant creator can only make below transitions
        /// @notice Submitted => Approved
        /// @notice Requested => Approved
        if (currentState == MilestoneState.Submitted || currentState == MilestoneState.Requested) {
            applicationMilestones[_applicationId][_milestoneId] = MilestoneState.Approved;
        } else {
            revert("MilestoneStateUpdate: Invalid state transition");
        }

        application.milestonesDone += 1;

        emit MilestoneUpdated(
            _applicationId,
            _milestoneId,
            MilestoneState.Approved,
            _reasonMetadataHash,
            block.timestamp
        );
    }

    /**
     * @notice returns application owner
     * @param _applicationId applicationId for which owner is required
     * @return address of application owner
     */
    function getApplicationOwner(uint96 _applicationId) external view override returns (address) {
        Application memory application = applications[_applicationId];
        return application.owner;
    }

    /**
     * @notice returns application workspace id
     * @param _applicationId applicationId for which owner is required
     * @return id of application's workspace
     */
    function getApplicationWorkspace(uint96 _applicationId) external view override returns (uint96) {
        Application memory application = applications[_applicationId];
        return application.workspaceId;
    }

    /**
     * @notice returns application grant
     * @param _applicationId applicationId for which grant is required
     * @return address of application's grant
     */
    function getApplicationGrant(uint96 _applicationId) external view override returns (address) {
        Application memory application = applications[_applicationId];
        return application.grant;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/// @title Interface of the applicationRegistry contract
interface IApplicationRegistry {
    /// @notice Returns owner of application using specified application id
    function getApplicationOwner(uint96 _applicationId) external view returns (address);

    /// @notice returns application workspace id
    function getApplicationWorkspace(uint96 _applicationId) external view returns (uint96);

    /// @notice returns application grant
    function getApplicationGrant(uint96 _applicationId) external view returns (address);

    function migrateWallet(address fromWallet, address toWallet) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/// @title Interface of the applicationReviewRegistry contract
interface IApplicationReviewRegistry {
    /// @notice Sets the rubric for the application review for the specified grant
    function setRubrics(
        uint96 _workspaceId,
        address _grantAddress,
        string memory _metadataHash
    ) external;

    function migrateWallet(
        address fromWallet,
        address toWallet,
        uint96 appId
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/// @title Interface of the grant contract
interface IGrant {
    /// @notice number of submitted applications
    function numApplicants() external view returns (uint96);

    /// @notice Returns a boolean value indicating whether a grant is active
    function active() external view returns (bool);

    /// @notice It increments number of applicants against the grant
    /// and is invoked at the time of submitting application
    function incrementApplicant() external;

    function metadataHash() external view returns (string memory);

    /// @notice It disburses reward to application owner using locked funds
    function disburseReward(
        uint96 _applicationId,
        uint96 _milestoneId,
        address _asset,
        uint256 _amount,
        address _sender
    ) external;

    /// @notice It disburses reward to application owner P2P from workspace admin wallet
    function disburseRewardP2P(
        uint96 _applicationId,
        uint96 _milestoneId,
        address _asset,
        uint256 _amount,
        address _sender
    ) external;

    /// @notice Return the workspace id to which the grant belongs
    function workspaceId() external view returns (uint96);

    /// @notice Update the metadata pointer of a grant, can be called by GrantFactory contract
    function updateGrant(string memory _metadataHash) external;

    /// @notice Update grant accessibility, can be called by GrantFactory contract
    function updateGrantAccessibility(bool _canAcceptApplication) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IUtilityRegistry {
    function createProfile(string memory metadataHash) external;

    function updateProfile(string memory metadataHash) external;

    function getAddress(bytes memory data) external pure returns (address addr);

    function splitSignature(bytes memory sig) external pure returns (bytes32 r, bytes32 s, uint8 v);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/// @title Interface of workspaceRegistry contract
interface IWorkspaceRegistry {
    /// @notice Returns a boolean value indicating whether specified address is owner of given workspace
    function isWorkspaceAdmin(uint96 _id, address _member) external view returns (bool);

    /// @notice Returns a boolean value indicating whether specified address is admin or reviewer of given workspace
    function isWorkspaceAdminOrReviewer(uint96 _id, address _member) external view returns (bool);
}