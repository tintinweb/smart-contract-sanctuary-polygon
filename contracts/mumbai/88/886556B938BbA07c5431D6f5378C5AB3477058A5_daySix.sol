/**
 *Submitted for verification at polygonscan.com on 2022-11-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract daySix{

    function average(int256 a,int256 b,int256 c) public pure returns (int256){
        require(a > 0 && b > 0 && c > 0, "Value entered should be greater than 0");
        int256 avg = (a + b + c)/3;
        return avg;
    }
    
}