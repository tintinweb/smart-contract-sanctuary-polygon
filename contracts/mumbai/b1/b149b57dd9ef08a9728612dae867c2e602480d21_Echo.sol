/**
 *Submitted for verification at polygonscan.com on 2022-06-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Echo {    
    event Message(address indexed reciever, string message);
    event Identity(address indexed communicationAddress);

    function logMessage(address reciever_, string memory message_) external {
        emit Message(reciever_, message_);
    }

    function logIdentity(address communicationAddress_) external {
        emit Identity(communicationAddress_);
    }
}