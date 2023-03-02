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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
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
interface IBeacon {
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

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
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
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
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
            Address.functionDelegateCall(newImplementation, data);
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
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
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
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
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
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
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
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822.sol";
import "../ERC1967/ERC1967Upgrade.sol";

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
abstract contract UUPSUpgradeable is IERC1822Proxiable, ERC1967Upgrade {
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
interface IERC20Permit {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
library StorageSlot {
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

// SPDX-License-Identifier: CC-BY-1.0
// https://github.com/aurora-is-near/native-erc20-connector
pragma solidity ^0.8.17;

import "./Borsh.sol";
import "./Codec.sol";
import "./Types.sol";
import "./Utils.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Address of Cross Contract Call precompile in Aurora.
// It allows scheduling new promises to NEAR contracts.
address constant XCC_PRECOMPILE = 0x516Cded1D16af10CAd47D6D49128E2eB7d27b372;
// Address of predecessor account id precompile in Aurora.
// It allows getting the predecessor account id of the current call.
address constant PREDECESSOR_ACCOUNT_ID_PRECOMPILE = 0x723FfBAbA940e75E7BF5F6d61dCbf8d9a4De0fD7;
// Address of predecessor account id precompile in Aurora.
// It allows getting the current account id of the current call.
address constant CURRENT_ACCOUNT_ID_PRECOMPILE = 0xfeFAe79E4180Eb0284F261205E3F8CEA737afF56;
// Addresss of promise result precompile in Aurora.
address constant PROMISE_RESULT_PRECOMPILE = 0x0A3540F79BE10EF14890e87c1A0040A68Cc6AF71;
// Address of wNEAR ERC20 on mainnet
address constant wNEAR_MAINNET = 0x4861825E75ab14553E5aF711EbbE6873d369d146;

struct NEAR {
    /// Wether the represenative NEAR account id for this contract
    /// has already been created or not. This is required since the
    /// first cross contract call requires attaching extra deposit
    /// to cover storage staking balance.
    bool initialized;
    /// Address of wNEAR token contract. It is used to charge the user
    /// required tokens for paying NEAR storage fees and attached balance
    /// for cross contract calls.
    IERC20 wNEAR;
}

library AuroraSdk {
    using Codec for bytes;
    using Codec for PromiseCreateArgs;
    using Codec for PromiseWithCallback;
    using Codec for Borsh.Data;
    using Borsh for Borsh.Data;

    /// Create an instance of NEAR object. Requires the address at which
    /// wNEAR ERC20 token contract is deployed.
    function initNear(IERC20 wNEAR) public returns (NEAR memory) {
        NEAR memory near = NEAR(false, wNEAR);
        near.wNEAR.approve(
            XCC_PRECOMPILE,
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        );
        return near;
    }

    /// Default configuration for mainnet.
    function mainnet() public returns (NEAR memory) {
        return initNear(IERC20(wNEAR_MAINNET));
    }

    /// Compute NEAR represtentative account for the given Aurora address.
    /// This is the NEAR account created by the cross contract call precompile.
    function nearRepresentative(address account)
        public
        returns (string memory)
    {
        return addressSubAccount(account, currentAccountId());
    }

    /// Prepends the given account ID with the given address (hex-encoded).
    function addressSubAccount(address account, string memory accountId)
        public
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    Utils.bytesToHex(abi.encodePacked((bytes20(account)))),
                    ".",
                    accountId
                )
            );
    }

    /// Compute implicity Aurora Address for the given NEAR account.
    function implicitAuroraAddress(string memory accountId)
        public
        pure
        returns (address)
    {
        return address(uint160(uint256(keccak256(bytes(accountId)))));
    }

    /// Compute the implicit Aurora address of the represenative NEAR account
    /// for the given Aurora address. Useful when a contract wants to call
    /// itself via a callback using cross contract call precompile.
    function nearRepresentitiveImplicitAddress(address account)
        public
        returns (address)
    {
        return implicitAuroraAddress(nearRepresentative(account));
    }

    /// Get the promise result at the specified index.
    function promiseResult(uint256 index)
        public
        returns (PromiseResult memory result)
    {
        (bool success, bytes memory returnData) = PROMISE_RESULT_PRECOMPILE
            .call("");
        require(success);

        Borsh.Data memory borsh = Borsh.from(returnData);

        uint32 length = borsh.decodeU32();
        require(index < length, "Index out of bounds");

        for (uint256 i = 0; i < index; i++) {
            PromiseResultStatus status = PromiseResultStatus(
                uint8(borsh.decodeU8())
            );
            if (status == PromiseResultStatus.Successful) {
                borsh.skipBytes();
            }
        }

        result.status = PromiseResultStatus(borsh.decodeU8());
        if (result.status == PromiseResultStatus.Successful) {
            result.output = borsh.decodeBytes();
        }
    }

    /// Get the NEAR account id of the current contract. It is the account id of Aurora engine.
    function currentAccountId() public returns (string memory) {
        (bool success, bytes memory returnData) = CURRENT_ACCOUNT_ID_PRECOMPILE
            .call("");
        require(success);
        return string(returnData);
    }

    /// Get the NEAR account id of the predecessor contract.
    function predecessorAccountId() public returns (string memory) {
        (
            bool success,
            bytes memory returnData
        ) = PREDECESSOR_ACCOUNT_ID_PRECOMPILE.call("");
        require(success);
        return string(returnData);
    }

    /// Crease a base promise. This is not immediately schedule for execution
    /// until transact is called. It can be combined with other promises using
    /// `then` combinator.
    ///
    /// Input is not checekd during promise creation. If it is invalid, the
    /// transaction will be scheduled either way, but it will fail during execution.
    function call(
        NEAR storage near,
        string memory targetAccountId,
        string memory method,
        bytes memory args,
        uint128 nearBalance,
        uint64 nearGas
    ) public returns (PromiseCreateArgs memory) {
        /// Need to capture nearBalance before we modify it so that we don't
        /// double-charge the user for their initialization cost.
        PromiseCreateArgs memory promise_args = PromiseCreateArgs(
            targetAccountId,
            method,
            args,
            nearBalance,
            nearGas
        );

        if (!near.initialized) {
            /// If the contract needs to be initialized, we need to attach
            /// 2 NEAR (= 2 * 10^24 yoctoNEAR) to the promise.
            nearBalance += 2_000_000_000_000_000_000_000_000;
            near.initialized = true;
        }

        if (nearBalance > 0) {
            near.wNEAR.transferFrom(
                msg.sender,
                address(this),
                uint256(nearBalance)
            );
        }

        return promise_args;
    }

    /// Similar to `call`. It is a wrapper that simplifies the creation of a promise
    /// to a controct inside `Aurora`.
    function auroraCall(
        NEAR storage near,
        address target,
        bytes memory args,
        uint128 nearBalance,
        uint64 nearGas
    ) public returns (PromiseCreateArgs memory) {
        return
            call(
                near,
                currentAccountId(),
                "call",
                abi.encodePacked(uint8(0), target, uint256(0), args.encode()),
                nearBalance,
                nearGas
            );
    }

    /// Schedule a base promise to be executed on NEAR. After this function is called
    /// the promise should not be used anymore.
    function transact(PromiseCreateArgs memory nearPromise) public {
        (bool success, bytes memory returnData) = XCC_PRECOMPILE.call(
            nearPromise.encodeCrossContractCallArgs(ExecutionMode.Eager)
        );

        if (!success) {
            revert(string(returnData));
        }
    }

    /// Schedule a promise with callback to be executed on NEAR. After this function is called
    /// the promise should not be used anymore.
    ///
    /// Duplicated due to lack of generics in solidity. Check relevant issue:
    /// https://github.com/ethereum/solidity/issues/869
    function transact(PromiseWithCallback memory nearPromise) public {
        (bool success, bytes memory returnData) = XCC_PRECOMPILE.call(
            nearPromise.encodeCrossContractCallArgs(ExecutionMode.Eager)
        );

        if (!success) {
            revert(string(returnData));
        }
    }

    /// Similar to `transact`, except the promise is not executed as part of the same transaction.
    /// A separate transaction to execute the scheduled promise is needed.
    function lazy_transact(PromiseCreateArgs memory nearPromise) public {
        (bool success, bytes memory returnData) = XCC_PRECOMPILE.call(
            nearPromise.encodeCrossContractCallArgs(ExecutionMode.Lazy)
        );

        if (!success) {
            revert(string(returnData));
        }
    }

    function lazy_transact(PromiseWithCallback memory nearPromise) public {
        (bool success, bytes memory returnData) = XCC_PRECOMPILE.call(
            nearPromise.encodeCrossContractCallArgs(ExecutionMode.Lazy)
        );

        if (!success) {
            revert(string(returnData));
        }
    }

    /// Create a promise with callback from two given promises.
    function then(
        PromiseCreateArgs memory base,
        PromiseCreateArgs memory callback
    ) public pure returns (PromiseWithCallback memory) {
        return PromiseWithCallback(base, callback);
    }
}

// SPDX-License-Identifier: CC-BY-1.0
// https://github.com/aurora-is-near/native-erc20-connector
// https://github.com/aurora-is-near/native-erc20-connector
pragma solidity ^0.8.17;

import "./Utils.sol";

library Borsh {
    using Borsh for Data;

    struct Data {
        uint256 ptr;
        uint256 end;
    }

    function from(bytes memory data) internal pure returns (Data memory res) {
        uint256 ptr;
        assembly {
            ptr := data
        }
        unchecked {
            res.ptr = ptr + 32;
            res.end = res.ptr + Utils.readMemory(ptr);
        }
    }

    // This function assumes that length is reasonably small, so that data.ptr + length will not overflow. In the current code, length is always less than 2^32.
    function requireSpace(Data memory data, uint256 length) internal pure {
        unchecked {
            require(
                data.ptr + length <= data.end,
                "Parse error: unexpected EOI"
            );
        }
    }

    function read(Data memory data, uint256 length)
        internal
        pure
        returns (bytes32 res)
    {
        data.requireSpace(length);
        res = bytes32(Utils.readMemory(data.ptr));
        unchecked {
            data.ptr += length;
        }
        return res;
    }

    function done(Data memory data) internal pure {
        require(data.ptr == data.end, "Parse error: EOI expected");
    }

    // Same considerations as for requireSpace.
    function peekKeccak256(Data memory data, uint256 length)
        internal
        pure
        returns (bytes32)
    {
        data.requireSpace(length);
        return Utils.keccak256Raw(data.ptr, length);
    }

    // Same considerations as for requireSpace.
    function peekSha256(Data memory data, uint256 length)
        internal
        view
        returns (bytes32)
    {
        data.requireSpace(length);
        return Utils.sha256Raw(data.ptr, length);
    }

    function decodeU8(Data memory data) internal pure returns (uint8) {
        return uint8(bytes1(data.read(1)));
    }

    function decodeU16(Data memory data) internal pure returns (uint16) {
        return Utils.swapBytes2(uint16(bytes2(data.read(2))));
    }

    function decodeU32(Data memory data) internal pure returns (uint32) {
        return Utils.swapBytes4(uint32(bytes4(data.read(4))));
    }

    function decodeU64(Data memory data) internal pure returns (uint64) {
        return Utils.swapBytes8(uint64(bytes8(data.read(8))));
    }

    function decodeU128(Data memory data) internal pure returns (uint128) {
        return Utils.swapBytes16(uint128(bytes16(data.read(16))));
    }

    function decodeU256(Data memory data) internal pure returns (uint256) {
        return Utils.swapBytes32(uint256(data.read(32)));
    }

    function decodeBytes20(Data memory data) internal pure returns (bytes20) {
        return bytes20(data.read(20));
    }

    function decodeBytes32(Data memory data) internal pure returns (bytes32) {
        return data.read(32);
    }

    function decodeBool(Data memory data) internal pure returns (bool) {
        uint8 res = data.decodeU8();
        require(res <= 1, "Parse error: invalid bool");
        return res != 0;
    }

    function skipBytes(Data memory data) internal pure {
        uint256 length = data.decodeU32();
        data.requireSpace(length);
        unchecked {
            data.ptr += length;
        }
    }

    function decodeBytes(Data memory data)
        internal
        pure
        returns (bytes memory res)
    {
        uint256 length = data.decodeU32();
        data.requireSpace(length);
        res = Utils.memoryToBytes(data.ptr, length);
        unchecked {
            data.ptr += length;
        }
    }
}

// SPDX-License-Identifier: CC-BY-1.0
// https://github.com/aurora-is-near/native-erc20-connector
pragma solidity ^0.8.17;

import "./Borsh.sol";
import "./Types.sol";
import "./Utils.sol";

/// Provide borsh serialization and deserialization for multiple types.
library Codec {
    using Borsh for Borsh.Data;

    function encodeU8(uint8 v) internal pure returns (bytes1) {
        return bytes1(v);
    }

    function encodeU16(uint16 v) internal pure returns (bytes2) {
        return bytes2(Utils.swapBytes2(v));
    }

    function encodeU32(uint32 v) public pure returns (bytes4) {
        return bytes4(Utils.swapBytes4(v));
    }

    function encodeU64(uint64 v) public pure returns (bytes8) {
        return bytes8(Utils.swapBytes8(v));
    }

    function encodeU128(uint128 v) public pure returns (bytes16) {
        return bytes16(Utils.swapBytes16(v));
    }

    /// Encode bytes into borsh. Use this method to encode strings as well.
    function encode(bytes memory value) public pure returns (bytes memory) {
        return abi.encodePacked(encodeU32(uint32(value.length)), bytes(value));
    }

    /// Encode Execution mode enum into borsh.
    function encodeEM(ExecutionMode mode) public pure returns (bytes1) {
        return bytes1(uint8(mode));
    }

    /// Encode PromiseArgsVariant enum into borsh.
    function encodePromise(
        PromiseArgsVariant mode
    ) public pure returns (bytes1) {
        return bytes1(uint8(mode));
    }

    /// Encode base promise into borsh.
    function encode(
        PromiseCreateArgs memory nearPromise
    ) public pure returns (bytes memory) {
        return
            abi.encodePacked(
                encode(bytes(nearPromise.targetAccountId)),
                encode(bytes(nearPromise.method)),
                encode(nearPromise.args),
                encodeU128(nearPromise.nearBalance),
                encodeU64(nearPromise.nearGas)
            );
    }

    /// Encode promise with callback into borsh.
    function encode(
        PromiseWithCallback memory nearPromise
    ) public pure returns (bytes memory) {
        return
            abi.encodePacked(
                encode(nearPromise.base),
                encode(nearPromise.callback)
            );
    }

    /// Encode create promise using borsh. The encoded data
    /// uses the same format that the Cross Contract Call precompile expects.
    function encodeCrossContractCallArgs(
        PromiseCreateArgs memory nearPromise,
        ExecutionMode mode
    ) public pure returns (bytes memory) {
        return
            abi.encodePacked(
                encodeEM(mode),
                encodePromise(PromiseArgsVariant.Create),
                encode(nearPromise)
            );
    }

    /// Encode promise with callback using borsh. The encoded data
    /// uses the same format that the Cross Contract Call precompile expects.
    function encodeCrossContractCallArgs(
        PromiseWithCallback memory nearPromise,
        ExecutionMode mode
    ) public pure returns (bytes memory) {
        return
            abi.encodePacked(
                encodeEM(mode),
                encodePromise(PromiseArgsVariant.Callback),
                encode(nearPromise)
            );
    }

    /// Decode promise result using borsh.
    function decodePromiseResult(
        Borsh.Data memory data
    ) public pure returns (PromiseResult memory result) {
        result.status = PromiseResultStatus(data.decodeU8());
        if (result.status == PromiseResultStatus.Successful) {
            result.output = data.decodeBytes();
        }
    }

    /// Skip promise result from the buffer.
    function skipPromiseResult(Borsh.Data memory data) public pure {
        PromiseResultStatus status = PromiseResultStatus(
            uint8(data.decodeU8())
        );
        if (status == PromiseResultStatus.Successful) {
            data.skipBytes();
        }
    }
}

// SPDX-License-Identifier: CC-BY-1.0
// https://github.com/aurora-is-near/native-erc20-connector
pragma solidity ^0.8.17;

/// Basic NEAR promise.
struct PromiseCreateArgs {
    /// Account id of the target contract to be called.
    string targetAccountId;
    /// Method in the contract to be called
    string method;
    /// Payload to be passed to the method as input.
    bytes args;
    /// Amount of NEAR tokens to attach to the call. This will
    /// be charged from the caller in wNEAR.
    uint128 nearBalance;
    /// Amount of gas to attach to the call.
    uint64 nearGas;
}

enum PromiseArgsVariant {
    /// Basic NEAR promise
    Create,
    /// NEAR promise with a callback attached.
    Callback,
    /// Description of arbitrary NEAR promise. Allows applying combinators
    /// recursively, multiple action types and batched actions.
    Recursive
}

/// Combine two base promises using NEAR combinator `then`.
struct PromiseWithCallback {
    /// Initial promise to be triggered.
    PromiseCreateArgs base;
    /// Second promise that is executed after the execution of `base`.
    /// In particular this promise will have access to the result of
    /// the `base` promise.
    PromiseCreateArgs callback;
}

enum ExecutionMode {
    /// Eager mode means that the promise WILL be executed in a single
    /// NEAR transaction.
    Eager,
    /// Lazy mode means that the promise WILL be scheduled for execution
    /// and a separate interaction is required to trigger this execution.
    Lazy
}

enum PromiseResultStatus {
    /// This status should not be reachable.
    NotReady,
    /// The promise was executed successfully.
    Successful,
    /// The promise execution failed.
    Failed
}

struct PromiseResult {
    /// Status result of the promise execution.
    PromiseResultStatus status;
    /// If the status is successful, output contains the output of the promise.
    /// Otherwise the output field MUST be ignored.
    bytes output;
}

// SPDX-License-Identifier: CC-BY-1.0
// https://github.com/aurora-is-near/native-erc20-connector
pragma solidity ^0.8.17;

library Utils {
    function swapBytes2(uint16 v) internal pure returns (uint16) {
        return (v << 8) | (v >> 8);
    }

    function swapBytes4(uint32 v) internal pure returns (uint32) {
        v = ((v & 0x00ff00ff) << 8) | ((v & 0xff00ff00) >> 8);
        return (v << 16) | (v >> 16);
    }

    function swapBytes8(uint64 v) internal pure returns (uint64) {
        v = ((v & 0x00ff00ff00ff00ff) << 8) | ((v & 0xff00ff00ff00ff00) >> 8);
        v = ((v & 0x0000ffff0000ffff) << 16) | ((v & 0xffff0000ffff0000) >> 16);
        return (v << 32) | (v >> 32);
    }

    function swapBytes16(uint128 v) internal pure returns (uint128) {
        v =
            ((v & 0x00ff00ff00ff00ff00ff00ff00ff00ff) << 8) |
            ((v & 0xff00ff00ff00ff00ff00ff00ff00ff00) >> 8);
        v =
            ((v & 0x0000ffff0000ffff0000ffff0000ffff) << 16) |
            ((v & 0xffff0000ffff0000ffff0000ffff0000) >> 16);
        v =
            ((v & 0x00000000ffffffff00000000ffffffff) << 32) |
            ((v & 0xffffffff00000000ffffffff00000000) >> 32);
        return (v << 64) | (v >> 64);
    }

    function swapBytes32(uint256 v) internal pure returns (uint256) {
        v =
            ((v &
                0x00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff) <<
                8) |
            ((v &
                0xff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00) >>
                8);
        v =
            ((v &
                0x0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff) <<
                16) |
            ((v &
                0xffff0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff0000) >>
                16);
        v =
            ((v &
                0x00000000ffffffff00000000ffffffff00000000ffffffff00000000ffffffff) <<
                32) |
            ((v &
                0xffffffff00000000ffffffff00000000ffffffff00000000ffffffff00000000) >>
                32);
        v =
            ((v &
                0x0000000000000000ffffffffffffffff0000000000000000ffffffffffffffff) <<
                64) |
            ((v &
                0xffffffffffffffff0000000000000000ffffffffffffffff0000000000000000) >>
                64);
        return (v << 128) | (v >> 128);
    }

    function readMemory(uint256 ptr) internal pure returns (uint256 res) {
        assembly {
            res := mload(ptr)
        }
    }

    function writeMemory(uint256 ptr, uint256 value) internal pure {
        assembly {
            mstore(ptr, value)
        }
    }

    function memoryToBytes(uint256 ptr, uint256 length)
        internal
        pure
        returns (bytes memory res)
    {
        if (length != 0) {
            assembly {
                // 0x40 is the address of free memory pointer.
                res := mload(0x40)
                let end := add(
                    res,
                    and(
                        add(length, 63),
                        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0
                    )
                )
                // end = res + 32 + 32 * ceil(length / 32).
                mstore(0x40, end)
                mstore(res, length)
                let destPtr := add(res, 32)
                // prettier-ignore
                for {} 1 {} {
                    mstore(destPtr, mload(ptr))
                    destPtr := add(destPtr, 32)
                    if eq(destPtr, end) { break }
                    ptr := add(ptr, 32)
                }
            }
        }
    }

    function keccak256Raw(uint256 ptr, uint256 length)
        internal
        pure
        returns (bytes32 res)
    {
        assembly {
            res := keccak256(ptr, length)
        }
    }

    function sha256Raw(uint256 ptr, uint256 length)
        internal
        view
        returns (bytes32 res)
    {
        assembly {
            // 2 is the address of SHA256 precompiled contract.
            // First 64 bytes of memory can be used as scratch space.
            let ret := staticcall(gas(), 2, ptr, length, 0, 32)
            // If the call to SHA256 precompile ran out of gas, burn any gas that remains.
            // prettier-ignore
            for {} iszero(ret) {} {}
            res := mload(0)
        }
    }

    /// Convert array of bytes to hexadecimal string.
    /// https://ethereum.stackexchange.com/a/126928/45323
    function bytesToHex(bytes memory buffer)
        public
        pure
        returns (string memory)
    {
        // Fixed buffer size for hexadecimal convertion
        bytes memory converted = new bytes(buffer.length * 2);

        bytes memory _base = "0123456789abcdef";

        for (uint256 i = 0; i < buffer.length; i++) {
            converted[i * 2] = _base[uint8(buffer[i]) / _base.length];
            converted[i * 2 + 1] = _base[uint8(buffer[i]) % _base.length];
        }

        return string(converted);
    }
}

pragma solidity ^0.8.17;

import "../AuroraSDK/AuroraSdk.sol";

contract AquaProxy {
    using AuroraSdk for NEAR;
    using AuroraSdk for PromiseWithCallback;
    using AuroraSdk for PromiseCreateArgs;

    enum ParticleStatus {
        None,
        Pending,
        Success,
        Failure
    }

    struct Particle {
        string air;
        string prevData;
        string params;
        string callResults;
    }

    IERC20 constant wNEAR = IERC20(0x4861825E75ab14553E5aF711EbbE6873d369d146);

    address public immutable selfReprsentativeImplicitAddress;
    address public immutable aquaVMImplicitAddress;

    NEAR public near;
    string public aquaVMAddress;

    uint64 constant VS_NEAR_GAS = 30_000_000_000_000;

    constructor(string memory aquaVMAddress_) {
        aquaVMAddress = aquaVMAddress_;
        aquaVMImplicitAddress = AuroraSdk.implicitAuroraAddress(aquaVMAddress);

        near = AuroraSdk.initNear(wNEAR);

        selfReprsentativeImplicitAddress = AuroraSdk
            .nearRepresentitiveImplicitAddress(address(this));
    }

    function verifyParticle(Particle calldata particle) public {
        PromiseCreateArgs memory verifyScriptCall = near.call(
            aquaVMAddress,
            "verify_script",
            abi.encodePacked(
                Codec.encode(bytes(particle.air)),
                Codec.encode(bytes(particle.prevData)),
                Codec.encode(bytes(particle.params)),
                Codec.encode(bytes(particle.callResults))
            ),
            0,
            VS_NEAR_GAS
        );

        verifyScriptCall.transact();
    }
}

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "../AuroraSDK/AuroraSdk.sol";
import "./AquaProxy.sol";
import "./EpochManager.sol";

contract CoreState {
    IERC20 public fluenceToken;
    AquaProxy public aquaProxy;
    uint public withdrawTimeout;
    uint public epochDelayForReward;
    uint public minAmountOfEpochsForReward;
    uint public slashFactor;
    uint public updateSettingsTimeout;
    EpochManager public epochManager;
}

contract Core is OwnableUpgradeable, CoreState, UUPSUpgradeable {
    function initialize(
        IERC20 fluenceToken_,
        AquaProxy aquaProxy_,
        uint withdrawTimeout_,
        uint epochDelayForReward_,
        uint slashFactor_,
        uint updateSettingsTimeout_,
        EpochManager epochManager_
    ) public initializer {
        fluenceToken = fluenceToken_;
        aquaProxy = aquaProxy_;
        withdrawTimeout = withdrawTimeout_;
        epochDelayForReward = epochDelayForReward_;
        slashFactor = slashFactor_;
        updateSettingsTimeout = updateSettingsTimeout_;
        epochManager = epochManager_;

        __Ownable_init();
    }

    function setFluenceToken(IERC20 fluenceToken_) external onlyOwner {
        fluenceToken = fluenceToken_;
    }

    function setAquaProxy(AquaProxy aquaProxy_) external onlyOwner {
        aquaProxy = aquaProxy_;
    }

    function setWithdrawTimeout(uint withdrawTimeout_) external onlyOwner {
        withdrawTimeout = withdrawTimeout_;
    }

    function setEpochDelayForReward(
        uint epochDelayForReward_
    ) external onlyOwner {
        epochDelayForReward = epochDelayForReward_;
    }

    function setMinAmountOfEpochsForReward(
        uint minAmountOfEpochsForReward_
    ) external onlyOwner {
        minAmountOfEpochsForReward = minAmountOfEpochsForReward_;
    }

    function setSlashFactor(uint slashFactor_) external onlyOwner {
        slashFactor = slashFactor_;
    }

    function setUpdateSettingsTimeout(
        uint updateSettingsTimeout_
    ) external onlyOwner {
        updateSettingsTimeout = updateSettingsTimeout_;
    }

    function setEpochManager(EpochManager epochManager_) external onlyOwner {
        epochManager = epochManager_;
    }

    function _authorizeUpgrade(address newImplementation) internal override {}
}

pragma solidity ^0.8.17;

contract EpochManager {
    uint256 public epochDuration;

    constructor(uint256 epochDuration_) {
        epochDuration = epochDuration_;
    }

    function currentEpoch() external view returns (uint256) {
        return block.timestamp / epochDuration;
    }
}

pragma solidity ^0.8.17;

import "./external/DealConfig.sol";
import "./external/PaymentByEpoch.sol";
import "./external/WorkersManager.sol";
import "./external/WithdrawManager.sol";

import "./internal/DealConfigInternal.sol";
import "./internal/WorkersManagerInternal.sol";
import "./internal/WithdrawManagerInternal.sol";
import "./internal/PaymentManagers/PaymentByEpochInternal.sol";
import "./internal/StatusControllerInternal.sol";

contract Deal is
    DealConfig,
    PaymentByEpoch,
    WorkersManager,
    WithdrawManager,
    DealConfigInternal,
    StatusControllerInternal,
    PaymentByEpochInternal,
    WorkersManagerInternal,
    WithdrawManagerInternal
{
    constructor(
        Core core_,
        address paymentToken_,
        uint256 pricePerEpoch_,
        uint256 requiredStake_,
        uint256 minWorkers_,
        uint256 maxWorkers_,
        uint256 targetWorkers_,
        string memory appCID_,
        string[] memory effectorWasmsCids_
    )
        DealConfigInternal(
            core_,
            address(core_.fluenceToken()),
            paymentToken_,
            pricePerEpoch_,
            requiredStake_,
            minWorkers_,
            maxWorkers_,
            targetWorkers_,
            appCID_,
            effectorWasmsCids_
        )
    {}
}

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IDealConfig.sol";
import "../internal/interfaces/IDealConfigInternal.sol";

abstract contract DealConfig is IDealConfig, IDealConfigInternal {
    using SafeERC20 for IERC20;
    event NewAppCID(string appCID);

    function core() external view returns (Core) {
        return _core();
    }

    function requiredStake() external view returns (uint256) {
        return _requiredStake();
    }

    function paymentToken() external view returns (IERC20) {
        return _paymentToken();
    }

    function pricePerEpoch() external view returns (uint256) {
        return _pricePerEpoch();
    }

    function fluenceToken() external view returns (IERC20) {
        return _fluenceToken();
    }

    function appCID() external view returns (string memory) {
        return _appCID();
    }

    function effectorWasmsCids() external view returns (string[] memory) {
        return _effectorWasmsCids();
    }

    function minWorkers() external view returns (uint256) {
        return _minWorkers();
    }

    function maxWorkersPerProvider() external view returns (uint256) {
        return _maxWorkersPerProvider();
    }

    function targetWorkers() external view returns (uint256) {
        return _targetWorkers();
    }

    function setAppCID(string calldata appCID_) external override {
        _setAppCID(appCID_);

        emit NewAppCID(appCID_);
    }
}

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../../Core/Core.sol";

interface IDealConfig {
    function core() external view returns (Core);

    function requiredStake() external view returns (uint256);

    function paymentToken() external view returns (IERC20);

    function pricePerEpoch() external view returns (uint256);

    function fluenceToken() external view returns (IERC20);

    function appCID() external view returns (string memory);

    function effectorWasmsCids() external view returns (string[] memory);

    function minWorkers() external view returns (uint256);

    function maxWorkersPerProvider() external view returns (uint256);

    function targetWorkers() external view returns (uint256);

    function setAppCID(string calldata appCID_) external;
}

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPaymentManager {
    function getPaymentBalance() external view returns (uint256);

    function depositToPaymentBalance(uint256 amount) external;

    //function withdrawFromPaymentBalance(IERC20 token, uint256 amount) external;
}

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWithdrawManager {
    function getUnlockedCollateralBy(address owner, uint256 timestamp)
        external
        view
        returns (uint256);

    function withdraw(IERC20 token) external;
}

pragma solidity ^0.8.17;

import "../../../Core/Core.sol";

interface IWorkersManager {
    type PATId is bytes32;

    event AddProviderToken(address indexed owner, PATId id);
    event RemoveProviderToken(PATId id);

    function getPATOwner(PATId id) external view returns (address);

    function createProviderToken(bytes32 salt) external;

    function removeProviderToken(PATId id) external;
}

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IPaymentManager.sol";
import "../internal/interfaces/IPaymentInternal.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract PaymentByEpoch is IPaymentManager, IPaymentInternal, Ownable {
    using SafeERC20 for IERC20;

    uint256 private _balance;

    function getPaymentBalance() public view returns (uint256) {
        return _getPaymentBalance();
    }

    function depositToPaymentBalance(uint256 amount) public {
        _depositToPaymentBalance(amount);
    }
    /*
    function withdrawFromPaymentBalance(IERC20 token, uint256 amount) public {
        _withdrawFromPaymentBalance(token, amount);
    }*/
}

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IWithdrawManager.sol";
import "../internal/interfaces/IWithdrawManagerInternal.sol";
import "../internal/interfaces/IDealConfigInternal.sol";

abstract contract WithdrawManager is
    IWithdrawManager,
    IDealConfigInternal,
    IWithdrawManagerInternal
{
    function getUnlockedCollateralBy(address owner, uint256 timestamp)
        external
        view
        returns (uint256)
    {
        return _getUnlockedAmountBy(_fluenceToken(), owner, timestamp);
    }

    function withdraw(IERC20 token) external {
        _withdraw(token, msg.sender);
    }
}

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../internal/interfaces/IWorkersManagerInternal.sol";
import "../internal/interfaces/IDealConfigInternal.sol";
import "./interfaces/IWorkersManager.sol";

abstract contract WorkersManager is
    IWorkersManager,
    IDealConfigInternal,
    IWorkersManagerInternal
{
    using SafeERC20 for IERC20;

    function getPATOwner(PATId id) external view returns (address) {
        return _getPATOwner(id);
    }

    function createProviderToken(bytes32 salt) external {
        address owner = msg.sender;

        //TODO: owner
        PATId id = PATId.wrap(
            keccak256(abi.encode(address(this), block.number, salt, owner))
        );

        _createPAT(id, owner);

        emit AddProviderToken(owner, id);
    }

    function removeProviderToken(PATId id) external {
        require(_getPATOwner(id) == msg.sender, "WorkersManager: not owner");
        _removePAT(id);

        emit RemoveProviderToken(id);
    }
}

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IDealConfigInternal.sol";

abstract contract DealConfigInternal is IDealConfigInternal {
    Core private immutable _coreAddr;
    IERC20 private immutable _fluenceToken_;
    IERC20 private immutable _paymentToken_;

    uint256 private _pricePerEpoch_;
    uint256 private _requiredStake_;
    string private _appCID_;
    uint256 private _minWorkers_;
    uint256 private _maxWorkersPerProvider_;
    uint256 private _targetWorkers_;
    string[] private _effectorWasmsCids_;

    constructor(
        Core core_,
        address fluenceToken_,
        address paymentToken_,
        uint256 pricePerEpoch_,
        uint256 requiredStake_,
        uint256 minWorkers_,
        uint256 maxWorkersPerProvider_,
        uint256 targetWorkers_,
        string memory appCID_,
        string[] memory effectorWasmsCids_
    ) {
        _coreAddr = core_;
        _fluenceToken_ = IERC20(fluenceToken_);
        _paymentToken_ = IERC20(paymentToken_);
        _pricePerEpoch_ = pricePerEpoch_;
        _requiredStake_ = requiredStake_;
        _minWorkers_ = minWorkers_;
        _maxWorkersPerProvider_ = maxWorkersPerProvider_;
        _targetWorkers_ = targetWorkers_;
        _appCID_ = appCID_;
        _effectorWasmsCids_ = effectorWasmsCids_;
    }

    function _core() internal view override returns (Core) {
        return _coreAddr;
    }

    function _requiredStake() internal view override returns (uint256) {
        return _requiredStake_;
    }

    function _paymentToken() internal view override returns (IERC20) {
        return _paymentToken_;
    }

    function _pricePerEpoch() internal view override returns (uint256) {
        return _pricePerEpoch_;
    }

    function _fluenceToken() internal view override returns (IERC20) {
        return _fluenceToken_;
    }

    function _appCID() internal view override returns (string memory) {
        return _appCID_;
    }

    function _effectorWasmsCids()
        internal
        view
        override
        returns (string[] memory)
    {
        return _effectorWasmsCids_;
    }

    function _minWorkers() internal view override returns (uint256) {
        return _minWorkers_;
    }

    function _maxWorkersPerProvider() internal view override returns (uint256) {
        return _maxWorkersPerProvider_;
    }

    function _targetWorkers() internal view override returns (uint256) {
        return _targetWorkers_;
    }

    function _setPricePerEpoch(uint256 pricePerEpoch_) internal override {
        _pricePerEpoch_ = pricePerEpoch_;
    }

    function _setRequiredStake(uint256 requiredStake_) internal override {
        _requiredStake_ = requiredStake_;
    }

    function _setAppCID(string calldata appCID_) internal override {
        _appCID_ = appCID_;
    }
}

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../../Core/Core.sol";

abstract contract IDealConfigInternal {
    function _core() internal view virtual returns (Core);

    function _requiredStake() internal view virtual returns (uint256);

    function _paymentToken() internal view virtual returns (IERC20);

    function _pricePerEpoch() internal view virtual returns (uint256);

    function _fluenceToken() internal view virtual returns (IERC20);

    function _appCID() internal view virtual returns (string memory);

    function _effectorWasmsCids()
        internal
        view
        virtual
        returns (string[] memory);

    function _minWorkers() internal view virtual returns (uint256);

    function _maxWorkersPerProvider() internal view virtual returns (uint256);

    function _targetWorkers() internal view virtual returns (uint256);

    function _setPricePerEpoch(uint256 pricePerEpoch_) internal virtual;

    function _setRequiredStake(uint256 requiredStake_) internal virtual;

    function _setAppCID(string calldata appCID_) internal virtual;
}

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../internal/interfaces/IDealConfigInternal.sol";
import "../../internal/interfaces/IStatusControllerInternal.sol";
import "../../../Utils/Consts.sol";

abstract contract IPaymentInternal {
    function _getPaymentBalance() internal view virtual returns (uint256);

    function _depositToPaymentBalance(uint256 amount) internal virtual;

    function _withdrawFromPaymentBalance(IERC20 token, uint256 amount)
        internal
        virtual;

    function _spendReward() internal virtual;

    function _getRewards() internal view virtual returns (uint256);
}

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../../Core/Core.sol";

abstract contract IStatusControllerInternal {
    enum Status {
        WaitingForWorkers,
        Working
    }

    function _status() internal view virtual returns (Status);

    function _startWorkingEpoch() internal view virtual returns (uint256);

    function _changeStatus(Status status_) internal virtual;
}

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../external/interfaces/IWorkersManager.sol";

abstract contract IWithdrawManagerInternal {
    function _getUnlockedAmountBy(
        IERC20 token,
        address owner,
        uint256 timestamp
    ) internal view virtual returns (uint256);

    function _createWithdrawRequest(
        IERC20 token,
        address owner,
        uint256 amount
    ) internal virtual;

    function _withdraw(IERC20 token, address owner) internal virtual;
}

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../external/interfaces/IWorkersManager.sol";

abstract contract IWorkersManagerInternal {
    function _getPATOwner(IWorkersManager.PATId id)
        internal
        view
        virtual
        returns (address);

    function _createPAT(IWorkersManager.PATId id, address owner)
        internal
        virtual;

    function _removePAT(IWorkersManager.PATId id) internal virtual;
}

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../internal/interfaces/IDealConfigInternal.sol";
import "../../internal/interfaces/IStatusControllerInternal.sol";
import "../../internal/interfaces/IPaymentInternal.sol";
import "../../../Utils/Consts.sol";

abstract contract PaymentByEpochInternal is
    IDealConfigInternal,
    IStatusControllerInternal,
    IPaymentInternal
{
    using SafeERC20 for IERC20;

    uint256 private _balance;

    function _getPaymentBalance() internal view override returns (uint256) {
        return _balance - _getRewards();
    }

    function _depositToPaymentBalance(uint256 amount) internal override {
        IERC20 token = _paymentToken();
        token.safeTransferFrom(msg.sender, address(this), amount);
        _balance += amount;
    }

    function _withdrawFromPaymentBalance(IERC20 token, uint256 amount)
        internal
        override
    {
        require(
            _getPaymentBalance() >= amount,
            "PaymentByEpochInternal: Not enough balance"
        );
        _balance -= amount;
        token.safeTransfer(msg.sender, amount);
    }

    function _spendReward() internal override {
        _balance -= _getRewards();
    }

    function _getRewards() internal view override returns (uint256) {
        if (_startWorkingEpoch() != 0) {
            uint256 currentEpoch = _core().epochManager().currentEpoch();
            uint256 epochsPassed = currentEpoch - _startWorkingEpoch();
            uint256 pricePerEpoch = _pricePerEpoch();
            uint256 totalPayment = epochsPassed * pricePerEpoch;
            if (totalPayment > _balance) {
                return _balance;
            }
            return totalPayment;
        }

        return 0;
    }
}

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IStatusControllerInternal.sol";
import "./interfaces/IPaymentInternal.sol";
import "./interfaces/IDealConfigInternal.sol";

abstract contract StatusControllerInternal is
    IDealConfigInternal,
    IStatusControllerInternal,
    IPaymentInternal
{
    event StatusChanged(IStatusControllerInternal.Status newStatus);

    IStatusControllerInternal.Status private _status_;

    uint256 private _startWorkingEpoch_;

    function _status()
        internal
        view
        override
        returns (IStatusControllerInternal.Status)
    {
        return _status_;
    }

    function _startWorkingEpoch() internal view override returns (uint256) {
        return _startWorkingEpoch_;
    }

    function _changeStatus(IStatusControllerInternal.Status status_)
        internal
        override
    {
        IStatusControllerInternal.Status oldStatus = _status_;

        if (oldStatus == status_) {
            return;
        }

        if (
            oldStatus != status_ &&
            status_ == IStatusControllerInternal.Status.Working
        ) {
            _onStartWorking();
        } else if (
            oldStatus != status_ &&
            status_ == IStatusControllerInternal.Status.WaitingForWorkers
        ) {
            _onEndWorking();
        }

        _status_ = status_;
        emit StatusChanged(status_);
    }

    function _onStartWorking() private {
        _startWorkingEpoch_ = _core().epochManager().currentEpoch();
    }

    function _onEndWorking() private {
        _spendReward();
        //TODO: transfer reward to workers
        _startWorkingEpoch_ = 0;
    }
}

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IWithdrawManagerInternal.sol";
import "./interfaces/IDealConfigInternal.sol";
import "../../Utils/WithdrawRequests.sol";

abstract contract WithdrawManagerInternal is
    IDealConfigInternal,
    IWithdrawManagerInternal
{
    using WithdrawRequests for WithdrawRequests.Requests;
    using SafeERC20 for IERC20;

    mapping(address => WithdrawRequests.Requests) private _requests;

    modifier onlyFluenceToken(IERC20 token) {
        require(
            _fluenceToken() == token,
            "WithdrawManagerInternal: wrong token"
        );
        _;
    }

    function _getUnlockedAmountBy(
        IERC20 token,
        address owner,
        uint256 timestamp
    ) internal view override onlyFluenceToken(token) returns (uint256) {
        return
            _requests[owner].getAmountBy(timestamp - _core().withdrawTimeout());
    }

    function _createWithdrawRequest(
        IERC20 token,
        address owner,
        uint256 amount
    ) internal override onlyFluenceToken(token) {
        _requests[owner].push(amount);
    }

    function _withdraw(IERC20 token, address owner)
        internal
        override
        onlyFluenceToken(token)
    {
        uint256 amount = _requests[owner].confirmBy(
            block.timestamp - _core().withdrawTimeout()
        );

        token.safeTransfer(owner, amount);
    }
}

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";
import "../external/interfaces/IWorkersManager.sol";
import "./interfaces/IWorkersManagerInternal.sol";
import "./interfaces/IDealConfigInternal.sol";
import "./interfaces/IWithdrawManagerInternal.sol";
import "./interfaces/IStatusControllerInternal.sol";

abstract contract WorkersManagerInternal is
    IDealConfigInternal,
    IStatusControllerInternal,
    IWithdrawManagerInternal,
    IWorkersManagerInternal
{
    using SafeERC20 for IERC20;

    struct OwnerInfo {
        uint256 patsCount;
    }

    struct PAT {
        address owner;
        uint256 collateral;
        uint256 created;
    }

    bytes32 private constant _PREFIX_PAT_SLOT =
        keccak256("network.fluence.WorkersManager.pat");

    uint256 private _currentWorkers;
    mapping(address => OwnerInfo) private _ownersInfo;

    function _getPATOwner(IWorkersManager.PATId id)
        internal
        view
        override
        returns (address)
    {
        return _getPAT(id).owner;
    }

    function _createPAT(IWorkersManager.PATId id, address owner)
        internal
        override
    {
        PAT storage pat = _getPAT(id);
        uint256 patsCountByOwner = _ownersInfo[owner].patsCount;
        uint256 currentWorkers = _currentWorkers;

        require(currentWorkers < _targetWorkers(), "Target workers reached");
        require(
            patsCountByOwner < _maxWorkersPerProvider(),
            "Max workers per provider reached"
        );
        require(pat.owner == address(0x00), "Id already used");

        uint256 epoch = _core().epochManager().currentEpoch();
        uint256 requiredStake = _requiredStake();

        _fluenceToken().safeTransferFrom(owner, address(this), requiredStake);

        pat.owner = owner;
        pat.collateral = requiredStake;
        pat.created = epoch;

        _ownersInfo[owner].patsCount = patsCountByOwner + 1;

        currentWorkers++;
        _currentWorkers = currentWorkers;

        IStatusControllerInternal.Status status = _status();
        if (
            status == IStatusControllerInternal.Status.WaitingForWorkers &&
            currentWorkers >= _minWorkers()
        ) {
            status = IStatusControllerInternal.Status.Working;
            _changeStatus(status);
        }
    }

    function _removePAT(IWorkersManager.PATId id) internal override {
        PAT storage pat = _getPAT(id);
        address owner = pat.owner;

        _createWithdrawRequest(_fluenceToken(), owner, pat.collateral);

        _ownersInfo[owner].patsCount--;

        uint256 currentWorkers = _currentWorkers;
        currentWorkers--;
        _currentWorkers = currentWorkers;

        if (
            _status() == IStatusControllerInternal.Status.Working &&
            currentWorkers < _minWorkers()
        ) {
            _changeStatus(IStatusControllerInternal.Status.WaitingForWorkers);
        }

        delete pat.owner;
        delete pat.collateral;
        delete pat.created;
    }

    function _getPAT(IWorkersManager.PATId id)
        private
        pure
        returns (PAT storage pat)
    {
        bytes32 bytes32Id = IWorkersManager.PATId.unwrap(id);

        bytes32 slot = bytes32(
            uint256(keccak256(abi.encodePacked(_PREFIX_PAT_SLOT, bytes32Id))) -
                1
        );

        assembly {
            pat.slot := slot
        }
    }
}

pragma solidity ^0.8.17;

import "../Core/Core.sol";
import "../Deal/Deal.sol";

contract DealFactory {
    Core public core;
    address public defaultPaymentToken;

    event DealCreated(
        address deal,
        address paymentToken,
        uint256 pricePerEpoch,
        uint256 requiredStake,
        uint256 minWorkers,
        uint256 maxWorkersPerProvider,
        uint256 targetWorkers,
        string appCID,
        string[] effectorWasmsCids,
        uint256 epoch
    );

    constructor(Core core_, address defaultPaymentToken_) {
        core = core_;
        defaultPaymentToken = defaultPaymentToken_;
    }

    function createDeal(
        uint256 minWorkers_,
        uint256 targetWorkers_,
        string memory appCID_
    ) external {
        //TODO: args varables
        uint256 pricePerEpoch_ = 83 * 10**15;
        uint256 requiredStake_ = 1 * 10**18;
        uint256 maxWorkersPerProvider_ = 10000000;
        address paymentToken_ = defaultPaymentToken;

        string[] memory effectorWasmsCids_ = new string[](0);

        // TODO: create2 function
        Deal deal = new Deal(
            core,
            paymentToken_,
            pricePerEpoch_,
            requiredStake_,
            minWorkers_,
            maxWorkersPerProvider_,
            targetWorkers_,
            appCID_,
            effectorWasmsCids_
        );

        deal.transferOwnership(msg.sender);

        emit DealCreated(
            address(deal),
            address(paymentToken_),
            pricePerEpoch_,
            requiredStake_,
            minWorkers_,
            maxWorkersPerProvider_,
            targetWorkers_,
            appCID_,
            effectorWasmsCids_,
            core.epochManager().currentEpoch()
        );
    }
}

pragma solidity ^0.8.17;

bytes32 constant NULL = hex"0000000000000000000000000000000000000000000000000000000000000000";

pragma solidity ^0.8.17;

import "./Consts.sol";

library WithdrawRequests {
    struct Requests {
        Request[] _requests;
        uint256 _indexOffset;
    }

    struct Request {
        uint32 _createTimestamp;
        uint224 _cumulative;
    }

    function getAt(Requests storage self, uint256 index)
        internal
        view
        returns (uint256 timestamp, uint256 amount)
    {
        uint256 realLength = self._requests.length;
        uint256 realIndex = index + self._indexOffset;

        if (realIndex >= realLength) {
            revert("Index is out of range");
        }

        Request storage request = self._requests[realIndex];

        amount = request._cumulative;
        if (realIndex != 0) {
            Request storage previousRequest = self._requests[realIndex - 1];
            amount -= previousRequest._cumulative;
        }

        return (request._createTimestamp, amount);
    }

    function length(Requests storage self) internal view returns (uint256) {
        return self._requests.length - self._indexOffset;
    }

    function getAmountBy(Requests storage self, uint256 timestamp)
        internal
        view
        returns (uint256)
    {
        (, uint256 amount) = _getIndexAndAmountBy(self, timestamp);
        return amount;
    }

    function push(Requests storage self, uint256 amount) internal {
        uint32 timestamp = uint32(block.timestamp);

        require(amount > 0, "Amount can't be zero");
        require(amount <= type(uint224).max, "Amount is too big");

        //TODO: check overflow
        uint224 uint224Amount = uint224(amount);
        uint256 realLength = self._requests.length;
        uint256 currentLength = realLength - self._indexOffset;

        if (currentLength != 0) {
            Request storage last = self._requests[realLength - 1];
            if (last._createTimestamp == timestamp) {
                last._cumulative += uint224Amount;
                return;
            } else {
                self._requests.push(
                    Request(timestamp, last._cumulative + uint224Amount)
                );
            }
        } else {
            self._requests.push(Request(timestamp, uint224Amount));
        }
    }

    function removeFromLast(Requests storage self, uint256 amount) internal {
        uint256 realLength = self._requests.length;
        uint256 currentLength = realLength - self._indexOffset;

        require(currentLength != 0, "Requests is empty");
        require(amount <= type(uint224).max, "Amount is too big");

        //TODO: check overflow
        uint224 uint224Amount = uint224(amount);

        Request storage last = self._requests[currentLength - 1];
        uint256 currentAmount = last._cumulative;

        require(currentAmount >= uint224Amount, "Not enough amount");

        if (uint224Amount < currentAmount) {
            last._cumulative -= uint224Amount;
        } else {
            self._requests.pop();
        }
    }

    function confirmBy(Requests storage self, uint256 timestamp)
        internal
        returns (uint256)
    {
        (uint256 index, uint256 amount) = _getIndexAndAmountBy(self, timestamp);
        self._indexOffset = index + 1;
        return amount;
    }

    function _getIndexAndAmountBy(Requests storage self, uint256 timestamp)
        private
        view
        returns (uint256, uint256)
    {
        uint256 realLength = self._requests.length;
        uint256 indexOffset = self._indexOffset;

        uint256 currentLength = realLength - indexOffset;

        require(currentLength != 0, "Requests is empty");

        (uint256 index, Request storage request) = _getIndexBy(
            self,
            indexOffset,
            realLength - 1,
            timestamp
        );
        uint256 amount = request._cumulative;
        if (indexOffset != 0) {
            amount -= self._requests[indexOffset - 1]._cumulative;
        }

        return (index, amount);
    }

    function _getIndexBy(
        Requests storage self,
        uint256 startLow,
        uint256 startHigh,
        uint256 timestamp
    ) private view returns (uint256, Request storage request) {
        uint256 low = startLow;
        uint256 high = startHigh;

        uint256 mid = (low + high) / 2;
        request = self._requests[mid];

        while (low != high) {
            uint256 midTimestamp = request._createTimestamp;
            if (midTimestamp == timestamp) {
                return (mid, request);
            } else if (midTimestamp < timestamp) {
                low = mid + 1;
            } else {
                high = mid - 1;
            }

            mid = (low + high) / 2;
            request = self._requests[mid];
        }

        return (mid, request);
    }
}