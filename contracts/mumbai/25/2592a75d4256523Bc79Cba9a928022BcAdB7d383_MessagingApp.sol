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
//     function getSharedMessages(uint256 messageId) external view returns (MessageShared[] memory) {
//     require(checkUserExists(msg.sender) == true, "You must have an account");
//     uint256 sharedMessagesCount = 0;
//     for (uint256 i = 0; i < shares.length; i++) {
//         if (shares[i].messageId == messageId) {
//             sharedMessagesCount++;
//         }
//     }
//     MessageShared[] memory messageShares = new MessageShared[](sharedMessagesCount);
//     uint256 j = 0;
//     for (uint256 i = 0; i < shares.length; i++) {
//         if (shares[i].messageId == messageId) {
//             messageShares[j] = shares[i];
//             j++;
//         }
//     }
//     return messageShares;
// }

function readMessage(uint256 messageId) external {
    require(messageId < messages.length, "Invalid message ID");
    require(checkUserExists(msg.sender) == true, "You must have an account");
    Message storage messageToRead = messages[messageId];
    require(messageToRead.receiver == msg.sender, "You are not the receiver of this message");
    require(messageToRead.read == false, "Message already read");
    messageToRead.read = true;
    messageToRead.views++;
    messageToRead.viewedBy.push(msg.sender);
}

function getInbox() external view returns (Message[] memory) {
    require(checkUserExists(msg.sender) == true, "You must have an account");
    uint256 inboxSize = 0;
    for (uint256 i = 0; i < messages.length; i++) {
        if (messages[i].receiver == msg.sender) {
            inboxSize++;
        }
    }
    Message[] memory inbox = new Message[](inboxSize);
    uint256 j = 0;
    for (uint256 i = 0; i < messages.length; i++) {
        if (messages[i].receiver == msg.sender) {
            inbox[j] = messages[i];
            j++;
        }
    }
    return inbox;
}

function getSentMessages() external view returns (Message[] memory) {
    require(checkUserExists(msg.sender) == true, "You must have an account");
    uint256 sentMessagesCount = 0;
    for (uint256 i = 0; i < messages.length; i++) {
        if (messages[i].sender == msg.sender) {
            sentMessagesCount++;
        }
    }
    Message[] memory sentMessages = new Message[](sentMessagesCount);
    uint256 j = 0;
    for (uint256 i = 0; i < messages.length; i++) {
        if (messages[i].sender == msg.sender) {
            sentMessages[j] = messages[i];
            j++;
        }
    }
    return sentMessages;
}
}