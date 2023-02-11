//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

import "./IERC20.sol";
import "./IUniswap.sol";

contract SwapV2 {
    //address private constant UNISWAP_V2_ROUTER_ETHEREUM = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant UNISWAP_V2_ROUTER_POLYGON = 0x4237a813604bD6815430d55141EA2C24D4543e44;

    //address constant WETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
    address constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
 
    function swap(address _tokenIn, address _tokenOut, uint _amountIn, uint _amountOutMin) external returns (uint[] memory amounts) {
        IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn); //transferring tokens from sender to contract
        IERC20(_tokenIn).approve(UNISWAP_V2_ROUTER_POLYGON, _amountIn); //this contract needs to allow uniswap V2 router to spend token

        address[] memory path;
        path = new address[](3);
        path[0] = _tokenIn; 
        path[1] = WMATIC; 
        path[2] = _tokenOut; 

        uint[] memory respAmounts = IUniswapV2Router(UNISWAP_V2_ROUTER_POLYGON).swapExactTokensForTokens(_amountIn, _amountOutMin, path, msg.sender, block.timestamp);
        return respAmounts;
    }
}