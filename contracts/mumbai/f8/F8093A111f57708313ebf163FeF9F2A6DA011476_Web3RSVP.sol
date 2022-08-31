/**
 *Submitted for verification at polygonscan.com on 2022-08-30
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

    event DepositPaidOut(bytes32 eventID);

    struct CreateEvent {
        bytes32 eventId;
        string eventDataCID;
        address eventOwner;
        uint256 eventTimestamp;
        uint256 deposit;
        uint256 maxCapacity;
        address[] confirmedRSVPs;
        address[] claimedRSPVs;
        bool paidOut;
    }

    mapping(bytes32 => CreateEvent) public idToEvent;

    function createNewEvent(
        uint256 eventTimestamp,
        uint256 deposit, 
        uint256 maxCapacity,
        string calldata eventDataCID
    ) external {
        // generate an eventID based on other things passed in to generate a hash
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

        // this creates a new CreateEvent struct and adds it to the idToEvent mapping
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

    function createNewRSVP(bytes32 eventID) external payable {
        // Look up event from our mapping
        CreateEvent storage myEvent = idToEvent[eventID];

        // transfer deposit to our contract / require that they send in enough ETH to cover the deposit requirement of this specific event
        require(msg.value == myEvent.deposit, "NOT ENOUGH");

        // require that the event hasn´t already started (<eventTimestamp)
        require(block.timestamp < myEvent.eventTimestamp, "ALREADY STARTED");

        // make sure event is under max capacity
        require(
            myEvent.confirmedRSVPs.length < myEvent.maxCapacity,
            "THIS EVENT HAS REACHED CAPACITY"
        );

        // require that msg.sender isn't already in myEvent.confirmedRSVPs AKA hasn't already RSVP'd
        for(uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++){
            require(myEvent.confirmedRSVPs[i] != msg.sender, "ALREADY CONFIRMED");
        }

        myEvent.confirmedRSVPs.push(payable(msg.sender));

        emit NewRSVP(eventID, msg.sender);
    }

    function confirmAttendee(bytes32 eventID, address attendee) public {
        CreateEvent storage myEvent = idToEvent[eventID];

        // require that msg.sender is the owner of the event
        require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED");

        // require that attendee trying to check in actualiy RSVP´d
        address rsvpConfirm;

        for(uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++){
            if(myEvent.confirmedRSVPs[i] == attendee){
                rsvpConfirm = myEvent.confirmedRSVPs[i];
            }
        }

        require(rsvpConfirm == attendee, "NO RSVP TO CONFIRM");

        // require that attendee is NOT already in the claimedRSVPs list AKA make sure they haven't already checked in
        for(uint8 i = 0; i < myEvent.claimedRSPVs.length; i++){
            require(myEvent.claimedRSPVs[i] != attendee, "ALREADY CLAIMED");
        }

        // add the attendee to the claimedRSVPs list
        myEvent.claimedRSPVs.push(attendee);

        // sending eth back to the staker
        (bool sent,) = attendee.call{value: myEvent.deposit}("");

        // if fails, remove the user form the array of claimed RSVPs
        if(!sent) {
            myEvent.claimedRSPVs.pop();
        }

        require(sent, "Falied to send Ether");

        emit ConfirmedAttendee(eventID, attendee);
    }

    function confirmAllAttendees(bytes32 eventID) external {
        // Look up event from our struct with the eventID
        CreateEvent memory myEvent = idToEvent[eventID];

        // make sure you require that msg.sender is the owner of the event
        require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED");

        // confirm each attendee in the rsvp array
        for(uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++){
            confirmAttendee(eventID, myEvent.confirmedRSVPs[i]);
        }
    }

    function withdrawUnclaimedDeposits(bytes32 eventID) external {
        // Looh up event
        CreateEvent memory myEvent = idToEvent[eventID];

        // check that the paidOut boolean still equals false AKA the money hasn´t already been paid out
        require(!myEvent.paidOut, "ALREADY PAID");

        // check if it´s been 7 days past myEvent.eventTimestamp
        require(
            block.timestamp >= (myEvent.eventTimestamp + 7 days),
            "TOO EARLY TO CLAIM"
        );

        // only the event owner can withdraw
        require(msg.sender == myEvent.eventOwner, "MUST BE EVENT OWNER");

        // calculate how many people didn´t claim by comparising
        uint256 unclaimed = myEvent.confirmedRSVPs.length - myEvent.claimedRSPVs.length;
        uint256 payout = unclaimed * myEvent.deposit;

        // mark as paid before to avoid reetrancy attack
        myEvent.paidOut =  true;

        // send the payout to the owner
        (bool sent,) = msg.sender.call{value: payout}("");

        // if this fails 
        if(!sent){
            myEvent.paidOut = false;
        }

        require(sent, "Failed to send Ether");

        emit DepositPaidOut(eventID);
    }
}