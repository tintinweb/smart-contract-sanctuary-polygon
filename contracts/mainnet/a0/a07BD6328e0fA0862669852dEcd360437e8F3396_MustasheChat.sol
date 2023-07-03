/**
 *Submitted for verification at polygonscan.com on 2023-07-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract MustasheChat {
    uint256 public constant messageExpiration = 24 hours;
    uint256 public constant maxChatMessages = 100;

    struct User {
        string name;
        bool isRegistered;
        uint256 lastTransactionTimestamp;
    }

    struct Message {
        string sender;
        string text;
        uint256 timestamp;
    }

    mapping(address => User) public users;
    mapping(string => bool) private registeredNames;
    Message[] public publicChatMessages;
    address private contractOwner;
    address private tokenAddress;
    uint256 public nameChangePrice;

    event UserRegistered(address indexed userAddress, string name);
    event PublicMessageSent(string indexed sender, string text);
    event NameChanged(address indexed userAddress, string newName);
    event PriceUpdated(uint256 newPrice);

    constructor(address _tokenAddress, uint256 _nameChangePrice) {
        contractOwner = msg.sender;
        tokenAddress = _tokenAddress;
        nameChangePrice = _nameChangePrice;
        // Set the initial last transaction timestamp to contract deployment time
        users[msg.sender].lastTransactionTimestamp = block.timestamp;
    }

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only contract owner can call this function");
        _;
    }

    function registerUser(string memory _name) external {
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(!users[msg.sender].isRegistered, "User already registered");
        require(!registeredNames[_name], "Name is already registered");

        users[msg.sender].name = _name;
        users[msg.sender].isRegistered = true;
        registeredNames[_name] = true;

        emit UserRegistered(msg.sender, _name);
    }

    function sendPublicMessage(string memory _text) external {
        require(bytes(_text).length > 0, "Message text cannot be empty");
        require(users[msg.sender].isRegistered, "User is not registered");

        Message memory message = Message(users[msg.sender].name, _text, block.timestamp);
        publicChatMessages.push(message);

        // Update the last transaction timestamp for the sender
        users[msg.sender].lastTransactionTimestamp = block.timestamp;

        emit PublicMessageSent(users[msg.sender].name, _text);

        // Check if the number of messages exceeds the maximum limit
        if (publicChatMessages.length > maxChatMessages) {
            // Calculate the number of messages to be deleted
            uint256 deleteCount = publicChatMessages.length - maxChatMessages;

            // Delete the oldest messages
            for (uint256 i = 0; i < deleteCount; i++) {
                delete publicChatMessages[i];
            }

            // Shift the remaining messages to fill the deleted slots
            for (uint256 i = deleteCount; i < publicChatMessages.length; i++) {
                publicChatMessages[i - deleteCount] = publicChatMessages[i];
            }

            // Resize the array to remove the empty slots
            publicChatMessages.pop();
        }
    }

    function getPublicChatMessages() external view returns (Message[] memory) {
        return publicChatMessages;
    }

    function updateName(string memory _newName) external {
        require(bytes(_newName).length > 0, "Name cannot be empty");
        require(users[msg.sender].isRegistered, "User is not registered");
        require(!registeredNames[_newName], "Name is already registered");

        IERC20 token = IERC20(tokenAddress);

        // Check if the user has enough tokens to cover the name change price
        require(token.balanceOf(msg.sender) >= getNameChangePrice(), "Insufficient tokens");

        // Transfer the name change price tokens from the user to the contract
        require(token.transferFrom(msg.sender, address(this), getNameChangePrice()), "Token transfer failed");

        // Update the registered names and the user's name
        registeredNames[users[msg.sender].name] = false;
        registeredNames[_newName] = true;
        users[msg.sender].name = _newName;

        emit NameChanged(msg.sender, _newName);
    }

     function cleanupMessages() external onlyOwner {
        delete publicChatMessages;
    }

    function updatePrice(uint256 _newPrice) external onlyOwner {
        nameChangePrice = _newPrice;
        emit PriceUpdated(_newPrice);
    }

    function withdrawTokens(address recipient) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(recipient, balance), "Failed to transfer tokens");
    }

    function getNameChangePrice() public view returns (uint256) {
        return nameChangePrice;
    }
}