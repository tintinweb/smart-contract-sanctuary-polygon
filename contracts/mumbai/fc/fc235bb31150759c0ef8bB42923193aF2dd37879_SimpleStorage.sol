// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.9.0;

contract SimpleStorage {
  uint storedData;
  uint cat;

  function set(uint x) public {
    storedData = x;
  }

  function get() public view returns (uint) {
    return storedData;
  }
}