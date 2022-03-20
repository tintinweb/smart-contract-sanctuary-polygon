// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract VisitorsAddress {
    address owner = msg.sender;

    event VisitorCame(uint256 timestamp, address visitor);
    uint256 public visitors;

    uint256 public uniqueVisitors;
    mapping(address => bool) visited;

    function visitorCame(address _visitor) external {
        require(owner == msg.sender, "only owner");
        visitors++;
        if (!visited[_visitor]) {
            uniqueVisitors++;
            visited[_visitor] = true;
        }
        emit VisitorCame(block.timestamp, _visitor);
    }
}