/**
 *Submitted for verification at polygonscan.com on 2022-05-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract tweets {

    address public owner;
    uint256 private counter;
    string private visiable;

    constructor() {
        counter = 0;
        owner = msg.sender;
        visiable = "In Feed";
     }

    struct tweet {
        address tweeter;
        uint256 id;
        string tweetTxt;
        string tweetImg;
        string visiable;
    }

    event tweetCreated (
        address tweeter,
        uint256 id,
        string tweetTxt,
        string tweetImg,
        string visiable
    );

      event tweetDeleted (
        address tweeter,
        uint256 id,
        string tweetTxt,
        string tweetImg,
        string visiable
    );

    mapping(uint256 => tweet) Tweets;

    function addTweet(
        string memory tweetTxt,
        string memory tweetImg
        ) public payable {
            require(msg.value == (0.01 ether), "Please submit 0.1 Matic");
            tweet storage newTweet = Tweets[counter];
            newTweet.tweetTxt = tweetTxt;
            newTweet.tweetImg = tweetImg;
            newTweet.tweeter = msg.sender;
            newTweet.id = counter;
            newTweet.visiable = visiable;

            emit tweetCreated(
                msg.sender, 
                counter, 
                tweetTxt, 
                tweetImg,
                visiable
            );
            counter++;

            payable(owner).transfer(msg.value);
    }

    function deleteTweet(
        uint256 id
    ) public payable {
        require(msg.value == (0.01 ether), "Please submit 0.1 Matic");
        tweet storage t = Tweets[id];
        require(msg.sender == t.tweeter, "Not the creator");
        t.visiable = "Hidden";

        emit tweetDeleted(
            t.tweeter, 
            t.id, 
            t.tweetTxt, 
            t.tweetImg,
            t.visiable
        );
        payable(owner).transfer(msg.value);
    }

    function getTweet(uint256 id) public view returns (address, uint256, string memory, string memory, string memory){
        require(id < counter, "No such Tweet");

        tweet storage t = Tweets[id];
        return (t.tweeter, t.id, t.tweetTxt, t.tweetImg, t.visiable);
    }
}