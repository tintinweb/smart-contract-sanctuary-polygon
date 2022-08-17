// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Logic {
    uint256 public count;

    constructor() {}

    function increment() public {
        count++;
    }
}