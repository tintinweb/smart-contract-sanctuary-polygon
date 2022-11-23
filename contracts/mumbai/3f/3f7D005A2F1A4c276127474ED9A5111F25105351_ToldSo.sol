/**
 *Submitted for verification at polygonscan.com on 2022-11-22
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";


contract ToldSo {
    struct Post {
        string title;
        string body;
        uint256 timestamp;
    }

    mapping(address => Post[]) private _authorToPosts;

    function createPost(string memory title, string memory content) external {
        Post memory post = Post(title, content, block.timestamp);
        _authorToPosts[msg.sender].push(post);
    }

    function getPostsByAuthor(address user) external view returns (Post[] memory) {
        return _authorToPosts[user];
    }
}