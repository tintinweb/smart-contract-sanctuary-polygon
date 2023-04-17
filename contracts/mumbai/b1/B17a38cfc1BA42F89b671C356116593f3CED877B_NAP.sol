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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
library Counters {
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

pragma solidity ^0.8.19;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV2Router02} from "../../libs/uniswap-v2/contracts/interfaces/IUniswapV2Router02.sol";

interface INAP {
    /**
     * @dev Emitted when tokens are deactivated
     * @param tokenIds An array of token IDs that were deactivated
     * @param deactivationProfits The total amount of profits generated from the deactivation
     * @dev The profits are calculated as the difference between the token price and deactivation fee precentage
     */
    event DeactivateTokens(uint16[] tokenIds, uint deactivationProfits);

    /**
     * @dev Emitted when tokens are activated
     * @param tokenIds An array of token IDs that were activated
     * @param activationPrices The total amount of prices paid for the activation
     */
    event ActivateTokens(uint16[] tokenIds, uint activationPrices);

    /**
     * @dev Emitted when tokens are claimed
     * @param tokenIds An array of token IDs that were claimed
     * @param claimAmount The total amount claimed
     */
    event Claim(uint16[] tokenIds, uint claimAmount);

    /**
     * @dev Emitted when the vesting end block is updated
     * @param vestingEndAt The new vesting end block
     */
    event VestingEndUpdated(uint64 indexed vestingEndAt);

    /**
     * @dev Emitted when the vesting is activated
     * @param vestingStartAt The vesting start block
     * @param vestingEndAt The vesting end block
     */
    event VestingActivated(uint64 indexed vestingStartAt, uint64 indexed vestingEndAt);

    /**
     * @dev Emitted when the maximum number of deactivations per interval is updated
     * @param maxDeactivationsPerPeriod The new maximum number of deactivations per interval
     */
    event MaxDeactivationsPerIntervalUpdated(uint16 maxDeactivationsPerPeriod);

    /**
     * @dev Emitted when the interval duration is updated
     * @param newPeriodDuration The new interval duration in blocks
     * @param periodDurationUpdatedAt The block of the interval duration update
     */
    event IntervalDurationUpdated(uint64 newPeriodDuration, uint64 periodDurationUpdatedAt);

    /**
     * @dev Emitted when the deactivation fee percentage is updated
     * @param newDeactivationFeePrecentage The new deactivation fee percentage
     */
    event DeactivationFeePrecentageUpdated(uint16 newDeactivationFeePrecentage);


    /**
     * @dev Error thrown when a vesting period is not active
     */
    error VestingPeriodNotActive();

    /**
     * @dev Error thrown when a vesting period is already active
     */
    error VestingPeriodActive();

    /**
     * @dev Error thrown when attempting to activate a vesting period that is already active
     */
    error VestingPeriodAlreadyActive();

    /**
     * @dev Error thrown when the provided vesting end time is less than the current block
     * @param vestingEndAt The invalid vesting end block
     */
    error InvalidVestingEndAt(uint64 vestingEndAt);

    /**
     * @dev Error thrown when the provided deactivation fee percentage is invalid
     * @param deactivationFeePrecentage The invalid deactivation fee percentage
     */
    error InvalidDeactivationFeePrecentage(uint16 deactivationFeePrecentage);

    /**
     * @dev Error thrown when the maximum number of deactivations per interval has been exceeded
     * @param period The interval period in blocks
     * @param maxDeactivationsPerPeriod The maximum number of deactivations allowed per interval
     * @param deactivationsCount The number of deactivations that exceeded the maximum allowed
     */
    error MaxDeactivationAmountPerIntervalExceeded(uint64 period, uint16 maxDeactivationsPerPeriod, uint16 deactivationsCount);

    /**
     * @dev Error thrown when a user attempts to claim tokens that they do not own
     * @param tokenId The ID of the token being claimed
     * @param claimer The address of the user attempting to claim the token
     */
    error ClaimerIsNotTokenOwner(uint16 tokenId, address claimer);

    /**
     * @dev Error thrown when the owner sets the vesting end block to a time when it already is ended.
     */
    error VestingPeriodAlreadyEnded();


    /**
     * @notice Initializes the contract with the specified parameters
     * @param pfpNft_ The address of the ERC721 PFP NFT contract
     * @param b01_ The address of the B01 token contract
     * @param usdc_ The address of the USDC token contract
     * @param uniswapRouter_ The address of the Uniswap Router contract
     * @param tokenPrice_ The price of the PFP token in USDC
     * @param feeRecipient_ The address where fees will be sent
     * @param deactivationFeePrecentage_ The percentage of the token price to charge when deactivating tokens
     * @param maxDeactivationsPerInterval_ The maximum number of tokens that can be deactivated in a single interval
     */
    function initialize(
        IERC721 pfpNft_,
        IERC20 b01_,
        IERC20 usdc_,
        IUniswapV2Router02 uniswapRouter_,
        uint tokenPrice_,
        address feeRecipient_,
        uint16 deactivationFeePrecentage_,
        uint16 maxDeactivationsPerInterval_
    ) external;

    /**
     * @notice Activates a batch of tokens by transferring them from the contract to the specified recipient.
     * @dev This function takes an array of token IDs and transfers them from the contract to the specified recipient.
     * It also charges the caller the total activation price based on the number of tokens being activated.
     * @param tokenIds The array of token IDs to activate
     * @param to The address of the recipient who will receive the activated tokens.
     */
    function activateTokens(uint16[] calldata tokenIds, address to) external;

    /**
     * @dev Deactivates NFTs by transfering them from the caller to this contract and
     * transfer B01 with `tokenPrice` substracted by deactivation fee precentage
     * @param tokenIds Array of token IDs to be deactivated.
     * @param to Address to which the deactivated tokens will be transferred.
     * @return deactivationProfit The total deactivation profit.
     */
    function deactivateTokens(uint16[] calldata tokenIds, address to) external returns (uint deactivationProfit);

    /**
     * @notice Claims the specified tokens' rewards and transfers them to the specified address
     * @param tokenIds The array of token IDs to claim rewards from
     * @param to The address to which the rewards will be transferred
     * @return claimAmount The total amount of rewards claimed in B01 tokens
     */
    function claim(uint16[] calldata tokenIds, address to) external returns (uint claimAmount);

    /**
     * @notice Enables vesting period and set the block of its ending
     * @param newVestingEndAt The new vesting end block
     */
    function activateVesting(uint64 newVestingEndAt) external;

    /**
     * @notice Sets the deactivation fee percentage to the specified value
     * @param newDeactivationFeePrecentage The new deactivation fee percentage
     */
    function setDeactivationFeePrecentage(uint16 newDeactivationFeePrecentage) external;

    /**
     * @notice Sets the maximum number of tokens that can be deactivated in a single interval to the specified value
     * @param newMaxDeactivationsPerInterval The new maximum number of tokens that can be deactivated in a single interval
     */
    function setMaxDeactivationsPerInterval(uint16 newMaxDeactivationsPerInterval) external;

    /**
     * @notice Sets the duration of the deactivation interval to the specified value
     * @param newIntervalDuration The new duration of the deactivation interval in blocks
     */
    function setIntervalDuration(uint64 newIntervalDuration) external;

    /**
     * @notice Sets the vesting end block to the specified value
     * @param newVestingEndAt The new vesting end block
     */
    function setVestingEnd(uint64 newVestingEndAt) external;

    /**
     * @dev Returns the current interval index.
     */
    function getCurrentInterval() external view returns (uint64);

    /**
     * @notice Calculates the reward per block.
     * @return rewardPerBlock The reward per block.
     */
    function calculateRewardPerBlock() external view returns (uint rewardPerBlock);

    /**
     * @notice Calculates the number of available deactivations per current interval.
     * @return The number of available deactivations.
     */
    function getAvailableDeactivationCount() external view returns (uint16);

    /**
     * @dev Calculates the rewards that can be claimed for the given tokens.
     * @param tokenIds Array of token IDs to calculate rewards for.
     * @return rewards An array of the calculated rewards, in wei.
     */
    function calculateClaimRewards(uint16[] calldata tokenIds) external view returns (uint[] memory rewards);

    /**
     * @dev Returns the PFP NFT contract used by the NAP contract.
     * @return The PFP NFT contract instance.
     */
    function pfpNft() external view returns (IERC721);

    /**
     * @dev Returns the B01 token contract used by the NAP contract.
     * @return The B01 token contract instance.
     */
    function b01() external view returns (IERC20);

    /**
     * @dev Returns the USDC token contract used by the NAP contract.
     * @return The USDC token contract instance.
     */
    function usdc() external view returns (IERC20);

    /**
     * @dev Returns the Uniswap V2 router contract instance used by the NAP contract.
     * @return The Uniswap V2 router contract instance.
     */
    function uniswapRouter() external view returns (IUniswapV2Router02);

    /**
     * @dev Returns the address of the fee recipient for this contract.
     * @return The address of the fee recipient.
     */
    function feeRecipient() external view returns (address);

    /**
     * @dev Returns the address at the given index in the exchange path used for swaps.
     * @param index The index of the exchange path address to return.
     * @return The address at the given index in the exchange path.
     */
    function exchangePath(uint256 index) external view returns (address);

    /**
     * @dev Returns the deactivation fee percentage for this contract.
     * @return The deactivation fee percentage, represented as a number between 0 and 10000.
     */
    function deactivationFeePrecentage() external view returns (uint16);

    /**
     * @dev Returns the current token price in USDC for this contract.
     * @return The current token price, in wei.
     */
    function tokenPrice() external view returns (uint);

    /**
     * @dev Returns the current duration of each interval, in blocks.
     * @return The current interval duration, in bblocks.
     */
    function intervalDuration() external view returns (uint64);

    /**
     * @dev Returns the blocks of the last time the interval duration was updated.
     * @return The blocks of the last interval duration update.
     */
    function intervalDurationUpdatedAt() external view returns (uint64);

    /**
     * @dev Returns the index of the last interval duration update.
     * @return The index of the last interval duration update.
     */
    function intervalDurationUpdatedAtIndex() external view returns (uint64);

    /**
     * @dev Returns the maximum number of deactivations allowed per interval for this contract.
     * @return The maximum number of deactivations allowed per interval.
     */
    function maxDeactivationsPerInterval() external view returns (uint16);

    /**
     * @dev Returns the number of deactivations that occurred in the given interval.
     * @param intervalIndex The index of the interval to check.
     * @return The number of deactivations that occurred in the given interval.
     */
    function deactivationsCountByInterval(uint64 intervalIndex) external view returns (uint16);

    /**
     * @dev Returns whether vesting is currently active for this contract.
     * @return True if vesting is currently active, false otherwise.
     */
    function vestingActive() external view returns (bool);

    /**
     * @dev Returns the block of the start of the vesting period.
     * @return The block of the start of the vesting period.
     */
    function vestingStartAt() external view returns (uint64);

    /**
     * @dev Returns the block
     * @return The block of the end of the vesting period.
     */
    function vestingEndAt() external view returns (uint64);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";

interface IPFPSeasons {
    error CannotReserveAmountGtMaxSupply();
    error SeasonNotExist(uint16 seasonId);
    error UriAlreadyDefined();
    error CallerIsNotMinter();
    error UriNotDefined();

    event SeasonCreated(uint16 indexed seasonId);
    event FormParamsUpdated(string[3] baseURIs, bool[3] enabledForms);
    event MinterSettled(address indexed minter);

    enum TokenForm {
        STUB,
        PIXEL_ART,
        THREE_D,
        AR
    }

    struct Season {
        bool exist;
        uint16 id;
        uint64 startAt;
        uint64 endAt;
        uint16 firstTokenId;
        uint16 lastTokenId;
        string stubURI;
        string[3] baseURIs;
        bool[3] enabledForms;
    }

    function MAX_RESERVED_TOKENS_AMOUNT() external pure returns (uint16);
    function reservedTokensAmount() external view returns (uint16);
    function totalSeasonsCount() external view returns (uint);
    function minter() external view returns (address);

    function initialize() external;
    function setMinter(address newMinter) external;
    function createSeason(
        uint16 tokensAmount,
        uint64 startAt,
        uint64 endAt,
        string calldata stubURI,
        string[3] calldata baseURIs,
        bool[3] calldata enabledForms
    ) external returns (uint16 seasonId);

    function setFormParams(
        uint16 seasonId,
        string[3] calldata baseURIs,
        bool[3] calldata enabledForms
    ) external;

    function getCurrentSeason() external view returns (Season memory);
    function isExist(uint16 seasonId) external view returns (bool);
    function isActiveSeason(uint16 seasonId) external view returns (bool);
    function isEnabledForm(
        uint16 seasonId,
        TokenForm tokenForm
    ) external view returns (bool);

    function getCurrentSeasonId() external view returns (uint16);
    function getSeason(
        uint16 seasonId
    )
        external
        view
        returns (
        bool exist,
        uint16 id,
        uint64 startAt,
        uint64 endAt,
        uint16 firstTokenId,
        uint16 lastTokenId,
        string memory stubURI,
        string[3] memory baseURIs,
        bool[3] memory enabledForms
    );

    function getTokenURI(
        uint16 seasonId,
        uint16 tokenId,
        TokenForm activeTokenForm
    ) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

// TEST 1

pragma solidity ^0.8.19;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {INAP} from "./interfaces/INAP.sol";
import {IPFPSeasons} from "./interfaces/IPFPSeasons.sol";
import {IUniswapV2Router02} from "../libs/uniswap-v2/contracts/interfaces/IUniswapV2Router02.sol";

contract NAP is 
    UUPSUpgradeable,
    OwnableUpgradeable,
    INAP
{
    IERC721 public pfpNft;
    IERC20 public b01;
    IERC20 public usdc;
    IUniswapV2Router02 public uniswapRouter;
    address public feeRecipient;

    // Exchange path for B01 -> USDC
    address[] public exchangePath;
    uint16 public deactivationFeePrecentage;

    uint public tokenPrice;

    /// @dev Interval duration in blocks
    uint64 public intervalDuration;
    uint64 public intervalDurationUpdatedAt;
    uint64 public intervalDurationUpdatedAtIndex;
    uint16 public maxDeactivationsPerInterval;

    mapping (uint64 => uint16) public deactivationsCountByInterval;

    bool public vestingActive;
    uint64 public vestingStartAt;
    uint64 public vestingEndAt;

    uint private lastRewardIndex;
    uint64 private lastRewardBlock;
    // uint private constant MULTIPLIER = 1;
    uint private constant MULTIPLIER = 1e18;

    mapping (uint16 => uint) private rewardIndexOf;

    function initialize(
        IERC721 pfpNft_,
        IERC20 b01_,
        IERC20 usdc_,
        IUniswapV2Router02 uniswapRouter_,
        uint tokenPrice_,
        address feeRecipient_,
        uint16 deactivationFeePrecentage_,
        uint16 maxDeactivationsPerInterval_
    )
        external
        initializer
    {
        __Ownable_init();

        pfpNft = pfpNft_;
        b01 = b01_;
        usdc = usdc_;
        uniswapRouter = uniswapRouter_;
        tokenPrice = tokenPrice_;
        feeRecipient = feeRecipient_;
        _setDeactivationFeePrecentage(deactivationFeePrecentage_);
        setMaxDeactivationsPerInterval(maxDeactivationsPerInterval_);
        setIntervalDuration(4320);  // ≈1 day in blocks

        exchangePath = new address[](2);
        exchangePath[0] = address(b01);
        exchangePath[1] = address(usdc);

        b01.approve(address(uniswapRouter), type(uint).max);
    }

    function activateTokens(uint16[] calldata tokenIds, address to) external {
        uint16 tokenIdsLength = uint16(tokenIds.length);
        uint totalActivationPrice = tokenPrice * tokenIdsLength;

        if (totalActivationPrice != 0) {
            b01.transferFrom(msg.sender, address(this), totalActivationPrice);
        }

        for (uint16 i; i < tokenIdsLength; i++) {
            pfpNft.transferFrom(address(this), to, tokenIds[i]);
        }

        emit ActivateTokens(tokenIds, totalActivationPrice);
    }

    /**
     * @dev See {INAP-deactivateTokens}.
     * 
     * Emits a {DeactivateTokens} event with the list of token IDs and total deactivation profit.
     * 
     * Requirements:
     * - Vesting period must not be active.
     * - The number of deactivations per current interval must not exceed the maximum allowed amount per interval.
     * - The contract must be authorized to transfer tokens from the message sender.
     * - The total deactivation profit must be greater than 0.
     */
    function deactivateTokens(uint16[] calldata tokenIds, address to) external returns (uint deactivationProfit) {
        if (vestingActive) {
            revert VestingPeriodActive();
        }

        uint16 tokenIdsLength = uint16(tokenIds.length);
        uint16 maxDeactivationsPerInterval_ = maxDeactivationsPerInterval;
        uint64 currentInterval = getCurrentInterval();
        uint16 currentDeactivationsCount = deactivationsCountByInterval[currentInterval] + tokenIdsLength;
        if (currentDeactivationsCount > maxDeactivationsPerInterval_) {
            revert MaxDeactivationAmountPerIntervalExceeded(currentInterval, maxDeactivationsPerInterval_, currentDeactivationsCount);
        }

        for (uint16 i; i < tokenIdsLength; i++) {
            pfpNft.transferFrom(msg.sender, address(this), tokenIds[i]);
        }

        uint totalDeactivationProfit = tokenPrice * tokenIdsLength;
        if (totalDeactivationProfit != 0) {
            uint deactivationFee = totalDeactivationProfit * deactivationFeePrecentage / 10000;
            deactivationsCountByInterval[currentInterval] = currentDeactivationsCount;
            deactivationProfit = totalDeactivationProfit - deactivationFee;

            b01.transfer(to, deactivationProfit);
            if (deactivationFee != 0) {
                uniswapRouter.swapExactTokensForTokens(
                    deactivationFee,
                    0,
                    exchangePath,
                    feeRecipient,
                    block.timestamp
                );
            }
        }

        emit DeactivateTokens(tokenIds, totalDeactivationProfit);
    }

    function claim(uint16[] calldata tokenIds, address to) external returns (uint claimAmount){
        if (!vestingActive) {
            revert VestingPeriodNotActive();
        }

        claimAmount = _claimRewards(tokenIds);
        if (claimAmount != 0) {
            b01.transfer(to, claimAmount);
        }
    
        emit Claim(tokenIds, claimAmount);
    }

    function activateVesting(uint64 newVestingEndAt) external onlyOwner {
        if (vestingActive) {
            revert VestingPeriodAlreadyActive();
        }

        vestingActive = true;
        vestingStartAt = uint64(block.number);
        lastRewardBlock = uint64(block.number);
        vestingEndAt = uint64(block.number);

        _setVestingEnd(newVestingEndAt);

        emit VestingActivated(uint64(block.number), vestingEndAt);
    }

    function setDeactivationFeePrecentage(uint16 newDeactivationFeePrecentage) external onlyOwner {
        _setDeactivationFeePrecentage(newDeactivationFeePrecentage);
    }

    function calculateClaimRewards(uint16[] calldata tokenIds) external view returns (uint[] memory rewards) {
        uint16 tokenIdsLength = uint16(tokenIds.length);

        rewards = new uint[](tokenIdsLength);
        if (!vestingActive) {
            return rewards;
        }

        uint rewardIndex = _calculateRewardIndex();
        for (uint16 i; i < tokenIdsLength; ++i) {
            rewards[i] = _calculateReward(tokenIds[i], rewardIndex);
        }
    }

    /**
     * @notice Calculates the reward per block.
     * @return rewardPerBlock The reward per block.
     */ 
    function calculateRewardPerBlock() external view returns (uint rewardPerBlock) {
        rewardPerBlock = _calculateRewardPerBlock() / MULTIPLIER;
    }

    function setMaxDeactivationsPerInterval(uint16 newMaxDeactivationsPerInterval) public onlyOwner {
        maxDeactivationsPerInterval = newMaxDeactivationsPerInterval;

        emit MaxDeactivationsPerIntervalUpdated(newMaxDeactivationsPerInterval);
    }

    function setIntervalDuration(uint64 newIntervalDuration) public onlyOwner {
        uint64 currentBlock = uint64(block.number);
        if (intervalDuration == 0) {
            intervalDurationUpdatedAtIndex = 0;
        } else {
            intervalDurationUpdatedAtIndex = getCurrentInterval() + 1;
        }
        intervalDurationUpdatedAt = currentBlock;
        intervalDuration = newIntervalDuration;

        emit IntervalDurationUpdated(newIntervalDuration, currentBlock);
    }

    function setVestingEnd(uint64 newVestingEndAt) public onlyOwner {
        if (!vestingActive) {
            revert VestingPeriodNotActive();
        }
        if (block.number >= vestingEndAt) {
            revert VestingPeriodAlreadyEnded();
        }
        _setVestingEnd(newVestingEndAt);
    }

    /// @dev Returns the current interval index.
    function getCurrentInterval() public view returns (uint64) {
        return (uint64(block.number) - intervalDurationUpdatedAt) / intervalDuration + intervalDurationUpdatedAtIndex;
    }

    function getAvailableDeactivationCount() public view returns (uint16) {
        uint16 maxDeactivationsPerInterval_ = maxDeactivationsPerInterval;
        uint64 currentInterval = getCurrentInterval();
        uint16 currentDeactivationsCount = deactivationsCountByInterval[currentInterval];
        if (currentDeactivationsCount >= maxDeactivationsPerInterval_) {
            return 0;
        }
        return maxDeactivationsPerInterval_ - currentDeactivationsCount;
    }

    function _setVestingEnd(uint64 newVestingEndAt) internal {
        if (newVestingEndAt <= block.number) {
            revert InvalidVestingEndAt(newVestingEndAt);
        }

        lastRewardIndex = _calculateRewardIndex();
    
        vestingEndAt = newVestingEndAt;
        lastRewardBlock = _getCurrentRewardBlock();

        emit VestingEndUpdated(newVestingEndAt);
    }

    function _setDeactivationFeePrecentage(uint16 newDeactivationFeePrecentage) internal {
        if (newDeactivationFeePrecentage > 10000) {
            revert InvalidDeactivationFeePrecentage(newDeactivationFeePrecentage);
        }
        deactivationFeePrecentage = newDeactivationFeePrecentage;

        emit DeactivationFeePrecentageUpdated(newDeactivationFeePrecentage);
    }

    function _claimRewards(uint16[] calldata tokenIds) private returns (uint totalReward) {
        uint16 tokenIdsLength = uint16(tokenIds.length);

        uint rewardIndex = _calculateRewardIndex();

        for (uint16 i; i < tokenIdsLength; ++i) {
            uint16 tokenId = tokenIds[i];
            if (pfpNft.ownerOf(tokenId) != msg.sender) {
                revert ClaimerIsNotTokenOwner(tokenId, msg.sender);
            }

            uint reward = _calculateReward(tokenId, rewardIndex);
            totalReward += reward;
            rewardIndexOf[tokenId] = rewardIndex;
        }
        // TODO: try to remove setting it. Mayble it should be only during setting vesting period end date
        // lastRewardIndex = rewardIndex;
        // lastRewardBlock = _getCurrentRewardBlock();
    }

    function _calculateRewardIndex() private view returns (uint rewardIndex) {
        uint rewardPerBlock = _calculateRewardPerBlock();
        uint64 rewardBlock = uint64(block.number);
        uint64 blocksSinceLastReward = rewardBlock - lastRewardBlock;
        uint reward = blocksSinceLastReward * rewardPerBlock;
        rewardIndex = reward + lastRewardIndex;
        uint maxRewardIndex = tokenPrice * MULTIPLIER;
        if (rewardIndex > maxRewardIndex) {
            rewardIndex = maxRewardIndex;
        }
    }

    /// @notice Calculates the reward per block.
    /// @return rewardPerBlock The reward per block.
    /// @dev It returns multiplied by the MULTIPLIER value
    function _calculateRewardPerBlock() private view returns (uint rewardPerBlock) {
        // TODO: try to use vestingEndUpdatedAt instead of lastRewardBlock
        uint64 remainingDuration = uint64(vestingEndAt - lastRewardBlock);
        if (remainingDuration == 0) {
            return 0;
        }
        rewardPerBlock = (tokenPrice * MULTIPLIER - lastRewardIndex) / remainingDuration;
    }

    function _calculateReward(uint16 tokenId, uint rewardIndex) private view returns (uint) {
        return ((rewardIndex - rewardIndexOf[tokenId]) / MULTIPLIER);
    }

    function _getCurrentRewardBlock() private view returns (uint64) {
        return block.number > vestingEndAt ? vestingEndAt : uint64(block.number);
    }

    function _authorizeUpgrade(address _newImplementation) internal override onlyOwner {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}