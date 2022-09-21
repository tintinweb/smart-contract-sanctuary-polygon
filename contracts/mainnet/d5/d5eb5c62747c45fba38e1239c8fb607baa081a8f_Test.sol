/**
 *Submitted for verification at polygonscan.com on 2022-09-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Test {
    function time() external view returns (uint256) {
        return block.timestamp;
    }
}