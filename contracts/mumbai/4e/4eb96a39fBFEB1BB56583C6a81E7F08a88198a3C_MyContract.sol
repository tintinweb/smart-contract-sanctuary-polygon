// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract MyContract {
  uint public myNumber;

  function initialize(uint _number) public {
    myNumber = _number;
  }

  function setNumber(uint _number) public {
    myNumber = _number;
  }
}