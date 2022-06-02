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


interface IV2SwapRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountOut);
}

contract SwapSuQuickswap {

   event AmmontareRicevuto(uint256 _ammontare);


    // For the scope of these swap examples,
    // we will detail the design considerations when using
    // `exactInput`, `exactInputSingle`, `exactOutput`, and  `exactOutputSingle`.

    // It should be noted that for the sake of these examples, we purposefully pass in the swap router instead of inherit the swap router for simplicity.
    // More advanced example contracts will detail how to inherit the swap router safely.

    //ISwapRouter public immutable swapRouter;

    // This example swaps DAI/WMATIC for single path swaps and DAI/USDC/WMATIC for multi path swaps.

    address public constant DAI = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063; //DAI sulla Mainnet
    address public constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270; //WMATIC sulla Mainnet

    address public constant ROUTER = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;

    //Il router (cioe' la coppia di scambio) dovrebbe essere questa: ROUTER
    //constructor(ISwapRouter _swapRouter) {
    //    swapRouter = _swapRouter;
    //}

    function HoISoldi() external view returns (uint) {
        return IERC20(DAI).balanceOf(address(this));
    }

    function ChiPuoSpendermeli() external view returns (uint) {
        return IERC20(DAI).allowance(address(this),ROUTER);
    }

    /// @notice swapExactInputSingle swaps a fixed amount of DAI for a maximum possible amount of WMATIC
    /// using the DAI/WMATIC 0.3% pool by calling `exactInputSingle` in the swap router.
    /// @dev The calling address must approve this contract to spend at least `amountIn` worth of its DAI for this function to succeed.
    /// @param amountIn The exact amount of DAI that will be swapped for WMATIC.
    /// @return amountOut The amount of WMATIC received.
    function swapExactInputSingle(uint256 amountIn) external returns (uint256 amountOut) {
        // msg.sender must approve this contract
        //Approva fisicamente il contratto da Uniswap

        // Transfer the specified amount of DAI to this contract.
        //TransferHelper.safeTransferFrom(DAII, msg.sender, address(this), amountIn);

        // Approve the router to spend DAI.
        //TransferHelper.safeApprove(DAI, address(swapRouter), amountIn);
        IERC20(DAI).approve(ROUTER,amountIn);

        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        address[] memory path = new address[](2);
        path[0] = DAI;
        path[1] = WMATIC;
        amountOut = IV2SwapRouter(ROUTER).swapExactTokensForTokens(amountIn, 0, path, msg.sender, 115792089237316195423570985008687907853269984665640564039457584007913129639935);

        emit AmmontareRicevuto(amountOut);

        // if (amountOut < 29748933820802605)
        // revert ("Ammontare inferiore di quanto voglio");
        // The call to `exactInputSingle` executes the swap.
        //amountOut = swapRouter.exactInputSingle(params);
    }

    function withdrawMoney(address payable MyAddress) public {
        //devi interagire con lo smart contract del token per mandarti i soldi
        uint My_WETH_Balance = IERC20(WMATIC).balanceOf(address(this));
        IERC20(WMATIC).transfer(MyAddress, My_WETH_Balance);

        uint My_DAI_Balance = IERC20(DAI).balanceOf(address(this));
        IERC20(DAI).transfer(MyAddress, My_DAI_Balance);
    }


}