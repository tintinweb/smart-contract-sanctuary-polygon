/**
 *Submitted for verification at polygonscan.com on 2022-11-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract daySeven {
    
    function digitSum(int256 n) public pure returns(int256){
        require(n > 0, "Value entered should be a natural number.");

        int256 remainder;
        int256 result;

        while (n > 0){
            remainder = n % 10; // Returns the last digit of any number
            result += remainder;
            n /= 10;
        }

        return result;
    }

}