/**
 *Submitted for verification at polygonscan.com on 2022-02-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract Pol {
    uint num = 0;

    function inc() public {
        num++;
    }
    
    function getNum() public view returns(uint) {
        return num;
    }
}