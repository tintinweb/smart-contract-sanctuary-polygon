/**
 *Submitted for verification at polygonscan.com on 2022-11-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


contract Storage {
     uint256 public s_usdtPrice = 36000;
     uint256 public s_minAmountToInvest = 100000000;

    function multiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }
      function buyTokens(uint256 amount) payable external  {
        uint256 payableAmount = multiply(amount, s_usdtPrice);
        require(
            payableAmount >= s_minAmountToInvest,
            "YPredictPrivateSale: Less than Minimum investment"
        );
    }

    
}