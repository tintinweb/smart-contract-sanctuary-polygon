/**
 *Submitted for verification at polygonscan.com on 2022-11-26
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract TdexCmcGraph {
    
    //{
    //     "fromAmount": "280000000000000000",
    //     "id": "0x889164e561a65fdd3990af835b8a369f2849d16fe32b6085c74056d70de1e889",
    //     "pair": {
    //       "fromToken": {
    //         "decimals": 18,
    //         "symbol": "ETH",
    //         "tradeVolume": "5207944.760473916764396218"
    //       },
    //       "toToken": {
    //         "decimals": 9,
    //         "symbol": "DGX",
    //         "tradeVolume": "3028.465867692"
    //       }
    //     },
    //     "timestamp": "1569689186",
    //     "toAmount": "1054116024"
    //   },


    event Swap(uint256 fromAmount, 
               uint256 toAmount,
               uint256 timestamp,
               uint256 fromTokenDecimals,
               string  fromTokenSymbol,
               uint256 fromTokenTradeVolume,
               uint256 toTokenDecimals,
               string  toTokenSymbol,
               uint256 toTokenTradeVolume
    );

    constructor() {

    }



    function swapEvent(uint256 fromAmount, 
               uint256 toAmount,
               uint256 timestamp,
               uint256 fromTokenDecimals,
               string memory fromTokenSymbol,
               uint256 fromTokenTradeVolume,
               uint256 toTokenDecimals,
               string memory toTokenSymbol,
               uint256 toTokenTradeVolume) external {
        emit Swap( fromAmount, 
                toAmount,
                timestamp,
                fromTokenDecimals,
                 fromTokenSymbol,
                fromTokenTradeVolume,
                toTokenDecimals,
                 toTokenSymbol,
                toTokenTradeVolume);
    }
}