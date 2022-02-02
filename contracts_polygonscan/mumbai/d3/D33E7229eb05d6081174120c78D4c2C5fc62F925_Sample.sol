// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Sample {
  uint public rndCounter;
  uint[] public arr;

  function getNumbers() public {
    for (uint i = 0; i < 10; i++) {
      arr.push(getRandomNumber(50));
    }
  }

  function getRandomNumber(uint _num) public returns (uint) {
    if (rndCounter >= 1000) rndCounter = 0;
    else rndCounter++;
    return uint(uint(keccak256(abi.encodePacked(block.timestamp, rndCounter))) % _num);
  }
}