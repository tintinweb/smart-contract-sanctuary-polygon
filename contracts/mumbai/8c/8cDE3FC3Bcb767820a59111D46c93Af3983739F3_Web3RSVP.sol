/**
 *Submitted for verification at polygonscan.com on 2022-08-13
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Import this file to use console.log



contract Web3RSVP {
    event NewEventCreated(
        bytes32 eventID,
        address creatorAddress,
        uint256 eventTimestamp,
        uint256 maxCapacity,
        uint256 deposit,
        string eventDataCID
    );

    event NewRSVP(bytes32 eventID, address attendeeAddress);
    event confirmedAttendee(bytes32 eventID, address attendeeAddress);
    event DepositPaidOut(bytes32 eventID);

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

    mapping (bytes32 => CreateEvent) public idToEvent;

    function createNewEvent (
        uint256 eventTimestamp,
        uint256 deposit,
        uint256 maxCapacity,
        string calldata eventDataCID
   ) external {

    bytes32 eventId = keccak256(
        abi.encodePacked(
            msg.sender,
            address(this),
            eventTimestamp,
            deposit,
            maxCapacity
        )
    );
  

    address[] memory confirmedRSVPs;
    address[] memory claimedRSVPs;


    idToEvent[eventId] = CreateEvent(
        eventId,
        // eventName,
        eventDataCID,
        msg.sender,
        eventTimestamp,
        deposit,
        maxCapacity,
        confirmedRSVPs,
        claimedRSVPs,
        false
    );

    emit NewEventCreated(
        eventId,
        msg.sender,
        eventTimestamp,
        maxCapacity,
        deposit,
        eventDataCID
    );

   }

    function createNewRSVP(bytes32 eventId) external payable {
        CreateEvent storage myEvent = idToEvent[eventId];

        require(msg.value == myEvent.deposit, "You do not have enough to deposit for this Event");

        require(block.timestamp <= myEvent.eventTimestamp, "Event has aleady Happened");

        require(
            myEvent.confirmedRSVPs.length < myEvent.maxCapacity,
            "This event has reached its maximum capacity"

        );

        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            require(myEvent.confirmedRSVPs[i] != msg.sender, "RSPV Already confirmed");
        }

        myEvent.confirmedRSVPs.push(payable(msg.sender));
        
        emit NewRSVP(eventId, msg.sender);

   }

    function confirmeAlldAttendee(bytes32 eventId) external {
        CreateEvent memory myEvent = idToEvent[eventId];

        require(msg.sender == myEvent.eventOwner, "Not Authorized");

        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            confirmAttendee(eventId, myEvent.confirmedRSVPs[i]);
    }
   }

   function confirmAttendee(bytes32 eventId, address attendee) public {
        CreateEvent storage myEvent = idToEvent[eventId];

        require(msg.sender == myEvent.eventOwner, "NOt AUTHORIZED");

        address rsvpConfirm;

        for (uint8 i= 0; i < myEvent.confirmedRSVPs.length; i++) {
            if(myEvent.confirmedRSVPs[i] == attendee) {
                rsvpConfirm = myEvent.confirmedRSVPs[i];
            }
        }

        require(rsvpConfirm == attendee, "NO RSPV TO CONFIRM");

        for (uint8 i = 0; i < myEvent.claimedRSVPs.length; i++) {
            require(myEvent.claimedRSVPs[i] != attendee, "Already claimed");
        }

        require(myEvent.paidOut == false, "ALready Paid out");

        myEvent.claimedRSVPs.push(attendee);

        (bool sent,) = attendee.call{value: myEvent.deposit}("");


        if (!sent) {
            myEvent.claimedRSVPs.pop();
        }

        require(sent, "Failed to send Ether");

        emit confirmedAttendee(eventId, attendee);
    }


   function withdrawUnclaimedDeposits(bytes32 eventId)  external {
        CreateEvent memory myEvent = idToEvent[eventId];

        require(!myEvent.paidOut, "Already paid out");

        require (
            block.timestamp >= (myEvent.eventTimestamp + 7 days),
            "Too early"
        );

        require(msg.sender == myEvent.eventOwner, "Must Be Event Owner");

        uint256 unclaimed = myEvent.confirmedRSVPs.length - myEvent.claimedRSVPs.length;

        uint256 payout = unclaimed * myEvent.deposit;

        myEvent.paidOut = true;

        (bool sent, ) = msg.sender.call{value: payout}("");

        if (!sent) {
            myEvent.paidOut = false;
        
        }
        require(sent, "Failed to send Ether");

        emit DepositPaidOut(eventId);

        
   }
}