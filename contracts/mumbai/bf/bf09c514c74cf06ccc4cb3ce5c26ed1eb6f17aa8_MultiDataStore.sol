/**
 *Submitted for verification at polygonscan.com on 2023-05-05
*/

// SPDX-License-Identifier: UNLICENSED 
pragma solidity ^0.8.19;

contract MultiDataStore {

  struct Details {
    mapping(string => string) data;
    string[] keys;
  }

  mapping(string => Details) users; 
  string[] userKeys; // new array to keep track of all user keys

  address private owner;

  constructor() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "Only the contract owner can call this function.");
    _;
  }

  function addDetail(string memory userKey, string memory detailKey, string memory value) public onlyOwner {
    Details storage details = users[userKey];
    details.data[detailKey] = value;
    details.keys.push(detailKey);
    
    if (details.keys.length == 1) { 
        userKeys.push(userKey);
    }
  }

  function getDetail(string memory userKey, string memory detailKey) public view onlyOwner returns (string memory) {
    return users[userKey].data[detailKey];
  }

  function getAllDetails(string memory userKey) public view onlyOwner returns (string memory) {
    Details storage details = users[userKey];
    string memory result;
    for(uint i=0; i<details.keys.length; i++) {
      result = string(abi.encodePacked(result, details.keys[i], ": ", details.data[details.keys[i]], "\n"));
    }
    return result;
  }
  
  function getAllUserKeys() public view onlyOwner returns (string[] memory) {
    return userKeys;
  }
}