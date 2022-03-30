/**
 *Submitted for verification at polygonscan.com on 2022-03-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract DecentralizedTweets {

    // Mappings
    mapping(address => string) public tweets;

    constructor() {
        // Initialize by posting a tweet
        postTweet("Contract deployed!");
    }

    // Twitt function
    function postTweet(string memory _message) public {
        tweets[msg.sender] = _message;
    }

    // Read twitt(s) of a certain address
    function getTweets() public view returns(string memory) {
        return tweets[msg.sender];
    }
}