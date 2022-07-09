//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

// https://docs.alchemy.com/alchemy/tutorials/how-to-code-and-deploy-a-polygon-smart-contract


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