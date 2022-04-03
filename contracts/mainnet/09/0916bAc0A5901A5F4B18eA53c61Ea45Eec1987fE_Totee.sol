// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./User.sol";

struct Content {
    string excerpt;
    uint256 publishTime;
}

contract User {
    bytes32 private _username;

    constructor(bytes32 username) {
        _username = username;
    }

    function getUsername() public view returns (bytes32) {
        return _username;
    }
}

contract Totee {
    using IterableDatabase for IterableDatabase.Database;
    IterableDatabase.Database private users;

    function submit(bytes32 username) public {
        if (!users.isInserted(msg.sender)) {
            User user = new User(username);
            users.set(msg.sender, address(user));
        }
    }

    function getUsername(address addr) public view returns (bytes32) {
        return User(users.get(addr)).getUsername();
    }

    function publish(string memory excerpt) public {
        // User storage user = users.get(msg.sender);
        // user.contents.push(
        //     Content({excerpt: excerpt, publishTime: block.timestamp})
        // );
    }

    function getContents(address addr) public view returns (Content[] memory) {
        // User storage user = users.get(addr);
        // return user.contents;
    }
}