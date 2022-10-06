// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract V1 {
    uint256 public number;

    function initialValue(uint256 _num) external {
        number = _num;
    }

    function increase() external {
        number += 1;
    }
}