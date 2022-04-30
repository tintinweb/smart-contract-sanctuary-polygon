/**
 *Submitted for verification at polygonscan.com on 2022-04-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract PrintMessage {
  string public message;

  function storeMessage(string memory _message) public {
      message = _message;
  }

  function retrieveMessage() public view returns (string memory) {
      return message;
  }
}