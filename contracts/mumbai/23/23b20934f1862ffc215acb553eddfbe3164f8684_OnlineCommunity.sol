/**
 *Submitted for verification at polygonscan.com on 2023-04-16
*/

//SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.0;

contract OnlineCommunity {
    struct User {
        string username;
        string password;
        bool registered;
    }
    
    struct Content {
        address author;
        string title;
        string description;
        uint votes;
        bool removed;
    }
    
    mapping(address => User) public users;
    Content[] public contents;
    mapping(address => mapping(uint => bool)) public userVotes;
    
    event UserRegistered(address indexed userAddress, string username, string password);
    event ContentCreated(uint indexed contentIndex, address author, string title, string description);
    event ContentRemoved(uint indexed contentIndex);
    event ContentVoted(uint indexed contentIndex, address indexed voter);
    
    function registerUser(string memory _username, string memory _password) public {
        require(!users[msg.sender].registered, "User already registered");
        
        User memory newUser = User({
            username: _username,
            password: _password,
            registered: true
        });
        
        users[msg.sender] = newUser;
        
        emit UserRegistered(msg.sender, _username, _password);
    }
    
    function createContent(string memory _title, string memory _description) public {
        require(users[msg.sender].registered, "User is not registered");
        
        Content memory newContent = Content({
            author: msg.sender,
            title: _title,
            description: _description,
            votes: 0,
            removed: false
        });
        
        contents.push(newContent);
        
        emit ContentCreated(contents.length - 1, msg.sender, _title, _description);
    }
    
    function viewContent(uint _contentIndex) public view returns (address, string memory, string memory, uint) {
        Content memory content = contents[_contentIndex];
        require(!content.removed, "Content is removed");
        
        return (content.author, content.title, content.description, content.votes);
    }
    
    function voteContent(uint _contentIndex) public {
        require(users[msg.sender].registered, "User is not registered");
        require(!contents[_contentIndex].removed, "Content is removed");
        require(!userVotes[msg.sender][_contentIndex], "User has already voted");
        
        contents[_contentIndex].votes++;
        userVotes[msg.sender][_contentIndex] = true;
        
        emit ContentVoted(_contentIndex, msg.sender);
    }
    
    function removeContent(uint _contentIndex) public {
        require(contents[_contentIndex].author == msg.sender, "User is not the author");
        require(!contents[_contentIndex].removed, "Content is already removed");
        
        contents[_contentIndex].removed = true;
        
        emit ContentRemoved(_contentIndex);
    }
}