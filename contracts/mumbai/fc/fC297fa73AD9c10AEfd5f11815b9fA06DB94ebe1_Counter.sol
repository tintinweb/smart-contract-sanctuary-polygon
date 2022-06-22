// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Counter {
  uint256 count = 0;

  function increment() public {
    count++;
  }

  function getCount() external view returns(uint256) {
    return count;
  }
}