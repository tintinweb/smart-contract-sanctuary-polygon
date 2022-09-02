pragma solidity ^0.8.0;

import "./CracyToken.sol";

contract W3Blog is CracyToken {
    uint256 public latestPostId;

    struct User {
        string nickname;
        uint256[] postIds;
    }

    struct Post {
        string title;
        string content;
        address creator;
        uint256 createdAt;
    }

    mapping (address => User) public users;
    mapping (uint256 => Post) public posts;

    event NewPost(address indexed author, uint256 postId, string title);

    constructor() {
        latestPostId = 0;
    }

    function createPost(string memory _title, string memory _content) public {
        latestPostId++;

        posts[latestPostId] = Post(_title, _content, msg.sender, block.timestamp);
        users[msg.sender].postIds.push(latestPostId);

        _mint(msg.sender, 1e18);

        emit NewPost(msg.sender, latestPostId, _title);
    }

    function modifyPostTitle(uint256 _postId, string memory _title) public {
        require(msg.sender == posts[_postId].creator, "Only the author can modify");

        posts[_postId].title = _title;
    }

    function modifyPostContent(uint256 _postId, string memory _content) public {
        require(msg.sender == posts[_postId].creator, "Only the author can modify");

        posts[_postId].content = _content;
    }

    function createUser(string memory _nickname) public {
        User memory user;
        user.nickname = _nickname;
        users[msg.sender] = user;
    }

    function updateNickname(string memory _nickname) public {
        users[msg.sender].nickname = _nickname;
    }

    function getPostIdsByCreator(address _creator)
    public
    view
    returns (uint256[] memory)
    {
        return users[_creator].postIds;
    }

    function getPostById(uint256 postId)
    public
    view
    returns (string memory _title, string memory _content)
    {
        _title = posts[postId].title;
        _content = posts[postId].content;
    }
}