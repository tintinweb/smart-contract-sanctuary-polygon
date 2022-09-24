/**
 *Submitted for verification at polygonscan.com on 2022-09-23
*/

// SPDX-License-Identifier: GPL

pragma solidity 0.8.17;

contract BoxV2 {
    uint256 public val;

    // function initialize(uint256 _val) external {
    //     val = _val;
    // }

    function increment() external {
        val = ++val;
    }
}