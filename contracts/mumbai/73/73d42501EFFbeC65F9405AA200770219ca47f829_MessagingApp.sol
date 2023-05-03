// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract MessagingApp {
    struct User {
        string email;
        bool exists;
    }

    struct Message {
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

    mapping(address => User) userList;
    // mapping(bytes32 => Message[]) allMessages;
    Message[] public messages;
    mapping(string => address) userListByEmail;
    event MessageShared(uint256 messageId, address sender, address[] receivers);

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

    function sendMessage(address reciever, string calldata message) external {
        require(
            checkUserExists(msg.sender) == true,
            "You must have an account"
        );
        require(checkUserExists(reciever) == true, "Recipient does not exist");
        Message memory newMessage = Message(
            msg.sender,
            reciever,
            message,
            block.timestamp,
            false,
            true,
            0,
            0,
            new address[](0), 
            new address[](0));
        messages.push(newMessage);
    }
    function MessageSent(
        string memory email
    ) external view returns (Message[] memory) {
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

    function MessageRecieved(
        string memory email
    ) external view returns (Message[] memory) {
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

function shareMessage(uint256 messageId, address[] memory receivers) public {
    require(messages[messageId].shareable, "This message cannot be shared");
    messages[messageId].shares++;
    emit MessageShared(messageId, messages[messageId].sender, receivers);
    sendNotification(messages[messageId].sender, "Your message has been shared with other users.");
    for (uint i = 0; i < receivers.length; i++) {
        messages[messageId].sharedWith.push(receivers[i]);
        sendNotification(receivers[i], "You have received a shared message.");
    }
}


// function shareMessage(address receiver, string calldata message, address[] memory receivers) external {
//     Message memory newMessage = Message(
//         msg.sender,
//         receiver,
//         message,
//         block.timestamp,
//         false,
//         0,
//         0,
//         receivers,
//         new address[](0));
//     messages.push(newMessage);
//     emit MessageShared(messages.length - 1, msg.sender, receivers);
//     for (uint i = 0; i < receivers.length; i++) {
//         sendNotification(receivers[i], "You have received a shared message.");
//     }
// }

    function viewMessage(uint256 messageId) public {
        messages[messageId].views++;
        messages[messageId].viewedBy.push(msg.sender);
        sendNotification(messages[messageId].receiver, "Your message has been viewed by other users.");
    }

    function getSharedWith(uint256 messageId) public view returns (address[] memory) {
        return messages[messageId].sharedWith;
    }

    function getViewedBy(uint256 messageId) public view returns (address[] memory) {
        return messages[messageId].viewedBy;
    }
    function sendNotification(address user, string memory message) private {
        // implementation omitted for brevity
    }
}