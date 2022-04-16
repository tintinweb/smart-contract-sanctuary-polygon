/**
 *Submitted for verification at polygonscan.com on 2022-04-16
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Greeter {
    string private greeting;
    event greetingUpdated(string greeting, uint blocknumber);

    constructor(string memory _greeting) {
        greeting = _greeting;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
        emit greetingUpdated(greeting, block.number);
    }
}