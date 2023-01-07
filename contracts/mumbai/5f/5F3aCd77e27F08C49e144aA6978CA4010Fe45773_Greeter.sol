// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Greeter {
    string greeting;

    constructor() {
        greeting = "FIRSTGREETING";
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }
}