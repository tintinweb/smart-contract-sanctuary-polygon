//SPDX-License-Identifier:MIT
pragma solidity ^0.8.9;

contract Verify {
    string private gretting;

    function hello(bool sayHello) public pure returns (string memory) {
        if (sayHello) {
            return "hello!";
        }
        return "";
    }
}