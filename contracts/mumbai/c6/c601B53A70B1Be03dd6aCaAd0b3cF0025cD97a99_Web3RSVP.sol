/**
 *Submitted for verification at polygonscan.com on 2022-12-11
*/

//SPDX-License-Identifier:Unlicensed
pragma solidity ^0.8.9;

/// @title Onchain Event Ticketing System
/// @author Ogubuike Alexandra
/// @notice Manages processes for event ticket management
contract Web3RSVP {
    struct CreateEvent {
        bytes32 eventId;
        string eventDataCID;
        address eventOwner;
        uint256 eventTimeStamp;
        uint256 deposit;
        uint256 maxCapacity;
        address[] confirmedRSVPs;
        address[] claimedRSVPs;
        bool paidOut;
    }

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

    //Mapping from Id to Event
    mapping(bytes32 => CreateEvent) public idToEvent;

    /// @notice Create a new event
    /// @param eventTimeStamp the time of the event
    /// @param deposit the amount to be deposited during RSVP of the event
    /// @param maxCapacity the maximum event attendees required
    /// @param eventDataCID The IPFS generated CID that holds data about the event
    function createNewEvent(
        uint256 eventTimeStamp,
        uint256 deposit,
        uint256 maxCapacity,
        string calldata eventDataCID
    ) external {
        //Generate an eventId by hashing some of the input parameters
        //This is used instead of a uint to decrease the possibility of collisions
        bytes32 eventId = keccak256(
            abi.encodePacked(
                msg.sender,
                address(this),
                eventTimeStamp,
                deposit,
                maxCapacity
            )
        );

        //Confirm that this Id has never been used
        require(idToEvent[eventId].eventTimeStamp == 0, "Already registered");

        //Aray to track RSVPs
        address[] memory confirmedRSVPs;
        //Array to track those who actually come to event
        address[] memory claimedRSVPs;

        //Create a new CreateEvent struct
        idToEvent[eventId] = CreateEvent(
            eventId,
            eventDataCID,
            msg.sender,
            eventTimeStamp,
            deposit,
            maxCapacity,
            confirmedRSVPs,
            claimedRSVPs,
            false
        );

        emit NewEventCreated(
            eventId,
            msg.sender,
            eventTimeStamp,
            maxCapacity,
            deposit,
            eventDataCID
        );
    }

    /// @notice Create an RSVP fro an event
    /// @dev The sender has to send a deposit which they will get back when they check into the event i.e confirm their attendance
    /// @param eventId Event ID
    function createNewRSVP(bytes32 eventId) external payable {
        //Get the event from  the mapping
        CreateEvent storage myEvent = idToEvent[eventId];

        //Require that deposit sent is same as that stored in event
        require(msg.value == myEvent.deposit, "Not Enough");

        //Require that event has not already happened
        require(block.timestamp <= myEvent.eventTimeStamp, "Already Happened");

        //Require that user is not already in the RSVP list
        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            require(
                myEvent.confirmedRSVPs[i] != msg.sender,
                "Already Confirmed"
            );
        }

        myEvent.confirmedRSVPs.push(msg.sender);

        emit NewRSVP(eventId, msg.sender);
    }

    /// @notice Check in an attendee into the event
    /// @param eventId EventId
    /// @param attendee The attendee who wants to check into the event
    function confirmAttendee(bytes32 eventId, address attendee) public {
        //get event
        CreateEvent storage myEvent = idToEvent[eventId];

        //require that sender is not the owner of the event
        require(msg.sender == myEvent.eventOwner, "Not Authorized");

        //require that attendee trying to check in actually RSVP'd
        address rsvpConfirm;

        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            if (myEvent.confirmedRSVPs[i] == attendee) {
                rsvpConfirm = myEvent.confirmedRSVPs[i];
            }
        }

        require(rsvpConfirm == attendee, "NO RSVP TO CONFIRM");

        //Make sure the attendee has not alreday confirmed attendance i.e has not checked into the event
        for (uint8 i = 0; i < myEvent.claimedRSVPs.length; i++) {
            require(myEvent.claimedRSVPs[i] != attendee, "ALREADY CLAIMED");
        }

        // require that deposits are not already claimed by the event owner
        require(myEvent.paidOut == false, "ALREADY PAID OUT");

        // add the attendee to the claimedRSVPs list
        myEvent.claimedRSVPs.push(attendee);

        // sending eth back to the staker
        (bool sent, ) = attendee.call{value: myEvent.deposit}("");

        // if this fails, remove the user from the array of claimed RSVPs
        if (!sent) {
            myEvent.claimedRSVPs.pop();
        }

        require(sent, "Failed to send Ether");

        emit ConfirmedAttendee(eventId, attendee);
    }

    /// @notice Check in all attendees into the event
    /// @param eventId EventId    
    function confirmAllAttendees(bytes32 eventId) external {
        // look up event from our struct with the eventId
        CreateEvent memory myEvent = idToEvent[eventId];

        // make sure you require that msg.sender is the owner of the event
        require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED");

        // confirm each attendee in the rsvp array
        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            confirmAttendee(eventId, myEvent.confirmedRSVPs[i]);
        }
    }

    /// @notice Event Creator Collects unclaimed deposits    
    function withdrawUnclaimedDeposits(bytes32 eventId) external {
        //Get Event
        CreateEvent memory myEvent = idToEvent[eventId];

        //Check that the event balance has not been paid out
        require(!myEvent.paidOut, "ALREADY PAID");

        //Check that is been seven days after the event
        require(
            block.timestamp >= myEvent.eventTimeStamp + 7 days,
            "Too Early"
        );

        //only the event owner can withdraw
        require(msg.sender == myEvent.eventOwner, "Unauthorized!");

        //calculate how many people did not confirm RSVP
        uint256 unclaimed = myEvent.confirmedRSVPs.length - myEvent
            .claimedRSVPs
            .length;
        uint256 payout = unclaimed * myEvent.deposit;

        //Change state to paidOut
        myEvent.paidOut = true;

        //pay event owner
        (bool sent, ) = msg.sender.call{value: payout}("");

        if (!sent) {
            myEvent.paidOut = false;
        }

        require(sent, "Failed to semd Ether");
        emit DepositsPaidOut(eventId);
    }
}