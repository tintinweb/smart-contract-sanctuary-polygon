/**
 *Submitted for verification at polygonscan.com on 2023-06-13
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity 0.8.19;

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

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


// File @openzeppelin/contracts-upgradeable/token/ERC20/extensions/[email protected]

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


// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]

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


// File @openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeabl[email protected]

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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

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


// File contracts/common/NonReentrancy.sol

contract NonReentrancy {

    uint256 private islocked;

    // No additional state variables should be added here.
    // We won't upgrade this file.

    modifier noReenter() {
        require(islocked == 0, 'Tidal: LOCKED');
        islocked = 1;
        _;
        islocked = 0;
    }

    modifier noReenterView() {
        require(islocked == 0, 'Tidal: LOCKED');
        _;
    }
}


// File contracts/interface/IEventAggregator.sol

interface IEventAggregator {

    function setEventAggregator(
        address oldAggregator_,
        address newAggregator_
    ) external;

    function enablePool(
        bool enabled_
    ) external;

    function buy(
        address who_,
        uint256 policyIndex_,
        uint256 amount_,
        uint256 fromWeek_,
        uint256 toWeek_,
        string calldata notes_
    ) external;

    function deposit(
        address who_,
        uint256 amount_
    ) external;

    function withdraw(
        address who_,
        uint256 requestIndex_,
        uint256 share_
    ) external;

    function withdrawPending(
        address who_,
        uint256 requestIndex_
    ) external;

    function withdrawReady(
        address who_,
        uint256 requestIndex_,
        bool succeeded_
    ) external;

    function refund(
        uint256 policyIndex_,
        uint256 week_,
        address who_,
        uint256 amount_
    ) external;

    function claim(
        uint256 requestIndex_,
        uint256 policyIndex_,
        uint256 amount_,
        address receipient_
    ) external;

    function changePoolManager(
        uint256 requestIndex_,
        address poolManager_
    ) external;

    function addToCommittee(
        uint256 requestIndex_,
        address who_
    ) external;

    function removeFromCommittee(
        uint256 requestIndex_,
        address who_
    ) external;

    function changeCommitteeThreshold(
        uint256 requestIndex_,
        uint256 threshold_
    ) external;

    function voteAndSupport(
        uint256 requestIndex_
    ) external;

    function execute(
        uint256 requestIndex_,
        uint256 operation_,
        bytes calldata data_
    ) external;
}


// File contracts/model/PoolModel.sol

contract PoolModel {
    bool public isTest;

    address public baseToken;
    address public tidalToken;

    uint256 public withdrawWaitWeeks1;
    uint256 public withdrawWaitWeeks2;
    uint256 public policyWeeks;

    // withdrawFee is a percentage.
    uint256 public withdrawFee;

    // managementFee1 is a percentage and charged as shares.
    uint256 public managementFee1;

    // managementFee2 is a percentage and charged as tokens.
    uint256 public managementFee2;

    // Minimum deposit amount.
    uint256 public minimumDepositAmount;

    bool public enabled;
    string public name;
    string public terms;

    bool public locked;

    struct Policy {
        uint256 collateralRatio;
        uint256 weeklyPremium;
        string name;
        string terms;
    }

    Policy[] public policyArray;

    // policy index => week => amount
    mapping(uint256 => mapping(uint256 => uint256)) public coveredMap;

    struct PoolInfo {
        // Base token amount
        uint256 totalShare;
        uint256 amountPerShare;

        // Pending withdraw share
        uint256 pendingWithdrawShare;

        // Tidal Rewards
        uint256 accTidalPerShare;
    }

    PoolInfo public poolInfo;

    struct UserInfo {
        // Base token amount
        uint256 share;

        // Pending withdraw share
        uint256 pendingWithdrawShare;

        // Tidal Rewards
        uint256 tidalPending;
        uint256 tidalDebt;
    }

    mapping(address => UserInfo) public userInfoMap;

    // week => share
    mapping(uint256 => uint256) public poolWithdrawMap;

    enum WithdrawRequestStatus {
        Created,
        Pending,
        Executed
    }

    struct WithdrawRequest {
        uint256 share;
        uint256 time;
        WithdrawRequestStatus status;
        bool succeeded;
    }

    mapping(address => WithdrawRequest[]) public withdrawRequestMap;

    // policy index => week => Income
    mapping(uint256 => mapping(uint256 => uint256)) public incomeMap;

    struct Coverage {
        uint256 amount;
        uint256 premium;
        bool refunded;
    }

    // policy index => week => who => Coverage
    mapping(uint256 => mapping(uint256 => mapping(
        address => Coverage))) public coverageMap;

    mapping(uint256 => mapping(uint256 => uint256)) public refundMap;

    // Committee request.

    enum CommitteeRequestType {
        None,
        Claim,  // #1
        ChangePoolManager,  // #2
        AddToCommittee,  // #3
        RemoveFromCommittee,  // #4
        ChangeCommitteeThreshold  // #5
    }

    struct CommitteeRequest {
        uint256 time;
        uint256 vote;
        bool executed;
        CommitteeRequestType operation;
        bytes data;
    }

    CommitteeRequest[] public committeeRequestArray;

    // Vote.
    mapping(address => mapping(uint256 => bool)) committeeVote;

    // Access control.

    address public poolManager;

    mapping(address => uint256) public committeeIndexPlusOne;
    address[] public committeeArray;
    uint256 public committeeThreshold;

    // Time control.
    uint256 public timeExtra;

    // Event aggregator.
    address public eventAggregator;

    // This is a storage gap in case more state variables will be added
    // in the future.
    uint256[49] __gap;
}


// File contracts/Pool.sol

contract Pool is Initializable, NonReentrancy, ContextUpgradeable, PoolModel {

    using SafeERC20Upgradeable for IERC20Upgradeable;
 
    uint256 constant SHARE_UNITS = 1e18;
    uint256 constant AMOUNT_PER_SHARE = 1e18;
    uint256 constant VOTE_EXPIRATION = 3 days;
    uint256 constant RATIO_BASE = 1e6;
    uint256 constant TIME_OFFSET = 4 days;

    constructor(bool isTest_) {
        if (!isTest_) {
            _disableInitializers();
        }
    }

    function initialize(
        address baseToken_,
        address tidalToken_,
        bool isTest_,
        address poolManager_,
        address[] calldata committeeMembers_
    ) public initializer {
        baseToken = baseToken_;
        tidalToken = tidalToken_;
        isTest = isTest_;
        committeeThreshold = 2;

        require(poolManager_ != address(0), "Empty poolManager");
        require(committeeMembers_.length >= 2, "At least 2 initial members");

        poolManager = poolManager_;
        for (uint256 i = 0; i < committeeMembers_.length; ++i) {
            for (uint256 j = i + 1; j < committeeMembers_.length; ++j) {
                require(committeeMembers_[i] != committeeMembers_[j],
                        "Duplicated committee members");
            }

            address member = committeeMembers_[i];
            committeeArray.push(member);
            committeeIndexPlusOne[member] = committeeArray.length;
        }
    }

    modifier onlyPoolManager() {
        require(poolManager == _msgSender(), "Only pool manager");
        _;
    }

    modifier onlyTest() {
        require(isTest, "Only enabled in test environment");
        _;
    }

    modifier onlyCommittee() {
        require(committeeIndexPlusOne[_msgSender()] > 0, "Only committee");
        _;
    }

    // ** Time related functions.

    function setTimeExtra(uint256 timeExtra_) external onlyTest {
        timeExtra = timeExtra_;
    }

    function getCurrentWeek() public view returns(uint256) {
        return (block.timestamp + TIME_OFFSET + timeExtra) / (7 days);
    }

    function getNow() public view returns(uint256) {
        return block.timestamp + timeExtra;
    }

    function getWeekFromTime(uint256 time_) public pure returns(uint256) {
        return (time_ + TIME_OFFSET) / (7 days);
    }

    function getUnlockTime(
        uint256 time_,
        uint256 waitWeeks_
    ) public pure returns(uint256) {
        require(time_ + TIME_OFFSET > (7 days), "Time not large enough");
        return ((time_ + TIME_OFFSET) / (7 days) + waitWeeks_) * (7 days) - TIME_OFFSET;
    }

    // ** Event aggregator

    function setEventAggregator(
        address eventAggregator_
    ) external onlyPoolManager {
        require(eventAggregator_ != eventAggregator, "Value no difference");

        if (eventAggregator != address(0)) {
            IEventAggregator(eventAggregator).setEventAggregator(
                eventAggregator,
                eventAggregator_
            );
        }

        if (eventAggregator_ != address(0)) {
            IEventAggregator(eventAggregator_).setEventAggregator(
                eventAggregator,
                eventAggregator_
            );
        }

        eventAggregator = eventAggregator_;
    }

    // ** Pool and policy config.

    function getPool() external view noReenterView returns(
        uint256 withdrawWaitWeeks1_,
        uint256 withdrawWaitWeeks2_,
        uint256 policyWeeks_,
        uint256 withdrawFee_,
        uint256 managementFee1_,
        uint256 managementFee2_,
        uint256 minimumDepositAmount_,
        bool enabled_,
        string memory name_,
        string memory terms_
    ) {
        withdrawWaitWeeks1_ = withdrawWaitWeeks1;
        withdrawWaitWeeks2_ = withdrawWaitWeeks2;
        policyWeeks_ = policyWeeks;
        withdrawFee_ = withdrawFee;
        managementFee1_ = managementFee1;
        managementFee2_ = managementFee2;
        minimumDepositAmount_ = minimumDepositAmount;
        enabled_ = enabled;
        name_ = name;
        terms_ = terms;
    }

    function setPool(
        uint256 withdrawWaitWeeks1_,
        uint256 withdrawWaitWeeks2_,
        uint256 policyWeeks_,
        uint256 withdrawFee_,
        uint256 managementFee1_,
        uint256 managementFee2_,
        uint256 minimumDepositAmount_,
        bool enabled_,
        string calldata name_,
        string calldata terms_
    ) external onlyPoolManager {
        withdrawWaitWeeks1 = withdrawWaitWeeks1_;
        withdrawWaitWeeks2 = withdrawWaitWeeks2_;
        policyWeeks = policyWeeks_;
        withdrawFee = withdrawFee_;
        managementFee1 = managementFee1_;
        managementFee2 = managementFee2_;
        minimumDepositAmount = minimumDepositAmount_;
        enabled = enabled_;
        name = name_;
        terms = terms_;
    }

    function setPolicy(
        uint256 index_,
        uint256 collateralRatio_,
        uint256 weeklyPremium_,
        string calldata name_,
        string calldata terms_
    ) external onlyPoolManager {
        require(index_ < policyArray.length, "Invalid index");
        require(collateralRatio_ > 0, "Should be non-zero");
        require(weeklyPremium_ < RATIO_BASE, "Should be less than 100%");

        Policy storage policy = policyArray[index_];
        policy.collateralRatio = collateralRatio_;
        policy.weeklyPremium = weeklyPremium_;
        policy.name = name_;
        policy.terms = terms_;
    }

    function addPolicy(
        uint256 collateralRatio_,
        uint256 weeklyPremium_,
        string calldata name_,
        string calldata terms_
    ) external onlyPoolManager {
        require(collateralRatio_ > 0, "Should be non-zero");
        require(weeklyPremium_ < RATIO_BASE, "Should be less than 100%");

        policyArray.push(Policy({
            collateralRatio: collateralRatio_,
            weeklyPremium: weeklyPremium_,
            name: name_,
            terms: terms_
        }));
    }

    function getPolicyArrayLength() external view noReenterView returns(uint256) {
        return policyArray.length;
    }

    function getCollateralAmount() external view noReenterView returns(uint256) {
        return poolInfo.amountPerShare * (
            poolInfo.totalShare - poolInfo.pendingWithdrawShare) / SHARE_UNITS;
    }

    function getAvailableCapacity(
        uint256 policyIndex_,
        uint256 w_
    ) public view returns(uint256) {
        uint256 currentWeek = getCurrentWeek();
        uint256 amount = 0;
        uint256 w;

        if (w_ >= currentWeek + withdrawWaitWeeks1 || w_ < currentWeek) {
            return 0;
        } else {
            amount = poolInfo.amountPerShare * (
                poolInfo.totalShare - poolInfo.pendingWithdrawShare) / SHARE_UNITS;

            for (w = currentWeek - withdrawWaitWeeks1;
                 w < w_ - withdrawWaitWeeks1;
                 ++w) {
                amount -= poolInfo.amountPerShare * poolWithdrawMap[w] / SHARE_UNITS;
            }

            Policy storage policy = policyArray[policyIndex_];
            uint256 capacity = amount * RATIO_BASE / policy.collateralRatio;

            if (capacity > coveredMap[policyIndex_][w_]) {
                return capacity - coveredMap[policyIndex_][w_];
            } else {
                return 0;
            }
        }
    }

    function getCurrentAvailableCapacity(
        uint256 policyIndex_
    ) external view noReenterView returns(uint256) {
        uint256 w = getCurrentWeek();
        return getAvailableCapacity(policyIndex_, w);
    }

    function getTotalAvailableCapacity() external view noReenterView returns(uint256) {
        uint256 w = getCurrentWeek();

        uint256 total = 0;
        for (uint256 i = 0; i < policyArray.length; ++i) {
            total += getAvailableCapacity(i, w);
        }

        return total;
    }

    function getUserBaseAmount(address who_) external view noReenterView returns(uint256) {
        UserInfo storage userInfo = userInfoMap[who_];
        return poolInfo.amountPerShare * userInfo.share / SHARE_UNITS;
    }

    // ** Regular operations.

    // Anyone can be a buyer, and pay premium on certain policy for a few weeks.
    function buy(
        uint256 policyIndex_,
        uint256 amount_,
        uint256 maxPremium_,
        uint256 fromWeek_,
        uint256 toWeek_,
        string calldata notes_
    ) external noReenter {
        require(enabled, "Not enabled");

        require(toWeek_ > fromWeek_, "Not enough weeks");
        require(toWeek_ - fromWeek_ <= policyWeeks,
            "Too many weeks");
        require(fromWeek_ > getCurrentWeek(), "Buy next week");

        Policy storage policy = policyArray[policyIndex_];
        uint256 premium = amount_ * policy.weeklyPremium / RATIO_BASE;
        uint256 allPremium = premium * (toWeek_ - fromWeek_);

        require(allPremium <= maxPremium_, "Exceeds maxPremium_");

        uint256 maximumToCover = poolInfo.amountPerShare * (
            poolInfo.totalShare - poolInfo.pendingWithdrawShare) / SHARE_UNITS *
                    RATIO_BASE / policy.collateralRatio;

        for (uint256 w = fromWeek_; w < toWeek_; ++w) {
            incomeMap[policyIndex_][w] += premium;
            coveredMap[policyIndex_][w] += amount_;

            require(coveredMap[policyIndex_][w] <= maximumToCover,
                "Not enough to buy");

            Coverage storage entry = coverageMap[policyIndex_][w][_msgSender()];
            entry.amount += amount_;
            entry.premium += premium;
            entry.refunded = false;
        }

        IERC20Upgradeable(baseToken).safeTransferFrom(
            _msgSender(), address(this), allPremium);

        if (eventAggregator != address(0)) {
            IEventAggregator(eventAggregator).buy(
                _msgSender(),
                policyIndex_,
                amount_,
                fromWeek_,
                toWeek_,
                notes_
            );
        }
    }

    // Anyone just call this function once per week for every policy.
    function addPremium(uint256 policyIndex_) external noReenter {
        require(enabled, "Not enabled");

        uint256 week = getCurrentWeek();

        if (incomeMap[policyIndex_][week] == 0) {
            // Already added premium or no premium to add.
            return;
        }

        Policy storage policy = policyArray[policyIndex_];

        uint256 maximumToCover = poolInfo.amountPerShare * (
            poolInfo.totalShare - poolInfo.pendingWithdrawShare) / SHARE_UNITS *
                RATIO_BASE / policy.collateralRatio;

        uint256 allCovered = coveredMap[policyIndex_][week];

        if (allCovered > maximumToCover) {
            refundMap[policyIndex_][week] = incomeMap[policyIndex_][week] * (
                allCovered - maximumToCover) / allCovered;
            incomeMap[policyIndex_][week] -= refundMap[policyIndex_][week];
        }

        // Deducts management fee.
        uint256 totalIncome = incomeMap[policyIndex_][week];
        uint256 fee1 = totalIncome * managementFee1 / RATIO_BASE;
        uint256 fee2 = totalIncome * managementFee2 / RATIO_BASE;
        uint256 realIncome = totalIncome - fee1 - fee2;

        poolInfo.amountPerShare +=
            realIncome * SHARE_UNITS / poolInfo.totalShare;

        // Updates tidalPending (before Distributes fee1).
        UserInfo storage poolManagerInfo = userInfoMap[poolManager];
        uint256 accAmount = poolInfo.accTidalPerShare *
            poolManagerInfo.share / SHARE_UNITS;
        poolManagerInfo.tidalPending += accAmount - poolManagerInfo.tidalDebt;

        // Distributes fee1.
        uint256 fee1Share = fee1 * SHARE_UNITS / poolInfo.amountPerShare;
        poolManagerInfo.share += fee1Share;
        poolInfo.totalShare += fee1Share;

        // Updates tidalDebt.
        poolManagerInfo.tidalDebt = poolInfo.accTidalPerShare *
            poolManagerInfo.share / SHARE_UNITS;

        // Distributes fee2.
        IERC20Upgradeable(baseToken).safeTransfer(poolManager, fee2);

        incomeMap[policyIndex_][week] = 0;
    }

    // Anyone just call this function once per week for every policy.
    function refund(
        uint256 policyIndex_,
        uint256 week_,
        address who_
    ) external noReenter {
        require(refundMap[policyIndex_][week_] > 0, "Not ready to refund");

        Coverage storage coverage = coverageMap[policyIndex_][week_][who_];

        require(!coverage.refunded, "Already refunded");

        uint256 allCovered = coveredMap[policyIndex_][week_];
        uint256 amountToRefund = refundMap[policyIndex_][week_] *
            coverage.amount / allCovered;
        coverage.amount = coverage.amount *
            (coverage.premium - amountToRefund) / coverage.premium;
        coverage.refunded = true;

        IERC20Upgradeable(baseToken).safeTransfer(who_, amountToRefund);

        if (eventAggregator != address(0)) {
            IEventAggregator(eventAggregator).refund(
                policyIndex_,
                week_,
                who_,
                amountToRefund
            );
        }
    }

    // Anyone can be a seller, and deposit baseToken (e.g. USDC or WETH)
    // to the pool.
    function deposit(
        uint256 amount_
    ) external noReenter {
        require(enabled, "Not enabled");

        require(amount_ >= minimumDepositAmount, "Less than minimum");

        IERC20Upgradeable(baseToken).safeTransferFrom(
            _msgSender(), address(this), amount_);

        UserInfo storage userInfo = userInfoMap[_msgSender()];

        // Updates tidalPending.
        uint256 accAmount = poolInfo.accTidalPerShare *
            userInfo.share / SHARE_UNITS;
        userInfo.tidalPending += accAmount - userInfo.tidalDebt;

        if (poolInfo.totalShare == 0) {          
            poolInfo.amountPerShare = AMOUNT_PER_SHARE;
            poolInfo.totalShare = amount_ * SHARE_UNITS / AMOUNT_PER_SHARE;
            userInfo.share = poolInfo.totalShare;
        } else {
            uint256 shareToAdd =
                amount_ * SHARE_UNITS / poolInfo.amountPerShare;
            poolInfo.totalShare += shareToAdd;
            userInfo.share += shareToAdd;
        }

        // Updates tidalDebt.
        userInfo.tidalDebt = poolInfo.accTidalPerShare *
            userInfo.share / SHARE_UNITS;

        if (eventAggregator != address(0)) {
            IEventAggregator(eventAggregator).deposit(
                _msgSender(),
                amount_
            );
        }
    }

    function getUserAvailableWithdrawAmount(
        address who_
    ) external view noReenterView returns(uint256) {
        UserInfo storage userInfo = userInfoMap[who_];
        return poolInfo.amountPerShare * (
            userInfo.share - userInfo.pendingWithdrawShare) / SHARE_UNITS;
    }

    // Existing sellers can request to withdraw from the pool by shares.
    function withdraw(
        uint256 share_
    ) external noReenter {
        require(enabled, "Not enabled");

        UserInfo storage userInfo = userInfoMap[_msgSender()];

        require(userInfo.share >=
            userInfo.pendingWithdrawShare + share_, "Not enough");

        withdrawRequestMap[_msgSender()].push(WithdrawRequest({
            share: share_,
            time: getNow(),
            status: WithdrawRequestStatus.Created,
            succeeded: false
        }));

        userInfo.pendingWithdrawShare += share_;

        uint256 week = getCurrentWeek();
        poolWithdrawMap[week] += share_;

        if (eventAggregator != address(0)) {
            IEventAggregator(eventAggregator).withdraw(
                _msgSender(),
                withdrawRequestMap[_msgSender()].length - 1,
                share_
            );
        }
    }

    // Called after withdrawWaitWeeks1, by anyone (can be a script or by
    // seller himself).
    function withdrawPending(
        address who_,
        uint256 index_
    ) external noReenter {
        require(enabled, "Not enabled");

        require(index_ < withdrawRequestMap[who_].length, "No index");

        WithdrawRequest storage request = withdrawRequestMap[who_][index_];
        require(request.status == WithdrawRequestStatus.Created,
                "Wrong status");

        uint256 unlockTime = getUnlockTime(request.time, withdrawWaitWeeks1);
        require(getNow() > unlockTime, "Not ready yet");

        poolInfo.pendingWithdrawShare += request.share;

        request.status = WithdrawRequestStatus.Pending;

        if (eventAggregator != address(0)) {
            IEventAggregator(eventAggregator).withdrawPending(
                who_,
                index_
            );
        }
    }

    // Called after withdrawWaitWeeks2, by anyone.
    function withdrawReady(
        address who_,
        uint256 index_
    ) external noReenter {
        require(enabled, "Not enabled");

        require(index_ < withdrawRequestMap[who_].length, "No index");

        WithdrawRequest storage request = withdrawRequestMap[who_][index_];
        require(request.status == WithdrawRequestStatus.Pending,
                "Wrong status");

        uint256 waitWeeks = withdrawWaitWeeks1 + withdrawWaitWeeks2;
        uint256 unlockTime = getUnlockTime(request.time, waitWeeks);
        require(getNow() > unlockTime, "Not ready yet");

        UserInfo storage userInfo = userInfoMap[who_];

        if (userInfo.share >= request.share) {
            // Updates tidalPending.
            uint256 accAmount = poolInfo.accTidalPerShare *
                userInfo.share / SHARE_UNITS;
            userInfo.tidalPending += accAmount - userInfo.tidalDebt;

            userInfo.share -= request.share;
            poolInfo.totalShare -= request.share;

            // Updates tidalDebt.
            userInfo.tidalDebt = poolInfo.accTidalPerShare *
                userInfo.share / SHARE_UNITS;

            uint256 amount = poolInfo.amountPerShare *
                request.share / SHARE_UNITS;

            // A withdrawFee goes to everyone.
            uint256 fee = amount * withdrawFee / RATIO_BASE;
            IERC20Upgradeable(baseToken).safeTransfer(who_, amount - fee);
            poolInfo.amountPerShare += fee * SHARE_UNITS / poolInfo.totalShare;

            request.succeeded = true;
        } else {
            request.succeeded = false;
        }

        request.status = WithdrawRequestStatus.Executed;

        // Reduce pendingWithdrawShare.
        userInfo.pendingWithdrawShare -= request.share;
        poolInfo.pendingWithdrawShare -= request.share;

        if (eventAggregator != address(0)) {
            IEventAggregator(eventAggregator).withdrawReady(
                who_,
                index_,
                request.succeeded
            );
        }
    }

    function withdrawRequestCount(
        address who_
    ) external view noReenterView returns(uint256) {
        return withdrawRequestMap[who_].length;
    }

    // Anyone can add tidal to the pool as incentative any time.
    function addTidal(uint256 amount_) external noReenter {
        IERC20Upgradeable(tidalToken).safeTransferFrom(
            _msgSender(), address(this), amount_);

        poolInfo.accTidalPerShare +=
            amount_ * SHARE_UNITS / poolInfo.totalShare;
    }

    function getUserTidalAmount(address who_) external view noReenterView returns(uint256) {
        UserInfo storage userInfo = userInfoMap[who_];
        return poolInfo.accTidalPerShare * userInfo.share / SHARE_UNITS +
            userInfo.tidalPending - userInfo.tidalDebt;
    }

    // Sellers can withdraw TIDAL, which are bonuses, from the pool.
    function withdrawTidal() external noReenter {
        require(enabled, "Not enabled");

        UserInfo storage userInfo = userInfoMap[_msgSender()];
        uint256 accAmount = poolInfo.accTidalPerShare *
            userInfo.share / SHARE_UNITS;
        uint256 tidalAmount = userInfo.tidalPending +
            accAmount - userInfo.tidalDebt;

        IERC20Upgradeable(tidalToken).safeTransfer(_msgSender(), tidalAmount);

        userInfo.tidalPending = 0;
        userInfo.tidalDebt = accAmount;
    }

    // ** Emergency

    // Pool manager can enable or disable the pool in emergency.
    function enablePool(bool enabled_) external onlyPoolManager {
        enabled = enabled_;

        if (eventAggregator != address(0)) {
            IEventAggregator(eventAggregator).enablePool(
                enabled_
            );
        }
    }

    // ** Claim (and other type of requests), vote, and execute.

    // ** Operation #1, claim
    function claim(
        uint256 policyIndex_,
        uint256 amount_,
        address receipient_
    ) external onlyPoolManager {
        committeeRequestArray.push(CommitteeRequest({
            time: getNow(),
            vote: 0,
            executed: false,
            operation: CommitteeRequestType.Claim,
            data: abi.encode(policyIndex_, amount_, receipient_)
        }));

        if (eventAggregator != address(0)) {
            IEventAggregator(eventAggregator).claim(
                committeeRequestArray.length - 1,
                policyIndex_,
                amount_,
                receipient_
            );
        }
    }

    // ** Operation #2, changePoolManager
    function changePoolManager(
        address poolManager_
    ) external onlyCommittee {
        committeeRequestArray.push(CommitteeRequest({
            time: getNow(),
            vote: 0,
            executed: false,
            operation: CommitteeRequestType.ChangePoolManager,
            data: abi.encode(poolManager_)
        }));

        if (eventAggregator != address(0)) {
            IEventAggregator(eventAggregator).changePoolManager(
                committeeRequestArray.length - 1,
                poolManager_
            );
        }
    }

    // ** Operation #3, addToCommittee
    function addToCommittee(
        address who_
    ) external onlyCommittee {
        require(committeeIndexPlusOne[who_] == 0, "Existing committee member");

        committeeRequestArray.push(CommitteeRequest({
            time: getNow(),
            vote: 0,
            executed: false,
            operation: CommitteeRequestType.AddToCommittee,
            data: abi.encode(who_)
        }));

        if (eventAggregator != address(0)) {
            IEventAggregator(eventAggregator).addToCommittee(
                committeeRequestArray.length - 1,
                who_
            );
        }
    }

    // ** Operation #4, removeFromCommittee
    function removeFromCommittee(
        address who_
    ) external onlyCommittee {
        require(committeeArray.length > committeeThreshold,
                "Not enough members");

        committeeRequestArray.push(CommitteeRequest({
            time: getNow(),
            vote: 0,
            executed: false,
            operation: CommitteeRequestType.RemoveFromCommittee,
            data: abi.encode(who_)
        }));

        if (eventAggregator != address(0)) {
            IEventAggregator(eventAggregator).removeFromCommittee(
                committeeRequestArray.length - 1,
                who_
            );
        }
    }

    // ** Operation #5, changeCommitteeThreshold
    function changeCommitteeThreshold(
        uint256 threshold_
    ) external onlyCommittee {
        require(threshold_ >= 2, "Invalid threshold");
        require(threshold_ <= committeeArray.length,
                "Threshold more than member count");

        committeeRequestArray.push(CommitteeRequest({
            time: getNow(),
            vote: 0,
            executed: false,
            operation: CommitteeRequestType.ChangeCommitteeThreshold,
            data: abi.encode(threshold_)
        }));

        if (eventAggregator != address(0)) {
            IEventAggregator(eventAggregator).changeCommitteeThreshold(
                committeeRequestArray.length - 1,
                threshold_
            );
        }
    }

    // Committee members can vote on any of the above 5 types of operations.
    function voteAndSupport(
        uint256 requestIndex_
    ) external onlyCommittee noReenter {
        require(requestIndex_ < committeeRequestArray.length, "Invalid index");

        require(!committeeVote[_msgSender()][requestIndex_],
                "Already supported");
        committeeVote[_msgSender()][requestIndex_] = true;

        CommitteeRequest storage cr = committeeRequestArray[requestIndex_];

        require(getNow() < cr.time + VOTE_EXPIRATION,
                "Already expired");
        require(!cr.executed, "Already executed");
        cr.vote += 1;

        if (eventAggregator != address(0)) {
            IEventAggregator(eventAggregator).voteAndSupport(
                requestIndex_
            );
        }

        if (cr.vote >= committeeThreshold) {
            _execute(requestIndex_);
        }
    }

    // Anyone can execute an operation request that has received enough
    // approving votes.
    function _execute(uint256 requestIndex_) private {
        require(requestIndex_ < committeeRequestArray.length, "Invalid index");

        CommitteeRequest storage cr = committeeRequestArray[requestIndex_];

        require(cr.vote >= committeeThreshold, "Not enough votes");
        require(getNow() < cr.time + VOTE_EXPIRATION,
                "Already expired");
        require(!cr.executed, "Already executed");

        cr.executed = true;

        if (cr.operation == CommitteeRequestType.Claim) {
            (, uint256 amount, address receipient) = abi.decode(
                cr.data, (uint256, uint256, address));
            _executeClaim(amount, receipient);
        } else if (cr.operation == CommitteeRequestType.ChangePoolManager) {
            address poolManager = abi.decode(cr.data, (address));
            _executeChangePoolManager(poolManager);
        } else if (cr.operation == CommitteeRequestType.AddToCommittee) {
            address newMember = abi.decode(cr.data, (address));
            _executeAddToCommittee(newMember);
        } else if (cr.operation == CommitteeRequestType.RemoveFromCommittee) {
            address oldMember = abi.decode(cr.data, (address));
            _executeRemoveFromCommittee(oldMember);
        } else if (cr.operation ==
                CommitteeRequestType.ChangeCommitteeThreshold) {
            uint256 threshold = abi.decode(cr.data, (uint256));
            _executeChangeCommitteeThreshold(threshold);
        }

        if (eventAggregator != address(0)) {
            IEventAggregator(eventAggregator).execute(
                requestIndex_,
                uint256(cr.operation),
                cr.data
            );
        }
    }

    function _executeClaim(
        uint256 amount_,
        address receipient_
    ) private {
        IERC20Upgradeable(baseToken).safeTransfer(receipient_, amount_);

        poolInfo.amountPerShare -=
            amount_ * SHARE_UNITS / poolInfo.totalShare;
    }

    function _executeChangePoolManager(address poolManager_) private {
        poolManager = poolManager_;
    }

    function _executeAddToCommittee(address who_) private {
        require(committeeIndexPlusOne[who_] == 0, "Existing committee member");
        committeeArray.push(who_);
        committeeIndexPlusOne[who_] = committeeArray.length;
    }

    function _executeRemoveFromCommittee(address who_) private {
        require(committeeArray.length > committeeThreshold,
                "Not enough members");
        require(committeeIndexPlusOne[who_] > 0,
                "Non-existing committee member");
        if (committeeIndexPlusOne[who_] != committeeArray.length) {
            address lastOne = committeeArray[committeeArray.length - 1];
            committeeIndexPlusOne[lastOne] = committeeIndexPlusOne[who_];
            committeeArray[committeeIndexPlusOne[who_] - 1] = lastOne;
        }

        committeeIndexPlusOne[who_] = 0;
        committeeArray.pop();
    }

    function _executeChangeCommitteeThreshold(uint256 threshold_) private {
        require(threshold_ >= 2, "Invalid threshold");
        require(threshold_ <= committeeArray.length,
                "Threshold more than member count");
        committeeThreshold = threshold_;
    }

    function getCommitteeRequestLength() external view noReenterView returns(uint256) {
        return committeeRequestArray.length;
    }

    function getCommitteeRequestArray(
        uint256 limit_,
        uint256 offset_
    ) external view noReenterView returns(CommitteeRequest[] memory, uint256[] memory) {
        if (committeeRequestArray.length <= offset_) {
            return (new CommitteeRequest[](0), new uint256[](0));
        }

        uint256 leftSideOffset = committeeRequestArray.length - offset_;
        CommitteeRequest[] memory result =
            new CommitteeRequest[](
                leftSideOffset < limit_ ? leftSideOffset : limit_);
        uint256[] memory indexArray =
            new uint256[](
                leftSideOffset < limit_ ? leftSideOffset : limit_);

        uint256 i = 0;
        while (i < limit_ && leftSideOffset > 0) {
            leftSideOffset -= 1;
            result[i] = committeeRequestArray[leftSideOffset];
            indexArray[i] = leftSideOffset;
            i += 1;
        }

        return (result, indexArray);
    }
}