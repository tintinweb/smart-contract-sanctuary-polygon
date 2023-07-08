/**
 *Submitted for verification at polygonscan.com on 2023-07-06
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract SimpleContract {
    uint public value;

    constructor() {
        value = 0;
    }

    function setValue(uint newValue) public {
        value = newValue;
    }

    function getValue() public view returns (uint) {
        return value;
    }
}