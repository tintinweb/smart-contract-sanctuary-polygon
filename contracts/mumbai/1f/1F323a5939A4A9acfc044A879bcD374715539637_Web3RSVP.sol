/**
 *Submitted for verification at polygonscan.com on 2022-08-31
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// import "hardhat/console.sol";

contract Web3RSVP {
    // define events
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

    // event definition ends here

    // new event struct - properties of an event
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

    // map ID to event
    mapping(bytes32 => CreateEvent) public idToEvent;

    function createNewEvent(
        uint256 eventTimestamp,
        uint256 deposit,
        uint256 maxCapacity,
        string calldata eventDataCID
    ) external {
        // generate a unique eventID based on other things passed in to generate a hash to prevent hash collisions
        bytes32 eventId = keccak256(
            abi.encodePacked(
                msg.sender,
                address(this),
                eventTimestamp,
                deposit,
                maxCapacity
            )
        );

        // list of confirmed RSVPs
        address[] memory confirmedRSVPs;
        // list of RSVP'd persons who checked in for the event
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

        // emit event
        emit NewEventCreated(eventId, msg.sender, eventTimestamp, maxCapacity, deposit, eventDataCID);
    }

    // book a spot in the event
    function createNewRSVP(bytes32 eventId) external payable {
        // look up to event from the mapping
        CreateEvent storage myEvent = idToEvent[eventId];

        // transfer refundable deposit to our contract
        require(msg.value == myEvent.deposit, "NOT ENOUGH");

        // require that the event hasn't happened yet
        require(block.timestamp <= myEvent.eventTimestamp, "ALREADY HAPPENED");

        // make sure the event is under maximum capacity
        require(
            myEvent.confirmedRSVPs.length < myEvent.maxCapacity,
            "This event has reached capacity"
        );

        // check that the sender hasn't already booked a spot for the event
        // avoid double booking
        for(uint i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            require(myEvent.confirmedRSVPs[i] != msg.sender, "ALREADY CONFIRMED");
        }

        // add sender wallet address to list of confirmedRSVPs
        myEvent.confirmedRSVPs.push(payable(msg.sender));

        // emit RSVP event
        emit NewRSVP(eventId, msg.sender);
    }

    function confirmAttendee(bytes32 eventId, address attendee) public {
        // look up to event from the mapping
        CreateEvent storage myEvent = idToEvent[eventId];

        // only the owner of the event should check people in
        require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED");

        // attendee checking in should have RSVP'd
        address rsvpConfirm;
        
        for (uint i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            if(myEvent.confirmedRSVPs[i] == attendee) {
                rsvpConfirm = myEvent.confirmedRSVPs[i];
            }
        }

        // if attendee is not found in list of confirmedRSVPs, deny admission to event
        require(rsvpConfirm == attendee, "NO RSVP TO CONFIRM");

        // make sure attendee hasn't confirmed yet - an attendee is only admitted once
        for(uint8 i = 0; i < myEvent.claimedRSVPs.length; i++) {
            require(myEvent.claimedRSVPs[i] != attendee, "ALREADY CLAIMED");
        }

        // make sure deposits haven't been paid to attendee
        require(myEvent.paidOut == false, "ALREADY PAID OUT");

        // add the attendee to the claimedRSVPs list
        myEvent.claimedRSVPs.push(attendee);

        // refund eth back to attendee
        (bool sent,) = attendee.call{value: myEvent.deposit}("");

        // if refund fails, remove attendee from claimedRSVP list
        if (!sent) {
            myEvent.claimedRSVPs.pop();
        }

        require(sent, "failed to refund eth");

        emit ConfirmedAttendee(eventId, attendee);
    }

    function confirmAllAttendees(bytes32 eventId) external {
        CreateEvent memory myEvent = idToEvent[eventId];

        // only the owner of the event should check people in
        require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED");

        for(uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            confirmAttendee(eventId, myEvent.confirmedRSVPs[i]);
        }
    }

    function withdrawUnclaimedDeposits(bytes32 eventId) external {
        // look up event
        CreateEvent memory myEvent = idToEvent[eventId];

        // only event owner can withdraw
        require(msg.sender == myEvent.eventOwner, "MUST BE EVENT OWNER TO WITHDRAW");

        // check if the eth hasn't been paid out
        require(!myEvent.paidOut, "ALREADY PAID");

        // check if it's been 7 days past the event
        require(block.timestamp >= (myEvent.eventTimestamp + 7 days), "TOO EARLY");

        // calculate how many people didn't claim
        uint256 unclaimed = myEvent.confirmedRSVPs.length - myEvent.claimedRSVPs.length;

        uint256 payout = unclaimed * myEvent.deposit;

        // mark as paid to avoid reentrancy attack
        myEvent.paidOut = true;

        // refund
        (bool sent,) = msg.sender.call{value: payout}("");

        if(!sent) {
            myEvent.paidOut = false;
        }

        require(sent, "Failed to send Ether");

        emit DepositsPaidOut(eventId);
    }
}