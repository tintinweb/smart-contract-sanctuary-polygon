/**
 *Submitted for verification at polygonscan.com on 2023-04-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Test {
    string public greet = "Hello World!";
    uint256 initialSupply;

    constructor(uint256 _initialSupply, string memory _name) {
        greet = string.concat("Hello, ", _name);
        initialSupply = _initialSupply;
    }
}