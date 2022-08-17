// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract MinusV2 {
    uint256 public val;

    function dec() external {
        val -= 1;
    }
}