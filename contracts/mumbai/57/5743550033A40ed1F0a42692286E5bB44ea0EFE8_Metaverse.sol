/**
 *Submitted for verification at polygonscan.com on 2023-05-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Metaverse {
    uint256 public totalUser;
    uint256 public totalCompany;
    address public owner;

    struct User {
        string userName;
        uint256 userId;
        address companyAddress;
        string country;
        string verificationId;
    }

    // Event for student registration
    event UserRegistered(
        address indexed userAddress,
        uint256 userId,
        string country,
        string verificationId
    );

    struct Company {
        string companyName;
        uint256 companyId;
        // string companyKey;
        string country;
        string verificationId;
        uint256 numberOfUsers;
    }

    event CompanyRegistered(
        address indexed companyAddress,
        uint256 userId,
        string country,
        string verificationId
    );

    mapping(address => User) private users;
    mapping(address => Company) private companies;

    mapping(string => bool) private verificationIds;

    // register user in metaverse system
    function registerUser(
        string memory _userName,
        address _companyAddress,
        string memory _country,
        string memory _verificationId
    ) public {
        require(
            users[msg.sender].userId == 0 &&
                companies[msg.sender].companyId == 0,
            "This account is already registered with us. Kindly use another account."
        );
        require(
            companies[_companyAddress].companyId != 0,
            "Company Not registered"
        );
        require(
            !verificationIds[_verificationId],
            "User already registered with this verificatoin Id"
        );

        totalUser++;
        users[msg.sender] = User(
            _userName,
            totalUser,
            _companyAddress,
            _country,
            _verificationId
        );
        verificationIds[_verificationId] = true;
        companies[_companyAddress].numberOfUsers++;
        emit UserRegistered(msg.sender, totalUser, _country, _verificationId);
    }

    // register company in metaverse system
    function registerCompany(
        string memory _companyName,
        string memory _country,
        string memory _verificationId
    ) public {
        require(
            users[msg.sender].userId == 0 &&
                companies[msg.sender].companyId == 0,
            "This account is already registered with us. Kindly use another account."
        );

        require(
            !verificationIds[_verificationId],
            "Already registered company with this verificatoin Id"
        );

        totalCompany++;
        companies[msg.sender] = Company(
            _companyName,
            totalCompany,
            _country,
            _verificationId,
            0
        );
        verificationIds[_verificationId] = true;
        emit CompanyRegistered(
            msg.sender,
            totalUser,
            _country,
            _verificationId
        );
    }

    // getter funcitons
    function getUser(address _userAddress) public view returns (User memory) {
        return users[_userAddress];
    }

    function getCompany(address _companyAddress)
        public
        view
        returns (Company memory)
    {
        return companies[_companyAddress];
    }
}