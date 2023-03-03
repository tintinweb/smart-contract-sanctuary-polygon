/**
 *Submitted for verification at polygonscan.com on 2023-03-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Attendance {
    mapping(address => bool) private managers;
    mapping(bytes32 => bool) private sessionIds;

    address private admin;

    event SessionIdGenerated(address indexed manager, bytes32 sessionId, address indexed client, uint256 timestamp);

    modifier onlyManager() {
        require(managers[msg.sender], "Sender is not a manager");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function addManager() public {
        require(!managers[msg.sender], "Address is already a manager");
        managers[msg.sender] = true;
    }


    function removeManager() public onlyManager {
        managers[msg.sender] = false;
    }

    function isManager(address _address) public view returns (bool) {
        return managers[_address];
    }

    function generateSessionId(address client) public onlyManager returns (bytes32) {
        bytes32 sessionId = keccak256(abi.encodePacked(msg.sender, client, block.timestamp));

        require(!sessionIds[sessionId], "Session ID already exists");

        sessionIds[sessionId] = true;

        emit SessionIdGenerated(msg.sender, sessionId, client, block.timestamp);

        return sessionId;
    }

    function isSessionIdValid(bytes32 sessionId) public view returns (bool) {
        return sessionIds[sessionId];
    }
}