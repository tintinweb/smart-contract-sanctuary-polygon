/**
 *Submitted for verification at polygonscan.com on 2022-11-28
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract HuddleComments {
    struct Comment {
        uint32 id;
        string slug;
        address creator_address;
        string message;
        uint created_at;
    }

    uint32 private idCounter;
    mapping(string => Comment[]) private commentsBySlug;

    event CommentAdded(Comment comment);

    function getComments(
        string calldata slug
    ) public view returns (Comment[] memory) {
        return commentsBySlug[slug];
    }

    function addComment(string calldata slug, string calldata message) public {
        Comment memory comment = Comment({
            id: idCounter,
            slug: slug,
            creator_address: msg.sender,
            message: message,
            created_at: block.timestamp
        });
        commentsBySlug[slug].push(comment);
        idCounter++;
        emit CommentAdded(comment);
    }
}