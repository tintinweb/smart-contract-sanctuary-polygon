// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

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
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        _transferOwnership(_msgSender());
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
contract ERC20 is Context, IERC20, IERC20Metadata {
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
    constructor(string memory name_, string memory symbol_) {
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
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
        }
        _balances[to] += amount;

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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
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
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
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

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import 'lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol';

/**
 * @notice IAdapter
 * @author Atlendis Labs
 * @notice Interface Adapter contract
 *         An Adapter is associated to a yield provider.
 *         It implement the logic necessary to deposit, withdraw and compute rewards
 *         the custodian will get when managing its holdings
 */
interface IAdapter is IERC165 {
    /**
     * @notice Verifies that the yield provider associated with the adapter supports the custodian token
     * @return _ True if the token is supported, false otherwise
     **/
    function supportsToken(address yieldProvider) external returns (bool);

    /**
     * @notice Deposit tokens to the yield provider
     * @param amount Amount to deposit
     * @return success Success boolean, required as additional safely for delegate call handling
     **/
    function deposit(uint256 amount) external returns (bool success);

    /**
     * @notice Withdraw tokens from the yield provider
     * @param amount Amount to withdraw
     * @return success Success boolean, required as additional safely for delegate call handling
     **/
    function withdraw(uint256 amount) external returns (bool success);

    /**
     * @notice Withdraws all deposits from the yield provider
     * Only called when switching yield providers
     * @return success Success boolean, required as additional safely for delegate call handling
     * @return withdrawnAmount Withdrawn amount
     **/
    function empty() external returns (bool success, uint256 withdrawnAmount);

    /**
     * @notice Updates the pending rewards accrued by the deposits
     * @return _ The collected amount of rewards
     **/
    function collectRewards() external returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import 'lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';
import '../roles-manager/interfaces/IRolesManager.sol';

/**
 * @title CustodianStorage
 * @author Atlendis Labs
 */
abstract contract CustodianStorage {
    // constants
    uint256 public constant WAD = 1e18;
    uint256 public constant RAY = 1e27;

    // addresses
    ERC20 public token; // Custodian token - not updatable
    address public pool; // Pool address - not updatable
    IRolesManager public rolesManager; // Roles manager
    address public adapter; // Current adapter
    address public yieldProvider; // Current yield provider
    address public rewardsOperator; // Current authorised address to withdraw rewards

    // balances
    uint256 public depositedBalance; // Original token balance deposited to custodian
    uint256 public pendingRewards; // Yield provider rewards to be withdrawn
    uint256 public generatedRewards; // Yield provider rewards to be withdrawn

    // below variable usage are yield provider specific
    uint256 public yieldProviderBalance; // Yield provider specific balance
    uint256 public lastYieldFactor; // Yield provider specific ratio to be used to compute rewards
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../../interfaces/ITimelock.sol';

struct CustodianTimelock {
    uint256 readyTimestamp;
    address adapter;
    address yieldProvider;
    uint256 executedAt;
}

/**
 * @title CustodianTimelockLogic
 * @author AtlendisLabs
 * @dev Contains the utilities methods associated to the manipulation of the Timelock for the custodian
 */
library CustodianTimelockLogic {
    /**
     * @dev Initiate the timelock
     * @param timelock Timelock
     * @param delay Delay in seconds
     * @param adapter New adapter address
     * @param yieldProvider New yield provider address
     */
    function initiate(
        CustodianTimelock storage timelock,
        uint256 delay,
        address adapter,
        address yieldProvider
    ) internal {
        if (timelock.readyTimestamp != 0 && timelock.executedAt == 0) revert ITimelock.TIMELOCK_ALREADY_INITIATED();
        timelock.readyTimestamp = block.timestamp + delay;
        timelock.adapter = adapter;
        timelock.yieldProvider = yieldProvider;
        timelock.executedAt = 0;
    }

    /**
     * @dev Execute the timelock
     * @param timelock Timelock
     */
    function execute(CustodianTimelock storage timelock) internal {
        if (timelock.readyTimestamp == 0) revert ITimelock.TIMELOCK_INEXISTANT();
        if (timelock.executedAt > 0) revert ITimelock.TIMELOCK_ALREADY_EXECUTED();
        if (block.timestamp < timelock.readyTimestamp) revert ITimelock.TIMELOCK_NOT_READY();
        timelock.executedAt = block.timestamp;
    }

    /**
     * @dev Cancel the timelock
     * @param timelock Timelock
     */
    function cancel(CustodianTimelock storage timelock) internal {
        if (timelock.readyTimestamp == 0) revert ITimelock.TIMELOCK_INEXISTANT();
        if (timelock.executedAt > 0) revert ITimelock.TIMELOCK_ALREADY_EXECUTED();
        delete timelock.readyTimestamp;
        delete timelock.adapter;
        delete timelock.yieldProvider;
        delete timelock.executedAt;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import 'lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol';
import '../roles-manager/interfaces/IManaged.sol';
import './CustodianTimelockLogic.sol';
import '../../interfaces/ITimelock.sol';

/**
 * @notice IPoolCustodian
 * @author Atlendis Labs
 * @notice Interface of the Custodian contract
 *         A custodian contract is associated to a product contract.
 *         It receives funds by the associated product contract.
 *         A yield strategy is chosen in order to generate rewards based on the deposited funds.
 */
interface IPoolCustodian is IERC165, ITimelock, IManaged {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Thrown when an internal delegate call fails
     */
    error DELEGATE_CALL_FAIL();

    /**
     * @notice Thrown when given yield provider does not support the token
     */
    error TOKEN_NOT_SUPPORTED();

    /**
     * @notice Thrown when the given address does not support the adapter interface
     */
    error ADAPTER_NOT_SUPPORTED();

    /**
     * @notice Thrown when sender is not the setup pool address
     * @param sender Sender address
     * @param pool Pool address
     */
    error ONLY_POOL(address sender, address pool);

    /**
     * @notice Thrown when sender is not the setup pool address
     * @param sender Sender address
     * @param rewardsOperator Rewards operator address
     */
    error ONLY_REWARDS_OPERATOR(address sender, address rewardsOperator);

    /**
     * @notice Thrown when trying to initialize an already initialized pool
     * @param pool Address of the already initialized pool
     */
    error POOL_ALREADY_INITIALIZED(address pool);

    /**
     * @notice Thrown when trying to withdraw an amount of deposits higher than what is available
     */
    error NOT_ENOUGH_DEPOSITS();

    /**
     * @notice Thrown when trying to withdraw an amount of rewards higher than what is available
     */
    error NOT_ENOUGH_REWARDS();

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Emitted when tokens have been deposited to the custodian using current adapter and yield provider
     * @param amount Deposited amount of tokens
     * @param adapter Address of the adapter
     * @param yieldProvider Address of the yield provider
     **/
    event Deposit(uint256 amount, address from, address adapter, address yieldProvider);

    /**
     * @notice Emitted when tokens have been withdrawn from the custodian using current adapter and yield provider
     * @param amount Withdrawn amount of tokens
     * @param to Recipient address
     * @param adapter Address of the adapter
     * @param yieldProvider Address of the yield provider
     **/
    event Withdraw(uint256 amount, address to, address adapter, address yieldProvider);

    /**
     * @notice Emitted when the yield provider has been switched
     * @param adapter Address of the new adapter
     * @param yieldProvider Address of the new yield provider
     * @param delay Delay for the timelock to be executed
     **/
    event YieldProviderSwitchProcedureStarted(address adapter, address yieldProvider, uint256 delay);

    /**
     * @notice Emitted when the rewards have been collected
     * @param amount Amount of collected rewards
     **/
    event RewardsCollected(uint256 amount);

    /**
     * @notice Emitted when rewards have been withdrawn
     * @param amount Amount of withdrawn rewards
     **/
    event RewardsWithdrawn(uint256 amount);

    /**
     * @notice Emitted when pool has been initialized
     * @param pool Address of the pool
     */
    event PoolInitialized(address pool);

    /**
     * @notice Emitted when rewards operator has been updated
     * @param rewardsOperator Address of the rewards operator
     */
    event RewardsOperatorUpdated(address rewardsOperator);

    /*//////////////////////////////////////////////////////////////
                             VIEW METHODS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Retrieve the current stored amount of rewards generated by the custodian
     * @return rewards Amount of rewards
     */
    function getRewards() external view returns (uint256 rewards);

    /**
     * @notice Retrieve the all time amount of generated rewards by the custodian
     * @return generatedRewards All time amount of rewards
     */
    function getGeneratedRewards() external view returns (uint256 generatedRewards);

    /**
     * @notice Retrieve the decimals of the underlying asset
     * @return decimals Decimals of the underlying asset
     */
    function getAssetDecimals() external view returns (uint256 decimals);

    /**
     * @notice Returns the token address of the custodian and the decimals number
     * @return token Token address
     * @return decimals Decimals number
     */
    function getTokenConfiguration() external view returns (address token, uint256 decimals);

    /**
     * @notice Retrieve the current timelock
     * @return timelock The current timelock, may be empty
     */
    function getTimelock() external view returns (CustodianTimelock memory);

    /*//////////////////////////////////////////////////////////////
                          DEPOSIT MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deposit tokens to the yield provider
     * Collects pending rewards before depositing
     * @param amount Amount to deposit
     *
     * Emits a {Deposit} event
     **/
    function deposit(uint256 amount, address from) external;

    /**
     * @notice Exceptional deposit from the governance directly, bypassing the underlying pool
     * Collects pending rewards before depositing
     * @param amount Amount to deposit
     *
     * Emits a {Deposit} event
     **/
    function exceptionalDeposit(uint256 amount) external;

    /**
     * @notice Withdraw tokens from the yield provider
     * Collects pending rewards before withdrawing
     * @param amount Amount to withdraw
     * @param to Recipient address
     *
     * Emits a {Withdraw} event
     **/
    function withdraw(uint256 amount, address to) external;

    /**
     * @notice Withdraw all the deposited tokens from the yield provider
     * Collects pending rewards before withdrawing
     * @param to Recipient address
     * @return withdrawnAmount The withdrawn amount
     *
     * Emits a {Withdraw} event
     **/
    function withdrawAllDeposits(address to) external returns (uint256 withdrawnAmount);

    /*//////////////////////////////////////////////////////////////
                          REWARDS MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Withdraw an amount of rewards
     * @param amount The amount of rewards to be withdrawn
     * @param to Address that will receive the rewards
     *
     * Emits a {RewardsWithdrawn} event
     **/
    function withdrawRewards(uint256 amount, address to) external;

    /**
     * @notice Updates the pending rewards accrued by the deposits
     * @return generatedRewards The all time amount of generated rewards by the custodian
     *
     * Emits a {RewardsCollected} event
     **/
    function collectRewards() external returns (uint256);

    /*//////////////////////////////////////////////////////////////
                      YIELD PROVIDER MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Start a procedure for changing the yield provider used by the custodian
     * @param newAdapter New adapter used to manage yield provider interaction
     * @param newYieldProvider New yield provider address
     * @param delay Delay for the timlelock
     *
     * Emits a {YieldProviderSwitchProcedureStarted} event
     **/
    function startSwitchYieldProviderProcedure(
        address newAdapter,
        address newYieldProvider,
        uint256 delay
    ) external;

    /*//////////////////////////////////////////////////////////////
                          GOVERNANCE METHODS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initialize and block the address of the pool for the custodian
     * @param pool Address of the pool
     *
     * Emits a {PoolInitialized} event
     */
    function initializePool(address pool) external;

    /**
     * @notice Update the rewards operator address
     * @param rewardsOperator Address of the rewards operator
     *
     * Emits a {RewardsOperatorUpdated} event
     */
    function updateRewardsOperator(address rewardsOperator) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import 'lib/openzeppelin-contracts/contracts/access/AccessControl.sol';
import 'lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import 'lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol';

import '../../interfaces/ITimelock.sol';
import './adapters/IAdapter.sol';
import '../custodian/IPoolCustodian.sol';
import './CustodianStorage.sol';

/**
 * @title PoolCustodian
 * @author Atlendis Labs
 * @dev CustodianStorage should be imported first, storage layout is important
 * for adapters delegatecall to work as intended
 */
contract PoolCustodian is ERC165, IPoolCustodian, CustodianStorage {
    /*//////////////////////////////////////////////////////////////
                              LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using SafeERC20 for ERC20;
    using CustodianTimelockLogic for CustodianTimelock;

    /*//////////////////////////////////////////////////////////////
                               STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public constant SWITCH_YP_MIN_TIMELOCK_DELAY = 10 days;

    CustodianTimelock private timelock;

    /*//////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Constructor
     * @param _rolesManager Roles manager contract
     * @param _token ERC20 contract of the token
     * @param _adapter Address of the adapter
     * @param _yieldProvider Address of the yield provider
     */
    constructor(
        IRolesManager _rolesManager,
        ERC20 _token,
        address _adapter,
        address _yieldProvider
    ) {
        token = _token;
        rolesManager = _rolesManager;
        adapter = _adapter;
        yieldProvider = _yieldProvider;

        if (!IAdapter(_adapter).supportsInterface(type(IAdapter).interfaceId)) revert ADAPTER_NOT_SUPPORTED();
        bytes memory returnData = adapterDelegateCall(
            _adapter,
            abi.encodeWithSignature('supportsToken(address)', _yieldProvider)
        );
        if (!abi.decode(returnData, (bool))) revert TOKEN_NOT_SUPPORTED();
    }

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Restrict the sender to governance only
     */
    modifier onlyGovernance() {
        if (!rolesManager.isGovernance(msg.sender)) revert ONLY_GOVERNANCE();
        _;
    }

    /**
     * @dev Restrict the sender to pool only
     */
    modifier onlyPool() {
        if (msg.sender != pool) revert ONLY_POOL(msg.sender, pool);
        _;
    }

    /*//////////////////////////////////////////////////////////////
                             VIEW METHODS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IPoolCustodian
     */
    function getAssetDecimals() external view returns (uint256) {
        return token.decimals();
    }

    /**
     * @inheritdoc IPoolCustodian
     */
    function getRewards() external view returns (uint256) {
        return pendingRewards;
    }

    /**
     * @inheritdoc IPoolCustodian
     */
    function getGeneratedRewards() external view returns (uint256) {
        return generatedRewards;
    }

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IPoolCustodian).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IManaged
     */
    function getRolesManager() public view returns (IRolesManager) {
        return rolesManager;
    }

    /**
     * @inheritdoc IPoolCustodian
     */
    function getTokenConfiguration() public view returns (address, uint256) {
        return (address(token), token.decimals());
    }

    /*//////////////////////////////////////////////////////////////
                          DEPOSIT MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IPoolCustodian
     */
    function deposit(uint256 amount, address from) public onlyPool {
        _deposit(amount, from);
    }

    /**
     * @inheritdoc IPoolCustodian
     */
    function exceptionalDeposit(uint256 amount) external onlyGovernance {
        _deposit(amount, msg.sender);
    }

    /**
     * @inheritdoc IPoolCustodian
     */
    function withdraw(uint256 amount, address to) public onlyPool {
        if (amount > depositedBalance) revert NOT_ENOUGH_DEPOSITS();

        collectRewards();

        depositedBalance -= amount;

        bytes memory returnData = adapterDelegateCall(adapter, abi.encodeWithSignature('withdraw(uint256)', amount));
        if (!abi.decode(returnData, (bool))) revert DELEGATE_CALL_FAIL();
        token.safeTransfer(to, amount);

        emit Withdraw(amount, to, adapter, yieldProvider);
    }

    /**
     * @inheritdoc IPoolCustodian
     */
    function withdrawAllDeposits(address to) public onlyPool returns (uint256) {
        collectRewards();

        uint256 amount = depositedBalance;

        depositedBalance = 0;

        bytes memory returnData = adapterDelegateCall(adapter, abi.encodeWithSignature('withdraw(uint256)', amount));
        if (!abi.decode(returnData, (bool))) revert DELEGATE_CALL_FAIL();
        token.safeTransfer(to, amount);

        emit Withdraw(amount, to, adapter, yieldProvider);

        return amount;
    }

    /*//////////////////////////////////////////////////////////////
                          REWARDS MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IPoolCustodian
     */
    function collectRewards() public returns (uint256) {
        bytes memory returnData = adapterDelegateCall(
            adapter,
            abi.encodeWithSignature('collectRewards()', yieldProvider)
        );
        uint256 collectedAmount = abi.decode(returnData, (uint256));

        pendingRewards += collectedAmount;
        generatedRewards += collectedAmount;

        emit RewardsCollected(collectedAmount);

        return generatedRewards;
    }

    /**
     * @inheritdoc IPoolCustodian
     */
    function withdrawRewards(uint256 amount, address to) external {
        if (msg.sender != rewardsOperator) revert ONLY_REWARDS_OPERATOR(msg.sender, rewardsOperator);
        collectRewards();

        if (amount > pendingRewards) revert NOT_ENOUGH_REWARDS();

        pendingRewards -= amount;

        bytes memory returnData = adapterDelegateCall(adapter, abi.encodeWithSignature('withdraw(uint256)', amount));
        if (!abi.decode(returnData, (bool))) revert DELEGATE_CALL_FAIL();

        token.safeTransfer(to, amount);

        emit RewardsWithdrawn(amount);
    }

    /*//////////////////////////////////////////////////////////////
                      YIELD PROVIDER MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IPoolCustodian
     */
    function startSwitchYieldProviderProcedure(
        address newAdapter,
        address newYieldProvider,
        uint256 delay
    ) external onlyGovernance {
        if (delay < SWITCH_YP_MIN_TIMELOCK_DELAY) revert TIMELOCK_DELAY_TOO_SMALL();

        if (!IAdapter(newAdapter).supportsInterface(type(IAdapter).interfaceId)) revert ADAPTER_NOT_SUPPORTED();
        bytes memory returnData = adapterDelegateCall(
            newAdapter,
            abi.encodeWithSignature('supportsToken(address)', newYieldProvider)
        );
        if (!abi.decode(returnData, (bool))) revert TOKEN_NOT_SUPPORTED();

        timelock.initiate(delay, newAdapter, newYieldProvider);

        emit YieldProviderSwitchProcedureStarted(newAdapter, newYieldProvider, delay);
    }

    /**
     * @inheritdoc ITimelock
     */
    function executeTimelock() external onlyGovernance {
        timelock.execute();

        collectRewards();
        bytes memory returnData = adapterDelegateCall(adapter, abi.encodeWithSignature('empty()'));
        if (!abi.decode(returnData, (bool))) revert DELEGATE_CALL_FAIL();

        uint256 balanceToSwitch = token.balanceOf(address(this));
        adapter = timelock.adapter;
        yieldProvider = timelock.yieldProvider;

        collectRewards();
        returnData = adapterDelegateCall(adapter, abi.encodeWithSignature('deposit(uint256)', balanceToSwitch));
        if (!abi.decode(returnData, (bool))) revert DELEGATE_CALL_FAIL();

        emit TimelockExecuted(balanceToSwitch);
    }

    /**
     * @inheritdoc ITimelock
     */
    function cancelTimelock() external onlyGovernance {
        timelock.cancel();
        emit TimelockCancelled();
    }

    /**
     * @inheritdoc IPoolCustodian
     */
    function getTimelock() external view returns (CustodianTimelock memory) {
        return timelock;
    }

    /*//////////////////////////////////////////////////////////////
                          GOVERNANCE METHODS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IManaged
     */
    function updateRolesManager(address _rolesManager) public onlyGovernance {
        rolesManager = IRolesManager(_rolesManager);
        emit RolesManagerUpdated(address(rolesManager));
    }

    /**
     * @inheritdoc IPoolCustodian
     */
    function initializePool(address _pool) public onlyGovernance {
        if (pool != address(0)) revert POOL_ALREADY_INITIALIZED(pool);
        pool = _pool;
        emit PoolInitialized(pool);
    }

    /**
     * @inheritdoc IPoolCustodian
     */
    function updateRewardsOperator(address _rewardsOperator) public onlyGovernance {
        rewardsOperator = _rewardsOperator;
        emit RewardsOperatorUpdated(rewardsOperator);
    }

    /*//////////////////////////////////////////////////////////////
                           PRIVATE METHODS
    //////////////////////////////////////////////////////////////*/

    function adapterDelegateCall(address _adapter, bytes memory data) private returns (bytes memory) {
        (bool success, bytes memory returnData) = _adapter.delegatecall(data);
        if (!success || returnData.length == 0) revert DELEGATE_CALL_FAIL();
        return returnData;
    }

    function _deposit(uint256 amount, address from) private {
        collectRewards();

        depositedBalance += amount;

        token.safeTransferFrom(from, address(this), amount);
        bytes memory returnData = adapterDelegateCall(adapter, abi.encodeWithSignature('deposit(uint256)', amount));
        if (!abi.decode(returnData, (bool))) revert DELEGATE_CALL_FAIL();

        emit Deposit(amount, from, adapter, yieldProvider);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

/**
 * @notice IFeesController
 * @author Atlendis Labs
 * Contract responsible for gathering protocol fees from users
 * actions and making it available for governance to withdraw
 * Is called from the pools contracts directly
 */
interface IFeesController {
    /*//////////////////////////////////////////////////////////////
                             EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Emitted when management fees are registered
     * @param token Token address of the fees taken
     * @param amount Amount of fees taken
     **/
    event ManagementFeesRegistered(address token, uint256 amount);

    /**
     * @notice Emitted when exit fees are registered
     * @param token Token address of the fees taken
     * @param amount Amount of fees taken
     * @param rate Exit fees rate
     **/
    event ExitFeesRegistered(address token, uint256 amount, uint256 rate);

    /**
     * @notice Emitted when borrowing fees are registered
     * @param token Token address of the fees taken
     * @param amount Amount of fees taken
     **/
    event BorrowingFeesRegistered(address token, uint256 amount);

    /**
     * @notice Emitted when repayment fees are registered
     * @param token Token address of the fees taken
     * @param amount Amount of fees taken
     **/
    event RepaymentFeesRegistered(address token, uint256 amount);

    /**
     * @notice Emitted when fees are withdrawn from the fee collector
     * @param token Token address of the fees taken
     * @param amount Amount of fees taken
     * @param to Recipient address of the fees
     **/
    event FeesWithdrawn(address token, uint256 amount, address to);

    /**
     * @notice Emitted when the due fees are pulled from the pool
     * @param token Token address of the fees
     * @param amount Amount of due fees
     */
    event DuesFeesPulled(address token, uint256 amount);

    /**
     * @notice Emitted when pool is initialized
     * @param managedPool Address of the managed pool
     */
    event PoolInitialized(address managedPool);

    /*//////////////////////////////////////////////////////////////
                             VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the repayment fee rate
     * @dev Necessary for RCL pool new epochs amounts accounting
     * @return repaymentFeesRate Amount of fees taken at repayment
     **/
    function getRepaymentFeesRate() external view returns (uint256 repaymentFeesRate);

    /**
     * @notice Get the total amount of fees currently held by the contract for the target token
     * @param token Address of the token for which total fees are queried
     * @return fees Amount of fee held by the contract
     **/
    function getTotalFees(address token) external view returns (uint256 fees);

    /**
     * @notice Get the amount of fees currently held by the pool contract for the target token ready to be withdrawn to the Fees Controller
     * @param token Address of the token for which total fees are queried
     * @return fees Amount of fee held by the pool contract
     **/
    function getDueFees(address token) external view returns (uint256 fees);

    /**
     * @notice Get the managed pool contract address
     * @return managedPool The managed pool contract address
     */
    function getManagedPool() external view returns (address managedPool);

    /*//////////////////////////////////////////////////////////////
                             EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Register fees on lender position withdrawal
     * @param amount Withdrawn amount subjected to fees
     * @return fees Amount of fees taken in the pool token for pool accounting
     *
     * Emits a {ManagementFeesRegistered} event
     **/
    function registerManagementFees(uint256 amount) external returns (uint256 fees);

    /**
     * @notice Register fees on exit
     * @param amount Exited amount subjected to fees
     * @return fees Amount of fees taken in the pool token for pool accounting
     *
     * Emits a {ExitFeesRegistered} event
     **/
    function registerExitFees(uint256 amount, uint256 timeUntilMaturity) external returns (uint256 fees);

    /**
     * @notice Register fees on borrow
     * @param amount Borrowed amount subjected to fees
     * @return fees Amount of fees taken in the pool token for pool accounting
     *
     * Emits a {BorrowingFeesRegistered} event
     **/
    function registerBorrowingFees(uint256 amount) external returns (uint256 fees);

    /**
     * @notice Register fees on repayment
     * @param amount Repaid interests subjected to fees
     * @return fees Amount of fees taken in the pool token for pool accounting
     *
     * Emits a {RepaymentFeesRegistered} event
     **/
    function registerRepaymentFees(uint256 amount) external returns (uint256 fees);

    /**
     * @notice Pull dues fees from the pool
     * @param token Address of the token for which the fees are pulled
     *
     * Emits a {DuesFeesPulled} event
     */
    function pullDueFees(address token) external;

    /**
     * @notice Allows the contract owner to withdraw accumulated fees
     * @param token Address of the token for which fees are withdrawn
     * @param amount Amount of fees to withdraw
     * @param to Recipient address of the witdrawn fees
     *
     * Emits a {FeesWithdrawn} event
     **/
    function withdrawFees(
        address token,
        uint256 amount,
        address to
    ) external;

    /**
     * @notice Initialize the managed pool
     * @param managedPool Address of the managed pool
     *
     * Emits a {PoolInitialized} event
     */
    function initializePool(address managedPool) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import 'lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';
import 'lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';

import '../custodian/IPoolCustodian.sol';
import '../../interfaces/IPool.sol';
import '../../libraries/FixedPointMathLib.sol';
import '../roles-manager/Managed.sol';
import './IFeesController.sol';

/**
 * @title PoolTokenFeesController
 * @author Atlendis Labs
 * Contract to gather fees from user actions in pools
 * Allows the contract owner to withdraw fees
 * Simple fee rules, applies a rate to the input amount
 * No introduction of third party fee rules, only takes fees in the pool token kind
 * Fees are held in the pool custodian for the owner to claim
 */
contract PoolTokenFeesController is IFeesController, Managed {
    using FixedPointMathLib for uint256;
    using SafeERC20 for ERC20;

    /*//////////////////////////////////////////////////////////////
                             ERRORS
    //////////////////////////////////////////////////////////////*/

    error FC_ONLY_POOL(); // Function can only be called by the pool
    error FC_POOL_ALREADY_INITIALIZED(); // Function can only be called when the pool has not been initialized

    /*//////////////////////////////////////////////////////////////
                             STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal totalFees;
    uint256 internal dueFees;

    uint256 public constant ONE = 1e18; // precision of the fees rates

    uint256 public immutable MANAGEMENT_FEES_RATE;
    uint256 public immutable EXIT_FEES_INFLECTION_THRESHOLD;
    uint256 public immutable EXIT_FEES_MIN_RATE;
    uint256 public immutable EXIT_FEES_INFLEXION_RATE;
    uint256 public immutable EXIT_FEES_MAX_RATE;
    uint256 public immutable BORROWING_FEES_RATE;
    uint256 public immutable REPAYMENT_FEES_RATE;

    // The state variables below are using immutable styling as they are initialized once
    IPool public POOL;
    address public TOKEN;
    uint256 public LOAN_DURATION;

    /**
     * @dev Constructor
     * @param rolesManager Roles manager contract
     * @param managementFeesRate fee rate taken at lender withdraw
     * @param exitFeesInflectionThreshold result of timeUntilMaturity / loanDuration after which exit fee rate slope changes
     * @param exitFeesMinRate minimum fee rate taken at position exit
     * @param exitFeesInflectionRate fee rate taken at position exit when inflection threshold is reached
     * @param exitFeesMaxRate max fee rate taken at position exit
     * @param borrowingFeesRate fee rate taken at borrow time
     * @param repaymentFeesRate fee rate taken at repay time
     **/
    constructor(
        IRolesManager rolesManager,
        uint256 managementFeesRate,
        uint256 exitFeesInflectionThreshold,
        uint256 exitFeesMinRate,
        uint256 exitFeesInflectionRate,
        uint256 exitFeesMaxRate,
        uint256 borrowingFeesRate,
        uint256 repaymentFeesRate
    ) Managed(address(rolesManager)) {
        MANAGEMENT_FEES_RATE = managementFeesRate;
        EXIT_FEES_INFLECTION_THRESHOLD = exitFeesInflectionThreshold;
        EXIT_FEES_MIN_RATE = exitFeesMinRate;
        EXIT_FEES_INFLEXION_RATE = exitFeesInflectionRate;
        EXIT_FEES_MAX_RATE = exitFeesMaxRate;
        BORROWING_FEES_RATE = borrowingFeesRate;
        REPAYMENT_FEES_RATE = repaymentFeesRate;
        FixedPointMathLib.setDenominator(ONE);
    }

    /*//////////////////////////////////////////////////////////////
                             VIEW METHODS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IFeesController
     */
    function getRepaymentFeesRate() external view returns (uint256 repaymentFeesRate) {
        repaymentFeesRate = REPAYMENT_FEES_RATE;
    }

    /**
     * @dev Restrict the sender to pool only
     */
    modifier onlyPool() {
        if (msg.sender != address(POOL)) revert FC_ONLY_POOL();
        _;
    }

    /**
     * @inheritdoc IFeesController
     */
    function getTotalFees(address) external view returns (uint256 fees) {
        fees = totalFees;
    }

    /**
     * @inheritdoc IFeesController
     */
    function getDueFees(address) external view returns (uint256 fees) {
        fees = dueFees;
    }

    /**
     * @inheritdoc IFeesController
     */
    function getManagedPool() external view returns (address managedPool) {
        return address(POOL);
    }

    /*//////////////////////////////////////////////////////////////
                             FEES REGISTRATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IFeesController
     */
    function registerManagementFees(uint256 amount) external onlyPool returns (uint256 fees) {
        fees = amount.mul(MANAGEMENT_FEES_RATE);
        dueFees += fees;
        totalFees += fees;

        emit ManagementFeesRegistered(TOKEN, fees);
    }

    /**
     * @inheritdoc IFeesController
     */
    function registerExitFees(uint256 amount, uint256 timeUntilMaturity) external onlyPool returns (uint256 fees) {
        uint256 loanAdvancement = (ONE * timeUntilMaturity) / LOAN_DURATION;
        uint256 actualRate = 0;
        if (EXIT_FEES_INFLECTION_THRESHOLD != 0) {
            if (loanAdvancement > EXIT_FEES_INFLECTION_THRESHOLD) {
                actualRate =
                    EXIT_FEES_INFLEXION_RATE -
                    (EXIT_FEES_INFLEXION_RATE - EXIT_FEES_MIN_RATE)
                        .mul(loanAdvancement - EXIT_FEES_INFLECTION_THRESHOLD)
                        .div(EXIT_FEES_INFLECTION_THRESHOLD);
            } else {
                actualRate =
                    EXIT_FEES_MAX_RATE -
                    (EXIT_FEES_MAX_RATE - EXIT_FEES_INFLEXION_RATE).mul(loanAdvancement).div(
                        EXIT_FEES_INFLECTION_THRESHOLD
                    );
            }
        }
        fees = amount.mul(actualRate);
        dueFees += fees;
        totalFees += fees;

        emit ExitFeesRegistered(TOKEN, fees, actualRate);
    }

    /**
     * @inheritdoc IFeesController
     */
    function registerBorrowingFees(uint256 amount) external onlyPool returns (uint256 fees) {
        fees = amount.mul(BORROWING_FEES_RATE);
        dueFees += fees;
        totalFees += fees;

        emit BorrowingFeesRegistered(TOKEN, fees);
    }

    /**
     * @inheritdoc IFeesController
     */
    function registerRepaymentFees(uint256 amount) external onlyPool returns (uint256 fees) {
        fees = amount.mul(REPAYMENT_FEES_RATE);
        dueFees += fees;
        totalFees += fees;

        emit RepaymentFeesRegistered(TOKEN, fees);
    }

    /**
     * @inheritdoc IFeesController
     */
    function pullDueFees(address) external onlyPool {
        uint256 fees = dueFees;

        dueFees = 0;

        ERC20(TOKEN).safeTransferFrom(address(POOL), address(this), fees);

        emit DuesFeesPulled(TOKEN, fees);
    }

    /*//////////////////////////////////////////////////////////////
                             FEES WITHDRAWAL
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IFeesController
     */
    function withdrawFees(
        address,
        uint256 amount,
        address to
    ) external onlyGovernance {
        if (amount == type(uint256).max) amount = totalFees;
        totalFees -= amount;
        ERC20(TOKEN).safeTransfer(to, amount);

        emit FeesWithdrawn(TOKEN, amount, to);
    }

    /*//////////////////////////////////////////////////////////////
                              GOVERNANCE
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IFeesController
     */
    function initializePool(address managedPool) public onlyGovernance {
        if (address(POOL) != address(0)) revert FC_POOL_ALREADY_INITIALIZED();

        POOL = IPool(managedPool);
        (TOKEN, ) = IPoolCustodian(POOL.CUSTODIAN()).getTokenConfiguration();
        LOAN_DURATION = POOL.LOAN_DURATION();

        emit PoolInitialized(managedPool);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import 'lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';
import 'lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import 'lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol';

import '../../interfaces/IPool.sol';
import '../../libraries/FixedPointMathLib.sol';
import '../custodian/IPoolCustodian.sol';
import '../roles-manager/Managed.sol';
import './INonStandardRepaymentModule.sol';

/**
 * @title BaseNonStandardRepaymentModule
 * @author Atlendis Labs
 * Contract handling the repayment cases not supported by the pool
 * Such cases can be early repays, partial repays or defaults for example
 * Instances of this contract, when integrated with the pools, will typically
 * interrupt all actions possible on the pool, and accept position NFTs in
 * exchange for partial repayment as well as a debt NFT.
 * Follow up interactions with the debt NFT are not part of this contract scope.
 *
 * Leaves the {withdraw} function not implemented, as its implementation will heavily rely on the
 * business choices made during the compensation process
 */
abstract contract BaseNonStandardRepaymentModule is INonStandardRepaymentModule, Managed, ERC721 {
    using FixedPointMathLib for uint256;
    using SafeERC20 for ERC20;

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    IPool public POOL;
    ERC20 public TOKEN;

    ModuleStatus public status = ModuleStatus.NOT_INITIALIZED;
    uint256 public totalRepaidAmount;
    uint256 public remainingRepaidAmount;

    mapping(uint256 => uint256) public debts;
    mapping(address => bool) public debtTokenRecipients;

    constructor(
        string memory name,
        string memory symbol,
        address _rolesManager
    ) ERC721(name, symbol) Managed(_rolesManager) {}

    /*//////////////////////////////////////////////////////////////
                                FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function initialize(uint256 amount) public {
        if (status != ModuleStatus.NOT_INITIALIZED) revert NSR_WRONG_PHASE();

        POOL = IPool(msg.sender);
        IPoolCustodian custodian = IPoolCustodian(POOL.CUSTODIAN());
        (address token, uint256 decimals) = custodian.getTokenConfiguration();
        TOKEN = ERC20(token);
        FixedPointMathLib.setDenominator(10**decimals);
        status = ModuleStatus.NOT_INITIATED;

        emit Initialized(msg.sender, amount);
    }

    function initiateEarlyRepay(uint256 amount) public onlyBorrower {
        if (block.timestamp > POOL.getMaturity()) revert NSR_EARLY_REPAY_AFTER_MATURITY();
        if (status != ModuleStatus.NOT_INITIATED) revert NSR_WRONG_PHASE();

        uint256 totalBorrowed = POOL.totalBorrowed();
        uint256 accruals = POOL.getCurrentAccruals();
        if (amount < totalBorrowed + accruals) revert NSR_AMOUNT_TOO_LOW_EARLY_REPAY();

        totalRepaidAmount = amount;
        remainingRepaidAmount = amount;
        status = ModuleStatus.ONGOING;

        TOKEN.safeTransferFrom(msg.sender, address(this), amount);

        emit EarlyRepaid(amount);
    }

    function initiateRepay(uint256 amount) public onlyBorrower {
        if (status != ModuleStatus.NOT_INITIATED) revert NSR_WRONG_PHASE();

        totalRepaidAmount = amount;
        remainingRepaidAmount = amount;
        status = ModuleStatus.ONGOING;

        TOKEN.safeTransferFrom(msg.sender, address(this), amount);

        if (amount < POOL.totalToBeRepaid()) {
            emit PartiallyRepaid(amount);
        } else {
            emit Repaid(amount);
        }
    }

    function initiateDefault() public {
        if (!rolesManager.isGovernance(msg.sender) && !rolesManager.isBorrower(msg.sender))
            revert NSR_ONLY_GOVERNANCE_OR_BORROWER();
        if (status != ModuleStatus.NOT_INITIATED) revert NSR_WRONG_PHASE();

        status = ModuleStatus.ONGOING;

        emit Defaulted();
    }

    function withdraw(uint256 positionId) public virtual;

    /*//////////////////////////////////////////////////////////////
                          TRANSFER RESTRICTION
    //////////////////////////////////////////////////////////////*/

    function allowDebtRecipient(address recipient) public onlyGovernance {
        debtTokenRecipients[recipient] = true;
        emit Allowed(recipient);
    }

    function disallowDebtRecipient(address recipient) public onlyGovernance {
        debtTokenRecipients[recipient] = false;
        emit Disallowed(recipient);
    }

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Restrict the sender to borrower only
     */
    modifier onlyBorrower() {
        if (!rolesManager.isBorrower(msg.sender)) revert NSR_ONLY_BORROWER();
        _;
    }

    /**
     * @dev Restrict the sender to governance only
     */
    modifier onlyToDebtRecipient(address to) {
        if (!debtTokenRecipients[to]) revert NSR_UNAUTHORIZED_TRANSFER();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                              OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyToDebtRecipient(to) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyToDebtRecipient(to) {
        super.safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override onlyToDebtRecipient(to) {
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(INonStandardRepaymentModule).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

/**
 * @title NonStandardRepaymentModule
 * @author Atlendis Labs
 * Contract handling the repayment cases not supported by the pool
 * Such cases can be early repays, partial repays or defaults for example
 * Instances of this contract, when integrated with the pools, will typically
 * interrupt all actions possible on the pool, and accept position NFTs in
 * exchange for partial repayment as well as a debt NFT.
 * Follow up interactions with the debt NFT are not part of this contract scope.
 */
interface INonStandardRepaymentModule {
    enum ModuleStatus {
        NOT_INITIALIZED,
        NOT_INITIATED,
        ONGOING
    }

    /**
     * @notice Emitted when the module is initialized as part of its integration process with pools
     * @param pool Address of the pool that initialized this contract
     * @param amount Amount of tokens left for the pool in its custodian, sent to the non standard repayment module for further operations
     */
    event Initialized(address pool, uint256 amount);

    /**
     * @notice Emitted when the repayment procedure is determined as an early repayment
     * @param amount Amount of tokens sent by the borrower to early repay its loan
     */
    event EarlyRepaid(uint256 amount);

    /**
     * @notice Emitted when the repayment procedure is determined as an partial repayment
     * @param amount Amount of tokens sent by the borrower to partially repay its loan
     */
    event PartiallyRepaid(uint256 amount);

    /**
     * @notice Emitted when the repayment procedure is determined as a full repayment
     * @param amount Amount of tokens sent by the borrower to repay its loan
     */
    event Repaid(uint256 amount);

    /**
     * @notice Emitted when the repayment procedure is determined as a default
     */
    event Defaulted();

    /**
     * @notice Emitted when a lender withdraws its compensation in exchange for its position token
     * @param positionId Id of the position to be withdrawn using the non standard repayment module
     * @param positionCurrentValue Current value of the withdrawn position
     * @param withdrawnAmount Amount of tokens sent as compensation during the withdrawal
     */
    event Withdrawn(uint256 positionId, uint256 positionCurrentValue, uint256 withdrawnAmount);

    /**
     * @notice Emitted when governance allows an address to receive debt tokens
     * @param recipient Address allowed to receive debt tokens
     */
    event Allowed(address recipient);

    /**
     * @notice Emitted when governance disallows an address to receive debt tokens
     * @param recipient Address disallowed to receive debt tokens
     */
    event Disallowed(address recipient);

    error NSR_WRONG_PHASE(); // The action is not performed during the right phase of the repayment process
    error NSR_UNAUTHORIZED_TRANSFER(); // The recipient of the debt NFT must be allowed
    error NSR_ONLY_BORROWER(); // Only borrowers can perform this action
    error NSR_ONLY_LENDER(); // Only lenders can perform this action
    error NSR_ONLY_GOVERNANCE_OR_BORROWER(); // Only governance or borrowers can perform this action
    error NSR_EARLY_REPAY_AFTER_MATURITY(); // Cannot early repay after maturity passed
    error NSR_AMOUNT_TOO_LOW_EARLY_REPAY(); // Amount early repaid is too low

    /**
     * @notice Initialization of the repayment module
     * @param amount Amount of tokens not borrowed in the pool, left to be withdrawn by lenders
     */
    function initialize(uint256 amount) external;

    /**
     * @notice Initiation of the non standard repayment procedure as an early repay by the pool borrower
     * @param amount Amount of tokens to be sent as early repayment
     */
    function initiateEarlyRepay(uint256 amount) external;

    /**
     * @notice Initiation of the non standard repayment procedure as a partial or full repayment by the pool borrower
     * @param amount Amount of tokens to be sent as compensation for the loan repayment
     */
    function initiateRepay(uint256 amount) external;

    /**
     * @notice Initiation of the non standard repayment procedure as a default by the governance or the borrowers
     */
    function initiateDefault() external;

    /**
     * @notice Withdraw compensation payment in exchange for pool position token
     * @param positionId Id of the position to withdraw
     */
    function withdraw(uint256 positionId) external;

    /**
     * @notice Allows an address to receive debt tokens
     * @param debtTokenRecipient Recipient address
     */
    function allowDebtRecipient(address debtTokenRecipient) external;

    /**
     * @notice Disallows an address to receive debt tokens
     * @param debtTokenRecipient Recipient address
     */
    function disallowDebtRecipient(address debtTokenRecipient) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import 'lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';
import 'lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';

import '../../libraries/FixedPointMathLib.sol';
import '../roles-manager/interfaces/IRolesManager.sol';
import './BaseNonStandardRepaymentModule.sol';

/**
 * @title ProportionalNonStandardRepaymentModule
 * @author Atlendis Labs
 * Contract handling the repayment cases not supported by the pool
 *
 * Extension of {BaseNonStandardRepaymentModule} implementing the {withdraw} function
 * Withdraw distributes compensation proportionnally to the position involvment into the loan
 */
contract ProportionalNonStandardRepaymentModule is BaseNonStandardRepaymentModule {
    using FixedPointMathLib for uint256;
    using SafeERC20 for ERC20;

    uint256 constant RAY = 1e27;

    constructor(
        string memory name,
        string memory symbol,
        address _rolesManager
    ) BaseNonStandardRepaymentModule(name, symbol, _rolesManager) {}

    /*//////////////////////////////////////////////////////////////
                          POSITION WITHDRAWING
    //////////////////////////////////////////////////////////////*/

    function withdraw(uint256 positionId) public override {
        if (!rolesManager.isLender(msg.sender)) revert NSR_ONLY_LENDER();
        if (status != ModuleStatus.ONGOING) revert NSR_WRONG_PHASE();

        uint256 amountToWithdraw = 0;

        // send back all of the unborrowed amount
        (uint256 unborrowedAmount, ) = POOL.getPositionRepartition(positionId);
        amountToWithdraw += unborrowedAmount;

        // compensate borrowed amount proportionnally to the position share in the loan
        uint256 positionLoanShare = POOL.getPositionLoanShare(positionId);
        // position loan share is in RAY precision by default
        uint256 borrowedAmountCompensation = positionLoanShare.mul(totalRepaidAmount, RAY);
        amountToWithdraw += borrowedAmountCompensation;
        // @dev precision issue: need remediation
        if (borrowedAmountCompensation > remainingRepaidAmount) borrowedAmountCompensation = remainingRepaidAmount;
        remainingRepaidAmount -= borrowedAmountCompensation;

        // if the withdrawn amount is less than the position current value, mint a debt token
        uint256 positionCurrentValue = POOL.getPositionCurrentValue(positionId);
        if (positionCurrentValue > amountToWithdraw) {
            debts[positionId] = positionCurrentValue - amountToWithdraw;
            _safeMint(msg.sender, positionId);
        }

        // exchange pool positions for token compensation
        POOL.transferFrom(msg.sender, address(this), positionId);
        TOKEN.safeTransfer(msg.sender, amountToWithdraw);

        emit Withdrawn(positionId, positionCurrentValue, amountToWithdraw);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import 'lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol';
import '../../interfaces/IPool.sol';

/**
 * @title IRewardsManager
 * @author Atlendis Labs
 * @notice Interface of the Rewards Manager contract
 *         It allows users to stake their positions and earn rewards associated to it.
 *         When a position is staked, a NFT associated to the staked position is minted to the owner.
 *         The staked position NFT can be burn in order to unlock the original position.
 */
interface IRewardsManager is IERC721 {
    /**
     * @notice Thrown when the minimum value position is zero
     */
    error INVALID_ZERO_MIN_POSITION_VALUE();

    /**
     * @notice Thrown when the min locking duration parameter is given as 0
     */
    error INVALID_ZERO_MIN_LOCKING_DURATION();

    /**
     * @notice Thrown when the max locking duration parameter is too low with respect to the minimum duration
     * @param minLockingDuration Value of the min locking duration
     * @param receivedValue Received value for the max locking duration
     */
    error INVALID_TOO_LOW_MAX_LOCKING_DURATION(uint256 minLockingDuration, uint256 receivedValue);

    /**
     * @notice Thrown when an invalid locking duration is given
     * @param minLockingDuration Value of the min locking duration
     * @param maxLockingDuration Value of the max locking duration
     * @param receivedValue Received value for the locking duration
     */
    error INVALID_LOCKING_DURATION(uint256 minLockingDuration, uint256 maxLockingDuration, uint256 receivedValue);

    /**
     * @notice Thrown when the sender is not the expected one
     * @param actualAddress Address of the sender
     * @param expectedAddress Expected address
     */
    error UNAUTHORIZED(address actualAddress, address expectedAddress);

    /**
     * @notice Thrown when the address is not a lender one
     * @param actualAddress Address of the sender
     */
    error ONLY_LENDER(address actualAddress);

    /**
     * @notice Thrown when the address is not an operator one
     * @param actualAddress Address of the sender
     */
    error ONLY_OPERATOR(address actualAddress);

    /**
     * @notice Thrown when the position value is below the minimum
     * @param value Value of the position
     * @param minimumValue Minimum value required for the position
     */
    error POSITION_VALUE_TOO_LOW(uint256 value, uint256 minimumValue);

    /**
     * @notice Thrown when a module is already added
     * @param module Address of the module
     */
    error MODULE_ALREADY_ADDED(address module);

    /**
     * @notice Thrown when a position is unavailable
     */
    error POSITION_UNAVAILABLE();

    /**
     * @notice Thrown when a position is not borrowed or is borrowed but already opted out
     * @param actualStatus Actual position status
     */
    error POSITION_NOT_BORROWED(PositionStatus actualStatus);

    /**
     * @notice Thrown when a term rewards is pending and unlocked after a maximum required term
     * @param actualTerm Actual term
     * @param maximumRequiredTerm Maximum required term
     */
    error TOO_LONG_TERM_PENDING(uint256 actualTerm, uint256 maximumRequiredTerm);

    /**
     * @notice Thrown when the rewards module is disabled
     */
    error DISABLED_REWARDS_MANAGER();

    /**
     * @notice Emitted when a position has been staked
     * @param positionId ID of the position
     * @param owner Address of the owner of the position
     * @param rate Rate of the position
     * @param positionValue Value of the position at staking time
     * @param lockingDuration Locking durations related to term rewards modules
     */
    event PositionStaked(
        uint256 indexed positionId,
        address indexed owner,
        uint256 rate,
        uint256 positionValue,
        uint256 lockingDuration
    );

    /**
     * @notice Emitted when a staked position has been updated
     * @param positionId ID of the position
     * @param owner Address of the owner of the position
     * @param rate Rate of the position
     * @param positionValue Value of the position at staking time
     * @param lockingDuration Locking durations related to term rewards modules
     */
    event StakeUpdated(
        uint256 indexed positionId,
        address indexed owner,
        uint256 rate,
        uint256 positionValue,
        uint256 lockingDuration
    );

    /**
     * @notice Emitted when a position has been unstaked
     * @param positionId ID of the position
     * @param owner Address of the owner of the position
     */
    event PositionUnstaked(uint256 indexed positionId, address indexed owner);

    /**
     * @notice Emitted when rewards of a staked position has been claimed
     * @param positionId ID of the position
     * @param owner Address of the owner of the position
     */
    event RewardsClaimed(uint256 indexed positionId, address indexed owner);

    /**
     * @notice Emitted when locking duration limits have been updated
     * @param minLockingDuration Minimum locking duration allowed for term rewards
     * @param maxLockingDuration Maximum locking duration allowed for term rewards
     */
    event LockingDurationLimitsUpdated(uint256 minLockingDuration, uint256 maxLockingDuration);

    /**
     * @notice Emitted when the minimum position value has been updated
     * @param minPositionValue Minimum position value
     */
    event MinPositionValueUpdated(uint256 minPositionValue);

    /**
     * @notice Emitted when the delta exit locking duration value has been updated
     * @param deltaExitLockingDuration Delta exit locking duration
     */
    event DeltaExitLockingDurationUpdated(uint256 deltaExitLockingDuration);

    /**
     * @notice Emitted when a module is activated
     * @param module Address of the module
     * @param asContinuous True if the module has been activated as a continuous rewards module, false if it has been activated as a term rewards module
     */
    event ModuleAdded(address indexed module, bool indexed asContinuous);

    /**
     * @notice Emitted when the rewards manager is disabled
     * @param unallocatedRewardsRecipient Recipient address of the unallocated rewards
     */
    event RewardsManagerDisabled(address unallocatedRewardsRecipient);

    /**
     * @notice Update a staked position in the contract
     * @param positionId ID of the position
     * @param lockingDuration Locking duration related to term rewards modules, a value of 0 will not update the term rewards
     *
     * Emits a {StakeUpdated} event
     */
    function updateStake(uint256 positionId, uint256 lockingDuration) external;

    /**
     * @notice Update a batch of staked positions in the contract
     * @param positionIds Array of IDs of the positions
     * @param lockingDuration Locking duration related to term rewards modules, a value of 0 will not update the term rewards
     *
     * Emits a {StakeUpdated} event for each staked position
     */
    function batchUpdateStake(uint256[] calldata positionIds, uint256 lockingDuration) external;

    /**
     * @notice Unstake a position in the contract
     *         The assiocated staked position NFT is burned
     *         The position is transferred to the owner of the staked position NFT
     * @param positionId ID of the position
     *
     * Emits a {PositionUnstaked} event
     */
    function unstake(uint256 positionId) external;

    /**
     * @notice Unstake a batch of positions in the contract
     *         The assiocated staked positions NFT are burned
     *         The positions are transferred to the owner of the staked positions NFTs
     * @param positionIds Array of IDs of the positions
     *
     * Emits a {PositionUnstaked} event for each unstaked position
     */
    function batchUnstake(uint256[] calldata positionIds) external;

    /**
     * @notice Claim the rewards earned for a staked position without burning it
     * @param positionId ID of the position
     *
     * Emits a {RewardsClaimed} event
     */
    function claimRewards(uint256 positionId) external;

    /**
     * @notice Claim the rewards earned for a batch of staked positions without burning them
     * @param positionIds Array of IDs of the positions
     *
     * Emits a {RewardsClaimed} event for each reward claimed
     */
    function batchClaimRewards(uint256[] calldata positionIds) external;

    /**
     * @notice Update the rate of the staked position
     * @param positionId The ID of the position
     * @param rate The new rate of the position
     */
    function updatePositionRate(uint256 positionId, uint256 rate) external;

    /**
     * @notice Update the locking durations limits for term rewards
     * @param minLockingDuration Value of the new allowed minimum locking duration
     * @param maxLockingDuration Value of the new allowed maximum locking duration
     *
     * Emits a {LockingDurationLimitsUpdated} event
     */
    function updateLockingDurationLimits(uint256 minLockingDuration, uint256 maxLockingDuration) external;

    /**
     * @notice Update the allowed delta locking duration for opted out position
     * @param deltaExitLockingDuration Value of the new delta exit locking duration
     *
     * Emits a {DeltaExitLockingDurationUpdated} event
     */
    function updateDeltaExitLockingDuration(uint256 deltaExitLockingDuration) external;

    /**
     * @notice Update the minimum position value
     * @param minPositionValue Value of the new minimum position value
     *
     * Emits a {MinPositionValueUpdated} event
     */
    function updateMinPositionValue(uint256 minPositionValue) external;

    /**
     * @notice Add a module
     * @param module Address of the module
     * @param asContinuous True if the module is a continuous rewards module, false if it is a term rewards module
     *
     * Emits a {ModuleAdded} event
     */
    function addModule(address module, bool asContinuous) external;

    /**
     * @notice Disable the rewards manager
     * @param unallocatedRewardsRecipient Recipient address of the unallocated rewards
     *
     * Emits a {RewardsManagerDisabled} event
     */
    function disable(address unallocatedRewardsRecipient) external;

    /**
     * @notice Retrieve if a position is staked with respect to a module
     * @param positionId ID of the position
     * @return _ True if the position is staked with respect to the module, false otherwise
     */
    function isStaked(uint256 positionId) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import 'lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';
import 'lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import './interfaces/IContinuousERC20Rewards.sol';
import '../../../libraries/FixedPointMathLib.sol';
import './RewardsModule.sol';

/**
 * @title ContinuousERC20Rewards
 * @author Atlendis Labs
 * @notice Implementation of the IContinuousERC20Rewards
 */
contract ContinuousERC20Rewards is IContinuousERC20Rewards, RewardsModule {
    /*//////////////////////////////////////////////////////////////
                              LIBRARIES
    //////////////////////////////////////////////////////////////*/
    using SafeERC20 for ERC20;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                               STRUCTS
    //////////////////////////////////////////////////////////////*/
    struct StakedPosition {
        uint256 positionValue;
        uint256 startEarningsPerDeposit;
    }

    /*//////////////////////////////////////////////////////////////
                               STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 private constant SECONDS_PER_YEAR = 365 days;

    ERC20 public immutable TOKEN;
    uint256 immutable ONE;

    uint256 public distributionRate;

    uint256 public deposits;

    uint256 public pendingRewards;
    uint256 public earningsPerDeposit;
    uint256 public lastUpdateTimestamp;

    uint256 constant WAD = 1e18;
    uint256 constant RAY = 1e27;

    // position ID -> staked position liquid staking
    mapping(uint256 => StakedPosition) public stakedPositions;

    /*//////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev constructor
     * @param rewardsManager Address of the rewards manager contract
     * @param token Address of the ERC20 token contract
     * @param _distributionRate Value of the rate of rewards distribution in WAD precision
     */
    constructor(
        address rewardsManager,
        address token,
        uint256 _distributionRate
    ) RewardsModule(rewardsManager) {
        if (_distributionRate == 0) revert INVALID_ZERO_RATE();
        distributionRate = _distributionRate;
        TOKEN = ERC20(token);
        ONE = 10**TOKEN.decimals();
    }

    /*//////////////////////////////////////////////////////////////
                          GOVERNANCE METHODS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IContinuousERC20Rewards
     */
    function updateDistributionRate(uint256 _distributionRate) public onlyGovernance rewardsCollector {
        if (_distributionRate == 0) revert INVALID_ZERO_RATE();
        distributionRate = _distributionRate;

        emit DistributionRateUpdated(_distributionRate);
    }

    /**
     * @inheritdoc IContinuousERC20Rewards
     */
    function empty(address recipient) public onlyGovernance rewardsCollector {
        uint256 transferredAmount = transferUnallocatedRewards(recipient);
        emit Emptied(recipient, transferredAmount);
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC METHODS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IContinuousRewardsModule
     */
    function stake(
        uint256 positionId,
        address owner,
        uint256 rate,
        uint256 positionValue
    ) public onlyRewardsManager rewardsCollector {
        StakedPosition storage stakedPosition = stakedPositions[positionId];
        if (isStaked(positionId)) return;

        stakedPosition.positionValue = positionValue;
        stakedPosition.startEarningsPerDeposit = earningsPerDeposit;
        deposits += positionValue;

        emit PositionStaked(positionId, owner, rate, positionValue);
    }

    /**
     * @inheritdoc IRewardsModule
     */
    function unstake(uint256 positionId, address owner) public onlyRewardsManager rewardsCollector {
        StakedPosition memory stakedPosition = stakedPositions[positionId];

        uint256 positionRewards = stakedPosition.positionValue.mul(
            earningsPerDeposit - stakedPosition.startEarningsPerDeposit,
            RAY
        );

        deposits -= stakedPosition.positionValue;
        pendingRewards -= positionRewards;

        delete stakedPositions[positionId];

        TOKEN.safeTransfer(owner, positionRewards);

        emit PositionUnstaked(positionId, owner, positionRewards);
    }

    /**
     * @inheritdoc IRewardsModule
     */
    function claimRewards(uint256 positionId, address owner) public onlyRewardsManager rewardsCollector {
        StakedPosition storage stakedPosition = stakedPositions[positionId];

        uint256 positionRewards = stakedPosition.positionValue.mul(
            earningsPerDeposit - stakedPosition.startEarningsPerDeposit,
            RAY
        );

        pendingRewards -= positionRewards;
        stakedPosition.startEarningsPerDeposit = earningsPerDeposit;

        TOKEN.safeTransfer(owner, positionRewards);

        emit RewardsClaimed(positionId, owner, positionRewards);
    }

    /**
     * @inheritdoc IRewardsModule
     */
    function collectRewards() public override(IRewardsModule, RewardsModule) {
        if (disabled) return;

        if (deposits == 0) {
            lastUpdateTimestamp = block.timestamp;
            return;
        }
        uint256 maximumRewardsSinceLastUpdate = (distributionRate * (block.timestamp - lastUpdateTimestamp)).mul(
            ONE,
            WAD
        ) / SECONDS_PER_YEAR;

        if (maximumRewardsSinceLastUpdate == 0) {
            return;
        }

        uint256 contractBalance = TOKEN.balanceOf(address(this));
        uint256 rewardsSinceLastUpdate = pendingRewards + maximumRewardsSinceLastUpdate <= contractBalance
            ? maximumRewardsSinceLastUpdate
            : contractBalance - pendingRewards;

        earningsPerDeposit += rewardsSinceLastUpdate.div(deposits, RAY);
        pendingRewards += rewardsSinceLastUpdate;
        lastUpdateTimestamp = block.timestamp;

        emit RewardsCollected(pendingRewards, earningsPerDeposit);
    }

    /**
     * @inheritdoc IRewardsModule
     */
    function isStaked(uint256 positionId) public view override returns (bool) {
        return stakedPositions[positionId].positionValue > 0;
    }

    /**
     * @inheritdoc IRewardsModule
     */
    function getRewards(uint256 positionId) public view returns (uint256 positionRewards) {
        StakedPosition memory stakedPosition = stakedPositions[positionId];

        if (deposits == 0) return 0;

        uint256 maximumRewardsSinceLastUpdate = (distributionRate * (block.timestamp - lastUpdateTimestamp)).mul(
            ONE,
            WAD
        ) / SECONDS_PER_YEAR;

        uint256 contractBalance = TOKEN.balanceOf(address(this));
        uint256 rewardsSinceLastUpdate = pendingRewards + maximumRewardsSinceLastUpdate <= contractBalance
            ? maximumRewardsSinceLastUpdate
            : contractBalance - pendingRewards;

        uint256 currentEarningsPerDeposit = earningsPerDeposit + rewardsSinceLastUpdate.div(deposits, RAY);

        positionRewards = stakedPosition.positionValue.mul(
            currentEarningsPerDeposit - stakedPosition.startEarningsPerDeposit,
            RAY
        );

        return positionRewards;
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL METHODS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Implementation of the method according to RewardsModule specifications
     */
    function transferUnallocatedRewards(address unallocatedRewardsRecipient) internal override returns (uint256) {
        uint256 contractBalance = TOKEN.balanceOf(address(this));

        uint256 unallocatedRewards = contractBalance - pendingRewards;
        if (unallocatedRewards > 0) {
            TOKEN.safeTransfer(unallocatedRewardsRecipient, unallocatedRewards);
        }
        return unallocatedRewards;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../../../libraries/FixedPointMathLib.sol';
import '../../custodian/IPoolCustodian.sol';
import './interfaces/ICustodianRewards.sol';
import './RewardsModule.sol';

/**
 * @title CustodianRewards
 * @author Atlendis Labs
 * @notice Implementation of the ICustodianRewards
 */
contract CustodianRewards is ICustodianRewards, RewardsModule {
    /*//////////////////////////////////////////////////////////////
                               STRUCTS
    //////////////////////////////////////////////////////////////*/
    struct StakedPosition {
        uint256 positionValue;
        uint256 adjustedAmount;
    }

    /*//////////////////////////////////////////////////////////////
                              LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                               STORAGE
    //////////////////////////////////////////////////////////////*/

    IPoolCustodian public immutable CUSTODIAN;

    uint256 public rewards;
    uint256 public liquidityRatio;
    uint256 public unallocatedRewards;
    uint256 public totalStakedAdjustedAmount;

    uint256 constant RAY = 1e27;

    // position ID -> staked position custodian
    mapping(uint256 => StakedPosition) public stakedPositions;

    /*//////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Constructor
     * @param rewardsManager Address of the rewards manager contract
     * @param custodian Address of the custodian contract
     */
    constructor(address rewardsManager, address custodian) RewardsModule(rewardsManager) {
        CUSTODIAN = IPoolCustodian(custodian);
        liquidityRatio = RAY;
    }

    /*//////////////////////////////////////////////////////////////
                           PUBLIC METHODS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IContinuousRewardsModule
     */
    function stake(
        uint256 positionId,
        address owner,
        uint256 rate,
        uint256 positionValue
    ) public onlyRewardsManager rewardsCollector {
        StakedPosition storage stakedPosition = stakedPositions[positionId];
        if (isStaked(positionId)) return;

        uint256 adjustedAmount = positionValue.div(liquidityRatio, RAY);

        totalStakedAdjustedAmount += adjustedAmount;
        stakedPosition.positionValue = positionValue;
        stakedPosition.adjustedAmount = adjustedAmount;

        emit PositionStaked(positionId, owner, rate, positionValue, adjustedAmount);
    }

    /**
     * @inheritdoc IRewardsModule
     */
    function unstake(uint256 positionId, address owner) public onlyRewardsManager rewardsCollector {
        StakedPosition memory stakedPosition = stakedPositions[positionId];

        uint256 stakedPositionValue = stakedPositions[positionId].adjustedAmount.mul(liquidityRatio, RAY);
        // @dev precision issue
        uint256 positionRewards = stakedPositionValue > stakedPositions[positionId].positionValue
            ? stakedPositionValue - stakedPositions[positionId].positionValue
            : 0;

        totalStakedAdjustedAmount -= stakedPosition.adjustedAmount;
        delete stakedPositions[positionId];

        if (positionRewards > 0) {
            CUSTODIAN.withdrawRewards(positionRewards, owner);
        }

        emit PositionUnstaked(positionId, owner, positionRewards);
    }

    /**
     * @inheritdoc IRewardsModule
     */
    function claimRewards(uint256 positionId, address owner) public onlyRewardsManager rewardsCollector {
        StakedPosition storage stakedPosition = stakedPositions[positionId];

        uint256 stakedPositionValue = stakedPositions[positionId].adjustedAmount.mul(liquidityRatio, RAY);
        // @dev precision issue
        uint256 positionRewards = stakedPositionValue > stakedPositions[positionId].positionValue
            ? stakedPositionValue - stakedPositions[positionId].positionValue
            : 0;

        uint256 adjustedAmountDecrease = stakedPosition.adjustedAmount -
            stakedPosition.positionValue.div(liquidityRatio, RAY);
        totalStakedAdjustedAmount -= adjustedAmountDecrease;
        stakedPosition.adjustedAmount -= adjustedAmountDecrease;

        CUSTODIAN.withdrawRewards(positionRewards, owner);

        emit RewardsClaimed(positionId, owner, positionRewards, adjustedAmountDecrease);
    }

    /**
     * @inheritdoc IRewardsModule
     */
    function collectRewards() public override(IRewardsModule, RewardsModule) {
        if (disabled) return;

        uint256 currentRewards = CUSTODIAN.collectRewards();
        uint256 collectedRewards = currentRewards - rewards;

        if (totalStakedAdjustedAmount > 0) {
            liquidityRatio += collectedRewards.div(totalStakedAdjustedAmount, RAY);
        } else {
            unallocatedRewards += collectedRewards;
        }
        rewards = currentRewards;

        emit RewardsCollected(rewards, liquidityRatio, unallocatedRewards);
    }

    /**
     * @inheritdoc IRewardsModule
     */
    function isStaked(uint256 positionId) public view override returns (bool) {
        return stakedPositions[positionId].positionValue > 0;
    }

    /**
     * @inheritdoc IRewardsModule
     */
    function getRewards(uint256 positionId) public view returns (uint256 positionRewards) {
        if (totalStakedAdjustedAmount == 0) return 0;

        uint256 currentRewards = CUSTODIAN.getGeneratedRewards();
        uint256 rewardsSinceLastUpdate = currentRewards - rewards;
        uint256 currentLiquidityRatio = liquidityRatio + rewardsSinceLastUpdate.div(totalStakedAdjustedAmount, RAY);

        uint256 stakedPositionValue = stakedPositions[positionId].adjustedAmount.mul(currentLiquidityRatio, RAY);

        // @dev precision issue
        positionRewards = stakedPositionValue > stakedPositions[positionId].positionValue
            ? stakedPositionValue - stakedPositions[positionId].positionValue
            : 0;

        return positionRewards;
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL METHODS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Implementation of the method according to RewardsModule specifications
     */
    function transferUnallocatedRewards(address unallocatedRewardsRecipient) internal override returns (uint256) {
        uint256 transferredAmount = unallocatedRewards;
        unallocatedRewards = 0;
        if (transferredAmount > 0) {
            CUSTODIAN.withdrawRewards(transferredAmount, unallocatedRewardsRecipient);
        }
        return transferredAmount;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import './IContinuousRewardsModule.sol';

/**
 * @title IContinuousERC20Rewards
 * @author Atlendis Labs
 * @notice Interface of the Continuous ERC20 Rewards module contract
 *         This module is controlled by a rewards manager.
 *         It allows to generate rewards of ERC20 tokens based on a configured rate and continuously distribute the rewards to staked positions.
 */
interface IContinuousERC20Rewards is IContinuousRewardsModule {
    /**
     * @notice Thrown when a value of zero has been given for the rate
     */
    error INVALID_ZERO_RATE();

    /**
     * @notice Emitted when a position has been staked
     * @param positionId ID of the position
     * @param owner Address of the owner of the position
     * @param rate Rate of the position
     * @param positionValue Value of the position at staking time
     */
    event PositionStaked(uint256 indexed positionId, address indexed owner, uint256 rate, uint256 positionValue);

    /**
     * @notice Emitted when a position has been unstaked
     * @param positionId ID of the position
     * @param owner Address of the owner of the position
     * @param positionRewards Value of the position rewards
     */
    event PositionUnstaked(uint256 indexed positionId, address indexed owner, uint256 positionRewards);

    /**
     * @notice Emitted when rewards of a staked position has been claimed
     * @param positionId ID of the position
     * @param owner Address of the owner of the position
     * @param positionRewards Value of the position rewards
     */
    event RewardsClaimed(uint256 indexed positionId, address indexed owner, uint256 positionRewards);

    /**
     * @notice Emitted when rewards are colleted
     * @param pendingRewards Amount of rewards to be collected
     * @param earningsPerDeposit Value of the computed earning per deposit ratio
     */
    event RewardsCollected(uint256 pendingRewards, uint256 earningsPerDeposit);

    /**
     * @notice Emitted when the distribution rate has been updated
     * @param distributionRate Value of the new distribution rate
     */
    event DistributionRateUpdated(uint256 distributionRate);

    /**
     * @notice Emitted when the contract balance has been emptied
     * @param recipient Recipient address
     * @param amount Transferred amount
     */
    event Emptied(address recipient, uint256 amount);

    /**
     * @notice Update the distribution rate
     * @param distributionRate Value of the new distribution rate
     *
     * Emits a {DistributionRateUpdated} event
     */
    function updateDistributionRate(uint256 distributionRate) external;

    /**
     * @notice Transfer the unallocated ERC20 balance of the contract to a recipient
     * @param recipient Recipient address
     *
     * Emits a {Emptied} event
     */
    function empty(address recipient) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import './IRewardsModule.sol';

/**
 * @title IContinuousRewardsModule
 * @author Atlendis Labs
 * @notice Interface of a Continuous Rewards module contract
 *         A module implementing this interface is meant to be controlled by a rewards manager.
 *         It allows to retrieve rewards and continuously distribute them to staked positions.
 *         The way to retrieve the rewards is specific for each module type.
 */
interface IContinuousRewardsModule is IRewardsModule {
    /**
     * @notice Stake a position at the module level
     *         The method is idempotent
     *         Only the Rewards Manager is able to trigger this method
     * @param positionId ID of the staked position
     * @param owner Owner of the staked position
     * @param rate Rate of the underlying position
     * @param positionValue Value of the underlying position
     *
     * Emits a {PositionStaked}. The params of the event varies according to the module type.
     */
    function stake(
        uint256 positionId,
        address owner,
        uint256 rate,
        uint256 positionValue
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import './IContinuousRewardsModule.sol';

/**
 * @title ICustodianRewards
 * @author Atlendis Labs
 * @notice Interface of the Custodian Rewards module contract
 *         This module is controlled by a rewards manager.
 *         It allows to retrieve the generated rewards by a custodian contract and distribute them to staked positions.
 */
interface ICustodianRewards is IContinuousRewardsModule {
    /**
     * @notice Emitted when a position has been staked
     * @param positionId ID of the position
     * @param owner Address of the owner of the position
     * @param rate Rate of the position
     * @param positionValue Value of the position at staking time
     * @param adjustedAmount Value of the computed adjusted amount
     */
    event PositionStaked(
        uint256 indexed positionId,
        address indexed owner,
        uint256 rate,
        uint256 positionValue,
        uint256 adjustedAmount
    );

    /**
     * @notice Emitted when a position has been unstaked
     * @param positionId ID of the position
     * @param owner Address of the owner of the position
     * @param positionRewards Value of the position rewards
     */
    event PositionUnstaked(uint256 indexed positionId, address indexed owner, uint256 positionRewards);

    /**
     * @notice Emitted when rewards of a staked position has been claimed
     * @param positionId ID of the position
     * @param owner Address of the owner of the position
     * @param positionRewards Value of the position rewards
     * @param adjustedAmountDecrease Value of the computed decrease in adjusted amount
     */
    event RewardsClaimed(
        uint256 indexed positionId,
        address indexed owner,
        uint256 positionRewards,
        uint256 adjustedAmountDecrease
    );

    /**
     * @notice Emitted when rewards are colleted
     * @param rewards Total amount of collected rewards
     * @param liquidityRatio Value of the computed liquidity ratio
     * @param unallocatedRewards Amount of unallocated rewards
     */
    event RewardsCollected(uint256 rewards, uint256 liquidityRatio, uint256 unallocatedRewards);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import './ITermERC20Rewards.sol';

/**
 * @title IRateWeightedTermERC20Rewards
 * @author Atlendis Labs
 * @notice Interface extension of the ITermERC20Rewards
 *         A maximum rate parameter is added.
 *         Position with rate above this parameter have a computed multiplier of zero and are allocated base rewards only
 */
interface IRateWeightedTermERC20Rewards is ITermERC20Rewards {
    /**
     * @notice Emitted when the max rate has been updated
     * @param maxRate Updated max rate value
     */
    event MaxRateUpdated(uint256 maxRate);

    /**
     * @notice Update max rate
     * @param maxRate New max rate value
     *
     * Emits a {MaxRateUpdated} event.
     */
    function updateMaxRate(uint256 maxRate) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

/**
 * @title IRewardsModule
 * @author Atlendis Labs
 * @notice Interface of a Rewards module contract
 *         A module implementing this interface is meant to be controlled by a rewards manager.
 *         It allows to retrieve rewards and distribute them to staked positions.
 *         The way to retrieve the rewards is specific for each module type.
 */
interface IRewardsModule {
    /**
     * @notice Thrown when the sender is not the expected one
     * @param actualAddress Address of the sender
     * @param expectedAddress Expected address
     */
    error UNAUTHORIZED(address actualAddress, address expectedAddress);

    /**
     * @notice Thrown when the module is already disabled
     */
    error ALREADY_DISABLED();

    /**
     * @notice Emitted when the module is disabled
     * @param unallocatedRewardsRecipient Recipient address of the unallocated rewards
     * @param unallocatedRewards Amount of unallocated rewards
     */
    event ModuleDisabled(address unallocatedRewardsRecipient, uint256 unallocatedRewards);

    /**
     * @notice Disable the module
     *         Only the Rewards Manager is able to trigger this method
     * @param unallocatedRewardsRecipient Recipient address of the unallocated rewards
     *
     * Emits a {ModuleDisabled} event
     */
    function disable(address unallocatedRewardsRecipient) external;

    /**
     * @notice Return wheter or not the module is disabled
     * @return _ True if the module is disabled, false otherwise
     */
    function disabled() external view returns (bool);

    /**
     * @notice Forward the unstaking of a position at the module level
     *         Only the Rewards Manager is able to trigger this method
     * @param positionId ID of the position
     * @param owner Owner of the staked position
     *
     * Emits a {PositionUnstaked} event. The params of the event varies according to the module type.
     */
    function unstake(uint256 positionId, address owner) external;

    /**
     * @notice Forward the rewards claim associated to a staked position at the module level
     *         Only the Rewards Manager is able to trigger this method
     * @param positionId ID of the position
     * @param owner Owner of the staked position
     *
     * Emits a {RewardsClaimed} event. The params of the event varies according to the module type.
     */
    function claimRewards(uint256 positionId, address owner) external;

    /**
     * @notice Collect the rewards since last update and distribute them to staked positions
     *
     * Emits a {RewardsCollected} event. The params of the event varies according to the module type.
     */
    function collectRewards() external;

    /**
     * @notice Retrieve if a position is staked with respect to a module
     * @param positionId ID of the position
     * @return _ True if the position is staked with respect to the module, false otherwise
     */
    function isStaked(uint256 positionId) external view returns (bool);

    /**
     * @notice Retrieve the rewards associated to a staked position
     * @param positionId ID of the position
     * @return positionRewards Rewards associated to the staked position
     */
    function getRewards(uint256 positionId) external view returns (uint256 positionRewards);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import './ITermRewardsModule.sol';

/**
 * @title ILiquidERC20Rewards
 * @author Atlendis Labs
 * @notice Interface of the Term ERC20 Rewards module contract
 *         This module is controlled by a rewards manager.
 *         It allows to generate rewards of ERC20 tokens based on a configured rate and unlock the rewards to staked positions after a configured duration.
 */
interface ITermERC20Rewards is ITermRewardsModule {
    /**
     * @notice Thrown when a value of zero has been given for the rate
     */
    error INVALID_ZERO_RATE();

    /**
     * @notice Thrown when the base multiplier value is too low
     * @param actualValue Given value for the base multiplier
     * @param minimumValue Minimum value for the base multiplier
     */
    error INVALID_BASE_MULTIPLIER_TOO_LOW(uint256 actualValue, uint256 minimumValue);

    /**
     * @notice Thrown when the max multiplier parameter is too low with respect to the base multiplier
     * @param baseMultiplier Value of the base multiplier
     * @param receivedValue Received value for the max multiplier
     */
    error INVALID_TOO_LOW_MAX_MULTIPLIER(uint256 baseMultiplier, uint256 receivedValue);

    /**
     * @notice Emitted when a position has been staked
     * @param positionId ID of the position
     * @param owner Address of the owner of the position
     * @param rate Rate of the position at staking time
     * @param positionValue Value of the position at staking time
     * @param lockingDuration Duration of locking in order to unlock rewards
     * @param positionRewards Value of the position rewards if the lock is held
     */
    event PositionStaked(
        uint256 indexed positionId,
        address indexed owner,
        uint256 rate,
        uint256 positionValue,
        uint256 lockingDuration,
        uint256 positionRewards
    );

    /**
     * @notice Emitted when a lock has been renewed
     * @param positionId ID of the position
     * @param owner Address of the owner of the position
     * @param rate Rate of the position at staking time
     * @param positionValue Value of the position at staking time
     * @param lockingDuration Duration of locking in order to unlock rewards
     * @param positionRewards Value of the position rewards if the lock is held
     */
    event LockRenewed(
        uint256 indexed positionId,
        address indexed owner,
        uint256 rate,
        uint256 positionValue,
        uint256 lockingDuration,
        uint256 positionRewards
    );

    /**
     * @notice Emitted when a position has been unstaked
     * @param positionId ID of the position
     * @param owner Address of the owner of the position
     * @param positionRewards Value of the position rewards
     */
    event PositionUnstaked(uint256 indexed positionId, address indexed owner, uint256 positionRewards);

    /**
     * @notice Emitted when rewards of a staked position has been claimed
     * @param positionId ID of the position
     * @param owner Address of the owner of the position
     * @param positionRewards Value of the position rewards
     */
    event RewardsClaimed(uint256 indexed positionId, address indexed owner, uint256 positionRewards);

    /**
     * @notice Emitted when the distribution rate has been updated
     * @param distributionRate Value of the new distribution rate
     */
    event DistributionRateUpdated(uint256 distributionRate);

    /**
     * @notice Emitted when the multipliers have been updated
     * @param baseMultiplier Value of the new base multiplier
     * @param maxMultiplier Value of the new max multiplier
     */
    event MultipliersUpdated(uint256 baseMultiplier, uint256 maxMultiplier);

    /**
     * @notice Emitted when the contract balance has been emptied
     * @param recipient Recipient address
     * @param amount Transferred amount
     */
    event Emptied(address recipient, uint256 amount);

    /**
     * @notice Update the distribution rate
     * @param distributionRate Value of the new distribution rate
     *
     * Emits a {DistributionRateUpdated} event
     */
    function updateDistributionRate(uint256 distributionRate) external;

    /**
     * @notice Update the multipliers
     * @param baseMultiplier Value of the new base multiplier
     * @param maxMultiplier Value of the new max multiplier
     *
     * Emits a {MultipliersUpdated} event
     */
    function updateMultipliers(uint256 baseMultiplier, uint256 maxMultiplier) external;

    /**
     * @notice Transfer the unallocated ERC20 balance of the contract to a recipient
     * @param recipient Recipient address
     *
     * Emits a {Emptied} event
     */
    function empty(address recipient) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import './IRewardsModule.sol';

/**
 * @title ITermRewardsModule
 * @author Atlendis Labs
 * @notice Interface of a Term Rewards module contract
 *         A module implementing this interface is meant to be controlled by a rewards manager.
 *         It allows to retrieve rewards and distribute them to staked positions after a configured duration.
 *         The way to retrieve the rewards is specific for each module type.
 */
interface ITermRewardsModule is IRewardsModule {
    /**
     * @notice Stake or the update a stake of a position at the module level
     *         Apart from the emitted event, the method is idempotent
     *         Only the Rewards Manager is able to trigger this method
     * @param positionId ID of the staked position
     * @param owner Owner of the staked position
     * @param rate Rate of the underlying position
     * @param positionValue Value of the underlying position
     * @param lockingDuration Duration of the locking
     *
     * Emits a {PositionStaked} or {LockRenewed} event. The params of the event varies according to the module type.
     */
    function stake(
        uint256 positionId,
        address owner,
        uint256 rate,
        uint256 positionValue,
        uint256 lockingDuration
    ) external;

    /**
     * @notice Estimate the rewards associated to a position for a locking duration
     * @param positionId ID of the staked position
     * @param owner Owner of the staked position
     * @param rate Rate of the underlying position
     * @param positionValue Value of the underlying position
     * @param lockingDuration Duration of the locking
     * @return positionRewards Rewards associated to the position and the locking duration if staked
     */
    function estimateRewards(
        uint256 positionId,
        address owner,
        uint256 rate,
        uint256 positionValue,
        uint256 lockingDuration
    ) external view returns (uint256 positionRewards);

    /**
     * @notice Retrieve the term at which the reward is unlocked
     * @param positionId ID of the staked position
     * @return term The term at whcih the reward is unlocked
     */
    function getTerm(uint256 positionId) external view returns (uint256 term);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import './TermERC20Rewards.sol';
import './interfaces/IRateWeightedTermERC20Rewards.sol';

/**
 * @title TermERC20Rewards
 * @author Atlendis Labs
 * @notice Implementation of the IRateWeightedTermERC20Rewards
 */
contract RateWeightedTermERC20Rewards is TermERC20Rewards, IRateWeightedTermERC20Rewards {
    /*//////////////////////////////////////////////////////////////
                               STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public maxRate;

    /*//////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev constructor
     * @param rewardsManager Address of the rewards manager contract
     * @param token Address of the ERC20 token contract
     * @param _distributionRate Value of the rate of rewards distribution in WAD precision
     * @param _baseMultiplier Value of the base multiplier
     * @param _maxMultiplier Value of the maximum multiplier allowed
     * @param _maxRate Value of the maximum rate allowed
     */
    constructor(
        address rewardsManager,
        address token,
        uint256 _distributionRate,
        uint256 _baseMultiplier,
        uint256 _maxMultiplier,
        uint256 _maxRate
    ) TermERC20Rewards(rewardsManager, token, _distributionRate, _baseMultiplier, _maxMultiplier) {
        maxRate = _maxRate;
    }

    /*//////////////////////////////////////////////////////////////
                          GOVERNANCE METHODS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IRateWeightedTermERC20Rewards
     */
    function updateMaxRate(uint256 _maxRate) public onlyGovernance {
        maxRate = _maxRate;
        emit MaxRateUpdated(_maxRate);
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL METHODS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Compute the multiplier
     *      Override of the `computeMultiplier` method of the parent `TermERC20Rewards`
     *      Method is free to be overriden by child contracts
     * @custom:param PositionId positionId ID of the staked position
     * @custom:param owner Owner of the staked position
     * @param rate Rate of the underlying position
     * @custom:param value Value of the underlying position
     * @param lockingDuration Duration of the locking
     * @return multiplier Computed multiplier
     */
    function computeMultiplier(
        uint256,
        address,
        uint256 rate,
        uint256,
        uint256 lockingDuration
    ) internal view virtual override returns (uint256 multiplier) {
        if (rate >= maxRate) return baseMultiplier;

        uint256 minLockingDuration = RewardsManager(REWARDS_MANAGER).minLockingDuration();
        uint256 maxLockingDuration = RewardsManager(REWARDS_MANAGER).maxLockingDuration();
        return
            baseMultiplier +
            ((maxMultiplier - baseMultiplier) * (lockingDuration - minLockingDuration) * (maxRate - rate)) /
            (maxLockingDuration - minLockingDuration) /
            maxRate;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../../roles-manager/Managed.sol';
import '../RewardsManager.sol';
import './interfaces/IRewardsModule.sol';

abstract contract RewardsModule is IRewardsModule, Managed {
    /*//////////////////////////////////////////////////////////////
                               STORAGE
    //////////////////////////////////////////////////////////////*/

    address public immutable REWARDS_MANAGER;

    bool public disabled;
    uint256 public disabledAt;

    /*//////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev constructor
     * @param rewardsManager Address of the rewards manager contract
     */
    constructor(address rewardsManager) Managed(address(RewardsManager(rewardsManager).getRolesManager())) {
        REWARDS_MANAGER = rewardsManager;
    }

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Restrict sender to Rewards Manager contract
     */
    modifier onlyRewardsManager() {
        if (msg.sender != REWARDS_MANAGER) revert UNAUTHORIZED(msg.sender, REWARDS_MANAGER);
        _;
    }

    /**
     * @dev Trigger the collection of rewards
     */
    modifier rewardsCollector() {
        collectRewards();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC METHODS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IRewardsModule
     */
    function disable(address unallocatedRewardsRecipient) public onlyRewardsManager rewardsCollector {
        if (disabled) revert ALREADY_DISABLED();

        disabled = true;
        disabledAt = block.timestamp;

        uint256 unallocatedRewards = transferUnallocatedRewards(unallocatedRewardsRecipient);

        emit ModuleDisabled(unallocatedRewardsRecipient, unallocatedRewards);
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL METHODS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Transfer the unallocated rewards to a recipient
     * @param unallocatedRewardsRecipient Recipient address of the unallocated rewards
     * @return unallocatedRewards Amount of transferred unallocated rewards
     */
    function transferUnallocatedRewards(address unallocatedRewardsRecipient)
        internal
        virtual
        returns (uint256 unallocatedRewards);

    /**
     * @inheritdoc IRewardsModule
     */
    function collectRewards() public virtual {}
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import 'lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';
import 'lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import './interfaces/ITermERC20Rewards.sol';
import '../RewardsManager.sol';
import './RewardsModule.sol';

/**
 * @title TermERC20Rewards
 * @author Atlendis Labs
 * @notice Implementation of the ITermERC20Rewards
 */
contract TermERC20Rewards is ITermERC20Rewards, RewardsModule {
    /*//////////////////////////////////////////////////////////////
                              LIBRARIES
    //////////////////////////////////////////////////////////////*/
    using SafeERC20 for ERC20;

    /*//////////////////////////////////////////////////////////////
                               STRUCTS
    //////////////////////////////////////////////////////////////*/
    struct StakedPosition {
        uint256 rewardsTimestamp;
        uint256 rewards;
        uint256 unlockedRewards;
    }

    /*//////////////////////////////////////////////////////////////
                               STORAGE
    //////////////////////////////////////////////////////////////*/
    uint256 private constant SECONDS_PER_YEAR = 365 days;
    uint256 constant WAD = 1e18;
    uint256 constant RAY = 1e27;

    ERC20 public immutable TOKEN;
    uint256 public immutable POOL_TOKEN_ONE;

    uint256 public maxMultiplier;
    uint256 public baseMultiplier;
    uint256 public distributionRate;

    uint256 public pendingRewards;

    // position ID -> staked position
    mapping(uint256 => StakedPosition) public stakedPositions;

    /*//////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev constructor
     * @param rewardsManager Address of the rewards manager contract
     * @param token Address of the ERC20 token contract
     * @param _distributionRate Value of the rate of rewards distribution in WAD precision
     * @param _baseMultiplier Value of the base multiplier
     * @param _maxMultiplier Value of the maximum multiplier allowed
     */
    constructor(
        address rewardsManager,
        address token,
        uint256 _distributionRate,
        uint256 _baseMultiplier,
        uint256 _maxMultiplier
    ) RewardsModule(rewardsManager) {
        if (_distributionRate == 0) revert INVALID_ZERO_RATE();
        validateMultipliers(_baseMultiplier, _maxMultiplier);

        distributionRate = _distributionRate;
        baseMultiplier = _baseMultiplier;
        maxMultiplier = _maxMultiplier;

        TOKEN = ERC20(token);
        POOL_TOKEN_ONE = RewardsManager(rewardsManager).POSITION_MANAGER().ONE();
    }

    /*//////////////////////////////////////////////////////////////
                          GOVERNANCE METHODS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc ITermERC20Rewards
     */
    function updateDistributionRate(uint256 _distributionRate) public onlyGovernance {
        if (_distributionRate == 0) revert INVALID_ZERO_RATE();
        distributionRate = _distributionRate;

        emit DistributionRateUpdated(_distributionRate);
    }

    /**
     * @inheritdoc ITermERC20Rewards
     */
    function updateMultipliers(uint256 _baseMultiplier, uint256 _maxMultiplier) public onlyGovernance {
        validateMultipliers(_baseMultiplier, _maxMultiplier);

        baseMultiplier = _baseMultiplier;
        maxMultiplier = _maxMultiplier;

        emit MultipliersUpdated(baseMultiplier, maxMultiplier);
    }

    /**
     * @inheritdoc ITermERC20Rewards
     */
    function empty(address recipient) public onlyGovernance {
        uint256 transferredAmount = transferUnallocatedRewards(recipient);
        emit Emptied(recipient, transferredAmount);
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC METHODS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc ITermRewardsModule
     */
    function stake(
        uint256 positionId,
        address owner,
        uint256 rate,
        uint256 positionValue,
        uint256 lockingDuration
    ) public onlyRewardsManager {
        if (block.timestamp < stakedPositions[positionId].rewardsTimestamp) return;

        bool isAlreadyStaked = isStaked(positionId);

        uint256 positionRewards = getPositionRewards(positionId, owner, rate, positionValue, lockingDuration);
        registerRewards(positionId, lockingDuration, positionRewards);

        if (isAlreadyStaked) {
            emit LockRenewed(positionId, owner, rate, positionValue, lockingDuration, positionRewards);
        } else {
            emit PositionStaked(positionId, owner, rate, positionValue, lockingDuration, positionRewards);
        }
    }

    /**
     * @inheritdoc IRewardsModule
     */
    function unstake(uint256 positionId, address owner) public onlyRewardsManager {
        StakedPosition memory stakedPosition = stakedPositions[positionId];

        pendingRewards -= stakedPosition.rewards + stakedPosition.unlockedRewards;
        delete stakedPositions[positionId];

        uint256 positionRewards = stakedPosition.unlockedRewards;
        if (block.timestamp >= stakedPosition.rewardsTimestamp && stakedPosition.rewards > 0) {
            positionRewards += stakedPosition.rewards;
        }

        if (positionRewards > 0) {
            TOKEN.safeTransfer(owner, positionRewards);
        }

        emit PositionUnstaked(positionId, owner, positionRewards);
    }

    /**
     * @inheritdoc IRewardsModule
     */
    function claimRewards(uint256 positionId, address owner) public onlyRewardsManager {
        StakedPosition storage stakedPosition = stakedPositions[positionId];

        uint256 positionRewards = stakedPosition.unlockedRewards;
        if (block.timestamp >= stakedPosition.rewardsTimestamp && stakedPosition.rewards > 0) {
            positionRewards += stakedPosition.rewards;
            stakedPosition.rewards = 0;
        }

        if (positionRewards == 0) return;

        stakedPosition.unlockedRewards = 0;
        pendingRewards -= positionRewards;

        TOKEN.safeTransfer(owner, positionRewards);

        emit RewardsClaimed(positionId, owner, positionRewards);
    }

    /**
     * @inheritdoc IRewardsModule
     */
    function isStaked(uint256 positionId) public view override returns (bool) {
        return stakedPositions[positionId].rewardsTimestamp > 0;
    }

    /**
     * @inheritdoc IRewardsModule
     */
    function getRewards(uint256 positionId) public view returns (uint256 positionRewards) {
        StakedPosition memory stakedPosition = stakedPositions[positionId];

        if (block.timestamp < stakedPosition.rewardsTimestamp) return stakedPosition.unlockedRewards;

        return stakedPosition.unlockedRewards + stakedPosition.rewards;
    }

    /**
     * @inheritdoc ITermRewardsModule
     */
    function estimateRewards(
        uint256 positionId,
        address owner,
        uint256 rate,
        uint256 positionValue,
        uint256 lockingDuration
    ) public view returns (uint256 positionRewards) {
        return getPositionRewards(positionId, owner, rate, positionValue, lockingDuration);
    }

    /**
     * @inheritdoc ITermRewardsModule
     */
    function getTerm(uint256 positionId) public view returns (uint256 term) {
        return stakedPositions[positionId].rewardsTimestamp;
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL METHODS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Compute the multiplier
     *      Method is free to be overriden by child contracts
     * @custom:param PositionId positionId ID of the staked position
     * @custom:param owner Owner of the staked position
     * @custom:param rate Rate of the underlying position
     * @custom:param value Value of the underlying position
     * @param lockingDuration Duration of the locking
     * @return multiplier Computed multiplier
     */
    function computeMultiplier(
        uint256,
        address,
        uint256,
        uint256,
        uint256 lockingDuration
    ) internal view virtual returns (uint256 multiplier) {
        uint256 minLockingDuration = RewardsManager(REWARDS_MANAGER).minLockingDuration();
        uint256 maxLockingDuration = RewardsManager(REWARDS_MANAGER).maxLockingDuration();
        return
            baseMultiplier +
            ((maxMultiplier - baseMultiplier) * (lockingDuration - minLockingDuration)) /
            (maxLockingDuration - minLockingDuration);
    }

    /*//////////////////////////////////////////////////////////////
                           PRIVATE METHODS
    //////////////////////////////////////////////////////////////*/

    function getPositionRewards(
        uint256 positionId,
        address owner,
        uint256 rate,
        uint256 positionValue,
        uint256 lockingDuration
    ) private view returns (uint256) {
        uint256 multiplier = computeMultiplier(positionId, owner, rate, positionValue, lockingDuration);

        uint256 tokenDenominator = (POOL_TOKEN_ONE * WAD) / (10**TOKEN.decimals());

        uint256 positionRewards = ((positionValue * distributionRate * lockingDuration * multiplier) /
            SECONDS_PER_YEAR) /
            baseMultiplier /
            tokenDenominator;

        uint256 contractBalance = TOKEN.balanceOf(address(this));

        if (pendingRewards + positionRewards > contractBalance) {
            return contractBalance - pendingRewards;
        }
        return positionRewards;
    }

    function validateMultipliers(uint256 _baseMultiplier, uint256 _maxMultiplier) private pure {
        if (_baseMultiplier < RAY) revert INVALID_BASE_MULTIPLIER_TOO_LOW(_baseMultiplier, RAY);
        if (_maxMultiplier < _baseMultiplier) revert INVALID_TOO_LOW_MAX_MULTIPLIER(_baseMultiplier, _maxMultiplier);
    }

    function registerRewards(
        uint256 positionId,
        uint256 lockingDuration,
        uint256 positionRewards
    ) private {
        StakedPosition storage stakedPosition = stakedPositions[positionId];
        stakedPosition.rewardsTimestamp = block.timestamp + lockingDuration;
        stakedPosition.unlockedRewards += stakedPosition.rewards;
        stakedPosition.rewards = positionRewards;

        pendingRewards += positionRewards;
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL METHODS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Implementation of the method according to RewardsModule specifications
     */
    function transferUnallocatedRewards(address unallocatedRewardsRecipient) internal override returns (uint256) {
        uint256 contractBalance = TOKEN.balanceOf(address(this));

        uint256 unallocatedRewards = contractBalance - pendingRewards;
        if (unallocatedRewards > 0) {
            TOKEN.safeTransfer(unallocatedRewardsRecipient, unallocatedRewards);
        }
        return unallocatedRewards;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import 'lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol';

import '../roles-manager/Managed.sol';
import './IRewardsManager.sol';
import './modules/interfaces/IContinuousRewardsModule.sol';
import './modules/interfaces/ITermRewardsModule.sol';
import './modules/interfaces/IRewardsModule.sol';

/**
 * @title Rewards Manager
 * @author Atlendis Labs
 * @notice Implementation of the IRewardsManager
 */
abstract contract RewardsManager is IRewardsManager, ERC721, Managed {
    /*//////////////////////////////////////////////////////////////
                               STORAGE
    //////////////////////////////////////////////////////////////*/
    IPool public immutable POSITION_MANAGER;

    uint256 public minPositionValue;
    uint256 public minLockingDuration;
    uint256 public maxLockingDuration;
    uint256 public deltaExitLockingDuration;

    address[] public continuousRewardsModules;
    address[] public termRewardsModules;
    // address -> module added
    mapping(address => bool) public addedModules;

    bool public disabled;
    uint256 public disabledAt;

    /*//////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Constructor
     * @param positionManager Address of the position manager contract
     * @param _minPositionValue Minimum position required value
     * @param _minLockingDuration Minimum locking duration allowed for term rewards
     * @param _maxLockingDuration Maximum locking duration allowed for term rewards
     * @param _deltaExitLockingDuration Allowed delta duration for locking for term rewards in case of opted out position
     * @param name ERC721 name of the staked position NFT
     * @param symbol ERC721 symbol of the staked position NFT
     */
    constructor(
        address positionManager,
        uint256 _minPositionValue,
        uint256 _minLockingDuration,
        uint256 _maxLockingDuration,
        uint256 _deltaExitLockingDuration,
        string memory name,
        string memory symbol
    ) Managed(IPool(positionManager).getRolesManager()) ERC721(name, symbol) {
        if (_minPositionValue == 0) revert INVALID_ZERO_MIN_POSITION_VALUE();
        validateLockingDurationLimits(_minLockingDuration, _maxLockingDuration);

        minPositionValue = _minPositionValue;
        minLockingDuration = _minLockingDuration;
        maxLockingDuration = _maxLockingDuration;
        deltaExitLockingDuration = _deltaExitLockingDuration;

        POSITION_MANAGER = IPool(positionManager);
    }

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Restrict actions if rewards manager is disabled
     */
    modifier onlyEnabled() {
        if (disabled) revert DISABLED_REWARDS_MANAGER();
        _;
    }

    /**
     * @dev Restrict the sender to lender only
     */
    modifier onlyLender() {
        if (!rolesManager.isLender(msg.sender)) revert ONLY_LENDER(msg.sender);
        _;
    }

    /*//////////////////////////////////////////////////////////////
                              GOVERNANCE
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IRewardsManager
     */
    function addModule(address module, bool asContinuous) public onlyGovernance onlyEnabled {
        if (addedModules[module]) revert MODULE_ALREADY_ADDED(module);

        address[] storage moduleList = asContinuous ? continuousRewardsModules : termRewardsModules;
        moduleList.push(module);
        addedModules[module] = true;

        emit ModuleAdded(module, asContinuous);
    }

    /**
     * @inheritdoc IRewardsManager
     */
    function disable(address unallocatedRewardsRecipient) public onlyGovernance onlyEnabled {
        disabled = true;
        disabledAt = block.timestamp;

        for (uint256 i = 0; i < continuousRewardsModules.length; i++) {
            IRewardsModule module = IRewardsModule(continuousRewardsModules[i]);
            module.disable(unallocatedRewardsRecipient);
        }

        for (uint256 i = 0; i < termRewardsModules.length; i++) {
            IRewardsModule module = IRewardsModule(termRewardsModules[i]);
            module.disable(unallocatedRewardsRecipient);
        }

        emit RewardsManagerDisabled(unallocatedRewardsRecipient);
    }

    /**
     * @inheritdoc IRewardsManager
     */
    function updateLockingDurationLimits(uint256 _minLockingDuration, uint256 _maxLockingDuration)
        public
        onlyGovernance
        onlyEnabled
    {
        validateLockingDurationLimits(_minLockingDuration, _maxLockingDuration);

        minLockingDuration = _minLockingDuration;
        maxLockingDuration = _maxLockingDuration;

        emit LockingDurationLimitsUpdated(minLockingDuration, maxLockingDuration);
    }

    /**
     * @inheritdoc IRewardsManager
     */
    function updateMinPositionValue(uint256 _minPositionValue) public onlyGovernance {
        if (_minPositionValue == 0) revert INVALID_ZERO_MIN_POSITION_VALUE();

        minPositionValue = _minPositionValue;

        emit MinPositionValueUpdated(minPositionValue);
    }

    /**
     * @inheritdoc IRewardsManager
     */
    function updateDeltaExitLockingDuration(uint256 _deltaExitLockingDuration) public onlyGovernance {
        deltaExitLockingDuration = _deltaExitLockingDuration;

        emit DeltaExitLockingDurationUpdated(deltaExitLockingDuration);
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC METHODS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IRewardsManager
     */
    function updateStake(uint256 positionId, uint256 lockingDuration) public onlyEnabled onlyLender {
        _updateStake(positionId, lockingDuration);
    }

    /**
     * @inheritdoc IRewardsManager
     */
    function batchUpdateStake(uint256[] calldata positionIds, uint256 lockingDuration) public onlyEnabled onlyLender {
        for (uint256 i = 0; i < positionIds.length; i++) {
            _updateStake(positionIds[i], lockingDuration);
        }
    }

    /**
     * @inheritdoc IRewardsManager
     */
    function unstake(uint256 positionId) public onlyLender {
        _unstake(positionId);
    }

    /**
     * @inheritdoc IRewardsManager
     */
    function batchUnstake(uint256[] calldata positionIds) public onlyLender {
        for (uint256 i = 0; i < positionIds.length; i++) {
            _unstake(positionIds[i]);
        }
    }

    /**
     * @inheritdoc IRewardsManager
     */
    function claimRewards(uint256 positionId) public onlyLender {
        _claimRewards(positionId);
    }

    /**
     * @inheritdoc IRewardsManager
     */
    function batchClaimRewards(uint256[] calldata positionIds) public onlyLender {
        for (uint256 i = 0; i < positionIds.length; i++) {
            _claimRewards(positionIds[i]);
        }
    }

    /**
     * @inheritdoc IRewardsManager
     */
    function updatePositionRate(uint256 positionId, uint256 rate) public onlyLender {
        address owner = ownerOf(positionId);
        if (msg.sender != owner) revert UNAUTHORIZED(msg.sender, owner);

        POSITION_MANAGER.updateRate(positionId, rate);
    }

    /**
     * @dev Retrieve the list of continuous rewards module
     * @return _ The list of addresses of continuous rewards module
     */
    function getContinuousRewardsModules() public view returns (address[] memory) {
        return continuousRewardsModules;
    }

    /**
     * @dev Retrieve the list of term rewards module
     * @return _ The list of addresses of term rewards module
     */
    function getTermRewardsModules() public view returns (address[] memory) {
        return termRewardsModules;
    }

    /**
     * @inheritdoc IRewardsManager
     */
    function isStaked(uint256 positionId) public view returns (bool) {
        return _exists(positionId);
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL METHODS
    //////////////////////////////////////////////////////////////*/

    function _stake(uint256 positionId, uint256 lockingDuration) internal {
        (address positionOwner, uint256 rate, uint256 positionValue, PositionStatus status) = POSITION_MANAGER
            .getPosition(positionId);
        if (msg.sender != positionOwner) revert UNAUTHORIZED(msg.sender, positionOwner);
        if (positionValue < minPositionValue) revert POSITION_VALUE_TOO_LOW(positionValue, minPositionValue);
        if (status == PositionStatus.UNAVAILABLE) revert POSITION_UNAVAILABLE();

        address owner = msg.sender;

        bool withLockRewards = lockingDuration != 0;
        if (withLockRewards) validateLockingDuration(lockingDuration);

        POSITION_MANAGER.transferFrom(owner, address(this), positionId);

        propagateStakeToModules({
            positionId: positionId,
            owner: owner,
            rate: rate,
            positionValue: positionValue,
            lockingDuration: lockingDuration,
            withLockRewards: withLockRewards
        });

        _mint(owner, positionId);

        emit PositionStaked(positionId, owner, rate, positionValue, lockingDuration);
    }

    function _updateStake(uint256 positionId, uint256 lockingDuration) internal {
        address owner = ownerOf(positionId);
        if (msg.sender != owner) revert UNAUTHORIZED(msg.sender, owner);

        (, , , PositionStatus status) = POSITION_MANAGER.getPosition(positionId);
        if (status == PositionStatus.UNAVAILABLE) revert POSITION_UNAVAILABLE();

        bool withLockRewards = lockingDuration != 0;
        if (withLockRewards) validateLockingDuration(lockingDuration);

        (, uint256 rate, uint256 positionValue, ) = POSITION_MANAGER.getPosition(positionId);

        propagateStakeToModules({
            positionId: positionId,
            owner: owner,
            rate: rate,
            positionValue: positionValue,
            lockingDuration: lockingDuration,
            withLockRewards: withLockRewards
        });

        emit StakeUpdated(positionId, owner, rate, positionValue, lockingDuration);
    }

    function _unstake(uint256 positionId) internal {
        address owner = ownerOf(positionId);
        if (msg.sender != owner) revert UNAUTHORIZED(msg.sender, owner);

        _burn(positionId);

        for (uint256 i = 0; i < continuousRewardsModules.length; i++) {
            IContinuousRewardsModule(continuousRewardsModules[i]).unstake(positionId, owner);
        }
        for (uint256 i = 0; i < termRewardsModules.length; i++) {
            ITermRewardsModule(termRewardsModules[i]).unstake(positionId, owner);
        }

        POSITION_MANAGER.transferFrom(address(this), owner, positionId);

        emit PositionUnstaked(positionId, owner);
    }

    function _claimRewards(uint256 positionId) internal {
        address owner = ownerOf(positionId);
        if (msg.sender != owner) revert UNAUTHORIZED(msg.sender, owner);

        for (uint256 i = 0; i < continuousRewardsModules.length; i++) {
            IContinuousRewardsModule(continuousRewardsModules[i]).claimRewards(positionId, owner);
        }
        for (uint256 i = 0; i < termRewardsModules.length; i++) {
            ITermRewardsModule(termRewardsModules[i]).claimRewards(positionId, owner);
        }

        emit RewardsClaimed(positionId, owner);
    }

    /*//////////////////////////////////////////////////////////////
                           PRIVATE METHODS
    //////////////////////////////////////////////////////////////*/

    function validateLockingDurationLimits(uint256 min, uint256 max) private pure {
        if (min == 0) revert INVALID_ZERO_MIN_LOCKING_DURATION();
        if (max < min) revert INVALID_TOO_LOW_MAX_LOCKING_DURATION(min, max);
    }

    function propagateStakeToModules(
        uint256 positionId,
        address owner,
        uint256 rate,
        uint256 positionValue,
        uint256 lockingDuration,
        bool withLockRewards
    ) private {
        for (uint256 i = 0; i < continuousRewardsModules.length; i++) {
            IContinuousRewardsModule(continuousRewardsModules[i]).stake(positionId, owner, rate, positionValue);
        }
        if (withLockRewards) {
            for (uint256 i = 0; i < termRewardsModules.length; i++) {
                ITermRewardsModule(termRewardsModules[i]).stake(
                    positionId,
                    owner,
                    rate,
                    positionValue,
                    lockingDuration
                );
            }
        }
    }

    function validateLockingDuration(uint256 lockingDuration) private view {
        if (lockingDuration < minLockingDuration || lockingDuration > maxLockingDuration)
            revert INVALID_LOCKING_DURATION(minLockingDuration, maxLockingDuration, lockingDuration);
    }

    /*//////////////////////////////////////////////////////////////
                          TRANSFER OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) {
        if (!rolesManager.isOperator(msg.sender)) revert ONLY_OPERATOR(msg.sender);

        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) {
        if (!rolesManager.isOperator(msg.sender)) revert ONLY_OPERATOR(msg.sender);

        super.safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override(ERC721, IERC721) {
        if (!rolesManager.isOperator(msg.sender)) revert ONLY_OPERATOR(msg.sender);

        super.safeTransferFrom(from, to, tokenId, _data);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import './IRolesManager.sol';

/**
 * @title IManaged
 * @author Atlendis Labs
 * @notice Interface in order to integrate roles and permissions managed by a RolesManager
 */
interface IManaged {
    /**
     * @notice Thrown when sender is not a governance address
     */
    error ONLY_GOVERNANCE();

    /**
     * @notice Emitted when the Roles Manager contract has been updated
     * @param rolesManager New Roles Manager contract address
     */
    event RolesManagerUpdated(address indexed rolesManager);

    /**
     * @notice Update the Roles Manager contract
     * @param rolesManager The new Roles Manager contract
     *
     * Emits a {RolesManagerUpdated} event
     */
    function updateRolesManager(address rolesManager) external;

    /**
     * @notice Retrieve the Roles Manager contract
     * @return rolesManager The Roles Manager contract
     */
    function getRolesManager() external view returns (IRolesManager rolesManager);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import 'lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol';

/**
 * @notice IRolesManager
 * @author Atlendis Labs
 * @notice Roles Manager interface
 *         The Roles Manager is in charge of managing the various roles in the set of smart contracts of a product.
 *         The identified roles are
 *          - GOVERNANCE: allowed to manage the parameters of the contracts and various governance only actions,
 *          - BORROWER: allowed to perform borrow and repay actions,
 *          - OPERATOR: allowed to perform Position NFT or staked Position NFT transfer,
 *          - LENDER: allowed to deposit, update rate, withdraw etc...
 */
interface IRolesManager is IERC165 {
    /**
     * @notice Check if an address has a governance role
     * @param account Address to check
     * @return _ True if the address has a governance role, false otherwise
     */
    function isGovernance(address account) external view returns (bool);

    /**
     * @notice Check if an address has a borrower role
     * @param account Address to check
     * @return _ True if the address has a borrower role, false otherwise
     */
    function isBorrower(address account) external view returns (bool);

    /**
     * @notice Check if an address has an operator role
     * @param account Address to check
     * @return _ True if the address has a operator role, false otherwise
     */
    function isOperator(address account) external view returns (bool);

    /**
     * @notice Check if an address has a lender role
     * @param account Address to check
     * @return _ True if the address has a lender role, false otherwise
     */
    function isLender(address account) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import './IRolesManager.sol';

/**
 * @notice IStandardRolesManager
 * @author Atlendis Labs
 * @notice Standard Roles Manager interface
 *         Extension of the RolesManager interface
 *         The restrictions on lenders can be toggled
 */
interface IStandardRolesManager is IRolesManager {
    /**
     * @notice Emitted when the restrictions on lenders is toggled
     * @param restrictionsEnabled True if restrictions are enabled, false otherwise
     */
    event RestrictionsToggled(bool restrictionsEnabled);

    /**
     * @notice Toggle the restrictions on lenders
     *
     * Emits a {RestrictionsToggled} event
     */
    function toggleRestrictions() external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import './interfaces/IManaged.sol';

/**
 * @title Managed
 * @author Atlendis Labs
 * @notice Implementation of the IManaged interface
 */
abstract contract Managed is IManaged {
    IRolesManager internal rolesManager;

    /**
     * @dev Constructor
     * @param _rolesManager Roles Manager contract address
     */
    constructor(address _rolesManager) {
        rolesManager = IRolesManager(_rolesManager);
    }

    /**
     * @dev Restrict the sender to governance only
     */
    modifier onlyGovernance() {
        if (!rolesManager.isGovernance(msg.sender)) revert ONLY_GOVERNANCE();
        _;
    }

    /**
     * @inheritdoc IManaged
     */
    function updateRolesManager(address _rolesManager) external onlyGovernance {
        if (rolesManager.isGovernance(msg.sender)) revert ONLY_GOVERNANCE();
        rolesManager = IRolesManager(_rolesManager);
        emit RolesManagerUpdated(address(rolesManager));
    }

    /**
     * @inheritdoc IManaged
     */
    function getRolesManager() public view returns (IRolesManager) {
        return rolesManager;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import 'lib/openzeppelin-contracts/contracts/access/AccessControl.sol';
import 'lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol';

import './interfaces/IStandardRolesManager.sol';

/**
 * @title StandardRolesManager
 * @author Atlendis Labs
 * @notice Implementation of the IStandardRolesManager
 */
contract StandardRolesManager is AccessControl, IStandardRolesManager {
    bytes32 public constant OPERATOR_ROLE = keccak256('OPERATOR_ROLE');
    bytes32 public constant LENDER_ROLE = keccak256('LENDER_ROLE');
    bytes32 public constant BORROWER_ROLE = keccak256('BORROWER_ROLE');
    bytes32 public constant NOT_ALLOWED_LENDER_ROLE = keccak256('NOT_ALLOWED_LENDER_ROLE');

    bool public lenderRestrictionsEnabled;

    /**
     * @dev Constructor
     * @param governance Address of the governance
     */
    constructor(address governance) {
        _grantRole(DEFAULT_ADMIN_ROLE, governance);
    }

    /**
     * @inheritdoc IStandardRolesManager
     */
    function toggleRestrictions() public onlyRole(DEFAULT_ADMIN_ROLE) {
        lenderRestrictionsEnabled = !lenderRestrictionsEnabled;
        emit RestrictionsToggled(lenderRestrictionsEnabled);
    }

    /**
     * @inheritdoc IRolesManager
     */
    function isGovernance(address account) public view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    /**
     * @inheritdoc IRolesManager
     */
    function isBorrower(address account) public view returns (bool) {
        return hasRole(BORROWER_ROLE, account);
    }

    /**
     * @inheritdoc IRolesManager
     */
    function isOperator(address account) public view returns (bool) {
        return hasRole(OPERATOR_ROLE, account);
    }

    /**
     * @inheritdoc IRolesManager
     */
    function isLender(address account) public view returns (bool) {
        if (hasRole(NOT_ALLOWED_LENDER_ROLE, account)) return false;

        if (lenderRestrictionsEnabled) return hasRole(LENDER_ROLE, account);

        return true;
    }

    /**
     * @dev Batch extension of the `AccessControl.grantRole` public method
     */
    function batchGrantRole(bytes32 role, address[] memory accounts) public onlyRole(getRoleAdmin(role)) {
        for (uint256 i = 0; i < accounts.length; i++) {
            _grantRole(role, accounts[i]);
        }
    }

    /**
     * @dev Batch extension of the `AccessControl.revokeRole` public method
     */
    function batchRevokeRole(bytes32 role, address[] memory accounts) public onlyRole(getRoleAdmin(role)) {
        for (uint256 i = 0; i < accounts.length; i++) {
            _revokeRole(role, accounts[i]);
        }
    }

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, IERC165) returns (bool) {
        return
            interfaceId == type(IStandardRolesManager).interfaceId ||
            interfaceId == type(IRolesManager).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import 'lib/openzeppelin-contracts/contracts/access/Ownable.sol';
import 'lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol';
import 'lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol';
import 'lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol';
import './interfaces/IProductFactory.sol';
import './interfaces/IFactoryRegistry.sol';

/**
 * @title FactoryRegistry
 * @author Atlendis Labs
 * @notice Implementation of the IFactoryRegistry
 *         The product factory management and the right to deploy product instances are restricted to an owner
 */
contract FactoryRegistry is IFactoryRegistry, Initializable, OwnableUpgradeable, UUPSUpgradeable {
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public version;
    // product ID -> factory
    mapping(bytes32 => IProductFactory) public productFactories;
    // instance ID -> address
    mapping(string => address) public productInstances;

    /*//////////////////////////////////////////////////////////////
                             INITIALIZER
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Implementation of the initialize method according to Initializable contract specs
     */
    function initialize(address governance) public initializer {
        __Ownable_init();
        transferOwnership(governance);
        version++;
    }

    /*//////////////////////////////////////////////////////////////
                            UPGRADABILITY
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Implementation of the _authorizeUpgrade method of UUPSUpgradeable
     */
    function _authorizeUpgrade(address) internal override onlyOwner {}

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IFactoryRegistry
     */
    function registerProductFactory(bytes32 productId, IProductFactory factory) external onlyOwner {
        if (address(productFactories[productId]) != address(0)) revert PRODUCT_FACTORY_ALREADY_EXISTING();

        productFactories[productId] = factory;

        emit ProductFactoryRegistered(productId, address(factory));
    }

    /**
     * @inheritdoc IFactoryRegistry
     */
    function unregisterProductFactory(bytes32 productId) external onlyOwner {
        if (address(productFactories[productId]) == address(0)) revert PRODUCT_FACTORY_NOT_FOUND();

        productFactories[productId] = IProductFactory(address(0));

        emit ProductFactoryUnregistered(productId);
    }

    /**
     * @inheritdoc IFactoryRegistry
     */
    function deployProductInstance(
        bytes32 productId,
        string memory instanceId,
        bytes memory custodianConfig,
        bytes memory feesControllerConfig,
        bytes memory parametersConfigFirstPart,
        bytes memory parametersConfigSecondPart,
        string memory name,
        string memory symbol
    ) external onlyOwner {
        if (productInstances[instanceId] != address(0)) revert PRODUCT_INSTANCE_ALREADY_EXISTING();

        IProductFactory factory = productFactories[productId];
        if (address(factory) == address(0)) revert PRODUCT_FACTORY_NOT_FOUND();

        address instance = factory.deploy(
            msg.sender,
            custodianConfig,
            feesControllerConfig,
            parametersConfigFirstPart,
            parametersConfigSecondPart,
            name,
            symbol
        );
        productInstances[instanceId] = instance;

        emit ProductInstanceDeployed(
            productId,
            msg.sender,
            instanceId,
            instance,
            custodianConfig,
            feesControllerConfig,
            parametersConfigFirstPart,
            parametersConfigSecondPart,
            name,
            symbol
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import './IProductFactory.sol';

/**
 * @title IFactoryRegistry
 * @author Atlendis Labs
 * @notice Interface of the Factory Registry, its responsibilities are twofold
 *           - manage the product factories,
 *           - use the product factories in order to deploy product instance and register them
 */
interface IFactoryRegistry {
    /**
     * @notice Thrown when the product factory already exists
     */
    error PRODUCT_FACTORY_ALREADY_EXISTING();

    /**
     * @notice Thrown when the candidate product factory does not implement the required interface
     */
    error INVALID_PRODUCT_FACTORY_CANDIDATE();

    /**
     * @notice Thrown when the product factory has not been found
     */
    error PRODUCT_FACTORY_NOT_FOUND();

    /**
     * @notice Thrown when the product instance already exists
     */
    error PRODUCT_INSTANCE_ALREADY_EXISTING();

    /**
     * @notice Emitted when a new product factory has been registered
     * @param productId The ID of the new product
     * @param factory The address of the factory of the new product
     */
    event ProductFactoryRegistered(bytes32 indexed productId, address factory);

    /**
     * @notice Emitted when a product factory has been unregistered
     * @param productId The ID of the new product
     */
    event ProductFactoryUnregistered(bytes32 indexed productId);

    /**
     * @notice Emitted when a new instance of a product has been deployed
     * @param productId The ID of the registered product
     * @param governance Address of the governance of the product instance
     * @param instanceId The string ID of the deployed instance of the product
     * @param instance Address of the deployed instance
     * @param custodianConfig Custodian-specific configurations, encoded as bytes
     * @param parametersConfigFirstPart First batch of parameters-specific configurations specific, encoded as bytes
     * @param parametersConfigSecondPart Second batch of parameters-specific configurations specific, encoded as bytes
     * @param name Name of the ERC721 token associated to the product instance
     * @param symbol Symbol of the ERC721 token associated to the product instance
     */
    event ProductInstanceDeployed(
        bytes32 indexed productId,
        address indexed governance,
        string instanceId,
        address instance,
        bytes custodianConfig,
        bytes feesControllerConfig,
        bytes parametersConfigFirstPart,
        bytes parametersConfigSecondPart,
        string name,
        string symbol
    );

    /**
     * @notice Register a new product factory
     * @param productId The ID of the new product
     * @param factory The address of the factory of the new product
     *
     * Emits a {ProductFactoryRegistered} event
     */
    function registerProductFactory(bytes32 productId, IProductFactory factory) external;

    /**
     * @notice Unregister an existing product factory
     * @param productId The ID of the product
     *
     * Emits a {ProductFactoryUnregistered} event
     */
    function unregisterProductFactory(bytes32 productId) external;

    /**
     * @notice Deploy a new instance of a product and register the address using an ID
     * @param productId The  ID of the registered product
     * @param instanceId The string ID of the deployed instance of the product
     * @param custodianConfig Custodian-specific configurations, encoded as bytes
     * @param feesControllerConfig FeesController-specific configurations, encoded as bytes
     * @param parametersConfigFirstPart First batch of parameters-specific configurations specific, encoded as bytes
     * @param parametersConfigSecondPart Second batch of parameters-specific configurations specific, encoded as bytes
     * @param name Name of the ERC721 token associated to the product instance
     * @param symbol Symbol of the ERC721 token associated to the product instance
     *
     * Emits a {ProductInstanceDeployed} event
     */
    function deployProductInstance(
        bytes32 productId,
        string memory instanceId,
        bytes memory custodianConfig,
        bytes memory feesControllerConfig,
        bytes memory parametersConfigFirstPart,
        bytes memory parametersConfigSecondPart,
        string memory name,
        string memory symbol
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import 'lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol';

enum PositionStatus {
    AVAILABLE,
    BORROWED,
    UNAVAILABLE
}

/**
 * @title IPool
 * @author Atlendis Labs
 * @notice Interface of a Position Manager
 */
interface IPool is IERC721 {
    /**
     * @notice Total amount borrowed in the pool
     */
    function totalBorrowed() external view returns (uint256 totalBorrowed);

    /**
     * @notice Total amount borrowed to be repaid in the pool
     */
    function totalToBeRepaid() external view returns (uint256 totalToBeRepaid);

    /**
     * @notice Retrieve a position
     * @param positionId ID of the position
     * @return owner Address of the position owner
     * @return rate Value of the position rate
     * @return depositedAmount Deposited amount of the position
     * @return status Status of the position
     */
    function getPosition(uint256 positionId)
        external
        view
        returns (
            address owner,
            uint256 rate,
            uint256 depositedAmount,
            PositionStatus status
        );

    /**
     * @notice Retrieve a position repartition between borrowed and unborrowed amounts
     * @param positionId ID of the position
     * @return unborrowedAmount Amount of deposit not borrowed
     * @return borrowedAmount Amount of deposit borrowed in the current loan
     */
    function getPositionRepartition(uint256 positionId)
        external
        view
        returns (uint256 unborrowedAmount, uint256 borrowedAmount);

    /**
     * @notice Retrieve a position current value, an any time in the pool cycle
     * @param positionId ID of the position
     * @return value Current value of the position, expressed in token precision
     */
    function getPositionCurrentValue(uint256 positionId) external view returns (uint256 value);

    /**
     * @notice Retrieve a position share within the current loan
     * Returns 0 if a loan is not active
     * @param positionId ID of the position
     * @return loanShare Returns the share of the position within the current loan, in WAD
     */
    function getPositionLoanShare(uint256 positionId) external view returns (uint256 loanShare);

    /**
     * @notice Update a position rate
     * @param positionId The ID of the position
     * @param rate The new rate of the position
     */
    function updateRate(uint256 positionId, uint256 rate) external;

    /**
     * @notice Retrieve the current maturity
     * @return maturity The current maturity
     */
    function getMaturity() external view returns (uint256 maturity);

    /**
     * @notice Retrieve the loan duration
     * @return loanDuration The loan duration
     */
    function LOAN_DURATION() external view returns (uint256 loanDuration);

    /**
     * @notice Retrieve one in the pool token precision
     * @return one One in the pool token precision
     */
    function ONE() external view returns (uint256 one);

    /**
     * @notice Retrieve the address of the custodian
     * @return custodian Address of the custodian
     */
    function CUSTODIAN() external view returns (address custodian);

    /**
     * @notice Retrieve the address of the roles manager
     * @return rolesManager Address of the roles manager
     */
    function getRolesManager() external view returns (address rolesManager);

    /**
     * @notice Retrieve the accruals due at the current point in time
     * @return currentAccruals Accruals due at current point in time
     */
    function getCurrentAccruals() external view returns (uint256 currentAccruals);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

/**
 * @title IProductFactory
 * @author Atlendis Labs
 * @notice Interface of the factory contract in charge of deploying instance of one dedicated product
 *         One Product Factory is deployed per product
 *         Used by the Factory Router contract in order to deploy instances of any products
 */
interface IProductFactory {
    /**
     * @notice Thrown when constructor data is invalid
     */
    error INVALID_PRODUCT_PARAMS();

    /**
     * @notice Thrown when min origination amount is less than target origination amount
     */
    error INVALID_ORIGINATION_PARAMETERS();

    /**
     * @notice Thrown when invalid rate boundaries parameters are given
     */
    error INVALID_RATE_BOUNDARIES();

    /**
     * @notice Thrown when zero rate spacing input is given
     */
    error INVALID_ZERO_RATE_SPACING();

    /**
     * @notice Thrown when invalid rate parameters are given
     */
    error INVALID_RATE_PARAMETERS();

    /**
     * @notice Thrown when an invalid percentage input is given
     */
    error INVALID_PERCENTAGE_VALUE();

    /**
     * @notice Thrown when sender is not authorized
     */
    error UNAUTHORIZED();

    /**
     * @notice Deploy an instance of the product
     * @param governance Address of the governance of the product instance
     * @param custodianConfig Custodian-specific configurations, encoded as bytes
     * @param feesControllerConfig FeesController-specific configurations, encoded as bytes
     * @param parametersConfigFirstPart First batch of parameters-specific configurations specific, encoded as bytes
     * @param parametersConfigSecondPart Second batch of parameters-specific configurations specific, encoded as bytes
     * @param name Name of the ERC721 token associated to the product instance
     * @param symbol Symbol of the ERC721 token associated to the product instance
     * @return instance The address of the deployed product instance
     */
    function deploy(
        address governance,
        bytes memory custodianConfig,
        bytes memory feesControllerConfig,
        bytes memory parametersConfigFirstPart,
        bytes memory parametersConfigSecondPart,
        string memory name,
        string memory symbol
    ) external returns (address instance);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

/**
 * @title ITimelock
 * @author Atlendis Labs
 * @notice Interface of a basic Timelock
 *         Timelocks are considered for non standard repay, rescue procedures and switching yield provider
 *         Initiation of such procedures are not specified here
 */
interface ITimelock {
    /**
     * @notice Thrown when trying to interact with inexistant timelock
     */
    error TIMELOCK_INEXISTANT();

    /**
     * @notice Thrown when trying to interact with an already executed timelock
     */
    error TIMELOCK_ALREADY_EXECUTED();

    /**
     * @notice Thrown when trying to interact with an already executed timelock
     */
    error TIMELOCK_NOT_READY();

    /**
     * @notice Thrown when trying to interact with an already initiated timelock
     */
    error TIMELOCK_ALREADY_INITIATED();

    /**
     * @notice Thrown when the input delay for a timelock is too small
     */
    error TIMELOCK_DELAY_TOO_SMALL();

    /**
     * @notice Emitted when a timelock has been cancelled
     */
    event TimelockCancelled();

    /**
     * @notice Emitted when a timelock has been executed
     * @param transferredAmount Amount of transferred tokens
     */
    event TimelockExecuted(uint256 transferredAmount);

    /**
     * @notice Execute a ready timelock
     *
     * Emits a {TimelockExecuted} event
     */
    function executeTimelock() external;

    /**
     * @notice Cancel a timelock
     *
     * Emits a {TimelockCancelled} event
     */
    function cancelTimelock() external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import {FixedPointMathLib as SolmateFixedPointMathLib} from 'lib/solmate/src/utils/FixedPointMathLib.sol';

/**
 * @title FixedPointMathLib library
 * @author Atlendis Labs
 * @dev Overlay over Solmate FixedPointMathLib
 *      Results of multiplications and divisions are always rounded down
 */
library FixedPointMathLib {
    using SolmateFixedPointMathLib for uint256;

    struct LibStorage {
        uint256 denominator;
    }

    function libStorage() internal pure returns (LibStorage storage ls) {
        bytes32 position = keccak256('diamond.standard.library.storage');
        assembly {
            ls.slot := position
        }
    }

    function setDenominator(uint256 denominator) internal {
        LibStorage storage ls = libStorage();
        ls.denominator = denominator;
    }

    function mul(uint256 x, uint256 y) internal view returns (uint256) {
        return x.mulDivDown(y, libStorage().denominator);
    }

    function div(uint256 x, uint256 y) internal view returns (uint256) {
        return x.mulDivDown(libStorage().denominator, y);
    }

    function mul(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256) {
        return x.mulDivDown(y, denominator);
    }

    function div(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256) {
        return x.mulDivDown(denominator, y);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import {IERC20} from 'lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import 'lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import '../common/custodian/IPoolCustodian.sol';
import '../common/fees/IFeesController.sol';

/**
 * @title FundsTransfer library
 * @author Atlendis Labs
 * @dev Contains the utilities methods associated to transfers of funds between pool contract, pool custodian and fees controller contracts
 */
library FundsTransfer {
    using SafeERC20 for IERC20;

    /**
     * @dev Withdraw funds from the custodian, apply a fee and transfer the computed amount to a recipient address
     * @param token Address of the ERC20 token of the pool
     * @param custodian Pool custodian contract
     * @param recipient Recipient address
     * @param amount Amount of tokens to send to the sender
     * @param fees Amount of tokens to keep as fees
     */
    function chargedWithdraw(
        address token,
        IPoolCustodian custodian,
        address recipient,
        uint256 amount,
        uint256 fees
    ) external {
        custodian.withdraw(amount + fees, address(this));
        IERC20(token).safeTransfer(recipient, amount);
    }

    /**
     * @dev Deposit funds to the custodian from the sender, apply a fee
     * @param token Address of the ERC20 token of the pool
     * @param custodian Pool custodian contract
     * @param amount Amount of tokens to send to the custodian
     * @param fees Amount of tokens to keep as fees
     */
    function chargedDepositToCustodian(
        address token,
        IPoolCustodian custodian,
        uint256 amount,
        uint256 fees
    ) external {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount + fees);
        IERC20(token).safeApprove(address(custodian), amount);
        custodian.deposit(amount, address(this));
    }

    /**
     * @dev Approve fees to be pulled by the fees controller
     * @param token Address of the ERC20 token of the pool
     * @param feesController Fees controller contract
     * @param fees Amount of tokens to allow the fees controller to pull
     */
    function approveFees(
        address token,
        IFeesController feesController,
        uint256 fees
    ) external {
        IERC20(token).safeApprove(address(feesController), fees);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../interfaces/ITimelock.sol';

enum TimelockType {
    NON_STANDARD_REPAY,
    RESCUE
}

struct PoolTimelock {
    uint256 readyTimestamp;
    address recipient;
    TimelockType timelockType;
    uint256 executedAt;
}

/**
 * @title PoolTimelockLogic
 * @author AtlendisLabs
 * @dev Contains the utilities methods associated to the manipulation of the Timelock for the pool
 */
library PoolTimelockLogic {
    /**
     * @dev Initiate the timelock
     * @param timelock Timelock
     * @param delay Delay in seconds
     * @param recipient Recipient address
     * @param timelockType Type of the timelock
     */
    function initiate(
        PoolTimelock storage timelock,
        uint256 delay,
        address recipient,
        TimelockType timelockType
    ) internal {
        if (timelock.readyTimestamp != 0) revert ITimelock.TIMELOCK_ALREADY_INITIATED();
        timelock.readyTimestamp = block.timestamp + delay;
        timelock.recipient = recipient;
        timelock.timelockType = timelockType;
        timelock.executedAt = 0;
    }

    /**
     * @dev Execute the timelock
     * @param timelock Timelock
     */
    function execute(PoolTimelock storage timelock) internal {
        if (timelock.readyTimestamp == 0) revert ITimelock.TIMELOCK_INEXISTANT();
        if (timelock.executedAt > 0) revert ITimelock.TIMELOCK_ALREADY_EXECUTED();
        if (block.timestamp < timelock.readyTimestamp) revert ITimelock.TIMELOCK_NOT_READY();
        timelock.executedAt = block.timestamp;
    }

    /**
     * @dev Cancel the timelock
     * @param timelock Timelock
     */
    function cancel(PoolTimelock storage timelock) internal {
        if (timelock.readyTimestamp == 0) revert ITimelock.TIMELOCK_INEXISTANT();
        if (timelock.executedAt > 0) revert ITimelock.TIMELOCK_ALREADY_EXECUTED();
        delete timelock.readyTimestamp;
        delete timelock.recipient;
        delete timelock.timelockType;
        delete timelock.executedAt;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import './FixedPointMathLib.sol';

/**
 * @title TimeValue library
 * @author Atlendis Labs
 * @dev Contains the utilities methods associated to time computation in the Atlendis Protocol
 */
library TimeValue {
    using FixedPointMathLib for uint256;
    uint256 internal constant SECONDS_PER_YEAR = 365 days;

    /**
     * @dev Compute the discount factor given a rate and a time delta with respect to the time at which the loan started
     *      Exact computation is defined as 1 / (1 + rate)^deltaTime
     *      The approximation uses up to the first order of the Taylor series, i.e. 1 / (1 + deltaTime * rate)
     * @param rate Rate
     * @param timeDelta Time difference since the the time at which the loan started
     * @param denominator The denominator value
     * @return discountFactor The discount factor
     */
    function getDiscountFactor(
        uint256 rate,
        uint256 timeDelta,
        uint256 denominator
    ) internal pure returns (uint256 discountFactor) {
        uint256 timeInYears = (timeDelta * denominator).div(SECONDS_PER_YEAR * denominator, denominator);
        return denominator.div(denominator + rate.mul(timeInYears, denominator), denominator);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import 'lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol';
import 'lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol';
import 'lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol';
import '../FactoryRegistry.sol';

contract FactoryRegistryV2 is FactoryRegistry {
    function upgradeVersion() external onlyOwner {
        version++;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../../../libraries/TimeValue.sol';
import '../LoanBase/interfaces/IRepayableLoan.sol';
import '../LoanBase/LoanBase.sol';

/**
 * @title BulletLoan
 * @author Atlendis Labs
 */
contract Bullet is LoanBase, IRepayableLoan {
    /*//////////////////////////////////////////////////////////////
                                LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using LoanLogic for LoanTypes.Tick;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Constructor - pass parameters to modules
     * @param rolesManager Address of the roles manager
     * @param custodian Address of the custodian
     * @param feesController Address of the fees controller
     * @param ratesAmountsConfig Parameters-specific configurations
     * @param durationsConfig Parameters-specific configurations
     * @param name ERC721 name of the positions
     * @param symbol ERC721 symbol of the positions
     */
    constructor(
        address rolesManager,
        IPoolCustodian custodian,
        IFeesController feesController,
        bytes memory ratesAmountsConfig,
        bytes memory durationsConfig,
        string memory name,
        string memory symbol
    )
        LoanLender(name, symbol)
        LoanState(rolesManager, custodian, feesController, ratesAmountsConfig, durationsConfig)
    {}

    /*//////////////////////////////////////////////////////////////
                        PUBLIC VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc ILoan
     */
    function getPositionCurrentValue(uint256 positionId) external view override returns (uint256 positionCurrentValue) {
        // TODO test that it works
        (uint256 unborrowedAmount, uint256 borrowedAmount) = getPositionRepartition(positionId);
        uint256 referenceTimestamp = timelock.executedAt > 0 ? timelock.executedAt : block.timestamp;

        uint256 lateRepaymentThreshold = borrowTimestamp + LOAN_DURATION;
        uint256 timeDeltaIntoLoan = referenceTimestamp > lateRepaymentThreshold
            ? LOAN_DURATION
            : referenceTimestamp - borrowTimestamp;
        uint256 timeDeltaIntoLateRepayment = referenceTimestamp > lateRepaymentThreshold
            ? referenceTimestamp - lateRepaymentThreshold
            : 0;
        uint256 currentBorrowedAmount = borrowedAmount
            .div(TimeValue.getDiscountFactor(positions[positionId].rate, timeDeltaIntoLoan, ONE))
            .div(TimeValue.getDiscountFactor(LATE_REPAYMENT_FEE_RATE, timeDeltaIntoLateRepayment, ONE));
        positionCurrentValue = unborrowedAmount + currentBorrowedAmount;
    }

    /**
     * @inheritdoc ILoan
     */
    function getCurrentAccruals() external view override returns (uint256 currentAccruals) {
        uint256 loanMaturity = borrowTimestamp + LOAN_DURATION;
        uint256 referenceTimestamp = timelock.executedAt > 0 ? timelock.executedAt : block.timestamp;
        if (referenceTimestamp > loanMaturity) {
            referenceTimestamp = loanMaturity;
            currentAccruals +=
                (totalBorrowedStatic * LATE_REPAYMENT_FEE_RATE * (referenceTimestamp - loanMaturity)) /
                365 days /
                ONE;
        }
        uint256 timeUntilMaturity = loanMaturity - referenceTimestamp;
        currentAccruals =
            (((totalToBeRepaid - totalBorrowedStatic) * (LOAN_DURATION - timeUntilMaturity)) * ONE) /
            LOAN_DURATION /
            ONE;
    }

    /*//////////////////////////////////////////////////////////////
                                BORROWER
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IRepayableLoan
     */
    function repay() external onlyBorrower {
        _repay(Bullet.calculateRepayAmount);
    }

    /**
     * @notice Gets the amount to repay for the ongoing loan for the target tick
     * @param borrowedAmount Total amount of funds borrowed in the target tick
     * @param rate Rate of target tick
     * @param timeDeltaIntoLateRepay Time since maturity in case of late repay
     * @param lateRepaymentRate Rate of late repayment fees
     * @return amountToRepayForTick Total amount of repay of tick
     * @return tickFees Amount of protocol fees for the tick
     */
    function calculateRepayAmount(
        uint256 borrowedAmount,
        uint256 rate,
        uint256 timeDeltaIntoLateRepay,
        uint256 lateRepaymentRate
    ) internal returns (uint256 amountToRepayForTick, uint256 tickFees) {
        amountToRepayForTick = borrowedAmount.div(TimeValue.getDiscountFactor(rate, LOAN_DURATION, ONE));
        if (timeDeltaIntoLateRepay > 0)
            amountToRepayForTick = amountToRepayForTick.div(
                TimeValue.getDiscountFactor(lateRepaymentRate, timeDeltaIntoLateRepay, ONE)
            );
        tickFees = FEES_CONTROLLER.registerRepaymentFees(amountToRepayForTick - borrowedAmount);
    }

    // No docstring to prevent compilation errors due to parameters being present in docstrings but not used in function
    function getPaymentAmountForTick(
        LoanTypes.Tick memory,
        uint256,
        uint256,
        uint256
    ) internal pure override returns (uint256, uint256) {
        return (0, 0);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../../../../common/custodian/PoolCustodian.sol';
import '../Bullet.sol';

/**
 * @title BulletDeployer
 * @author Atlendis Labs
 * @notice Library created in order to isolate Bullet deployment for contract size reason
 */
library BulletDeployer {
    function deploy(
        address rolesManager,
        IPoolCustodian custodian,
        IFeesController feesController,
        bytes storage ratesAmountsConfig,
        bytes storage durationsConfig,
        string storage name,
        string storage symbol
    ) external returns (address) {
        address instance = address(
            new Bullet(rolesManager, custodian, feesController, ratesAmountsConfig, durationsConfig, name, symbol)
        );
        return instance;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../../../../common/custodian/PoolCustodian.sol';
import '../../../../common/fees/PoolTokenFeesController.sol';
import '../../LoanBase/LoanFactoryBase.sol';
import './BulletDeployer.sol';

/**
 * @title BulletFactory
 * @author Atlendis Labs
 */
contract BulletFactory is LoanFactoryBase {
    bytes32 public constant PRODUCT_ID = keccak256('BULLET');

    /**
     * @dev Constructor
     * @param factoryRegistry Address of the factory registry contract
     */
    constructor(address factoryRegistry) LoanFactoryBase(factoryRegistry) {}

    /*//////////////////////////////////////////////////////////////
                        OVERRIDES
    //////////////////////////////////////////////////////////////*/

    function deployPool(
        address rolesManager,
        PoolCustodian custodian,
        PoolTokenFeesController feesController
    ) internal override returns (address) {
        return
            BulletDeployer.deploy(
                rolesManager,
                custodian,
                feesController,
                ratesAmountsConfigTmp,
                durationsConfigTmp,
                nameTmp,
                symbolTmp
            );
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../LoanBase/interfaces/IPayableLoan.sol';
import '../LoanBase/interfaces/IRepayableLoan.sol';
import '../LoanBase/LoanBase.sol';

/**
 * @title BulletLoan
 * @author Atlendis Labs
 */
contract CouponBullet is LoanBase, IPayableLoan, IRepayableLoan {
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Constructor - pass parameters to modules
     * @param rolesManager Address of the roles manager
     * @param custodian Address of the custodian
     * @param feesController Address of the fees controller
     * @param ratesAmountsConfig Parameters-specific configurations
     * @param durationsConfig Parameters-specific configurations
     * @param name ERC721 name of the positions
     * @param symbol ERC721 symbol of the positions
     */
    constructor(
        address rolesManager,
        IPoolCustodian custodian,
        IFeesController feesController,
        bytes memory ratesAmountsConfig,
        bytes memory durationsConfig,
        string memory name,
        string memory symbol
    )
        LoanLender(name, symbol)
        LoanState(rolesManager, custodian, feesController, ratesAmountsConfig, durationsConfig)
    {}

    /*//////////////////////////////////////////////////////////////
                        PUBLIC VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc ILoan
     */
    function getPositionCurrentValue(uint256 positionId) external view override returns (uint256 positionCurrentValue) {
        return _getPaymentsLoansPositionCurrentValue(positionId);
    }

    /**
     * @inheritdoc ILoan
     */
    function getCurrentAccruals() external view override returns (uint256 currentAccruals) {
        return _getPaymentsLoanCurrentAccruals();
    }

    /*//////////////////////////////////////////////////////////////
                                BORROWER
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IRepayableLoan
     */
    function repay() external onlyBorrower {
        uint256 paymentsToMake = _getNumberOfPaymentsExpired() - paymentsDoneCount;
        _makePaymentsDue(paymentsToMake);
        _repay(CouponBullet.calculateRepayAmount);
    }

    /**
     * @notice Gets the amount to repay for the ongoing loan for the target tick
     * @param borrowedAmount Total amount of funds borrowed in the target tick
     * @param timeDeltaIntoLateRepay Time since maturity in case of late repay
     * @param lateRepaymentRate Rate of late repayment fees
     * @return amountToRepayForTick Total amount of repay of tick
     * @return tickFees Amount of protocol fees for the tick
     */
    function calculateRepayAmount(
        uint256 borrowedAmount,
        uint256,
        uint256 timeDeltaIntoLateRepay,
        uint256 lateRepaymentRate
    ) internal view returns (uint256 amountToRepayForTick, uint256 tickFees) {
        if (timeDeltaIntoLateRepay > 0) {
            amountToRepayForTick =
                borrowedAmount +
                (borrowedAmount * timeDeltaIntoLateRepay).mul(lateRepaymentRate).div(365 days * ONE);
        } else {
            amountToRepayForTick = borrowedAmount;
        }
        tickFees = 0;
    }

    /**
     * @inheritdoc IPayableLoan
     */
    function makePaymentsDue() external onlyBorrower {
        uint256 paymentsToMake = _getNumberOfPaymentsExpired() - paymentsDoneCount;
        if (paymentsToMake == 0) revert LoanErrors.NO_PAYMENTS_DUE();
        _makePaymentsDue(paymentsToMake);
    }

    /**
     * @notice Get the amount of a single payment, as well at its earnings
     * @param tick Target tick
     * @param rate Rate of the tick
     * @param paymentPeriod Period of time during two payments
     * @return couponPaymentForTick Amount of a single coupon payment
     * @return earnings Part of earnings of the payment
     */
    function getPaymentAmountForTick(
        LoanTypes.Tick memory tick,
        uint256 rate,
        uint256 paymentPeriod,
        uint256
    ) internal view override returns (uint256 couponPaymentForTick, uint256 earnings) {
        couponPaymentForTick = tick.borrowedAmount.mul(LoanLogic.getPaymentRate(rate, paymentPeriod, ONE));
        earnings = couponPaymentForTick;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../CouponBullet.sol';

/**
 * @title CouponBulletDeployer
 * @author Atlendis Labs
 * @notice Library created in order to isolate Bullet deployment for contract size reason
 */
library CouponBulletDeployer {
    function deploy(
        address rolesManager,
        IPoolCustodian custodian,
        IFeesController feesController,
        bytes storage ratesAmountsConfig,
        bytes storage durationsConfig,
        string storage name,
        string storage symbol
    ) external returns (address) {
        address instance = address(
            new CouponBullet(rolesManager, custodian, feesController, ratesAmountsConfig, durationsConfig, name, symbol)
        );
        return instance;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../../../../common/custodian/PoolCustodian.sol';
import '../../../../common/fees/PoolTokenFeesController.sol';
import '../../LoanBase/LoanFactoryBase.sol';
import './CouponBulletDeployer.sol';

/**
 * @title CouponBulletFactory
 * @author Atlendis Labs
 */
contract CouponBulletFactory is LoanFactoryBase {
    bytes32 public constant PRODUCT_ID = keccak256('CB');

    /**
     * @dev Constructor
     * @param factoryRegistry Address of the factory registry contract
     */
    constructor(address factoryRegistry) LoanFactoryBase(factoryRegistry) {}

    /*//////////////////////////////////////////////////////////////
                        OVERRIDES
    //////////////////////////////////////////////////////////////*/

    function deployPool(
        address rolesManager,
        PoolCustodian custodian,
        PoolTokenFeesController feesController
    ) internal override returns (address) {
        return
            CouponBulletDeployer.deploy(
                rolesManager,
                custodian,
                feesController,
                ratesAmountsConfigTmp,
                durationsConfigTmp,
                nameTmp,
                symbolTmp
            );
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../../../../common/custodian/PoolCustodian.sol';
import './../InstallmentLoan.sol';

/**
 * @title InstallmentLoanDeployer
 * @author Atlendis Labs
 * @notice Library created in order to isolate Bullet deployment for contract size reason
 */
library InstallmentLoanDeployer {
    function deploy(
        address rolesManager,
        PoolCustodian custodian,
        IFeesController feesController,
        bytes storage ratesAmountsConfig,
        bytes storage durationsConfig,
        string storage name,
        string storage symbol
    ) external returns (address) {
        address instance = address(
            new InstallmentLoan(
                rolesManager,
                custodian,
                feesController,
                ratesAmountsConfig,
                durationsConfig,
                name,
                symbol
            )
        );
        return instance;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../../../../common/custodian/PoolCustodian.sol';
import '../../../../common/fees/PoolTokenFeesController.sol';
import '../../LoanBase/LoanFactoryBase.sol';
import './InstallmentLoanDeployer.sol';

/**
 * @title InstallmentLoanFactory
 * @author Atlendis Labs
 */
contract InstallmentLoanFactory is LoanFactoryBase {
    bytes32 public constant PRODUCT_ID = keccak256('IL');

    /**
     * @dev Constructor
     * @param factoryRegistry Address of the factory registry contract
     */
    constructor(address factoryRegistry) LoanFactoryBase(factoryRegistry) {}

    /*//////////////////////////////////////////////////////////////
                        OVERRIDES
    //////////////////////////////////////////////////////////////*/

    function deployPool(
        address rolesManager,
        PoolCustodian custodian,
        PoolTokenFeesController feesController
    ) internal override returns (address) {
        return
            InstallmentLoanDeployer.deploy(
                rolesManager,
                custodian,
                feesController,
                ratesAmountsConfigTmp,
                durationsConfigTmp,
                nameTmp,
                symbolTmp
            );
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../LoanBase/interfaces/IPayableLoan.sol';
import '../LoanBase/LoanBase.sol';

/**
 * @title InstallmentLoan
 * @author Atlendis Labs
 */
contract InstallmentLoan is LoanBase, IPayableLoan {
    /*//////////////////////////////////////////////////////////////
                                LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using FixedPointMathLib for uint256;
    using LoanLogic for LoanTypes.Tick;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Constructor - pass parameters to modules
     * @param rolesManager Address of the roles manager
     * @param custodian Address of the custodian
     * @param feesController Address of the fees controller
     * @param ratesAmountsConfig Parameters-specific configurations
     * @param durationsConfig Parameters-specific configurations
     * @param name ERC721 name of the positions
     * @param symbol ERC721 symbol of the positions
     */
    constructor(
        address rolesManager,
        IPoolCustodian custodian,
        IFeesController feesController,
        bytes memory ratesAmountsConfig,
        bytes memory durationsConfig,
        string memory name,
        string memory symbol
    )
        LoanLender(name, symbol)
        LoanState(rolesManager, custodian, feesController, ratesAmountsConfig, durationsConfig)
    {}

    /*//////////////////////////////////////////////////////////////
                        PUBLIC VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc ILoan
     */
    function getPositionCurrentValue(uint256 positionId) external view override returns (uint256 positionCurrentValue) {
        LoanTypes.Position storage position = positions[positionId];
        LoanTypes.Tick storage tick = ticks[position.rate];

        if (position.numberOfPaymentsWithdrawn == totalPaymentsCount || tick.depositedAmount == 0) return 0;
        positionCurrentValue = _getPaymentsLoansPositionCurrentValue(positionId);

        uint256 oneInstallmentBorrowedAmountEquivalement = ((tick.borrowedAmount * position.depositedAmount * ONE) /
            totalPaymentsCount /
            tick.depositedAmount /
            ONE);
        uint256 outstandingBorrowedAmount = paymentsDoneCount * oneInstallmentBorrowedAmountEquivalement;
        if (poolPhase != LoanTypes.PoolPhase.REPAID) {
            positionCurrentValue -= outstandingBorrowedAmount;
        }
    }

    /**
     * @inheritdoc ILoan
     */
    function getCurrentAccruals() external view override returns (uint256 currentAccruals) {
        return _getPaymentsLoanCurrentAccruals();
    }

    /*//////////////////////////////////////////////////////////////
                                BORROWER
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IPayableLoan
     */
    function makePaymentsDue() external onlyBorrower {
        uint256 paymentsToMake = _getNumberOfPaymentsExpired() - paymentsDoneCount;
        if (paymentsToMake == 0) revert LoanErrors.NO_PAYMENTS_DUE();

        _makePaymentsDue(paymentsToMake);

        if (paymentsDoneCount == totalPaymentsCount) {
            poolPhase = LoanTypes.PoolPhase.REPAID;
            totalCurrentBorrowed = 0;
        } else {
            totalCurrentBorrowed -= (totalBorrowedStatic * paymentsToMake).div(totalPaymentsCount * ONE);
        }
    }

    /**
     * @notice Get the amount of a single payment, as well at its earnings
     * @param tick Target tick
     * @param rate Rate of the tick
     * @param paymentPeriod Period of time during two payments
     * @param totalPaymentsCount Total number of payments for the loan
     * @return paymentAmount Amount of a single coupon payment
     * @return earnings Part of earnings of the payment
     */
    function getPaymentAmountForTick(
        LoanTypes.Tick memory tick,
        uint256 rate,
        uint256 paymentPeriod,
        uint256 totalPaymentsCount
    ) internal view override returns (uint256 paymentAmount, uint256 earnings) {
        paymentAmount = tick
            .borrowedAmount
            .mul(ONE + LoanLogic.getPaymentRate(rate, paymentPeriod, ONE) * totalPaymentsCount)
            .div(totalPaymentsCount * ONE);
        earnings = paymentAmount - tick.borrowedAmount.div(totalPaymentsCount * ONE);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../../../../interfaces/IPool.sol';

/**
 * @title ILoan
 * @author Atlendis Labs
 */
interface ILoan {
    /**
     * @notice Retrieve the general high level information of a position
     * @param positionId ID of the position
     * @return owner Owner of the position
     * @return rate Rate of the position
     * @return depositedAmount Base deposit of the position
     * @return status Current status of the position
     */
    function getPosition(uint256 positionId)
        external
        view
        returns (
            address owner,
            uint256 rate,
            uint256 depositedAmount,
            PositionStatus status
        );

    /**
     * @notice Retrieve the repartition between borrowed amount and unborrowed amount of the position
     * @param positionId ID of the position
     * @return unborrowedAmount Amount that is not currently borrowed, and can be withdrawn
     * @return borrowedAmount Amount that is currently borrowed
     */
    function getPositionRepartition(uint256 positionId)
        external
        view
        returns (uint256 unborrowedAmount, uint256 borrowedAmount);

    /**
     * @notice Retrieve the current overall value of the position, including both borrowed and unborrowed amounts
     * @param positionId ID of the position
     * @return positionCurrentValue Current value of the position
     */
    function getPositionCurrentValue(uint256 positionId) external view returns (uint256 positionCurrentValue);

    /**
     * @notice Retrieve the share the position holds in the current loan
     * @dev Retuns 0 if there's no loan ongoing
     * @dev a result in RAY precision - 1e27
     * @param positionId ID of the position
     * @return positionShare Share of the position in the current loan
     */
    function getPositionLoanShare(uint256 positionId) external view returns (uint256 positionShare);

    /**
     * @notice Retrieves the current accruals of the ongoing loan
     * @return currentAccruals Current total accruals for the current loan
     */
    function getCurrentAccruals() external returns (uint256 currentAccruals);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

/**
 * @title ILoanBorrower
 * @author Atlendis Labs
 * @notice Interface of the LoanBorrower module contract
 *         It exposes the available methods for permissioned borrowers.
 */
interface ILoanBorrower {
    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Emitted when a borrow has been made
     *         The transferred amount is given by borrowedAmount + cancellationFeeEscrow - borrowingFee
     * @param borrower Address of the borrower
     * @param borrowedAmount Borrowed amount
     * @param borrowingFee Borrowing fee
     * @param cancellationFeeEscrow Cancelation fee at borrow time
     */
    event Borrowed(
        address indexed borrower,
        uint256 borrowedAmount,
        uint256 borrowingFee,
        uint256 cancellationFeeEscrow
    );

    /**
     * @notice Emitted when a payment has been made
     * @param borrower Address of the borrower
     * @param numberOfPaymentsMade Total number of payments made during the action
     * @param paidAmount Total amount of all payments made during the action
     * @param repayFee Amount of fee taken
     */
    event PaymentMade(address indexed borrower, uint256 numberOfPaymentsMade, uint256 paidAmount, uint256 repayFee);

    /**
     * @notice Emitted when a loan has been repaid
     *         Total paid amount by borrower is given by repaidAmount + atlendisFee
     * @param borrower Address of the borrower
     * @param repaidAmount Repaid amount
     * @param repayFee Amount of fee taken
     */
    event PrincipalRepaid(address indexed borrower, uint256 repaidAmount, uint256 repayFee);

    /**
     * @notice Emitted when the remaining cancellation fee has been withdrawn
     * @param amount Withdrawn remaining cancellation fee amount
     */
    event EscrowWithdrawn(address indexed contractAddress, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                                FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Retrieve the current maturity
     * @return maturity The current maturity
     */
    function getMaturity() external view returns (uint256 maturity);

    /**
     * @notice Enable the book building phase by depositing in escrow the cancellation fee amount of tokens
     *
     * Emits a {BookBuildingPhaseEnabled} event
     */
    function enableBookBuildingPhase() external;

    /**
     * @notice Withdraw the remaining escrow
     * @param to Address to which the remaining escrow amount is transferred
     *
     * Emits a {EscrowWithdrawn} event
     */
    function withdrawRemainingEscrow(address to) external;

    /**
     * @notice Borrow against the order book state
     * @param amount Amount to borrow
     * @param to Address to which the loaned amount is transferred
     *
     * Emits a {Borrowed} event
     */
    function borrow(uint256 amount, address to) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../../../../common/fees/IFeesController.sol';
import '../../../../common/non-standard-repayment/INonStandardRepaymentModule.sol';
import '../../../../interfaces/ITimelock.sol';
import '../../../../libraries/PoolTimelockLogic.sol';

/**
 * @title ILoanGovernance
 * @author Atlendis Labs
 * @notice Interface of the Loan Governance module contract
 *         It is in charge of the governance part of the contract
 *         In details:
 *           - manage borrowers,
 *           - enable origination phase,
 *           - able to cancel loan or default.
 *          Extended by the LoanBase contract
 */
interface ILoanGovernance is ITimelock {
    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Emitted when the origination phase has started
     * @param contractAddress Address of the contract
     */
    event OriginationPhaseEnabled(address contractAddress);

    /**
     * @notice Cancel the loan and consume the escrow in fees
     * @param contractAddress Address of the contract
     * @param remainingEscrow Remaining amount in escrow after fees distribution
     */
    event LoanOriginationCancelled(address contractAddress, uint256 remainingEscrow);

    /**
     * @notice Emitted when fees are withdrawn to the fees controller
     * @param fees Amount of fees withdrawn to the fees controller
     */
    event FeesWithdrawn(uint256 fees);

    /**
     * @notice Emitted when the fees controller is set
     * @param feesController Address of the fees controller
     */
    event FeesControllerSet(address feesController);

    /**
     * @notice Emitted when a non standard repayment procedure is started
     * @param nonStandardRepaymentModule Address of the non standard repayment module contract
     * @param delay Timelock delay
     */
    event NonStandardRepaymentProcedureStarted(address nonStandardRepaymentModule, uint256 delay);

    /**
     * @notice Emitted when a rescue procedure has started
     * @param recipient Recipient address of the unborrowed funds
     * @param delay Timelock delay
     */
    event RescueProcedureStarted(address recipient, uint256 delay);

    /**
     * @notice Emitted when the minimum deposit amount has been updated
     * @param minDepositAmount Updated value of the minimum deposit amount
     */
    event MinDepositAmountUpdated(uint256 minDepositAmount);

    /*//////////////////////////////////////////////////////////////
                                FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Enable the origination phase
     *
     * Emits a {OriginationPhaseEnabled} event
     */
    function enableOriginationPhase() external;

    /**
     * @notice Cancel the loan
     * @param redistributeCancelFee Boolean deciding whether the cancel fees gets redistributed to lenders or not
     *
     * Emits a {LoanOriginationCancelled} event
     */
    function cancelLoan(bool redistributeCancelFee) external;

    /**
     * @notice Withdraw fees to the fees controller
     *
     * Emits a {FeesWithdrawn} event
     */
    function withdrawFees() external;

    /**
     * @notice Set the fees controller contract address
     * @param feesController Address of the fees controller
     *
     * Emits a {FeesControllerSet} event
     */
    function setFeesController(IFeesController feesController) external;

    /**
     * @notice Starts a non standard repayment procedure by initiating a timelock for
     * - Stops all native actions possible in the pool
     * - Sends the unborrowed funds to the non standard repayment procedure contract
     * - Initializes the non standard repayment procedure contract
     * @param nonStandardRepaymentModule Address of the non standard repayment module contract
     * @param delay Timelock delay
     *
     * Emits a {NonStandardRepaymentProcedureStarted} event
     */
    function startNonStandardRepaymentProcedure(INonStandardRepaymentModule nonStandardRepaymentModule, uint256 delay)
        external;

    /**
     * @notice Start a rescue procedure by initiating a timelock for
     * - Stops all native actions possible in the pool
     * - Sends the unborrowed funds to a recipient address
     * @param recipient Address to which the funds will be sent
     * @param delay Timelock delay
     *
     * Emits a {RescueProcedureStarted} event
     */
    function startRescueProcedure(address recipient, uint256 delay) external;

    /**
     * @notice Update the minimum deposit amount
     * @param minDepositAmount New value of the minimum deposit amount
     *
     * Emits a {MinDepositAmountUpdated} event
     */
    function updateMinDepositAmount(uint256 minDepositAmount) external;

    /**
     * @notice Retrieve the current timelock
     * @return timelock The current timelock, may be empty
     */
    function getTimelock() external view returns (PoolTimelock memory timelock);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

/**
 * @title ILoanLender
 * @author Atlendis Labs
 * @notice Interface of the LoanLender module contract
 *         It exposes the available methods for the lenders
 */
interface ILoanLender {
    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Emitted when a deposit has been made
     * @param positionId ID of the position associated to the deposit
     * @param owner Address of the position owner
     * @param rate Chosen rate at which the funds can be borrowed
     * @param amount Deposited amount
     */
    event Deposited(uint256 indexed positionId, address indexed owner, uint256 rate, uint256 amount);

    /**
     * @notice Emitted when a rate has been updated
     * @param positionId ID of the position
     * @param owner Address of the position owner
     * @param oldRate Previous rate
     * @param newRate Updated rate
     */
    event RateUpdated(uint256 indexed positionId, address indexed owner, uint256 oldRate, uint256 newRate);

    /**
     * @notice Emitted when a partial withdraw has been made
     * @param positionId ID of the position
     * @param owner Address of the position owner
     * @param amount Withdrawn amount
     */
    event PartiallyWithdrawn(uint256 indexed positionId, address indexed owner, uint256 amount);

    /**
     * @notice Emitted when a withdraw has been made
     * @param positionId ID of the position
     * @param owner Address of the position owner
     * @param amount Withdrawn amount
     */
    event Withdrawn(uint256 indexed positionId, address indexed owner, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                                FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deposit amount of tokens at a chosen rate
     * @param rate Chosen rate at which the funds can be borrowed
     * @param amount Deposited amount of tokens
     * @param to Recipient address for the position associated to the deposit
     * @return positionId ID of the position
     *
     * Emits a {Deposited} event
     */
    function deposit(
        uint256 rate,
        uint256 amount,
        address to
    ) external returns (uint256 positionId);

    /**
     * @notice Update a position rate
     * @param positionId The ID of the position
     * @param newRate The new rate of the position
     *
     * Emits a {RateUpdated} event
     */
    function updateRate(uint256 positionId, uint256 newRate) external;

    /**
     * @notice Withdraw the position fully
     * @param positionId ID of the position
     *
     * Emits a {Withdrawn} event
     */
    function withdraw(uint256 positionId) external;

    /**
     * @notice Withdraw any amount up to the full position deposited amount
     * @dev Can only be used during the
     * @param positionId ID of the position
     * @param amount Amount to withdraw
     *
     * Emits a {PartiallyWithdrawn} event
     */
    function withdraw(uint256 positionId, uint256 amount) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../../../../common/rewards/IRewardsManager.sol';

/**
 * @title ILoanRewardsManager
 * @author Atlendis Labs
 * @notice Interface of the Loan Rewards Manager contract
 *         This interface completes the core IRewardsManager interface.
 *         Staking and batch staking is allowed, the locking duration is derived from the Loan contract.
 */
interface ILoanRewardsManager is IRewardsManager {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    /**
     * Thrown when the book building phase is over
     */
    error BOOK_BUILDING_PHASE_OVER();

    /*//////////////////////////////////////////////////////////////
                                FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Stake a position in the contract
     *         The locking duration for the term rewards is chosen as the remaining time until end of book building phase plus the loan duration
     *         An associated staked position NFT is created for the owner
     * @param positionId ID of the position
     *
     * Emits a {PositionStaked} event
     */
    function stake(uint256 positionId) external;

    /**
     * @notice Stake a batch of positions in the contract
     *         The locking duration for the term rewards is chosen as the remaining time until end of book building phase plus the loan duration
     *         For each staked position, an associated staked position NFT is created for the owner
     * @param positionIds Array of IDs of the positions
     *
     * Emits a {PositionStaked} event for each staked position
     */
    function batchStake(uint256[] calldata positionIds) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

interface ILoanState {
    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Emitted when the book building phase has started
     * @param contractAddress Address of the contract
     */
    event BookBuildingPhaseEnabled(address contractAddress, uint256 cancellationFeeEscrow);

    /*//////////////////////////////////////////////////////////////
                                FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get the timestamp of the end of the book building phase
     * @return bookBuildingPhaseEndTimestamp The timestamp of the end of the book building phase
     */
    function getBookBuildingPhaseEndTimestamp() external view returns (uint256 bookBuildingPhaseEndTimestamp);

    /**
     * @notice Retrieve the loan duration
     * @return loanDuration The loan duration
     */
    function LOAN_DURATION() external view returns (uint256 loanDuration);

    /**
     * @notice Retrieve the book building period duration
     * @return bookBuildingPeriodDuration The book building period duration
     */
    function BOOK_BUILDING_PERIOD_DURATION() external view returns (uint256 bookBuildingPeriodDuration);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

/**
 * @title IPayableLoan
 * @author Atlendis Labs
 */
interface IPayableLoan {
    /**
     * @notice Make a payment depending on the loan parameters and schedule
     */
    function makePaymentsDue() external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

/**
 * @title IRepayableLoan
 * @author Atlendis Labs
 */
interface IRepayableLoan {
    /**
     * @notice Repay an ongoing loan
     * @dev Depending on the loan type, repayment can be only principal or both principal and interests
     */
    function repay() external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import './LoanTypes.sol';

/**
 * @title LoanErrors
 * @author Atlendis Labs
 */
library LoanErrors {
    error LOAN_INVALID_RATE_BOUNDARIES(); // "Invalid rate boundaries parameters"
    error LOAN_INVALID_ZERO_RATE_SPACING(); // "Can not have rate spacing to zero"
    error LOAN_INVALID_RATE_PARAMETERS(); // "Invalid rate parameters"
    error LOAN_INVALID_PERCENTAGE_VALUE(); // "Invalid percentage value"

    error LOAN_OUT_OF_BOUND_MIN_RATE(); // "Input rate is below min rate"
    error LOAN_OUT_OF_BOUND_MAX_RATE(); // "Input rate is above max rate"
    error LOAN_INVALID_RATE_SPACING(); // "Input rate is invalid with respect to rate spacing"

    error LOAN_ONLY_GOVERNANCE(); // "Operation restricted to governance only"
    error LOAN_ONLY_LENDER(); // "Operation restricted to lender only"
    error LOAN_ONLY_BORROWER(); // "Operation restricted to borrower only"
    error LOAN_ONLY_OPERATOR(); // "Operation restricted to operator only"

    error LOAN_INVALID_PHASE(); // "Phase is invalid for this operation"
    error LOAN_DEPOSIT_AMOUNT_TOO_LOW(); // "Deposit amount is too low"
    error LOAN_MGMT_ONLY_OWNER(); // "Only the owner of the position token can manage it (update rate, withdraw)";
    error LOAN_TIMELOCK(); // "Cannot withdraw or update rate in the same block as deposit";
    error LOAN_BOOK_BUILDING_TIME_NOT_OVER(); // "Book building time window is not over";
    error LOAN_ALLOWED_ONLY_BOOK_BUILDING_PHASE(); // "Action only allowed during the book building phase";
    error LOAN_REPAY_TOO_EARLY(); // "Loan cannot be early repaid";
    error LOAN_EARLY_PARTIAL_REPAY_NOT_ALLOWED(); // "Partial repays are not allowed before maturity or during not allowed phases";
    error LOAN_NOT_ENOUGH_FUNDS_AVAILABLE(); // "Not enough funds available in pool"
    error LOAN_WITHDRAW_AMOUNT_TOO_LARGE(); // "Cannot withdraw more than the position amount"
    error LOAN_WITHDRAW_AMOUNT_TOO_LOW(); // "Cannot withdraw less than the min deposit amount"
    error LOAN_REMAINING_AMOUNT_TOO_LOW(); // "Remaining amount in position after withdraw is less than the minimum amount"
    error LOAN_WITHDRAWAL_NOT_ALLOWED(); // "Withdrawal not possible"
    error LOAN_ZERO_BORROW_AMOUNT_NOT_ALLOWED(); // "Borrowing from an empty pool is not allowed"
    error LOAN_ORIGINATION_PHASE_EXPIRED(); // "Origination phase has expired"
    error LOAN_ORIGINATION_PERIOD_STILL_ACTIVE(); // "Origination period not expired yet"
    error LOAN_WRONG_INPUT(); // The specified input does not pass validation
    error LOAN_INSTALLMENTS_TOO_LOW(); // "Installment parameter too low"
    error NO_PAYMENTS_DUE(); // "No payment is due"
    error LOAN_POSITIONS_NOT_EXIST(); // "Position does not exits";
    error LOAN_MATURITY_REACHED(); // "Loan maturity has been reached"
    error LOAN_BORROW_AMOUNT_OUT_OF_RANGE(); // "Borrow amount has to be between min and target origination"
    error LOAN_BORROW_AMOUNT_TOO_HIGH(); // "Cannot borrow more than the pool deposits"

    error LOAN_INVALID_FEES_CONTROLLER_MANAGED_POOL(); // "Managed pool of fees controller is not the instance one"
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../../../../libraries/FixedPointMathLib.sol';
import './LoanErrors.sol';
import './LoanTypes.sol';

/**
 * @title LoanLogic
 * @author Atlendis Labs
 */
library LoanLogic {
    using FixedPointMathLib for uint256;

    /**
     * @dev Gets the number of payments that are due and not yet paid
     * @param referenceTimestamp Either non standard procedure start or block timestamp
     * @param borrowTimestamp Borrow timestamp
     * @param loanDuration Duration of the loan
     * @param repaymentPeriodDuration Period of time before maturity when the borrower can repay
     * @param paymentPeriod Period of time during two payments
     * @return paymentsDueCount Total number of payments due
     */
    function getNumberOfPaymentsExpired(
        uint256 referenceTimestamp,
        uint256 borrowTimestamp,
        uint256 loanDuration,
        uint256 repaymentPeriodDuration,
        uint256 paymentPeriod
    ) internal pure returns (uint256 paymentsDueCount) {
        uint256 loanMaturity = borrowTimestamp + loanDuration;
        if (referenceTimestamp > loanMaturity - repaymentPeriodDuration) return loanDuration / paymentPeriod;
        uint256 maturityCappedTimestamp = referenceTimestamp > loanMaturity ? loanMaturity : referenceTimestamp;
        return (maturityCappedTimestamp - borrowTimestamp) / paymentPeriod;
    }

    /**
     * @dev Gets the global rate of a single payment
     * @param rate Rate of the loan
     * @param paymentPeriod Period of time during two payments
     * @param one Precision
     * @return paymentRate Actual rate of a payment
     */
    function getPaymentRate(
        uint256 rate,
        uint256 paymentPeriod,
        uint256 one
    ) internal pure returns (uint256 paymentRate) {
        paymentRate = (rate * one * paymentPeriod) / 365 days / one;
    }

    /**
     * @dev Get the total amount of payment to withdraw for a position
     * @param tick Target tick
     * @param position Target position
     * @param paymentsDoneCount Total number of payments done
     * @return paymentsAmountToWithdraw Total amount of payment to be withdrawn for the target position
     * @return earnings Part of net earnings of the payments amount to be withdrawn
     */
    function getPaymentsAmountToWithdraw(
        LoanTypes.Tick storage tick,
        LoanTypes.Position storage position,
        uint256 paymentsDoneCount
    ) internal view returns (uint256 paymentsAmountToWithdraw, uint256 earnings) {
        uint256 numberOfPaymentsDue = paymentsDoneCount - position.numberOfPaymentsWithdrawn;
        if (numberOfPaymentsDue > 0) {
            paymentsAmountToWithdraw = (numberOfPaymentsDue * position.depositedAmount)
                .mul(tick.singlePaymentAmount)
                .div(tick.depositedAmount);
            earnings = (numberOfPaymentsDue * position.depositedAmount).mul(tick.singlePaymentEarnings).div(
                tick.depositedAmount
            );
        }
    }

    /**
     * @dev Distributes escrowed cancellation fee to tick
     * @param tick Target tick
     * @param cancellationFeePercentage Percentage of the total borrowed amount to be kept in escrow
     * @param remainingEscrow Remaining amount in escrow
     */
    function repayCancelFeeForTick(
        LoanTypes.Tick storage tick,
        uint256 cancellationFeePercentage,
        uint256 remainingEscrow,
        bool redistributeCancelFee
    ) internal returns (uint256 cancelFeeForTick) {
        if (redistributeCancelFee) {
            if (cancellationFeePercentage.mul(tick.depositedAmount) > remainingEscrow) {
                cancelFeeForTick = remainingEscrow;
            } else {
                cancelFeeForTick = cancellationFeePercentage.mul(tick.depositedAmount);
            }
        }
        tick.repaidAmount = tick.depositedAmount + cancelFeeForTick;
    }

    /**
     * @dev Deposit amount to tick
     * @param tick Target tick
     * @param amount Amount to be deposited
     */
    function depositToTick(LoanTypes.Tick storage tick, uint256 amount) internal {
        tick.depositedAmount += amount;
    }

    /**
     * @dev Transfer an amount from one tick to another
     * @param currentTick Tick for which the deposited amount will decrease
     * @param newTick Tick for which the deposited amount will increase
     * @param amount The transferred amount
     */
    function updateTicksDeposit(
        LoanTypes.Tick storage currentTick,
        LoanTypes.Tick storage newTick,
        uint256 amount
    ) internal {
        currentTick.depositedAmount -= amount;
        newTick.depositedAmount += amount;
    }

    /**
     * @dev Register borrowed amount in tick
     * @param tick Target tick
     * @param amountToBorrow The amount to borrow
     * @return borrowComplete True if the deposited amount of the tick is larger than the amount to borrow
     * @return remainingAmount Remaining amount to borrow
     */
    function borrowFromTick(LoanTypes.Tick storage tick, uint256 amountToBorrow)
        internal
        returns (bool borrowComplete, uint256 remainingAmount)
    {
        if (tick.depositedAmount == 0) return (false, amountToBorrow);

        if (tick.depositedAmount < amountToBorrow) {
            amountToBorrow -= tick.depositedAmount;
            tick.borrowedAmount += tick.depositedAmount;
            return (false, amountToBorrow);
        }

        if (tick.depositedAmount >= amountToBorrow) {
            tick.borrowedAmount += amountToBorrow;
            return (true, 0);
        }
    }

    /**
     * @dev Register amounts for a single payment in the target tick
     * @param tick Target tick
     * @param paymentAmount Total amount paid for a single payment
     * @param earningsAmount Earnings part of the payment made
     */
    function registerPaymentsAmounts(
        LoanTypes.Tick storage tick,
        uint256 paymentAmount,
        uint256 earningsAmount
    ) internal {
        tick.singlePaymentAmount = paymentAmount;
        tick.singlePaymentEarnings = earningsAmount;
    }

    /**
     * @dev Derive the allowed amount to be withdrawn
     *      The sequence of conditional branches is relevant for correct logic
     *      Decrease tick deposited amount if the contract is in the Book Building phase
     * @param tick Target tick
     * @param poolPhase The current pool phase
     * @param depositedAmount The original deposited amount in the position
     * @param didPartiallyWithdraw True if the position has already been partially withdrawn
     * @return amountToWithdraw The allowed amount to be withdrawn
     * @return unborrowedAmountWithdrawn True if it is a partial withdraw
     */
    function withdrawFromTick(
        LoanTypes.Tick storage tick,
        LoanTypes.PoolPhase poolPhase,
        uint256 depositedAmount,
        bool didPartiallyWithdraw
    ) external returns (uint256 amountToWithdraw, bool unborrowedAmountWithdrawn) {
        (uint256 unborrowedAmount, , bool partialWithdraw) = getInitialPositionRepartition(
            tick,
            poolPhase,
            depositedAmount,
            didPartiallyWithdraw
        );
        if (poolPhase == LoanTypes.PoolPhase.BOOK_BUILDING) {
            tick.depositedAmount -= unborrowedAmount;
        }

        return (unborrowedAmount, partialWithdraw);
    }

    /**
     * @dev Gets the position repartition before payments addition
     * @param tick Target tick
     * @param poolPhase The current pool phase
     * @param depositedAmount The original deposited amount in the position
     * @param didPartiallyWithdraw True if the position has already been partially withdrawn
     * @return unborrowedAmount Unborrowed part of the position
     * @return borrowedAmount Borrowed part of the position
     * @return partialWithdraw Boolean to signal whether the position has been already partially withdrawn
     */
    function getInitialPositionRepartition(
        LoanTypes.Tick storage tick,
        LoanTypes.PoolPhase poolPhase,
        uint256 depositedAmount,
        bool didPartiallyWithdraw
    )
        public
        view
        returns (
            uint256 unborrowedAmount,
            uint256 borrowedAmount,
            bool partialWithdraw
        )
    {
        /// @dev The order of conditional statements in this function is relevant to the correctness of the logic
        if (poolPhase == LoanTypes.PoolPhase.BOOK_BUILDING) {
            unborrowedAmount = depositedAmount;
            return (unborrowedAmount, borrowedAmount, partialWithdraw);
        }

        // partial withdraw during borrow before repay
        if (
            tick.borrowedAmount > 0 &&
            tick.borrowedAmount < tick.depositedAmount &&
            (poolPhase == LoanTypes.PoolPhase.ISSUED || poolPhase == LoanTypes.PoolPhase.NON_STANDARD)
        ) {
            uint256 unborrowedPart = depositedAmount.mul(tick.depositedAmount - tick.borrowedAmount).div(
                tick.depositedAmount
            );
            unborrowedAmount = didPartiallyWithdraw ? 0 : unborrowedPart;
            borrowedAmount = depositedAmount - unborrowedPart;
            partialWithdraw = true;
            return (unborrowedAmount, borrowedAmount, partialWithdraw);
        }

        // if tick was not matched
        if (tick.borrowedAmount == 0 && poolPhase != LoanTypes.PoolPhase.CANCELLED) {
            unborrowedAmount = depositedAmount;
            return (unborrowedAmount, borrowedAmount, partialWithdraw);
        }

        // If loan has not been paid back and the tick was fully filled
        if (tick.depositedAmount == tick.borrowedAmount && tick.repaidAmount == 0) {
            borrowedAmount = depositedAmount;
            return (unborrowedAmount, borrowedAmount, partialWithdraw);
        }
        // If full fill and repaid or origination was cancelled
        if (
            (tick.depositedAmount == tick.borrowedAmount && poolPhase == LoanTypes.PoolPhase.REPAID) ||
            poolPhase == LoanTypes.PoolPhase.CANCELLED
        ) {
            unborrowedAmount = depositedAmount.mul(tick.repaidAmount).div(tick.depositedAmount);
            return (unborrowedAmount, borrowedAmount, partialWithdraw);
        }

        // If loan has been paid back and the tick was partially filled
        if (tick.depositedAmount > tick.borrowedAmount && poolPhase == LoanTypes.PoolPhase.REPAID) {
            uint256 unborrowedAmountToWithdraw = didPartiallyWithdraw
                ? 0
                : depositedAmount.mul(tick.depositedAmount - tick.borrowedAmount).div(tick.depositedAmount);
            unborrowedAmount =
                depositedAmount.mul(tick.repaidAmount).div(tick.depositedAmount) +
                unborrowedAmountToWithdraw;
            return (unborrowedAmount, borrowedAmount, partialWithdraw);
        }
        return (unborrowedAmount, borrowedAmount, partialWithdraw);
    }

    function getPositionRepartition(
        LoanTypes.Tick storage tick,
        LoanTypes.Position storage position,
        LoanTypes.PoolPhase poolPhase,
        uint256 paymentsDoneCount
    ) external view returns (uint256 unborrowedAmount, uint256 borrowedAmount) {
        (unborrowedAmount, borrowedAmount, ) = getInitialPositionRepartition(
            tick,
            poolPhase,
            position.depositedAmount,
            position.unborrowedAmountWithdrawn
        );

        uint256 paymentOutstanding = paymentsDoneCount - position.numberOfPaymentsWithdrawn;

        unborrowedAmount += paymentOutstanding * tick.singlePaymentAmount;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

/**
 * @title PoolDataTypes library
 * @dev Defines the structs and enums related to the pool
 */
library LoanTypes {
    enum PoolPhase {
        INACTIVE,
        BOOK_BUILDING,
        ORIGINATION,
        ISSUED,
        REPAID,
        NON_STANDARD,
        CANCELLED
    }

    struct Tick {
        uint256 depositedAmount;
        uint256 borrowedAmount;
        uint256 repaidAmount;
        uint256 singlePaymentAmount;
        uint256 singlePaymentEarnings;
    }

    struct Position {
        uint256 depositedAmount;
        uint256 rate;
        uint256 depositBlockNumber;
        bool unborrowedAmountWithdrawn;
        uint256 numberOfPaymentsWithdrawn;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../../../interfaces/IPool.sol';
import './interfaces/ILoan.sol';
import './modules/LoanGovernance.sol';
import './modules/LoanLender.sol';
import './modules/LoanBorrower.sol';

/**
 * @title LoanBase
 * @author Atlendis Labs
 * @notice Base contract for all Loans products
 */
abstract contract LoanBase is ILoan, LoanState, LoanGovernance, LoanLender, LoanBorrower {
    /*//////////////////////////////////////////////////////////////
                                LIBRARIES
    //////////////////////////////////////////////////////////////*/
    using FixedPointMathLib for uint256;
    using LoanLogic for LoanTypes.Tick;

    /*//////////////////////////////////////////////////////////////
                        PUBLIC VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc ILoan
     */
    function getPosition(uint256 positionId)
        public
        view
        returns (
            address owner,
            uint256 rate,
            uint256 depositedAmount,
            PositionStatus status
        )
    {
        LoanTypes.Position memory position = positions[positionId];
        LoanTypes.Tick storage tick = ticks[position.rate];
        owner = ownerOf(positionId);
        depositedAmount = position.depositedAmount;
        rate = position.rate;
        if (poolPhase == LoanTypes.PoolPhase.BOOK_BUILDING) {
            status = PositionStatus.AVAILABLE;
        } else if (poolPhase == LoanTypes.PoolPhase.ISSUED) {
            if (tick.borrowedAmount == 0) {
                status = PositionStatus.UNAVAILABLE;
            } else {
                status = PositionStatus.BORROWED;
            }
        } else {
            status = PositionStatus.UNAVAILABLE;
        }
    }

    /**
     * @inheritdoc ILoan
     */
    function getPositionRepartition(uint256 positionId)
        public
        view
        override
        returns (uint256 unborrowedAmount, uint256 borrowedAmount)
    {
        (unborrowedAmount, borrowedAmount) = LoanLogic.getPositionRepartition(
            ticks[positions[positionId].rate],
            positions[positionId],
            poolPhase,
            paymentsDoneCount
        );
    }

    /**
     * @inheritdoc ILoan
     */
    function getPositionCurrentValue(uint256 positionId) external view virtual returns (uint256 positionCurrentValue);

    /**
     * @inheritdoc ILoan
     */
    function getPositionLoanShare(uint256 positionId) external view returns (uint256 positionLoanShare) {
        if (totalBorrowedStatic == 0) return 0;
        (, uint256 borrowedAmount) = getPositionRepartition(positionId);
        return borrowedAmount.mul(RAY).div(totalBorrowedStatic);
    }

    /**
     * @inheritdoc ILoan
     */
    function getCurrentAccruals() external view virtual returns (uint256 currentAccruals);

    /**
     * @notice Returns the total amount that is currently borrowed in the pool
     * Loans product maintaining two borrowed amounts, this function is made
     * to retain a similar interface as other products
     */
    function totalBorrowed() external view returns (uint256) {
        return totalCurrentBorrowed;
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get the current loan accruals for a payments based loan
     * @return currentAccruals The total current accruals for the ongoing loan
     */
    function _getPaymentsLoanCurrentAccruals() internal view returns (uint256 currentAccruals) {
        uint256 referenceTimestamp = timelock.executedAt > 0 ? timelock.executedAt : block.timestamp;
        uint256 numberOfPaymentsExpired = _getNumberOfPaymentsExpired();
        uint256 paymentsDue = numberOfPaymentsExpired - paymentsDoneCount;
        uint256 timeIntoCurrentPayment = paymentsDoneCount == totalPaymentsCount ||
            numberOfPaymentsExpired == totalPaymentsCount
            ? 0
            : (referenceTimestamp - borrowTimestamp) - numberOfPaymentsExpired * PAYMENT_PERIOD;

        uint256 totalMissedEarnings;
        uint256 totalRunningEarnings;
        uint256 currentInterestRate = MIN_RATE;
        while (currentInterestRate <= MAX_RATE) {
            LoanTypes.Tick storage tick = ticks[currentInterestRate];
            if (tick.borrowedAmount > 0) {
                uint256 earnings = tick.singlePaymentEarnings;
                totalMissedEarnings += earnings * paymentsDue;
                totalRunningEarnings += (earnings * timeIntoCurrentPayment * ONE) / PAYMENT_PERIOD / ONE;
            }

            currentInterestRate += RATE_SPACING;
        }

        currentAccruals = totalMissedEarnings + totalRunningEarnings;
    }

    /**
     * @notice Get the current position value for a payments based loan
     * @param positionId ID of the position to withdraw
     * @return positionCurrentValue Current value of the position
     */
    function _getPaymentsLoansPositionCurrentValue(uint256 positionId)
        internal
        view
        returns (uint256 positionCurrentValue)
    {
        (uint256 unborrowedAmount, uint256 borrowedAmount) = getPositionRepartition(positionId);

        uint256 paymentAmount = ticks[positions[positionId].rate].singlePaymentEarnings;
        uint256 numberOfPaymentsExpired = _getNumberOfPaymentsExpired();
        if (numberOfPaymentsExpired > paymentsDoneCount) {
            unborrowedAmount += (numberOfPaymentsExpired - paymentsDoneCount) * paymentAmount;
        }
        positionCurrentValue = unborrowedAmount + borrowedAmount;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../../../common/custodian/PoolCustodian.sol';
import '../../../common/fees/PoolTokenFeesController.sol';
import '../../../common/roles-manager/StandardRolesManager.sol';
import '../../../interfaces/IProductFactory.sol';

/**
 * @title LoanFactoryBase
 * @author Atlendis Labs
 */
abstract contract LoanFactoryBase is IProductFactory {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Thrown when invalid payment period input is given
     */
    error PAYMENT_PERIOD();

    /**
     * @notice Thrown when the repayment period is higher than the payment period
     */
    error REPAYMENT_PERIOD_TOO_HIGH();

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    address public immutable FACTORY_REGISTRY;

    // Temporary storage for deployment inputs in order to not copy in memory for external lib call
    bytes ratesAmountsConfigTmp;
    bytes durationsConfigTmp;
    string nameTmp;
    string symbolTmp;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Constructor
     * @param factoryRegistry Address of the factory registry contract
     */
    constructor(address factoryRegistry) {
        FACTORY_REGISTRY = factoryRegistry;
    }

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IProductFactory
     */
    function deploy(
        address governance,
        bytes memory custodianConfig,
        bytes memory feesControllerConfig,
        bytes memory ratesAmountsConfig,
        bytes memory durationsConfig,
        string memory name,
        string memory symbol
    ) external returns (address instance) {
        if (msg.sender != FACTORY_REGISTRY) revert UNAUTHORIZED();

        StandardRolesManager rolesManager = new StandardRolesManager(address(this));
        PoolCustodian custodian = deployCustodian(rolesManager, custodianConfig);
        PoolTokenFeesController feesController = deployFeesController(rolesManager, feesControllerConfig);

        ratesAmountsConfigTmp = ratesAmountsConfig;
        durationsConfigTmp = durationsConfig;
        nameTmp = name;
        symbolTmp = symbol;

        instance = deployLoan(rolesManager, custodian, feesController);

        delete ratesAmountsConfigTmp;
        delete durationsConfigTmp;
        delete nameTmp;
        delete symbolTmp;

        feesController.initializePool(instance);
        custodian.initializePool(instance);

        rolesManager.grantRole(rolesManager.OPERATOR_ROLE(), instance);
        rolesManager.grantRole(rolesManager.DEFAULT_ADMIN_ROLE(), governance);
        rolesManager.renounceRole(rolesManager.DEFAULT_ADMIN_ROLE(), address(this));
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL METHODS
    //////////////////////////////////////////////////////////////*/

    function deployCustodian(StandardRolesManager rolesManager, bytes memory custodianConfig)
        internal
        returns (PoolCustodian)
    {
        if (custodianConfig.length != 96) revert INVALID_PRODUCT_PARAMS();
        (address token, address adapter, address yieldProvider) = abi.decode(
            custodianConfig,
            (address, address, address)
        );
        return new PoolCustodian(rolesManager, ERC20(token), adapter, yieldProvider);
    }

    function deployFeesController(StandardRolesManager rolesManager, bytes memory feesControllerConfig)
        internal
        returns (PoolTokenFeesController)
    {
        if (feesControllerConfig.length != 224) revert INVALID_PRODUCT_PARAMS();
        (
            uint256 managementFeesRate,
            uint256 exitFeesInflectionThreshold,
            uint256 exitFeesMinRate,
            uint256 exitFeesInflectionRate,
            uint256 exitFeesMaxRate,
            uint256 borrowingFeesRate,
            uint256 repaymentFeesRate
        ) = abi.decode(feesControllerConfig, (uint256, uint256, uint256, uint256, uint256, uint256, uint256));
        return
            new PoolTokenFeesController(
                rolesManager,
                managementFeesRate,
                exitFeesInflectionThreshold,
                exitFeesMinRate,
                exitFeesInflectionRate,
                exitFeesMaxRate,
                borrowingFeesRate,
                repaymentFeesRate
            );
    }

    function deployLoan(
        StandardRolesManager rolesManager,
        PoolCustodian custodian,
        PoolTokenFeesController feesController
    ) private returns (address) {
        if (ratesAmountsConfigTmp.length != 256) revert INVALID_PRODUCT_PARAMS();
        if (durationsConfigTmp.length != 160) revert INVALID_PRODUCT_PARAMS();

        (
            uint256 minRate,
            uint256 maxRate,
            uint256 rateSpacing,
            uint256 targetOrigination,
            ,
            uint256 cancellationFeePc,
            ,
            uint256 minOrigination
        ) = abi.decode(ratesAmountsConfigTmp, (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256));

        (uint256 loanDuration, uint256 repaymentPeriod, , , uint256 paymentPeriod) = abi.decode(
            durationsConfigTmp,
            (uint256, uint256, uint256, uint256, uint256)
        );

        uint256 ONE = 10**custodian.getAssetDecimals();

        if (minOrigination > targetOrigination) revert INVALID_ORIGINATION_PARAMETERS();
        if (minRate >= maxRate) revert INVALID_RATE_BOUNDARIES();
        if (rateSpacing == 0) revert INVALID_ZERO_RATE_SPACING();
        if ((maxRate - minRate) % rateSpacing != 0) revert INVALID_RATE_PARAMETERS();
        if (cancellationFeePc >= ONE) revert INVALID_PERCENTAGE_VALUE();

        if (paymentPeriod > 0 && loanDuration % paymentPeriod != 0) revert PAYMENT_PERIOD();
        if (paymentPeriod > 0 && repaymentPeriod > paymentPeriod) revert REPAYMENT_PERIOD_TOO_HIGH();

        return deployPool(address(rolesManager), custodian, feesController);
    }

    function deployPool(
        address rolesManager,
        PoolCustodian custodian,
        PoolTokenFeesController feesController
    ) internal virtual returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../../../common/rewards/RewardsManager.sol';
import './interfaces/ILoanRewardsManager.sol';
import './interfaces/ILoan.sol';
import './interfaces/ILoanState.sol';

/**
 * @title LoanRewardsManager Manager
 * @author Atlendis Labs
 * @notice Implementation of the ILoanRewardsManager
 */
contract LoanRewardsManager is RewardsManager, ILoanRewardsManager {
    /**
     * @dev Constructor
     * @param positionManager Address of the position manager contract
     * @param _minPositionValue Minimum position required value
     * @param _deltaExitLockingDuration Allowed delta duration for locking for term rewards in case of opted out position
     * @param name ERC721 name of the staked position NFT
     * @param symbol ERC721 symbol of the staked position NFT
     */
    constructor(
        address positionManager,
        uint256 _minPositionValue,
        uint256 _deltaExitLockingDuration,
        string memory name,
        string memory symbol
    )
        RewardsManager(
            positionManager,
            _minPositionValue,
            IPool(positionManager).LOAN_DURATION(),
            IPool(positionManager).LOAN_DURATION() + ILoanState(positionManager).BOOK_BUILDING_PERIOD_DURATION(),
            _deltaExitLockingDuration,
            name,
            symbol
        )
    {}

    /**
     * @inheritdoc ILoanRewardsManager
     */
    function stake(uint256 positionId) public onlyEnabled onlyLender {
        uint256 endTimestamp = ILoanState(address(POSITION_MANAGER)).getBookBuildingPhaseEndTimestamp();
        if (block.timestamp > endTimestamp) revert BOOK_BUILDING_PHASE_OVER();
        uint256 remainingTimeInBookBuildingPhase = endTimestamp - block.timestamp;
        uint256 lockingDuration = remainingTimeInBookBuildingPhase + POSITION_MANAGER.LOAN_DURATION();
        _stake(positionId, lockingDuration);
    }

    /**
     * @inheritdoc ILoanRewardsManager
     */
    function batchStake(uint256[] calldata positionIds) public onlyEnabled onlyLender {
        uint256 endTimestamp = ILoanState(address(POSITION_MANAGER)).getBookBuildingPhaseEndTimestamp();
        if (block.timestamp > endTimestamp) revert BOOK_BUILDING_PHASE_OVER();
        uint256 remainingTimeInBookBuildingPhase = endTimestamp - block.timestamp;
        uint256 lockingDuration = remainingTimeInBookBuildingPhase + POSITION_MANAGER.LOAN_DURATION();
        for (uint256 i = 0; i < positionIds.length; i++) {
            _stake(positionIds[i], lockingDuration);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../../../../libraries/TimeValue.sol';
import '../../../../libraries/FixedPointMathLib.sol';
import './../libraries/LoanTypes.sol';
import './../libraries/LoanLogic.sol';
import '../interfaces/ILoanBorrower.sol';
import './LoanState.sol';

/**
 * @title LoanBorrower
 * @author Atlendis Labs
 * @notice Implementation of the ILoanBorrower
 */
abstract contract LoanBorrower is LoanState, ILoanBorrower {
    /*//////////////////////////////////////////////////////////////
                                LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using FixedPointMathLib for uint256;
    using LoanLogic for LoanTypes.Tick;

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public borrowTimestamp;
    uint256 public totalCurrentBorrowed;
    uint256 public totalBorrowedStatic;
    uint256 public totalToBeRepaid;

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Restrict the sender to borrower only
     */
    modifier onlyBorrower() {
        if (!rolesManager.isBorrower(msg.sender)) revert LoanErrors.LOAN_ONLY_BORROWER();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                        VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc ILoanBorrower
     */
    function getMaturity() external view returns (uint256 maturity) {
        if (poolPhase != LoanTypes.PoolPhase.ISSUED && poolPhase != LoanTypes.PoolPhase.NON_STANDARD) return 0;
        return borrowTimestamp + LOAN_DURATION;
    }

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc ILoanBorrower
     */
    function enableBookBuildingPhase() external onlyBorrower onlyInPhase(LoanTypes.PoolPhase.INACTIVE) {
        poolPhase = LoanTypes.PoolPhase.BOOK_BUILDING;

        cancellationFeeEscrow = CANCELLATION_FEE_PC.mul(TARGET_ORIGINATION_AMOUNT);

        CUSTODIAN.deposit(cancellationFeeEscrow, msg.sender);

        emit BookBuildingPhaseEnabled(address(this), cancellationFeeEscrow);
    }

    /**
     * @inheritdoc ILoanBorrower
     */
    function withdrawRemainingEscrow(address to) external onlyBorrower onlyInPhase(LoanTypes.PoolPhase.CANCELLED) {
        CUSTODIAN.withdraw(cancellationFeeEscrow, to);
        emit EscrowWithdrawn(address(this), cancellationFeeEscrow);
    }

    /**
     * @inheritdoc ILoanBorrower
     */
    function borrow(uint256 borrowedAmount, address to)
        external
        onlyBorrower
        onlyInPhase(LoanTypes.PoolPhase.ORIGINATION)
    {
        // Validation
        if (block.timestamp > ORIGINATION_PHASE_START_TIMESTAMP + ORIGINATION_PERIOD_DURATION)
            revert LoanErrors.LOAN_ORIGINATION_PHASE_EXPIRED();
        if (deposits == 0) revert LoanErrors.LOAN_ZERO_BORROW_AMOUNT_NOT_ALLOWED();

        if (deposits > 0 && deposits < MIN_ORIGINATION_AMOUNT) {
            borrowedAmount = deposits;
        } else if ((borrowedAmount < MIN_ORIGINATION_AMOUNT) || (borrowedAmount > TARGET_ORIGINATION_AMOUNT)) {
            revert LoanErrors.LOAN_BORROW_AMOUNT_OUT_OF_RANGE();
        } else if (borrowedAmount > deposits) {
            revert LoanErrors.LOAN_BORROW_AMOUNT_TOO_HIGH();
        }

        // Iteration on the ticks to form the loan
        bool borrowComplete = false;
        uint256 currentInterestRate = MIN_RATE;
        uint256 remainingAmount = borrowedAmount;
        while (remainingAmount > 0 && currentInterestRate <= MAX_RATE && !borrowComplete) {
            LoanTypes.Tick storage tick = ticks[currentInterestRate];
            if (tick.depositedAmount > 0) {
                uint256 amountToBorrow = remainingAmount;
                if (tick.depositedAmount < remainingAmount) amountToBorrow = tick.depositedAmount;
                totalToBeRepaid += amountToBorrow.div(
                    TimeValue.getDiscountFactor(currentInterestRate, LOAN_DURATION, ONE)
                );
                (borrowComplete, remainingAmount) = tick.borrowFromTick(remainingAmount);
                (uint256 paymentAmount, uint256 earningsAmount) = getPaymentAmountForTick(
                    tick,
                    currentInterestRate,
                    PAYMENT_PERIOD,
                    totalPaymentsCount
                );
                tick.registerPaymentsAmounts(paymentAmount, earningsAmount);
            }
            currentInterestRate += RATE_SPACING;
        }
        if (remainingAmount > 0) {
            revert LoanErrors.LOAN_NOT_ENOUGH_FUNDS_AVAILABLE();
        }

        // Update globals
        poolPhase = LoanTypes.PoolPhase.ISSUED;
        borrowTimestamp = block.timestamp;
        totalCurrentBorrowed = borrowedAmount;
        totalBorrowedStatic = borrowedAmount;

        // Fee calculation and transfers
        uint256 fees = FEES_CONTROLLER.registerBorrowingFees(borrowedAmount);
        FundsTransfer.chargedWithdraw({
            token: TOKEN,
            custodian: CUSTODIAN,
            recipient: to,
            amount: borrowedAmount + cancellationFeeEscrow - fees,
            fees: fees
        });

        emit Borrowed(msg.sender, borrowedAmount, fees, cancellationFeeEscrow);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get the amount of a single payment, as well at its earnings
     * @param tick Target tick
     * @param rate Rate of the tick
     * @param paymentPeriod Period of time during two payments
     * @param totalPaymentsCount Total number of payments for the loan
     * @return paymentAmount Amount of a single coupon payment
     * @return earnings Part of earnings of the payment
     */
    function getPaymentAmountForTick(
        LoanTypes.Tick memory tick,
        uint256 rate,
        uint256 paymentPeriod,
        uint256 totalPaymentsCount
    ) internal view virtual returns (uint256 paymentAmount, uint256 earnings);

    /**
     * @notice Get the number of payments due but not paid yet
     * @return numberOfPaymentsDue Number of payments
     */
    function _getNumberOfPaymentsExpired() internal view returns (uint256 numberOfPaymentsDue) {
        uint256 referenceTimestamp = timelock.executedAt > 0 ? timelock.executedAt : block.timestamp;
        numberOfPaymentsDue = LoanLogic.getNumberOfPaymentsExpired(
            referenceTimestamp,
            borrowTimestamp,
            LOAN_DURATION,
            REPAYMENT_PERIOD_DURATION,
            PAYMENT_PERIOD
        );
    }

    /**
     * @notice Make the payments that are due but not paid yet
     * @param paymentsToMake Number of payments to make
     */
    function _makePaymentsDue(uint256 paymentsToMake) internal {
        if (poolPhase != LoanTypes.PoolPhase.ISSUED) revert LoanErrors.LOAN_INVALID_PHASE();

        if (paymentsToMake == 0) return;

        uint256 totalPaymentAmount;
        uint256 totalEarnings;
        uint256 currentInterestRate = MIN_RATE;
        while (currentInterestRate <= MAX_RATE) {
            LoanTypes.Tick storage tick = ticks[currentInterestRate];
            if (tick.borrowedAmount > 0) {
                totalPaymentAmount += tick.singlePaymentAmount * paymentsToMake;
                totalEarnings += tick.singlePaymentEarnings * paymentsToMake;
            }
            currentInterestRate += RATE_SPACING;
        }
        totalToBeRepaid -= totalPaymentAmount;
        paymentsDoneCount += paymentsToMake;

        uint256 fees = FEES_CONTROLLER.registerRepaymentFees(totalEarnings);
        FundsTransfer.chargedDepositToCustodian({
            token: TOKEN,
            custodian: CUSTODIAN,
            amount: totalPaymentAmount - fees,
            fees: fees
        });

        emit PaymentMade(msg.sender, paymentsDoneCount, totalPaymentAmount, fees);
    }

    /**
     * @notice Repay the current loan
     * @param calculateRepayAmount Function to get the amount to be repaid, depends on the implementation
     */
    function _repay(
        function(uint256, uint256, uint256, uint256) internal returns (uint256, uint256) calculateRepayAmount
    ) internal onlyInPhase(LoanTypes.PoolPhase.ISSUED) {
        if (block.timestamp < borrowTimestamp + LOAN_DURATION - REPAYMENT_PERIOD_DURATION)
            revert LoanErrors.LOAN_REPAY_TOO_EARLY();

        uint256 timeDeltaIntoLateRepay = getLateRepayTimeDelta();
        uint256 repaidAmount = 0;
        uint256 fees = 0;
        uint256 currentInterestRate = MIN_RATE;
        while (currentInterestRate <= MAX_RATE) {
            LoanTypes.Tick storage tick = ticks[currentInterestRate];
            if (tick.borrowedAmount > 0) {
                (uint256 amountRepayForTick, uint256 tickFees) = calculateRepayAmount(
                    tick.borrowedAmount,
                    currentInterestRate,
                    timeDeltaIntoLateRepay,
                    LATE_REPAYMENT_FEE_RATE
                );
                tick.repaidAmount = amountRepayForTick - tickFees;
                fees += tickFees;
                repaidAmount += amountRepayForTick;
            }
            currentInterestRate += RATE_SPACING;
        }
        poolPhase = LoanTypes.PoolPhase.REPAID;

        FundsTransfer.chargedDepositToCustodian({
            token: TOKEN,
            custodian: CUSTODIAN,
            amount: repaidAmount - fees,
            fees: fees
        });

        emit PrincipalRepaid(msg.sender, repaidAmount, fees);
    }

    /**
     * @notice Gets the amount of time elapsed since maturity in case of late repayment
     * @return timeDeltaIntoLateRepay Amount of time since maturity
     */
    function getLateRepayTimeDelta() internal view returns (uint256 timeDeltaIntoLateRepay) {
        uint256 lateRepaymentThreshold = borrowTimestamp + LOAN_DURATION;
        timeDeltaIntoLateRepay = (block.timestamp > lateRepaymentThreshold)
            ? block.timestamp - lateRepaymentThreshold
            : 0;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../../../../common/non-standard-repayment/INonStandardRepaymentModule.sol';
import '../../../../libraries/PoolTimelockLogic.sol';
import './../libraries/LoanTypes.sol';
import './../libraries/LoanErrors.sol';
import './../interfaces/ILoanGovernance.sol';
import './../libraries/LoanLogic.sol';
import './LoanState.sol';

/**
 * @title LoanGovernance
 * @author Atlendis Labs
 * @notice Implementation of the ILoanGovernance
 *         Governance module of the Loan products
 */
abstract contract LoanGovernance is ILoanGovernance, LoanState {
    /*//////////////////////////////////////////////////////////////
                              LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using PoolTimelockLogic for PoolTimelock;

    /*//////////////////////////////////////////////////////////////
                               STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public constant NON_STANDARD_REPAY_MIN_TIMELOCK_DELAY = 1 days;
    uint256 public constant RESCUE_MIN_TIMELOCK_DELAY = 10 days;

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /**
     * @inheritdoc ILoanGovernance
     */
    function enableOriginationPhase() external onlyGovernance onlyInPhase(LoanTypes.PoolPhase.BOOK_BUILDING) {
        if (block.timestamp <= CREATION_TIMESTAMP + BOOK_BUILDING_PERIOD_DURATION) {
            revert LoanErrors.LOAN_BOOK_BUILDING_TIME_NOT_OVER();
        }
        poolPhase = LoanTypes.PoolPhase.ORIGINATION;
        ORIGINATION_PHASE_START_TIMESTAMP = block.timestamp;
        emit OriginationPhaseEnabled(address(this));
    }

    /**
     * @inheritdoc ILoanGovernance
     */
    function cancelLoan(bool redistributeCancelFee)
        external
        onlyGovernance
        onlyInPhase(LoanTypes.PoolPhase.ORIGINATION)
    {
        if (block.timestamp < ORIGINATION_PHASE_START_TIMESTAMP + ORIGINATION_PERIOD_DURATION) {
            revert LoanErrors.LOAN_ORIGINATION_PERIOD_STILL_ACTIVE();
        }
        uint256 remainingEscrow = cancellationFeeEscrow;
        for (
            uint256 currentInterestRate = MIN_RATE;
            currentInterestRate <= MAX_RATE;
            currentInterestRate += RATE_SPACING
        ) {
            LoanTypes.Tick storage tick = ticks[currentInterestRate];
            uint256 cancelFeeForTick = LoanLogic.repayCancelFeeForTick(
                tick,
                CANCELLATION_FEE_PC,
                remainingEscrow,
                redistributeCancelFee && (deposits > MIN_ORIGINATION_AMOUNT)
            );
            remainingEscrow -= cancelFeeForTick;
        }
        cancellationFeeEscrow = remainingEscrow;

        poolPhase = LoanTypes.PoolPhase.CANCELLED;

        emit LoanOriginationCancelled(address(this), remainingEscrow);
    }

    /**
     * @inheritdoc ILoanGovernance
     */
    function withdrawFees() external onlyGovernance {
        uint256 dueFees = FEES_CONTROLLER.getDueFees(address(TOKEN));

        FundsTransfer.approveFees(TOKEN, FEES_CONTROLLER, dueFees);
        FEES_CONTROLLER.pullDueFees(address(TOKEN));

        emit FeesWithdrawn(dueFees);
    }

    /**
     * @inheritdoc ILoanGovernance
     */
    function setFeesController(IFeesController feesController)
        external
        onlyGovernance
        onlyInPhase(LoanTypes.PoolPhase.BOOK_BUILDING)
    {
        address managedPool = feesController.getManagedPool();
        if (managedPool != address(this)) revert LoanErrors.LOAN_INVALID_FEES_CONTROLLER_MANAGED_POOL();
        FEES_CONTROLLER = feesController;
        emit FeesControllerSet(address(feesController));
    }

    /**
     * @inheritdoc ILoanGovernance
     */
    function startNonStandardRepaymentProcedure(INonStandardRepaymentModule nonStandardRepaymentModule, uint256 delay)
        external
        onlyGovernance
        onlyInPhase(LoanTypes.PoolPhase.ISSUED)
    {
        if (delay < NON_STANDARD_REPAY_MIN_TIMELOCK_DELAY) revert TIMELOCK_DELAY_TOO_SMALL();
        if (
            !IERC165(address(nonStandardRepaymentModule)).supportsInterface(
                type(INonStandardRepaymentModule).interfaceId
            )
        ) revert LoanErrors.LOAN_WRONG_INPUT();

        timelock.initiate({
            delay: delay,
            recipient: address(nonStandardRepaymentModule),
            timelockType: TimelockType.NON_STANDARD_REPAY
        });

        emit NonStandardRepaymentProcedureStarted(address(nonStandardRepaymentModule), delay);
    }

    /**
     * @inheritdoc ILoanGovernance
     */
    function startRescueProcedure(address recipient, uint256 delay) external onlyGovernance {
        if (delay < RESCUE_MIN_TIMELOCK_DELAY) revert TIMELOCK_DELAY_TOO_SMALL();

        timelock.initiate({delay: delay, recipient: recipient, timelockType: TimelockType.RESCUE});

        emit RescueProcedureStarted(recipient, delay);
    }

    /**
     * @inheritdoc ITimelock
     */
    function executeTimelock() external onlyGovernance {
        timelock.execute();

        uint256 withdrawnAmount = CUSTODIAN.withdrawAllDeposits(timelock.recipient);

        if (timelock.timelockType == TimelockType.NON_STANDARD_REPAY) {
            INonStandardRepaymentModule(timelock.recipient).initialize(withdrawnAmount);
        }

        poolPhase = LoanTypes.PoolPhase.NON_STANDARD;

        emit TimelockExecuted(withdrawnAmount);
    }

    /**
     * @inheritdoc ITimelock
     */
    function cancelTimelock() external onlyGovernance {
        timelock.cancel();
        emit TimelockCancelled();
    }

    /**
     * @inheritdoc ILoanGovernance
     */
    function getTimelock() external view returns (PoolTimelock memory) {
        return timelock;
    }

    /**
     * @inheritdoc ILoanGovernance
     */
    function updateMinDepositAmount(uint256 amount) external onlyGovernance {
        minDepositAmount = amount;
        emit MinDepositAmountUpdated(amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import {ERC721 as SolmateERC721} from 'lib/solmate/src/tokens/ERC721.sol';

import '../../../../libraries/FixedPointMathLib.sol';
import './../libraries/LoanTypes.sol';
import './../libraries/LoanLogic.sol';
import '../interfaces/ILoanLender.sol';
import './LoanState.sol';

/**
 * @title LoanLender
 * @author Atlendis Labs
 * @notice Implementation of the ILoanLender
 *         Lenders module of the Loan product
 *         Positions are created according to associated ERC721 token
 */
abstract contract LoanLender is LoanState, SolmateERC721, ILoanLender {
    /*//////////////////////////////////////////////////////////////
                                LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using FixedPointMathLib for uint256;
    using LoanLogic for LoanTypes.Tick;

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 constant WAD = 1e18;
    mapping(uint256 => LoanTypes.Position) public positions;
    uint256 public nextPositionId;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @param name ERC721 name of the positions
     * @param symbol ERC721 symbol of the positions
     */
    constructor(string memory name, string memory symbol) SolmateERC721(name, symbol) {
        FixedPointMathLib.setDenominator(ONE);
    }

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Restrict the sender to lender only
     */
    modifier onlyLender() {
        if (!rolesManager.isLender(msg.sender)) revert LoanErrors.LOAN_ONLY_LENDER();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                             VIEW METHODS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Implementation of the ERC721 token URI
     * TODO: revisit in #115
     */
    function tokenURI(uint256) public pure override returns (string memory) {
        return '';
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL METHODS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc ILoanLender
     */
    function deposit(
        uint256 rate,
        uint256 amount,
        address to
    ) external onlyLender returns (uint256 positionId) {
        if (
            poolPhase != LoanTypes.PoolPhase.BOOK_BUILDING ||
            block.timestamp > CREATION_TIMESTAMP + BOOK_BUILDING_PERIOD_DURATION
        ) revert LoanErrors.LOAN_ALLOWED_ONLY_BOOK_BUILDING_PHASE();

        if (amount < minDepositAmount) revert LoanErrors.LOAN_DEPOSIT_AMOUNT_TOO_LOW();

        validateRate(rate);

        ticks[rate].depositToTick(amount);
        positionId = nextPositionId++;
        deposits += amount;
        _safeMint(to, positionId);
        positions[positionId] = LoanTypes.Position({
            depositedAmount: amount,
            rate: rate,
            depositBlockNumber: block.number,
            unborrowedAmountWithdrawn: false,
            numberOfPaymentsWithdrawn: 0
        });

        CUSTODIAN.deposit(amount, msg.sender);

        emit Deposited(positionId, to, rate, amount);
    }

    /**
     * @inheritdoc ILoanLender
     */
    function updateRate(uint256 positionId, uint256 rate) external onlyLender {
        if (ownerOf(positionId) != msg.sender) revert LoanErrors.LOAN_MGMT_ONLY_OWNER();
        if (
            poolPhase != LoanTypes.PoolPhase.BOOK_BUILDING ||
            block.timestamp > CREATION_TIMESTAMP + BOOK_BUILDING_PERIOD_DURATION
        ) revert LoanErrors.LOAN_ALLOWED_ONLY_BOOK_BUILDING_PHASE();

        validateRate(rate);

        uint256 oldRate = positions[positionId].rate;
        ticks[oldRate].updateTicksDeposit(ticks[rate], positions[positionId].depositedAmount);
        positions[positionId].rate = rate;

        emit RateUpdated(positionId, msg.sender, oldRate, rate);
    }

    /**
     * @inheritdoc ILoanLender
     */
    function withdraw(uint256 positionId) external {
        validateWithdraw(positionId);

        LoanTypes.Position storage position = positions[positionId];
        LoanTypes.Tick storage tick = ticks[position.rate];

        // get unborrowed part of the position
        (uint256 unborrowedAmount, bool unborrowedAmountWithdrawn) = tick.withdrawFromTick(
            poolPhase,
            position.depositedAmount,
            position.unborrowedAmountWithdrawn
        );

        if (poolPhase == LoanTypes.PoolPhase.BOOK_BUILDING) {
            deposits -= unborrowedAmount;
        }

        // get payments amounts made to the position
        (uint256 paymentsToWithdraw, uint256 earnings) = tick.getPaymentsAmountToWithdraw(position, paymentsDoneCount);
        position.numberOfPaymentsWithdrawn = paymentsDoneCount;

        if (unborrowedAmount + paymentsToWithdraw == 0) revert LoanErrors.LOAN_WITHDRAWAL_NOT_ALLOWED();

        // position update
        if (unborrowedAmountWithdrawn) {
            position.unborrowedAmountWithdrawn = true;
        } else if (
            ((totalPaymentsCount > 0) && paymentsDoneCount == totalPaymentsCount) ||
            unborrowedAmount > 0 ||
            poolPhase == LoanTypes.PoolPhase.CANCELLED
        ) {
            _burn(positionId);
            delete positions[positionId];
        }

        // fees calculation and tranfers
        uint256 fees = earnings.mul(WAD).mul(FEES_CONTROLLER.getRepaymentFeesRate());
        CUSTODIAN.withdraw(unborrowedAmount + paymentsToWithdraw - fees, msg.sender);

        emit Withdrawn(positionId, msg.sender, unborrowedAmount + paymentsToWithdraw - fees);
    }

    /**
     * @inheritdoc ILoanLender
     */
    function withdraw(uint256 positionId, uint256 amount)
        external
        onlyLender
        onlyInPhase(LoanTypes.PoolPhase.BOOK_BUILDING)
    {
        LoanTypes.Position storage position = positions[positionId];

        // Validation
        if (ownerOf(positionId) != msg.sender) revert LoanErrors.LOAN_MGMT_ONLY_OWNER();
        if (position.depositBlockNumber == block.number) revert LoanErrors.LOAN_TIMELOCK();
        if (amount > position.depositedAmount) revert LoanErrors.LOAN_WITHDRAW_AMOUNT_TOO_LARGE();
        if (amount < minDepositAmount) revert LoanErrors.LOAN_WITHDRAW_AMOUNT_TOO_LOW();
        if (position.depositedAmount - amount < minDepositAmount) revert LoanErrors.LOAN_REMAINING_AMOUNT_TOO_LOW();

        // Position udpate
        ticks[position.rate].depositedAmount -= amount;
        if (position.depositedAmount == amount) {
            _burn(positionId);
            delete positions[positionId];
        } else {
            position.depositedAmount -= amount;
        }
        deposits -= amount;

        // Transfer and event
        CUSTODIAN.withdraw(amount, msg.sender);
        emit PartiallyWithdrawn(positionId, msg.sender, amount);
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL METHODS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Validation of the rate for the deposit and update rate actions
     * @param newRate Rate to be validated
     */
    function validateRate(uint256 newRate) internal view {
        if (newRate < MIN_RATE) revert LoanErrors.LOAN_OUT_OF_BOUND_MIN_RATE();
        if (newRate > MAX_RATE) revert LoanErrors.LOAN_OUT_OF_BOUND_MAX_RATE();
        if ((newRate - MIN_RATE) % RATE_SPACING != 0) revert LoanErrors.LOAN_INVALID_RATE_SPACING();
    }

    /**
     * @notice Validation of the withdraw logic
     * @param positionId ID of the position to validate the withdrawal for
     */
    function validateWithdraw(uint256 positionId) internal view {
        if (ownerOf(positionId) != msg.sender) revert LoanErrors.LOAN_MGMT_ONLY_OWNER();
        if (positions[positionId].depositBlockNumber == block.number) revert LoanErrors.LOAN_TIMELOCK();
        if (poolPhase == LoanTypes.PoolPhase.ORIGINATION || poolPhase == LoanTypes.PoolPhase.NON_STANDARD)
            revert LoanErrors.LOAN_WITHDRAWAL_NOT_ALLOWED();
    }

    /*//////////////////////////////////////////////////////////////
                          TRANSFER OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See {IERC721-transferFrom}.
     * Bear in mind that `safeTransferFrom` methods are internally using `transferFrom`, hence restrictions are also applied on these methods
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        if (!rolesManager.isOperator(msg.sender)) revert LoanErrors.LOAN_ONLY_OPERATOR();

        super.transferFrom(from, to, tokenId);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../../../../common/fees/IFeesController.sol';
import '../../../../common/custodian/IPoolCustodian.sol';
import '../../../../common/roles-manager/Managed.sol';
import '../../../../libraries/FundsTransfer.sol';
import '../../../../libraries/PoolTimelockLogic.sol';
import '../interfaces/ILoanState.sol';
import '../libraries/LoanTypes.sol';
import '../libraries/LoanErrors.sol';

/**
 * @title LoanState
 * @author Atlendis Labs
 * @notice Implementation of the ILoanState
 */
abstract contract LoanState is Managed, ILoanState {
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    // Loan integrations
    IPoolCustodian public immutable CUSTODIAN;
    address public immutable TOKEN;
    IFeesController public FEES_CONTROLLER;

    // Loan lifecycle dates
    uint256 public immutable CREATION_TIMESTAMP;
    uint256 public ORIGINATION_PHASE_START_TIMESTAMP;

    // Loan parameters
    uint256 constant RAY = 1e27;
    uint256 public immutable ONE;
    uint256 public immutable MIN_RATE;
    uint256 public immutable MAX_RATE;
    uint256 public immutable RATE_SPACING;
    uint256 public immutable LOAN_DURATION;
    uint256 public immutable TARGET_ORIGINATION_AMOUNT;
    uint256 public immutable BOOK_BUILDING_PERIOD_DURATION;
    uint256 public immutable ORIGINATION_PERIOD_DURATION;
    uint256 public immutable REPAYMENT_PERIOD_DURATION;
    uint256 public immutable LATE_REPAYMENT_FEE_RATE;
    uint256 public immutable CANCELLATION_FEE_PC;
    uint256 public immutable PAYMENT_PERIOD;
    uint256 public minDepositAmount;
    uint256 public immutable MIN_ORIGINATION_AMOUNT;

    LoanTypes.PoolPhase public poolPhase;
    mapping(uint256 => LoanTypes.Tick) public ticks;

    uint256 public deposits;
    uint256 public cancellationFeeEscrow;

    uint256 public totalPaymentsCount;
    uint256 public paymentsDoneCount;

    PoolTimelock internal timelock;

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Constructor
     * @param rolesManager Address of the roles manager contract
     * @param custodian Address of the custodian contract
     * @param feesController Address of the fees controller contract
     * @param ratesAmountsConfig Other Configurations
     * @param durationsConfig Other Configurations
     */
    constructor(
        address rolesManager,
        IPoolCustodian custodian,
        IFeesController feesController,
        bytes memory ratesAmountsConfig,
        bytes memory durationsConfig
    ) Managed(rolesManager) {
        (
            MIN_RATE,
            MAX_RATE,
            RATE_SPACING,
            TARGET_ORIGINATION_AMOUNT,
            LATE_REPAYMENT_FEE_RATE,
            CANCELLATION_FEE_PC,
            minDepositAmount,
            MIN_ORIGINATION_AMOUNT
        ) = abi.decode(ratesAmountsConfig, (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256));
        (
            LOAN_DURATION,
            REPAYMENT_PERIOD_DURATION,
            ORIGINATION_PERIOD_DURATION,
            BOOK_BUILDING_PERIOD_DURATION,
            PAYMENT_PERIOD
        ) = abi.decode(durationsConfig, (uint256, uint256, uint256, uint256, uint256));

        (address token, uint256 decimals) = custodian.getTokenConfiguration();
        TOKEN = token;
        ONE = 10**decimals;

        if (CANCELLATION_FEE_PC > 0) {
            poolPhase = LoanTypes.PoolPhase.INACTIVE;
        } else {
            poolPhase = LoanTypes.PoolPhase.BOOK_BUILDING;
            emit BookBuildingPhaseEnabled(address(this), 0);
        }

        totalPaymentsCount = PAYMENT_PERIOD > 0 ? LOAN_DURATION / PAYMENT_PERIOD : 0;

        CREATION_TIMESTAMP = block.timestamp;
        CUSTODIAN = custodian;
        FEES_CONTROLLER = feesController;
    }

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Allow only if the pool phase is the expected one
     * @param expectedPhase Expected phase
     */
    modifier onlyInPhase(LoanTypes.PoolPhase expectedPhase) {
        if (poolPhase != expectedPhase) revert LoanErrors.LOAN_INVALID_PHASE();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                             VIEW METHODS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get the maximum ending timestamp of the book building period
     */
    function getBookBuildingPhaseEndTimestamp() external view returns (uint256 bookBuildingPhaseEndTimestamp) {
        return CREATION_TIMESTAMP + BOOK_BUILDING_PERIOD_DURATION;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../../../common/rewards/IRewardsManager.sol';

/**
 * @title IRCLRewardsManager
 * @author Atlendis Labs
 * @notice Interface of the Revolving Credit Lines Rewards Manager contract
 *         This interface completes the core IRewardsManager interface.
 *         Staking and batch staking is allowed, the locking duration is chosen by the user.
 *         User is allowed to opt out staked position of the next loan.
 */
interface IRCLRewardsManager is IRewardsManager {
    /**
     * @notice Stake a position in the contract
     *         An associated staked position NFT is created for the owner
     * @param positionId ID of the position
     * @param lockingDuration Locking duration related to term rewards modules, a value of 0 will not generate term rewards
     *
     * Emits a {PositionStaked} event
     */
    function stake(uint256 positionId, uint256 lockingDuration) external;

    /**
     * @notice Stake a batch of positions in the contract
     *         For each staked position, an associated staked position NFT is created for the owner
     * @param positionIds Array of IDs of the positions
     * @param lockingDuration Locking duration related to term rewards modules, a value of 0 will not generate term rewards
     *
     * Emits a {PositionStaked} event for each staked position
     */
    function batchStake(uint256[] calldata positionIds, uint256 lockingDuration) external;

    /**
     * @notice Opt out a borrowed position from the next loan, remove it from the borrowable funds and stop the generation of continuous rewards for this position
     * @param positionId The ID of the position
     */
    function optOut(uint256 positionId) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../../../interfaces/IPool.sol';
import './../modules/interfaces/IRCLOrderBook.sol';
import './../modules/interfaces/IRCLGovernance.sol';
import './../modules/interfaces/IRCLBorrowers.sol';
import './../modules/interfaces/IRCLLenders.sol';

/**
 * @title IRevolvingCreditLine
 * @author Atlendis Labs
 */
interface IRevolvingCreditLine is IRCLLenders, IRCLBorrowers, IRCLGovernance, IRCLOrderBook {
    /**
     * @notice Retrieve the general high level information of a position
     * @param positionId ID of the position
     * @return owner Owner of the position
     * @return rate Rate of the position
     * @return depositedAmount Base deposit of the position
     * @return status Current status of the position
     */
    function getPosition(uint256 positionId)
        external
        view
        returns (
            address owner,
            uint256 rate,
            uint256 depositedAmount,
            PositionStatus status
        );

    /**
     * @notice Retrieve the repartition between borrowed amount and unborrowed amount of the position
     * @param positionId ID of the position
     * @return unborrowedAmount Amount that is not currently borrowed, and can be withdrawn
     * @return borrowedAmount Amount that is currently borrowed
     */
    function getPositionRepartition(uint256 positionId)
        external
        view
        returns (uint256 unborrowedAmount, uint256 borrowedAmount);

    /**
     * @notice Retrieve the current overall value of the position, including both borrowed and unborrowed amounts
     * @param positionId ID of the position
     * @return positionCurrentValue Current value of the position
     */
    function getPositionCurrentValue(uint256 positionId) external view returns (uint256 positionCurrentValue);

    /**
     * @notice Retrieve the share the position holds in the current loan
     * @dev Retuns 0 if there's no loan ongoing
     * @dev a result in RAY precision - 1e27
     * @param positionId ID of the position
     * @return positionShare Share of the position in the current loan
     */
    function getPositionLoanShare(uint256 positionId) external view returns (uint256 positionShare);

    /**
     * @notice Retrieves the current accruals of the ongoing loan
     */
    function getCurrentAccruals() external returns (uint256 currentAccruals);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

/**
 * @title DataTypes library
 * @dev Defines the structs and enums used by the revolving credit line
 */
library DataTypes {
    struct BaseEpochsAmounts {
        uint256 adjustedDeposits;
        uint256 adjustedOptedOut;
        uint256 available;
        uint256 borrowed;
    }

    struct NewEpochsAmounts {
        uint256 toBeAdjusted;
        uint256 available;
        uint256 borrowed;
        uint256 optedOut;
    }

    struct WithdrawnAmounts {
        uint256 toBeAdjusted;
        uint256 borrowed;
    }

    struct Epoch {
        bool isBaseEpoch;
        uint256 borrowed;
        uint256 deposited;
        uint256 optedOut;
        uint256 accruals;
        uint256 precedingLoanId;
        uint256 loanId;
    }

    struct Tick {
        uint256 yieldFactor;
        uint256 loanStartEpochId;
        uint256 currentEpochId;
        uint256 latestLoanId;
        BaseEpochsAmounts baseEpochsAmounts;
        NewEpochsAmounts newEpochsAmounts;
        WithdrawnAmounts withdrawnAmounts;
        mapping(uint256 => Epoch) epochs;
        mapping(uint256 => uint256) endOfLoanYieldFactors;
    }

    struct Loan {
        uint256 id;
        uint256 maturity;
        uint256 nonStandardRepaymentTimestamp;
        uint256 lateRepayTimeDelta;
        uint256 lateRepayFeeRate;
        uint256 repaymentFeesRate;
    }

    enum OrderBookPhase {
        OPEN,
        CLOSED,
        NON_STANDARD
    }

    struct Position {
        uint256 baseDeposit;
        uint256 rate;
        uint256 epochId;
        uint256 creationTimestamp;
        uint256 optOutLoanId;
        uint256 withdrawLoanId;
        WithdrawalAmounts withdrawn;
    }

    struct WithdrawalAmounts {
        uint256 borrowed;
        uint256 expectedAccruals;
    }

    struct BorrowInput {
        uint256 totalAmountToBorrow;
        uint256 totalAccrualsToAllocate;
        uint256 rate;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

/**
 * @title Errors library
 * @dev Defines the errors used in the Revolving credit line product
 */
library RevolvingCreditLineErrors {
    error RCL_ONLY_LENDER(); // "Operation restricted to lender only"
    error RCL_ONLY_BORROWER(); // "Operation restricted to borrower only"
    error RCL_ONLY_OPERATOR(); // "Operation restricted to operator only"

    error RCL_OUT_OF_BOUND_MIN_RATE(); // "Input rate is below min rate"
    error RCL_OUT_OF_BOUND_MAX_RATE(); // "Input rate is above max rate"
    error RCL_INVALID_RATE_SPACING(); // "Input rate is invalid with respect to rate spacing"
    error RCL_INVALID_PHASE(); // "Phase is invalid for this operation"
    error RCL_ZERO_AMOUNT_NOT_ALLOWED(); // "Zero amount not allowed"
    error RCL_DEPOSIT_AMOUNT_TOO_LOW(); // "Deposit amount is too low"
    error RCL_NO_LIQUIDITY(); // "No liquidity available for the amount to borrow"
    error RCL_LOAN_RUNNING(); // "Loan has not reached maturity"
    error RCL_AMOUNT_EXCEEDS_MAX(); // "Amount exceeds maximum allowed"
    error RCL_NO_LOAN_RUNNING(); // No loan currently running
    error RCL_ONLY_OWNER(); // Has to be position owner
    error RCL_TIMELOCK(); // ActionNot possible within this block
    error RCL_CANNOT_EXIT(); // Cannot exit after maturity
    error RCL_POSITION_NOT_BORROWED(); // The positions is currently not under a borrow
    error RCL_POSITION_BORROWED(); // The positions is currently under a borrow
    error RCL_POSITION_NOT_FULLY_BORROWED(); // The position is currently not fully borrowed
    error RCL_POSITION_FULLY_BORROWED(); // The position is currently fully borrowed
    error RCL_HAS_OPTED_OUT(); // Position that already opted out can not exit
    error RCL_REPAY_TOO_EARLY(); // Cannot repay before repayment period started
    error RCL_WRONG_INPUT(); // The specified input does not pass validation
    error RCL_REMAINING_AMOUNT_TOO_LOW(); // Withdraw or exit cannot result in the position being worth less than the minimum deposit
    error RCL_AMOUNT_TOO_HIGH(); // Cannot withdraw more than the position current value
    error RCL_AMOUNT_TOO_LOW(); // Cannot withdraw less that the minimum position deposit
    error RCL_MATURITY_PASSED(); // Cannot perform the target action after maturity

    error RCL_INVALID_FEES_CONTROLLER_MANAGED_POOL(); // "Managed pool of fees controller is not the instance one"

    error RCL_NOT_ENOUGH_ADJUSTED_DEPOSITS(); // "Adjusted deposits are too low in the tick compared to the input"
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../RevolvingCreditLine.sol';

/**
 * @title RevolvingCreditLineDeployer
 * @author Atlendis Labs
 * @notice Library created in order to isolate RevolvingCreditLine deployment for contract size reason
 */
library RevolvingCreditLineDeployer {
    function deploy(
        address rolesManager,
        IPoolCustodian custodian,
        IFeesController feesController,
        bytes storage parametersConfig,
        string storage name,
        string storage symbol
    ) external returns (address) {
        return
            address(new RevolvingCreditLine(rolesManager, custodian, feesController, parametersConfig, name, symbol));
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../../../common/fees/IFeesController.sol';
import '../../../libraries/FixedPointMathLib.sol';
import './Errors.sol';
import './DataTypes.sol';

/**
 * @title TickLogic
 * @author Atlendis Labs
 */
library TickLogic {
    /*//////////////////////////////////////////////////////////////
                                LIBRARIES
    //////////////////////////////////////////////////////////////*/
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/
    uint256 constant RAY = 1e27;

    /*//////////////////////////////////////////////////////////////
                            GLOBAL TICK LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Evaluates the increase in yield factor depending on the tick borrow status
     * @param tick Target tick
     * @param timeDelta Duration during which the fees accrue
     * @param rate Rate at which the fees accrue
     * @return yieldFactorIncrease Increase in the yield factor value
     */
    function calculateYieldFactorIncrease(
        DataTypes.Tick storage tick,
        uint256 timeDelta,
        uint256 rate
    ) public view returns (uint256 yieldFactorIncrease) {
        // if base epoch was fully exit yield factor does not increase
        if (tick.baseEpochsAmounts.adjustedDeposits == 0) return 0;
        yieldFactorIncrease = accrualsFor(tick.baseEpochsAmounts.borrowed, timeDelta, rate).div(
            tick.baseEpochsAmounts.adjustedDeposits
        );
    }

    /**
     * @notice Evaluates and includes late repayment fees in tick data
     * @param tick Target tick
     * @param timeDelta Duration between maturity and late repay
     * @param rate Rate at which the fees accrue
     */
    function registerLateRepaymentAccruals(
        DataTypes.Tick storage tick,
        uint256 timeDelta,
        uint256 rate
    ) external {
        if (tick.baseEpochsAmounts.borrowed != 0) {
            tick.yieldFactor += calculateYieldFactorIncrease(tick, timeDelta, rate);
        }
        if (tick.newEpochsAmounts.borrowed != 0) {
            uint256 newEpochsAccruals = accrualsFor(tick.newEpochsAmounts.borrowed, timeDelta, rate);
            tick.newEpochsAmounts.toBeAdjusted += newEpochsAccruals;
        }
        if (tick.withdrawnAmounts.borrowed != 0) {
            uint256 withdrawnAccruals = accrualsFor(tick.withdrawnAmounts.borrowed, timeDelta, rate);
            tick.withdrawnAmounts.toBeAdjusted += withdrawnAccruals;
        }
    }

    /**
     * @notice Prepares all the tick data structures for the next loan cycle
     * @param tick Target tick
     * @param currentLoan Current loan information
     */
    function prepareTickForNextLoan(DataTypes.Tick storage tick, DataTypes.Loan storage currentLoan) external {
        DataTypes.Epoch storage lastEpoch = tick.epochs[tick.currentEpochId];
        if (lastEpoch.borrowed == 0) {
            lastEpoch.isBaseEpoch = true;
            lastEpoch.precedingLoanId = tick.latestLoanId;
        }

        // opted out amounts are not to be adjusted into base epoch
        if (tick.newEpochsAmounts.available + tick.newEpochsAmounts.borrowed > 0) {
            tick.newEpochsAmounts.toBeAdjusted -= tick
                .newEpochsAmounts
                .toBeAdjusted
                .mul(tick.newEpochsAmounts.optedOut)
                .div(tick.newEpochsAmounts.available + tick.newEpochsAmounts.borrowed);
        }

        // wrapping up all tick action and new epochs amounts into the base epoch for the next loan
        uint256 tickAdjusted = tick.baseEpochsAmounts.adjustedDeposits +
            (tick.newEpochsAmounts.toBeAdjusted + tick.withdrawnAmounts.toBeAdjusted).div(tick.yieldFactor) -
            tick.baseEpochsAmounts.adjustedOptedOut;
        uint256 tickAvailable = tickAdjusted.mul(tick.yieldFactor);

        // recording end of loan yield factor for further use
        tick.endOfLoanYieldFactors[currentLoan.id] = tick.yieldFactor;

        // resetting data structures
        delete tick.baseEpochsAmounts;
        delete tick.newEpochsAmounts;
        delete tick.withdrawnAmounts;
        tick.baseEpochsAmounts.adjustedDeposits = tickAdjusted;
        tick.baseEpochsAmounts.available = tickAvailable;
    }

    /*//////////////////////////////////////////////////////////////
                            POSITION LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Gets the adjusted amount corresponding to the position depending on its history
     * @param tick Target tick
     * @param position Target position
     * @param referenceLoan Either first loan or detach loan of the position
     * @return adjustedAmount Adjusted amount of the position
     */
    function getAdjustedAmount(
        DataTypes.Tick storage tick,
        DataTypes.Position storage position,
        DataTypes.Loan storage referenceLoan
    ) public view returns (uint256 adjustedAmount) {
        DataTypes.Epoch storage epoch = tick.epochs[position.epochId];
        if (position.withdrawLoanId > 0) {
            uint256 lateRepayFees = accrualsFor(
                position.withdrawn.borrowed,
                referenceLoan.lateRepayTimeDelta,
                referenceLoan.lateRepayFeeRate
            );
            uint256 protocolFees = (position.withdrawn.expectedAccruals + lateRepayFees).mul(
                referenceLoan.repaymentFeesRate
            );
            return
                adjustedAmount = (position.withdrawn.borrowed +
                    position.withdrawn.expectedAccruals +
                    lateRepayFees -
                    protocolFees).div(tick.endOfLoanYieldFactors[position.withdrawLoanId]);
        }
        adjustedAmount = position.baseDeposit.div(getEquivalentYieldFactor(tick, epoch, referenceLoan));
    }

    /**
     * @notice Gets the equivalent yield factor for the target epoch depending on its borrow history
     * @param tick Target tick
     * @param epoch Target epoch
     * @param referenceLoan Either first loan or detach loan of the position
     * @return equivalentYieldFactor Equivalent yield factor of the position
     */
    function getEquivalentYieldFactor(
        DataTypes.Tick storage tick,
        DataTypes.Epoch storage epoch,
        DataTypes.Loan storage referenceLoan
    ) public view returns (uint256 equivalentYieldFactor) {
        if (epoch.isBaseEpoch) {
            equivalentYieldFactor = tick.endOfLoanYieldFactors[epoch.precedingLoanId];
        } else {
            uint256 accruals = epoch.accruals +
                accrualsFor(epoch.borrowed, referenceLoan.lateRepayTimeDelta, referenceLoan.lateRepayFeeRate);
            uint256 protocolFees = accruals.mul(referenceLoan.repaymentFeesRate);
            uint256 endOfLoanValue = epoch.deposited + accruals - protocolFees;

            equivalentYieldFactor = tick.endOfLoanYieldFactors[epoch.loanId].mul(epoch.deposited).div(endOfLoanValue);
        }
    }

    /**
     * @notice Gets the position current overall value
     * Holds in all cases whatever the position status
     * Returns the exact position value including non repaid interests of current loan
     * @param tick Target tick
     * @param position Target position
     * @param referenceLoan Either first loan or detach loan of the position
     * @param currentLoan Current loan information
     * @return currentValue Current value of the position
     */
    function getPositionCurrentValue(
        DataTypes.Tick storage tick,
        DataTypes.Position storage position,
        DataTypes.Loan storage referenceLoan,
        DataTypes.Loan storage currentLoan
    ) public view returns (uint256) {
        DataTypes.Epoch storage epoch = tick.epochs[position.epochId];
        if (position.optOutLoanId > 0) {
            bool optOutLoanRepaid = (position.optOutLoanId < currentLoan.id) || currentLoan.maturity == 0;
            if (optOutLoanRepaid) {
                return
                    getAdjustedAmount(tick, position, referenceLoan).mul(
                        tick.endOfLoanYieldFactors[position.optOutLoanId]
                    );
            }
        }
        if (position.withdrawLoanId > 0) {
            bool withdrawLoanRepaid = (position.withdrawLoanId < currentLoan.id) || currentLoan.maturity == 0;
            if (!withdrawLoanRepaid) {
                if (block.timestamp > currentLoan.maturity) {
                    uint256 lateRepayTimeDelta = block.timestamp - currentLoan.maturity;
                    uint256 lateRepayFees = accrualsFor(
                        position.withdrawn.borrowed,
                        lateRepayTimeDelta,
                        currentLoan.lateRepayFeeRate
                    );
                    return position.withdrawn.borrowed + position.withdrawn.expectedAccruals + lateRepayFees;
                } else {
                    uint256 timeUntilMaturity = currentLoan.maturity - block.timestamp;
                    uint256 unrealizedInterests = accrualsFor(
                        position.withdrawn.borrowed,
                        timeUntilMaturity,
                        position.rate
                    );
                    return position.withdrawn.borrowed + position.withdrawn.expectedAccruals - unrealizedInterests;
                }
            }
        }
        // current epoch is never borrowed
        if (position.epochId == tick.currentEpochId) {
            return position.baseDeposit;
        }
        // new epochs for currently ongoing loan share a part of the expected fees
        if (
            (position.epochId > tick.loanStartEpochId) &&
            ((tick.baseEpochsAmounts.borrowed > 0) || (tick.newEpochsAmounts.borrowed > 0))
        ) {
            if (block.timestamp > currentLoan.maturity) {
                uint256 lateRepayTimeDelta = block.timestamp - currentLoan.maturity;
                uint256 lateRepayFees = accrualsFor(epoch.borrowed, lateRepayTimeDelta, currentLoan.lateRepayFeeRate);
                return
                    position.baseDeposit +
                    (epoch.accruals + lateRepayFees).mul(position.baseDeposit).div(epoch.deposited);
            } else {
                uint256 timeUntilMaturity = currentLoan.maturity - block.timestamp;
                uint256 unrealizedInterests = accrualsFor(epoch.borrowed, timeUntilMaturity, position.rate);
                return
                    position.baseDeposit +
                    (epoch.accruals - unrealizedInterests).mul(position.baseDeposit).div(epoch.deposited);
            }
        }

        // all base epochs verify the position value = adjusted value * current yield factor formula
        // we compute the last exact yield factor depending on the state of the loan maturity
        uint256 newYieldFactor = tick.yieldFactor;
        uint256 referenceTimestamp = currentLoan.nonStandardRepaymentTimestamp > 0
            ? currentLoan.nonStandardRepaymentTimestamp
            : block.timestamp;
        if (referenceTimestamp > currentLoan.maturity) {
            uint256 lateRepayFeesYieldFactorDelta = calculateYieldFactorIncrease(
                tick,
                referenceTimestamp - currentLoan.maturity,
                currentLoan.lateRepayFeeRate
            );
            newYieldFactor += lateRepayFeesYieldFactorDelta;
        } else {
            uint256 unrealizedYieldFactorIncrease = calculateYieldFactorIncrease(
                tick,
                currentLoan.maturity - referenceTimestamp,
                position.rate
            );
            newYieldFactor -= unrealizedYieldFactorIncrease;
        }

        return getAdjustedAmount(tick, position, referenceLoan).mul(newYieldFactor);
    }

    /**
     * @notice Gets the position value at the start of the current loan
     * @dev Only holds when the position is currently borrowed
     * @dev Is used to evaluate current loan earnings for a specific position
     * @param tick Target tick
     * @param position Target position
     * @param referenceLoan Either first loan or detach loan of the position
     * @param currentLoan Current loan information
     * @return positionValue Start of loan value of the position
     */
    function getPositionStartOfLoanValue(
        DataTypes.Tick storage tick,
        DataTypes.Position storage position,
        DataTypes.Loan storage referenceLoan,
        DataTypes.Loan storage currentLoan
    ) public view returns (uint256 positionValue) {
        if (position.withdrawLoanId > 0) {
            bool withdrawLoanRepaid = (position.withdrawLoanId < currentLoan.id) || currentLoan.maturity == 0;
            if (!withdrawLoanRepaid) return position.withdrawn.borrowed;
        }
        if ((position.epochId < tick.loanStartEpochId) || position.withdrawn.borrowed > 0) {
            uint256 precedingLoanId = tick.epochs[tick.loanStartEpochId].precedingLoanId;
            positionValue = getAdjustedAmount(tick, position, referenceLoan).mul(
                tick.endOfLoanYieldFactors[precedingLoanId]
            );
        } else {
            positionValue = position.baseDeposit;
        }
    }

    /**
     * @notice Gets the position value at the end of the current loan
     * @dev Only holds when the position is currently borrowed
     * @dev Is used to evaluate expected end of loan earnings for a specific position
     * @param tick Target tick
     * @param position Target position
     * @param referenceLoan Either first loan or detach loan of the position
     * @param currentLoan Current loan information
     * @return positionValue Expected value of the position at the end of the current loan
     */
    function getPositionEndOfLoanValue(
        DataTypes.Tick storage tick,
        DataTypes.Position storage position,
        DataTypes.Loan storage referenceLoan,
        DataTypes.Loan storage currentLoan
    ) public view returns (uint256 positionValue) {
        DataTypes.Epoch storage epoch = tick.epochs[position.epochId];
        if (position.optOutLoanId > 0) {
            bool optOutLoanRepaid = (position.optOutLoanId < currentLoan.id) || currentLoan.maturity == 0;
            if (optOutLoanRepaid)
                return
                    getAdjustedAmount(tick, position, referenceLoan).mul(
                        tick.endOfLoanYieldFactors[position.optOutLoanId]
                    );
        }
        if (position.withdrawLoanId > 0) {
            bool withdrawLoanRepaid = (position.withdrawLoanId < currentLoan.id) || currentLoan.maturity == 0;
            if (!withdrawLoanRepaid) return position.withdrawn.borrowed + position.withdrawn.expectedAccruals;
        }
        if ((position.epochId <= tick.loanStartEpochId) || position.withdrawn.borrowed > 0) {
            positionValue = getAdjustedAmount(tick, position, referenceLoan).mul(tick.yieldFactor);
        } else {
            uint256 endOfLoanInterest = epoch.accruals.mul(position.baseDeposit).div(epoch.deposited);
            positionValue = position.baseDeposit + endOfLoanInterest;
        }
    }

    /**
     * @notice Gets the repartition of the position between borrowed an unborrowed amount
     * @dev The borrowed amount does not include pending interest for the current loan
     * @dev Holds in all cases, whether the position is borrowed or not
     * @param tick Target tick
     * @param position Target position
     * @param referenceLoan Either first loan or detach loan of the position
     * @param currentLoan Current loan information
     * @return unborrowedAmount Amount that is not currently borrowed, and can be withdrawn
     * @return borrowedAmount Amount that is currently borrowed
     */
    function getPositionRepartition(
        DataTypes.Tick storage tick,
        DataTypes.Position storage position,
        DataTypes.Loan storage referenceLoan,
        DataTypes.Loan storage currentLoan
    ) public view returns (uint256, uint256) {
        DataTypes.Epoch storage epoch = tick.epochs[position.epochId];
        uint256 unborrowedAmount;
        uint256 borrowedAmount;
        if (position.optOutLoanId > 0) {
            bool optOutLoanRepaid = (position.optOutLoanId < currentLoan.id) || currentLoan.maturity == 0;
            if (optOutLoanRepaid) {
                unborrowedAmount = getAdjustedAmount(tick, position, referenceLoan).mul(
                    tick.endOfLoanYieldFactors[position.optOutLoanId]
                );
                return (unborrowedAmount, 0);
            }
        }
        if (position.withdrawLoanId > 0) {
            bool withdrawLoanRepaid = (position.withdrawLoanId < currentLoan.id) || currentLoan.maturity == 0;
            if (!withdrawLoanRepaid) return (0, position.withdrawn.borrowed);
        }
        if (tick.currentEpochId == 0) {
            return (position.baseDeposit, 0);
        }
        if (currentLoan.maturity == 0) {
            uint256 adjustedAmount = getAdjustedAmount(tick, position, referenceLoan);
            unborrowedAmount = adjustedAmount.mul(tick.yieldFactor);
            return (unborrowedAmount, 0);
        }
        if (position.epochId <= tick.loanStartEpochId) {
            uint256 adjustedAmount = getAdjustedAmount(tick, position, referenceLoan);
            unborrowedAmount = tick.baseEpochsAmounts.available.mul(adjustedAmount).div(
                tick.baseEpochsAmounts.adjustedDeposits
            );
            borrowedAmount = tick.baseEpochsAmounts.borrowed.mul(adjustedAmount).div(
                tick.baseEpochsAmounts.adjustedDeposits
            );
            return (unborrowedAmount, borrowedAmount);
        }

        unborrowedAmount = (epoch.deposited - epoch.borrowed).mul(position.baseDeposit).div(epoch.deposited);
        borrowedAmount = epoch.borrowed.mul(position.baseDeposit).div(epoch.deposited);
        return (unborrowedAmount, borrowedAmount);
    }

    function getPositionLoanShare(
        DataTypes.Tick storage tick,
        DataTypes.Position storage position,
        DataTypes.Loan storage referenceLoan,
        DataTypes.Loan storage currentLoan,
        uint256 totalBorrowedWithSecondary
    ) external view returns (uint256 positionShare) {
        if (currentLoan.maturity == 0 || (tick.baseEpochsAmounts.borrowed == 0 && tick.newEpochsAmounts.borrowed == 0))
            return 0;

        (, uint256 borrowedAmount) = getPositionRepartition(tick, position, referenceLoan, currentLoan);

        // @dev bear in mind that a.mul(b) = a * b / ONE, therefore RAY.mul(1) = RAY / ONE
        return (borrowedAmount * RAY.mul(1)).div(totalBorrowedWithSecondary);
    }

    /*//////////////////////////////////////////////////////////////
                            LENDER LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Logic for lenders depositing a position
     * @param tick Target tick
     * @param currentLoan Current loan information
     * @param amount Amount deposited
     */
    function deposit(
        DataTypes.Tick storage tick,
        DataTypes.Loan storage currentLoan,
        uint256 amount
    ) public {
        if ((currentLoan.maturity > 0) && (tick.latestLoanId == currentLoan.id)) {
            tick.newEpochsAmounts.toBeAdjusted += amount;
            tick.newEpochsAmounts.available += amount;
            tick.epochs[tick.currentEpochId].deposited += amount;
        } else {
            tick.baseEpochsAmounts.available += amount;
            tick.baseEpochsAmounts.adjustedDeposits += amount.div(tick.yieldFactor);
        }
    }

    /**
     * @notice Logic for updating the rate of a position
     * @param position Target position
     * @param tick Current tick of the position
     * @param newTick New tick of the position
     * @param currentLoan Current loan information
     * @param referenceLoan Either first loan or detach loan of the position
     * @param newRate New rate
     * @return updatedAmount Amount of funds updated
     */
    function updateRate(
        DataTypes.Position storage position,
        DataTypes.Tick storage tick,
        DataTypes.Tick storage newTick,
        DataTypes.Loan storage referenceLoan,
        DataTypes.Loan storage currentLoan,
        uint256 newRate
    ) public returns (uint256 updatedAmount) {
        updatedAmount = withdraw(tick, position, type(uint256).max, referenceLoan, currentLoan);
        deposit(newTick, currentLoan, updatedAmount);

        position.baseDeposit = updatedAmount;
        position.rate = newRate;
        position.epochId = newTick.currentEpochId;
    }

    /**
     * @notice Logic for withdrawing an unborrowed position
     * @dev Can only be called either when there's no loan ongoing or the target position is not currently borrowed
     * @dev expectedWithdrawnAmount set to type(uint256).max means a full withdraw
     * @param tick Target tick
     * @param position Target position
     * @param expectedWithdrawnAmount Requested withdrawal amount
     * @param referenceLoan Either first loan or detach loan of the position
     * @param currentLoan Current loan information
     * @return withdrawnAmount Actual withdrawn amount
     */
    function withdraw(
        DataTypes.Tick storage tick,
        DataTypes.Position storage position,
        uint256 expectedWithdrawnAmount,
        DataTypes.Loan storage referenceLoan,
        DataTypes.Loan storage currentLoan
    ) public returns (uint256 withdrawnAmount) {
        uint256 positionCurrentValue = getPositionCurrentValue(tick, position, referenceLoan, currentLoan);

        if (expectedWithdrawnAmount == type(uint256).max) {
            withdrawnAmount = positionCurrentValue;
        } else {
            withdrawnAmount = expectedWithdrawnAmount;
        }

        // if the position was optedOut to exit, its value has already been removed from the tick data
        if (position.optOutLoanId > 0) {
            return positionCurrentValue;
        }

        // when the tick is not borrowed, all positions are part of the base epoch
        if (currentLoan.maturity == 0 || (currentLoan.maturity > 0 && tick.latestLoanId < currentLoan.id)) {
            uint256 adjustedAmountToWithdraw = withdrawnAmount.div(tick.yieldFactor);
            // @dev precision issue
            bool precisionIssueDetected = withdrawnAmount > tick.baseEpochsAmounts.available ||
                adjustedAmountToWithdraw > tick.baseEpochsAmounts.adjustedDeposits;

            if (!precisionIssueDetected) {
                tick.baseEpochsAmounts.available -= withdrawnAmount;
                tick.baseEpochsAmounts.adjustedDeposits -= adjustedAmountToWithdraw;
            } else {
                if (
                    withdrawnAmount > tick.baseEpochsAmounts.available + 10 ||
                    adjustedAmountToWithdraw > tick.baseEpochsAmounts.adjustedDeposits + 10
                ) revert RevolvingCreditLineErrors.RCL_NOT_ENOUGH_ADJUSTED_DEPOSITS();
                withdrawnAmount = tick.baseEpochsAmounts.available;
                tick.baseEpochsAmounts.available = 0;
                tick.baseEpochsAmounts.adjustedDeposits = 0;
            }
        }
        // when a loan is ongoing, only the current epoch is not borrowed
        else {
            if (currentLoan.maturity > 0 && tick.currentEpochId != position.epochId)
                revert RevolvingCreditLineErrors.RCL_LOAN_RUNNING();
            tick.newEpochsAmounts.toBeAdjusted -= withdrawnAmount;
            tick.newEpochsAmounts.available -= withdrawnAmount;
            tick.epochs[tick.currentEpochId].deposited -= withdrawnAmount;
        }

        if (expectedWithdrawnAmount != type(uint256).max) {
            position.baseDeposit = positionCurrentValue - expectedWithdrawnAmount;
            position.epochId = tick.currentEpochId;
            position.withdrawLoanId = 0;
            position.withdrawn = DataTypes.WithdrawalAmounts({borrowed: 0, expectedAccruals: 0});
        }
    }

    /**
     * @notice Logic for withdrawing the unborrowed part of a borrowed position
     * @dev Can only be called if the position is partially borrowed
     * @param tick Target tick
     * @param position Target position
     * @param referenceLoan Either first loan or detach loan of the position
     * @param currentLoan Current loan information
     * @return unborrowedAmount Position unborrowed amount that was withdrawn
     */
    function detach(
        DataTypes.Tick storage tick,
        DataTypes.Position storage position,
        DataTypes.Loan storage referenceLoan,
        DataTypes.Loan storage currentLoan,
        uint256 minDepositAmount
    ) external returns (uint256 unborrowedAmount) {
        DataTypes.Epoch storage epoch = tick.epochs[position.epochId];
        uint256 borrowedAmount;
        (unborrowedAmount, borrowedAmount) = getPositionRepartition(tick, position, referenceLoan, currentLoan);
        if (unborrowedAmount == 0) revert RevolvingCreditLineErrors.RCL_POSITION_FULLY_BORROWED();

        uint256 endOfLoanPositionValue = getPositionEndOfLoanValue(tick, position, referenceLoan, currentLoan);

        if (endOfLoanPositionValue - unborrowedAmount < minDepositAmount)
            revert RevolvingCreditLineErrors.RCL_REMAINING_AMOUNT_TOO_LOW();
        if (unborrowedAmount < minDepositAmount) revert RevolvingCreditLineErrors.RCL_AMOUNT_TOO_LOW();

        uint256 accruals = endOfLoanPositionValue - borrowedAmount - unborrowedAmount;

        if (position.epochId <= tick.loanStartEpochId) {
            uint256 adjustedAmount = getAdjustedAmount(tick, position, referenceLoan);
            if (position.optOutLoanId == currentLoan.id) {
                tick.baseEpochsAmounts.adjustedOptedOut -= adjustedAmount;
            } else {
                tick.withdrawnAmounts.borrowed += borrowedAmount;
                tick.withdrawnAmounts.toBeAdjusted += borrowedAmount + accruals;
            }
            tick.baseEpochsAmounts.adjustedDeposits -= adjustedAmount;
            tick.baseEpochsAmounts.available -= unborrowedAmount;
            tick.baseEpochsAmounts.borrowed -= borrowedAmount;
        } else {
            if (position.optOutLoanId == currentLoan.id) {
                epoch.optedOut -= position.baseDeposit;
                tick.newEpochsAmounts.optedOut -= position.baseDeposit;
            } else {
                tick.withdrawnAmounts.borrowed += borrowedAmount;
                tick.withdrawnAmounts.toBeAdjusted += borrowedAmount + accruals;
            }
            tick.newEpochsAmounts.available -= unborrowedAmount;
            tick.newEpochsAmounts.borrowed -= borrowedAmount;
            tick.newEpochsAmounts.toBeAdjusted = tick.newEpochsAmounts.toBeAdjusted - endOfLoanPositionValue;
            epoch.borrowed -= borrowedAmount;
            epoch.deposited -= position.baseDeposit;
            epoch.accruals -= accruals;
        }
        position.withdrawn = DataTypes.WithdrawalAmounts({borrowed: borrowedAmount, expectedAccruals: accruals});
        position.withdrawLoanId = currentLoan.id;
    }

    /**
     * @notice Logic for preparing an exit before reallocating the borrowed amount
     * @dev borrowedAmountToExit set to type(uint256).max means a full exit
     * @dev partial exits are only possible for fully matched positions
     * @dev any partially matched position can be detached to result in being fully matched
     * @param tick Target tick
     * @param position Target position
     * @param borrowedAmountToExit Requested borrowed amount to exit
     * @param referenceLoan Either first loan or detach loan of the position
     * @param currentLoan Current loan information
     * @return endOfLoanBorrowedAmountValue Expected end of loan value of the borrowed part of the position
     * @return realizedInterests Interests accrued by the position until the exit
     * @return borrowedAmount Borrowed part of the position
     * @return unborrowedAmount Unborrowed part of the position to be withdrawn
     */
    function registerExit(
        DataTypes.Tick storage tick,
        DataTypes.Position storage position,
        uint256 borrowedAmountToExit,
        DataTypes.Loan storage referenceLoan,
        DataTypes.Loan storage currentLoan
    )
        external
        returns (
            uint256 endOfLoanBorrowedAmountValue,
            uint256 realizedInterests,
            uint256 borrowedAmount,
            uint256 unborrowedAmount
        )
    {
        (unborrowedAmount, borrowedAmount) = getPositionRepartition(tick, position, referenceLoan, currentLoan);

        // scale down all amounts in case of partial exit
        if (borrowedAmountToExit == type(uint256).max) borrowedAmountToExit = borrowedAmount;
        uint256 exitProportion = borrowedAmountToExit.div(borrowedAmount);
        borrowedAmount = borrowedAmount.mul(exitProportion);

        // get position values
        uint256 currentPositionValue = getPositionCurrentValue(tick, position, referenceLoan, currentLoan).mul(
            exitProportion
        );
        uint256 startOfLoanPositionValue = getPositionStartOfLoanValue(tick, position, referenceLoan, currentLoan).mul(
            exitProportion
        );
        uint256 endOfLoanPositionValue = getPositionEndOfLoanValue(tick, position, referenceLoan, currentLoan).mul(
            exitProportion
        );
        realizedInterests = (currentPositionValue - startOfLoanPositionValue);
        endOfLoanBorrowedAmountValue = (endOfLoanPositionValue - realizedInterests - unborrowedAmount);
        if (position.withdrawn.borrowed > 0) {
            uint256 scaledWithdrawnAmount = position.withdrawn.borrowed.mul(exitProportion);
            tick.withdrawnAmounts.toBeAdjusted -= endOfLoanPositionValue;
            tick.withdrawnAmounts.borrowed -= scaledWithdrawnAmount;
            position.withdrawn.borrowed -= scaledWithdrawnAmount;
            position.withdrawn.expectedAccruals -= position.withdrawn.expectedAccruals.mul(exitProportion);
        }
        // register the exit for base epoch
        else if (position.epochId <= tick.loanStartEpochId) {
            (borrowedAmount, unborrowedAmount) = registerBaseEpochExit(
                tick,
                position,
                referenceLoan,
                borrowedAmount,
                unborrowedAmount,
                exitProportion
            );
        }
        // register the exit for new epochs
        else {
            registerNewEpochExit(
                tick,
                position,
                currentLoan,
                startOfLoanPositionValue,
                currentPositionValue,
                endOfLoanPositionValue,
                borrowedAmount,
                unborrowedAmount
            );
        }
    }

    /**
     * @notice Prepare the exit of a base epoch position
     * @param tick Target tick
     * @param position Target position
     * @param referenceLoan Either first loan or detach loan of the position
     * @param borrowedAmount Borrowed amount of the position
     * @param unborrowedAmount Unborrowed amount of the position
     * @param exitProportion Proportion of the position to be withdrawn, used for partial exits
     * @return actualBorrowedAmount Actual borrowed amound, differ from the input in case of imprecision
     * @return actualUnborrowedAmount Actual unborrowed amound, differ from the input in case of imprecision
     */
    function registerBaseEpochExit(
        DataTypes.Tick storage tick,
        DataTypes.Position storage position,
        DataTypes.Loan storage referenceLoan,
        uint256 borrowedAmount,
        uint256 unborrowedAmount,
        uint256 exitProportion
    ) public returns (uint256 actualBorrowedAmount, uint256 actualUnborrowedAmount) {
        uint256 adjustedAmount = getAdjustedAmount(tick, position, referenceLoan).mul(exitProportion);
        // @dev precision issue
        if (adjustedAmount > tick.baseEpochsAmounts.adjustedDeposits) {
            if (adjustedAmount > tick.baseEpochsAmounts.adjustedDeposits + 10)
                revert RevolvingCreditLineErrors.RCL_NOT_ENOUGH_ADJUSTED_DEPOSITS();

            actualBorrowedAmount = tick.baseEpochsAmounts.borrowed;
            actualUnborrowedAmount = tick.baseEpochsAmounts.available;

            tick.baseEpochsAmounts.adjustedDeposits = 0;
            tick.baseEpochsAmounts.borrowed = 0;
            tick.baseEpochsAmounts.available = 0;
        } else {
            actualBorrowedAmount = borrowedAmount;
            actualUnborrowedAmount = unborrowedAmount;

            tick.baseEpochsAmounts.adjustedDeposits -= adjustedAmount;
            tick.baseEpochsAmounts.borrowed -= borrowedAmount;
            tick.baseEpochsAmounts.available -= unborrowedAmount;
        }

        uint256 precedingLoanId = tick.epochs[tick.loanStartEpochId].precedingLoanId;
        position.baseDeposit -= borrowedAmount
            .mul(getEquivalentYieldFactor(tick, tick.epochs[position.epochId], referenceLoan))
            .div(tick.endOfLoanYieldFactors[precedingLoanId]);
    }

    /**
     * @notice Prepare the exit of a new epoch position
     * @param tick Target tick
     * @param position Target position
     * @param currentLoan Current loan information
     * @param startOfLoanPositionValue Value of the position at the start of the loan
     * @param currentPositionValue Current value of the position
     * @param endOfLoanPositionValue Value of the position at the end of the loan
     * @param borrowedAmount Borrowed amount of the position
     * @param unborrowedAmount Unborrowed amount of the position
     */
    function registerNewEpochExit(
        DataTypes.Tick storage tick,
        DataTypes.Position storage position,
        DataTypes.Loan storage currentLoan,
        uint256 startOfLoanPositionValue,
        uint256 currentPositionValue,
        uint256 endOfLoanPositionValue,
        uint256 borrowedAmount,
        uint256 unborrowedAmount
    ) public {
        DataTypes.Epoch storage epoch = tick.epochs[position.epochId];

        // update epoch
        epoch.borrowed -= borrowedAmount;
        epoch.deposited -= startOfLoanPositionValue;
        epoch.accruals -= (endOfLoanPositionValue - startOfLoanPositionValue);

        // update tick
        tick.newEpochsAmounts.borrowed -= borrowedAmount;
        tick.newEpochsAmounts.available -= unborrowedAmount;
        tick.newEpochsAmounts.toBeAdjusted -=
            currentPositionValue +
            accrualsFor(borrowedAmount, currentLoan.maturity - block.timestamp, position.rate);
        position.baseDeposit -= borrowedAmount;
    }

    /**
     * @notice Redistributes the amount to be exited on the order book
     * @dev Logic is similar to a borrow, with the exception that we optimise for end of position value
     * @dev Since the repaid amount must be the same at the end of loan, the borrowed amount can vary depending on the rate of the receiving tick
     * @dev Accruals realized by the exited position are counted as borrowed amount, they will be repaid at the end of the loan
     * @dev Positions that advance realized accruals also claim the accruals that are missed due to that actions, these are basically advances accruals accruals
     * @param tick Target tick
     * @param currentLoan Current loan information
     * @param endOfLoanBorrowedAmountValue Expected end of loan value of the exited borrowed amount
     * @param remainingAccrualsToAllocate Remaining amount of realized accruals left to be allocated to the order book
     * @param rate Rate of the exiting tick
     * @param one One value for the token precision
     * @return tickBorrowed Amount borrowed from the tick
     * @return tickAllocatedAccruals Amount of accruals allocated to the tick
     * @return tickAllocatedAccrualsInterests Expected amount of accruals of the allocated accruals
     * @return tickBorrowedEndOfLoanValue End of loan value of the amount borrowed in the tick
     */
    function exit(
        DataTypes.Tick storage tick,
        DataTypes.Loan storage currentLoan,
        uint256 endOfLoanBorrowedAmountValue,
        uint256 remainingAccrualsToAllocate,
        uint256 rate,
        uint256 one
    )
        external
        returns (
            uint256 tickBorrowed,
            uint256 tickAllocatedAccruals,
            uint256 tickAllocatedAccrualsInterests,
            uint256 tickBorrowedEndOfLoanValue
        )
    {
        uint256 tickToBorrowEquivalent = toTickCurrentValue(
            endOfLoanBorrowedAmountValue,
            currentLoan.maturity,
            rate,
            one
        );

        (tickBorrowed, tickAllocatedAccruals, tickAllocatedAccrualsInterests) = borrow(
            tick,
            currentLoan,
            DataTypes.BorrowInput({
                totalAmountToBorrow: tickToBorrowEquivalent,
                totalAccrualsToAllocate: remainingAccrualsToAllocate,
                rate: rate
            })
        );

        tickBorrowedEndOfLoanValue = toEndOfLoanValue(tickBorrowed, currentLoan.maturity, rate, one);
    }

    /**
     * @notice Mark the position as optedOut and register the optedOut amount in the ticks
     * @param tick Target tick
     * @param position Target position
     * @param referenceLoan Either first loan or detach loan of the position
     * @param currentLoan Current loan information
     */
    function optOut(
        DataTypes.Tick storage tick,
        DataTypes.Position storage position,
        DataTypes.Loan storage referenceLoan,
        DataTypes.Loan storage currentLoan
    ) external {
        DataTypes.Epoch storage epoch = tick.epochs[position.epochId];

        if (position.withdrawLoanId == currentLoan.id) {
            tick.withdrawnAmounts.borrowed -= position.withdrawn.borrowed;
            tick.withdrawnAmounts.toBeAdjusted -= position.withdrawn.borrowed + position.withdrawn.expectedAccruals;
        }
        // if the position is from the base epoch, the adjusted amount to remove at the end of the loan is known in advance
        else if (position.epochId <= tick.loanStartEpochId) {
            tick.baseEpochsAmounts.adjustedOptedOut += getAdjustedAmount(tick, position, referenceLoan);
        }
        // if the position is from a new epoch, the exact earnings to be removed at the end of the loan will be computed later
        else {
            epoch.optedOut += position.baseDeposit;
            tick.newEpochsAmounts.optedOut += position.baseDeposit;
        }
        position.optOutLoanId = currentLoan.id;
    }

    /*//////////////////////////////////////////////////////////////
                            BORROWER LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Logic for borrowing against the order book
     * @dev The borrow args are in a struct to prevent a stack too deep error
     * @dev This function is used both when borrowing and exiting, the logic being the exact same
     * @dev When borrowing, the amount of accruals to allocate is set to zero
     * @dev This function is responsible for the deciding how to allocate borrowed amounts between base and new epochs
     * @param tick Target tick
     * @param currentLoan Current loan information
     * @param args Input arguments for the borrow actions
     * @return tickBorrowed Amount borrowed from the target tick
     * @return tickAccrualsAllocated Amount of accruals allocated to the target tick
     * @return tickAccrualsExpectedEarnings Amount of expected accruals accumualted until the end of the loan by the accruals allocated to the tick
     */
    function borrow(
        DataTypes.Tick storage tick,
        DataTypes.Loan storage currentLoan,
        DataTypes.BorrowInput memory args
    )
        public
        returns (
            uint256 tickBorrowed,
            uint256 tickAccrualsAllocated,
            uint256 tickAccrualsExpectedEarnings
        )
    {
        DataTypes.Epoch storage epoch;
        uint256 epochBorrowed = 0;
        uint256 epochAccruals = 0;
        if (tick.baseEpochsAmounts.available + tick.newEpochsAmounts.available > 0) {
            // borrow from base epoch
            // @dev precision issue - available amount and adjusted deposits can be desynchronised with zero value
            if (tick.baseEpochsAmounts.available > 0 && tick.baseEpochsAmounts.adjustedDeposits > 0) {
                uint256 epochId = tick.currentEpochId;
                // if this is the first borrow for that tick, we rectify the epochId
                if (tick.latestLoanId == currentLoan.id) epochId--;
                epoch = tick.epochs[epochId];
                (epochBorrowed, epochAccruals) = borrowFromBase({
                    tick: tick,
                    epoch: epoch,
                    currentLoan: currentLoan,
                    amountToBorrow: args.totalAmountToBorrow,
                    accrualsToAllocate: args.totalAccrualsToAllocate,
                    rate: args.rate
                });
            }
            // else tap into new epoch potential partial fill
            else {
                epoch = tick.epochs[tick.currentEpochId - 1];
                if (!epoch.isBaseEpoch && epoch.deposited > epoch.borrowed && epoch.borrowed > 0) {
                    (epochBorrowed, epochAccruals) = borrowFromNew({
                        tick: tick,
                        epoch: epoch,
                        currentLoan: currentLoan,
                        amountToBorrow: args.totalAmountToBorrow,
                        accrualsToAllocate: args.totalAccrualsToAllocate,
                        rate: args.rate
                    });
                }
            }
            uint256 timeUntilMaturity = currentLoan.maturity - block.timestamp;
            args.totalAmountToBorrow -= epochBorrowed;
            tickBorrowed += epochBorrowed;
            args.totalAccrualsToAllocate -= epochAccruals;
            tickAccrualsAllocated += epochAccruals;
            tickAccrualsExpectedEarnings += accrualsFor(epochAccruals, timeUntilMaturity, args.rate);

            // if amount remaining, tap into untouched new epoch
            if (args.totalAmountToBorrow > 0 && tick.newEpochsAmounts.available > 0) {
                epoch = tick.epochs[tick.currentEpochId];
                (epochBorrowed, epochAccruals) = borrowFromNew({
                    tick: tick,
                    epoch: epoch,
                    currentLoan: currentLoan,
                    amountToBorrow: args.totalAmountToBorrow,
                    accrualsToAllocate: args.totalAccrualsToAllocate,
                    rate: args.rate
                });

                tickBorrowed += epochBorrowed;
                tickAccrualsAllocated += epochAccruals;
                tickAccrualsExpectedEarnings += accrualsFor(epochAccruals, timeUntilMaturity, args.rate);
            }
        }
    }

    /**
     * @notice Borrow against the base epoch of the tick
     * @param tick Target tick
     * @param epoch Target epoch
     * @param currentLoan Current loan information
     * @param amountToBorrow Total amount to borrow left to allocate
     * @param accrualsToAllocate Total accruals left to allocate
     * @param rate Rate of the tick being borrowed
     * @return amountBorrowed Actual borrowed amount in the tick
     * @return accrualsAllocated Actual amount of accruals allocated to the tick
     */
    function borrowFromBase(
        DataTypes.Tick storage tick,
        DataTypes.Epoch storage epoch,
        DataTypes.Loan storage currentLoan,
        uint256 amountToBorrow,
        uint256 accrualsToAllocate,
        uint256 rate
    ) public returns (uint256 amountBorrowed, uint256 accrualsAllocated) {
        if (tick.baseEpochsAmounts.borrowed == 0) {
            epoch.isBaseEpoch = true;
            tick.loanStartEpochId = tick.currentEpochId;
            epoch.precedingLoanId = tick.latestLoanId;
            epoch.loanId = currentLoan.id;
            tick.latestLoanId = currentLoan.id;
            tick.currentEpochId += 1;
        }
        (amountBorrowed, accrualsAllocated) = allocateBorrowAmounts(
            tick.baseEpochsAmounts.available,
            amountToBorrow,
            accrualsToAllocate
        );
        tick.baseEpochsAmounts.borrowed += amountBorrowed + accrualsAllocated;
        tick.baseEpochsAmounts.available -= amountBorrowed + accrualsAllocated;
        tick.yieldFactor += accrualsFor(
            amountBorrowed + accrualsAllocated,
            currentLoan.maturity - block.timestamp,
            rate
        ).div(tick.baseEpochsAmounts.adjustedDeposits);
    }

    /**
     * @notice Borrow against the new epoch of the tick
     * @param tick Target tick
     * @param epoch Target epoch
     * @param currentLoan Current loan information
     * @param amountToBorrow Total amount to borrow left to allocate
     * @param accrualsToAllocate Total accruals left to allocate
     * @param rate Rate of the tick being borrowed
     * @return amountBorrowed Actual borrowed amount in the tick
     * @return accrualsAllocated Actual amount of accruals allocated to the tick
     */
    function borrowFromNew(
        DataTypes.Tick storage tick,
        DataTypes.Epoch storage epoch,
        DataTypes.Loan storage currentLoan,
        uint256 amountToBorrow,
        uint256 accrualsToAllocate,
        uint256 rate
    ) public returns (uint256 amountBorrowed, uint256 accrualsAllocated) {
        if (epoch.borrowed == 0) {
            epoch.loanId = currentLoan.id;
            tick.currentEpochId += 1;
        }
        uint256 epochAvailable = epoch.deposited - epoch.borrowed;
        (amountBorrowed, accrualsAllocated) = allocateBorrowAmounts(epochAvailable, amountToBorrow, accrualsToAllocate);

        uint256 earnings = accrualsFor(
            amountBorrowed + accrualsAllocated,
            currentLoan.maturity - block.timestamp,
            rate
        );
        epoch.borrowed += amountBorrowed + accrualsAllocated;
        epoch.accruals += earnings;

        tick.newEpochsAmounts.borrowed += amountBorrowed + accrualsAllocated;
        tick.newEpochsAmounts.available -= amountBorrowed + accrualsAllocated;
        tick.newEpochsAmounts.toBeAdjusted += earnings;
    }

    /*//////////////////////////////////////////////////////////////
                            FEES
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Logic to persist the repayment fees for base epoch
     * @param tick Target tick
     * @param feesController Address of the fees controller
     * @return baseEpochsFees Amount of fees accrued for the tick base epoch
     */
    function registerBaseEpochFees(DataTypes.Tick storage tick, IFeesController feesController)
        public
        returns (uint256 baseEpochsFees)
    {
        if (tick.baseEpochsAmounts.adjustedDeposits == 0) return 0;
        uint256 baseEpochsAccruals = tick.baseEpochsAmounts.adjustedDeposits.mul(tick.yieldFactor) -
            tick.baseEpochsAmounts.available -
            tick.baseEpochsAmounts.borrowed;
        baseEpochsFees = feesController.registerRepaymentFees(baseEpochsAccruals);
        tick.yieldFactor -= baseEpochsFees.div(tick.baseEpochsAmounts.adjustedDeposits);
    }

    /**
     * @notice Logic to persist the repayment fees for new epochs
     * @param tick Target tick
     * @param feesController Address of the fees controller
     * @return newEpochsFees Amount of fees accrued for the tick new epochs
     */
    function registerNewEpochsFees(DataTypes.Tick storage tick, IFeesController feesController)
        public
        returns (uint256 newEpochsFees)
    {
        uint256 newEpochsAccruals = tick.newEpochsAmounts.toBeAdjusted -
            tick.newEpochsAmounts.borrowed -
            tick.newEpochsAmounts.available;
        newEpochsFees = feesController.registerRepaymentFees(newEpochsAccruals);
        tick.newEpochsAmounts.toBeAdjusted -= newEpochsFees;
    }

    /**
     * @notice Logic to persist the repayment fees for base epoch and new epochs
     * @param tick Target tick
     * @param feesController Address of the fees controller
     * @return fees Amount of fees accrued for the tick base epoch and the tick new epochs
     */
    function registerRepaymentFees(DataTypes.Tick storage tick, IFeesController feesController)
        external
        returns (uint256 fees)
    {
        uint256 baseEpochsFees = registerBaseEpochFees(tick, feesController);
        uint256 newEpochsFees = registerNewEpochsFees(tick, feesController);
        fees = baseEpochsFees + newEpochsFees;
    }

    /*//////////////////////////////////////////////////////////////
                              VALIDATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Validation logic for withdrawal actions
     * @dev Used for both withdraw and update rate actions
     * @param position Target position
     * @param tick Target tick
     * @param referenceLoan Either first loan or detach loan of the position
     * @param currentLoan Current loan information
     * @param amountToWithdraw Amount of funds to withdraw from the tick
     * @param minDepositAmount Minimum amount of funds that must be held in a position
     */
    function validateWithdraw(
        DataTypes.Position storage position,
        DataTypes.Tick storage tick,
        DataTypes.Loan storage referenceLoan,
        DataTypes.Loan storage currentLoan,
        uint256 amountToWithdraw,
        uint256 minDepositAmount
    ) external view {
        if (position.creationTimestamp == block.timestamp) revert RevolvingCreditLineErrors.RCL_TIMELOCK();

        (, uint256 borrowedAmount) = getPositionRepartition(tick, position, referenceLoan, currentLoan);
        if (borrowedAmount > 0) revert RevolvingCreditLineErrors.RCL_POSITION_BORROWED();
        uint256 positionCurrentValue = getPositionCurrentValue(tick, position, referenceLoan, currentLoan);
        if (amountToWithdraw != type(uint256).max && amountToWithdraw > positionCurrentValue)
            revert RevolvingCreditLineErrors.RCL_AMOUNT_TOO_HIGH();
        if (amountToWithdraw != type(uint256).max && positionCurrentValue - amountToWithdraw < minDepositAmount)
            revert RevolvingCreditLineErrors.RCL_REMAINING_AMOUNT_TOO_LOW();
        if (amountToWithdraw < minDepositAmount) revert RevolvingCreditLineErrors.RCL_AMOUNT_TOO_LOW();
    }

    /**
     * @notice Validation logic for exit actions
     * @param position Target position
     * @param tick Target tick
     * @param referenceLoan Either first loan or detach loan of the position
     * @param currentLoan Current loan information
     * @param borrowedAmountToExit Borrowed amount from the position to exit
     * @param minDepositAmount Minimum amount of funds that must be held in a position
     */
    function validateExit(
        DataTypes.Position storage position,
        DataTypes.Tick storage tick,
        DataTypes.Loan storage referenceLoan,
        DataTypes.Loan storage currentLoan,
        uint256 borrowedAmountToExit,
        uint256 minDepositAmount
    ) external view {
        (uint256 unborrowedAmount, uint256 borrowedAmount) = getPositionRepartition(
            tick,
            position,
            referenceLoan,
            currentLoan
        );
        if ((unborrowedAmount > 0) && borrowedAmountToExit != type(uint256).max)
            revert RevolvingCreditLineErrors.RCL_POSITION_NOT_FULLY_BORROWED();
        if (borrowedAmount == 0) revert RevolvingCreditLineErrors.RCL_POSITION_NOT_BORROWED();
        if (position.optOutLoanId > 0) revert RevolvingCreditLineErrors.RCL_HAS_OPTED_OUT();
        if (block.timestamp > currentLoan.maturity) revert RevolvingCreditLineErrors.RCL_CANNOT_EXIT();
        if (borrowedAmountToExit != type(uint256).max && borrowedAmountToExit > borrowedAmount)
            revert RevolvingCreditLineErrors.RCL_AMOUNT_TOO_HIGH();
        if (borrowedAmountToExit != type(uint256).max && borrowedAmount - borrowedAmountToExit < minDepositAmount)
            revert RevolvingCreditLineErrors.RCL_REMAINING_AMOUNT_TOO_LOW();
        if (borrowedAmountToExit < minDepositAmount) revert RevolvingCreditLineErrors.RCL_AMOUNT_TOO_LOW();
    }

    /**
     * @notice Validation logic for position opting out
     * @param position Target position
     * @param tick Target tick
     * @param referenceLoan Either first loan or detach loan of the position
     * @param currentLoan Current loan information
     */
    function validateOptOut(
        DataTypes.Position storage position,
        DataTypes.Tick storage tick,
        DataTypes.Loan storage referenceLoan,
        DataTypes.Loan storage currentLoan
    ) external view {
        (, uint256 borrowedAmount) = getPositionRepartition(tick, position, referenceLoan, currentLoan);

        if (borrowedAmount == 0) revert RevolvingCreditLineErrors.RCL_POSITION_NOT_BORROWED();
        if (block.timestamp > currentLoan.maturity) revert RevolvingCreditLineErrors.RCL_MATURITY_PASSED();
    }

    /*//////////////////////////////////////////////////////////////
                            UTILS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Calculates the accruals accumulated by an amount during a duration and at a target rate
     * @param amount Amount to calculate accruals for
     * @param timeDelta Duration during which to calculate the accruals
     * @param rate Accrual rate
     */
    function accrualsFor(
        uint256 amount,
        uint256 timeDelta,
        uint256 rate
    ) public view returns (uint256 accruals) {
        accruals = ((amount * timeDelta * rate) / 365 days).mul(1);
    }

    /**
     * @notice Logic for allocating amounts to borrow between amount to borrow and accruals to allocate
     * @param epochAvailable Amount available in the target epoch
     * @param amountToBorrow Total amount to borrow
     * @param accrualsToAllocate Total amount of accruals to allocate
     * @return amountBorrowed Actual amount borrowed for the epoch
     * @return accrualsAllocated Actual amount of accruals to allocate for the epoch
     */
    function allocateBorrowAmounts(
        uint256 epochAvailable,
        uint256 amountToBorrow,
        uint256 accrualsToAllocate
    ) public view returns (uint256 amountBorrowed, uint256 accrualsAllocated) {
        if (amountToBorrow + accrualsToAllocate >= epochAvailable) {
            accrualsAllocated = accrualsToAllocate.mul(epochAvailable).div(amountToBorrow + accrualsToAllocate);
            amountBorrowed = epochAvailable - accrualsAllocated;
        } else {
            amountBorrowed = amountToBorrow;
            accrualsAllocated = accrualsToAllocate;
        }
    }

    /**
     * @notice Util to calculate the equivalent current value of an amount for a tick depending on its end of loan value
     * @param endOfLoanValue Address of the fees controller
     * @param currentMaturity Maturity of the current loan
     * @param rate Rate of the target tick
     * @param one One value for the token precision
     * @return tickCurrentValue Equivalent current value for the target tick
     */
    function toTickCurrentValue(
        uint256 endOfLoanValue,
        uint256 currentMaturity,
        uint256 rate,
        uint256 one
    ) private view returns (uint256 tickCurrentValue) {
        uint256 currentValueToEndOfLoanMultiplier = one + accrualsFor(one, currentMaturity - block.timestamp, rate);
        tickCurrentValue = endOfLoanValue.div(currentValueToEndOfLoanMultiplier);
    }

    /**
     * @notice Util to calculate the end loan value of an amount for a tick depending on its current value
     * @param tickCurrentValue Current value of the amount
     * @param currentMaturity Maturity of the current loan
     * @param rate Rate of the target tick
     * @param one One value for the token precision
     * @return endOfLoanValue Value of the amount at the end of the loan
     */
    function toEndOfLoanValue(
        uint256 tickCurrentValue,
        uint256 currentMaturity,
        uint256 rate,
        uint256 one
    ) private view returns (uint256 endOfLoanValue) {
        uint256 currentValueToEndOfLoanMultiplier = one + accrualsFor(one, currentMaturity - block.timestamp, rate);
        endOfLoanValue = tickCurrentValue.mul(currentValueToEndOfLoanMultiplier);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

/**
 * @title IRCLBorrowers
 * @author Atlendis Labs
 */
interface IRCLBorrowers {
    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Emitted during a borow
     * @param borrowedAmount Amount of funds borrowed again the order book
     * @param fees Total fees taken
     * @param to Receiving address of the borrowed funds
     */
    event Borrow(uint256 borrowedAmount, uint256 fees, address to);

    /**
     * @notice Emitted during a repayment
     * @param repaidAmount Total amount repaid by the borrower
     * @param fees Total fees taken
     */
    event Repay(uint256 repaidAmount, uint256 fees);

    /*//////////////////////////////////////////////////////////////
                                FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Borrow funds from the pool against the order book
     * The to address has to have a borrowed role
     * It is not possible to borrow after the current loan maturity has passed
     * @param to Receiving address of the borrowed funds
     * @param amount Amount of funds to borrow
     *
     * Emits a {Borrow} event
     */
    function borrow(address to, uint256 amount) external;

    /**
     * @notice Repay borrowed funds with interest to the pool
     *
     * Emits a {Repay} event
     */
    function repay() external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../../../../common/fees/IFeesController.sol';
import '../../../../common/non-standard-repayment/INonStandardRepaymentModule.sol';
import '../../../../interfaces/ITimelock.sol';
import '../../../../libraries/PoolTimelockLogic.sol';

/**
 * @title IRCLGovernance
 * @author Atlendis Labs
 */
interface IRCLGovernance is ITimelock {
    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Emitted when the pool is closed
     */
    event Closed();

    /**
     * @notice Emitted when the pool is opened
     */
    event Opened();

    /**
     * @notice Emitted when fees are withdrawn to the fees controller
     * @param fees Amount of fees withdrawn to the fees controller
     */
    event FeesWithdrawn(uint256 fees);

    /**
     * @notice Emitted when the fees controller is set
     * @param feesController Address of the fees controller
     */
    event FeesControllerSet(address feesController);

    /**
     * @notice Emitted when a non standard repayment procedure has started
     * @param nonStandardRepaymentModule Address of the non standard repayment module contract
     * @param delay Timelock delay
     */
    event NonStandardRepaymentProcedureStarted(address nonStandardRepaymentModule, uint256 delay);

    /**
     * @notice Emitted when a rescue procedure has started
     * @param recipient Recipient address of the unborrowed funds
     * @param delay Timelock delay
     */
    event RescueProcedureStarted(address recipient, uint256 delay);

    /**
     * @notice Emitted when the minimum deposit amount has been updated
     * @param minDepositAmount Updated value of the minimum deposit amount
     */
    event MinDepositAmountUpdated(uint256 minDepositAmount);

    /**
     * @notice Emitted when the maximum borrowable amount has been updated
     * @param maxBorrowableAmount Updated value of the maximum borrowable amount
     */
    event MaxBorrowableAmountUpdated(uint256 maxBorrowableAmount);

    /*//////////////////////////////////////////////////////////////
                                FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Closes the pool
     * Changes the pool phase to CLOSED, stops all actions in the pool
     *
     * Emits a {Closed} event
     */
    function close() external;

    /**
     * @notice Opens a pool that was closed before
     * Changes the pool phase to OPEN
     *
     * Emits a {Opened} event
     */
    function open() external;

    /**
     * @notice Set the fees controller contract address
     * @param feesController Address of the fees controller
     *
     * Emits a {FeesControllerSet} event
     */
    function setFeesController(IFeesController feesController) external;

    /**
     * @notice Starts a non standard repayment procedure by initiating a timelock for
     * - Stops all native actions possible in the pool
     * - Sends the unborrowed funds to the non standard repayment procedure contract
     * - Initializes the non standard repayment procedure contract
     * @param nonStandardRepaymentModule Address of the non standard repayment module contract
     * @param delay Timelock delay
     *
     * Emits a {NonStandardRepaymentProcedureStarted} event
     */
    function startNonStandardRepaymentProcedure(INonStandardRepaymentModule nonStandardRepaymentModule, uint256 delay)
        external;

    /**
     * @notice Start a rescue procedure by initiating a timelock for
     * - Stops all native actions possible in the pool
     * - Sends the unborrowed funds to a recipient address
     * @param recipient Address to which the funds will be sent
     * @param delay Timelock delay
     *
     * Emits a {RescueProcedureStarted} event
     */
    function startRescueProcedure(address recipient, uint256 delay) external;

    /**
     * @notice Update the minimum deposit amount
     * @param minDepositAmount New value of the minimum deposit amount
     *
     * Emits a {MinDepositAmountUpdated} event
     */
    function updateMinDepositAmount(uint256 minDepositAmount) external;

    /**
     * @notice Update the maximum borrowable amount
     * @param maxBorrowableAmount New value of the maximum borrowable amount
     *
     * Emits a {MaxBorrowableAmountUpdated} event
     */
    function updateMaxBorrowableAmount(uint256 maxBorrowableAmount) external;

    /**
     * @notice Withdraw fees to the fees controller
     *
     * Emits a {FeesWithdrawn} event
     */
    function withdrawFees() external;

    /**
     * @notice Retrieve the current timelock
     * @return timelock The current timelock, may be empty
     */
    function getTimelock() external view returns (PoolTimelock memory timelock);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

/**
 * @title IRCLenders
 * @author Atlendis Labs
 */
interface IRCLLenders {
    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Emitted when a deposit is made on the pool
     * @param positionId ID of the position
     * @param to Receing address of the position
     * @param amount Amount of funds to deposit
     * @param rate Target deposit rate
     * @param epochId Id of the deposit epoch
     */
    event Deposit(uint256 indexed positionId, address to, uint256 amount, uint256 rate, uint256 epochId);

    /**
     * @notice Emitted when a position is withdrawn
     * @dev amountToWithdraw set to type(uint256).max means a full withdraw
     * @param positionId ID of the position
     * @param amountToWithdraw Amount of funds to be withdrawn
     * @param receivedAmount Amount of funds received by the position owner
     * @param managementFees Amount of fees taken
     */
    event Withdraw(
        uint256 indexed positionId,
        uint256 amountToWithdraw,
        uint256 receivedAmount,
        uint256 managementFees
    );

    /**
     * @notice Emitted when the unborrowed part of a borrowed position is withdrawn
     * @param positionId ID of the position
     * @param receivedAmount Amount of funds received by the position owner
     * @param managementFees Amount of fees taken
     */
    event Detach(uint256 indexed positionId, uint256 receivedAmount, uint256 managementFees);

    /**
     * @notice Emitted when a position's rate is updated
     * @param positionId ID of the position
     * @param newRate New rate of the position
     */
    event UpdateRate(uint256 indexed positionId, uint256 newRate);

    /**
     * @notice Emitted when a borrowed position is signalling its intention to not be a part of the next loan
     * @param positionId ID of the position
     * @param loanId ID of the current loan after which the position will be opted out
     */
    event OptOut(uint256 indexed positionId, uint256 loanId);

    /**
     * @notice Emitted when a position is exited
     * @dev borrowedAmountToExit set to type(uint256).max means a full exit
     * @dev full exits are only possible for fully matched positions
     * @param positionId ID of the position
     * @param borrowedAmountToExit Amount of borrowed funds to exit
     * @param receivedAmount Amount of funds received by the position owner
     * @param exitFees Amount of fees taken
     */
    event Exit(uint256 indexed positionId, uint256 borrowedAmountToExit, uint256 receivedAmount, uint256 exitFees);

    /*//////////////////////////////////////////////////////////////
                                FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deposit funds to the target rate tick
     * @param rate Rate to which deposit funds
     * @param amount Amount of funds to deposit
     * @param to Receing address of the position
     * @return positionId ID of the newly minted position
     *
     * Emits a {Deposit} event
     */
    function deposit(
        uint256 rate,
        uint256 amount,
        address to
    ) external returns (uint256 positionId);

    /**
     * @notice Withdraw funds from the order book
     * @dev amountToWithdraw set to type(uint256).max means a full withdraw
     * @dev amountToWithdraw must be set between 0 and positionCurrentValue
     * @dev full withdrawals need the pool approval to transfer the position
     * @dev a successful full withdraw will burn the position
     * @param positionId ID of the position
     * @param amountToWithdraw Address of the fees controller
     *
     * Emits a {Withdraw} event
     */
    function withdraw(uint256 positionId, uint256 amountToWithdraw) external;

    /**
     * @notice Withdrawn the unborrowed part of a borrowed position
     * @param positionId ID of the position
     *
     * Emits a {Detach} event
     */
    function detach(uint256 positionId) external;

    /**
     * @notice Update the rate of a position
     * @param positionId ID of the position
     * @param newRate New rate of the position
     *
     * Emits a {UpdateRate} event
     */
    function updateRate(uint256 positionId, uint256 newRate) external;

    /**
     * @notice Opt out a borrowed position from a loan and remove it from the borrowable funds
     * @param positionId The ID of the position
     *
     * Emits a {OptOut} event
     */
    function optOut(uint256 positionId) external;

    /**
     * @notice Exit a position from the current loan
     * @dev will reallocate the borrowed part of the position as well as realized accrualas, and withdraw the unborrowed part of the position
     * @dev borrowedAmountToExit set to type(uint256).max means a full exit
     * @dev full exits are only possible for fully matched positions
     * @dev full exits will burn the position and need pool approval to transfer it
     * @param positionId ID of the position
     * @param borrowedAmountToExit Address of the fees controller
     *
     * Emits a {Exit} event
     */
    function exit(uint256 positionId, uint256 borrowedAmountToExit) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

/**
 * @title IRCLOrderBook
 * @author Atlendis Labs
 */
interface IRCLOrderBook {
    /*//////////////////////////////////////////////////////////////
                                FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Retrieve the current maturity
     * @return maturity The current maturity
     */
    function getMaturity() external view returns (uint256 maturity);

    /**
     * @notice Gets the target epoch data
     * @param rate Rate of the queried tick
     * @param epochId ID of the queried epoch
     * @return deposited Amount of funds deposited into the epoch
     * @return borrowed Amount of funds borrowed from the epoch
     * @return accruals Accruals generated by the epoch
     * @return loanId ID of the first loan of the epoch
     * @return isBaseEpoch Boolean to signify whether the epoch is a base epoch or not
     */
    function getEpoch(uint256 rate, uint256 epochId)
        external
        view
        returns (
            uint256 deposited,
            uint256 borrowed,
            uint256 accruals,
            uint256 loanId,
            bool isBaseEpoch
        );

    /**
     * @notice Gets the base epoch amounts for the target tick
     * @param rate Rate of the queried tick
     * @return adjustedDeposits Amount of deposited funds adjusted to the tick yield factor
     * @return borrowed Amount borrowed from the base epoch
     * @return available Amount available to be borrowed from the base epoch
     * @return adjustedOptedOut Adjusted amount opted out of the next loan
     */
    function getTickBaseEpochsAmounts(uint256 rate)
        external
        view
        returns (
            uint256 adjustedDeposits,
            uint256 borrowed,
            uint256 available,
            uint256 adjustedOptedOut
        );

    /**
     * @notice Gets the new epochs amounts for the target tick
     * @param rate Rate of the queried tick
     * @return toBeAdjusted Total amount to be adjusted and included into the base epoch at the end of the current loan
     * @return borrowed Amount borrowed from the new epochs
     * @return available Amount available to be borrowed from the new epochs
     * @return optedOut Amount opted out of the next loan
     */
    function getTickNewEpochsAmounts(uint256 rate)
        external
        view
        returns (
            uint256 toBeAdjusted,
            uint256 borrowed,
            uint256 available,
            uint256 optedOut
        );
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../../../libraries/FixedPointMathLib.sol';
import '../../../libraries/TimeValue.sol';
import '../libraries/TickLogic.sol';
import './interfaces/IRCLBorrowers.sol';
import './RCLOrderBook.sol';

/**
 * @title RCLBorrowers
 * @author Atlendis Labs
 * @notice Implementation of IBorrowers
 */
abstract contract RCLBorrowers is IRCLBorrowers, RCLOrderBook {
    /*//////////////////////////////////////////////////////////////
                                LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Restrict the sender of the message to the borrowe, i.e. default admin
     */
    modifier onlyBorrower() {
        if (!rolesManager.isBorrower(msg.sender)) revert RevolvingCreditLineErrors.RCL_ONLY_BORROWER();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IRCLBorrowers
     */
    function borrow(address to, uint256 amount) external onlyBorrower onlyInPhase(DataTypes.OrderBookPhase.OPEN) {
        if (currentLoan.maturity > 0 && block.timestamp > currentLoan.maturity)
            revert RevolvingCreditLineErrors.RCL_MATURITY_PASSED();
        if (amount + totalBorrowed > maxBorrowableAmount) revert RevolvingCreditLineErrors.RCL_AMOUNT_EXCEEDS_MAX();
        if (amount == 0) revert RevolvingCreditLineErrors.RCL_ZERO_AMOUNT_NOT_ALLOWED();
        if (!rolesManager.isBorrower(to)) revert RevolvingCreditLineErrors.RCL_ONLY_BORROWER();

        if (currentLoan.maturity == 0) {
            currentLoan.maturity = block.timestamp + LOAN_DURATION;
            currentLoan.lateRepayFeeRate = LATE_REPAYMENT_FEE_RATE;
            currentLoan.id++;
        }

        uint256 remainingAmount = amount;
        uint256 rate = MIN_RATE;
        while (remainingAmount > 0 && rate <= MAX_RATE) {
            (uint256 tickBorrowedAmount, , ) = TickLogic.borrow(
                ticks[rate],
                currentLoan,
                DataTypes.BorrowInput({totalAmountToBorrow: remainingAmount, totalAccrualsToAllocate: 0, rate: rate})
            );
            remainingAmount -= tickBorrowedAmount;

            totalToBeRepaid +=
                tickBorrowedAmount +
                TickLogic.accrualsFor(tickBorrowedAmount, currentLoan.maturity - block.timestamp, rate);

            rate += RATE_SPACING;
        }
        // @dev precision issue
        if (remainingAmount > 10) revert RevolvingCreditLineErrors.RCL_NO_LIQUIDITY();
        uint256 borrowedAmount = amount - remainingAmount;
        amendGlobalAmountsOnBorrow(borrowedAmount);

        uint256 fees = FEES_CONTROLLER.registerBorrowingFees(borrowedAmount);
        FundsTransfer.chargedWithdraw({
            token: TOKEN,
            custodian: CUSTODIAN,
            recipient: to,
            amount: borrowedAmount - fees,
            fees: fees
        });

        emit Borrow(borrowedAmount - fees, fees, to);
    }

    /**
     * @inheritdoc IRCLBorrowers
     */
    function repay() external onlyBorrower notInPhase(DataTypes.OrderBookPhase.NON_STANDARD) {
        if (currentLoan.maturity == 0) revert RevolvingCreditLineErrors.RCL_NO_LOAN_RUNNING();
        if (block.timestamp < currentLoan.maturity - REPAYMENT_PERIOD)
            revert RevolvingCreditLineErrors.RCL_REPAY_TOO_EARLY();

        uint256 fees = 0;
        uint256 currentInterestRate = MIN_RATE;
        while (currentInterestRate <= MAX_RATE) {
            DataTypes.Tick storage tick = ticks[currentInterestRate];
            if (tick.latestLoanId == currentLoan.id) {
                if (block.timestamp > currentLoan.maturity) {
                    TickLogic.registerLateRepaymentAccruals(
                        tick,
                        block.timestamp - currentLoan.maturity,
                        LATE_REPAYMENT_FEE_RATE
                    );
                }

                fees += TickLogic.registerRepaymentFees(tick, FEES_CONTROLLER);

                TickLogic.prepareTickForNextLoan(tick, currentLoan);
            }
            currentInterestRate += RATE_SPACING;
        }
        uint256 lateRepayFees = block.timestamp > currentLoan.maturity
            ? TickLogic.accrualsFor(totalBorrowed, block.timestamp - currentLoan.maturity, LATE_REPAYMENT_FEE_RATE)
            : 0;
        uint256 toBeRepaid = totalToBeRepaid + lateRepayFees;
        amendGlobalsOnRepay();

        FundsTransfer.chargedDepositToCustodian({
            token: TOKEN,
            custodian: CUSTODIAN,
            amount: toBeRepaid - fees,
            fees: fees
        });

        emit Repay(toBeRepaid - fees, fees);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Update global pool variables during a repayment
     */
    function amendGlobalsOnRepay() internal {
        uint256 lateRepayTimeDelta = block.timestamp > currentLoan.maturity
            ? block.timestamp - currentLoan.maturity
            : 0;
        loans[currentLoan.id] = currentLoan;
        loans[currentLoan.id].lateRepayTimeDelta = lateRepayTimeDelta;
        loans[currentLoan.id].repaymentFeesRate = FEES_CONTROLLER.getRepaymentFeesRate().div(WAD);
        currentLoan.maturity = 0;
        totalBorrowed = 0;
        totalBorrowedWithSecondary = 0;
        totalToBeRepaid = 0;
        totalToBeRepaidWithSecondary = 0;
    }

    /**
     * @notice Update global amount pool variables during a borrow
     * @param amount Borrowed amount
     */
    function amendGlobalAmountsOnBorrow(uint256 amount) internal {
        totalBorrowed += amount;
        totalBorrowedWithSecondary += amount;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import 'lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol';

import '../../../common/non-standard-repayment/INonStandardRepaymentModule.sol';
import '../libraries/Errors.sol';
import './interfaces/IRCLGovernance.sol';
import './RCLOrderBook.sol';

/**
 * @title RCLGovernance
 * @author Atlendis Labs
 * @notice Implementation of the IRCLGovernance
 *         Governance module of the RCL product
 */
abstract contract RCLGovernance is IRCLGovernance, RCLOrderBook {
    /*//////////////////////////////////////////////////////////////
                              LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using PoolTimelockLogic for PoolTimelock;

    /*//////////////////////////////////////////////////////////////
                               STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public constant NON_STANDARD_REPAY_MIN_TIMELOCK_DELAY = 1 days;
    uint256 public constant RESCUE_MIN_TIMELOCK_DELAY = 10 days;
    PoolTimelock private timelock;

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IRCLGovernance
     */
    function close() external onlyGovernance onlyInPhase(DataTypes.OrderBookPhase.OPEN) {
        orderBookPhase = DataTypes.OrderBookPhase.CLOSED;
    }

    /**
     * @inheritdoc IRCLGovernance
     */
    function open() external onlyGovernance onlyInPhase(DataTypes.OrderBookPhase.CLOSED) {
        orderBookPhase = DataTypes.OrderBookPhase.OPEN;
    }

    /**
     * @inheritdoc IRCLGovernance
     */
    function withdrawFees() external onlyGovernance {
        uint256 dueFees = FEES_CONTROLLER.getDueFees(address(TOKEN));

        FundsTransfer.approveFees(TOKEN, FEES_CONTROLLER, dueFees);
        FEES_CONTROLLER.pullDueFees(address(TOKEN));

        emit FeesWithdrawn(dueFees);
    }

    /**
     * @inheritdoc IRCLGovernance
     */
    function setFeesController(IFeesController feesController)
        external
        onlyGovernance
        onlyInPhase(DataTypes.OrderBookPhase.OPEN)
    {
        address managedPool = feesController.getManagedPool();
        if (managedPool != address(this)) revert RevolvingCreditLineErrors.RCL_INVALID_FEES_CONTROLLER_MANAGED_POOL();
        FEES_CONTROLLER = feesController;
        emit FeesControllerSet(address(feesController));
    }

    /**
     * @inheritdoc IRCLGovernance
     */
    function startNonStandardRepaymentProcedure(INonStandardRepaymentModule nonStandardRepaymentModule, uint256 delay)
        external
        onlyGovernance
        onlyInPhase(DataTypes.OrderBookPhase.OPEN)
    {
        if (delay < NON_STANDARD_REPAY_MIN_TIMELOCK_DELAY) revert TIMELOCK_DELAY_TOO_SMALL();
        if (
            !IERC165(address(nonStandardRepaymentModule)).supportsInterface(
                type(INonStandardRepaymentModule).interfaceId
            )
        ) revert RevolvingCreditLineErrors.RCL_WRONG_INPUT();
        if (currentLoan.maturity == 0) revert RevolvingCreditLineErrors.RCL_NO_LOAN_RUNNING();

        timelock.initiate({
            delay: delay,
            recipient: address(nonStandardRepaymentModule),
            timelockType: TimelockType.NON_STANDARD_REPAY
        });

        emit NonStandardRepaymentProcedureStarted(address(nonStandardRepaymentModule), delay);
    }

    /**
     * @inheritdoc IRCLGovernance
     */
    function startRescueProcedure(address recipient, uint256 delay) external onlyGovernance {
        if (delay < RESCUE_MIN_TIMELOCK_DELAY) revert TIMELOCK_DELAY_TOO_SMALL();

        timelock.initiate({delay: delay, recipient: recipient, timelockType: TimelockType.RESCUE});

        emit RescueProcedureStarted(recipient, delay);
    }

    /**
     * @inheritdoc ITimelock
     */
    function executeTimelock() external onlyGovernance {
        timelock.execute();

        uint256 withdrawnAmount = CUSTODIAN.withdrawAllDeposits(timelock.recipient);

        if (timelock.timelockType == TimelockType.NON_STANDARD_REPAY) {
            INonStandardRepaymentModule(timelock.recipient).initialize(withdrawnAmount);
        }

        currentLoan.nonStandardRepaymentTimestamp = block.timestamp;
        orderBookPhase = DataTypes.OrderBookPhase.NON_STANDARD;

        emit TimelockExecuted(withdrawnAmount);
    }

    /**
     * @inheritdoc ITimelock
     */
    function cancelTimelock() external onlyGovernance {
        timelock.cancel();
        emit TimelockCancelled();
    }

    /**
     * @inheritdoc IRCLGovernance
     */
    function getTimelock() external view returns (PoolTimelock memory) {
        return timelock;
    }

    /**
     * @inheritdoc IRCLGovernance
     */
    function updateMinDepositAmount(uint256 amount) external onlyGovernance {
        minDepositAmount = amount;
        emit MinDepositAmountUpdated(amount);
    }

    /**
     * @inheritdoc IRCLGovernance
     */
    function updateMaxBorrowableAmount(uint256 amount) external onlyGovernance {
        maxBorrowableAmount = amount;
        emit MaxBorrowableAmountUpdated(amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import {ERC721 as SolmateERC721} from 'lib/solmate/src/tokens/ERC721.sol';

import '../../../libraries/FixedPointMathLib.sol';
import '../libraries/DataTypes.sol';
import '../libraries/Errors.sol';
import '../libraries/TickLogic.sol';
import './interfaces/IRCLLenders.sol';
import './RCLOrderBook.sol';

/**
 * @title RCLenders
 * @author Atlendis Labs
 * @notice Implementation of the IRCLenders
 *         Lenders module of the RCL product
 *         Positions are created according to associated ERC721 token
 */
abstract contract RCLLenders is IRCLLenders, RCLOrderBook, SolmateERC721 {
    /*//////////////////////////////////////////////////////////////
                                LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant SECONDS_PER_YEAR = 365 days;

    mapping(uint256 => DataTypes.Position) public positions;
    uint256 public nextPositionId;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Constructor - Initialize parametrization
     * @param name Address of the roles manager contract
     * @param symbol Address of the custodian contract
     */
    constructor(string memory name, string memory symbol) SolmateERC721(name, symbol) {
        FixedPointMathLib.setDenominator(ONE);
    }

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Restrict the sender to borrower only
     */
    modifier onlyLender() {
        if (!rolesManager.isLender(msg.sender)) revert RevolvingCreditLineErrors.RCL_ONLY_LENDER();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Implementation of the ERC721 token URI
     * TODO: revisit in #115
     */
    function tokenURI(uint256) public pure override returns (string memory) {
        return '';
    }

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IRCLLenders
     */
    function deposit(
        uint256 rate,
        uint256 amount,
        address to
    ) external onlyLender onlyInPhase(DataTypes.OrderBookPhase.OPEN) returns (uint256 positionId) {
        if (amount < minDepositAmount) revert RevolvingCreditLineErrors.RCL_DEPOSIT_AMOUNT_TOO_LOW();
        if (!rolesManager.isLender(to)) revert RevolvingCreditLineErrors.RCL_ONLY_LENDER();
        validateDepositRate(rate);

        TickLogic.deposit(ticks[rate], currentLoan, amount);

        positionId = nextPositionId++;
        positions[positionId] = DataTypes.Position({
            baseDeposit: amount,
            rate: rate,
            epochId: ticks[rate].currentEpochId,
            creationTimestamp: block.timestamp,
            optOutLoanId: 0,
            withdrawLoanId: 0,
            withdrawn: DataTypes.WithdrawalAmounts({borrowed: 0, expectedAccruals: 0})
        });

        _safeMint(to, positionId);
        CUSTODIAN.deposit(amount, msg.sender);

        emit Deposit(positionId, to, amount, rate, ticks[rate].currentEpochId);
    }

    /**
     * @inheritdoc IRCLLenders
     */
    function updateRate(uint256 positionId, uint256 newRate)
        external
        onlyLender
        onlyInPhase(DataTypes.OrderBookPhase.OPEN)
    {
        if (ownerOf(positionId) != msg.sender) revert RevolvingCreditLineErrors.RCL_ONLY_OWNER();
        validateDepositRate(newRate);

        DataTypes.Position storage position = positions[positionId];
        DataTypes.Tick storage tick = ticks[position.rate];
        DataTypes.Loan storage referenceLoan = getPositionLoan(position, tick);

        TickLogic.validateWithdraw({
            position: position,
            tick: tick,
            referenceLoan: referenceLoan,
            currentLoan: currentLoan,
            amountToWithdraw: type(uint256).max,
            minDepositAmount: minDepositAmount
        });

        TickLogic.updateRate({
            position: position,
            tick: tick,
            newTick: ticks[newRate],
            referenceLoan: referenceLoan,
            currentLoan: currentLoan,
            newRate: newRate
        });

        emit UpdateRate(positionId, newRate);
    }

    /**
     * @inheritdoc IRCLLenders
     */
    function withdraw(uint256 positionId, uint256 amountToWithdraw)
        public
        onlyLender
        notInPhase(DataTypes.OrderBookPhase.NON_STANDARD)
    {
        if (ownerOf(positionId) != msg.sender) revert RevolvingCreditLineErrors.RCL_ONLY_OWNER();

        DataTypes.Position storage position = positions[positionId];
        DataTypes.Tick storage tick = ticks[position.rate];
        DataTypes.Loan storage referenceLoan = getPositionLoan(position, tick);

        TickLogic.validateWithdraw({
            position: position,
            tick: tick,
            referenceLoan: referenceLoan,
            currentLoan: currentLoan,
            amountToWithdraw: amountToWithdraw,
            minDepositAmount: minDepositAmount
        });

        uint256 withdrawableAmount = TickLogic.withdraw(tick, position, amountToWithdraw, referenceLoan, currentLoan);

        if (amountToWithdraw == type(uint256).max || position.optOutLoanId > 0) {
            burn(positionId);
        }

        uint256 fees = FEES_CONTROLLER.registerManagementFees(withdrawableAmount);
        FundsTransfer.chargedWithdraw({
            token: TOKEN,
            custodian: CUSTODIAN,
            recipient: msg.sender,
            amount: withdrawableAmount - fees,
            fees: fees
        });

        emit Withdraw(positionId, amountToWithdraw, withdrawableAmount - fees, fees);
    }

    /**
     * @inheritdoc IRCLLenders
     */
    function detach(uint256 positionId) public onlyLender notInPhase(DataTypes.OrderBookPhase.NON_STANDARD) {
        DataTypes.Position storage position = positions[positionId];
        DataTypes.Tick storage tick = ticks[position.rate];
        DataTypes.Loan storage loan = getPositionLoan(position, tick);

        if (ownerOf(positionId) != msg.sender) revert RevolvingCreditLineErrors.RCL_ONLY_OWNER();
        if (currentLoan.maturity == 0) revert RevolvingCreditLineErrors.RCL_NO_LOAN_RUNNING();

        uint256 unborrowedAmount = TickLogic.detach(tick, position, loan, currentLoan, minDepositAmount);

        uint256 fees = FEES_CONTROLLER.registerManagementFees(unborrowedAmount);
        uint256 withdrawnAmount = unborrowedAmount - fees;
        FundsTransfer.chargedWithdraw({
            token: TOKEN,
            custodian: CUSTODIAN,
            recipient: msg.sender,
            amount: withdrawnAmount,
            fees: fees
        });

        emit Detach(positionId, withdrawnAmount, fees);
    }

    /**
     * @inheritdoc IRCLLenders
     */
    function optOut(uint256 positionId) external onlyLender onlyInPhase(DataTypes.OrderBookPhase.OPEN) {
        if (ownerOf(positionId) != msg.sender) revert RevolvingCreditLineErrors.RCL_ONLY_OWNER();

        DataTypes.Position storage position = positions[positionId];
        DataTypes.Tick storage tick = ticks[position.rate];
        DataTypes.Loan storage referenceLoan = getPositionLoan(position, tick);

        TickLogic.validateOptOut({
            position: position,
            tick: tick,
            referenceLoan: referenceLoan,
            currentLoan: currentLoan
        });

        TickLogic.optOut({tick: tick, position: position, referenceLoan: referenceLoan, currentLoan: currentLoan});

        emit OptOut(positionId, currentLoan.id);
    }

    /**
     * @inheritdoc IRCLLenders
     */
    function exit(uint256 positionId, uint256 borrowedAmountToExit)
        public
        onlyLender
        notInPhase(DataTypes.OrderBookPhase.NON_STANDARD)
    {
        if (ownerOf(positionId) != msg.sender) revert RevolvingCreditLineErrors.RCL_ONLY_OWNER();

        DataTypes.Position storage position = positions[positionId];
        DataTypes.Tick storage tick = ticks[position.rate];
        DataTypes.Loan storage referenceLoan = getPositionLoan(position, tick);

        TickLogic.validateExit({
            position: position,
            tick: tick,
            referenceLoan: referenceLoan,
            currentLoan: currentLoan,
            borrowedAmountToExit: borrowedAmountToExit,
            minDepositAmount: minDepositAmount
        });

        // compute position values to exit over other ticks
        /// @dev totalAmountReborrowed = realizedAccruals, to save a variable and prevent a stack too deep
        (
            uint256 endOfLoanBorrowEquivalent,
            uint256 totalAmountReborrowed,
            uint256 actualBorrowedAmountToExit,
            uint256 unborrowedAmount
        ) = TickLogic.registerExit(tick, position, borrowedAmountToExit, referenceLoan, currentLoan);

        // swap the debt to exit with other ticks' available liquidity
        uint256 totalAccrualsInterests = 0;
        uint256 remainingAccrualsToAllocate = totalAmountReborrowed;
        uint256 rate = MIN_RATE;
        /// @dev in theory endOfLoanBorrowEquivalent should be exactly zero after succesful borrow, however due to rounding and different order of operations some dust may remain
        /// @dev not checking on remainingRealizedAccrualsToExit to be distributed fully because they can be zero due to low precision tokens
        while (endOfLoanBorrowEquivalent > 10 && rate <= MAX_RATE) {
            if (ticks[rate].baseEpochsAmounts.available > 0 || ticks[rate].newEpochsAmounts.available > 0) {
                (
                    uint256 tickBorrowed,
                    uint256 tickAllocatedAccruals,
                    uint256 tickAllocatedAccrualsInterests,
                    uint256 tickBorrowedEndOfLoanBorrowEquivalent
                ) = TickLogic.exit(
                        ticks[rate],
                        currentLoan,
                        endOfLoanBorrowEquivalent,
                        remainingAccrualsToAllocate,
                        rate,
                        ONE
                    );

                // register accumulated amounts
                totalAmountReborrowed += tickBorrowed;
                totalAccrualsInterests += tickAllocatedAccrualsInterests;

                // register data for next iteration
                endOfLoanBorrowEquivalent -= tickBorrowedEndOfLoanBorrowEquivalent;
                remainingAccrualsToAllocate -= tickAllocatedAccruals;
            }
            rate += RATE_SPACING;
        }

        // @dev precision issue
        if (endOfLoanBorrowEquivalent > 10) revert RevolvingCreditLineErrors.RCL_NO_LIQUIDITY();

        amendGlobalsOnExit(actualBorrowedAmountToExit, totalAmountReborrowed, totalAccrualsInterests);

        uint256 toBeWithdrawn = totalAmountReborrowed + unborrowedAmount - totalAccrualsInterests;

        uint256 fees = FEES_CONTROLLER.registerExitFees(toBeWithdrawn, currentLoan.maturity - block.timestamp);
        FundsTransfer.chargedWithdraw({
            token: TOKEN,
            custodian: CUSTODIAN,
            recipient: msg.sender,
            amount: toBeWithdrawn - fees,
            fees: fees
        });

        emit Exit(positionId, borrowedAmountToExit, toBeWithdrawn - fees, fees);

        if (borrowedAmountToExit == type(uint256).max) {
            burn(positionId);
        }
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Update global pool variables during an exit
     */
    function amendGlobalsOnExit(
        uint256 actualBorrowedAmountToExit,
        uint256 totalAmountReborrowed,
        uint256 totalAccrualsInterests
    ) internal {
        totalBorrowedWithSecondary = totalBorrowedWithSecondary + totalAmountReborrowed - actualBorrowedAmountToExit;
        totalToBeRepaidWithSecondary += totalAccrualsInterests;
    }

    /**
     * @notice Validation of the input deposit rate
     * @dev Used for both deposit and update rate actions
     * @param rate Rate to be validated
     */
    function validateDepositRate(uint256 rate) internal view {
        if (rate < MIN_RATE) revert RevolvingCreditLineErrors.RCL_OUT_OF_BOUND_MIN_RATE();
        if (rate > MAX_RATE) revert RevolvingCreditLineErrors.RCL_OUT_OF_BOUND_MAX_RATE();
        if ((rate - MIN_RATE) % RATE_SPACING != 0) revert RevolvingCreditLineErrors.RCL_INVALID_RATE_SPACING();
    }

    /**
     * @notice Returns the reference loan of a position
     * If the position has been detached, the reference loan is the detach loan
     * Otherwise it's the first loan when the position was borrowed
     * @param position Target position
     * @param tick Target tick
     * @return loan Position reference loan
     */
    function getPositionLoan(DataTypes.Position storage position, DataTypes.Tick storage tick)
        internal
        view
        returns (DataTypes.Loan storage loan)
    {
        uint256 loanId = position.withdrawLoanId > 0 ? position.withdrawLoanId : tick.epochs[position.epochId].loanId;
        loan = loans[loanId];
    }

    /**
     * @notice Burns the position and deletes its corresponding data
     * @param positionId ID of the position to burn
     */
    function burn(uint256 positionId) internal {
        _burn(positionId);
        delete positions[positionId];
    }

    /*//////////////////////////////////////////////////////////////
                          TRANSFER OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See {IERC721-transferFrom}.
     * Bear in mind that `safeTransferFrom` methods are internally using `transferFrom`, hence restrictions are also applied on these methods
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        if (!rolesManager.isOperator(msg.sender)) revert RevolvingCreditLineErrors.RCL_ONLY_OPERATOR();
        super.transferFrom(from, to, tokenId);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../../../common/custodian/IPoolCustodian.sol';
import '../../../common/fees/IFeesController.sol';
import '../../../common/non-standard-repayment/INonStandardRepaymentModule.sol';
import '../../../common/roles-manager/Managed.sol';
import '../../../libraries/FundsTransfer.sol';
import './../libraries/DataTypes.sol';
import './../libraries/Errors.sol';
import './interfaces/IRCLOrderBook.sol';

/**
 * @title RCLOrderBook
 * @author Atlendis Labs
 * @notice Implementation of the IOrderBook
 *         Contains the core storage of the pool and shared methods accross the modules
 */
abstract contract RCLOrderBook is IRCLOrderBook, Managed {
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    // pool configuration
    uint256 public immutable LOAN_DURATION;
    uint256 public immutable MIN_RATE;
    uint256 public immutable MAX_RATE;
    uint256 public immutable RATE_SPACING;
    uint256 public immutable REPAYMENT_PERIOD;
    uint256 public immutable LATE_REPAYMENT_FEE_RATE;
    uint256 public maxBorrowableAmount;
    uint256 public minDepositAmount;

    // constants
    uint256 public immutable ONE;
    uint256 constant WAD = 1e18;
    uint256 constant RAY = 1e27;

    // pool extensions
    IFeesController public FEES_CONTROLLER;
    IPoolCustodian public immutable CUSTODIAN;
    address public immutable TOKEN;

    // pool status
    uint256 public totalBorrowed;
    uint256 public totalBorrowedWithSecondary;
    uint256 public totalToBeRepaid;
    uint256 public totalToBeRepaidWithSecondary;
    DataTypes.Loan public currentLoan;
    DataTypes.OrderBookPhase public orderBookPhase;

    // accounting
    mapping(uint256 => DataTypes.Tick) public ticks;
    mapping(uint256 => DataTypes.Loan) public loans;

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Constructor - Initialize parametrization
     * @param rolesManager Address of the roles manager contract
     * @param custodian Address of the custodian contract
     * @param feesController Address of the fees controller contract
     * @param parametersConfig Other Configurations
     */
    constructor(
        address rolesManager,
        IPoolCustodian custodian,
        IFeesController feesController,
        bytes memory parametersConfig
    ) Managed(rolesManager) {
        orderBookPhase = DataTypes.OrderBookPhase.OPEN;

        (
            maxBorrowableAmount,
            MIN_RATE,
            MAX_RATE,
            RATE_SPACING,
            REPAYMENT_PERIOD,
            LOAN_DURATION,
            LATE_REPAYMENT_FEE_RATE,
            minDepositAmount
        ) = abi.decode(parametersConfig, (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256));

        (address token, uint256 decimals) = custodian.getTokenConfiguration();
        TOKEN = token;
        ONE = 10**decimals;
        CUSTODIAN = custodian;
        FEES_CONTROLLER = feesController;

        // @dev unchecked is used as rate variable in loop is safe to not overflow
        unchecked {
            for (uint256 rate = MIN_RATE; rate <= MAX_RATE; rate += RATE_SPACING) {
                ticks[rate].yieldFactor = ONE;
                /// @dev the first loan gets an ID of one.
                /// Hence the endOfPriorLoanYieldFactor for genesis deposits is never set but is theoertically ONE
                ticks[rate].endOfLoanYieldFactors[0] = ONE;
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                                VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IRCLOrderBook
     */
    function getMaturity() public view returns (uint256 maturity) {
        return currentLoan.maturity;
    }

    /**
     * @inheritdoc IRCLOrderBook
     */
    function getEpoch(uint256 rate, uint256 epochId)
        public
        view
        returns (
            uint256 deposited,
            uint256 borrowed,
            uint256 accruals,
            uint256 loanId,
            bool isBaseEpoch
        )
    {
        DataTypes.Tick storage tick = ticks[rate];
        borrowed = tick.epochs[epochId].borrowed;
        accruals = tick.epochs[epochId].accruals;
        deposited = tick.epochs[epochId].deposited;
        loanId = tick.epochs[epochId].loanId;
        isBaseEpoch = tick.epochs[epochId].isBaseEpoch;
    }

    /**
     * @inheritdoc IRCLOrderBook
     */
    function getTickBaseEpochsAmounts(uint256 rate)
        public
        view
        returns (
            uint256 adjustedDeposits,
            uint256 borrowed,
            uint256 available,
            uint256 adjustedOptedOut
        )
    {
        DataTypes.Tick storage tick = ticks[rate];
        return (
            tick.baseEpochsAmounts.adjustedDeposits,
            tick.baseEpochsAmounts.borrowed,
            tick.baseEpochsAmounts.available,
            tick.baseEpochsAmounts.adjustedOptedOut
        );
    }

    /**
     * @inheritdoc IRCLOrderBook
     */
    function getTickNewEpochsAmounts(uint256 rate)
        public
        view
        returns (
            uint256 toBeAdjusted,
            uint256 borrowed,
            uint256 available,
            uint256 optedOut
        )
    {
        DataTypes.Tick storage tick = ticks[rate];
        return (
            tick.newEpochsAmounts.toBeAdjusted,
            tick.newEpochsAmounts.borrowed,
            tick.newEpochsAmounts.available,
            tick.newEpochsAmounts.optedOut
        );
    }

    function getTickWithdrawnAmounts(uint256 rate) public view returns (uint256, uint256) {
        DataTypes.Tick storage tick = ticks[rate];

        return (tick.withdrawnAmounts.toBeAdjusted, tick.withdrawnAmounts.borrowed);
    }

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Allow only if the pool phase is the expected one
     * @param expectedPhase Expected phase
     */
    modifier onlyInPhase(DataTypes.OrderBookPhase expectedPhase) {
        if (orderBookPhase != expectedPhase) revert RevolvingCreditLineErrors.RCL_INVALID_PHASE();
        _;
    }

    /**
     * @dev Allow only if the pool phase is not the target one
     * @param excludedPhase Excluded phase
     */
    modifier notInPhase(DataTypes.OrderBookPhase excludedPhase) {
        if (orderBookPhase == excludedPhase) revert RevolvingCreditLineErrors.RCL_INVALID_PHASE();
        _;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../../common/fees/PoolTokenFeesController.sol';
import '../../common/custodian/PoolCustodian.sol';
import '../../common/roles-manager/StandardRolesManager.sol';
import '../../interfaces/IProductFactory.sol';
import './libraries/RevolvingCreditLineDeployer.sol';

/**
 * @title RCLFactory
 * @author Atlendis Labs
 * @notice Implementation of the IProductFactory for the Revolving Credit Line product
 */
contract RCLFactory is IProductFactory {
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    address public immutable FACTORY_REGISTRY;
    bytes32 public constant PRODUCT_ID = keccak256('RCL');

    // Temporary storage for deployment inputs in order to not copy in memory for external lib call
    bytes parametersConfigTmp;
    string nameTmp;
    string symbolTmp;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address factoryRegistry) {
        FACTORY_REGISTRY = factoryRegistry;
    }

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IProductFactory
     */
    function deploy(
        address governance,
        bytes memory custodianConfig,
        bytes memory feesControllerConfig,
        bytes memory parametersConfig,
        bytes memory,
        string memory name,
        string memory symbol
    ) external returns (address instance) {
        if (msg.sender != FACTORY_REGISTRY) revert UNAUTHORIZED();

        StandardRolesManager rolesManager = new StandardRolesManager(address(this));

        PoolCustodian custodian = deployCustodian(rolesManager, custodianConfig);
        PoolTokenFeesController feesController = deployFeesController(rolesManager, feesControllerConfig);

        parametersConfigTmp = parametersConfig;
        nameTmp = name;
        symbolTmp = symbol;

        instance = deployRevolvingCreditLine(rolesManager, custodian, feesController);

        delete parametersConfigTmp;
        delete nameTmp;
        delete symbolTmp;

        feesController.initializePool(instance);
        custodian.initializePool(instance);

        rolesManager.grantRole(rolesManager.OPERATOR_ROLE(), instance);
        rolesManager.grantRole(rolesManager.DEFAULT_ADMIN_ROLE(), governance);
        rolesManager.renounceRole(rolesManager.DEFAULT_ADMIN_ROLE(), address(this));
    }

    /*//////////////////////////////////////////////////////////////
                           PRIVATE METHODS
    //////////////////////////////////////////////////////////////*/

    function deployCustodian(StandardRolesManager rolesManager, bytes memory custodianConfig)
        private
        returns (PoolCustodian)
    {
        if (custodianConfig.length != 96) revert INVALID_PRODUCT_PARAMS();
        (address token, address adapter, address yieldProvider) = abi.decode(
            custodianConfig,
            (address, address, address)
        );
        return new PoolCustodian(rolesManager, ERC20(token), adapter, yieldProvider);
    }

    function deployFeesController(StandardRolesManager rolesManager, bytes memory feesControllerConfig)
        private
        returns (PoolTokenFeesController)
    {
        if (feesControllerConfig.length != 224) revert INVALID_PRODUCT_PARAMS();
        (
            uint256 managementFeesRate,
            uint256 exitFeesInflectionThreshold,
            uint256 exitFeesMinRate,
            uint256 exitFeesInflectionRate,
            uint256 exitFeesMaxRate,
            uint256 borrowingFeesRate,
            uint256 repaymentFeesRate
        ) = abi.decode(feesControllerConfig, (uint256, uint256, uint256, uint256, uint256, uint256, uint256));
        return
            new PoolTokenFeesController(
                rolesManager,
                managementFeesRate,
                exitFeesInflectionThreshold,
                exitFeesMinRate,
                exitFeesInflectionRate,
                exitFeesMaxRate,
                borrowingFeesRate,
                repaymentFeesRate
            );
    }

    function deployRevolvingCreditLine(
        StandardRolesManager rolesManager,
        PoolCustodian custodian,
        PoolTokenFeesController feesController
    ) private returns (address) {
        if (parametersConfigTmp.length != 256) revert INVALID_PRODUCT_PARAMS();

        (, uint256 minRate, uint256 maxRate, uint256 rateSpacing, , , ) = abi.decode(
            parametersConfigTmp,
            (uint256, uint256, uint256, uint256, uint256, uint256, uint256)
        );

        if (minRate >= maxRate) revert INVALID_RATE_BOUNDARIES();
        if (rateSpacing == 0) revert INVALID_ZERO_RATE_SPACING();
        if ((maxRate - minRate) % rateSpacing != 0) revert INVALID_RATE_PARAMETERS();

        return
            RevolvingCreditLineDeployer.deploy(
                address(rolesManager),
                custodian,
                feesController,
                parametersConfigTmp,
                nameTmp,
                symbolTmp
            );
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../../common/rewards/RewardsManager.sol';
import './interfaces/IRCLRewardsManager.sol';
import './interfaces/IRevolvingCreditLine.sol';

/**
 * @title RCLRewardsManager
 * @author Atlendis Labs
 * @notice Implementation of the IRCLRewardsManager
 */
contract RCLRewardsManager is RewardsManager, IRCLRewardsManager {
    /**
     * @dev Constructor
     * @param positionManager Address of the position manager contract
     * @param _minPositionValue Minimum position required value
     * @param _minLockingDuration Minimum locking duration allowed for term rewards
     * @param _maxLockingDuration Maximum locking duration allowed for term rewards
     * @param _deltaExitLockingDuration Allowed delta duration for locking for term rewards in case of opted out position
     * @param name ERC721 name of the staked position NFT
     * @param symbol ERC721 symbol of the staked position NFT
     */
    constructor(
        address positionManager,
        uint256 _minPositionValue,
        uint256 _minLockingDuration,
        uint256 _maxLockingDuration,
        uint256 _deltaExitLockingDuration,
        string memory name,
        string memory symbol
    )
        RewardsManager(
            positionManager,
            _minPositionValue,
            _minLockingDuration,
            _maxLockingDuration,
            _deltaExitLockingDuration,
            name,
            symbol
        )
    {}

    /**
     * @inheritdoc IRCLRewardsManager
     */
    function stake(uint256 positionId, uint256 lockingDuration) public onlyEnabled onlyLender {
        _stake(positionId, lockingDuration);
    }

    /**
     * @inheritdoc IRCLRewardsManager
     */
    function batchStake(uint256[] calldata positionIds, uint256 lockingDuration) public onlyEnabled onlyLender {
        for (uint256 i = 0; i < positionIds.length; i++) {
            _stake(positionIds[i], lockingDuration);
        }
    }

    /**
     * @inheritdoc IRCLRewardsManager
     */
    function optOut(uint256 positionId) public onlyLender {
        address owner = ownerOf(positionId);
        if (msg.sender != owner) revert UNAUTHORIZED(msg.sender, owner);

        (, , , PositionStatus status) = POSITION_MANAGER.getPosition(positionId);
        if (status != PositionStatus.BORROWED) revert POSITION_NOT_BORROWED(status);

        uint256 maturity = POSITION_MANAGER.getMaturity();

        uint256 maximumRequiredTerm = maturity + deltaExitLockingDuration;
        for (uint256 i = 0; i < termRewardsModules.length; i++) {
            uint256 term = ITermRewardsModule(termRewardsModules[i]).getTerm(positionId);
            if (term > maximumRequiredTerm) revert TOO_LONG_TERM_PENDING(term, maximumRequiredTerm);
        }

        for (uint256 i = 0; i < continuousRewardsModules.length; i++) {
            IContinuousRewardsModule(continuousRewardsModules[i]).unstake(positionId, owner);
        }

        IRevolvingCreditLine revolvingCreditLine = IRevolvingCreditLine(address(POSITION_MANAGER));
        revolvingCreditLine.optOut(positionId);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import './interfaces/IRevolvingCreditLine.sol';
import './libraries/DataTypes.sol';
import './modules/RCLBorrowers.sol';
import './modules/RCLGovernance.sol';
import './modules/RCLLenders.sol';
import './modules/RCLOrderBook.sol';

/**
 * @title RevolvingCreditLine
 * @author Atlendis Labs
 * @notice Implementation of the IRevolvingCreditLines
 */
contract RevolvingCreditLine is IRevolvingCreditLine, RCLOrderBook, RCLGovernance, RCLBorrowers, RCLLenders {
    /*//////////////////////////////////////////////////////////////
                                LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Constructor - pass parameters to modules
     * @param rolesManager Address of the roles manager
     * @param custodian Address of the custodian
     * @param feesController Address of the fees controller
     * @param parametersConfig Order book parameters
     * @param name ERC721 name of the positions
     * @param symbol ERC721 symbol of the positions
     */
    constructor(
        address rolesManager,
        IPoolCustodian custodian,
        IFeesController feesController,
        bytes memory parametersConfig,
        string memory name,
        string memory symbol
    ) RCLLenders(name, symbol) RCLOrderBook(rolesManager, custodian, feesController, parametersConfig) {}

    /**
     * @inheritdoc IRevolvingCreditLine
     */
    function getPosition(uint256 positionId)
        public
        view
        returns (
            address owner,
            uint256 rate,
            uint256 depositedAmount,
            PositionStatus status
        )
    {
        owner = ownerOf(positionId);
        DataTypes.Position storage position = positions[positionId];

        if (position.optOutLoanId > 0) return (owner, position.rate, position.baseDeposit, PositionStatus.UNAVAILABLE);

        (, uint256 borrowedAmount) = getPositionRepartition(positionId);

        if (borrowedAmount == 0) {
            return (owner, position.rate, position.baseDeposit, PositionStatus.AVAILABLE);
        }

        return (owner, position.rate, position.baseDeposit, PositionStatus.BORROWED);
    }

    /**
     * @inheritdoc IRevolvingCreditLine
     */
    function getPositionRepartition(uint256 positionId)
        public
        view
        returns (uint256 unborrowedAmount, uint256 borrowedAmount)
    {
        DataTypes.Position storage position = positions[positionId];
        DataTypes.Tick storage tick = ticks[position.rate];
        DataTypes.Loan storage loan = getPositionLoan(position, tick);
        return TickLogic.getPositionRepartition(tick, position, loan, currentLoan);
    }

    /**
     * @inheritdoc IRevolvingCreditLine
     */
    function getPositionCurrentValue(uint256 positionId) public view returns (uint256 positionCurrentValue) {
        DataTypes.Position storage position = positions[positionId];
        DataTypes.Tick storage tick = ticks[position.rate];
        DataTypes.Loan storage loan = getPositionLoan(position, tick);

        positionCurrentValue = TickLogic.getPositionCurrentValue(tick, position, loan, currentLoan);
    }

    /**
     * @inheritdoc IRevolvingCreditLine
     */
    function getPositionLoanShare(uint256 positionId) external view returns (uint256 positionShare) {
        DataTypes.Position storage position = positions[positionId];
        DataTypes.Tick storage tick = ticks[position.rate];
        DataTypes.Loan storage loan = getPositionLoan(position, tick);

        positionShare = TickLogic.getPositionLoanShare(tick, position, loan, currentLoan, totalBorrowedWithSecondary);
    }

    /**
     * @inheritdoc IRevolvingCreditLine
     */
    function getCurrentAccruals() external view returns (uint256 currentAccruals) {
        if (currentLoan.maturity < block.timestamp) {
            revert RevolvingCreditLineErrors.RCL_MATURITY_PASSED();
        }
        uint256 timeUntilMaturity = currentLoan.maturity - block.timestamp;
        currentAccruals = ((totalToBeRepaid - totalBorrowed) * (LOAN_DURATION - timeUntilMaturity)) / LOAN_DURATION;
    }
}