// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
error Error01();

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

    function setName(string memory _name) public {
        name = _name;
    }

    function getInfo() public view returns (string memory, uint256) {
        return (name, index);
    }

    function cal(uint256 a, uint256 b) public returns (uint256) {
        if (a > b) {
            revert("Error no 1");
        }


        if (a < b) {
            revert Error01();
        }
        index = a + b;
    }
}