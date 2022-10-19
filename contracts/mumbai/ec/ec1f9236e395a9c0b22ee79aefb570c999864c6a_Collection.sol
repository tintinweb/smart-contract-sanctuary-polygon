// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Relational.sol";

contract Collection is Relational {
    struct CollectionContents {
        uint256 id;
        address author;
        uint256 createdTimestamp;
        string name;
        Relationship[] relationships;
    }

    mapping(uint256 => CollectionContents) public collections;
    uint256 public collectionCount;

    event CollectionCreated(uint256 id, CollectionContents collection);

    function create(string memory name, Relationship[] memory relationships)
        public
    {
        CollectionContents storage collection = collections[collectionCount];

        collection.id = collectionCount;
        collection.author = msg.sender;
        collection.createdTimestamp = block.timestamp;
        collection.name = name;

        for (uint256 i = 0; i < relationships.length; i++) {
            addBiDirectionalRelationship(collectionCount, relationships[i]);
        }

        emit CollectionCreated(collectionCount, collection);
        collectionCount++;
    }

    function addBiDirectionalRelationship(
        uint256 collectionID,
        Relationship memory relationship
    ) public {
        Relationship memory thisCollection = Relationship({
            addr: address(this),
            id: collectionID
        });

        Relational(relationship.addr).addUniDirectionalRelationship(
            relationship.id,
            thisCollection
        );
        addUniDirectionalRelationship(collectionID, relationship);
    }

    function addUniDirectionalRelationship(
        uint256 collectionID,
        Relationship memory relationship
    ) public {
        CollectionContents storage collection = collections[collectionID];
        collection.relationships.push(relationship);
        emit RelationshipAdded(collectionID, relationship);
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