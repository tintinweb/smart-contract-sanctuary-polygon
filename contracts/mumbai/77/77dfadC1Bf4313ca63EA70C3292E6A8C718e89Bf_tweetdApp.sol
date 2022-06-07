/**
 *Submitted for verification at polygonscan.com on 2022-06-06
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

// No need of constructon in the given smart contract.

contract tweetdApp{

    struct user{
        string name;
        uint id;
    }
    
    mapping(address => bytes) public stringMap; // Mapping to store the tweet data with the Address.
    mapping(address => user) public userMap;    // Mapping to keep users name and id with the Address.
    mapping(address => bool) public checkUser;  // Checking the user is already registered or not.

    
    
    uint256 public UserCounter;  // Creating a counter will act as a user ID
                                 // Id will not be same. Same may same. It will also give total registered users.


    event displayTweetEvent (address _from , string _tweetData);


    // Function to register a New User.
    function createUser( string memory _name) public {

        require( !checkUser[msg.sender], "User already exist");

        userMap[msg.sender].name = _name;
        UserCounter += 1;
        userMap[msg.sender].id= UserCounter;
        checkUser[msg.sender] = true;
    }

    // Creating new Tweet
    function createTweet(string memory _textTweet) public {
        // Require statement for teh 280 characters. 
        require(checkUser[msg.sender] , " User must be registered");
        // Converting string to bytes to store.
        bytes memory newName = bytes(bytes(_textTweet));
        stringMap[msg.sender] = newName;
        // Emiting the data.
        emit displayTweetEvent(msg.sender , _textTweet);

    }
    
    // reteriveing the Tweet
    function reteriveTweet(address _userAdress) public view returns(string  memory){
        // Converting bytes to string to reterive the data
        string memory strTweet = string(abi.encodePacked(stringMap[_userAdress]));
        return strTweet;
    }

    // User can delete their function.
    function deleteTweet() public{

        delete stringMap[msg.sender];
    }
}