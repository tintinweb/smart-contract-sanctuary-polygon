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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {IHopscotch} from "./IHopscotch.sol";
import {IWrappedNativeToken} from "./IWrappedNativeToken.sol";

contract Hopscotch is IHopscotch {
    using SafeERC20 for IERC20;

    ////
    // Types
    ////

    struct Request {
        address payable recipient;
        address recipientToken;
        uint256 recipientTokenAmount;
        bool paid;
    }

    ////
    // Storage
    ////

    address public immutable wrappedNativeToken;
    Request[] requests;

    ////
    // Special
    ////

    /// @param _wrappedNativeToken wrapped native token address for the chain
    constructor(address _wrappedNativeToken) {
        wrappedNativeToken = _wrappedNativeToken;
    }

    fallback() external payable {}
    receive() external payable {}

    ////
    // Public functions
    ////

    function createRequest(address recipientToken, uint256 recipientTokenAmount) external returns (uint256 id) {
        require(recipientTokenAmount > 0, "createRequest/recipientTokenAmountZero");

        id = requests.length;
        requests.push(Request(payable(msg.sender), recipientToken, recipientTokenAmount, false));
        emit RequestCreated(id, msg.sender, recipientToken, recipientTokenAmount);
    }

    function payRequest(PayRequestInputParams calldata params)
        external
        payable
        returns (
            uint256 refundedNativeTokenAmount,
            uint256 refundedErc20InputTokenAmount,
            uint256 refundedErc20OutputTokenAmount
        )
    {
        Request storage request = requests[params.requestId];

        require(!request.paid, "payRequest/alreadyPaid");
        require(params.inputTokenAmount > 0, "payRequest/inputTokenAmountZero");

        request.paid = true;

        bool inputIsNative = (params.inputToken == address(0));
        bool outputIsNative = (request.recipientToken == address(0));

        if (inputIsNative) {
            require(
                address(this).balance >= params.inputTokenAmount, "payRequest/nativeTokenAmountLessThanInputTokenAmount"
            );

            if (!outputIsNative) {
                // Wrap native token
                IWrappedNativeToken(wrappedNativeToken).deposit{value: params.inputTokenAmount}();
            }
        } else {
            // Transfer tokens in
            IERC20(params.inputToken).safeTransferFrom(msg.sender, address(this), params.inputTokenAmount);
        }

        address erc20InputToken = inputIsNative ? wrappedNativeToken : params.inputToken;
        address erc20OutputToken = outputIsNative ? wrappedNativeToken : request.recipientToken;

        // Stright transfer if not overridden by swap below
        uint256 inputTokenAmountPaid = request.recipientTokenAmount;

        if (erc20InputToken != erc20OutputToken) {
            (inputTokenAmountPaid,) = performSwap(
                erc20InputToken,
                erc20OutputToken,
                params.inputTokenAmount,
                request.recipientTokenAmount,
                params.swapContractAddress,
                params.swapContractCallData
            );
        }

        if (outputIsNative) {
            if (!inputIsNative) {
                // Unwrap
                IWrappedNativeToken(wrappedNativeToken).withdraw(
                    IWrappedNativeToken(wrappedNativeToken).balanceOf(address(this))
                );
            }

            // Direct send
            require(address(this).balance >= request.recipientTokenAmount, "payRequest/notEnoughNativeTokens");
            (bool success,) = request.recipient.call{value: request.recipientTokenAmount}("");
            require(success, "payRequest/nativeTokenSendFailure");
        } else {
            // Direct transfer
            require(
                IERC20(request.recipientToken).balanceOf(address(this)) >= request.recipientTokenAmount,
                "payErc20RequestDirect/insufficientFunds"
            );
            IERC20(request.recipientToken).safeTransfer(request.recipient, request.recipientTokenAmount);
        }

        // Refund extra request
        uint256 nativeTokenBalance = address(this).balance;
        if (nativeTokenBalance > 0) {
            (bool success,) = payable(msg.sender).call{value: nativeTokenBalance}("");
            require(success, "payRequest/refundNative");
        }

        uint256 erc20InputTokenBalance = IERC20(erc20InputToken).balanceOf(address(this));
        if (erc20InputTokenBalance > 0) {
            IERC20(erc20InputToken).safeTransfer(msg.sender, erc20InputTokenBalance);
        }

        uint256 erc20OutputTokenBalance = IERC20(erc20OutputToken).balanceOf(address(this));
        if (erc20OutputTokenBalance > 0) {
            IERC20(request.recipientToken).safeTransfer(msg.sender, erc20OutputTokenBalance);
        }

        emit RequestPaid(params.requestId, msg.sender, params.inputToken, inputTokenAmountPaid);
        return (nativeTokenBalance, erc20InputTokenBalance, erc20OutputTokenBalance);
    }

    function getRequest(uint256 requestId)
        external
        view
        returns (address recipient, address recipientToken, uint256 recipientTokenAmount, bool paid)
    {
        Request storage request = requests[requestId];
        return (request.recipient, request.recipientToken, request.recipientTokenAmount, request.paid);
    }

    ////
    // Private functions
    ////

    /// @notice Perform a swap from inputToken to outputToken using the swapContractAddress with swapContractCallData
    /// @param inputToken input token to swap
    /// @param outputToken output token to swap to
    /// @param inputTokenAmountAllowance allowance of inputTokens given to swapContractAddress to perform the swap
    /// @param minimumOutputTokenAmountReceived minumum output token amount recieved from the swap
    /// @param swapContractAddress address of the contract that will perform the swap
    ///                            if no swap is needed due to input and recipient tokens being the same this will not be called
    /// @param swapContractCallData call data to pass into the swap contract that will perform the swap
    /// @dev The call will revert if
    ///         * inputToken balance of this contract is not at least inputTokenAmountAllowance
    ///         * outputToken balance of this contract is not increaced by at least minimumOutputTokenAmountReceived after the swap
    ///         * swapContract call reverts
    /// @return inputTokenAmountPaid amount of input tokens paid for the swap
    /// @return outputTokenAmountReceived amount of output tokens recieved from the swap
    function performSwap(
        address inputToken,
        address outputToken,
        uint256 inputTokenAmountAllowance,
        uint256 minimumOutputTokenAmountReceived,
        address swapContractAddress,
        bytes calldata swapContractCallData
    ) internal returns (uint256 inputTokenAmountPaid, uint256 outputTokenAmountReceived) {
        // Grab balances before swap to compare with after
        uint256 inputTokenBalanceBeforeSwap = IERC20(inputToken).balanceOf(address(this));
        uint256 outputTokenBalanceBeforeSwap = IERC20(outputToken).balanceOf(address(this));

        // Make sure this contract holds enough input tokens
        require(inputTokenBalanceBeforeSwap >= inputTokenAmountAllowance, "performSwap/notEnoughInputTokens");

        // Allow swap contract to spend this amount of swap input tokens
        IERC20(inputToken).approve(swapContractAddress, inputTokenAmountAllowance);

        // Execute swap
        (bool swapSuccess, bytes memory result) = swapContractAddress.call(swapContractCallData);

        // Revert with the reason returned by the call
        if (!swapSuccess) {
            // Next 5 lines from https://ethereum.stackexchange.com/a/83577
            if (result.length < 68) revert();
            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }

        // Check output balance increaced by at least request amount
        inputTokenAmountPaid = inputTokenBalanceBeforeSwap - IERC20(inputToken).balanceOf(address(this));
        outputTokenAmountReceived = IERC20(outputToken).balanceOf(address(this)) - outputTokenBalanceBeforeSwap;

        require(
            outputTokenAmountReceived >= minimumOutputTokenAmountReceived, "performSwap/notEnoughOutputTokensFromSwap"
        );

        // Revoke input token approval
        IERC20(inputToken).approve(swapContractAddress, 0);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {IWrappedNativeToken} from "./IWrappedNativeToken.sol";

interface IHopscotch {
    ////
    // Types
    ////

    /// @param requestId id of the request to be paid
    /// @param inputToken input token the request is being paid with, use zero address for native token
    /// @param inputTokenAmount amount of input token to pay the request, this should be the quoted amount for the swap data
    /// @param swapContractAddress address of the contract that will perform the swap
    ///                            if no swap is needed due to input and recipient tokens being the same this will not be called
    /// @param swapContractCallData call data to pass into the swap contract that will perform the swap
    struct PayRequestInputParams {
        uint256 requestId;
        address inputToken;
        uint256 inputTokenAmount;
        address swapContractAddress;
        bytes swapContractCallData;
    }

    ////
    // Events
    ////

    /// @notice Emitted when a request is created
    /// @param requestId id of the created request
    /// @param recipient recipient of the request
    /// @param recipientToken requested token, zero if it is the native asset
    /// @param recipientTokenAmount requested token amount
    event RequestCreated(
        uint256 indexed requestId,
        address indexed recipient,
        address indexed recipientToken,
        uint256 recipientTokenAmount
    );

    /// @notice Emitted when a request is paid
    /// @param requestId id of the paid request
    /// @param sender sender of the request
    /// @param senderToken sender token, zero address if it was the native asset
    /// @param senderTokenAmount sender token amount used to pay the request
    event RequestPaid(
        uint256 indexed requestId, address indexed sender, address senderToken, uint256 senderTokenAmount
    );

    ////
    // Public function declarations
    ////

    /// @notice Create a request for a given token and token amount to be paid to msg.sender
    /// @param recipientToken token being requested, use zero address for native token
    /// @param recipientTokenAmount the amount of the request token being requested
    /// @dev The call will revert if:
    ///         * recipient token amount is 0
    ///       emits RequestCreated
    /// @return id request id that was created
    function createRequest(address recipientToken, uint256 recipientTokenAmount) external returns (uint256 id);

    /// @notice Pay the request at requestId using the swapContractAddress
    /// @param params params
    /// @dev The call will revert if:
    ///         * request for requestId does not exist
    ///         * request has already been paid
    ///         * inputTokenAmount is 0
    ///         * input token approval for this contract from msg.sender is less than inputTokenAmount
    ///         * insufficient input token balance
    ///         * swapContractAddress called with swapContractCallData did not output at least the requests recipientTokenAmount of recipientToken
    ///      Excess input or output tokens will be returned to msg.sender
    ///      This will automatically wrap ETH asset if the inputTokenAddress is WETH9 and at least the inputTokenAmount of ETH was sent in
    ///      emits RequestPaid
    /// @return refundedNativeTokenAmount amount of native token refunded to msg.sender
    /// @return refundedErc20InputTokenAmount amount of input token refunded to msg.sender
    /// @return refundedErc20OutputTokenAmount amount of output token refunded to msg.sender
    function payRequest(PayRequestInputParams calldata params)
        external
        payable
        returns (
            uint256 refundedNativeTokenAmount,
            uint256 refundedErc20InputTokenAmount,
            uint256 refundedErc20OutputTokenAmount
        );

    /// @notice Get the request for the id
    /// @param requestId request id
    function getRequest(uint256 requestId)
        external
        view
        returns (address recipient, address recipientToken, uint256 recipientTokenAmount, bool paid);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

interface IWrappedNativeToken is IERC20 {
    /// @notice Deposit native asset to get wrapped native token
    function deposit() external payable;

    /// @notice Withdraw wrapped native asset to get native asset
    function withdraw(uint256 amount) external;
}