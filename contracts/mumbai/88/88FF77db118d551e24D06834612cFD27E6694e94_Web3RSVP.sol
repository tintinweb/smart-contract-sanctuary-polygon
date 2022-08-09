/**
 *Submitted for verification at polygonscan.com on 2022-08-09
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Web3RSVP {
    event NewEventCreated(
        bytes32 eventId,
        address creatorAddress,
        uint256 eventTimestamp,
        uint256 maxCapacity,
        uint256 deposit,
        string eventDataCID
    );
    event NewRSVP(bytes32 eventId, address attendeeAdress);
    event ConfirmedAttendee(bytes32 eventId, address attendeeAddress);
    event DepositsPaidOut(bytes32 eventId);

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

        require(idToEvent[eventId].eventTimestamp == 0, "EVENT IS ALREADY REGISTERED");

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
        // Look up event
        CreateEvent storage eventData = idToEvent[eventId];

        require(msg.value == eventData.deposit, "NOT ENOUGH TO RESERVE A SPOT");
        require(block.timestamp <= eventData.eventTimestamp, "EVENT HAS ALREADY STARTED");
        require(eventData.confirmedRSVPs.length < eventData.maxCapacity, "EVENT IS AT FULL CAPACITY");

        for (uint8 i = 0; i < eventData.confirmedRSVPs.length; i++) {
            require(eventData.confirmedRSVPs[i] != msg.sender, "ALREADY CONFIRMED");
        }

        eventData.confirmedRSVPs.push(payable(msg.sender));

        emit NewRSVP(eventId, msg.sender);
    }

    function confirmAttendee(bytes32 eventId, address attendee) public {
        CreateEvent storage eventData = idToEvent[eventId];

        // Only the creator of the event can confirm attendee
        require(msg.sender == eventData.eventOwner, "NOT AUTHORIZED, ONLY EVENT OWNER CAN CONFIRM ATTENDEE");

        // require that attendee checking in has actually RSVP'd
        address rsvpConfirm;

        for (uint8 i = 0; i < eventData.confirmedRSVPs.length; i++) {
            if (eventData.confirmedRSVPs[i] == attendee) {
                rsvpConfirm = eventData.confirmedRSVPs[i];
            }
        }

        require(rsvpConfirm == attendee, "NO RSVP TO CONFIRM");

        // Check to make sure attendee has not already checked in
        for (uint8 i = 0; i < eventData.claimedRSVPs.length; i++) {
            require(eventData.claimedRSVPs[i] != attendee, "ALREADY CONFIRMED");
        }

        // Make sure that the event deposits have not already been paid out to the event creator
        require(eventData.paidOut == false, "EVENT DEPOSITS ALREADY PAID OUT TO EVENT OWNER");

        eventData.claimedRSVPs.push(attendee);

        // sending eth back to the staker `https://solidity-by-example.org/sending-ether`
        (bool sent,) = attendee.call{value: eventData.deposit}("");

        // If eth send fails remove user from the claimed RSVP list
        if (!sent) {
            eventData.claimedRSVPs.pop();
        }

        require(sent, "FAILED TO SEND ETHER TO ATTENDEE");

        emit ConfirmedAttendee(eventId, attendee);
    }

    function confirmAllAttendees(bytes32 eventId) external {
        CreateEvent storage eventData = idToEvent[eventId];

        // Only the creator of the even can confirm attendee
        require(msg.sender == eventData.eventOwner, "NOT AUTHORIZED");

        for (uint8 i = 0; i < eventData.confirmedRSVPs.length; i++) {
            confirmAttendee(eventId, eventData.confirmedRSVPs[i]);
        }
    }

    function withdrawUnclaimedDeposits(bytes32 eventId) external {
        CreateEvent memory eventData = idToEvent[eventId];

        require(!eventData.paidOut, "EVENT HAS ALREADY BEEN PAID OUT");

        require(
            block.timestamp >= (eventData.eventTimestamp + 7 days),
            "IT HAS NOT BEEN 7 DAYS SINCE THE EVENT, DEPOSIT CANNOT BE PAID OUT"
        );

        // Only the creator of the event can withdraw unclaimed deposits
        require(msg.sender == eventData.eventOwner, "NOT AUTHORIZED, ONLY EVENT OWNER CAN WITHDRAW UNCLAIMED DEPOSITS");

        // calculate how many people didn't claim by comparing
        uint256 unclaimed = eventData.confirmedRSVPs.length - eventData.claimedRSVPs.length;

        uint256 payoutAmount = unclaimed * eventData.deposit;

        eventData.paidOut = true;

        (bool sent, ) = msg.sender.call{value: payoutAmount}("");

        if (!sent) {
            eventData.paidOut = false;
        }

        require(sent, "FAILED TO SEND UNCLAIMED DEPOSIT TO EVENT OWNER");

        emit DepositsPaidOut(eventId);
    }
}