// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract Test{
  address public owner;

  constructor(address owner_) {
    owner = owner_;
  }

  function getTime() external view returns(uint){
      return block.timestamp;
  }
}