// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

contract BoxV2 {
    uint public val;

    function inc() external {
        val += 1;
    }
}