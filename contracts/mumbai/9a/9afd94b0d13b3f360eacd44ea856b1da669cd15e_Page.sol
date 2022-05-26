// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Relational.sol";

contract Page is Relational {

    event PageCreated(uint256 id, Post data);
    event RelationshipAdded(uint256 id, uint256 relationshipId);
    event PageEdited(uint256 id, string data);
    event PageRemoved(uint256 id);

    error NotAuthorized();
    error NotFound();

    // this should probably be uint256 -> address 
    // use sstore2 as the underlying storage. serializing and deserializing the struct
    mapping(uint256 => Post) public pages;
    uint256 public pageID;

    function create(string memory data, Relationship[] memory relationships) public {
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

    function edit(uint256 id, string memory data) public {
        if (id >= pageID) revert NotFound();
        if (pages[id].author != msg.sender) revert NotAuthorized();

        Post storage page = pages[id];

        page.modifiedTimestamp = block.timestamp;
        page.data = data;

        emit PageEdited(id, data);
    }

    function remove(uint256 id) public {
        if (id >= pageID) revert NotFound();
        if (pages[id].author != msg.sender) revert NotAuthorized();

        delete pages[id];
        emit PageRemoved(id);
    }

    function addRelationship(uint256 id, Relationship memory relationship) public {
        if (id >= pageID) revert NotFound();
        if (pages[id].author != msg.sender) revert NotAuthorized();

        Post storage page = pages[id];

        page.modifiedTimestamp = block.timestamp;
        page.relationships.push(relationship);

        emit RelationshipAdded(id, page.relationships.length - 1);
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