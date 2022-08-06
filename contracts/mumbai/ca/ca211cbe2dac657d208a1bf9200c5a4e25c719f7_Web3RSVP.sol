/**
 *Submitted for verification at polygonscan.com on 2022-08-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Web3RSVP{

    // be picky about the data you store on-chain as it is expensive!

    // eDataCID to store event name, description etc
    // only store data that is required for on-chain functionality 
    struct Event{

        // unique event identifier
        bytes32 eID;
        // unique event content-identifier
        string eDataCID;
        // address of person creating the event
        address eCreator;
        // timestamp of when event starts
        uint256 eTimeStart;
        // maximum capacity for event registrants
        uint256 eCapacity;
        // amount to be deposited by each registrant
        uint256 eDepositAmount;
        // array to store addresses of everyone that registers
        address[] eRegistrants;
        // array to store addresses of registrants that check-in and attend the event
        address[] eAttendees;
        // to check if deposited amlont is paid or not
        bool isPaid;
    }


    // link an eID to an Event struct using mapping
    mapping(bytes32 => Event) public idToEventMapping;


    event NewEventCreated(bytes32 eID, string eDataCID, address eCreator, uint256 eTimeStart, uint256 eCapacity, uint256 eDepositAmount);

    event NewRegistrantAdded(bytes32 eID, address registrantAddress);

    event NewAttendeeCheckIn(bytes32 eID, address attendeeAddress);

    event UnclaimedDepositPaidOut(bytes32 eID, uint256 unclaimedDepositAmount);

    // Create function to add an event
    // data passed my front-end: event data CID, start time, capacity, deposit amount
    function createEvent(string calldata eDataCID, uint256 eTimeStart, uint256 eCapacity, uint256 eDepositAmount) external{
        // eID generated usisng keccak256 hashing with a bunch of things
        bytes32 eID = keccak256(abi.encodePacked(msg.sender, address(this), eTimeStart, eCapacity, eDepositAmount ));
        // set eCreator with address of whoever called this function   
        address eCreator = msg.sender;
        // Initialise array and bool for struct creation
        address[] memory eRegistrants;
        address[] memory eAttendees;
        bool isPaid = false;

        // uses mapping to map and create struct when this function is called
        idToEventMapping[eID] = Event(eID, eDataCID, eCreator, eTimeStart, eCapacity, eDepositAmount, eRegistrants, eAttendees, isPaid);

        emit NewEventCreated(eID, eDataCID, eCreator, eTimeStart, eCapacity, eDepositAmount);

    }

    // Create function to add registrants by using eID to identify which event they want to get added to
    // Make it payable as ETH is required to put as stake to register
    function addNewRegistrant(bytes32 eID) external payable{

        // use eID to check Event mapping and get that struct for this function
        Event storage thisEvent = idToEventMapping[eID];

        // Check if it has been less than 1 hour since event started
        require(block.timestamp <= thisEvent.eTimeStart + 30 minutes, 'Too late to register');

        // Check if event capacity is reached yet?
        require(thisEvent.eRegistrants.length < thisEvent.eCapacity, 'Max capacity reached');

        // Check if registrant has enough ETH?
        require(msg.value == thisEvent.eDepositAmount, 'Not enough ETH to proceed');

        // Check if registrant already registered previously? 
        for (uint8 i = 0; i < thisEvent.eRegistrants.length; i++){
            require( thisEvent.eRegistrants[i] != msg.sender, 'You are already registered!');
        }

        // After all checks, push the registrant's address to the required array
        thisEvent.eRegistrants.push(payable(msg.sender));

        emit NewRegistrantAdded(eID, msg.sender);

        // How does the contract know how much ETH to use?
        // If we have 1000s of registrants, wouldn't a for loop be slow?
        // Should there be a mechanism in place to check if eID passed exists? 
        
    }

    function checkInRegistrant (bytes32 eID, address registrant) public {

        Event storage thisEvent = idToEventMapping[eID];

        // Extension: Allow more people to check-in attendees
        // Only allow event creator to check-in attendees
        require(msg.sender == thisEvent.eCreator, 'Only event creator can check-in attendees!');


        // Check if registrant already checked-in
        for (uint8 i=0; i< thisEvent.eAttendees.length; i++){
            require (thisEvent.eAttendees[i] != registrant, 'You are already checked-in!');
        }


        // Check if registrant address is in eRegistrants [] 
        address attendeeAddress; 

        for (uint8 i =0; i < thisEvent.eRegistrants.length; i++){
            if (thisEvent.eRegistrants[i] == registrant){
                attendeeAddress = registrant;
            }
        }

        require(attendeeAddress == registrant, 'You did not register for this event!');


        // Check if deposit already claimed by event creator
        require(thisEvent.isPaid == false, 'Event owner already claimed the remaining deposit!');

        // After all checks, push the attendee/registrant address in eAttendees []
        thisEvent.eAttendees.push(attendeeAddress);

        // used for sending ETH to an address
        (bool sent,) = attendeeAddress.call{value: thisEvent.eDepositAmount}("");

        // if sent failed, take the attendee pushed just now out of the array
        if (!sent){
            thisEvent.eAttendees.pop();
        }

        // Send message about check-in and deposit refund fail
        require(sent, 'Failed to check-in attendee, try again.');

        emit NewAttendeeCheckIn(eID, attendeeAddress);

    }


    function checkInAllRegistrants(bytes32 eID) public {

        Event storage thisEvent = idToEventMapping[eID];

        // Check if address calling this function is event creator
        require(msg.sender == thisEvent.eCreator, 'Only event creator can check-in attendees!');

        // Use pcheck-in function in a loop to check-in all registrants
        for (uint8 i=0; i< thisEvent.eRegistrants.length; i++){
            checkInRegistrant(eID, thisEvent.eRegistrants[i]);
        }

    }


    function withdrawUnclaimedDeposit(bytes32 eID) public {

        Event storage thisEvent = idToEventMapping[eID];

        // Check if function is called by event creator
        require(msg.sender == thisEvent.eCreator, "Deposit can only be claimed my event creator");

        // Check if deposit already paid out?
        require(thisEvent.isPaid == false, "Unclaimed deposit already withdrawn");

        // Check if this function only being called after one week of event
        require(block.timestamp >= thisEvent.eTimeStart + 7 days, 'Cannot claim deposit until one week has passed.');

        // Check if unclaimed registrants left
        require(thisEvent.eRegistrants.length != thisEvent.eAttendees.length, 'No unclaimed deposit left');

        // Find number of registrants that did not attend
        uint256 unclaimedRegistrants = thisEvent.eRegistrants.length - thisEvent.eAttendees.length;
        // Multiply non-attendees to deposit amount to find unclaimed amount
        uint256 unclaimedAmount = unclaimedRegistrants * thisEvent.eDepositAmount;

        // Set isPaid to true
        thisEvent.isPaid = true;

        // Send ETH to creator
        (bool sent, ) = msg.sender.call{value: unclaimedAmount}("");

        // If issues in sending, revert back the transaction
        if(!sent){
            thisEvent.isPaid = false;
        }

        require(sent, 'Failed to process unclaimed deposit, try again');


        emit UnclaimedDepositPaidOut(eID, unclaimedAmount);



    }





}