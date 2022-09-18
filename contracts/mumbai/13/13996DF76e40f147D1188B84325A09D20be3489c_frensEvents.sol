/**
 *Submitted for verification at polygonscan.com on 2022-09-18
*/

// SPDX-License-Identifier: MIT License
pragma solidity ^0.8.9;


contract frensEvents {

    event NewEventCreated (
        bytes32 eventId,
        address creatoraddress,
        uint256 eventTimeStamp,
        uint256 maxCapacity,
        uint256 deposit,
        string eventDataCID
    );

    event NewRSVP (bytes32 eventID, address attendeeAddress);

    event ConfirmedAttendee(bytes32 eventID, address attendeeAddress);

    event DepositIsPaidOut(bytes32 eventID);

    struct CreateEvent {
        bytes32 eventId;
        string eventDataCID;
        address eventOwner;
        uint256 eventTimeStamp;
        uint256 deposit;
        uint256 maxCapacity;
        address[] confirmedFren;
        address[] frenClaimed;
        bool paidOut;
    }

    mapping(bytes32 => CreateEvent) public idToEvent;

    function createNewEvent (
        uint256 eventTimeStamp,
        uint256 deposit,
        uint256 maxCapacity,
        string calldata eventDataCID
    ) external {
          //generate an eventID
    bytes32 eventId = keccak256 (
        abi.encodePacked(
            msg.sender,
            address(this),
            eventTimeStamp,
            deposit,
            maxCapacity
        )
        
    );

    address[] memory confirmedFren;
    address[] memory frenClaimed;

    //create a new event struct and add to idToEvent mapping
    idToEvent[eventId] = CreateEvent(
        
        eventId,
        eventDataCID,
        msg.sender,
        eventTimeStamp,
        deposit,
        maxCapacity,
        confirmedFren,
        frenClaimed,
        false
    );
    emit NewEventCreated(
            eventId,
            msg.sender,
            eventTimeStamp,
            maxCapacity,
            deposit,
            eventDataCID

        );
    }

    function createNewRSVP(bytes32 eventId) external payable {
        //Find event from mapping
        CreateEvent storage myEvent = idToEvent[eventId];

        //transfer deposit to contract and require enough ETH be sent to cover the deposit requirement of this pecific event.
        require(msg.value == myEvent.deposit, "NOT ENOUGH ETH");
        
        //require that event has not already happened
        require(block.timestamp <= myEvent.eventTimeStamp, "EVENT ALREADY HAPPENED");

        //make sure event is under max capacity
        require(myEvent.confirmedFren.length < myEvent.maxCapacity, "THIS EVENT IS FULL");

        //require that msg.sender isn't already registered already
        for (uint i = 0; i < myEvent.confirmedFren.length; i++) {
            require(myEvent.confirmedFren[i] != msg.sender, "ALREADY REGISTERED");
        }        

        myEvent.confirmedFren.push(payable(msg.sender));
        
        emit NewRSVP(eventId, msg.sender);
            }

function confirmAllAttendees(bytes32 eventId) external {
            //look up event
            CreateEvent memory myEvent = idToEvent[eventId];
            // make sure you require that msg.sender is the owner of event
            require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED");

            for (uint8 i = 0; i < myEvent.frenClaimed.length; i++) {
                confirmAttendee(eventId, myEvent.confirmedFren[i]);         
                 }
        }

    function confirmAttendee(bytes32 eventId, address attendee) public {
            // look up event from struct with eventId
        CreateEvent storage myEvent = idToEvent[eventId];
            //require msg.sender is owner of the event - only host can check people in.
            require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED");

            //require that attendee trying to check in registered.
            address frenClaimed;

            for (uint8 i = 0; i < myEvent.confirmedFren.length; i++) {
                if(myEvent.confirmedFren[i] == attendee) {
                    frenClaimed = myEvent.confirmedFren[i];
                }
            }
            require(frenClaimed == attendee, "NOT REGISTERED FOR EVENT");

            //require that attendee is Not already in the frenClaimed list and make sure they have not checked into event
            for (uint8 i = 0; i < myEvent.frenClaimed.length; i++) {
                require(myEvent.frenClaimed[i] != attendee, "ALREADY CLAIMED");
   //require that deposits are not already claimed by the event owner
                require(myEvent.paidOut == false, "ALREADY PAID OUT");
         
            myEvent.frenClaimed.push(attendee);
            
            //sending ETH back to Staker
            (bool sent,) = attendee.call{value: myEvent.deposit}("");

            if(!sent) {
                myEvent.frenClaimed.pop();
            }
            require(sent, "FAILED TO SEND ETH");

            emit ConfirmedAttendee(eventId, attendee);
            }
    }

        function withdrawUnclaimedDeposits(bytes32 eventId) external {
            CreateEvent memory myEvent = idToEvent[eventId];

            require(!myEvent.paidOut, "ALREADY PAID");

            require(
                block.timestamp >= (myEvent.eventTimeStamp + 7 days),
                "TOO EARLY"
            );

            require(msg.sender == myEvent.eventOwner, "MUST BE EVENT OWNER");

            uint256 unclaimed = myEvent.confirmedFren.length - myEvent.frenClaimed.length;

            uint256 payout = unclaimed * myEvent.deposit;

            myEvent.paidOut = true;

            (bool sent, ) = msg.sender.call{value: payout}("");

            if (!sent) {
                myEvent.paidOut = false;
            }
            require(sent, "FAILED TO SEND ETH");

            emit DepositIsPaidOut(eventId);
        }
}