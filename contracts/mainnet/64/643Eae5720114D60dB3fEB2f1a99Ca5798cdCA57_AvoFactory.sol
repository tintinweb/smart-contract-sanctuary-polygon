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
pragma solidity >=0.8.17;

interface AvoCoreStructs {
    /// @notice a pair of a bytes signature and its signer.
    struct SignatureParams {
        ///
        /// @param signature signature, e.g. ECDSA signature for default flow
        bytes signature;
        ///
        /// @param signer signer of the signature, required for smart contract signatures
        address signer;
    }

    /// @notice an executable action, including operation (call or delegateCall), target, data and value
    struct Action {
        ///
        /// @param target the target to execute the actions on
        address target;
        ///
        /// @param data the data to be passed to the call for each target
        bytes data;
        ///
        /// @param value the msg.value to be passed to the call for each target. set to 0 if none
        uint256 value;
        ///
        /// @param operation type of operation to execute:
        /// 0 -> .call; 1 -> .delegateCall, 2 -> flashloan (via .call)
        uint256 operation;
    }

    /// @notice common params for both `cast()` and `castAuthorized()`
    struct CastParams {
        Action[] actions;
        ///
        /// @param id             Required:
        ///                       id for actions, e.g. 0 = CALL, 1 = MIXED (call and delegatecall),
        ///                                           20 = FLASHLOAN_CALL, 21 = FLASHLOAN_MIXED
        uint256 id;
        ///
        /// @param avoSafeNonce   Required:
        ///                       avoSafeNonce to be used for this tx. Must equal the avoSafeNonce value on AvoSafe
        ///                       or alternatively it must be set to -1 to use a non-sequential nonce instead
        int256 avoSafeNonce;
        ///
        /// @param salt           Optional:
        ///                       Salt to customize non-sequential nonce (if `avoSafeNonce` is set to -1)
        bytes32 salt;
        ///
        /// @param source         Optional:
        ///                       Source e.g. referral for this tx
        address source;
        ///
        /// @param metadata       Optional:
        ///                       metadata for future flexibility
        bytes metadata;
    }

    /// @notice `cast()` input params related to forwarding validity
    struct CastForwardParams {
        ///
        /// @param gas            Required:
        ///                       As EIP-2770: an amount of gas limit to set for the execution
        ///                       Protects against potential gas griefing attacks & ensures the relayer sends enough gas
        ///                       See https://ronan.eth.limo/blog/ethereum-gas-dangers/
        uint256 gas;
        ///
        /// @param gasPrice       Optional:
        ///                       Not implemented / used yet
        uint256 gasPrice;
        ///
        /// @param validAfter     Optional:
        ///                       the earliest block timestamp that the request can be forwarded in
        ///                       or 0 if the request is not time-limited to occur after a certain time
        ///                       Protects against relayers executing a certain transaction at an earlier moment
        ///                       not intended by the user, where it might have a completely different effect.
        uint256 validAfter;
        ///
        /// @param validUntil     Optional:
        ///                       Similar to EIP-2770: the latest block timestamp (instead of block number) the request
        ///                       can be forwarded, or 0 if request should be valid forever.
        ///                       Protects against relayers executing a certain transaction at a later moment
        ///                       not intended by the user, where it might have a completely different effect.
        uint256 validUntil;
    }

    /// @notice `castAuthorized()` input params
    struct CastAuthorizedParams {
        ///
        /// @param maxFee         Optional:
        ///                       the maximum fee allowed to be paid for tx execution
        uint256 maxFee;
        ///
        /// @param gasPrice       Optional:
        ///                       Not implemented / used yet
        uint256 gasPrice;
        ///
        /// @param validAfter     Optional:
        ///                       the earliest block timestamp that the request can be executed in
        ///                       or 0 if the request is not time-limited to occur after a certain time
        ///                       Protects against executing a certain transaction at  an earlier moment
        ///                       not intended when signed, where it might have a completely different effect.
        ///                       Has no effect for AvoWallet (Solo), only used for AvoMultisig
        uint256 validAfter;
        ///
        /// @param validUntil     Optional:
        ///                       Similar to EIP-2770: the latest block timestamp (instead of block number) the request
        ///                       is valid for, or 0 if request should be valid forever.
        ///                       Protects against executing a certain transaction at a later moment
        ///                       not intended when signed, where it might have a completely different effect.
        ///                       Has no effect for AvoWallet (Solo), only used for AvoMultisig
        uint256 validUntil;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { AvoMultiSafe } from "./AvoMultiSafe.sol";
import { IAvoWalletV3 } from "./interfaces/IAvoWalletV3.sol";
import { IAvoMultisigV3 } from "./interfaces/IAvoMultisigV3.sol";
import { IAvoVersionsRegistry } from "./interfaces/IAvoVersionsRegistry.sol";
import { IAvoFactory } from "./interfaces/IAvoFactory.sol";
import { IAvoForwarder } from "./interfaces/IAvoForwarder.sol";

abstract contract AvoFactoryErrors {
    /// @notice thrown when trying to deploy an AvoSafe for a smart contract
    error AvoFactory__NotEOA();

    /// @notice thrown when a caller is not authorized to execute a certain action
    error AvoFactory__Unauthorized();

    /// @notice thrown when a method is called with invalid params (e.g. zero address)
    error AvoFactory__InvalidParams();
}

abstract contract AvoFactoryConstants is AvoFactoryErrors, IAvoFactory {
    /// @dev hardcoded AvoSafe creation code. Hardcoding this allows us to enable the optimizer without affecting the
    /// bytecode of the AvoSafe proxy, which would break the deterministic address of previous versions.
    /// @dev in next version, also hardcode the creation code for the avoMultiSafe
    bytes public constant avoSafeCreationCode =
        hex"608060405234801561001057600080fd5b506000803373ffffffffffffffffffffffffffffffffffffffff166040518060400160405280600481526020017f8e7daf690000000000000000000000000000000000000000000000000000000081525060405161006e91906101a5565b6000604051808303816000865af19150503d80600081146100ab576040519150601f19603f3d011682016040523d82523d6000602084013e6100b0565b606091505b50915091506000602082015190508215806100e2575060008173ffffffffffffffffffffffffffffffffffffffff163b145b156100ec57600080fd5b806000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055505050506101bc565b600081519050919050565b600081905092915050565b60005b8381101561016857808201518184015260208101905061014d565b60008484015250505050565b600061017f82610134565b610189818561013f565b935061019981856020860161014a565b80840191505092915050565b60006101b18284610174565b915081905092915050565b60aa806101ca6000396000f3fe608060405273ffffffffffffffffffffffffffffffffffffffff600054167f87e9052a0000000000000000000000000000000000000000000000000000000060003503604f578060005260206000f35b3660008037600080366000845af43d6000803e8060008114606f573d6000f35b3d6000fdfea26469706673582212206b87e9571aaea9ed523b568c544f1e27605a9e60767f9b6c9efbab3ad8293ea864736f6c63430008110033";

    /// @dev cached AvoSafe Bytecode to optimize gas usage
    bytes32 public constant avoSafeBytecode = keccak256(abi.encodePacked(avoSafeCreationCode));

    /// @dev cached AvoSafeMultsig Bytecode to optimize gas usage
    bytes32 public constant avoMultiSafeBytecode = keccak256(abi.encodePacked(type(AvoMultiSafe).creationCode));

    /// @notice  registry holding the valid versions (addresses) for AvoWallet implementation contracts
    ///          The registry is used to verify a valid version before setting a new avoWalletImpl
    ///          as default for new deployments
    IAvoVersionsRegistry public immutable avoVersionsRegistry;

    /// @notice constructor sets the immutable avoVersionsRegistry address
    /// @dev    setting the avoVersionsRegistry on the logic contract at deployment is ok because the
    ///         AvoVersionsRegistry is upgradeable so the address set here is the proxy address
    ///         which really shouldn't change. Even if it should change then worst case
    ///         a new AvoFactory logic contract has to be deployed pointing to a new registry
    constructor(IAvoVersionsRegistry avoVersionsRegistry_) {
        avoVersionsRegistry = avoVersionsRegistry_;

        if (avoSafeBytecode != 0x9aa119706de4bc0b1d341ea3b741a89ce1da096034c271d93473502675bb2c11) {
            revert AvoFactory__InvalidParams();
        }
        // @dev in next version, add the same check for avoMultiSafeBytecode
    }
}

abstract contract AvoFactoryVariables is AvoFactoryConstants, Initializable {
    /// @dev Before variables here are vars from Initializable
    /// uint8 private _initialized;
    /// bool private _initializing;

    /// @notice Avo wallet logic contract address that new AvoSafe deployments point to
    ///         modifiable by AvoVersionsRegistry
    address public avoWalletImpl;

    // 10 bytes empty

    // ----------------------- slot 1 ---------------------------

    /// @notice AvoMultisig logic contract address that new AvoMultiSafe deployments point to
    ///         modifiable by AvoVersionsRegistry
    address public avoMultisigImpl;
}

abstract contract AvoFactoryEvents {
    /// @notice Emitted when a new AvoSafe has been deployed
    event AvoSafeDeployed(address indexed owner, address indexed avoSafe);

    /// @notice Emitted when a new AvoSafe has been deployed with a non-default version
    event AvoSafeDeployedWithVersion(address indexed owner, address indexed avoSafe, address indexed version);

    /// @notice Emitted when a new AvoMultiSafe has been deployed
    event AvoMultiSafeDeployed(address indexed owner, address indexed avoMultiSafe);

    /// @notice Emitted when a new AvoMultiSafe has been deployed with a non-default version
    event AvoMultiSafeDeployedWithVersion(address indexed owner, address indexed avoMultiSafe, address indexed version);
}

abstract contract AvoForwarderCore is AvoFactoryErrors, AvoFactoryConstants, AvoFactoryVariables, AvoFactoryEvents {
    /// @notice constructor sets the immutable avoVersionsRegistry address
    constructor(IAvoVersionsRegistry avoVersionsRegistry_) AvoFactoryConstants(avoVersionsRegistry_) {
        if (address(avoVersionsRegistry_) == address(0)) {
            revert AvoFactory__InvalidParams();
        }

        // Ensure logic contract initializer is not abused by disabling initializing
        // see https://forum.openzeppelin.com/t/security-advisory-initialize-uups-implementation-contracts/15301
        // and https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializing_the_implementation_contract
        _disableInitializers();
    }
}

/// @title      AvoFactory v3.0.0
/// @notice     Deploys AvoSafe contracts at deterministic addresses using Create2
/// @dev        Upgradeable through AvoFactoryProxy
///             To deploy a new version of AvoSafe, the new factory contract must be deployed
///             and AvoFactoryProxy upgraded to that new contract
contract AvoFactory is AvoForwarderCore {
    /***********************************|
    |              MODIFIERS            |
    |__________________________________*/

    /// @notice reverts if owner_ is a contract
    modifier onlyEOA(address owner_) {
        if (Address.isContract(owner_)) {
            revert AvoFactory__NotEOA();
        }
        _;
    }

    /// @notice reverts if msg.sender is not AvoVersionsRegistry
    modifier onlyRegistry() {
        if (msg.sender != address(avoVersionsRegistry)) {
            revert AvoFactory__Unauthorized();
        }
        _;
    }

    /***********************************|
    |    CONSTRUCTOR / INITIALIZERS     |
    |__________________________________*/

    /// @notice constructor sets the immutable avoVersionsRegistry address
    constructor(IAvoVersionsRegistry avoVersionsRegistry_) AvoForwarderCore(avoVersionsRegistry_) {}

    /// @notice initializes the contract
    function initialize() public initializer {}

    /***********************************|
    |            PUBLIC API             |
    |__________________________________*/

    /// @inheritdoc IAvoFactory
    function isAvoSafe(address avoSafe_) external view returns (bool) {
        if (avoSafe_ == address(0)) {
            return false;
        }
        if (Address.isContract(avoSafe_) == false) {
            // can not recognize isAvoSafe when not yet deployed
            return false;
        }

        // get the owner from the AvoSafe
        try IAvoWalletV3(avoSafe_).owner() returns (address owner_) {
            // compute the AvoSafe address for that owner
            address computedAddress_ = computeAddress(owner_);
            if (computedAddress_ == avoSafe_) {
                // computed address for owner is an avoSafe because it matches a computed address
                // which includes the address of this contract itself so it also guarantees the AvoSafe
                // was deployed by the AvoFactory
                return true;
            } else {
                // if it is not a computed address match for the AvoSafe, try for the Multisig too
                computedAddress_ = computeAddressMultisig(owner_);
                return computedAddress_ == avoSafe_;
            }
        } catch {
            // if fetching owner doesn't work, it can not be an AvoSafe
            return false;
        }
    }

    /// @inheritdoc IAvoFactory
    function deploy(address owner_) external onlyEOA(owner_) returns (address deployedAvoSafe_) {
        // deploy AvoSafe deterministically using low level CREATE2 opcode to use hardcoded AvoSafe bytecode
        bytes32 salt_ = _getSalt(owner_);
        bytes memory byteCode_ = avoSafeCreationCode;
        assembly {
            deployedAvoSafe_ := create2(0, add(byteCode_, 0x20), mload(byteCode_), salt_)
        }

        // initialize AvoWallet through proxy with IAvoWallet interface
        IAvoWalletV3(deployedAvoSafe_).initialize(owner_);

        emit AvoSafeDeployed(owner_, deployedAvoSafe_);
    }

    /// @inheritdoc IAvoFactory
    function deployWithVersion(
        address owner_,
        address avoWalletVersion_
    ) external onlyEOA(owner_) returns (address deployedAvoSafe_) {
        avoVersionsRegistry.requireValidAvoWalletVersion(avoWalletVersion_);

        // deploy AvoSafe deterministically using low level CREATE2 opcode to use hardcoded AvoSafe bytecode
        bytes32 salt_ = _getSalt(owner_);
        bytes memory byteCode_ = avoSafeCreationCode;
        assembly {
            deployedAvoSafe_ := create2(0, add(byteCode_, 0x20), mload(byteCode_), salt_)
        }

        // initialize AvoWallet through proxy with IAvoWallet interface
        IAvoWalletV3(deployedAvoSafe_).initializeWithVersion(owner_, avoWalletVersion_);

        emit AvoSafeDeployedWithVersion(owner_, deployedAvoSafe_, avoWalletVersion_);
    }

    function deployMultisig(address owner_) external onlyEOA(owner_) returns (address deployedAvoMultiSafe_) {
        // deploy AvoMultiSafe deterministically using CREATE2 opcode (through specifying salt)
        // Note: because `AvoMultiSafe` bytecode differs from `AvoSafe` bytecode, the deterministic address
        // will be different from the deployed AvoSafes through `deploy` / `deployWithVersion`
        deployedAvoMultiSafe_ = address(new AvoMultiSafe{ salt: _getSaltMultisig(owner_) }());

        // initialize AvoMultisig through proxy with IAvoMultisig interface
        IAvoMultisigV3(deployedAvoMultiSafe_).initialize(owner_);

        emit AvoMultiSafeDeployed(owner_, deployedAvoMultiSafe_);
    }

    function deployMultisigWithVersion(
        address owner_,
        address avoMultisigVersion_
    ) external onlyEOA(owner_) returns (address deployedAvoMultiSafe_) {
        avoVersionsRegistry.requireValidAvoMultisigVersion(avoMultisigVersion_);

        // deploy AvoMultiSafe deterministically using CREATE2 opcode (through specifying salt)
        // Note: because `AvoMultiSafe` bytecode differs from `AvoSafe` bytecode, the deterministic address
        // will be different from the deployed AvoSafes through `deploy()` / `deployWithVersion`
        deployedAvoMultiSafe_ = address(new AvoMultiSafe{ salt: _getSaltMultisig(owner_) }());

        // initialize AvoMultisig through proxy with IAvoMultisig interface
        IAvoMultisigV3(deployedAvoMultiSafe_).initializeWithVersion(owner_, avoMultisigVersion_);

        emit AvoMultiSafeDeployedWithVersion(owner_, deployedAvoMultiSafe_, avoMultisigVersion_);
    }

    /// @inheritdoc IAvoFactory
    function computeAddress(address owner_) public view returns (address computedAddress_) {
        if (Address.isContract(owner_)) {
            // owner of a AvoSafe must be an EOA, if it's a contract return zero address
            return address(0);
        }

        // replicate Create2 address determination logic
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), _getSalt(owner_), avoSafeBytecode));

        // cast last 20 bytes of hash to address
        assembly {
            computedAddress_ := and(hash, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
    }

    /// @inheritdoc IAvoFactory
    function computeAddressMultisig(address owner_) public view returns (address computedAddress_) {
        if (Address.isContract(owner_)) {
            // owner of a AvoMultiSafe must be an EOA, if it's a contract return zero address
            return address(0);
        }

        // replicate Create2 address determination logic
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), _getSaltMultisig(owner_), avoMultiSafeBytecode)
        );

        // cast last 20 bytes of hash to address
        assembly {
            computedAddress_ := and(hash, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
    }

    /***********************************|
    |            ONLY  REGISTRY         |
    |__________________________________*/

    /// @inheritdoc IAvoFactory
    function setAvoWalletImpl(address avoWalletImpl_) external onlyRegistry {
        // do not `registry.requireValidAvoWalletVersion()` because sender is registry anyway
        avoWalletImpl = avoWalletImpl_;
    }

    /// @inheritdoc IAvoFactory
    function setAvoMultisigImpl(address avoMultisigImpl_) external onlyRegistry {
        // do not `registry.requireValidAvoMultisigVersion()` because sender is registry anyway
        avoMultisigImpl = avoMultisigImpl_;
    }

    /***********************************|
    |              INTERNAL             |
    |__________________________________*/

    /// @dev            gets the salt used for deterministic deployment for owner_
    /// @param owner_   AvoSafe owner
    /// @return         the bytes32 (keccak256) salt
    function _getSalt(address owner_) internal pure returns (bytes32) {
        // only owner is used as salt
        // no extra salt is needed because even if another version of AvoFactory would be deployed,
        // deterministic deployments take into account the deployers address (i.e. the factory address)
        return keccak256(abi.encode(owner_));
    }

    /// @dev            gets the salt used for deterministic Multisig deployment for owner_
    /// @param owner_   AvoMultiSafe owner
    /// @return         the bytes32 (keccak256) salt
    function _getSaltMultisig(address owner_) internal pure returns (bytes32) {
        // only owner is used as salt
        // no extra salt is needed because even if another version of AvoFactory would be deployed,
        // deterministic deployments take into account the deployers address (i.e. the factory address)
        return keccak256(abi.encode(owner_));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

/// @title   IAvoSafe
/// @notice  interface to access _avoMultisigImpl on-chain
interface IAvoMultiSafe {
    function _avoMultisigImpl() external view returns (address);
}

/// @title      AvoMultiSafe
/// @notice     Proxy for AvoMultisigs as deployed by the AvoFactory.
///             Basic Proxy with fallback to delegate and address for implementation contract at storage 0x0
/// @dev        If this contract changes then the deployment addresses for new AvoSafes through factory change too!!
///             Relayers might want to pass in version as new param then to forward to the correct factory
contract AvoMultiSafe {
    /// @notice address of the AvoMultisig logic / implementation contract. IMPORTANT: SAME STORAGE SLOT AS FOR PROXY
    /// @dev    _avoMultisigImpl MUST ALWAYS be the first declared variable here in the proxy and in the logic contract
    ///         when upgrading, the storage at memory address 0x0 is upgraded (first slot).
    ///         To reduce deployment costs this variable is internal but can still be retrieved with
    ///         _avoMultisigImpl(), see code and comments in fallback below
    address internal _avoMultisigImpl;

    /// @notice   sets _avoMultisigImpl address, fetching it from msg.sender via avoMultisigImpl()
    /// @dev      avoMultisigImpl_ is not an input param to not influence the deterministic Create2 address!
    constructor() {
        // "\x6d\x9b\x93\x8f" is hardcoded bytes of function selector for avoMultisigImpl()
        (bool success_, bytes memory data_) = msg.sender.call(bytes("\x6d\x9b\x93\x8f"));

        address avoMultisigImpl_;
        assembly {
            // cast last 20 bytes of hash to address
            avoMultisigImpl_ := mload(add(data_, 32))
        }

        if (!success_ || avoMultisigImpl_.code.length == 0) {
            revert();
        }

        _avoMultisigImpl = avoMultisigImpl_;
    }

    /// @notice Delegates the current call to `_avoMultisigImpl` unless _avoMultisigImpl() is called
    ///         if _avoMultisigImpl() is called then the address for _avoMultisigImpl is returned
    /// @dev    Mostly based on OpenZeppelin Proxy.sol
    fallback() external payable {
        assembly {
            // load address avoMultisigImpl_ from storage
            let avoMultisigImpl_ := and(sload(0), 0xffffffffffffffffffffffffffffffffffffffff)

            // first 4 bytes of calldata specify which function to call.
            // if those first 4 bytes == f3b1cd21 (function selector for _avoMultisigImpl()) then we return the _avoMultisigImpl address
            // The value is right padded to 32-bytes with 0s
            if eq(calldataload(0), 0xf3b1cd2100000000000000000000000000000000000000000000000000000000) {
                mstore(0, avoMultisigImpl_) // store address avoMultisigImpl_ at memory address 0x0
                return(0, 0x20) // send first 20 bytes of address at memory address 0x0
            }

            // @dev code below is taken from OpenZeppelin Proxy.sol _delegate function

            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), avoMultisigImpl_, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { IAvoVersionsRegistry } from "./IAvoVersionsRegistry.sol";

interface IAvoFactory {
    /// @notice returns AvoVersionsRegistry (proxy) address
    function avoVersionsRegistry() external view returns (IAvoVersionsRegistry);

    /// @notice returns Avo wallet logic contract address that new AvoSafe deployments point to
    function avoWalletImpl() external view returns (address);

    /// @notice returns AvoMultisig logic contract address that new AvoMultiSafe deployments point to
    function avoMultisigImpl() external view returns (address);

    /// @notice           Checks if a certain address is an AvoSafe instance. only works for already deployed AvoSafes
    /// @param avoSafe_   address to check
    /// @return           true if address is an avoSafe
    function isAvoSafe(address avoSafe_) external view returns (bool);

    /// @notice                    Computes the deterministic address for owner based on Create2
    /// @param owner_              AvoSafe owner
    /// @return computedAddress_   computed address for the contract (AvoSafe)
    function computeAddress(address owner_) external view returns (address computedAddress_);

    /// @notice                      Computes the deterministic Multisig address for owner based on Create2
    /// @param owner_                AvoMultiSafe owner
    /// @return computedAddress_     computed address for the contract (AvoSafe)
    function computeAddressMultisig(address owner_) external view returns (address computedAddress_);

    /// @notice         Deploys an AvoSafe for a certain owner deterministcally using Create2.
    ///                 Does not check if contract at address already exists. AvoForwarder already does that.
    /// @param owner_   AvoSafe owner
    /// @return         deployed address for the contract (AvoSafe)
    function deploy(address owner_) external returns (address);

    /// @notice                    Deploys an AvoSafe with non-default version for an owner deterministcally using Create2.
    ///                            ATTENTION: Only supports AvoWallet version > 2.0.0
    ///                            Does not check if contract at address already exists. AvoForwarder already does that.
    /// @param owner_              AvoSafe owner
    /// @param avoWalletVersion_   Version of AvoWallet logic contract to deploy
    /// @return                    deployed address for the contract (AvoSafe)
    function deployWithVersion(address owner_, address avoWalletVersion_) external returns (address);

    /// @notice         Deploys an AvoMultiSafe for a certain owner deterministcally using Create2.
    ///                 Does not check if contract at address already exists. AvoForwarder already does that.
    /// @param owner_   AvoMultiSafe owner
    /// @return         deployed address for the contract (AvoMultiSafe)
    function deployMultisig(address owner_) external returns (address);

    /// @notice                      Deploys an AvoMultiSafe with non-default version for an owner
    ///                              deterministcally using Create2.
    ///                              Does not check if contract at address already exists. AvoForwarder already does that.
    /// @param owner_                AvoMultiSafe owner
    /// @param avoMultisigVersion_   Version of AvoMultisig logic contract to deploy
    /// @return                      deployed address for the contract (AvoMultiSafe)
    function deployMultisigWithVersion(address owner_, address avoMultisigVersion_) external returns (address);

    /// @notice                     registry can update the current AvoWallet implementation contract set as default
    ///                             `_ avoWalletImpl` logic contract address for new AvoSafe (proxy) deployments
    /// @param avoWalletImpl_       the new avoWalletImpl address
    function setAvoWalletImpl(address avoWalletImpl_) external;

    /// @notice                     registry can update the current AvoMultisig implementation contract set as default
    ///                             `_ avoMultisigImpl` logic contract address for new AvoMultiSafe (proxy) deployments
    /// @param avoMultisigImpl_     the new avoWalletImpl address
    function setAvoMultisigImpl(address avoMultisigImpl_) external;

    /// @notice      returns the byteCode for the AvoSafe contract used for Create2 address computation
    function avoSafeBytecode() external view returns (bytes32);

    /// @notice      returns  the byteCode for the AvoSafe contract used for Create2 address computation
    function avoMultiSafeBytecode() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { IAvoFactory } from "./IAvoFactory.sol";

interface IAvoForwarder {
    /// @notice returns the AvoFactory (proxy) address
    function avoFactory() external view returns (IAvoFactory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { AvoCoreStructs } from "../AvoCore/AvoCoreStructs.sol";

/// @notice base interface without getters for storage variables
interface IAvoMultisigV3Base is AvoCoreStructs {
    /// @notice             initializer called by AvoFactory after deployment
    /// @param owner_       the owner (immutable) of this smart wallet
    function initialize(address owner_) external;

    /// @notice                     initialize contract and set new AvoMultisig version
    /// @param owner_               the owner (immutable) of this smart wallet
    /// @param avoWalletVersion_    version of AvoMultisig logic contract to deploy
    function initializeWithVersion(address owner_, address avoWalletVersion_) external;

    /// @notice             returns the domainSeparator for EIP712 signature
    function domainSeparatorV4() external view returns (bytes32);

    /// @notice               gets the digest (hash) used to verify an EIP712 signature for `cast()`
    /// @dev                  This is also the non-sequential nonce that will be marked as used when the request
    ///                       with the matching `params_` and `forwardParams_` is executed via `cast()`
    /// @param params_        Cast params such as id, avoSafeNonce and actions to execute
    /// @param forwardParams_ Cast params related to validity of forwarding as instructed and signed
    /// @return               bytes32 digest to verify signature
    function getSigDigest(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_
    ) external view returns (bytes32);

    /// @notice                   gets the digest (hash) used to verify an EIP712 signature for `castAuthorized()`
    /// @dev                      This is also the non-sequential nonce that will be marked as used when the request
    ///                           with the matching `params_` and `authorizedParams_` is executed via `castAuthorized()`
    /// @param params_            Cast params such as id, avoSafeNonce and actions to execute
    /// @param authorizedParams_  Cast params related to authorized execution such as maxFee, as signed
    /// @return                   bytes32 digest to verify signature
    function getSigDigestAuthorized(
        CastParams calldata params_,
        CastAuthorizedParams calldata authorizedParams_
    ) external view returns (bytes32);

    /// @notice                   Verify the transaction signature for a `cast()' request is valid and can be executed.
    ///                           This does not guarantuee that the tx will not revert, simply that the params are valid.
    ///                           Does not revert and returns successfully if the input is valid.
    ///                           Reverts if input params, signature or avoSafeNonce etc. are invalid.
    /// @param params_            Cast params such as id, avoSafeNonce and actions to execute
    /// @param forwardParams_     Cast params related to validity of forwarding as instructed and signed
    /// @param signaturesParams_  array of struct for signature and signer:
    ///                           - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                           For smart contract signatures it must fulfill the requirements for the relevant
    ///                           smart contract `.isValidSignature()` EIP1271 logic
    ///                           -signer(Optional): address of the signature signer. Required for smart contract signatures.
    ///                           If defined, it must match the actual signature signer or refer to the smart contract
    ///                           that must be an allowed signer and validates signature via EIP1271
    /// @return                   returns true if everything is valid, otherwise reverts
    function verify(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_,
        SignatureParams[] calldata signaturesParams_
    ) external view returns (bool);

    /// @notice                   Verify the transaction signature for a `castAuthorized()' request is valid and can be executed.
    ///                           This does not guarantuee that the tx will not revert, simply that the params are valid.
    ///                           Does not revert and returns successfully if the input is valid.
    ///                           Reverts if input params, signature or avoSafeNonce etc. are invalid.
    /// @param params_            Cast params such as id, avoSafeNonce and actions to execute
    /// @param authorizedParams_  Cast params related to authorized execution such as maxFee, as signed
    /// @param signaturesParams_  array of struct for signature and signer:
    ///                           - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                           For smart contract signatures it must fulfill the requirements for the relevant
    ///                           smart contract `.isValidSignature()` EIP1271 logic
    ///                           -signer(Optional): address of the signature signer. Required for smart contract signatures.
    ///                           If defined, it must match the actual signature signer or refer to the smart contract
    ///                           that must be an allowed signer and validates signature via EIP1271
    /// @return                   returns true if everything is valid, otherwise reverts
    function verifyAuthorized(
        CastParams calldata params_,
        CastAuthorizedParams calldata authorizedParams_,
        SignatureParams[] calldata signaturesParams_
    ) external view returns (bool);

    /// @notice                   executes arbitrary `actions_` with a valid signature executable by AvoForwarder
    ///                           if one action fails the transaction doesn't revert, instead emits the `CastFailed` event.
    ///                           in that case, all previous actions are reverted. On success, emits CastExecuted event.
    /// @dev                      validates EIP712 signature then executes each action via .call or .delegatecall
    /// @param params_            Cast params such as id, avoSafeNonce and actions to execute
    /// @param forwardParams_     Cast params related to validity of forwarding as instructed and signed
    /// @param signaturesParams_  array of struct for signature and signer:
    ///                           - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                           For smart contract signatures it must fulfill the requirements for the relevant
    ///                           smart contract `.isValidSignature()` EIP1271 logic
    ///                           -signer(Optional): address of the signature signer. Required for smart contract signatures.
    ///                           If defined, it must match the actual signature signer or refer to the smart contract
    ///                           that must be an allowed signer and validates signature via EIP1271
    /// @return success           true if all actions were executed succesfully, false otherwise.
    /// @return revertReason      revert reason if one of the actions fails
    function cast(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_,
        SignatureParams[] calldata signaturesParams_
    ) external payable returns (bool success, string memory revertReason);

    /// @notice                   executes arbitrary `actions_` through authorized tx sent with valid signatures.
    ///                           Includes a fee to be paid in native network gas currency, depends on registry feeConfig
    ///                           if one action fails the transaction doesn't revert, instead emits the `CastFailed` event.
    ///                           in that case, all previous actions are reverted. On success, emits CastExecuted event.
    /// @dev                      executes a .call or .delegateCall for every action (depending on params)
    /// @param params_            Cast params such as id, avoSafeNonce and actions to execute
    /// @param authorizedParams_  Cast params related to authorized execution such as maxFee, as signed
    /// @param signaturesParams_  array of struct for signature and signer:
    ///                           - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                           For smart contract signatures it must fulfill the requirements for the relevant
    ///                           smart contract `.isValidSignature()` EIP1271 logic
    ///                           -signer(Optional): address of the signature signer. Required for smart contract signatures.
    ///                           If defined, it must match the actual signature signer or refer to the smart contract
    ///                           that must be an allowed signer and validates signature via EIP1271
    /// @return success           true if all actions were executed succesfully, false otherwise.
    /// @return revertReason      revert reason if one of the actions fails
    function castAuthorized(
        CastParams calldata params_,
        CastAuthorizedParams calldata authorizedParams_,
        SignatureParams[] calldata signaturesParams_
    ) external payable returns (bool success, string memory revertReason);

    /// @notice  checks if an address `signer_` is an allowed signer (returns true if allowed)
    function isSigner(address signer_) external view returns (bool);

    /// @notice  returns allowed signers on AvoMultisig wich can trigger actions
    ///          if reaching quorum of `requiredSigners` (include owner)
    function signers() external view returns (address[] memory signers);
}

/// @notice full interface with some getters for storage variables
interface IAvoMultisigV3 is IAvoMultisigV3Base {
    /// @notice             AvoMultisig Owner
    function owner() external view returns (address);

    /// @notice             Domain separator name for signatures
    function DOMAIN_SEPARATOR_NAME() external view returns (string memory);

    /// @notice             Domain separator version for signatures
    function DOMAIN_SEPARATOR_VERSION() external view returns (string memory);

    /// @notice             incrementing nonce for each valid tx executed (to ensure unique)
    function avoSafeNonce() external view returns (uint88);

    /// @notice             returns the number of allowed signers
    function signersCount() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface IAvoFeeCollector {
    /// @notice FeeConfig params used to determine the fee
    struct FeeConfig {
        /// @param feeCollector address that the fee should be paid to
        address payable feeCollector;
        /// @param mode current fee mode: 0 = percentage fee (gas cost markup); 1 = static fee (better for L2)
        uint8 mode;
        /// @param fee current fee amount:
        // for mode percentage: fee in 1e6 percentage (1e8 = 100%, 1e6 = 1%);
        // for static mode: absolute amount in native gas token to charge (max value 30_9485_009,821345068724781055 in 1e18)
        uint88 fee;
    }

    /// @notice calculates the fee for an AvoSafe (msg.sender) transaction `gasUsed_` based on fee configuration
    /// @param gasUsed_ amount of gas used, required if mode is percentage. not used if mode is static fee.
    /// @return feeAmount_    calculate fee amount to be paid
    /// @return feeCollector_ address to send the fee to
    function calcFee(uint256 gasUsed_) external view returns (uint256 feeAmount_, address payable feeCollector_);
}

interface IAvoVersionsRegistry is IAvoFeeCollector {
    /// @notice                   checks if an address is listed as allowed AvoWallet version and reverts if not
    /// @param avoWalletVersion_  address of the Avo wallet logic contract to check
    function requireValidAvoWalletVersion(address avoWalletVersion_) external view;

    /// @notice                      checks if an address is listed as allowed AvoForwarder version
    ///                              and reverts if it is not
    /// @param avoForwarderVersion_  address of the AvoForwarder logic contract to check
    function requireValidAvoForwarderVersion(address avoForwarderVersion_) external view;

    /// @notice                     checks if an address is listed as allowed AvoMultisig version and reverts if not
    /// @param avoMultisigVersion_  address of the AvoMultisig logic contract to check
    function requireValidAvoMultisigVersion(address avoMultisigVersion_) external view;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { AvoCoreStructs } from "../AvoCore/AvoCoreStructs.sol";

/// @notice base interface without getters for storage variables
interface IAvoWalletV3Base is AvoCoreStructs {
    /// @notice             initializer called by AvoFactory after deployment
    /// @param owner_       the owner (immutable) of this smart wallet
    function initialize(address owner_) external;

    /// @notice                     initialize contract and set new AvoWallet version
    /// @param owner_               the owner (immutable) of this smart wallet
    /// @param avoWalletVersion_    version of AvoWallet logic contract to deploy
    function initializeWithVersion(address owner_, address avoWalletVersion_) external;

    /// @notice             returns the domainSeparator for EIP712 signature
    function domainSeparatorV4() external view returns (bytes32);

    /// @notice               returns non-sequential nonce that will be marked as used when the request with the matching
    ///                       `params_` and `authorizedParams_` is executed via `castAuthorized()`
    /// @param params_        Cast params such as id, avoSafeNonce and actions to execute
    /// @param authorizedParams_   Cast params related to execution through owner such as maxFee
    /// @return               bytes32 non sequential nonce
    function nonSequentialNonceAuthorized(
        CastParams calldata params_,
        CastAuthorizedParams calldata authorizedParams_
    ) external view returns (bytes32);

    /// @notice               gets the digest (hash) used to verify an EIP712 signature
    /// @dev                  This is also the non-sequential nonce that will be marked as used when the request
    ///                       with the matching `params_` and `forwardParams_` is executed via `cast()`
    /// @param params_        Cast params such as id, avoSafeNonce and actions to execute
    /// @param forwardParams_ Cast params related to validity of forwarding as instructed and signed
    /// @return               bytes32 digest to verify signature
    function getSigDigest(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_
    ) external view returns (bytes32);

    /// @notice                 Verify the transaction signature is valid and can be executed.
    ///                         This does not guarantuee that the tx will not revert, simply that the params are valid.
    ///                         Does not revert and returns successfully if the input is valid.
    ///                         Reverts if input params, signature or avoSafeNonce etc. are invalid.
    /// @param params_          Cast params such as id, avoSafeNonce and actions to execute
    /// @param forwardParams_   Cast params related to validity of forwarding as instructed and signed
    /// @param signatureParams_ struct for signature and signer:
    ///                         - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                         For smart contract signatures it must fulfill the requirements for the relevant
    ///                         smart contract `.isValidSignature()` EIP1271 logic
    ///                         -signer(Optional): address of the signature signer. Required for smart contract signatures.
    ///                         If defined, it must match the actual signature signer or refer to the smart contract
    ///                         that must be an allowed authority and validates signature via EIP1271
    /// @return                 returns true if everything is valid, otherwise reverts
    function verify(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_,
        SignatureParams calldata signatureParams_
    ) external view returns (bool);

    /// @notice                 executes arbitrary `actions_` with a valid signature
    ///                         if one action fails the transaction doesn't revert, instead emits the `CastFailed` event.
    ///                         in that case, all previous actions are reverted. On success, emits CastExecuted event.
    /// @dev                    validates EIP712 signature then executes each action via .call or .delegatecall
    /// @param params_          Cast params such as id, avoSafeNonce and actions to execute
    /// @param forwardParams_   Cast params related to validity of forwarding as instructed and signed
    /// @param signatureParams_ struct for signature and signer:
    ///                         - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                         For smart contract signatures it must fulfill the requirements for the relevant
    ///                         smart contract `.isValidSignature()` EIP1271 logic
    ///                         -signer(Optional): address of the signature signer. Required for smart contract signatures.
    ///                         If defined, it must match the actual signature signer or refer to the smart contract
    ///                         that must be an allowed authority and validates signature via EIP1271
    /// @return success         true if all actions were executed succesfully, false otherwise.
    /// @return revertReason    revert reason if one of the actions fails
    function cast(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_,
        SignatureParams calldata signatureParams_
    ) external payable returns (bool success, string memory revertReason);

    /// @notice                 executes arbitrary `actions_` through authorized tx sent by owner.
    ///                         Includes a fee to be paid in native network gas currency, depends on registry feeConfig
    ///                         if one action fails the transaction doesn't revert, instead emits the `CastFailed` event.
    ///                         in that case, all previous actions are reverted. On success, emits CastExecuted event.
    /// @dev                    executes a .call or .delegateCall for every action (depending on params)
    /// @param params_          Cast params such as id, avoSafeNonce and actions to execute
    /// @param authorizedParams_     Cast params related to execution through owner such as maxFee
    /// @return success         true if all actions were executed succesfully, false otherwise.
    /// @return revertReason    revert reason if one of the actions fails
    function castAuthorized(
        CastParams calldata params_,
        CastAuthorizedParams calldata authorizedParams_
    ) external payable returns (bool success, string memory revertReason);

    /// @notice             checks if an address `authority` is an allowed authority (returns true if allowed)
    function isAuthority(address authority_) external view returns (bool);
}

/// @notice full interface with some getters for storage variables
interface IAvoWalletV3 is IAvoWalletV3Base {
    /// @notice             AvoWallet Owner
    function owner() external view returns (address);

    /// @notice             Domain separator name for signatures
    function DOMAIN_SEPARATOR_NAME() external view returns (string memory);

    /// @notice             Domain separator version for signatures
    function DOMAIN_SEPARATOR_VERSION() external view returns (string memory);

    /// @notice             incrementing nonce for each valid tx executed (to ensure unique)
    function avoSafeNonce() external view returns (uint88);
}