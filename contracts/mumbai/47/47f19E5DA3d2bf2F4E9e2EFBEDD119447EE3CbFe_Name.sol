// SPDX-License-Identifier: nolicense
pragma solidity ^0.8.0; 
contract Name { 
  string public name; 

  function setName(string memory _newName) public returns(bool){
     name =_newName; 
     return true; 
  } 

  function getName() public view returns (string memory){ 
    return name; 
  } 
}