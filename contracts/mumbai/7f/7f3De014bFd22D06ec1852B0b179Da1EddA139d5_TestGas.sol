/**
 *Submitted for verification at polygonscan.com on 2022-09-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestGas {
    uint256 public value = 0;

    function setValue(uint256 newValue) external {
        require(newValue < 10, "newValue >= 10");

        value = newValue;
    }
}