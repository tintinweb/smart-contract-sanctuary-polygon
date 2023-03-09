// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract X {
    uint256 public TEST;

    constructor() {
        TEST = 0;
    }

    function setTest(uint256 _value) public {
        TEST = _value;
    }

    function getTest() public view returns (uint256) {
        return TEST;
    }
}