// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Coterie {
    // State variables
    address public owner;

    uint256 public postId;
    // Events

    event PostCreated(uint256 postId, address author, string content);
    event PostLiked(uint256 postId, address author, address liker);
    event PostDeleted(uint256 postId, address author);

    // Constructor
    constructor() {
        owner = msg.sender;
    }

    struct Post {
        uint256 id;
        address author;
        string content;
        string img;
        uint256 timestamp;

    }

    struct Like {
        uint256 id;
        address author;
        address liker;
        uint256 timestamp;
        uint256 numlikes;
    }
    
    
    mapping (uint256 => Like) public allLikes;
    mapping(uint256 => Post) public allPosts;

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    // Functions
    function getAllPosts() public view returns (Post[] memory) {
        Post[] memory posts = new Post[](postId);
        for (uint256 i = 0; i < postId; i++) {
            posts[i] = allPosts[i];
        }
        return posts;
    }

    function createPost(string memory _content, string memory _img) public {
        allPosts[postId] = Post(
            postId,
            msg.sender,
            _content,
            _img,
            block.timestamp
        );
        emit PostCreated(postId, msg.sender, _content);
        postId++;
    }

    function deletePost(uint256 _postId) public {
        require(
            allPosts[_postId].author == msg.sender,
            "You can only delete your own posts."
        );
        delete allPosts[_postId];
        emit PostDeleted(_postId, msg.sender);
    }

    function likePost(uint256 _postId) public {
        require(_postId < postId, "Post does not exist.");
        allLikes[_postId] = Like(
            _postId,
            allPosts[_postId].author,
            msg.sender,
            block.timestamp,
            allLikes[_postId].numlikes + 1
        );
        emit PostLiked(_postId, allPosts[_postId].author, msg.sender);
    }

    function getPostLikes(uint256 _postId) public view returns (uint256) {
        return allLikes[_postId].numlikes;
    }

    
}