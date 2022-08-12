/**
 *Submitted for verification at polygonscan.com on 2022-08-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// define the smart contract & its associated information to be stored on chain
// properties that each individual event will have
// to save up on storage space, we do not store details such as the event's name
// or description on chain, but only the reference to the IPFS hash (eventDataCID)
contract Web3RSVP {

	// define events that allow interaction 

	event NewEventCreated(
		bytes32 eventID, // eventId in the functions below
		address creatorAddress,
		uint256 eventTimestamp,
		uint256 maxCapacity,
		uint256 deposit,
		string eventDataCID
	);

	event NewRSVP(bytes32 eventID, address attendeeAddress);

	event ConfrimedAttendee(bytes32 eventID, address attendeeAddress);

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

	// map events to their references
	mapping(bytes32 => CreateEvent) public idToEvent;

	function createNewEvent(
		uint256 eventTimestamp, // event deets (start date/time)
		uint256 deposit, // event deets (deposit to RSVP)
		uint256 maxCapacity, // event deets (max # attendees)
		string calldata eventDataCID // reference to IPFS hash that contains more information on the event (e.g. name)
	) external { // visibility = external, for performance and to save on gas
		// generate eventID based on parameters to be hashed
		bytes32 eventId = keccak256( // create unique ID event by hashing relevant parameters
			abi.encodePacked(
				msg.sender, // user (event initiator) ID
				address(this),
				eventTimestamp,
				deposit,
				maxCapacity
			)
		// make sure eventId is unique // To-Do: not sure where to put it
	//	require(idToEvent[eventId].eventTimestamp == 0, "ALREADY REGISTERED");

		);

	address[] memory confirmedRSVPs; // how many confirmed
	address[] memory claimedRSVPs; // how many attended

	// create new event CreateEvent (struct/class) and add it to the mapping (idToEvent)
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

	// events must be emitted once they happen
	emit NewEventCreated(
		eventId,
		msg.sender,
		eventTimestamp,
		maxCapacity,
		deposit,
		eventDataCID
	);

	}

	// function registeres new attendee to the eventId passed as argument
	// user RVSPs
	function createNewRSVP(bytes32 eventId) external payable {

		// the respective event (myEvent) is the one mapped to eventId in the idToEvent mapping
		CreateEvent storage myEvent = idToEvent[eventId];

		// transfer deposit from registering attendee (require enough ETH for registration price)
		// if the value paid by the attendee is not the same as the required deposit, raise 'not enough' alert
		require(msg.value == myEvent.deposit, "NOT ENOUGH"); 

		// the event start time must be in the future (i.e., it has not happened yet)
		require(block.timestamp <= myEvent.eventTimestamp, "ALREADY HAPPENED");

		// # RSVPs must not exceed capacity
		require(myEvent.confirmedRSVPs.length < myEvent.maxCapacity, "This event had reached capacity");

		// the RSVP must not have not already RSVPed (i.e., the RSVP must be new)
		for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) { // for each confirmed attendee
			require(myEvent.confirmedRSVPs[i] != msg.sender, "ALREADY CONFIRMED"); // ensure it's not the new one
		}

		// if all conditions met, add the new RSVP
		myEvent.confirmedRSVPs.push(payable(msg.sender));

		emit NewRSVP(eventId, msg.sender);

	}

	// once the attendee checked-in at the event, return their deposit, otherwise keep it
	// confirm one attendee
	function confirmAttendee(bytes32 eventId, address attendee) public {
		// find event in map based on id
		CreateEvent storage myEvent = idToEvent[eventId];

		// sender of the message (attendance confirmation message) should be the event owner, else raise authorization error
		require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED");

		address rsvpConfirm;

		// require that the attendee attempting to check-in has previously RSVPd
		for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
			if(myEvent.confirmedRSVPs[i] == attendee) { // if the attendee is in the RSVP list
				rsvpConfirm = myEvent.confirmedRSVPs[i]; // rsvpConfirm is set to the attendee's address
			}
		}

		// the two values must match (same wallet address)
		require(rsvpConfirm == attendee, "NO RSVP TO CONFIRM");

		// the attendee must not have already be confirmed as checked-in (and thus issued a deposit refund)
		for (uint8 i = 0; i < myEvent.claimedRSVPs.length; i++) {
			require(myEvent.claimedRSVPs[i] != attendee, "ALREADY CLAIMED");
		}

		// for respective event, the deposits must not have been paid out
		require(myEvent.paidOut == false, "ALREADY PAID OUT");

		// acknowledge that the attendee must be given deposit back (i.e., make it to the list of claimed addresses)
		myEvent.claimedRSVPs.push(attendee);

		// sent deposits back to the claimed attendee
		// how to send ether: https://solidity-by-example.org/sending-ether
		(bool sent,) = attendee.call{value: myEvent.deposit}("");

		// if the transfer fails, remove attendee from refunded (claimed) RSVPs
		if (!sent) {
			myEvent.claimedRSVPs.pop(); // pops the last one
		}

		require(sent, "Failed to send Ether"); // if the transaction failed (sent = 0), raise warning

		emit ConfrimedAttendee(eventId, attendee);
	}

	// confirm multiple attendees at the same time
	function confirmAllAttendees(bytes32 eventId) external {

		// same as above
		CreateEvent memory myEvent = idToEvent[eventId];

		// same as above
		require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED");

		// confirm all attendees in the RSVPd array at once
		for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
			confirmAttendee(eventId, myEvent.confirmedRSVPs[i]);
		}
	}

	// unclaimed deposits (RSVPs who did not check-in) sent to the event organizer
	function withdrawUnclaimedDeposits(bytes32 eventId) external {

		// same as above
		CreateEvent memory myEvent = idToEvent[eventId];

		// verify that the unclaimed deposits have not already been sent to the owner
		require(!myEvent.paidOut, "ALREADY PAID");

		// check that at least 7 days since the event passed (else must wait)
		require(block.timestamp >= (myEvent.eventTimestamp + 7 days), "TOO EARLY");

		// only the owner can withdraw
		require(msg.sender == myEvent.eventOwner, "MUST BE EVENT OWNER");

		// calculate number of RSVPs who did not check-in
		uint256 unclaimed = myEvent.confirmedRSVPs.length - myEvent.claimedRSVPs.length;

		// calculate how much the owner will withdraw
		uint256 payout = unclaimed * myEvent.deposit;

		// mark as paid before sending ether to prevent REENTRANCY ATTACKS (https://quantstamp.com/blog/what-is-a-re-entrancy-attack)
		myEvent.paidOut = true;

		// send payout to owner
		(bool sent, ) = msg.sender.call{value: payout}("");

		// if failed
		if (!sent) {
			myEvent.paidOut = false;
		}

		// same as above
		require(sent, "Failed to send Ether");

		emit DepositsPaidOut(eventId);
		}
	
}


// TO-DO: Custom Solidity Events: https://www.30daysofweb3.xyz/en/curriculum/3-writing-your-smart-contract/4-custom-solidity-events