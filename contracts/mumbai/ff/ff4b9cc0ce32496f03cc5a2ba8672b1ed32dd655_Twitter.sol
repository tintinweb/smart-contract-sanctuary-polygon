/**
 *Submitted for verification at polygonscan.com on 2023-01-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Twitter {

    address public owner;

    mapping (address => string) public username;

    constructor() {
    owner = msg.sender;
    }

    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function"
        );
        _;
    }

    modifier hasUsername {
        require(keccak256(abi.encodePacked(username[msg.sender]))
         != keccak256(abi.encodePacked("")), "Address does not have a username.");

         _;
    }

    function addUsername(string memory _username) public {
        require(keccak256(abi.encodePacked(username[msg.sender])) == 
        keccak256(abi.encodePacked("")), "Address already has a username associated.");
        username[msg.sender] = _username;
    }

    function changeUsername(address user, string memory _newUsername) public onlyOwner {
        username[user] = _newUsername;
    }


    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }

    struct Tweet {
        string username;
        address sender;
        string content;
        uint timestamp;
    }

    function getUsername(address _address) public hasUsername view returns (string memory) {
        return username[_address];
    }

    Tweet[] tweets;

    function postTweet(string calldata _content) public hasUsername {
        tweets.push(Tweet(username[msg.sender], msg.sender, _content, block.timestamp));
    }

    function getTweets() view public returns (Tweet[] memory) {
        return tweets;
    }
}