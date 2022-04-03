/**
 *Submitted for verification at polygonscan.com on 2022-04-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

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

library IterableDatabase {
    struct Database {
        mapping(address => uint256) indexes;
        mapping(uint256 => address) itks;
        address[] values;
    }

    function isInserted(Database storage self, address key)
        public
        view
        returns (bool)
    {
        uint256 index = self.indexes[key];
        return key == self.itks[index];
    }

    function get(Database storage self, address key)
        public
        view
        returns (address)
    {
        uint256 index = self.indexes[key];
        return self.values[index];
    }

    function set(
        Database storage self,
        address key,
        address user
    ) public {
        if (isInserted(self, key)) {
            revert();
        } else {
            uint256 index = self.values.length;
            self.indexes[key] = index;
            self.itks[index] = key;

            self.values.push(user);
        }
    }

    function remove(Database storage self, address key) public {
        if (!isInserted(self, key)) {
            return;
        }
        uint256 lastIndex = self.values.length - 1;
        uint256 index = self.indexes[key];

        // 删除数组中的元素
        self.values[index] = self.values[lastIndex];

        address lastKey = self.itks[lastIndex];
        self.itks[index] = lastKey;
        self.indexes[lastKey] = index;

        // delete
        self.values.pop();
        delete self.indexes[key];
        delete self.itks[lastIndex];
    }
}