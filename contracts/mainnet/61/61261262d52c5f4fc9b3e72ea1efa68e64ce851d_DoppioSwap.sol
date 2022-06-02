/**
 *Submitted for verification at polygonscan.com on 2022-06-02
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;


interface IERC20 {
	function totalSupply() external view returns (uint);
	function balanceOf(address account) external view returns (uint);
	function transfer(address recipient, uint amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint);
	function approve(address spender, uint amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint amount) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
}

interface QuickIV2SwapRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountOut);
}

interface UniIV2SwapRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) external payable returns (uint256 amountOut);
}


contract DoppioSwap {

   event AmmontareRicevuto(uint256 _ammontare);

    // This example swaps DAI/WMATIC for single path swaps and DAI/USDC/WMATIC for multi path swaps.

    address public constant DAI = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063; //DAI sulla Mainnet
    address public constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270; //WMATIC sulla Mainnet

    address public constant QuickROUTER = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    address public constant UniROUTER = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;


    function HoISoldi() external view returns (uint) {
        return IERC20(DAI).balanceOf(address(this));
    }

    function QuickPuoSpendeDAI() external view returns (uint) {
        return IERC20(DAI).allowance(address(this),QuickROUTER);
    }

    function UniPuoSpendereWMATIC() external view returns (uint) {
        return IERC20(WMATIC).allowance(address(this),UniROUTER);
    }


    /// @return amountOut The amount of WMATIC received.
    function swapExactInputSingle(uint256 amountIn) external returns (uint256 amountOut) {

        // Approve the QuickSwap router to spend DAI.
        IERC20(DAI).approve(QuickROUTER,amountIn);

        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        address[] memory path = new address[](2);
        path[0] = DAI;
        path[1] = WMATIC;
        uint deadline = block.timestamp + 300;
        amountOut = QuickIV2SwapRouter(QuickROUTER).swapExactTokensForTokens(amountIn, 0, path, address(this), deadline);

        emit AmmontareRicevuto(amountOut);

        // Approve the Uniswap router to spend WMATIC
        IERC20(WMATIC).approve(UniROUTER,amountOut);

        address[] memory path2 = new address[](2);
        path2[0] = WMATIC;
        path2[1] = DAI;
        amountOut = UniIV2SwapRouter(UniROUTER).swapExactTokensForTokens(amountOut, 0, path2, msg.sender);

    }

    function withdrawMoney(address payable MyAddress) public {
        //devi interagire con lo smart contract del token per mandarti i soldi
        uint My_WETH_Balance = IERC20(WMATIC).balanceOf(address(this));
        IERC20(WMATIC).transfer(MyAddress, My_WETH_Balance);

        uint My_DAI_Balance = IERC20(DAI).balanceOf(address(this));
        IERC20(DAI).transfer(MyAddress, My_DAI_Balance);
    }


}