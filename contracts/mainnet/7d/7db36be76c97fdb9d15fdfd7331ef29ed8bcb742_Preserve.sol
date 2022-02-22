/**
 *Submitted for verification at polygonscan.com on 2022-02-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/* 
TODO
 - Make sure only a certain set of ownsers can addAddresses
 */

contract Preserve {
  address owner;
  uint256 indexLen;

  /*
    1 - Full permissions
  */
  mapping(address => uint256) permissions;

  /* 
    You could possibly have multiple indexes depending on the usecase.
    This could either be explicit (new mapping) or by having a mapping of a mapping
    */
  mapping(uint256 => string) mainIndex;

  /*** Modifiers  ***/
  modifier fullPermissions() {
    require(permissions[msg.sender] == 1, "Action not allowed by user");
    _;
  }

  constructor() {
    permissions[msg.sender] = 1;
    owner = msg.sender;
  }

  /***
   Functions
  */
  function setUserPermissions(address _user, uint256 _permission)
    external
    fullPermissions
  {
    require(_user != owner, "Can't modify owner permissions");
    require(_user != msg.sender, "Can't modify your own permissions");

    permissions[_user] = _permission;
  }

  function returnIndexLen() external view returns (uint256) {
    return indexLen;
  }

  function returnValueAtIndex(uint256 _idx)
    external
    view
    returns (string memory)
  {
    return mainIndex[_idx];
  }

  function addValueToIndex(string memory _value) external fullPermissions {
    mainIndex[indexLen] = _value;
    indexLen++;
  }
}