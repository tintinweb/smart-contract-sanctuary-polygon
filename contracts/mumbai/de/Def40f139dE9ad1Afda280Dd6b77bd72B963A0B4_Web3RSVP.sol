/**
 *Submitted for verification at polygonscan.com on 2022-08-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Web3RSVP {
    // we define events at the very tippytop of our file. right after the contract declaration.
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

    // after creating the events, we have to actually emit them so they can work.  Defining events is adding them as a tool on your toolbelt, but emitting them is actually pulling that tool out and using it. Each event should be emitted where it makes sense, after a specific action has been taken.

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

    //  our first event, newEventCreated should be emitted at the very end of our function createNewEvent.

    function createNewEvent(
        uint256 eventTimestamp,
        uint256 deposit,
        uint256 maxCapacity,
        string calldata eventDataCID
    ) external {
        // here, generate an event id based on things passsed in to generate a hash
        bytes32 eventID = keccak256(
            abi.encodePacked(
                msg.sender,
                address(this),
                eventTimestamp,
                deposit,
                maxCapacity
            )
        );
        require(idToEvent[eventID].eventTimestamp == 0, "Already registered");

        address[] memory confirmedRSVPs;
        address[] memory claimedRSVPs;

        // next, i'll create a new event struct and add it to the idToEvent mapping
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

        emit NewEventCreated(
            eventID,
            msg.sender,
            eventTimestamp,
            maxCapacity,
            deposit,
            eventDataCID
        );

    }

    // this is the function that gets called when a user finds an event and RSVPs to it on the front end. 
    // NewRSVP should be emitted at the very end of our function createNewRSVP like this:

    function createNewRSVP(bytes32 eventID) external payable {
        // first, look up the event from our mapping
        CreateEvent storage myEvent = idToEvent[eventID];

        // next, transfer the deposit to our contract and require that user sends in enough eth to cover the requirement
        require(msg.value == myEvent.deposit, "Ooops! not enough");

        // require that the event hasn't already happened with the <eventTimestamp>
        require(
            block.timestamp <= myEvent.eventTimestamp,
            "Oops, this event already happened!"
        );

        // make sure that the event is under max capacity
        require(
            myEvent.confirmedRSVPs.length < myEvent.maxCapacity,
            "Sorry, this event has reached its max capacity"
        );

        // confirm that the msg.sender isn't already rsvpd
        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            require(
                myEvent.confirmedRSVPs[i] != msg.sender,
                "you're already confirmed!"
            );
        }

        myEvent.confirmedRSVPs.push(payable(msg.sender));
        // the NewRSVP solidity event is emitted at the very end of our function createNewRSVP like this:
        emit NewRSVP(eventID, msg.sender);
    }

    // the function that checks in attendees and returns their deposits
    // ConfirmedAttendees should be emitted at the very end of our function confirmAttendee
    function confirmAttendee(bytes32 eventID, address attendee) public {
        // look up event from our struct using the eventID
        CreateEvent storage myEvent = idToEvent[eventID];

        // next, require that msg.sender is the owner of the event since only the host should be able to check people in
        require(
            msg.sender == myEvent.eventOwner,
            "Not authorized || No access"
        );

        // require that attendee trying to check in actually rsvp'd
        address rsvpConfirm;

        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            if (myEvent.confirmedRSVPs[i] == attendee) {
                rsvpConfirm = myEvent.confirmedRSVPs[i];
            }
        }

        require(rsvpConfirm == attendee, "No RSVP to confirm :( ");

        // require that attendee is NOT already in the claimedRSVPs list AKA make sure they haven't already checked in
        for (uint8 i = 0; i < myEvent.claimedRSVPs.length; i++) {
            require(myEvent.claimedRSVPs[i] != attendee, "already claimed!");
        }

        // require that deposits are not already claimed by the event owner
        require(myEvent.paidOut == false, "already paid out deposits!");

        // add the attendee to the claimedRSVPs list
        myEvent.claimedRSVPs.push(attendee);

        // sending eth back to the staker `https://solidity-by-example.org/sending-ether
        (bool sent, ) = attendee.call{value: myEvent.deposit}("");

        // if this fails, remove the user from the array of claimed RSVPs
        if (!sent) {
            myEvent.claimedRSVPs.pop();
        }

        require(sent, "Failed to send Ether");

        // ConfirmedAttendee is emitted here at the very end of our function confirmAttendee
        emit ConfirmedAttendee(eventID, attendee);
    }

    // Confirm The Whole Group
    // event organizers might want to be able to confirm all attendees at once, instead of processing them one at a time. this function confirms every person that has RSVPs to a specific event

    function confirmAllAttendees(bytes32 eventID) external {
        // first, look up event from our struct with the eventID
        CreateEvent memory myEvent = idToEvent[eventID];

        // next, require that msg.sender is the owner of the event
        require(
            msg.sender == myEvent.eventOwner,
            "Not authorized. Contact the owner of this event"
        );

        // confirm each attendee in the rsvp array
        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            confirmAttendee(eventID, myEvent.confirmedRSVPs[i]);
        }
    }

    // Send Unclaimed Deposits to Event Organizer
    // Finally, we need to write a function that will withdraw deposits of people who didn’t show up to the event and send them to the event organizer

    // DepositPaidOut should be emitted at the very end of our function withdrawUnclaimedDeposits
    function withdrawUnclaimedDeposits(bytes32 eventID) external {
        // first, look up the event
        CreateEvent memory myEvent = idToEvent[eventID];

        // next, check that the the paidOut boolean still equals false i.e the money hasn't already been paid out
        require(!myEvent.paidOut, "ALREADY PAID");

        // check if it's been 7 days past the event with myEvent.eventTimestamp
        require(
            block.timestamp >= (myEvent.eventTimestamp + 7 days),
            "oops! too early, come back later!"
        );

        // ensure only the event owner can withdraw
        require(
            msg.sender == myEvent.eventOwner,
            "Must be an event owner to access this!"
        );

        // next, calculate the number of people who didn't claim their deposits
        uint256 unclaimed = myEvent.confirmedRSVPs.length -
            myEvent.claimedRSVPs.length;
        uint256 payout = unclaimed * myEvent.deposit;

        // mark as paid before sending to prevent a reentrancy attack
        myEvent.paidOut = true;

        // send the payout to the owner
        (bool sent, ) = msg.sender.call{value: payout}("");

        // if this fails,
        if (!sent) {
            myEvent.paidOut = false;
        }

        require(sent, "Oh no, failed to send ether");

        // DepositsPaidOut is emitted at the very end of our function withdrawUnclaimedDeposits here
        emit DepositsPaidOut(eventID);
    }

    // right now, we have functions to create a new event on our platform, RSVP to an event, confirm individual attendees, confirm the group of attendees, and send unclaimed funds back to the event owner. In order for our subgraph to be able to access the information from these functions, we need to expose them via solidity *events*.
    //  Solidity events are a way for subgraph to listen for specific actions to enable us to make queries about the data from our smart contract. they are emitted in their corresponding functions. events are written at the tippy top of the file, right after the contract declaration. so jump up hehe :)
}