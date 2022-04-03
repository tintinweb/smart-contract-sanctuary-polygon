// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./User.sol";

struct Content {
    string excerpt;
    uint256 publishTime;
}

contract User {
    bytes32 private _username;
    Content[] private _contents;

    address private _creater;
    address private _owner;

    constructor(address owner, bytes32 username) {
        _username = username;
        _owner = owner;
        _creater = msg.sender;
    }

    function getUsername() public view returns (bytes32) {
        return _username;
    }

    function publish(string memory excerpt) public returns (bool) {
        require(
            msg.sender == _creater || msg.sender == _owner,
            "creater or owner"
        );
        _contents.push(
            Content({excerpt: excerpt, publishTime: block.timestamp})
        );
        return true;
    }

    function getContents() public view returns (Content[] memory) {
        return _contents;
    }
}

contract Totee {
    using IterableDatabase for IterableDatabase.Database;
    IterableDatabase.Database private users;

    function submit(bytes32 username) public {
        if (!users.isInserted(msg.sender)) {
            User user = new User(msg.sender, username);
            users.set(msg.sender, address(user));
        }
    }

    function getUsername(address addr) public view returns (bytes32) {
        return User(users.get(addr)).getUsername();
    }

    function publish(string memory excerpt) public {
        User user = User(users.get(msg.sender));
        user.publish(excerpt);
    }

    function getContents(address addr) public view returns (Content[] memory) {
        User user = User(users.get(addr));
        return user.getContents();
    }
}