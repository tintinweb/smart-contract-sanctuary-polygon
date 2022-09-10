/**
 *Submitted for verification at polygonscan.com on 2022-09-09
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract HelloWorld {
    // Events that allows for emitting a message
    event UpdatedMessages(string oldStr, string newStr);
    
    // Variables that stores message
    string public message;

    /**
     * @dev Main constructor with initiated message
     */
    constructor(string memory initMessage) {
      message = initMessage;
    }

    /**
     * @dev Function that updates message and emits an event with the old and new message
     */
    function update(string memory newMessage) public {
      string memory oldMsg = message;
      message = newMessage;
      emit UpdatedMessages(oldMsg, newMessage);
   }
}