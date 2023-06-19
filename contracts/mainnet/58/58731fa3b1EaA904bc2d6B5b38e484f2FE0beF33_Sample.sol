// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Sample {
    uint256 private value;

    function getValue() external view returns (uint256) {
        return value;
    }

    function setValue(uint256 newValue) external {
        value = newValue;
    }
}