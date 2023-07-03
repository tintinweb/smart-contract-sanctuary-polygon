/**
 *Submitted for verification at polygonscan.com on 2023-07-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Messenger {
    uint256 public constant messageExpiration = 24 hours;

    struct User {
        string name;
        bool isRegistered;
        uint256 lastTransactionTimestamp;
        mapping(string => uint256) privateChatRoomIndex;
    }

    struct Message {
        string sender;
        string text;
        uint256 timestamp;
    }

    struct ChatRoom {
        address creator;
        uint256 maxParticipants;
        string password;
        string[] participants;
        mapping(string => bool) isParticipant;
        Message[] messages;
    }

    mapping(address => User) public users;
    mapping(uint256 => ChatRoom) private chatRooms;
    uint256 private chatRoomCount;
    Message[] public publicChatMessages;

    event UserRegistered(address indexed userAddress, string name);
    event PrivateMessageSent(string indexed sender, string indexed recipient, string text);
    event PublicMessageSent(string indexed sender, string text);
    event JoinedChatRoom(string indexed user, uint256 indexed chatRoomIndex);
    event AddedParticipant(address indexed creator, uint256 indexed chatRoomIndex, string indexed participant);

    constructor() {
        // Set the initial last transaction timestamp to contract deployment time
        users[msg.sender].lastTransactionTimestamp = block.timestamp;
    }

    function registerUser(string memory _name) external {
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(!users[msg.sender].isRegistered, "User already registered");

        users[msg.sender].name = _name;
        users[msg.sender].isRegistered = true;

        emit UserRegistered(msg.sender, _name);
    }

    function createChatRoom(uint256 _maxParticipants, string memory _password) external {
        require(_maxParticipants > 0, "Invalid max participants");
        require(bytes(_password).length > 0, "Password cannot be empty");

        chatRoomCount++;
        ChatRoom storage chatRoom = chatRooms[chatRoomCount];
        chatRoom.creator = msg.sender;
        chatRoom.maxParticipants = _maxParticipants;
        chatRoom.password = _password;
        chatRoom.isParticipant[users[msg.sender].name] = true;
        chatRoom.participants.push(users[msg.sender].name);

        emit JoinedChatRoom(users[msg.sender].name, chatRoomCount);
    }

    function addParticipant(uint256 _chatRoomIndex, string memory _participant, string memory _password) external {
        require(_chatRoomIndex > 0 && _chatRoomIndex <= chatRoomCount, "Invalid chat room index");
        require(users[msg.sender].privateChatRoomIndex[users[msg.sender].name] == 0, "Participant is already in a private chat room");

        ChatRoom storage chatRoom = chatRooms[_chatRoomIndex];
        require(chatRoom.creator != address(0), "Chat room does not exist");
        require(chatRoom.participants.length < chatRoom.maxParticipants, "Chat room is full");
        require(keccak256(bytes(chatRoom.password)) == keccak256(bytes(_password)), "Invalid password");

        chatRoom.participants.push(_participant);
        chatRoom.isParticipant[_participant] = true;
        users[msg.sender].privateChatRoomIndex[_participant] = _chatRoomIndex;

        emit AddedParticipant(msg.sender, _chatRoomIndex, _participant);
    }

    function joinChatRoom(uint256 _chatRoomIndex, string memory _password) external {
        require(_chatRoomIndex > 0 && _chatRoomIndex <= chatRoomCount, "Invalid chat room index");
        require(users[msg.sender].privateChatRoomIndex[users[msg.sender].name] == 0, "Already joined private chat room");

        ChatRoom storage chatRoom = chatRooms[_chatRoomIndex];
        require(chatRoom.creator != address(0), "Chat room does not exist");
        require(keccak256(bytes(chatRoom.password)) == keccak256(bytes(_password)), "Invalid password");

        chatRoom.participants.push(users[msg.sender].name);
        chatRoom.isParticipant[users[msg.sender].name] = true;
        users[msg.sender].privateChatRoomIndex[users[msg.sender].name] = _chatRoomIndex;

        emit JoinedChatRoom(users[msg.sender].name, _chatRoomIndex);
    }

    function sendPublicMessage(string memory _text) external {
        require(bytes(_text).length > 0, "Message text cannot be empty");

        Message memory message = Message(users[msg.sender].name, _text, block.timestamp);
        publicChatMessages.push(message);

        // Update the last transaction timestamp for the sender
        users[msg.sender].lastTransactionTimestamp = block.timestamp;

        emit PublicMessageSent(users[msg.sender].name, _text);
    }

    function sendPrivateMessage(uint256 _chatRoomIndex, string memory _text, string memory _password) external {
    require(users[msg.sender].isRegistered, "User is not registered");
    require(bytes(_text).length > 0, "Message text cannot be empty");

    ChatRoom storage chatRoom = chatRooms[_chatRoomIndex];
    require(chatRoom.creator != address(0), "Chat room does not exist");
    require(keccak256(bytes(chatRoom.password)) == keccak256(bytes(_password)), "Invalid password");
    require(chatRoom.isParticipant[users[msg.sender].name], "You are not a participant in this private chat room");

    Message memory message = Message(users[msg.sender].name, _text, block.timestamp);
    chatRoom.messages.push(message);

    // Update the last transaction timestamp for the sender
    users[msg.sender].lastTransactionTimestamp = block.timestamp;

    emit PrivateMessageSent(users[msg.sender].name, "", _text);
}

    function getPrivateChatMessages(uint256 _chatRoomIndex, string memory _password) external view returns (Message[] memory) {
        require(_chatRoomIndex > 0 && _chatRoomIndex <= chatRoomCount, "Invalid chat room index");

        ChatRoom storage chatRoom = chatRooms[_chatRoomIndex];
        require(chatRoom.creator != address(0), "Chat room does not exist");
        require(keccak256(bytes(chatRoom.password)) == keccak256(bytes(_password)), "Invalid password");
        require(chatRoom.isParticipant[users[msg.sender].name], "You are not a participant in this private chat room");

        return chatRoom.messages;
    }

    function getPublicChatMessages() external view returns (Message[] memory) {
        return publicChatMessages;
    }

    function cleanupMessages() external {
        for (uint256 i = 1; i <= chatRoomCount; i++) {
            Message[] storage messages = chatRooms[i].messages;
            uint256 j = 0;

            while (j < messages.length) {
                if (messages[j].timestamp < block.timestamp - messageExpiration) {
                    delete messages[j];
                } else {
                    break;
                }
                j++;
            }
        }
    }
}