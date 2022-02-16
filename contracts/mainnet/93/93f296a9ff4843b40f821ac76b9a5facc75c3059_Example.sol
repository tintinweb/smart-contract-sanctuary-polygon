/**
 *Submitted for verification at polygonscan.com on 2022-02-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Example {

    struct Message {
        address writer;
        string message;
    }

    mapping(uint => Message) messages;
    uint public messagesLength;

    function chat(string memory _message) public {
        messages[messagesLength] = Message(msg.sender, _message);
        messagesLength++;
    }

    function getLatestMessage() public view returns (address, string memory) {
        return (messages[messagesLength - 1].writer, messages[messagesLength - 1].message);
    }

    function getMessageAt(uint index) public view returns (address, string memory) {
        return (messages[index].writer, messages[index].message);
    }
}