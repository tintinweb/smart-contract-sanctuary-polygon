/**
 *Submitted for verification at polygonscan.com on 2022-05-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Web3RSVP {
    address payable owner; // we're not using this variable, we don't need it right? @terps

    event NewEventCreated(
        bytes32 eventID,
        address creatorAddress,
        uint256 eventTimestamp,
        uint256 maxCapacity,
        uint256 deposit,
        uint256 ticketPrice
    );

    event NewRSVP(bytes32 eventID, address attendeeAddress);

    event ConfirmedAttendee(bytes32 eventID, address attendeeAddress);

    event DepositsPaidOut(bytes32 eventID);

    struct CreateEvent {
        bytes32 eventId;
        string eventName; // I think we do need to store this on-chain - how else are we going to persist the event name to show it on the front end? @terps 
        address eventOwner;
        uint256 eventTimestamp;
        uint256 deposit;
        uint256 ticketPrice;
        uint256 maxCapacity;
        address[] confirmedRSVPs;
        address[] claimedRSVPs;
        bool paidOut;
    }

    CreateEvent public createevent; // we're also not using this ? @terps
    mapping(bytes32 => CreateEvent) public idToEvent;

    function createNewEvent(
        uint256 eventTimestamp,
        uint256 deposit,
        uint256 maxCapacity,
        uint256 ticketPrice,
        string memory eventName
    ) external {
        // generate an eventID based on other things passed in to generate a hash
        bytes32 eventId = keccak256(
            abi.encodePacked(
                msg.sender,
                address(this),
                eventTimestamp,
                deposit,
                maxCapacity,
                ticketPrice
            )
        );

        address[] memory confirmedRSVPs; 
        address[] memory claimedRSVPs;
        

        //this creates a new CreateEvent struct and adds it to the idToEvent mapping
        idToEvent[eventId] = CreateEvent(
            eventId,
            eventName,
            msg.sender,
            eventTimestamp,
            deposit,
            ticketPrice,
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
            ticketPrice
        );
    }

    function createNewRSVP(bytes32 eventId) external payable {
        // look up event
        CreateEvent storage myEvent = idToEvent[eventId];

        //require that the value is equal to the deposit plus the price
        require(msg.value == myEvent.deposit + myEvent.ticketPrice, "NOT ENOUGH");

        //require that the event hasn't already happened (<eventTimestamp)
        require(block.timestamp <= myEvent.eventTimestamp, "ALREADY HAPPENED");

        //make sure event is under max capacity
        require(
            myEvent.confirmedRSVPs.length < myEvent.maxCapacity,
            "This event has reached capacity"
        );

        //require that msg.sender isn't already in myEvent.confirmedRSVPs
        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            require(myEvent.confirmedRSVPs[i] != msg.sender, "ALREADY CONFIRMED");
        }

        myEvent.confirmedRSVPs.push(payable(msg.sender)); 

        
        emit NewRSVP(eventId, msg.sender);
    }

    function confirmGroup(bytes32 eventId, address[] calldata attendees) external {
        // look up event
        CreateEvent memory myEvent = idToEvent[eventId];

        // make sure you require that msg.sender is the owner of the event
        require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED");

        //confirm each attendee
        for (uint8 i = 0; i < attendees.length; i++) {
            confirmAttendee(eventId, attendees[i]);
        }
    }

    function confirmAttendee(bytes32 eventId, address attendee) public {
        // look up event
        CreateEvent storage myEvent = idToEvent[eventId];

        // make sure you require that msg.sender is the owner of the event
        require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED");

        // require that attendee is in myEvent.confirmedRSVPs
        // ?
        address rsvpConfirm;

        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            if(myEvent.confirmedRSVPs[i] == attendee){
                rsvpConfirm = myEvent.confirmedRSVPs[i];
            }
        }

        require(rsvpConfirm == attendee, "NO RSVP TO CONFIRM");


        // require that attendee is NOT in the claimedRSVPs list
        // is there an array.contains() method?
        for (uint8 i = 0; i < myEvent.claimedRSVPs.length; i++) {
            require(myEvent.claimedRSVPs[i] != msg.sender);
        }

        // require that deposits are not already claimed
        require(myEvent.paidOut == false);

        // add them to the claimedRSVPs list
        // this wont work ?
        myEvent.claimedRSVPs.push(attendee);

        // sending eth back to the staker https://solidity-by-example.org/sending-ether
        (bool sent,) = attendee.call{value: myEvent.deposit}("");
        // require(sent, "Failed to send Ether");
        //what happens if this fails?
        if(!sent){
            // delete myEvent.claimedRSVPs[attendee];
        }

        emit ConfirmedAttendee(eventId, msg.sender);
    }

    function withdrawMoney(bytes32 eventId) external {
        //the owner of the event can withdraw unclaimed deposits AND all ticket sales 

        // look up event
        CreateEvent memory myEvent = idToEvent[eventId];

        // check if already paid
        require(!myEvent.paidOut, "ALREADY PAID");

        // check if it's been 7 days past myEvent.eventTimestamp
        require(
            block.timestamp >= (myEvent.eventTimestamp + 7 days),
            "TOO EARLY"
        );

        // only the event owner can withdraw
        require(msg.sender == myEvent.eventOwner, "MUST BE EVENT OWNER");

        // calculate how many people didn't claim by comparing
        uint256 unclaimed = myEvent.confirmedRSVPs.length - myEvent.claimedRSVPs.length;

        uint256 payout = unclaimed * myEvent.deposit;

        uint256 ticketRevenue = myEvent.confirmedRSVPs.length * myEvent.ticketPrice;

        //save both to payout variable
        payout = payout + ticketRevenue;

        // mark as paid before sending to avoid reentrancy attack
        myEvent.paidOut = true;

        // send the payout to the owner
        (bool sent, ) = msg.sender.call{value: payout}("");
        // require(sent, "Failed to send Ether");
        // what happens if this fails?
        if(!sent){
            myEvent.paidOut == false;
        }

        emit DepositsPaidOut(eventId);
    }
}