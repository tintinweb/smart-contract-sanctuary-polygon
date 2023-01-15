/**
 *Submitted for verification at polygonscan.com on 2023-01-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
contract SkyAnomChat {

  struct Message {
    address sender;
    string content;
    uint timestamp;
  }

  event NewMessageEvent(address from, uint timestamp, string message);
  
  address public admin;
  Message[] messages;
  address[] bannedAddresses;

  constructor(){
    admin=msg.sender;
  }

  modifier onlyAdmin {
    require(msg.sender == admin);
    _;
  }
  
  function sendMessage(string calldata _content) public {
    require(!isBanned(msg.sender),"This user is Banned");
    messages.push(Message(msg.sender, _content, block.timestamp));
    emit NewMessageEvent(msg.sender, block.timestamp, _content);
    if(messages.length>=10){
      delete messages[0];
    }
  }

  function isBanned(address _address) private view returns (bool) {
    for (uint256 i = 0; i < bannedAddresses.length; i++) {
      if (bannedAddresses[i] == _address) {
        return true;
      }
    }
    return false; 
  }

  function banUser(address _address) public onlyAdmin {
    bannedAddresses.push(_address);
  }

  function deleteMessages() public onlyAdmin {
    delete messages;
  }

  function getMessages() view public returns (Message[] memory) {
    return messages;
  }

  function getAdmin() view public returns(address){
    return admin;
  }
}