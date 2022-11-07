/**
 *Submitted for verification at polygonscan.com on 2022-11-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract dayFour{

    function evaluate(int256 a, int256 b) public pure returns(int256){
        int256 sum = a + b;
        int256 diff = a - b;
        int256 result = sum - diff;
        return result;
    }

    // OR

    // function evaluate(int256 a, int256 b) public pure returns (int256) {
    //     return ((a + b) - (a - b));
    // }

}