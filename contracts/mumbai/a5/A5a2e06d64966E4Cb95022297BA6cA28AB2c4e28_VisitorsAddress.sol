// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract VisitorsAddress {
    address owner = msg.sender;

    event VisitorCame(uint256 timestamp, address visitor);
    uint256 public visitors;

    function visitorCame(address _visitor) external {
        require(owner == msg.sender, "only owner");
        visitors++;
        emit VisitorCame(block.timestamp, _visitor);
    }

    function visitorsReset() external {
        require(owner == msg.sender, "only owner");
        visitors = 0;
    }
}