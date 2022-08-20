/**
 *Submitted for verification at polygonscan.com on 2022-08-19
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

// Defining events 
contract Web3RSVP {

    // definig events 
    event NewEventCreated(
        bytes32 eventID,
        address creatorAddress,
        uint256 eventTimestamp,
        uint256 maxCapacity,
        uint256 deposit,
        string eventDataCID
    );

    event NewRSVP (bytes32 eventId, address attendeeAddress);
    event ConfirmAttendee (bytes32 eventId, address confirmAttendee);
    event DepositsPaidOut (bytes32 eventId);


    struct CreateEvent {
        bytes32 eventId;
        string eventDataCID;
        address eventOwner;
        uint256 eventTimestamp;
        uint256 deposit;
        uint256 maxCapacity;
        address[] confirmedRSVP;
        address[] claimedRSVP;
        bool paidOut;
    }
    // handling Multiple events 
    mapping(bytes32 => CreateEvent) public idToEvent;

    // Defining Functions 
    function CreateNewEvent(
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

       address[] memory confirmedRSVP;
       address[] memory claimedRSVP;

       // this creates a new CreateEvent struct and adds it to the idToEvent mapping
       idToEvent[eventId] = CreateEvent(
           eventId,
           eventDataCID,
           msg.sender,
           eventTimestamp,
           deposit,
           maxCapacity,
           confirmedRSVP,
           claimedRSVP,
           false
       ); 

       // emitting the events 
       emit NewEventCreated(
            eventId,
            msg.sender,
            eventTimestamp,
            maxCapacity,
            deposit,
            eventDataCID
       );
    }

    /// RSVP to Event 
    function CreateNewRSVP(bytes32 eventId) external payable {
        // look up event from our mapping 
        CreateEvent storage myEvent = idToEvent[eventId];

        // transfer deposit to our contract/require that they send in enough ETH to cover 
        require(msg.value == myEvent.deposit, "NOT ENOUGH");

        // require that event hasn't already happened
        require(block.timestamp <= myEvent.eventTimestamp, "ALREADY HAPPENED");

        // making sure event is under max capacity 
        require(myEvent.confirmedRSVP.length < myEvent.maxCapacity,"This event has reached it's max capacity");

        // require that msg.sender isn't already in myEvent.confirmedRSVP 
        for (uint8 i = 0; i < myEvent.confirmedRSVP.length; i++) {
            require(myEvent.confirmedRSVP[i] != msg.sender, "ALREADY CONFIRMED");
        }

        myEvent.confirmedRSVP.push(payable(msg.sender));

        //emit new rsvp 
        emit NewRSVP(eventId, msg.sender);
    }

    //Check in Attendees
    function confirmAttendee(bytes32 eventId, address attendee) public {
        // look up event from our struct using the event id 
        CreateEvent storage myEvent = idToEvent[eventId];

       // require that only host should be able to check in people 
       require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED");

       // require that attendee trying to check in actully RSVP'd
       address rsvpConfirm;

       for (uint8 i = 0; i <myEvent.confirmedRSVP.length; i++) {
           if(myEvent.confirmedRSVP[i] == attendee){
               rsvpConfirm = myEvent.confirmedRSVP[i];
           }
       } 

       require(rsvpConfirm == attendee, "NO RSVP TO CONFIRM");

       // require that attendee is NOT already checked in 
       for (uint8 i = 0; i <myEvent.claimedRSVP.length; i++) {
           require(myEvent.claimedRSVP[i] != attendee, "ALREADY CLAIMED");
       }

       // require that deposit are not already claimed by the event owner 
       require(myEvent.paidOut == false, "ALREADY PAID OUT");

       // adding attendee to claim rsvp list 
       myEvent.claimedRSVP.push(attendee);

       // sending eth back to the staker
       (bool sent, ) = attendee.call{value: myEvent.deposit}("");

       //in case of transaction failure sent remove user form claimed rsvp 
       if (!sent) {
           myEvent.claimedRSVP.pop();
       } 
       require(sent, "FAILED TO SEND ETH");

       emit ConfirmAttendee(eventId, attendee);
    }

    // Confrim whole group function 
    function confirmAllAttendee (bytes32 eventId) external {
        // look up event form our struct from eventId 
        CreateEvent memory myEvent = idToEvent[eventId];

        // check msg.sender is owner of the event 
        require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED");

        // confirm ecah attendee is rsvp array 
        for (uint8 i = 0; i < myEvent.confirmedRSVP.length; i++) {
            confirmAttendee (eventId, myEvent.confirmedRSVP[i]);
        }
    }

    // Send unclaimed deposits to event organizer 
    function withdrawUnclaimedDeposit (bytes32 eventId) external {
        // look up event 
        CreateEvent memory myEvent = idToEvent[eventId];

        // check eth hasn't already been paid out 
        require(!myEvent.paidOut, "ALRADY PAID");

        // check if it's been 7 days past the event 
        require(block.timestamp >= (myEvent.eventTimestamp + 7 days), "NOT 7 DAYS YET");

        // check msg.sender is owner of the event 
        require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED");

        //Check how many people didn't claim the funds and total amount of unclaimed funds 
        uint256 unclaimed = myEvent.confirmedRSVP.length - myEvent.claimedRSVP.length;
        uint256 payout = unclaimed * myEvent.deposit;

        // to stop confusion change claimed to true 
        myEvent.paidOut = true;

        // sending the funds to owner 
       (bool sent, ) = msg.sender.call{value: payout}("");

       require(sent, "FAILED TO SEND ETH");

       emit DepositsPaidOut(eventId);
    }
}