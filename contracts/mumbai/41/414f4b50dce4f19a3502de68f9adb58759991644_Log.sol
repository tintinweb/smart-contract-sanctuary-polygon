// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Relational.sol";

contract Log is Relational {

    event LogCreated(uint256 id, Post data);
    event LogEdited(uint256 id, string data);
    event LogRemoved(uint256 id);

    mapping(uint256 => Post) public logs;
    uint256 logID = 0;

    function create(string memory data) public {
        Post storage log = logs[logID];

        log.id = logID;
        log.author = msg.sender;
        log.createdTimestamp = block.timestamp;
        log.modifiedTimestamp = block.timestamp;
        log.data = data;
        emit LogCreated(log.id, log);

        logID++;
    }

    function edit(uint256 id, string memory data) public {
        Post storage log = logs[id];

        log.modifiedTimestamp = block.timestamp;
        log.data = data;

        emit LogEdited(id, data);
    }

    function remove(uint256 id) public {
        delete logs[id];
        emit LogRemoved(id);
    }


}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface Relational {

    // TODO review naming: could be "Link"
    struct Relationship {
        address addr;
        uint256 id;
        // maybe need to add author in here too
    }

    struct Post {
        uint256 id;
        address author;
        uint256 createdTimestamp;
        uint256 modifiedTimestamp;
        string data;
        Relationship[] relationships;
    }


}