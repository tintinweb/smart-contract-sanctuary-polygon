// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Increment {
  uint256 private value;

  function getterValue() public view returns(uint256) {
    return value;
  }

  function setterValue() public {
    value++;
  }

  function doSomething() public view {
    value;
  }
}