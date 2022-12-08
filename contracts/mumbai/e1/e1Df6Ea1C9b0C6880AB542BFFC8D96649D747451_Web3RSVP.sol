/**
 *Submitted for verification at polygonscan.com on 2022-12-07
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

contract Web3RSVP {
    //EVENTS
    event NewEventCreated(
        bytes32 eventID,
        address creatorAddress,
        uint256 eventTimestamp,
        uint256 maxCapacity,
        uint256 deposit,
        string eventDataCID
    );

    event NewRSVP(bytes32 eventID, address attendeeAddress);
    event ConfirmedAttendee(bytes32 eventID,address attendeeAddress);
    event DepositsPaidOut(bytes32 eventID);

    //1.Create Event Struct
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
    //2. Mapping for all events with unique ID;
    mapping(bytes32 => CreateEvent) public idToEvent;

    //3.Create event Function
    function createNewEvent(
        uint256 eventTimestamp,
        uint256 deposit,
        uint256 maxCapacity,
        string calldata eventDataCID
    ) external {
        //Create an EventID with all information so its unique
        bytes32 eventID = keccak256(
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

        //Add specific event to mapping to be called later
        idToEvent[eventID] = CreateEvent(
            eventID,
            eventDataCID,
            msg.sender,
            eventTimestamp,
            deposit,
            maxCapacity,
            confirmedRSVPs,
            claimedRSVPs,
            false
        );

        emit NewEventCreated(eventID, msg.sender, eventTimestamp, maxCapacity, deposit, eventDataCID);
    }

    //4. Function to Create new rsvp
    function createNewRSVP(bytes32 eventId) external payable{
        //1.check rsvp hasn't been confirmed
        //2. Make sure event hasn't happened
        //3. Check to make sure they have eenough for deposit

        //1. Look up event for mapping
        CreateEvent storage myEvent = idToEvent[eventId];

        //transfer deposit to our contract/ require that they send in enough ETH to cover
        require(msg.value == myEvent.deposit, "NOT ENOUGH");

        //Require the event hasn't already happened
        require(block.timestamp <= myEvent.eventTimestamp, "ALREADY HAPPENED");

        //Make sure event is under max capacity
        require(myEvent.confirmedRSVPs.length < myEvent.maxCapacity, "this event has reached capacity");

        //reuqire that msg.sender isn't already in myEvent.confirmed RSPVS 
        for(uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++){
            require(myEvent.confirmedRSVPs[i] != msg.sender, "ALREADY CONFIRMED");

        }

        myEvent.confirmedRSVPs.push(payable(msg.sender));

        emit NewRSVP(eventId, msg.sender);

    }

    function confirmAttendee(bytes32 eventId, address attendee) public {
        //check that they are confirmedrspvs

        //look up event from our struct
        CreateEvent storage myEvent = idToEvent[eventId];

        //require that msg.sender is the owner of the event - only the hose should be able to 
        require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED");

        //require that attendee trying to check in actually RSVP's
        address rsvpConfirm;

        for(uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++){
            if(myEvent.confirmedRSVPs[i] == attendee){
                rsvpConfirm = myEvent.confirmedRSVPs[i];
            }

        }

        require(rsvpConfirm == attendee, "NO RSVP TO CONFIRM");

        //require that attendee is NOT already in the claimedRSVPs list AKA make sure they 
        for(uint8 i = 0; i < myEvent.claimedRSVPs.length; i++){
            require(myEvent.claimedRSVPs[i] != attendee,"ALREADY CLAIMED");
        }

        //require that deposits are not already claimed by the event owner
        require(myEvent.paidOut == false, "ALREADY PAID OUT");

        //add the attendee to the claimedRSVPS list
        myEvent.claimedRSVPs.push(attendee);

        //sending eth back to the staker 
        (bool sent, ) = attendee.call{value: myEvent.deposit}("");

        //if this failes, remove the user from the array of claimed RSVPS
        if(!sent){
            myEvent.claimedRSVPs.pop();
        }

        require(sent, "Failed to send Ether");
        
        emit ConfirmedAttendee(eventId, attendee);
    }

    //5. Confirm all attendees in one go 
    function confirmAllAttendees(bytes32 eventId) external{
        //look up event 
        CreateEvent memory myEvent = idToEvent[eventId];

        //make sure you require that msg.sender is the owner of the event
        require(myEvent.eventOwner == msg.sender,"NOT AUTHORIZED");

        //confirm each attendee in the rsvp array 
        for(uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++){
            confirmAttendee(eventId, myEvent.confirmedRSVPs[i]);
        }
    }

    //6. withdraw unclaimed Deposits
    function withdrawUnclaimedDeposits(bytes32 eventId) external{
        
        CreateEvent memory myEvent = idToEvent[eventId];

        //check that the paidOut boolean still equals false AKA the moeny hasn't already been taken out
        require(!myEvent.paidOut,"ALREADY PAID");

        //check if its been 7 days past myEvent.eventTimestamp
        require(block.timestamp >= myEvent.eventTimestamp + 7 days,"TOO EARLY");

        //only the event owner can withdraw
        require(myEvent.eventOwner == msg.sender,"MUST BE EVENT OWNER");

        //calculate how many people didn't claim
        uint256 unclaimed = myEvent.confirmedRSVPs.length - myEvent.claimedRSVPs.length;

        uint256 payout = myEvent.deposit * unclaimed;

        //mark as paid before sending to avoid reetrancy attack
        myEvent.paidOut = true;

        //send the payout to the owner
        (bool sent, ) = msg.sender.call{value: payout}("");

        //if this fails
        if(!sent){
            myEvent.paidOut = false;
        }

        require(sent, "Failed to send Ether");
        
        emit DepositsPaidOut(eventId);
    }
}