// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Greeter {
    string private greeting;
    event storageEvent(string oldMsg, string newMsg);

    constructor(string memory _greeting){
        greeting=_greeting;
    }

    function setGreeting(string memory _greeting) public {
        emit storageEvent( greeting, _greeting);
        greeting = _greeting;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }
}