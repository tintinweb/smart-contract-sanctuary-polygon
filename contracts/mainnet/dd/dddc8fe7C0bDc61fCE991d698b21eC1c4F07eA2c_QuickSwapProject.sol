/**
 *Submitted for verification at polygonscan.com on 2022-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import "https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol";

interface IUniswapV2Router02 {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}
    

interface IERC20 {
    function transferFrom(address from, address to, uint value) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
}

contract QuickSwapProject {
    address private constant MATIC = 0x0000000000000000000000000000000000001010;
    address private constant QUICKSWAP_V2_ROUTER = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    address private constant DAI = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    
    function simpleSwap (address receiverAddress)
    external {

        address tokenIn = MATIC;
        address tokenOut = DAI;
        uint amountIn = 10000000000000000;
        uint amountOutMin = 1;

        // We need that the smart contract that has the tokens, approve(allow) Uniswap to spend its tokens, and how much do we approve.
        IERC20(tokenIn).approve(QUICKSWAP_V2_ROUTER, amountIn);
        // We send the tokens from the wallet address (msg.sender) to the smart contract SwapProject
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);


        address[] memory path;
        path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;


        IUniswapV2Router02(QUICKSWAP_V2_ROUTER).swapExactTokensForTokens(amountIn, amountOutMin, path, receiverAddress, block.timestamp);

    }

    function swap (
        address tokenIn,
        address tokenOut,
        uint amountIn,
        uint amountOutMin,
        address receiverAddress
        //uint256 deadline
    )
    external {
        // We send the tokens from the wallet address (msg.sender) to the smart contract SwapProject
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        // We need that the smart contract that has the tokens, approve(allow) Uniswap to spend its tokens, and how much do we approve.
        IERC20(tokenIn).approve(QUICKSWAP_V2_ROUTER, amountIn);

        tokenOut= DAI;

        address[] memory path; 
        path = new address[](2);
        path[0] = tokenIn;
        path[1] = DAI;


        IUniswapV2Router02(QUICKSWAP_V2_ROUTER).swapExactTokensForTokens(amountIn, amountOutMin, path, receiverAddress, block.timestamp);

    }

        //this function will return the minimum amount from a swap
       //input the 3 parameters below and it will return the minimum amount out
       //this is needed for the swap function above

    function getAmountOutMin(address tokenIn, address tokenOut, uint amountIn) external view returns (uint) {

       
       //path is an array of addresses.
       //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
       //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
        address[] memory path;
        path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        
        uint[] memory amountOutMins = IUniswapV2Router02(QUICKSWAP_V2_ROUTER).getAmountsOut(amountIn, path);
        return amountOutMins[path.length -1];
    }
}