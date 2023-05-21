/**
 *Submitted for verification at polygonscan.com on 2023-05-20
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IV3SwapRouter  {
     struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

}

interface INonfungiblePositionManager
{
    function positions(uint256 tokenId)
    external
    view
    returns (
        uint96 nonce,
        address operator,
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        uint256 feeGrowthInside0LastX128,
        uint256 feeGrowthInside1LastX128,
        uint128 tokensOwed0,
        uint128 tokensOwed1
    );
    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    function increaseLiquidity(IncreaseLiquidityParams calldata params)
    external
    payable
    returns (
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );
    function refundETH() external payable;
}

contract UniswapV3Example {
    IV3SwapRouter router =
        IV3SwapRouter(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
    INonfungiblePositionManager positionManager =
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    uint24 constant defaultv3Fee = 3000;
    address tokenAddress = 0x1057b31A307EcE832f7d5718Fa128DD9Da784f60;
    address maticAddress = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;
    uint256 public v3positionId = 28126;
    uint lpMaticAmount = 0;
    uint256 lpMaticLimit = 500000e18;

    constructor() {
        safeApprove(tokenAddress, address(router), type(uint).max);
        safeApprove(tokenAddress, address(positionManager), type(uint).max);
    }

    function addLiquitidyWithId (
        uint256 maticAmount,
        uint256 tokenAmount
    ) public { //internal
        positionManager.increaseLiquidity{value: maticAmount}(
            INonfungiblePositionManager.IncreaseLiquidityParams({
                tokenId: v3positionId,
                amount0Desired: maticAmount,
                amount1Desired: tokenAmount,
                amount0Min: 0,
                amount1Min: maticAmount,
                deadline: block.timestamp + 360
            })
        );
        positionManager.refundETH();
    }

    function buyBurn(
        uint256 amountIn
    ) public {
        uint ethvalue = amountIn;
        router.exactInputSingle{value: ethvalue}(
            IV3SwapRouter.ExactInputSingleParams({
                tokenIn: maticAddress,
                tokenOut: tokenAddress,
                fee: defaultv3Fee,
                recipient: address(this),
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
        );
        
    }

    function safeApprove(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SA"
        );
    }

    function withdrawEth(address to, uint256 value) external {
        payable(to).transfer(value);
    }

    receive() external payable {}
    
}