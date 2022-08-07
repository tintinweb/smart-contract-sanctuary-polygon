/**
 *Submitted for verification at polygonscan.com on 2022-08-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract Web3RSVP {

    struct CreateEvent {
        bytes32     eventId;
        /* eventDataCID is the id of the data stored @ IPFS */
        string      eventDataCID;
        address     eventOwner;
        uint256     eventTimestamp;
        uint256     deposit;
        uint256     maxCapacity;
        address[]   confirmedRSVPs;
        address[]   claimedRSVPs;
        bool        paidOut;
    }


    mapping(bytes32 => CreateEvent) public idToEvent;


    event NewEventCreated(
        bytes32     eventID,
        address     ownerAddress
    );

    event NewRSVP(
        bytes32     eventID,
        address     attendeeAddress
    );

    event ConfirmedAttendee(
        bytes32     eventID,
        address     attendeeAddress
    );

    event DepositsPaidOut(
        bytes32     eventID
    );


    function createNewEvent(
        uint256         eventTimestamp,
        uint256         deposit,
        uint256         maxCapacity,
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
        emit NewEventCreated(
            eventId,
            msg.sender
        );
    }


    function createNewRSVP(
        bytes32     eventId
    ) external payable {
        // Look up for the eventId in our mapping
        CreateEvent storage myEvent = idToEvent[eventId];

        // Transfer deposit to our contract / require that they send in enough
        // ETH to cover the deposit requirement for that event.
        require(msg.value == myEvent.deposit, "Not enough supplied");

        // Require that the event has not already happened
        require(block.timestamp <= myEvent.eventTimestamp, "This event already happened");

        // Make sure that event has capacity for more people
        require(
            myEvent.confirmedRSVPs.length < myEvent.maxCapacity,
            "This event reach max capacity"
        );

        // Require that msg.sender isn't already RSVP
        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            require(myEvent.confirmedRSVPs[i] != msg.sender, "Already RSVP'ed to that event");
        }

        myEvent.confirmedRSVPs.push(payable(msg.sender));
        emit NewRSVP(eventId, msg.sender);
    }


    function confirmAttendee(
        bytes32     eventId,
        address     attendee
    ) public {
        // Search if the event exists
        CreateEvent storage myEvent = idToEvent[eventId];

        // Msg.sender must be the owner of the event
        require(msg.sender == myEvent.eventOwner, "Only owner can register new attendees");

        // Require that attendee trying to check is actually RSVP
        address rsvpConfirm;
        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            if (myEvent.confirmedRSVPs[i] == attendee) {
                rsvpConfirm = myEvent.confirmedRSVPs[i];
                break;
            }
        }
        require(rsvpConfirm == attendee, "No RSVP to confirm");

        // Check that it's not already claimed
        for (uint8 i = 0; i < myEvent.claimedRSVPs.length; i++) {
            require(myEvent.claimedRSVPs[i] != attendee, "Already claimed");
        }

        // Require that deposits are not already claimed by the event owner
        require(myEvent.paidOut == false, "Already paid out for this event");

        // Add the attendee to the claimed list
        myEvent.claimedRSVPs.push(attendee);

        // Send ETH back to the attendee
        (bool sent,) = attendee.call{value: myEvent.deposit}("");
        // if this fails, remove the user from the array of claimed RSVPs
        if (!sent) {
            myEvent.claimedRSVPs.pop();
        }

        require(sent, "Failed to send ETH to the attendee");
        emit ConfirmedAttendee(eventId, attendee);
    }


    function confirmAllAttendees(
        bytes32     eventId
    ) external {
        // Look up for the event
        CreateEvent memory myEvent = idToEvent[eventId];

        // Make sure msg sender is the owner
        require(msg.sender == myEvent.eventOwner, "Must be owner of that event");

        // Confirm each attendee in the RSVP array
        for (uint i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            confirmAttendee(eventId, myEvent.confirmedRSVPs[i]);
        }
    }


    function withdrawUnclaimedDeposits(
        bytes32     eventId
    ) external {
        CreateEvent memory myEvent = idToEvent[eventId];

        // check that the paidOut boolean still equals false AKA the money hasn't already been paid out
        require(myEvent.paidOut == false, "Event already paid out");

        // only the event owner can withdraw
        require(msg.sender == myEvent.eventOwner, "Must be owner of that event");

        // check if it's been 7 days past myEvent.eventTimestamp
        require(
            block.timestamp >= (myEvent.eventTimestamp + 7 days),
            "Too early"
        );

        // calculate how many people didn't claim by comparing
        uint256 unclaimeds = myEvent.confirmedRSVPs.length - myEvent.claimedRSVPs.length;
        uint256 payout = unclaimeds * myEvent.deposit;
        
        // mark as paid before sending to avoid reentrancy attack
        myEvent.paidOut = true;

        // send the payout to the owner
        (bool sent,) = msg.sender.call{value: payout}("");
        if (!sent) {
            myEvent.paidOut = false;
        }
        require(sent, "Failed to send back ETH");
        emit DepositsPaidOut(eventId);
    }
}