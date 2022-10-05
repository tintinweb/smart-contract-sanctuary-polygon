/**
 *Submitted for verification at polygonscan.com on 2022-10-04
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract Web3RSVP {
    event NewCreatedEvent(
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

    /**
     * @dev allows organizer to create events
     */
    function createNewEvent(
        uint256 eventTimestamp,
        uint256 deposit,
        uint256 maxCapacity,
        string calldata eventDataCID // IPFS hash of event description
    ) external {
        bytes32 eventId = keccak256(
            abi.encodePacked(
                msg.sender,
                address(this),
                eventTimestamp,
                deposit,
                maxCapacity
            )
        );

        // To avoid collisions by having two events with the same Id
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

        emit NewCreatedEvent(
            eventId, 
            msg.sender, 
            eventTimestamp, 
            maxCapacity, 
            deposit, 
            eventDataCID
        );
    }

    /**
     * @dev allows attendees to RSVP to an event
     */
     function createNewRSVP(bytes32 eventId) external payable {
         CreateEvent storage myEvent = idToEvent[eventId];

         require(msg.value == myEvent.deposit, "NOT ENOUGH");

         require(block.timestamp <= myEvent.eventTimestamp, "ALREADY HAPPENED");
         
         // event must be under the max capacity
         require(
             myEvent.confirmedRSVPs.length < myEvent.maxCapacity,
             "This event has reached capacity"
         );

         for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++){
             // confirm user hasn't already RSVP'd
             require(myEvent.confirmedRSVPs[i] != msg.sender, "ALREADY CONFIRMED");
         }

         myEvent.confirmedRSVPs.push(payable(msg.sender));

         emit NewRSVP(eventId, msg.sender);
     }

     /**
      * @dev allows organizer to confirm attendance and return their deposits
      */
      function confirmAttendee(bytes32 eventId, address attendee) public {
          CreateEvent storage myEvent = idToEvent[eventId];

          require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED");
          
          // require that attendee trying to check in actually RSVP'd
          address rsvpConfirm;

          for(uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
              if(myEvent.confirmedRSVPs[i] == attendee) {
                  rsvpConfirm = myEvent.confirmedRSVPs[i];
              }
          }

          require(rsvpConfirm == attendee, "NO RSVP TO CONFIRM");

          // require that attendee is NOT already in the claimedRSVPs
          for(uint8 i = 0; i < myEvent.claimedRSVPs.length; i++) {
              require(myEvent.claimedRSVPs[i] != attendee, "ALREADY CLAIMED");
          }

          require(myEvent.paidOut == false, "ALREADY PAID OUT");

          myEvent.claimedRSVPs.push(attendee);

          (bool sent,) = attendee.call{value: myEvent.deposit}("");

          if(!sent) {
              myEvent.claimedRSVPs.pop();
          }

          require(sent, "Failed to send ether");

          emit ConfirmedAttendee(eventId, attendee);
      }

      /**
       * @dev allows event organizer to confirm every person that has RSVPs
       */
       function confirmAllAttendees(bytes32 eventId) external {
           CreateEvent memory myEvent = idToEvent[eventId];

           require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED");

           for(uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
               confirmAttendee(eventId, myEvent.confirmedRSVPs[i]);
           }
       }

       /**
        * @dev allows event organizer to withdraw the deposits of people who didn't show up
        */
        function withdrawUnclaimedDeposits(bytes32 eventId) external {
            CreateEvent memory myEvent = idToEvent[eventId];

            require(!myEvent.paidOut, "ALREADY PAID");

            // check if it's been 7 days past myEvent.eventTimestamp
            require(
                block.timestamp >= (myEvent.eventTimestamp + 7 days),
                "TOO EARLY"
            );

            require(msg.sender == myEvent.eventOwner, "MUST BE EVENT OWNER");

            uint256 unclaimed = myEvent.confirmedRSVPs.length - myEvent.claimedRSVPs.length;

            uint256 payout = unclaimed * myEvent.deposit;

            myEvent.paidOut = true;

            (bool sent,) = msg.sender.call{value: payout}("");

            if(!sent) {
                myEvent.paidOut = false;
            }

            require(sent, "Failed to send Ether");

            emit DepositsPaidOut(eventId);
        }
}