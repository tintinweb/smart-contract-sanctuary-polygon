/**
 *Submitted for verification at polygonscan.com on 2022-06-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


contract Memory {

    event newMemoryAdded(bytes32 memoryId, address memoryCreator, uint256 eventTimestamp, string memoryCID);

    struct memoryInfo {
      bytes32 memoryId;
      string memoryCID;
      address memoryOwner;
      address[] friends;
      uint256 eventTimestamp;
      bool visibleToPublic;
    }

    mapping(bytes32 => memoryInfo) public idToCard;

    function createNewMemory(
        string calldata memoryCID,
        uint eventTimestamp,
        //bytes32 memoryId, //remove from here when I get the chainlink random number working
        bool visibleToPublic,
        address[] memory friendsList
    ) external returns (address) {
        bytes32 memoryId = keccak256(
            abi.encodePacked(
                msg.sender,
                eventTimestamp
            )
        );
        idToCard[memoryId] = memoryInfo(memoryId, memoryCID, msg.sender, friendsList, eventTimestamp, visibleToPublic);
        emit newMemoryAdded(memoryId, msg.sender, eventTimestamp, memoryCID);
        return msg.sender; //return the creator of this memory's address so we can use it in lit protocol to gate it
    }


}