/**
 *Submitted for verification at polygonscan.com on 2022-11-12
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Web3RSVP{
    //Events
    event NewEventCreated(
        bytes32 eventId,
        address creatorAddress,
        uint256 eventTimestamp,
        uint256 maxCapacity,
        uint256 deposit,
        string eventDataCID
    );
    
    event NewRSVP(bytes32 eventID, address attendeeAddress);
    event ConfirmedAttendee(bytes32 eventID, address attendeeAddress);
    event DepositsPaidOut(bytes32 eventID);

    //1. Event struct that contains all properties someone would need to create an event
    // eventDataCID is a string url for all data stored offchain on IPFS
    struct CreateEvent{
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

    //2. Mapping for to index all events. idToEvent(321) = that certain event
    //Mapping is like a hashtable and array is just an array with index. Mapping is key to value
    mapping (bytes32 => CreateEvent) public idToEvent;

    //3. Function with parameters of the new event 
    // memory = is reserved for variables that are defined within the scope of a function. 
    // calldata = an immutable(not changing), temporary location wehre function arguments are stored, and behaves mostly like memory.
    function createNewEvent(
        uint256 eventTimestamp,
        uint256 deposit,
        uint256 maxCapacity,
        string calldata eventDataCID
    ) external {

        //Creates a unique id for the event to help map to certain event
        bytes32 eventId = keccak256(
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

        //Create the event 
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

        //Emit createEVENT
        emit NewEventCreated(eventId, msg.sender, eventTimestamp, maxCapacity, deposit, eventDataCID);
    }

    //4. RSVP function for the event it has to be payable because inorder to rsvp to the event you need to pay a fee which they will get back 
    function createNewRSVP(bytes32 eventId) external payable{
        // look up event from our mapping 
        //The storage word is used as a pointer 
        CreateEvent storage myEvent = idToEvent[eventId];

        //transfer deposit to our contract / require that they send in enough ETH 
        require(msg.value == myEvent.deposit, "NOT ENOUGH");

        //require that the event hasn't already happened
        require(block.timestamp <= myEvent.eventTimestamp, "ALREADY HAPPENED");

        //make sure event is under max capacity 
        require(
            myEvent.confirmedRSVPs.length < myEvent.maxCapacity,
            "this event has reached capacity"
        );

        //require that msg.sender isn't already in myEvent.confirmedRSVPs
        for(uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++){
            require(myEvent.confirmedRSVPs[i] != msg.sender, "ALREADY CONFIRMED");

        }

        myEvent.confirmedRSVPs.push(payable(msg.sender));

        //Emit the newRSVP event
        emit NewRSVP(eventId, msg.sender);
    }

    //5.Confirm attendee for event
    function confirmAttendee(bytes32 eventId, address attendee) public {
        //look up event from our struct using the eventId
        CreateEvent storage myEvent = idToEvent[eventId];

        //require that msg.sender is the owner of the event 
        require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED");

        //require that attendee trying to check in actually RSVP'd
        address rsvpConfirm;

        for(uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++){
            if(myEvent.confirmedRSVPs[i] == attendee){
                rsvpConfirm = myEvent.confirmedRSVPs[i];
            }
        }

        require(rsvpConfirm == attendee, "NO RSVP TO CONFIRM");

        //require that attendee is NOT already in the claimedRSVPs list AKA make sure they haven't already check in
        for(uint8 i = 0; i < myEvent.claimedRSVPs.length; i++){
            require(myEvent.claimedRSVPs[i] != attendee, "ALREADY CLAIMED");
        }

        //require that deposits are not already claimed by the event owner
        require(myEvent.paidOut == false, "ALREADY PAID OUT");

        // add the attendee to the claimedRSVPs list
        myEvent.claimedRSVPs.push(attendee);

        //sending eth back to the staker 
        (bool sent, ) = attendee.call{value: myEvent.deposit}("");

        //if this fails, remove the user for the array of claimed RSVPs
        if(!sent){
            myEvent.claimedRSVPs.pop();
        }

        require(sent, "FAILED to send Ether");

        //Emit confirm attendee event 
        emit ConfirmedAttendee(eventId, attendee);

    }

    function confirmAllAttendees(bytes32 eventId) external{
        //look up event from our struct with the eventId
        CreateEvent memory myEvent = idToEvent[eventId];

        //make sure you require that msg.sender is the owner of the event
        require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED");

        //confirm each attendee in the rsvp array
        for(uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++){
            confirmAttendee(eventId, myEvent.confirmedRSVPs[i]);
        }

    }

    function withdrawUnclaimedDeposits(bytes32 eventId) external {
        //look up event
        CreateEvent memory myEvent = idToEvent[eventId];

        //check that the paidOut boolean still equals false AKA the money
        require(!myEvent.paidOut, "ALREADY PAID");

        //check if thats been 7 days past myevent.eventTimestamp
        require(block.timestamp >= (myEvent.eventTimestamp + 7 days), "TOO EARLY");

        //only the event owner can withdraw
        require(msg.sender == myEvent.eventOwner, "MUST BE EVENT OWNER");

        //calculate how many people didn't claim by comparing
        uint256 unclaimed = myEvent.confirmedRSVPs.length - myEvent.claimedRSVPs.length;

        uint256 payout = unclaimed * myEvent.deposit;

        //mark as paid before sending to avoid reentracy attack
        myEvent.paidOut = true;

        //send the payout to the owner
        (bool sent, ) = msg.sender.call{value: payout}("");

        //if this fails 
        if(!sent){
            myEvent.paidOut = false;
        }

        require(sent, "Failed to send Ether");

        //emit deposit paid out event 
        emit DepositsPaidOut(eventId);

    }


}