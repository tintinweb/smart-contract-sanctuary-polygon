// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Counter {
    uint256 public number;
    event NumberChanged(uint256 newNumber);

    function setNumber(uint256 newNumber) public {
        number = newNumber;
        emit NumberChanged(newNumber);
    }

    function increment() public {
        number++;
    }
}