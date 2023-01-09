/**
 *Submitted for verification at polygonscan.com on 2023-01-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


contract Muta {
       struct CreateVideoContent { 
       bytes32 videocontentId; // Id of the event
       string videocontentCID; // IPFS or Arweave hash of videocontent name, and details of the event
       address videoOwner; // Address of the Creator of the event
       uint256 videoTimestamp; // Time of the event(saved on the blockchain in seconds)
       address[] watchParties; 
   }

 mapping(bytes32 => CreateVideoContent) public identityToVideoContent; // ID to track individual Video Contents


event NewVideoCreated(
    bytes32 videocontentId,
    address creatorAddress,
     uint256 videoTimestamp,
    string videocontentDataCID
);

event NewWatchParty(bytes32 videoID, address attendeeAddress);

function createVideoNewContent(
    uint256 videoTimestamp,
    string calldata videocontentDataCID
    ) external {
    bytes32 eventId = keccak256( 
    abi.encodePacked(
        msg.sender,
        address(this),
        videoTimestamp
    )
    );
    require(identityToVideoContent[eventId].videoTimestamp == 0, "ALREADY JOINED VIDEO WATCH PARTY");

    address[] memory watchParties;    
   identityToVideoContent[eventId] = CreateVideoContent(
    eventId,
    videocontentDataCID,
    msg.sender,
    videoTimestamp,
    watchParties
);

emit NewVideoCreated(
    eventId,
    msg.sender,
    videoTimestamp,
    videocontentDataCID
);
}

function JoinWatchParty( bytes32 eventId) external {
    CreateVideoContent storage myWatch = identityToVideoContent[eventId];
    for (uint8 i = 0; i < myWatch.watchParties.length; i++) {
        require( myWatch.watchParties[i] != msg.sender, "Already Joined Watch Party");
    }
     myWatch.watchParties.push(msg.sender);
     emit NewWatchParty(eventId, msg.sender);
}

}