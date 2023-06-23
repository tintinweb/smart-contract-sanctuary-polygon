// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract SocialMediaPlatform {
    struct User {
        string username;
        string aboutMe;
        address[] followers;
        mapping(address => bool) following;
        uint256[] postIds;
        uint256[] messageIds;
        mapping(uint256 => Post) posts;
        mapping(uint256 => Message) messages;
        uint256[] inbox;
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
    address[] public userAddresses; // Maintain an array of user addresses
    uint256 public userCount;

    event UserRegistered(address indexed userAddress, string username);
    event PostCreated(
        address indexed userAddress,
        uint256 postId,
        string content
    );
    event MessageSent(
        address indexed senderAddress,
        address indexed receiverAddress,
        string content
    );

    function registerUser(
        string memory _username,
        string memory _aboutMe
    ) public {
        require(bytes(_username).length > 0, "Username is required");
        require(
            bytes(users[msg.sender].username).length == 0,
            "User already registered"
        );

        User storage newUser = users[msg.sender];
        newUser.username = _username;
        newUser.aboutMe = _aboutMe;

        userAddresses.push(msg.sender); // Add user address to the array
        userCount++;

        emit UserRegistered(msg.sender, _username);
    }

    function editProfile(string memory _aboutMe) public {
        User storage user = users[msg.sender];
        require(bytes(user.username).length > 0, "User not registered");

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

        receiver.inbox.push(messageId); // Add message ID to the receiver's inbox

        emit MessageSent(msg.sender, _receiver, _content);
    }

    // Read functions for individual profile fields

    function getUsername(
        address _userAddress
    ) public view returns (string memory) {
        return users[_userAddress].username;
    }

    function getAboutMe(
        address _userAddress
    ) public view returns (string memory) {
        return users[_userAddress].aboutMe;
    }

    function getFollowersCount(
        address _userAddress
    ) public view returns (uint256) {
        return users[_userAddress].followers.length;
    }

    function getPostsCount(address _userAddress) public view returns (uint256) {
        return users[_userAddress].postIds.length;
    }

    function getPostContent(
        address _userAddress,
        uint256 _postId
    ) public view returns (string memory) {
        return users[_userAddress].posts[_postId].content;
    }

    function getPostTimestamp(
        address _userAddress,
        uint256 _postId
    ) public view returns (uint256) {
        return users[_userAddress].posts[_postId].timestamp;
    }

    function getMessageSender(
        address _userAddress,
        uint256 _messageId
    ) public view returns (address) {
        return users[_userAddress].messages[_messageId].sender;
    }

    function getMessageContent(
        address _userAddress,
        uint256 _messageId
    ) public view returns (string memory) {
        return users[_userAddress].messages[_messageId].content;
    }

    function getMessageTimestamp(
        address _userAddress,
        uint256 _messageId
    ) public view returns (uint256) {
        return users[_userAddress].messages[_messageId].timestamp;
    }

    function getInbox(
        address _userAddress
    ) public view returns (uint256[] memory) {
        return users[_userAddress].inbox;
    }

    function getFeed()
        public
        view
        returns (address[] memory, string[] memory, string[] memory)
    {
        uint256 totalPosts;
        for (uint256 i = 0; i < userAddresses.length; i++) {
            totalPosts += users[userAddresses[i]].postIds.length;
        }

        address[] memory addresses = new address[](totalPosts);
        string[] memory usernames = new string[](totalPosts);
        string[] memory contents = new string[](totalPosts);

        uint256 currentIndex = 0;

        for (uint256 i = 0; i < userAddresses.length; i++) {
            User storage user = users[userAddresses[i]];
            for (uint256 j = 0; j < user.postIds.length; j++) {
                addresses[currentIndex] = userAddresses[i];
                usernames[currentIndex] = user.username;
                contents[currentIndex] = user.posts[user.postIds[j]].content;
                currentIndex++;
            }
        }

        return (addresses, usernames, contents);
    }

    function getAddressByUsername(
        string memory _username
    ) public view returns (address) {
        for (uint256 i = 0; i < userAddresses.length; i++) {
            if (
                keccak256(bytes(users[userAddresses[i]].username)) ==
                keccak256(bytes(_username))
            ) {
                return userAddresses[i];
            }
        }

        revert("Username not found");
    }

    function getPostsByUser(
        string memory _username
    ) public view returns (string[] memory) {
        address userAddress = getAddressByUsername(_username);
        require(userAddress != address(0), "User not found");

        return getPostsByAddress(userAddress);
    }

    function getPostsByAddress(
        address _userAddress
    ) public view returns (string[] memory) {
        User storage user = users[_userAddress];
        uint256 numPosts = user.postIds.length;

        string[] memory posts = new string[](numPosts);

        for (uint256 i = 0; i < numPosts; i++) {
            posts[i] = user.posts[user.postIds[i]].content;
        }

        return posts;
    }
}