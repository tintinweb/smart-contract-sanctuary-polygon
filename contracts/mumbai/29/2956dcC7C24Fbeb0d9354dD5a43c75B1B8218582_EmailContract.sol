// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EmailContract {
    struct Email {
        uint256 id;
        address sender;
        address recipient;
        string subject;
        string content;
        uint256 timestamp;
        bool read;
    }

    mapping(address => Email[]) private inbox;
    mapping(address => Email[]) private outbox;
    uint256 private emailIdCounter;

    event EmailSent(address indexed sender, address indexed recipient, string subject);

    mapping(address => bool) private loggedInUsers; // Track logged-in users

    function login() external {
        loggedInUsers[msg.sender] = true;
    }

    function logout() external {
        loggedInUsers[msg.sender] = false;
    }

    function isUserLoggedIn(address user) external view returns (bool) {
        return loggedInUsers[user];
    }

    function sendEmail(address recipient, string memory subject, string memory content) external {
        // Check if the sender is logged in
        require(loggedInUsers[msg.sender], "Sender is not logged in.");

        Email memory newEmail = Email({
            id: emailIdCounter,
            sender: msg.sender,
            recipient: recipient,
            subject: subject,
            content: content,
            timestamp: block.timestamp,
            read: false
        });

        inbox[recipient].push(newEmail);
        outbox[msg.sender].push(newEmail);
        emailIdCounter++;

        emit EmailSent(msg.sender, recipient, subject);
    }

    function getInbox() external view returns (Email[] memory) {
        // Check if the user is logged in
        require(loggedInUsers[msg.sender], "User is not logged in.");

        return inbox[msg.sender];
    }

}