/**
 *Submitted for verification at polygonscan.com on 2023-02-09
*/

//SPDX-License-Identifier: Unlicense
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

    event confirmedAttendee(bytes32 eventId, address attendeeAddress);
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

    function CreateNewEvent(
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
        require(idToEvent[eventId].eventTimestamp == 0, "Already Registred");

        address[] memory confirmedRSVPs;
        address[] memory claimedRSVPs;

        //this creates a new CreatEvent struct and adds it to idToEvent mapping

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
        //look up event from our mapping
        CreateEvent storage myEvent = idToEvent[eventId];

        //transfer deposit to our contract / require that they send enought ETH to cover the deposit
        require(msg.value == myEvent.deposit, "NOT ENOUGH");

        //require that the event hasn't already happened (<evenTimestamp)
        require(block.timestamp <= myEvent.eventTimestamp, "ALREADY HAPPENED");

        //make sure event is under max capacity
        require(
            myEvent.confirmedRSVPs.length < myEvent.maxCapacity,
            "This Event Has Reached Capacity"
        );

        //require that msg.sender isn't already in myEvent.confirmedRSVPs aka hasn't already RSVP'd
        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            require(
                myEvent.confirmedRSVPs[i] != msg.sender,
                "ALREADY CONFIRMED"
            );
        }
        myEvent.confirmedRSVPs.push(payable(msg.sender));
        emit NewRSVP(eventId, msg.sender);
    }

    function confirmAttendee(bytes32 eventId, address attendee) public {
        //look up event from our mapping
        CreateEvent storage myEvent = idToEvent[eventId];

        //require taht msg.sender is the owner of the event
        require(msg.sender == myEvent.eventOwner, "Not Authorized");

        //require that attendee trying to check in actually RSVP'd
        address rsvpConfirm;

        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            if (myEvent.confirmedRSVPs[i] == attendee) {
                rsvpConfirm = myEvent.confirmedRSVPs[i];
            }
        }

        require(rsvpConfirm == attendee, "NO RSVP TO CONFIRM");

        // require that attendee is not already in the claimedRSVPs List
        for (uint8 i = 0; i < myEvent.claimedRSVPs.length; i++) {
            require(myEvent.paidOut == false, "ALREADY CLAIMED");
        }

        //require that deposits are not already claimed by the event owner
        require(myEvent.paidOut == false, "ALREADY PAID OUT");

        //add the attendee to the claimedRSVPs list
        myEvent.claimedRSVPs.push(attendee);

        //sending eth back to the staker
        (bool sent, ) = attendee.call{value: myEvent.deposit}("");

        //if this fails, remove the user from the array of claimed RSVPs
        if (!sent) {
            myEvent.claimedRSVPs.pop();
        }
        require(sent, "Failed to send ether");
        emit confirmedAttendee(eventId, attendee);
    }

    function confirmAllAttendees(bytes32 eventId) external {
        //look up event from our struct with the eventId
        CreateEvent memory myEvent = idToEvent[eventId];

        //make sure you require that msg.sender is the owner of the event
        require(msg.sender == myEvent.eventOwner, "NOT Authorized");

        //confirm each attendee in the rsvp array
        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            confirmAttendee(eventId, myEvent.confirmedRSVPs[i]);
        }
    }

    function withdrawUnclaimedDeposits(bytes32 eventId) external {
        CreateEvent memory myEvent = idToEvent[eventId];

        //check that the paidOut boolean still equal false
        require(!myEvent.paidOut, "ALREADY PAID");

        //check if it's been 7 days past my Event.eventTimestamp
        require(
            block.timestamp >= (myEvent.eventTimestamp + 7 days),
            "TOO EARLY"
        );

        //only the event owner people didn't claim by comparing
        uint256 unclaimed = myEvent.confirmedRSVPs.length -
            myEvent.claimedRSVPs.length;

        uint256 payout = unclaimed * myEvent.deposit;

        //mark as paid befor sending to avoid reentrancy attack
        myEvent.paidOut = true;

        //Send the payout to the owner
        (bool sent, ) = msg.sender.call{value: payout}("");

        //if this fails
        if (!sent) {
            myEvent.paidOut = false;
        }
        require(sent, "Failed to send Ether");
        emit DepositsPaidOut(eventId);
    }
}