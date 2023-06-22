// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Test {

    int8 public _number;

    function test(int8 number) public {
        require(number > 2, "number shoud be higher than 2");
        _number = number;
    }
}