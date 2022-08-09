/**
 *Submitted for verification at polygonscan.com on 2022-08-08
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Web3RSVP {

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
    uint256 maxCapacity,
    string calldata eventDataCID
  ) external {
      // Generate an eventID based on other things passed in to generate a hash
      bytes32 eventId = keccak256(
        abi.encodePacked(
          msg.sender,
          address(this),
          eventTimestamp,
          deposit,
          maxCapacity
        )
      );

      require(idToEvent[eventId].eventTimestamp == 0, "ALREADY REGISTERED");

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

      emit NewEventCreated(eventId, msg.sender, eventTimestamp, maxCapacity, deposit, eventDataCID);
  }

  function createNewRSVP(bytes32 eventId) external payable {

    // look up event from our mapping
    CreateEvent storage myEvent = idToEvent[eventId];

    // transfer deposit to our contract require that they send in enough ETH
    // to cover the deposit
    require(msg.value == myEvent.deposit, "NOT ENOUGH");

    // require that the event hasn't already started
    require(block.timestamp <= myEvent.eventTimestamp, "ALREADY HAPPENED");

    // confirm that the event is under its max capacity
    require(
      myEvent.confirmedRSVPs.length < myEvent.maxCapacity,
      "This event has reached capacity"
    );

    // confirm unique confirmation from msg.sender
    for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
      require(myEvent.confirmedRSVPs[i] != msg.sender, "ALREADY CONFIRMED");
    }

    myEvent.confirmedRSVPs.push(payable(msg.sender));

    emit NewRSVP(eventId, msg.sender);
  }

  function confirmAttendee(bytes32 eventId, address attendee) public {
    // look up event from our struct using the eventId
    CreateEvent storage myEvent = idToEvent[eventId];
    require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED");

    // require that attendee trying to check in is actually RSVP'd
    address rsvpConfirm;

    for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
      if (myEvent.confirmedRSVPs[i] == attendee) {
        rsvpConfirm = myEvent.confirmedRSVPs[i];
      }
    }

    require(rsvpConfirm == attendee, "NO RSVP TO CONFIRM");

    // require that attendee is not already paid
    for (uint8 i = 0; i < myEvent.claimedRSVPs.length; i++) {
      require (myEvent.claimedRSVPs[i] != attendee, "ALREADY CLAIMED");
    }

    // require that deposits are not already claimed by the event owner
    require(myEvent.paidOut == false, "ALREADY PAID OUT");

    // add the attendee to the claimedRSVPs list
    myEvent.claimedRSVPs.push(attendee);

    // send eth back to the staker
    (bool sent,) = attendee.call{value: myEvent.deposit}("");

    // if that fails, remove the user from the array of claimed RSVPs
    if (!sent) {
      myEvent.claimedRSVPs.pop();
    }

    require(sent, "Failed to send Ether");

    emit ConfirmedAttendee(eventId, attendee);
  }

  function confirmAllAttendees(bytes32 eventId) external {
    // look up event from our struct with the eventId
    CreateEvent memory myEvent = idToEvent[eventId];

    // make sure you require that msg.sender is the owner of the event
    require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED");

    //  confirm each attendee in the RSVP array
    for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
      confirmAttendee(eventId, myEvent.confirmedRSVPs[i]);
    }
  }

  function withdrawUnclaimedDeposits(bytes32 eventId) external {
    // look up event from our struct with the eventId
    CreateEvent memory myEvent = idToEvent[eventId];

    // make sure you require that msg.sender is the owner of the event
    require(msg.sender == myEvent.eventOwner, "MUST BE EVENT OWNER");

    // check the money hasn't already been paid
    require(!myEvent.paidOut, "ALREADY PAID");

    // check if it's been 7 days past the event date
    require(block.timestamp >= (myEvent.eventTimestamp + 7 days), "TOO EARLY");

    uint256 unclaimed = myEvent.confirmedRSVPs.length - myEvent.claimedRSVPs.length;
    uint256 payout = myEvent.deposit * unclaimed;

    myEvent.paidOut = true;
    (bool sent,) = msg.sender.call{value: payout}("");

    if (!sent) {
      myEvent.paidOut = false;
    }

    require(sent, "FAILED TO SEND ETHER");

    emit DepositsPaidOut(eventId);
  }
}