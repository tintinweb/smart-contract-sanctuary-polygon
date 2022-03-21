/**
 *Submitted for verification at polygonscan.com on 2022-03-20
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;



contract MasterContract {

    struct User{
        string domain;
        string username;
        string ipfsHash;
        address walletAddress;
    }

    mapping (string => User) users;

    constructor(){}
    
    function registerUser(string calldata _domain,string calldata _username, address _address) public view{
        User memory user = users[_username];
        user.domain = _domain;
        user.username = _username;
        user.walletAddress = _address;
    }

    function registerIpfsHash(string calldata _username,string calldata _ipfsHash) public view{
       User memory user = users[_username];
       require(user.walletAddress == msg.sender,"Not authorised");
       user.ipfsHash = _ipfsHash;
    }

    function getIpfsHash(string calldata _username) public view returns(string memory){
        return users[_username].ipfsHash;
    }

}