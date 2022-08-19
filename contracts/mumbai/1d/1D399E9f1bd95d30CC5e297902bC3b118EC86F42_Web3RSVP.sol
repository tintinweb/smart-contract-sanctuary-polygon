/**
 *Submitted for verification at polygonscan.com on 2022-08-19
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4; 

contract Web3RSVP {
    struct CreateEvent {
        bytes32 eventId;
        string eventDataCID;
        address eventOwner;
        uint256 eventTimestamp;
        uint256 deposit;
        uint256 maxCapacity;
        address[] confirmedRSVPs;
        address[] claimedRSVPs;
        bool paidOut;
   }

    mapping(bytes32 => CreateEvent) public idToEvent;

    function createNewEvent(
    uint256 eventTimestamp,
    uint256 deposit,
    uint256 maxCapacity,
    string calldata eventDataCID
 ) external {
     // generate an eventID based on other things passed in to generate a hash
     bytes32 eventId = keccak256(
        abi.encodePacked(
            msg.sender,
            address(this),
            eventTimestamp,
            deposit,
            maxCapacity
        )
    );

     // make sure this id isn't already claimed
     require(idToEvent[eventId].eventTimestamp == 0, "ALREADY REGISTERED");


     address[] memory confirmedRSVPs;
     address[] memory claimedRSVPs;

     // this creates a new CreateEvent struct and adds it to the idToEvent mapping
    idToEvent[eventId] = CreateEvent(
        eventId,
        eventDataCID,
        msg.sender,
        eventTimestamp,
        deposit,
        maxCapacity,
        confirmedRSVPs,
        claimedRSVPs,
        false
    );
}
}