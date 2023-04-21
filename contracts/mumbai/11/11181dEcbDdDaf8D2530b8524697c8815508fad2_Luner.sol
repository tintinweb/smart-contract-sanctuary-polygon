/**
 *Submitted for verification at polygonscan.com on 2023-04-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Luner {
    event DaysSince(uint256 daysSince);
    
    function moonPhase() public returns (uint256){
        uint256 timestamp = block.timestamp;
        uint256 lastNewMoon =  947163600 gwei; // january 6th 2000 -- gwei adds 9 zeros we will use as for decimals
        uint256 daysSince = ((timestamp * 1 gwei) - lastNewMoon) / 86400 gwei; // 86400 seconds in a day
        emit DaysSince(daysSince);

        return 0;


    }
}