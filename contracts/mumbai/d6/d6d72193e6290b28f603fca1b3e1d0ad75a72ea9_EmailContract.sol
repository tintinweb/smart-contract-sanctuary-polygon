// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EmailContract {
    struct Email {
        address sender;
        address recipient;
        string encryptedSubject;
        string encryptedBody;
        uint256 timestamp;
    }

    mapping(address => Email[]) private inboxMapping;
    mapping(address => Email[]) private outboxMapping;
    mapping(address => uint256) private priceMapping;
    address private contractOwner;
    mapping(address => mapping(address => string)) private secretKeys;

    constructor() {
        contractOwner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only contract owner can access this function");
        _;
    }

    // Function to encrypt data using AES
    function encryptAES(string memory text, string memory key) private pure returns (string memory) {
        bytes32 keyHash = keccak256(abi.encodePacked(key));
        bytes memory inputBytes = bytes(text);
        uint256 len = inputBytes.length;
        uint256 lenPadded = len + (16 - len % 16);
        bytes memory paddedBytes = new bytes(lenPadded);
        for (uint256 i = 0; i < len; i++) {
            paddedBytes[i] = inputBytes[i];
        }
        for (uint256 i = len; i < lenPadded; i++) {
            paddedBytes[i] = 0;
        }
        bytes memory encryptedBytes = new bytes(lenPadded);
        for (uint256 i = 0; i < lenPadded; i += 16) {
            for (uint256 j = 0; j < 16; j++) {
                encryptedBytes[i + j] = paddedBytes[i + j] ^ keyHash[j];
            }
        }
        return string(encryptedBytes);
    }

    // Function to decrypt data using AES
    function decryptAES(string memory encryptedText, string memory key) private pure returns (string memory) {
        bytes32 keyHash = keccak256(abi.encodePacked(key));
        bytes memory encryptedBytes = bytes(encryptedText);
        uint256 len = encryptedBytes.length;
        bytes memory decryptedBytes = new bytes(len);
        for (uint256 i = 0; i < len; i += 16) {
            for (uint256 j = 0; j < 16; j++) {
                decryptedBytes[i + j] = encryptedBytes[i + j] ^ keyHash[j];
            }
        }
        uint256 lastNullByte;
        for (uint256 i = len - 1; i >= 0; i--) {
            if (decryptedBytes[i] != 0) {
                lastNullByte = i;
                break;
            }
        }
        bytes memory finalBytes = new bytes(lastNullByte + 1);
        for (uint256 i = 0; i <= lastNullByte; i++) {
            finalBytes[i] = decryptedBytes[i];
        }
        return string(finalBytes);
    }

    // Function to send an email
    function sendEmail(address recipient, string memory subject, string memory body, string memory key) public payable {
        require(msg.value >= priceMapping[contractOwner], "Insufficient funds");

        string memory encryptedSubject = encryptAES(subject, key);
        string memory encryptedBody = encryptAES(body, key);

        Email memory email = Email({
            sender: msg.sender,
            recipient: recipient,
            encryptedSubject: encryptedSubject,
            encryptedBody: encryptedBody,
            timestamp: block.timestamp
        });

        inboxMapping[recipient].push(email);
        outboxMapping[msg.sender].push(email);

        secretKeys[msg.sender][recipient] = key; // Store the shared key between sender and recipient

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

    // Function to decrypt the subject and body of the email
    function decryptEmailContent(uint256 emailIndex) public view returns (string memory decryptedSubject, string memory decryptedBody) {
        Email memory email = inboxMapping[msg.sender][emailIndex];

        string memory sharedKey = secretKeys[email.sender][email.recipient];
        decryptedSubject = decryptAES(email.encryptedSubject, sharedKey);
        decryptedBody = decryptAES(email.encryptedBody, sharedKey);
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