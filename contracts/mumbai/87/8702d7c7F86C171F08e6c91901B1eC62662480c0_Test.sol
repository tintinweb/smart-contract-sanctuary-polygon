// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Test {
    
    string public name;
    uint256 public index;

    mapping(address => bool) public whiteList;

    event RegisterEvent(
        uint256 indexed _totalRegisters
    );

    constructor() {
        name = "hello";
        index = 0;
    }

    function register() public returns (uint256) {
        index = index +1;
        emit RegisterEvent(index);
        return index;
    }

    function add(uint256 a, uint256 b) public pure returns (uint256) {
        return a + b;
    }
}