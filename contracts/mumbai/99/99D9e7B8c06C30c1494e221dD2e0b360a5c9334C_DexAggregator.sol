// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IUniswapV2Router {
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
}

// This contract uses the UniswapV2Router contract interface to get the prices of DAI and WETH on Uniswap.
//  It then compares the prices of DAI to WETH and WETH to DAI to determine the best price.
//   Note that this is just a basic example and that a real-world Dex aggregator would likely need to
//    be more complex and handle multiple tokens and exchanges.


contract DexAggregator {
    address private constant uniswapV2RouterAddress = 0xb71c52BA5E0690A7cE3A0214391F4c03F5cbFB0d;
    address private constant daiAddress = 0x5A01Ea01Ba9A8DC2B066714A65E61a78838B1b9e;
    address private constant wethAddress = 0xA6FA4fB5f76172d178d61B04b0ecd319C5d1C0aa;

    function getBestPrice() public view returns (uint) {
        uint daiToWeth = _getDaiToWethPrice();
        uint wethToDai = _getWethToDaiPrice();
        return daiToWeth < wethToDai ? daiToWeth : wethToDai;
    }

    function _getDaiToWethPrice() public view returns (uint) {
        address[] memory path = new address[](2);
        path[0] = daiAddress;
        path[1] = wethAddress;
        uint[] memory amounts = IUniswapV2Router(uniswapV2RouterAddress).getAmountsOut(1e18, path);
        return amounts[1];
    }

    function _getWethToDaiPrice() public view returns (uint) {
        address[] memory path = new address[](2);
        path[0] = wethAddress;
        path[1] = daiAddress;
        uint[] memory amounts = IUniswapV2Router(uniswapV2RouterAddress).getAmountsOut(1e18, path);
        return amounts[1];
    }
}