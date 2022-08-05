/**
 *Submitted for verification at polygonscan.com on 2022-08-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Web3RSVP {
    event NewEventCreated(
        bytes32 eventId,
        address creatorAddress,
        uint256 eventTimestamp,
        uint256 deposit,
        uint256 maxCapacity,
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

    mapping(bytes32 => CreateEvent) public idToEvent;

    function createNewEvent(
        uint256 eventTimestamp,
        uint256 deposit,
        uint256 maxCapacity,
        string calldata eventDataCID
    ) external {
        // generate event ID
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
        CreateEvent storage myEvent = idToEvent[eventId];

        // do checks
        require(msg.value == myEvent.deposit, "not enough deposit");
        require(block.timestamp <= myEvent.eventTimestamp, "event in the past");
        require(
            myEvent.confirmedRSVPs.length < myEvent.maxCapacity,
            "event is full"
        );

        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            require(
                myEvent.confirmedRSVPs[i] != msg.sender,
                "already confirmed"
            );
        }

        myEvent.confirmedRSVPs.push(payable(msg.sender));

        emit NewRSVP(eventId, msg.sender);
    }

    function confirmAttendee(bytes32 eventId, address attendee) public {
        CreateEvent storage myEvent = idToEvent[eventId];

        require(msg.sender == myEvent.eventOwner, "unauthorized");

        address rsvpConfirm;

        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            if (myEvent.confirmedRSVPs[i] == attendee) {
                rsvpConfirm = myEvent.confirmedRSVPs[i];
                // should a break; be here?
            }
        }

        require(rsvpConfirm == attendee, "attendee did not RSVP");

        for (uint8 i = 0; i < myEvent.claimedRSVPs.length; i++) {
            require(myEvent.claimedRSVPs[i] != attendee, "already claimed");
        }

        require(myEvent.paidOut == false, "already paid out");

        myEvent.claimedRSVPs.push(attendee);

        (bool sent, ) = attendee.call{value: myEvent.deposit}("");

        if (!sent) {
            myEvent.claimedRSVPs.pop();
        }

        require(sent, "failed to send deposit");

        emit ConfirmedAttendee(eventId, attendee);
    }

    function confirmAllAttendees(bytes32 eventId) external {
        CreateEvent storage myEvent = idToEvent[eventId];

        require(msg.sender == myEvent.eventOwner, "unauthorized");

        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            confirmAttendee(eventId, myEvent.confirmedRSVPs[i]);
        }
    }

    function withdrawUnclaimedDeposits(bytes32 eventId) external {
        CreateEvent storage myEvent = idToEvent[eventId];

        require(!myEvent.paidOut, "already paid out");

        require(
            block.timestamp >= (myEvent.eventTimestamp + 7 days),
            "too early to pay out"
        );

        require(msg.sender == myEvent.eventOwner, "must be owner of event");

        uint256 unclaimed = myEvent.confirmedRSVPs.length -
            myEvent.claimedRSVPs.length;
        uint256 payout = unclaimed * myEvent.deposit;

        myEvent.paidOut = true;

        (bool sent, ) = msg.sender.call{value: payout}("");

        if (!sent) {
            myEvent.paidOut = false;
        }

        require(sent, "failed to send payout");

        emit DepositsPaidOut(eventId);
    }
}