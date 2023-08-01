/**
 *Submitted for verification at polygonscan.com on 2023-07-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract MathContract {
    uint public i;

    constructor() {
        i = 0;
    }

    function add(uint value) public {
        i = i + value;
    }

    function subtract(uint value) public {
        require(i >= value, "The value to subtract must be less than or equal to 'i'");
        i = i - value;
    }

    function multiply(uint value) public {
        i = i * value;
    }

    function divide(uint value) public {
        require(value != 0, "Cannot divide by zero");
        i = i / value;
    }
}