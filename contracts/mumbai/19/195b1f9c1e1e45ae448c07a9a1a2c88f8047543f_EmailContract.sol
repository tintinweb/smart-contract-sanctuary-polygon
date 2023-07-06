// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EmailContract {
    struct Email {
        string subject;
        string content;
        bool isSent;
    }

    mapping(address => Email[]) public inboxes;
    mapping(address => Email[]) public outboxes;

    event EmailSent(address indexed sender, address indexed recipient, string subject, string content);

    modifier onlySenderAndRecipient(address recipient) {
        require(msg.sender == recipient || msg.sender == owner(), "Access denied");
        _;
    }

    function sendEmail(address recipient, string memory subject, string memory content) public onlySenderAndRecipient(recipient) {
        Email memory newEmail = Email(subject, content, true);
        inboxes[recipient].push(newEmail);
        outboxes[msg.sender].push(newEmail);
        emit EmailSent(msg.sender, recipient, subject, content);
    }

    function getInbox(address recipient) public view onlySenderAndRecipient(recipient) returns (Email[] memory) {
        return inboxes[recipient];
    }

    function getOutbox(address sender) public view onlySenderAndRecipient(sender) returns (Email[] memory) {
        return outboxes[sender];
    }

    function owner() internal view returns (address) {
        return address(this);
    }
}