//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

contract Verify {
    string private greeting;
    constructor() {
    }

    function hello(bool sayHello) public pure returns (string memory) {
        if (sayHello) {
            return "hello";
        }
        return "";
    }
}

// Verify Contract Address: 0xD755BF24d36E1Ca269d2854d34C9A249425Ad8Ed