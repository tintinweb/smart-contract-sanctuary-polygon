/**
 *Submitted for verification at polygonscan.com on 2022-08-04
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

contract Web3RSVP {
    event NewEventCreated(
        bytes32 eventId,
        address creatorAddress,
        uint256 eventTimestamp,
        uint256 maxCapacity,
        uint256 deposit,
        string eventDataCID
    );

    event NewRSVP(bytes32 eventId, address attendeeAddress);

    event ConfirmedAttendee(bytes32 eventId, address attendeeAddress);

    event DepositsPaidOut(bytes32 eventId);

    struct CreateEvent {
        bytes32 eventId;
        string eventDataCID; // reference to an IPFS hash for storing details like the event’s name and event description
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
        // generating an eventID
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
            false // because at the time of eventCreation, there have been no payouts to the RSVPers (there are none yet) or the event owner yet
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
        // look up event from our struct using the eventId
        CreateEvent storage myEvent = idToEvent[eventId];

        // transfer deposit to our contract / require that they send in enough ETH to cover the deposit requirement of this specific event
        require(msg.value == myEvent.deposit, "Not enough deposit");

        // require that the event hasn't already happened (<eventTimestamp)
        require(block.timestamp <= myEvent.eventTimestamp, "Already happened");

        // make sure event is under max capacity
        require(
            myEvent.confirmedRSVPs.length < myEvent.maxCapacity,
            "This event has reached maximum capacity"
        );

        // require that msg.sender isn't already in myEvent.confirmedRSVPs AKA hasn't already RSVP'd
        for (uint8 index = 0; index < myEvent.confirmedRSVPs.length; index++) {
            require(
                myEvent.confirmedRSVPs[index] != msg.sender,
                "Already confirmed"
            );
        }

        myEvent.confirmedRSVPs.push(payable(msg.sender));

        emit NewRSVP(eventId, msg.sender);
    }

    // part of our app requires users to pay a deposit which they get back when they arrive at the event
    function confirmAttendee(bytes32 eventId, address attendee) public {
        // look up event from our struct using the eventId
        CreateEvent storage myEvent = idToEvent[eventId];

        // require that msg.sender is the owner of the event - only the host should be able to check people in
        require(msg.sender == myEvent.eventOwner, "Not authorized");

        // require that attendee trying to check in actually RSVP'd
        address rsvpConfirm;

        for (uint8 index = 0; index < myEvent.confirmedRSVPs.length; index++) {
            if (myEvent.confirmedRSVPs[index] == attendee) {
                rsvpConfirm = myEvent.confirmedRSVPs[index];
            }
        }

        require(rsvpConfirm == attendee, "No RSVP to confirm");

        // require that attendee is NOT already in the claimedRSVPs list AKA make sure they haven't already checked in
        for (uint8 index = 0; index < myEvent.claimedRSVPs.length; index++) {
            require(myEvent.claimedRSVPs[index] != attendee, "Already claimed");
        }

        // require that deposits are not already claimed by the event owner
        require(myEvent.paidOut == false, "Already paid out");

        // add the attendee to the claimedRSVPs list
        myEvent.claimedRSVPs.push(attendee);

        // sending eth back to the staker `https://solidity-by-example.org/sending-ether`
        (bool sent, ) = attendee.call{value: myEvent.deposit}("");

        // if this fails, remove the user from the array of claimed RSVPs
        if (!sent) {
            myEvent.claimedRSVPs.pop();
        }

        require(sent, "Failed to send ether");

        emit ConfirmedAttendee(eventId, attendee);
    }

    function confirmAllAttendees(bytes32 eventId) external {
        // look up event from our struct using the eventId
        CreateEvent storage myEvent = idToEvent[eventId];

        // require that msg.sender is the owner of the event - only the host should be able to check people in
        require(msg.sender == myEvent.eventOwner, "Not authorized");

        // confirm each attendee in the rsvp array
        for (uint8 index = 0; index < myEvent.confirmedRSVPs.length; index++) {
            confirmAttendee(eventId, myEvent.confirmedRSVPs[index]);
        }
    }

    function withdrawUnclaimedDeposits(bytes32 eventId) external {
        // look up event
        CreateEvent storage myEvent = idToEvent[eventId];

        // check that the money hasn't already been paid out
        require(!myEvent.paidOut, "Already piad");

        // check if it's been 7 days past myEvent.eventTimestamp
        require(
            block.timestamp >= (myEvent.eventTimestamp + 7 days),
            "Too early"
        );

        // only the event owner can withdraw
        require(msg.sender == myEvent.eventOwner, "Must be event owner");

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
            myEvent.paidOut == false;
        }

        require(sent, "Failed to send ether");

        emit DepositsPaidOut(eventId);
    }
}