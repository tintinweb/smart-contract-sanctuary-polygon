/**
 *Submitted for verification at polygonscan.com on 2022-03-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleContract {

  uint private idCounter;
  mapping(uint => string) private messages;

  constructor() {
    idCounter = 0;
  }

  function setMessage(string memory message) public {
    idCounter++;
    messages[idCounter] = message;
  }

  function getMessage(uint x) public view returns (string memory) {
    return messages[x];
  }
}