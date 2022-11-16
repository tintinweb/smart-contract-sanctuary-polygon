/**
 *Submitted for verification at polygonscan.com on 2022-11-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract dayFourteen {
    
    function even(uint256[] memory inputArr, uint256 length) public pure returns(uint256[] memory){
        for (uint8 i = 0; i <= length - 1; i++) {
            uint256 temp = inputArr[i] * 2; // multiply every index value by 2
            inputArr[i] = temp;
        }
        return inputArr;
    }

}