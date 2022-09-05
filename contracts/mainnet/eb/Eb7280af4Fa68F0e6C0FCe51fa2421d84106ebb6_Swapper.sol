// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.7;

// import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
// import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';

// interface IwERC20 {
//     function deposit() external payable;
//     function balanceOf(address _owner) external view returns(uint256);
// }

// on polygon matic mainnet
contract Swapper {

    // ISwapRouter public constant swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    // address public constant wMATIC_Token = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    // address public constant LINK_Token = 0xb0897686c545045aFc77CF20eC7A532E3120E0F1;

    // // For this example, we will set the pool fee to 0.3%.
    // uint24 public constant poolFee = 3000;


    // function swap_MATIC_LINK(uint256 amountIn) public {
    //     IwERC20 wMATIC = IwERC20(wMATIC_Token);
    //     wMATIC.deposit{value: amountIn - wMATIC.balanceOf(address(this))}();

    //     TransferHelper.safeApprove(wMATIC_Token, address(swapRouter), amountIn);

    //     ISwapRouter.ExactInputSingleParams memory params =
    //         ISwapRouter.ExactInputSingleParams({
    //             tokenIn: wMATIC_Token,
    //             tokenOut: LINK_Token,
    //             fee: poolFee,
    //             recipient: address(this),
    //             deadline: block.timestamp,
    //             amountIn: amountIn,
    //             amountOutMinimum: 0,
    //             sqrtPriceLimitX96: 0
    //         });

    //     swapRouter.exactInputSingle(params);
    // }

    // function swap_MATIC_LINK(uint256 amountOut, uint256 amountInMaximum) public {
    //     IwERC20 wMATIC = IwERC20(wMATIC_Token);
    //     wMATIC.deposit{value: amountInMaximum - wMATIC.balanceOf(address(this))}();

    //     TransferHelper.safeApprove(wMATIC_Token, address(swapRouter), amountInMaximum);

    //     ISwapRouter.ExactOutputSingleParams memory params =
    //         ISwapRouter.ExactOutputSingleParams({
    //             tokenIn: wMATIC_Token,
    //             tokenOut: LINK_Token,
    //             fee: poolFee,
    //             recipient: msg.sender,
    //             deadline: block.timestamp,
    //             amountOut: amountOut,
    //             amountInMaximum: amountInMaximum,
    //             sqrtPriceLimitX96: 0
    //         });

    //     uint256 amountIn = swapRouter.exactOutputSingle(params);

    //     if (amountIn < amountInMaximum) {
    //         TransferHelper.safeApprove(wMATIC_Token, address(swapRouter), 0);
    //     }
    // }

    // function linkBalance() public view returns(uint256) {
    //     return IERC20(LINK_Token).balanceOf(address(this));
    // }

    function maticBalance() public view returns(uint256) {
        return address(this).balance;
    }

    // function withdrawLink() public {
    //     IERC20(LINK_Token).transfer(msg.sender, linkBalance());
    // }

    function withdrawMatic() public {
        payable(msg.sender).transfer(maticBalance());
    }

    function charge() public payable{}
    receive() external payable{}
}