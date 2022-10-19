// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


contract Web3Rsvp {
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
        uint256 _maxCapacity,
        uint256 _deposit,
        string calldata _eventDataCID
    ) external {
        // generate an eventID based on other things passed in to generate a hash
        bytes32 _eventId = keccak256(
            abi.encodePacked (
                msg.sender,
                address(this),
                _eventTimestamp,
                _deposit,
                _maxCapacity
            )
        );

        // make sure this id isn't already claimed
        require(idToEvent[_eventId].eventTimestamp == 0, "ALREADY REGISTERED");

        address[] memory _confirmedRSVPs;
        address[] memory _claimedRSVPs;

        // this creates a new CreateEvent struct and adds it to the idToEvent mapping
        idToEvent[_eventId] = CreateEvent(
            _eventId,
            _eventDataCID,
            msg.sender,
            _eventTimestamp,
            _deposit,
            _maxCapacity,
            _confirmedRSVPs,
            _claimedRSVPs,
            false
        );

        emit NewEventCreated(
            _eventId,
            msg.sender,
            _eventTimestamp,
            _maxCapacity,
            _deposit,
            _eventDataCID
        );
    }

    // RSVP To Event
    function createNewRSVP(bytes32 _eventId) external payable {
        // look up event from our mapping
        CreateEvent storage myEvent = idToEvent[_eventId];

        // transfer deposit to our contract / require that they send in enough ETH to cover
        require(msg.value == myEvent.deposit, "NOT ENOUGH DEPOSIT AMOUNT");

        // require that the event hasn't already happened (<eventTimestamp)
        require(block.timestamp < myEvent.eventTimestamp, "EVENT ALREADY HAPPENED");

        // make sure event is under max capacity
        require(myEvent.confirmedRSVPs.length < myEvent.maxCapacity, "EVENT ALREADY REACHED CAPACITY");

        // require that msg.sender isn't already in myEvent.confirmedRSVPs AKA hasn't already RSVP'd
        for(uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            require(msg.sender != myEvent.confirmedRSVPs[i], "ALREADY CONFIRMED");
        }

        myEvent.confirmedRSVPs.push(payable(msg.sender));

        emit NewRSVP(_eventId, msg.sender);
    }

    // Check In Attendees
    // Part of our app requires users to pay a deposit which they get back when they arrive at the event. 
    // We'll write the function that checks in attendees and returns their deposit.
    function confirmAttendee(bytes32 _eventId, address _attendee) public {
        // look up event from our struct using the eventId
        CreateEvent storage myEvent = idToEvent[_eventId];

        // require that msg.sender is the owner of the event - only the host should be able to check people in
        require(msg.sender == myEvent.eventOwner, "PERMISSION DENIED");

        // require that attendee trying to check in actually RSVP'd
        address rsvpConfirm;

        for(uint i; i < myEvent.confirmedRSVPs.length; i++) {
            if(_attendee == myEvent.confirmedRSVPs[i]) {
                rsvpConfirm = myEvent.confirmedRSVPs[i];
            }
        }

        require(rsvpConfirm == _attendee, "NO RSVP TO CONFIRM");

        // require that attendee is NOT already in the claimedRSVPs list 
        // AKA make sure they haven't already checked in
        for(uint i; i < myEvent.claimedRSVPs.length; i++) {
            require(_attendee != myEvent.claimedRSVPs[i], "ALREADY CLAIMED");
        }

        // require that deposits are not already claimed by the event owner
        require(myEvent.paidOut == false, "ALREADY PAYOUT");

        // add the attendee to the claimedRSVPs list
        myEvent.claimedRSVPs.push(_attendee);

        // sending eth back to the staker `https://solidity-by-example.org/sending-ether`
        (bool sent,) = _attendee.call{value: myEvent.deposit}("");

        // if this fails, remove the user from the array of claimed RSVPs
        if (!sent) {
            myEvent.claimedRSVPs.pop();
        }
 
        require(sent, "Failed to send Ether");

        emit ConfirmedAttendee(_eventId, _attendee);
    }

    // Confirm The Whole Group
    // As an event organizer, you might want to be able to confirm all of your attendees at once, instead of processing them one at a time.
    function confirmAllAttendees(bytes32 _eventId) external {
        // look up event from our struct with the eventId
        CreateEvent memory myEvent = idToEvent[_eventId];

        // make sure you require that msg.sender is the owner of the event
        require(msg.sender == myEvent.eventOwner, "PERMISSION DENIED");

        // confirm each attendee in the rsvp array
        for(uint i; i < myEvent.confirmedRSVPs.length; i++) {
            confirmAttendee(_eventId, myEvent.confirmedRSVPs[i]);
        }
    }

    // Send Unclaimed Deposits to Event Organizer
    // Finally, we need to write a function that will withdraw deposits of people who didn’t show up to the event and send them to the event organizer:
    function withdrawUnclaimedDeposits(bytes32 _eventId) external {
        // look up event 
        CreateEvent memory myEvent = idToEvent[_eventId];

        // check that the paidOut boolean still equals false 
        // AKA the money hasn't already been paid out
        require(myEvent.paidOut == false, "ALREADY PAID");

        // check if it's been 7 days past myEvent.eventTimestamp
        require(block.timestamp >= (myEvent.eventTimestamp + 7 days), "TOO EARLY");

        // calculate how many people didn't claim by comparing
        uint256 unclaimed = myEvent.confirmedRSVPs.length - myEvent.claimedRSVPs.length;

        uint256 payout = unclaimed * myEvent.deposit;

        // mark as paid before sending to avoid reentrancy attack
        myEvent.paidOut = true;

        // send the payout to the owner
        (bool sent, ) = msg.sender.call{value: payout}("");

        // if this fails
        if (!sent) {
            myEvent.paidOut = false;
        }

        require(sent, "Failed to send Ether");

        emit DepositsPaidOut(_eventId);
    }
}