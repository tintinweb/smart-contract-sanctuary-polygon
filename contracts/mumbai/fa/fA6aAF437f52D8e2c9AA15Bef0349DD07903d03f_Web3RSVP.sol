/**
 *Submitted for verification at polygonscan.com on 2022-11-14
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
/*
import "hardhat/console.sol";

contract Greeter {
    string private greeting;

    constructor(string memory _greeting) {
        console.log("Deploying a Greeter with greeting:", _greeting);
        greeting = _greeting;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        console.log("Changing greeting from '%s' to '%s'", greeting, _greeting);
        greeting = _greeting;
    }
}
*/

contract Web3RSVP {
    event NewEventCreated(
        bytes32 eventID,
        address creatorAddress,
        uint256 eventTimestamp,
        uint256 maxCapacity,
        uint256 deposit,
        string eventDataCID
    );

    event NewRSVP(bytes32 eventId, address attendeeAddress);

    event ConfirmedAttendee(bytes32 eventID, address attendeeAddress);

    event DepositPaidOut(bytes32 eventID);

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
    uint256 eventTimestamp,
    uint256 deposit,
    uint maxCapacity, 
    string calldata eventDataCID
   ) external{
    //generate an eventID based on other things passed in to generate a hash
    bytes32 eventId = keccak256(
        abi.encodePacked(
            msg.sender,
            address(this),
            eventTimestamp, 
            deposit,
            maxCapacity
        )
    );

    // make sure this id isn't already claimed
    require(idToEvent[eventId].eventTimestamp == 0, "ALREADY REGISTERED");

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

   


   function createNewRSVP(bytes32 eventId) external payable{
    // Look up event from our mapping
    CreateEvent storage myEvent = idToEvent[eventId];

    // Transfer deposit to our contract / require that they send in enough ETH to cover the deposit
    //requirement of this specific event
    require(msg.value == myEvent.deposit, "NOT ENOUGH");

    // Require that the event hasn't already happened (<eventTimestamp)
    require(block.timestamp <= myEvent.eventTimestamp, "ALREADY HAPPENED");

    // Make sure event is under max capacity
    require(myEvent.confirmedRSVPs.length < myEvent.maxCapacity, "This event has reached capacity");

    // Require that msg.sender isn't already in myEvent.confirmedRSVPs AKA hasn't already RSVP'd
    for(uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++){
        require(myEvent.confirmedRSVPs[i] != msg.sender, "ALREADY CONFIRMED");
    }
    
    myEvent.confirmedRSVPs.push(payable(msg.sender));

    emit NewRSVP(eventId, msg.sender);

   }

   function confirmAttendee(bytes32 eventId, address attendee) public {

    // Look up event from our struct using the eventId
    CreateEvent storage myEvent = idToEvent[eventId];

    // Require that msg.seder is the owner of the event - only the host should be able to check people in
    require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED");

    // Require that attendee trying to check in actually RSVP'd
    address rsvpConfirm;
    for (uint8 i = 0; i< myEvent.confirmedRSVPs.length; i++) {
        if(myEvent.confirmedRSVPs[i] == attendee){
            rsvpConfirm = myEvent.confirmedRSVPs[i];
        }
    }
    require(rsvpConfirm == attendee, "NO RSVP TO CONFIRM");

    // Require that attendee is NOT already in the claimedRSVPs list AKA make sure they haven't already checked in
    for (uint8 i = 0; i < myEvent.claimedRSVPs.length; i++){
        require(myEvent.claimedRSVPs[i] != attendee, "ALREADY CLAIMED");
    }
    
    // Require that deposits are not already claimed by the event owner
    require(myEvent.paidOut == false, "ALREADY PAID OUT");
    
    // Add the attendee to the claimedRSVPs list
    myEvent.claimedRSVPs.push(attendee);

    // Sending ETH back to the staker 'https://solidity-by-example.org/sending-ether'
    (bool sent, ) = attendee.call{value: myEvent.deposit}("");

    //if this fails, remove the user from the array of claimed RSVPs
    if (!sent) {
        myEvent.claimedRSVPs.pop();
    }
    require(sent, "Failed to send ETH");

    emit ConfirmedAttendee(eventId, attendee);

   }

   function confirmAllAttendees(bytes32 eventId) external {
    // Look up event from our struct with the eventId
    CreateEvent memory myEvent = idToEvent[eventId];

    // make sure your require that msg.sender is the owner of the event
    require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED");

    // Confirm each attendee in the rsvp array
    for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++){
        confirmAttendee(eventId, myEvent.confirmedRSVPs[i]);
    }

   }

   function withdrawUnclaimedDeposits(bytes32 eventId) external {
    // Look up event
    CreateEvent memory myEvent = idToEvent[eventId];
    

    // Check that paidOut boolean still equals false AKA the money hasn't already beed paid
    require(!myEvent.paidOut, "ALREADY PAID");

    // Check if it's been 7 days past myEvent.eventTimestamp
    require(block.timestamp >= (myEvent.eventTimestamp + 7 days), "TOO EARLY");

    // Only the event owner can withdraw
    require(msg.sender == myEvent.eventOwner, "MUST BE EVENT OWNER");

    // Calculate how many people didn't claim by comparing
    uint256 unclaimed = myEvent.confirmedRSVPs.length - myEvent.claimedRSVPs.length;
    uint payout = unclaimed * myEvent.deposit;

    // Mark as paid before sending to avoid reentrancy attack
    myEvent.paidOut = true;

    // Send the payout to the owner
    (bool sent, ) = msg.sender.call{value: payout}("");

    // If this fails
    if(!sent){
        myEvent.paidOut = false;
    }
    require(sent, "Failed to send ETH");

    emit DepositPaidOut(eventId);
    
   }

}