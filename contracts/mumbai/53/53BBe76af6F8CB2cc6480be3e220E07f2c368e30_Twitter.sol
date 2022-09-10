/**
 *Submitted for verification at polygonscan.com on 2022-09-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Twitter {
    address public owner;
    uint256 private counter; // represent ID of a tweet

    constructor() {
        owner = msg.sender;
        counter = 0;
    }

    struct tweet {
        address tweeter;
        uint256 id;
        string tweetText;
        string tweetImg;
        bool isDeleted;
        uint256 timestapm;
    }

    struct user {
        string name;
        string bio;
        string profileImg;
        string profileBanner;
    }

    mapping(uint256 => tweet) Tweets; //id to tweet struct
    mapping(address => user) Users; //address to a user struct

    event tweetCreated(
        address tweeter,
        uint256 id,
        string tweetText,
        string tweeetImg,
        bool isDeleted,
        uint256 timestamp
    );

    event TweetDeleted(uint256 id, bool isDeleted);

    // Method to add a tweet

    function addTweet(string memory tweetText, string memory tweetImg)
        public
        payable
    {
        require(msg.value == (0.01 ether), "Please submit 0.01 MATIC");
        tweet storage newTweet = Tweets[counter];
        newTweet.tweetText = tweetText;
        newTweet.tweetImg = tweetImg;
        newTweet.tweeter = msg.sender;
        newTweet.id = counter;
        newTweet.isDeleted = false;
        newTweet.timestapm = block.timestamp;

        emit tweetCreated(
            msg.sender,
            counter,
            tweetText,
            tweetImg,
            false,
            block.timestamp
        );
        counter++;
        payable(owner).transfer(msg.value);
    }

    // Fetch all tweets

    function getAllTweets() public view returns (tweet[] memory) {
        tweet[] memory temporary = new tweet[](counter);
        uint256 countTweets = 0;
        for (uint256 i = 0; i < counter; i++) {
            if (Tweets[i].isDeleted == false) {
                temporary[countTweets] = Tweets[i];
                countTweets++;
            }
        }
        tweet[] memory result = new tweet[](countTweets);
        for (uint256 i = 0; i < countTweets; i++) {
            result[i] = temporary[i];
        }

        return result;
    }

    // Method to get all tweets of a every user

    function getMyTweets() external view returns (tweet[] memory) {
        tweet[] memory temporary = new tweet[](counter);
        uint256 countMyTweets = 0;

        for (uint256 i = 0; i < counter; i++) {
            if (
                Tweets[i].tweeter == msg.sender && Tweets[i].isDeleted == false
            ) {
                temporary[countMyTweets] = Tweets[i];
                countMyTweets++;
            }
        }

        tweet[] memory result = new tweet[](countMyTweets);
        for (uint256 i = 0; i < countMyTweets; i++) {
            result[i] = temporary[i];
        }
        return result;
    }

    // Method to get a tweet
    function getTweet(uint256 id)
        public
        view
        returns (
            string memory,
            string memory,
            address
        )
    {
        require(id < counter, "No such Tweet");
        tweet storage t = Tweets[id];
        require(t.isDeleted == false, "Tweet is deleted");
        return (t.tweetText, t.tweetImg, t.tweeter);
    }

    //Method to delete Tweet
    function deleteTweet(uint256 tweetId, bool isDeleted) external {
        require(
            Tweets[tweetId].tweeter == msg.sender,
            "You can only delete your own tweet"
        );
        Tweets[tweetId].isDeleted = isDeleted;
        emit TweetDeleted(tweetId, isDeleted);
    }

    // Method to update user details

    function updateUser(
        string memory newName,
        string memory newBio,
        string memory newProfileImg,
        string memory newProfileBanner
    ) public {
        user storage userData = Users[msg.sender];
        userData.name = newName;
        userData.bio = newBio;
        userData.profileImg = newProfileImg;
        userData.profileBanner = newProfileBanner;
    }

    // Method to get user details
    function getUser(address userAddress) public view returns (user memory) {
        return Users[userAddress];
    }
}