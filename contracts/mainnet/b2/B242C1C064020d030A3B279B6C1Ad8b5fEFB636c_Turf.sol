/**
 *Submitted for verification at polygonscan.com on 2022-09-26
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.7;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address account, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
}

interface IBentoBox {
    function deposit(
        address token,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external payable returns (uint256 amountOut, uint256 shareOut);

    function withdraw(
        address token,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

interface IPool {
    function getAmountOut(bytes calldata data) external view returns (uint256 finalAmountOut);
}

address constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
address constant ATRF = 0x6943DC226AA8737BAd630A18eD9EA6E7c4Ea8487;
address constant QUICKSWAP = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
address constant WMATIC_ATRF_PAIR = 0x11bAb3b9fbE21feA46A2f10D33FE88042b88eB96;
address constant BENTOBOX = 0x0319000133d3AdA02600f0875d2cf03D442C3367;
address constant WMATIC_ATRF_POOL = 0xf4B0Fe8E9fd3f236FEEEeAB16dAd3f851824F84a;

contract Turf {
    address private immutable owner;

    constructor() {
        owner = msg.sender;
    }

    function quickBento(
        uint maticIn
    ) external {
        require(tx.origin == owner, ";)");
        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(WMATIC_ATRF_PAIR).getReserves();
        uint atrfOut = IRouter(QUICKSWAP).getAmountOut(maticIn, reserve0, reserve1);
        IERC20(WMATIC).transferFrom(msg.sender, WMATIC_ATRF_PAIR, maticIn);
        IUniswapV2Pair(WMATIC_ATRF_PAIR).swap(0, atrfOut, address(this), new bytes(0));
        IERC20(ATRF).approve(BENTOBOX, atrfOut);
        uint maticOut = IPool(WMATIC_ATRF_POOL).getAmountOut(abi.encode(ATRF, atrfOut));
        IBentoBox(BENTOBOX).deposit(ATRF, address(this), WMATIC_ATRF_POOL, atrfOut, 0);
        IBentoBox(BENTOBOX).withdraw(WMATIC, WMATIC_ATRF_POOL, msg.sender, maticOut, 0);
        require(maticOut > maticIn);
    }

    function bentoQuick(
        uint amountIn
    ) external {
        require(tx.origin == owner, ";)");
        IERC20(WMATIC).transferFrom(msg.sender, address(this), amountIn);
        IERC20(ATRF).approve(BENTOBOX, amountIn);
        uint amountOut = IPool(WMATIC_ATRF_POOL).getAmountOut(abi.encode(WMATIC, amountIn));
        IBentoBox(BENTOBOX).deposit(WMATIC, address(this), WMATIC_ATRF_POOL, amountIn, 0);
        IBentoBox(BENTOBOX).withdraw(ATRF, WMATIC_ATRF_POOL, address(this), amountOut, 0);
        address[] memory path = new address[](2);
        path[0] = ATRF;
        path[1] = WMATIC;
        IERC20(ATRF).approve(QUICKSWAP, amountOut);
        IRouter(QUICKSWAP)
            .swapExactTokensForTokens(amountOut, amountIn, path, msg.sender, block.timestamp);
    }
}