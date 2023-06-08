// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
}

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint value) external returns (bool);

    function withdraw(uint) external;

    function balanceOf(address guy) external returns (uint);

    function approve(address guy, uint wad) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Module, ModuleData} from "./StructList.sol";
import {IERC20Metadata as IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IOps {
    function createTask(
        address execAddress,
        bytes calldata execDataOrSelector,
        ModuleData calldata moduleData,
        address feeToken
    ) external returns (bytes32 taskId);

    function cancelTask(bytes32 taskId) external;

    function getFeeDetails() external view returns (uint256, address);

    function gelato() external view returns (address payable);

    function taskTreasury() external view returns (ITaskTreasuryUpgradable);
}

interface ITaskTreasuryUpgradable {
    function depositFunds(
        address receiver,
        address token,
        uint256 amount
    ) external payable;

    function withdrawFunds(
        address payable receiver,
        address token,
        uint256 amount
    ) external;
}

interface IOpsProxyFactory {
    function getProxyOf(address account) external view returns (address, bool);
}

abstract contract OpsReady {
    IOps public immutable ops;
    address public immutable dedicatedMsgSender;
    address public immutable _gelato;
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant OPS_PROXY_FACTORY =
    0xC815dB16D4be6ddf2685C201937905aBf338F5D7;

    /**
     * @dev
     * Only tasks created by _taskCreator defined in constructor can call
     * the functions with this modifier.
     */
    modifier onlyDedicatedMsgSender() {
        require(msg.sender == dedicatedMsgSender, "Only dedicated msg.sender");
        _;
    }

    /**
     * @dev
     * _taskCreator is the address which will create tasks for this contract.
     */
    constructor(address _ops, address _taskCreator) {
        ops = IOps(_ops);
        _gelato = IOps(_ops).gelato();
        (dedicatedMsgSender,) = IOpsProxyFactory(OPS_PROXY_FACTORY).getProxyOf(
            _taskCreator
        );
    }

    /**
     * @dev
     * Transfers fee to gelato for synchronous fee payments.
     *
     * _fee & _feeToken should be queried from IOps.getFeeDetails()
     */
    function _transfer(uint256 _fee, address _feeToken) internal {
        if (_feeToken == ETH) {
            (bool success,) = _gelato.call{value : _fee}("");
            require(success, "_transfer: ETH transfer failed");
        } else {
            SafeERC20.safeTransfer(IERC20(_feeToken), _gelato, _fee);
        }
    }

    function _getFeeDetails()
    internal
    view
    returns (uint256 fee, address feeToken)
    {
        (fee, feeToken) = ops.getFeeDetails();
    }
}

abstract contract OpsTaskCreator is OpsReady {
    using SafeERC20 for IERC20;

    address public immutable fundsOwner;
    ITaskTreasuryUpgradable public immutable taskTreasury;

    constructor(address _ops, address _fundsOwner)
    OpsReady(_ops, address(this))
    {
        fundsOwner = _fundsOwner;
        taskTreasury = ops.taskTreasury();
    }

    /**
     * @dev
     * Withdraw funds from this contract's Gelato balance to fundsOwner.
     */
    function withdrawFunds(uint256 _amount, address _token) external {
        require(
            msg.sender == fundsOwner,
            "Only funds owner can withdraw funds"
        );

        taskTreasury.withdrawFunds(payable(fundsOwner), _token, _amount);
    }

    function _depositFunds(uint256 _amount, address _token) internal {
        uint256 ethValue = _token == ETH ? _amount : 0;
        taskTreasury.depositFunds{value : ethValue}(
            address(this),
            _token,
            _amount
        );
    }

    function _createTask(
        address _execAddress,
        bytes memory _execDataOrSelector,
        ModuleData memory _moduleData,
        address _feeToken
    ) internal returns (bytes32) {
        return
        ops.createTask(
            _execAddress,
            _execDataOrSelector,
            _moduleData,
            _feeToken
        );
    }

    function _cancelTask(bytes32 _taskId) internal {
        ops.cancelTask(_taskId);
    }

    function _resolverModuleArg(
        address _resolverAddress,
        bytes memory _resolverData
    ) internal pure returns (bytes memory) {
        return abi.encode(_resolverAddress, _resolverData);
    }

    function _timeModuleArg(uint256 _startTime, uint256 _interval)
    internal
    pure
    returns (bytes memory)
    {
        return abi.encode(uint128(_startTime), uint128(_interval));
    }

    function _proxyModuleArg() internal pure returns (bytes memory) {
        return bytes("");
    }

    function _singleExecModuleArg() internal pure returns (bytes memory) {
        return bytes("");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IERC20Metadata as IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Module, OrderType, ModuleData, TxItem, UserInfoItem, TokenInfoItem, TokenInfoItem2, LimitItem, TccItem, TcdItem, TaskConfig, BalanceItem, TokenItem, FeeItem, FeeItem2, SwapTokenItem, SwapEventItem, OrderEventItem, CreateItem, GasItem, GasItemList} from "./StructList.sol";
import {OrderBase} from "./OrderBase.sol";
import {IWETH} from "./IWETH.sol";

contract OrderAdmin is OrderBase {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeMath for uint256;
    EnumerableSet.Bytes32Set private activeManualOrderSet;
    mapping(address => EnumerableSet.Bytes32Set) private userAllLimitOrderList;
    mapping(address => EnumerableSet.Bytes32Set) private userActiveLimitOrderList;
    mapping(address => EnumerableSet.Bytes32Set) private userAllSwapOrderList;
    mapping(address => EnumerableSet.Bytes32Set) private userActiveSwapOrderList;
    mapping(address => EnumerableSet.AddressSet) private userTokenSet;
    mapping(address => EnumerableSet.UintSet) private userTxSet;

    constructor(
        uint256 _approveAmount,
        address payable _ops,
        address _fundsOwner,
        address _USDTPoolAddress,
        address _WETH,
        address _USDT
    ) OrderBase (_approveAmount, _ops, _fundsOwner, _USDTPoolAddress, _WETH, _USDT){}

    function setDedicatedMsgSenderList(address[] memory _dedicatedMsgSenderList, bool _status) external onlyOwner {
        uint256 _num = _dedicatedMsgSenderList.length;
        for (uint256 i = 0; i < _num; i++) {
            dedicatedMsgSenderList[_dedicatedMsgSenderList[i]] = _status;
        }
    }

    function setV2Dex(address _V2Dex) external onlyOwner {
        V2Dex = _V2Dex;
    }

    function setV3Dex(address _V3Dex) external onlyOwner {
        V3Dex = _V3Dex;
    }

    function setDevTokenAndFee(address _devToken, uint256 _devFee) external onlyOwner {
        devToken = _devToken;
        devFee = _devFee;
    }

    function setDefaultSwapInfo(uint256 _approveAmount) external onlyOwner {
        approveAmount = _approveAmount;
    }

    function setUsdtPoolAddress(address _usdtPoolAddress, address _weth) external onlyOwner {
        usdtPoolAddress = _usdtPoolAddress;
        weth = _weth;
    }

    function setFeeRates(uint256 _feeRate, uint256 _feeAllRate) external onlyOwner {
        feeRate = _feeRate;
        feeAllRate = _feeAllRate;
    }

    function setSwapRates(uint256 _swapRate, uint256 _swapAllRate) external onlyOwner {
        swapRate = _swapRate;
        swapAllRate = _swapAllRate;
    }

    function setTakeFeeGas(uint256 _takeFeeGas) external onlyOwner {
        takeFeeGas = _takeFeeGas;
    }

    function setGasRate(uint256 _gasRate) external onlyOwner {
        require(_gasRate > 100, "r001");
        gasRate = _gasRate;
    }

    function setGasPriceLimit(uint256 _gasPriceLimitForManual, uint256 _gasPriceLimitForAutomate) external onlyOwner {
        gasPriceLimitForManual = _gasPriceLimitForManual;
        gasPriceLimitForAutomate = _gasPriceLimitForAutomate;
    }

    function cancelTask(bytes32 _taskId) public nonReentrant {
        TaskConfig storage y = taskConfigList[_taskId];
        require(msg.sender == owner() || msg.sender == y.tcd._owner, "A01");
        if (!y.tcd._status) {
            return;
        }
        _cancelTask(_taskId);
        y.tcd._status = false;
        if (y.tcc._type == OrderType.LimitOrder) {
            address token = y.tcd._swapInToken;
            uint256 amount = y.tcd._maxSpendTokenAmount;
            emit FundsEvent(block.number, block.timestamp, msg.sender, token, IERC20(token).decimals(), amount, "withdraw limitOrder");
            if (token != weth) {
                IERC20(token).transfer(y.tcd._owner, amount);
            } else {
                IWETH(weth).withdraw(amount);
                payable(y.tcd._owner).transfer(amount);
            }
            userActiveLimitOrderList[msg.sender].remove(_taskId);
        } else {
            if (y.tcc._type == OrderType.ManualOrder) {
                activeManualOrderSet.remove(_taskId);
            }
            userActiveSwapOrderList[msg.sender].remove(_taskId);
        }
    }

    function massCancelTask(bytes32[] memory _taskIdList) external nonReentrant {
        uint256 _num = _taskIdList.length;
        for (uint256 i = 0; i < _num; i++) {
            bytes32 _taskId = _taskIdList[i];
            cancelTask(_taskId);
        }
    }

    function changeTaskType(bytes32 _taskId, OrderType _type) external {
        TaskConfig storage y = taskConfigList[_taskId];
        require(_type != OrderType.LimitOrder && y.tcc._type != OrderType.LimitOrder && _type != y.tcc._type, "L00");
        require(y.tcd._status, "L001");
        if (y.tcc._type == OrderType.ManualOrder) {
            activeManualOrderSet.remove(_taskId);
        }
        if (y.tcc._type == OrderType.AutomateOrder) {
            activeManualOrderSet.add(_taskId);
        }
        require(msg.sender == owner() || msg.sender == y.tcd._owner, "A02");
        y.tcc._type = _type;
    }

    function restartTask(bytes32 _taskId) public {
        TaskConfig storage y = taskConfigList[_taskId];
        require(msg.sender == owner() || msg.sender == y.tcd._owner, "A02");
        if ((y.tcc._type != OrderType.LimitOrder) && !y.tcd._status) {
            _createTask(y.tcd._execAddress, y.tcd._execDataOrSelector, y.tcd._moduleData, y.tcd._feeToken);
            y.tcd._status = true;
            if (y.tcc._type == OrderType.ManualOrder) {
                activeManualOrderSet.add(_taskId);
            }
            userActiveSwapOrderList[msg.sender].add(_taskId);
        }
    }

    function massRestartTask(bytes32[] memory _taskIdList) external {
        uint256 _num = _taskIdList.length;
        for (uint256 i = 0; i < _num; i++) {
            bytes32 _taskId = _taskIdList[i];
            restartTask(_taskId);
        }
    }

    function editTaskSwapAmountList(bytes32 _taskId, uint256[] memory _swapAmountList) external {
        TaskConfig storage y = taskConfigList[_taskId];
        require(msg.sender == owner() || msg.sender == y.tcd._owner, "No permission to modify");
        require(y.tcc._type != OrderType.LimitOrder, "A03");
        y.tcc._swapAmountList = _swapAmountList;
        lastSwapAmountIndexList[_taskId] = 0;
    }

    function editTaskStartEndTime(bytes32 _taskId, uint256[] memory _start_end_Time) external {
        TaskConfig storage y = taskConfigList[_taskId];
        require(msg.sender == owner() || msg.sender == y.tcd._owner, "No permission to modify");
        require((_start_end_Time.length == 2) && (_start_end_Time[1] > _start_end_Time[0]), "A04");
        y.tcc._start_end_Time = _start_end_Time;
    }

    function editTaskTimeList(bytes32 _taskId, uint256[] memory _timeList) external {
        TaskConfig storage y = taskConfigList[_taskId];
        require(msg.sender == owner() || msg.sender == y.tcd._owner, "No permission to modify");
        require((y.tcc._type != OrderType.LimitOrder) && _timeList.length % 2 == 0, "A05");
        y.tcc._timeList = _timeList;
    }

    function editTaskTimeIntervalList(bytes32 _taskId, uint256[] memory _timeIntervalList) external {
        TaskConfig storage y = taskConfigList[_taskId];
        require(msg.sender == owner() || msg.sender == y.tcd._owner, "No permission to modify");
        require((y.tcc._type != OrderType.LimitOrder) && _timeIntervalList.length > 0, "A06");
        y.tcc._timeIntervalList = _timeIntervalList;
        lastTimeIntervalIndexList[_taskId] = 0;
    }

    function editTaskSwapPriceZone(bytes32 _taskId, uint256 _minPrice, uint256 _maxPrice) external {
        require(_minPrice < _maxPrice, "B01");
        TaskConfig storage y = taskConfigList[_taskId];
        require(msg.sender == owner() || msg.sender == y.tcd._owner, "No permission to modify");
        require(y.tcc._swapPathConfig1._swapPriceZone.length == 2, "B02");
        y.tcc._swapPathConfig1._swapPriceZone[0] = _minPrice;
        y.tcc._swapPathConfig1._swapPriceZone[1] = _maxPrice;
    }

    function editTaskLimit(bytes32 _taskId, uint256 _maxtxAmount, uint256 _maxSpendTokenAmount, uint256 _maxFeePerTx) external {
        TaskConfig storage y = taskConfigList[_taskId];
        require(msg.sender == owner() || msg.sender == y.tcd._owner, "No permission to modify");
        require(_maxtxAmount > 0 && _maxSpendTokenAmount > 0 && _maxFeePerTx > 0, "A07");
        if (y.tcc._type != OrderType.LimitOrder) {
            y.tcc._maxtxAmount = _maxtxAmount;
            y.tcc._maxSpendTokenAmount = _maxSpendTokenAmount;
        }
        y.tcc._maxFeePerTx = _maxFeePerTx;
    }

    //    function editLimitOrder(bytes32 _taskId, uint256 _minswapOutAmount) external {
    //        TaskConfig storage y = taskConfigList[_taskId];
    //        require(msg.sender == owner() || msg.sender == y.tcd._owner, "No permission to modify");
    //        require((y.tcc._type == OrderType.LimitOrder) && y.tcd._status, "A08");
    //        y.tcc._limitItem._minswapOutAmount = _minswapOutAmount;
    //    }

    //刷单资产存入
    function deposit(address _token, uint256 _tokenAmount, uint256 _devAmount) external nonReentrant payable {
        address _user = msg.sender;
        uint256 _gasAmount = 0;
        if (_tokenAmount > 0) {
            if (_token != weth) {
                uint256 balance0 = IERC20(_token).balanceOf(address(this));
                IERC20(_token).transferFrom(_user, address(this), _tokenAmount);
                uint256 balance1 = IERC20(_token).balanceOf(address(this));
                _tokenAmount = balance1.sub(balance0);
            } else {
                IWETH(weth).deposit{value: _tokenAmount}();
                _gasAmount = msg.value.sub(_tokenAmount);
            }
            userTokenAmountList[_user][_token].depositAmount = userTokenAmountList[_user][_token].depositAmount.add(_tokenAmount);
            userTokenAmountList[_user][_token].leftAmount = userTokenAmountList[_user][_token].leftAmount.add(_tokenAmount);
            emit FundsEvent(block.number, block.timestamp, _user, _token, IERC20(_token).decimals(), _tokenAmount, "depositToken");
            if (!userTokenSet[_user].contains(_token)) {
                userTokenSet[_user].add(_token);
            }
        } else {
            _gasAmount = msg.value;
        }
        if (_gasAmount > 0) {
            userInfoList[_user].ethDepositAmount = userInfoList[_user].ethDepositAmount.add(msg.value);
            userInfoList[_user].ethAmount = userInfoList[_user].ethAmount.add(msg.value);
            emit FundsEvent(block.number, block.timestamp, _user, weth, 18, msg.value, "depositGas");
        }
        if (_devAmount > 0 && devToken != address(0) && devFee > 0) {
            uint256 balance0 = IERC20(devToken).balanceOf(address(this));
            IERC20(devToken).transferFrom(_user, address(this), _devAmount);
            uint256 balance1 = IERC20(devToken).balanceOf(address(this));
            _devAmount = balance1.sub(balance0);
            userInfoList[_user].devDepositAmount = userInfoList[_user].devDepositAmount.add(_devAmount);
            userInfoList[_user].devAmount = userInfoList[_user].devAmount.add(_devAmount);
            emit FundsEvent(block.number, block.timestamp, _user, devToken, 18, _devAmount, "depositDev");
        }
    }

    //刷单资产取出
    function withdraw(address _token, uint256 _tokenAmount, uint256 _ethAmount, uint256 _devAmount) external nonReentrant {
        address _user = msg.sender;
        require(_tokenAmount <= userTokenAmountList[_user][_token].leftAmount, "A09");
        require(_ethAmount <= userInfoList[_user].ethAmount, "A10");
        require(_devAmount <= userInfoList[msg.sender].devAmount, "A11");
        if (_tokenAmount > 0) {
            if (_token != weth) {
                IERC20(_token).transfer(_user, _tokenAmount);
            } else {
                IWETH(weth).withdraw(_tokenAmount);
                payable(_user).transfer(_tokenAmount);
            }
            userTokenAmountList[_user][_token].leftAmount = userTokenAmountList[_user][_token].leftAmount.sub(_tokenAmount);
            userTokenAmountList[_user][_token].withdrawAmount = userTokenAmountList[_user][_token].withdrawAmount.add(_tokenAmount);
            emit FundsEvent(block.number, block.timestamp, _user, _token, IERC20(_token).decimals(), _tokenAmount, "withdrawToken");
            if (userTokenAmountList[_user][_token].leftAmount == 0 && userTokenSet[_user].contains(_token)) {
                userTokenSet[_user].remove(_token);
            }
        }
        if (_ethAmount > 0) {
            payable(_user).transfer(_ethAmount);
            userInfoList[_user].ethAmount = userInfoList[_user].ethAmount.sub(_ethAmount);
            userInfoList[_user].ethWithdrawAmount = userInfoList[_user].ethWithdrawAmount.add(_ethAmount);
            emit FundsEvent(block.number, block.timestamp, _user, weth, 18, _ethAmount, "withdrawGas");
        }
        if (_devAmount > 0 && devToken != address(0) && devFee > 0) {
            IERC20(devToken).transfer(_user, _devAmount);
            userInfoList[_user].devAmount = userInfoList[_user].devAmount.sub(_devAmount);
            userInfoList[_user].devWithdrawAmount = userInfoList[_user].devWithdrawAmount.add(_devAmount);
            emit FundsEvent(block.number, block.timestamp, _user, devToken, 18, _devAmount, "withdrawDev");
        }
    }

    //刷单资产全部取出
    function withdrawAll() external nonReentrant {
        address _user = msg.sender;
        require(userInfoList[_user].ethAmount > 0 || userInfoList[_user].devAmount > 0, "A12");
        if (userInfoList[_user].ethAmount > 0) {
            emit FundsEvent(block.number, block.timestamp, _user, weth, 18, userInfoList[_user].ethAmount, "withdrawGas");
            payable(_user).transfer(userInfoList[_user].ethAmount);
            userInfoList[_user].ethWithdrawAmount = userInfoList[_user].ethWithdrawAmount.add(userInfoList[_user].ethAmount);
            userInfoList[_user].ethAmount = 0;
        }
        if (userInfoList[_user].devAmount > 0 && address(devToken) != address(0) && devFee > 0) {
            emit FundsEvent(block.number, block.timestamp, _user, address(devToken), 18, userInfoList[_user].devAmount, "withdrawDev");
            IERC20(devToken).transfer(_user, userInfoList[_user].devAmount);
            userInfoList[_user].devWithdrawAmount = userInfoList[_user].devWithdrawAmount.add(userInfoList[_user].devAmount);
            userInfoList[_user].devAmount = 0;
        }
    }

    //限价单资产取出
    function withdrawTokens(address[] memory _tokenList) external nonReentrant {
        uint256 j = 0;
        address _user = msg.sender;
        uint256 _num = _tokenList.length;
        for (uint256 i = 0; i < _num; i++) {
            address _token = _tokenList[i];
            if (userTokenAmountList[_user][_token].leftAmount > 0) {
                emit FundsEvent(block.number, block.timestamp, _user, _token, IERC20(_token).decimals(), userTokenAmountList[_user][_token].leftAmount, "withdraw limitOrder");
                IERC20(_token).transfer(_user, userTokenAmountList[_user][_token].leftAmount);
                userTokenAmountList[_user][_token].leftAmount = 0;
                userTokenAmountList[_user][_token].withdrawAmount = userTokenAmountList[_user][_token].withdrawAmount.add(userTokenAmountList[_user][_token].leftAmount);
                j = j.add(1);
            }
            if (userTokenSet[_user].contains(_token)) {
                userTokenSet[_user].remove(_token);
            }
        }
        require(j > 0, "A13");
    }

    function claimToken(IERC20 _token, uint256 _amount) external onlyOwner {
        require(_amount > 0 && _amount <= _token.balanceOf(address(this)), "A13");
        _token.transfer(msg.sender, _amount);
    }

    function claimEth(uint256 _amount) external onlyOwner {
        require(_amount > 0 && _amount <= address(this).balance, "A14");
        payable(msg.sender).transfer(_amount);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {OpsTaskCreator} from "./OpsTaskCreator.sol";
import {OrderEventItem, UserInfoItem, TaskConfig, TxItem, TokenInfoItem, OrderType, TccItem, TccItemV2, SwapEventItem, GasItemList} from "./StructList.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract OrderBase is OpsTaskCreator, Ownable, ReentrancyGuard {
    address internal V2Dex = 0xdBCA47a05324b06f31C5920923E66669ef210dD7;
    address internal V3Dex = 0x9E19784E77e13ac2Ca22E9E33C8a6bEF62774D2E;
    address internal usdtPoolAddress;
    address public weth;
    address internal usdt;
    address internal devToken;

    uint256 internal devFee;
    uint256 internal swapRate = 100;
    uint256 internal swapAllRate = 1000;
    uint256 internal feeRate = 1;
    uint256 internal feeAllRate = 1000;
    uint256 internal takeFeeGas = 100000;
    uint256 internal gasRate = 110;
    uint256 internal gasPriceLimitForManual = 4 * 10 ** 9;
    uint256 internal gasPriceLimitForAutomate = 4 * 10 ** 9;
    uint256 internal approveAmount;
    uint256 internal taskAmount;
    uint256 internal txAmount;
    uint256 internal totalFee;

    mapping(address => uint256) public userTxAmountList;
    mapping(uint256 => OrderEventItem) internal orderInfoList;
    mapping(address => uint256) public usertotalFeeList;
    mapping(uint256 => bytes32) internal taskList;
    mapping(bytes32 => bool) internal taskIdStatusList;
    mapping(address => UserInfoItem) public userInfoList;
    mapping(address => bytes32[]) internal userTaskList;
    mapping(bytes32 => bool) internal md5List;
    mapping(bytes32 => bytes32) internal md5TaskList;
    mapping(bytes32 => TaskConfig) public taskConfigList;
    mapping(bytes32 => uint256) internal lastExecutedTimeList;
    mapping(bytes32 => uint256) internal lastTimeIntervalIndexList;
    mapping(bytes32 => uint256) internal lastSwapAmountIndexList;
    mapping(bytes32 => mapping(uint256 => TxItem)) internal txHistoryList;
    mapping(address => bool) public dedicatedMsgSenderList;
    mapping(string => bool) internal taskNameList;
    mapping(address => mapping(address => TokenInfoItem)) internal userTokenAmountList;

    event CreateTaskEvent(uint256 _blockNumber, uint256 _timestamp, address indexed _user, bytes32 indexed _md5, uint256 _taskAmount, bytes32 indexed _taskId, OrderType _type, TccItemV2 _tcc);
    event OrderEvent(uint256 _blockNumber, uint256 _timestamp, OrderType _type, address indexed _user, bytes32 indexed _taskId, address _caller, uint256 _fee, SwapEventItem _swapEventItem);
    event FundsEvent(uint256 _blockNumber, uint256 _timestamp, address _user, address _token, uint256 _tokenDecimals, uint256 _amount, string _fundsType);
    event GasEvent(uint256 _gas0, GasItemList _gasList);

    constructor(
        uint256 _approveAmount,
        address payable _ops,
        address _fundsOwner,
        address _usdtPoolAddress,
        address _weth,
        address _usdt
    ) OpsTaskCreator(_ops, _fundsOwner){
        approveAmount = _approveAmount;
        usdtPoolAddress = _usdtPoolAddress;
        weth = _weth;
        usdt = _usdt;
        dedicatedMsgSenderList[dedicatedMsgSender] = true;
        dedicatedMsgSenderList[msg.sender] = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

    struct ExactInputParams {
        address factory;
        address[] tokenList;
        uint24[] feeList;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
        bool forceUseWETH;
    }

    enum Module {
        RESOLVER,
        TIME,
        PROXY,
        SINGLE_EXEC
    }

    enum OrderType{
        AutomateOrder,
        LimitOrder,
        ManualOrder
    }

    struct ModuleData {
        Module[] modules;
        bytes[] args;
    }

    struct TxItem {
        uint256 _totalTx;
        uint256 _totalSpendTokenAmount;
        uint256 _totalFee;
    }

    struct UserInfoItem {
        uint256 ethDepositAmount;
        uint256 ethAmount;
        uint256 ethUsedAmount;
        uint256 ethWithdrawAmount;
        uint256 devDepositAmount;
        uint256 devAmount;
        uint256 devUsedAmount;
        uint256 devWithdrawAmount;
    }

    struct TokenInfoItem {
        uint256 depositAmount;
        uint256 leftAmount;
        uint256 usedAmount;
        uint256 withdrawAmount;
    }

    struct TokenInfoItem2 {
        address token;
        uint256 decimals;
        string symbol;
        TokenInfoItem info;
    }

    struct LimitItem {
        uint256 _swapInDecimals;
        uint256 _swapInAmount;
        uint256 _swapInAmountOld;
        uint256 _swapOutDecimals;
        uint256 _swapOutStandardAmount;
        uint256 _minswapOutAmount;
        uint256 _swapOutAmount;
        uint256[] _swapPriceZone;
    }

    struct TccItem {
        string _taskName; //任务名字 (刷单/限价单)
        address[] _routerAddressList; //路由地址(刷单/限价单)
        address[] _swapRouter;  //usdt买代币(刷单/限价单)
        address[] _swapRouter2; //代币换USDT
        uint256 _interval; //触发频率,小于20每个区块都检测,大于20按指定的时间间隔检测条件
        uint256[] _start_end_Time; //开始和结束时间(刷单/限价单)
        uint256[] _timeList; //设置的交易时间段,两个一组(刷单)
        uint256[] _timeIntervalList; //交易的时间间隔列表(刷单)
        uint256[] _swapAmountList; //交易的USDT数量列表(刷单)
        uint256 _maxtxAmount; //每天的交易次数上限(刷单)
        uint256 _maxSpendTokenAmount; //每天刷单消耗USDT的总量上限(刷单)
        uint256 _maxFeePerTx; //每笔刷单消耗的GAS上限(刷单/限价单)
        LimitItem _limitItem; //(限价单)
        OrderType _type;
    }

    struct TcdItem {
        bool _status;
        bool _completed;
        uint256 _index;
        uint256 _taskExTimes;
        uint256 _totalFee;
        uint256 _maxSpendTokenAmount; //要交易的代币数量
        uint256 _swapInDecimals;
        uint256 _swapOutDecimals;
        address _owner;
        address _execAddress;
        address _feeToken;
        address _swapInToken;
        address _swapOutToken;
        bytes _execDataOrSelector;
        bytes32 _md5;
        bytes32 _taskId;
        ModuleData _moduleData;
    }

    struct TaskConfig {
        LimitItem _limitItem;
        TccItemV2 tcc;
        TcdItem tcd;
    }

    struct BalanceItem {
        uint256 balanceOfIn0;
        uint256 balanceOfOut0;
        uint256 balanceOfOut1;
        uint256 balanceOfIn1;
    }

    struct TokenItem {
        address swapInToken;
        address swapOutToken;
    }

    struct FeeItem {
        uint256 poolFee;
        uint256 allFee;
    }

    struct FeeItem2 {
        uint256 fee;
        address feeToken;
    }

    struct SwapTokenItem {
        uint256 day;
        uint256 claimAmount;
        uint256 swapInAmount;
        uint256 swapFee;
        uint256 spendSwapInToken;
        bytes32 taskId;
        TokenItem _TokenItem;
        BalanceItem _balanceItem;
        FeeItem _feeItem;
        FeeItem2 _feeItem2;
    }

    struct SwapEventItem {
        address _swapInToken;
        address _swapOutToken;
        uint256 _swapInDecimals;
        uint256 _swapOutDecimals;
        uint256 _usdtAmount;
        uint256 _spendUsdtAmount;
        uint256 _poolFee;
        uint256 _swapInAmount;
        uint256 _minswapOutAmount;
        uint256 _swapOutAmount;
    }

    struct OrderEventItem {
        uint256 _blockNumber;
        uint256 _timestamp;
        OrderType _type;
        address _user;
        bytes32 _taskId;
        address _caller;
        uint256 _fee;
        SwapEventItem _swapEventItem;
    }

    struct CreateItem {
        bytes32 md5;
        bytes execData;
        ModuleData moduleData;
        TaskConfig _taskConfig;
        bytes32 taskId;
        address swapInToken;
        address swapOutToken;
        uint256 tokenAmount0;
        uint256 tokenAmount1;
        uint256 tokenAmount;
    }

    struct GasItem {
        uint256 _gas0;
        uint256 _gas1;
        uint256 _gas2;
        uint256 _gas3;
        uint256 _gas4;
        uint256 _gas5;
        uint256 _gas6;
        uint256 _gas7;
        uint256 _gas8;
        uint256 _gas9;
        uint256 _gas10;
        uint256 _gas11;
        uint256 _gas12;
    }

    struct GasItemList {
        GasItem _gasItem0;
        GasItem _gasItem1;
        GasItem _gasItem2;
        GasItem _gasItem3;
        GasItem _gasItem4;
        GasItem _gasItem5;
    }

    struct taskInfoItem {
        TaskConfig _config;
        uint256 _lastExecutedTime;
        uint256 _nextTimeIntervalIndex;
        uint256 _nextSwapAmountIndex;
        uint256 _day;
        uint256 _userEthAmount;
        uint256 _userTokenAmount;
        TxItem _txInfo;
    }

    struct swapPathItem {
        address[] _swapPathList;
        address[] _routerAddressListV2;
        address[] _factoryV3;
        uint24[] _feeListV3;
        uint256[] _swapPriceZone; //成交区间
    }

    struct TccItemV2 {
        string _taskName; //任务名字 (刷单/限价单)
        uint256 _interval; //触发频率,小于20每个区块都检测,大于20按指定的时间间隔检测条件
        uint256[] _start_end_Time; //开始和结束时间(刷单/限价单)
        uint256[] _timeList; //设置的交易时间段,两个一组(刷单)
        uint256[] _timeIntervalList; //交易的时间间隔列表(刷单)
        uint256[] _swapAmountList; //交易的USDT数量列表(刷单)
        uint256 _maxtxAmount; //每天的交易次数上限(刷单)
        uint256 _maxSpendTokenAmount; //每天刷单消耗USDT的总量上限(刷单)
        uint256 _maxFeePerTx; //每笔刷单消耗的GAS上限(刷单/限价单)
        OrderType _type;
        swapPathItem _swapPathConfig1; //第一次兑换数据
        swapPathItem _swapPathConfig2; //第二次兑换数据
        bool isV3; //使用V3模式
    }

    struct BaseItem {
        address multiDexRouterAddress;
        address V3Dex;
        address usdtPoolAddress;
        address weth;
        address usdt;
        address devToken;
        uint256 devFee;
        uint256 swapRate;
        uint256 swapAllRate;
        uint256 feeRate;
        uint256 feeAllRate;
        uint256 takeFeeGas;
        uint256 gasRate;
        uint256 gasPriceLimitForManual;
        uint256 gasPriceLimitForAutomate;
        uint256 approveAmount;
        uint256 taskAmount;
        uint256 txAmount;
        uint256 totalFee;
    }