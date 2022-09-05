/**
 *Submitted for verification at polygonscan.com on 2022-09-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

contract Token {

    event NewEventCreated(
        bytes32 eventId,
        address creatorAddress,
        uint256 eventTimeStamp,
        uint deposit
    );

    event NewRSVP(bytes32 eventId, address attendeeAddress);

    event withdrawDeposits(bytes32 eventID);

    struct CreateEvent {
        bytes32 eventId;
        address eventOwner;
        uint256 eventTimeStamp;
        uint256 deposit;
        address[] confirmedRSVPs;
    }

    mapping(bytes32 => CreateEvent) public idToEvent;

    function createNewEvent(
        uint256 eventTimeStamp,
        uint256 deposit
    ) external {
        // generate an eventID based on other things passed in to generate a hash
        require(msg.sender == 0x6ce039D5BBF0c91925DD9CDceecF8605B6F4bC42, "MUST BE EVENT OWNER");
        bytes32 eventId = keccak256(
            abi.encodePacked(
                msg.sender,
                address(this),
                eventTimeStamp,
                deposit
            )
        );
        // make sure this id isn't already claimed
        require(idToEvent[eventId].eventTimeStamp == 0, "Ya estas registrado!");

        address[] memory confirmedRSVPs;

        //this creates a new CreateEvent struct and adds it to the idToEvent mapping
        idToEvent[eventId] = CreateEvent(
            eventId,
            msg.sender,
            eventTimeStamp,
            deposit,
            confirmedRSVPs
        );

        emit NewEventCreated(
            eventId,
            msg.sender,
            eventTimeStamp,
            deposit
        );
    }


    function createNewRSVP(bytes32 eventId) external payable {
        CreateEvent storage myEvent = idToEvent[eventId];

        require(msg.value == myEvent.deposit, "NOT ENOUGH");

        require(block.timestamp <= myEvent.eventTimeStamp, "ALREADY HAPPENED");

        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            require(myEvent.confirmedRSVPs[i] != msg.sender, "ALREADY CONFIRMED");
        }

        myEvent.confirmedRSVPs.push(payable(msg.sender));

        emit NewRSVP(eventId, msg.sender);
}

    function withdrawBote(bytes32 eventId) external {
        CreateEvent memory myEvent = idToEvent[eventId];

        require(msg.sender == myEvent.eventOwner, "MUST BE EVENT OWNER");

        uint256 payout = myEvent.deposit * myEvent.confirmedRSVPs.length;

        (bool sent, ) = msg.sender.call{value: payout}("");

        emit withdrawDeposits(eventId);
    }
}