// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract HelloWorld {
    constructor() {}

    //functio to return greet with name
    function greet(string memory _name) public pure returns (string memory _greet) {
        _greet = string(abi.encodePacked("Hello World ",_name));
    }
}