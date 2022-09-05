//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Malicious {
    uint256 public counter;

    constructor() {}

    function count() public returns (bool) {
        counter++;
        return true;
    }
}