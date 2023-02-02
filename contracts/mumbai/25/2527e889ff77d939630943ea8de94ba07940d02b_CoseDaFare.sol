/**
 *Submitted for verification at polygonscan.com on 2023-02-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
 contract CoseDaFare {
   struct Note {
     uint256 id;
     bytes32 content;
     address owner;
     bool isCompleted;
     uint256 timestamp;
   }
   uint256 public constant maxAmountOfNote = 100;
   // Owner = Note
   mapping(address => Note[maxAmountOfNote]) public note;
   // Owner = id ultima nota
   mapping(address => uint256) public lastIds; 
  
  modifier onlyOwner(address _owner) {
  require(msg.sender == _owner);
  _;
  }
  // Aggiungi note alla lista
  function addNote(bytes32 _content) public {
    Note memory myNote = Note(lastIds[msg.sender], _content, msg.sender, false, block.timestamp);
    note[msg.sender][lastIds[msg.sender]] = myNote;
  
    if(lastIds[msg.sender] == maxAmountOfNote)
  
    lastIds[msg.sender] = 0;
  
    else lastIds[msg.sender]++;
  
}
}