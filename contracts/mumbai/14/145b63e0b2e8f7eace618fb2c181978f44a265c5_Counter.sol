// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Counter {
    uint256 public number;
    uint256 public pressCounter;

    struct Instructor {
        uint256 number;
        uint256 pressCounter;
    }

    event NumberChanged(Instructor instructor);

    function setNumber(uint256 newNumber) public {
        number = newNumber;
        emit NumberChanged(Instructor(number, pressCounter));
    }

    function increment() public {
        number++;
        pressCounter++;
        emit NumberChanged(Instructor(number, pressCounter));
    }

    function decrement() public {
        number--;
        pressCounter++;
        emit NumberChanged(Instructor(number, pressCounter));
    }
}