/**
 *Submitted for verification at polygonscan.com on 2022-08-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Web3RSVP {
    // Exposes data about the new event like the owner, max capacity, event owner, deposit amount, etc.
    event NewEventCreated(
        bytes32 eventID,
        address creatorAddress,
        uint256 eventTimestamp,
        uint256 maxCapacity,
        uint256 deposit,
        string eventDataCID
    );

    // Exposes data about the user who RSVP'd and the event they RSVP'd to
    event NewRSVP(bytes32 eventID, address attendeeAddress);

    // Exposes data about the user who was confirmed and the event that they were confirmed for
    event ConfirmedAttendee(bytes32 eventID, address attendeeAddress);

    // Exposes data about unclaimed deposits being sent to the event organizer
    event DepositsPaidOut(bytes32 eventID);

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
        // Generate an eventId based on input to generate a hash
        bytes32 eventId = keccak256(
            abi.encodePacked(
                msg.sender,
                address(this),
                eventTimestamp,
                deposit,
                maxCapacity
            )
        );

        // Make sure eventId isn't already claimed
        require(idToEvent[eventId].eventTimestamp == 0, "ALREADY REGISTERED");

        address[] memory confirmedRSVPs;
        address[] memory claimedRSVPs;

        // Create a new CreateEvent struct and add it to the idToEvent mapping
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
            msg.sender,
            eventTimestamp,
            maxCapacity,
            deposit,
            eventDataCID
        );
    }

    function createNewRSVP(
        //Pass in a unique event ID the user wishes to RSVP to
        bytes32 eventId
    ) external payable {
        // Look up event in mapping
        CreateEvent storage myEvent = idToEvent[eventId];

        // Transfer deposit to contract and check if user has enough ETH to cover the deposit requirement of this specific event
        require(msg.value == myEvent.deposit, "INSUFFICIENT FUNDS");

        // Ensure that the event hasn’t already started based on the timestamp of the event - people shouldn’t be able to RSVP after the event has started
        require(
            myEvent.eventTimestamp > block.timestamp,
            "EVENT HAS ALREADY STARTED"
        );

        // Ensure that the event is under max capacity
        require(
            myEvent.maxCapacity > myEvent.confirmedRSVPs.length,
            "EVENT HAS REACHED ITS MAXIMUM CAPACITY"
        );

        // Ensure that msg.sender isn't already in myEvent.confirmedRSVPs AKA hasn't already RSVP'd
        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            require(
                myEvent.confirmedRSVPs[i] != msg.sender,
                "ALREADY CONFIRMED"
            );
        }

        // Add msg.sender to array of confirmed RSVPs
        // and declare address as payable which means that it can receive eth from this contract
        myEvent.confirmedRSVPs.push(payable(msg.sender));

        emit NewRSVP(eventId, msg.sender);
    }

    function confirmAttendee(
        // Pass a unique event ID for the event the user wants to confirm users for
        bytes32 eventId,
        // Pass in the attendee address of the user who is checking in
        address attendee
    ) public {
        // Look up event in mapping
        CreateEvent storage myEvent = idToEvent[eventId];

        // Ensure that only the creator of the event can confirm attendees
        require(
            myEvent.eventOwner == msg.sender,
            "MESSAGE SENDER IS NOT EVENT OWNER"
        );

        // Ensure that attendee has RSVP'd
        bool doesListContainAttendee = false;
        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            if (attendee == myEvent.confirmedRSVPs[i]) {
                doesListContainAttendee = true;

                break;
            }
        }
        require(doesListContainAttendee, "ATTENDEE HAS NOT RSVPd");

        // Ensure that attendee is NOT already in the claimedRSVPs list AKA make sure they haven't already checked in
        for (uint8 i = 0; i < myEvent.claimedRSVPs.length; i++) {
            require(myEvent.claimedRSVPs[i] != attendee, "ALREADY CLAIMED");
        }

        // Ensure that deposits are not already claimed by the event owner
        require(myEvent.paidOut == false, "ALREADY PAID OUT");

        // Add the attendee to the claimedRSVPs list
        myEvent.claimedRSVPs.push(attendee);

        // Send eth back to the attendee `https://solidity-by-example.org/sending-ether`
        (bool sent, ) = attendee.call{value: myEvent.deposit}("");

        // If sending eth fails, remove the user from the array of claimed RSVPs
        if (!sent) {
            myEvent.claimedRSVPs.pop();
        }

        require(sent, "Failed to send Ether");

        emit ConfirmedAttendee(eventId, attendee);
    }

    function confirmAllAttendees(
        // Pass a unique event ID for the event the user wants to confirm all users for
        bytes32 eventId
    ) external {
        // Look up event in mapping
        CreateEvent memory myEvent = idToEvent[eventId];

        // Ensure that only the creator of the event can confirm attendees
        require(
            myEvent.eventOwner == msg.sender,
            "MESSAGE SENDER IS NOT EVENT OWNER"
        );

        // Confirm each attendee in the RSVP array
        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            confirmAttendee(eventId, myEvent.confirmedRSVPs[i]);
        }
    }

    function withdrawUnclaimedDeposits(
        // Pass a unique event ID for the event the user wants to withdraw unclaimed deposits
        bytes32 eventId
    ) external {
        // Look up event in mapping
        CreateEvent memory myEvent = idToEvent[eventId];

        // Check that the paidOut boolean still equals false AKA the money hasn't already been paid out
        require(!myEvent.paidOut, "ALREADY PAID");

        // Check if it's been 7 days since event happened
        require(
            block.timestamp >= (myEvent.eventTimestamp + 7 days),
            "TOO EARLY"
        );

        // Ensure that only the creator of the event can withdraw
        require(
            myEvent.eventOwner == msg.sender,
            "MESSAGE SENDER IS NOT EVENT OWNER"
        );

        // Calculate how many people didn't claim RSVP
        uint256 unclaimed = myEvent.confirmedRSVPs.length -
            myEvent.claimedRSVPs.length;

        // Calculate the amount to withdraw
        uint256 payout = unclaimed * myEvent.deposit;

        // Mark as paid before sending to avoid reentrancy attack
        myEvent.paidOut = true;

        // Send the payout to the owner
        (bool sent, ) = msg.sender.call{value: payout}("");

        // If sending eth fails, mark it as not paid out
        if (!sent) {
            myEvent.paidOut = false;
        }

        require(sent, "Failed to send Ether");

        emit DepositsPaidOut(eventId);
    }
}