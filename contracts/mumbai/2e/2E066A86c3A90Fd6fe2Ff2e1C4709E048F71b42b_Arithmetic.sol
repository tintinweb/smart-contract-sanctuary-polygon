// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18 <0.9.0;

contract Arithmetic {
    uint public result;
    uint[] public arr;

    function add(uint x, uint y) public {
        result = x + y;
        arr.push(result);
    }

    function subtract(uint x, uint y) public {
        result = x - y;
        arr.push(result);
    }

    function multiply(uint x, uint y) public {
        result = x * y;
        arr.push(result);
    }

    function divide(uint x, uint y) public {
        require(y != 0, "Cannot divide by zero");
        result = x / y;
        arr.push(result);
    }
}