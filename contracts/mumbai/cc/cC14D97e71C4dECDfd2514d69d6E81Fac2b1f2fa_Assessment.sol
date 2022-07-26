/**
 *Submitted for verification at polygonscan.com on 2022-07-25
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract Assessment {
    address _owner;
    
    struct User {
        string user_name;
        string email_address;
        string password_hash;
    }

    mapping(address => User) registered_user;
    
    constructor(){
        _owner = msg.sender;
    }

    function registerMe(string memory name, string memory email_address, string memory password_hash) public returns(bool){
        registered_user[msg.sender] = User(
            name,
            email_address,
            password_hash 
        );
        return true;
    }

    function login(string memory _email, string memory entered_password_hash) public view returns(User memory){
        User memory my_self = registered_user[msg.sender];
        if(keccak256(abi.encodePacked(_email)) == keccak256(abi.encodePacked(my_self.email_address))){
            if(keccak256(abi.encodePacked(my_self.password_hash)) == keccak256(abi.encodePacked(entered_password_hash))) {
                return my_self;
            }else{
                revert("Unauthorized user!");
            }
        }else{
            revert("Not exist!");
        }
    }
}