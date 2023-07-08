/**
 *Submitted for verification at polygonscan.com on 2023-07-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EmailContract {
    struct Email {
        address sender;
        address recipient;
        string subject;
        string body;
        uint256 timestamp;
        bytes32 txId; // Added transaction ID field
    }

    mapping(address => Email[]) private inboxMapping;
    mapping(address => Email[]) private outboxMapping;
    mapping(address => uint256) private priceMapping;
    address private contractOwner;

    constructor() {
        contractOwner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only contract owner can access this function");
        _;
    }

    // Function to send an email
    function sendEmail(address recipient, string memory subject, string memory body) public payable {
        require(msg.value >= priceMapping[contractOwner], "Insufficient funds");

        Email memory email = Email({
            sender: msg.sender,
            recipient: recipient,
            subject: subject,
            body: body,
            timestamp: block.timestamp,
            txId: bytes32(0) // Initialize transaction ID as empty bytes32
        });

        inboxMapping[recipient].push(email);
        outboxMapping[msg.sender].push(email);

        // Store the transaction ID in the email struct
        email.txId = bytes32(block.timestamp); // Set transaction ID to a unique value (example: using block timestamp)
        
        inboxMapping[recipient][inboxMapping[recipient].length - 1] = email; // Update the email in the inbox with the transaction ID
        outboxMapping[msg.sender][outboxMapping[msg.sender].length - 1] = email; // Update the email in the outbox with the transaction ID

        payable(contractOwner).transfer(msg.value);
    }

    // Function to get inbox content
    function getInboxContent() public view returns (Email[] memory) {
        return inboxMapping[msg.sender];
    }

    // Function to get outbox content
    function getOutboxContent() public view returns (Email[] memory) {
        return outboxMapping[msg.sender];
    }

    // Function to set the price to send an email
    function setPrice(uint256 price) public onlyOwner {
        priceMapping[contractOwner] = price;
    }

    // Function to get the current price to send an email
    function getPrice() public view returns (uint256) {
        return priceMapping[contractOwner];
    }
}