// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

contract Box {
    uint public val;

    function initialize(uint _val) external {
        val = _val;
    }
}