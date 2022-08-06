/**
 *Submitted for verification at polygonscan.com on 2022-08-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Web3RSVP {
    /*
Events: Specific actions than can be listened by the subgraph. This will enable us to make queries to the smart contract from the front-end. Defining the events it's not enough, they need to be emitted after an specific action has been taked

*/
    //Contains the details of the event
    event NewEventCreated(
        bytes32 eventID,
        address creatorAddress,
        uint256 eventTimestamp,
        uint256 maxCapacity,
        uint256 deposit,
        string eventDataCID
    );

    //Contains the data of the user that RSVP'd and the event
    event NewRSVP(bytes32 eventID, address attendeeAddress);
    //Contains the data of the user that attendee the event and the event itself
    event ConfirmedAttendee(bytes32 eventID, address attendeeAddress);
    //Data about unclaimed deposits of an event being sent (or not) to the organizer
    event DepositsPaidOut(bytes32 eventID);

    struct CreateEvent {
        bytes32 eventId; //bytes32: string with a max length of 64 chars.
        string eventDataCID;
        address eventOwner;
        uint256 eventTimestamp; //uint256: positive integer with a size below 256 bits (can have a lot of decimals)
        uint256 deposit;
        uint256 maxCapacity;
        address[] confirmedRSVPs;
        address[] claimedRSVPs;
        bool paidOut;
    }
    mapping(bytes32 => CreateEvent) public idToEvent; //mapping: similar to a hash table, used to store data as key-value pairs

    /* Create a new event

Requeriments: 
1) Unique ID
2) Address of the event creator
3) Time of the event
4) Maximum capacity of the event
5) Deposit amount for the event
6) Keep track of users that RSVP’d
7) Keep track of users that actually attended the event
8) Event details (name, description, etc.)
*/

    function createNewEvent(
        // eventTimestamp: start of the event; deposit: amount required to RSVP to the event; maxCapacity: max cap of the event, eventDataCID: reference to IPFS hash containing the event details
        uint256 eventTimestamp,
        uint256 deposit,
        uint256 maxCapacity,
        string calldata eventDataCID
    ) external {
        //external = function visibility (highly perfomant and gas saving)

        //generate the eventId
        bytes32 eventId = keccak256(
            abi.encodePacked(
                msg.sender,
                address(this),
                eventTimestamp,
                deposit,
                maxCapacity
            )
        );
        // require(idToEvent[eventId].eventTimestamp != 0, "ALREADY REGISTERED");

        //arrays to track addresses of users that RSVPs and addresses of actual attendees (those two arrays are defined on the CreateEvent struct)
        address[] memory confirmedRSVPs; // memory (data location) is where the array is stored
        address[] memory claimedRSVPs;

        // Create a new event (struct) and adds it to the  directory of events (idToEvent mapping). eventID = mapping key.
        idToEvent[eventId] = CreateEvent(
            eventId,
            eventDataCID,
            msg.sender,
            eventTimestamp,
            deposit,
            maxCapacity,
            confirmedRSVPs,
            claimedRSVPs,
            false //paidOut is false because there's no payouts at the time of the event creation
        );
        //emits the event
        emit NewEventCreated(
            eventId,
            msg.sender,
            eventTimestamp,
            maxCapacity,
            deposit,
            eventDataCID
        );
    }

    /*RSVP to event

Requeriments:
1) Unique event ID to RSVP to
2) Deposit value meets deposit requirement for that event
3) Make sure event hasn't already started
4) Make sure event is below max cap
*/

    function createNewRSVP(bytes32 eventId) external payable {
        //payable functions and addresses can receive and send ether to and out of the contract

        //Find event in the directory (idToEvent mapping)
        CreateEvent storage myEvent = idToEvent[eventId]; //storage (data location) is where local and state variables are held, in this case "myEvent"

        //Deposit value meets deposit requirement for that event (requirement)
        require(msg.value == myEvent.deposit, "Insufficient funds");

        //Make sure event hasn't already started (requirement)
        require(
            block.timestamp <= myEvent.eventTimestamp,
            "Event already happened :("
        );

        //Make sure event is below max cap (requirement)
        require(
            myEvent.confirmedRSVPs.length < myEvent.maxCapacity,
            "This event has reached its maximum capacity"
        );

        //Make sure the address hasn't already RSVP'd
        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            require(
                myEvent.confirmedRSVPs[i] != msg.sender,
                "User already RSVP'd to this event"
            );
        }

        myEvent.confirmedRSVPs.push(payable(msg.sender));
        emit NewRSVP(eventId, msg.sender);
    }

    /*

Check In Attendees
When the user check-in at the event, they got refunded their deposit
*/

    function confirmAttendee(bytes32 eventId, address attendee) public {
        //Find event in the directory (idToEvent mapping)
        CreateEvent storage myEvent = idToEvent[eventId];

        //only the host address should be able to check people in (requirement)
        require(
            msg.sender == myEvent.eventOwner,
            "You're not authorized to check people in"
        );

        //make sure the attendee checking in RSVP'd before (requirement)
        address rsvpConfirm;

        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            if (myEvent.confirmedRSVPs[i] == attendee) {
                rsvpConfirm = myEvent.confirmedRSVPs[i];
            }
        }
        require(rsvpConfirm == attendee, "User hasn't RSVP'd");

        //make sure the attendee hasn't already checked in (requirement)
        for (uint8 i = 0; i < myEvent.claimedRSVPs.length; i++) {
            require(
                myEvent.claimedRSVPs[i] != attendee,
                "User already checked in"
            );
        }
        // Make sure the deposit hasn't been already refunded (requirement)
        require(myEvent.paidOut == false, "Deposit already refunded");

        //Add the user to the attendees array
        myEvent.claimedRSVPs.push(attendee);

        //Refund the deposit
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use for sending funds. https://solidity-by-example.org/sending-ether`
        (bool sent, ) = attendee.call{value: myEvent.deposit}("");

        //remove the user from the attendees array if the transaction fails (requirement)
        if (!sent) {
            myEvent.claimedRSVPs.pop();
        }
        require(sent, "Failed to send Ether");
        emit ConfirmedAttendee(eventId, attendee);
    }

    /*
Confirm all the users that has RSVPs to an event at once
    */

    function confirmAllAttendees(bytes32 eventId) external {
        //Find event in the directory (idToEvent mapping)
        CreateEvent storage myEvent = idToEvent[eventId];

        //only the host address should be able to confirm attendees (requirement)
        require(
            msg.sender == myEvent.eventOwner,
            "You're not authorized to check people in"
        );

        // confirm each attendee in the rsvp array
        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            confirmAttendee(eventId, myEvent.confirmedRSVPs[i]);
        }
    }

    /*
Send unclaimed deposits to the event organizer
Withdraw from the smart contract all deposits of users that didn't attend to the event and send them to the organizer
    */

    function withdrawUnclaimedDeposits(bytes32 eventId) external {
        //Find event in the directory (idToEvent mapping)
        CreateEvent storage myEvent = idToEvent[eventId];

        // Make sure the deposit hasn't been already withdrawed (requirement)
        require(!myEvent.paidOut, "Funds already withdrawed");

        // check if it's been 7 days past myEvent.eventTimestamp (requirement)
        require(
            block.timestamp >= (myEvent.eventTimestamp + 7 days),
            "Need to wait 7 days after the event to receive the funds"
        );

        // only the event owner can withdraw (requirement)
        require(
            msg.sender == myEvent.eventOwner,
            "Only the event owner can withdraw the funds"
        );

        // calculate how many people didn't claim by comparing
        uint256 unclaimed = myEvent.confirmedRSVPs.length -
            myEvent.claimedRSVPs.length;
        uint256 payout = unclaimed * myEvent.deposit;

        // mark as paid before sending to avoid reentrancy attack https://solidity-by-example.org/hacks/re-entrancy/
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