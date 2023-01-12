// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract JakeCounter {
    uint256 public jakeNumber;

    function setJakeNumber(uint256 newNumber) public {
        jakeNumber = newNumber;
    }

    function incrementJake() public {
        jakeNumber++;
    }
}