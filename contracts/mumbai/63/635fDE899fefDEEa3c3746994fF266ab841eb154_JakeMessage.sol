// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract JakeMessage {
    string public message;
    address payable public owner;

    constructor(string memory _message) {
        message = _message;
        owner = payable(msg.sender);
    }

    function setMessage(string calldata _message) public {
        require(msg.sender == owner, "You are not the owner");
        message = _message;
    }

}