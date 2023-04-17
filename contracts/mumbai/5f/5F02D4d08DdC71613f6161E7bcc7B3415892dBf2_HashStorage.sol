/**
 *Submitted for verification at polygonscan.com on 2023-04-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HashStorage {
    struct User {
        address wallet;
        string email;
        bool kycStatus;
        address kycVerifier;
        bytes32[] hashes;
    }

    mapping(address => User) users;
    mapping(bytes32 => address) hashToUser;

    address public owner;

    event HashSigned(address indexed user, bytes32 hash);
    event KYCVerified(address indexed user, address indexed verifier);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this method");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function registerUser(string memory email) public onlyOwner {
        require(users[msg.sender].wallet == address(0), "User already registered");
        users[msg.sender].wallet = msg.sender;
        users[msg.sender].email = email;
    }

    function signHash(bytes32 hash) public {
        User storage user = users[msg.sender];
        require(user.wallet == msg.sender, "User not registered");
        user.hashes.push(hash);
        hashToUser[hash] = msg.sender;
        emit HashSigned(msg.sender, hash);
    }

    function setKYCStatus(bool status, address verifier) public onlyOwner {
        User storage user = users[msg.sender];
        require(user.wallet == msg.sender, "User not registered");
        user.kycStatus = status;
        user.kycVerifier = verifier;
        emit KYCVerified(msg.sender, verifier);
    }

    function getKYCStatus(address userWallet) public view returns (bool) {
        User storage user = users[userWallet];
        require(user.wallet == userWallet, "User not registered");
        return user.kycStatus;
    }

    function getHashes(address userWallet) public view returns (bytes32[] memory) {
        User storage user = users[userWallet];
        require(user.wallet == userWallet, "User not registered");
        return user.hashes;
    }

    function getUser(address userWallet) public view returns (address wallet, string memory email, bool kycStatus, address kycVerifier, bytes32[] memory hashes) {
        User storage user = users[userWallet];
        require(user.wallet == userWallet, "User not registered");
        return (user.wallet, user.email, user.kycStatus, user.kycVerifier, user.hashes);
    }

    function getUserByHash(bytes32 hash) public view returns (address wallet, string memory email, bool kycStatus, address kycVerifier) {
        address userWallet = hashToUser[hash];
        User storage user = users[userWallet];
        require(user.wallet == userWallet, "User not registered");
        return (user.wallet, user.email, user.kycStatus, user.kycVerifier);
    }
}