pragma solidity ^0.8.10;
// SPDX-License-Identifier: MIT

contract Block {
    uint public val;
    function initialize(uint _val) external {
            val = _val;
    }
}