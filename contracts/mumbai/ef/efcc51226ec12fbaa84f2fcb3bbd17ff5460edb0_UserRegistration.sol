/**
 *Submitted for verification at polygonscan.com on 2023-06-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UserRegistration {
    struct User {
        address userAddress;
        string username;
        uint registrationTimestamp;
        uint otp;
        bool otpVerified;
    }

    mapping(address => User) public users;

    event UserRegistered(address indexed userAddress, string username, uint registrationTimestamp);
    event OtpGenerated(address indexed userAddress, uint otp);
    event OtpVerified(address indexed userAddress);

    function registerUser(string memory _username) public {
        require(users[msg.sender].userAddress == address(0), "User already registered");
        require(bytes(_username).length > 0, "Invalid username");

        uint otp = generateOtp();

        User memory newUser = User({
            userAddress: msg.sender,
            username: _username,
            registrationTimestamp: block.timestamp,
            otp: otp,
            otpVerified: false
        });

        users[msg.sender] = newUser;

        emit UserRegistered(msg.sender, _username, block.timestamp);
        emit OtpGenerated(msg.sender, otp);
    }

    function verifyOtp(uint _otp) public {
        require(users[msg.sender].userAddress != address(0), "User not found");
        require(users[msg.sender].otp == _otp, "Invalid OTP");
        require(!users[msg.sender].otpVerified, "OTP already verified");

        users[msg.sender].otpVerified = true;

        emit OtpVerified(msg.sender);
    }

    function getUser(address _userAddress) public view returns (string memory, uint, bool) {
        require(users[_userAddress].userAddress != address(0), "User not found");

        User memory user = users[_userAddress];
        return (user.username, user.registrationTimestamp, user.otpVerified);
    }

    function generateOtp() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % 1000000;
    }
}