// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

contract DecentralizedTwitter {
    uint256 public tweetCounter;
    mapping(uint256 => Tweet) public tweets;

    struct Tweet {
        uint256 id;
        string content;
        uint256 likes;
        address author;
    }

    event TweetCreated(uint256 id, string content, address author);
    event TweetLiked(uint256 id, address liker);

    function createTweet(string memory _content) public {
        tweetCounter++;
        tweets[tweetCounter] = Tweet(tweetCounter, _content, 0, msg.sender);
        emit TweetCreated(tweetCounter, _content, msg.sender);
    }

    function likeTweet(uint256 _tweetId) public {
        require(_tweetId > 0 && _tweetId <= tweetCounter, "Invalid tweet ID");
        tweets[_tweetId].likes++;
        emit TweetLiked(_tweetId, msg.sender);
    }
}