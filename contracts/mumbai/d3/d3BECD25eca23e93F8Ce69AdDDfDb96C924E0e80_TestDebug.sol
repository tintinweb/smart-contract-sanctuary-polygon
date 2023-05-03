/**
 *Submitted for verification at polygonscan.com on 2023-05-02
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

contract TestDebug {

    uint8 public value1;
    
    function test1(uint8 value) public returns (uint8) {
        require(value > 10, "Value should be higher than 10");
        value1 = value + 5;

        return value1;
    }
}