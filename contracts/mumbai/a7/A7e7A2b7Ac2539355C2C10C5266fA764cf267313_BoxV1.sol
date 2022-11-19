// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract BoxV1 {
    uint256 public val;

    function initialize(uint256 val_) external {
        val = val_;
    }
}