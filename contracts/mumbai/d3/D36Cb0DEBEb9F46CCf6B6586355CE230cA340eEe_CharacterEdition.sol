// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract CharacterEdition {
    struct CharacterEditionRecord {
        uint256 characterEditionId;
        uint256[] characterDefinitionIds;
        uint256[] weights;
        uint256[] itemPackDefinitionIds;
    }

    uint256 public worldId;

    // key: characterEditionId, (key: characterDefinitionId, value: CharacterDefinitionId)
    mapping(uint256 => CharacterEditionRecord) public records;
    // key: tokenId, value: characterEditionId
    mapping(uint256 => uint256) public tokenAndEditions;

    constructor(uint256 worldId_) {
        worldId = worldId_;
    }

    function getCharacterEditionRecord(uint256 characterEditionId) public view returns(CharacterEditionRecord memory) {
        return records[characterEditionId];
    }

    // TODO: add access control modifier
    function setCharacterEdition(uint256 characterEditionId, CharacterEditionRecord calldata record) public {
        records[characterEditionId] = record;
    }

    // TODO: add access control modifier
    function setTokenIdToCharacterEdition(uint256 tokenId, uint256 characterEditionId) public {
        tokenAndEditions[tokenId] = characterEditionId;
    }
}