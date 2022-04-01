// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Project {
    uint private count;
    uint private value=0;

    function getValue () external view returns (uint) {
        return count;
    }

    function addOneToValue () external {
        value += count;    
    }
}