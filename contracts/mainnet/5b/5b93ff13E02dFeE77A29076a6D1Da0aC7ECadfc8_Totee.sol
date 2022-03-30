/**
 *Submitted for verification at polygonscan.com on 2022-03-30
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

struct User {
    bytes32 username;
    uint256 test;
}

// struct ToteeStorage {

// }

contract Totee {
    mapping(address => User) public users;
    address[] public arr2 = [
        0x08D2a6f983933d502Ce847D7840BADfa4ee49B52,
        0x08D2a6f983933d502Ce847D7840BADfa4ee49B52,
        0x08D2a6f983933d502Ce847D7840BADfa4ee49B52,
        0x08D2a6f983933d502Ce847D7840BADfa4ee49B52,
        0x08D2a6f983933d502Ce847D7840BADfa4ee49B52,
        0x08D2a6f983933d502Ce847D7840BADfa4ee49B52,
        0x08D2a6f983933d502Ce847D7840BADfa4ee49B52,
        0x08D2a6f983933d502Ce847D7840BADfa4ee49B52,
        0x08D2a6f983933d502Ce847D7840BADfa4ee49B52,
        0x08D2a6f983933d502Ce847D7840BADfa4ee49B52,
        0x08D2a6f983933d502Ce847D7840BADfa4ee49B52,
        0x08D2a6f983933d502Ce847D7840BADfa4ee49B52,
        0x08D2a6f983933d502Ce847D7840BADfa4ee49B52,
        0x08D2a6f983933d502Ce847D7840BADfa4ee49B52,
        0x08D2a6f983933d502Ce847D7840BADfa4ee49B52,
        0x08D2a6f983933d502Ce847D7840BADfa4ee49B52,
        0x08D2a6f983933d502Ce847D7840BADfa4ee49B52,
        0x08D2a6f983933d502Ce847D7840BADfa4ee49B52,
        0x08D2a6f983933d502Ce847D7840BADfa4ee49B52,
        0x08D2a6f983933d502Ce847D7840BADfa4ee49B52,
        0x08D2a6f983933d502Ce847D7840BADfa4ee49B52,
        0x08D2a6f983933d502Ce847D7840BADfa4ee49B52,
        0x08D2a6f983933d502Ce847D7840BADfa4ee49B52,
        0x08D2a6f983933d502Ce847D7840BADfa4ee49B52,
        0x08D2a6f983933d502Ce847D7840BADfa4ee49B52,
        0x08D2a6f983933d502Ce847D7840BADfa4ee49B52,
        0x08D2a6f983933d502Ce847D7840BADfa4ee49B52,
        0x08D2a6f983933d502Ce847D7840BADfa4ee49B52,
        0x08D2a6f983933d502Ce847D7840BADfa4ee49B52,
        0x08D2a6f983933d502Ce847D7840BADfa4ee49B52,
        0x08D2a6f983933d502Ce847D7840BADfa4ee49B52,
        0x08D2a6f983933d502Ce847D7840BADfa4ee49B52,
        0x08D2a6f983933d502Ce847D7840BADfa4ee49B52,
        0x08D2a6f983933d502Ce847D7840BADfa4ee49B52,
        0x08D2a6f983933d502Ce847D7840BADfa4ee49B52,
        0x08D2a6f983933d502Ce847D7840BADfa4ee49B52,
        0x08D2a6f983933d502Ce847D7840BADfa4ee49B52,
        0x08D2a6f983933d502Ce847D7840BADfa4ee49B52,
        0x08D2a6f983933d502Ce847D7840BADfa4ee49B52,
        0x08D2a6f983933d502Ce847D7840BADfa4ee49B52,
        0x08D2a6f983933d502Ce847D7840BADfa4ee49B52,
        0x08D2a6f983933d502Ce847D7840BADfa4ee49B52,
        0x08D2a6f983933d502Ce847D7840BADfa4ee49B52,
        0x08D2a6f983933d502Ce847D7840BADfa4ee49B52,
        0x08D2a6f983933d502Ce847D7840BADfa4ee49B52
    ];

    User[] public userlist;

    constructor() {
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
        userlist.push(
            User({username: bytes32(bytes("wqeqweqweqwe")), test: 556})
        );
    }

    function submit(string memory username) public {
        users[msg.sender] = User({
            username: bytes32(bytes(username)),
            test: 556
        });
    }

    function happy() public {
        arr2.push(msg.sender);
    }

    function pushToUserlist(string memory username) public {
        userlist.push(User({username: bytes32(bytes(username)), test: 556}));
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