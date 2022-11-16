// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// import "hardhat/console.sol";

contract MessageToken {
    mapping(address => mapping(address => string[])) messages;

    event Message(address indexed from, address indexed to, string message);

    function send(address to, string calldata message) public {
        messages[msg.sender][to].push(message);

        emit Message(msg.sender, to, message);
    }

    function getMessagesTo(address to) public view returns (string[] memory) {
        return messages[msg.sender][to];
    }
}