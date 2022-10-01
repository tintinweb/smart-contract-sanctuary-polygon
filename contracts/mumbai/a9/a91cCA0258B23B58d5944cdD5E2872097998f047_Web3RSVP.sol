/**
 *Submitted for verification at polygonscan.com on 2022-09-30
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Web3RSVP{

    //event for when new event has been created 
    event NewEventCreated(
        bytes32 eventId,
        address creatorAddress,
        uint256 eventTimestamp,
        uint256 maxCapacity,
        uint256 deposit,
        string eventDataCID
    );

    //event for when someone rsvps
    event NewRSVP(bytes32 eventId, address attendeeAddress);

    //event for when an attendee has been confirmed
    event ConfirmedAttendee(bytes32 eventId, address attendeeAddress);

    //event for when deposits have been paid out
    event DepositsPaidOut(bytes32 eventId);

    //a struct that stores the event details 
    struct CreateEvent {
        bytes32 eventID;
        string eventDataCID;
        address eventOwner;
        uint256 eventTimestamp;
        uint256 deposit;
        uint256 maxCapacity;
        address[] confirmedRSVPs;
        address[] claimedRSVPs;
        bool paidOut;
    }
    // a mapping that maps a unique event id to the event
    mapping(bytes32 => CreateEvent) public idToEvent;

    //a function that creates new events
    function createNewEvent(
        uint256 eventTimestamp,
        uint256 deposit,
        uint256 maxCapacity,
        string calldata eventDataCID
    ) external {
        //generate an eventID based on other things passed in to generate a hash
        bytes32 eventId = keccak256(abi.encodePacked(
                                        msg.sender,
                                        address(this),
                                        eventTimestamp,
                                        deposit,
                                        maxCapacity
                                    )
                                );

        //to ensure the id isnt already claimed
        require(idToEvent[eventId].eventTimestamp == 0, "ALREADY REGISTERED");

        address[] memory confirmedRSVPs;
        address[] memory claimedRSVPs;

        //this creates a new CreateEvent struct and adds it to the idToEvent mapping
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

        emit NewEventCreated(eventId, msg.sender, eventTimestamp, maxCapacity, deposit, eventDataCID);
    }
    //function that allows people rsvp to events
    function createNewRSVP(bytes32 eventId) external payable{
        //look up event fro our mapping
        CreateEvent storage myEvent = idToEvent[eventId];

        //transfer deposit to our contract/ require that they sned in enough ether to cover deposit amt of the specific event
        require(msg.value == myEvent.deposit, "NOT ENOUGH");

        //require that the event hasnt alrready happened ref. to event timestamp 
        require(block.timestamp <= myEvent.eventTimestamp, "ALREADY HAPPENED");

        //make sure event is under max capacity
        require(
            myEvent.confirmedRSVPs.length < myEvent.maxCapacity, "EVENT FULL"
        );

        //require that msg.sender hasnt already RSVP`d
        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++){
            require(myEvent.confirmedRSVPs[i] != msg.sender);
        }

        myEvent.confirmedRSVPs.push(payable(msg.sender));

        emit NewRSVP(eventId, msg.sender);
    }
    // afunction that checks in single attendees
    function confirmAttendee(bytes32 eventId, address attendee) public {
        //look up event from our struct using the event id
        CreateEvent storage myEvent = idToEvent[eventId];

        //ensure only host of event can confirm attendee
        require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED");

        //require that attendee trying to check in actually RSVP`d
        address rsvpConfirm;
        for(uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++){
            if(myEvent.confirmedRSVPs[i] == attendee){
                rsvpConfirm = myEvent.confirmedRSVPs[i];
            }
        }
        require(rsvpConfirm == attendee, "NO RSVP TO CONFIRM");
        
        //reuire that attendee hasnt already claiimed
        for(uint8 i = 0; i < myEvent.claimedRSVPs.length; i++){
            require(myEvent.claimedRSVPs[i] != attendee, "ALREADY CLAIMED");
        }

        //require that event owner hasnt claimed deposits
        require(myEvent.paidOut == false, "ALREADY PAID OUT");

        //add attendee to claimed RSVPs list
        myEvent.claimedRSVPs.push(attendee);

        //sending eth back to the staker
        (bool sent,) = attendee.call{value: myEvent.deposit}("");

        // if it fails, stll remove the person from the claimedRSVPs
        if(!sent){
            myEvent.claimedRSVPs.pop();
        }

        require(sent, "ETHER NOT SENT");
        
        emit ConfirmedAttendee(eventId, attendee);
    }

    //function that confirms everyone that RSVPd at once
    function confirmAllAttendees(bytes32 eventId) external {
        //look up event from our struct with the event ID
        CreateEvent storage myEvent = idToEvent[eventId];

        //ensure the caller is the event Owner
        require(msg.sender == myEvent.eventOwner, "UNAUTHORIZED");

        //confirm each attendee in the RSVP array
        for(uint8 i =0; i < myEvent.confirmedRSVPs.length; i++){
            confirmAttendee(eventId, myEvent.confirmedRSVPs[i]);
        }
    }
    //function that sends all unclaimed deposits back to event Owner
    function withdrawUnclaimedDeposits(bytes32 eventId) external {

        //look up event
        CreateEvent storage myEvent  = idToEvent[eventId];

        //check out the paidOut  boolean is still false to be sure mone hasnt been paid out
        require(!myEvent.paidOut, "ALREADY PAID");
        
        //check if its been 7 days past the event

        require(block.timestamp >= (myEvent.eventTimestamp + 7 days), "TOO EARLY");

        //only event owner can withdraw
        require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED");

        //calculate how many  people did not come and how much you would be paying
        uint256 unclaimed = myEvent.confirmedRSVPs.length - myEvent.claimedRSVPs.length;
        uint256 payout = unclaimed * myEvent.deposit;

        // mark as paid to send to avoid reentrancy
        myEvent.paidOut = true;

        //send the payout to the owner
        (bool sent, ) = msg.sender.call{value: payout}("");

        //if this fails
        if(!sent){
            myEvent.paidOut  = false;
        }

        require(sent, "PAYOUT FAILED");

        emit DepositsPaidOut(eventId);
    }
}