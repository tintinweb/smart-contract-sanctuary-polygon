/**
 *Submitted for verification at polygonscan.com on 2022-03-14
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract HelloWorld {
  string public message;
  string public message2;

  constructor(string memory initialMessage) {
    message = initialMessage;
  }

  function updateMessage(string memory newMessage) public {
    message = newMessage;
  }
}