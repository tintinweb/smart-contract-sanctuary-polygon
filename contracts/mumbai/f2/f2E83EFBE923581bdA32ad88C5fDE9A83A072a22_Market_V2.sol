//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Market_V2 {
    uint public val;

    function inc() external {
        val += 1;
    }
}