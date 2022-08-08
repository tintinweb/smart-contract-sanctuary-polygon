/**
 *Submitted for verification at polygonscan.com on 2022-08-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Web3RSVP {

    event NewEventCreated (
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
        uint256 deposit;
        uint256 maxCapacity;
        address[] confirmedRSVPs;
        address[] claimedRSVPs;
        bool paidOut;
   }

    mapping(bytes32 => CreateEvent) public idToEvent;

    // Create a new Event on the blockchain
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

     // Function for a user to RSVP into a existing event
    function createNewRSVP(bytes32 eventId) external payable {
        CreateEvent storage eventRSVP = idToEvent[eventId];
        // Ensure that the value of their deposit is sufficient for that event’s deposit requirement
        require(eventRSVP.deposit == msg.value, "Not enough coins sent");
        // Ensure that the event hasn’t already started
        require(eventRSVP.eventTimestamp >= block.timestamp, "The event start date has already passed");
        // Ensure that the event is under max capacity
        require(eventRSVP.maxCapacity > eventRSVP.confirmedRSVPs.length, "This event is already full");
        // Ensure the user is not already registered to this event
        for (uint8 i = 0; i < eventRSVP.confirmedRSVPs.length; i++) {
            require(eventRSVP.confirmedRSVPs[i] != msg.sender, "You are already attending this event");
        }

        eventRSVP.confirmedRSVPs.push(payable(msg.sender));

        emit NewRSVP(eventId, msg.sender);
    }

    // Function to confirm an attendee at an event
    function confirmAttendee(bytes32 eventId, address attendee) public {
        CreateEvent storage currentEvent = idToEvent[eventId];
        bool isAttendee = false;

        // Ensure the owner is confirming the attendee
        require(msg.sender == currentEvent.eventOwner, "Only the owner can confirm an attendee");

        // Ensure the user is registered to this event
        for (uint8 i = 0; i < currentEvent.confirmedRSVPs.length; i++) {
            if (currentEvent.confirmedRSVPs[i] == attendee) {
                isAttendee = true;
            }
        }
        require(isAttendee, "This address is not registered for this event");

        // Ensure that attendee hasn't already checked in
        for (uint8 i = 0; i < currentEvent.claimedRSVPs.length; i++) {
            require(currentEvent.claimedRSVPs[i] != attendee, "This attendee already claimed its coins");
        }

        // Ensure deposits are not already claimed by the event owner
        require(currentEvent.paidOut == false, "Owner already claimed deposits");

        currentEvent.claimedRSVPs.push(attendee);
        // sending eth back to the staker `https://solidity-by-example.org/sending-ether`
        (bool sent,) = attendee.call{value: currentEvent.deposit}("");

        // if this fails, remove the user from the array of claimed RSVPs
        if (!sent) {
            currentEvent.claimedRSVPs.pop();
        }

        require(sent, "Failed to send Ether");

        emit ConfirmedAttendee(eventId, attendee);
    }

    // Function to confirm all attendees at an event
    function confirmAllAttendees(bytes32 eventId) external {
        // look up event from our struct with the eventId
        CreateEvent memory currentEvent = idToEvent[eventId];
    
        // make sure you require that msg.sender is the owner of the event
        require(msg.sender == currentEvent.eventOwner, "Only the owner can confirm attendees");
    
        // confirm each attendee in the rsvp array
        for (uint8 i = 0; i < currentEvent.confirmedRSVPs.length; i++) {
            confirmAttendee(eventId, currentEvent.confirmedRSVPs[i]);
        }
    }

    // Function to withdraw unclaimed deposits
    function withdrawUnclaimedDeposits(bytes32 eventId) external {
        CreateEvent memory currentEvent = idToEvent[eventId];
    
        // Ensure that the money hasn't already been paid out
        require(!currentEvent.paidOut, "Money already withdraw for this event");
    
        // check if it's been 7 days past currentEvent.eventTimestamp
        require(
            block.timestamp >= (currentEvent.eventTimestamp + 7 days),
            "You need to wait 7 days to withdraw unclaimed deposits"
        );
    
        // only the event owner can withdraw
        require(msg.sender == currentEvent.eventOwner, "Only the owner can withdraw");
    
        // calculate how many people didn't claim by comparing
        uint256 unclaimed = currentEvent.confirmedRSVPs.length - currentEvent.claimedRSVPs.length;
    
        uint256 payout = unclaimed * currentEvent.deposit;
    
        // mark as paid before sending to avoid reentrancy attack
        currentEvent.paidOut = true;
    
        // send the payout to the owner
        (bool sent, ) = msg.sender.call{value: payout}("");
    
        // if this fails
        if (!sent) {
            currentEvent.paidOut == false;
        }
    
        require(sent, "Failed to send Ether");

        emit DepositsPaidOut(eventId);
    }
}