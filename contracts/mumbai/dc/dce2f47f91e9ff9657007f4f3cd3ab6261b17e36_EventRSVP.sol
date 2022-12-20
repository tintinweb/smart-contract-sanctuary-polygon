/**
 *Submitted for verification at polygonscan.com on 2022-12-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract EventRSVP {
    //events
    event NewEventCreated(
        bytes32 eventId,
        address eventOwner,
        uint256 eventTimestamp,
        uint256 maxCapacity,
        uint256 deposit,
        string eventDataCID
    );
    event NewRSVP(bytes32 eventId, address attendeeAddress);
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

    //function to create new event
    function createNewEvent (uint256 _eventTimestamp, uint256 _deposit, uint256 _maxCapacity, string calldata _eventDataCID) external {

        //create a unique eventId
        bytes32 _eventId = keccak256(abi.encodePacked(msg.sender, address(this), _eventTimestamp, _deposit,_maxCapacity));
        address[] memory _confirmedRSVPs;
        address[] memory _claimedRSVPs;

        require(idToEvent[_eventId].eventTimestamp == 0, "EVENT ALREADY REGISTERED");

        //create an event
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

    //function to create new RSVP to the existing event
    function createNewRSVP(bytes32 _eventId) external payable{
        //lookup the event
        CreateEvent storage myEvent = idToEvent[_eventId];

        //see that the user has enough funds
        require(msg.value == myEvent.deposit, "SEND ENOUGH FUNDS TO RSVP");

        //ensure that the event hasn't already started
        require(block.timestamp <= myEvent.eventTimestamp, "EVENT ALREADY STARTED");

        // ensure that the max capacity isnt reached
        require(myEvent.confirmedRSVPs.length < myEvent.maxCapacity, "MAX CAPACITY REACHED :(");

        for(uint8 i=0; i<myEvent.confirmedRSVPs.length; i++) {
            require(myEvent.confirmedRSVPs[i] != msg.sender, "ALREADY RSVPed");
        }
        myEvent.confirmedRSVPs.push(payable(msg.sender));
        emit NewRSVP(_eventId, msg.sender);
    }


    // function to confirm presence of attendee
    function confirmAttendee(bytes32 _eventId, address attendee) public {
        // fetch the event
        CreateEvent storage myEvent = idToEvent[_eventId];

        //confirm that the person calling the function is the owner of the event
        require(msg.sender == myEvent.eventOwner, "ONLY EVENT OWNER CAN CALL THIS FUNCTION");

        //check if the person actually RSVPed
        address rsvpConfirm;
        for(uint8 i; i<myEvent.confirmedRSVPs.length; i++) {
            if(myEvent.confirmedRSVPs[i] == attendee) {
                rsvpConfirm = myEvent.confirmedRSVPs[i];
            }
        }

        require(rsvpConfirm == attendee, "NO RSVP TO CONFIRM");

        //check if the person is not there in the claimRSVPs
        for(uint8 i; i<myEvent.claimedRSVPs.length; i++) {
            require(myEvent.claimedRSVPs[i] != attendee, "ALREADY CLAIMED");
        }

        //see the the event is not already PAID OUT
        require(myEvent.paidOut == false, "EVENT ALREADY PAID OUT");

        //add the attendee to the claimedRSVPs
        myEvent.claimedRSVPs.push(attendee);

        //sent the payment to the attendee address
        (bool sent,) = attendee.call{value: myEvent.deposit}("");

        //if the payment fails, remove the attendee from the claimedRSVPs
        if(!sent) {
            myEvent.claimedRSVPs.pop();
        }
        require(sent, "Failed to send Ether");
        emit ConfirmedAttendee(_eventId, msg.sender);
    }

    //function to confirm all alttendees at once
    function confirmAllAttendees(bytes32 _eventId) external {
        //fetch the event
        CreateEvent storage myEvent = idToEvent[_eventId];

        //check if the person calling the function is the owner of the event
        require(msg.sender == myEvent.eventOwner, "ONLY EVENT OWNER CAN CALL THIS FUNCTION");

        //call confirmAttendee function
        for(uint8 i=0; i<myEvent.confirmedRSVPs.length; i++) {
            confirmAttendee(_eventId, myEvent.confirmedRSVPs[i]);
        }
    }

    //withdrawal of unclaimed deposits
    function withdrawUnclaimedDeposits(bytes32 _eventId) external {
        //fetch the event
        CreateEvent storage myEvent = idToEvent[_eventId];

        //check if the person calling the function is the owner of the event
        require(msg.sender == myEvent.eventOwner, "ONLY EVENT OWNER CAN CALL THIS FUNCTION");

        //check if the event has been paid out
        require(myEvent.paidOut == false, "ALREADY PAID");

        //check is the event is completed
        require(block.timestamp >= (myEvent.eventTimestamp + 7 days), "TOO EARLY TO WITHDRAW");

        //calculate how many ppl didnt claim rsvp
        uint256 unclaimedCount = myEvent.confirmedRSVPs.length - myEvent.claimedRSVPs.length;
        uint256 payout = unclaimedCount * myEvent.deposit;

        //mark the event as paidout
        myEvent.paidOut = true;

        // send the payment
        (bool sent,) = msg.sender.call{value: payout}("");

        //check if payment fails and do the steps
        if(!sent) myEvent.paidOut = false;

        require(sent, "Failed to send Ether");
        emit DepositsPaidOut(_eventId);
    }

}