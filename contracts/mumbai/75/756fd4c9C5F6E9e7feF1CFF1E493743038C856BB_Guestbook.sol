/**
 *Submitted for verification at polygonscan.com on 2023-05-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Guestbook {

  event NewMessage(address indexed from, string message);

  struct Message {
    address visitor;
    string message;
  }

  mapping(address => bool) public hasWrittenMessage;
  Message[] messages;

  constructor() {}

  function setMessage(string memory _message) public {
    require(!hasWrittenMessage[msg.sender], "You have already written a message.");
    hasWrittenMessage[msg.sender] = true;
    messages.push(Message(msg.sender, _message));
    emit NewMessage(msg.sender, _message);
  }

  function getAllMessages() public view returns (Message[] memory) {
    return messages;
  }
}