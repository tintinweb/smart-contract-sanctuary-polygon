/**
 *Submitted for verification at polygonscan.com on 2022-03-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
contract MyContract {
    string value;

    constructor() {
        value = "myValue";
    }
    function get() public view returns(string memory) {
        return value;
    }
    function set(string memory newValue) public {
        value = newValue;
    }
}