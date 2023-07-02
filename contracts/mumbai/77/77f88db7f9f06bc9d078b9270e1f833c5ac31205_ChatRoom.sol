/**
 *Submitted for verification at polygonscan.com on 2023-07-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract ChatRoom {
    struct UserProfile {
        string username;
        bool isRegistered;
        mapping(bytes32 => bool) joinedChats;
    }

    struct Chat {
        string chatName;
        address creator;
        uint256 entryFee;
        Message[] messages;
        mapping(address => uint256) userMessageCount;
        mapping(address => bool) hasPaidEntryFee;
    }

    struct Message {
        string content;
        address sender;
        uint256 timestamp;
    }

    mapping(address => UserProfile) public userProfiles;
    mapping(bytes32 => Chat) public chats;

    event MessageSent(bytes32 chatId, address sender, string content, uint256 timestamp);
    event ChatCreated(bytes32 chatId, string chatName, address creator, uint256 entryFee);
    event UserRegistered(address user, string username);
    event EntryFeePaid(bytes32 chatId, address user);
    event UserJoinedChat(bytes32 chatId, address user);
    event UserLeftChat(bytes32 chatId, address user);
    event ChatDeleted(bytes32 chatId);

    modifier isRegistered() {
        require(userProfiles[msg.sender].isRegistered, "User is not registered");
        _;
    }

    function registerUser(string calldata _username) external {
        require(!userProfiles[msg.sender].isRegistered, "User is already registered");
        require(bytes(_username).length > 0, "Username cannot be empty");

        userProfiles[msg.sender].username = _username;
        userProfiles[msg.sender].isRegistered = true;

        emit UserRegistered(msg.sender, _username);
    }

    function sendMessage(bytes32 _chatId, string calldata _content) external isRegistered {
        require(bytes(_content).length > 0, "Message content cannot be empty");
        require(userProfiles[msg.sender].joinedChats[_chatId], "User is not a member of the chat");

        Chat storage chat = chats[_chatId];
        chat.messages.push(Message(_content, msg.sender, block.timestamp));
        chat.userMessageCount[msg.sender]++;

        if (chat.messages.length > 50) {
            delete chat.messages[chat.messages.length - 51];
        }

        emit MessageSent(_chatId, msg.sender, _content, block.timestamp);
    }

    function createChat(bytes32 _chatId, string calldata _chatName, uint256 _entryFee) external isRegistered {
        require(chats[_chatId].creator == address(0), "Chat already exists");

        chats[_chatId].chatName = _chatName;
        chats[_chatId].creator = msg.sender;
        chats[_chatId].entryFee = _entryFee;

        emit ChatCreated(_chatId, _chatName, msg.sender, _entryFee);
    }

    function joinChat(bytes32 _chatId) external payable isRegistered {
        Chat storage chat = chats[_chatId];
        require(chat.creator != address(0), "Chat does not exist");
        require(!userProfiles[msg.sender].joinedChats[_chatId], "User is already a member of the chat");

        if (chat.entryFee > 0) {
            require(msg.value == chat.entryFee, "Incorrect entry fee");
            chat.hasPaidEntryFee[msg.sender] = true;
            emit EntryFeePaid(_chatId, msg.sender);
        }

        userProfiles[msg.sender].joinedChats[_chatId] = true;

        emit UserJoinedChat(_chatId, msg.sender);
    }

    function leaveChat(bytes32 _chatId) external {
        require(userProfiles[msg.sender].joinedChats[_chatId], "User is not a member of the chat");

        delete userProfiles[msg.sender].joinedChats[_chatId];

        emit UserLeftChat(_chatId, msg.sender);
    }

    function getChatMessages(bytes32 _chatId, uint256 _start, uint256 _count) external view returns (Message[] memory) {
        Chat storage chat = chats[_chatId];
        require(chat.creator != address(0), "Chat does not exist");
        require(userProfiles[msg.sender].joinedChats[_chatId], "User is not a member of the chat");

        uint256 totalMessages = chat.messages.length;
        uint256 end = (_start + _count) > totalMessages ? totalMessages : (_start + _count);

        Message[] memory result = new Message[](_count);
        uint256 resultIndex = 0;

        for (uint256 i = _start; i < end; i++) {
            result[resultIndex] = chat.messages[i];
            resultIndex++;
        }

        return result;
    }

    function deleteChat(bytes32 _chatId) external {
        require(chats[_chatId].creator == msg.sender, "Only the chat creator can delete the chat");

        delete chats[_chatId];

        emit ChatDeleted(_chatId);
    }
}