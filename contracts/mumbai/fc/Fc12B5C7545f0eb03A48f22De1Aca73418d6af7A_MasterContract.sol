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

    mapping (address => User) users;

    constructor() {
    }

    function registerUser(string calldata _domain,string calldata _username) public {
        address _address = msg.sender;
        users[_address] = User(
            {
                domain: _domain,
                username: _username,
                ipfsHash: users[_address].ipfsHash,
                walletAddress: _address
            }
        );
    }

    function registerIpfsHash(string calldata _ipfsHash) public{
        address _address = msg.sender;
        users[_address] = User(
            {
                domain: users[_address].domain,
                ipfsHash: _ipfsHash,
                username: users[_address].username,
                walletAddress: users[_address].walletAddress
            }
        );
    }

    function getIpfsHash() public view returns(string memory){
        return users[msg.sender].ipfsHash;
    }

}