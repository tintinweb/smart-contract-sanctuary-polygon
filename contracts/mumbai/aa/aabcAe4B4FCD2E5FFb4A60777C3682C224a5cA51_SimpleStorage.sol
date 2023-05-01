// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    string private value;

    function setValue(string memory _value) public {
        value = _value;
    }

    function getValue() public view returns (string memory) {
        return value;
    }
}