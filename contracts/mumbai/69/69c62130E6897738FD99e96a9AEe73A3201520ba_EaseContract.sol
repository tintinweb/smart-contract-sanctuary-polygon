/**
 *Submitted for verification at polygonscan.com on 2023-07-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EaseContract {
    string value;

    constructor() {
        value = "hello world";
    }

    function getValue() public view returns(string memory) {
        return value;
    }

    function setValue(string memory _value) public {
        value = _value;
    }
}