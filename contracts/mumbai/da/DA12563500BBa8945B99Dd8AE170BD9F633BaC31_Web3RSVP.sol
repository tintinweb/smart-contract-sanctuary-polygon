/**
 *Submitted for verification at polygonscan.com on 2022-08-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ========== DEFINE AN 'EVENT' =============
/**
First we store details of the creation of a new event by an event organiser in a struct
Storing data on Ethereum can be quite expensive, so we'll be storing a reference to an IPFS hash
whose details will be kept off-chain (eventDataCID)
 */

contract Web3RSVP {

//============= CREATING CUSTOM SOLIDITY EVENTS =============
/**
Solidity events are a way for our subgraphs to listen to specific actions,
this enables us to make queries about the data from the smart contract.

We will be writing the following events (NewEventCreated, NewRSVP, ConfirmedAttendee, DepositsPaid),
and emit them inside their corresponding function:
*/

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

//============= HANDLING MULTIPLE EVENTS =============
/**
create a solidity mapping to ensure we are referencing the correct event 
when we call functions on that event like RSVPing, confirming attendees, etc.
 */
    mapping(bytes32 => CreateEvent) public idToEvent;


//============= CREATE A NEW EVENT =============
/**
Write a function that gets called (setter method) when a user creates a new event in our frontend.
A setter method is a function that gets executed and sets the value based on information the user passed in.
 */

    function createNewEvent(
        uint256 eventTimestamp,
        uint256 deposit,
        uint256 maxCapacity,
        string calldata eventDataCID
// set the function visibility to external since it is highly performant and this saves on gas
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
        // To prevent collision in addition to using keccak256 algorithm
        // we add a require statement to ensure that the eventId isn't already in use.
        require(idToEvent[eventId]. eventTimestamp == 0, "ALREADY REGISTERED");

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

//============= EMIT EVENT =============
/**
Each event should be emitted where it makes sense, after a specific action has been taken
For our first event, `newEventCreated`, we should emit this at the very end of the 
`createNewEvent` function
*/

        emit NewEventCreated(
            eventId, 
            msg.sender, 
            eventTimestamp, 
            maxCapacity, 
            deposit, 
            eventDataCID);
    }

//============= RSVP to Event =============
    function createNewRSVP(bytes32 eventId) external payable {
//look up event from the mapping
        CreateEvent storage myEvent = idToEvent[eventId];

//transfer deposit to our contract/ require that they send enough ETH to cover
        require(msg.value == myEvent.deposit, "NOT ENOUGH");

// require that the event hasn't already happened (< eventTimestamp)
        require(block.timestamp <= myEvent.eventTimestamp, "ALREADY HAPPENED");

// make sure the event is under capacity
        require(
            myEvent.confirmedRSVPs.length < myEvent.maxCapacity,
            "This event has reached capacity"
        );

// require that msg.sender isn't already in myEvent.confirmedRSVPs a.k.a hasn't already RSVP'd
        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            require(myEvent.confirmedRSVPs[i] != msg.sender, "ALREADY CONFIRMED");
        }

        myEvent.confirmedRSVPs.push(payable(msg.sender));

        emit NewRSVP(eventId, msg.sender);
    }


 //============= CONFIRM THE WHOLE GROUP =============
/**
As an event organiser, you may want to be able to confirm all of your attendees at once
instead of processing them one at a time.

Let's write a function to confirm every person that has RSVPs to a special event:
 */
    function confirmAllAttendees(bytes32 eventId) external {
// look up event from our struct (object) with the eventId
        CreateEvent memory myEvent = idToEvent[eventId];

// make sure you require that msg.sender is the owner of the event
        require(msg.sender == myEvent.eventOwner, "NOT AUTHORISED");

// confirm each attendee in the rsvp array
        for(uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            confirmAttendee(eventId, myEvent.confirmedRSVPs[i]);
        }
    }

//============= CHECK-IN ATTENDEES =============
/**Part of our app requires users to pay a deposit which they get back when they arrive at the event. 
We'll write the function that checks in attendees and returns their deposit.
 */
    function confirmAttendee(bytes32 eventId, address attendee) public {

// look up event from our struct using the eventId
        CreateEvent storage myEvent = idToEvent[eventId];

// require the msg.sender is the owner of the event - only the host should be able to check people in
        require(msg.sender == myEvent.eventOwner, "NOT AUTHORISED");

// require that the attendee trying to check in actually RSVP'd
        address rsvpConfirm;

        for(uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            if(myEvent.confirmedRSVPs[i] == attendee){
                rsvpConfirm = myEvent.confirmedRSVPs[i];
            }
        }

        require(rsvpConfirm == attendee, "NO RSVP TO CONFIRM");

// require that attendee is NOT already in the claimedRSVPs list a.k.a make sure they haven't already checked in.
        for (uint8 i = 0; i < myEvent.claimedRSVPs.length; i++) {
            require(myEvent.claimedRSVPs[i] != attendee, "ALREADY CLAIMED");
        }

// require that deposits are not already claimed by the event owner
        require(myEvent.paidOut == false, "ALREADY PAID OUT");

// add the attendee to the claimedRSVPs list
        myEvent.claimedRSVPs.push(attendee);

// sending eth back to the staker `https://solidity-by-example.org/sending-ether`
        (bool sent,) = attendee.call{value: myEvent.deposit}("");

// if this fails, remove the user from the array of the claimed RSVPs

        if (!sent) {
            myEvent.claimedRSVPs.pop();
        }

        require(sent, "Failed to send Ether");

        emit ConfirmedAttendee(eventId, attendee);

    }


//============= SEND UNCLAIMED DEPOSITS TO EVENT ORGANISER =============
/**
Let's write a function that will withdraw deposits of people who didn't show up to 
the event and send them to the event organiser:
*/

    function withdrawUnclaimedDeposits(bytes32 eventId) external {
// look up the event
        CreateEvent memory myEvent = idToEvent[eventId];

// check that the paidOut boolean still equals false a.k.a the money hasn't already been paid out.
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
        if(!sent) {
            myEvent.paidOut = false;
        }

        require(sent, "Failed to send Ether");

        emit DepositsPaidOut(eventId);
        
    }

}