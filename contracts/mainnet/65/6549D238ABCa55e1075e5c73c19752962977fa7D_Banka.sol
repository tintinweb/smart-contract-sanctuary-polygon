/**
 *Submitted for verification at polygonscan.com on 2022-02-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Banka {
    event gameStarted(uint timeStarted, uint timeEnd);
    uint public timeEnd = 0;

    function startTimer() public {
        timeEnd = block.timestamp + 99;
        emit gameStarted(block.timestamp, timeEnd);
    }
    function timeLeft() public view returns(uint) {
        return timeEnd - block.timestamp;
    }
}