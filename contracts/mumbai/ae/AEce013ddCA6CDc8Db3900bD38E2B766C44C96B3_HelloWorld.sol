/**
 *Submitted for verification at polygonscan.com on 2022-03-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract HelloWorld {

    string saySomething;

    constructor() {
        saySomething = "Hello World!";
    }

    function speak() public view returns(string memory) {
        return saySomething;
    }
}