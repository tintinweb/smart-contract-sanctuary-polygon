// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract ChangeNumber {
    uint256 number = 1;
    constructor() {}

    function getNumber() public view returns (uint256) {
        return number;
    }

    function changeNumber(uint256 _number) public returns (uint256) {
        number = _number;
        return number;
    }
}