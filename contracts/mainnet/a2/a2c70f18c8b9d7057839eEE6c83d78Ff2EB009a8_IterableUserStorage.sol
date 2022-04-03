/**
 *Submitted for verification at polygonscan.com on 2022-04-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

struct User {
    bytes32 username;
}
struct UserStorage {
    mapping(address => uint256) indexes;
    mapping(uint256 => address) itks;
    mapping(address => bool) inserted;
    User[] users;
}

library IterableUserStorage {
    function get(UserStorage storage userStorage, address key)
        public
        view
        returns (User memory)
    {
        uint256 index = userStorage.indexes[key];
        return userStorage.users[index];
    }

    function set(
        UserStorage storage userStorage,
        address key,
        User memory user
    ) public {
        if (userStorage.inserted[key]) {
            uint256 index = userStorage.indexes[key];
            userStorage.users[index] = user;
        } else {
            uint256 index = userStorage.users.length;
            userStorage.indexes[key] = index;
            userStorage.itks[index] = key;
            userStorage.inserted[key] = true;

            userStorage.users.push(user);
        }
    }

    function remove(UserStorage storage userStorage, address key) public {
        if (!userStorage.inserted[key]) {
            return;
        }
        uint256 lastIndex = userStorage.users.length - 1;
        uint256 index = userStorage.indexes[key];

        // 删除数组中的元素
        userStorage.users[index] = userStorage.users[lastIndex];

        address lastKey = userStorage.itks[lastIndex];
        userStorage.itks[index] = lastKey;
        userStorage.indexes[lastKey] = index;

        // delete
        userStorage.users.pop();
        delete userStorage.indexes[key];
        delete userStorage.inserted[key];
        delete userStorage.itks[lastIndex];
    }
}

contract Totee {
    using IterableUserStorage for UserStorage;
    UserStorage private users;

    // mapping(address => User) public users;

    function submit(bytes32 username) public {
        users.set(msg.sender, User({username: username}));
    }

    function getUsername(address addr) public view returns (bytes32) {
        return users.get(addr).username;
    }
}