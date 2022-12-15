// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract TestMapping {
    mapping(uint8 => uint256) public testMap;

    constructor() {
        testMap[5] = 10000;
    }
}