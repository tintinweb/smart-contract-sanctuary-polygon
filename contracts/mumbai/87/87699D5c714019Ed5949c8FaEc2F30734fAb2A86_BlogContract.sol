// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract BlogContract {
    event AddPost(address owner, uint256 postId);
    event DeletePost(uint256 postId, bool isDeleted);

    struct Post {
        uint256 postId;
        address owner;
        string postContent;
        bool isDeleted;
    }

    mapping(uint256 => address) blogOwners;
    Post[] private posts;

    function addPost(string memory postContent) external {
        uint256 postId = posts.length;
        address owner = msg.sender;
        posts.push(Post(postId, owner, postContent, false));
        blogOwners[postId] = owner;
        emit AddPost(owner, postId);
    }

    function deletePost(uint256 postId) external {
        require(
            blogOwners[postId] == msg.sender,
            "You are not the owner of this post"
        );
        posts[postId].isDeleted = true;
        emit DeletePost(postId, true);
    }

    function getPosts() external view returns (Post[] memory) {
        Post[] memory temporary = new Post[](posts.length);
        uint256 counter = 0;
        for (uint256 i = 0; i < posts.length; i++) {
            if (posts[i].isDeleted == false) {
                temporary[counter] = posts[i];
                counter++;
            }
        }
        Post[] memory result = new Post[](counter);
        for (uint256 i = 0; i < counter; i++) {
            result[i] = temporary[i];
        }
        return result;
    }
}