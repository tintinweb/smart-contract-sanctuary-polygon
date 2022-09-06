/**
 *Submitted for verification at polygonscan.com on 2022-09-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Web3RSVP {

    struct CreateEvent{
        bytes32 eventId;
        string eventDataCID;
        address eventOwner;
        uint eventTimestamp;
        uint deposit;
        uint maxCapacity;
        address[] confirmedRSVPs;
        address[] claimedRSVPs;
        bool paidOut;
    }

    event NewEventCreated(
        bytes32 eventID,
        address creatorAddress,
        uint eventTimestamp,
        uint maxCapacity,
        uint deposit,
        string eventDataCID
    );
    event NewRSVP(bytes32 eventID, address attendeeAddress);
    event ConfirmedAttendee(bytes32 eventID, address attendeeAddress);
    event DepositsPaidOut(bytes32 eventID);

    mapping(bytes32 => CreateEvent) public idToEvent;

    function createNewEvent(
        uint eventTimestamp, 
        uint maxCapacity, 
        uint deposit,
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
            eventDataCID,
            msg.sender,
            eventTimestamp,
            deposit,
            maxCapacity,
            confirmedRSVPs,
            claimedRSVPs,
            false
        );

        emit NewEventCreated(eventId, msg.sender, eventTimestamp, maxCapacity, deposit, eventDataCID);
    }


    function createNewRSVP(bytes32 eventId) external payable {

        CreateEvent storage myEvent = idToEvent[eventId];
        require(msg.value == myEvent.deposit, "Not Enough Deposit");
        require(block.timestamp <= myEvent.eventTimestamp, "Event Has Already Happened");
        require(myEvent.confirmedRSVPs.length < myEvent.maxCapacity, "This event has reached capacity");

        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            require(myEvent.confirmedRSVPs[i] != msg.sender, "You've already registered");
        }

        myEvent.confirmedRSVPs.push(payable(msg.sender));

        emit NewRSVP(eventId, msg.sender);        
    }


    function confirmAttendee(bytes32 eventId, address attendee) public {

        CreateEvent storage myEvent = idToEvent[eventId];

        require(msg.sender == myEvent.eventOwner, "You're not authorized");

        address rsvpConfirm;

        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            if(myEvent.confirmedRSVPs[i] == attendee) {
                rsvpConfirm = myEvent.confirmedRSVPs[i];
            }
        }

        require(rsvpConfirm == attendee, "No RSVP found to confirm.");

        for (uint8 i = 0; i < myEvent.claimedRSVPs.length; i++) {
            require(myEvent.claimedRSVPs[i] != attendee, "RSVP Already Claimed");
        }
        
        require(myEvent.paidOut == false, "Already Paid Out");

        myEvent.claimedRSVPs.push(attendee);

        (bool sent,) = attendee.call{value: myEvent.deposit}("");

        if (!sent) {
            myEvent.claimedRSVPs.pop();
        }

        require(sent, "Failed to send Ether");

        emit ConfirmedAttendee(eventId, attendee);
    }


    function confirmAllAttendees(bytes32 eventId) external {

        CreateEvent memory myEvent = idToEvent[eventId];

        require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED");

        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            confirmAttendee(eventId, myEvent.confirmedRSVPs[i]);
        }
    }


    function withdrawUnclaimedDeposits(bytes32 eventId) external {

        CreateEvent memory myEvent = idToEvent[eventId];
        
        require(!myEvent.paidOut, "Already Paid");
        require(block.timestamp >= (myEvent.eventTimestamp + 7 days), "Can't be paid this early");
        require(msg.sender ==  myEvent.eventOwner, "Can't access youre nnot the event owner");

        uint unclaimed = myEvent.confirmedRSVPs.length - myEvent.claimedRSVPs.length;
        uint payout = unclaimed * myEvent.deposit;
        myEvent.paidOut = true;

        (bool sent,) = msg.sender.call{value: payout}("");

        if (!sent) {
            myEvent.paidOut = false;
        }

        require(sent, "Failed to send Ether");

        emit DepositsPaidOut(eventId);
    }

}