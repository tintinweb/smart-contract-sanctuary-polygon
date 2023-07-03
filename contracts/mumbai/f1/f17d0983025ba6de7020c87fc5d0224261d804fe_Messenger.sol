/**
 *Submitted for verification at polygonscan.com on 2023-07-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Messenger {
    uint256 public constant messageExpiration = 24 hours;
    uint256 public constant maxPublicMessages = 100;

    struct User {
        string name;
        bool isRegistered;
        uint256 lastTransactionTimestamp;
        mapping(uint256 => address[]) privateChatRooms;
        mapping(address => uint256) privateChatRoomIndex;
    }

    struct Message {
        address sender;
        string text;
        uint256 timestamp;
    }

    struct ChatRoom {
        address[] participants;
        Message[] messages;
    }

    mapping(address => User) public users;
    mapping(uint256 => ChatRoom) private chatRooms;
    uint256 private chatRoomCount;
    Message[] public publicChatMessages;

    event UserRegistered(address indexed userAddress, string name);
    event PrivateMessageSent(address indexed sender, address indexed recipient, string text);
    event PublicMessageSent(address indexed sender, string text);
    event JoinedChatRoom(address indexed user, uint256 indexed chatRoomIndex);

    modifier canSendMessage(address _user) {
        require(users[_user].isRegistered, "User is not registered");
        require(
            block.timestamp > users[_user].lastTransactionTimestamp + messageExpiration,
            "Message sending is restricted at the moment"
        );
        _;
    }

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

    function sendSignedMessage(address _recipient, string memory _text, bytes memory _signature) external canSendMessage(msg.sender) {
        require(users[_recipient].isRegistered, "Recipient is not registered");
        require(bytes(_text).length > 0, "Message text cannot be empty");

        // Verify the signature
        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender, _recipient, _text));
        require(recoverSigner(messageHash, _signature) == msg.sender, "Invalid signature");

        Message memory message = Message(msg.sender, _text, block.timestamp);
        uint256 chatRoomIndex = users[msg.sender].privateChatRoomIndex[_recipient];

        if (chatRoomIndex == 0) {
            // Create new private chat room if it doesn't exist
            chatRoomCount++;
            chatRoomIndex = chatRoomCount;
            users[msg.sender].privateChatRooms[chatRoomIndex].push(msg.sender);
            users[msg.sender].privateChatRooms[chatRoomIndex].push(_recipient);
            users[_recipient].privateChatRooms[chatRoomIndex].push(msg.sender);
            users[_recipient].privateChatRooms[chatRoomIndex].push(_recipient);
            users[msg.sender].privateChatRoomIndex[_recipient] = chatRoomIndex;
            users[_recipient].privateChatRoomIndex[msg.sender] = chatRoomIndex;
            emit JoinedChatRoom(msg.sender, chatRoomIndex);
            emit JoinedChatRoom(_recipient, chatRoomIndex);
        }

        ChatRoom storage chatRoom = chatRooms[chatRoomIndex];
        chatRoom.messages.push(message);

        // Update the last transaction timestamp for the sender
        users[msg.sender].lastTransactionTimestamp = block.timestamp;

        emit PrivateMessageSent(msg.sender, _recipient, _text);
    }

    function sendUnsignedMessage(address _recipient, string memory _text) external canSendMessage(msg.sender) {
        require(users[_recipient].isRegistered, "Recipient is not registered");
        require(bytes(_text).length > 0, "Message text cannot be empty");

        uint256 chatRoomIndex = users[msg.sender].privateChatRoomIndex[_recipient];
        require(chatRoomIndex != 0, "Private chat room does not exist");

        Message memory message = Message(msg.sender, _text, block.timestamp);
        ChatRoom storage chatRoom = chatRooms[chatRoomIndex];
        chatRoom.messages.push(message);

        // Update the last transaction timestamp for the sender
        users[msg.sender].lastTransactionTimestamp = block.timestamp;

        emit PrivateMessageSent(msg.sender, _recipient, _text);
    }

    function getPrivateChatMessages(address _counterparty) external view returns (Message[] memory) {
        require(users[msg.sender].isRegistered, "User is not registered");
        require(users[_counterparty].isRegistered, "Counterparty is not registered");

        uint256 chatRoomIndex = users[msg.sender].privateChatRoomIndex[_counterparty];
        require(chatRoomIndex != 0, "Private chat room does not exist");

        return chatRooms[chatRoomIndex].messages;
    }

    function getPublicChatMessages() external view returns (Message[] memory) {
        return publicChatMessages;
    }

    function cleanupMessages() external {
        Message[] storage messages = publicChatMessages;
        uint256 i = 0;

        while (i < messages.length) {
            if (messages[i].timestamp < block.timestamp - messageExpiration) {
                delete messages[i];
            } else {
                break;
            }
            i++;
        }
    }

    function recoverSigner(bytes32 _messageHash, bytes memory _signature) private pure returns (address) {
        require(_signature.length == 65, "Invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28, "Invalid signature recovery");

        return ecrecover(_messageHash, v, r, s);
    }
}