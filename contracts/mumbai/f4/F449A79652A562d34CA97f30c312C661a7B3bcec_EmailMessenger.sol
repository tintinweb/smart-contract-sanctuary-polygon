// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract EmailMessenger {
    struct Message {
        address sender;
        string recipientEmail;
        bytes32 encryptedContent;
        bool isEncrypted;
    }

    struct UserAccount {
        address wallet;
        string email;
        bytes32 passwordHash;
        bool isRegistered;
    }

    mapping(string => Message[]) private inbox;
    mapping(address => UserAccount) private userAccounts;

    event MessageSent(
        address indexed sender,
        string recipientEmail,
        bytes32 encryptedContent
    );
    event MessageRead(
        address indexed reader,
        string senderEmail,
        bytes32 encryptedContent
    );

    function registerUser(string memory email, bytes32 passwordHash) public {
        require(!userAccounts[msg.sender].isRegistered, "User already registered");
        require(bytes(email).length != 0, "Email must not be empty");
        require(passwordHash != bytes32(0), "Password hash must not be empty");

        userAccounts[msg.sender] = UserAccount({
            wallet: msg.sender,
            email: email,
            passwordHash: passwordHash,
            isRegistered: true
        });
    }

    function sendMessage(
        string memory recipientEmail,
        bytes32 encryptedContent
    ) public {
        require(
            bytes(recipientEmail).length != 0,
            "Recipient email must not be empty"
        );

        Message memory newMessage = Message({
            sender: msg.sender,
            recipientEmail: recipientEmail,
            encryptedContent: encryptedContent,
            isEncrypted: true
        });

        inbox[recipientEmail].push(newMessage);

        emit MessageSent(msg.sender, recipientEmail, encryptedContent);
    }

    function readMessage(
        string memory senderEmail,
        uint index,
        bytes memory signature
    ) public {
        require(index < inbox[senderEmail].length, "Invalid index");

        Message storage message = inbox[senderEmail][index];
        require(message.isEncrypted, "Message is not encrypted");

        bytes32 hash = keccak256(abi.encodePacked(msg.sender));
        require(
            verifySignature(hash, signature, msg.sender),
            "Invalid signature"
        );

        emit MessageRead(msg.sender, senderEmail, message.encryptedContent);

        message.isEncrypted = false;
    }

    function getInboxLength(string memory email) public view returns (uint) {
        return inbox[email].length;
    }

    function getMessage(
        string memory email,
        uint index
    ) public view returns (address, string memory, bytes32, bool) {
        require(index < inbox[email].length, "Invalid index");

        Message memory message = inbox[email][index];
        return (
            message.sender,
            message.recipientEmail,
            message.encryptedContent,
            message.isEncrypted
        );
    }

    function getInbox(
        string memory email
    ) public view returns (Message[] memory) {
        return inbox[email];
    }

    function getLastMessage(
        string memory email
    ) public view returns (address, string memory, bytes32, bool) {
        uint inboxLength = getInboxLength(email);
        require(inboxLength > 0, "Inbox is empty");

        return getMessage(email, inboxLength - 1);
    }

    function verifySignature(
        bytes32 hash,
        bytes memory signature,
        address signer
    ) internal pure returns (bool) {
        bytes32 prefixedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(signature);
        return ecrecover(prefixedHash, v, r, s) == signer;
    }

    function splitSignature(
        bytes memory signature
    ) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        require(signature.length == 65, "Invalid signature length");

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
    }
}