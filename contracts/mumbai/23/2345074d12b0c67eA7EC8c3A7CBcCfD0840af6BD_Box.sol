// SPDX-Licensed-Identifier: MIT

pragma solidity ^0.8.18;

contract Box {
    uint256 public y;

    function initialize(uint256 _val) public {
        y = _val;
    }
}