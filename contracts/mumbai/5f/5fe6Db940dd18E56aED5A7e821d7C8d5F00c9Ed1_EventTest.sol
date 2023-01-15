/**
 *Submitted for verification at polygonscan.com on 2023-01-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; //version

 contract EventTest {
    // Create an  transfer event 
    event transfer(address account, string _message);

    function testEvent(string memory _message) public {
        emit transfer(msg.sender, _message);
    }
}