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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IPancakePair {
    function balanceOf(address owner) external view returns (uint);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

/// @title Farming contract for minted Narfex Token
/// @author Danil Sakhinov
/// @author Vladimir Smelov
/// @notice Distributes a reward from the balance instead of minting it
contract MasterChef is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // User share of a pool
    struct UserInfo {
        uint amount; // Amount of LP-tokens deposit
        uint withdrawnReward; // Reward already withdrawn
        uint depositTimestamp; // Last deposit time
        uint harvestTimestamp; // Last harvest time
        uint storedReward; // Reward tokens accumulated in contract (not paid yet)
    }

    struct PoolInfo {
        bool exist;  // default storage slot value is false, set true on adding
        IERC20 pairToken; // Address of LP token contract
        uint256 allocPoint; // How many allocation points assigned to this pool
        uint256 lastRewardBlock;  // Last block number that NRFX distribution occurs.
        uint256 accRewardPerShare; // Accumulated NRFX per share, times ACC_REWARD_PRECISION=1e12
        uint256 totalDeposited; // Total amount of LP-tokens deposited
    }

    uint256 constant internal ACC_REWARD_PRECISION = 1e12;

    /// @notice Reward token to harvest
    IERC20 public immutable rewardToken;

    /// @notice The interval from the deposit in which the commission for the reward will be taken.
    uint256 public earlyHarvestCommissionInterval = 14 days;

    /// @notice Interval since last harvest when next harvest is not possible
    uint256 public harvestInterval = 8 hours;

    /// @notice Commission for to early harvests with 2 digits of precision (10000 = 100%)
    uint256 public earlyHarvestCommission = 1000;  // 1000 = 10%

    /// @notice Referral percent for reward with 2 digits of precision (10000 = 100%)
    uint256 public constant referralPercent = 60;  // 60 = 0.6%

    /// @notice The address of the fee treasury
    address public feeTreasury;

    /// @notice DENOMINATOR for 100% with 2 digits of precision
    uint256 constant public HUNDRED_PERCENTS = 10000;

    /// @notice Info of each pool.
    PoolInfo[] public poolInfo;

    /// @notice Info of each user that stakes LP tokens.
    mapping (uint256 /*poolId*/ => mapping (address => UserInfo)) public userInfo;

    /// @notice Mapping of pools IDs for pair addresses
    mapping (address => uint256) public poolId;

    /// @notice Mapping of users referrals
    mapping (address => address) public referrals;

    /// @notice Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    /// @notice The block number when farming starts
    uint256 public immutable startBlock;
    /// @notice The block number when all allocated rewards will be distributed as rewards
    uint256 public endBlock;

    /// @notice This variable we need to understand how many rewards WAS transferred to the contract since the last call
    uint256 public lastRewardTokenBalance;
    /// @notice restUnallocatedRewards = rewards % rewardPerBlock it's not enough to give new block so we keep it to accumulate with future rewards
    /// @dev these rewards are not accounted in endBlock
    uint256 public restUnallocatedRewards;

    // There are 2 ways how to calculate reward per block:
    //   1) manually set by owner
    //   2) automatically calculated based on the remaining rewards via rewardPerBlockUpdater, see recalculateRewardPerBlock() function

    /// @notice Amount of NRFX per block for all pools
    uint256 public rewardPerBlock;
    /// @notice The address of the reward per block updater
    address public rewardPerBlockUpdater;
    /// @notice The number of blocks generated in the blockchain per day
    uint256 public blockchainBlocksPerDay; // Value is 40,000 on Polygon - https://flipsidecrypto.xyz/niloofar-discord/polygon-block-performance-sMKJcS
    /// @notice The number of days in the estimated reward period, e.g. if set to 100, 1/100 of the remaining rewards will be allocated each day
    uint256 public estimationRewardPeriodDays; // For example, if set to 100, 1/100 of the remaining rewards will be allocated each day

    /// @notice Set the number of blocks generated in the blockchain per day
    /// @param _newBlocksPerDay The new value for the blockchainBlocksPerDay variable
    event BlockchainBlocksPerDayUpdated(uint256 _newBlocksPerDay);

    /// @notice Set the number of days in the expected reward period
    /// @param _newRewardPeriodDays The new value for the estimationRewardPeriodDays variable
    event EstimationRewardPeriodDaysUpdated(uint256 _newRewardPeriodDays);

    /// @notice Set the address of the new reward per block updater
    /// @param _newUpdater The new address for the rewardPerBlockUpdater attribute
    event RewardPerBlockUpdaterUpdated(address indexed _newUpdater);

    /**
     * @notice Event emitted as a result of accounting for new rewards.
     * @param newRewardsAmount The amount of new rewards that were accounted for.
     * @param newEndBlock The block number until which new rewards will be accounted for.
     * @param newRestUnallocatedRewards The remaining unallocated amount of rewards.
     * @param newLastRewardTokenBalance The token balance in the master chef contract after accounting for new rewards.
     * @param afterEndBlock Flag indicating whether the accounting was done after the end of the term.
     */
    event NewRewardsAccounted(
        uint256 newRewardsAmount,
        uint256 newEndBlock,
        uint256 newRestUnallocatedRewards,
        uint256 newLastRewardTokenBalance,
        bool afterEndBlock
    );

    /// @notice Set the address of the new fee treasury
    /// @param _newTreasury The new address for the feeTreasury variable
    event FeeTreasuryUpdated(address indexed _newTreasury);

    /**
     * @notice Event emitted in case no new rewards were accounted for.
     */
    event NoNewRewardsAccounted();

    /**
     * @notice Emitted when the end block is recalculated (because of rewardPerBlock change).
     * @param newEndBlock The new end block number.
     * @param newRestUnallocatedRewards The new value of rest unallocated rewards.
     */
    event EndBlockRecalculatedBecauseOfRewardPerBlockChange(
        uint256 newEndBlock,
        uint256 newRestUnallocatedRewards
    );

    /**
     * @notice Emitted when the end block is recalculated (because of owner withdraw).
     * @param newEndBlock The new end block number.
     * @param newRestUnallocatedRewards The new value of rest unallocated rewards.
     */
    event EndBlockRecalculatedBecauseOfOwnerWithdraw(
        uint256 newEndBlock,
        uint256 newRestUnallocatedRewards
    );

    /**
     * @notice Emitted when the owner withdraws Narfex tokens.
     * @param owner The address of the owner who withdraws the tokens.
     * @param amount The amount of Narfex tokens withdrawn by the owner.
     */
    event WithdrawNarfexByOwner(
        address indexed owner,
        uint256 amount
    );

    /// @notice Emitted when the reward per block is recalculated
    /// @param newRewardPerBlock The new reward per block value
    /// @param futureUnallocatedRewards The future unallocated rewards amount
    /// @param estimationRewardPeriodDays The number of days in the expected reward period
    /// @param blockchainBlocksPerDay The number of blocks generated in the blockchain per day
    /// @param caller The address of the function caller
    event RewardPerBlockRecalculated(
        uint256 newRewardPerBlock,
        uint256 futureUnallocatedRewards,
        uint256 estimationRewardPeriodDays,
        uint256 blockchainBlocksPerDay,
        address indexed caller
    );

    /// @notice Event emitted when a user deposits tokens into a pool
    /// @param user The address of the user who deposited tokens
    /// @param pid The ID of the pool the user deposited tokens into
    /// @param amount The amount of tokens the user deposited
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);

    /// @notice Event emitted when a user withdraws tokens from a pool
    /// @param user The address of the user who withdrew tokens
    /// @param pid The ID of the pool the user withdrew tokens from
    /// @param amount The amount of tokens the user withdrew
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    /// @notice Event emitted when a user harvests rewards from a pool
    /// @param user The address of the user who harvested rewards
    /// @param pid The ID of the pool the user harvested rewards from
    /// @param amount The amount of rewards the user harvested
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);

    /// @notice Event emitted when a user emergency withdraws tokens from a pool
    /// @param user The address of the user who emergency withdrew tokens
    /// @param pid The ID of the pool the user emergency withdrew tokens from
    /// @param amount The amount of tokens the user emergency withdrew
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    /// @notice Event emitted when the total allocation points of all pools are updated
    /// @param totalAllocPoint The new total allocation points
    event TotalAllocPointUpdated(uint256 totalAllocPoint);

    /// @notice Event emitted when a new pool is added to the contract
    /// @param pid The ID of the new pool
    /// @param pairToken The address of the token pair used in the new pool
    /// @param allocPoint The allocation points for the new pool
    event PoolAdded(uint256 indexed pid, address indexed pairToken, uint256 allocPoint);

    /// @notice Event emitted when the allocation points for a pool are updated
    /// @param pid The ID of the pool
    /// @param allocPoint The new allocation points for the pool
    event PoolAllocPointSet(uint256 indexed pid, uint256 allocPoint);

    /// @notice Event emitted when the reward per block is updated
    /// @param rewardPerBlock The new reward per block value
    event RewardPerBlockSet(uint256 rewardPerBlock);

    /// @notice Event emitted when the early harvest commission interval is updated
    /// @param interval The new early harvest commission interval value
    event EarlyHarvestCommissionIntervalSet(uint256 interval);

    /// @notice Event emitted when the early harvest commission is updated
    /// @param percents The new early harvest commission value
    event EarlyHarvestCommissionSet(uint256 percents);

    /// @notice Event emitted when the harvest interval is updated
    /// @param interval The new harvest interval value
    event HarvestIntervalSet(uint256 interval);

    /// @notice Event emitted when a referral reward is paid to a user
    /// @param referral The address of the user who received the referral reward
    /// @param amount The amount of tokens paid as the referral reward
    event ReferralRewardPaid(address indexed referral, uint256 amount);

    /// @notice Event emitted when a referral reward is paid to a treasury
    /// @param treasury The address of the treasury who received the referral reward
    /// @param amount The amount of tokens paid as the referral reward
    event ReferralRewardPaidToTreasury(address indexed treasury, uint256 amount);

    /// @notice Emits an event when the early harvest commission is paid to the fee treasury
    /// @param _feeTreasury The address of the fee treasury receiving the commission
    /// @param _fee The amount of commission paid
    event EarlyHarvestCommissionPaid(address indexed _feeTreasury, uint256 _fee);

    /**
     * @notice This event is emitted when the last reward token balance decreases after a transfer.
     * @dev This event is useful for keeping track of changes in the last reward token balance.
     * @param amount The amount by which the last reward token balance has decreased.
     * @param lastRewardTokenBalance The last value of the balance.
     */
    event LastRewardTokenBalanceDecreasedAfterTransfer(uint256 amount, uint256 lastRewardTokenBalance);

    /// @notice Constructor for the Narfex MasterChef contract
    /// @param _rewardToken The address of the ERC20 token used for rewards (NRFX)
    /// @param _rewardPerBlock The amount of reward tokens allocated per block
    /// @param _feeTreasury The address of the fee treasury contract
    constructor(
        address _rewardToken,
        uint256 _rewardPerBlock,
        address _feeTreasury
    ) {
        require(_rewardToken != address(0), "zero address");
        rewardToken = IERC20(_rewardToken);
        rewardPerBlock = _rewardPerBlock;
        emit RewardPerBlockSet(rewardPerBlock);
        startBlock = block.number;
        endBlock = block.number;
        require(_feeTreasury != address(0), "zero address");
        feeTreasury = _feeTreasury;
    }

    /// @notice Updates the address of the reward per block updater
    /// @param _newUpdater The new address for the rewardPerBlockUpdater variable
    /// @dev Only the contract owner can call this function
    function setRewardPerBlockUpdater(address _newUpdater) external onlyOwner {
        rewardPerBlockUpdater = _newUpdater;
        emit RewardPerBlockUpdaterUpdated(_newUpdater);
    }

    /// @notice Updates the number of blockchain blocks per day
    /// @param _newBlocksPerDay The new value for the blockchainBlocksPerDay variable
    /// @dev Only the contract owner can call this function
    function setBlockchainBlocksPerDay(uint256 _newBlocksPerDay) external onlyOwner {
        blockchainBlocksPerDay = _newBlocksPerDay;
        emit BlockchainBlocksPerDayUpdated(_newBlocksPerDay);
    }

    /// @notice Updates the number of estimation reward period days
    /// @param _newRewardPeriodDays The new value for the estimationRewardPeriodDays variable
    /// @dev Only the contract owner can call this function
    function setEstimationRewardPeriodDays(uint256 _newRewardPeriodDays) external onlyOwner {
        estimationRewardPeriodDays = _newRewardPeriodDays;
        emit EstimationRewardPeriodDaysUpdated(_newRewardPeriodDays);
    }

    /// @notice Updates the address of the fee treasury
    /// @param _newTreasury The new address for the feeTreasury variable
    /// @dev Only the contract owner can call this function
    function setFeeTreasury(address _newTreasury) external onlyOwner {
        require(_newTreasury != address(0), "Invalid address provided.");
        feeTreasury = _newTreasury;
        emit FeeTreasuryUpdated(_newTreasury);
    }

    /// @notice Recalculates the reward per block based on the unallocated rewards and estimation reward period days
    /// @dev This function can be called by either the contract owner or rewardPerBlockUpdater
    function recalculateRewardPerBlock() external {
        require(msg.sender == owner() || msg.sender == rewardPerBlockUpdater, "no access");
        require(estimationRewardPeriodDays != 0, "estimationRewardPeriodDays is zero");
        require(blockchainBlocksPerDay != 0, "blockchainBlocksPerDay is zero");

        accountNewRewards();
        _massUpdatePools();

        uint256 _futureUnallocatedRewards = futureUnallocatedRewards();
        uint256 newRewardPerBlock = _futureUnallocatedRewards / (estimationRewardPeriodDays * blockchainBlocksPerDay);

        emit RewardPerBlockRecalculated({
            newRewardPerBlock: newRewardPerBlock,
            futureUnallocatedRewards: _futureUnallocatedRewards,
            estimationRewardPeriodDays: estimationRewardPeriodDays,
            blockchainBlocksPerDay: blockchainBlocksPerDay,
            caller: msg.sender
        });
        _setRewardPerBlock(newRewardPerBlock);
    }

    /**
     * @notice Account new rewards from the reward pool. This function can be called periodically by anyone to distribute new rewards to the reward pool.
     */
    function accountNewRewards() public {
        uint256 currentBalance = getNarfexBalance();
        uint256 newRewardsAmount = currentBalance - lastRewardTokenBalance;
        if (newRewardsAmount == 0) {
            emit NoNewRewardsAccounted();
            return;
        }
        uint256 _rewardPerBlockWithReferralPercent = rewardPerBlockWithReferralPercent();
        lastRewardTokenBalance = currentBalance;  // account new balance
        uint256 newRewardsToAccount = newRewardsAmount + restUnallocatedRewards;
        if ((block.number > endBlock) && (startBlock != endBlock)) {
            if (newRewardsToAccount > _rewardPerBlockWithReferralPercent) {
                // if there are more rewards than the reward per block, then we need to extend the end block

                _massUpdatePools();  // set all poolInfo.lastRewardBlock=block.number

                uint256 deltaBlocks = newRewardsToAccount / _rewardPerBlockWithReferralPercent;
                endBlock = block.number + deltaBlocks;  // start give rewards AGAIN from block.number
                restUnallocatedRewards = newRewardsToAccount - deltaBlocks * _rewardPerBlockWithReferralPercent;  // (newRewardsAmount + restUnallocatedRewards) % rewardPerBlockWithReferralPercent
                emit NewRewardsAccounted({
                    newRewardsAmount: newRewardsAmount,
                    newEndBlock: endBlock,
                    newRestUnallocatedRewards: restUnallocatedRewards,
                    newLastRewardTokenBalance: lastRewardTokenBalance,
                    afterEndBlock: true
                });

                return;
            }

            // accumulate rewards in `restUnallocatedRewards` after the end block
            // note that if startBlock == endBlock it will make initial endBlock setting
            restUnallocatedRewards = newRewardsToAccount;
            emit NewRewardsAccounted({
                newRewardsAmount: newRewardsAmount,
                newEndBlock: endBlock,
                newRestUnallocatedRewards: restUnallocatedRewards,
                newLastRewardTokenBalance: lastRewardTokenBalance,
                afterEndBlock: true
            });
            return;
        }
        uint256 _deltaBlocks = newRewardsToAccount / _rewardPerBlockWithReferralPercent;
        endBlock += _deltaBlocks;
        restUnallocatedRewards = newRewardsToAccount - _deltaBlocks * _rewardPerBlockWithReferralPercent;  // (newRewardsAmount + restUnallocatedRewards) % rewardPerBlockWithReferralPercent
        emit NewRewardsAccounted({
            newRewardsAmount: newRewardsAmount,
            newEndBlock: endBlock,
            newRestUnallocatedRewards: restUnallocatedRewards,
            newLastRewardTokenBalance: lastRewardTokenBalance,
            afterEndBlock: false
        });
    }

    /// @notice Calculates the reward per block with referral percentage included
    /// @dev Calculates the reward per block with referral percentage included by multiplying the reward per block by 100% + referral percent
    /// @return The reward per block with referral percentage included
    function rewardPerBlockWithReferralPercent() public view returns(uint256) {
        return rewardPerBlock * (HUNDRED_PERCENTS + referralPercent) / HUNDRED_PERCENTS;
    }

    /// @notice Count of created pools
    /// @return poolInfo length
    function getPoolsCount() external view returns (uint256) {
        return poolInfo.length;
    }

    /// @notice Returns the balance of reward token in the contract
    /// @return Reward left in the common pool
    function getNarfexBalance() public view returns (uint) {
        return rewardToken.balanceOf(address(this));
    }

    /// @notice Calculate the estimated unallocated rewards for the remaining blocks
    /// @return The estimated unallocated rewards for the remaining blocks
    function futureUnallocatedRewards() public view returns(uint256) {
        if (block.number >= endBlock) {
            return restUnallocatedRewards;
        } else {
            uint256 futureBlocks = endBlock - block.number;
            uint256 _rewardPerBlockWithReferralPercent = rewardPerBlockWithReferralPercent();
            return _rewardPerBlockWithReferralPercent * futureBlocks + restUnallocatedRewards;
        }
    }

    /// @notice Calculate the estimated end block and remaining rewards based on the provided reward allocation
    /// @param _rewards The total unallocated rewards to be distributed
    /// @param _rewardPerBlock The reward allocation per block
    /// @return _endBlock The estimated end block
    /// @return _rest The estimated remaining rewards
    function calculateFutureRewardAllocationWithArgs(
        uint256 _rewards,
        uint256 _rewardPerBlock
    ) public view returns(
        uint256 _endBlock,
        uint256 _rest
    ) {
        // Calculate the number of blocks needed to allocate the remaining rewards
        uint256 blocks = _rewards / _rewardPerBlock;

        // Calculate the estimated end block based on the current block number and the number of blocks needed
        _endBlock = block.number + blocks;

        // Calculate the remaining rewards after all full blocks have been allocated
        _rest = _rewards - blocks * _rewardPerBlock;
    }

    /**
     * @notice Withdraws an amount of reward tokens to the owner of the contract. Only unallocated reward tokens can be withdrawn.
     * @param amount The amount of reward tokens to withdraw
     * @dev Only the contract owner can call this function
     */
    function withdrawNarfexByOwner(uint256 amount) external onlyOwner nonReentrant {
        // Validate the withdrawal amount
        require(amount > 0, "zero amount");
        require(amount <= getNarfexBalance(), "Not enough reward tokens left");

        accountNewRewards();

        // Calculate the remaining rewards
        uint256 _futureUnallocatedRewards = futureUnallocatedRewards();
        require(amount <= _futureUnallocatedRewards, "not enough unallocated rewards");
        
        // Calculate the new unallocated rewards after the withdrawal
        uint256 newUnallocatedRewards = _futureUnallocatedRewards - amount;
        
        // Update the end block and remaining unallocated rewards
        (endBlock, restUnallocatedRewards) = calculateFutureRewardAllocationWithArgs(newUnallocatedRewards, rewardPerBlockWithReferralPercent());
        
        // Emit events for the updated end block and withdrawn amount
        emit EndBlockRecalculatedBecauseOfOwnerWithdraw(endBlock, restUnallocatedRewards);
        emit WithdrawNarfexByOwner(msg.sender, amount);
        
        // Transfer the withdrawn amount to the contract owner's address
        _transferNRFX(msg.sender, amount);
    }

    /**
     * @notice Modifier that checks if the pool corresponding to a given pair address exists
     * @param _pairAddress The address of the pool's pair token
     */
    modifier onlyExistPool(address _pairAddress) {
        require(poolExists(_pairAddress), "pool not exist");
        _;
    }

     /**
      * @notice Checks if the pool corresponding to a given pair address exists
      * @param _pairAddress The address of the pool's pair token
      * @return True if the pool exists, false otherwise
      */
    function poolExists(address _pairAddress) public view returns(bool) {
        if (poolInfo.length == 0) {  // prevent out of bounds error
            return false;
        }
        return poolInfo[poolId[_pairAddress]].exist;
    }

    /// @notice Add a new pool
    /// @param _allocPoint Allocation point for this pool
    /// @param _pairAddress Address of LP token contract
    function add(uint256 _allocPoint, address _pairAddress) external onlyOwner nonReentrant {
        require(!poolExists(_pairAddress), "already exists");
        _massUpdatePools();
        uint256 lastRewardBlock = Math.max(block.number, startBlock);
        totalAllocPoint = totalAllocPoint + _allocPoint;
        emit TotalAllocPointUpdated(totalAllocPoint);
        poolInfo.push(PoolInfo({
            pairToken: IERC20(_pairAddress),
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accRewardPerShare: 0,
            exist: true,
            totalDeposited: 0
        }));
        poolId[_pairAddress] = poolInfo.length - 1;
        emit PoolAdded({
            pid: poolId[_pairAddress],
            pairToken: _pairAddress,
            allocPoint: _allocPoint
        });
    }

    /// @notice Update allocation points for a pool
    /// @param _pid Pool index
    /// @param _allocPoint Allocation points
    function set(uint256 _pid, uint256 _allocPoint) external onlyOwner nonReentrant {
        _massUpdatePools();
        totalAllocPoint = totalAllocPoint + _allocPoint - poolInfo[_pid].allocPoint;
        emit TotalAllocPointUpdated(totalAllocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;  // note: revert if not exist
        emit PoolAllocPointSet({
            pid: _pid,
            allocPoint: _allocPoint
        });
    }

    /// @notice Set a new reward per block amount (runs _massUpdatePools)
    /// @param _amount Amount of reward tokens per block
    function setRewardPerBlock(uint256 _amount) external onlyOwner nonReentrant {
        _setRewardPerBlock(_amount);
    }

    /// @dev Set a new reward per block amount
    function _setRewardPerBlock(uint256 newRewardPerBlock) internal {
        accountNewRewards();
        _massUpdatePools();  // set poolInfo.lastRewardBlock=block.number

        uint256 futureRewards = futureUnallocatedRewards();
        rewardPerBlock = newRewardPerBlock;
        emit RewardPerBlockSet(newRewardPerBlock);

        // endBlock = currentBlock + unallocatedRewards / rewardPerBlock
        // so now we should update the endBlock since rewardPerBlock was changed
        uint256 _rewardPerBlockWithReferralPercent = rewardPerBlockWithReferralPercent();
        uint256 deltaBlocks = futureRewards / _rewardPerBlockWithReferralPercent;
        endBlock = block.number + deltaBlocks;
        restUnallocatedRewards = futureRewards - deltaBlocks * _rewardPerBlockWithReferralPercent;
        emit EndBlockRecalculatedBecauseOfRewardPerBlockChange({
            newEndBlock: endBlock,
            newRestUnallocatedRewards: restUnallocatedRewards
        });
    }

    /// @notice Calculates the reward for a user based on their staked amount, accumulated reward per share, and withdrawn and stored rewards.
    /// @param user UserInfo storage of the user for whom to calculate the reward
    /// @param _accRewardPerShare Accumulated reward per share, calculated as (total reward / total staked amount)
    /// @return The reward amount for the user based on their staked amount and the accumulated reward per share, minus the withdrawn rewards, and plus the stored rewards.
    function _calculateUserReward(
        UserInfo storage user,
        uint256 _accRewardPerShare
    ) internal view returns (uint256) {
        return user.amount * _accRewardPerShare / ACC_REWARD_PRECISION - user.withdrawnReward + user.storedReward;
    }

    /// @notice Calculates the user's reward based on a blocks range
    /// @param _pairAddress The address of LP token
    /// @param _user The user address
    /// @return reward size
    /// @dev Only for frontend view
    function getUserReward(address _pairAddress, address _user) public view onlyExistPool(_pairAddress) returns (uint256) {
        uint256 _pid = poolId[_pairAddress];
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 lpSupply = pool.totalDeposited;
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 rightBlock = Math.min(block.number, endBlock);
            uint256 leftBlock = Math.max(pool.lastRewardBlock, startBlock);
            if (rightBlock > leftBlock) {
                uint256 blocks = rightBlock - leftBlock;
                uint256 reward = blocks * rewardPerBlock * pool.allocPoint / totalAllocPoint;
                accRewardPerShare += reward * ACC_REWARD_PRECISION / lpSupply;
            }
        }
        return _calculateUserReward(user, accRewardPerShare);
    }

    /// @notice If enough time has passed since the last harvest
    /// @param _pairAddress The address of LP token
    /// @param _user The user address
    /// @return true if user can harvest
    function getIsUserCanHarvest(address _pairAddress, address _user) public view onlyExistPool(_pairAddress) returns (bool) {
        uint256 _pid = poolId[_pairAddress];
        UserInfo storage user = userInfo[_pid][_user];
        bool isEarlyHarvest = block.timestamp - user.harvestTimestamp < harvestInterval;
        return !isEarlyHarvest;
    }

    /// @notice Returns user's amount of LP tokens
    /// @param _pairAddress The address of LP token
    /// @param _user The user address
    /// @return user's pool size
    function getUserPoolSize(address _pairAddress, address _user) external view onlyExistPool(_pairAddress) returns (uint) {
        uint256 _pid = poolId[_pairAddress];
        return userInfo[_pid][_user].amount;
    }

    /// @notice Returns contract settings by one request
    /// @return uintRewardPerBlock uintRewardPerBlock
    /// @return uintEarlyHarvestCommissionInterval uintEarlyHarvestCommissionInterval
    /// @return uintHarvestInterval uintHarvestInterval
    /// @return uintEarlyHarvestCommission uintEarlyHarvestCommission
    /// @return uintReferralPercent uintReferralPercent
    function getSettings() public view returns (
        uint uintRewardPerBlock,
        uint uintEarlyHarvestCommissionInterval,
        uint uintHarvestInterval,
        uint uintEarlyHarvestCommission,
        uint uintReferralPercent
    ) {
        return (
            rewardPerBlock,
            earlyHarvestCommissionInterval,
            harvestInterval,
            earlyHarvestCommission,
            referralPercent
        );
    }

    /// @notice Get pool data in one request
    /// @param _pairAddress The address of LP token
    /// @return token0 First token address
    /// @return token1 Second token address
    /// @return token0symbol First token symbol
    /// @return token1symbol Second token symbol
    /// @return totalDeposited Total amount of LP tokens deposited
    /// @return poolShare Share of the pool based on allocation points
    function getPoolData(address _pairAddress) public view onlyExistPool(_pairAddress) returns (
        address token0,
        address token1,
        string memory token0symbol,
        string memory token1symbol,
        uint totalDeposited,
        uint poolShare
    ) {
        uint256 _pid = poolId[_pairAddress];
        IPancakePair pairToken = IPancakePair(_pairAddress);
        IERC20Metadata _token0 = IERC20Metadata(pairToken.token0());
        IERC20Metadata _token1 = IERC20Metadata(pairToken.token1());

        return (
            pairToken.token0(),
            pairToken.token1(),
            _token0.symbol(),
            _token1.symbol(),
            poolInfo[_pid].totalDeposited,
            poolInfo[_pid].allocPoint * HUNDRED_PERCENTS / totalAllocPoint
        );
    }

    /// @notice Returns pool data in one request
    /// @param _pairAddress The ID of liquidity pool
    /// @param _user The user address
    /// @return balance User balance of LP token
    /// @return userPool User liquidity pool size in the current pool
    /// @return reward Current user reward in the current pool
    /// @return isCanHarvest Is it time to harvest the reward
    function getPoolUserData(address _pairAddress, address _user) public view onlyExistPool(_pairAddress) returns (
        uint balance,
        uint userPool,
        uint256 reward,
        bool isCanHarvest
    ) {
        return (
            IPancakePair(_pairAddress).balanceOf(_user),
            userInfo[poolId[_pairAddress]][_user].amount,
            getUserReward(_pairAddress, _user),
            getIsUserCanHarvest(_pairAddress, _user)
        );
    }

    /// @notice Sets the early harvest commission interval
    /// @param interval Interval size in seconds
    function setEarlyHarvestCommissionInterval(uint interval) external onlyOwner nonReentrant {
        earlyHarvestCommissionInterval = interval;
        emit EarlyHarvestCommissionIntervalSet(interval);
    }

    /// @notice Sets the harvest interval
    /// @param interval Interval size in seconds
    function setHarvestInterval(uint interval) external onlyOwner nonReentrant {
        harvestInterval = interval;
        emit HarvestIntervalSet(interval);
    }

    /// @notice Sets the early harvest commission
    /// @param percents Early harvest commission in percents denominated by 10000 (1000 for default 10%)
    function setEarlyHarvestCommission(uint percents) external onlyOwner nonReentrant {
        earlyHarvestCommission = percents;
        emit EarlyHarvestCommissionSet(percents);
    }

    /**
     * @notice Updates all pools and rewards the users with the new rewards
     * @dev Calls the internal function _massUpdatePools
     * @dev This function should be called before any deposit, withdrawal, or harvest operation
     * @dev Only one call to this function can be made at a time
     */
    function massUpdatePools() external nonReentrant {
        accountNewRewards();
        _massUpdatePools();
    }

    /**
     * @dev Internal function that updates all pools
     */
    function _massUpdatePools() internal {
        uint256 length = poolInfo.length;
        unchecked {
            for (uint256 pid = 0; pid < length; ++pid) {
                _updatePool(pid);
            }
        }
    }

    /// @notice Update reward variables of the given pool to be up-to-date
    /// @param _pid Pool index
    function updatePool(uint256 _pid) external nonReentrant {
        accountNewRewards();
        _updatePool(_pid);
    }

    function _updatePool(uint256 _pid) internal {  // todo tricky enable disable
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.totalDeposited;
        if (lpSupply == 0) {
            // WARNING: always keep some small deposit in every pool
            // there could be a small problem if no one will deposit in the pool with e.g. 30% allocation point
            // then the reward for this 30% alloc points will never be distributed
            // however endBlock is already set, so no one will harvest the.
            // But fixing this problem with math would increase complexity of the code.
            // So just let the owner to keep 1 lp token in every pool to mitigate this problem.
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 rightBlock = Math.min(block.number, endBlock);
        uint256 leftBlock = Math.max(pool.lastRewardBlock, startBlock);
        if (rightBlock <= leftBlock) {
           pool.lastRewardBlock = block.number;
           return;  // after endBlock passed we continue to scroll lastRewardBlock with no update of accRewardPerShare
        }
        uint256 blocks = rightBlock - leftBlock;
        uint256 reward = blocks * rewardPerBlock * pool.allocPoint / totalAllocPoint;
        pool.accRewardPerShare += reward * ACC_REWARD_PRECISION / lpSupply;
        pool.lastRewardBlock = block.number;
    }

    /// @dev some erc20 may have internal transferFee or deflationary mechanism so the actual received amount after transfer will not match the transfer amount
    function _safeTransferFromCheckingBalance(IERC20 token, address from, address to, uint256 amount) internal {
        uint256 balanceBefore = token.balanceOf(to);
        token.safeTransferFrom(from, to, amount);
        require(token.balanceOf(to) - balanceBefore == amount, "transfer amount mismatch");
    }

    /// @notice Deposit LP tokens to the farm. It will try to harvest first
    /// @param _pairAddress The address of LP token
    /// @param _amount Amount of LP tokens to deposit
    /// @param _referral Address of the agent who invited the user
    function deposit(address _pairAddress, uint256 _amount, address _referral) public onlyExistPool(_pairAddress) nonReentrant {
        accountNewRewards();
        uint256 _pid = poolId[_pairAddress];
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        _updatePool(_pid);

        if (user.amount > 0) {
            uint256 pending = _calculateUserReward(user, pool.accRewardPerShare);
            if (pending > 0) {
                _rewardTransfer({user: user, _amount: pending, isWithdraw: false, _pid: _pid});
            }
        }
        if (_amount > 0) {
            _safeTransferFromCheckingBalance(IERC20(pool.pairToken), msg.sender, address(this), _amount);
            user.amount += _amount;
            pool.totalDeposited += _amount;
        }
        user.withdrawnReward = user.amount * pool.accRewardPerShare / ACC_REWARD_PRECISION;
        user.depositTimestamp = block.timestamp;
        emit Deposit(msg.sender, _pid, _amount);
        if (_referral != address(0) && _referral != msg.sender && referrals[msg.sender] != _referral) {
            referrals[msg.sender] = _referral;
        }
    }

    /**
     * @notice Deposit tokens into a pool without referral
     * @param _pairAddress Address of the pair token to deposit into
     * @param _amount Amount of tokens to deposit
     */
    function depositWithoutRefer(address _pairAddress, uint256 _amount) public {
        deposit(_pairAddress, _amount, address(0));
    }

    /// @notice Withdraw LP tokens from the farm. It will try to harvest first
    /// @param _pairAddress The address of LP token
    /// @param _amount Amount of LP tokens to withdraw
    function withdraw(address _pairAddress, uint256 _amount) public nonReentrant onlyExistPool(_pairAddress) {
        accountNewRewards();
        uint256 _pid = poolId[_pairAddress];
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        _updatePool(_pid);

        require(user.amount >= _amount, "Too big amount");
        _harvest(_pairAddress);
        uint256 pending = _calculateUserReward(user, pool.accRewardPerShare);
        if (pending > 0) {
            _rewardTransfer({user: user, _amount: pending, isWithdraw: true, _pid: _pid});
        }
        if (_amount > 0) {
            user.amount -= _amount;
            pool.totalDeposited -= _amount;
            pool.pairToken.safeTransfer(address(msg.sender), _amount);
        }
        user.withdrawnReward = user.amount * pool.accRewardPerShare / ACC_REWARD_PRECISION;
        emit Withdraw(msg.sender, _pid, _amount);
    }

    /// @notice Returns LP tokens to the user with the entire reward reset to zero
    /// @param _pairAddress The address of LP token
    function emergencyWithdraw(address _pairAddress) public {
        uint256 _pid = poolId[_pairAddress];
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.pairToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.withdrawnReward = 0;
        user.storedReward = 0;
    }

    /// @notice Harvest rewards for the given pool and transfer them to the user's address.
    /// @param _pairAddress The address of the pool contract.
    function _harvest(address _pairAddress) internal {
        uint256 _pid = poolId[_pairAddress];
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        _updatePool(_pid);
        uint256 pending = _calculateUserReward(user, pool.accRewardPerShare);
        if (pending > 0) {
            _rewardTransfer({user: user, _amount: pending, isWithdraw: true, _pid: _pid});
        }
        user.withdrawnReward = user.amount * pool.accRewardPerShare / ACC_REWARD_PRECISION;
    }
    
    /// @notice Harvest reward from the pool and send to the user
    /// @param _pairAddress The address of LP token
    function harvest(address _pairAddress) public onlyExistPool(_pairAddress) {
        _harvest(_pairAddress);
    }

    /// @notice Recover any accidentally sent native currency
    /// @param to Address to receive the native currency
    /// @param amount Amount of native currency to recover
    function recoverNative(address payable to, uint256 amount) external onlyOwner nonReentrant {
        // Send the native currency to the specified address
        (bool success,) = to.call{value: amount}("");
        require(success, "Failed to send native currency");
    }

    /// @notice Recover any token accidentally sent to the contract (does not allow recover deposited LP and reward tokens)
    /// @param token Token to recover
    /// @param to Where to send recovered tokens
    function recoverERC20(address token, address to, uint256 amount) public onlyOwner nonReentrant {
        require(token != address(rewardToken), "cannot recover reward token");
        if (poolExists(token)) {
            PoolInfo storage pool = poolInfo[poolId[token]];
            uint256 rest = IERC20(token).balanceOf(address(this)) - pool.totalDeposited;
            require(amount <= rest, "cannot withdraw deposited amount");
            IERC20(token).safeTransfer(to, amount);
        } else {
            IERC20(token).safeTransfer(to, amount);
        }
    }

    /// @notice Transfer reward with all checks
    /// @param user UserInfo storage pointer
    /// @param _amount Amount of reward to transfer
    /// @param isWithdraw Set to false if it called by deposit function
    /// @param _pid Pool index
    function _rewardTransfer(
        UserInfo storage user,
        uint256 _amount,
        bool isWithdraw,
        uint256 _pid
    ) internal {
        bool isEarlyHarvestCommission = block.timestamp - user.depositTimestamp < earlyHarvestCommissionInterval;
        bool isEarlyHarvest = block.timestamp - user.harvestTimestamp < harvestInterval;
        
        if (isEarlyHarvest) {
            user.storedReward = _amount;
            return;
        }

        uint amountToUser = _amount;
        if (isWithdraw && isEarlyHarvestCommission) {
            uint256 fee = earlyHarvestCommission / HUNDRED_PERCENTS;
            amountToUser = _amount - fee;
            _transferNRFX(feeTreasury, fee);
            emit EarlyHarvestCommissionPaid(feeTreasury, fee);
        }

        uint256 harvestedAmount = _transferNRFX(msg.sender, amountToUser);
        emit Harvest(msg.sender, _pid, harvestedAmount);

        // Send referral reward
        address referral = referrals[msg.sender];
        uint256 referralAmount = _amount * referralPercent / HUNDRED_PERCENTS;  // note: initial _amount not amountToUser
        if (referral != address(0)) {
            uint256 referralRewardPaid = _transferNRFX(referral, referralAmount);
            emit ReferralRewardPaid(referral, referralRewardPaid);
        } else {
            uint256 referralRewardPaid = _transferNRFX(feeTreasury, referralAmount);
            emit ReferralRewardPaidToTreasury(feeTreasury, referralRewardPaid);
        }

        user.storedReward = 0;
        user.harvestTimestamp = block.timestamp;
    }

    /**
     * @notice Transfer a specified amount of NRFX tokens to a specified address, after ensuring that there are sufficient
     *         NRFX tokens remaining in the contract. If the remaining NRFX tokens are less than the specified amount,
     *         then transfer the remaining amount of NRFX tokens. If the transferred amount is greater than zero.
     *         This function is intended to be used for transferring NRFX tokens for referral rewards.
     * @param to The address to which the NRFX tokens are transferred
     * @param amount The amount of NRFX tokens to transfer
     * @return The amount of NRFX tokens that were actually transferred
     */
    function _transferNRFX(address to, uint256 amount) internal returns(uint256) {
        // Get the remaining NRFX tokens
        uint256 narfexLeft = getNarfexBalance();

        // If the remaining NRFX tokens are less than the specified amount, transfer the remaining amount of NRFX tokens
        if (narfexLeft < amount) {
            amount = narfexLeft;
        }
        if (amount > 0) {
            rewardToken.safeTransfer(to, amount);
            lastRewardTokenBalance -= amount;
            emit LastRewardTokenBalanceDecreasedAfterTransfer(amount, lastRewardTokenBalance);
        }
        return amount;
    }
}