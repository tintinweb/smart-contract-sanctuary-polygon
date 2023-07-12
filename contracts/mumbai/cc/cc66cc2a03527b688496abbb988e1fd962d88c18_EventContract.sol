/**
 *Submitted for verification at polygonscan.com on 2023-07-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract EventContract {
    event MyEvent(address indexed sender, uint256 value);

    function emitEvent(uint256 value) external {
        emit MyEvent(msg.sender, value);
    }
}