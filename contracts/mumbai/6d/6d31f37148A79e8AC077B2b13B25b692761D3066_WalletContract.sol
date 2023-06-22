// SPDX-License-Identifier: UNLICENSED 
pragma solidity ^0.8.0;

contract WalletContract {
    struct User {
        address walletAddress;
        uint balance;
    }

    mapping(string => User) private users;
    string[] private userEmails;

    event NewUserCreated(address indexed walletAddress, string email);
    event Deposit(address indexed walletAddress, uint amount);
    event Withdraw(address indexed walletAddress, uint amount);
    event Transfer(address indexed fromWalletAddress, address indexed toWalletAddress, uint amount);

    function createUser(string memory email) public {
        require(users[email].walletAddress == address(0), "User already exists");
        address walletAddress = address(bytes20(keccak256(abi.encodePacked(msg.sender, email))));
        users[email] = User(walletAddress, 0);
        userEmails.push(email);
        emit NewUserCreated(walletAddress, email);
    }

    function getUserWalletAddress(string memory email) public view returns (address) {
        return users[email].walletAddress;
    }

    function getUserBalance(string memory email) public view returns (uint) {
        return users[email].balance;
    }

    function deposit() public payable {
        User storage user = users[getEmail(msg.sender)];
        user.balance += msg.value;
        emit Deposit(user.walletAddress, msg.value);
    }

    function withdraw(uint amount) public {
        User storage user = users[getEmail(msg.sender)];
        require(amount <= user.balance, "Insufficient balance");
        user.balance -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdraw(user.walletAddress, amount);
    }

    function transfer(string memory toEmail, uint amount) public {
        User storage fromUser = users[getEmail(msg.sender)];
        User storage toUser = users[toEmail];
        require(amount <= fromUser.balance, "Insufficient balance");
        fromUser.balance -= amount;
        toUser.balance += amount;
        emit Transfer(fromUser.walletAddress, toUser.walletAddress, amount);
    }

    function getEmail(address walletAddress) private view returns (string memory) {
        for (uint i = 0; i < userEmails.length; i++) {
            if (users[userEmails[i]].walletAddress == walletAddress) {
                return userEmails[i];
            }
        }
        revert("Email not found");
    }
}