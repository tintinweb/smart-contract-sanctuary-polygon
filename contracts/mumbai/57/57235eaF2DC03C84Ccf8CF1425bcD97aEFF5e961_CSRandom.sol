// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract CSRandom {
  address private immutable wmaticAddress = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

  constructor() {

  }

  function randomGenerator() public view returns(uint) {
    return address(wmaticAddress).balance;
    // return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, players)));
  }
}