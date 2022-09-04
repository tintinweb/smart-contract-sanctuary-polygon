/**
 *Submitted for verification at polygonscan.com on 2022-09-03
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// import "hardhat/console.sol";

contract M3mentoRSVP {
    event NewEventCreated(
        bytes32 eventID,
        address creatorAddress,
        uint eventTimestamp,
        uint maxCapacity,
        uint deposit,
        string eventDataCID
    );

    event NewRSVP(bytes32 eventID, address attendee);
    event ConfirmedAttendee(bytes32 eventID, address attendee);
    event DepositsPaidOut(bytes32 eventID);

    struct CreateEvent {
        bytes32 eventID;
        string eventDataCID;
        address eventOwner;
        uint eventTimestamp;
        uint deposit;
        uint maxCapacity;
        address[] confirmedRSVPs;
        address[] claimedRSVPs;
        bool paidOut;
    }

    mapping(bytes32 => CreateEvent) public idToEvent;

    function createEvent(
        uint eventTimestamp,
        uint deposit,
        uint maxCapacity,
        string calldata eventDataCID
    ) external {

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

        emit NewEventCreated(
            eventID,
            msg.sender,
            eventTimestamp,
            maxCapacity,
            deposit,
            eventDataCID
        );
    }

    function createNewRSVP(bytes32 eventID) external payable {
        CreateEvent storage myEvent = idToEvent[eventID];
        require(msg.value == myEvent.deposit, "Make a larger deposit");
        require(block.timestamp <= myEvent.eventTimestamp, "The event already started");
        require(myEvent.confirmedRSVPs.length < myEvent.maxCapacity, "Sold Out");

        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            require(myEvent.confirmedRSVPs[i] != msg.sender, "You have already RSVP'd");
        }

        // what is payable
        myEvent.confirmedRSVPs.push(payable(msg.sender));
        emit NewRSVP(eventID, msg.sender);

    }

    function confirmAttendee(bytes32 eventID, address attendee) public {
        CreateEvent storage myEvent = idToEvent[eventID];
        require(msg.sender == myEvent.eventOwner, "You are not the host");

        // require that the attendee itrying to check in is actually RSVP
        address rsvpConfirm;
        for (uint i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            if (myEvent.confirmedRSVPs[i] == attendee){
                rsvpConfirm = myEvent.confirmedRSVPs[i];
            }
        }

        require(rsvpConfirm == attendee, "You are not RSVP'd");

        for (uint i = 0; i < myEvent.claimedRSVPs.length; i++) {
            require(myEvent.claimedRSVPs[i] != attendee, "You are already checked in");
        }

        require(myEvent.paidOut == false, "You've already been paid");

        myEvent.claimedRSVPs.push(attendee);

        (bool sent,) = attendee.call{value: myEvent.deposit}("");

        if(!sent) {
            myEvent.claimedRSVPs.pop();
        }

        require(sent, "Failed to send deposit");
        emit ConfirmedAttendee(eventID, attendee);
    }

    function confirmAllAttendees(bytes32 eventID) external {
        CreateEvent memory myEvent = idToEvent[eventID];
        require(myEvent.eventOwner == msg.sender, "You are not the host");
        for (uint i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            confirmAttendee(eventID, myEvent.confirmedRSVPs[i]);
        }
    }

    function withdrawUnclaimedDeposits(bytes32 eventID) external {
        CreateEvent memory myEvent = idToEvent[eventID];
        require(!myEvent.paidOut, "This has alreayd been paid out");
        require(block.timestamp >= (myEvent.eventTimestamp + 7 days), "It hasn't been 7 days since the event");
        require(msg.sender == myEvent.eventOwner, "You are not the host");
        uint unclaimed = myEvent.confirmedRSVPs.length - myEvent.claimedRSVPs.length;
        uint payout = unclaimed * myEvent.deposit;
        myEvent.paidOut = true;
        (bool sent,) = msg.sender.call{value: payout}("");
        if(!sent){
            myEvent.paidOut = false;
        }
        require(sent, "There was an error in withdrawing the unclaimed deposits");

        emit DepositsPaidOut(eventID);
    }
}