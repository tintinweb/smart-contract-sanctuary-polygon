// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract Test{
  function getTime() external view returns(uint){
      return block.timestamp;
    }
}