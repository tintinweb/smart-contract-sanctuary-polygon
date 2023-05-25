/**
 *Submitted for verification at polygonscan.com on 2023-05-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Test {
    function test() public view returns (uint256) {
        return block.basefee;
    }
}