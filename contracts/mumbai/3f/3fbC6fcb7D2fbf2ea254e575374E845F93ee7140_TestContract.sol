// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.9;

contract TestContract {
  uint256 private _counter = 0;

  function test() public {
    _counter = _counter + 1;
  }
}