/**
 *Submitted for verification at polygonscan.com on 2023-07-05
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
    function paused() public view returns (bool) {
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

// File: contracts/FantazyV2.sol

/**
 * @author Vijay Sugali
 * @name FantazyV2
 * @description to support all fantasy sports
 */

pragma solidity 0.8.19;

/**
 * Imports -
 *     -> Ownable - to have ownership to the contract
 *     -> ReentrancyGuard - to avoid reentrancy attacks
 *     -> Pausable - to pause vulnerability is exposed
 */
contract FantazyV2 is Ownable, ReentrancyGuard, Pausable {
    /* To have secure ERC20 transfers */
    using SafeERC20 for IERC20;

    /* Range of minimum and maximum */
    struct Range {
        uint8 minimum;
        uint8 maximum;
    }

    /* 
        Team criteria:
            -> totalPlayers - minimum and maximum players to be selected
            -> eachTeam     - minimum and maximum players to be selected by each team
            -> categoryN    - minimum and maximum players to be selected for Nth category
        Note that for 
            -> cricket has four categories - 
                => wicket keeper, 
                => batsman, 
                => all rounder, 
                => bowler
            -> soccer has four categories - 
                => Goal keeper,
                => Defender,
                => Midfielder,
                => Forward
            -> kabbadi has three categories -
                => Raider,
                => Allrounder,
                => Defender
            -> Baseball has four categories -
                => Outfielder,
                => Infielder,
                => Pitcher,
                => Catcher
            -> Basketball has five categories -
                => Point guard,
                => Shotting guard,
                => Small forward,
                => Power forward,
                => Center
            -> NFL has five categories -
                => Quarterback
                => Runningback
                => Wide Receiver
                => Tight end
                => Defense
            -> Hockey has four categories -
                => Goal keeper
                => Defender
                => Midfielder
                => Striker
            -> Hand ball has three categories -
                => Goal keeper
                => Defender
                => Forward
            -> Volley ball has five categories -
                => Libero
                => Setter
                => Blocker
                => Attacker
                => Universal
     */
    struct TeamCriteria {
        Range totalPlayers;
        Range eachTeam;
        Range category1;
        Range category2;
        Range category3;
        Range category4;
        Range category5;
    }

    /* 
        Sport Struct -
            -> name                 :   Name of the sport
            -> captainMultiplier    :   multiplier for captain player (Eg: 20)
            -> viceCaptainMultiplier:   multiplier for vice captain   (Eg: 15)
            -> joinTeamsLimit       :   how many teams can a user create per pool
            -> teamCriteria         :   Team criteria for all teams in the sport
    */
    struct Sport {
        string name;
        uint256 captainMultiplier;
        uint256 viceCaptainMultiplier;
        uint256 joinTeamsLimit;
        TeamCriteria teamCriteria;
    }
    /* mapping for each sport data :: sport id to sport */
    mapping(uint256 => Sport) private sportData;
    /* mapping to get if sport exist :: sportId to bool */
    mapping(uint256 => bool) private hasSport;
    /* primary state for sports count in Fantazy */
    uint256 public sportsCount;

    /* 
        Currency Struct -
            -> name                         :   Name of the currency
            -> erc20                        :   Contract address if it is ERC20 crypto token
            -> decimals                     :   Decimals of the currency
            -> isErc20                      :   True if erc20 else false
            -> protocolBonusStakedAmount    :   Amount spent by Fantazy for users in the form of discounts on joining pools
            -> protocolPaidStakedAmount     :   Amount spent by users for joining pools
    */
    struct Currency {
        string name;
        address erc20;
        uint256 decimals;
        bool isErc20;
        uint256 protocolBonusStakedAmount;
        uint256 protocolPaidStakedAmount;
    }
    /* mapping for each currency :: currency id to currency */
    mapping(uint256 => Currency) private currencyData;
    /* mapping to get if currency exist :: currencyId to bool */
    mapping(uint256 => bool) private hasCurrency;
    /* total number of Currency supported */
    uint256 public currenciesCount;

    /*
        Player Struct -
            -> category :   Category of the player
            -> team     :   team of the player (Eg: A or B as 1 or 2)
            -> points   :   Fantazy points in a match
    */
    struct Player {
        uint8 category;
        uint8 team; 
        uint256 points;
    }

    /* 
        Event Struct -
            -> eventName    :   Name of the match
            -> sportId      :   ID of the sport that event belongs to
            -> startTime    :   Time when match starts
            -> teamAsquad   :   Player Ids of Team A squad
            -> teamBsquad   :   Player Ids of Team B squad
    */
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

    /* 
        PrizeBucket Struct -
            -> from     :   Rank range left
            -> to       :   Rank range right
            -> amount   :   Prize amount for this rank range
    */
    struct PrizeBucket {
        uint256 from;
        uint256 to;
        uint256 amount;
    }

    /* 
        Pool Struct -
            -> eventId                      :   ID of the match
            -> contestType                  :   Type of the contest, 1 - grand and 2 - H2H
            -> currencyId                   :   ID of the currency
            -> entryFee                     :   Entry fee to join the pool
            -> discountPercentNumerator     :   Discount that platform gives to join pool (Numerator value)
            -> discountPercentDenominator   :   DIscount that platform gives to join pool (Denominator value)
            -> teamsJoinedCount             :   How many people joined the pool
            -> paidStakedAmount             :   How much of amount people paid by themselves
            -> bonusStakedAmount            :   How much of amount platform gave discount to teams to join pool
            -> paidStakedClaimedAmount      :   Amount of which winners claimed their paid amount back
            -> bonusStakedClaimedAmount     :   Amount of which platform claims its discounted amount back
            -> poolLimit                    :   Minimum and maximum pool limit
            -> winningsTable                :   Prize distribution table
            -> isWinningsTableUpdated       :   True if pool didnt fill full and distribution table updated, else false
            -> isCommissionWithdrawn        :   True if commission withdrawn for this pool
    */
    struct Pool {
        uint256 eventId;
        uint256 contestType; 
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
    mapping(uint256 => mapping(uint256 => bool)) public isTeamParticipated;

    /* 
        Team Struct -
            -> user                 :   Address of the owner of the team
            -> teamName             :   Name of the team
            -> eventId              :   ID of the match
            -> selectedCaptain      :   Player ID of the captain selected
            -> selectedViceCaptain  :   Player ID of the vice-captain selected
            -> totalPlayersCount    :   No. of players selected in the team
            -> teamACount           :   No. of players selected in the team from team A
            -> teamBCount           :   No. of players selected in the team from team B
            -> category1Count       :   No. of players selected in the team from category 1
            -> category2Count       :   No. of players selected in the team from category 2
            -> category3Count       :   No. of players selected in the team from category 3
            -> category4Count       :   No. of players selected in the team from category 4
            -> category5Count       :   No. of players selected in the team from category 5
            -> selectedPlayers      :   Array of player IDs selected in the team
    */
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
        uint256[] selectedPlayers;
    }
    /* mapping for each team :: sportId to teamId to Team */
    mapping(uint256 => Team) private teamData;
    /* mapping to know if refund claimed for pool :: poolId to teamId to bool */
    mapping(uint256 => mapping(uint256 => bool)) public isFeeRefunded;
    /* mapping to know if prize claimed for pool :: poolId to teamId to bool */
    mapping(uint256 => mapping(uint256 => bool)) public isPrizeClaimed;
    /* 
        mapping to know which payment type chosen to join in pool 
        teamId to poolId to paidPaymentType
    */
   mapping(uint256 => mapping(uint256 => uint256)) public paidPaymentType;

    /* 
        Commission Struct -
            Fantazy commission percentage in fraction 
            -> numerator    :   numerator of the percentage fraction
            -> denominator  :   denominator of the percentage fraction
    */
    struct Commission {
        uint256 numerator;
        uint256 denominator;
    }

    /* Other declarations */
    /* protocol commission */
    Commission public protocolCommission;
    /* matic received to the contract */
    uint256 private receivedAmount;
    /* number of events happenned in Fantazy */
    uint256 public eventsCount;
    /* number of pools created in Fantazy */
    uint256 public poolsCount;
    /* number of teams created in Fantazy */
    uint256 public teamsCount;
    /* number of users created in Fantazy */
    uint256 public usersCount;
    /* App's homepage URL */
    string public appUrl;
    /* 
        mapping to maintain usersCount properly
        address to bool
    */
    mapping(address => bool) private isFantazyUser;

    /*
        InsertTeam Event -
            when someone created a team outside from dapp, 
            purposes used:
                1. their details are collected to blacklist claim operation later
                2. when app was down to recollect the teams data
            -> _teamId          :   ID of the team
            -> _eventId         :   ID of the event
            -> _user            :   Address of the owner of the team
            -> _insertType      :   1 for creating new team, 2 for updating the existing team
            -> _timestamp       :   Timestamp when team is created or updated
    */
    event InsertTeam(
        uint256 indexed _teamId,
        uint256 indexed _eventId,
        address indexed _user,
        uint256 _insertType,
        uint256 _timestamp
    );

    /*
        JoinContest Event -
            when someone joined a contest outside from dapp,
            purposes used:
                1. their details are collected to blacklist claim operation later
                2. when app was down to recollect the teams data
            -> _teamId      :   ID of the team
            -> _poolId      :   ID of the pool
            -> _paymentType :   Type of the payment, 1 for crypto wallet, 2 for bonus wallet
            -> _user        :   Address of the user joined the contest
            -> _timestamp   :   Timestamp when team has joined
    */
    event JoinContest(
        uint256 indexed _teamId,
        uint256 indexed _poolId,
        uint256 _paymentType,
        address indexed _user,
        uint256 _timestamp
    );

    /* 
        Claim Event -
            when someone claimed from outside dapp,
            purposes used:
                1. their details are collected to saved for later decision
                2. when app was down to recollect the claim data
            -> _teamId      :   ID of the team
            -> _poolId      :   ID of the pool
            -> _user        :   Address of the user claimed
            -> _amount      :   Amount of prizes/refund claimed
            -> _timestamp   :   Timestamp when claim has happenned
    */
    event Claim(
        uint256 indexed _teamId,
        uint256 indexed _poolId,
        address indexed _user,
        uint256 _amount,
        uint256 _timestamp
    );


    /// A Custom error occurred in smart contract with `errorId`
    error CustomError(uint256 errorId);

    /* 
        Constructor -
            ->  _sportsCount            :   No. of sports enrolled in Fantazy before versions
            ->  _eventsCount            :   No. of events enrolled in Fantazy before versions
            ->  _poolsCount             :   No. of pools enrolled in Fantazy before versions
            ->  _teamsCount             :   No. of teams enrolled in Fantazy before versions
            ->  _usersCount             :   No. of users enrolled in Fantazy before versions
            ->  _commissionNumerator    :   Protocol commission from every pool in fraction (Numerator)
            ->  _commissionDenominator  :   Protocol commission from every pool in fraction (Denominator)
            ->  _appUrl                 :   Fantazy website homepage URL
    */
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

    /* To monitor how much matic contract received */
    receive() external payable {
        receivedAmount += msg.value;
    }

    /* To pause all contract operations at once */
    function pause() public onlyOwner {
        _pause();
    }

    /* To resume all contract operations at once */
    function unPause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev changeData is to change important contract data,
     *      only owner of the contract can call
     *      it is advisable to pause the contract 
     *      and execute this function to have integrity of contract info like eventsCount, poolsCount, usersCount, teamsCount
     * @param _appUrl is the homepage URL of Fantazy website
     * @param _commissionNumerator is the commission that platform gets from every pool in fraction(numerator)
     * @param _commissionDenominator is the commission that platform gets from every pool in fraction(denominator)
     */
    function changeData(string memory _appUrl, uint256 _commissionNumerator, uint256 _commissionDenominator) public onlyOwner{
        appUrl = _appUrl;
        protocolCommission.numerator = _commissionNumerator;
        protocolCommission.denominator = _commissionDenominator;
    }

    /**
     * @dev insertSportData is to create and edit sport data
     *      while updating sport data,
     *      make sure you update all fields along with field you want to edit
     * @param _name is the name of the sport
     * @param _sportId is the ID of the sport
     * @param _captainMultiplier is the multiplier for captain (Eg: 20)
     * @param _viceCaptainMultiplier is the multiplier for vice captain (Eg: 15)
     * @param _userTeamsLimit is the number of teams can be created per pool
     * @param _teamCriteria is the rules of team creation, visit TeamCriteria struct
     */
    function insertSportData(
        string memory _name,
        uint256 _sportId,
        uint256 _captainMultiplier,
        uint256 _viceCaptainMultiplier,
        uint256 _userTeamsLimit,
        TeamCriteria calldata _teamCriteria
    ) public onlyOwner nonReentrant whenNotPaused {
        /* check if sport is already added, if not add it */
        if (!hasSport[_sportId]) {
            sportsCount++;
            hasSport[_sportId] = true;
        }
        /* create or modify sport data */
        sportData[_sportId] = Sport(
            _name,
            _captainMultiplier,
            _viceCaptainMultiplier,
            _userTeamsLimit,
            _teamCriteria
        );
    }

    /**
     * @dev insertCurrencyData
     * @param _name is the name of the Currency
     * @param _currencyId is the ID of the currency
     * @param _erc20 is the contract address of erc20 crypto token
     * @param _decimals is the number of decimals of erc20 crypto token
     * @param _isErc20 is the boolean, true if currency is erc20 crypto token else false
     */
    function insertCurrencyData(
        string memory _name,
        uint256 _currencyId,
        address _erc20,
        uint256 _decimals,
        bool _isErc20
    ) public onlyOwner nonReentrant whenNotPaused {
        /* if currency is not yet added, add it */
        if (!hasCurrency[_currencyId]) {
            currenciesCount++;
            hasCurrency[_currencyId] = true;
        }
        /* create or modify currency info */
        currencyData[_currencyId] = Currency(
            _name,
            _erc20,
            _decimals,
            _isErc20,
            0,
            0
        );
    }

    /**
     * @dev addNewEvent is to add new match live on contract
     *      only owner can call this function
     *      only when contract is not paused this function will be success
     * @param _sportId is the ID of the sport
     * @param _eventId is the ID of the match
     * @param _startTime is the match start time
     * @param _eventName is the name of the match
     * @param _teamAsquad is the array of player IDs of team A squad
     * @param _teamAsquadCategories is the respective categories of all player IDs of team A squad
     * @param _teamBsquad is the array of player IDs of team B squad
     * @param _teamBsquadCategories is the respective categories of all player IDs of team B squad
     */
    function addNewEvent(
        uint256 _sportId,
        uint256 _eventId,
        uint256 _startTime,
        string memory _eventName,
        uint256[] calldata _teamAsquad,
        uint8[] calldata _teamAsquadCategories,
        uint256[] calldata _teamBsquad,
        uint8[] calldata _teamBsquadCategories
    ) public onlyOwner nonReentrant whenNotPaused {
        /* necessary conditions */
        if(
            /* start time should always be greater than current time */
            _startTime <= block.timestamp ||
            /* event with same event id shold not be present */
            eventData[_eventId].startTime != 0 ||
            /* team A squad and its categories should be of same length */
            _teamAsquad.length != _teamAsquadCategories.length ||
            /* team B squad and its categories should be of same length */
            _teamBsquad.length != _teamBsquadCategories.length
        ){
            /* Fantazy :: Invalid event details */
            revert CustomError(7);
        }
        /* update event data */
        eventData[_eventId] = Event(
            _eventName,
            _sportId,
            _startTime,
            _teamAsquad,
            _teamBsquad
        );
        /* update player categories and team for this event for Team A squad */
        for (uint256 i = 0; i < _teamAsquad.length; i++) {
            playerData[_eventId][_teamAsquad[i]] = Player(
                _teamAsquadCategories[i],
                1,
                0
            );
        }
        /* update player categories and team for this event for Team B squad */
        for (uint256 i = 0; i < _teamBsquad.length; i++) {
            playerData[_eventId][_teamBsquad[i]] = Player(
                _teamBsquadCategories[i],
                2,
                0
            );
        }
        /* increment the events count */
        eventsCount++;
    }

    /**
     * @dev insertPlayerPoints to insert fantasy points of all players after match is ended
     *      only owner can call this function
     *      only when contract is not paused this function will be success
     * @param _eventId is the ID of the event
     * @param _playerIds is the array of player IDs
     * @param _playerPoints is the array of player points of respective player IDs 
     */
    function insertPlayerPoints(
        uint256 _eventId,
        uint256[] calldata _playerIds,
        uint256[] calldata _playerPoints
    ) public onlyOwner nonReentrant whenNotPaused {
        /* loop through each player and assign player points */
        for (uint256 i = 0; i < _playerIds.length; i++) {
            playerData[_eventId][_playerIds[i]].points = _playerPoints[i];
        }
    }

    /**
     * @dev updateWinnings is to update distribution table accordingly if pool is not filled
     *      please not that this should be called only after match is started based on pool attendance
     *      only owner can call this function
     *      only when contract is not paused this function will be success
     * @param _poolId is the ID of the pool
     * @param _winningsTable is the updated distribution table
     */
    function updateWinnings(
        uint256 _poolId,
        PrizeBucket[] calldata _winningsTable
    ) public onlyOwner nonReentrant whenNotPaused {
        if(
            /* pool should exist to update the winnings */
            poolData[_poolId].eventId == 0 ||
            /* teams joined on pool should not fill the pool */
            poolData[_poolId].poolLimit.maximum ==
            poolData[_poolId].teamsJoinedCount
        ){
            /* Fantazy :: Invalid winnings table details */
            revert CustomError(8);
        }
        /* total pool amount collected */
        uint256 totalPoolAmount = poolData[_poolId].entryFee *
            poolData[_poolId].teamsJoinedCount;
        /* platform commission for every pool */
        uint256 poolPlatformCommission = (totalPoolAmount *
            protocolCommission.numerator) / protocolCommission.denominator;
        /* prize amount to distribute to winners */
        uint256 distributionAmount = totalPoolAmount - poolPlatformCommission;
        /* monitor the cumulative winning amount mentioned in distribution table */
        uint256 winningsAmount = 0;
        /* to make sure rank ranges are incremental */
        uint256 bucketStart;
        /* loop through each row of distribution table and cumulate the amount */
        for (uint8 i = 0; i < _winningsTable.length; i++) {
            if(
                /* rank range (left) should not be zero */
                _winningsTable[i].from == 0 ||
                /* rank range (right) should not be less than rank range (left) */
                _winningsTable[i].to < _winningsTable[i].from ||
                /* rank range (left) should be greater than previous row rank range (right) */
                _winningsTable[i].from <= bucketStart
            ){
                /* Fantazy :: Invalid winnings table */
                revert CustomError(9);
            }
            /* if rank range left and right are same then cumulate the amount for one team  */
            if (_winningsTable[i].from == _winningsTable[i].to) {
                winningsAmount += _winningsTable[i].amount;
            /* if rank range left and right are not same then cumulate the amount for no. of teams in the rank range */
            } else if (_winningsTable[i].from != _winningsTable[i].to) {
                winningsAmount +=
                    (_winningsTable[i].to - _winningsTable[i].from + 1) *
                    _winningsTable[i].amount;
            }
            /* update bucketStart to rank range right */
            bucketStart = _winningsTable[i].to;
            /* update the distribution table row */
            poolData[_poolId].winningsTable[i] = _winningsTable[i];
        }
        /* check if cumulative amount is equals to the prize amount allotted for distribution */
        if(winningsAmount != distributionAmount){
            /* Fantazy :: Invalid distribution table */
            revert CustomError(1);
        }
        /* update pool data with isWinningsTableUpdated */
        poolData[_poolId].isWinningsTableUpdated = true;
    }

    /**
     * @dev addNewPool is used to add a new pool
     *      only owner can call this function
     *      only when contract is not paused this function will be success
     * @param _eventId is the event ID of the match
     * @param _poolId is the pool ID of the pool
     * @param _contestType is the type of the contest, 1 for grand pool, 2 for H2H pool
     * @param _currencyId is the ID of the currency, Eg: 1 for matic, 2 for USDT
     * @param _entryFee is the entry fee to join the pool
     * @param _poolLimit is the minimum and maximum limit no. of teams to join in pool
     * @param _discountPercentNumerator is the discount in entry fee for the pool in fraction (numerator)
     * @param _discountPercentDenominator is the discount in entry fee for the pool in fraction (denominator)
     * @param _winningsTable is the distribution table for the pool considering pool will fill
     */
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
        if (
            /* event should exist */
            eventData[_eventId].startTime == 0 || 
            /* pool should be available */
            poolData[_poolId].entryFee != 0 || 
            /* currency should have enrolled */
            currencyData[_currencyId].decimals == 0 || 
            /* entry fee should be greater than zero */
            _entryFee == 0 ||
            /* pool should have minimum number of teams */
            _poolLimit.minimum == 0 ||
            /* discount percent denominator should always be non zero to avoid zero by divide error */
            _discountPercentDenominator == 0 ||
            /* maximum number of teams to be joined in pool should not be less than minimum number of teams */
            _poolLimit.maximum < _poolLimit.minimum ||
            (
                /* for grand pool maximum number of teams should always be greater than minimum number of teams  */
                _contestType == 1 &&
                _poolLimit.maximum <= _poolLimit.minimum
            ) ||
            (
                /* for H2H pool discount should always be zero */
                _contestType != 1 &&
                _discountPercentNumerator != 0 
            )
        ) {
            /* Fantazy :: Invalid pool details */
            revert CustomError(10);
        }
        /* update the given contest type to the pool */
        poolData[_poolId].contestType = _contestType;
        /* update the given currency id to the pool */
        poolData[_poolId].currencyId = _currencyId;
        /* update the given entry fee to the pool */
        poolData[_poolId].entryFee = _entryFee;
        /* update the given pool limit to the pool */
        poolData[_poolId].poolLimit = _poolLimit;
        /* update the given discount in fraction (numerator) */
        poolData[_poolId].discountPercentNumerator = _discountPercentNumerator;
        /* update the given discount in fraction (denominator) */
        poolData[_poolId].discountPercentDenominator = _discountPercentDenominator;
        /* update the given event id to the pool */
        poolData[_poolId].eventId = _eventId;
        /* update the total pools count */
        poolsCount++;
        /* calculate the total pool amount */
        uint256 totalPoolAmount = _entryFee * _poolLimit.maximum;
        /* calculate the platform commission */
        uint256 poolPlatformCommission = (totalPoolAmount *
            protocolCommission.numerator) / protocolCommission.denominator;
        /* monitor the cumulative winnings amount */
        uint256 winningsAmount = 0;
        /* rank ranges should be incremental */
        uint256 bucketStart;
        /* loop through input distribution table and validate */
        for (uint8 i = 0; i < _winningsTable.length; i++) {
            if(
                /* rank range (left) should not be zero */
                _winningsTable[i].from == 0 ||
                /* rank range (right) should not be less than rank range (left) */
                _winningsTable[i].to < _winningsTable[i].from ||
                /* rank range (left) should be greater than previous row rank range (right) */
                _winningsTable[i].from <= bucketStart
            ){
                /* Fantazy :: Invalid winnings table */
                revert CustomError(11);
            }
            /* if rank range left and right are same then cumulate the amount for one team  */
            if (_winningsTable[i].from == _winningsTable[i].to) {
                winningsAmount += _winningsTable[i].amount;
            /* if rank range left and right are not same then cumulate the amount for no. of teams in the rank range */
            } else if (_winningsTable[i].from != _winningsTable[i].to) {
                winningsAmount +=
                    (_winningsTable[i].to - _winningsTable[i].from + 1) *
                    _winningsTable[i].amount;
            }
            /* update bucketStart to rank range right */
            bucketStart = _winningsTable[i].to;
            /* update the distribution table row */
            poolData[_poolId].winningsTable[i] = _winningsTable[i];
        }
        /* check if cumulative amount is equals to the prize amount allotted for distribution */
        if(winningsAmount != totalPoolAmount - poolPlatformCommission){
            /* Fantazy :: Invalid distribution table */
            revert CustomError(2);
        }
    }

    /**
     * @dev createNewTeam is used to create a new team
     *      make sure that you create the team from Fantazy website or app
     * @param _eventId is the ID of the match
     * @param _teamId is the available ID of the team 
     * @param _teamName is the name of the team
     * @param _selectedCaptain is the player id of the selected captain
     * @param _selectedViceCaptain is the player id of the selected vice captain
     * @param _selectedPlayers is the array of player ids of the selected team players
     */
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
        if (
            eventData[_eventId].startTime == 0 || // event should exist
            teamData[_teamId].user != address(0) || // team should be available
            block.timestamp >= eventData[_eventId].startTime || // can't create team when match starts
            _selectedPlayers.length < sportData[eventData[_eventId].sportId].teamCriteria.totalPlayers.minimum ||
            _selectedPlayers.length > sportData[eventData[_eventId].sportId].teamCriteria.totalPlayers.maximum
        ) {
            /* Fantazy :: Invalid team details */
            revert CustomError(12);
        }

        /* store total players */
        teamData[_teamId].totalPlayersCount = _selectedPlayers.length;

        /* store other team data */
        for (uint8 i = 0; i < _selectedPlayers.length; i++) {
            /* store the team of the player */
            uint8 playerTeam = playerData[_eventId][_selectedPlayers[i]].team;
            /* store the category of the player */
            uint8 _playerCategory = playerData[_eventId][_selectedPlayers[i]].category;
            /* check if player team is valid */
            if(playerTeam <1 && playerTeam>2){
                /* Fantazy :: selected player is not in both team squads */
                revert CustomError(3);
            }
            /* check if player category is valid */
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
        if (
            teamData[_teamId].selectedCaptain == 0 ||
            teamData[_teamId].selectedViceCaptain == 0 ||
            teamData[_teamId].teamACount < criteria.eachTeam.minimum ||
            teamData[_teamId].teamACount > criteria.eachTeam.maximum ||
            teamData[_teamId].teamBCount < criteria.eachTeam.minimum ||
            teamData[_teamId].teamBCount > criteria.eachTeam.maximum ||
            teamData[_teamId].category1Count < criteria.category1.minimum ||
            teamData[_teamId].category1Count > criteria.category1.maximum ||
            teamData[_teamId].category2Count < criteria.category2.minimum ||
            teamData[_teamId].category2Count > criteria.category2.maximum ||
            teamData[_teamId].category3Count < criteria.category3.minimum ||
            teamData[_teamId].category3Count > criteria.category3.maximum ||
            teamData[_teamId].category4Count < criteria.category4.minimum ||
            teamData[_teamId].category4Count > criteria.category4.maximum ||
            teamData[_teamId].category5Count < criteria.category5.minimum ||
            teamData[_teamId].category5Count > criteria.category5.maximum
        ) {
            /* Fantazy :: Team details are invalid */
            revert CustomError(13);
        }

        /* update the given team name to team data */
        teamData[_teamId].teamName = _teamName;
        /* update the given user address to team data */
        teamData[_teamId].user = _msgSender();
        /* update the given event ID to team data */
        teamData[_teamId].eventId = _eventId;
        /* update the given selected players to team data */
        teamData[_teamId].selectedPlayers = _selectedPlayers;
        /* update the total no of teams count */
        teamsCount++;
        /* if user is not already counted as fantazy user, count it */
        if (!isFantazyUser[_msgSender()]) {
            usersCount++;
            isFantazyUser[_msgSender()] = true;
        }
        /* emit the event */
        emit InsertTeam(
            _teamId,
            _eventId,
            _msgSender(),
            1,
            block.timestamp
        );
    }

    /**
     * @dev getDiscountFee is to get the discounted fee for a given pool
     *      this amount is paid by platform
     * @param _poolId is the ID of the pool
     * @return _amount is the discount amount to be paid by platform
     */
    function getDiscountFee(uint256 _poolId)
        private
        view
        returns (uint256 _amount)
    {
        /* if its not grand pool return discount fee as 0 */
        if (poolData[_poolId].contestType != 1) {
            return 0;
        }
        /* only for grand pool send the discount amount */
        return
            (poolData[_poolId].entryFee *
                poolData[_poolId].discountPercentNumerator) /
            poolData[_poolId].discountPercentDenominator;
    }

    /**
     * @dev joinContest is to join the contest with created team
     * @param _poolId is the ID of the pool
     * @param _teamId is the ID of the team
     * @param _paymentType is the type of payment, 1 for crypto wallet and 2 for bonus wallet
     * @param _v is the signature v attribute 
     *           it is 0, if payment type is crypto wallet else admin signature
     * @param _r is the signature r attribute
     *           it is 0 bytes if payment type is crypto wallet else admin signature
     * @param _s is the signature s attribute
     *           it is 0 bytes if payment type is crypto wallet else admin signature
     */
    function joinContest(
        uint256 _poolId,
        uint256 _teamId,
        uint256 _paymentType,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public payable nonReentrant whenNotPaused {
        /* hash of the normal input values */
        bytes32 input;
        /* hash of the EIP-191 signature standard input */
        bytes32 hash;
        /* To store ERC20 contract instance if pool is created for ERC20 token */
        IERC20 token;
        /* If payment type is bonus wallet, hash the input */
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
        /* if currency ID is not matic, get the erc20 token instance */
        if (poolData[_poolId].currencyId != 1) {
            token = IERC20(currencyData[poolData[_poolId].currencyId].erc20);
        }
        
        if(
            (
                /* check if this team is already participated */
                !isTeamParticipated[_teamId][_poolId] && 
                /* payment type should be either of 1 or 2 */
                (_paymentType == 1 || _paymentType == 2) && 
                (
                    (
                        /* 
                            recover owner address from given signature 
                            if payment type is bonus wallet to avoid 
                            users joining for infinite bonus amount
                            without proper db validations and admin approval
                        */
                        _paymentType == 2 &&
                        owner() == ecrecover(hash, _v, _r, _s) &&
                        (
                            (
                                /* if the currency is matic check contract has enough balance to pay the pool given discount amount */
                                poolData[_poolId].currencyId == 1 &&
                                receivedAmount - currencyData[poolData[_poolId].currencyId].protocolBonusStakedAmount  >=
                                getDiscountFee(_poolId) &&
                                address(this).balance >= currencyData[poolData[_poolId].currencyId].protocolBonusStakedAmount + getDiscountFee(_poolId)
                            ) ||
                            (
                                /* if the currency is erc20 check erc20 token balance of the contract to pay the pool given discount amount */
                                poolData[_poolId].currencyId != 1 &&
                                token.balanceOf(address(this)) >= currencyData[poolData[_poolId].currencyId].protocolBonusStakedAmount + getDiscountFee(_poolId)
                            )
                        )
                    ) ||
                    (
                        /* 
                            if payment type is crypto wallet then
                            no need to recover admin signature
                        */
                        _paymentType == 1 &&
                        _v == uint8(0) &&
                        _r == bytes32(0) &&
                        _s == bytes32(0) &&
                        (
                            (
                                /* check for enough matic is being sent to function execution */
                                poolData[_poolId].currencyId == 1 &&
                                msg.value >= poolData[_poolId].entryFee
                            ) ||
                            (
                                /* check if contract has allowance to transfer on behalf of user */
                                poolData[_poolId].currencyId != 1 &&
                                /* check if user has enough erc20 token to pay the entry fee */
                                token.balanceOf(_msgSender()) >= poolData[_poolId].entryFee &&
                                token.allowance(_msgSender(), address(this)) >= poolData[_poolId].entryFee
                            )
                        )
                    )
                ) &&
                /* team can join pool only if match is not started */
                block.timestamp < eventData[poolData[_poolId].eventId].startTime &&
                (poolData[_poolId].contestType == 1)
                    ?
                        /* no of teams an user can create per pool should not be exceeded in grand pools */
                        joinTeamsCount[_poolId][_msgSender()] < sportData[eventData[poolData[_poolId].eventId].sportId].joinTeamsLimit
                    : 
                        /* only one team can participate in H2H pools */
                        joinTeamsCount[_poolId][_msgSender()] == 0
                    &&
                /* pool should not exceed */
                poolData[_poolId].teamsJoinedCount < poolData[_poolId].poolLimit.maximum &&
                /* function executer should be the owner of team */
                _msgSender() == teamData[_teamId].user
            ) == false
        )
            /* Fantazy :: Invalid join details */
            revert CustomError(19);

        if (_paymentType == 1) {
            /* transfer entry fee after discount from user account to contract */
            if (poolData[_poolId].currencyId != 1) {
                token.safeTransferFrom(
                    _msgSender(),
                    address(this),
                    poolData[_poolId].entryFee - getDiscountFee(_poolId)
                );
            }
            /* update currency state and pool state for the amounts of users paid */
            currencyData[poolData[_poolId].currencyId].protocolPaidStakedAmount += poolData[_poolId].entryFee;
            poolData[_poolId].paidStakedAmount += poolData[_poolId].entryFee;
        } else {
            /* update currency state and pool state for the amounts of fantazy paid and user paid */
            currencyData[poolData[_poolId].currencyId].protocolBonusStakedAmount += getDiscountFee(_poolId);
            currencyData[poolData[_poolId].currencyId].protocolPaidStakedAmount += poolData[_poolId].entryFee - getDiscountFee(_poolId);
            poolData[_poolId].bonusStakedAmount += getDiscountFee(_poolId);
            poolData[_poolId].paidStakedAmount += poolData[_poolId].entryFee - getDiscountFee(_poolId);
        }
        /* increment the no of teams joined in this pool by an user */
        joinTeamsCount[_poolId][_msgSender()]++;
        /* increment the pool attendance */
        poolData[_poolId].teamsJoinedCount++;
        /* mark team participation in the pool to true */
        isTeamParticipated[_teamId][_poolId] = true;
        /* store the payment type of this pool for this team */
        paidPaymentType[_teamId][_poolId] = _paymentType;
  
        /* emit the event */
        emit JoinContest(
            _teamId,
            _poolId,
            _paymentType,
            _msgSender(),
            block.timestamp
        );
    }

    /**
     * @dev getPrizeAmountByRank is to get the prize amount
     *      from distribution table for this rank
     * @param _poolId is the ID of the pool
     * @param _rank is the Rank of the team
     */
    function getPrizeAmountByRank(uint256 _poolId, uint256 _rank)
        private 
        view
        returns (uint256 _prizeAmount)
    {
        /* loop through the distribution table and find the suitable row for this rank */
        for (uint8 i = 0; i < poolData[_poolId].winningsTable.length; i++) {
            if (
                poolData[_poolId].winningsTable[i].from > 0 &&
                (
                    _rank >= poolData[_poolId].winningsTable[i].from &&
                    _rank <= poolData[_poolId].winningsTable[i].to
                ) 
                
            ) {
                /* return the prize amount for this rank */
                return poolData[_poolId].winningsTable[i].amount;
            /* return 0 prize amount if no more rows present in distribution table */
            }else if(poolData[_poolId].winningsTable[i].from == 0)
                return 0;
        }
        /* return the 0 prize amount if rank is not present in distribution table */
        return 0;
    }

    /**
     * @dev updateEditedTeam is to update the edited team
     *      please invoke this only when matches postponed or 
     *      when team is edited multiple times but update the final team
     *      only when this team wins prizes and before claiming prize
     *      admin signature is required as a proof of match postponed
     * @param _teamId is the ID of the team
     * @param _selectedCaptain is the player ID of the captain
     * @param _selectedViceCaptain is the player ID of the vice captain
     * @param _selectedPlayers is the array of player IDs of the selected players
     * @param _v is the signature attribute v from admin signature
     * @param _r is the signature attribute r from admin signature
     * @param _s is the signature attribute s from admin signature
     */
    function updateEditedTeam(
        uint256 _teamId,
        uint256 _selectedCaptain,
        uint256 _selectedViceCaptain,
        uint256[] calldata _selectedPlayers,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public nonReentrant whenNotPaused {
        /* hash out all the input parameters */
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
        /* hash out the EIP-191 standard input */
        bytes32 hash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", input)
        );
        if (
            /* team should exist */
            teamData[_teamId].eventId == 0 ||
            /* only the owner of the team should edit team */
            _msgSender() != teamData[_teamId].user ||
            /* selected players should satisfy the criteria */
            _selectedPlayers.length < sportData[eventData[teamData[_teamId].eventId].sportId]
                .teamCriteria.totalPlayers.minimum ||
            _selectedPlayers.length > sportData[eventData[teamData[_teamId].eventId].sportId]
                .teamCriteria.totalPlayers.maximum ||
            /* recovered address should be owner as a proof of team edit */
            owner() != ecrecover(hash, _v, _r, _s)
        ) {
            /* Fantazy :: Invalid team details */
            revert CustomError(14);
        }

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
        if(
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
            )
            == false
        )
            /* Fantazy :: Team details are invalid */
            revert CustomError(18);

        /* store selected players */
        teamData[_teamId].selectedPlayers = _selectedPlayers;
        /* emit the event */
        emit InsertTeam(
            _teamId,
            teamData[_teamId].eventId,
            _msgSender(),
            2,
            block.timestamp
        );
    }

    /**
     * @dev getTeamPoints is to get the total team points
     *      make sure that insertPlayerPoints is done
     * @param _teamId is the ID of the team
     * @return totalTeamPoints is the total team points
     */
    function getTeamPoints(uint256 _teamId)
        private
        view
        returns (uint256 totalTeamPoints)
    {
        /* loop through all players and find total team points */
        for (uint256 i = 0; i < teamData[_teamId].selectedPlayers.length; i++) {
            /* if player is captain add captain multiplier */
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
            /* if player is vice captain add vicecaptain multiplier */
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
            /* add other team points */
            totalTeamPoints += (
                playerData[teamData[_teamId].eventId][
                    teamData[_teamId].selectedPlayers[i]
                ].points
            );
        }
    }

    /**
     * @dev claim is to claim prizes or refund
     *      owner  signature is the proof of rank or 
     *      proof of match abandoned while refund or
     *      proof of match is completed
     * @param _teamId is the ID of the team
     * @param _poolId is the ID of the pool
     * @param _rank is the rank of the team
     * @param _magicValue is 1 if admin force refund when match is abandoned
     *                    is 0 if pool is not filled with minimum count
     *                    is total points if _isRefund is false
     * @param _isRefund is true if claim is for refund
     *                  is false if claim is for prize
     * @param _v is the signature attribute v from admin signature
     * @param _r is the signature attribute r from admin signature
     * @param _s is the signature attribute s from admin signature 
     */
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
        /* store locally the currency ID */
        uint256 currencyId = poolData[_poolId].currencyId;
        /* store the claim amount */
        uint256 claimAmount = (!_isRefund)
            /* if claim is prize, get prize amount */
            ? getPrizeAmountByRank(_poolId, _rank)
            /* if claim is refund, get the amount paid by user */
            : poolData[_poolId].entryFee - (
                paidPaymentType[_teamId][_poolId] == 1 ? 0 : getDiscountFee(_poolId)
            );
        /* get the erc20 token instance if currency ID is not matic */
        IERC20 token = (currencyId != 1)
            ? IERC20(currencyData[currencyId].erc20)
            : IERC20(address(0));

        /* get the hash of input parameters */
        bytes32 input = keccak256(
            abi.encodePacked(
                "0x19",
                _teamId,
                _poolId,
                (!_isRefund) ? _rank : 0,
                claimAmount,
                address(this),
                _msgSender(),
                _magicValue
            )
        );
        /* get the hash of EIP-191 standard input */
        bytes32 hash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", input)
        );
        /* validate the necessary functions */
        if(
            /* check if team is participated in pool */
            isTeamParticipated[_teamId][_poolId] &&
            /* check if claim amount is greater than zero */
            claimAmount > 0 &&
            (
                (
                    /* if claim is prize, make sure minimum teams joined in pool */
                    !_isRefund &&
                    poolData[_poolId].teamsJoinedCount >= poolData[_poolId].poolLimit.minimum &&
                    /* make sure prize is not claimed already */
                    !isPrizeClaimed[_poolId][_teamId] &&
                    /* make sure owner signed with right total team points of the given team */
                    _magicValue == getTeamPoints(_teamId)
                ) ||
                (
                    /* if claim is refund, make sure refund is not claimed already */
                    _isRefund &&
                    !isFeeRefunded[_poolId][_teamId] &&
                    (
                        _magicValue == 1 ? 
                            /* if admin forced to refund, make sure atleast one team is joined */
                            poolData[_poolId].teamsJoinedCount >= 1 
                        : (
                            _magicValue == 0 ? 
                                /* if admin nor force, make sure pool is filled with less than minimum pool limit */
                                poolData[_poolId].teamsJoinedCount < poolData[_poolId].poolLimit.minimum 
                            : false
                        )
                    )

                )
            ) &&
            /* only owner of the team can claim refund/prize */
            _msgSender() == teamData[_teamId].user && 
            /* make sure recovered address is owners */
            owner() == ecrecover(hash, _v, _r, _s) &&
            (
                (
                    /* if currency is matic, make sure contract has enough matic */
                    currencyId == 1 &&
                    address(this).balance >= claimAmount
                ) ||
                (
                    /* if currency is erc20, make sure contract has enough token balance */
                    currencyId != 1 &&
                    token.balanceOf(address(this)) >= claimAmount
                )
            ) &&
            (       
                /* currency's users paid amount and platform paid amount should not be less than claim amount */
                currencyData[currencyId].protocolBonusStakedAmount +
                currencyData[currencyId].protocolPaidStakedAmount >= claimAmount
            )
            == false
        )
            /* Fantazy :: Invalid claim request */
            revert CustomError(17);

        if (currencyId == 1) {
            /* send the claimed matic amount to user */
            (bool success, ) = payable(_msgSender()).call{value: claimAmount}("");
            if(!success){
                /* claim is unsuccessful */
                revert CustomError(5);
            }
        } else {
            /* send the claimed erc20 to user */
            token.safeTransfer(_msgSender(), claimAmount);
        }

        if (paidPaymentType[_teamId][_poolId] == 1) {
            /* update currency and pool state of funds */
            currencyData[currencyId].protocolPaidStakedAmount -= poolData[_poolId].entryFee;
            poolData[_poolId].paidStakedClaimedAmount += poolData[_poolId].entryFee;
        } else if (paidPaymentType[_teamId][_poolId] == 2) {
            /* update currency and pool state of funds */
            currencyData[currencyId].protocolPaidStakedAmount -= poolData[_poolId].entryFee - getDiscountFee(_poolId);
            currencyData[currencyId].protocolBonusStakedAmount -= getDiscountFee(_poolId);
            poolData[_poolId].paidStakedClaimedAmount += poolData[_poolId].entryFee - getDiscountFee(_poolId);
            poolData[_poolId].bonusStakedClaimedAmount += getDiscountFee(_poolId);
        }

        /* update claim status to avoid double spending */
        (!_isRefund)
            ? isPrizeClaimed[_poolId][_teamId] = true
            : isFeeRefunded[_poolId][_teamId] = true;

        /* emit the Claim event */
        emit Claim(_teamId, _poolId, _msgSender(), claimAmount, block.timestamp);
    }

    /**
     * @dev getPoolCommission is to get the pool commission amount
     * @param _poolId is the ID of the pool
     * @return amount is the commission amount to be received by owner from the given pool 
     */
    function getPoolCommission(uint256 _poolId)
        private 
        view
        returns (uint256 amount)
    {
        /* do the necessary validations */
        if(
            (
                (
                    /* if winnings table is false then pool should have filled */
                    poolData[_poolId].poolLimit.maximum ==
                    poolData[_poolId].teamsJoinedCount &&
                    !poolData[_poolId].isWinningsTableUpdated
                ) ||
                (
                    /* if winnings table is true then pool should not have filled full */
                    poolData[_poolId].poolLimit.maximum >
                    poolData[_poolId].teamsJoinedCount &&
                    poolData[_poolId].isWinningsTableUpdated
                )
            )
            == false
        ) 
            /* Fantazy :: Invalid withdraw */
            revert CustomError(16);

        /* return the commission fee */
        return
            (
                poolData[_poolId].entryFee *
                poolData[_poolId].teamsJoinedCount *
                protocolCommission.numerator
            ) / protocolCommission.denominator;
    }

    /**
     * @dev withdraw is to withdraw pool commission or any currency in contract
     *      it is advised not to withdraw contract balance by force,
     *      instead withdraw pool by pool
     * @param _currencyId is the ID of the currency
     * @param _poolId is the ID of the pool
     * @param _isForce is true if you want to withdraw all contract balance of given currency
     *                 is false if you want to withdraw only the given pool commission
     */
    function withdraw(
        uint256 _currencyId,
        uint256 _poolId,
        bool _isForce
    ) public onlyOwner nonReentrant whenNotPaused {
        /* if currency is erc20, to store the token contract instance */
        IERC20 token;
        /* commission amount to withdraw */
        uint256 commissionAmount;
        /* if matic to check if withdrawal is success or not */
        bool success;
        if (!_isForce){
            /* get the pool commission amount */
            commissionAmount = getPoolCommission(_poolId);
        }else{
            if(_currencyId == 1){
                /* get the contract matic balance */
                commissionAmount = address(this).balance;
            }else{
                /* get the contract erc20 balance */
                commissionAmount = token.balanceOf(address(this));
                
            }
        }
        if(_currencyId != 1){
            /* store the erc20 token contract instance */
            token = IERC20(currencyData[_currencyId].erc20);
        }

        if(
            /* check if withdrawing is owner or not */
            _msgSender() == owner() &&
            /* check if currency is enrolled or not */
            currencyData[_currencyId].decimals > 0 && 
            (
                (
                    /* contract amount should be more than 0 */
                    _isForce &&
                    commissionAmount > 0
                ) ||
                (
                    /* pool should have commission amount to withdraw */
                    !_isForce &&
                    currencyData[_currencyId].protocolBonusStakedAmount +
                    currencyData[_currencyId].protocolPaidStakedAmount >= commissionAmount &&
                    poolData[_poolId].paidStakedAmount + 
                    poolData[_poolId].bonusStakedAmount >= commissionAmount
                )
            )
            == false
        ) 
            /* Fantazy :: Invalid withdraw details */
            revert CustomError(15);

        /* withdraw amount to owner */
        if (_currencyId == 1) {
            (success, ) = payable(owner()).call{value: commissionAmount}("");
            if(!success){
                /* Withdraw failed */
                revert CustomError(6);
            }
        } else if (_currencyId != 1) {
            token.safeTransfer(
                owner(),
                commissionAmount
            );
        }

        /* update currency and pool state */
        if (!_isForce) {
            /* update commission withdrawn to true in pool */
            poolData[_poolId].isCommissionWithdrawn = true;
            currencyData[_currencyId].protocolPaidStakedAmount -= (
                poolData[_poolId].paidStakedAmount - poolData[_poolId].paidStakedClaimedAmount
            );
            currencyData[_currencyId].protocolBonusStakedAmount -= (
                poolData[_poolId].bonusStakedAmount - poolData[_poolId].bonusStakedClaimedAmount
            );
        }
    }

    /**
     * @dev Retrieves data for a pool, event, team, and currency.
     * @param _poolId The ID of the pool to retrieve data for.
     * @param _eventId The ID of the event to retrieve data for.
     * @param _teamId The ID of the team to retrieve data for.
     * @param _currencyId The ID of the currency to retrieve data for.
     * @return _pool The retrieved pool data.
     * @return _event The retrieved event data.
     * @return _team The retrieved team data.
     * @return _currency The retrieved currency data.
     */
    function getData(
        uint256 _poolId, 
        uint256 _eventId, 
        uint256 _teamId,
        uint256 _currencyId
    ) 
    public view returns(
        Pool memory _pool, 
        Event memory _event, 
        Team memory _team,
        Currency memory _currency
    ){
        return (
            poolData[_poolId], 
            eventData[_eventId], 
            teamData[_teamId],
            currencyData[_currencyId]
        );
    }

}