// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract MessagingApp {
    struct User {
        string email;
        bool exists;
    }

    struct Message {
        uint256 id;
        address sender;
        address receiver;
        string message;
        uint256 timestamp;
        bool read;
        bool shareable;
        uint256 shares;
        uint256 views;
        address[] sharedWith;
        address[] viewedBy;
    }

    struct Share {
        uint256 messageId;
        uint256 timestamp;
        address sender;
        address receiver;
    }
    
    mapping(address => User) userList;
    Message[] public messages;
    mapping(string => address) userListByEmail;
    Share[] public shares;
    event MessageShared(uint256 shareId, uint256 messageId, address sender, address[] receivers);

    uint256 messageCount;
    uint256 shareCount;

    // CHECK USER EXISTS
    function checkUserExists(address user) public view returns (bool) {
        return bytes(userList[user].email).length > 0;
    }

    function createUser(string calldata email, address adresse) external {
        require(
            checkUserExists(adresse) == false,
            "Account with this email already exist"
        );
        require(bytes(email).length > 0, "email cannot be empty");
        User memory newUser = User(email, true);
        userList[adresse] = newUser;
        userListByEmail[email] = adresse;
    }

    function getEmail(address adresse) external view returns (string memory) {
        require(
            checkUserExists(adresse) == true,
            "User with given address don't exist"
        );
        return userList[adresse].email;
    }

    function getAddress(string memory emailAdd) public view returns (address) {
        return userListByEmail[emailAdd];
    }

    function sendMessage(address[] memory receivers, string calldata message, bool isShareable) external {
        require(
            checkUserExists(msg.sender) == true,
            "You must have an account"
        );
        
        for (uint i = 0; i < receivers.length; i++) {
            require(checkUserExists(receivers[i]), "Receiver does not exist");
            Message memory newMessage = Message(
                messageCount,
                msg.sender,
                receivers[i],
                message,
                block.timestamp,
                false,
                isShareable,
                0,
                0,
                receivers, 
                new address[](0)
            );
            messageCount++;
            messages.push(newMessage);
        }
    }
    
    function shareMessage(uint256 messageId, address[] calldata receivers) external {
        require(messageId < messages.length, "Invalid message ID");
        require(checkUserExists(msg.sender) == true, "You must have an account");
        Message storage messageToShare = messages[messageId];
        require(messageToShare.shareable == true, "Message is not shareable");

        // Update message shares
        for (uint256 i = 0; i < receivers.length; i++) {
            require(checkUserExists(receivers[i]), "Receiver does not exist");
            Share memory newShare = Share(messageId, block.timestamp, msg.sender, receivers[i]);
            shares.push(newShare);
            messageToShare.shares++;
            messageToShare.sharedWith.push(receivers[i]);
        }

        emit MessageShared(shareCount, messageId, msg.sender, receivers);
        shareCount++;
    }
function MessageSent(string memory email) public view returns (Message[] memory) {
        uint count = 0;
        for (uint i = 0; i < messages.length; i++) {
            if (messages[i].sender == getAddress(email)) {
                count++;
            }
        }
        Message[] memory messagesSent = new Message[](count);
        uint index = 0;
        for (uint i = 0; i < messages.length; i++) {
            if (messages[i].sender == getAddress(email)) {
                messagesSent[index] = messages[i];
                index++;
            }
        }
        return messagesSent;
    }

    function MessageReceived(
        string memory email
    ) public view returns (Message[] memory) {  
        uint count = 0;
        for (uint i = 0; i < messages.length; i++) {
            if (messages[i].receiver == getAddress(email)) {
                count++;
            }
        }
        Message[] memory messagesRecieved = new Message[](count);
        uint index = 0;
        for (uint i = 0; i < messages.length; i++) {
            if (messages[i].receiver == getAddress(email)) {
                messagesRecieved[index] = messages[i];
                index++;
            }
        }
        return messagesRecieved;
    }
    function getShares(uint256 messageId) external view returns (Share[] memory) {
        require(messageId < messages.length, "Invalid message ID");

        uint256 count = 0;
        for (uint256 i = 0; i < shares.length; i++) {
            if (shares[i].messageId == messageId) {
                count++;
            }
        }
        Share[] memory messageShares = new Share[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < shares.length; i++) {
            if (shares[i].messageId == messageId) {
                messageShares[index] = shares[i];
                index++;
            }
        }
        return messageShares;
    }


}