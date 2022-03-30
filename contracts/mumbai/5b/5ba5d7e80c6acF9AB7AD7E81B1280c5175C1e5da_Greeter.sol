//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Greeter {
    string private greeting;

    constructor() {
        greeting = "Hello from Greeter!";
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }
}