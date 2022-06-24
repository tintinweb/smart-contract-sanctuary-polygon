//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Greeter {
    string private greeting;

    constructor() {
        greeting = "Hello Gopi";
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }
}