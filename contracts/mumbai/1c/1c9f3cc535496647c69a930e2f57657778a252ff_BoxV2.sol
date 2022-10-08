// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract BoxV2 {
    uint public val;

    // constructor(uint _val) {
    //     val = _val;
    // }

    function inc(uint _val) external {
        val += _val;
    }
}