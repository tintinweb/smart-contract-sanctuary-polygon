/**
 *Submitted for verification at polygonscan.com on 2022-08-03
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

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

    event ConfirmedAttendee(bytes32 eventID, address attendeeAddress);

    event DepositsPaidOut(bytes32 eventID);

    struct CreateEvent {
        bytes32 eventId;
        string eventDataCID;
        address eventOwner;
        uint256 eventTimestamp;
        uint deposit;
        uint maxCapacity;
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

        emit NewEventCreated(
            eventId,
            msg.sender, // gets returned as: creatorAddress: '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
            eventTimestamp,
            maxCapacity,
            deposit,
            eventDataCID
        );
    }

    function createNewRSVP(bytes32 eventId) external payable {
        CreateEvent storage myEvent = idToEvent[eventId];

        require(msg.value == myEvent.deposit, "NOT ENOUGH");
        require(block.timestamp <= myEvent.eventTimestamp, "ALREADY HAPPENED");
        require(myEvent.confirmedRSVPs.length < myEvent.maxCapacity, "This event has reached capacity");

        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
           require(myEvent.confirmedRSVPs[i] != msg.sender, "ALREADY CONFIRMED"); 
        }

        myEvent.confirmedRSVPs.push(payable(msg.sender));

        emit NewRSVP(eventId, msg.sender);
    }
    
    function confirmAttendee(bytes32 eventId, address attendee) public {
        CreateEvent storage myEvent = idToEvent[eventId];

        require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED");

        address rsvpConfirm;

        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            if(myEvent.confirmedRSVPs[i] == attendee) {
                rsvpConfirm = myEvent.confirmedRSVPs[i];
            }
        }

        require(rsvpConfirm == attendee, "NO RSVP TO CONFIRM");

        for (uint8 i = 0; i < myEvent.claimedRSVPs.length; i++) {
           require(myEvent.claimedRSVPs[i] != attendee, "ALREADY CLAIMED"); 
        }

        require(myEvent.paidOut == false, "ALREADY PAID OUT");

        myEvent.claimedRSVPs.push(attendee);

        (bool sent,) = attendee.call{value: myEvent.deposit}("");

        if(!sent) {
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

        require(!myEvent.paidOut, "ALREADY PAID");

        require(
            block.timestamp >= (myEvent.eventTimestamp + 7 days),
            "TOO EARLY"
        );

        require(msg.sender == myEvent.eventOwner, "MUST BE EVENT OWNER");

        uint256 unclaimed = myEvent.confirmedRSVPs.length - myEvent.claimedRSVPs.length;

        uint256 payout = unclaimed * myEvent.deposit;

        myEvent.paidOut = true;

        (bool sent,) = msg.sender.call{value: payout}("");

        if(!sent) {
            myEvent.paidOut == false;
        }

        require(sent, "Failed to send Ether");

        emit DepositsPaidOut(eventId);
    }
}

// Web3 is the stack of protocols that enable fully decentralised applications