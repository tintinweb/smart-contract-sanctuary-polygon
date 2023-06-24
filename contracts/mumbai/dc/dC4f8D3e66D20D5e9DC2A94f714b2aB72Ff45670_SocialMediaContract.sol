// SPDX-License-Identifier: UNLICENSED 
pragma solidity ^0.8.0;

contract SocialMediaContract {
    struct User {
        string name;
        string username;
        string bio;
        string email;
        string image;
        string coverImage;
        string profileImage;
        string hashedPassword;
        uint256 createdAt;
        bool hasNotification;
    }

    struct Post {
        uint256 id;
        string body;
        uint256 createdAt;
        address userId;
        string image;
    }

    struct Comment {
        uint256 id;
        string body;
        uint256 createdAt;
        address userId;
        uint256 postId;
    }

    struct Notification {
        uint256 id;
        string body;
        address userId;
        uint256 createdAt;
    }

    mapping(address => User) private users;
    Post[] private posts;
    Comment[] private comments;
    Notification[] private notifications;

    function createUser(
        string memory _name,
        string memory _username,
        string memory _bio,
        string memory _email
    ) external {
        User storage user = users[msg.sender];
        user.name = _name;
        user.username = _username;
        user.bio = _bio;
        user.email = _email;
        user.createdAt = block.timestamp;
        user.hasNotification = false;
    }

    function createPost(string memory _body, string memory _image) external {
        uint256 postId = posts.length + 1;
        Post memory post = Post(postId, _body, block.timestamp, msg.sender, _image);
        posts.push(post);
    }

    function createComment(string memory _body, uint256 _postId) external {
        require(_postId > 0 && _postId <= posts.length, "Invalid post ID");
        
        uint256 commentId = comments.length + 1;
        Comment memory comment = Comment(commentId, _body, block.timestamp, msg.sender, _postId);
        comments.push(comment);
    }

    function createNotification(string memory _body, address _userId) external {
        Notification memory notification = Notification(notifications.length + 1, _body, _userId, block.timestamp);
        notifications.push(notification);

        User storage user = users[_userId];
        user.hasNotification = true;
    }

    function getUser(address _userId) external view returns (User memory) {
        return users[_userId];
    }

    function getPost(uint256 _postId) external view returns (Post memory) {
        require(_postId > 0 && _postId <= posts.length, "Invalid post ID");
        return posts[_postId - 1];
    }

    function getComment(uint256 _commentId) external view returns (Comment memory) {
        require(_commentId > 0 && _commentId <= comments.length, "Invalid comment ID");
        return comments[_commentId - 1];
    }

    function getNotification(uint256 _notificationId) external view returns (Notification memory) {
        require(_notificationId > 0 && _notificationId <= notifications.length, "Invalid notification ID");
        return notifications[_notificationId - 1];
    }
}