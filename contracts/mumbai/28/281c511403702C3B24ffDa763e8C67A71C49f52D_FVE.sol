// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract FVE {
    uint256 public counter = 0;

    function setIncrement() external {
        counter += 1;
    }
}