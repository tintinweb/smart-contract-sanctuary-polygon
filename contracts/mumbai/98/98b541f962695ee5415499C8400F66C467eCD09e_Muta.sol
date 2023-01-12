/**
 *Submitted for verification at polygonscan.com on 2023-01-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


contract Muta {
       struct CreateVideoContent { 
       bytes32 videocontentId; // Id of the event
       string videocontentCID; // IPFS or Arweave hash of videocontent name, and details of the event
       address videoOwner; // Address of the Creator of the event
       uint256 maxWatchCapacity;
       address[] watchParties; 
   }

 mapping(bytes32 => CreateVideoContent) public identityToVideoContent; // ID to track individual Video Contents


event NewVideoCreated(
    bytes32 videocontentId,
    uint maxWatchCapacity,
    address creatorAddress,
    string videocontentDataCID
);

event NewWatchParty(bytes32 videoID, address attendeeAddress);

function createVideoNewContent(
    string calldata videocontentDataCID,
    uint256 maxWatchCapacity
    ) external {
    bytes32 videocontentId = keccak256( 
     abi.encodePacked(
        msg.sender,
        address(this),
        videocontentDataCID,
        maxWatchCapacity
        )
    );
   address[] memory watchParties;    
   identityToVideoContent[videocontentId] = CreateVideoContent(
    videocontentId,
    videocontentDataCID,
    msg.sender,
    maxWatchCapacity,
    watchParties
);

emit NewVideoCreated(
   videocontentId,
   maxWatchCapacity,
    msg.sender,
    videocontentDataCID
);
}

function JoinWatchParty( bytes32 eventId) external {
    CreateVideoContent storage myWatch = identityToVideoContent[eventId];
    require(myWatch.watchParties.length < myWatch.maxWatchCapacity, "Max  Watch Capacity Reached Already");
    for (uint8 i = 0; i < myWatch.watchParties.length; i++) {
        require( myWatch.watchParties[i] != msg.sender, "Already Joined Watch Party");
    }
     myWatch.watchParties.push(msg.sender);
     emit NewWatchParty(eventId, msg.sender);
}
}