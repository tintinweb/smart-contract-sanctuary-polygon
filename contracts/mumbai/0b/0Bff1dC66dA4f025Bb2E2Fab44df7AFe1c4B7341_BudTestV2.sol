//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract BudTestV2 {
    uint256 public val;

    function inc() external {
        val += 1;
    }
}