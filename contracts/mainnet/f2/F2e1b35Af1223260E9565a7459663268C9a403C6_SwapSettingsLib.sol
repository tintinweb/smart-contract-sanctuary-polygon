// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

library SwapSettingsLib {
    function netWorkSettings(
    )
        external
        view
        returns(address, address, uint256 k1, uint256 k2, uint256 k3, uint256 k4)
    {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        if ((chainId == 0x1) || (chainId == 0x3) || (chainId == 0x4) || (chainId == 0x539) || (chainId == 0x7a69)) {  //+ localganache chainId, used for fork 
            // Ethereum-Uniswap
            (k1,k2,k3,k4) = _koefficients(1000, 3); // fee = 0.3%
            return( 
                0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, //uniswapRouter
                0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f, //uniswapRouterFactory
                //3988000,3988009,1997,1994
                k1,k2,k3,k4
            );
            //_koefficients(1000, 3);
        } else if((chainId == 0x89)) {
            // Matic-QuickSwap
            (k1,k2,k3,k4) = _koefficients(1000, 3); // fee = 0.3%
            return( 
                0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff, //uniswapRouter
                0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32, //uniswapRouterFactory
                //3988000,3988009,1997,1994
                k1,k2,k3,k4
            );
        } else if((chainId == 0x38)) {
            // Binance-PancakeSwap
            (k1,k2,k3,k4) = _koefficients(10000, 25); // fee = 0.25%
            return( 
                0x10ED43C718714eb63d5aA57B78B54704E256024E, //uniswapRouter
                0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73, //uniswapRouterFactory
                //399000000,399000625,19975,19950
                k1,k2,k3,k4
            );
            //_koefficients(10000, 25);
        } else {
            revert("unsupported chain");
        }
    }
    /**
    * @dev calculation koefficients for formula in https://blog.alphaventuredao.io/onesideduniswap/
    */
    function _koefficients(uint256 d, uint256 f) private pure returns(uint256, uint256, uint256, uint256) {
            // uint256 f = 3000;//0,003 mul denominator
            // uint256 k1=4*(1*d-f)*d; //4*(1-f)^2 = 3988000
            // uint256 k2=(2*d-f)*(2*d-f); //(2-f)^2 = 3988009
            // uint256 k3=(2*d-f); //(2-f) = 1997
            // uint256 k4=2*(1*d-f); //2*(1-f) // 1994
            return(
                4*(1*d-f)*d,
                (2*d-f)*(2*d-f),
                (2*d-f),
                2*(1*d-f)
            );
    }
}