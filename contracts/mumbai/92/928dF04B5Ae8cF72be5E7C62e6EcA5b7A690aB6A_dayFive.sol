/**
 *Submitted for verification at polygonscan.com on 2022-11-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract dayFive{

    function find(int256 a) public pure returns(int256){
        require(a > 0, "Value entered should be greater than 0");
        int256 remainder = a % 3;
        return remainder;
    }

}