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

function getInbox(uint256 startIndex, uint256 endIndex) external view returns (Email[] memory) {
    require(inbox[msg.sender].length > 0, "No emails found in the inbox.");
    require(startIndex <= endIndex, "Invalid range.");

    uint256 inboxLength = inbox[msg.sender].length;
    require(endIndex < inboxLength, "End index exceeds inbox length.");

    uint256 range = endIndex - startIndex + 1;
    Email[] memory userInbox = new Email[](range);

    for (uint256 i = 0; i < range; i++) {
        uint256 emailIndex = startIndex + i;
        userInbox[i] = inbox[msg.sender][emailIndex];
    }

    return userInbox;
}



function getOutbox() external view returns (Email[] memory) {
    require(outbox[msg.sender].length > 0, "No emails found in the outbox.");
    Email[] memory userOutbox = new Email[](outbox[msg.sender].length);
    for (uint256 i = 0; i < outbox[msg.sender].length; i++) {
        userOutbox[i] = outbox[msg.sender][i];
    }
    return userOutbox;
}


function convertTimestamp(uint256 timestamp) public pure returns (string memory) {
    uint256 secondsInMinute = 60;
    uint256 secondsInHour = 60 * secondsInMinute;
    uint256 secondsInDay = 24 * secondsInHour;

    uint256 day = timestamp / secondsInDay;
    uint256 hour = (timestamp % secondsInDay) / secondsInHour;
    uint256 minute = (timestamp % secondsInHour) / secondsInMinute;
    uint256 second = timestamp % secondsInMinute;

    string memory dayString = day > 1 ? " days, " : " day, ";
    string memory hourString = hour > 1 ? " hours, " : " hour, ";
    string memory minuteString = minute > 1 ? " minutes, " : " minute, ";
    string memory secondString = second > 1 ? " seconds" : " second";

    string memory timeString = string(
        abi.encodePacked(
            day, dayString,
            hour, hourString,
            minute, minuteString,
            second, secondString
        )
    );

    return timeString;
}

    function markEmailAsRead(uint256 emailId) external {
        uint256 inboxLength = inbox[msg.sender].length;
        for (uint256 i = 0; i < inboxLength; i++) {
            if (inbox[msg.sender][i].id == emailId) {
                inbox[msg.sender][i].read = true;
                break;
            }
        }
    }
}