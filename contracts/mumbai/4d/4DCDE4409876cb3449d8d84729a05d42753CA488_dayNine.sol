/**
 *Submitted for verification at polygonscan.com on 2022-11-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract dayNine {
    
    function prime(uint256 n) public pure returns(uint8){
        if(n <= 1){
            return 0; // Not Prime
        }
        for(uint256 i = 2; i < n; i++){
            if(n % i == 0){
                return 0; // Not Prime
            }
        }
        return 1;
      }

}