//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Market_V1 {
    uint public val;

    function initialize(uint _val) external {
        val = _val;
    }
}