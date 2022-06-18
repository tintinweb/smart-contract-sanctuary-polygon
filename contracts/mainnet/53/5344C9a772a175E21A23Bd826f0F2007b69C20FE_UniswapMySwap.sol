// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;
pragma abicoder v2;

import './ISwapRouter.sol';
import './TransferHelper.sol';

//swapRouter address in ropsten 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45 from https://docs.uniswap.org/protocol/reference/deployments
//deployed contract 0x5344C9a772a175E21A23Bd826f0F2007b69C20FE

contract UniswapMySwap{
    ISwapRouter public immutable swapRouter;

    address public constant DAI = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    address public constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

    // For this example, we will set the pool fee to 0.3%.
    uint24 public constant poolFee = 3000;

    event Swapped(address _in, uint amountIn, address out, uint amountOut);

    constructor(ISwapRouter _swapRouter) {
        swapRouter = _swapRouter;
    }

     function swapExactInputSingle(uint256 amountIn) external returns (uint256 amountOut) {
        // msg.sender must approve this contract

        // Transfer the specified amount of DAI to this contract.
        TransferHelper.safeTransferFrom(DAI, msg.sender, address(this), amountIn);

        // Approve the router to spend DAI.
        TransferHelper.safeApprove(DAI, address(swapRouter), amountIn);

        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: DAI,
                tokenOut: USDC,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        amountOut = swapRouter.exactInputSingle(params);
        emit Swapped(DAI, amountIn, USDC, amountOut);
    }

}