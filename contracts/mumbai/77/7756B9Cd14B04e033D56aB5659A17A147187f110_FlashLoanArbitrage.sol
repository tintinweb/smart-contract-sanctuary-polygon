//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC20.sol";

import "ISwapRoute.sol";
import "IDODO.sol";

import "DodoBase.sol";
import "Swap.sol";


contract FlashLoanArbitrage is ISwapRoute, DODOFlashLoan {
    uint constant PART_PADDING = 100;

    event SwapOccurred(address indexed fromToken, address indexed toToken, address indexed protocolRouter,
        ProtocolRouterType routerType, uint256 amount);

    event ArbitrageMiddleStage(address indexed tradingToken, uint256 indexed newTokenAmount);

    event FinishedArbitrage(address indexed baseToken, address indexed tradingToken, uint256 initialAmount, uint256 returnedAmount);

    event SentProfit(address indexed token, uint256 indexed profit);

    function flashLoanArbitrage(FlashLoanArbitrageParams memory params) public {
        bytes memory data = abi.encode(msg.sender, params);

        if (IDODO(params.flashLoanPool)._BASE_TOKEN_() == params.loanToken) {
            IDODO(params.flashLoanPool).flashLoan(params.loanAmount, 0, address(this), data);
        } else {
            IDODO(params.flashLoanPool).flashLoan(0, params.loanAmount, address(this), data);
        }
    }

    function _flashLoanCallBack(address, uint256, uint256, bytes calldata data) internal override {
        (address sender, FlashLoanArbitrageParams memory params) = abi.decode(data, (address, FlashLoanArbitrageParams));

        require(msg.sender == params.flashLoanPool, "Failed entering flash loan");

        arbitrage(ArbitrageParams(params.firstRoutes, params.secondRoutes, params.loanToken, params.tradingToken,
            params.loanAmount));
        //Note: Realize your own logic using the token from flashLoan pool.

        require(IERC20(params.loanToken).balanceOf(address(this)) >= params.loanAmount, "Not enough balance to return loan");

        //Return funds
        IERC20(params.loanToken).transfer(params.flashLoanPool, params.loanAmount);

        // send all loanToken to msg.sender
        uint256 remainedAmount = IERC20(params.loanToken).balanceOf(address(this));
        IERC20(params.loanToken).transfer(sender, remainedAmount);
        emit SentProfit(params.loanToken, remainedAmount);
    }

    function arbitrage(ArbitrageParams memory params) public returns (uint256) {
        SwapParams memory firstSwapParams = SwapParams(params.firstRoutes, params.baseToken, params.tradingToken, params.amount);
        uint256 newTokenAmount = swapTokens(firstSwapParams);
        emit ArbitrageMiddleStage(params.tradingToken, newTokenAmount);
        SwapParams memory secondSwapParams = SwapParams(params.secondRoutes, params.tradingToken, params.baseToken, newTokenAmount);
        uint256 returnedAmount = swapTokens(secondSwapParams);
        emit FinishedArbitrage(params.baseToken, params.tradingToken, params.amount, returnedAmount);
        return returnedAmount;
    }

    function swapTokens(SwapParams memory params) public returns (uint256) {
        require(
            IERC20(params.fromToken).balanceOf(address(this)) >= params.amount,
            "Can't swap. Contract doesn't have enough balance!"
        );

        uint256 targetTokenAmount = 0;
        for (uint8 i = 0; i < params.routes.length; i++) {
            targetTokenAmount += runRoute(params.routes[i], params.amount * params.routes[i].part / (100 * PART_PADDING));
        }

        require(
            IERC20(params.toToken).balanceOf(address(this)) >= targetTokenAmount,
            "Contract doesn't have the expected amount of the target token!"
        );

        return targetTokenAmount;
    }

    function runRoute(Route memory route, uint256 amount) internal returns (uint256) {
        for (uint256 i = 0; i < route.swaps.length; i++) {
            TokenSwap memory swap = route.swaps[i];
            uint256 newTokenAmount = 0;
            for (uint256 j = 0; j < swap.protocols.length; j++) {
                newTokenAmount += doSingleSwap(swap.fromTokenAddress, swap.toTokenAddress, swap.protocols[j].routerAddress,
                    swap.protocols[j].routerType, amount * swap.protocols[j].part / (100 * PART_PADDING));
            }
            amount = newTokenAmount;
        }
        return amount;
    }

    function doSingleSwap(
        address fromToken,
        address toToken,
        address protocolRouter,
        ProtocolRouterType routerType,
        uint256 amount
    ) internal returns (uint256) {
//        emit SwapOccurred(fromToken, toToken, protocolRouter, routerType, amount);

        if (routerType == ProtocolRouterType.UNISWAP_V2) {
            return Swap.uniswapV2Swap(fromToken, toToken, protocolRouter, amount);
        } else if (routerType == ProtocolRouterType.UNISWAP_V3) {
            revert("UNISWAP_V3 is not supported at this moment");
        } else if (routerType == ProtocolRouterType.DODO_V2) {
            revert("DODO_V2 is not supported at this moment");
        } else {
            revert("Invalid protocol router type: ");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface ISwapRoute {
    enum ProtocolRouterType{UNISWAP_V2, UNISWAP_V3, DODO_V2}

    struct Protocol {
        uint16 part;
        address routerAddress;
        ProtocolRouterType routerType;
    }

    struct TokenSwap {
        address fromTokenAddress;
        address toTokenAddress;
        Protocol[] protocols;
    }

    struct Route {
        uint16 part;
        TokenSwap[] swaps;
    }

    struct SwapParams {
        Route[] routes;
        address fromToken;
        address toToken;
        uint256 amount;
    }

    struct ArbitrageParams {
        Route[] firstRoutes;
        Route[] secondRoutes;
        address baseToken;
        address tradingToken;
        uint256 amount;
    }

    struct FlashLoanArbitrageParams {
        Route[] firstRoutes;
        Route[] secondRoutes;
        address loanToken;
        address tradingToken;
        address flashLoanPool;
        uint256 loanAmount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDODO {
    function flashLoan(
        uint256 baseAmount,
        uint256 quoteAmount,
        address assetTo,
        bytes calldata data
    ) external;

    function _BASE_TOKEN_() external view returns (address);
    function _BASE_RESERVE_() external view returns (uint112);
    function _QUOTE_TOKEN_() external view returns (address);
    function _QUOTE_RESERVE_() external view returns (uint112);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract DODOFlashLoan {
    //Note: CallBack function executed by DODOV2(DVM) flashLoan pool
    function DVMFlashLoanCall(
        address sender,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata data
    ) external {
        _flashLoanCallBack(sender, baseAmount, quoteAmount, data);
    }

    //Note: CallBack function executed by DODOV2(DPP) flashLoan pool
    function DPPFlashLoanCall(
        address sender,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata data
    ) external {
        _flashLoanCallBack(sender, baseAmount, quoteAmount, data);
    }

    //Note: CallBack function executed by DODOV2(DSP) flashLoan pool
    function DSPFlashLoanCall(
        address sender,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata data
    ) external {
        _flashLoanCallBack(sender, baseAmount, quoteAmount, data);
    }

    function _flashLoanCallBack(
        address,
        uint256,
        uint256,
        bytes calldata data
    ) internal virtual {}

//    modifier validatePool(FlashParams memory params) {
//        address loanToken = RouteUtils.getInitialToken(params.firstRoutes[0]);
//        bool loanEqBase = loanToken == IDODO(params.flashLoanPool)._BASE_TOKEN_();
//        bool loanEqQuote = loanToken == IDODO(params.flashLoanPool)._QUOTE_TOKEN_();
//        require(loanEqBase || loanEqQuote, "Wrong flashloan pool address");
//		_;
//	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "SafeERC20.sol";
import "Strings.sol";

import "IUniswapV2Router.sol";

library Swap {
    using SafeERC20 for IERC20;

    function uniswapV2Swap(
        address fromToken,
        address toToken,
        address protocolRouter,
        uint256 amount
    ) internal returns (uint256) {
        address[] memory path;
        path = new address[](2);
        path[0] = fromToken;
        path[1] = toToken;

        require(
            IERC20(fromToken).balanceOf(address(this)) >= amount,
            "No balance"
        );
//        revert(Strings.toString(amount));
        require(
            IERC20(fromToken).approve(protocolRouter, amount),
            "Failed to approve!"
        );

        try IUniswapV2Router(protocolRouter).swapExactTokensForTokens(
            amount,
            uint(0),
            path,
            address(this),
            block.timestamp
        ) returns (uint256[] memory newAmounts) {
            return newAmounts[1];
        } catch Error(string memory reason) {
            revert(string(abi.encodePacked("uniswapV2Swap failed! ", reason)));
        } catch (bytes memory lowLevelData) {
            revert(string(abi.encodePacked("uniswapV2Swap low level failure! ", lowLevelData)));
        }
        revert("uniswapV2Swap failed for some weird reason");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Address.sol";

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

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}