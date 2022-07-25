/**
 *Submitted for verification at polygonscan.com on 2022-07-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

contract HelloWorld2 {

   event UpdatedMessages(string oldStr, string newStr, uint totalChanges);

   string public message;
   uint private _totalChanges = 0;

   constructor(string memory initMessage) {
      message = initMessage;
   }

   // A public function that accepts a string argument and updates the `message` storage variable.
   function update(string memory newMessage) public {
      string memory oldMsg = message;
      message = newMessage;
      _totalChanges += 1;
      emit UpdatedMessages(oldMsg, newMessage, _totalChanges);
   }
}