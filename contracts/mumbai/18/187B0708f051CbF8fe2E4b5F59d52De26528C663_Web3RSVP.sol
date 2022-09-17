/**
 *Submitted for verification at polygonscan.com on 2022-09-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Web3RSVP {
    // * EVENTS
    // ? New Event Info
    event NewEventCreated(
        bytes32 eventID,
        address creatorAddress,
        uint256 eventTimestamp,
        uint256 maxCapacity,
        uint256 deposit,
        string eventDataCID
    );

    // ? New User RSVPed
    event NewRSVP(bytes32 eventID, address attendeeAddress);

    // ? New Attendee confirmed entry to the event
    event ConfirmedAttendee(bytes32 eventID, address attendeeAddress);

    // ? Event's deposits paid out
    event DepositsPaidOut(bytes32 eventID);

    // * Blueprint of Event Detail
    // ? Data on IPFS (referenced using eventDataCID)
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

    // * Giving each event a Unique id
    // ? Saving each Event instance to later reference them
    mapping(bytes32 => CreateEvent) public idToEvent;

    // * Setter Function for new Event
    // ? Calling from front-end to create a new Event
    function createNewEvent(
        // ? When the event will start
        uint256 eventTimestamp,
        // ? Deposit required to RSVP to this event
        uint256 deposit,
        uint256 maxCapacity,
        // ? IPFS hash containing data(name, description, media) of event
        string calldata eventDataCID
    ) external {
        // ? Generate an eventID based on other
        // ? things passed in to generate a hash
        bytes32 eventId = keccak256(
            abi.encodePacked(
                msg.sender,
                address(this),
                eventTimestamp,
                deposit,
                maxCapacity
            )
        );

        // * To Avoid Collision
        require(idToEvent[eventId].eventTimestamp == 0, "Already registered");

        // * Tracking RSVPs
        address[] memory confirmedRSVPs;
        address[] memory claimedRSVPs;

        // * Creating New Event Instance
        // * and adding it to the mapping with ID
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
        // * Emitting Event with newEvetn Data
        emit NewEventCreated(
            eventId,
            msg.sender,
            eventTimestamp,
            maxCapacity,
            deposit,
            eventDataCID
        );
    }

    // * RSVP to Event
    // ? Called by user to join an ongoing event
    function createNewRSVP(bytes32 eventId) external payable {
        // * Find(using mapping) & save the Event in myEvent
        CreateEvent storage myEvent = idToEvent[eventId];

        // * Checking if Deposit is enough to join
        require(msg.value == myEvent.deposit, "NOT ENOUGHT");

        // * Check if event hasn't finished
        require(myEvent.eventTimestamp >= block.timestamp, "FINISHED");

        // * Check if Max Capacity exceeded
        require(
            myEvent.maxCapacity > myEvent.confirmedRSVPs.length,
            "NO MORE CAPACITY"
        );

        // * Check if user already in confirmedRSVPs
        for (uint i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            require(
                msg.sender != myEvent.confirmedRSVPs[i],
                "ALREADY CONFIRMED"
            );
        }

        // * Add the user to confirmedRSVP list
        myEvent.confirmedRSVPs.push(payable(msg.sender));

        // * Emit the Event with the new RSVP user
        emit NewRSVP(eventId, msg.sender);
    }

    // * Claim your Attendance fee
    // ? Called by user to claim their fee if they joined the event
    function confirmAttendee(bytes32 eventId, address attendee) public {
        // lookup event from our struct using eventId
        CreateEvent storage myEvent = idToEvent[eventId];

        // * require that msg.sender is owner
        // ? Only the host should be able to let users check in
        require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED");

        // * require attendee trying to check in RSVP'd
        address rsvpConfirm;

        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            if (myEvent.confirmedRSVPs[i] == attendee) {
                rsvpConfirm = myEvent.confirmedRSVPs[i];
            }
        }

        require(rsvpConfirm == attendee, "NO RSVP TO CONFIRM");

        // require that attendee is NOT already in the claimedRSVPs list AKA make sure they haven't already checked in
        for (uint8 i = 0; i < myEvent.claimedRSVPs.length; i++) {
            require(myEvent.claimedRSVPs[i] != attendee, "ALREADY CLAIMED");
        }

        // require that deposits are not already claimed by the event owner
        require(myEvent.paidOut == false, "ALREADY PAID OUT");

        // add the attendee to the claimedRSVPs list
        myEvent.claimedRSVPs.push(attendee);

        // sending eth back to the staker `https://solidity-by-example.org/sending-ether`
        (bool sent, ) = attendee.call{value: myEvent.deposit}("");

        // if this fails, remove the user from the array of claimed RSVPs
        if (!sent) {
            myEvent.claimedRSVPs.pop();
        }

        require(sent, "Failed to send Ether");

        // * Emit Event with attendee who confirmed his entry
        emit ConfirmedAttendee(eventId, attendee);
    }

    // * Confirm all Attendees at once
    function confirmAllAttendees(bytes32 eventId) external {
        // look up event from our struct with the eventId
        CreateEvent memory myEvent = idToEvent[eventId];

        // make sure you require that msg.sender is the owner of the event
        require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED");

        // confirm each attendee in the rsvp array
        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            confirmAttendee(eventId, myEvent.confirmedRSVPs[i]);
        }
    }

    // * Withdraw funds of people who didn't show up
    // ? Only owner, after the time of event
    function withdrawUnclaimedDeposits(bytes32 eventId) external {
        // look up event
        CreateEvent memory myEvent = idToEvent[eventId];

        // check that the paidOut boolean still equals false AKA the money hasn't already been paid out
        require(!myEvent.paidOut, "ALREADY PAID");

        // check if it's been 7 days past myEvent.eventTimestamp
        require(
            block.timestamp >= (myEvent.eventTimestamp + 7 days),
            "TOO EARLY"
        );

        // only the event owner can withdraw
        require(msg.sender == myEvent.eventOwner, "MUST BE EVENT OWNER");

        // calculate how many people didn't claim by comparing
        uint256 unclaimed = myEvent.confirmedRSVPs.length -
            myEvent.claimedRSVPs.length;

        uint256 payout = unclaimed * myEvent.deposit;

        // mark as paid before sending to avoid reentrancy attack
        myEvent.paidOut = true;

        // send the payout to the owner
        (bool sent, ) = msg.sender.call{value: payout}("");

        // if this fails
        if (!sent) {
            myEvent.paidOut = false;
        }

        require(sent, "Failed to send Ether");

        // * Emit Event, Event Ended and Everything Paid out
        emit DepositsPaidOut(eventId);
    }
}