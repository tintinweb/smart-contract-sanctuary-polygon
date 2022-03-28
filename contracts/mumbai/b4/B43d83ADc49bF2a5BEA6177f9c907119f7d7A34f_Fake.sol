// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Fake {
    uint256 public num = 1;

    function add(uint256 _num) public returns (uint256) {
        return num += _num;
    }
}