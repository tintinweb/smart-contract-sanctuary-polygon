/**
 *Submitted for verification at polygonscan.com on 2022-03-27
*/

// SPDX-License-Identifier: None

pragma solidity >=0.8.9;

contract HelloWorld {
    event UpdatedMessages(string OldStr, string newStr);

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