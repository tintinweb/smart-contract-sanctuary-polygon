/**
 *Submitted for verification at polygonscan.com on 2022-03-31
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

struct User {
    bytes32 username;
}

contract Totee {
    mapping(address => User) public users;

    User[] public userlist;

    function submit(bytes32 _username) public {
        users[msg.sender] = User({username: _username});
    }
}