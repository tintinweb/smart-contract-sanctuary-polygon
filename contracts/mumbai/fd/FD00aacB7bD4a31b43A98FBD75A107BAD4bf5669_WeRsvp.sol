/**
 *Submitted for verification at polygonscan.com on 2022-12-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract WeRsvp {

    // Events
    event NewEventCreated (
        bytes32 eventId,
        address creatorAddress,
        uint256 eventStartTimestamp,
        uint256 eventEndTimestamp,
        uint256 maxCapacity,
        uint256 deposit,
        string eventDataCID
    );
    event NewRSVPcreated (bytes32 eventId, address registrantAddress);
    event AttendeeConfirmed (bytes32 eventId, address attendeeAddress);
    event UnclaimedDepositsWithdrawn(bytes32 eventId);

    event CapturedError (uint128 errorCode, string errorContext, string errorMessage);

    //  State Variables
    struct newEventData {
        bytes32 eventId;
        string eventDataCID;
        address eventOwner;
        uint256 eventStartTimestamp;
        uint256 eventEndTimestamp;
        uint256 deposit;
        uint256 maxCapacity;
        address[] confirmedRSVPs;
        address[] claimedRSVPs;
        bool refundPaidOut;
    }

    mapping ( bytes32 => newEventData ) public eventsMap;

    // functions

    function createNewEvent(
        uint256 _eventStartTimestamp,
        uint256 _eventEndTimestamp, 
        uint256 _deposit,
        uint256 _maxCapacity,
        string calldata _eventDataCID
        ) external {
            // generate an eventId based on parameters passed in to generate a hash
            bytes32 _eventId = keccak256(
                abi.encodePacked(
                    msg.sender,
                    address(this),
                    _eventStartTimestamp,
                    _eventEndTimestamp,
                    _deposit,
                    _maxCapacity
                )
            );

            if (eventsMap[_eventId].eventStartTimestamp != 0) {
                emit CapturedError (4091, 'createEventError: Bad Request', 'Event Already Registerred!!!');
            }
            // make sure this id isn't already claimed
            require(eventsMap[_eventId].eventStartTimestamp == 0, 'Event Already Registerred!!!');

            address[] memory _confirmedRSVPs;
            address[] memory _claimedRSVPs;

            // this creates a new CreateEvent struct and adds it to the eventsMap mapping
            eventsMap[_eventId] = newEventData(
                _eventId,
                _eventDataCID,
                msg.sender,
                _eventStartTimestamp,
                _eventEndTimestamp,
                _deposit,
                _maxCapacity,
                _confirmedRSVPs,
                _claimedRSVPs,
                false
            );

            emit NewEventCreated(
                _eventId,
                msg.sender,
                _eventStartTimestamp,
                _eventEndTimestamp,
                _maxCapacity,
                _deposit,
                _eventDataCID
            );

    }

    function createNewRsvp(bytes32 _eventId) external payable {

         // look up event from our mapping
         newEventData storage _eventData = eventsMap[_eventId];
         
         // transfer deposit to our contract 
        //  / require that they send in enough ETH to cover the deposit requirement of this specific event
        if (msg.value != _eventData.deposit) {
            // capture error with events
            emit CapturedError (4022, "newRSVPError: Payment Required", "INSUFFICIENT FUNDS");
        }
        require(msg.value == _eventData.deposit, 'INSUFFICIENT FUNDS');

        // require that the event hasn't already happened (<eventTimestamp)
        if (block.timestamp >= _eventData.eventEndTimestamp) {
            // capture error with events
            emit CapturedError (4232, "newRSVPError: Locked", "EVENT HAS TAKEN PLACE");
        }
        require(block.timestamp <= _eventData.eventEndTimestamp, "EVENT HAS TAKEN PLACE");

         // make sure event is under max capacity
        if (_eventData.confirmedRSVPs.length >= _eventData.maxCapacity) {
            emit CapturedError (4232, "newRSVPError: Locked", "EVENT FULL!. This event has reached maximum capacity");
        }
        require(_eventData.confirmedRSVPs.length <= _eventData.maxCapacity , "EVENT FULL!. This event has reached maximum capacity");

        // require that msg.sender isn't already in _eventData.confirmedRSVPs AKA hasn't already RSVP'd
        for(uint _i = 0; _i < _eventData.confirmedRSVPs.length; _i++){
            if (_eventData.confirmedRSVPs[_i] == msg.sender) {
                emit CapturedError (4092, "newRSVPError: Conflict", "ALREADY REGISTERED");
            }
            require(_eventData.confirmedRSVPs[_i] != msg.sender, 'ALREADY REGISTERED');
         }

         _eventData.confirmedRSVPs.push(payable(msg.sender));

         emit NewRSVPcreated (_eventId, msg.sender);

    }

    function confirmAttendee(bytes32 _eventId, address _attendee) public{
        newEventData storage _eventData = eventsMap[_eventId];

        // require that msg.sender is the owner of the event - only the host should be able to connfirm attendees
        if (msg.sender != _eventData.eventOwner) {
            emit CapturedError (4011, "confirmAttendeeError: UnAuthorised", "NOT AUTHORIZED !!!. Not Event owner");
        }
        require(msg.sender == _eventData.eventOwner, "NOT AUTHORIZED !!!");

        address _rsvpConfirmed;

        for(uint _i = 0; _i < _eventData.confirmedRSVPs.length; _i++ ){
            if (_eventData.confirmedRSVPs[_i] == _attendee) {
                _rsvpConfirmed = _eventData.confirmedRSVPs[_i];
            }
        }

        if (_rsvpConfirmed != _attendee) {
            // capture error with events
            emit CapturedError (4041, "confirmAttendeeError: Not Found", "NO RSVP TO CONFIRM");
        }
        require(_rsvpConfirmed == _attendee, "NO RSVP TO CONFIRM");

        // require that attendee is NOT already in the claimedRSVPs list AKA make sure they haven't already checked in
        for(uint _i=0; _i < _eventData.claimedRSVPs.length; _i++){
            if (_eventData.claimedRSVPs[_i] == _attendee) {
                emit CapturedError (4091, "confirmAttendeeError: Conflict", "RSVP ALREADY CLAIMED");
            }
            require(_eventData.claimedRSVPs[_i] != _attendee, 'RSVP ALREADY CLAIMED');
        }

        if (_eventData.refundPaidOut != false) {
            emit CapturedError (4091, "confirmAttendeeError: Conflict", "ALREADY PAID OUT RSVP REFUND");
        }
        // require that deposits are not already claimed by the event owner
        require(_eventData.refundPaidOut == false, "ALREADY PAID OUT RSVP REFUND");

         // add the attendee to the claimedRSVPs list 
         // done at this point to avoid double entry
        _eventData.claimedRSVPs.push(_attendee);

        (bool _sent, ) = _attendee.call{value: _eventData.deposit}("");

        if (!_sent) {
            _eventData.claimedRSVPs.pop();
            emit CapturedError (4221, "confirmAttendeeError: Unprocessable", "Failed to send RSVP Refund Ether");
        }
        require(_sent, "Failed to send RSVP Refund Ether");
        emit AttendeeConfirmed (_eventId, _attendee);
        
    }

    function confirmAllAttendees(bytes32 _eventId) external {

        newEventData storage _eventData = eventsMap[_eventId];

        // make sure you require that msg.sender is the owner of the event
        if (msg.sender != _eventData.eventOwner) {
            emit CapturedError (4011, "confirmAllAttendeesError: Unauthorized", "NOT AUTHORIZED !!!");
        }
        require(msg.sender == _eventData.eventOwner, 'NOT AUTHORIZED !!!');
        
        // confirm each attendee in the rsvp array
        for(uint _i = 0; _i < _eventData.confirmedRSVPs.length; _i++){
            confirmAttendee(_eventId, _eventData.confirmedRSVPs[_i]);
        }
    }

    function withdrawUnclaimedDeposits(bytes32 _eventId) external {
        newEventData storage _eventData = eventsMap[_eventId];

        // check that the paidOut boolean still equals false AKA the money hasn't already been paid out
        if (_eventData.refundPaidOut) {
            emit CapturedError (4091, "withdrawUnclaimedDepositsError: Conflict", "ALREADY PAID OUT RSVP REFUND");
        }
        require(!_eventData.refundPaidOut, 'ALREADY PAID OUT RSVP REFUND');

         // check if it's been 7 days past the _eventData.eventEndTimestam
        if (block.timestamp + 7 days <= _eventData.eventEndTimestamp) {
            emit CapturedError (4001, "withdrawUnclaimedDepositsError: Bad Request", "TOO EARLY TO WITHDRAW");
        }
        require( block.timestamp + 7 days >= _eventData.eventEndTimestamp, 'TOO EARLY TO WITHDRAW' );

         // only the event owner can withdraw
        if (msg.sender != _eventData.eventOwner) {
            emit CapturedError (4011, "withdrawUnclaimedDepositsError: Unauthorized", "NOT AUTHORIZED, Only EVent Owner can withdraw");
        }
        require(msg.sender == _eventData.eventOwner, 'NOT AUTHORIZED, Only EVent Owner can withdraw');

         // calculate how many people didn't claim by comparing
         uint256 _unclaimedDeposits = _eventData.confirmedRSVPs.length - _eventData.claimedRSVPs.length;

         uint256 _payout = _unclaimedDeposits * _eventData.deposit;

         // mark as paid before sending to avoid re-entrancy attack
        _eventData.refundPaidOut = true;

        (bool _sent, ) = msg.sender.call{value: _payout} ("");

        if (!_sent) {
            _eventData.refundPaidOut = true;
            emit CapturedError (4221, "withdrawUnclaimedDepositsError: Unprocessable", "PAYOUT FAILED, Failed to send Ethe");
        }
        require(_sent, "PAYOUT FAILED, Failed to send Ether");
        emit UnclaimedDepositsWithdrawn(_eventId);
    }
}