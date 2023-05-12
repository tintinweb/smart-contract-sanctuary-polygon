// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;

/*
  ______                     ______                                 
 /      \                   /      \                                
|  ▓▓▓▓▓▓\ ______   ______ |  ▓▓▓▓▓▓\__   __   __  ______   ______  
| ▓▓__| ▓▓/      \ /      \| ▓▓___\▓▓  \ |  \ |  \|      \ /      \ 
| ▓▓    ▓▓  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\\▓▓    \| ▓▓ | ▓▓ | ▓▓ \▓▓▓▓▓▓\  ▓▓▓▓▓▓\
| ▓▓▓▓▓▓▓▓ ▓▓  | ▓▓ ▓▓    ▓▓_\▓▓▓▓▓▓\ ▓▓ | ▓▓ | ▓▓/      ▓▓ ▓▓  | ▓▓
| ▓▓  | ▓▓ ▓▓__/ ▓▓ ▓▓▓▓▓▓▓▓  \__| ▓▓ ▓▓_/ ▓▓_/ ▓▓  ▓▓▓▓▓▓▓ ▓▓__/ ▓▓
| ▓▓  | ▓▓ ▓▓    ▓▓\▓▓     \\▓▓    ▓▓\▓▓   ▓▓   ▓▓\▓▓    ▓▓ ▓▓    ▓▓
 \▓▓   \▓▓ ▓▓▓▓▓▓▓  \▓▓▓▓▓▓▓ \▓▓▓▓▓▓  \▓▓▓▓▓\▓▓▓▓  \▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓ 
         | ▓▓                                             | ▓▓      
         | ▓▓                                             | ▓▓      
          \▓▓                                              \▓▓         

 * App:             https://apeswap.finance
 * Medium:          https://ape-swap.medium.com
 * Twitter:         https://twitter.com/ape_swap
 * Discord:         https://discord.com/invite/apeswap
 * Telegram:        https://t.me/ape_swap
 * Announcements:   https://t.me/ape_swap_news
 * GitHub:          https://github.com/ApeSwapFinance
 */

import "./lib/IApeSwapZap.sol";
import "./lib/IApeRouter02.sol";
import "./lib/IApeFactory.sol";
import "./lib/IApePair.sol";
import "./utils/TransferHelper.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ApeSwapZap is TransferHelper, IApeSwapZap, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct BalanceLocalVars {
        uint256 amount0;
        uint256 amount1;
    }

    IApeRouter02 public immutable router;
    IApeFactory public immutable factory;

    event Zap(address inputToken, uint256 inputAmount, address[] lpTokens, uint256 amountA, uint256 amountB);

    constructor(IApeRouter02 _router) TransferHelper(IWETH(_router.WETH())) {
        router = _router;
        factory = IApeFactory(router.factory());
    }

    /// @dev The receive method is used as a fallback function in a contract
    /// and is called when ether is sent to a contract with no calldata.
    receive() external payable {
        require(msg.sender == address(WNATIVE), "ApeSwapZap: Only receive ether from wrapped");
    }

    /// @notice Zap single token to LP
    /// @param inputToken Input token
    /// @param inputAmount Input amount
    /// @param lpTokens Tokens of LP to zap to
    /// @param path0 Path from input token to LP token0
    /// @param path1 Path from input token to LP token1
    /// @param minAmountsSwap The minimum amount of output tokens that must be received for swap
    /// @param minAmountsLP AmountAMin and amountBMin for adding liquidity
    /// @param to address to receive LPs
    /// @param deadline Unix timestamp after which the transaction will revert
    function zap(
        IERC20 inputToken,
        uint256 inputAmount,
        address[] memory lpTokens, //[tokenA, tokenB]
        address[] calldata path0,
        address[] calldata path1,
        uint256[] memory minAmountsSwap, //[A, B]
        uint256[] memory minAmountsLP, //[amountAMin, amountBMin]
        address to,
        uint256 deadline
    ) external override nonReentrant {
        inputAmount = _transferIn(inputToken, inputAmount);
        _zap(
            ZapParams({
                inputToken: inputToken,
                inputAmount: inputAmount,
                lpTokens: lpTokens,
                path0: path0,
                path1: path1,
                minAmountsSwap: minAmountsSwap,
                minAmountsLP: minAmountsLP,
                to: to,
                deadline: deadline
            }),
            false
        );
    }

    /// @notice Zap native token to LP
    /// @param lpTokens Tokens of LP to zap to
    /// @param path0 Path from input token to LP token0
    /// @param path1 Path from input token to LP token1
    /// @param minAmountsSwap The minimum amount of output tokens that must be received for swap
    /// @param minAmountsLP AmountAMin and amountBMin for adding liquidity
    /// @param to address to receive LPs
    /// @param deadline Unix timestamp after which the transaction will revert
    function zapNative(
        address[] memory lpTokens, //[tokenA, tokenB]
        address[] calldata path0,
        address[] calldata path1,
        uint256[] memory minAmountsSwap, //[A, B]
        uint256[] memory minAmountsLP, //[amountAMin, amountBMin]
        address to,
        uint256 deadline
    ) external payable override nonReentrant {
        (IERC20 weth, uint256 inputAmount) = _wrapNative();
        _zap(
            ZapParams({
                inputToken: weth,
                inputAmount: inputAmount,
                lpTokens: lpTokens,
                path0: path0,
                path1: path1,
                minAmountsSwap: minAmountsSwap,
                minAmountsLP: minAmountsLP,
                to: to,
                deadline: deadline
            }),
            true
        );
    }

    /// @notice get min amounts for swaps
    /// @param inputAmount total input amount for swap
    /// @param path0 path from input token to LP token0
    /// @param path1 path from input token to LP token1
    function getMinAmounts(
        uint256 inputAmount,
        address[] calldata path0,
        address[] calldata path1
    ) external view override returns (uint256[2] memory minAmountsSwap, uint256[2] memory minAmountsLP) {
        require(path0.length >= 2 || path1.length >= 2, "ApeSwapZap: Needs at least one path");

        uint256 inputAmountHalf = inputAmount / 2;

        uint256 minAmountSwap0 = inputAmountHalf;
        if (path0.length != 0) {
            uint256[] memory amountsOut0 = router.getAmountsOut(inputAmountHalf, path0);
            minAmountSwap0 = amountsOut0[amountsOut0.length - 1];
        }

        uint256 minAmountSwap1 = inputAmountHalf;
        if (path1.length != 0) {
            uint256[] memory amountsOut1 = router.getAmountsOut(inputAmountHalf, path1);
            minAmountSwap1 = amountsOut1[amountsOut1.length - 1];
        }

        address token0 = path0.length == 0 ? path1[0] : path0[path0.length - 1];
        address token1 = path1.length == 0 ? path0[0] : path1[path1.length - 1];

        IApePair lp = IApePair(factory.getPair(token0, token1));
        (uint256 reserveA, uint256 reserveB, ) = lp.getReserves();
        if (token0 == lp.token1()) {
            (reserveA, reserveB) = (reserveB, reserveA);
        }
        uint256 amountB = router.quote(minAmountSwap0, reserveA, reserveB);

        minAmountsSwap = [minAmountSwap0, minAmountSwap1];
        minAmountsLP = [minAmountSwap0, amountB];
    }

    /// @notice Swap single token to single token
    /// @param amountIn Amount of input token to pass in
    /// @param amountOutMin Min amount of output token to accept
    /// @param path Path from input token to output token
    /// @param deadline Unix timestamp after which the transaction will revert
    /// @return amountOut The final amount of output tokens received
    function _routerSwap(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        uint256 deadline,
        bool needApproval
    ) internal returns (uint256 amountOut) {
        require(amountIn > 0, "ApeSwapZap: amountIn must be greater than zero");
        if (needApproval) {
            IERC20(path[0]).approve(address(router), amountIn);
        }
        address outputToken = path[path.length - 1];
        uint256 balanceBefore = _getBalance(IERC20(outputToken));
        router.swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), deadline);
        amountOut = _getBalance(IERC20(outputToken)) - balanceBefore;
    }

    /// @dev Zap single token input to UniV2 LP token
    /// @param zapParams ZapParams struct
    /// @param nativeOut Whether to unwrap native token when refunding sender
    function _zap(ZapParams memory zapParams, bool nativeOut) internal {
        require(zapParams.inputAmount > 0, "ApeSwapZap: inputAmount must be greater than zero");
        require(zapParams.to != address(0), "ApeSwapZap: Can't zap to null address");
        require(zapParams.lpTokens.length == 2, "ApeSwapZap: need exactly 2 tokens to form a LP");
        require(
            factory.getPair(zapParams.lpTokens[0], zapParams.lpTokens[1]) != address(0),
            "ApeSwapZap: Pair doesn't exist"
        );

        BalanceLocalVars memory vars;

        zapParams.inputToken.approve(address(router), zapParams.inputAmount);

        vars.amount0 = zapParams.inputAmount / 2;
        if (zapParams.lpTokens[0] != address(zapParams.inputToken)) {
            uint256 path0Length = zapParams.path0.length;
            require(path0Length > 0, "ApeSwapZap: path0 is required for this operation");
            require(zapParams.path0[0] == address(zapParams.inputToken), "ApeSwapZap: wrong path path0[0]");
            require(zapParams.path0[path0Length - 1] == zapParams.lpTokens[0], "ApeSwapZap: wrong path path0[-1]");
            vars.amount0 = _routerSwap(
                vars.amount0,
                zapParams.minAmountsSwap[0],
                zapParams.path0,
                zapParams.deadline,
                false
            );
        }

        vars.amount1 = zapParams.inputAmount / 2;
        if (zapParams.lpTokens[1] != address(zapParams.inputToken)) {
            uint256 path1Length = zapParams.path1.length;
            require(path1Length > 0, "ApeSwapZap: path1 is required for this operation");
            require(zapParams.path1[0] == address(zapParams.inputToken), "ApeSwapZap: wrong path path1[0]");
            require(zapParams.path1[path1Length - 1] == zapParams.lpTokens[1], "ApeSwapZap: wrong path path1[-1]");
            vars.amount1 = _routerSwap(
                vars.amount1,
                zapParams.minAmountsSwap[1],
                zapParams.path1,
                zapParams.deadline,
                false
            );
        }

        IERC20(zapParams.lpTokens[0]).approve(address(router), vars.amount0);
        IERC20(zapParams.lpTokens[1]).approve(address(router), vars.amount1);
        (uint256 amountA, uint256 amountB, ) = router.addLiquidity(
            zapParams.lpTokens[0],
            zapParams.lpTokens[1],
            vars.amount0,
            vars.amount1,
            zapParams.minAmountsLP[0],
            zapParams.minAmountsLP[1],
            zapParams.to,
            zapParams.deadline
        );

        emit Zap(address(zapParams.inputToken), zapParams.inputAmount, zapParams.lpTokens, amountA, amountB);

        if (zapParams.lpTokens[0] == address(WNATIVE)) {
            // Ensure WNATIVE is called last
            _transferOut(IERC20(zapParams.lpTokens[1]), vars.amount1 - amountB, msg.sender, nativeOut);
            _transferOut(IERC20(zapParams.lpTokens[0]), vars.amount0 - amountA, msg.sender, nativeOut);
        } else {
            _transferOut(IERC20(zapParams.lpTokens[0]), vars.amount0 - amountA, msg.sender, nativeOut);
            _transferOut(IERC20(zapParams.lpTokens[1]), vars.amount1 - amountB, msg.sender, nativeOut);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;

/*
  ______                     ______                                 
 /      \                   /      \                                
|  ▓▓▓▓▓▓\ ______   ______ |  ▓▓▓▓▓▓\__   __   __  ______   ______  
| ▓▓__| ▓▓/      \ /      \| ▓▓___\▓▓  \ |  \ |  \|      \ /      \ 
| ▓▓    ▓▓  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\\▓▓    \| ▓▓ | ▓▓ | ▓▓ \▓▓▓▓▓▓\  ▓▓▓▓▓▓\
| ▓▓▓▓▓▓▓▓ ▓▓  | ▓▓ ▓▓    ▓▓_\▓▓▓▓▓▓\ ▓▓ | ▓▓ | ▓▓/      ▓▓ ▓▓  | ▓▓
| ▓▓  | ▓▓ ▓▓__/ ▓▓ ▓▓▓▓▓▓▓▓  \__| ▓▓ ▓▓_/ ▓▓_/ ▓▓  ▓▓▓▓▓▓▓ ▓▓__/ ▓▓
| ▓▓  | ▓▓ ▓▓    ▓▓\▓▓     \\▓▓    ▓▓\▓▓   ▓▓   ▓▓\▓▓    ▓▓ ▓▓    ▓▓
 \▓▓   \▓▓ ▓▓▓▓▓▓▓  \▓▓▓▓▓▓▓ \▓▓▓▓▓▓  \▓▓▓▓▓\▓▓▓▓  \▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓ 
         | ▓▓                                             | ▓▓      
         | ▓▓                                             | ▓▓      
          \▓▓                                              \▓▓         

 * App:             https://apeswap.finance
 * Medium:          https://ape-swap.medium.com
 * Twitter:         https://twitter.com/ape_swap
 * Discord:         https://discord.com/invite/apeswap
 * Telegram:        https://t.me/ape_swap
 * Announcements:   https://t.me/ape_swap_news
 * GitHub:          https://github.com/ApeSwapFinance
 */

import "./ApeSwapZap.sol";
import "./extensions/bills/ApeSwapZapTBills.sol";
import "./extensions/farms/ApeSwapZapMiniApeV2.sol";
import "./lib/IApeRouter02.sol";

/// @author ApeSwap
/// @dev Zap contract for ApeSwap staking features on Polygon
contract ApeSwapZapPolygonV0 is ApeSwapZap, ApeSwapZapTBills, ApeSwapZapMiniApeV2 {
    constructor(IApeRouter02 _router) ApeSwapZap(_router) ApeSwapZapTBills() ApeSwapZapMiniApeV2() {}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../../ApeSwapZap.sol";
import "./lib/ICustomBill.sol";

abstract contract ApeSwapZapTBills is ApeSwapZap {
    using SafeERC20 for IERC20;

    event ZapTBill(ICustomBill bill, IERC20 principalToken, uint256 depositAmount, uint256 payoutAmount);

    /// @notice Zap single token to LP
    /// @param inputToken Input token to zap
    /// @param inputAmount Amount of input tokens to zap
    /// @param lpTokens Tokens of LP to zap to
    /// @param path0 Path from input token to LP token0
    /// @param path1 Path from input token to LP token1
    /// @param minAmountsSwap The minimum amount of output tokens that must be received for swap
    /// @param minAmountsLP AmountAMin and amountBMin for adding liquidity
    /// @param deadline Unix timestamp after which the transaction will revert
    /// @param bill Treasury bill address
    /// @param maxPrice Max price of treasury bill
    function zapTBill(
        IERC20 inputToken,
        uint256 inputAmount,
        address[] memory lpTokens, //[tokenA, tokenB]
        address[] calldata path0,
        address[] calldata path1,
        uint256[] memory minAmountsSwap, //[A, B]
        uint256[] memory minAmountsLP, //[amountAMin, amountBMin]
        uint256 deadline,
        ICustomBill bill,
        uint256 maxPrice
    ) external nonReentrant {
        IApePair principalToken = _validateTBillZap(lpTokens, bill);
        inputAmount = _transferIn(inputToken, inputAmount);
        _zap(
            ZapParams({
                inputToken: inputToken,
                inputAmount: inputAmount,
                lpTokens: lpTokens,
                path0: path0,
                path1: path1,
                minAmountsSwap: minAmountsSwap,
                minAmountsLP: minAmountsLP,
                to: address(this),
                deadline: deadline
            }),
            false
        );

        (uint256 depositAmount, uint256 payoutAmount) = _depositTBill(
            bill,
            IERC20(address(principalToken)),
            maxPrice,
            msg.sender
        );
        emit ZapTBill(bill, IERC20(address(principalToken)), depositAmount, payoutAmount);
    }

    /// @notice Zap native token to Treasury Bill
    /// @param lpTokens Tokens of LP to zap to
    /// @param path0 Path from input token to LP token0
    /// @param path1 Path from input token to LP token1
    /// @param minAmountsSwap The minimum amount of output tokens that must be received for swap
    /// @param minAmountsLP AmountAMin and amountBMin for adding liquidity
    /// @param deadline Unix timestamp after which the transaction will revert
    /// @param bill Treasury bill address
    /// @param maxPrice Max price of treasury bill
    function zapTBillNative(
        address[] memory lpTokens, //[tokenA, tokenB]
        address[] calldata path0,
        address[] calldata path1,
        uint256[] memory minAmountsSwap, //[A, B]
        uint256[] memory minAmountsLP, //[amountAMin, amountBMin]
        uint256 deadline,
        ICustomBill bill,
        uint256 maxPrice
    ) external payable nonReentrant {
        IApePair principalToken = _validateTBillZap(lpTokens, bill);
        (IERC20 weth, uint256 inputAmount) = _wrapNative();
        _zap(
            ZapParams({
                inputToken: weth,
                inputAmount: inputAmount,
                lpTokens: lpTokens,
                path0: path0,
                path1: path1,
                minAmountsSwap: minAmountsSwap,
                minAmountsLP: minAmountsLP,
                to: address(this),
                deadline: deadline
            }),
            true
        );

        (uint256 depositAmount, uint256 payoutAmount) = _depositTBill(
            bill,
            IERC20(address(principalToken)),
            maxPrice,
            msg.sender
        );
        emit ZapTBill(bill, IERC20(address(principalToken)), depositAmount, payoutAmount);
    }

    /// @notice Zap token to single asset Treasury Bill
    /// @param inputToken Input token to zap
    /// @param inputAmount Amount of input tokens to zap
    /// @param path Path from input token to stake token
    /// @param minAmountsSwap The minimum amount of output tokens that must be received for swap
    /// @param deadline Unix timestamp after which the transaction will revert
    /// @param bill Pool address
    /// @param maxPrice MaxPrice for purchasing a bill
    function zapSingleAssetTBill(
        IERC20 inputToken,
        uint256 inputAmount,
        address[] calldata path,
        uint256 minAmountsSwap,
        uint256 deadline,
        ICustomBill bill,
        uint256 maxPrice
    ) external nonReentrant {
        inputAmount = _transferIn(inputToken, inputAmount);
        _zapSingleAssetTBill(inputToken, inputAmount, path, minAmountsSwap, deadline, bill, maxPrice);
    }

    /// @notice Zap native token to single asset Treasury Bill
    /// @param path Path from input token to stake token
    /// @param minAmountsSwap The minimum amount of output tokens that must be received for swap
    /// @param deadline Unix timestamp after which the transaction will revert
    /// @param bill Pool address
    /// @param maxPrice MaxPrice for purchasing a bill
    function zapSingleAssetTBillNative(
        address[] calldata path,
        uint256 minAmountsSwap,
        uint256 deadline,
        ICustomBill bill,
        uint256 maxPrice
    ) external payable nonReentrant {
        (IERC20 weth, uint256 inputAmount) = _wrapNative();
        _zapSingleAssetTBill(weth, inputAmount, path, minAmountsSwap, deadline, bill, maxPrice);
    }

    /** INTERNAL FUNCTIONs **/

    /// @notice Zap token to single asset Treasury Bill
    /// @param inputToken Input token to zap
    /// @param inputAmount Amount of input tokens to zap
    /// @param path Path from input token to stake token
    /// @param minAmountsSwap The minimum amount of output tokens that must be received for swap
    /// @param deadline Unix timestamp after which the transaction will revert
    /// @param bill Pool address
    /// @param maxPrice MaxPrice for purchasing a bill
    function _zapSingleAssetTBill(
        IERC20 inputToken,
        uint256 inputAmount,
        address[] calldata path,
        uint256 minAmountsSwap,
        uint256 deadline,
        ICustomBill bill,
        uint256 maxPrice
    ) internal {
        IERC20 principalToken = IERC20(bill.principalToken());
        require(
            (address(inputToken) == path[0] && address(principalToken) == path[path.length - 1]),
            "ApeSwapZapTBills: Wrong path for inputToken or principalToken"
        );

        _routerSwap(inputAmount, minAmountsSwap, path, deadline, true);
        (uint256 depositAmount, uint256 payoutAmount) = _depositTBill(bill, principalToken, maxPrice, msg.sender);

        emit ZapTBill(bill, principalToken, depositAmount, payoutAmount);
    }

    /** INTERNAL FUNCTIONS **/

    function _depositTBill(
        ICustomBill bill,
        IERC20 principalToken,
        uint256 maxPrice,
        address depositor
    ) internal returns (uint256 depositAmount, uint256 payoutAmount) {
        depositAmount = principalToken.balanceOf(address(this));
        require(depositAmount > 0, "ApeSwapZapTBills: Nothing to deposit");
        principalToken.approve(address(bill), depositAmount);
        payoutAmount = bill.deposit(depositAmount, maxPrice, depositor);
        principalToken.approve(address(bill), 0);
    }

    function _validateTBillZap(
        address[] memory lpTokens,
        ICustomBill bill
    ) internal view returns (IApePair principalToken) {
        principalToken = IApePair(bill.principalToken());
        require(
            (lpTokens[0] == principalToken.token0() && lpTokens[1] == principalToken.token1()) ||
                (lpTokens[1] == principalToken.token0() && lpTokens[0] == principalToken.token1()),
            "ApeSwapZapTBills: Wrong LP pair for TBill"
        );
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface ICustomBill {
    function principalToken() external view returns (address);

    function deposit(uint256 _amount, uint256 _maxPrice, address _depositor) external returns (uint256 payout);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../../ApeSwapZap.sol";
import "./lib/IMiniApeV2.sol";

abstract contract ApeSwapZapMiniApeV2 is ApeSwapZap {
    using SafeERC20 for IERC20;

    event ZapMiniApeV2(IERC20 inputToken, uint256 inputAmount, uint256 pid);
    event ZapMiniApeV2Native(uint256 inputAmount, uint256 pid);

    constructor() {}

    /// @notice Zap token into miniApev2 style dual farm
    /// @param inputToken Input token to zap
    /// @param inputAmount Amount of input tokens to zap
    /// @param lpTokens Tokens of LP to zap to
    /// @param path0 Path from input token to LP token0
    /// @param path1 Path from input token to LP token1
    /// @param minAmountsSwap The minimum amount of output tokens that must be received for swap
    /// @param minAmountsLP AmountAMin and amountBMin for adding liquidity
    /// @param deadline Unix timestamp after which the transaction will revert
    /// @param miniApe The main dualfarm contract
    /// @param pid Dual farm pid
    function zapMiniApeV2(
        IERC20 inputToken,
        uint256 inputAmount,
        address[] memory lpTokens, //[tokenA, tokenB]
        address[] calldata path0,
        address[] calldata path1,
        uint256[] memory minAmountsSwap, //[A, B]
        uint256[] memory minAmountsLP, //[amountAMin, amountBMin]
        uint256 deadline,
        IMiniApeV2 miniApe,
        uint256 pid
    ) external nonReentrant {
        IApePair pair = _validateMiniApeV2Zap(lpTokens, miniApe, pid);
        inputAmount = _transferIn(inputToken, inputAmount);
        _zap(
            ZapParams({
                inputToken: inputToken,
                inputAmount: inputAmount,
                lpTokens: lpTokens,
                path0: path0,
                path1: path1,
                minAmountsSwap: minAmountsSwap,
                minAmountsLP: minAmountsLP,
                to: address(this),
                deadline: deadline
            }),
            false
        );

        uint256 balance = pair.balanceOf(address(this));
        pair.approve(address(miniApe), balance);
        miniApe.deposit(pid, balance, msg.sender);
        pair.approve(address(miniApe), 0);
        emit ZapMiniApeV2(inputToken, inputAmount, pid);
    }

    /// @notice Zap native into miniApev2 style dual farm
    /// @param lpTokens Tokens of LP to zap to
    /// @param path0 Path from input token to LP token0
    /// @param path1 Path from input token to LP token1
    /// @param minAmountsSwap The minimum amount of output tokens that must be received for swap
    /// @param minAmountsLP AmountAMin and amountBMin for adding liquidity
    /// @param deadline Unix timestamp after which the transaction will revert
    /// @param miniApe The main dualfarm contract
    /// @param pid Dual Farm pid
    function zapMiniApeV2Native(
        address[] memory lpTokens, //[tokenA, tokenB]
        address[] calldata path0,
        address[] calldata path1,
        uint256[] memory minAmountsSwap, //[A, B]
        uint256[] memory minAmountsLP, //[amountAMin, amountBMin]
        uint256 deadline,
        IMiniApeV2 miniApe,
        uint256 pid
    ) external payable nonReentrant {
        (IERC20 weth, uint256 inputAmount) = _wrapNative();
        _zap(
            ZapParams({
                inputToken: weth,
                inputAmount: inputAmount,
                lpTokens: lpTokens,
                path0: path0,
                path1: path1,
                minAmountsSwap: minAmountsSwap,
                minAmountsLP: minAmountsLP,
                to: address(this),
                deadline: deadline
            }),
            true
        );

        IApePair pair = _validateMiniApeV2Zap(lpTokens, miniApe, pid);
        uint256 balance = pair.balanceOf(address(this));
        pair.approve(address(miniApe), balance);
        miniApe.deposit(pid, balance, msg.sender);
        pair.approve(address(miniApe), 0);
        emit ZapMiniApeV2Native(msg.value, pid);
    }

    /** PRIVATE FUNCTIONs **/

    function _validateMiniApeV2Zap(
        address[] memory lpTokens,
        IMiniApeV2 miniApe,
        uint256 pid
    ) private view returns (IApePair pair) {
        pair = IApePair(miniApe.lpToken(pid));
        require(
            (lpTokens[0] == pair.token0() && lpTokens[1] == pair.token1()) ||
                (lpTokens[1] == pair.token0() && lpTokens[0] == pair.token1()),
            "ApeSwapZapMiniApeV2: Wrong LP pair for Dual Farm"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMiniApeV2 {
    function lpToken(uint256 pid) external view returns (address);

    function deposit(uint256 pid, uint256 amount, address to) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.6.6;

interface IApeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function INIT_CODE_PAIR_HASH() external view returns (bytes32);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address token0, address token1) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(address token0, address token1) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.6.6;

interface IApePair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IApeRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address token0,
        address token1,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidity(
        address token0,
        address token1,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address token0,
        address token1,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./IApeRouter01.sol";

interface IApeRouter02 is IApeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

/*
  ______                     ______                                 
 /      \                   /      \                                
|  ▓▓▓▓▓▓\ ______   ______ |  ▓▓▓▓▓▓\__   __   __  ______   ______  
| ▓▓__| ▓▓/      \ /      \| ▓▓___\▓▓  \ |  \ |  \|      \ /      \ 
| ▓▓    ▓▓  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\\▓▓    \| ▓▓ | ▓▓ | ▓▓ \▓▓▓▓▓▓\  ▓▓▓▓▓▓\
| ▓▓▓▓▓▓▓▓ ▓▓  | ▓▓ ▓▓    ▓▓_\▓▓▓▓▓▓\ ▓▓ | ▓▓ | ▓▓/      ▓▓ ▓▓  | ▓▓
| ▓▓  | ▓▓ ▓▓__/ ▓▓ ▓▓▓▓▓▓▓▓  \__| ▓▓ ▓▓_/ ▓▓_/ ▓▓  ▓▓▓▓▓▓▓ ▓▓__/ ▓▓
| ▓▓  | ▓▓ ▓▓    ▓▓\▓▓     \\▓▓    ▓▓\▓▓   ▓▓   ▓▓\▓▓    ▓▓ ▓▓    ▓▓
 \▓▓   \▓▓ ▓▓▓▓▓▓▓  \▓▓▓▓▓▓▓ \▓▓▓▓▓▓  \▓▓▓▓▓\▓▓▓▓  \▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓ 
         | ▓▓                                             | ▓▓      
         | ▓▓                                             | ▓▓      
          \▓▓                                              \▓▓         

 * App:             https://apeswap.finance
 * Medium:          https://ape-swap.medium.com
 * Twitter:         https://twitter.com/ape_swap
 * Discord:         https://discord.com/invite/apeswap
 * Telegram:        https://t.me/ape_swap
 * Announcements:   https://t.me/ape_swap_news
 * GitHub:          https://github.com/ApeSwapFinance
 */

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IApeSwapZap {
    struct ZapParams {
        IERC20 inputToken;
        uint256 inputAmount;
        address[] lpTokens; // [token0, token1]
        address[] path0;
        address[] path1;
        uint256[] minAmountsSwap; // [A, B]
        uint256[] minAmountsLP; // [amountAMin, amountBMin]
        address to;
        uint256 deadline;
    }

    function zap(
        IERC20 inputToken,
        uint256 inputAmount,
        address[] memory lpTokens, //[token0, token1]
        address[] calldata path0,
        address[] calldata path1,
        uint256[] memory minAmountsSwap, //[A, B]
        uint256[] memory minAmountsLP, //[amountAMin, amountBMin]
        address to,
        uint256 deadline
    ) external;

    function zapNative(
        address[] memory lpTokens, //[token0, token1]
        address[] calldata path0,
        address[] calldata path1,
        uint256[] memory minAmountsSwap, //[A, B]
        uint256[] memory minAmountsLP, //[amountAMin, amountBMin]
        address to,
        uint256 deadline
    ) external payable;

    function getMinAmounts(
        uint256 inputAmount,
        address[] calldata path0,
        address[] calldata path1
    ) external view returns (uint256[2] memory minAmountsSwap, uint256[2] memory minAmountsLP);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../lib/IWETH.sol";

contract TransferHelper {
    using SafeERC20 for IERC20;

    IWETH public immutable WNATIVE;

    constructor(IWETH wnative) {
        WNATIVE = wnative;
    }

    /// @notice Wrap the msg.value into the Wrapped Native token
    /// @return wNative The IERC20 representation of the wrapped asset
    /// @return amount Amount of native tokens wrapped
    function _wrapNative() internal returns (IERC20 wNative, uint256 amount) {
        wNative = IERC20(address(WNATIVE));
        amount = msg.value;
        WNATIVE.deposit{value: amount}();
    }

    /// @notice Unwrap current balance of Wrapped Native tokens
    /// @return amount Amount of native tokens unwrapped
    function _unwrapNative() internal returns (uint256 amount) {
        amount = _getBalance(IERC20(address(WNATIVE)));
        IWETH(WNATIVE).withdraw(amount);
    }

    function _transferIn(IERC20 token, uint256 amount) internal returns (uint256 inputAmount) {
        if (amount == 0) return 0;
        uint256 balanceBefore = _getBalance(token);
        token.safeTransferFrom(msg.sender, address(this), amount);
        inputAmount = _getBalance(token) - balanceBefore;
    }

    function _transferOut(IERC20 token, uint256 amount, address to, bool native) internal {
        if (amount == 0) return;
        if (address(token) == address(WNATIVE) && native) {
            IWETH(WNATIVE).withdraw(amount);
            // 2600 COLD_ACCOUNT_ACCESS_COST plus 2300 transfer gas - 1
            // Intended to support transfers to contracts, but not allow for further code execution
            (bool success, ) = to.call{value: amount, gas: 4899}("");
            require(success, "native transfer error");
        } else {
            token.safeTransfer(to, amount);
        }
    }

    function _getBalance(IERC20 token) internal view returns (uint256 balance) {
        balance = token.balanceOf(address(this));
    }
}