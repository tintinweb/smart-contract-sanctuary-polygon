/**
 *Submitted for verification at polygonscan.com on 2023-06-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ChatDapp {
    struct Message {
        address sender;
        address recipient;
        uint256 timestamp;
        string content;
    }

    mapping(address => Message[]) private sentMessages;
    mapping(address => Message[]) private receivedMessages;

    function sendMessage(address recipient, string memory message) public {
        Message memory newMessage = Message(msg.sender, recipient, block.timestamp, message);
        sentMessages[msg.sender].push(newMessage);
        receivedMessages[recipient].push(newMessage);
    }

    function getSentMessages() public view returns (Message[] memory) {
        return sentMessages[msg.sender];
    }

    function getReceivedMessages() public view returns (Message[] memory) {
        return receivedMessages[msg.sender];
    }
}

// 0x7BB06D3e9DB1cb500795B73F539f625100ab6485