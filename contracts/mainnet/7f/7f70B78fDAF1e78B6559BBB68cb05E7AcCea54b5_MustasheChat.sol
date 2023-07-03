/**
 *Submitted for verification at polygonscan.com on 2023-07-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract MustasheChat {
    uint256 public constant messageExpiration = 24 hours;
    uint256 public constant maxChatMessages = 100;

    struct User {
        string name;
        bool isRegistered;
        uint256 lastTransactionTimestamp;
    }

    struct Message {
        string sender;
        string text;
        uint256 timestamp;
    }

    mapping(address => User) public users;
    mapping(string => bool) private registeredNames;
    Message[] public publicChatMessages;
    address private contractOwner;

    event UserRegistered(address indexed userAddress, string name);
    event PublicMessageSent(string indexed sender, string text);

    constructor() {
        contractOwner = msg.sender;
        // Set the initial last transaction timestamp to contract deployment time
        users[msg.sender].lastTransactionTimestamp = block.timestamp;
    }

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only contract owner can call this function");
        _;
    }

    function registerUser(string memory _name) external {
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(!users[msg.sender].isRegistered, "User already registered");
        require(!registeredNames[_name], "Name is already registered");

        users[msg.sender].name = _name;
        users[msg.sender].isRegistered = true;
        registeredNames[_name] = true;

        emit UserRegistered(msg.sender, _name);
    }

    function sendPublicMessage(string memory _text) external {
        require(bytes(_text).length > 0, "Message text cannot be empty");
        require(users[msg.sender].isRegistered, "User is not registered");

        Message memory message = Message(users[msg.sender].name, _text, block.timestamp);
        publicChatMessages.push(message);

        // Update the last transaction timestamp for the sender
        users[msg.sender].lastTransactionTimestamp = block.timestamp;

        emit PublicMessageSent(users[msg.sender].name, _text);

        // Check if the number of messages exceeds the maximum limit
        if (publicChatMessages.length > maxChatMessages) {
            // Calculate the number of messages to be deleted
            uint256 deleteCount = publicChatMessages.length - maxChatMessages;

            // Delete the oldest messages
            for (uint256 i = 0; i < deleteCount; i++) {
                delete publicChatMessages[i];
            }

            // Shift the remaining messages to fill the deleted slots
            for (uint256 i = deleteCount; i < publicChatMessages.length; i++) {
                publicChatMessages[i - deleteCount] = publicChatMessages[i];
            }

            // Resize the array to remove the empty slots
            publicChatMessages.pop();
        }
    }

    function getPublicChatMessages() external view returns (Message[] memory) {
        return publicChatMessages;
    }

    function cleanupMessages() external onlyOwner {
        delete publicChatMessages;
    }
}