// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// The Social contract has event emissions for a social feed.
contract Social {
    string[] public posts;
    mapping(uint => address) public postAuthor;

    event NewPost(uint id, string ipfs, address author);
    event DeletePost(uint id, address author);

    // event NewComment(string comment, string postIpfs, address user);
    // event DeleteComment(string comment, string postIpfs);

    function newPost(string memory _ipfs) public {
        require(bytes(_ipfs).length != 0); // consult on max byte length

        posts.push(_ipfs);
        postAuthor[posts.length - 1] = msg.sender;

        emit NewPost(posts.length - 1, _ipfs, msg.sender);
    }

    function deletePost(uint _id) public {
        require(_id < posts.length);
        require(msg.sender == postAuthor[_id], "msg sender not author of post");
        postAuthor[_id] = address(0);
        posts[_id] = "";

        emit DeletePost(_id, msg.sender);
    }
}