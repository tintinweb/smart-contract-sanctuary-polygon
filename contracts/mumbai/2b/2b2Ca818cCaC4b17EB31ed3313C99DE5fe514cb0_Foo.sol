// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract Foo {
  uint256 public value;

  constructor(uint256 initialValue) {
    value = initialValue;
  }

  function setValue(uint256 newValue) external {
    value = newValue;
  }
}