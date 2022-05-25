// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Relational.sol";

contract Page is Relational {

    event PageCreated(uint256 id, Post data);
    event RelationshipAdded(uint256 id, uint256 relationshipId);
    event PageEdited(uint256 id, bytes data);
    event PageRemoved(uint256 id);

    // this should probably be uint256 -> address 
    // use sstore2 as the underlying storage. serializing and deserializing the struct
    mapping(uint256 => Post) pages;
    uint256 pageID = 0;

    function create(bytes memory data, Relationship[] memory relationships) public {
        Post storage page = pages[pageID];

        page.id = pageID;
        page.author = msg.sender;
        page.createdTimestamp = block.timestamp;
        page.modifiedTimestamp = block.timestamp;
        page.data = data;
        for (uint256 i = 0; i < relationships.length; i++) {
            page.relationships.push(relationships[i]);
        }
        emit PageCreated(page.id, page);

        pageID++;
    }

    function edit(uint256 id, bytes memory data) public {
        Post storage page = pages[id];

        page.modifiedTimestamp = block.timestamp;
        page.data = data;

        emit PageEdited(id, data);
    }

    function remove(uint256 id) public {
        delete pages[id];
        emit PageRemoved(id);
    }

    function addRelationship(uint256 id, Relationship memory relationship) public {
        Post storage page = pages[id];

        page.modifiedTimestamp = block.timestamp;
        page.relationships.push(relationship);

        emit RelationshipAdded(id, page.relationships.length - 1);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface Relational {

    struct Relationship {
        address addr;
        uint256 id;
    }

    struct Post {
        uint256 id;
        address author;
        uint256 createdTimestamp;
        uint256 modifiedTimestamp;
        bytes data;
        Relationship[] relationships;
    }

}