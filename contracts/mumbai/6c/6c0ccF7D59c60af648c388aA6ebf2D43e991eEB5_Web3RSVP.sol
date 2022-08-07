/**
 *Submitted for verification at polygonscan.com on 2022-08-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Web3RSVP {
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

/**
 * Creates New Event
 */
    function createNewEvent(
        uint256 eventTimestamp,
        uint256 deposit,
        uint256 maxCapacity, 
        string calldata eventDataCID
    ) external {
        
        // Generating an eventId based on params passed in to generate a hash:
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

        // Creating a new CreateEvent struct & adds it to the idToEvent mapping. 
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

        // Emit new event: 
        emit NewEventCreated(
            eventId, 
            msg.sender, 
            eventTimestamp, 
            maxCapacity, 
            deposit, 
            eventDataCID);
    }

    /**
     * RSVPs to Event 
     */
    function createNewRSVP(bytes32 eventId) external payable {

        // Look up event from mapping: 
        CreateEvent storage myEvent = idToEvent[eventId];

        // Transfer deposit to our contract / require that they send in enough ETH to cover the deposit requirements of this specific event
        require(msg.value == myEvent.deposit, "Not enough ETH to RSVP to event.");

        // Require that the event hasn't already happened: 
        require(block.timestamp <= myEvent.eventTimestamp, "Sorry, can't RSVP to past event!");

        // Make sure that the event is under max capacity: 
        require(myEvent.confirmedRSVPs.length < myEvent.maxCapacity, "Sorry, this event has reached capacity!" );

        // Require that msg.sender isn't all ready in myEvent.confirmedRSVPs - hasn't all ready RSVP'd:
        for(uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++){
            require(myEvent.confirmedRSVPs[i] != msg.sender, "You're all ready confirmed to attend this event.");
        }

        // Add attendee address to confirmedRSVP in event to the event: 
        myEvent.confirmedRSVPs.push(payable(msg.sender));

        // Emit new RSVP:
        emit NewRSVP(eventId, msg.sender);
    }

    /**
     * Checks in attendees & returns their deposit made when RSVPing to event
     */
    function confirmAttendee(bytes32 eventId, address attendee) public {

        // Look up event from stuct using the eventId:
        CreateEvent storage myEvent = idToEvent[eventId];

        // Require that msg.sender is the owner of the event - only the host should be able to check in attendees
        require(msg.sender == myEvent.eventOwner, "You're not authorized to confirm attendees. Only the event owner can do this!");

        // Require that the attendee trying to check in is RSVP'd:
        address rsvpConfirm;

        for(uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++){
            if(myEvent.confirmedRSVPs[i] == attendee){
                rsvpConfirm = myEvent.confirmedRSVPs[i];
            }
        }

        require(rsvpConfirm == attendee, "Sorry, there is no RSVP to confirm" );
        
        // Require that attendee is NOT all ready in the claimedRSVPS list - make sure they haven't all ready been checked in:
        for(uint8 i = 0; i < myEvent.claimedRSVPs.length; i++){
            require(myEvent.claimedRSVPs[i] != attendee, "Sorry, you've all ready claimed your RSVP!");
        }

        // Require that the deposits aren't all ready claimed by the event owner:
        require(myEvent.paidOut == false, "Message To Owner: Sorry, you've all ready claimed deposits!");

        // Add the attendee to the claimedRSVPs list:
        myEvent.claimedRSVPs.push(attendee);

        // Send ETH deposit back to the staker (attendee):
        (bool sent, ) = attendee.call{value: myEvent.deposit}("");

        // If this fails, remove the user from the array of claimed RSVPs:
        if(sent == false){
            myEvent.claimedRSVPs.pop();
        }

        // Update attendee on fail:
        require(sent, "Message to Attendee: Failed to send ETH deposit back. You're RSVP status is unclaimed. Please try again!");

        // Emit confirmAttendee status: 
        emit ConfirmedAttendee(eventId, attendee);
    }

    /**
     * Confirms all RSVPs at once so that event owner doesn't have to do it multiple times.
     */
    function confirmAllAttendees(bytes32 eventId) external {

        // Loop up event from the struct using the eventId:
        CreateEvent storage myEvent = idToEvent[eventId];

        // Make sure you require that msg.sender is the owner of the event:
        require(myEvent.eventOwner == msg.sender, "Sorry only the owner of this event can confirm all attendee RSVPs at once!");

        // Confirm each attendee in the rsvp array: 
        for(uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++){
            confirmAttendee(eventId, myEvent.confirmedRSVPs[i]);
        }
    }

    /**
     * Withdraws deposits of people who don't show up to the event & sends them to the event organizer:
     */
    function withdrawUnclaimedDeposits(bytes32 eventId) external {

        // Look up event: 
        CreateEvent storage myEvent = idToEvent[eventId];

        // Check that the paidOut boolean still equals false - the money hasn't all ready been paid out:
        require(!myEvent.paidOut, "Message to Event Owner: Sorry, the ETH deposits have already been paid out!");

        // Check if it's been 7 days past myEvent.eventTimestamp: 
        require(block.timestamp >= (myEvent.eventTimestamp + 7 days), "Message to Event Owner: Sorry it is too early to withdraw unclaimed RSVP deposits.");

        // Only the event owner can withdraw:
        require(msg.sender == myEvent.eventOwner, "Sorry you're not authorized to withdraw ETH deposits, only the event owner is allowed to do this!");

        // Calculate how many people didn't claim by comparison:
        uint256 unclaimedRSVPs = myEvent.confirmedRSVPs.length - myEvent.claimedRSVPs.length;
        uint256 ownerPayout = unclaimedRSVPs * myEvent.deposit;

        // Mark as paid before sending to avoid reentray attack:
        myEvent.paidOut = true; 

        // Send the payout to the owner:
        (bool sent, ) = msg.sender.call{value: ownerPayout}("");

        // If this fails update the owner: 
        if(!sent){
            myEvent.paidOut = false; 
        }

        require(sent, "Message to Event Owner: Failed to sent ETH deposits for unclaimed RSVPs. Please try again!");

        // Emit deposits paid out: 
        emit DepositsPaidOut(eventId);
    }
}