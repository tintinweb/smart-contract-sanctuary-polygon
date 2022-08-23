// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract SimpleStorage {
    string public greeting;

    constructor(string memory _greetingInput) {
        greeting = _greetingInput;
    }

    function setGreeting(string memory _greetingInput) public {
        greeting = _greetingInput;
    }

    function getGreeting() public view returns (string memory) {
        return greeting;
    }
}