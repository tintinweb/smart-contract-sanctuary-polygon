/**
 *Submitted for verification at polygonscan.com on 2023-06-20
*/

// File: @openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20PermitUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

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

// File: @openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/interfaces/IERC1967Upgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/proxy/beacon/IBeaconUpgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/interfaces/draft-IERC1822Upgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;


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

// File: @openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;







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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;




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

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;



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

// File: @openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: @openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;




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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20Upgradeable token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && AddressUpgradeable.isContract(address(token));
    }
}

// File: @openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;





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
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
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
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
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
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
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
    function _transfer(address from, address to, uint256 amount) internal virtual {
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

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
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// File: contracts/USDG.sol


pragma solidity ^0.8.17;






contract USDGUpV1 is
    Initializable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    IERC20Upgradeable public USDT;

    //libraries
    using SafeERC20Upgradeable for IERC20Upgradeable;

    //attribute for the system
    uint256 public revenueRate;
    uint256 public secondsInDay;
    uint256 public baseReleaseDays;
    uint256 public baseSpeedupDays;
    uint256 public depositUnit;
    uint256 public platformFee;
    uint256 public lockedUSDG; //for gold exchange

    uint256 public platformFeeRate;
    uint256 public USDTShareRewardRate;
    uint256 public USDGShareRewardRate;

    bool public transferState;
    bool public openSwapState;
    bool public depositState;

    //one people's attribute;
    mapping(address => address) public father;
    mapping(address => uint256) public totalDepositValue;
    mapping(address => uint256) public totalRevenue;
    mapping(address => uint256) public totalclaimedRevenue;
    mapping(address => uint256) public totalSwapRevenue;
    mapping(address => uint256) public USDTShareReward;
    mapping(address => uint256) public USDGShareReward;
    mapping(address => bool) public registerState;
    mapping(address => address[6]) public parentList;
    mapping(address => uint256[6]) public performance;

    struct Order {
        uint256 depositValue;
        uint256 orderRevenue;
        uint256 releasPerDay;
        uint256 claimedRevenue; //var
        uint256 depositTime;
        uint256 refreshTime; //var
        uint256 endTime;
    }

    struct SwapOrder {
        address applier;
        uint256 swapValue;
        uint256 swapTime;
        uint8 state; //0 means swaping,1 means passed,2 means rejected;
    }

    struct SpeedUpCard {
        uint256 speedUpPerDay; //perday
        uint256 startTime;
        uint256 refreshTime;
        uint256 endTime;
        bool activeState;
    }

    struct SpeedUpPool {
        uint256 speedUpPerDay; //perday
        uint256 startTime;
        uint256 endTime;
    }

    mapping(address => mapping(uint8 => SpeedUpCard)) public userSpeedUpCard;
    mapping(address => mapping(uint8 => SpeedUpPool)) public userSpeedUpPool;

    SwapOrder[] public swapOrderBook;
    uint256[2] public activeSwapOrderIndex;
    mapping(address => uint256[]) public applierSwapOrderIndex;
    mapping(address => uint8) public applierState; //0 means no apply now, 1 means in applying

    mapping(address => uint256[6]) public fieldsDepositValue;
    mapping(address => mapping(uint8 => Order[])) public orderBook;
    mapping(address => mapping(uint8 => uint256[2])) public activeOrderIndex;

    //events
    event Registered(address parent, address user);
    event Deposited(address user, uint256 amount, uint8 fieldIndex);
    event SwapApply(address user, uint256 USDGamount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _usdt) public initializer {
        __ERC20_init("USD Gold", "USDG");
        __Ownable_init();
        __UUPSUpgradeable_init();

        revenueRate = 20;
        secondsInDay = 86400;
        baseReleaseDays = 500;
        baseSpeedupDays = 30;
        depositUnit = 12E19;
        platformFee = 0;
        platformFeeRate = 5;
        USDTShareRewardRate = 5;
        USDGShareRewardRate = 5;
        transferState = false;
        openSwapState = false;
        depositState = true;
        USDT = IERC20Upgradeable(_usdt);
        father[msg.sender] = address(0x00);
        registerState[address(0x00)] = true;
        registerState[msg.sender] = true;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    //tool function
    function getTimePeriod(
        uint256 t1,
        uint256 t2,
        uint256 t3,
        uint256 t4
    ) internal pure returns (uint256 newt1, uint256 newt2) {
        if (t1 >= t4 || t2 <= t3) {
            return (0, 0);
        } else {
            newt1 = (t1 < t3) ? t3 : t1;
            newt2 = (t2 < t4) ? t2 : t4;
        }
    }

    //functions for users

    function register(address _father) external {
        require(msg.sender != _father, "can not set yourself as parent");
        require(registerState[msg.sender] == false, "you should be new user");
        require(
            registerState[_father] == true,
            "your parent should be registed"
        );
        address cFather;
        if (_father == address(0x00)) {
            father[msg.sender] = owner();
            cFather = owner();
        } else {
            father[msg.sender] = _father;
            cFather = _father;
        }
        updateParentList(msg.sender, cFather);
        registerState[msg.sender] = true;
        SpeedUpCard memory newSpeedUpCard = SpeedUpCard(0, 0, 0, 0, false);
        SpeedUpPool memory newSpeedUpPool = SpeedUpPool(0, 0, 0);

        for (uint8 i = 0; i < 6; i++) {
            userSpeedUpCard[msg.sender][i] = newSpeedUpCard;
            userSpeedUpPool[msg.sender][i] = newSpeedUpPool;
        }

        emit Registered(_father, msg.sender);
    }

    function updateParentList(address _child, address _cFather) internal {
        parentList[_child][0] = _cFather;
        for (uint8 i = 0; i < 5; i++) {
            if (father[parentList[_child][i]] != address(0x00)) {
                address _gfather = father[parentList[_child][i]];
                parentList[_child][i + 1] = _gfather;
            }
        }
    }

    function checkFieldDepositable(
        address _buyer,
        uint8 _fieldIndex,
        uint256 _sendAmount
    ) public view returns (bool) {
        if (_fieldIndex > 5) {
            return false;
        }
        if (_fieldIndex == 0) {
            return true;
        }
        if (
            _fieldIndex > 1 &&
            performance[_buyer][_fieldIndex - 1] / ((_fieldIndex - 1) * 10) >=
            fieldsDepositValue[_buyer][_fieldIndex] + _sendAmount
        ) {
            return true;
        }
        if (
            _fieldIndex == 1 &&
            performance[_buyer][0] / 5 >=
            fieldsDepositValue[_buyer][1] + _sendAmount
        ) {
            return true;
        } else {
            return false;
        }
    }

    function deposit(uint256 _sendAmount, uint8 _fieldIndex) external {
        require(registerState[msg.sender] == true, "you need register first");
        require(
            _sendAmount >= depositUnit && _sendAmount % depositUnit == 0,
            "Deposit Amount should be times of depositUnit"
        );
        require(
            checkFieldDepositable(msg.sender, _fieldIndex, _sendAmount),
            "field not open yet"
        );
        require(depositState, "deposit is not open now");

        //need approve first
        USDT.safeTransferFrom(
            msg.sender,
            address(this),
            fixUSDTAmount(_sendAmount)
        );

        //after deposit
        USDTShareReward[father[msg.sender]] +=
            (_sendAmount * USDTShareRewardRate) /
            100;
        createOrder(msg.sender, _sendAmount, _fieldIndex);
        speedUp(msg.sender, _sendAmount);
        emit Deposited(msg.sender, _sendAmount, _fieldIndex);
    }

    function takeUSDTShareReward() external {
        uint256 _reward = USDTShareReward[msg.sender];
        USDT.transfer(msg.sender, fixUSDTAmount(_reward));
        USDTShareReward[msg.sender] = 0;
    }

    function takeUSDGShareReward() external {
        uint256 _reward = USDGShareReward[msg.sender];
        _mint(msg.sender, _reward);
        USDGShareReward[msg.sender] = 0;
    }

    function createOrder(
        address _buyer,
        uint256 _sendAmount,
        uint8 _fieldIndex
    ) internal {
        uint256 _depositValue = _sendAmount;
        uint256 _orderRevenue = _sendAmount * (_fieldIndex + 2);
        uint256 _releasPerDay = (_sendAmount * 2) / baseReleaseDays;
        uint256 _claimedRevenue = 0;
        uint256 _depositTime = block.timestamp;
        uint256 _endTime = block.timestamp +
            (secondsInDay * baseReleaseDays * 10 * (_fieldIndex + 2)) /
            20;
        uint256 _refreshTime = _depositTime;

        Order memory newOreder = Order(
            _depositValue,
            _orderRevenue,
            _releasPerDay,
            _claimedRevenue,
            _depositTime,
            _refreshTime,
            _endTime
        );
        orderBook[_buyer][_fieldIndex].push(newOreder);
        activeOrderIndex[_buyer][_fieldIndex][1]++;
        totalDepositValue[_buyer] += _sendAmount;
        totalRevenue[_buyer] += _orderRevenue;
        fieldsDepositValue[_buyer][_fieldIndex] += _sendAmount;
    }

    function createMarketOrder(
        address _marketLeader,
        uint8 _fieldIndex,
        uint256 _depositValue,
        uint256 _claimedRevenue
    ) external onlyOwner {
        uint256 _orderRevenue = _depositValue * (_fieldIndex + 2);
        uint256 _releasPerDay = (_depositValue * 2) / baseReleaseDays;
        uint256 _depositTime = block.timestamp;
        uint256 _endTime = block.timestamp +
            (secondsInDay * baseReleaseDays * 10 * (_fieldIndex + 2)) /
            20;
        uint256 _refreshTime = _depositTime;

        Order memory newOreder = Order(
            _depositValue,
            _orderRevenue,
            _releasPerDay,
            _claimedRevenue,
            _depositTime,
            _refreshTime,
            _endTime
        );
        orderBook[_marketLeader][_fieldIndex].push(newOreder);
        activeOrderIndex[_marketLeader][_fieldIndex][1]++;
        totalDepositValue[_marketLeader] += _depositValue;
        totalRevenue[_marketLeader] += _orderRevenue;
        fieldsDepositValue[_marketLeader][_fieldIndex] += _depositValue;
        totalclaimedRevenue[_marketLeader] += _claimedRevenue;

        speedUp(_marketLeader, _depositValue);
    }

    function speedUp(address _child, uint256 _baseAmount) internal {
        for (uint8 _fieldIndex = 0; _fieldIndex < 6; _fieldIndex++) {
            address _parent = parentList[_child][_fieldIndex];
            performance[_parent][_fieldIndex] += _baseAmount;
            if (_parent == address(0x00)) {
                continue;
            }
            // uint256 _speedBaseAmount = _baseAmount / (_fieldIndex + 1);
            baseSpeedup(_parent, _baseAmount, _fieldIndex);
        }
    }

    function baseSpeedup(
        address _orderOwner,
        uint256 _baseAmount,
        uint8 _fieldIndex
    ) internal {
        SpeedUpPool storage _userSpeedUpPool = userSpeedUpPool[_orderOwner][
            _fieldIndex
        ];

        uint256 _now = block.timestamp;
        uint256 _future = block.timestamp + baseSpeedupDays * secondsInDay;

        uint256 t1;
        uint256 t2;
        (t1, t2) = getTimePeriod(
            _userSpeedUpPool.startTime,
            _userSpeedUpPool.endTime,
            _now,
            _future
        );

        uint256 restval = ((t2 - t1) * _userSpeedUpPool.speedUpPerDay) /
            (secondsInDay * baseSpeedupDays);
        uint256 _baseRevenue = (_baseAmount * revenueRate) / 10;
        uint256 _baseReleasPerDay = _baseRevenue /
            (baseReleaseDays * (_fieldIndex + 1));
        _userSpeedUpPool.speedUpPerDay = _baseReleasPerDay + restval;
        _userSpeedUpPool.startTime = _now;
        _userSpeedUpPool.endTime = _future;
    }

    function chargeSpeedUpCard(uint8 _fieldIndex) external {
        takeRevenueForAddress(msg.sender);
        SpeedUpCard storage _userSpeedUpCard = userSpeedUpCard[msg.sender][
            _fieldIndex
        ];

        SpeedUpPool storage _userSpeedUpPool = userSpeedUpPool[msg.sender][
            _fieldIndex
        ];

        require(
            _userSpeedUpPool.endTime >= block.timestamp,
            "SpeedUpPool Expired"
        );
        if (_userSpeedUpCard.endTime > block.timestamp) {
            uint256 restPoolval = ((_userSpeedUpPool.endTime -
                block.timestamp) * _userSpeedUpPool.speedUpPerDay) /
                (secondsInDay * baseSpeedupDays);

            uint256 restCardval = ((_userSpeedUpCard.endTime -
                block.timestamp) * _userSpeedUpCard.speedUpPerDay) /
                (secondsInDay * baseSpeedupDays);

            _userSpeedUpCard.speedUpPerDay = restPoolval + restCardval;
            _userSpeedUpCard.startTime = block.timestamp;
            _userSpeedUpCard.refreshTime = block.timestamp;
            _userSpeedUpCard.endTime =
                block.timestamp +
                baseSpeedupDays *
                secondsInDay;
            _userSpeedUpCard.activeState = true;

            _userSpeedUpPool.speedUpPerDay = 0;
            _userSpeedUpPool.endTime = 0;
            _userSpeedUpPool.startTime = 0;
        } else {
            _userSpeedUpCard.speedUpPerDay = _userSpeedUpPool.speedUpPerDay;
            _userSpeedUpCard.startTime = block.timestamp;
            _userSpeedUpCard.refreshTime = block.timestamp;
            _userSpeedUpCard.endTime =
                block.timestamp +
                baseSpeedupDays *
                secondsInDay;
            _userSpeedUpCard.activeState = true;

            _userSpeedUpPool.speedUpPerDay = 0;
            _userSpeedUpPool.endTime = 0;
            _userSpeedUpPool.startTime = 0;
        }
    }

    function takeRevenue() external {
        takeRevenueForAddress(msg.sender);
    }

    function takeRevenueForAddress(address _revenueOwner) public {
        for (uint8 i = 0; i < 6; i++) {
            uint256 _length = activeOrderIndex[_revenueOwner][i][1];
            uint256 _start = activeOrderIndex[_revenueOwner][i][0];
            if (_length == 0) {
                continue;
            }
            for (uint256 j = _start; j < _start + _length; j++) {
                baseTakeRevenue(_revenueOwner, i, j);
            }
        }
    }

    function baseTakeRevenue(
        address _orderOwner,
        uint8 _fieldIndex,
        uint256 _orderIndex
    ) internal {
        Order storage orderToTakeRevenue = orderBook[_orderOwner][_fieldIndex][
            _orderIndex
        ];

        SpeedUpCard storage _userSpeedUpCard = userSpeedUpCard[_orderOwner][
            _fieldIndex
        ];

        if (_userSpeedUpCard.endTime <= orderToTakeRevenue.refreshTime) {
            _userSpeedUpCard.activeState = false;
        }

        if (_userSpeedUpCard.activeState == false) {
            uint256 revenueNow = ((block.timestamp -
                orderToTakeRevenue.refreshTime) *
                orderToTakeRevenue.releasPerDay) / secondsInDay;
            if (
                orderToTakeRevenue.endTime > block.timestamp &&
                revenueNow + orderToTakeRevenue.claimedRevenue <
                orderToTakeRevenue.orderRevenue
            ) {
                _mint(_orderOwner, revenueNow);
                orderToTakeRevenue.claimedRevenue += revenueNow;
                totalclaimedRevenue[_orderOwner] += revenueNow;
                orderToTakeRevenue.refreshTime = block.timestamp;
            } else {
                uint256 claimRevenue = orderToTakeRevenue.orderRevenue -
                    orderToTakeRevenue.claimedRevenue;
                _mint(_orderOwner, claimRevenue);
                orderToTakeRevenue.claimedRevenue = orderToTakeRevenue
                    .orderRevenue;
                orderToTakeRevenue.refreshTime = block.timestamp;
                totalclaimedRevenue[_orderOwner] += claimRevenue;
                activeOrderIndex[_orderOwner][_fieldIndex][0]++;
                activeOrderIndex[_orderOwner][_fieldIndex][1]--;
                return;
            }
        } else {
            uint256 t1;
            uint256 t2;
            (t1, t2) = getTimePeriod(
                _userSpeedUpCard.refreshTime,
                _userSpeedUpCard.endTime,
                orderToTakeRevenue.refreshTime,
                orderToTakeRevenue.endTime
            );
            uint256 r;
            if (t2 >= block.timestamp) {
                t2 = block.timestamp;
                //2 parts
                uint256 r1 = ((t1 - orderToTakeRevenue.refreshTime) *
                    orderToTakeRevenue.releasPerDay) / secondsInDay;
                if (
                    r1 + orderToTakeRevenue.claimedRevenue <
                    orderToTakeRevenue.orderRevenue
                ) {
                    r += r1;
                } else {
                    uint256 claimRevenue = orderToTakeRevenue.orderRevenue -
                        orderToTakeRevenue.claimedRevenue;
                    _mint(_orderOwner, claimRevenue);
                    orderToTakeRevenue.claimedRevenue = orderToTakeRevenue
                        .orderRevenue;
                    orderToTakeRevenue.refreshTime = block.timestamp;
                    totalclaimedRevenue[_orderOwner] += claimRevenue;
                    activeOrderIndex[_orderOwner][_fieldIndex][0]++;
                    activeOrderIndex[_orderOwner][_fieldIndex][1]--;
                    return;
                }
                uint256 r2 = ((t2 - t1) *
                    (orderToTakeRevenue.releasPerDay +
                        _userSpeedUpCard.speedUpPerDay)) / secondsInDay;
                if (
                    r2 + orderToTakeRevenue.claimedRevenue <
                    orderToTakeRevenue.orderRevenue
                ) {
                    r += r2;
                    _mint(_orderOwner, r);
                    orderToTakeRevenue.claimedRevenue += r;
                    totalclaimedRevenue[_orderOwner] += r;
                    orderToTakeRevenue.refreshTime = block.timestamp;
                    _userSpeedUpCard.refreshTime =
                        _userSpeedUpCard.refreshTime +
                        t2 -
                        t1;
                    return;
                } else {
                    uint256 claimRevenue = orderToTakeRevenue.orderRevenue -
                        orderToTakeRevenue.claimedRevenue;
                    r += claimRevenue;
                    _mint(_orderOwner, r);
                    orderToTakeRevenue.claimedRevenue = orderToTakeRevenue
                        .orderRevenue;
                    orderToTakeRevenue.refreshTime = block.timestamp;
                    totalclaimedRevenue[_orderOwner] += r;
                    activeOrderIndex[_orderOwner][_fieldIndex][0]++;
                    activeOrderIndex[_orderOwner][_fieldIndex][1]--;
                    _userSpeedUpCard.refreshTime =
                        _userSpeedUpCard.refreshTime +
                        (secondsInDay * claimRevenue) /
                        (orderToTakeRevenue.releasPerDay +
                            _userSpeedUpCard.speedUpPerDay);
                    return;
                }
            } else {
                //3parts
                uint256 r1 = ((t1 - orderToTakeRevenue.refreshTime) *
                    orderToTakeRevenue.releasPerDay) / secondsInDay;
                if (
                    r1 + orderToTakeRevenue.claimedRevenue <
                    orderToTakeRevenue.orderRevenue
                ) {
                    r += r1;
                } else {
                    uint256 claimRevenue = orderToTakeRevenue.orderRevenue -
                        orderToTakeRevenue.claimedRevenue;
                    _mint(_orderOwner, claimRevenue);
                    orderToTakeRevenue.claimedRevenue = orderToTakeRevenue
                        .orderRevenue;
                    orderToTakeRevenue.refreshTime = block.timestamp;
                    totalclaimedRevenue[_orderOwner] += claimRevenue;
                    activeOrderIndex[_orderOwner][_fieldIndex][0]++;
                    activeOrderIndex[_orderOwner][_fieldIndex][1]--;
                    return;
                }
                uint256 r2 = ((t2 - t1) *
                    (orderToTakeRevenue.releasPerDay +
                        _userSpeedUpCard.speedUpPerDay)) / secondsInDay;
                if (
                    r2 + orderToTakeRevenue.claimedRevenue <
                    orderToTakeRevenue.orderRevenue
                ) {
                    r += r2;
                    _userSpeedUpCard.refreshTime =
                        _userSpeedUpCard.refreshTime +
                        t2 -
                        t1;
                } else {
                    uint256 claimRevenue = orderToTakeRevenue.orderRevenue -
                        orderToTakeRevenue.claimedRevenue;
                    r += claimRevenue;
                    _mint(_orderOwner, r);
                    orderToTakeRevenue.claimedRevenue = orderToTakeRevenue
                        .orderRevenue;
                    orderToTakeRevenue.refreshTime = block.timestamp;
                    totalclaimedRevenue[_orderOwner] += r;
                    activeOrderIndex[_orderOwner][_fieldIndex][0]++;
                    activeOrderIndex[_orderOwner][_fieldIndex][1]--;
                    _userSpeedUpCard.refreshTime =
                        _userSpeedUpCard.refreshTime +
                        (secondsInDay * claimRevenue) /
                        (orderToTakeRevenue.releasPerDay +
                            _userSpeedUpCard.speedUpPerDay);
                    return;
                }
                uint256 r3 = ((block.timestamp - t2) *
                    orderToTakeRevenue.releasPerDay) / secondsInDay;
                if (
                    orderToTakeRevenue.endTime > block.timestamp &&
                    r3 + orderToTakeRevenue.claimedRevenue <
                    orderToTakeRevenue.orderRevenue
                ) {
                    r += r3;
                    _mint(_orderOwner, r);
                    orderToTakeRevenue.claimedRevenue += r;
                    totalclaimedRevenue[_orderOwner] += r;
                    orderToTakeRevenue.refreshTime = block.timestamp;
                    return;
                } else {
                    uint256 claimRevenue = orderToTakeRevenue.orderRevenue -
                        orderToTakeRevenue.claimedRevenue;
                    r += claimRevenue;
                    _mint(_orderOwner, r);
                    orderToTakeRevenue.claimedRevenue = orderToTakeRevenue
                        .orderRevenue;
                    orderToTakeRevenue.refreshTime = block.timestamp;
                    totalclaimedRevenue[_orderOwner] += r;
                    activeOrderIndex[_orderOwner][_fieldIndex][0]++;
                    activeOrderIndex[_orderOwner][_fieldIndex][1]--;
                    return;
                }
            }
        }
    }

    function revenueCalculate(
        address _revenueOwner
    ) public view returns (uint256) {
        uint256 _revenueCalculate;
        for (uint8 i = 0; i < 6; i++) {
            uint256 _length = activeOrderIndex[_revenueOwner][i][1];
            uint256 _start = activeOrderIndex[_revenueOwner][i][0];
            if (_length == 0) {
                continue;
            }
            SpeedUpCard memory _userSpeedUpCard = userSpeedUpCard[
                _revenueOwner
            ][i];
            for (uint256 j = _start; j < _start + _length; j++) {
                Order memory orderToTakeRevenue = orderBook[_revenueOwner][i][
                    j
                ];
                _revenueCalculate += baseRevenueCalculate(
                    orderToTakeRevenue,
                    _userSpeedUpCard
                );
            }
        }
        return _revenueCalculate;
    }

    function baseRevenueCalculate(
        Order memory orderToTakeRevenue,
        SpeedUpCard memory _userSpeedUpCard
    ) public view returns (uint256) {
        if (_userSpeedUpCard.endTime <= orderToTakeRevenue.refreshTime) {
            _userSpeedUpCard.activeState = false;
        }

        if (_userSpeedUpCard.activeState == false) {
            uint256 revenueNow = ((block.timestamp -
                orderToTakeRevenue.refreshTime) *
                orderToTakeRevenue.releasPerDay) / secondsInDay;
            if (
                orderToTakeRevenue.endTime > block.timestamp &&
                revenueNow + orderToTakeRevenue.claimedRevenue <
                orderToTakeRevenue.orderRevenue
            ) {
                orderToTakeRevenue.claimedRevenue += revenueNow;
                orderToTakeRevenue.refreshTime = block.timestamp;
                return revenueNow;
            } else {
                uint256 claimRevenue = orderToTakeRevenue.orderRevenue -
                    orderToTakeRevenue.claimedRevenue;
                orderToTakeRevenue.claimedRevenue = orderToTakeRevenue
                    .orderRevenue;
                orderToTakeRevenue.refreshTime = block.timestamp;
                return claimRevenue;
            }
        } else {
            uint256 t1;
            uint256 t2;
            (t1, t2) = getTimePeriod(
                _userSpeedUpCard.refreshTime,
                _userSpeedUpCard.endTime,
                orderToTakeRevenue.refreshTime,
                orderToTakeRevenue.endTime
            );
            uint256 r;
            if (t2 >= block.timestamp) {
                t2 = block.timestamp;
                //2 parts
                uint256 r1 = ((t1 - orderToTakeRevenue.refreshTime) *
                    orderToTakeRevenue.releasPerDay) / secondsInDay;
                if (
                    r1 + orderToTakeRevenue.claimedRevenue <
                    orderToTakeRevenue.orderRevenue
                ) {
                    r += r1;
                } else {
                    uint256 claimRevenue = orderToTakeRevenue.orderRevenue -
                        orderToTakeRevenue.claimedRevenue;
                    orderToTakeRevenue.claimedRevenue = orderToTakeRevenue
                        .orderRevenue;
                    orderToTakeRevenue.refreshTime = block.timestamp;

                    return claimRevenue;
                }
                uint256 r2 = ((t2 - t1) *
                    (orderToTakeRevenue.releasPerDay +
                        _userSpeedUpCard.speedUpPerDay)) / secondsInDay;
                if (
                    r2 + orderToTakeRevenue.claimedRevenue <
                    orderToTakeRevenue.orderRevenue
                ) {
                    r += r2;
                    orderToTakeRevenue.claimedRevenue += r;
                    orderToTakeRevenue.refreshTime = block.timestamp;
                    _userSpeedUpCard.refreshTime =
                        _userSpeedUpCard.refreshTime +
                        t2 -
                        t1;
                    return r;
                } else {
                    uint256 claimRevenue = orderToTakeRevenue.orderRevenue -
                        orderToTakeRevenue.claimedRevenue;
                    orderToTakeRevenue.claimedRevenue = orderToTakeRevenue
                        .orderRevenue;
                    orderToTakeRevenue.refreshTime = block.timestamp;

                    _userSpeedUpCard.refreshTime =
                        _userSpeedUpCard.refreshTime +
                        (secondsInDay * claimRevenue) /
                        (orderToTakeRevenue.releasPerDay +
                            _userSpeedUpCard.speedUpPerDay);
                    r += claimRevenue;
                    return r;
                }
            } else {
                //3parts
                uint256 r1 = ((t1 - orderToTakeRevenue.refreshTime) *
                    orderToTakeRevenue.releasPerDay) / secondsInDay;
                if (
                    r1 + orderToTakeRevenue.claimedRevenue <
                    orderToTakeRevenue.orderRevenue
                ) {
                    r += r1;
                } else {
                    uint256 claimRevenue = orderToTakeRevenue.orderRevenue -
                        orderToTakeRevenue.claimedRevenue;
                    orderToTakeRevenue.claimedRevenue = orderToTakeRevenue
                        .orderRevenue;
                    orderToTakeRevenue.refreshTime = block.timestamp;

                    return claimRevenue;
                }
                uint256 r2 = ((t2 - t1) *
                    (orderToTakeRevenue.releasPerDay +
                        _userSpeedUpCard.speedUpPerDay)) / secondsInDay;
                if (
                    r2 + orderToTakeRevenue.claimedRevenue <
                    orderToTakeRevenue.orderRevenue
                ) {
                    r += r2;
                    _userSpeedUpCard.refreshTime =
                        _userSpeedUpCard.refreshTime +
                        t2 -
                        t1;
                } else {
                    uint256 claimRevenue = orderToTakeRevenue.orderRevenue -
                        orderToTakeRevenue.claimedRevenue;
                    r += claimRevenue;
                    orderToTakeRevenue.claimedRevenue = orderToTakeRevenue
                        .orderRevenue;
                    orderToTakeRevenue.refreshTime = block.timestamp;

                    _userSpeedUpCard.refreshTime =
                        _userSpeedUpCard.refreshTime +
                        (secondsInDay * claimRevenue) /
                        (orderToTakeRevenue.releasPerDay +
                            _userSpeedUpCard.speedUpPerDay);
                    return r;
                }
                uint256 r3 = ((block.timestamp - t2) *
                    orderToTakeRevenue.releasPerDay) / secondsInDay;
                if (
                    orderToTakeRevenue.endTime > block.timestamp &&
                    r3 + orderToTakeRevenue.claimedRevenue <
                    orderToTakeRevenue.orderRevenue
                ) {
                    r += r3;
                    orderToTakeRevenue.claimedRevenue += r;
                    orderToTakeRevenue.refreshTime = block.timestamp;
                    return r;
                } else {
                    uint256 claimRevenue = orderToTakeRevenue.orderRevenue -
                        orderToTakeRevenue.claimedRevenue;
                    r += claimRevenue;
                    orderToTakeRevenue.claimedRevenue = orderToTakeRevenue
                        .orderRevenue;
                    orderToTakeRevenue.refreshTime = block.timestamp;
                    return r;
                }
            }
        }
    }

    function applyForSwap(uint256 _usdg) external {
        require(applierState[msg.sender] == 0, "you have an order in applying");
        require(
            balanceOf(msg.sender) >= _usdg &&
                _usdg >= depositUnit &&
                _usdg % depositUnit == 0,
            "Swap Amount should also be times of depositUnit"
        );
        require(
            _usdg + totalSwapRevenue[msg.sender] <=
                totalclaimedRevenue[msg.sender],
            "your swap value should smaller than claimedRevenue"
        );
        _burn(msg.sender, _usdg);

        address _applier = msg.sender;
        uint256 _swapValue = _usdg;
        uint256 _swapTime = block.timestamp;
        uint8 _state = 0; //0 means swapping,1 means passed,2 means rejected;
        SwapOrder memory newSwapOrder = SwapOrder(
            _applier,
            _swapValue,
            _swapTime,
            _state
        );

        swapOrderBook.push(newSwapOrder);
        applierSwapOrderIndex[msg.sender].push(
            activeSwapOrderIndex[0] + activeSwapOrderIndex[1]
        );
        activeSwapOrderIndex[1]++;

        applierState[_applier] = 1;
        emit SwapApply(msg.sender, _usdg);
    }

    //functions for administrator

    function rejectSwapOrder(uint256[] memory _indexs) external onlyOwner {
        uint256 _length = _indexs.length;
        for (uint256 i = 0; i < _length; i++) {
            uint256 _index = _indexs[i];
            require(
                activeSwapOrderIndex[1] > 0,
                "Thier is no active SwapOrder Now"
            );
            require(
                _index >= activeSwapOrderIndex[0] &&
                    _index <=
                    activeSwapOrderIndex[0] + activeSwapOrderIndex[1] - 1,
                "index should be active"
            );
            SwapOrder storage orderTovalid = swapOrderBook[_index];
            orderTovalid.state = 2;
        }
    }

    function executeSwapOrders(uint256 _endIndex) external onlyOwner {
        require(
            activeSwapOrderIndex[1] > 0,
            "Thier is no active SwapOrder Now"
        );
        require(
            _endIndex <= activeSwapOrderIndex[0] + activeSwapOrderIndex[1] - 1,
            "index should be active"
        );
        uint256 _startIndex = activeSwapOrderIndex[0];
        for (uint256 _index = _startIndex; _index < _endIndex + 1; _index++) {
            SwapOrder storage orderToSwap = swapOrderBook[_index];
            address _applier = orderToSwap.applier;
            address _father = father[_applier];
            if (orderToSwap.state == 0) {
                orderToSwap.swapTime = block.timestamp;
                orderToSwap.state = 1;
                uint256 _swapFeeForPlatform = (orderToSwap.swapValue *
                    platformFeeRate) / 100;
                platformFee += _swapFeeForPlatform;
                uint256 _swapFeeForParent = (orderToSwap.swapValue *
                    USDGShareRewardRate) / 100;
                USDGShareReward[_father] += _swapFeeForParent;
                uint256 _swapValue = orderToSwap.swapValue -
                    _swapFeeForPlatform -
                    _swapFeeForParent;
                USDT.transfer(_applier, fixUSDTAmount(_swapValue));
                lockedUSDG += _swapValue;
                totalSwapRevenue[_applier] += _swapValue;
                orderToSwap.state = 1;
                applierState[_applier] = 0;
            } else if (orderToSwap.state == 2) {
                _mint(_applier, orderToSwap.swapValue);
                applierState[_applier] = 0;
            }
        }
        activeSwapOrderIndex[1] =
            activeSwapOrderIndex[1] +
            _startIndex -
            _endIndex -
            1;
        activeSwapOrderIndex[0] = _endIndex + 1;
    }

    function openSwap(uint256 _usdg) external {
        require(openSwapState, "openSwap is not open");
        require(
            balanceOf(msg.sender) >= _usdg &&
                _usdg >= depositUnit &&
                _usdg % depositUnit == 0,
            "Swap Amount should also be times of depositUnit"
        );
        require(
            _usdg + totalSwapRevenue[msg.sender] <=
                totalclaimedRevenue[msg.sender],
            "your swap value should smaller than claimedRevenue"
        );
        _burn(msg.sender, _usdg);
        totalSwapRevenue[msg.sender] += _usdg;
        USDT.transfer(msg.sender, fixUSDTAmount(_usdg));
    }

    //functions for this system
    function takePlatformFee() external onlyOwner {
        USDT.transfer(msg.sender, fixUSDTAmount(platformFee));
        _mint(msg.sender, platformFee);
        platformFee = 0;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (transferState == false) {
            require(
                from == address(0) || to == address(0),
                "transfer is close now,you can applyForSwap"
            );
        }
        require(amount > 0);
    }

    function setTransferState(bool _newState) external onlyOwner {
        transferState = _newState;
    }

    function setOpenSwapState(bool _newState) external onlyOwner {
        openSwapState = _newState;
    }

    function setDepositState(bool _newState) external onlyOwner {
        depositState = _newState;
    }

    function setRevenueRate(uint256 _revenueRate) external onlyOwner {
        revenueRate = _revenueRate;
    }

    function setBaseReleaseDays(uint256 _baseReleaseDays) external onlyOwner {
        baseReleaseDays = _baseReleaseDays;
    }

    function setBaseSpeedupDays(uint256 _baseSpeedupDays) external onlyOwner {
        baseSpeedupDays = _baseSpeedupDays;
    }

    function setDepositUnit(uint256 _depositUnit) external onlyOwner {
        depositUnit = _depositUnit;
    }

    function setUSDTAddress(address _usdt) external onlyOwner {
        USDT = IERC20Upgradeable(_usdt);
    }

    function setSecondsInDay(uint256 _seconds) external onlyOwner {
        secondsInDay = _seconds;
    }

    function setPlatformFeeRate(uint256 _feerate) external onlyOwner {
        platformFeeRate = _feerate;
    }

    function setUSDTShareRewardRate(uint256 _feerate) external onlyOwner {
        USDTShareRewardRate = _feerate;
    }

    function setUSDGShareRewardRate(uint256 _feerate) external onlyOwner {
        USDGShareRewardRate = _feerate;
    }

    function applierSwapOrderIndexLength(
        address _applier
    ) public view returns (uint256) {
        return applierSwapOrderIndex[_applier].length;
    }

    function setOwnerRigistered() external onlyOwner {
        registerState[owner()] = true;
    }

    function fixUSDTAmount(
        uint256 _sendAmount
    ) internal pure returns (uint256 realamount) {
        realamount = _sendAmount / (10 ** 12);
    }
}