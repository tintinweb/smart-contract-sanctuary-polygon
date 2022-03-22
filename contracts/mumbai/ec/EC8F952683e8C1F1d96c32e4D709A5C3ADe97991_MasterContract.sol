/**
 *Submitted for verification at polygonscan.com on 2022-03-21
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

    mapping (address => User) users;
    mapping (string => address) userAddresses;

    constructor(){}
    
    function registerUser(string calldata _domain,string calldata _username) public{
        address _address = msg.sender;
        userAddresses[_username] = _address;
        User memory user = users[_address];
        user.domain = _domain;
        user.username = _username;
        user.walletAddress = _address;
    }

    function registerIpfsHash(string calldata _ipfsHash) public{
       address _address = msg.sender;
       User memory user = users[_address];
       user.ipfsHash = _ipfsHash;
    }

    function getIpfsHash(string calldata _username) public view returns(string memory){
        return users[userAddresses[_username]].ipfsHash;
    }

}