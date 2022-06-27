/**
 *Submitted for verification at polygonscan.com on 2022-06-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Echo {    
    event Message(string indexed reciever, string message);
    event Identity(string indexed communicationAddress);

    function logMessage(string memory reciever_, string memory message_) external {
        emit Message(reciever_, message_);
    }

    function logIdentity(string memory communicationAddress_) external {
        emit Identity(communicationAddress_);
    }
}