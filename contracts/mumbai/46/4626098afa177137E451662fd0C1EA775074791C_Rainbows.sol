// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


contract Rainbows {

    event LoopCreated(address indexed createdBy, address loop, string title, string description);

    function loopCreated(string memory title, string memory description, address loop, address creator) external {
        emit LoopCreated(creator, loop, title, description);
    }

}