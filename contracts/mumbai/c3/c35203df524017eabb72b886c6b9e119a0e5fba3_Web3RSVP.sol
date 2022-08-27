// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

error NOT_ENOUGH_ETH_SEND();
error EVENT_ALREADY_HAPPENED();
error EVENT_REACHED_MAX_CAPACITY();
error ALREADY_CONFIRMED_MEMBER();
error NOT_AUTHORIZED_OWNER();
error NO_RSVP_TO_CONFIRM();
error ALREADY_CLAIMED();
error ALREADY_PAID_OUT();
error FAILED_TO_SEND_ETHER();
error ALREADY_PAID();
error TOO_EARLY_TIME_PERIOD_NOT_ENDED();

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
        // generate an eventID based on other things passed in to generate a hash
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

        //this creates a new CreateEvent struct and adds it to the idToEvent mapping
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

    function createNewRSVP(bytes32 eventId) external payable {
        // look up event
        CreateEvent storage myEvent = idToEvent[eventId];

        // transfer deposit to our contract / require that they sent in enough ETH
        // require(msg.value == myEvent.deposit, "NOT ENOUGH");
        if (msg.value != myEvent.deposit) {
            revert NOT_ENOUGH_ETH_SEND();
        }

        // require that the event hasn't already happened (<eventTimestamp)
        // require(block.timestamp <= myEvent.eventTimestamp, "ALREADY HAPPENED");
        if(block.timestamp >= myEvent.eventTimestamp){
            revert EVENT_ALREADY_HAPPENED();
        }

        // make sure event is under max capacity
        // require(
        //     myEvent.confirmedRSVPs.length < myEvent.maxCapacity,
        //     "This event has reached capacity"
        // );

        if(myEvent.confirmedRSVPs.length > myEvent.maxCapacity){
            revert EVENT_REACHED_MAX_CAPACITY();
        }

        // require that msg.sender isn't already in myEvent.confirmedRSVPs
        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            // require(
            //     myEvent.confirmedRSVPs[i] != msg.sender,
            //     "ALREADY CONFIRMED"
            // );
            if(myEvent.confirmedRSVPs[i] == msg.sender){
                revert ALREADY_CONFIRMED_MEMBER();
            }
        }

        myEvent.confirmedRSVPs.push(payable(msg.sender));

        emit NewRSVP(eventId, msg.sender);
    }

    function confirmAllAttendees(bytes32 eventId) external {
        // look up event
        CreateEvent memory myEvent = idToEvent[eventId];

        // make sure you require that msg.sender is the owner of the event
        // require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED");
        if(msg.sender != myEvent.eventOwner) {
            revert NOT_AUTHORIZED_OWNER();
        }

        // confirm each attendee
        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            confirmAttendee(eventId, myEvent.confirmedRSVPs[i]);
        }
    }

    function confirmAttendee(bytes32 eventId, address attendee) public {
        // look up event
        CreateEvent storage myEvent = idToEvent[eventId];

        // make sure you require that msg.sender is the owner of the event
        // require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED");
        if(msg.sender != myEvent.eventOwner){
            revert NOT_AUTHORIZED_OWNER();
        }

        // require that attendee is in myEvent.confirmedRSVPs
        address rsvpConfirm;

        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            if (myEvent.confirmedRSVPs[i] == attendee) {
                rsvpConfirm = myEvent.confirmedRSVPs[i];
            }
        }

        // require(rsvpConfirm == attendee, "NO RSVP TO CONFIRM");
        if(rsvpConfirm != attendee){
            revert NO_RSVP_TO_CONFIRM();
        }

        // require that attendee is NOT in the claimedRSVPs list
        for (uint8 i = 0; i < myEvent.claimedRSVPs.length; i++) {
            // require(myEvent.claimedRSVPs[i] != attendee, "ALREADY CLAIMED");
            if(myEvent.claimedRSVPs[i] == attendee){
                revert ALREADY_CLAIMED();
            }
        }

        // require that deposits are not already claimed
        // require(myEvent.paidOut == false, "ALREADY PAID OUT");
        if(myEvent.paidOut){
            revert ALREADY_PAID_OUT();
        }

        // add them to the claimedRSVPs list
        myEvent.claimedRSVPs.push(attendee);

        // sending eth back to the staker https://solidity-by-example.org/sending-ether
        (bool sent, ) = attendee.call{value: myEvent.deposit}("");

        // if this fails
        if (!sent) {
            myEvent.claimedRSVPs.pop();
            revert FAILED_TO_SEND_ETHER();
        }

        // require(sent, "Failed to send Ether");

        emit ConfirmedAttendee(eventId, attendee);
    }

    function withdrawUnclaimedDeposits(bytes32 eventId) external {
        // look up event
        CreateEvent memory myEvent = idToEvent[eventId];

        // check if already paid
        // require(!myEvent.paidOut, "ALREADY PAID");
        if(myEvent.paidOut){
            revert ALREADY_PAID();
        }

        // check if it's been 7 days past myEvent.eventTimestamp
        // require(
        //     block.timestamp >= (myEvent.eventTimestamp + 7 days),
        //     "TOO EARLY"
        // );
        if(block.timestamp <= (myEvent.eventTimestamp + 7 days)){
            revert TOO_EARLY_TIME_PERIOD_NOT_ENDED();
        }

        // only the event owner can withdraw
        // require(msg.sender == myEvent.eventOwner, "MUST BE EVENT OWNER");
        if(msg.sender != myEvent.eventOwner){
            revert NOT_AUTHORIZED_OWNER();
        }

        // calculate how many people didn't claim by comparing
        uint256 unclaimed = myEvent.confirmedRSVPs.length -
            myEvent.claimedRSVPs.length;

        uint256 payout = unclaimed * myEvent.deposit;

        // mark as paid before sending to avoid reentrancy attack
        myEvent.paidOut = true;

        // send the payout to the owner
        (bool sent, ) = msg.sender.call{value: payout}("");

        // if this fails
        if (!sent) {
            myEvent.paidOut = false;
            revert FAILED_TO_SEND_ETHER();
        }

        // require(sent, "Failed to send Ether");

        emit DepositsPaidOut(eventId);
    }
}