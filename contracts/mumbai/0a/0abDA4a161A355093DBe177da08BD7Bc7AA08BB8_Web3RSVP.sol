/**
 *Submitted for verification at polygonscan.com on 2022-08-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

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
        // Generate an eventID based on other things passed in to generate a hash
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

        // This creates a new CreateEvent struct and adds it to the idToEvent mapping
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

    function createNewRSVP(bytes32 eventId) external payable {
        // Look up event from our mapping
        CreateEvent storage myEvent = idToEvent[eventId];

        // Transfer deposit to our contract / Require that they send in enough ETH to cover the deposit requirement of this specific event
        require(msg.value == myEvent.deposit, "NOT ENOUGH");

        // Require that the event hasn't already happened (<eventTimestamp>)
        require(block.timestamp <= myEvent.eventTimestamp, "ALREADY HAPPENED");

        // Make sure event is under max capacity
        require(
            myEvent.confirmedRSVPs.length < myEvent.maxCapacity,
            "This event has reached capacity"
        );

        // Require that msg.sender isn't already in myEvent.confirmedRSVPs AKA hasn't already RSVP'd
        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            require(myEvent.confirmedRSVPs[i] != msg.sender, "ALREADY CONFIRMED");
        }

        myEvent.confirmedRSVPs.push(payable(msg.sender));

        emit NewRSVP(eventId, msg.sender);
    }

    function confirmAttendee(bytes32 eventId, address attendee) public {
        // Look up event
        CreateEvent storage myEvent = idToEvent[eventId];

        // Require that msg.sender is the owner of the event - only the host should be able to check people in
        require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED");

        // Require that attendee trying to check in actually RSVP'd
        address rsvpConfirm;

        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            if(myEvent.confirmedRSVPs[i] == attendee){
                rsvpConfirm = myEvent.confirmedRSVPs[i];
            }
        }

        require(rsvpConfirm == attendee, "NO RSVP TO CONFIRM");

        // Require that attendee is NOT already in the claimedRSVPs list AKA make sure they haven't already checked in
        for (uint i = 0; i < myEvent.claimedRSVPs.length; i++) {
            require(myEvent.claimedRSVPs[i] != attendee, "ALREADY CLAIMED");
        }

        // Require that deposits are not already claimed by the event owner
        require(myEvent.paidOut == false, "ALREADY PAID OUT");

        // Add the attendee to the claimedRSVPs list
        myEvent.claimedRSVPs.push(attendee);

        // Sendind ETH back to the staker `https://solidity-by-example.org/sending-ether`
        (bool sent,) = attendee.call{value: myEvent.deposit}("");

        //If this fails, remove the user from the array of claimed RSVPs
        if (!sent) {
            myEvent.claimedRSVPs.pop();
        }

        require(sent, "Failed to send Ether");

        emit ConfirmedAttendee(eventId, attendee);
    }

    function confirmAllAttendees(bytes32 eventId) external {
        // Look up event from our struct with the eventId
        CreateEvent memory myEvent = idToEvent[eventId];

        // Make sure you require that msg.sender is the owner of the event
        require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED");

        // Confirm each attendee in the rsvp array
        for (uint i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            confirmAttendee(eventId, myEvent.confirmedRSVPs[i]);
        }
    }

    function withdrawUnclaimedDeposits(bytes32 eventId) external {
        // Look up event
        CreateEvent storage myEvent = idToEvent[eventId];

        // Check that the paidOut boolean still equals false AKA the money hasn't already been paid out
        require(!myEvent.paidOut, "ALREADY PAID");

        // Check if it's been 7 days past myEvent.eventTimestamp
        require(
            block.timestamp >= (myEvent.eventTimestamp + 7 days), 
            "TOO EARLY"
        );

        // Only the event owner can withdraw
        require(
            msg.sender == myEvent.eventOwner, "MUST BE EVENT OWNER");

        // Calculate how many people didn't claim by comparing
        uint256 unclaimed = myEvent.confirmedRSVPs.length - myEvent.claimedRSVPs.length;

        uint payout = unclaimed * myEvent.deposit;

        // Mark as paid before sendind to avoir reentrancy attack
        myEvent.paidOut = true;

        // Send the payout to the owner
        (bool sent, ) = msg.sender.call{value: payout}("");

        // If this fails
        if (!sent) {
            myEvent.paidOut == false;
        }

        require(sent, "Failed to send Ether");

        emit DepositsPaidOut(eventId);
    }
}