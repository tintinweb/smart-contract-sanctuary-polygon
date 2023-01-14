// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract setVal{
    uint public value = 0;

    function setValue() public returns(uint){
        value = 100;
        return value;
    }
}