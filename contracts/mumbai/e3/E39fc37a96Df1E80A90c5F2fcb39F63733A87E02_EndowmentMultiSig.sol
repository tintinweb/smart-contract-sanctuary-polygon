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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/Address.sol";

library Utils {
  function _execute(address target, uint256 value, bytes memory data) internal {
    string memory errorMessage = "call reverted without message";
    (bool success, bytes memory returndata) = target.call{value: value}(data);
    Address.verifyCallResult(success, returndata, errorMessage);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

abstract contract IMultiSigGeneric is IERC165 {
  /*
   *  Events
   */
  event TransactionConfirmed(address sender, uint256 transactionId);
  event ConfirmationRevoked(address sender, uint256 transactionId);
  event TransactionSubmitted(address sender, uint256 transactionId);
  event TransactionExecuted(uint256 transactionId);
  event Deposit(address sender, uint256 amount);
  event OwnerAdded(address owner);
  event OwnerRemoved(address owner);
  event ApprovalsRequiredChanged(uint256 approvalsRequired);
  event RequireExecutionChanged(bool requireExecution);
  event TransactionExpiryChanged(uint256 transactionExpiry);

  /// @dev Receive function allows to deposit ether.
  receive() external payable virtual;

  /// @dev Fallback function allows to deposit ether.
  fallback() external payable virtual;

  // function initialize(address[] memory owners, uint256 required)
  //     public
  //     virtual;

  /// @dev Allows to add new owners. Transaction has to be sent by wallet.
  /// @param owners Addresses of new owners.
  function addOwners(address[] memory owners) public virtual;

  /// @dev Allows to remove owners. Transaction has to be sent by wallet.
  /// @param owners Addresses of ousted owners.
  function removeOwners(address[] memory owners) public virtual;

  /// @dev Allows to replace an owner with a new owner. Transaction has to be sent by wallet.
  /// @param currOwner Address of owner to be replaced.
  /// @param newOwner Address of new owner.
  function replaceOwner(address currOwner, address newOwner) public virtual;

  /// @dev Allows to change the number of required confirmations. Transaction has to be sent by wallet.
  /// @param approvalsRequired Number of required confirmations.
  function changeApprovalsRequirement(uint256 approvalsRequired) public virtual;

  /// @dev Allows to change whether explicit execution step is needed once the required number of confirmations is met. Transaction has to be sent by wallet.
  /// @param requireExecution Explicit execution step is needed
  function changeRequireExecution(bool requireExecution) public virtual;

  /// @dev Allows to change the expiry time for transactions.
  /// @param _transactionExpiry time that a newly created transaction is valid for
  function changeTransactionExpiry(uint256 _transactionExpiry) public virtual;

  /// @dev Allows an owner to submit and confirm a transaction.
  /// @param destination Transaction target address.
  /// @param value Transaction ether value.
  /// @param data Transaction data payload.
  /// @param metadata Encoded transaction metadata, can contain dynamic content.
  /// @return transactionId transaction ID.
  function submitTransaction(
    address destination,
    uint256 value,
    bytes memory data,
    bytes memory metadata
  ) public virtual returns (uint256 transactionId);

  /// @dev Allows an owner to confirm a transaction.
  /// @param transactionId Transaction ID.
  function confirmTransaction(uint256 transactionId) public virtual;

  /// @dev Allows an owner to revoke a confirmation for a transaction.
  /// @param transactionId Transaction ID.
  function revokeConfirmation(uint256 transactionId) public virtual;

  /// @dev Allows current owners to revoke a confirmation for a non-executed transaction from a removed/non-current owner.
  /// @param transactionId Transaction ID.
  /// @param formerOwner Address of the non-current owner, whos confirmation is being revoked
  function revokeConfirmationOfFormerOwner(
    uint256 transactionId,
    address formerOwner
  ) public virtual;

  /// @dev Allows anyone to execute a confirmed transaction.
  /// @param transactionId Transaction ID.
  function executeTransaction(uint256 transactionId) public virtual;

  /// @dev Returns the confirmation status of a transaction.
  /// @param transactionId Transaction ID.
  /// @return Confirmation status.
  function isConfirmed(uint256 transactionId) public view virtual returns (bool);

  /*
   * Internal functions
   */
  /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
  /// @param destination Transaction target address.
  /// @param value Transaction ether value.
  /// @param data Transaction data payload.
  /// @param metadata Encoded transaction metadata, can contain dynamic content.
  /// @return transactionId Returns transaction ID.
  function addTransaction(
    address destination,
    uint256 value,
    bytes memory data,
    bytes memory metadata
  ) internal virtual returns (uint256 transactionId);

  /*
   * Web3 call functions
   */
  /// @dev Returns number of confirmations of a transaction.
  /// @param transactionId Transaction ID.
  /// @return count
  function getConfirmationCount(uint256 transactionId) public view virtual returns (uint256 count);

  /// @dev Returns status of confirmations of a transaction for a given owner.
  /// @param transactionId Transaction ID.
  /// @param ownerAddr address of an owner
  /// @return bool
  function getConfirmationStatus(
    uint256 transactionId,
    address ownerAddr
  ) public view virtual returns (bool);

  /// @dev Returns whether an address is an active owner.
  /// @return Bool. True if owner is an active owner.
  function getOwnerStatus(address ownerAddr) public view virtual returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./storage.sol";
import {IMultiSigGeneric} from "./interfaces/IMultiSigGeneric.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Utils} from "../lib/utils.sol";

contract MultiSigGeneric is
  StorageMultiSig,
  IMultiSigGeneric,
  ERC165,
  Initializable,
  ReentrancyGuard
{
  /*
   *  Modifiers
   */
  modifier onlyWallet() {
    require(msg.sender == address(this));
    _;
  }

  modifier ownerDoesNotExist(address _owner) {
    require(!isOwner[_owner], "Owner address dne");
    _;
  }

  modifier ownerExists(address _owner) {
    require(isOwner[_owner], "Owner address already exists");
    _;
  }

  modifier transactionExists(uint256 transactionId) {
    require(transactions[transactionId].destination != address(0), "Transaction dne");
    _;
  }

  modifier confirmed(uint256 transactionId, address _owner) {
    require(confirmations[transactionId].confirmationsByOwner[_owner], "Transaction is confirmed");
    _;
  }

  modifier notConfirmed(uint256 transactionId, address _owner) {
    require(
      !confirmations[transactionId].confirmationsByOwner[_owner],
      "Transaction is not confirmed"
    );
    _;
  }

  modifier notExecuted(uint256 transactionId) {
    require(!transactions[transactionId].executed, "Transaction is executed");
    _;
  }

  modifier notExpired(uint256 transactionId) {
    require(transactions[transactionId].expiry > block.timestamp, "Transaction is expired");
    _;
  }

  modifier notNull(address addr) {
    require(addr != address(0), "Address cannot be a zero address");
    _;
  }

  modifier validApprovalsRequirement(uint256 _ownerCount, uint256 _approvalsRequired) {
    require(_approvalsRequired <= _ownerCount && _approvalsRequired != 0);
    _;
  }

  /// @dev Receive function allows to deposit ether.
  receive() external payable override {
    if (msg.value > 0) emit Deposit(msg.sender, msg.value);
  }

  /// @dev Fallback function allows to deposit ether.
  fallback() external payable override {
    if (msg.value > 0) emit Deposit(msg.sender, msg.value);
  }

  /*
   * Public functions
   */
  /// @dev Contract constructor sets initial owners and required number of confirmations.
  /// @param owners List of initial owners.
  /// @param _approvalsRequired Number of required confirmations.
  /// @param _requireExecution setting for if an explicit execution call is required
  function initialize(
    address[] memory owners,
    uint256 _approvalsRequired,
    bool _requireExecution,
    uint256 _transactionExpiry
  ) public virtual initializer validApprovalsRequirement(owners.length, _approvalsRequired) {
    require(owners.length > 0, "Must pass at least one owner address");
    for (uint256 i = 0; i < owners.length; i++) {
      require(!isOwner[owners[i]] && owners[i] != address(0));
      isOwner[owners[i]] = true;
      emit OwnerAdded(owners[i]);
    }
    // set storage variables
    approvalsRequired = _approvalsRequired;
    emit ApprovalsRequiredChanged(_approvalsRequired);

    requireExecution = _requireExecution;
    emit RequireExecutionChanged(requireExecution);

    transactionExpiry = _transactionExpiry;
    emit TransactionExpiryChanged(transactionExpiry);
  }

  /// @dev Allows to add new owners. Transaction has to be sent by wallet.
  /// @param owners Addresses of new owners.
  function addOwners(address[] memory owners) public virtual override onlyWallet {
    require(owners.length > 0, "Empty new owners list passed");
    for (uint256 o = 0; o < owners.length; o++) {
      require(!isOwner[owners[o]], "New owner already exists");
      // increment active owners count by 1
      activeOwnersCount += 1;
      // set the owner address to false in mapping
      isOwner[owners[o]] = true;
      emit OwnerAdded(owners[o]);
    }
  }

  /// @dev Allows to remove owners. Transaction has to be sent by wallet.
  /// @param owners Addresses of removed owners.
  function removeOwners(address[] memory owners) public virtual override onlyWallet {
    require(
      owners.length < activeOwnersCount,
      "Must have at least one owner left after all removals"
    );
    // check that all ousted owners are current, existing owners
    for (uint256 oo = 0; oo < owners.length; oo++) {
      require(isOwner[owners[oo]], "Ousted owner is not a current owner");
      // decrement active owners count by 1
      activeOwnersCount -= 1;
      // set the owner address to false in mapping
      isOwner[owners[oo]] = false;
      emit OwnerRemoved(owners[oo]);
    }
    // adjust the approval threshold downward if we've removed more members than can meet the currently
    // set threshold level. (ex. Prevent 10 owners total needing 15 approvals to execute txs)
    if (approvalsRequired > activeOwnersCount) changeApprovalsRequirement(activeOwnersCount);
  }

  /// @dev Allows to replace an owner with a new owner. Transaction has to be sent by wallet.
  /// @param currOwner Address of current owner to be replaced.
  /// @param newOwner Address of new owner.
  function replaceOwner(
    address currOwner,
    address newOwner
  ) public virtual override onlyWallet ownerExists(currOwner) ownerDoesNotExist(newOwner) {
    isOwner[currOwner] = false;
    isOwner[newOwner] = true;
    emit OwnerRemoved(currOwner);
    emit OwnerAdded(newOwner);
  }

  /// @dev Allows to change the number of required confirmations. Transaction has to be sent by wallet.
  /// @param _approvalsRequired Number of required confirmations.
  function changeApprovalsRequirement(
    uint256 _approvalsRequired
  )
    public
    virtual
    override
    onlyWallet
    validApprovalsRequirement(activeOwnersCount, _approvalsRequired)
  {
    approvalsRequired = _approvalsRequired;
    emit ApprovalsRequiredChanged(_approvalsRequired);
  }

  /// @dev Allows to change whether explicit execution step is needed once the required number of confirmations is met. Transaction has to be sent by wallet.
  /// @param _requireExecution Is an explicit execution step is needed
  function changeRequireExecution(bool _requireExecution) public virtual override onlyWallet {
    requireExecution = _requireExecution;
    emit RequireExecutionChanged(_requireExecution);
  }

  /// @dev Allows to change the expiry time for transactions.
  /// @param _transactionExpiry time that a newly created transaction is valid for
  function changeTransactionExpiry(uint256 _transactionExpiry) public virtual override onlyWallet {
    transactionExpiry = _transactionExpiry;
    emit TransactionExpiryChanged(_transactionExpiry);
  }

  /// @dev Allows an owner to submit and confirm a transaction.
  /// @param destination Transaction target address.
  /// @param value Transaction ether value.
  /// @param data Transaction data payload.
  /// @param metadata Encoded transaction metadata, can contain dynamic content.
  /// @return transactionId transaction ID.
  function submitTransaction(
    address destination,
    uint256 value,
    bytes memory data,
    bytes memory metadata
  ) public virtual override returns (uint256 transactionId) {
    transactionId = addTransaction(destination, value, data, metadata);
    confirmTransaction(transactionId);
  }

  /// @dev Allows an owner to confirm a transaction.
  /// @param transactionId Transaction ID.
  function confirmTransaction(
    uint256 transactionId
  )
    public
    virtual
    override
    nonReentrant
    ownerExists(msg.sender)
    transactionExists(transactionId)
    notConfirmed(transactionId, msg.sender)
    notExpired(transactionId)
  {
    confirmations[transactionId].confirmationsByOwner[msg.sender] = true;
    confirmations[transactionId].count += 1;
    emit TransactionConfirmed(msg.sender, transactionId);
    // if execution is required, do not auto execute
    if (!requireExecution) {
      executeTransaction(transactionId);
    }
  }

  /// @dev Allows an owner to revoke a confirmation for a transaction.
  /// @param transactionId Transaction ID.
  function revokeConfirmation(
    uint256 transactionId
  )
    public
    virtual
    override
    nonReentrant
    ownerExists(msg.sender)
    confirmed(transactionId, msg.sender)
    notExecuted(transactionId)
    notExpired(transactionId)
  {
    confirmations[transactionId].confirmationsByOwner[msg.sender] = false;
    confirmations[transactionId].count -= 1;
    emit ConfirmationRevoked(msg.sender, transactionId);
  }

  /// @dev Allows current owners to revoke a confirmation for a non-executed transaction from a removed/non-current owner.
  /// @param transactionId Transaction ID.
  /// @param formerOwner Address of the non-current owner, whos confirmation is being revoked
  function revokeConfirmationOfFormerOwner(
    uint256 transactionId,
    address formerOwner
  )
    public
    virtual
    override
    nonReentrant
    ownerExists(msg.sender)
    confirmed(transactionId, formerOwner)
    notExecuted(transactionId)
    notExpired(transactionId)
  {
    require(!isOwner[formerOwner], "Attempting to revert confirmation of a current owner");
    confirmations[transactionId].confirmationsByOwner[formerOwner] = false;
    confirmations[transactionId].count -= 1;
    emit ConfirmationRevoked(formerOwner, transactionId);
  }

  /// @dev Allows anyone to execute a confirmed transaction.
  /// @param transactionId Transaction ID.
  function executeTransaction(
    uint256 transactionId
  )
    public
    virtual
    override
    ownerExists(msg.sender)
    confirmed(transactionId, msg.sender)
    notExecuted(transactionId)
    notExpired(transactionId)
  {
    if (isConfirmed(transactionId)) {
      MultiSigStorage.Transaction storage txn = transactions[transactionId];
      txn.executed = true;
      Utils._execute(txn.destination, txn.value, txn.data);
      emit TransactionExecuted(transactionId);
    }
  }

  /// @dev Returns the confirmation status of a transaction.
  /// @param transactionId Transaction ID.
  /// @return Confirmation status.
  function isConfirmed(uint256 transactionId) public view override returns (bool) {
    if (confirmations[transactionId].count >= approvalsRequired) return true;
    return false;
  }

  /// @dev Returns number of confirmations of a transaction.
  /// @param transactionId Transaction ID.
  /// @return count
  function getConfirmationCount(
    uint256 transactionId
  ) public view override transactionExists(transactionId) returns (uint256 count) {
    return confirmations[transactionId].count;
  }

  function getConfirmationStatus(
    uint256 transactionId,
    address ownerAddr
  ) public view override transactionExists(transactionId) returns (bool) {
    return confirmations[transactionId].confirmationsByOwner[ownerAddr];
  }

  /// @dev Returns whether an address is an active owner.
  /// @return Bool. True if owner is an active owner.
  function getOwnerStatus(address ownerAddr) public view override returns (bool) {
    return isOwner[ownerAddr];
  }

  /*
   * Internal functions
   */
  /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
  /// @param destination Transaction target address.
  /// @param value Transaction ether value.
  /// @param data Transaction data payload.
  /// @param metadata Encoded transaction metadata, can contain dynamic content.
  /// @return transactionId Returns transaction ID.
  function addTransaction(
    address destination,
    uint256 value,
    bytes memory data,
    bytes memory metadata
  ) internal virtual override notNull(destination) returns (uint256 transactionId) {
    transactionId = transactionCount;
    transactions[transactionId] = MultiSigStorage.Transaction({
      destination: destination,
      value: value,
      data: data,
      expiry: block.timestamp + transactionExpiry,
      executed: false,
      metadata: metadata
    });
    transactionCount += 1;
    emit TransactionSubmitted(msg.sender, transactionId);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

library MultiSigStorage {
  struct Confirmations {
    mapping(address => bool) confirmationsByOwner;
    uint256 count;
  }

  struct Transaction {
    address destination;
    uint256 value;
    bytes data;
    bool executed;
    uint256 expiry;
    bytes metadata;
  }
}

contract StorageMultiSig {
  mapping(uint256 => MultiSigStorage.Transaction) public transactions;
  mapping(uint256 => MultiSigStorage.Confirmations) public confirmations;
  mapping(address => bool) public isOwner;
  uint256 public transactionExpiry;
  uint256 public activeOwnersCount;
  uint256 public approvalsRequired;
  uint256 public transactionCount;
  bool public requireExecution;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import {MultiSigGeneric} from "../../multisigs/MultiSigGeneric.sol";
import {IEndowmentMultiSigEmitter} from "./interfaces/IEndowmentMultiSigEmitter.sol";
import {MultiSigStorage} from "../../multisigs/storage.sol";
import {Utils} from "../../lib/utils.sol";

/**
 * @notice the endowment multisig contract
 * @dev the endowment multisig contract is a generic multisig contract with a special initialize function
 */
contract EndowmentMultiSig is MultiSigGeneric {
  uint256 public ENDOWMENT_ID;
  address public EMITTER_ADDRESS;

  // @dev overrides the generic multisig initializer and restricted function
  function initialize(address[] memory, uint256, bool, uint256) public override initializer {
    revert("Not Implemented");
  }

  /**
   * @notice initialize the multisig with the endowment id and the endowment multisig emitter address
   * @dev special initialize function for endowment multisig
   * @param _endowmentId the endowment id
   * @param _emitter the endowment multisig emitter address
   * @param _owners the owners of the multisig
   * @param _required the required number of signatures
   * @param _requireExecution the require execution flag
   * @param _transactionExpiry the duration of validity for newly created transactions
   */
  function initialize(
    uint256 _endowmentId,
    address _emitter,
    address[] memory _owners,
    uint256 _required,
    bool _requireExecution,
    uint256 _transactionExpiry
  ) public initializer {
    require(_emitter != address(0), "Invalid Address");
    ENDOWMENT_ID = _endowmentId;
    EMITTER_ADDRESS = _emitter;
    super.initialize(_owners, _required, _requireExecution, _transactionExpiry);
  }

  /// @dev Allows to add new owners. Transaction has to be sent by wallet.
  /// @param owners Addresses of new owners.
  function addOwners(address[] memory owners) public override onlyWallet {
    super.addOwners(owners);
    IEndowmentMultiSigEmitter(EMITTER_ADDRESS).addOwnersEndowment(ENDOWMENT_ID, owners);
  }

  /// @dev Allows to remove owners. Transaction has to be sent by wallet.
  /// @param owners Addresses of removed owners.
  function removeOwners(address[] memory owners) public override onlyWallet {
    super.removeOwners(owners);
    IEndowmentMultiSigEmitter(EMITTER_ADDRESS).removeOwnersEndowment(ENDOWMENT_ID, owners);
  }

  /**
   * @notice overrides the generic multisig replaceOwner function
   * @dev emits the removeOwnerEndowment and addOwnerEndowment events
   * @param currOwner the owner to be replaced
   * @param newOwner the new owner to add
   */
  function replaceOwner(address currOwner, address newOwner) public override {
    super.replaceOwner(currOwner, newOwner);
    IEndowmentMultiSigEmitter(EMITTER_ADDRESS).replaceOwnerEndowment(
      ENDOWMENT_ID,
      currOwner,
      newOwner
    );
  }

  /**
   * @notice overrides the generic multisig changeRequirement function
   * @dev emits the requirementChangeEndowment event
   * @param _approvalsRequired the new required number of signatures
   */
  function changeApprovalsRequirement(uint256 _approvalsRequired) public override {
    super.changeApprovalsRequirement(_approvalsRequired);
    IEndowmentMultiSigEmitter(EMITTER_ADDRESS).approvalsRequirementChangeEndowment(
      ENDOWMENT_ID,
      _approvalsRequired
    );
  }

  /**
   * @notice overrides the generic multisig changeTransactionExpiry function
   * @dev emits the transactionExpiryChangeEndowment event
   * @param _transactionExpiry the new validity for newly created transactions
   */
  function changeTransactionExpiry(uint256 _transactionExpiry) public override {
    super.changeTransactionExpiry(_transactionExpiry);
    IEndowmentMultiSigEmitter(EMITTER_ADDRESS).transactionExpiryChangeEndowment(
      ENDOWMENT_ID,
      _transactionExpiry
    );
  }

  /**
   * @notice overrides the generic multisig changeRequireExecution function
   * @dev emits the requirementChangeEndowment event
   * @param _requireExecution Explicit execution step is needed
   */
  function changeRequireExecution(bool _requireExecution) public override {
    super.changeRequireExecution(_requireExecution);
    IEndowmentMultiSigEmitter(EMITTER_ADDRESS).requireExecutionChangeEndowment(
      ENDOWMENT_ID,
      _requireExecution
    );
  }

  /// @dev Allows an owner to submit and confirm a transaction.
  /// @param destination Transaction target address.
  /// @param value Transaction ether value.
  /// @param data Transaction data payload.
  /// @return transactionId transaction ID.
  function submitTransaction(
    address destination,
    uint256 value,
    bytes memory data,
    bytes memory metadata
  ) public virtual override returns (uint256 transactionId) {
    transactionId = addTransaction(destination, value, data, metadata);
    confirmTransaction(transactionId);
  }

  /**
   * @notice overrides the generic multisig confirmTransaction function
   * @dev emits the confirmEndowment event
   * @param transactionId the transaction id
   */
  function confirmTransaction(uint256 transactionId) public override {
    super.confirmTransaction(transactionId);
    IEndowmentMultiSigEmitter(EMITTER_ADDRESS).confirmEndowment(
      ENDOWMENT_ID,
      msg.sender,
      transactionId
    );
  }

  /**
   * @notice overrides the generic multisig revokeConfirmation function
   * @dev emits the revokeEndowment event
   * @param transactionId the transaction id
   */
  function revokeConfirmation(uint256 transactionId) public override {
    super.revokeConfirmation(transactionId);
    IEndowmentMultiSigEmitter(EMITTER_ADDRESS).revokeEndowment(
      ENDOWMENT_ID,
      msg.sender,
      transactionId
    );
  }

  /**
   * @notice overrides the generic multisig revokeConfirmationOfFormerOwner function
   * @dev emits the revokeEndowment event
   * @param transactionId the transaction id
   * @param formerOwner Address of the non-current owner, whos confirmation is being revoked
   */
  function revokeConfirmationOfFormerOwner(
    uint256 transactionId,
    address formerOwner
  ) public override {
    super.revokeConfirmationOfFormerOwner(transactionId, formerOwner);
    IEndowmentMultiSigEmitter(EMITTER_ADDRESS).revokeEndowment(
      ENDOWMENT_ID,
      formerOwner,
      transactionId
    );
  }

  /**
   * @notice function called when a proposal has to be explicity executed
   * @dev emits the executeEndowment event, overrides underlying execute function
   * @param transactionId the transaction id
   */
  function executeTransaction(
    uint256 transactionId
  )
    public
    override
    ownerExists(msg.sender)
    confirmed(transactionId, msg.sender)
    notExecuted(transactionId)
  {
    if (isConfirmed(transactionId)) {
      MultiSigStorage.Transaction storage txn = transactions[transactionId];
      txn.executed = true;
      Utils._execute(txn.destination, txn.value, txn.data);
      IEndowmentMultiSigEmitter(EMITTER_ADDRESS).executeEndowment(ENDOWMENT_ID, transactionId);
    }
  }

  /**
   * @notice overrides the generic multisig addTransaction function
   * @dev emits the submitEndowment event
   * @param destination the destination of the transaction
   * @param value the value of the transaction
   * @param data the data of the transaction
   * @param metadata Encoded transaction metadata, can contain dynamic content.
   */
  function addTransaction(
    address destination,
    uint256 value,
    bytes memory data,
    bytes memory metadata
  ) internal override returns (uint256 transactionId) {
    transactionId = super.addTransaction(destination, value, data, metadata);
    IEndowmentMultiSigEmitter(EMITTER_ADDRESS).submitEndowment(ENDOWMENT_ID, transactionId);
    return transactionId;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IEndowmentMultiSigEmitter {
  function confirmEndowment(uint256 endowmentId, address sender, uint256 transactionId) external;

  function revokeEndowment(uint256 endowmentId, address sender, uint256 transactionId) external;

  function submitEndowment(uint256 endowmentId, uint256 transactionId) external;

  function executeEndowment(uint256 endowmentId, uint256 transactionId) external;

  function executeFailureEndowment(uint256 endowmentId, uint256 transactionId) external;

  function depositEndowment(uint256 endowmentId, address sender, uint256 value) external;

  function addOwnersEndowment(uint256 endowmentId, address[] memory owners) external;

  function removeOwnersEndowment(uint256 endowmentId, address[] memory owners) external;

  function replaceOwnerEndowment(uint256 endowmentId, address currOwner, address newOwner) external;

  function approvalsRequirementChangeEndowment(
    uint256 endowmentId,
    uint256 approvalsRequired
  ) external;

  function requireExecutionChangeEndowment(uint256 endowmentId, bool requireExecution) external;

  function transactionExpiryChangeEndowment(
    uint256 endowmentId,
    uint256 transactionExpiry
  ) external;

  function createMultisig(
    address multisigAddress,
    uint256 endowmentId,
    address emitter,
    address[] memory owners,
    uint256 required,
    bool requireExecution,
    uint256 transactionExpiry
  ) external;
}