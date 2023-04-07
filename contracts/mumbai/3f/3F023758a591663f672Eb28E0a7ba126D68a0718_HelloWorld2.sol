// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract HelloWorld2 {

    string saySomething;

    constructor() {
        saySomething = "Hello World2!";
    }

    function speak() public view returns(string memory) {
        return saySomething;
    }
}