/**
 *Submitted for verification at polygonscan.com on 2022-08-09
*/

// SPDX-License-Identifier: UNLICENSED
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
    
    event DepositPaidOut(bytes32 eventID, uint256 payout);

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

    mapping (bytes32 => CreateEvent) public idToEvent;

    function createNewEvent(
        uint256 eventTimestamp,
        uint256 deposit,
        uint256 maxCapacity,
        string calldata eventDataCID
    ) external {
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
        emit NewEventCreated(
            eventId,
            msg.sender,
            eventTimestamp,
            maxCapacity,
            deposit,
            eventDataCID
        );
    }

    function createNewRSVP(bytes32 eventId) external payable {
        // Look up event from our mapping 
        // storage because we want to point to the stored data and modify it
        // https://stackoverflow.com/questions/33839154/in-ethereum-solidity-what-is-the-purpose-of-the-memory-keyword

        CreateEvent storage myEvent = idToEvent[eventId];

        // transfer deposit to our contract / require that user send in enough ETH to cover the deposit requirement of this specific event
        require(msg.value == myEvent.deposit, "NOT ENOUGH FOUND FOR RSVP DEPOSIT");

        // require that the event hasn't already happened
        require(block.timestamp <= myEvent.eventTimestamp, "EVENT ALREADY HAPPENED");

        // make sure event is under max capacity
        require(myEvent.maxCapacity > myEvent.confirmedRSVPs.length, "EVENT HAS REACHED MAX CAPACITY");

        // require that user (msg.sender) hasn't already RSVP'd
        for(uint i; i < myEvent.confirmedRSVPs.length; i ++) {
            require(msg.sender != myEvent.confirmedRSVPs[i], "USER HAS ALREADY RSVPd");
        }
        // Push user address in confirmedRSVPs array
        // cast msg.sender of type address to type address payable in order to be able to transfer() or send() funds
        myEvent.confirmedRSVPs.push(payable(msg.sender));

        emit NewRSVP(eventId, msg.sender);
    }

    function confirmAttendee(bytes32 eventId, address attendee) public {
        //Look up event from our mapping
        CreateEvent storage myEvent = idToEvent[eventId];

        // require that msg.seneder is the owner of the event 
        // only the host should be able to check people in
        require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED");

        address rsvpConfirm;

        // if user is in the list assign the variable
        for(uint8 i; i < myEvent.confirmedRSVPs.length; i ++) {
            if(myEvent.confirmedRSVPs[i] == attendee) {
                rsvpConfirm = myEvent.confirmedRSVPs[i];
            }
        }

        // require that the attendee has RSVd
        require(rsvpConfirm == attendee, "NO RSVP TO CONFIRM");

        // require that attendee is NOT already in the claimedRSVPs list AKA make sure they haven't alreadychecked in
        for (uint8 i; i < myEvent.claimedRSVPs.length; i ++) {
            require(myEvent.claimedRSVPs[i] != attendee, "Attendee has already claimed");
        }

        // require that deposits are not already claimed by the event owner
        require(myEvent.paidOut == false, "Event owner already claimed deposits");

        // add the attendee to the claimedRSVPs list
        myEvent.claimedRSVPs.push(attendee);

        // sending eth back to the staker `https://solidity-by-exemple.org/sending-ether`
        (bool sent,) = attendee.call{value: myEvent.deposit}("");

        // if this fails, remove the user from the array of claimed RSVPs
        if (!sent) {
            myEvent.claimedRSVPs.pop();
        }

        require(sent, "Failed to send Ether");

        emit ConfirmedAttendee(eventId, attendee);
    }

    function confirmAllAttendees(bytes32 eventId) external {
        // look up event from our struct with the eventId
        // store data in `memory` this time, because we won't make any write operation here
        CreateEvent memory myEvent = idToEvent[eventId];

        // make sure you require that msg.sender is the owner of the event
        require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED to confirm all attendees");

        // confirm each attendee in the rsvp array
        for (uint8 i; i < myEvent.confirmedRSVPs.length; i ++) {
            confirmAttendee(eventId, myEvent.confirmedRSVPs[i]);
        }
    }

    function withdrawUnclaimedDeposits(bytes32 eventId) external {
        // look up event from our struct with the eventId
        // !! TUTORIAL USE memory POINTER HERE, CHECK IF IT WORKS
        // MAYBE WORKS WITH BOOLEANS
        CreateEvent storage myEvent = idToEvent[eventId];

        // require that the event owner has not already claimed deposit
        require(myEvent.paidOut == false, "ALREADY PAID");

        // require that it's been 7 days past myEvent.eventTimestamp
        require(
            block.timestamp >= myEvent.eventTimestamp + 7 days,
            "TOO EARLY"
        );

        // only the vent owner can withdraw
        require(msg.sender == myEvent.eventOwner, "MUST BE EVENT OWNER");

        // calculate how many people didn't claim by comparing
        uint256 unclaimed = myEvent.confirmedRSVPs.length - myEvent.claimedRSVPs.length;
        uint256 payout = unclaimed * myEvent.deposit;

        // mark paidOut as true
        myEvent.paidOut = true;

        // send payout to envent owner
        (bool sent,) = msg.sender.call{value: payout}("");

        // if this fails
        if (!sent) {
            myEvent.paidOut = false;
        }

        require(sent, "FAILED TO SEND ETHER TO EVENT OWNER");

        emit DepositPaidOut(eventId, payout);
    }
}