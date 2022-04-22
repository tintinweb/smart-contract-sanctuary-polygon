/**
 *Submitted for verification at polygonscan.com on 2022-04-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract UserManager {

    struct User{
        string name;
        string email;
        string password;
        address publickey;
    }

    User[] users;

    function isUserExist(string memory name , string memory email , address publickey) internal view returns (bool result) {
        for ( uint i = 0 ; i < users.length ; i ++ )
        {
            if(keccak256(abi.encodePacked(name)) == keccak256(abi.encodePacked(users[i].name)) || keccak256(abi.encodePacked(email)) == keccak256(abi.encodePacked(users[i].email)) || publickey == users[i].publickey)
            {
                result = true;
            }
        }
    }

    function userSignUp(string memory name , string memory email , string memory password , address publickey) public {
        if(!isUserExist(name,email,publickey))
        {
            users.push(User(name,email,password,publickey));
        }  
    }

    function userLogIn(string memory email , string memory password) public view returns (bool result) {
        for(uint i = 0 ; i < users.length ; i ++)
        {
            if(keccak256(abi.encodePacked(email)) == keccak256(abi.encodePacked(users[i].email)) && keccak256(abi.encodePacked(password)) == keccak256(abi.encodePacked(users[i].password)))
            {
                result = true;
            }
        }
    }

    function getUserByName(string memory name) public view returns (User memory now_user) {

        for(uint i = 0 ; i < users.length ; i ++)
        {
            if(keccak256(abi.encodePacked(name)) == keccak256(abi.encodePacked(users[i].name)))
            {
                now_user = users[i];
            }
        }
    }

}