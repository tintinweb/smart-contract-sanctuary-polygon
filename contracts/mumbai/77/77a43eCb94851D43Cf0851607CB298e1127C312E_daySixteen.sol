/**
 *Submitted for verification at polygonscan.com on 2022-11-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract daySixteen {
    function distinct(int256[] memory array, uint256 length) public pure returns(uint256) {
        
        uint256 distinctCount = 1;
        uint256 index;
        
        for (uint256 step = 1; step < length; step++) // picking all elements one by one
        {
            for (index = 0; index < step; index++) 
            {
                if(array[step] == array[index]){
                    break;
                }
            }
                if (index == step) {
                    distinctCount++;
                }
        }
        return distinctCount;
    }
}