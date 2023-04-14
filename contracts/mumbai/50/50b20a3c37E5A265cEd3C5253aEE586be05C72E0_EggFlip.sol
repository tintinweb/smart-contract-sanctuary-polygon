/**
 *Submitted for verification at polygonscan.com on 2023-04-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EggFlip {

  uint256 public consecutiveWins;
  uint nonce = 0;
  constructor() {
    consecutiveWins = 0;
  }

  function flip(uint _guess) public returns (bool) {
    uint randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % 3;
        //randomnumber = randomnumber + 100;
    nonce++;


    if (randomnumber == _guess) {
      consecutiveWins++;
      return true;
    } else {
      consecutiveWins = 0;
      return false;
    }
  }
}