/**
 *Submitted for verification at polygonscan.com on 2022-04-03
*/

// SPDX-License-Identifier: GPL-3.0

// File: contracts/rate0304.sol



pragma solidity >=0.7.0 <0.9.0;

contract Rate_v5{
  mapping(uint256 => uint256) public rateNFT;
  mapping(uint256 => uint256) public rateBOOSTER;
    constructor(
  ) {
  }
  function rates() public {
      for(uint256 i = 1; i <= 5; i++){
          	if (i == 1){
        		rateNFT[i] = 5;
            }
        	if (i == 2){
        		rateNFT[i] = 15;
            	}
        	if (i == 3){
        		rateNFT[i] = 25;
        	}
        	if (i == 4){
        		rateNFT[i] = 35;
        	}
        	if (i == 5){
        		rateNFT[i] = 45;
        	}
      }
        for(uint256 i = 1; i <= 3; i++){
          	if (i == 1){
        		rateBOOSTER[i] = 50;
            }
        	if (i == 2){
        		rateBOOSTER[i] = 100;
            	}
        	if (i == 3){
        		rateBOOSTER[i] = 200;
        	}
      }
  }
}