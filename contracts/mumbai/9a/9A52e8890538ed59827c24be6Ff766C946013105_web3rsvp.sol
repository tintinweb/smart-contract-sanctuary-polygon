/**
 *Submitted for verification at polygonscan.com on 2022-08-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract web3rsvp {

    event NewEventCreated(
        bytes32 eventID,
        address creatorAddress,
        uint256 eventTimestamp,
        uint256 maxCapacity,
        uint256 deposit,
        string eventDataCID
    );

    event NewRsvp(
        bytes32 eventID, address attendeeAddress
    );

    event ConfirmedAttendee(bytes32 eventID, address attendeeAddress);

    event DepositsPaidOut(bytes32 eventID);

    struct CreateEvent {
        bytes32 evenTd;
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
    ) external{

        //generate an event Id based on other event details passed in to generate a hash
        bytes32 eventId = keccak256(abi.encodePacked(
            msg.sender,
            address(this),
            eventTimestamp,
            deposit,
            maxCapacity)
        );

        
        address[] memory confirmedRSVPs;
        address[] memory claimedRSVPs;

        //this creates a new createEvent struct and add it to the idToEvent mapping
        idToEvent[eventId]= CreateEvent(
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

        // make sure this id isn't already claimed
        require(idToEvent[eventId].eventTimestamp == 0, "ALREADY REGISTERED");
       
        emit NewEventCreated(
            eventId,
            msg.sender,
            eventTimestamp,
            maxCapacity,
            deposit,
            eventDataCID
        );

    }

    function createNewRSVP(bytes32 eventId) external payable{

        //lookup event from mapping using passed event Id
        CreateEvent storage myEvent = idToEvent[eventId];

        //check if user has sufficient deposits
        require(msg.value >= myEvent.deposit, "You do not have sufficient balance to RSVP!");

        //check if the event already started
        require(block.timestamp <= myEvent.eventTimestamp, "Already Started");

        //check if the max capacity is not exceed
        require(
            myEvent.confirmedRSVPs.length < myEvent.maxCapacity, "Already Filled"
        );

        //Check if the user already in the confimedRSVPs
        for(uint8 i=0; i < myEvent.confirmedRSVPs.length; i++){
            require(myEvent.confirmedRSVPs[i] != msg.sender, "User already confirmed!");
        }

        myEvent.confirmedRSVPs.push(payable(msg.sender));

        emit NewRsvp(eventId, msg.sender);
    }

    function confirmAttendee(bytes32 eventId, address attendee) public {

        //lookup event from our struct using eventId
        CreateEvent storage myEvent = idToEvent[eventId];

        //require msg.sender should be the owner of the event
        require(msg.sender == myEvent.eventOwner, "Not Authorized");

        //require that the attendee trying to checkin is actually in confirmedRSVPs
        address rsvpConfirm;
        for(uint8 i=0; i < myEvent.confirmedRSVPs.length;i++){
            if(myEvent.confirmedRSVPs[i] == attendee){
                rsvpConfirm = myEvent.confirmedRSVPs[i] ;
            }
        }
         require(rsvpConfirm == attendee, "Attendee not Found");

         //check they haven't already checked in AKA they should not be in claimed RSVPs
         
         for(uint8 i=0; i < myEvent.claimedRSVPs.length; i++){
            require(myEvent.claimedRSVPs[i] != attendee, "Already Checked IN");
         }

         //check if the attendee aleay paidout
         require(myEvent.paidOut == false, "Already Paid Out!");

         //add attendee to claimedrsvp
         myEvent.claimedRSVPs.push(attendee);

         //sending eth back to attendee `https://solidity-by-example.org/sending-ether`
         (bool sent,) = attendee.call{value: myEvent.deposit}("");

         //if this fails, remove the user from claimedrsvp
         if(!sent){
            myEvent.claimedRSVPs.pop();
         }
         require(sent, "Failed to send Ether");

         emit ConfirmedAttendee(eventId, attendee);
    }

    function confirmAllAttendees(bytes32 eventId) external{
        //look up for the event via eventId
        CreateEvent storage myEvent = idToEvent[eventId];

        //caller must be owner
        require(myEvent.eventOwner == msg.sender, "Not Authorized");

        //confirm each attendee in RSVP array
        for(uint8 i=0; i < myEvent.confirmedRSVPs.length; i++){
            confirmAttendee(eventId, myEvent.confirmedRSVPs[i]);
        }
    }

    function withdrawUnclaimedDeposits(bytes32 eventId) external{
        //lookup for the event
        CreateEvent storage myEvent = idToEvent[eventId];

        //check if the money hasn't been paid
        require(!myEvent.paidOut , "Already paid, No unclaimed deposits");

        //check if it's been 7 days past the event.timestamp
        require(block.timestamp >= (myEvent.eventTimestamp+7 days), "Too Early");

        //only event owner can withdraw
        require(msg.sender == myEvent.eventOwner, "Not Authorized");

        //calculate how many people didn't claim
        uint256 unclaimed = myEvent.confirmedRSVPs.length - myEvent.claimedRSVPs.length;
        uint256 payout = unclaimed * myEvent.deposit;

         // mark as paid before sending to avoid reentrancy attack
        myEvent.paidOut = true; 

        //send payout to owner
        (bool sent,) = msg.sender.call{value: payout}("");

        //if this fails
        if(!sent){
            myEvent.paidOut = false;
        }

        require(sent,"Falied to send Ether");
        emit DepositsPaidOut(eventId);
    }
}