/**
 *Submitted for verification at polygonscan.com on 2022-11-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract dayFifteen {
    
    function sort(int256[] memory array, uint256 length) public pure returns(int256[] memory) {
        for (uint256 step = 0; step < length - 1; ++step) { 
            int256 swapped = 0;

            for (uint256 i = 0; i < length - step - 1; ++i) { 
                if (array[i] > array[i + 1]) {
                    int256 temp;
                    temp = array[i];
                    array[i] = array[i + 1];
                    array[i + 1] = temp;

                    swapped = 1;
                }
            }

            if (swapped == 0) {
                break;
            }
        }
        return array;
    }
}