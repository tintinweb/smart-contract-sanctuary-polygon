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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AngelCoreStruct} from "../struct.sol";

library AccountMessages {
    struct CreateEndowmentRequest {
        address owner; // address that originally setup the endowment account
        bool withdrawBeforeMaturity; // endowment allowed to withdraw funds from locked acct before maturity date
        uint256 maturityTime; // datetime int of endowment maturity
        uint256 maturityHeight; // block equiv of the maturity_datetime
        string name; // name of the Endowment
        AngelCoreStruct.Categories categories; // SHOULD NOT be editable for now (only the Config.owner, ie via the Gov contract or AP CW3 Multisig can set/update)
        uint256 tier; // SHOULD NOT be editable for now (only the Config.owner, ie via the Gov contract or AP CW3 Multisig can set/update)
        AngelCoreStruct.EndowmentType endow_type;
        string logo;
        string image;
        // AngelCoreStruct.Member[] cw4_members;
        address[] cw4_members;
        bool kycDonorsOnly;
        AngelCoreStruct.Threshold cw3Threshold;
        AngelCoreStruct.Duration cw3MaxVotingPeriod;
        address[] whitelistedBeneficiaries;
        address[] whitelistedContributors;
        uint256 splitMax;
        uint256 splitMin;
        uint256 splitDefault;
        AngelCoreStruct.EndowmentFee earningsFee;
        AngelCoreStruct.EndowmentFee withdrawFee;
        AngelCoreStruct.EndowmentFee depositFee;
        AngelCoreStruct.EndowmentFee aumFee;
        AngelCoreStruct.DaoSetup dao;
        bool createDao;
        uint256 proposalLink;
        AngelCoreStruct.SettingsController settingsController;
        uint256 parent;
        address[] maturityWhitelist;
        bool ignoreUserSplits;
        AngelCoreStruct.SplitDetails splitToLiquid;
    }

    struct UpdateEndowmentSettingsRequest {
        uint256 id;
        bool donationMatchActive;
        address[] whitelistedBeneficiaries;
        address[] whitelistedContributors;
        address[] maturity_whitelist_add;
        address[] maturity_whitelist_remove;
        AngelCoreStruct.SplitDetails splitToLiquid;
        bool ignoreUserSplits;
    }
    struct UpdateEndowmentControllerRequest {
        uint256 id;
        AngelCoreStruct.SettingsPermission endowmentController;
        AngelCoreStruct.SettingsPermission name;
        AngelCoreStruct.SettingsPermission image;
        AngelCoreStruct.SettingsPermission logo;
        AngelCoreStruct.SettingsPermission categories;
        AngelCoreStruct.SettingsPermission kycDonorsOnly;
        AngelCoreStruct.SettingsPermission splitToLiquid;
        AngelCoreStruct.SettingsPermission ignoreUserSplits;
        AngelCoreStruct.SettingsPermission whitelistedBeneficiaries;
        AngelCoreStruct.SettingsPermission whitelistedContributors;
        AngelCoreStruct.SettingsPermission maturityWhitelist;
        AngelCoreStruct.SettingsPermission earningsFee;
        AngelCoreStruct.SettingsPermission depositFee;
        AngelCoreStruct.SettingsPermission withdrawFee;
        AngelCoreStruct.SettingsPermission aumFee;
    }

    struct UpdateEndowmentStatusRequest {
        uint256 endowmentId;
        uint256 status;
        AngelCoreStruct.Beneficiary beneficiary;
    }

    struct UpdateEndowmentDetailsRequest {
        uint256 id; /// u32,
        address owner; /// Option<String>,
        bool kycDonorsOnly; /// Option<bool>,
        AngelCoreStruct.EndowmentType endow_type; /// Option<String>,
        string name; /// Option<String>,
        AngelCoreStruct.Categories categories; /// Option<Categories>,
        uint256 tier; /// Option<u8>,
        string logo; /// Option<String>,
        string image; /// Option<String>,
        AngelCoreStruct.RebalanceDetails rebalance;
    }

    struct Strategy {
        string vault; // Vault SC Address
        uint256 percentage; // percentage of funds to invest
    }

    struct UpdateProfileRequest {
        uint256 id;
        string overview;
        string url;
        string registrationNumber;
        string countryOfOrigin;
        string streetAddress;
        string contactEmail;
        string facebook;
        string twitter;
        string linkedin;
        uint16 numberOfEmployees;
        string averageAnnualBudget;
        string annualRevenue;
        string charityNavigatorRating;
    }

    ///TODO: response struct should be below this

    struct ConfigResponse {
        address owner;
        string version;
        address registrarContract;
    }

    struct StateResponse {
        AngelCoreStruct.DonationsReceived donationsReceived;
        bool closingEndowment;
        AngelCoreStruct.Beneficiary closingBeneficiary;
    }

    struct EndowmentBalanceResponse {
        AngelCoreStruct.BalanceInfo tokensOnHand; //: BalanceInfo,
        address[] invested_locked_string; //: Vec<(String, Uint128)>,
        uint128[] invested_locked_amount;
        address[] invested_liquid_string; //: Vec<(String, Uint128)>,
        uint128[] invested_liquid_amount;
    }

    struct EndowmentEntry {
        uint256 id; // u32,
        address owner; // String,
        AngelCoreStruct.EndowmentStatus status; // EndowmentStatus,
        AngelCoreStruct.EndowmentType endow_type; // EndowmentType,
        string name; // Option<String>,
        string logo; // Option<String>,
        string image; // Option<String>,
        AngelCoreStruct.Tier tier; // Option<Tier>,
        AngelCoreStruct.Categories categories; // Categories,
        string proposalLink; // Option<u64>,
    }

    struct EndowmentListResponse {
        EndowmentEntry[] endowments;
    }

    struct ProfileResponse {
        string name; // String,
        string overview; // String,
        AngelCoreStruct.Categories categories; // Categories,
        uint256 tier; // Option<u8>,
        string logo; // Option<String>,
        string image; // Option<String>,
        string url; // Option<String>,
        string registrationNumber; // Option<String>,
        string countryOfOrigin; // Option<String>,
        string streetAddress; // Option<String>,
        string contactEmail; // Option<String>,
        AngelCoreStruct.SocialMedialUrls socialMediaUrls; // SocialMedialUrls,
        uint16 numberOfEmployees; // Option<u16>,
        string averageAnnualBudget; // Option<String>,
        string annualRevenue; // Option<String>,
        string charityNavigatorRating; // Option<String>,
    }

    struct EndowmentDetailsResponse {
        address owner; //: Addr,
        address dao;
        address daoToken;
        string description;
        AngelCoreStruct.AccountStrategies strategies;
        AngelCoreStruct.EndowmentStatus status;
        AngelCoreStruct.EndowmentType endow_type;
        uint256 maturityTime;
        AngelCoreStruct.OneOffVaults oneoffVaults;
        AngelCoreStruct.RebalanceDetails rebalance;
        address donationMatchContract;
        bool kycDonorsOnly;
        address[] maturityWhitelist;
        bool depositApproved;
        bool withdrawApproved;
        uint256 pendingRedemptions;
        string logo;
        string image;
        string name;
        AngelCoreStruct.Categories categories;
        uint256 tier;
        uint256 copycatStrategy;
        uint256 proposalLink;
        uint256 parent;
        AngelCoreStruct.SettingsController settingsController;
    }

    struct DepositRequest {
        uint256 id;
        uint256 lockedPercentage;
        uint256 liquidPercentage;
    }

    struct UpdateEndowmentFeeRequest {
        uint256 id;
        AngelCoreStruct.EndowmentFee earningsFee;
        AngelCoreStruct.EndowmentFee depositFee;
        AngelCoreStruct.EndowmentFee withdrawFee;
        AngelCoreStruct.EndowmentFee aumFee;
    }

    enum DonationMatchEnum {
        HaloTokenReserve,
        Cw20TokenReserve
    }

    struct DonationMatchData {
        address reserveToken;
        address uniswapFactory;
        uint24 poolFee;
    }

    struct DonationMatch {
        DonationMatchEnum enumData;
        DonationMatchData data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

//Libraries
import "./storage.sol";
import {AngelCoreStruct} from "../struct.sol";
import {Array} from "../../lib/array.sol";
import {IRegistrar} from "../registrar/interface/IRegistrar.sol";
import {RegistrarStorage} from "../registrar/storage.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IndexFundMessage} from "./message.sol";
import {AccountMessages} from "../accounts/message.sol";
import {Validator} from "../registrar/lib/validator.sol";
import {AddressArray} from "../../lib/address/array.sol";
import {Array} from "../../lib/array.sol";
import {Validator} from "../registrar/lib/validator.sol";
import {Utils} from "../../lib/utils.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

// TODO: Edit Query functions with start and limit to optimise the size of data being returned

/**
 * @title IndexFund
 * @notice User can deposit/donate to a collection of endowments (index funds) through this contract
 * @dev IndexFund is a contract that manages the funds of the angelcore platform
 * It is responsible for creating new funds, adding members to funds, and
 * distributing funds to members
 */
contract IndexFund is StorageIndexFund, ReentrancyGuard, Initializable {
    event OwnerUpdated(address newOwner);
    event RegistrarUpdated(address newRegistrar);
    event ConfigUpdated(IndexFundStorage.Config config);
    event AllianceMemberAdded(address member);
    event AllianceMemberRemoved(address member);
    event IndexFundCreated(uint256 id, AngelCoreStruct.IndexFund fund);
    event IndexFundRemoved(uint256 id);
    event MemberRemoved(uint256 fundId, uint256 memberId);
    event MemberAdded(uint256 fundId, uint256 memberId);
    event DonationMessagesUpdated(IndexFundStorage.DonationMessages messages);
    event UpdateActiveFund(uint256 fundId);
    event UpdateIndexFundState(IndexFundStorage._State state);
    uint256 maxLimit;
    uint256 defaultLimit;

    using SafeMath for uint256;

    /**
     * @notice Initializer function for index fund contract, to be called when proxy is deployed
     * @dev This function is called by deployer only once at the time of initialization
     * @param curDetails IndexFundMessage.InstantiateMessage
     */
    function initIndexFund(
        IndexFundMessage.InstantiateMessage memory curDetails
    ) public initializer {
        require(
            curDetails.registrarContract != address(0),
            "invalid registrar address"
        );

        maxLimit = 30;
        defaultLimit = 10;

        require(!state.initIndexFund, "AlreadyInitilized");
        state.initIndexFund = true;

        state.config = IndexFundStorage.Config({
            owner: msg.sender,
            registrarContract: curDetails.registrarContract,
            fundRotation: curDetails.fundRotation,
            fundMemberLimit: curDetails.fundMemberLimit,
            fundingGoal: curDetails.fundingGoal,
            alliance_members: new address[](0)
        });
        emit ConfigUpdated(state.config);

        state.state = IndexFundStorage._State({
            totalFunds: 0,
            activeFund: 0,
            nextFundId: 1,
            round_donations: 0,
            nextRotationBlock: block.number + state.config.fundRotation
        });
        emit UpdateIndexFundState(state.state);
    }

    /**
     * @notice function to update ownder of the contract
     * @dev can be called by current owner to set new owner
     * @param newOwner address of new owner
     */
    function updateOwner(address newOwner) public nonReentrant returns (bool) {
        if (msg.sender != state.config.owner) {
            revert("Unauthorized");
        }

        require(newOwner != address(0), "invalid input address");

        state.config.owner = newOwner;
        emit OwnerUpdated(newOwner);
        return true;
    }

    /**
     * @notice function to update registrar contract address
     * @dev can be called by current owner to set new registrar contract address
     * @param newRegistrar address of new registrar contract
     */
    function updateRegistrar(
        address newRegistrar
    ) public nonReentrant returns (bool) {
        if (msg.sender != state.config.owner) {
            revert("Unauthorized");
        }

        require(newRegistrar != address(0), "invalid input address");

        state.config.registrarContract = newRegistrar;
        emit RegistrarUpdated(newRegistrar);
        return true;
    }

    /**
     * @notice function to update config of index fund
     * @dev can be called by current owner to set new config
     * @param curDetails IndexFundMessage.UpdateConfigMessage
     */
    function updateConfig(
        IndexFundMessage.UpdateConfigMessage memory curDetails
    ) public nonReentrant returns (bool) {
        if (msg.sender != state.config.owner) {
            revert("Unauthorized");
        }

        if (curDetails.fundingGoal != 0) {
            if (curDetails.fundingGoal < state.state.round_donations) {
                revert("Invalid Inputs");
            }
            state.config.fundingGoal = curDetails.fundingGoal;
        } else {
            state.config.fundingGoal = 0;
        }

        state.config.fundRotation = curDetails.fundRotation;
        state.config.fundMemberLimit = curDetails.fundMemberLimit;
        emit ConfigUpdated(state.config);
        return true;
    }

    /**
     * @notice function to update alliance member list
     * @dev can be called by current owner to add/remove members from alliance member list
     * @param addr address of member to be added/removed
     * @param action string to indicate add/remove
     */
    function updateAllianceMemberList(
        address addr,
        string memory action
    ) public nonReentrant returns (bool) {
        if (msg.sender != state.config.owner) {
            revert("Unauthorized");
        }

        if (!Validator.addressChecker(addr)) {
            revert("Invalid Address");
        }

        if (Validator.compareStrings(action, "add")) {
            uint256 curNone;
            bool indexFound;
            (curNone, indexFound) = AddressArray.indexOf(
                state.config.alliance_members,
                addr
            );
            if (!indexFound) {
                state.config.alliance_members.push(addr);
                emit AllianceMemberAdded(addr);
            }
        } else if (Validator.compareStrings(action, "remove")) {
            uint256 delIndex;
            bool indexFound;
            (delIndex, indexFound) = AddressArray.indexOf(
                state.config.alliance_members,
                addr
            );

            if (indexFound) {
                state.config.alliance_members = AddressArray.remove(
                    state.config.alliance_members,
                    delIndex
                );
                emit AllianceMemberRemoved(addr);
            }
        } else {
            revert("Invalid Action");
        }
        return true;
    }

    /**
     * @notice function to create index fund
     * @dev can be called by current owner to create index fund
     * @param name name of index fund
     * @param description description of index fund
     * @param members array of members of index fund
     * @param rotatingFund boolean to indicate if index fund is rotating fund
     * @param splitToLiquid split of index fund to liquid fund
     * @param expiryTime expiry time of index fund
     * @param expiryHeight expiry height of index fund
     */
    function createIndexFund(
        string memory name,
        string memory description,
        uint256[] memory members,
        bool rotatingFund,
        uint256 splitToLiquid,
        uint256 expiryTime,
        uint256 expiryHeight
    ) public nonReentrant returns (bool) {
        if (msg.sender != state.config.owner) {
            revert("Unauthorized");
        }

        require(splitToLiquid <= 100, "invalid split");

        state.FUND[state.state.nextFundId] = AngelCoreStruct.IndexFund({
            id: state.state.nextFundId,
            name: name,
            description: description,
            members: members,
            rotatingFund: rotatingFund,
            splitToLiquid: splitToLiquid,
            expiryTime: expiryTime,
            expiryHeight: expiryHeight
        });

        emit IndexFundCreated(
            state.state.nextFundId,
            state.FUND[state.state.nextFundId]
        );

        if (state.FUND_LIST.length == 0) {
            state.state.activeFund = state.state.nextFundId;
            emit UpdateActiveFund(state.state.activeFund);
        }

        state.FUND_LIST.push(state.state.nextFundId);

        state.state.totalFunds += 1;
        state.state.nextFundId += 1;

        return true;
    }

    /**
     * @notice function to remove index fund
     * @dev can be called by current owner to remove an index fund
     * @param fundId id of index fund to be removed
     */
    function removeIndexFund(
        uint256 fundId
    ) public nonReentrant returns (bool) {
        if (msg.sender != state.config.owner) {
            revert("Unauthorized");
        }

        if (state.state.activeFund == fundId) {
            state.state.activeFund = rotateFund(
                fundId,
                block.number,
                block.timestamp
            );
            emit UpdateActiveFund(state.state.activeFund);
        }
        state.state.totalFunds -= 1;

        uint256 index = state.FUND_LIST.length + 1;

        for (uint256 i = 0; i < state.FUND_LIST.length; i++) {
            if (state.FUND[state.FUND_LIST[i]].id == fundId) {
                index = i;
            }
        }

        require(index != state.FUND_LIST.length + 1, "Invalid fundId");

        state.FUND_LIST = Array.remove(state.FUND_LIST, index);
        delete state.FUND[fundId];

        emit IndexFundRemoved(fundId);
        return true;
    }

    /**
     *  @notice function to remove member from all the index funds
     *  @dev can be called by current owner to remove a member from all the index funds
     *  @param member member to be removed from index fund
     */
    function removeMember(uint256 member) public nonReentrant returns (bool) {
        RegistrarStorage.Config memory registrar_config = IRegistrar(
            state.config.registrarContract
        ).queryConfig();

        require(
            address(0) != registrar_config.accountsContract,
            "accounts contract not configured"
        );

        // TODO: added owner for testing
        require(
            msg.sender == registrar_config.accountsContract ||
                msg.sender == state.config.owner,
            "Unauthorized"
        );

        // check all funds and remove member if found

        for (uint256 i = 0; i < state.FUND_LIST.length; i++) {
            bool found;
            uint256 index;
            (index, found) = Array.indexOf(
                state.FUND[state.FUND_LIST[i]].members,
                member
            );
            if (found) {
                Array.remove(state.FUND[state.FUND_LIST[i]].members, index);
                emit MemberRemoved(i, member);
            }
        }
        return true;
    }

    /**
     *  @notice function to update fund members
     *  @dev can be called by current owner to add/remove member to an index fund
     *  @param fundId id of index fund to be updated
     *  @param add array of members to be added to index fund
     *  @param remove array of members to be removed from index fund
     */
    function updateFundMembers(
        uint256 fundId,
        uint256[] memory add,
        uint256[] memory remove
    ) public nonReentrant returns (bool) {
        bool found;
        uint256 index;
        require(msg.sender == state.config.owner, "Unauthorized");

        if (fundIsExpired(state.FUND[fundId], block.number, block.timestamp)) {
            revert("Index Fund Expired");
        }

        // add members
        for (uint256 i = 0; i < add.length; i++) {
            (index, found) = Array.indexOf(state.FUND[fundId].members, add[i]);
            if (!found) {
                state.FUND[fundId].members.push(add[i]);
                emit MemberAdded(fundId, add[i]);
            }
        }

        // remove members
        for (uint256 i = 0; i < remove.length; i++) {
            (index, found) = Array.indexOf(
                state.FUND[fundId].members,
                remove[i]
            );
            if (found) {
                Array.remove(state.FUND[fundId].members, index);
            }
            emit MemberRemoved(fundId, remove[i]);
        }

        require(
            state.FUND[fundId].members.length < state.config.fundMemberLimit,
            "Fund member limit exceeded"
        );
        return true;
    }

    /**
     * @notice deposit function which can be called by user to add funds to index fund
     * @dev converted from rust implementation, handles donations by managing limits and rotating active fund
     * @param curDetails deposit details
     * @param fund fund to deposit to
     */
    function depositERC20(
        address senderAddr,
        IndexFundMessage.DepositMsg memory curDetails,
        AngelCoreStruct.AssetBase memory fund
    ) public nonReentrant returns (bool) {
        if (fund.info != AngelCoreStruct.AssetInfoBase.Cw20) {
            revert("Invalid asset type");
        }

        // validate fund
        validateDepositFind(fund);

        // check each of the currently allowed Alliance member addr
        bool isAllianceMem = false;
        uint256 depositAmount = fund.amount;

        for (uint256 i = 0; i < state.config.alliance_members.length; i++) {
            if (senderAddr == state.config.alliance_members[i]) {
                isAllianceMem = true;
                break;
            }
        }

        // check if block height limit is reached
        if (state.config.fundRotation != 0) {
            if (block.number >= state.state.nextRotationBlock) {
                uint256 newFundId = rotateFund(
                    state.state.activeFund,
                    block.number,
                    block.timestamp
                );
                state.state.activeFund = newFundId;
                emit UpdateActiveFund(state.state.activeFund);
                state.state.round_donations = 0;

                while (block.number >= state.state.nextRotationBlock) {
                    state.state.nextRotationBlock += state.config.fundRotation;
                }
            }
        }

        RegistrarStorage.Config memory registrar_config = IRegistrar(
            state.config.registrarContract
        ).queryConfig();

        if (curDetails.fundId != 0) {
            require(
                state.FUND[curDetails.fundId].members.length != 0,
                "Empty Fund"
            );

            require(
                !fundIsExpired(
                    state.FUND[curDetails.fundId],
                    block.number,
                    block.timestamp
                ),
                "Expired Fund"
            );

            uint256 split = calculateSplit(
                isAllianceMem,
                registrar_config.splitToLiquid,
                state.FUND[curDetails.fundId].splitToLiquid,
                curDetails.split
            );

            updateDonationMessages(
                state.FUND[curDetails.fundId].members,
                split,
                fund.amount,
                state.donationMessages
            );
        } else {
            if (state.config.fundingGoal != 0) {
                uint256 loopDonation = 0;

                while (depositAmount > 0) {
                    // This will revert the transaction and donation will fail. TODO: check with team
                    require(
                        state.FUND[state.state.activeFund].members.length != 0,
                        "Empty Index Fund"
                    );

                    require(
                        !fundIsExpired(
                            state.FUND[state.state.activeFund],
                            block.number,
                            block.timestamp
                        ),
                        "Expired Fund"
                    );
                    uint256 goalLeftover = state.config.fundingGoal -
                        state.state.round_donations;

                    uint256 curActiveFund = state.state.activeFund;


                    if (depositAmount >= goalLeftover) {
                        state.state.round_donations = 0;
                        // set state active fund to next fund for next loop iteration

                        state.state.activeFund = rotateFund(
                            state.state.activeFund,
                            block.number,
                            block.timestamp
                        );

                        emit UpdateActiveFund(state.state.activeFund);
                        loopDonation = goalLeftover;
                    } else {
                        state.state.round_donations += depositAmount;
                        loopDonation = depositAmount;
                    }

                    uint256 split = calculateSplit(
                        isAllianceMem,
                        registrar_config.splitToLiquid,
                        state.FUND[curActiveFund].splitToLiquid,
                        curDetails.split
                    );

                    updateDonationMessages(
                        state.FUND[curActiveFund].members,
                        split,
                        loopDonation,
                        state.donationMessages
                    );
                    // deduct donated amount in this round from total donation amt
                    depositAmount -= loopDonation;
                }
            } else {
                require(
                    state.FUND[state.state.activeFund].members.length != 0,
                    "Empty Index Fund"
                );

                require(
                    !fundIsExpired(
                        state.FUND[state.state.activeFund],
                        block.number,
                        block.timestamp
                    ),
                    "Expired Fund"
                );

                uint256 split = calculateSplit(
                    isAllianceMem,
                    registrar_config.splitToLiquid,
                    state.FUND[state.state.activeFund].splitToLiquid,
                    curDetails.split
                );

                updateDonationMessages(
                    state.FUND[state.state.activeFund].members,
                    split,
                    fund.amount,
                    state.donationMessages
                );
            }
        }

        // transfer funds from msg sender to here
        require(
            IERC20(fund.addr).transferFrom(
                senderAddr,
                address(this),
                fund.amount
            ),
            "Failed to transfer funds"
        );

        // give allowance to accounts
        require(
            IERC20(fund.addr).approve(
                registrar_config.accountsContract,
                fund.amount
            ),
            "Failed to approve funds"
        );

        (
            address[] memory target,
            uint256[] memory value,
            bytes[] memory callData
        ) = buildDonationMessages(
                registrar_config.accountsContract,
                state.donationMessages,
                fund.addr
            );

        Utils._execute(target, value, callData);

        // Clean up storage for next call
        delete state.donationMessages.member_ids;
        delete state.donationMessages.locked_donation_amount;
        delete state.donationMessages.liquid_donation_amount;
        delete state.donationMessages.lockedSplit;
        delete state.donationMessages.liquidSplit;

        emit UpdateIndexFundState(state.state);
        return true;
    }

    /**
     * @dev Update donation messages
     * @param members Array of members
     * @param split Split to liquid
     * @param balance Balance of fund
     * @param curDonationMessages Donation messages
     */
    function updateDonationMessages(
        uint256[] memory members,
        uint256 split,
        uint256 balance,
        IndexFundStorage.DonationMessages storage curDonationMessages
    ) internal {
        uint256 memberPortion = balance;

        if (members.length > 0) {
            memberPortion = memberPortion.div(members.length);
        }

        uint256 lockSplit = 100 - split;

        for (uint256 i = 0; i < members.length; i++) {
            // check if member is in membersidsm, then modify, else push
            bool alreadyExists = false;
            uint256 index = 0;

            for (
                uint256 j = 0;
                j < curDonationMessages.member_ids.length;
                j++
            ) {
                if (curDonationMessages.member_ids[j] == members[i]) {
                    alreadyExists = true;
                    index = j;
                    break;
                }
            }

            if (alreadyExists) {
                curDonationMessages.lockedSplit[index] = lockSplit;
                curDonationMessages.liquidSplit[index] = split;
                curDonationMessages.locked_donation_amount[index] +=
                    (memberPortion * lockSplit) /
                    100;
                // avoid any over and under flows
                curDonationMessages.liquid_donation_amount[index] += (
                    (memberPortion - ((memberPortion * lockSplit) / 100))
                );
            } else {
                curDonationMessages.member_ids.push(members[i]);
                curDonationMessages.lockedSplit.push(lockSplit);
                curDonationMessages.liquidSplit.push(split);
                curDonationMessages.locked_donation_amount.push(
                    (memberPortion * lockSplit) / 100
                );
                // avoid any over and under flows
                curDonationMessages.liquid_donation_amount.push(
                    (memberPortion - ((memberPortion * lockSplit) / 100))
                );
            }
        }
        emit DonationMessagesUpdated(curDonationMessages);
    }

    /**
     * @dev Build donation messages
     * @param curAccountscontract Accounts contract address
     * @param curDonationMessages Donation messages
     * @param curTokenaddress Token address
     */
    function buildDonationMessages(
        address curAccountscontract,
        IndexFundStorage.DonationMessages storage curDonationMessages,
        address curTokenaddress
    )
        internal
        view
        returns (
            address[] memory target,
            uint256[] memory value,
            bytes[] memory callData
        )
    {
        target = new address[](curDonationMessages.member_ids.length);
        value = new uint256[](curDonationMessages.member_ids.length);
        callData = new bytes[](curDonationMessages.member_ids.length);
        // TODO: check with andrey for the split logic in index fund
        for (uint256 i = 0; i < curDonationMessages.member_ids.length; i++) {
            target[i] = curAccountscontract;
            value[i] = 0;
            callData[i] = abi.encodeWithSignature(
                "depositERC20((uint256,uint256,uint256),address,uint256)",
                AccountMessages.DepositRequest({
                    id: curDonationMessages.member_ids[i],
                    lockedPercentage: curDonationMessages.lockedSplit[i],
                    liquidPercentage: curDonationMessages.liquidSplit[i]
                }),
                curTokenaddress,
                curDonationMessages.locked_donation_amount[i] +
                    curDonationMessages.liquid_donation_amount[i]
            );
        }
    }

    /**
     * @dev Calculate split
     * @param tca True if this is a split for a TCA (Terra charity alliance)
     * @param registrar_split Registrar split
     * @param fundSplit Fund split (set on index fund contract)
     * @param userSplit User split
     */

    function calculateSplit(
        bool tca,
        AngelCoreStruct.SplitDetails memory registrar_split,
        uint256 fundSplit,
        uint256 userSplit
    ) internal pure returns (uint256) {
        uint256 split = 0;

        if (fundSplit == 0) {
            if (!tca) {
                if (userSplit == 0) {
                    split = registrar_split.defaultSplit;
                } else {
                    if (
                        userSplit > registrar_split.min &&
                        userSplit < registrar_split.max
                    ) {
                        split = userSplit;
                    }
                }
            }
        } else {
            split = fundSplit;
        }

        return split;
    }

    // QUERIES

    /**
     * @dev Query config
     * @return Config
     */
    function queryConfig()
        public
        view
        returns (
            // TODO: Add reentrancy guard to `view` functions
            IndexFundStorage.Config memory
        )
    {
        return state.config;
    }

    /**
     * @dev Query state
     * @return State
     */
    function queryState()
        public
        view
        returns (IndexFundMessage.StateResponseMessage memory)
    {
        return
            IndexFundMessage.StateResponseMessage({
                totalFunds: state.state.totalFunds,
                activeFund: state.state.activeFund,
                round_donations: state.state.round_donations,
                nextRotationBlock: state.state.nextRotationBlock
            });
    }

    /**
     * @dev Query fund list
     * @param startAfter Start after (Index after which to start getting values)
     * @param limit Limit (total number of values to return)
     * @return Fund details
     */
    function queryFundsList(
        uint256 startAfter,
        uint256 limit
    ) public view returns (AngelCoreStruct.IndexFund[] memory) {
        if (limit == 0) {
            limit = defaultLimit;
        }

        if (limit > maxLimit) {
            limit = maxLimit;
        }

        AngelCoreStruct.IndexFund[]
            memory resp = new AngelCoreStruct.IndexFund[](limit);

        for (uint256 i = 0; i < limit; i++) {
            if (i + startAfter >= state.FUND_LIST.length) {
                break;
            }
            resp[i] = state.FUND[state.FUND_LIST[i + startAfter]];
        }

        return resp;
    }

    /**
     * @dev Query fund details
     * @param fundId Fund id
     * @return Fund details
     */
    function queryFundDetails(
        uint256 fundId
    ) public view returns (AngelCoreStruct.IndexFund memory) {
        return state.FUND[fundId];
    }

    /**
     * @dev Query in which index funds is an endowment part of
     * @param endowmentId Endowment id
     * @return Fund details
     */
    function queryInvolvedFunds(
        uint256 endowmentId
    ) public view returns (AngelCoreStruct.IndexFund[] memory) {
        uint256 counter = 0;
        // check how many
        for (uint256 i = 0; i < state.FUND_LIST.length; i++) {
            bool found;
            uint256 index;
            (index, found) = Array.indexOf(
                state.FUND[state.FUND_LIST[i]].members,
                endowmentId
            );
            if (found) {
                counter++;
            }
        }
        // make memory and allocate to response object

        AngelCoreStruct.IndexFund[]
            memory resp = new AngelCoreStruct.IndexFund[](counter);

        uint256 indexer = 0;

        for (uint256 i = 0; i < state.FUND_LIST.length; i++) {
            bool found;
            uint256 index;
            (index, found) = Array.indexOf(
                state.FUND[state.FUND_LIST[i]].members,
                endowmentId
            );
            if (found) {
                resp[indexer] = state.FUND[state.FUND_LIST[i]];
                indexer++;
            }
        }

        return resp;
    }

    /**
     * @dev Query active fund details
     * @return Fund details
     */
    function queryActiveFundDetails()
        public
        view
        returns (AngelCoreStruct.IndexFund memory)
    {
        return state.FUND[state.state.activeFund];
    }

    // function queryAllianceMember(address wallet)
    //     public
    //     view
    //     returns (IndexFundMessage.AllianceMemberResponse memory)
    // {
    //     return
    //         IndexFundMessage.AllianceMemberResponse({
    //             wallet: wallet,
    //             name: state.config.alliance_members[wallet].name,
    //             logo: state.config.alliance_members[wallet].logo,
    //             website: state.config.alliance_members[wallet].website
    //         });
    // }

    /**
     * @dev Query alliance members
     * @param startAfter Start after (Index after which to start getting values)
     * @param limit Limit (total number of values to return)
     * @return Alliance members
     */
    function queryAllianceMembers(
        uint256 startAfter,
        uint256 limit
    ) public view returns (address[] memory) {
        if (limit == 0) {
            limit = defaultLimit;
        }

        if (limit > maxLimit) {
            limit = maxLimit;
        }

        address[] memory resp = new address[](limit);

        for (uint256 i = 0; i < limit; i++) {
            if (i + startAfter >= state.config.alliance_members.length) {
                break;
            }

            resp[i] = state.config.alliance_members[i + startAfter];
        }

        return resp;
    }

    // Internal functions
    /**
     * @dev Check if fund is expired
     * @param fund Fund
     * @param envHeight Current block height
     * @param envTime Current block time
     * @return True if fund is expired
     */
    function fundIsExpired(
        AngelCoreStruct.IndexFund memory fund,
        uint256 envHeight,
        uint256 envTime
    ) internal pure returns (bool) {
        if (
            (fund.expiryHeight != 0 && envHeight >= fund.expiryHeight) ||
            (fund.expiryTime != 0 && envTime >= fund.expiryTime)
        ) {
            return true;
        }
        return false;
    }

    /**
     * @dev rotate active based if investment goal is fulfillef
     * @param currFund Current Active fund
     * @param envHeight Current block height
     * @param envTime Current block time
     * @return New active fund
     */
    function rotateFund(
        uint256 currFund,
        uint256 envHeight,
        uint256 envTime
    ) internal view returns (uint256) {
        uint256 activeFundCount = 0;

        // TODO: can be optimised by storing indexes of active funds in a memory array

        for (uint256 i = 0; i < state.FUND_LIST.length; i++) {
            if (
                !fundIsExpired(
                    state.FUND[state.FUND_LIST[i]],
                    envHeight,
                    envTime
                ) && state.FUND[state.FUND_LIST[i]].rotatingFund == true
            ) {
                activeFundCount++;
            }
        }

        uint256 indexer = 0;

        AngelCoreStruct.IndexFund[]
            memory activeFunds = new AngelCoreStruct.IndexFund[](
                activeFundCount
            );

        for (uint256 i = 0; i < state.FUND_LIST.length; i++) {
            if (
                !fundIsExpired(
                    state.FUND[state.FUND_LIST[i]],
                    envHeight,
                    envTime
                ) && state.FUND[state.FUND_LIST[i]].rotatingFund == true
            ) {
                activeFunds[indexer] = state.FUND[state.FUND_LIST[i]];
                indexer++;
            }
        }

        // default value outside of index range
        uint256 currFundIndex = activeFunds.length + 1;

        for (uint256 i = 0; i < activeFunds.length; i++) {
            if (activeFunds[i].id == currFund) {
                currFundIndex = i;
            }
        }

        if (currFundIndex < state.FUND_LIST.length) {
            if (currFundIndex == activeFunds.length - 1) {
                return activeFunds[0].id;
            } else {
                return activeFunds[currFundIndex + 1].id;
            }
        } else {
            AngelCoreStruct.IndexFund memory filter_fund;
            for (uint256 i = 0; i < activeFunds.length; i++) {
                if (activeFunds[i].id > currFund) {
                    filter_fund = activeFunds[i];
                    break;
                }
            }

            if (filter_fund.id != 0) {
                return filter_fund.id;
            } else {
                return activeFunds[0].id;
            }
        }
    }

    /**
     * @dev Validate deposit find (by querying registrar contract)
     * @param fund Fund
     * @return True if fund is valid
     */
    function validateDepositFind(
        AngelCoreStruct.AssetBase memory fund
    ) internal view returns (bool) {
        RegistrarStorage.Config memory registrar_config = IRegistrar(
            state.config.registrarContract
        ).queryConfig();

        if (fund.info == AngelCoreStruct.AssetInfoBase.Cw20) {
            bool flag = false;
            for (
                uint256 i = 0;
                i < registrar_config.acceptedTokens.cw20.length;
                i++
            ) {
                if (registrar_config.acceptedTokens.cw20[i] == fund.addr) {
                    flag = true;
                }
            }

            require(flag, "Not accepted token");
        } else {
            revert();
        }

        require(fund.amount != 0, "invalid fund amount");

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AngelCoreStruct} from "../struct.sol";

library IndexFundMessage {
    struct InstantiateMessage {
        address registrarContract;
        uint256 fundRotation; // how many blocks are in a rotation cycle for the active IndexFund
        uint256 fundMemberLimit; // limit to number of members an IndexFund can have
        uint256 fundingGoal; // donation funding limit to trigger early cycle of the Active IndexFund
    }

    struct UpdateConfigMessage {
        uint256 fundRotation;
        uint256 fundMemberLimit;
        uint256 fundingGoal;
    }

    struct StateResponseMessage {
        uint256 totalFunds;
        uint256 activeFund; // index ID of the Active IndexFund
        uint256 round_donations; // total donations given to active charity this round
        uint256 nextRotationBlock; // block height to perform next rotation on
    }

    struct DonationDetailsResponse {
        address addr;
        uint256 totalUst;
    }

    struct AllianceMemberResponse {
        address wallet;
        string name;
        string logo;
        string website;
    }

    struct DepositMsg {
        uint256 fundId;
        uint256 split;
    }

    // struct BuildDonationMessage{
    //     uint256 key;
    //     uint256 key1;
    //     uint256 value1;
    //     uint256 key2;
    //     uint256 value2;
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AngelCoreStruct} from "../struct.sol";

library IndexFundStorage {
    struct Config {
        address owner; // DANO Address
        address registrarContract; // Address of Registrar SC
        uint256 fundRotation; // how many blocks are in a rotation cycle for the active IndexFund
        uint256 fundMemberLimit; // limit to number of members an IndexFund can have
        uint256 fundingGoal; // donation funding limit (in UUSD) to trigger early cycle of the Active IndexFund
        address[] alliance_members;
    }

    struct _State {
        uint256 totalFunds;
        uint256 activeFund; // index ID of the Active IndexFund
        uint256 round_donations; // total donations given to active charity this round
        uint256 nextRotationBlock; // block height to perform next rotation on
        uint256 nextFundId;
    }

    struct DonationMessages {
        uint256[] member_ids;
        uint256[] locked_donation_amount;
        uint256[] liquid_donation_amount;
        uint256[] lockedSplit;
        uint256[] liquidSplit;
    }

    struct State {
        Config config;
        _State state;
        // mapping(address => AngelCoreStruct.GenericBalance) TCA_DONATIONS;
        // mapping(address => AngelCoreStruct.AllianceMember) ALLIANCE_MEMBERS;
        // address[] ALLIANCE_MEMBERS_LIST;
        mapping(uint256 => AngelCoreStruct.IndexFund) FUND;
        uint256[] FUND_LIST;
        DonationMessages donationMessages;
        bool initIndexFund;
    }
}

contract StorageIndexFund {
    IndexFundStorage.State state;
}

// SPDX-License-Identifier: MIT
// pragma solidity ^0.8.16;
// import {RegistrarStorage} from "../storage.sol";
// import {RegistrarMessages} from "../message.sol";
// import {AngelCoreStruct} from "../../struct.sol";

// interface IRegistrar {
//     function queryConfig()
//         external
//         view
//         returns (RegistrarStorage.Config memory);

//     function queryNetworkConnection(
//         uint256 chainId
//     ) external view returns (AngelCoreStruct.NetworkInfo memory);

//     function queryVaultDetails(
//         address vaultAddr
//     ) external view returns (AngelCoreStruct.YieldVault memory);

//     function queryVaultList(
//         uint256 network,
//         AngelCoreStruct.EndowmentType endowmentType,
//         AngelCoreStruct.AccountType accountType,
//         AngelCoreStruct.VaultType vaultType,
//         AngelCoreStruct.BoolOptional approved,
//         uint256 startAfter,
//         uint256 limit
//     ) external view returns (AngelCoreStruct.YieldVault[] memory);

//     function updateConfig(
//         RegistrarMessages.UpdateConfigRequest memory curDetails
//     ) external returns (bool);

//     function updateNetworkConnections(
//         AngelCoreStruct.NetworkInfo memory networkInfo,
//         string memory action
//     ) external returns (bool);

//     function updateOwner(address newOwner) external returns (bool);

//     function vaultAdd(
//         RegistrarMessages.VaultAddRequest memory curDetails
//     ) external returns (bool);

//     function vaultRemove(address vaultAddr) external returns (bool);

//     function vaultUpdate(
//         address vaultAddr,
//         bool approved,
//         AngelCoreStruct.EndowmentType[] memory restrictedFrom
//     ) external returns (bool);

//     function queryFee(string memory name) external returns (uint256);

//     function testQuery() external view returns (address[] memory);

//     function testQueryStruct()
//         external
//         view
//         returns (AngelCoreStruct.YieldVault[] memory);

//     function queryVaultListBg(
//         uint256 network,
//         AngelCoreStruct.EndowmentType endowmentType,
//         AngelCoreStruct.AccountType accountType,
//         AngelCoreStruct.VaultType vaultType,
//         AngelCoreStruct.BoolOptional approved,
//         uint256 startAfter,
//         uint256 limit
//     ) external view returns (AngelCoreStruct.YieldVault[] memory);
// }

pragma solidity ^0.8.16;
import {RegistrarStorage} from "../storage.sol";
import {RegistrarMessages} from "../message.sol";
import {AngelCoreStruct} from "../../struct.sol";

interface IRegistrar {
    function updateConfig(
        RegistrarMessages.UpdateConfigRequest memory curDetails
    ) external;

    function updateOwner(address newOwner) external;

    function updateFees(
        RegistrarMessages.UpdateFeeRequest memory curDetails
    ) external;

    function vaultAdd(
        RegistrarMessages.VaultAddRequest memory curDetails
    ) external;

    function vaultRemove(string memory _stratagyName) external;

    function vaultUpdate(
        string memory _stratagyName,
        bool curApproved,
        AngelCoreStruct.EndowmentType[] memory curRestrictedfrom
    ) external;

    function updateNetworkConnections(
        AngelCoreStruct.NetworkInfo memory networkInfo,
        string memory action
    ) external;

    // Query functions for contract

    function queryConfig()
        external
        view
        returns (RegistrarStorage.Config memory);

    function testQuery() external view returns (string[] memory);

    function testQueryStruct()
        external
        view
        returns (AngelCoreStruct.YieldVault[] memory);

    function queryVaultListDep(
        uint256 network,
        AngelCoreStruct.EndowmentType endowmentType,
        AngelCoreStruct.AccountType accountType,
        AngelCoreStruct.VaultType vaultType,
        AngelCoreStruct.BoolOptional approved,
        uint256 startAfter,
        uint256 limit
    ) external view returns (AngelCoreStruct.YieldVault[] memory);

    function queryVaultList(
        uint256 network,
        AngelCoreStruct.EndowmentType endowmentType,
        AngelCoreStruct.AccountType accountType,
        AngelCoreStruct.VaultType vaultType,
        AngelCoreStruct.BoolOptional approved,
        uint256 startAfter,
        uint256 limit
    ) external view returns (AngelCoreStruct.YieldVault[] memory);

    function queryVaultDetails(
        string memory _stratagyName
    ) external view returns (AngelCoreStruct.YieldVault memory response);

    function queryNetworkConnection(
        uint256 chainId
    ) external view returns (AngelCoreStruct.NetworkInfo memory response);

    function queryFee(
        string memory name
    ) external view returns (uint256 response);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import {AngelCoreStruct} from "../../struct.sol";

library Validator {
    function addressChecker(address curAddr1) internal pure returns (bool) {
        if (curAddr1 == address(0)) {
            return false;
        }
        return true;
    }

    function splitChecker(
        AngelCoreStruct.SplitDetails memory split
    ) internal pure returns (bool) {
        if (
            !(split.max >= split.min &&
                split.defaultSplit <= split.max &&
                split.defaultSplit >= split.min)
        ) {
            return false;
        } else {
            return true;
        }
    }

    function compareStrings(
        string memory a,
        string memory b
    ) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AngelCoreStruct} from "../struct.sol";

library RegistrarMessages {
    struct InstantiateRequest {
        address treasury;
        uint256 taxRate;
        AngelCoreStruct.RebalanceDetails rebalance;
        AngelCoreStruct.SplitDetails splitToLiquid;
        AngelCoreStruct.AcceptedTokens acceptedTokens;
        address router;
        address axelerGateway;
    }

    struct UpdateConfigRequest {
        address accountsContract;
        uint256 taxRate;
        AngelCoreStruct.RebalanceDetails rebalance;
        string[] approved_charities;
        uint256 splitMax;
        uint256 splitMin;
        uint256 splitDefault;
        uint256 collectorShare;
        AngelCoreStruct.AcceptedTokens acceptedTokens;
        // WASM CODES -> EVM -> Solidity Implementation contract addresses
        address subdaoGovCode; // subdao gov wasm code
        address subdaoCw20TokenCode; // subdao gov token (basic CW20) wasm code
        address subdaoBondingTokenCode; // subdao gov token (w/ bonding-curve) wasm code
        address subdaoCw900Code; // subdao gov ve-CURVE contract for locked token voting
        address subdaoDistributorCode; // subdao gov fee distributor wasm code
        address subdaoEmitter;
        address donationMatchCode; // donation matching contract wasm code
        // CONTRACT ADSRESSES
        address indexFundContract;
        address govContract;
        address treasury;
        address donationMatchCharitesContract;
        address donationMatchEmitter;
        address haloToken;
        address haloTokenLpContract;
        address charitySharesContract;
        address fundraisingContract;
        address applicationsReview;
        address swapsRouter;
        address multisigFactory;
        address multisigEmitter;
        address charityProposal;
        address lockedWithdrawal;
        address proxyAdmin;
        address usdcAddress;
        address wethAddress;
        address cw900lvAddress;
    }

    struct VaultAddRequest {
        // chainid of network
        uint256 network;
        string stratagyName;
        address inputDenom;
        address yieldToken;
        AngelCoreStruct.EndowmentType[] restrictedFrom;
        AngelCoreStruct.AccountType acctType;
        AngelCoreStruct.VaultType vaultType;
    }

    struct UpdateFeeRequest {
        string[] keys;
        // TODO Change to decimal
        uint256[] values;
    }

    struct ConfigResponse {
        address owner;
        uint256 version;
        address accountsContract;
        address treasury;
        uint256 taxRate;
        AngelCoreStruct.RebalanceDetails rebalance;
        address indexFund;
        AngelCoreStruct.SplitDetails splitToLiquid;
        address haloToken;
        address govContract;
        address charitySharesContract;
        uint256 cw3Code;
        uint256 cw4Code;
        AngelCoreStruct.AcceptedTokens acceptedTokens;
        address applicationsReview;
        address swapsRouter;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AngelCoreStruct} from "../struct.sol";

library RegistrarStorage {
    struct Config {
        address owner; // AP TEAM MULTISIG
        //Application review multisig
        address applicationsReview; // Endowment application review team's CW3 (set as owner to start). Owner can set and change/revoke.
        address indexFundContract;
        address accountsContract;
        address treasury;
        address subdaoGovCode; // subdao gov wasm code
        address subdaoCw20TokenCode; // subdao gov cw20 token wasm code
        address subdaoBondingTokenCode; // subdao gov bonding curve token wasm code
        address subdaoCw900Code; // subdao gov ve-CURVE contract for locked token voting
        address subdaoDistributorCode; // subdao gov fee distributor wasm code
        address subdaoEmitter;
        address donationMatchCode; // donation matching contract wasm code
        address donationMatchCharitesContract; // donation matching contract address for "Charities" endowments
        address donationMatchEmitter;
        AngelCoreStruct.SplitDetails splitToLiquid; // set of max, min, and default Split paramenters to check user defined split input against
        //TODO: pending check
        address haloToken; // TerraSwap HALO token addr
        address haloTokenLpContract;
        address govContract; // AP governance contract
        address collectorAddr; // Collector address for new fee
        uint256 collectorShare;
        address charitySharesContract;
        AngelCoreStruct.AcceptedTokens acceptedTokens; // list of approved native and CW20 coins can accept inward
        //PROTOCOL LEVEL
        address fundraisingContract;
        AngelCoreStruct.RebalanceDetails rebalance;
        address swapsRouter;
        address multisigFactory;
        address multisigEmitter;
        address charityProposal;
        address lockedWithdrawal;
        address proxyAdmin;
        address usdcAddress;
        address wethAddress;
        address cw900lvAddress;
    }

    struct State {
        Config config;
        mapping(string => AngelCoreStruct.YieldVault) VAULTS;
        string[] VAULT_POINTERS;
        mapping(uint256 => AngelCoreStruct.NetworkInfo) NETWORK_CONNECTIONS;
        mapping(string => uint256) FEES;
    }
}

contract Storage {
    RegistrarStorage.State state;
    bool initilized = false;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library AngelCoreStruct {
    enum AccountType {
        Locked,
        Liquid,
        None
    }

    enum Tier {
        None,
        Level1,
        Level2,
        Level3
    }

    struct Pair {
        //This should be asset info
        string[] asset;
        address contractAddress;
    }

    struct Asset {
        address addr;
        string name;
    }

    enum AssetInfoBase {
        Cw20,
        Native,
        None
    }

    struct AssetBase {
        AssetInfoBase info;
        uint256 amount;
        address addr;
        string name;
    }

    //By default array are empty
    struct Categories {
        uint256[] sdgs;
        uint256[] general;
    }

    ///TODO: by default are not internal need to create a custom internal function for this refer :- https://ethereum.stackexchange.com/questions/21155/how-to-expose-enum-in-solidity-contract
    enum EndowmentType {
        Charity,
        Normal,
        None
    }

    enum EndowmentStatus {
        Inactive,
        Approved,
        Frozen,
        Closed
    }

    struct AccountStrategies {
        string[] locked_vault;
        uint256[] lockedPercentage;
        string[] liquid_vault;
        uint256[] liquidPercentage;
    }

    function accountStratagyLiquidCheck(
        AccountStrategies storage strategies,
        OneOffVaults storage oneoffVaults
    ) public {
        for (uint256 i = 0; i < strategies.liquid_vault.length; i++) {
            bool checkFlag = true;
            for (uint256 j = 0; j < oneoffVaults.liquid.length; j++) {
                if (
                    keccak256(abi.encodePacked(strategies.liquid_vault[i])) ==
                    keccak256(abi.encodePacked(oneoffVaults.liquid[j]))
                ) {
                    checkFlag = false;
                }
            }

            if (checkFlag) {
                oneoffVaults.liquid.push(strategies.liquid_vault[i]);
            }
        }
    }

    function accountStratagyLockedCheck(
        AccountStrategies storage strategies,
        OneOffVaults storage oneoffVaults
    ) public {
        for (uint256 i = 0; i < strategies.locked_vault.length; i++) {
            bool checkFlag = true;
            for (uint256 j = 0; j < oneoffVaults.locked.length; j++) {
                if (
                    keccak256(abi.encodePacked(strategies.locked_vault[i])) ==
                    keccak256(abi.encodePacked(oneoffVaults.locked[j]))
                ) {
                    checkFlag = false;
                }
            }

            if (checkFlag) {
                oneoffVaults.locked.push(strategies.locked_vault[i]);
            }
        }
    }

    function accountStrategiesDefaut()
        public
        pure
        returns (AccountStrategies memory)
    {
        AccountStrategies memory empty;
        return empty;
    }

    //TODO: handle the case when we invest into vault or redem from vault
    struct OneOffVaults {
        string[] locked;
        uint256[] lockedAmount;
        string[] liquid;
        uint256[] liquidAmount;
    }

    function removeLast(string[] storage vault, string memory remove) public {
        for (uint256 i = 0; i < vault.length - 1; i++) {
            if (
                keccak256(abi.encodePacked(vault[i])) ==
                keccak256(abi.encodePacked(remove))
            ) {
                vault[i] = vault[vault.length - 1];
                break;
            }
        }

        vault.pop();
    }

    function oneOffVaultsDefault() public pure returns (OneOffVaults memory) {
        OneOffVaults memory empty;
        return empty;
    }

    function checkTokenInOffVault(
        string[] storage curAvailible,
        uint256[] storage cerAvailibleAmount, 
        string memory curToken
    ) public {
        bool check = true;
        for (uint8 j = 0; j < curAvailible.length; j++) {
            if (
                keccak256(abi.encodePacked(curAvailible[j])) ==
                keccak256(abi.encodePacked(curToken))
            ) {
                check = false;
            }
        }
        if (check) {
            curAvailible.push(curToken);
            cerAvailibleAmount.push(0);
        }
    }

    struct RebalanceDetails {
        bool rebalanceLiquidInvestedProfits; // should invested portions of the liquid account be rebalanced?
        bool lockedInterestsToLiquid; // should Locked acct interest earned be distributed to the Liquid Acct?
        ///TODO: Should be decimal type insted of uint256
        uint256 interest_distribution; // % of Locked acct interest earned to be distributed to the Liquid Acct
        bool lockedPrincipleToLiquid; // should Locked acct principle be distributed to the Liquid Acct?
        ///TODO: Should be decimal type insted of uint256
        uint256 principle_distribution; // % of Locked acct principle to be distributed to the Liquid Acct
    }

    function rebalanceDetailsDefaut()
        public
        pure
        returns (RebalanceDetails memory)
    {
        RebalanceDetails memory _tempRebalanceDetails = RebalanceDetails({
            rebalanceLiquidInvestedProfits: false,
            lockedInterestsToLiquid: false,
            interest_distribution: 20,
            lockedPrincipleToLiquid: false,
            principle_distribution: 0
        });

        return _tempRebalanceDetails;
    }

    struct DonationsReceived {
        uint256 locked;
        uint256 liquid;
    }

    function donationsReceivedDefault()
        public
        pure
        returns (DonationsReceived memory)
    {
        DonationsReceived memory empty;
        return empty;
    }

    struct Coin {
        string denom;
        uint128 amount;
    }

    struct Cw20CoinVerified {
        uint128 amount;
        address addr;
    }

    struct GenericBalance {
        uint256 coinNativeAmount;
        // Coin[] native;
        uint256[] Cw20CoinVerified_amount;
        address[] Cw20CoinVerified_addr;
        // Cw20CoinVerified[] cw20;
    }

    function addToken(
        GenericBalance storage curTemp,
        address curTokenaddress,
        uint256 curAmount
    ) public {
        bool notFound = true;
        for (uint8 i = 0; i < curTemp.Cw20CoinVerified_addr.length; i++) {
            if (curTemp.Cw20CoinVerified_addr[i] == curTokenaddress) {
                notFound = false;
                curTemp.Cw20CoinVerified_amount[i] += curAmount;
            }
        }
        if (notFound) {
            curTemp.Cw20CoinVerified_addr.push(curTokenaddress);
            curTemp.Cw20CoinVerified_amount.push(curAmount);
        }
    }

    function addTokenMem(
        GenericBalance memory curTemp,
        address curTokenaddress,
        uint256 curAmount
    ) public pure returns (GenericBalance memory) {
        bool notFound = true;
        for (uint8 i = 0; i < curTemp.Cw20CoinVerified_addr.length; i++) {
            if (curTemp.Cw20CoinVerified_addr[i] == curTokenaddress) {
                notFound = false;
                curTemp.Cw20CoinVerified_amount[i] += curAmount;
            }
        }
        if (notFound) {
            GenericBalance memory new_temp = GenericBalance({
                coinNativeAmount: curTemp.coinNativeAmount,
                Cw20CoinVerified_amount: new uint256[](
                    curTemp.Cw20CoinVerified_amount.length + 1
                ),
                Cw20CoinVerified_addr: new address[](
                    curTemp.Cw20CoinVerified_addr.length + 1
                )
            });
            for (uint256 i = 0; i < curTemp.Cw20CoinVerified_addr.length; i++) {
                new_temp.Cw20CoinVerified_addr[i] = curTemp
                    .Cw20CoinVerified_addr[i];
                new_temp.Cw20CoinVerified_amount[i] = curTemp
                    .Cw20CoinVerified_amount[i];
            }
            new_temp.Cw20CoinVerified_addr[
                curTemp.Cw20CoinVerified_addr.length
            ] = curTokenaddress;
            new_temp.Cw20CoinVerified_amount[
                curTemp.Cw20CoinVerified_amount.length
            ] = curAmount;
            return new_temp;
        } else return curTemp;
    }

    function subToken(
        GenericBalance storage curTemp,
        address curTokenaddress,
        uint256 curAmount
    ) public {
        for (uint8 i = 0; i < curTemp.Cw20CoinVerified_addr.length; i++) {
            if (curTemp.Cw20CoinVerified_addr[i] == curTokenaddress) {
                curTemp.Cw20CoinVerified_amount[i] -= curAmount;
            }
        }
    }

    function subTokenMem(
        GenericBalance memory curTemp,
        address curTokenaddress,
        uint256 curAmount
    ) public pure returns (GenericBalance memory) {
        for (uint8 i = 0; i < curTemp.Cw20CoinVerified_addr.length; i++) {
            if (curTemp.Cw20CoinVerified_addr[i] == curTokenaddress) {
                curTemp.Cw20CoinVerified_amount[i] -= curAmount;
            }
        }
        return curTemp;
    }

    function splitBalance(
        uint256[] storage cw20Coin,
        uint256 splitFactor
    ) public view returns (uint256[] memory) {
        uint256[] memory curTemp = new uint256[](cw20Coin.length);
        for (uint8 i = 0; i < cw20Coin.length; i++) {
            uint256 result = SafeMath.div(cw20Coin[i], splitFactor);
            curTemp[i] = result;
        }

        return curTemp;
    }

    function receiveGenericBalance(
        address[] storage curReceiveaddr,
        uint256[] storage curReceiveamount,
        address[] storage curSenderaddr,
        uint256[] storage curSenderamount
    ) public {
        uint256 a = curSenderaddr.length;
        uint256 b = curReceiveaddr.length;

        for (uint8 i = 0; i < a; i++) {
            bool flag = true;
            for (uint8 j = 0; j < b; j++) {
                if (curSenderaddr[i] == curReceiveaddr[j]) {
                    flag = false;
                    curReceiveamount[j] += curSenderamount[i];
                }
            }

            if (flag) {
                curReceiveaddr.push(curSenderaddr[i]);
                curReceiveamount.push(curSenderamount[i]);
            }
        }
    }

    function receiveGenericBalanceModified(
        address[] storage curReceiveaddr,
        uint256[] storage curReceiveamount,
        address[] storage curSenderaddr,
        uint256[] memory curSenderamount
    ) public {
        uint256 a = curSenderaddr.length;
        uint256 b = curReceiveaddr.length;

        for (uint8 i = 0; i < a; i++) {
            bool flag = true;
            for (uint8 j = 0; j < b; j++) {
                if (curSenderaddr[i] == curReceiveaddr[j]) {
                    flag = false;
                    curReceiveamount[j] += curSenderamount[i];
                }
            }

            if (flag) {
                curReceiveaddr.push(curSenderaddr[i]);
                curReceiveamount.push(curSenderamount[i]);
            }
        }
    }

    function deductTokens(
        address[] memory curAddress,
        uint256[] memory curAmount,
        address curDeducttokenfor,
        uint256 curDeductamount
    ) public pure returns (uint256[] memory) {
        for (uint8 i = 0; i < curAddress.length; i++) {
            if (curAddress[i] == curDeducttokenfor) {
                require(curAmount[i] > curDeductamount, "Insufficient Funds");
                curAmount[i] -= curDeductamount;
            }
        }

        return curAmount;
    }

    function getTokenAmount(
        address[] memory curAddress,
        uint256[] memory curAmount,
        address curTokenaddress
    ) public pure returns (uint256) {
        uint256 amount = 0;
        for (uint8 i = 0; i < curAddress.length; i++) {
            if (curAddress[i] == curTokenaddress) {
                amount = curAmount[i];
            }
        }

        return amount;
    }

    struct AllianceMember {
        string name;
        string logo;
        string website;
    }

    function genericBalanceDefault()
        public
        pure
        returns (GenericBalance memory)
    {
        GenericBalance memory empty;
        return empty;
    }

    struct BalanceInfo {
        GenericBalance locked;
        GenericBalance liquid;
    }

    ///TODO: need to test this same names already declared in other libraries
    struct EndowmentId {
        uint256 id;
    }

    struct IndexFund {
        uint256 id;
        string name;
        string description;
        uint256[] members;
        bool rotatingFund; // set a fund as a rotating fund
        //Fund Specific: over-riding SC level setting to handle a fixed split value
        // Defines the % to split off into liquid account, and if defined overrides all other splits
        uint256 splitToLiquid;
        // Used for one-off funds that have an end date (ex. disaster recovery funds)
        uint256 expiryTime; // datetime int of index fund expiry
        uint256 expiryHeight; // block equiv of the expiry_datetime
    }

    struct Wallet {
        string addr;
    }

    struct BeneficiaryData {
        uint256 id;
        address addr;
    }

    enum BeneficiaryEnum {
        EndowmentId,
        IndexFund,
        Wallet,
        None
    }

    struct Beneficiary {
        BeneficiaryData data;
        BeneficiaryEnum enumData;
    }

    function beneficiaryDefault() public pure returns (Beneficiary memory) {
        Beneficiary memory curTemp = Beneficiary({
            enumData: BeneficiaryEnum.None,
            data: BeneficiaryData({id: 0, addr: address(0)})
        });

        return curTemp;
    }

    struct SocialMedialUrls {
        string facebook;
        string twitter;
        string linkedin;
    }

    struct Profile {
        string overview;
        string url;
        string registrationNumber;
        string countryOfOrigin;
        string streetAddress;
        string contactEmail;
        SocialMedialUrls socialMediaUrls;
        uint16 numberOfEmployees;
        string averageAnnualBudget;
        string annualRevenue;
        string charityNavigatorRating;
    }

    ///CHanges made for registrar contract

    struct SplitDetails {
        uint256 max;
        uint256 min;
        uint256 defaultSplit; // for when a split parameter is not provided
    }

    function checkSplits(
        SplitDetails memory registrarSplits,
        uint256 userLocked,
        uint256 userLiquid,
        bool userOverride
    ) public pure returns (uint256, uint256) {
        // check that the split provided by a non-TCA address meets the default
        // requirements for splits that is set in the Registrar contract
        if (
            userLiquid > registrarSplits.max ||
            userLiquid < registrarSplits.min ||
            userOverride == true
        ) {
            return (
                100 - registrarSplits.defaultSplit,
                registrarSplits.defaultSplit
            );
        } else {
            return (userLocked, userLiquid);
        }
    }

    struct AcceptedTokens {
        address[] cw20;
    }

    function cw20Valid(
        address[] memory cw20,
        address token
    ) public pure returns (bool) {
        bool check = false;
        for (uint8 i = 0; i < cw20.length; i++) {
            if (cw20[i] == token) {
                check = true;
            }
        }

        return check;
    }

    struct NetworkInfo {
        string name;
        uint256 chainId;
        address router;
        address axelerGateway;
        string ibcChannel; // Should be removed
        string transferChannel;
        address gasReceiver; // Should be removed
        uint256 gasLimit; // Should be used to set gas limit
    }

    struct Ibc {
        string ica;
    }

    ///TODO: need to check this and have a look at this
    enum VaultType {
        Native, // Juno native Vault contract
        Ibc, // the address of the Vault contract on it's Cosmos(non-Juno) chain
        Evm, // the address of the Vault contract on it's EVM chain
        None
    }

    enum BoolOptional {
        False,
        True,
        None
    }

    struct YieldVault {
        string addr; // vault's contract address on chain where the Registrar lives/??
        uint256 network; // Points to key in NetworkConnections storage map
        address inputDenom; //?
        address yieldToken; //?
        bool approved;
        EndowmentType[] restrictedFrom;
        AccountType acctType;
        VaultType vaultType;
    }

    struct Member {
        address addr;
        uint256 weight;
    }

    struct ThresholdData {
        uint256 weight;
        uint256 percentage;
        uint256 threshold;
        uint256 quorum;
    }
    enum ThresholdEnum {
        AbsoluteCount,
        AbsolutePercentage,
        ThresholdQuorum
    }

    struct DurationData {
        uint256 height;
        uint256 time;
    }

    enum DurationEnum {
        Height,
        Time
    }

    struct Duration {
        DurationEnum enumData;
        DurationData data;
    }

    //TODO: remove if not needed
    // function durationAfter(Duration memory data)
    //     public
    //     view
    //     returns (Expiration memory)
    // {
    //     if (data.enumData == DurationEnum.Height) {
    //         return
    //             Expiration({
    //                 enumData: ExpirationEnum.atHeight,
    //                 data: ExpirationData({
    //                     height: block.number + data.data.height,
    //                     time: 0
    //                 })
    //             });
    //     } else if (data.enumData == DurationEnum.Time) {
    //         return
    //             Expiration({
    //                 enumData: ExpirationEnum.atTime,
    //                 data: ExpirationData({
    //                     height: 0,
    //                     time: block.timestamp + data.data.time
    //                 })
    //             });
    //     } else {
    //         revert("Duration not configured");
    //     }
    // }

    enum ExpirationEnum {
        atHeight,
        atTime,
        Never
    }

    struct ExpirationData {
        uint256 height;
        uint256 time;
    }

    struct Expiration {
        ExpirationEnum enumData;
        ExpirationData data;
    }

    struct Threshold {
        ThresholdEnum enumData;
        ThresholdData data;
    }

    enum CurveTypeEnum {
        Constant,
        Linear,
        SquarRoot
    }

    //TODO: remove if unused
    // function getReserveRatio(CurveTypeEnum curCurveType)
    //     public
    //     pure
    //     returns (uint256)
    // {
    //     if (curCurveType == CurveTypeEnum.Linear) {
    //         return 500000;
    //     } else if (curCurveType == CurveTypeEnum.SquarRoot) {
    //         return 660000;
    //     } else {
    //         return 1000000;
    //     }
    // }

    struct CurveTypeData {
        uint128 value;
        uint256 scale;
        uint128 slope;
        uint128 power;
    }

    struct CurveType {
        CurveTypeEnum curve_type;
        CurveTypeData data;
    }

    enum TokenType {
        ExistingCw20,
        NewCw20,
        BondingCurve
    }

    struct DaoTokenData {
        address existingCw20Data;
        uint256 newCw20InitialSupply;
        string newCw20Name;
        string newCw20Symbol;
        CurveType bondingCurveCurveType;
        string bondingCurveName;
        string bondingCurveSymbol;
        uint256 bondingCurveDecimals;
        address bondingCurveReserveDenom;
        uint256 bondingCurveReserveDecimals;
        uint256 bondingCurveUnbondingPeriod;
    }

    struct DaoToken {
        TokenType token;
        DaoTokenData data;
    }

    struct DaoSetup {
        uint256 quorum; //: Decimal,
        uint256 threshold; //: Decimal,
        uint256 votingPeriod; //: u64,
        uint256 timelockPeriod; //: u64,
        uint256 expirationPeriod; //: u64,
        uint128 proposalDeposit; //: Uint128,
        uint256 snapshotPeriod; //: u64,
        DaoToken token; //: DaoToken,
    }

    struct Delegate {
        address Addr;
        uint256 expires; // datetime int of delegation expiry
    }

    function canTakeAction(
        Delegate storage self,
        address sender,
        uint256 envTime
    ) public view returns (bool) {
        if (
            sender == self.Addr &&
            (self.expires == 0 || envTime <= self.expires)
        ) {
            return true;
        } else {
            return false;
        }
    }

    struct EndowmentFee {
        address payoutAddress;
        uint256 feePercentage;
        bool active;
    }

    struct SettingsPermission {
        bool ownerControlled;
        bool govControlled;
        bool modifiableAfterInit;
        Delegate delegate;
    }

    function setDelegate(
        SettingsPermission storage self,
        address sender,
        address owner,
        address gov,
        address delegateAddr,
        uint256 delegateExpiry
    ) public {
        if (
            (sender == owner && self.ownerControlled) ||
            (gov != address(0) && self.govControlled && sender == gov)
        ) {
            self.delegate = Delegate({
                Addr: delegateAddr,
                expires: delegateExpiry
            });
        }
    }

    function revokeDelegate(
        SettingsPermission storage self,
        address sender,
        address owner,
        address gov,
        uint256 envTime
    ) public {
        if (
            (sender == owner && self.ownerControlled) ||
            (gov != address(0) && self.govControlled && sender == gov) ||
            (self.delegate.Addr != address(0) &&
                canTakeAction(self.delegate, sender, envTime))
        ) {
            self.delegate = Delegate({Addr: address(0), expires: 0});
        }
    }

    function canChange(
        SettingsPermission storage self,
        address sender,
        address owner,
        address gov,
        uint256 envTime
    ) public view returns (bool) {
        if (
            (sender == owner && self.ownerControlled) ||
            (gov != address(0) && self.govControlled && sender == gov) ||
            (self.delegate.Addr != address(0) &&
                canTakeAction(self.delegate, sender, envTime))
        ) {
            return self.modifiableAfterInit;
        }
        return false;
    }

    struct SettingsController {
        SettingsPermission endowmentController;
        SettingsPermission strategies;
        SettingsPermission whitelistedBeneficiaries;
        SettingsPermission whitelistedContributors;
        SettingsPermission maturityWhitelist;
        SettingsPermission maturityTime;
        SettingsPermission profile;
        SettingsPermission earningsFee;
        SettingsPermission withdrawFee;
        SettingsPermission depositFee;
        SettingsPermission aumFee;
        SettingsPermission kycDonorsOnly;
        SettingsPermission name;
        SettingsPermission image;
        SettingsPermission logo;
        SettingsPermission categories;
        SettingsPermission splitToLiquid;
        SettingsPermission ignoreUserSplits;
    }

    function getPermissions(
        SettingsController storage _tempObject,
        string memory name
    ) public view returns (SettingsPermission storage) {
        if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("endowmentController"))
        ) {
            return _tempObject.endowmentController;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("maturityWhitelist"))
        ) {
            return _tempObject.maturityWhitelist;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("splitToLiquid"))
        ) {
            return _tempObject.splitToLiquid;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("ignoreUserSplits"))
        ) {
            return _tempObject.ignoreUserSplits;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("strategies"))
        ) {
            return _tempObject.strategies;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("whitelistedBeneficiaries"))
        ) {
            return _tempObject.whitelistedBeneficiaries;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("whitelistedContributors"))
        ) {
            return _tempObject.whitelistedContributors;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("maturityTime"))
        ) {
            return _tempObject.maturityTime;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("profile"))
        ) {
            return _tempObject.profile;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("earningsFee"))
        ) {
            return _tempObject.earningsFee;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("withdrawFee"))
        ) {
            return _tempObject.withdrawFee;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("depositFee"))
        ) {
            return _tempObject.depositFee;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("aumFee"))
        ) {
            return _tempObject.aumFee;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("kycDonorsOnly"))
        ) {
            return _tempObject.kycDonorsOnly;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("name"))
        ) {
            return _tempObject.name;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("image"))
        ) {
            return _tempObject.image;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("logo"))
        ) {
            return _tempObject.logo;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("categories"))
        ) {
            return _tempObject.categories;
        } else {
            revert("InvalidInputs");
        }
    }

    // None at the start as pending starts at 1 in ap rust contracts (in cw3 core)
    enum Status {
        None,
        Pending,
        Open,
        Rejected,
        Passed,
        Executed
    }
    enum Vote {
        Yes,
        No,
        Abstain,
        Veto
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

library AddressArray {
    function indexOf(address[] memory arr, address searchFor)
        internal
        pure
        returns (uint256, bool)
    {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == searchFor) {
                return (i, true);
            }
        }
        // not found
        return (0, false);
    }

    function remove(address[] storage data, uint256 index)
        internal
        returns (address[] memory)
    {
        if (index >= data.length) {
            revert("Error in remove: internal");
        }

        for (uint256 i = index; i < data.length - 1; i++) {
            data[i] = data[i + 1];
        }
        data.pop();
        return data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

library Array {
    function quickSort(
        uint256[] memory arr,
        int256 left,
        int256 right
    ) internal pure {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        uint256 pivot = arr[uint256(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint256(i)] < pivot) i++;
            while (pivot < arr[uint256(j)]) j--;
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (
                    arr[uint256(j)],
                    arr[uint256(i)]
                );
                i++;
                j--;
            }
        }
        if (left < j) quickSort(arr, left, j);
        if (i < right) quickSort(arr, i, right);
    }

    function sort(uint256[] memory data)
        internal
        pure
        returns (uint256[] memory)
    {
        quickSort(data, int256(0), int256(data.length - 1));
        return data;
    }

    function max(uint256[] memory data) internal pure returns (uint256) {
        uint256 curMax = data[0];
        for (uint256 i = 1; i < data.length; i++) {
            if (curMax < data[i]) {
                curMax = data[i];
            }
        }

        return curMax;
    }

    // function min(uint256[] memory data) internal pure returns (uint256) {
    //     uint256 curMin = data[0];
    //     for (uint256 i = 1; i < data.length; i++) {
    //         if (curMin > data[i]) {
    //             curMin = data[i];
    //         }
    //     }

    //     return curMin;
    // }

    function indexOf(uint256[] memory arr, uint256 searchFor)
        internal
        pure
        returns (uint256, bool)
    {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == searchFor) {
                return (i, true);
            }
        }
        // not found
        return (0, false);
    }

    function remove(uint256[] storage data, uint256 index)
        internal
        returns (uint256[] memory)
    {
        if (index >= data.length) {
            revert("Error in remove: internal");
        }

        for (uint256 i = index; i < data.length - 1; i++) {
            data[i] = data[i + 1];
        }
        data.pop();
        return data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/Address.sol";

library Utils {
    function _execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas
    ) internal {
        string memory errorMessage = "call reverted without message";
        for (uint256 i = 0; i < targets.length; ++i) {
            (bool success, bytes memory returndata) = targets[i].call{
                value: values[i]
            }(calldatas[i]);
            Address.verifyCallResult(success, returndata, errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}