/**
 *Submitted for verification at polygonscan.com on 2022-09-05
*/

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0;
contract GameUserProfile {
  string public name;

  constructor() {
    name = "n/a";
  }
  
  function setName(string memory _name) public {
    name = _name;
  }
  
  function getName() view public returns (string memory) {
    return name;
  }
}