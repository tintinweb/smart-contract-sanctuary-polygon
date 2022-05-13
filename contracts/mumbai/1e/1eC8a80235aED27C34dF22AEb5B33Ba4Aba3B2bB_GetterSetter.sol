// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract GetterSetter {
    mapping(address => string) public values;

    function setValue(string memory value) external {
        values[msg.sender] = value;
    }
}