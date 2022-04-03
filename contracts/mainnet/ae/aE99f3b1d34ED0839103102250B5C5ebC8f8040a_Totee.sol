// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Database.sol";
import "./User.sol";

contract Totee {
    using IterableDatabase for IterableDatabase.Database;
    IterableDatabase.Database private users;

    function setUsername(bytes32 username) public {
        if (users.isExisted(msg.sender)) {
            User(users.get(msg.sender)).setUsername(username);
        } else {
            User user = new User(msg.sender, username);
            users.insert(msg.sender, address(user));
        }
    }

    function getUsername(address addr) public view returns (bytes32) {
        return User(users.get(addr)).getUsername();
    }

    function publish(string memory arId, string memory excerpt) public {
        User user = User(users.get(msg.sender));
        user.publish(arId, excerpt);
    }

    function getContents(address addr) public view returns (Content[] memory) {
        User user = User(users.get(addr));
        return user.getContents();
    }
}