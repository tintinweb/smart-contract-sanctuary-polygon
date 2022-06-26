/**
 *Submitted for verification at polygonscan.com on 2022-06-25
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Echo {

    uint256 public number = 5;
    
    event Message(address indexed reciever, string message);
    event Identity(address indexed communicationAddress, address indexed identityAddress);

    function logMessage(address reciever_, string memory message_) external {
        emit Message(reciever_, message_);
    }

    function logIdentity(address communicationAddress_, address identityAddress_) external {
        emit Identity(communicationAddress_, identityAddress_);
    }
}