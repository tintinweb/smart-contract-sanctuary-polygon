/**
 *Submitted for verification at polygonscan.com on 2023-04-25
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract GetTimeStamp {
    function getCurrentTimestamp() public view returns (uint256) {
        return block.timestamp;
    }
}