// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract PresaleB {
  uint public val;

  // function initialize(uint _val) external {
  //   val = _val;
  // }

  function inc() external {
    val += 1;
  }
}