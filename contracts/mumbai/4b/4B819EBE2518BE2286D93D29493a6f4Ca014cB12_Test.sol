/**
 *Submitted for verification at polygonscan.com on 2023-01-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Test {
    uint256 private val;

    constructor() {
        val = 1;
    }

    function getVal() public view returns (uint256) {
        return val;
    }

    function setVal(uint256 newValue) external {
        require(newValue < 10, "newValue >= 10");

        val = newValue;
    }
}