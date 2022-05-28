// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

contract Tweets {
    address public owner;
    uint256 private counter;

    struct Tweet {
        address tweeter;
        uint256 id;
        string tweetText;
        string tweetImage;
    }

    mapping(uint256 => Tweet) tweets;

    event TweetCreated(
        address tweeter,
        uint256 id,
        string tweetText,
        string tweetImage
    );

    constructor() {
        counter = 0;
        owner = msg.sender;
    }

    function addTweet(string memory tweetText, string memory tweetImage)
        external
        payable
    {
        require(msg.value == 1 ether, "Please send 1 MATIC to create a tweet");
        Tweet storage newTweet = tweets[counter];
        newTweet.tweeter = msg.sender;
        newTweet.id = counter;
        newTweet.tweetText = tweetText;
        newTweet.tweetImage = tweetImage;

        emit TweetCreated(msg.sender, counter, tweetText, tweetImage);

        counter++;

        payable(owner).transfer(msg.value);
    }

    function getTweet(uint256 id)
        external
        view
        returns (
            address,
            string memory,
            string memory
        )
    {
        require(id < counter, "No such Tweet");
        Tweet storage t = tweets[id];
        return (t.tweeter, t.tweetText, t.tweetImage);
    }
}