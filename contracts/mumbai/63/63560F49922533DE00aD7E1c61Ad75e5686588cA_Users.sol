//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.8;

import "./../model/Model.sol";

contract Users {
    mapping(address => SharedModel.User) s_users;
    address[] s_addresses;

    event AddedNewUser(address indexed walletAddress, string nick, bool isAdmin);
    event UpdatedUsersPoints(address indexed walletAddress, uint32 current_points);
    event UpdatedUsersNick(address indexed walletAddress, string new_nick);
    event UpdatedUsersAdminRole(address indexed walletAddress, bool isAdmin);

    constructor() {
        addUser(msg.sender, "", true);
    }

    modifier onlyAdmin() {
        require(s_users[msg.sender].isAdmin, "msg sender must be admin");
        _;
    }

    modifier walletExists(address walletAddress) {
        require(
            s_users[walletAddress].walletAddress == walletAddress, 
            "User with passed wallet not exists"
        );
        _;
    }

    function setAdmin(address walletAddress, bool isAdmin) public onlyAdmin walletExists(walletAddress){
        s_users[walletAddress].isAdmin = isAdmin;
        emit UpdatedUsersAdminRole(walletAddress, isAdmin);
    }

    function setNick(address walletAddress, string memory nick) public onlyAdmin walletExists(walletAddress){
        s_users[walletAddress].nick = nick;

        emit UpdatedUsersNick(walletAddress, nick);
    }

    function addUser(address walletAddress, string memory nick, bool isAdmin) public {
        require(
            s_users[walletAddress].walletAddress != walletAddress,
            "Wallet address already exists"
        );

        s_addresses.push(walletAddress);
        s_users[walletAddress] = SharedModel.User(walletAddress, nick, 0, isAdmin);

        emit AddedNewUser(
            walletAddress,
            nick,
            isAdmin
        );
    }

    function getUser(address walletAddress) public view returns (SharedModel.User memory) {
        return s_users[walletAddress];
    }

    function getUsers() public view returns (SharedModel.User[] memory) {
        SharedModel.User[] memory result = new SharedModel.User[](s_addresses.length);
        for (uint256 i = 0; i < s_addresses.length; i++) {
            result[i] = s_users[s_addresses[i]];
        }
        return result;
    }

    function addPoints(address walletAddress, uint32 points) public onlyAdmin walletExists(walletAddress) {
        s_users[walletAddress].points += points;

        emit UpdatedUsersPoints(walletAddress, s_users[walletAddress].points);
    }

    function substractPoints(address walletAddress, uint32 points) public onlyAdmin walletExists(walletAddress) {
        if(s_users[walletAddress].points < points) {
            s_users[walletAddress].points = 0;
        } else {
            s_users[walletAddress].points -= points;
        }
        
        emit UpdatedUsersPoints(walletAddress, s_users[walletAddress].points);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.8;

library SharedModel {
    struct User {
        address walletAddress;
        string nick;
        uint32 points;
        bool isAdmin;
    }
}