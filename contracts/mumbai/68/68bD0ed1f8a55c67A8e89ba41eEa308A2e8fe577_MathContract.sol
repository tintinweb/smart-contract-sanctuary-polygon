/**
 *Submitted for verification at polygonscan.com on 2023-08-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract MathContract {
    mapping(address => int) public i;

    function add(int value) public {
        i[msg.sender] = i[msg.sender] + value;
    }

    function subtract(int value) public {
        i[msg.sender] = i[msg.sender] - value;
    }

    function multiply(int value) public {
        i[msg.sender] = i[msg.sender] * value;
    }

    function divide(int value) public {
        require(value != 0, "Cannot divide by zero");
        i[msg.sender] = i[msg.sender] / value;
    }

    function getVal(address val) public view returns (int) {
        return i[val];
    }
}