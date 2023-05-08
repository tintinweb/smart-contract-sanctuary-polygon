// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract BlogContract{
    struct Post {
        uint postId;
        address author;
        bytes32 content;
        bool deleted;
    }

    mapping (uint=>address) blogAuthors;
    Post[] private posts;
    event AddPost(address indexed author, uint indexed postId);
    event DeletePost(uint indexed postId, bool deleted);

    modifier isAuthor(uint postId) {
        require(blogAuthors[postId] == msg.sender, "You are not the owner of this post");
        _;
    }

    function addPost(bytes32 content) external {
        address author = msg.sender;
        posts.push(Post(posts.length, author, content, false ));
        blogAuthors[posts.length-1] = author;
        emit AddPost(author, posts.length-1);
    }

    function deletePost(uint postId) external isAuthor(postId) {
        posts[postId].deleted = true;
        emit DeletePost(postId, true);
    }

    function getPosts() external view returns(Post[] memory){
        Post[] memory temporary = new Post[](posts.length);
        uint counter = 0;
        for(uint i=0; i< posts.length; i++){
            if(!posts[i].deleted){
                temporary[counter] = posts[i];
                counter++;
            }
        }
        Post[] memory result = new Post[](counter);
        for(uint i = 0; i<counter; i++){
            result[i] = temporary[i];
        }
        return result;
    }
}