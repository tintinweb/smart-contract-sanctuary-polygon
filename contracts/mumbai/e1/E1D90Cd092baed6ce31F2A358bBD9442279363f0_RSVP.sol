/**
 *Submitted for verification at polygonscan.com on 2022-08-07
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract RSVP {
    /// @notice Exposes data about the new event e.g. the owner, max capacity, deposit amount etc.
    event NewEventCreated(
        bytes32 eventId,
        address creatorAddress,
        uint256 eventTimestamp,
        uint256 maxCapacity,
        uint256 deposit,
        string eventDataCID
    );

    /// @notice exposes data about the user who RSVP'd and the event they RSVP'd to
    event NewRSVP(bytes32 eventId, address attendeeAddress);

    /// @notice exposes data about the user who was confirmed and the event that they were confirmed for
    event ConfirmedAttendee(bytes32 eventId, address attendeeAddress);

    /// @notice exposes data about unclaimed deposits being sent to the event organizer
    event DepositsPaid(bytes32 eventId);

    struct CreateEvent {
        bytes32 eventId;
        string eventDataCID; // This will be a reference to a IPFS hash
        address eventOwner;
        uint256 eventTimestamp;
        uint256 deposit;
        uint256 maxCapacity;
        address[] confirmedRSVPs;
        address[] claimedRSVPs;
        bool paidOut;
    }

    mapping(bytes32 => CreateEvent) public idToEvent;

    /// @notice This gets called when a user creates a new event in frontend
    /// @param eventTimestamp The time of the event, so we know when refunds should become available
    /// @param deposit Deposit amonut for that event
    /// @param maxCapacity The max capacity of attendees for that event
    /// @param eventDataCID Hash of event info
    function createNewEvent(
        uint256 eventTimestamp, // Time of the event
        uint256 deposit, // Deposit amount
        uint256 maxCapacity,
        string calldata eventDataCID
    ) external {
        // generate an eventID based on other things passed in to generate a hash
        bytes32 eventId = keccak256(
            abi.encodePacked(
                msg.sender,
                address(this),
                eventTimestamp,
                deposit,
                maxCapacity
            )
        );

        require(idToEvent[eventId].eventTimestamp == 0, "Already registered");

        address[] memory confirmedRSVPs;
        address[] memory claimedRSVPs;

        // this creates a new CreateEvent struct and adds it to the idToEvent mapping
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

    /// @notice This gets called when a user finds an event and RSVPs to it on the frontend
    /// @param eventId unique event ID
    function createNewRSVP(bytes32 eventId) external payable {
        // look up event from our mapping
        CreateEvent storage myEvent = idToEvent[eventId];

        // transfer deposit to our contract & require that they send in enough ETH
        // to cover the deposit requirement of this specific event
        require(msg.value == myEvent.deposit, "Not enough");

        // make sure event is under max capacity
        require(
            myEvent.confirmedRSVPs.length < myEvent.maxCapacity,
            "This event has reached capacity"
        );

        // require that msg.sender isn't already in myEvent.confirmedRSVPs aka
        // hasn't already RSVP'd
        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            require(
                myEvent.confirmedRSVPs[i] != msg.sender,
                "Already confirmed"
            );
        }

        myEvent.confirmedRSVPs.push(payable(msg.sender));

        emit NewRSVP(eventId, msg.sender);
    }

    /// @notice This checks in attendees and returns their deposit
    function confirmAttendee(bytes32 eventId, address attendee) public {
        // look up event from our struct using the eventId
        CreateEvent storage myEvent = idToEvent[eventId];

        // requre that msg.sender is the owner of the event - only the host should
        // be able to check people in
        require(msg.sender == myEvent.eventOwner, "Not authorized");

        // require that attendee trying to check in actually RSVP'd
        address rsvpConfirm;

        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            if (myEvent.confirmedRSVPs[i] == attendee) {
                rsvpConfirm = myEvent.confirmedRSVPs[i];
            }
        }

        require(rsvpConfirm == attendee, "No RSVP confirmed");

        // require that attendee isn't already in the claimedRSVPs list aka
        // make sure they haven't already checked in
        for (uint8 i = 0; i < myEvent.claimedRSVPs.length; i++) {
            require(myEvent.claimedRSVPs[i] != attendee, "Already claimed");
        }

        // require that deposits aren't already claimed by the event owner
        require(myEvent.paidOut == false, "Already paid out");

        // add the attendee to the claimedRSVPs list
        myEvent.claimedRSVPs.push(attendee);

        // sending eth back to the staker 'https://solidity-by-example.org/sending-ether'
        (bool sent, ) = attendee.call{value: myEvent.deposit}("");

        // if this fails, remove the user from the array of claimed RSVPs
        if (!sent) {
            myEvent.claimedRSVPs.pop();
        }

        require(sent, "Failed to send Ether");

        emit ConfirmedAttendee(eventId, attendee);
    }

    /// @notice This confirms every person that has RSVP'd to a specific event
    function confirmAllAttendees(bytes32 eventId) external {
        // look up event from our struct with the eventId
        CreateEvent memory myEvent = idToEvent[eventId];

        // make sure you require that msg.sender is the owner of the event
        require(msg.sender == myEvent.eventOwner, "Not authorized");

        // confirm each attendee in the RSVP array
        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            confirmAttendee(eventId, myEvent.confirmedRSVPs[i]);
        }
    }

    /// @notice This withdraws deposits of people who didn't show up to the event and sends them to the event organizer
    function withdrawUnclaimedDeposits(bytes32 eventId) external {
        // look up event
        CreateEvent memory myEvent = idToEvent[eventId];

        // check that the paidOut boolean is still false
        require(!myEvent.paidOut, "Already paid");

        // check if it's been 7 days past myEvent.eventTimestamp
        require(
            block.timestamp >= myEvent.eventTimestamp + 7 days,
            "Too early"
        );

        // only the event owner can withdraw
        require(msg.sender == myEvent.eventOwner, "Must be event owner");

        // calculate how many people didn't claim by comparing
        uint256 unclaimed = myEvent.confirmedRSVPs.length -
            myEvent.claimedRSVPs.length;
        uint256 payout = unclaimed * myEvent.deposit;

        myEvent.paidOut = true;

        // send the payout to the owner
        (bool sent, ) = msg.sender.call{value: payout}("");

        // if this fails
        if (!sent) {
            myEvent.paidOut = false;
        }

        require(sent, "Failed to send Ether");

        emit DepositsPaid(eventId);
    }
}