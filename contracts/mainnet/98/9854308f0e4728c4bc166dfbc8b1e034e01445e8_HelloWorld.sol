/**
 *Submitted for verification at polygonscan.com on 2023-05-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract HelloWorld {
    string greeting = unicode"こんにちは";

    function greet(string memory name) public view returns (string memory) {
        return string.concat(greeting, " ", name);
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }
}