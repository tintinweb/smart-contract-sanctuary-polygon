/**
 *Submitted for verification at polygonscan.com on 2022-03-28
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

struct User {
    bytes32 username;
}

// struct ToteeStorage {

// }

contract Totee {
    mapping(address => User) public users;

    function submit(bytes32 username) public {
        users[msg.sender] = User({username: username});
    }

    function getUsername(address addr) public view returns (bytes32) {
        return users[addr].username;
    }
}