// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;
contract HelloWorld {
    event UpdatedMessages(string oldMsg, string newMsg);
    string public message;
    constructor(string memory initMessage) {
        message = initMessage;
    }
    function update(string memory newMessage) public {
        string memory oldMsg = message;
        message = newMessage;
        emit UpdatedMessages(oldMsg, newMessage);
    }
}