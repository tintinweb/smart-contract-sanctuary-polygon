// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyMiniBlog {
    uint256 public latestPostId = 0;

    struct User {
        string username;
        string bio;
        uint256[] postIds;
    }

    struct Post {
        string title;
        string content;
        address author;
        uint256 created;
    }

    mapping(address => User) public users;
    mapping(uint256 => Post) public posts;

    event NewPost(address indexed author, uint256 postId, string title);

    function createPost(string memory title, string memory content) public {
        latestPostId++;

        posts[latestPostId] = Post(title, content, msg.sender, block.timestamp);
        users[msg.sender].postIds.push(latestPostId);

        emit NewPost(msg.sender, latestPostId, title);
    }

    function modifyPostTitle(uint256 postId, string memory title) public {
        require(
            msg.sender == posts[postId].author,
            "Only the author can modify"
        );

        posts[postId].title = title;
    }

    function modifyPostContent(uint256 postId, string memory content) public {
        require(
            msg.sender == posts[postId].author,
            "Only the author can modify"
        );

        posts[postId].content = content;
    }

    function updateUsername(string memory username) public {
        users[msg.sender].username = username;
    }

    function updateBio(string memory bio) public {
        users[msg.sender].bio = bio;
    }

    function getPostIdsByAuthor(address author)
        public
        view
        returns (uint256[] memory)
    {
        return users[author].postIds;
    }

    function getPostById(uint256 postId)
        public
        view
        returns (string memory title, string memory content)
    {
        title = posts[postId].title;
        content = posts[postId].content;
    }
}