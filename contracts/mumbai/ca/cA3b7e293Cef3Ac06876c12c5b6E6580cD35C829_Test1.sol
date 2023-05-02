/**
 *Submitted for verification at polygonscan.com on 2023-05-01
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

contract Test1 {

    uint8 public value1;
    
    // *************** Get/Set *****************
    function getValue1() public virtual view returns (uint8) {
        return value1;
    }
    
    function test1(uint8 value) public returns (uint8) {
        require(value > 10, "Value should be higher than 10");
        value1 = value + 5;

        return value1;
    }
}