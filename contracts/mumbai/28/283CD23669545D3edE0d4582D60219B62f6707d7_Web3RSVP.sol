/**
 *Submitted for verification at polygonscan.com on 2022-08-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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

  // Event structure
  struct CreateEvent {
    // event ID
    bytes32 eventId;
    string eventDataCID;
    // Wallet address of the event creator
    address eventOwner;
    // Timestamp of when the even starts. * 1000 to get a UNIX timestamp
    uint256 eventTimestamp;
    // Deposit amount
    uint256 deposit;
    // Maximum capacity of attendees
    uint256 maxCapacity;
    // Array of wallet addresses of users who RSVP’d
    address[] confirmedRSVPs;
    // Array of wallet addresses of users who check into the event
    address[] claimedRSVPs;
    bool paidOut;
  }
  // Allow us to lookup events by ID
  mapping(bytes32 => CreateEvent) public idToEvent;

  /* *
   * - Creates a new attendable event.
   * @param {uint256} evenTimestamp: timestamp in ms of when the event will start
   * @param {uint256} deposit: amount of ETH required to RSVP to the event
   * @param {uint256} maxCapacity: max capacity of the event
   * @param {string} eventDataCID: reference to the IPFS hash containing the event info
   * */
  function createNewEvent(
    uint256 eventTimestamp,
    uint256 deposit,
    uint256 maxCapacity,
    string calldata eventDataCID
  ) external {
    // `external` sets the function visibility to external since it is highly performant and saves on gas.

    // generate an eventID based on other things passed in to generate a hash
    // generates a unique eventID by hashing together the values we passed
    bytes32 eventId = keccak256(abi.encodePacked(msg.sender, address(this), eventTimestamp, deposit, maxCapacity));

    // array to track RSVPs
    address[] memory confirmedRSVPs;
    // arrays to track event attendees
    address[] memory claimedRSVPs;

    // Creates a new CreateEvent struct and adds it to the idToEvent mapping
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

  /* *
   * - RSVP a user to a given event.
   * @param {bytes32} eventId: id of the event
   * */
  function createNewRSVP(bytes32 eventId) external payable {
    // look up event from our mapping
    CreateEvent storage myEvent = idToEvent[eventId];

    // transfer deposit to our contract / require that they send in enough ETH to cover the deposit requirement of this specific event
    require(msg.value == myEvent.deposit, 'NOT ENOUGH');

    // require that the event hasn't already happened (<eventTimestamp)
    require(block.timestamp <= myEvent.eventTimestamp, 'ALREADY HAPPENED');

    // make sure event is under max capacity
    require(myEvent.confirmedRSVPs.length < myEvent.maxCapacity, 'This event has reached capacity');

    // require that msg.sender isn't already in myEvent.confirmedRSVPs AKA hasn't already RSVP'd
    for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
      require(myEvent.confirmedRSVPs[i] != msg.sender, 'ALREADY CONFIRMED');
    }

    myEvent.confirmedRSVPs.push(payable(msg.sender));
    emit NewRSVP(eventId, msg.sender);
  }

  /* *
   * - Checks-in attendees and returns their ETH deposit.
   * @param {bytes32} eventId: id of the event
   * @param {address} attendee: wallet address of the user to check-in
   * */
  function confirmAttendee(bytes32 eventId, address attendee) public {
    // look up event from our struct using the eventId
    CreateEvent storage myEvent = idToEvent[eventId];

    // require that msg.sender is the owner of the event - only the host should be able to check people in
    require(msg.sender == myEvent.eventOwner, 'NOT AUTHORIZED');

    // require that attendee trying to check in actually RSVP'd
    address rsvpConfirm;

    for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
      if (myEvent.confirmedRSVPs[i] == attendee) {
        rsvpConfirm = myEvent.confirmedRSVPs[i];
      }
    }

    require(rsvpConfirm == attendee, 'NO RSVP TO CONFIRM');

    // require that attendee is NOT already in the claimedRSVPs list AKA make sure they haven't already checked in
    for (uint8 i = 0; i < myEvent.claimedRSVPs.length; i++) {
      require(myEvent.claimedRSVPs[i] != attendee, 'ALREADY CLAIMED');
    }

    // require that deposits are not already claimed by the event owner
    require(myEvent.paidOut == false, 'ALREADY PAID OUT');

    // add the attendee to the claimedRSVPs list
    myEvent.claimedRSVPs.push(attendee);

    // sending eth back to the staker `https://solidity-by-example.org/sending-ether`
    (bool sent, ) = attendee.call{value: myEvent.deposit}('');

    // if this fails, remove the user from the array of claimed RSVPs
    if (!sent) {
      myEvent.claimedRSVPs.pop();
    }

    require(sent, 'Failed to send Ether');
    emit ConfirmedAttendee(eventId, attendee);
  }

  /* *
   * - Confirm every person that has RSVPs to a specific event.
   * @param {bytes32} eventId: id of the event
   * */
  function confirmAllAttendees(bytes32 eventId) external {
    // look up event from our struct with the eventId
    CreateEvent memory myEvent = idToEvent[eventId];

    // make sure you require that msg.sender is the owner of the event
    require(msg.sender == myEvent.eventOwner, 'NOT AUTHORIZED');

    // confirm each attendee in the rsvp array
    for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
      confirmAttendee(eventId, myEvent.confirmedRSVPs[i]);
    }
  }

  /* *
   * - Withdraw deposits of people who didn’t show up to the event & send them to the event organizer.
   * - Note: the event organizer = the wallet address that created the event.
   * @param {bytes32} eventId: id of the event
   * */
  function withdrawUnclaimedDeposits(bytes32 eventId) external {
    // Look up event
    CreateEvent memory myEvent = idToEvent[eventId];

    // Check that the paidOut boolean still equals false AKA the money hasn't already been paid out
    require(!myEvent.paidOut, 'ALREADY PAID');

    // Check if it's been 7 days past myEvent.eventTimestamp
    require(block.timestamp >= (myEvent.eventTimestamp + 7 days), 'TOO EARLY');

    // Only the event owner can withdraw
    require(msg.sender == myEvent.eventOwner, 'MUST BE EVENT OWNER');

    // Calculate how many people didn't claim by comparing
    uint256 unclaimed = myEvent.confirmedRSVPs.length - myEvent.claimedRSVPs.length;

    uint256 payout = unclaimed * myEvent.deposit;

    // Mark as paid before sending to avoid reentrancy attack
    myEvent.paidOut = true;

    // Send the payout to the owner
    (bool sent, ) = msg.sender.call{value: payout}('');

    // If this fails
    if (!sent) {
      myEvent.paidOut == false;
    }

    require(sent, 'Failed to send Ether');
    emit DepositsPaidOut(eventId);
  }
}