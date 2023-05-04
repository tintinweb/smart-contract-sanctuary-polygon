// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Define a new contract named UserRegistry
contract UserRegistry {
    // Define an enumeration UserType to distinguish between JobSeeker and Employer users
    enum UserType {
        JobSeeker,
        Employer
    } // Define a struct named User to store user information
    struct User {
        uint id; // Unique identifier for the user
        UserType userType; // Type of user - JobSeeker or Employer
        string name; // Name of the user
        string email; // Email address of the user
        address wallet; // Wallet address associated with the user
        bool isRegistered; // Flag to indicate whether the user is registered or not
    }

    // Define a private variable to keep track of the total number of users
    uint private userCounter;
    // Define a mapping to store user data indexed by their unique identifier
    mapping(uint => User) private users;
    // Define a mapping to store user data indexed by their wallet address
    mapping(address => uint) private userLookup;

    // Define an event to be emitted when a new user is registered
    event UserRegistered(
        uint indexed userId,
        UserType userType,
        string name,
        string email,
        address wallet
    );

    // Define a function to register a new user with the given type, name, and email
    function registerUser(
        UserType _userType,
        string memory _name,
        string memory _email
    ) public {
        // Check if the user is already registered
        require(!isUserRegistered(msg.sender), "User already registered");

        // Increment the user counter
        userCounter++;
        // Create a new User struct with the provided information
        User memory newUser = User(
            userCounter,
            _userType,
            _name,
            _email,
            msg.sender,
            true
        );

        // Store the new user in the users mapping and update the userLookup mapping
        users[userCounter] = newUser;
        userLookup[msg.sender] = userCounter;

        // Emit the UserRegistered event
        emit UserRegistered(userCounter, _userType, _name, _email, msg.sender);
    }

    // Define a function to get user information by their unique identifier
    function getUserById(uint _userId) public view returns (User memory) {
        return users[_userId];
    }

    // Define a function to get user information by their wallet address
    function getUserByAddress(
        address _wallet
    ) public view returns (User memory) {
        uint userId = userLookup[_wallet];
        return users[userId];
    }

    // Define a function to check if a user is registered by their wallet address
    function isUserRegistered(address _wallet) public view returns (bool) {
        uint userId = userLookup[_wallet];
        return users[userId].isRegistered;
    }
}