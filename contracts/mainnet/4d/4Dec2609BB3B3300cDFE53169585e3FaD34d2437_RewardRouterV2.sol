// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
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
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
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
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Governable {
    address public gov;

    constructor() {
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "Governable: forbidden");
        _;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISblpManager {
    function usdg() external view returns (address);
    function cooldownDuration() external returns (uint256);
    function getAumInUsdg(bool maximise) external view returns (uint256);
    function lastAddedAt(address _account) external returns (uint256);
    function addLiquidity(address _token, uint256 _amount, uint256 _minUsdg, uint256 _minSblp) external returns (uint256);
    function addLiquidityForAccount(address _fundingAccount, address _account, address _token, uint256 _amount, uint256 _minUsdg, uint256 _minSblp) external returns (uint256);
    function removeLiquidity(address _tokenOut, uint256 _sblpAmount, uint256 _minOut, address _receiver) external returns (uint256);
    function removeLiquidityForAccount(address _account, address _tokenOut, uint256 _sblpAmount, uint256 _minOut, address _receiver) external returns (uint256);
    // function setShortsTrackerAveragePriceWeight(uint256 _shortsTrackerAveragePriceWeight) external;
    function setCooldownDuration(uint256 _cooldownDuration) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRewardTracker {
    function depositBalances(address _account, address _depositToken) external view returns (uint256);
    function stakedAmounts(address _account) external view returns (uint256);
    function updateRewards() external;
    function stake(address _depositToken, uint256 _amount) external;
    function stakeForAccount(address _fundingAccount, address _account, address _depositToken, uint256 _amount) external;
    function unstake(address _depositToken, uint256 _amount) external;
    function unstakeForAccount(address _account, address _depositToken, uint256 _amount, address _receiver) external;
    function tokensPerInterval() external view returns (uint256);
    function claim(address _receiver) external returns (uint256);
    function claimForAccount(address _account, address _receiver) external returns (uint256);
    function claimable(address _account) external view returns (uint256);
    function averageStakedAmounts(address _account) external view returns (uint256);
    function cumulativeRewards(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IVester {
    function rewardTracker() external view returns (address);

    function claimForAccount(address _account, address _receiver) external returns (uint256);

    function claimable(address _account) external view returns (uint256);
    function cumulativeClaimAmounts(address _account) external view returns (uint256);
    function claimedAmounts(address _account) external view returns (uint256);
    function pairAmounts(address _account) external view returns (uint256);
    function getVestedAmount(address _account) external view returns (uint256);
    function transferredAverageStakedAmounts(address _account) external view returns (uint256);
    function transferredCumulativeRewards(address _account) external view returns (uint256);
    function cumulativeRewardDeductions(address _account) external view returns (uint256);
    function bonusRewards(address _account) external view returns (uint256);

    function transferStakeValues(address _sender, address _receiver) external;
    function setTransferredAverageStakedAmounts(address _account, uint256 _amount) external;
    function setTransferredCumulativeRewards(address _account, uint256 _amount) external;
    function setCumulativeRewardDeductions(address _account, uint256 _amount) external;
    function setBonusRewards(address _account, uint256 _amount) external;

    function getMaxVestableAmount(address _account) external view returns (uint256);
    function getCombinedAverageStakedAmount(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./interfaces/IRewardTracker.sol";
import "./interfaces/IVester.sol";
import "../tokens/interfaces/IMintable.sol";
import "../tokens/interfaces/IWETH.sol";
import "../core/interfaces/ISblpManager.sol";
import "../access/Governable.sol";

contract RewardRouterV2 is ReentrancyGuard, Governable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address payable;

    bool public isInitialized;

    address public weth;

    address public sbx;
    address public esSbx;
    address public bnSbx;

    address public sblp; // SBX Liquidity Provider token

    address public stakedSbxTracker;
    address public bonusSbxTracker;
    address public feeSbxTracker;

    address public stakedSblpTracker;
    address public feeSblpTracker;

    address public sblpManager;

    address public sbxVester;
    address public sblpVester;

    mapping (address => address) public pendingReceivers;

    event StakeSbx(address account, address token, uint256 amount);
    event UnstakeSbx(address account, address token, uint256 amount);

    event StakeSblp(address account, uint256 amount);
    event UnstakeSblp(address account, uint256 amount);

    receive() external payable {
        require(msg.sender == weth, "Router: invalid sender");
    }

    struct initParams{
        address _weth;
        address _sbx;
        address _esSbx;
        address _bnSbx;
        address _sblp;
        address _stakedSbxTracker;
        address _bonusSbxTracker;
        address _feeSbxTracker;
        address _feeSblpTracker;
        address _stakedSblpTracker;
        address _sblpManager;
        address _sbxVester;
        address _sblpVester;
    }

    function initialize(initParams memory params) external onlyGov {
        require(!isInitialized, "RewardRouter: already initialized");
        isInitialized = true;

        weth = params._weth;

        sbx = params._sbx;
        esSbx = params._esSbx;
        bnSbx = params._bnSbx;

        sblp = params._sblp;

        stakedSbxTracker = params._stakedSbxTracker;
        bonusSbxTracker = params._bonusSbxTracker;
        feeSbxTracker = params._feeSbxTracker;

        feeSblpTracker = params._feeSblpTracker;
        stakedSblpTracker = params._stakedSblpTracker;

        sblpManager = params._sblpManager;

        sbxVester = params._sbxVester;
        sblpVester = params._sblpVester;
    }

    // to help users who accidentally send their tokens to this contract
    function withdrawToken(address _token, address _account, uint256 _amount) external onlyGov {
        IERC20(_token).safeTransfer(_account, _amount);
    }

    function saftApprove(address token, address spender, uint256 amount) public onlyGov {
        IERC20(token).approve(spender, amount);
    }

    function batchStakeSbxForAccount(address[] memory _accounts, uint256[] memory _amounts) external nonReentrant onlyGov {
        address _sbx = sbx;
        for (uint256 i = 0; i < _accounts.length; i++) {
            _stakeSbx(msg.sender, _accounts[i], _sbx, _amounts[i]);
        }
    }

    function stakeSbxForAccount(address _account, uint256 _amount) external nonReentrant onlyGov {
        _stakeSbx(msg.sender, _account, sbx, _amount);
    }

    function stakeSbx(uint256 _amount) external nonReentrant {
        _stakeSbx(msg.sender, msg.sender, sbx, _amount);
    }

    function stakeEsSbx(uint256 _amount) external nonReentrant {
        _stakeSbx(msg.sender, msg.sender, esSbx, _amount);
    }

    function unstakeSbx(uint256 _amount) external nonReentrant {
        _unstakeSbx(msg.sender, sbx, _amount, true);
    }

    function unstakeEsSbx(uint256 _amount) external nonReentrant {
        _unstakeSbx(msg.sender, esSbx, _amount, true);
    }

    function mintAndStakeSblp(address _token, uint256 _amount, uint256 _minUsdg, uint256 _minSblp) external nonReentrant returns (uint256) {
        require(_amount > 0, "RewardRouter: invalid _amount");

        address account = msg.sender;
        uint256 sblpAmount = ISblpManager(sblpManager).addLiquidityForAccount(account, account, _token, _amount, _minUsdg, _minSblp);
        IRewardTracker(feeSblpTracker).stakeForAccount(account, account, sblp, sblpAmount);
        IRewardTracker(stakedSblpTracker).stakeForAccount(account, account, feeSblpTracker, sblpAmount);

        emit StakeSblp(account, sblpAmount);

        return sblpAmount;
    }

    function mintAndStakeSblpETH(uint256 _minUsdg, uint256 _minSblp) external payable nonReentrant returns (uint256) {
        require(msg.value > 0, "RewardRouter: invalid msg.value");

        IWETH(weth).deposit{value: msg.value}();
        IERC20(weth).approve(sblpManager, msg.value);

        address account = msg.sender;
        uint256 sblpAmount = ISblpManager(sblpManager).addLiquidityForAccount(address(this), account, weth, msg.value, _minUsdg, _minSblp);

        IRewardTracker(feeSblpTracker).stakeForAccount(account, account, sblp, sblpAmount);
        IRewardTracker(stakedSblpTracker).stakeForAccount(account, account, feeSblpTracker, sblpAmount);

        emit StakeSblp(account, sblpAmount);

        return sblpAmount;
    }

    function unstakeAndRedeemSblp(address _tokenOut, uint256 _sblpAmount, uint256 _minOut, address _receiver) external nonReentrant returns (uint256) {
        require(_sblpAmount > 0, "RewardRouter: invalid _sblpAmount");

        address account = msg.sender;
        IRewardTracker(stakedSblpTracker).unstakeForAccount(account, feeSblpTracker, _sblpAmount, account);
        IRewardTracker(feeSblpTracker).unstakeForAccount(account, sblp, _sblpAmount, account);
        uint256 amountOut = ISblpManager(sblpManager).removeLiquidityForAccount(account, _tokenOut, _sblpAmount, _minOut, _receiver);

        emit UnstakeSblp(account, _sblpAmount);

        return amountOut;
    }

    function unstakeAndRedeemSblpETH(uint256 _sblpAmount, uint256 _minOut, address payable _receiver) external nonReentrant returns (uint256) {
        require(_sblpAmount > 0, "RewardRouter: invalid _sblpAmount");

        address account = msg.sender;
        IRewardTracker(stakedSblpTracker).unstakeForAccount(account, feeSblpTracker, _sblpAmount, account);
        IRewardTracker(feeSblpTracker).unstakeForAccount(account, sblp, _sblpAmount, account);
        uint256 amountOut = ISblpManager(sblpManager).removeLiquidityForAccount(account, weth, _sblpAmount, _minOut, address(this));

        IWETH(weth).withdraw(amountOut);

        _receiver.sendValue(amountOut);

        emit UnstakeSblp(account, _sblpAmount);

        return amountOut;
    }

    function claim() external nonReentrant {
        address account = msg.sender;

        IRewardTracker(feeSbxTracker).claimForAccount(account, account);
        IRewardTracker(feeSblpTracker).claimForAccount(account, account);

        IRewardTracker(stakedSbxTracker).claimForAccount(account, account);
        IRewardTracker(stakedSblpTracker).claimForAccount(account, account);
    }

    function claimEsSbx() external nonReentrant {
        address account = msg.sender;

        IRewardTracker(stakedSbxTracker).claimForAccount(account, account);
        IRewardTracker(stakedSblpTracker).claimForAccount(account, account);
    }

    function claimFees() external nonReentrant {
        address account = msg.sender;

        IRewardTracker(feeSbxTracker).claimForAccount(account, account);
        IRewardTracker(feeSblpTracker).claimForAccount(account, account);
    }

    function compound() external nonReentrant {
        _compound(msg.sender);
    }

    function compoundForAccount(address _account) external nonReentrant onlyGov {
        _compound(_account);
    }

    function handleRewards(
        bool _shouldClaimSbx,
        bool _shouldStakeSbx,
        bool _shouldClaimEsSbx,
        bool _shouldStakeEsSbx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external nonReentrant {
        address account = msg.sender;

        uint256 sbxAmount = 0;
        if (_shouldClaimSbx) {
            uint256 sbxAmount0 = IVester(sbxVester).claimForAccount(account, account);
            uint256 sbxAmount1 = IVester(sblpVester).claimForAccount(account, account);
            sbxAmount = sbxAmount0.add(sbxAmount1);
        }

        if (_shouldStakeSbx && sbxAmount > 0) {
            _stakeSbx(account, account, sbx, sbxAmount);
        }

        uint256 esSbxAmount = 0;
        if (_shouldClaimEsSbx) {
            uint256 esSbxAmount0 = IRewardTracker(stakedSbxTracker).claimForAccount(account, account);
            uint256 esSbxAmount1 = IRewardTracker(stakedSblpTracker).claimForAccount(account, account);
            esSbxAmount = esSbxAmount0.add(esSbxAmount1);
        }

        if (_shouldStakeEsSbx && esSbxAmount > 0) {
            _stakeSbx(account, account, esSbx, esSbxAmount);
        }

        if (_shouldStakeMultiplierPoints) {
            uint256 bnSbxAmount = IRewardTracker(bonusSbxTracker).claimForAccount(account, account);
            if (bnSbxAmount > 0) {
                IRewardTracker(feeSbxTracker).stakeForAccount(account, account, bnSbx, bnSbxAmount);
            }
        }

        if (_shouldClaimWeth) {
            if (_shouldConvertWethToEth) {
                uint256 weth0 = IRewardTracker(feeSbxTracker).claimForAccount(account, address(this));
                uint256 weth1 = IRewardTracker(feeSblpTracker).claimForAccount(account, address(this));

                uint256 wethAmount = weth0.add(weth1);
                IWETH(weth).withdraw(wethAmount);

                payable(account).sendValue(wethAmount);
            } else {
                IRewardTracker(feeSbxTracker).claimForAccount(account, account);
                IRewardTracker(feeSblpTracker).claimForAccount(account, account);
            }
        }
    }

    function batchCompoundForAccounts(address[] memory _accounts) external nonReentrant onlyGov {
        for (uint256 i = 0; i < _accounts.length; i++) {
            _compound(_accounts[i]);
        }
    }

    function signalTransfer(address _receiver) external nonReentrant {
        require(IERC20(sbxVester).balanceOf(msg.sender) == 0, "RewardRouter: sender has vested tokens");
        require(IERC20(sblpVester).balanceOf(msg.sender) == 0, "RewardRouter: sender has vested tokens");

        _validateReceiver(_receiver);
        pendingReceivers[msg.sender] = _receiver;
    }

    function acceptTransfer(address _sender) external nonReentrant {
        require(IERC20(sbxVester).balanceOf(_sender) == 0, "RewardRouter: sender has vested tokens");
        require(IERC20(sblpVester).balanceOf(_sender) == 0, "RewardRouter: sender has vested tokens");

        address receiver = msg.sender;
        require(pendingReceivers[_sender] == receiver, "RewardRouter: transfer not signalled");
        delete pendingReceivers[_sender];

        _validateReceiver(receiver);
        _compound(_sender);

        uint256 stakedSbx = IRewardTracker(stakedSbxTracker).depositBalances(_sender, sbx);
        if (stakedSbx > 0) {
            _unstakeSbx(_sender, sbx, stakedSbx, false);
            _stakeSbx(_sender, receiver, sbx, stakedSbx);
        }

        uint256 stakedEsSbx = IRewardTracker(stakedSbxTracker).depositBalances(_sender, esSbx);
        if (stakedEsSbx > 0) {
            _unstakeSbx(_sender, esSbx, stakedEsSbx, false);
            _stakeSbx(_sender, receiver, esSbx, stakedEsSbx);
        }

        uint256 stakedBnSbx = IRewardTracker(feeSbxTracker).depositBalances(_sender, bnSbx);
        if (stakedBnSbx > 0) {
            IRewardTracker(feeSbxTracker).unstakeForAccount(_sender, bnSbx, stakedBnSbx, _sender);
            IRewardTracker(feeSbxTracker).stakeForAccount(_sender, receiver, bnSbx, stakedBnSbx);
        }

        uint256 esSbxBalance = IERC20(esSbx).balanceOf(_sender);
        if (esSbxBalance > 0) {
            IERC20(esSbx).transferFrom(_sender, receiver, esSbxBalance);
        }

        uint256 sblpAmount = IRewardTracker(feeSblpTracker).depositBalances(_sender, sblp);
        if (sblpAmount > 0) {
            IRewardTracker(stakedSblpTracker).unstakeForAccount(_sender, feeSblpTracker, sblpAmount, _sender);
            IRewardTracker(feeSblpTracker).unstakeForAccount(_sender, sblp, sblpAmount, _sender);

            IRewardTracker(feeSblpTracker).stakeForAccount(_sender, receiver, sblp, sblpAmount);
            IRewardTracker(stakedSblpTracker).stakeForAccount(receiver, receiver, feeSblpTracker, sblpAmount);
        }

        IVester(sbxVester).transferStakeValues(_sender, receiver);
        IVester(sblpVester).transferStakeValues(_sender, receiver);
    }

    function _validateReceiver(address _receiver) private view {
        require(IRewardTracker(stakedSbxTracker).averageStakedAmounts(_receiver) == 0, "RewardRouter: stakedSbxTracker.averageStakedAmounts > 0");
        require(IRewardTracker(stakedSbxTracker).cumulativeRewards(_receiver) == 0, "RewardRouter: stakedSbxTracker.cumulativeRewards > 0");

        require(IRewardTracker(bonusSbxTracker).averageStakedAmounts(_receiver) == 0, "RewardRouter: bonusSbxTracker.averageStakedAmounts > 0");
        require(IRewardTracker(bonusSbxTracker).cumulativeRewards(_receiver) == 0, "RewardRouter: bonusSbxTracker.cumulativeRewards > 0");

        require(IRewardTracker(feeSbxTracker).averageStakedAmounts(_receiver) == 0, "RewardRouter: feeSbxTracker.averageStakedAmounts > 0");
        require(IRewardTracker(feeSbxTracker).cumulativeRewards(_receiver) == 0, "RewardRouter: feeSbxTracker.cumulativeRewards > 0");

        require(IVester(sbxVester).transferredAverageStakedAmounts(_receiver) == 0, "RewardRouter: sbxVester.transferredAverageStakedAmounts > 0");
        require(IVester(sbxVester).transferredCumulativeRewards(_receiver) == 0, "RewardRouter: sbxVester.transferredCumulativeRewards > 0");

        require(IRewardTracker(stakedSblpTracker).averageStakedAmounts(_receiver) == 0, "RewardRouter: stakedSblpTracker.averageStakedAmounts > 0");
        require(IRewardTracker(stakedSblpTracker).cumulativeRewards(_receiver) == 0, "RewardRouter: stakedSblpTracker.cumulativeRewards > 0");

        require(IRewardTracker(feeSblpTracker).averageStakedAmounts(_receiver) == 0, "RewardRouter: feeSblpTracker.averageStakedAmounts > 0");
        require(IRewardTracker(feeSblpTracker).cumulativeRewards(_receiver) == 0, "RewardRouter: feeSblpTracker.cumulativeRewards > 0");

        require(IVester(sblpVester).transferredAverageStakedAmounts(_receiver) == 0, "RewardRouter: sbxVester.transferredAverageStakedAmounts > 0");
        require(IVester(sblpVester).transferredCumulativeRewards(_receiver) == 0, "RewardRouter: sbxVester.transferredCumulativeRewards > 0");

        require(IERC20(sbxVester).balanceOf(_receiver) == 0, "RewardRouter: sbxVester.balance > 0");
        require(IERC20(sblpVester).balanceOf(_receiver) == 0, "RewardRouter: sblpVester.balance > 0");
    }

    function _compound(address _account) private {
        _compoundSbx(_account);
        _compoundSblp(_account);
    }

    function _compoundSbx(address _account) private {
        uint256 esSbxAmount = IRewardTracker(stakedSbxTracker).claimForAccount(_account, _account);
        if (esSbxAmount > 0) {
            _stakeSbx(_account, _account, esSbx, esSbxAmount);
        }

        uint256 bnSbxAmount = IRewardTracker(bonusSbxTracker).claimForAccount(_account, _account);
        if (bnSbxAmount > 0) {
            IRewardTracker(feeSbxTracker).stakeForAccount(_account, _account, bnSbx, bnSbxAmount);
        }
    }

    function _compoundSblp(address _account) private {
        uint256 esSbxAmount = IRewardTracker(stakedSblpTracker).claimForAccount(_account, _account);
        if (esSbxAmount > 0) {
            _stakeSbx(_account, _account, esSbx, esSbxAmount);
        }
    }

    function _stakeSbx(address _fundingAccount, address _account, address _token, uint256 _amount) private {
        require(_amount > 0, "RewardRouter: invalid _amount");

        IRewardTracker(stakedSbxTracker).stakeForAccount(_fundingAccount, _account, _token, _amount);
        IRewardTracker(bonusSbxTracker).stakeForAccount(_account, _account, stakedSbxTracker, _amount);
        IRewardTracker(feeSbxTracker).stakeForAccount(_account, _account, bonusSbxTracker, _amount);

        emit StakeSbx(_account, _token, _amount);
    }

    function _unstakeSbx(address _account, address _token, uint256 _amount, bool _shouldReduceBnSbx) private {
        require(_amount > 0, "RewardRouter: invalid _amount");

        uint256 balance = IRewardTracker(stakedSbxTracker).stakedAmounts(_account);

        IRewardTracker(feeSbxTracker).unstakeForAccount(_account, bonusSbxTracker, _amount, _account);
        IRewardTracker(bonusSbxTracker).unstakeForAccount(_account, stakedSbxTracker, _amount, _account);
        IRewardTracker(stakedSbxTracker).unstakeForAccount(_account, _token, _amount, _account);

        if (_shouldReduceBnSbx) {
            uint256 bnSbxAmount = IRewardTracker(bonusSbxTracker).claimForAccount(_account, _account);
            if (bnSbxAmount > 0) {
                IRewardTracker(feeSbxTracker).stakeForAccount(_account, _account, bnSbx, bnSbxAmount);
            }

            uint256 stakedBnSbx = IRewardTracker(feeSbxTracker).depositBalances(_account, bnSbx);
            if (stakedBnSbx > 0) {
                uint256 reductionAmount = stakedBnSbx.mul(_amount).div(balance);
                IRewardTracker(feeSbxTracker).unstakeForAccount(_account, bnSbx, reductionAmount, _account);
                IMintable(bnSbx).burn(_account, reductionAmount);
            }
        }

        emit UnstakeSbx(_account, _token, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMintable {
    function isMinter(address _account) external returns (bool);
    function setMinter(address _minter, bool _isActive) external;
    function mint(address _account, uint256 _amount) external;
    function burn(address _account, uint256 _amount) external;
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}