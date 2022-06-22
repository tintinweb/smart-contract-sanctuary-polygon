// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Verify {
    constructor() {}

    function hello(bool sayHello) public pure returns (string memory) {
        if (sayHello) {
            return "hello";
        } else {
            return "";
        }
    }
}