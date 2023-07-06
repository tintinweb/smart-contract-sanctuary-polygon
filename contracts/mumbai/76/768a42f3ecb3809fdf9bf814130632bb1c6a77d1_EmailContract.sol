// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EmailContract {
    struct Email {
        address sender;
        address recipient;
        string subject;
        string content;
        bool sent;
    }

    mapping(address => Email[]) private inbox;
    mapping(address => Email[]) private outbox;
    mapping(address => uint256) private prices;
    address private contractOwner;

    event EmailSent(address indexed sender, address indexed recipient, string subject);

    constructor() {
        contractOwner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only contract owner can call this function");
        _;
    }

    function sendEmail(address recipient, string memory subject, string memory content) public payable {
        require(msg.value >= prices[msg.sender], "Insufficient payment to send email");
        
        Email memory email = Email({
            sender: msg.sender,
            recipient: recipient,
            subject: subject,
            content: content,
            sent: true
        });
        
        inbox[recipient].push(email);
        outbox[msg.sender].push(email);

        emit EmailSent(msg.sender, recipient, subject);
        
        // Transfer payment to contract owner
        payable(contractOwner).transfer(msg.value);
    }

function getInbox(address walletAddress) public view returns (Email[] memory) {
    return inbox[walletAddress];
}

function getOutbox(address walletAddress) public view returns (Email[] memory) {
    return outbox[walletAddress];
}

    function setPrice(uint256 price) public onlyOwner {
        prices[msg.sender] = price;
    }

    function getPrice(address sender) public view returns (uint256) {
        return prices[sender];
    }
}