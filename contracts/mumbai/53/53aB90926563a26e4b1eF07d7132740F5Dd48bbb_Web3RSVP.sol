/**
 *Submitted for verification at polygonscan.com on 2022-08-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Web3RSVP {
    event NewEventCreated(
        bytes32 eventId,
        address creatorAddress,
        uint256 eventTimestamp,
        uint256 maxCapacity,
        uint256 deposit,
        string eventDataCID
    );

    event NewRSVP(bytes32 eventId, address attendeeAddress);

    event ConfirmedAttendee(bytes32 eventId, address attendeeAddress);

    event DepositPaidout(bytes32 eventId);

    struct Event {
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

    mapping(bytes32 => Event) public idToEvent;

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

        idToEvent[eventId] = Event(
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
        Event storage myEvent = idToEvent[eventId];

        require(msg.value == myEvent.deposit, "Not enough");

        require(block.timestamp <= myEvent.eventTimestamp, "Already happened");

        require(
            myEvent.confirmedRSVPs.length < myEvent.maxCapacity,
            "Event is full"
        );

        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            require(
                myEvent.confirmedRSVPs[i] != msg.sender,
                "Already confirmed"
            );
        }

        myEvent.confirmedRSVPs.push(payable(msg.sender));
        emit NewRSVP(eventId, msg.sender);
    }

    function confirmAttendee(bytes32 eventId, address attendee) public {
        Event storage myEvent = idToEvent[eventId];

        require(msg.sender == myEvent.eventOwner, "Not allowed");

        address rsvpConfirm;

        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            if (myEvent.confirmedRSVPs[i] == attendee) {
                rsvpConfirm = myEvent.confirmedRSVPs[i];
            }
        }

        require(rsvpConfirm == attendee, "No rsvp to confirm");

        for (uint8 i = 0; i < myEvent.claimedRSVPs.length; i++) {
            require(msg.sender != myEvent.claimedRSVPs[i], "Already confirmed");
        }

        require(myEvent.paidOut == false, "Already paid out");

        (bool sent, ) = attendee.call{value: myEvent.deposit}("");

        require(sent, "failed to send ether");

        myEvent.claimedRSVPs.push(attendee);
        emit ConfirmedAttendee(eventId, msg.sender);
    }

    function confirmAllAttendees(bytes32 eventId) external {
        Event storage myEvent = idToEvent[eventId];

        require(msg.sender == myEvent.eventOwner, "Not authorized");

        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            confirmAttendee(eventId, myEvent.confirmedRSVPs[i]);
        }
    }

    function withdrawUnclaimedDeposits(bytes32 eventId) external {
        Event storage myEvent = idToEvent[eventId];

        require(!myEvent.paidOut, "Already paidOut");

        require(
            block.timestamp >= (myEvent.eventTimestamp + 7 days),
            "Too early to calim"
        );

        require(msg.sender == myEvent.eventOwner, "Not authorized");

        uint256 unclaimed = myEvent.confirmedRSVPs.length -
            myEvent.claimedRSVPs.length;
        uint256 payout = unclaimed * myEvent.deposit;

        (bool sent, ) = msg.sender.call{value: payout}("");

        require(sent, "Failed to send Ether");

        myEvent.paidOut = true;
        emit DepositPaidout(eventId);
    }
}