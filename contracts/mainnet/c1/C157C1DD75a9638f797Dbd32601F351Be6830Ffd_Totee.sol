/**
 *Submitted for verification at polygonscan.com on 2022-03-30
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
    address[] public arr2;
    User[] public userlist;

    function submit(string memory username) public {
        users[msg.sender] = User({username: bytes32(bytes(username))});
    }

    function happy() public {
        arr2.push(msg.sender);
    }

    function pushToUserlist(string memory username) public {
        userlist.push(User({username: bytes32(bytes(username))}));
    }

    function getUsername() public view returns (string memory) {
        return string(abi.encodePacked(users[msg.sender].username));
    }

    function getUsername2(address addr) public view returns (string memory) {
        return string(abi.encodePacked(users[addr].username));
    }

    function test() public view returns (address[] memory) {
        return arr2;
    }

    function test2() public view returns (User[] memory) {
        return userlist;
    }
}