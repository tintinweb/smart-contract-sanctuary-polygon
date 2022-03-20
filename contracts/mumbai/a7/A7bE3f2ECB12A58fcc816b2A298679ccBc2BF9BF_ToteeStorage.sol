/**
 *Submitted for verification at polygonscan.com on 2022-03-19
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

struct User {
    bytes16 username;
}

contract ToteeStorage {
    mapping(address => User) users;

    function submit(bytes16 username) public {
        users[msg.sender] = User({username: username});
    }

    function getUsername(address addr) public view returns (bytes16) {
        return users[addr].username;
    }
}