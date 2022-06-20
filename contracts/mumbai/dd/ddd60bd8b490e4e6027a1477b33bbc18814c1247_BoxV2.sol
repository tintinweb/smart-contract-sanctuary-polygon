/**
 *Submitted for verification at polygonscan.com on 2022-06-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract BoxV2 {
    uint public val;

    // function initialize(uint _val) external {
    //     val = _val;
    // }

    function inc() public {
        val += 1;
    }
}