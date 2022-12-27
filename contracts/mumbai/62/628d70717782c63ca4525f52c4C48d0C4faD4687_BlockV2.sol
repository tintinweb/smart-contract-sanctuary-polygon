pragma solidity ^0.8.10;

// SPDX-License-Identifier: MIT

contract BlockV2 {
    uint256 public val;

    function initialize(uint256 _val) external {
        val += _val;
    }
}