// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestArg  {
  uint256 public minDelay;
  address[] public addresses;
  address[] public executors;

  constructor(uint256 _minDelay,
        address[] memory _addresses,
        address[] memory _executors) {
    minDelay = _minDelay;
    addresses = _addresses;
    executors = _executors;
  }
}