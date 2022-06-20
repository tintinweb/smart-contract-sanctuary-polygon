// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.8;


contract EventFactory {

    error NotTicketOwner();
    error NotRegistered();
    error CheckedIn();
    error InsufficentBalance();

    struct EventTracker {
        uint48 eventTag;
        uint48 datePurchased;
        address participantAddress;
        bool ticketTransferStatus;
        bool eventCheckInStatus;
        uint40 ticketTransferDate;
    }

    struct AllEvents {
        address creatorAddress;
        uint48 maxParticipants;
        uint48 registeredParticipants;
        uint256 ticketAmount;
        uint256 amoutPaid;
    }

    uint256 public index;

    mapping(uint256 => AllEvents) public allEvents;
    mapping(uint256 => mapping(uint256=> EventTracker)) eventTracker;

    event CreateEvent(uint256 eventId);
    event EventCheckIn(uint256 _eventId, address participantAddress, bool eventCheckInStatus);
    event PurchasedTicket(uint256 eventId, address participantAddress, uint48 currentTag);
    event TransferTicketOwnership(uint256 eventId, address participantAddress, uint48 eventTag);

    function createEvent(uint48 maxNumberOfParticipants, uint256 _amount) public {
        AllEvents storage all = allEvents[index];
        all.creatorAddress = msg.sender;
        all.maxParticipants = maxNumberOfParticipants;
        all.ticketAmount = _amount;
        emit CreateEvent(index);
        index = index + 1;
    }

    function buyTicket(uint256 _eventId) public payable{
        AllEvents storage _event = allEvents[_eventId];

        if(_event.ticketAmount < msg.value) revert InsufficentBalance();
        uint48 _currentTag = _event.registeredParticipants + 1;
        _event.registeredParticipants = _currentTag;
        _event.amoutPaid += msg.value;
        EventTracker storage i_ = eventTracker[_eventId][_currentTag];
        i_.datePurchased = uint40(block.timestamp);
        i_.participantAddress = msg.sender;
        ++i_.eventTag;
        emit PurchasedTicket(_eventId, msg.sender, _currentTag);
    }

    function checkInEventAttendees(uint256 _eventId, address _address, uint32 _eventTag) public {
        EventTracker storage i_ = eventTracker[_eventId][_eventTag];
        if(i_.participantAddress != _address) revert NotRegistered();
        if(i_.eventCheckInStatus == true) revert CheckedIn();
        i_.eventCheckInStatus = true;
        emit EventCheckIn(_eventId, _address, true);
    }

    function transferTicketOwnership(uint256 _eventId, address _newAddress, uint32 _eventTag) public {
        EventTracker storage i_ = eventTracker[_eventId][_eventTag];
        if(msg.sender != i_.participantAddress) revert NotTicketOwner();
        i_.participantAddress = _newAddress;
        i_.ticketTransferDate = uint40(block.timestamp);
        emit TransferTicketOwnership(_eventId, _newAddress, _eventTag);
    }

    function fetchEventParticipants(uint256 _eventId, uint256 _participants) public view returns(EventTracker[] memory addresses) {
        addresses = new EventTracker[](_participants);
        for(uint256 i=0; i < _participants; i++){
            EventTracker storage i_ = eventTracker[_eventId][i];
            EventTracker memory c = addresses[i];
            c.datePurchased = i_.datePurchased;
            c.participantAddress = i_.participantAddress;
        }
    }
}