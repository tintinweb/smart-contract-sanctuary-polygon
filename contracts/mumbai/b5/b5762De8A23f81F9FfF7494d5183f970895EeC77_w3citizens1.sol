/**
 *Submitted for verification at polygonscan.com on 2022-09-24
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
//These properties are the properties that each individual event
// will have on our platform. All of these details will also be stored on-chain.
contract w3citizens1 {
    // NewEventCreated: exposes data about the new event like the owner, max capacity, event owner, deposit amount, etc.
    event NewEventCreated(
        bytes32 eventID,
        address creatorAddress,
        uint256 eventTimestamp,
        uint256 maxCapacity,
        uint256 deposit,
        string eventDataCID
    );
    // exposes data about the user who RSVP'd and the event they RSVP'd to
    event NewRSVP(bytes32 eventID, address attendeeAddress);
    // exposes data about the user who was confirmed and the event that they were confirmed for
    event ConfirmedAttendee(bytes32 eventID, address attendeeAddress);
    // exposes data about unclaimed deposits being sent to the event organizer
    event DepositsPaidOut(bytes32 eventID);

    struct CreateEvent {
        bytes32 eventId;
        //we’re storing a reference to an IPFS hash where those details will be stored off-chain
        string eventDataCID;
        address eventOwner;
        uint256 eventTimestamp;
        uint256 deposit;
        uint256 maxCapacity;
        address[] confirmedRSVPs;
        address[] claimedRSVPs;
        bool paidOut;
       
   }
   // maps, or defines a relationship with, a unique eventID to the struct we just defined that is associated with that event.
    mapping(bytes32 => CreateEvent) public idToEvent;
    //These are the settings-specific to an event that we will get from the person actually creating the event on the frontend. 
    function createNewEvent(
        uint256 eventTimestamp,
        uint256 deposit,
        uint256 maxCapacity,
        string calldata eventDataCID
    //We set the function visibility to external since it is highly performant and saves on gas.
    ) external {
        // generate an eventID based on other things passed in to generate a hash
        // this is to avoid collisions (one user creates 2 o more events at the same time)
        bytes32 eventId = keccak256(
            abi.encodePacked(
                msg.sender,
                address(this),
                eventTimestamp,
                deposit,
                maxCapacity
            )
        );
        // make sure this id isn't already claimed
        require(idToEvent[eventId].eventTimestamp == 0, "ALREADY REGISTERED");
        address[] memory confirmedRSVPs;
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
        // Defining events is adding them as a tool on your toolbelt, 
        // but emitting them is actually pulling that tool out and using it. Each event should be emitted where it makes sense, after a specific action has been taken.
        emit NewEventCreated(
            eventId,
            msg.sender,
            eventTimestamp,
            maxCapacity,
            deposit,
            eventDataCID
        );

        

    }
    // function that gets called when a user finds an event and RSVPs to it on the front end.
    function createNewRSVP(bytes32 eventId) external payable {
            // look up event from our mapping
            CreateEvent storage myEvent = idToEvent[eventId];

            // transfer deposit to our contract / require that they send in enough ETH to cover the deposit requirement of this specific event
            require(msg.value == myEvent.deposit, "NOT ENOUGH");

            // require that the event hasn't already happened (<eventTimestamp)
            require(block.timestamp <= myEvent.eventTimestamp, "ALREADY HAPPENED");

            // make sure event is under max capacity
            require(
                myEvent.confirmedRSVPs.length < myEvent.maxCapacity,
                "This event has reached capacity"
            );

            // require that msg.sender isn't already in myEvent.confirmedRSVPs AKA hasn't already RSVP'd
            for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
                require(myEvent.confirmedRSVPs[i] != msg.sender, "ALREADY CONFIRMED");
            }

            myEvent.confirmedRSVPs.push(payable(msg.sender));
            emit NewRSVP(eventId, msg.sender);

    }
    // our app requires users to pay a deposit which they get back when they arrive at the event.
    function confirmAttendee(bytes32 eventId, address attendee) public {
    // look up event from our struct using the eventId
    CreateEvent storage myEvent = idToEvent[eventId];

    // require that msg.sender is the owner of the event - only the host should be able to check people in
    require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED");

    // require that attendee trying to check in actually RSVP'd
    address rsvpConfirm;

    for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
        if(myEvent.confirmedRSVPs[i] == attendee){
            rsvpConfirm = myEvent.confirmedRSVPs[i];
        }
    }

    require(rsvpConfirm == attendee, "NO RSVP TO CONFIRM");


    // require that attendee is NOT already in the claimedRSVPs list AKA make sure they haven't already checked in
    for (uint8 i = 0; i < myEvent.claimedRSVPs.length; i++) {
        require(myEvent.claimedRSVPs[i] != attendee, "ALREADY CLAIMED");
    }

    // require that deposits are not already claimed by the event owner
    require(myEvent.paidOut == false, "ALREADY PAID OUT");

    // add the attendee to the claimedRSVPs list
    myEvent.claimedRSVPs.push(attendee);

    // sending eth back to the staker `https://solidity-by-example.org/sending-ether`
    (bool sent,) = attendee.call{value: myEvent.deposit}("");

    // if this fails, remove the user from the array of claimed RSVPs
    if (!sent) {
        myEvent.claimedRSVPs.pop();
    }

    require(sent, "Failed to send Ether");
    emit ConfirmedAttendee(eventId, attendee);

}
//  confirm all of your attendees at once, instead of processing them one at a time.
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
// withdraw deposits of people who didn’t show up to the event and send them to the event organizer:
function withdrawUnclaimedDeposits(bytes32 eventId) external {
    // look up event
    CreateEvent memory myEvent = idToEvent[eventId];

    // check that the paidOut boolean still equals false AKA the money hasn't already been paid out
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

    // mark as paid before sending to avoid reentrancy attack
    myEvent.paidOut = true;

    // send the payout to the owner
    (bool sent, ) = msg.sender.call{value: payout}("");

    // if this fails
    if (!sent) {
        myEvent.paidOut = false;
    }

    require(sent, "Failed to send Ether");
    emit DepositsPaidOut(eventId);


}
}