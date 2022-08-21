/**
 *Submitted for verification at polygonscan.com on 2022-08-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Web3RSVP {
    event DepositsPaid(bytes32 eventId);
    event ConfirmedAttendee(bytes32 eventId, address attendee);
    event NewRSVP(bytes32 eventId,  address attendee);
    event NewEventCreated(bytes32 eventId, string eventDataCID, address eventOwner, uint256 eventTimestamp, uint256 deposit, uint256 maxCapacity);

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

    function createNewEvent( uint256 deposit, uint256 eventTimestamp, uint256 maxCapacity, string calldata eventDataCID) external {

        bytes32 eventId = keccak256(
            abi.encodePacked(
                msg.sender,
                address(this),
                eventTimestamp,
                deposit,
                maxCapacity
            )
        );

        address[] memory claimedRSVPs;
        address[] memory confirmedRSVPs;

        idToEvent[eventId] = CreateEvent(
           eventId,eventDataCID,msg.sender,eventTimestamp,deposit,maxCapacity,confirmedRSVPs,claimedRSVPs,false);
        emit NewEventCreated(eventId,eventDataCID,address(this),eventTimestamp,deposit,maxCapacity);
    }

    function rsvpToEvent(bytes32 eventId) external payable {
        CreateEvent storage myEvent = idToEvent[eventId];

        require(msg.value == myEvent.deposit,"Not exact money");
        require(block.timestamp <= myEvent.eventTimestamp, "Event Already happened");
        require(myEvent.maxCapacity > myEvent.confirmedRSVPs.length, "This event has reached maxCapacity");
        for(uint8 i =0; i<myEvent.confirmedRSVPs.length; i++){
            require(myEvent.confirmedRSVPs[i] != msg.sender,"User already RSVPed");
        }
        myEvent.confirmedRSVPs.push(payable(msg.sender));
        emit NewRSVP(eventId,msg.sender);
    }

    function confirmAttendees(bytes32 eventId, address attendee) public {
        CreateEvent storage myEvent = idToEvent[eventId]; 
        require(msg.sender == myEvent.eventOwner,"Not authorised");

        address rsvpConfirm;
         for(uint8 i =0; i<myEvent.confirmedRSVPs.length; i++){
            if(myEvent.confirmedRSVPs[i] == attendee){
                rsvpConfirm = attendee;
            }
        }
        require(rsvpConfirm == attendee, "Not RSVPed");
        for(uint8 i =0; i<myEvent.claimedRSVPs.length; i++){
            require(myEvent.claimedRSVPs[i] != attendee,"Already Claimed ");
        }
        require(!myEvent.paidOut, "Already paid out");
        myEvent.claimedRSVPs.push(attendee);
        (bool sent,) = attendee.call{value: myEvent.deposit}("");
        if(!sent){
            myEvent.claimedRSVPs.pop();
        }
        require(sent, "Failed to send ether");
        emit ConfirmedAttendee(eventId, attendee);
    }

    function confirmAllAttendees(bytes32 eventId) external {
        CreateEvent memory myEvent = idToEvent[eventId]; 
        require(msg.sender == myEvent.eventOwner,"Not authorised");
        for(uint8 i =0; i<myEvent.confirmedRSVPs.length; i++){
            confirmAttendees(eventId,myEvent.confirmedRSVPs[i]);
        }

    }

    function withdrawUnclaimedDeposits(bytes32 eventId) external {
        CreateEvent storage myEvent = idToEvent[eventId]; 
        require(!myEvent.paidOut, "Already paid out");
        require(block.timestamp > myEvent.eventTimestamp + 7 days, "Too early");
        require(msg.sender == myEvent.eventOwner,"Not authorised");
        uint256 unclaimed = myEvent.confirmedRSVPs.length - myEvent.claimedRSVPs.length;
        uint256 payout = unclaimed * myEvent.deposit;
        myEvent.paidOut = true;
        (bool sent,) = msg.sender.call{value: payout}("");
        if(!sent){
            myEvent.paidOut = false;
        }
        require(sent, "Failed to send payout");
        emit DepositsPaid(eventId);
    }
}