/**
 *Submitted for verification at polygonscan.com on 2023-05-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

  mapping(bytes32 => CreateEvent) public idToEvent;

  function createNewEvent(
    uint256 _eventTimestamp,
    uint256 _deposit,
    uint256 _maxCapacity,
    string calldata _eventDataCID
  ) external {

    bytes32 eventId = keccak256(
      abi.encode(
        msg.sender,
        address(this),
        _eventTimestamp,
        _deposit,
        _maxCapacity
      )
    );

    address [] memory confirmedRSVPs;
    address [] memory claimedRSVPs;

    idToEvent[eventId] = CreateEvent(
        eventId,
        _eventDataCID,
        msg.sender,
        _eventTimestamp,
        _deposit,
        _maxCapacity,
        confirmedRSVPs,
        claimedRSVPs,
        false
    );


    emit NewEventCreated(eventId, msg.sender, _eventTimestamp, _maxCapacity, _deposit, _eventDataCID);
  }

  function createNewRSVP(bytes32 _eventId) external payable  {

    CreateEvent storage myEvent = idToEvent[_eventId];

    require(msg.value == myEvent.deposit, "Not Enough Matic Paid");
    require(block.timestamp <= myEvent.eventTimestamp, "Event Started");
    require(myEvent.confirmedRSVPs.length < myEvent.maxCapacity, "Max Capacity Reached");

    for(uint8 i=0;i<myEvent.confirmedRSVPs.length; i++){
      require(myEvent.confirmedRSVPs[i] != msg.sender, "Already Confirmed");
    }

    myEvent.confirmedRSVPs.push(payable(msg.sender));

    emit NewRSVP(_eventId, msg.sender);
  }

  function confirmAttendee(bytes32 _eventId, address _attendee) public{

    CreateEvent storage myEvent = idToEvent[_eventId];

    require(myEvent.eventOwner == msg.sender,"Not Authorised");

    address rsvpConfirm;

    for(uint8 i = 0 ;i < myEvent.confirmedRSVPs.length; i++){
      if(myEvent.confirmedRSVPs[i] == _attendee){
        rsvpConfirm = _attendee;
      }
    }

    require(rsvpConfirm == _attendee, "No RSVP to Confirm");

    for(uint8 i = 0 ;i< myEvent.claimedRSVPs.length; i++ ){
      require(myEvent.claimedRSVPs[i] != _attendee, "Already Claimed" );
    }

    require(myEvent.paidOut == false, "Already Paid Out");

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

  function confirmAllAttendees(bytes32 _eventId) external{

    CreateEvent storage myEvent = idToEvent[_eventId];

    require(msg.sender == myEvent.eventOwner,"Not Authorised");

    for(uint8 i = 0;i<myEvent.confirmedRSVPs.length;i++){
      confirmAttendee(_eventId, myEvent.confirmedRSVPs[i]);
    }

  }

  function withdrawUnclaimedDeposits(bytes32 _eventId) external {
    // look up event
    CreateEvent memory myEvent = idToEvent[_eventId];

    // check that the paidOut boolean still equals false AKA the money hasn't already been paid out
    require(!myEvent.paidOut, "ALREADY PAID");

    // check if it's been 7 days past myEvent.eventTimestamp
    require(
        block.timestamp >= (myEvent.eventTimestamp + 7 days),
        "TOO EARLY"
    );

    // only the event owner can withdraw
    require(msg.sender == myEvent.eventOwner, "MUST BE EVENT OWNER");

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