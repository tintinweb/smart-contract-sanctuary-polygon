//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

contract Verify {
    string private greetings;

    constructor() {}

    function hello(bool sayhello) public pure returns (string memory) {
        if (sayhello) {
            return "hello frens";
        }
        return "";
    }
}