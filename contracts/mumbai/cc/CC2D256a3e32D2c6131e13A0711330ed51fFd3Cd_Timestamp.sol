/**
 *Submitted for verification at polygonscan.com on 2022-09-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Timestamp {
    function getTimestamp() public view returns (uint) {
        return block.timestamp;
    }
}