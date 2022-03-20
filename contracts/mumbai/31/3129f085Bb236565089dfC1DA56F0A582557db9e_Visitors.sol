// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Visitors {
    address owner = msg.sender;

    event VisitorCame(uint256 timestamp);
    uint256 public visitors;

    function visitorCame() external {
        require(owner == msg.sender, "only owner");
        visitors++;
        emit VisitorCame(block.timestamp);
    }

    function visitorsReset() external {
        require(owner == msg.sender, "only owner");
        visitors = 0;
    }
}