/**
 *Submitted for verification at polygonscan.com on 2022-08-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9; // should be the same as in the hardhat.config.js file

contract Web3RSVP {

    // Define an event: Let’s start by defining our smart contract and the information that we want to store on-chain: the creation of a new event by an event organizer and the details associated with that event. We’ll save this in a struct. As a refresher, a struct is similar to a JS object in that it stores related information about an entity. In our case, we’re storing information related to the creation of a new event on our RSVP contract. Recall that Solidity events are a way for our subgraph to listen for specific actions to enable us to make queries about the data from our smart contract. We have functions written to create a new event on our platform, RSVP to an event, confirm individual attendees, confirm the group of attendees, and send unclaimed funds back to the event owner. In order for our subgraph to be able to access the information from these functions, we need to expose them via events. We'll write the following events and emit them inside of their corresponding function:
    // NewEventCreated: exposes data about the new event like the owner, max capacity, event owner, deposit amount, etc.
    // NewRSVP: exposes data about the user who RSVP'd and the event they RSVP'd to
    // ConfirmedAttendee: exposes data about the user who was confirmed and the event that they were confirmed for
    // DepositsPaid: exposes data about unclaimed deposits being sent to the event organizer
    // All of our events are denoted by using the keyword event, followed by the custom name for our event.
    // Define your events at the very top of your file, inside the curly braces (right after contract Web3RSVP {):

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

    // storing information related to the creation of a new event on our RSVP contract (these will be stored on-chain). In general, it’s wise to be picky about the data you store on-chain because it’s expensive to store data on Ethereum. Because of this, you’ll notice that we’re not storing details like the event’s name and event description directly in the struct, but instead we’re storing a reference to an IPFS hash where those details will be stored off-chain. More on this later, but for now just know that’s what eventDataCID is for!
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

    // Because we want our contract to be able to handle the creation of multiple events, we need a mechanism to store and easily look up events by some identifier, like a unique ID. This is what we will use to tell our program which event a user is RSVPing to, since we can assume there will be many. To do this, we can create a Solidity mapping that maps, or defines a relationship with, a unique eventID to the struct we just defined that is associated with that event. We’ll use this mapping to make sure we are referencing the correct event when we call functions on that event like RSVPing, confirming attendees, etc. Inside of our contract and under our struct, we'll define this mapping.
    mapping(bytes32 => CreateEvent) public idToEvent;

    // the function that will get called when a user creates a new event in our frontend. This is one of our setter methods - a function that gets executed and sets the value based on information the user passed in. 'External' - We set the function visibility to external since it is highly performant and saves on gas.
    //     Next, we’ll write the function that will get called when a user creates a new event in our frontend. This is one of our setter methods - a function that gets executed and sets the value based on information the user passed in.
    // A reminder of what this function should be able to handle:
    // A unique ID
    // A reference to who created the event (a wallet address of the creator)
    // The time of the event, so we know when refunds should become available.
    // The maximum capacity of attendees for that event
    // The deposit amount for that event
    // Keep track of those who RSVP’d
    // Keep track of users who check into the event
    function createNewEvent(
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

        // We initialize the two arrays we’ll use to track RSVPs and attendees. We know we need to define these two arrays because in our struct, CreateEvent, we define that there will be two arrays which will be used to track the addresses of users who RSVP, and the address of users who actually arrive and get checked into the event AKA are confirmed.
        address[] memory confirmedRSVPs;
        address[] memory claimedRSVPs;


        //this creates a new CreateEvent struct and adds it to the idToEvent mapping
        // The key is the eventID and the value is a struct, or object, with the following properties that we grabbed either from the function arguments passed by the user in the front end (eventName, eventTimestamp, deposit, maxCapacity), some we generated ourselves, or gathered from the smart contract side (eventID, eventOwner, confirmedRSVPS, claimedRSVPs). Finally we set the boolean paidOut to false because at the time of eventCreation, there have been no payouts to the RSVPers (there are none yet) or the event owner yet.
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

    //         Emit Events
    // Now that we've defined them, we actually have to emit them somewhere. Defining events is adding them as a tool on your toolbelt, but emitting them is actually pulling that tool out and using it. Each event should be emitted where it makes sense, after a specific action has been taken.

    // For our first event, newEventCreated, we should emit this at the very end of our function createNewEvent.

    // To emit an event, we use the keyword emit and then pass in the arguments, AKA the actual values we want, based on the parameters we defined.

    // Emit NewEventCreated at the bottom of your createNewEvent function like this:

        emit NewEventCreated(
            eventId,
            msg.sender,
            eventTimestamp,
            maxCapacity,
            deposit,
            eventDataCID
        );
    }

    // the function that gets called when a user finds an event and RSVPs to it on the front end. Reminder of the requirements for a function to allow users to RSVP to an event:
    // Pass in a unique event ID the user wishes to RSVP to
    // Ensure that the value of their deposit is sufficient for that event’s deposit requirement
    // Ensure that the event hasn’t already started based on the timestamp of the event - people shouldn’t be able to RSVP after the event has started
    // Ensure that the event is under max capacity
    // Add this function to your contract, just under the createNewEvent function.
    function createNewRSVP(bytes32 eventId) external payable {
        // look up event
        CreateEvent storage myEvent = idToEvent[eventId];

        // transfer deposit to our contract / require that they sent in enough ETH
        require(msg.value == myEvent.deposit, "NOT ENOUGH");

        // require that the event hasn't already happened (<eventTimestamp)
        require(block.timestamp <= myEvent.eventTimestamp, "ALREADY HAPPENED");

        // make sure event is under max capacity
        require(
            myEvent.confirmedRSVPs.length < myEvent.maxCapacity,
            "This event has reached capacity"
        );

        // require that msg.sender isn't already in myEvent.confirmedRSVPs
        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            require(myEvent.confirmedRSVPs[i] != msg.sender, "ALREADY CONFIRMED");
        }

        myEvent.confirmedRSVPs.push(payable(msg.sender));


        // emit event
        emit NewRSVP(eventId, msg.sender);
    }

    // Check In Attendees - Part of our app requires users to pay a deposit which they get back when they arrive at the event. We'll write the function that checks in attendees and returns their deposit.
    function confirmAllAttendees(bytes32 eventId) external {
        // look up event
        CreateEvent memory myEvent = idToEvent[eventId];

        // make sure you require that msg.sender is the owner of the event
        require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED");

        // confirm each attendee
        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            confirmAttendee(eventId, myEvent.confirmedRSVPs[i]);
        }
    }

    // Confirm The Whole Group - As an event organizer, you might want to be able to confirm all of your attendees at once, instead of processing them one at a time. Let’s write a function to confirm every person that has RSVPs to a specific event:
    function confirmAttendee(bytes32 eventId, address attendee) public {
        // look up event
        CreateEvent storage myEvent = idToEvent[eventId];

        // make sure you require that msg.sender is the owner of the event
        require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED");

        // require that attendee is in myEvent.confirmedRSVPs
        address rsvpConfirm;

        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            if(myEvent.confirmedRSVPs[i] == attendee){
                rsvpConfirm = myEvent.confirmedRSVPs[i];
            }
        }

        require(rsvpConfirm == attendee, "NO RSVP TO CONFIRM");


        // require that attendee is NOT in the claimedRSVPs list
        for (uint8 i = 0; i < myEvent.claimedRSVPs.length; i++) {
            require(myEvent.claimedRSVPs[i] != attendee, "ALREADY CLAIMED");
        }

        // require that deposits are not already claimed
        require(myEvent.paidOut == false, "ALREADY PAID OUT");

        // add them to the claimedRSVPs list
        myEvent.claimedRSVPs.push(attendee);

        // sending eth back to the staker https://solidity-by-example.org/sending-ether
        (bool sent,) = attendee.call{value: myEvent.deposit}("");

        // if this fails
        if (!sent) {
            myEvent.claimedRSVPs.pop();
        }

        require(sent, "Failed to send Ether");

    // emit event
        emit ConfirmedAttendee(eventId, attendee);
    }

    // Send Unclaimed Deposits to Event Organizer
    // Finally, we need to write a function that will withdraw deposits of people who didn’t show up to the event and send them to the event organizer:
    function withdrawUnclaimedDeposits(bytes32 eventId) external {
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

        // mark as paid before sending to avoid reentrancy attack
        myEvent.paidOut = true;

        // send the payout to the owner
        (bool sent, ) = msg.sender.call{value: payout}("");

        // if this fails
        if (!sent) {
            myEvent.paidOut == false;
        }

        require(sent, "Failed to send Ether");

    // emit event
        emit DepositsPaidOut(eventId);
    }
}