/**
 *Submitted for verification at polygonscan.com on 2022-08-25
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


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
        string eventDataCID; //was not clear from requirements but contains link to IPFS for name and details
        address eventOwner;
        uint256 eventTimestamp;
        uint256 deposit;
        uint256 maxCapacity;
        address[] confirmedRSVPs;
        address[] claimedRSVPs;
        bool paidOut;
    }

    mapping(bytes32 => CreateEvent) idToEvent;



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
            ) //maybe delete
        );

        emit NewEventCreated(
            eventId,
            msg.sender,
            eventTimestamp,
            maxCapacity,
            deposit,
            eventDataCID
            );
        

      
        address[] memory confirmedRSVPs;
        address[] memory claimedRSVPs;



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
    }


    function createNewRSVP(bytes32 eventId)external payable{

        CreateEvent storage myEvent = idToEvent[eventId];

    
        require(msg.value == myEvent.deposit, "Not enough deposit");

 
        require(block.timestamp <= myEvent.eventTimestamp, "Event already happened");


         require(myEvent.confirmedRSVPs.length < myEvent.maxCapacity,
        "This event has reached capacity");

        
        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++){
            require(myEvent.confirmedRSVPs[i] != msg.sender, "Already confirmed");
        }


        myEvent.confirmedRSVPs.push(payable(msg.sender));

        emit NewRSVP(eventId, msg.sender);
    }

    function confirmAttendee(bytes32 eventId, address attendee) public{
     
        CreateEvent storage myEvent = idToEvent[eventId];


        require(msg.sender == myEvent.eventOwner, "Not authorized");

     
        address rsvpConfirm;

        for(uint i = 0; i < myEvent.confirmedRSVPs.length; i++){
            if(myEvent.confirmedRSVPs[i] == attendee){
                rsvpConfirm = myEvent.confirmedRSVPs[i]; //address gets assigned the right value
            }
        }

 

        require(rsvpConfirm == attendee, "No RSVP to confirm");


    
         for(uint i = 0; i < myEvent.claimedRSVPs.length; i++){
             require(myEvent.claimedRSVPs[i] != attendee, "Already claimed");
         } 


         require(myEvent.paidOut == false, "Already paid out");

         myEvent.claimedRSVPs.push(attendee);

     
         (bool sent,) = attendee.call{value: myEvent.deposit}(""); //where are they sending it to though? to the smart contract

      
         if(!sent) {
             myEvent.claimedRSVPs.pop(); //pops the last element
         }

         require(sent, "Failed to send Ether");

         emit ConfirmedAttendee(eventId, attendee);
    }


    function confirmAllAttendees(bytes32 eventId) external {
 
        CreateEvent memory myEvent = idToEvent[eventId];

       
        require(msg.sender == myEvent.eventOwner, "Not authorized");

   
        for(uint i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            confirmAttendee(eventId, myEvent.confirmedRSVPs[i]);
        }
    }


    function withdrawUnclaimedDeposits(bytes32 eventId) external{
        CreateEvent memory myEvent = idToEvent[eventId];

      
        require(!myEvent.paidOut, "Already paid");

   
        require(block.timestamp >= myEvent.eventTimestamp + 7 days, "Too early withdraw");

 
        require(msg.sender == myEvent.eventOwner, "Must be event owner");


        uint256 unclaimed = myEvent.confirmedRSVPs.length - myEvent.claimedRSVPs.length;

        uint256 payout = unclaimed * myEvent.deposit;

        myEvent.paidOut = true; //I guess everything paid out at once


        (bool sent,) = msg.sender.call{value: payout}("");

     
        if(!sent){
            myEvent.paidOut = false;
        }
        require(sent, "Failed to send Ether");

        emit DepositsPaidOut(eventId);
    }
}