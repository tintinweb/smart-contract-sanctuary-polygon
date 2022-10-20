// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Relational.sol";

contract Log is Relational {
    struct LogContents {
        uint256 id;
        address author;
        uint256 createdTimestamp;
        uint256 modifiedTimestamp;
        string data;
        Relationship[] relationships;
    }

    event LogCreated(uint256 id, LogContents data);
    event LogEdited(uint256 id, string data);
    event LogRemoved(uint256 id);

    mapping(uint256 => LogContents) public logs;
    uint256 public logCount;

    function create(string memory data, Relationship[] memory relationships)
        public
        returns (uint256 id)
    {
        // fetch id
        id = logCount;

        // get storage slot for new tag
        LogContents storage log = logs[id];

        // set the new data for the tag
        log.id = id;
        log.author = msg.sender;
        log.createdTimestamp = block.timestamp;
        log.modifiedTimestamp = block.timestamp;
        log.data = data;

        // add relationships to the tag
        for (uint256 i = 0; i < relationships.length; i++) {
            addBiDirectionalRelationship(id, relationships[i]);
        }

        emit LogCreated(log.id, log);

        logCount++;

        return id;
    }

    // TODO need to add errors, and probably add relationships too.

    function edit(uint256 id, string memory data) public {
        LogContents storage log = logs[id];

        log.modifiedTimestamp = block.timestamp;
        log.data = data;

        emit LogEdited(id, data);
    }

    function remove(uint256 id) public {
        delete logs[id];
        emit LogRemoved(id);
    }

    function addBiDirectionalRelationship(
        uint256 id,
        Relationship memory relationship
    ) public {
        Relationship memory thisLog = Relationship({
            addr: address(this),
            id: id
        });

        Relational(relationship.addr).addUniDirectionalRelationship(
            relationship.id,
            thisLog
        );
        addUniDirectionalRelationship(id, relationship);
    }

    function addUniDirectionalRelationship(
        uint256 id,
        Relationship memory relationship
    ) public {
        LogContents storage log = logs[id];
        log.relationships.push(relationship);
        emit RelationshipAdded(id, relationship);
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

    event RelationshipAdded(uint256 id, Relationship relationship);

    // Option 1: call the other contract and emit events in both
    // Collection is of B (1,2,3)
    // Collection calls add relationships on id's 1,2,3 with the relationship (addr(collection), id(collection_id))
    // CreateCollection()

    // Option 2: emit events in just the contract which was called

    function addBiDirectionalRelationship(uint256 targetId, Relationship memory)
        external;

    function addUniDirectionalRelationship(
        uint256 targetId,
        Relationship memory
    ) external;

    // function removeRelationship(Relationship memory) external;

    // function create(uint256 id, bytes data);
    // function update(uint256 id, bytes data);
    // function delete(uint256 id);
    // function read(uint256 id) returns (bytes data);
}