//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Greeter {
    string public greeting;
    address public owner;

    constructor() {
        greeting = "Hello World!";
        owner = msg.sender;
    }

    function setGreeting(string memory _greeting) public {
        require(msg.sender == owner, "Only owner");
        greeting = _greeting;
    }
}