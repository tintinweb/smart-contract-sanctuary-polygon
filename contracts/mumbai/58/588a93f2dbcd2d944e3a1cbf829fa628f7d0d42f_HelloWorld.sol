// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.18;

contract HelloWorld {
    event UpdatedMessages(string oldMessage, string newMessage);

    string public message;

    constructor(string memory newMessage) {
        message = newMessage;
    }

    function update(string memory newMessage) public {
        string memory oldMessage = message;
        message = newMessage;
        emit UpdatedMessages(oldMessage, newMessage);
    }
}