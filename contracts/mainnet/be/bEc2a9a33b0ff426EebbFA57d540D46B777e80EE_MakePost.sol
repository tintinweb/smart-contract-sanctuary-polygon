/**
 *Submitted for verification at polygonscan.com on 2023-07-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

/**
 * @title Make Post
 * @dev Store & retrieve value in a mapping
 */
contract MakePost {
    constructor(){}
    uint public postCount = 0;
    mapping(uint => string) public posts;
    mapping(uint => address) public signatures;

    function makePost(string memory _post) public {
        posts[postCount] = _post;
        postCount ++;

    }

    function makeSignedPost(string memory _post) public {
        signatures[postCount] = msg.sender;
        makePost(_post);

    }

}