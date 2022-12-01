// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract PostStorage {
    string public currentMessage = "";
    string public currentDescription = "";

    function storeNewMessage(string memory newMessage) public {
        currentMessage = newMessage;
    }

    function storeNewDescription(string memory newDescription) public {
        currentDescription = newDescription;
    }

    function getCurrentMessage() public view returns (string memory) {
        return currentMessage;
    }

    function getCurrentDescription() public view returns (string memory) {
        return currentDescription;
    }
}