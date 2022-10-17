//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4; //asdas

contract Verify {
    string private greeting;

    constructor() {
    }

    function hello(bool sayHello) public pure returns (string memory) {
        if(sayHello) {
            return "hello";
        }
        return "";
    }
}