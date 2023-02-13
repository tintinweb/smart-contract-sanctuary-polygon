// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HelloWorld {
    string public message;

    function update(string memory newMessage) public {
        message = newMessage;
    }
}