/**
 *Submitted for verification at polygonscan.com on 2022-11-22
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract ToldSo {
     struct Post{
        string title;
        string body;
        // address author;
        uint256 timestamp;

     }
     mapping(address=>Post[])public authorToPosts;

     function createPost(string memory title, string memory body)public{
            Post memory post = Post(title,body,block.timestamp);
            authorToPosts[msg.sender].push(post);
     }
// public both contract and external world can call // external only outside world cna call
     function getPosts(address author) external view returns(Post[] memory){
        return authorToPosts[author];
     }
   

   
}