// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract ProductV2 {
    uint private value;

    function setValue(uint newValue) public {
        value = newValue;
    }

    function getValue() public view returns (uint) {
        return value + 2;
    }
}