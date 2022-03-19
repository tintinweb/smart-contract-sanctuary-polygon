/**
 *Submitted for verification at polygonscan.com on 2022-03-18
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract Counter {
    uint256 public value;

    constructor(uint256 _value) {
        value = _value;
    }

    function increment() public {
        value += 1;
    }
}