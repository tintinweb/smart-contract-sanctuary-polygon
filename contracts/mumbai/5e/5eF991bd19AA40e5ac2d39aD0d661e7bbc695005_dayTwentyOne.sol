/**
 *Submitted for verification at polygonscan.com on 2022-11-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract dayTwentyOne{

    function hcf(uint256 numA, uint256 numB) public pure returns(uint256){

    uint256 divisor;

        if(numA > numB){
            divisor = numB;
        }
        else{
            divisor = numA;
        }

        while(divisor >= 1){
            if(numB % divisor == 0 && numA % divisor == 0){
                break;
            }
            divisor--;
        }
        return divisor;
    }
}