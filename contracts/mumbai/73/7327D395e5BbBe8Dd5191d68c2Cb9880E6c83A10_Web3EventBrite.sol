/**
 *Submitted for verification at polygonscan.com on 2022-08-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Web3EventBrite {

    // Create events
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

    // The CreateEvent struct provides a struct of with specific event attributes
    struct CreateEvent {
        bytes32 eventId;
        string eventDataCID;    //Hash to store in IPFS to avoid storing more data on chain
        address eventOwner;
        uint256 eventTimestamp;
        uint256 deposit;
        uint256 maxCapacity;
        address[] confirmedRSVPs;
        address[] claimedRSVPs;
        bool paidOut;
    }

    // Use a dictionary to map event Id to an event struct
    mapping(bytes32 => CreateEvent) public idToEvent;

    /*
        The createNewEvent function uses external visibility to perform better which ends up saving on gas.
     */
    function createNewEvent(
        uint256 eventTimestamp,
        uint256 deposit,
        uint256 maxCapacity,
        string calldata eventDataCID // The calldata memory type is an immutable and temporary memory location
    ) external{

        /*
            Create an eventId by hashing using a unique hash value based on the specific parameters of the function.
            This helps avoid collisions
        */
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

        // Expose the data from the createNewEvent function
        emit NewEventCreated(
            eventId,
            msg.sender,
            eventTimestamp,
            maxCapacity,
            deposit,
            eventDataCID
        );
    }

    function createNewRSVP(bytes32 eventId) external payable {

        // Using storage we consume more gas but it helps to keep each execution of the smart contract
        CreateEvent storage myEvent = idToEvent[eventId];

        // Require that the user sends enough ETH to cover the deposit
        require(msg.value == myEvent.deposit, "INSUFFICIENT FUNDS");

        // Require that event has not already happened
        require(block.timestamp <= myEvent.eventTimestamp, "EVENT HAS ALREADY PASSED");

        // Require that the event is not at maximum capicity
        require(myEvent.confirmedRSVPs.length < myEvent.maxCapacity, "EVENT HAS REACHED MAXIMUM CAPACITY");

        // Require that the RSVP person has not already RSVP'd
        for(uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            require(msg.sender != myEvent.confirmedRSVPs[i], "RSVP HAS ALREADY BEEN CONFIRMED");
        }
        
        myEvent.confirmedRSVPs.push(payable(msg.sender));

        emit NewRSVP(eventId,msg.sender);
    }

    function confirmAttendee(bytes32 eventId, address attendee) public {

        // Use CreateEvent struct based on eventId
        CreateEvent storage myEvent = idToEvent[eventId];

        // Require that the owner of the event is msg.sender
        require(msg.sender == myEvent.eventOwner,"NOT AUTHORIZED");

        // Require that the person who always checked in RSVP'd
        address rsvpConfirmation;

        for(uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            if( myEvent.confirmedRSVPs[i] == attendee ){
                rsvpConfirmation = myEvent.confirmedRSVPs[i];
            }
        }

        require(rsvpConfirmation == attendee, "ATTENDEE NOT IN RSVP LIST");

        // Require that attendee has not already checked in
        for(uint8 i = 0; i < myEvent.claimedRSVPs.length; i++) {
            require(attendee != myEvent.claimedRSVPs[i], "ATTENDEE HAS ALREADY CONFIRMED");
        }

        // Require that the attendee has not paid the owner yet
        require(myEvent.paidOut == false, "ATTENDEE HAS ALREADY PAID");

        // Send Eth back to the staker
        // This is where the calls are explained: https://solidity-by-example.org/sending-ether/
        (bool sent,) = attendee.call{value: myEvent.deposit}("");

        if(sent == false){
            myEvent.claimedRSVPs.pop();
        }

        require(sent, "FAILED TO SEND ETHER: IN CONFIRMATION");

        emit ConfirmedAttendee(eventId, attendee);
    }

    function confirmAllAttendees(bytes32 eventId) external {

        // The memory keyword is used as temporary memory within the method
        CreateEvent memory myEvent = idToEvent[eventId];

        // Require that the msg.sender is the owner of the event
        require(msg.sender == myEvent.eventOwner,"NOT AUTHORIZED");

        // Iterate through confirmedRSVPs to confirm all attendees
        for(uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++){
            confirmAttendee(eventId, myEvent.confirmedRSVPs[i]);
        }
    }

    function withdrawUnclaimedDeposits(bytes32 eventId) external {
        
        // Get event from mapping usinfg 
        CreateEvent memory myEvent = idToEvent[eventId];

        // Require that the deposits has not been paid out yet
        require(!myEvent.paidOut,"ALREADY PAID OUT");

        // Require that it has been over a week from the event date
        require(myEvent.eventTimestamp <= (block.timestamp + 7 days), "HAS NOT PASSED 7 DAYS SINCE EVENT");

        // Require that the owner of the contract is executing this method
        require(msg.sender == myEvent.eventOwner,"NOT AUTHORIZED");

        // Calculate unclaimed funds to send back Eth to users who did not go to the event
        uint256 payoutFunds = (myEvent.confirmedRSVPs.length - myEvent.claimedRSVPs.length)*myEvent.deposit;

        // Set event to paid out before sending to avoid reentrancy attacks
        myEvent.paidOut = true;


        (bool sent,) = msg.sender.call{value: payoutFunds}("");

        if(!sent){
            myEvent.paidOut == false;
        }

        require(sent,"FAILED TO SEND ETHER: withdrawUnclaimedDeposits");

        emit DepositsPaidOut(eventId);
    }

}