/**
 *Submitted for verification at polygonscan.com on 2022-09-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DeStackOverflow {
    event PostCreated(bytes32 postId, address postOwner, string postparentId, bytes32 contentId);

    struct post {
        address postOwner;
        bytes32 contentId;
        bytes32 parentPost;
    }

    mapping(bytes32 => post) registeredPost;

    function createPost(string calldata _parentId, string calldata _contentUid) external {
        address _owner = msg.sender;
        bytes32 _contentId = keccak256(abi.encode(_contentUid));
        bytes32 _postId = keccak256(abi.encodePacked(_owner, _parentId, _contentId));
        registeredPost[_postId].postOwner = _owner;
        registeredPost[_postId].contentId = _contentId;
        emit PostCreated(_postId, _owner, _parentId, _contentId);
    }

    function getPost(bytes32 _postId) public view returns (address, bytes32, bytes32){
        return(
            registeredPost[_postId].postOwner,
            registeredPost[_postId].contentId,
            registeredPost[_postId].parentPost
        );
    }
}