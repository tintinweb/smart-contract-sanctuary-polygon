/**
 *Submitted for verification at polygonscan.com on 2022-08-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Web3RSVP {
    // custom events
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
        string eventDataCID; // CID(IPFS hash) of the event data
        address eventOwner;
        uint256 eventTimestamp;
        uint256 deposit;
        uint256 maxCapacity;
        address[] confirmedRSVPs;
        address[] claimedRSVPs;
        bool paidOut;
    }

    // mapping an eventId to the event
    mapping(bytes32 => CreateEvent) public idToEvent;

    function createNewEvent(
        uint256 eventTimestamp,
        uint256 deposit,
        uint256 maxCapacity,
        string calldata eventDataCID
    ) external {
        // generate an eventID based on other things passed in to generate a hash
        // decrease the lilkelihood of collisions (two users create an event at the same exact time
        bytes32 eventId = keccak256(
            abi.encodePacked(
                msg.sender,
                address(this),
                eventTimestamp,
                deposit,
                maxCapacity
            )
        );

        // track the addresses of users who RSVP and who are confirmed(arrive &get checked into the event).
        address[] memory confirmedRSVPs;
        address[] memory claimedRSVPs;

        //
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

        // emit events
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
        // look up event from our mapping
        CreateEvent storage myEvent = idToEvent[eventId];

        // validations
        require(msg.value == myEvent.deposit, "NOT ENOUGH");
        require(block.timestamp <= myEvent.eventTimestamp, "ALREADY HAPPENED");
        require(
            myEvent.confirmedRSVPs.length < myEvent.maxCapacity,
            "This event has reached capacity"
        );
        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            require(
                myEvent.confirmedRSVPs[i] != msg.sender,
                "ALREADY CONFIRMED"
            );
        }

        myEvent.confirmedRSVPs.push(payable(msg.sender));

        // emit event
        emit NewRSVP(eventId, msg.sender);
    }

    function confirmAllAttendees(bytes32 eventId) external {
        CreateEvent memory myEvent = idToEvent[eventId];

        require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED");

        // confirm each attendee in the rsvp array
        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            confirmAttendee(eventId, myEvent.confirmedRSVPs[i]);
        }
    }

    // check in attendees and return their deposit
    function confirmAttendee(bytes32 eventId, address attendee) public {
        CreateEvent storage myEvent = idToEvent[eventId];

        // validations
        require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED");
        // require that attendee trying to check in actually RSVP'd
        address rsvpConfirm;

        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            if (myEvent.confirmedRSVPs[i] == attendee) {
                rsvpConfirm = myEvent.confirmedRSVPs[i];
            }
        }
        require(rsvpConfirm == attendee, "NO RSVP TO CONFIRM");

        // require that attendee is NOT already in the claimedRSVPs array
        // aka, make sure they haven't already checked in
        for (uint8 i = 0; i < myEvent.claimedRSVPs.length; i++) {
            require(myEvent.claimedRSVPs[i] != attendee, "ALREADY CLAIMED");
        }

        require(myEvent.paidOut == false, "ALREADY PAID OUT");

        myEvent.claimedRSVPs.push(attendee);

        // sending eth back to the staker `https://solidity-by-example.org/sending-ether`
        (bool sent, ) = attendee.call{value: myEvent.deposit}("");
        //  if this fails, remove the usr from the array of claimed RSVPs
        if (!sent) {
            myEvent.claimedRSVPs.pop();
        }

        require(sent, "Failed to send Ether");
        // emit event
        emit ConfirmedAttendee(eventId, attendee);
    }

    function withdrawUnclaimedDeposits(bytes32 eventId) external {
        CreateEvent memory myEvent = idToEvent[eventId];

        // check that the paidOut boolean strill equals false
        require(!myEvent.paidOut, "ALREADY PAID");

        require(
            block.timestamp >= (myEvent.eventTimestamp + 7 days),
            "TOO EARLY"
        );

        require(msg.sender == myEvent.eventOwner, "MUST BE EVENT OWNER");

        // calculate how many people didn't claim by comparing
        uint256 unclaimed = myEvent.confirmedRSVPs.length -
            myEvent.claimedRSVPs.length;
        uint256 payout = unclaimed * myEvent.deposit;
        // mark as paid before sending to avoid reentrancy attack
        myEvent.paidOut = true;
        // send the payout to the owner
        (bool sent, ) = msg.sender.call{value: payout}("");
        if (!sent) {
            myEvent.paidOut == false;
        }

        require(sent, "Failed to send Ether");

        // emit event
        emit DepositsPaidOut(eventId);
    }
}