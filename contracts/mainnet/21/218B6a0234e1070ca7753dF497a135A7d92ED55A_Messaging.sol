/**
 *Submitted for verification at polygonscan.com on 2023-04-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Messaging {
    struct Message {
        address sender;
        string content;
        uint256 timestamp;
    }

    Message[] public messages;

    event NewMessage(uint256 indexed messageId, address indexed sender, string content, uint256 timestamp);

    function sendMessage(string memory content) public {
        uint256 newMessageId = messages.length;
        messages.push(Message(msg.sender, content, block.timestamp));
        emit NewMessage(newMessageId, msg.sender, content, block.timestamp);
    }

    function getMessageCount() public view returns (uint256) {
        return messages.length;
    }

    function getMessages() public view returns (Message[] memory) {
        return messages;
    }
}