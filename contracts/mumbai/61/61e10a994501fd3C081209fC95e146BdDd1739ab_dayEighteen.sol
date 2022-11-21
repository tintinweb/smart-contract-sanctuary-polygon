/**
 *Submitted for verification at polygonscan.com on 2022-11-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract dayEighteen{

    function sumArray(int256[] memory array, uint32 length) public pure returns(int256){
        int256 result = 0;

        for(uint32 i = 0; i < length; i++){
            result += array[i];
        }

        return result;
    }

}