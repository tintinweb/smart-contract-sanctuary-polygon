/**
 *Submitted for verification at polygonscan.com on 2022-11-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract dayThirteen{

    function reverseArray(uint256[] memory argArray, uint256 arrLength) public pure returns(uint256[] memory){
        uint256 temp;
        
        for(uint256 index = 0; index < arrLength/2; index++){
            temp = argArray[index];
            argArray[index] = argArray[arrLength - index - 1];
            argArray[arrLength - index - 1] = temp;
        }

        return argArray;
    }
    
}