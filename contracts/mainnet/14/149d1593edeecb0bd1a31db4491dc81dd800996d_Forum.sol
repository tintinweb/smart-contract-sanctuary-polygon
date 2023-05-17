/**
 *Submitted for verification at polygonscan.com on 2023-05-17
*/

// SPDX-License-Identifier: CANFLY LICENSE
// 2023 (c) Canfly
pragma solidity >=0.4.22 <0.9.0;

contract Forum {
    struct Post {
        uint id;
        address author;
        string content;
        uint timestamp;
    }

    Post[] public posts;

    function createPost(string memory _content) public {
        uint _id = posts.length;
        uint _timestamp = block.timestamp;
        posts.push(Post(_id, msg.sender, _content, _timestamp));
    }

    function getPostsCount() public view returns (uint) {
        return posts.length;
    }

    function getPost(uint _id) public view returns (uint, address, string memory, uint) {
        Post memory _post = posts[_id];
        return (_post.id, _post.author, _post.content, _post.timestamp);
    }
}