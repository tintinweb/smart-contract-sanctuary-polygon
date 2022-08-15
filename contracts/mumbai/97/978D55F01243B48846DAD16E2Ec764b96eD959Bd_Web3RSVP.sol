/**
 *Submitted for verification at polygonscan.com on 2022-08-14
*/

// SPDX-License-Identifier: MIT
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
        uint256 _eventTimestamp,
        uint256 _deposit, 
        uint256 _maxCapacity,
        string calldata _eventDataCID
    ) external {
        bytes32 eventId = keccak256(
            abi.encodePacked(
                msg.sender,
                address(this),
                _eventTimestamp,
                _deposit,
                _maxCapacity
            )
        );
        require(idToEvent[eventId].eventTimestamp == 0, "Already registered");

        address[] memory confirmedRSVPs;
        address[] memory claimedRSVPs;

        idToEvent[eventId] = CreateEvent(
            eventId,
            _eventDataCID,
            msg.sender,
            _eventTimestamp,
            _deposit,
            _maxCapacity,
            confirmedRSVPs,
            claimedRSVPs,
            false
        );

        emit NewEventCreated(
            eventId,
            msg.sender,
            _eventTimestamp,
            _maxCapacity,
            _deposit,
            _eventDataCID
        );
    }

    function createNewRSVP(
        bytes32 _eventId
    ) public payable {
        CreateEvent storage myEvent = idToEvent[_eventId];
        require(msg.value == myEvent.deposit, "Incorrect deposit");
        require(block.timestamp < myEvent.eventTimestamp, "Event has already started");
        require(myEvent.confirmedRSVPs.length < myEvent.maxCapacity, "No more RSVPs allowed");

        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            require(myEvent.confirmedRSVPs[i] != msg.sender, "ALREADY CONFIRMED");
        }
 
        myEvent.confirmedRSVPs.push(payable(msg.sender));

        emit NewRSVP(
            _eventId,
            msg.sender
        );
    }

    function confirmAttendee(
        bytes32 _eventId,
        address _attendee
    ) public {
        CreateEvent storage myEvent = idToEvent[_eventId];
        require(msg.sender == myEvent.eventOwner, "Only event owner can confirm attendees");

        address rsvpConfirm;

        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            if (myEvent.confirmedRSVPs[i] == _attendee) {
                rsvpConfirm = myEvent.confirmedRSVPs[i];
            }
        }

        require(rsvpConfirm == _attendee, "Attendee not confirmed");

        for (uint8 i = 0; i < myEvent.claimedRSVPs.length; i++) {
            if (myEvent.claimedRSVPs[i] == _attendee) {
                revert("ALREADY CLAIMED");
            }
        }

        require(myEvent.paidOut == false, "Event already paid out");

        myEvent.claimedRSVPs.push(_attendee);

        (bool sent,) = _attendee.call{value: myEvent.deposit}("");

        if (!sent) {
            myEvent.claimedRSVPs.pop();
        }

        require(sent, "Could not send ether");

        emit ConfirmedAttendee(
            _eventId,
            _attendee
        );
    }

    function confirmAllAttendees(
        bytes32 _eventId
    ) public {
        CreateEvent storage myEvent = idToEvent[_eventId];
        require(msg.sender == myEvent.eventOwner, "Only event owner can confirm attendees");

        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            confirmAttendee(_eventId, myEvent.confirmedRSVPs[i]);
        }
    }

    function withdrawUnclaimedDeposits(
        bytes32 _eventId
    ) public {
            CreateEvent storage myEvent = idToEvent[_eventId];
            require(msg.sender == myEvent.eventOwner, "Only event owner can withdraw");
            require(myEvent.paidOut == false, "Already paid out");
            require(block.timestamp >= (myEvent.eventTimestamp + 7 days), "Please wait seven days");
            
            uint256 unclaimed = myEvent.confirmedRSVPs.length - myEvent.claimedRSVPs.length;
            uint256 payout = unclaimed * myEvent.deposit;

            myEvent.paidOut = true;

            (bool sent,) = msg.sender.call{value: payout}("");

            if (!sent) {
                myEvent.paidOut = false;
            }

            require(sent, "Failed to send Ether");

            emit DepositsPaidOut(
                _eventId
            );
    }
}