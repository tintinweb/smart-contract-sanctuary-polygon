/**
 *Submitted for verification at polygonscan.com on 2023-04-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}

interface IUniswapV2Router02 {

    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);

    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);

}

contract ArbitrageBot {

    address public constant MATIC = 0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0;

    address public constant USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;

    address public constant QUICKSWAP_ROUTER = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;

    address public constant SUSHISWAP_ROUTER = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;

    uint public constant AMOUNT_IN = 1 ether;

    uint public  DEADLINE = block.timestamp + 300;

    function startArbitrage() external {

        IERC20(MATIC).approve(QUICKSWAP_ROUTER, AMOUNT_IN);

        address[] memory path = new address[](2);

        path[0] = MATIC;

        path[1] = USDT;

        uint[] memory amounts = IUniswapV2Router02(QUICKSWAP_ROUTER).getAmountsOut(AMOUNT_IN, path);

        uint amountOut = amounts[1];

        IUniswapV2Router02(QUICKSWAP_ROUTER).swapExactTokensForTokens(AMOUNT_IN, amountOut, path, address(this), DEADLINE);

        IERC20(USDT).approve(SUSHISWAP_ROUTER, amountOut);

        path[0] = USDT;

        path[1] = MATIC;

        IUniswapV2Router02(SUSHISWAP_ROUTER).swapExactTokensForTokens(amountOut, 0, path, address(this), DEADLINE);

        uint profit = IERC20(MATIC).balanceOf(address(this));

        require(profit > 0, "Arbitrage failed");

        IERC20(MATIC).transfer(msg.sender, profit);

    }

}