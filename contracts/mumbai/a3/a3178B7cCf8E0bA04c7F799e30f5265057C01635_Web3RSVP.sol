/**
 *Submitted for verification at polygonscan.com on 2022-08-04
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

contract Web3RSVP{
event NewEventCreated (
bytes32 eventId,
address creatorAddress,
uint256 eventTimeStamp,
uint256 maxCapacity,
uint256 deposit,
string  eventDataCID
);
event   NewRsvp(bytes32 eventId, address attendeeAddress);
event confirmedAttendee(bytes32 eventId, address attendeeAddress);
event DepositsPaidOut (bytes32 eventId);

struct CreateEvent{
    bytes32 eventId;
    string eventDataCID;
    address eventOwner;
    uint256 eventTimeStamp;
    uint256 deposit;
    uint256 maxCapacity;
    address[] confirmedRSVPs;
    address[] claimedRSVPs;
    bool paidOut;
}
mapping(bytes32 => CreateEvent) public idToEvent;
function createNewEvent(
uint256 eventTimeStamp,
uint256 deposit,
uint256 maxCapacity, 
string calldata eventDataCID) external {
    bytes32 eventId = keccak256(
        abi.encodePacked(
            msg.sender,
            address(this),
            eventTimeStamp
            ,deposit,
            maxCapacity));
            
    address[] memory confirmedRSVPs;
    address[] memory claimedRSVPs;

    idToEvent[eventId] = CreateEvent(
        eventId,
        eventDataCID,
        msg.sender,
        eventTimeStamp,
        deposit,
        maxCapacity,
        confirmedRSVPs,
        claimedRSVPs,
       false
    );
   emit NewEventCreated(
            eventId,
            msg.sender,
            eventTimeStamp,
            maxCapacity,
            deposit,
            eventDataCID
        );
}


function createNewRsvp(bytes32 eventId) external payable {
    CreateEvent storage myEvent = idToEvent[eventId];

    require(msg.value == myEvent.deposit,"NOT ENOUGH");
    require(block.timestamp <= myEvent.eventTimeStamp, "Already Happened");
    require(myEvent.confirmedRSVPs.length < myEvent.maxCapacity, "This Event has Reached max Capacity");
    for (uint256 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
        require(myEvent.confirmedRSVPs[i] != msg.sender, "Already Confirmed");
    }
  myEvent.confirmedRSVPs.push(payable(msg.sender));
  emit NewRsvp(eventId, msg.sender);
}
function confirmAttendees(bytes32 eventId,address attendee) public {
    CreateEvent storage myEvent = idToEvent[eventId];


    require(msg.sender == myEvent.eventOwner, "NOT Authorized");

      address rsvpConfirm;

    for (uint256 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
        if (myEvent.confirmedRSVPs[i] == attendee) {
            rsvpConfirm = myEvent.confirmedRSVPs[i];
        } 
    }

    require(rsvpConfirm == attendee, "No RSVP TO CONFIRM");

    for (uint256 i = 0; i < myEvent.claimedRSVPs.length; i++) {
        require(myEvent.claimedRSVPs[i] != attendee, "ALready Claimed") ;
    }
    require(myEvent.paidOut == false, "Already PAID OUT");

    myEvent.claimedRSVPs.push(attendee);

    (bool sent,) = attendee.call{value:myEvent.deposit}("");

    if (!sent) {
        myEvent.claimedRSVPs.pop();
    } 
    require(sent,"Failed TO SEND ETHER");
    emit confirmedAttendee(eventId,attendee);
}
function confirmAllAttendees(bytes32 eventId) external {
    CreateEvent memory  myEvent =idToEvent[eventId];
    require(msg.sender == myEvent.eventOwner, "Not Authorized");
    for (uint256 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
        confirmAttendees(eventId,myEvent.confirmedRSVPs[i]);
    }
}
function withdrawUnclaimedDeposits(bytes32 eventId) external
 {
      CreateEvent memory  myEvent =idToEvent[eventId];
      require(!myEvent.paidOut, "Already PaidOut");
      require(block.timestamp >= (myEvent.eventTimeStamp + 7 days), "Too Early");
     uint256 unClaimed =myEvent.confirmedRSVPs.length  - myEvent.claimedRSVPs.length;
     uint256 payout = unClaimed * myEvent.deposit;

     myEvent.paidOut = true;

     (bool sent, ) =msg.sender.call{value:payout}("");

      if (!sent) {
        myEvent.paidOut = false;
       } 
    require(sent,"Failed TO SEND ETHER");
    emit DepositsPaidOut (eventId);
}
}