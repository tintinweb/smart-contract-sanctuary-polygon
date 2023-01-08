/**
 *Submitted for verification at polygonscan.com on 2023-01-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Lock {
    bool isLocked;
    uint8 constant value = 7;

    function lock() public {
        isLocked = true;
    }

    function unlock() public {
        isLocked = false;
    }

    function getValue() public view returns (uint8) {
        require(!isLocked, "It is locked");
        return value;
    }
}