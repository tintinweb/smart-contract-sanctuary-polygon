// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Tag {

    struct TagContents {
        uint256 id;
        address author;
        uint256 createdTimestamp;
        string name;
    }

    mapping(uint256 => TagContents) tags;
    uint256 tagID = 0;

    event TagCreated(uint256 id, TagContents tag);

    function create(string memory name) public {
        TagContents storage tag = tags[tagID];

        tag.id = tagID;
        tag.author = msg.sender;
        tag.createdTimestamp = block.timestamp;
        tag.name = name;
        emit TagCreated(tagID, tag);

        tagID++;
    }
    
}