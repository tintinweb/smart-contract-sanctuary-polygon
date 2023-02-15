// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Increment {
  uint256 private value;

  function getter() public view returns(uint256) {
    return value;
  }

  function setter() public {
    value++;
  }
}