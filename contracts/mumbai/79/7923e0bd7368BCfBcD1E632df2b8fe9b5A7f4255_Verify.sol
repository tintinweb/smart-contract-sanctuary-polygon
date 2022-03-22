//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract Verify { 
    string private Greeting;

    function hello(bool sayHello) public pure returns (string memory) {
        if (sayHello) {
            return "Hello";
        } else {
            return "Goodbye";
        }
    }
}