// SPDX-Licnse-Identifier: Unlicensed
pragma solidity ^0.8.4;

contract Verify {
    string private greeting;

    constructor() {

    }

    function hi(bool sayHello) public pure returns(string memory) {
        if(sayHello) {
            return "Hello there";
        }
        return "";
    }
}