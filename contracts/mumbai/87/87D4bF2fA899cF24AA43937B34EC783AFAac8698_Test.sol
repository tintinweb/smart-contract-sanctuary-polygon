/**
 *Submitted for verification at polygonscan.com on 2022-03-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

contract Test {

  address public owner;
  uint256 public createdAt;
  string public data;

  constructor() {
    owner = msg.sender;
    createdAt = block.timestamp;
  }

  function updateData(string memory _data) public {
    require(msg.sender == owner);
    data = _data;
  }

}