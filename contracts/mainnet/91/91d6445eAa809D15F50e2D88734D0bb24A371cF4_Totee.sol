// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Database.sol";
import "./User.sol";

struct IndexContent {
    address author;
    string arId;
    string content;
    bool isWhole;
    uint256 publishTime;
}

contract Totee {
    using IterableDatabase for IterableDatabase.Database;
    IterableDatabase.Database private _users;

    IndexContent[] private _indexContents;

    function setUsername(string memory username) public {
        if (_users.isExisted(msg.sender)) {
            User(_users.get(msg.sender)).setUsername(username);
        } else {
            User user = new User(msg.sender, username);
            _users.insert(msg.sender, address(user));
        }
    }

    function getUsername(address addr) public view returns (string memory) {
        return User(_users.get(addr)).getUsername();
    }

    function publish(
        string memory arId,
        string memory content,
        bool isWhole
    ) public {
        require(_users.isExisted(msg.sender), "must signup first");

        User user = User(_users.get(msg.sender));
        user.publish(arId, content, isWhole);

        _indexContents.push(
            IndexContent({
                author: msg.sender,
                arId: arId,
                content: content,
                isWhole: isWhole,
                publishTime: block.timestamp
            })
        );
    }

    function getIndexContents(uint256 page, uint256 limit)
        public
        view
        returns (IndexContent[] memory)
    {
        uint256 start = _indexContents.length - page * limit;
        uint256 end = start - limit;

        start = getMin(start, _indexContents.length);
        end = getMax(end, 0);

        IndexContent[] memory result = new IndexContent[](start - end);

        uint256 x = 0;
        for (uint256 i = start - 1; i >= end; i--) {
            result[x] = _indexContents[i];
            x++;
        }
        return result;
    }

    function getMax(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? a : b;
    }

    function getMin(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function getContents(
        address addr,
        uint256 page,
        uint256 limit
    ) public view returns (Content[] memory) {
        User user = User(_users.get(addr));
        return user.getContents(page, limit);
    }
}