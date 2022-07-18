/**
 *Submitted for verification at polygonscan.com on 2022-07-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Tweets {
    address public owner;
    uint256 private counter;

    constructor() {
        counter = 0;
        owner = msg.sender;
    }

    struct tweet {
        address tweeter;
        uint256 id;
        string tweetText;
        string tweetImg;
    }

    event tweetPublished (
        address tweeter,
        uint256 id,
        string tweetText,
        string tweetImg
    );

    mapping (uint256 => tweet) tweets;

    function addTweet(string memory text, string memory img)public payable{
        require(msg.value == (0.1 ether), "Please submit 0.1 matic");
        tweet storage newTweet = tweets[counter];
        newTweet.tweetText = text;
        newTweet.tweetImg = img;
        newTweet.tweeter = msg.sender;
        newTweet.id = counter;
        emit tweetPublished(msg.sender, counter, text, img);
        counter++;
        payable(owner).transfer(msg.value);
    }

    function getTweet(uint256 id)public view returns(string memory, string memory, address) {
        require(id < counter, "No such tweet");
        tweet storage item = tweets[id];
        return(item.tweetText, item.tweetImg, item.tweeter);
    }
}