/**
 *Submitted for verification at polygonscan.com on 2023-05-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HelloWorld {
    // store the greeting phrase
    string greeting = "Hello";

    // given some name, greet that person 
    function greet(string memory name) public view returns(string memory) {
        return string.concat(greeting, " ", name);
    }

    // change the greeting phrase
    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }
}