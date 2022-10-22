/**
 *Submitted for verification at polygonscan.com on 2022-10-22
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

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

    struct CreateEvent{
        bytes32 eventId;
        string eventDataCID;
        address eventOwner;
        uint256 eventTimeStamp;
        uint256 deposit;
        uint256 maxCapacity;
        address[] confirmedRSVPs;
        address[] claimedRSVPs;
        bool paidOut;
    }

    mapping(bytes32 => CreateEvent) public idToEvent;

    function createNewEvent(
        uint256 eventTimeStamp,
        uint256 deposit,
        uint256 maxCapacity,
        string calldata eventdataCID
    ) external {
        //generate an eventID based on toher things pased in to generrate a hash
        bytes32 eventId = keccak256(
            abi.encodePacked(
                msg.sender, 
                address(this), 
                eventTimeStamp, 
                deposit, 
                maxCapacity
                )
        );
        address[] memory confirmedRSVPs;
        address[] memory claimedRSVPs;

        idToEvent[eventId] = CreateEvent(
            eventId,
            eventdataCID,
            msg.sender,
            eventTimeStamp,
            deposit,
            maxCapacity,
            confirmedRSVPs,
            claimedRSVPs,
            false
        );

    emit NewEventCreated(
        eventId,
        msg.sender, 
        eventTimeStamp, 
        maxCapacity, 
        deposit, 
        eventdataCID
        );
    }


    function createNewRSVP (bytes32 eventId) external payable {
        //Look up event for mapping
        CreateEvent storage myEvent = idToEvent[eventId];

        //transfer deposit to our contract / require that they send in enough to cover the deposit requiremnts of this specific event
         require(msg.value == myEvent.deposit, "NOT ENOUGH");

         //require that the event hasn't already happened(<eventTimestamp)
         require(block.timestamp <= myEvent.eventTimeStamp, "ALREADY HAPPENED");

         //make sure event is under the max capacity
         require(
            myEvent.confirmedRSVPs.length < myEvent.maxCapacity, "This event has reached capacity"
         );

         //require that msg.sender isnt't alrady in myEvent.confirmedRSVPs AKA hasn't already RSVP'd
         for(uint i = 0; i < myEvent.confirmedRSVPs.length; i++) {

         require(myEvent.confirmedRSVPs[i] != msg.sender, "ALREADY CONFRIMED");
         }

         myEvent.confirmedRSVPs.push(payable(msg.sender));

    emit NewRSVP(eventId, msg.sender);

    }


    function confirmAttendee(bytes32 eventId, address attendee) public {
        //look up event from our struct using the eventID
        CreateEvent storage myEvent = idToEvent[eventId];

        //require that msg.sender is the owner of the event -only the host should be able to check people in
        require(msg.sender == myEvent.eventOwner,"NOT AUTHORIZED");

        //require that attendee trying to check in actually RSVP'd
        address rsvpConfirm;

        for(uint i = 0; i < myEvent.confirmedRSVPs.length; i++){
            if(myEvent.confirmedRSVPs[i] == attendee){
                rsvpConfirm = myEvent.confirmedRSVPs[i];
            }
        }

        require(rsvpConfirm  == attendee, "NO RSVP TO CONFIRM");

        //require that attendee is NOT already in the claimedRSVPs list AKA make sure they havetn't already check in
        for(uint8 i = 0; i < myEvent.claimedRSVPs.length; i++) {
            require(myEvent.claimedRSVPs[i] != attendee, "ALREADY CLAIMED");
        }

        //require that deposits are not alreay claimed by the event owner
        require(myEvent.paidOut == false, "ALREAY PAID OUT");

        //add the attendee to claimmedRSVPs list 
        myEvent.claimedRSVPs.push(attendee);

        //sending eth back to the staker `https://solidity-by-example.org/sending-ether`
        (bool sent,) = attendee.call{value: myEvent.deposit}("");

        //if this fails, removethe user from the arry of claimed RSVPs
        if(!sent) {
            myEvent.claimedRSVPs.pop();
        }

        require(sent, "Failed to send Ether");

    emit ConfirmedAttendee(eventId, msg.sender);

    } 


    function confirmAllAttendees(bytes32 eventId) external {
        //look up event from our struct with the eventId
        CreateEvent memory myEvent = idToEvent[eventId];

        //make sure you require that msg.sender is the owner of the event;
        require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED");

        //confirm each attendee in the rsvparray
        for(uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            confirmAttendee(eventId, myEvent.confirmedRSVPs[i]);
        }
    }

    function withdrawUnclaimedDeposits(bytes32 eventId) external {
        //Look upevent
        CreateEvent memory myEvent = idToEvent[eventId];

        //check that the paidOut boolean stil equals false AKA the money hasn't already been paid out
        require(!myEvent.paidOut, "Already APID");

        //check if it's been 7 days past myEvent.eventTimeStamp
        require(
            block.timestamp >= (myEvent.eventTimeStamp + 7 days),
            "TOO EARLY"
        );

        //only the event owner can withdraw
        require(msg.sender == myEvent.eventOwner, "MUST BE EVENT OWNER");

        //calculae how many people didn't claim by comparing
        uint256 unclaimed = myEvent.confirmedRSVPs.length - myEvent.claimedRSVPs.length;
        uint256 payout = unclaimed * myEvent.deposit;

        //mark as paid before sending to avoid reentrancy attck
        myEvent.paidOut = true;

        //send the payout to the owner
        (bool sent,) = msg.sender.call{value: payout}("");

        //if this fails
        if(!sent){
            myEvent.paidOut = false;
        }

        require(sent, "Failed to send ETHER");

    emit DepositsPaidOut(eventId);

    }

}