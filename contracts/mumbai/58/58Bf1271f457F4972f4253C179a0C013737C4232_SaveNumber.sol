// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract SaveNumber {
    uint256 private secretNumber;

    constructor(uint256 _secretNumber) {
        secretNumber = _secretNumber;
    }

    function getNumber() external view returns (uint256) {
        return secretNumber;
    }
}