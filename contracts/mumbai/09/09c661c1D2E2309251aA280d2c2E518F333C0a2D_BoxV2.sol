// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract BoxV2 {
    uint256 public val;

    // function initialize(uint val_) external {
    //     val = val_;
    // }
    function inc() external {
        val++;
    }
}