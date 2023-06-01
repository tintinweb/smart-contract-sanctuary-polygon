// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract JakeMessage {
    bytes32 public message;
    address payable public owner;

    constructor(bytes32 _message) {
        message = _message;
        owner = payable(msg.sender);
    }

    function getMessage() public view returns (bytes32) {
        return message;
    }

    function setMessage(bytes32 _message) public {
        require(msg.sender == owner, "You aren't the owner");
        message = _message;
    }

}