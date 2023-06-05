/**
 *Submitted for verification at polygonscan.com on 2023-06-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract UserRegistration {
    struct User {
        address userAddress;
        uint registrationTimestamp;
        uint otp;
        bool otpVerified;
    }

    mapping(address => User) public users;

    event UserRegistered(address indexed userAddress, uint registrationTimestamp);
    event OtpGenerated(address indexed userAddress, uint otp);
    event OtpVerified(address indexed userAddress);

    function registerUser() public {
        require(users[msg.sender].userAddress == address(0), "User already registered");

        uint otp = generateOtp();

        User memory newUser = User({
            userAddress: msg.sender,
            registrationTimestamp: block.timestamp,
            otp: otp,
            otpVerified: false
        });

        users[msg.sender] = newUser;

        emit UserRegistered(msg.sender, block.timestamp);
        emit OtpGenerated(msg.sender, otp);
    }

    function verifyOtp(uint _otp) public {
        require(users[msg.sender].userAddress != address(0), "User not found");
        require(users[msg.sender].otp == _otp, "Invalid OTP");
        require(!users[msg.sender].otpVerified, "OTP already verified");

        users[msg.sender].otpVerified = true;

        emit OtpVerified(msg.sender);
    }

    function getUser(address _userAddress) public view returns ( uint, bool) {
        require(users[_userAddress].userAddress != address(0), "User not found");

        User memory user = users[_userAddress];
        return (user.registrationTimestamp, user.otpVerified);
    }

    function generateOtp() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % 1000000;
    }
}

contract UserLogin {
    UserRegistration public userRegistrationContract;

    event UserLoggedIn(address indexed userAddress);

    constructor(address _userRegistrationContractAddress) {
        userRegistrationContract = UserRegistration(_userRegistrationContractAddress);
    }

   function loginUser() public {
    (uint registrationTimestamp, bool otpVerified) = userRegistrationContract.getUser(msg.sender);
    require(registrationTimestamp != 0, "User not registered");
    require(otpVerified, "User not verified");

    emit UserLoggedIn(msg.sender);
}




}