/**
 *Submitted for verification at polygonscan.com on 2023-01-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; //version

 contract EventTest {
    // Create an  transfer event 
    string public mesage  = "aa";
    event transfer(address account, string message);
    

    function testEvent(string memory _message) public {
        mesage = _message;
        emit transfer(msg.sender, _message);
    }
}