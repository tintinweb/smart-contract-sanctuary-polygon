/**
 *Submitted for verification at polygonscan.com on 2023-04-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SocailPost {
    struct Post {
        string postIpfsHash;
        address user;
        uint256 dateTIme;
    }
    event newPost(string postIpfsHash, address user, uint256 dateTime);
    Post[] Posts;

    function AddPost(Post calldata post) public {
        Posts.push(post);
        emit newPost(post.postIpfsHash, post.user, post.dateTIme);
    }

    function getPostbyTime(uint256 time) public view returns (Post memory) {
        uint length = Posts.length;
        if (length > 0) {
            for (uint256 index = 0; index < length; ) {
                require(Posts[index].dateTIme == time, "no post availabe");
                if (Posts[index].dateTIme == time) {
                    return Posts[index];
                }
                unchecked {
                    index++;
                }
            }
        }
        revert("no post availabe");
    }
}