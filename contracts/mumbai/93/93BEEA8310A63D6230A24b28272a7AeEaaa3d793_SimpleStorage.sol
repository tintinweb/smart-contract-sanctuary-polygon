/**
 *Submitted for verification at polygonscan.com on 2022-02-04
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

contract SimpleStorage {
  uint storedData;

  event CounterUpdated(uint newCount);
  function set(uint x) public {
    storedData = x;
    emit CounterUpdated(x);
  }

  function get() public view returns (uint) {
    return storedData;
  }
}