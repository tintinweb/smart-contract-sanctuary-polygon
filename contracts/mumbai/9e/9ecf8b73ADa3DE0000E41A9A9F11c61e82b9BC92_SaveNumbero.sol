// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract SaveNumbero {
    uint256 private secretNumber;

    constructor(uint256 _secretNumber) {
        secretNumber = _secretNumber;
    }

    function getNumbero() external view returns (uint256) {
        return secretNumber;
    }
}