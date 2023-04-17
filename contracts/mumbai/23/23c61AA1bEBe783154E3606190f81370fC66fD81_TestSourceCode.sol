//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract TestSourceCode {

    uint8 public value1;

    function test(uint8 value) public returns (uint8) {
        require(value > 10, "Value should be higher than 10");
        value1 = value;

        return value;
    }
}