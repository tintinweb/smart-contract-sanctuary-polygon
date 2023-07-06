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

    function sendEmail(address recipient, string memory subject, string memory content) external {
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

    function getInbox(address user) external view returns (Email[] memory) {
        return inbox[user];
    }

    function getOutbox(address user) external view returns (Email[] memory) {
        return outbox[user];
    }

    function markEmailAsRead(address user, uint256 emailId) external {
        uint256 inboxLength = inbox[user].length;
        for (uint256 i = 0; i < inboxLength; i++) {
            if (inbox[user][i].id == emailId) {
                inbox[user][i].read = true;
                break;
            }
        }
    }

    function convertTimestamp(uint256 timestamp) public pure returns (string memory) {
        uint256 secondsInMinute = 60;
        uint256 secondsInHour = 60 * secondsInMinute;
        uint256 secondsInDay = 24 * secondsInHour;

        uint256 day = timestamp / secondsInDay;
        uint256 hour = (timestamp % secondsInDay) / secondsInHour;
        uint256 minute = (timestamp % secondsInHour) / secondsInMinute;
        uint256 second = timestamp % secondsInMinute;

        string memory timeString = string(
            abi.encodePacked(
                day, " day, ",
                hour, " hour, ",
                minute, " minute, ",
                second, " second"
            )
        );

        return timeString;
    }
}