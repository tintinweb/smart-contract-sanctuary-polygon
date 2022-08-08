/**
 *Submitted for verification at polygonscan.com on 2022-08-07
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//Contract is like a class in OOP (blueprint for object)
contract Web3RSVP {
/*Events are triggers.  Calling emit at the end of a our functions will expose the event data from the functions.
Will use this to create a dashboard (by using subgraphs, more to come in a future lesson)
*/
event NewEventCreated (
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

//Data structure for the events, each event will have these details
  	struct CreateEvent {
		bytes32 eventId;
	//eventDataCID will be stored in IPFS, blockchain storage is expensive
		string eventDataCID;
		address eventOwner;
		uint256 eventTimestamp;
		uint256 deposit;
		uint256 maxCapacity;
		address[] confirmedRSVPs;
		address[] claimedRSVPs;
		bool paidOut;
	}
//Allows you to store and look up events by identifier
//In this case it defines relationship of eventId to its respective CreateEvent structure.  
  	mapping(bytes32 => CreateEvent) public idToEvent;

//Function that is called when user creates new event on website front end
	function createNewEvent (
		//1. Takes in these arguments
		uint256 eventTimestamp,
		uint256 deposit,
		uint256 maxCapacity,
		string calldata eventDataCID
		) external {
				//2. Generates unique eventID based on below parameters
				bytes32 eventId = keccak256(
					abi.encodePacked(
						msg.sender,
						address(this),
						eventTimestamp,
						deposit,
						maxCapacity
					)
				);
		//3. Looks in the idToEvent mapping for the eventId and checks if the an event has already been initialized.  If the event
		//has not been created with all the same info, eventTimestamp associated with this generated eventId should be 0 or uninitialized.
		// require(idToEvent[eventId].eventTimestamp == 0, "ALREADY REGISTERED");

		address[] memory confirmedRSVPs;
		address[] memory claimedRSVPs;	
		//4. Here is where the new event is actually created and added to idToEvent mapping
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

	//Creates a new RSVP record when somebody RSVPs to an event on the website
	function createNewRSVP(bytes32 eventId) external payable {
		//Looks up specific event struct from the mapping by eventId
		CreateEvent storage myEvent = idToEvent[eventId];
		//Transfers deposit to contract, require that it matches the event's deposit amount
		require(msg.value == myEvent.deposit, "NOT ENOUGH");
		//Checks that event has already happened, if it did returns error
		require(block.timestamp <= myEvent.eventTimestamp, "ALREADY HAPPENED");
		//Checks that event is under max capacity, if it isn't returns error
		require(
			myEvent.confirmedRSVPs.length < myEvent.maxCapacity,
			"This event has reached capacity"
		);
		//loops through confirmedRSVPs list and checks if msg.sender has already RSVPed
		for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
			require(myEvent.confirmedRSVPs[i] != msg.sender, "ALREADY CONFIRMED");
		}

		myEvent.confirmedRSVPs.push(payable(msg.sender));

		emit NewRSVP(eventId, msg.sender);
	}

	//Confirms that an attendee who RSVPed attended the event, disburses deposit back to attendee wallet
	function confirmAttendee(bytes32 eventId, address attendee) public {
		//look up specific event struct by eventId 
		CreateEvent storage myEvent = idToEvent[eventId];
		//Checks if msg.sender is eventOwner, only eventOwner can confirm RSVPs
		require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED");
		//Declares a variable called rsvpConfirm, datatype is an address
		address rsvpConfirm;
		//Loops through confirmedRSVPs for the event, sets rsvpConfirm to matching address in confirmedRSVPs list if attendee
		//is found in the confirmedRSVPs list
		for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
			if(myEvent.confirmedRSVPs[i] == attendee){
				rsvpConfirm = myEvent.confirmedRSVPs[i];
			}
		}
		//Compares the address pulled out of the confirmedRSVP list (saved as rsvpConfirm) to address of attendee and checks
		//if they match, if address is not in list it means the user didn't RSVP and throws error
		require(rsvpConfirm == attendee, "NO RSVP TO CONFIRM");
		
		//Checks the for the attendee's address is claimedRSVPs list to make sure attendee hasn't already claimed their RSVP.
		for (uint8 i = 0; i < myEvent.claimedRSVPs.length; i++) {
			//Checks if attendee matches address in claimedRSVPs, if so it means they already RSVPed and throws error
			require(myEvent.claimedRSVPs[i] != attendee, "ALREADY CLAIMED");
			//Adds attendee's address to list of claimedRSVPs so they can't double claim
			myEvent.claimedRSVPs.push(attendee);
			//Sends ETH back to attendee
			(bool sent,) = attendee.call{value:myEvent.deposit}("");
			//If ETH doesn't send successfully, remove attendee from claimedRSVPs
			if (!sent) {
				myEvent.claimedRSVPs.pop();
			}
			//throws error if payment fails
			require(sent, "Failed to send Ether");
		}

		emit ConfirmedAttendee(eventId, attendee);
	}

	//Batch confirm attendees
	function confirmAllAttendees(bytes32 eventId) external {
		//looks up specific struct of event by eventId
		CreateEvent memory myEvent = idToEvent[eventId];
		//Check if msg.sender is eventOwner.  Only owner of event can confirm RSVPs
		require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED");
		//Loops through confirmedRSVPs list and calls confirmAttendee function for each attendee
		for (uint8 i = 0; i <myEvent.confirmedRSVPs.length; i++) {
			confirmAttendee(eventId, myEvent.confirmedRSVPs[i]);
		}
	}

	//Withdraws any unclaimed deposits from people who RSVPed but didn't show up, sends total to event Owner
	function withdrawUnclaimedDeposits(bytes32 eventId) external {
		//Looks up the specific struct of the event by eventId
		CreateEvent memory myEvent = idToEvent[eventId];
		//Checks if eventOwner already claimed their payout.  If yes, throws error
		require(!myEvent.paidOut, "ALREADY PAID");
		//Checks that 7 days have passed since event ended.  Event owner can't claim deposits until 7 days have passed
		require(
			block.timestamp >= (myEvent.eventTimestamp + 7 days), "TOO EARLY"
		);
		//Checks if msg.sender is the event owner for the event, only event owner can claim deposits 
		require(msg.sender == myEvent.eventOwner, "MUST BE EVENT OWNER");
		//Declares new variable, unclaimed.  Sets value to difference between confirmedRSVPs and claimed RSVPs
		uint256 unclaimed = myEvent.confirmedRSVPs.length - myEvent.claimedRSVPs.length;
		//Declares new variable, payout.  Sets value to number of unclaimed RSVPs * deposit for the even to get the total value
		uint256 payout = unclaimed * myEvent.deposit;
		//Sets paidOut to true to prevent eventOwner from claiming deposit multiple times
		myEvent.paidOut = true;
		//Sends total value of payout variable to the eventOwner
		(bool sent, ) = msg.sender.call{value: payout}("");

		if(!sent) {
			myEvent.paidOut = false;
		}
		
		require(sent, "Failed to sent Ether");

		emit DepositsPaidOut(eventId);
	}
}