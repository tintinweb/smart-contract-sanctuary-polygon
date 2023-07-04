/**
 *Submitted for verification at polygonscan.com on 2023-07-03
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/security/ReentrancyGuard.sol

// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol

// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionCallWithValue(
                target,
                data,
                0,
                "Address: low-level call failed"
            );
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
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

    function _revert(bytes memory returndata, string memory errorMessage)
        private
        pure
    {
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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol

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
library SafeERC20 {
    using Address for address;

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                oldAllowance + value
            )
        );
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    oldAllowance - value
                )
            );
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        bytes memory approvalCall = abi.encodeWithSelector(
            token.approve.selector,
            spender,
            value
        );

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(token.approve.selector, spender, 0)
            );
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        require(
            nonceAfter == nonceBefore + 1,
            "SafeERC20: permit did not succeed"
        );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        require(
            returndata.length == 0 || abi.decode(returndata, (bool)),
            "SafeERC20: ERC20 operation did not succeed"
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data)
        private
        returns (bool)
    {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success &&
            (returndata.length == 0 || abi.decode(returndata, (bool))) &&
            Address.isContract(address(token));
    }
}

// File: @openzeppelin/contracts/interfaces/IERC20.sol

// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/security/Pausable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() private view returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// File: contracts/Fantazy.sol

/**
 * @author Vijay Sugali
 * @name Fantazy for cricket
 * @description to record all fantasy cricket events on blockchain
 */

pragma solidity 0.8.19;

contract FantazyV2 is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    /* Range of minimum and maximum */
    struct Range {
        uint8 minimum;
        uint8 maximum;
    }

    /* Team criteria */
    struct TeamCriteria {
        Range totalPlayers;
        Range eachTeam;
        Range category1;
        Range category2;
        Range category3;
        Range category4;
        Range category5;
    }

    /* Struct of different sport */
    struct Sport {
        string name;
        uint256 captainMultiplier;
        uint256 viceCaptainMultiplier;
        uint256 joinTeamsLimit; // per pool
        TeamCriteria teamCriteria;
    }
    /* mapping for each sport data :: sport id to sport */
    mapping(uint256 => Sport) private sportData;
    /* mapping to get if sport exist :: sportId to bool */
    mapping(uint256 => bool) private hasSport;
    /* mapping to make an user counted :: sportId to user address to bool */
    mapping(uint256 => mapping(address => bool)) private isSportUser;
    /* primary state for sports count in Fantazy */
    uint256 private sportsCount;

    /* Struct to store supported currencies */
    struct Currencies {
        string name;
        address erc20;
        uint256 decimals;
        bool isErc20;
        uint256 protocolBonusStakedAmount;
        uint256 protocolPaidStakedAmount;
    }
    /* mapping for each currency :: currency id to currency */
    mapping(uint256 => Currencies) private currencyData;
    /* mapping to get if currency exist :: currencyId to bool */
    mapping(uint256 => bool) private hasCurrency;
    /* total number of currencies supported */
    uint256 private currenciesCount;

    struct Player {
        uint8 category;
        uint8 team; // 1 for team-A, 2 for team-B
        uint256 points;
    }

    /* A struct for new match */
    struct Event {
        string eventName;
        uint256 sportId;
        uint256 startTime;
        uint256[] teamAsquad;
        uint256[] teamBsquad;
    }
    /* mapping for each event :: eventId to Event */
    mapping(uint256 => Event) private eventData;
    /* mapping from event id to player id to player struct */
    mapping(uint256 => mapping(uint256 => Player)) private playerData;

    /* Struct for a bucket of prizes */
    struct PrizeBucket {
        uint256 from;
        uint256 to;
        uint256 amount;
    }

    /* A struct for all pools */
    struct Pool {
        uint256 eventId;
        uint256 contestType; // 1 for grand, 2 for H2H
        uint256 currencyId;
        uint256 entryFee;
        uint256 discountPercentNumerator;
        uint256 discountPercentDenominator;
        uint256 teamsJoinedCount;
        uint256 paidStakedAmount;
        uint256 bonusStakedAmount;
        uint256 paidStakedClaimedAmount;
        uint256 bonusStakedClaimedAmount;
        Range poolLimit;
        PrizeBucket[20] winningsTable;
        bool isWinningsTableUpdated;
        bool isCommissionWithdrawn;
    }
    /* mapping for each pool :: poolId to Pool */
    mapping(uint256 => Pool) private poolData;

    /* 
        mapping to find an user total teams joined in a pool.
        poolId to user address to teamsCount 
    */
    mapping(uint256 => mapping(address => uint256)) private joinTeamsCount;
    /* 
        mapping to find if a team is participated in pool.
        teamId to poolId to bool 
    */
    mapping(uint256 => mapping(uint256 => bool)) private isTeamParticipated;

    /* Struct for all the teams */
    struct Team {
        address user;
        string teamName;
        uint256 eventId;
        uint256 selectedCaptain;
        uint256 selectedViceCaptain;
        uint256 totalPlayersCount;
        uint256 teamACount;
        uint256 teamBCount;
        uint256 category1Count;
        uint256 category2Count;
        uint256 category3Count;
        uint256 category4Count;
        uint256 category5Count;
        uint256 paidPaymentType; // 1 - crypto wallet, 2 - bonus wallet
        uint256[] selectedPlayers;
    }
    /* mapping for each team :: sportId to teamId to Team */
    mapping(uint256 => Team) private teamData;
    /* mapping to know if refund claimed for pool :: poolId to teamId to bool */
    mapping(uint256 => mapping(uint256 => bool)) private isFeeRefunded;
    /* mapping to know if prize claimed for pool :: poolId to teamId to bool */
    mapping(uint256 => mapping(uint256 => bool)) private isPrizeClaimed;

    /* Fantazy commission percentage in fraction */
    struct Commission {
        uint256 numerator;
        uint256 denominator;
    }

    /* Other declarations */
    Commission private protocolCommission;
    /* matic received to the contract */
    uint256 private receivedAmount;
    uint256 public eventsCount;
    uint256 public poolsCount;
    uint256 public teamsCount;
    uint256 public usersCount;
    string public appUrl;
    mapping(address => bool) private isFantazyUser;

    /* Events */
    // event AddNewEvent(
    //     uint256 indexed _eventId,
    //     string indexed _eventName,
    //     uint256 indexed _startTime,
    //     uint256[] teamAsquad,
    //     uint256[] teamBsquad
    // );

    // event AddNewPool(
    //     uint256 indexed _poolId,
    //     uint256 indexed _contestType,
    //     uint256 indexed _currencyId,
    //     uint256 _entryFee,
    //     Range _poolLimit
    // );

    event CreateNewTeam(
        uint256 indexed _teamId,
        uint256 indexed _eventId,
        address indexed _user,
        string _teamName,
        uint256[] _selectedPlayers
    );

    event UpdateTeam(
        uint256 indexed _teamId,
        uint256 indexed _eventId,
        address indexed _user,
        uint256[] _selectedPlayers,
        uint256 _timestamp
    );

    event JoinContest(
        uint256 indexed _teamId,
        uint256 indexed _poolId,
        uint256 _paymentType,
        address indexed user,
        uint256 _timestamp
    );

    event Claim(
        uint256 indexed _teamId,
        uint256 indexed _poolId,
        address indexed _user,
        uint256 _amount,
        uint256 _timestamp
    );


    /// An error occurred in smart contract with `errorId`
    error CustomError(uint256 errorId);

    // event Withdraw(
    //     uint256 indexed _currencyId,
    //     uint256 indexed _poolId,
    //     bool indexed _isForce,
    //     uint256 _amount,
    //     uint256 _timestamp
    // );

    /* Initialize the constructor values */
    constructor(
        uint256 _sportsCount,
        uint256 _eventsCount,
        uint256 _poolsCount,
        uint256 _teamsCount,
        uint256 _usersCount,
        uint256 _commissionNumerator,
        uint256 _commissionDenominator,
        string memory _appUrl
    ) {
        sportsCount = _sportsCount;
        eventsCount = _eventsCount;
        poolsCount = _poolsCount;
        teamsCount = _teamsCount;
        usersCount = _usersCount;
        protocolCommission = Commission(
            _commissionNumerator,
            _commissionDenominator
        );
        appUrl = _appUrl;
    }

    receive() external payable {
        receivedAmount += msg.value;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unPause() public onlyOwner {
        _unpause();
    }

    function changeData(string memory _appUrl, uint256 _commissionNumerator, uint256 _commissionDenominator) public onlyOwner{
        appUrl = _appUrl;
        protocolCommission.numerator = _commissionNumerator;
        protocolCommission.denominator = _commissionDenominator;
    }

    function insertSportData(
        string memory _name,
        uint256 _sportId,
        uint256 _captainMultiplier,
        uint256 _viceCaptainMultiplier,
        uint256 _userTeamsLimit,
        TeamCriteria memory _teamCriteria
    ) public onlyOwner nonReentrant whenNotPaused {
        if (!hasSport[_sportId]) {
            sportsCount++;
            hasSport[_sportId] = true;
        }
        sportData[_sportId] = Sport(
            _name,
            _captainMultiplier,
            _viceCaptainMultiplier,
            _userTeamsLimit,
            _teamCriteria
        );
    }

    function insertCurrencyData(
        string memory _name,
        uint256 _currencyId,
        address _erc20,
        uint256 _decimals,
        bool _isErc20
    ) public onlyOwner nonReentrant whenNotPaused {
        if (!hasCurrency[_currencyId]) {
            currenciesCount++;
            hasCurrency[_currencyId] = true;
        }
        currencyData[_currencyId] = Currencies(
            _name,
            _erc20,
            _decimals,
            _isErc20,
            0,
            0
        );
    }

    function addNewEvent(
        uint256 _sportId,
        uint256 _eventId,
        uint256 _startTime,
        string memory _eventName,
        uint256[] memory _teamAsquad,
        uint8[] memory _teamAsquadCategories,
        uint256[] memory _teamBsquad,
        uint8[] memory _teamBsquadCategories
    ) public onlyOwner nonReentrant whenNotPaused {
        require(
            _startTime > block.timestamp &&
            eventData[_eventId].startTime == 0 &&
            _teamAsquad.length == _teamAsquadCategories.length &&
            _teamBsquad.length == _teamBsquadCategories.length,
            "Fantazy :: Invalid event details"
        );
        eventData[_eventId] = Event(
            _eventName,
            _sportId,
            _startTime,
            _teamAsquad,
            _teamBsquad
        );
        
        for (uint256 i = 0; i < _teamAsquad.length; i++) {
            playerData[_eventId][_teamAsquad[i]] = Player(
                _teamAsquadCategories[i],
                1,
                0
            );
        }
        for (uint256 i = 0; i < _teamBsquad.length; i++) {
            playerData[_eventId][_teamBsquad[i]] = Player(
                _teamBsquadCategories[i],
                2,
                0
            );
        }
        eventsCount++;
        // emit AddNewEvent(
        //     _eventId,
        //     _eventName,
        //     _startTime,
        //     eventData[_eventId].teamAsquad,
        //     eventData[_eventId].teamBsquad
        // );
    }

    function insertPlayerPoints(
        uint256 _eventId,
        uint256[] memory _playerIds,
        uint256[] memory _playerPoints
    ) public onlyOwner nonReentrant whenNotPaused {
        for (uint256 i = 0; i < _playerIds.length; i++) {
            playerData[_eventId][_playerIds[i]].points = _playerPoints[i];
        }
    }

    function updateWinnings(
        uint256 _poolId,
        PrizeBucket[] memory _winningsTable
    ) public onlyOwner nonReentrant whenNotPaused {
        require(
            poolData[_poolId].eventId > 0 && // pool should exist
            _winningsTable.length > 0 && // winnings table should present
            poolData[_poolId].poolLimit.maximum >
            poolData[_poolId].teamsJoinedCount, // you can only update winnings when enough users not joined on pool
            "Fantazy :: Invalid winnings table details "
        );
        uint256 totalPoolAmount = poolData[_poolId].entryFee *
            poolData[_poolId].teamsJoinedCount;
        uint256 poolPlatformCommission = (totalPoolAmount *
            protocolCommission.numerator) / protocolCommission.denominator;
        uint256 distributionAmount = totalPoolAmount - poolPlatformCommission;
        uint256 winningsAmount = 0;
        uint256 bucketStart;
        for (uint8 i = 0; i < _winningsTable.length; i++) {
            require(
                _winningsTable[i].from > 0 &&
                _winningsTable[i].to >= _winningsTable[i].from &&
                _winningsTable[i].from > bucketStart,
                "Fantazy :: Invalid winnings table"
            );
            if (_winningsTable[i].from == _winningsTable[i].to) {
                winningsAmount += _winningsTable[i].amount;
            } else if (_winningsTable[i].from != _winningsTable[i].to) {
                winningsAmount +=
                    (_winningsTable[i].to - _winningsTable[i].from + 1) *
                    _winningsTable[i].amount;
            }
            bucketStart = _winningsTable[i].to;
            poolData[_poolId].winningsTable[i] = _winningsTable[i];
        }
        if(winningsAmount != distributionAmount){
            revert CustomError(1);
        }
        poolData[_poolId].isWinningsTableUpdated = true;
    }

    function addNewPool(
        uint256 _eventId,
        uint256 _poolId,
        uint256 _contestType,
        uint256 _currencyId,
        uint256 _entryFee,
        Range calldata _poolLimit,
        uint256 _discountPercentNumerator,
        uint256 _discountPercentDenominator,
        PrizeBucket[] memory _winningsTable
    ) public onlyOwner nonReentrant whenNotPaused {
        require(
            eventData[_eventId].startTime > 0 && // event should exist
            poolData[_poolId].entryFee == 0 && // pool id should be available
            currencyData[_currencyId].decimals > 0 && // currency should be enrolled
            _entryFee > 0 &&
            _poolLimit.minimum > 0 &&
            _discountPercentDenominator > 0 &&
            _poolLimit.maximum >= _poolLimit.minimum &&
            (
                (
                    _contestType == 1 &&
                    _poolLimit.maximum > _poolLimit.minimum
                ) ||
                (
                    _contestType != 1 &&
                    _discountPercentNumerator == 0 
                ) // if contest is h2h, discount should not be there
            ),
            "Fantazy :: Invalid pool details"
        );
        poolData[_poolId].contestType = _contestType;
        poolData[_poolId].currencyId = _currencyId;
        poolData[_poolId].entryFee = _entryFee;
        poolData[_poolId].poolLimit = _poolLimit;
        poolData[_poolId].discountPercentNumerator = _discountPercentNumerator;
        poolData[_poolId].discountPercentDenominator = _discountPercentDenominator;
        poolData[_poolId].eventId = _eventId;
        poolsCount++;
        uint256 totalPoolAmount = _entryFee * _poolLimit.maximum;
        uint256 poolPlatformCommission = (totalPoolAmount *
            protocolCommission.numerator) / protocolCommission.denominator;
        uint256 winningsAmount = 0;
        uint256 bucketStart;
        for (uint8 i = 0; i < _winningsTable.length; i++) {
            
            require(
                _winningsTable[i].from > 0 &&
                _winningsTable[i].to >= _winningsTable[i].from &&
                _winningsTable[i].from > bucketStart,
                "Fantazy :: Invalid winnings table"
            );
            if (_winningsTable[i].from == _winningsTable[i].to) {
                winningsAmount += _winningsTable[i].amount;
            } else if (_winningsTable[i].from != _winningsTable[i].to) {
                winningsAmount +=
                    (_winningsTable[i].to - _winningsTable[i].from + 1) *
                    _winningsTable[i].amount;
            }
            bucketStart = _winningsTable[i].to;
            poolData[_poolId].winningsTable[i] = _winningsTable[i];
        }
        if(winningsAmount != totalPoolAmount - poolPlatformCommission){
            revert CustomError(2);
        }
        // emit AddNewPool(
        //     _poolId,
        //     _contestType,
        //     _currencyId,
        //     _entryFee,
        //     _poolLimit
        // );
    }

    function createNewTeam(
        uint256 _eventId,
        uint256 _teamId,
        string memory _teamName,
        uint256 _selectedCaptain,
        uint256 _selectedViceCaptain,
        uint256[] calldata _selectedPlayers
    )
        public
        nonReentrant
        whenNotPaused
    {
        require(
            eventData[_eventId].startTime > 0 && // event should exist
            teamData[_teamId].user == address(0) && // team should be available
            block.timestamp < eventData[_eventId].startTime && // can't create team when match starts
            _selectedPlayers.length >=
            sportData[eventData[_eventId].sportId].teamCriteria.totalPlayers.minimum &&
            _selectedPlayers.length <=
            sportData[eventData[_eventId].sportId].teamCriteria.totalPlayers.maximum,
            "Fantazy :: Invalid team details"
        );

        /* store total players */
        teamData[_teamId].totalPlayersCount = _selectedPlayers.length;

        /* store other team data */
        for (uint8 i = 0; i < _selectedPlayers.length; i++) {
            uint8 playerTeam = playerData[_eventId][_selectedPlayers[i]].team;
            uint8 _playerCategory = playerData[_eventId][_selectedPlayers[i]].category;

            if(playerTeam <1 && playerTeam>2){
                /* Fantazy :: selected player is not in both team squads */
                revert CustomError(3);
            }
            if(_playerCategory <1 && _playerCategory >5){
                /* Fantazy :: selected player category is not registered on sport */
                revert CustomError(4);
            }

            /* store team-A and team-B player counts */
            if (playerTeam == 1) {
                teamData[_teamId].teamACount++;
            } else {
                teamData[_teamId].teamBCount++;
            }

            /* store categories of players */
            if (_playerCategory == 1) {
                teamData[_teamId].category1Count++;
            } else if (_playerCategory == 2) {
                teamData[_teamId].category2Count++;
            } else if (_playerCategory == 3) {
                teamData[_teamId].category3Count++;
            } else if (_playerCategory == 4) {
                teamData[_teamId].category4Count++;
            } else {
                teamData[_teamId].category5Count++;
            }

            /* handle selected captain and vice-captain */
            if (_selectedPlayers[i] == _selectedCaptain) {
                teamData[_teamId].selectedCaptain = _selectedCaptain;
            } else if (_selectedPlayers[i] == _selectedViceCaptain) {
                teamData[_teamId].selectedViceCaptain = _selectedViceCaptain;
            }
        }

        /* check if team criteria is satisfied else revert */
        TeamCriteria memory criteria = sportData[eventData[_eventId].sportId].teamCriteria;

        require(
            teamData[_teamId].selectedCaptain > 0 &&
            teamData[_teamId].selectedViceCaptain > 0 &&
            teamData[_teamId].teamACount >= criteria.eachTeam.minimum &&
            teamData[_teamId].teamACount <= criteria.eachTeam.maximum &&
            teamData[_teamId].teamBCount >= criteria.eachTeam.minimum &&
            teamData[_teamId].teamBCount <= criteria.eachTeam.maximum &&
            teamData[_teamId].category1Count >= criteria.category1.minimum &&
            teamData[_teamId].category1Count <= criteria.category1.maximum &&
            teamData[_teamId].category2Count >= criteria.category2.minimum &&
            teamData[_teamId].category2Count <= criteria.category2.maximum &&
            teamData[_teamId].category3Count >= criteria.category3.minimum &&
            teamData[_teamId].category3Count <= criteria.category3.maximum &&
            teamData[_teamId].category4Count >= criteria.category4.minimum &&
            teamData[_teamId].category4Count <= criteria.category4.maximum &&
            teamData[_teamId].category5Count >= criteria.category5.minimum &&
            teamData[_teamId].category5Count <= criteria.category5.maximum,
            "Fantazy :: Team details are invalid"
        );

        teamData[_teamId].teamName = _teamName;
        teamData[_teamId].user = _msgSender();
        teamData[_teamId].eventId = _eventId;
        teamData[_teamId].selectedPlayers = _selectedPlayers;
        teamsCount++;
        if (!isSportUser[eventData[_eventId].sportId][_msgSender()]) {
            isSportUser[eventData[_eventId].sportId][_msgSender()] = true;
        }
        if (!isFantazyUser[_msgSender()]) {
            usersCount++;
            isFantazyUser[_msgSender()] = true;
        }
        emit CreateNewTeam(
            _teamId,
            _eventId,
            _msgSender(),
            _teamName,
            _selectedPlayers
        );
    }

    function getDiscountFee(uint256 _poolId)
        private
        view
        returns (uint256 _amount)
    {
        if (poolData[_poolId].contestType != 1) {
            return 0;
        }
        return
            (poolData[_poolId].entryFee *
                poolData[_poolId].discountPercentNumerator) /
            poolData[_poolId].discountPercentDenominator;
    }

    function joinContest(
        uint256 _poolId,
        uint256 _teamId,
        uint256 _paymentType, // 1 - polygon wallet, 2 - joining bonus
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public payable nonReentrant whenNotPaused {
        bytes32 input;
        bytes32 hash;
        IERC20 token;
        if (_paymentType == 2) {
            input = keccak256(
                abi.encodePacked(
                    "0x19",
                    _teamId,
                    address(this),
                    _msgSender(),
                    poolData[_poolId].entryFee - getDiscountFee(_poolId)
                )
            );
            hash = keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", input)
            );
        }
        if (poolData[_poolId].currencyId != 1) {
            token = IERC20(currencyData[poolData[_poolId].currencyId].erc20);
        }

        require(
            poolData[_poolId].eventId > 0 && // check if pool exists
            teamData[_teamId].eventId > 0 && // check if team exists
            !isTeamParticipated[_teamId][_poolId] && // check if this team is already participated
            (_paymentType == 1 || _paymentType == 2) && // 1 - crypto wallet, 2 - bonus wallet
            (
                (
                    _paymentType == 2 &&
                    owner() == ecrecover(hash, _v, _r, _s) &&
                    (
                        (
                            poolData[_poolId].currencyId == 1 &&
                            receivedAmount - currencyData[poolData[_poolId].currencyId].protocolBonusStakedAmount  >=
                            getDiscountFee(_poolId) &&
                            address(this).balance >= currencyData[poolData[_poolId].currencyId].protocolBonusStakedAmount + getDiscountFee(_poolId)
                        ) ||
                        (
                            poolData[_poolId].currencyId != 1 &&
                            token.balanceOf(address(this)) - currencyData[poolData[_poolId].currencyId].protocolBonusStakedAmount >=
                            getDiscountFee(_poolId)
                        )
                    )
                ) ||
                (
                    _paymentType == 1 &&
                    _v == uint8(0) &&
                    _r == bytes32(0) &&
                    _s == bytes32(0) &&
                    (
                        (
                            poolData[_poolId].currencyId == 1 &&
                            msg.value >= poolData[_poolId].entryFee
                        ) ||
                        (
                            poolData[_poolId].currencyId != 1 &&
                            token.balanceOf(_msgSender()) >= poolData[_poolId].entryFee &&
                            token.allowance(_msgSender(), address(this)) >= poolData[_poolId].entryFee
                        )
                    )
                )
            ) &&
            block.timestamp < eventData[poolData[_poolId].eventId].startTime &&
            (poolData[_poolId].contestType == 1)
                ?
                    joinTeamsCount[_poolId][_msgSender()] < sportData[eventData[poolData[_poolId].eventId].sportId].joinTeamsLimit
                : 
                    joinTeamsCount[_poolId][_msgSender()] == 0
                &&
            poolData[_poolId].teamsJoinedCount < poolData[_poolId].poolLimit.maximum &&
            _msgSender() == teamData[_teamId].user,
            "Fantazy :: Invalid join details"
        );
        if (_paymentType == 1) {
            if (poolData[_poolId].currencyId != 1) {
                token.safeTransferFrom(
                    _msgSender(),
                    address(this),
                    poolData[_poolId].entryFee - getDiscountFee(_poolId)
                );
            }
            currencyData[poolData[_poolId].currencyId].protocolPaidStakedAmount += poolData[_poolId].entryFee;
            poolData[_poolId].paidStakedAmount += poolData[_poolId].entryFee;
        } else {
            currencyData[poolData[_poolId].currencyId].protocolBonusStakedAmount += getDiscountFee(_poolId);
            currencyData[poolData[_poolId].currencyId].protocolPaidStakedAmount += poolData[_poolId].entryFee - getDiscountFee(_poolId);
            poolData[_poolId].bonusStakedAmount += getDiscountFee(_poolId);
            poolData[_poolId].paidStakedAmount += poolData[_poolId].entryFee - getDiscountFee(_poolId);
        }
        joinTeamsCount[_poolId][_msgSender()]++;
        poolData[_poolId].teamsJoinedCount++;
        isTeamParticipated[_teamId][_poolId] = true;
        teamData[_teamId].paidPaymentType = _paymentType;
  
        emit JoinContest(
            _teamId,
            _poolId,
            _paymentType,
            _msgSender(),
            block.timestamp
        );
    }

    function getPrizeAmountByRank(uint256 _poolId, uint256 _rank)
        private 
        view
        returns (uint256 _prizeAmount)
    {
        for (uint8 i = 0; i < poolData[_poolId].winningsTable.length; i++) {
            if (
                poolData[_poolId].winningsTable[i].from > 0 &&
                (
                    _rank >= poolData[_poolId].winningsTable[i].from &&
                    _rank <= poolData[_poolId].winningsTable[i].to
                ) 
                
            ) {
                return poolData[_poolId].winningsTable[i].amount;
            }
        }
        return 0;
    }

    function updateEditedTeam(
        uint256 _teamId,
        uint256 _selectedCaptain,
        uint256 _selectedViceCaptain,
        uint256[] calldata _selectedPlayers,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public nonReentrant whenNotPaused {
        bytes32 input = keccak256(
            abi.encodePacked(
                "0x19",
                _teamId,
                _selectedCaptain,
                _selectedViceCaptain,
                _selectedPlayers,
                address(this),
                _msgSender()
            )
        );
        bytes32 hash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", input)
        );
        require(
            teamData[_teamId].eventId > 0 && // team should exist
            _msgSender() == teamData[_teamId].user && // only team owner can edit the team
            _selectedPlayers.length >= sportData[eventData[teamData[_teamId].eventId].sportId]
                .teamCriteria.totalPlayers.minimum &&
            _selectedPlayers.length <= sportData[eventData[teamData[_teamId].eventId].sportId]
                .teamCriteria.totalPlayers.maximum &&
            owner() == ecrecover(hash, _v, _r, _s),
            "Fantazy :: Invalid team details"
        );
        /* store total players */
        teamData[_teamId].totalPlayersCount = _selectedPlayers.length;
        /* store other team data */
        for (uint8 i = 0; i < _selectedPlayers.length; i++) {
            /* store team-A and team-B player counts */
            if (
                playerData[teamData[_teamId].eventId][_selectedPlayers[i]].team == 1
            ) {
                teamData[_teamId].teamACount++;
            } else if (
                playerData[teamData[_teamId].eventId][_selectedPlayers[i]].team == 2
            ) {
                teamData[_teamId].teamBCount++;
            } 
            /* store categories of players */
            if (
                playerData[teamData[_teamId].eventId][_selectedPlayers[i]].category == 1
            ) {
                teamData[_teamId].category1Count++;
            } else if (
                playerData[teamData[_teamId].eventId][_selectedPlayers[i]].category == 2
            ) {
                teamData[_teamId].category2Count++;
            } else if (
                playerData[teamData[_teamId].eventId][_selectedPlayers[i]].category == 3
            ) {
                teamData[_teamId].category3Count++;
            } else if (
                playerData[teamData[_teamId].eventId][_selectedPlayers[i]].category == 4
            ) {
                teamData[_teamId].category4Count++;
            } else if (
                playerData[teamData[_teamId].eventId][_selectedPlayers[i]].category == 5
            ) {
                teamData[_teamId].category5Count++;
            } 
            /* handle selected captain */
            if (_selectedPlayers[i] == _selectedCaptain) {
                teamData[_teamId].selectedCaptain = _selectedCaptain;
            } else if (_selectedPlayers[i] == _selectedViceCaptain) {
                teamData[_teamId].selectedViceCaptain = _selectedViceCaptain;
            }
        }
        /* check if team criteria is satisfied else revert */
        require(
            teamData[_teamId].selectedCaptain > 0 &&
            teamData[_teamId].selectedViceCaptain > 0 &&
            (
                teamData[_teamId].teamACount >= sportData[eventData[teamData[_teamId].eventId].sportId]
                    .teamCriteria.eachTeam.minimum &&
                teamData[_teamId].teamACount <= sportData[eventData[teamData[_teamId].eventId].sportId]
                    .teamCriteria.eachTeam.maximum
            ) &&
            (
                teamData[_teamId].teamBCount >= sportData[eventData[teamData[_teamId].eventId].sportId]
                    .teamCriteria.eachTeam.minimum &&
                teamData[_teamId].teamBCount <= sportData[eventData[teamData[_teamId].eventId].sportId]
                    .teamCriteria.eachTeam.maximum
            ) &&
            (
                teamData[_teamId].category1Count >= sportData[eventData[teamData[_teamId].eventId].sportId]
                    .teamCriteria.category1.minimum &&
                teamData[_teamId].category1Count <= sportData[eventData[teamData[_teamId].eventId].sportId]
                    .teamCriteria.category1.maximum
            ) &&
            (
                teamData[_teamId].category2Count >= sportData[eventData[teamData[_teamId].eventId].sportId]
                    .teamCriteria.category2.minimum &&
                teamData[_teamId].category2Count <= sportData[eventData[teamData[_teamId].eventId].sportId]
                    .teamCriteria.category2.maximum
            ) &&
            (
                teamData[_teamId].category3Count >= sportData[eventData[teamData[_teamId].eventId].sportId]
                    .teamCriteria.category3.minimum &&
                teamData[_teamId].category3Count <= sportData[eventData[teamData[_teamId].eventId].sportId]
                    .teamCriteria.category3.maximum
            ) &&
            (
                teamData[_teamId].category4Count >= sportData[eventData[teamData[_teamId].eventId].sportId]
                    .teamCriteria.category4.minimum &&
                teamData[_teamId].category4Count <= sportData[eventData[teamData[_teamId].eventId].sportId]
                    .teamCriteria.category4.maximum
            ) &&
            (
                teamData[_teamId].category5Count >= sportData[eventData[teamData[_teamId].eventId].sportId]
                    .teamCriteria.category5.minimum &&
                teamData[_teamId].category5Count <= sportData[eventData[teamData[_teamId].eventId].sportId]
                    .teamCriteria.category5.maximum
            ),
            "Fantazy :: Team details are invalid"
        );
        teamData[_teamId].selectedPlayers = _selectedPlayers;
        emit UpdateTeam(
            _teamId,
            teamData[_teamId].eventId,
            _msgSender(),
            _selectedPlayers,
            block.timestamp
        );
    }

    function getTeamPoints(uint256 _teamId)
        private
        view
        returns (uint256 totalTeamPoints)
    {
        for (uint256 i = 0; i < teamData[_teamId].selectedPlayers.length; i++) {
            if (
                teamData[_teamId].selectedPlayers[i] ==
                teamData[_teamId].selectedCaptain
            ) {
                totalTeamPoints += ((playerData[teamData[_teamId].eventId][
                    teamData[_teamId].selectedPlayers[i]
                ].points *
                    sportData[eventData[teamData[_teamId].eventId].sportId]
                        .captainMultiplier) / 10);
                continue;
            } else if (
                teamData[_teamId].selectedPlayers[i] ==
                teamData[_teamId].selectedViceCaptain
            ) {
                totalTeamPoints += ((playerData[teamData[_teamId].eventId][
                    teamData[_teamId].selectedPlayers[i]
                ].points *
                    sportData[eventData[teamData[_teamId].eventId].sportId]
                        .viceCaptainMultiplier) / 10);
                continue;
            }
            totalTeamPoints += (
                playerData[teamData[_teamId].eventId][
                    teamData[_teamId].selectedPlayers[i]
                ].points
            );
        }
    }

    function claim(
        uint256 _teamId,
        uint256 _poolId,
        uint256 _rank,
        uint256 _magicValue, 
        // if _isRefund is true then _magicValue: 1(admin force refund), 0(non force refund by admin )
        // if _isRefund is false then _magicValue: totalPoints
        bool _isRefund,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public nonReentrant whenNotPaused {
        uint256 currencyId = poolData[_poolId].currencyId;
        uint256 claimAmount = (!_isRefund)
            ? getPrizeAmountByRank(_poolId, _rank)
            : poolData[_poolId].entryFee - (
                teamData[_teamId].paidPaymentType == 1 ? 0 : getDiscountFee(_poolId)
            );
        IERC20 token = (currencyId != 1)
            ? IERC20(currencyData[currencyId].erc20)
            : IERC20(address(0));

        bytes32 input = keccak256(
            abi.encodePacked(
                "0x19",
                _teamId,
                _poolId,
                (!_isRefund) ? _rank : 0,
                claimAmount,
                address(this),
                msg.sender,
                _magicValue
            )
        );
        bytes32 hash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", input)
        );

        require(
            isTeamParticipated[_teamId][_poolId] && // the team has to be participated in the pool
            claimAmount > 0 &&
            (
                (
                    !_isRefund &&
                    poolData[_poolId].teamsJoinedCount >= poolData[_poolId].poolLimit.minimum &&
                    !isPrizeClaimed[_poolId][_teamId] &&
                    _magicValue == getTeamPoints(_teamId)
                ) ||
                (
                    _isRefund &&
                    !isFeeRefunded[_poolId][_teamId] &&
                    (
                        _magicValue == 1 ? 
                            poolData[_poolId].teamsJoinedCount >= 1 
                        : (
                            _magicValue == 0 ? 
                                poolData[_poolId].teamsJoinedCount < poolData[_poolId].poolLimit.minimum 
                            : false
                        )
                    )

                )
            ) &&
            msg.sender == teamData[_teamId].user && // only owner of the team can claim refund/prize
            owner() == ecrecover(hash, _v, _r, _s) &&
            (
                (
                    currencyId == 1 &&
                    address(this).balance >= claimAmount
                ) ||
                (
                    currencyId != 1 &&
                    token.balanceOf(address(this)) >= claimAmount
                )
            ) &&
            (
                    currencyData[currencyId].protocolBonusStakedAmount +
                    currencyData[currencyId].protocolPaidStakedAmount >= claimAmount
            ),
            "Fantazy :: Invalid claim request"
        );

        if (currencyId == 1) {
            (bool success, ) = payable(msg.sender).call{value: claimAmount}("");
            if(!success){
                /* claim is unsuccessful */
                revert CustomError(5);
            }
        } else {
            token.safeTransferFrom(address(this), msg.sender, claimAmount);
        }

        if (teamData[_teamId].paidPaymentType == 1) {
            currencyData[currencyId].protocolPaidStakedAmount -= poolData[_poolId].entryFee;
            poolData[_poolId].paidStakedClaimedAmount += poolData[_poolId].entryFee;
        } else if (teamData[_teamId].paidPaymentType == 2) {
            currencyData[currencyId].protocolPaidStakedAmount -= poolData[_poolId].entryFee - getDiscountFee(_poolId);
            currencyData[currencyId].protocolBonusStakedAmount -= getDiscountFee(_poolId);
            poolData[_poolId].paidStakedClaimedAmount += poolData[_poolId].entryFee - getDiscountFee(_poolId);
            poolData[_poolId].bonusStakedClaimedAmount += getDiscountFee(_poolId);
        }

        (!_isRefund)
            ? isPrizeClaimed[_poolId][_teamId] = true
            : isFeeRefunded[_poolId][_teamId] = true;

        emit Claim(_teamId, _poolId, msg.sender, claimAmount, block.timestamp);
    }

    function getPoolCommission(uint256 _poolId)
        private 
        view
        returns (uint256 amount)
    {
        require(
            (
                (
                    poolData[_poolId].poolLimit.maximum ==
                    poolData[_poolId].teamsJoinedCount &&
                    !poolData[_poolId].isWinningsTableUpdated
                ) ||
                (
                    poolData[_poolId].poolLimit.maximum >
                    poolData[_poolId].teamsJoinedCount &&
                    poolData[_poolId].isWinningsTableUpdated
                )
            ),
            "Fantazy :: Invalid withdraw"
        );
        return
            (
                poolData[_poolId].entryFee *
                poolData[_poolId].teamsJoinedCount *
                protocolCommission.numerator
            ) / protocolCommission.denominator;
    }

    function withdraw(
        uint256 _currencyId,
        uint256 _poolId,
        bool _isForce
    ) public onlyOwner nonReentrant whenNotPaused {
        IERC20 token;
        uint256 commissionAmount;
        bool success;
        if (!_isForce){
            commissionAmount = getPoolCommission(_poolId);
        }else{
            if(_currencyId == 1){
                commissionAmount = address(this).balance;
            }else{
                commissionAmount = token.balanceOf(address(this));
                token = IERC20(currencyData[_currencyId].erc20);
            }
        }
        require(
            currencyData[_currencyId].decimals > 0 && // currency should exist
            (
                (
                    _currencyId == 1 &&
                    (
                        (
                            _isForce && 
                            address(this).balance > 0
                        ) ||
                        (
                            !_isForce &&
                            poolData[_poolId].currencyId == 1 &&
                            currencyData[_currencyId].protocolBonusStakedAmount +
                            currencyData[_currencyId].protocolPaidStakedAmount >= commissionAmount 
                        )
                    )
                ) ||
                (
                    _currencyId != 1 &&
                    (
                        (
                            _isForce && 
                            token.balanceOf(address(this)) > 0
                        ) ||
                        (
                            !_isForce &&
                            poolData[_poolId].currencyId != 1 &&
                            currencyData[_currencyId].protocolBonusStakedAmount +
                            currencyData[_currencyId].protocolPaidStakedAmount >= commissionAmount
                        )
                    )
                )
            ),
            "Fantazy :: Invalid withdraw details"
        );
        if (_currencyId == 1) {
            (success, ) = payable(owner()).call{value: commissionAmount}("");
            if(!success){
                /* Withdraw failed */
                revert CustomError(6);
            }
        } else if (_currencyId != 1) {
            token.safeTransferFrom(
                address(this),
                owner(),
                commissionAmount
            );
        }

        if (!_isForce) {
            poolData[_poolId].isCommissionWithdrawn = true;
            currencyData[_currencyId].protocolPaidStakedAmount -= (
                poolData[_poolId].paidStakedAmount - poolData[_poolId].paidStakedClaimedAmount
            );
            currencyData[_currencyId].protocolBonusStakedAmount -= (
                poolData[_poolId].bonusStakedAmount - poolData[_poolId].bonusStakedClaimedAmount
            );
        }
        // emit Withdraw(_currencyId, _poolId, _isForce, commissionAmount, block.timestamp);
    }

    function getData(
        uint256 _poolId, 
        uint256 _eventId, 
        uint256 _teamId
    ) 
    public view returns(Pool memory _pool, Event memory _event, Team memory _team){
        return (poolData[_poolId], eventData[_eventId], teamData[_teamId]);
    }

}