// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract Test{
  address public owner;
  uint256 public ownerId;
  string name;

  constructor(address owner_, uint256 ownerId_, string memory name_) {
    owner = owner_;
    ownerId = ownerId_;
    name = name_;
  }

  function getTime() external view returns(uint){
      return block.timestamp;
  }
}