/**
 *Submitted for verification at polygonscan.com on 2022-10-07
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract TestContract {
  uint256 private _counter = 0;

  function increaseCount() public {
    _counter = _counter + 1;
  }
}