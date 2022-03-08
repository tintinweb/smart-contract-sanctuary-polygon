//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract Verify {
    string private verify;

    constructor() {}

    function hello(bool sayHello) public pure returns (string memory) {
        if (sayHello) {
            return "hello";
        }
        return "";
    }
}