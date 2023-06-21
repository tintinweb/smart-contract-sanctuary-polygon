/**
 *Submitted for verification at polygonscan.com on 2023-06-20
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

contract BroadcastTest {
    event Broadcast(address sender, string message);
    string public top;

    function broadcast(string memory message) public {
        top = message;
        emit Broadcast(msg.sender, message);
    }
}