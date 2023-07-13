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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271Upgradeable {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
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
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC5267.sol)

pragma solidity ^0.8.0;

interface IERC5267Upgradeable {
    /**
     * @dev MAY be emitted to signal that the domain could have changed.
     */
    event EIP712DomainChanged();

    /**
     * @dev returns the fields and values that describe the domain separator used by this contract for EIP-712
     * signature.
     */
    function eip712Domain()
        external
        view
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        );
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";
import "./math/SignedMathUpgradeable.sol";

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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.8;

import "./ECDSAUpgradeable.sol";
import "../../interfaces/IERC5267Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * NOTE: In the upgradeable version of this contract, the cached values will correspond to the address, and the domain
 * separator of the implementation contract. This will cause the `_domainSeparatorV4` function to always rebuild the
 * separator from the immutable values, which is cheaper than accessing a cached version in cold storage.
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 52
 */
abstract contract EIP712Upgradeable is Initializable, IERC5267Upgradeable {
    bytes32 private constant _TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /// @custom:oz-renamed-from _HASHED_NAME
    bytes32 private _hashedName;
    /// @custom:oz-renamed-from _HASHED_VERSION
    bytes32 private _hashedVersion;

    string private _name;
    string private _version;

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        _name = name;
        _version = version;

        // Reset prior values in storage if upgrading
        _hashedName = 0;
        _hashedVersion = 0;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator();
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return keccak256(abi.encode(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash(), block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev See {EIP-5267}.
     *
     * _Available since v4.9._
     */
    function eip712Domain()
        public
        view
        virtual
        override
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        )
    {
        // If the hashed name and version in storage are non-zero, the contract hasn't been properly initialized
        // and the EIP712 domain is not reliable, as it will be missing name and version.
        require(_hashedName == 0 && _hashedVersion == 0, "EIP712: Uninitialized");

        return (
            hex"0f", // 01111
            _EIP712Name(),
            _EIP712Version(),
            block.chainid,
            address(this),
            bytes32(0),
            new uint256[](0)
        );
    }

    /**
     * @dev The name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712Name() internal virtual view returns (string memory) {
        return _name;
    }

    /**
     * @dev The version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712Version() internal virtual view returns (string memory) {
        return _version;
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: In previous versions this function was virtual. In this version you should override `_EIP712Name` instead.
     */
    function _EIP712NameHash() internal view returns (bytes32) {
        string memory name = _EIP712Name();
        if (bytes(name).length > 0) {
            return keccak256(bytes(name));
        } else {
            // If the name is empty, the contract may have been upgraded without initializing the new storage.
            // We return the name hash in storage if non-zero, otherwise we assume the name is empty by design.
            bytes32 hashedName = _hashedName;
            if (hashedName != 0) {
                return hashedName;
            } else {
                return keccak256("");
            }
        }
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: In previous versions this function was virtual. In this version you should override `_EIP712Version` instead.
     */
    function _EIP712VersionHash() internal view returns (bytes32) {
        string memory version = _EIP712Version();
        if (bytes(version).length > 0) {
            return keccak256(bytes(version));
        } else {
            // If the version is empty, the contract may have been upgraded without initializing the new storage.
            // We return the version hash in storage if non-zero, otherwise we assume the version is empty by design.
            bytes32 hashedVersion = _hashedVersion;
            if (hashedVersion != 0) {
                return hashedVersion;
            } else {
                return keccak256("");
            }
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../interfaces/IERC1271Upgradeable.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureCheckerUpgradeable {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(address signer, bytes32 hash, bytes memory signature) internal view returns (bool) {
        (address recovered, ECDSAUpgradeable.RecoverError error) = ECDSAUpgradeable.tryRecover(hash, signature);
        return
            (error == ECDSAUpgradeable.RecoverError.NoError && recovered == signer) ||
            isValidERC1271SignatureNow(signer, hash, signature);
    }

    /**
     * @dev Checks if a signature is valid for a given signer and data hash. The signature is validated
     * against the signer smart contract using ERC1271.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidERC1271SignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271Upgradeable.isValidSignature.selector, hash, signature)
        );
        return (success &&
            result.length >= 32 &&
            abi.decode(result, (bytes32)) == bytes32(IERC1271Upgradeable.isValidSignature.selector));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
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
pragma solidity ^0.8.19;

import {IValidator} from "./interfaces/IValidator.sol";
import {IERC2771Recipient} from "./interfaces/IERC2771Recipient.sol";
import "openzeppelin-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
import "openzeppelin-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import "openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import "openzeppelin-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import {DelegateCashCheckerLib} from "./utils/DelegateCashCheckerLib.sol";

error AgreementAlreadyExists();
error AgreementExpirationMustBeInTheFuture();
error AgreementDoesNotExist();
error NonceUsed();
error InvalidOffererSignature();
error InvalidNotarySignature();
error InvalidPromisorSignature();
error InvalidUserSignature();
error CannotSetToAddressZero();
error FieldNotUpdateable();
error CallerNotSigner();
error TermAlreadyIncluded();
error TermDoesNotExist();
error TermAlreadyExists();
error OffchainHashInvalid();
error NotCorrectPromisor();
error InvalidIndex();
error InvalidTermIndex();
error InvalidMatchingIndex();
error NotGaslessTransaction();
error CannotSetSelfToDelegate();

error NewPromisorCannotBeOldPromisor();
error NewOffererCannotBeOldOfferer();
error PromisorCannotBeOfferer();
error OffererCannotBePromisor();

error NewPromisorMustApproveContractHandoff();
error NewOfferorMustApproveContractHandoff();

/// @title Registry Smart Contract
/// @notice This contract is used for managing onchain agreements
/// @dev This contract uses OpenZeppelin's upgradeable contracts along with OpenGSN's IERC2771Recipient
/// @author Saasy Labs
contract Registry is Initializable, OwnableUpgradeable, UUPSUpgradeable, EIP712Upgradeable, IERC2771Recipient {
    using ECDSAUpgradeable for bytes32;

    /* -------------------------------------------------------------------------- */
    /*                                   events                                   */
    /* -------------------------------------------------------------------------- */
    /// @notice Emitted when a nonce has been burned
    /// @param nonce The nonce that has been burned
    /// @param user The address of the user related to this operation
    event NonceBurned(uint256 nonce, address user);

    /// @notice Emitted when the offerer of an agreement is updated
    /// @param agreementHash The hash of the agreement which was updated
    /// @param oldOfferer The address of the old offerer
    /// @param newOfferer The address of the new offerer
    /// @param reasonCID The CID of the reason for the update
    event OffererUpdated(
        bytes32 indexed agreementHash, address indexed oldOfferer, address indexed newOfferer, string reasonCID
    );

    /// @notice Emitted when a delegated signer is added or removed
    /// @param from The address of the user who added or removed the delegated signer
    /// @param to The address of the delegated signer
    /// @param status The status of the delegated signer
    event DelegatedSignerSet(address indexed from, address indexed to, bool indexed status);

    /// @notice Emitted when the promisor of an agreement is updated
    /// @param agreementHash The hash of the agreement which was updated
    /// @param oldPromisor The address of the old offerer
    /// @param newPromisor The address of the new offerer
    /// @param reasonCID The CID of the reason for the update
    event PromisorUpdated(
        bytes32 indexed agreementHash, address indexed oldPromisor, address indexed newPromisor, string reasonCID
    );

    /// @notice Emitted when an agreement is removed
    /// @param removed The agreement that was removed
    event AgreementRemoved(Agreement removed);

    /// @notice Emitted when a new agreement is created
    /// @param agreementHash The hash of the agreement which was created
    event AgreementCreated(bytes32 agreementHash);

    event AgreementAmendment(bytes32 indexed agreementHash, uint32[] termsToAdd, uint32[] termsToRemove);

    /* -------------------------------------------------------------------------- */
    /*                                    types                                   */
    /* -------------------------------------------------------------------------- */
    /// @notice Agreement struct to define a standard agreement in the contract
    /// @param id The ID of the partner
    /// @param offerer The address of the offerer
    /// @param promisor The address of the promisor
    /// @param flags - a bitmap of flags
    /// @param terms An array containing the addresses representing the terms of the agreement
    /// @param assetAddress The address of the asset linked with this agreement
    /// @param tokenId The ID of the token associated with the agreement
    /// @param validatorModule The address of the validator module for the agreement
    /// @param expiration The timestamp of the expiration time of the agreement
    /// @param paymentAmount The amount that needs to be paid according to the agreement
    /// @param dynamicData A string containing CID
    struct Agreement {
        // string contractName;
        // TODO: Should this point to an existing array of terms
        uint128 id; //template id for enterprise partners
        address offerer;
        uint128 flags;
        address promisor;
        uint32[] terms;
        address assetAddress;
        uint256 tokenId;
        uint128 expiration;
        address validatorModule;
        uint256 paymentAmount;
        string dynamicData;
        uint256 chainId;
    }

    struct AgreementTerms {
        string name;
        string description;
    }

    /* -------------------------------------------------------------------------- */
    /*                                  constants                                 */
    /* -------------------------------------------------------------------------- */
    uint256 private constant PROMISOR_SIGNATURE_REQUIRED_TO_VOID_AGREEMENT_MASK = 0x1;
    uint256 private constant OFFEROR_SIGNATURE_REQUIRED_TO_VOID_AGREEMENT_MASK = 0x2;
    uint256 private constant OFFEROR_SIGNATURE_REQUIRED_TO_UPDATE_OFFEROR_MASK = 0x4;
    uint256 private constant PROMISOR_SIGNATURE_REQUIRED_TO_UPDATE_OFFEROR_MASK = 0x8;
    uint256 private constant OFFEROR_SIGNATURE_REQUIRED_TO_UPDATE_PROMISOR_MASK = 0x10;
    uint256 private constant PROMISOR_SIGNATURE_REQUIRED_TO_UPDATE_PROMISOR_MASK = 0x20;
    uint256 private constant NOTARY_HAS_POWER_TO_UPDATE_PROMISOR_MASK = 0x40;
    uint256 private constant NOTARY_HAS_POWER_TO_UPDATE_OFFEROR_MASK = 0x80;
    uint256 private constant NOTARY_HAS_POWER_TO_VOID_AGREEMENT_MASK = 0x100;

    bytes32 constant NOTARY_ACTION_TYPEHASH =
        keccak256("NotaryAction(bytes32 agreementHash,uint256 nonce,string action)");
    bytes32 constant UPDATE_ACTION_TYPEHASH = keccak256(
        "UpdateAction(bytes32 agreementHash,uint256 nonce,address replacingAgent,string action,string reason)"
    );
    bytes32 constant BURN_NONCE_TYPEHASH = keccak256("BurnNonce(uint256 nonce)");
    bytes32 constant AMEND_TERMS_TYPEHASH = keccak256(
        "AmendmentAction(bytes32 agreementHash,uint256 nonce,uint32[] termsToAdd,uint32[] termsToRemove,string cid,string action)"
    );
    bytes32 constant BULK_CREATE_AGREEMENTS_TYPEHASH =
        keccak256("BulkCreateAgreements(bytes32[] agreementHashes,uint256 nonce)");

    /* -------------------------------------------------------------------------- */
    /*                                   states                                   */
    /* -------------------------------------------------------------------------- */
    //Both parties need to sign to amend terms
    address public verifyingSigner;
    address private _trustedForwarder;

    /// @notice a mapping to store all the nonces that have been used
    /// @dev the verified signer must verify all agreements and amendments.
    /// @dev therefore, we can use a single nonce mapping for all agreements and amendments
    /// @dev this also prevents replay attacks if we are to change the verifyingSigner
    mapping(uint256 => bool) public signerNoncesUsed;

    mapping(address => mapping(uint256 => bool)) public userNoncesUsed;

    /// @notice A mapping to store all agreements by their hash
    mapping(bytes32 => Agreement) private agreements;

    /// @notice A mapping to store the start date of each agreement by their hash
    mapping(bytes32 => uint256) public agreementsStartDate;

    mapping(address => mapping(address => bool)) public isDelegateSigner;

    struct AgreementPointer {
        bool exists;
        uint32 index;
    }
    /// @notice A mapping to store the terms of each agreement by their hash of the description

    mapping(bytes32 => AgreementPointer) public agreementPointers;

    /// @notice a u32 -> AgreementTerms mapping to store the terms of each agreement by their index.
    /// @dev there will be no more than 2^32-1 terms so we can use u32 to reduce SLOAD ops
    mapping(uint32 => AgreementTerms) public agreementTerms;
    uint32 private termCounter;

    /* -------------------------------------------------------------------------- */
    /*                                 constructor                                */
    /* -------------------------------------------------------------------------- */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        // _disableInitializers();
    }

    /// @notice Initializes the contract
    /// @dev Initializes the contract with the provided parameters
    /// @param _signer The address of the signer
    /// @param _trustedForwader The address of the trusted forwarder
    function initialize(
        address _signer,
        // uint256 _chainId,
        address _trustedForwader
    ) external initializer {
        // chainId = _chainId;
        __UUPSUpgradeable_init();
        __Ownable_init_unchained();
        __EIP712_init_unchained("Saasy Labs Registry", "1.0");
        _setTrustedForwarder(_trustedForwader);
        verifyingSigner = _signer;
    }

    /* -------------------------------------------------------------------------- */
    /*                                  external                                  */
    /* -------------------------------------------------------------------------- */
    /// @notice Marks a nonce as used (burns it)
    /// @dev After a nonce is burned, it can't be used again
    /// @param nonce The nonce of the off-chain agreement that has yet to be finalized on-chain
    /// @param notarySignature The notary's signature to use gasless transactions
    function burnNonce(uint256 nonce, address user, bytes memory notarySignature, bytes memory userSignature)
        external
    {
        bytes32 message = keccak256(
            abi.encodePacked("\x19\x01", _domainSeparatorV4(), keccak256(abi.encode(BURN_NONCE_TYPEHASH, nonce)))
        );
        if (!verifySigner(verifyingSigner, message, notarySignature)) {
            _revert(InvalidNotarySignature.selector);
        }
        if (!verifySigner(user, message, userSignature)) {
            _revert(InvalidUserSignature.selector);
        }

        //require nonce is not used to avoid paymaster replay attacks
        if (signerNoncesUsed[nonce]) _revert(NonceUsed.selector);
        if (userNoncesUsed[user][nonce]) _revert(NonceUsed.selector);
        //This is an unenessary sstore but helps us stay organized off-chain.
        signerNoncesUsed[nonce] = true;
        userNoncesUsed[user][nonce] = true;
        emit NonceBurned(nonce, user);
    }

    /// @notice this is for users that want to cancel a nonce without depending on the notary
    /// @param nonce The nonce of the off-chain agreement that has yet to be finalized on-chain
    /// @dev This function will not support gasless transactions
    function selfBurnNonce(uint256 nonce) external {
        if (msg.sender == _trustedForwarder) _revert(NotGaslessTransaction.selector);
        if (signerNoncesUsed[nonce]) _revert(NonceUsed.selector);
        userNoncesUsed[msg.sender][nonce] = true;
        emit NonceBurned(nonce, msg.sender);
    }

    /// @notice Updates the offerer of an agreement
    /// @dev This function requires a valid notary signature and unused nonces. It also verifies the existence of the agreement.
    /// @param agreementHash The hash of the agreement whose promisor is being updated
    /// @param newOfferer The new offerer's address
    /// @param notarySignature The notary's signature
    /// @param nonce The nonce related to this operation
    /// @param reason The reason for updating the offerer. Either a IPFS hash or arweave CID
    function updateOfferer(
        bytes32 agreementHash,
        address newOfferer,
        bytes memory notarySignature,
        bytes memory offererSignature,
        bytes memory promisorSignature,
        bytes memory newOffererSignature,
        uint256 nonce,
        string calldata reason
    ) external {
        bytes32 message = _createUpdateActionDigest(agreementHash, nonce, newOfferer, "updateOfferer", reason);

        if (!verifySigner(verifyingSigner, message, notarySignature)) {
            _revert(InvalidNotarySignature.selector);
        }

        if (!verifySigner(newOfferer, message, newOffererSignature)) {
            _revert(NewOfferorMustApproveContractHandoff.selector);
        }
        if (userNoncesUsed[newOfferer][nonce]) _revert(NonceUsed.selector);
        userNoncesUsed[newOfferer][nonce] = true;

        if (signerNoncesUsed[nonce]) _revert(NonceUsed.selector);

        Agreement storage agreement = agreements[agreementHash];

        if (agreement.offerer == newOfferer) _revert(NewOffererCannotBeOldOfferer.selector);
        if (agreement.promisor == newOfferer) _revert(PromisorCannotBeOfferer.selector);
        if (newOfferer == address(0)) _revert(CannotSetToAddressZero.selector);
        //Sig Verification
        {
            bool t;
            uint256 flags = agreement.flags;
            if (_isOfferorSignatureRequiredToUpdateOfferer(flags)) {
                t = true;
                if (!verifySigner(agreement.offerer, message, offererSignature)) {
                    _revert(InvalidOffererSignature.selector);
                }
                if (userNoncesUsed[agreement.offerer][nonce]) _revert(NonceUsed.selector);
                userNoncesUsed[agreement.offerer][nonce] = true;
            }
            if (_isPromisorSignatureRequiredToUpdateOfferer(flags)) {
                t = true;
                if (!verifySigner(agreement.promisor, message, promisorSignature)) {
                    _revert(InvalidPromisorSignature.selector);
                }
                if (userNoncesUsed[agreement.promisor][nonce]) _revert(NonceUsed.selector);
                userNoncesUsed[agreement.promisor][nonce] = true;
            }

            if (!t) {
                if (!_doesNotaryHaveUnilateralPowerToUpdateOfferor(flags)) {
                    _revert(FieldNotUpdateable.selector);
                }
            }
        }
        // Ensure that the agreement exists
        if (agreement.offerer == address(0)) {
            _revert(AgreementDoesNotExist.selector);
        }
        signerNoncesUsed[nonce] = true;

        // Update the offerer field of the agreement
        address oldOfferer = agreement.offerer;
        agreement.offerer = newOfferer;

        // Emit an event for the offerer update
        emit OffererUpdated(agreementHash, oldOfferer, newOfferer, reason);
    }

    /// @notice Updates the promisor of an agreement
    /// @dev This function requires a valid notary signature and unused nonces. It also verifies the existence of the agreement.
    /// @param agreementHash The hash of the agreement whose promisor is being updated
    /// @param newPromisor The new promisor's address
    /// @param notarySignature The notary's signature
    /// @param nonce The nonce related to this operation
    /// @param reason The ipfs or arweave CID of the reason for the update
    function updatePromisor(
        bytes32 agreementHash,
        address newPromisor,
        bytes memory notarySignature,
        bytes memory offererSignature,
        bytes memory promisorSignature,
        bytes memory newPromisorSignature,
        uint256 nonce,
        string calldata reason
    ) external {
        bytes32 message = _createUpdateActionDigest(agreementHash, nonce, newPromisor, "updatePromisor", reason);

        if (!verifySigner(verifyingSigner, message, notarySignature)) {
            _revert(InvalidNotarySignature.selector);
        }

        if (!verifySigner(newPromisor, message, newPromisorSignature)) {
            _revert(NewPromisorMustApproveContractHandoff.selector);
        }
        if (userNoncesUsed[newPromisor][nonce]) _revert(NonceUsed.selector);
        userNoncesUsed[newPromisor][nonce] = true;

        if (signerNoncesUsed[nonce]) _revert(NonceUsed.selector);

        Agreement storage agreement = agreements[agreementHash];
        address oldPromisor = agreement.promisor;
        address offerer = agreement.offerer;

        if (agreement.promisor == newPromisor) _revert(NewPromisorCannotBeOldPromisor.selector);
        if (agreement.offerer == newPromisor) _revert(OffererCannotBePromisor.selector);
        if (newPromisor == address(0)) _revert(CannotSetToAddressZero.selector);

        {
            bool t;
            uint256 flags = agreement.flags;
            if (_isOfferorSignatureRequiredToUpdatePromisor(flags)) {
                t = true;
                if (userNoncesUsed[offerer][nonce]) _revert(NonceUsed.selector);
                userNoncesUsed[offerer][nonce] = true;
                if (!verifySigner(offerer, message, offererSignature)) {
                    _revert(InvalidOffererSignature.selector);
                }
            }
            if (_isPromisorSignatureRequiredToUpdatePromisor(flags)) {
                t = true;
                if (userNoncesUsed[oldPromisor][nonce]) _revert(NonceUsed.selector);
                userNoncesUsed[oldPromisor][nonce] = true;
                if (!verifySigner(oldPromisor, message, promisorSignature)) {
                    _revert(InvalidPromisorSignature.selector);
                }
            }

            if (!t) {
                if (!_doesNotaryHaveUnilateralPowerToUpdatePromisor(flags)) {
                    _revert(FieldNotUpdateable.selector);
                }
            }
        }

        // Ensure that the agreement exists
        if (agreement.promisor == address(0)) {
            _revert(AgreementDoesNotExist.selector);
        }
        signerNoncesUsed[nonce] = true;

        // Update the promisor field of the agreement
        agreement.promisor = newPromisor;

        // Emit an event for the promisor update
        emit PromisorUpdated(agreementHash, oldPromisor, newPromisor, reason);
    }

    /// @notice Nullifies an existing agreement
    /// @dev This function requires a valid notary signature and an unused nonce
    /// @param agreementHash The hash of the agreement to be nullified
    /// @param notarySignature The notary's signature
    /// @param nonce The nonce related to this operation
    function nullAgreement(
        bytes32 agreementHash,
        bytes memory notarySignature,
        bytes memory offererSignature,
        bytes memory promisorSignature,
        uint256 nonce
    ) external {
        bytes32 message = _createNotaryActionDigest(agreementHash, nonce, "nullAgreement");

        if (!verifySigner(verifyingSigner, message, notarySignature)) {
            _revert(InvalidNotarySignature.selector);
        }

        if (signerNoncesUsed[nonce]) _revert(NonceUsed.selector);
        signerNoncesUsed[nonce] = true;
        Agreement memory agreementToRemove = agreements[agreementHash];

        {
            bool t;
            uint256 flags = agreementToRemove.flags;
            if (_isOfferorSignatureRequiredToNullAgreement(flags)) {
                t = true;
                if (userNoncesUsed[agreementToRemove.offerer][nonce]) _revert(NonceUsed.selector);
                userNoncesUsed[agreementToRemove.offerer][nonce] = true;
                if (!verifySigner(agreementToRemove.offerer, message, offererSignature)) {
                    _revert(InvalidOffererSignature.selector);
                }
            }
            if (_isPromisorSignatureRequiredToNullAgreement(flags)) {
                t = true;
                if (userNoncesUsed[agreementToRemove.promisor][nonce]) _revert(NonceUsed.selector);
                userNoncesUsed[agreementToRemove.promisor][nonce] = true;
                if (!verifySigner(agreementToRemove.promisor, message, promisorSignature)) {
                    _revert(InvalidPromisorSignature.selector);
                }
            }

            if (!t) {
                if (!_doesNotaryHaveUnilateralPowerToNullAgreement(flags)) {
                    _revert(FieldNotUpdateable.selector);
                }
            }
        }

        delete agreements[agreementHash];
        emit AgreementRemoved(agreementToRemove);
    }

    /// @notice Creates a new agreement
    /// @dev This function requires a valid notary signature and unused nonces. It also verifies the offchain agreement hash.
    /// @dev the notary will never sign for a term that has not been added added to this registry.
    /// @param agreement The agreement details
    /// @param _agreementHash The hash of the agreement
    /// @param notarySignature The notary's signature
    /// @param nonce The nonce related to this operation
    /// @param offererSignature The signature of the offerer
    /// @param promisorSignature The signature of the promisor
    function createAgreement(
        Agreement memory agreement,
        bytes32 _agreementHash,
        bytes memory notarySignature,
        uint256 nonce,
        bytes memory offererSignature,
        bytes memory promisorSignature
    ) external {
        bytes32 message = _createNotaryActionDigest(_agreementHash, nonce, "createAgreement");

        if (!verifySigner(verifyingSigner, message, notarySignature)) {
            _revert(InvalidNotarySignature.selector);
        }

        if (!verifySigner(agreement.offerer, message, offererSignature)) {
            _revert(InvalidOffererSignature.selector);
        }

        if (!verifySigner(agreement.promisor, message, promisorSignature)) {
            _revert(InvalidPromisorSignature.selector);
        }

        _checkIsGroupNonceAvailable(nonce, agreement.offerer, agreement.promisor);
        bytes32 agreementHash = keccak256(abi.encode(agreement));
        if (_agreementHash != agreementHash) {
            _revert(OffchainHashInvalid.selector);
        }

        if (agreements[agreementHash].promisor != address(0)) {
            _revert(AgreementAlreadyExists.selector);
        }

        if (agreement.promisor == address(0)) _revert(CannotSetToAddressZero.selector);
        if (agreement.offerer == address(0)) _revert(CannotSetToAddressZero.selector);
        if (block.timestamp > agreement.expiration) {
            _revert(AgreementExpirationMustBeInTheFuture.selector);
        }

        _useGroupNonce(nonce, agreement.offerer, agreement.promisor);
        agreementsStartDate[agreementHash] = block.timestamp;

        // Store the pending agreement
        agreements[agreementHash] = agreement;

        emit AgreementCreated(agreementHash);
    }

    // /// @notice Creates a new agreement
    // /// @dev This function requires a valid notary signature and unused nonces. It also verifies the offchain agreement hash.
    // /// @dev the notary will never sign for a term that has not been added added to this registry.
    // /// @param agreement The agreement details
    // /// @param _agreementHash The hash of the agreement
    // /// @param notarySignature The notary's signature
    // /// @param nonce The nonce related to this operation
    // /// @param offererSignature The signature of the offerer
    // /// @param promisorSignature The signature of the promisor
    function singleCreateAgreementsBulk(
        Agreement[] memory _agreements,
        bytes32[] memory _agreementHashes,
        bytes memory notarySignature,
        uint256[] memory nonces,
        bytes[] memory offererSignatures,
        bytes memory promisorSignature,
        address promisor,
        uint256 singleNonce
    ) external {
        {
            if (signerNoncesUsed[singleNonce]) _revert(NonceUsed.selector);
            if (userNoncesUsed[promisor][singleNonce]) _revert(NonceUsed.selector);
            bytes32 bulkMessage = _createBulkCreateAgreementsDigest(_agreementHashes, singleNonce);
            if (!verifySigner(verifyingSigner, bulkMessage, notarySignature)) {
                _revert(InvalidNotarySignature.selector);
            }
            if (!verifySigner(promisor, bulkMessage, promisorSignature)) {
                _revert(InvalidPromisorSignature.selector);
            }
        }
        unchecked {
            for (uint256 i; i < _agreements.length; ++i) {
                Agreement memory agreement = _agreements[i];
                if (agreement.promisor != promisor) _revert(NotCorrectPromisor.selector);
                bytes32 message = _createNotaryActionDigest(_agreementHashes[i], nonces[i], "createAgreement");
                if (!verifySigner(agreement.offerer, message, offererSignatures[i])) {
                    _revert(InvalidOffererSignature.selector);
                }
                if (userNoncesUsed[agreement.offerer][nonces[i]]) {
                    _revert(NonceUsed.selector);
                }
                userNoncesUsed[agreement.offerer][nonces[i]] = true;
                bytes32 agreementHash = hashAgreement(agreement);
                if (agreementHash != _agreementHashes[i]) {
                    _revert(OffchainHashInvalid.selector);
                }

                if (agreements[agreementHash].promisor != address(0)) {
                    _revert(AgreementAlreadyExists.selector);
                }

                if (agreement.promisor == address(0)) {
                    _revert(CannotSetToAddressZero.selector);
                }
                if (agreement.offerer == address(0)) {
                    _revert(CannotSetToAddressZero.selector);
                }
                if (block.timestamp > agreement.expiration) {
                    _revert(AgreementExpirationMustBeInTheFuture.selector);
                }

                agreements[agreementHash] = agreement;
                agreementsStartDate[agreementHash] = block.timestamp;
                emit AgreementCreated(agreementHash);
            }
        }
        signerNoncesUsed[singleNonce] = true;
        userNoncesUsed[promisor][singleNonce] = true;
    }

    /// @notice Ammends the agreements with new terms and removes old terms with an efficient dynamic index algorithm
    /// @dev This function requires a valid notary signature and unused nonces.
    /// @param agreementHash The hash of the agreement to which a new term is being added
    /// @param notarySignature The notary's signature
    /// @param promisorSignature The promisor's signature
    /// @param offererSignature The offerer's signature
    /// @param termsToAdd The terms to add
    /// @param termsToRemove The terms to remove
    /// @param dynamicTermsToRemoveIndexes The indexes of the terms to remove (keep in mind termsToRemove is a dynamic index since we are dynamically popping)
    /// @param nonce The nonce related to this operation
    function amendAgreementEfficient(
        bytes32 agreementHash,
        bytes memory notarySignature,
        bytes memory offererSignature,
        bytes memory promisorSignature,
        uint32[] memory termsToAdd,
        uint32[] memory termsToRemove,
        uint32[] memory dynamicTermsToRemoveIndexes,
        string memory cid,
        uint256 nonce
    ) external {
        address offerer = agreements[agreementHash].offerer;
        address promisor = agreements[agreementHash].promisor;
        {
            bytes32 message = _createAmendmentDigest(agreementHash, nonce, termsToAdd, termsToRemove, cid);

            if (!verifySigner(verifyingSigner, message, notarySignature)) {
                _revert(InvalidNotarySignature.selector);
            }

            if (!verifySigner(offerer, message, offererSignature)) {
                _revert(InvalidOffererSignature.selector);
            }

            if (!verifySigner(promisor, message, promisorSignature)) {
                _revert(InvalidPromisorSignature.selector);
            }
        }

        {
            _checkIsGroupNonceAvailable(nonce, offerer, promisor);
        }
        {
            for (uint256 i; i < termsToRemove.length;) {
                if (agreements[agreementHash].terms[dynamicTermsToRemoveIndexes[i]] != termsToRemove[i]) {
                    _revert(InvalidMatchingIndex.selector);
                }
                agreements[agreementHash].terms[dynamicTermsToRemoveIndexes[i]] =
                    agreements[agreementHash].terms[agreements[agreementHash].terms.length - 1];
                agreements[agreementHash].terms.pop();
                unchecked {
                    ++i;
                }
            }
        }

        {
            for (uint256 i; i < termsToAdd.length;) {
                if (_containsElement(agreements[agreementHash].terms, termsToAdd[i])) {
                    _revert(TermAlreadyIncluded.selector);
                }
                if (!_agreementTermExists(termsToAdd[i])) {
                    _revert(TermDoesNotExist.selector);
                }
                agreements[agreementHash].terms.push(termsToAdd[i]);
                unchecked {
                    ++i;
                }
            }
        }

        {
            string memory dynamicData = agreements[agreementHash].dynamicData;

            if (keccak256(abi.encodePacked(dynamicData)) != keccak256(abi.encodePacked(cid))) {
                agreements[agreementHash].dynamicData = cid;
            }
        }

        _useGroupNonce(nonce, offerer, promisor);
        emit AgreementAmendment(agreementHash, termsToAdd, termsToRemove);
    }

    /// @notice Ammends the agreements with new terms and removes old terms in a standard fashion.
    /// @dev This function requires a valid notary signature and unused nonces.
    /// @param agreementHash The hash of the agreement to which a new term is being added
    /// @param notarySignature The notary's signature
    /// @param promisorSignature The promisor's signature
    /// @param offererSignature The offerer's signature
    /// @param termsToAdd The terms to add
    /// @param termsToRemove The terms to remove
    /// @param nonce The nonce related to this operation
    function amendAgreement(
        bytes32 agreementHash,
        bytes memory notarySignature,
        bytes memory offererSignature,
        bytes memory promisorSignature,
        uint32[] memory termsToAdd,
        uint32[] memory termsToRemove,
        string memory cid,
        uint256 nonce
    ) external {
        bytes32 message = _createAmendmentDigest(agreementHash, nonce, termsToAdd, termsToRemove, cid);
        {
            address offerer = agreements[agreementHash].offerer;
            address promisor = agreements[agreementHash].promisor;

            if (!verifySigner(verifyingSigner, message, notarySignature)) {
                _revert(InvalidNotarySignature.selector);
            }

            if (!verifySigner(offerer, message, offererSignature)) {
                _revert(InvalidOffererSignature.selector);
            }

            if (!verifySigner(promisor, message, promisorSignature)) {
                _revert(InvalidPromisorSignature.selector);
            }
            _checkIsGroupNonceAvailable(nonce, offerer, promisor);
            _useGroupNonce(nonce, offerer, promisor);
        }

        {
            ///Remove Terms
            uint256 termsLength = agreements[agreementHash].terms.length;
            unchecked {
                for (uint256 i; i < termsToRemove.length; ++i) {
                    // uint32 term = termsToRemove[i];
                    for (uint256 j; j < termsLength; ++j) {
                        //Can this be gas optimized: TBD
                        if (agreements[agreementHash].terms[j] == termsToRemove[i]) {
                            agreements[agreementHash].terms[j] =
                                agreements[agreementHash].terms[agreements[agreementHash].terms.length - 1];
                            agreements[agreementHash].terms.pop();
                            --termsLength;
                            break;
                        }
                        //if we haven't broken out of the loop and we are at the end of the loop, then the term does not exist
                        // and we should revert
                        if (j == termsLength - 1) {
                            _revert(TermDoesNotExist.selector);
                        }
                    }
                }
            }
        }

        uint32[] storage terms = agreements[agreementHash].terms;
        unchecked {
            for (uint256 i; i < termsToAdd.length; ++i) {
                uint32 term = termsToAdd[i];
                if (_containsElement(terms, term)) _revert(TermAlreadyIncluded.selector);
                if (!_agreementTermExists(term)) _revert(TermDoesNotExist.selector);
                terms.push(term);
            }
        }
        {
            string memory dynamicData = agreements[agreementHash].dynamicData;

            if (keccak256(abi.encodePacked(dynamicData)) != keccak256(abi.encodePacked(cid))) {
                agreements[agreementHash].dynamicData = cid;
            }
        }

        emit AgreementAmendment(agreementHash, termsToAdd, termsToRemove);
    }

    function delegateSigners(address[] calldata delegates, bool status) external {
        if (msg.sender == _trustedForwarder) _revert(NotGaslessTransaction.selector);
        unchecked {
            for (uint256 i; i < delegates.length; ++i) {
                address delegate = delegates[i];
                if (delegate == address(0)) _revert(CannotSetToAddressZero.selector);
                if (delegate == msg.sender) _revert(CannotSetSelfToDelegate.selector);
                isDelegateSigner[msg.sender][delegate] = status;
                emit DelegatedSignerSet(msg.sender, delegate, status);
            }
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                                   owners                                   */
    /* -------------------------------------------------------------------------- */
    function addAgreementTerm(string memory _name, string memory _description) external onlyOwner {
        uint32 _termCounter = termCounter;
        bytes32 termHash = keccak256(abi.encodePacked(_description));

        if (agreementPointers[termHash].exists) {
            _revert(TermAlreadyExists.selector);
        }
        agreementPointers[termHash] = AgreementPointer(true, _termCounter);
        agreementTerms[_termCounter++] = AgreementTerms(_name, _description);
        termCounter = _termCounter;
    }

    function addAgreementTerms(AgreementTerms[] calldata _terms) external onlyOwner {
        uint32 _termCounter = termCounter;
        for (uint256 i; i < _terms.length;) {
            bytes32 termHash = keccak256(abi.encodePacked(_terms[i].description));

            if (agreementPointers[termHash].exists) {
                _revert(TermAlreadyExists.selector);
            }
            agreementPointers[termHash] = AgreementPointer(true, _termCounter);
            agreementTerms[_termCounter++] = _terms[i];
            unchecked {
                ++i;
            }
        }

        //Will revert if overflow
        termCounter = _termCounter;
    }

    function setVerifyingSigner(address _verifyingSigner) external onlyOwner {
        verifyingSigner = _verifyingSigner;
    }

    /// @notice Set a new trusted forwarder
    /// @dev Only callable by the contract owner
    /// @param _forwarder The address of the new Forwarder contract to be trusted
    function _setTrustedForwarder(address _forwarder) public onlyOwner {
        _trustedForwarder = _forwarder;
    }

    /// @notice Authorization function for upgrading the smart contract
    /// @dev Only callable by the owner of the contract
    function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {}

    /* -------------------------------------------------------------------------- */
    /*                                    views                                   */
    /* -------------------------------------------------------------------------- */
    /// @notice Check if a forwarder is trusted
    /// @param forwarder The address of the Forwarder contract to check
    /// @return bool Returns true if the forwarder is trusted, false otherwise
    function isTrustedForwarder(address forwarder) public view virtual override returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function getAgreementFromHash(bytes32 agreementHash) external view returns (Agreement memory) {
        return agreements[agreementHash];
    }

    /// @notice Get the trusted forwarder
    /// @dev The Forwarder can have full control over your Recipient. Only trust verified Forwarders.
    /// @return forwarder The address of the Forwarder contract currently trusted
    function getTrustedForwarder() public view virtual returns (address forwarder) {
        return _trustedForwarder;
    }

    /// @notice Verifies if the signer of a message is valid
    /// @dev This function checks if the provided signature of the message matches with the signer address using EIP-712 formatted signatures
    /// @param _signer The signer address
    /// @param message The message that has been signed
    /// @param signature The signature of the message
    /// @return bool Returns true if the signature is valid, false otherwise
    function verifySigner(address _signer, bytes32 message, bytes memory signature) public view returns (bool) {
        (address recovered, ECDSAUpgradeable.RecoverError error) = ECDSAUpgradeable.tryRecover(message, signature);
        if (error != ECDSAUpgradeable.RecoverError.NoError) return false;
        if (error == ECDSAUpgradeable.RecoverError.NoError && recovered == _signer) return true;
        if (DelegateCashCheckerLib.isDelegateForAll(_signer, recovered)) return true;
        if (isDelegateSigner[_signer][recovered]) return true;

        return false;
    }

    /// @notice Gets the payment data of an agreement
    /// @param agreementHash The hash of the agreement whose payment data is being retrieved
    /// @return validatorModule The address of the validator module
    /// @return offerer The address of the offerer
    /// @return promisor The address of the promisor
    /// @return paymentAmount The payment amount for the agreement
    /// @return start The start time of the agreement
    /// @return expiration The expiration time of the agreement
    function getPaymentData(bytes32 agreementHash)
        external
        view
        returns (
            address validatorModule,
            address offerer,
            address promisor,
            uint256 paymentAmount,
            uint256 start,
            uint256 expiration
        )
    {
        Agreement storage agreement = agreements[agreementHash];
        if (agreement.offerer == address(0)) _revert(AgreementDoesNotExist.selector);
        uint256 startDate = agreementsStartDate[agreementHash];

        return (
            agreement.validatorModule,
            agreement.offerer,
            agreement.promisor,
            agreement.paymentAmount,
            startDate,
            agreement.expiration
        );
    }

    /// @notice Hash an Agreement
    /// @param agreement The Agreement to be hashed
    /// @return bytes32 The keccak256 hash of the Agreement
    function hashAgreement(Agreement memory agreement) public pure returns (bytes32) {
        return keccak256(abi.encode(agreement));
    }

    /// @notice Verifies if an agreement is valid
    /// @dev This function checks the expiration of the agreement and its offerer. It also uses the agreement's validator module (if it exists) to validate the agreement
    /// @param agreementHash The hash of the agreement to verify
    /// @return bool Returns true if the agreement is valid, false otherwise
    function verifyAgreement(bytes32 agreementHash) public view returns (bool) {
        Agreement storage agreement = agreements[agreementHash];
        if (agreement.expiration <= block.timestamp) {
            return false;
        }
        if (agreement.offerer == address(0)) {
            return true;
        }
        // Validate the agreement using the validator module
        if (agreement.validatorModule != address(0)) {
            IValidator validator = IValidator(agreement.validatorModule);
            if (!validator.validate(agreementHash)) {
                return false;
            }
        }
        return true;
    }

    /* -------------------------------------------------------------------------- */
    /*                                  internal                                  */
    /* -------------------------------------------------------------------------- */
    // /// @
    function _createNotaryActionDigest(bytes32 _agreementHash, uint256 nonce, string memory action)
        internal
        view
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                _domainSeparatorV4(),
                keccak256(abi.encode(NOTARY_ACTION_TYPEHASH, _agreementHash, nonce, keccak256(bytes(action))))
            )
        );
    }

    function _createBulkCreateAgreementsDigest(bytes32[] memory agreementHashes, uint256 nonce)
        internal
        view
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                _domainSeparatorV4(),
                keccak256(
                    abi.encode(BULK_CREATE_AGREEMENTS_TYPEHASH, keccak256(abi.encodePacked(agreementHashes)), nonce)
                )
            )
        );
    }

    function _createUpdateActionDigest(
        bytes32 _agreementHash,
        uint256 nonce,
        address replacingAgent,
        string memory action,
        string memory reason
    ) internal view returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                _domainSeparatorV4(),
                keccak256(
                    abi.encode(
                        UPDATE_ACTION_TYPEHASH,
                        _agreementHash,
                        nonce,
                        replacingAgent,
                        keccak256(bytes(action)),
                        keccak256(bytes(reason))
                    )
                )
            )
        );
    }

    function _createAmendmentDigest(
        bytes32 _agreementHash,
        uint256 nonce,
        uint32[] memory termsToAdd,
        uint32[] memory termsToRemove,
        string memory cid
    ) internal view returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                _domainSeparatorV4(),
                keccak256(
                    abi.encode(
                        AMEND_TERMS_TYPEHASH,
                        _agreementHash,
                        nonce,
                        keccak256(abi.encodePacked(termsToAdd)),
                        keccak256(abi.encodePacked(termsToRemove)),
                        keccak256(bytes(cid)),
                        keccak256(bytes("amendAgreement"))
                    )
                )
            )
        );
    }

    function _agreementTermExists(uint32 term) internal view returns (bool) {
        return bytes(agreementTerms[term].description).length != 0;
    }

    /// @notice helper function to check if an element is contained in an array
    /// @param array The array to be checked
    /// @param element The element to be checked
    /// @return bool Returns true if the element is contained in the array, false otherwise
    function _containsElement(uint32[] memory array, uint32 element) internal pure returns (bool) {
        //Can never overflow since the term is capped to 2^32
        unchecked {
            for (uint256 i; i < array.length; ++i) {
                if (array[i] == element) {
                    return true;
                }
            }
        }
        return false;
    }

    /// @notice Get the sender of the message
    /// @dev This function overrides the default `_msgSender` function to make it compatible with GSN (Gas Station Network) transactions
    /// @return ret The address of the sender of the message
    function _msgSender() internal view virtual override(ContextUpgradeable, IERC2771Recipient) returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    // @notice Get the data of the message
    /// @dev This function overrides the default `_msgData` function to make it compatible with GSN (Gas Station Network) transactions
    /// @return ret The data of the message
    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, IERC2771Recipient)
        returns (bytes calldata ret)
    {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }

    function _checkIsGroupNonceAvailable(uint256 nonce, address offerer, address promisor) internal view {
        if (signerNoncesUsed[nonce]) _revert(NonceUsed.selector);
        if (userNoncesUsed[offerer][nonce]) _revert(NonceUsed.selector);
        if (userNoncesUsed[promisor][nonce]) _revert(NonceUsed.selector);
    }

    function _useGroupNonce(uint256 nonce, address offerer, address promisor) internal {
        signerNoncesUsed[nonce] = true;
        userNoncesUsed[offerer][nonce] = true;
        userNoncesUsed[promisor][nonce] = true;
    }

    //------------------Null Agreements Bitmask Functions------------------//
    function _isOfferorSignatureRequiredToNullAgreement(uint256 flags) internal pure returns (bool) {
        return flags & OFFEROR_SIGNATURE_REQUIRED_TO_VOID_AGREEMENT_MASK != 0;
    }

    function _isPromisorSignatureRequiredToNullAgreement(uint256 flags) internal pure returns (bool) {
        return flags & PROMISOR_SIGNATURE_REQUIRED_TO_VOID_AGREEMENT_MASK != 0;
    }

    function _doesNotaryHaveUnilateralPowerToNullAgreement(uint256 flags) internal pure returns (bool) {
        return flags & NOTARY_HAS_POWER_TO_VOID_AGREEMENT_MASK != 0;
    }

    //------------------Update Offerer Bitmask Functions------------------//
    function _isOfferorSignatureRequiredToUpdateOfferer(uint256 flags) internal pure returns (bool) {
        return flags & OFFEROR_SIGNATURE_REQUIRED_TO_UPDATE_OFFEROR_MASK != 0;
    }

    function _isPromisorSignatureRequiredToUpdateOfferer(uint256 flags) internal pure returns (bool) {
        return flags & PROMISOR_SIGNATURE_REQUIRED_TO_UPDATE_OFFEROR_MASK != 0;
    }

    function _doesNotaryHaveUnilateralPowerToUpdateOfferor(uint256 flags) internal pure returns (bool) {
        return flags & NOTARY_HAS_POWER_TO_UPDATE_OFFEROR_MASK != 0;
    }

    //------------------Update Promisor Bitmask Functions------------------//
    function _isOfferorSignatureRequiredToUpdatePromisor(uint256 flags) internal pure returns (bool) {
        return flags & OFFEROR_SIGNATURE_REQUIRED_TO_UPDATE_PROMISOR_MASK != 0;
    }

    function _isPromisorSignatureRequiredToUpdatePromisor(uint256 flags) internal pure returns (bool) {
        return flags & PROMISOR_SIGNATURE_REQUIRED_TO_UPDATE_PROMISOR_MASK != 0;
    }

    function _doesNotaryHaveUnilateralPowerToUpdatePromisor(uint256 flags) internal pure returns (bool) {
        return flags & NOTARY_HAS_POWER_TO_UPDATE_PROMISOR_MASK != 0;
    }
    //------------------Update Agreement Terms Bitmask Functions------------------//

    /// @dev for more efficient reverts
    /// @dev reduces byte-code size
    function _revert(bytes4 selector) internal pure {
        assembly {
            mstore(0x0, selector)
            revert(0x0, 0x04)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Declarations
 *
 * @notice A contract must implement this interface in order to support relayed transaction.
 *
 * @notice It is recommended that your contract inherits from the ERC2771Recipient contract.
 */
abstract contract IERC2771Recipient {
    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @param forwarder The address of the Forwarder contract that is being used.
     * @return isTrustedForwarder `true` if the Forwarder is trusted to forward relayed transactions by this Recipient.
     */
    function isTrustedForwarder(address forwarder) public view virtual returns (bool);

    /**
     * @notice Use this method the contract anywhere instead of msg.sender to support relayed transactions.
     * @return sender The real sender of this call.
     * For a call that came through the Forwarder the real sender is extracted from the last 20 bytes of the `msg.data`.
     * Otherwise simply returns `msg.sender`.
     */
    function _msgSender() internal view virtual returns (address);

    /**
     * @notice Use this method in the contract instead of `msg.data` when difference matters (hashing, signature, etc.)
     * @return data The real `msg.data` of this call.
     * For a call that came through the Forwarder, the real sender address was appended as the last 20 bytes
     * of the `msg.data` - so this method will strip those 20 bytes off.
     * Otherwise (if the call was made directly and not through the forwarder) simply returns `msg.data`.
     */
    function _msgData() internal view virtual returns (bytes calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IValidator {
    /// @notice Validate whether the correct amount has been paid for an agreement
    /// @param agreementHash The unique identifier for the agreement
    /// @return bool Whether the correct amount has been paid
    function validate(bytes32 agreementHash) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library DelegateCashCheckerLib {
    error CallFailed();

    address private constant DELEGATE_CASH_ADDRESS = 0x00000000000076A84feF008CDAbe6409d2FE638B;

    function isDelegateForAll(address _delegate, address _vault) internal view returns (bool status) {
        assembly {
            let ptr := mload(0x40)
            //Clean dirty bits just in case
            let vault := shr(96, shl(96, _vault))
            let delegate := shr(96, shl(96, _delegate))

            //load function selector for checkDelegateForAll
            mstore(0x0, 0x9c395bc2) //bytes4(keccak256(bytes("checkDelegateForAll(address,address)")))
            //store msg.sender
            mstore(0x20, delegate)
            //store user
            mstore(0x40, vault)
            //call checkDelegateForAll
            if iszero(staticcall(gas(), DELEGATE_CASH_ADDRESS, 0x1c, 0x44, 0x0, 0x20)) {
                // CallFailed.selector
                mstore(0x0, 0x3204506f)
                revert(0x1c, 0x04)
            }
            mstore(0x40, ptr) // restore free mem prtr
            status := mload(0x0)
        }
    }
}