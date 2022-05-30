//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract BudTest {
    uint256 public val;

    function initialize(uint256 _val) external {
        val = _val;
    }
}