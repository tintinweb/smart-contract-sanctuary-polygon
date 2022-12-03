// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract PostStorage {
    string public currentMessage = "";
    string public currentDescription = "";

    event UpdatedDescription(string oldDescr, string newDescr);

    function storeNewMessage(string memory newMessage) public {
        currentMessage = newMessage;
    }

    function storeNewDescription(string memory newDescription) public {
        string memory oldDescr = getCurrentDescription();
        currentDescription = newDescription;
        emit UpdatedDescription(oldDescr, newDescription);
    }

    function getCurrentMessage() public view returns (string memory) {
        return currentMessage;
    }

    function getCurrentDescription() public view returns (string memory) {
        return currentDescription;
    }
}