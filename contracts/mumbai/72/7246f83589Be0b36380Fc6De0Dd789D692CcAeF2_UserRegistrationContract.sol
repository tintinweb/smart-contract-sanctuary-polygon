// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract UserRegistrationContract {
    address private immutable i_owner;
    mapping(address => uint256) public UserIdToCredits;
    mapping(address => bool) public UserRegistration;
    mapping(address => bool) public AddressesPermittedToAccess;
    uint256 userCount;

    constructor() {
        i_owner = msg.sender;
        AddressesPermittedToAccess[msg.sender] = true;
    }

    modifier onlyOwner() {
        require(msg.sender == i_owner, "Only owner can call this function");
        _;
    }

    modifier onlyPermitted() {
        require(
            AddressesPermittedToAccess[msg.sender],
            "Only permitted addresses can call this function"
        );
        _;
    }

    function addPermittedAddress(address permittedAddress) external onlyOwner {
        AddressesPermittedToAccess[permittedAddress] = true;
    }

    function removePermittedAddress(
        address permittedAddress
    ) external onlyOwner {
        AddressesPermittedToAccess[permittedAddress] = false;
    }

    function registerUser(address userAddress) external {
        require(!UserRegistration[userAddress], "User already registered");
        UserIdToCredits[userAddress] = 100;
        UserRegistration[userAddress] = true;
        userCount++;
    }

    function getUserCredits(address user) external view returns (uint256) {
        require(UserRegistration[user], "User not registered");
        return UserIdToCredits[user];
    }

    function isUserRegistered(address user) external view returns (bool) {
        return UserRegistration[user];
    }

    function addUserCredits(
        address user,
        uint256 credits
    ) external onlyPermitted {
        require(UserRegistration[user], "User not registered");
        UserIdToCredits[user] += credits;
    }

    function getUserCount() external view returns (uint256) {
        return userCount;
    }
}