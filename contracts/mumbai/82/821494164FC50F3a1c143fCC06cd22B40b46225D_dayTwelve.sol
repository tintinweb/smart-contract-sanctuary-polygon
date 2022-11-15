/**
 *Submitted for verification at polygonscan.com on 2022-11-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract dayTwelve {
    
    function reverseDigit(uint256 n) public pure returns(uint256){
        uint256 reversed = 0;
        uint256 remainder;

        while (n != 0){
            remainder = n % 10;
            reversed = reversed * 10 + remainder;
            n /= 10;
        }

        return reversed;
    }
    
}