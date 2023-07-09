// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./ISwapRouter.sol";
import "./TransferHelper.sol";

interface IUniswapRouter is ISwapRouter {
    function refundETH() external payable;
}

contract SUSISWAP {
    IUniswapRouter public constant swapRouter =
        IUniswapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    address private WETH9 = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;
    address private feeRecipient = 0x18F8f7045618C15c4773B98B8997e94b2A8a4865;
    uint256 private constant FEE_PERCENT = 1;

    function swapExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint256 amountOutMinimum
    ) external payable {
        // Calculate the fee amount
        uint256 feeAmount = (amountIn * FEE_PERCENT) / 100000;

        // Wrap Ether in WETH9 if necessary
        if (tokenIn == address(0)) {
            require(msg.value == amountIn, "Incorrect Ether value");
            IWETH(WETH9).deposit{value: msg.value - feeAmount}();
            tokenIn = WETH9;
        } else {
            TransferHelper.safeTransferFrom(
                tokenIn,
                msg.sender,
                address(this),
                amountIn
            );
            TransferHelper.safeApprove(tokenIn, address(swapRouter), amountIn);
        }

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut == address(0) ? WETH9 : tokenOut,
                fee: fee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn - feeAmount,
                amountOutMinimum: amountOutMinimum,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        uint256 amountOut = swapRouter.exactInputSingle(params);

        // Send the fee to the fee recipient
        payable(feeRecipient).transfer(feeAmount);

        // Unwrap WETH9 to Ether if necessary
        if (tokenOut == address(0)) {
            IWETH(WETH9).withdraw(amountOut);
            TransferHelper.safeTransferETH(msg.sender, amountOut);
            (bool success, ) = msg.sender.call{value: address(this).balance}(
                ""
            );
            require(success, "refund failed");
        } else {
            TransferHelper.safeTransfer(tokenOut, msg.sender, amountOut);
            refundToken(tokenIn);
        }
    }

    function refundToken(address token) public {
        uint256 tokenBalance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(msg.sender, tokenBalance);
    }

    receive() external payable {}
}