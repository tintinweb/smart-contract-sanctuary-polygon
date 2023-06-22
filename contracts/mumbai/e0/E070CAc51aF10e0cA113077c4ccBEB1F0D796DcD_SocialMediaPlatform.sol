// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract SocialMediaPlatform {
    struct User {
        string username;
        bytes profileImage; // Updated to bytes type
        string aboutMe;
        address[] followers;
        mapping(address => bool) following;
        uint256[] postIds;
        uint256[] messageIds;
        mapping(uint256 => Post) posts;
        mapping(uint256 => Message) messages;
    }
    
    struct Post {
        string content;
        uint256 timestamp;
    }
    
    struct Message {
        address sender;
        string content;
        uint256 timestamp;
    }
    
    mapping(address => User) public users;
    uint256 public userCount;
    
    event UserRegistered(address indexed userAddress, string username);
    event PostCreated(address indexed userAddress, uint256 postId, string content);
    event MessageSent(address indexed senderAddress, address indexed receiverAddress, string content);
    
    function registerUser(string memory _username, bytes memory _profileImage, string memory _aboutMe) public {
        require(bytes(_username).length > 0, "Username is required");
        require(bytes(users[msg.sender].username).length == 0, "User already registered");
        
        User storage newUser = users[msg.sender];
        newUser.username = _username;
        newUser.aboutMe = _aboutMe;
        
        newUser.profileImage = _profileImage; // Assign the bytes profileImage directly
        
        userCount++;
        
        emit UserRegistered(msg.sender, _username);
    }
    
    function editProfile(bytes memory _profileImage, string memory _aboutMe) public {
        User storage user = users[msg.sender];
        require(bytes(user.username).length > 0, "User not registered");
        
        user.profileImage = _profileImage; // Assign the bytes profileImage directly
        user.aboutMe = _aboutMe;
    }
    
    function createPost(string memory _content) public {
        User storage user = users[msg.sender];
        require(bytes(user.username).length > 0, "User not registered");
        
        uint256 postId = user.postIds.length;
        user.postIds.push(postId);
        user.posts[postId] = Post({
            content: _content,
            timestamp: block.timestamp
        });
        
        emit PostCreated(msg.sender, postId, _content);
    }
    
    function sendMessage(address _receiver, string memory _content) public {
        User storage sender = users[msg.sender];
        User storage receiver = users[_receiver];
        require(bytes(sender.username).length > 0, "Sender not registered");
        require(bytes(receiver.username).length > 0, "Receiver not registered");
        
        uint256 messageId = sender.messageIds.length;
        sender.messageIds.push(messageId);
        sender.messages[messageId] = Message({
            sender: msg.sender,
            content: _content,
            timestamp: block.timestamp
        });
        
        emit MessageSent(msg.sender, _receiver, _content);
    }
    
    // Read functions for individual profile fields
    
    function getUsername(address _userAddress) public view returns (string memory) {
        return users[_userAddress].username;
    }

    // Read function for the updated getProfileImage
    function getProfileImage(address _userAddress) public view returns (bytes memory) {
        return users[_userAddress].profileImage;
    }
    
    function getAboutMe(address _userAddress) public view returns (string memory) {
        return users[_userAddress].aboutMe;
    }
    
    function getFollowersCount(address _userAddress) public view returns (uint256) {
        return users[_userAddress].followers.length;
    }
    
    function getPostsCount(address _userAddress) public view returns (uint256) {
        return users[_userAddress].postIds.length;
    }
    
    function getPostContent(address _userAddress, uint256 _postId) public view returns (string memory) {
        return users[_userAddress].posts[_postId].content;
    }
    
    function getPostTimestamp(address _userAddress, uint256 _postId) public view returns (uint256) {
        return users[_userAddress].posts[_postId].timestamp;
    }
    
    function getMessageSender(address _userAddress, uint256 _messageId) public view returns (address) {
        return users[_userAddress].messages[_messageId].sender;
    }
    
    function getMessageContent(address _userAddress, uint256 _messageId) public view returns (string memory) {
        return users[_userAddress].messages[_messageId].content;
    }
    
    function getMessageTimestamp(address _userAddress, uint256 _messageId) public view returns (uint256) {
        return users[_userAddress].messages[_messageId].timestamp;
    }
}