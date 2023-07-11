// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestImported {

    int8 public _number;

    function giveNumber(int8 number) public returns (int8) {
        require(number > 10, "number shoud be higher than 10");
        _number = number;
        return number * 2;
    }
}