/**
 *Submitted for verification at polygonscan.com on 2023-01-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
contract SkyAnomChat {
  address public admin;
  struct Message {
      address sender;
      string content;
      uint timestamp;
    }

  Message[] messages;
  constructor(){
    admin=msg.sender;
  }
  modifier onlyAdmin {
    require(msg.sender == admin);
    _;
}
  event SendMessage(address from, uint timestamp, string message);
  

  function sendMessage(string calldata _content) public {
    messages.push(Message(msg.sender, _content, block.timestamp));
    emit SendMessage(msg.sender, block.timestamp, _content);
    if(messages.length>=10){
      delete messages[0];
    }
  }

  function deleteMessages() public onlyAdmin {
    delete messages;
  }
  function getMessages() view public returns (Message[] memory) {
    return messages;
  }
}