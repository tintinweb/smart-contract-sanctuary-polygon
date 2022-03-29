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

    function submit(string memory username) public {
        users[msg.sender] = User({username: bytes32(bytes(username))});
    }

    function getUsername() public view returns (string memory) {
        return string(abi.encodePacked(users[msg.sender].username));
    }

    function getUsername2(address addr) public view returns (string memory) {
        return string(abi.encodePacked(users[addr].username));
    }
}