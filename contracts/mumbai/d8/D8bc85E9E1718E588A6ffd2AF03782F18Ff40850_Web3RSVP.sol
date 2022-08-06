/**
 *Submitted for verification at polygonscan.com on 2022-08-05
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Web3RSVP {
    // Events for communicating with our Subgraph
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

    
    // Creation of a new event struct
    struct CreateEvent {
        bytes32 eventId; // Unique identifier for our new event entity
        string eventDataCID; // CID to data about the event that we will be stored on IPFS
        address eventOwner; // Address of the person who created the event
        uint256 eventTimestamp; // Timestamp of when the event was created
        uint256 deposit; // Required deposit amount that attendees will have to deposit when they RSVP
        uint256 maxCapacity; // How many people can attend the event
        address[] confirmedRSVPs; // RSVPs that were confirmed 
        address[] claimedRSVPs; // RSVPs made 
        bool paidOut; // Did the event return all deposits to everyone? 
    }

    // Relationship between event identifier (eventId) to the CreateEvent struct 
    mapping(bytes32 => CreateEvent) public idToEvent;

    // Create Event 
    function createNewEvent(
        uint256 eventTimestamp, 
        uint256 deposit,
        uint256 maxCapacity,
        string calldata eventDataCID
    ) external {
        // Creating a unique identifier by hashing togehter event specific information
        bytes32 eventId = keccak256(
            abi.encodePacked(
                msg.sender,
                address(this), // address of the contract instance
                eventTimestamp,
                deposit,
                maxCapacity
            )
        );

        address[] memory confirmedRSVPs;
        address[] memory claimedRSVPs;

        // Adding to our event storage 
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

    // RSVP to an Event by paying a deposit
    function createNewRSVP(bytes32 eventId) external payable {
        CreateEvent storage myEvent = idToEvent[eventId];

        require(msg.value == myEvent.deposit, "NOT ENOUGH");

        require(block.timestamp <= myEvent.eventTimestamp, "ALREADY HAPPENED");

        require(
            myEvent.confirmedRSVPs.length < myEvent.maxCapacity,
            "This event has reached capacity"
        );

        for(uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            require(myEvent.confirmedRSVPs[i] != msg.sender, "ALREADY CONFIRMED");
        }

        myEvent.confirmedRSVPs.push(payable(msg.sender)); // casting msg.sender as an address that can recieve funds (for future purposes)

        emit NewRSVP(eventId, msg.sender);
    }

    // Check In Attendees
    function confirmAttendee(bytes32 eventId, address attendee) public {
        CreateEvent storage myEvent = idToEvent[eventId];

        // only the event owner can confirm an attendee
        require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED");

        // check that the attendee RSVP'd to the event
        address rsvpConfirm;

        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++){
            if(myEvent.confirmedRSVPs[i] == attendee){
                rsvpConfirm = myEvent.confirmedRSVPs[i]; // getting the payable address of the attendee 
            }
        }

        require(rsvpConfirm == attendee, "NO RSVP TO CONFIRM");

        // require that attendee is NOT already in the claimedRSVPs list AKA make sure they haven't already checked in
        for (uint8 i = 0; i < myEvent.claimedRSVPs.length; i++){
            require(myEvent.claimedRSVPs[i] != attendee, "ALREADY CLAIMED");
        }

        // require that deposits are not already claimed by the event owner
        require(!myEvent.paidOut, "ALREADY PAID OUT: CANNOT CONFIRM ATTENDEE.");

        // add the attendee to the claimedRSVPs list
        myEvent.claimedRSVPs.push(attendee);

        // sending eth back to the staker `https://solidity-by-example.org/sending-ether`
        (bool sent,) = attendee.call{ value: myEvent.deposit }("");

        // if this fails, remove the user from the array of claimed RSVPs
        if (!sent) {
            myEvent.claimedRSVPs.pop();
        }

        require(sent, "Failed to send Ether");

        emit ConfirmedAttendee(eventId, attendee);
    }


    // Confirm all at once
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

    // Send Unclaimed Deposits to Event Organizer
    function withdrawUnclaimedDeposits(bytes32 eventId) external {
        // look up event
        CreateEvent memory myEvent = idToEvent[eventId];

        // check that the paidOut boolean still equals false AKA the money hasn't already been paid out
        require(!myEvent.paidOut, "ALREADY PAID OUT: CANNOT WITHDRAW UNCLAIMED DEPOSITS.");

        // check if it's been 7 days past myEvent.eventTimestamp
        require(
            block.timestamp >= (myEvent.eventTimestamp + 7 days),
            "TOO EARLY: 7 DAYS MUST PASS BEFORE WITHDRAWING UNCLAIMED DEPOSITS."
        );

        // only the event owner can withdraw
        require(msg.sender == myEvent.eventOwner, "MUST BE EVENT OWNER TO WITHDRAW.");

        // calculate how many people didn't claim by comparing
        uint256 unclaimed = myEvent.confirmedRSVPs.length - myEvent.claimedRSVPs.length;

        uint256 payout = unclaimed * myEvent.deposit;

        // mark as paid before sending to avoid reentrancy attack
        myEvent.paidOut = true;

        // send the payout to the owner
        (bool sent, ) = msg.sender.call{value: payout}("");

        // if this fails
        if (!sent) {
            myEvent.paidOut == false;
        }

        require(sent, "Failed to send Ether");

        emit DepositsPaidOut(eventId);
    }
}