// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract Test  {
    uint256 public n;
    uint256 public t;
    function test() public {
        n = block.number;
        t = block.timestamp;
    }
}