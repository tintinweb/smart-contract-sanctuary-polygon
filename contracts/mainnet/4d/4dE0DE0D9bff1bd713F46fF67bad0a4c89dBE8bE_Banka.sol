/**
 *Submitted for verification at polygonscan.com on 2022-02-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Banka {
    uint public timeEnd = 0;

    function startTimer() public {
        timeEnd = block.timestamp + 99;
    }
    function timeLeft() public view returns(uint) {
        return timeEnd - block.timestamp;
    }
}