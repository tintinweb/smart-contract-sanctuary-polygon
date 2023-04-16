// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Dcass {
    uint public postId = 0;
    uint public commentId = 0;

    struct Comment {
        uint commentId;
        string lensHandle;
        address acct;
        string content;
        uint createdAt;
        bool validated;
    }

    struct Post {
        uint postId;
        string lensHandle;
        address acct;
        string content;
        uint createdAt;
    }

    mapping(uint => Comment[]) public comments;

    Post[] public posts;

    event newPostEmit(
        uint postId,
        string lensHandle,
        address acct,
        string content,
        uint createdAt
    );

    event newCommentEmit(
        uint  commentId,
        string lensHandle,
        address acct,
        string content,
        uint createdAt,
        bool validated
    );

    event newValidation(
        string postContent,
        string commentContent
    );

    function getAllPosts() public view returns(Post [] memory) {
        return posts;
    }

    function createPost(string calldata _lensHandle, string calldata _content) public {
        posts.push(Post(postId, _lensHandle, msg.sender, _content, block.timestamp));
        emit newPostEmit(postId, _lensHandle, msg.sender, _content, block.timestamp);
        postId+=1;
    }

    function createComment(uint _postId, string calldata _lensHandle, string calldata _content) public {
        comments[_postId].push(Comment(commentId, _lensHandle, msg.sender, _content, block.timestamp, false));
        emit newCommentEmit(commentId, _lensHandle, msg.sender, _content, block.timestamp, false);
        commentId +=1;
    }

    function validateComment(uint _postId, uint _commentId) public {
        comments[_postId][_commentId].validated = true;
        emit newValidation(posts[_postId].content, comments[_postId][_commentId].content);
    }

    function fetchPostComments(uint _postId) public view returns(Comment[] memory) {
        return comments[_postId];
    }
}