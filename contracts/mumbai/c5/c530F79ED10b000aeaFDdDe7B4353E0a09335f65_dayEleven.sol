/**
 *Submitted for verification at polygonscan.com on 2022-11-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract dayEleven {
    function palindrome(uint256 n) public pure returns(uint256){
        uint256 reversed = 0;
        uint256 remainder;
        uint256 original = n;

        while(n != 0){
            remainder = n % 10;
            reversed = reversed * 10 + remainder;
            n /= 10;
        }

        if(original == reversed){
            return 1; // Palindrome
        }
        else{
            return 0; // Not Palindrome
        }
    }
}