/**
 *Submitted for verification at polygonscan.com on 2022-10-02
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

contract HolaMundo {
    // Events for communicating with our Subgraph
    event NewGreetingCreated(
        bytes32 greetingId, // Greeting identifier
        string greetingDataCID, // CID to data about the greeting on IPFS
        address greetingOwner, // Address of the person who created the greeting
        uint256 timestamp // Timestamp of when the greeting was created
    );

    event RecievedGreeting(bytes32 greetingId, address from);

    // Creation of a new greeting struct
    struct CreateGreeting {
        bytes32 greetingId; // Greeting identifier
        string greetingDataCID; // CID to data about the greeting on IPFS
        address greetingOwner; // Address of the person who created the greeting
        uint256 timestamp; // Timestamp of when the greeting was created
        uint256 recieved; // Keep track of greetings recieved by other users
    }

    // GreetingStorage: Relationship between event identifier (eventId) to the CreateGreeting struct 
    mapping(bytes32 => CreateGreeting) public idToGreeting;

    // Create a Greeting
    function createNewGreeting(      
        string calldata greetingDataCID
    ) external {
        // Get timestamp
        uint256 timestamp = block.timestamp;

        // Creating a unique identifier for greeting
        bytes32 greetingId = keccak256(
            abi.encodePacked(
                msg.sender,
                address(this), // address of the contract instance
                timestamp,
                greetingDataCID
            )
        );

        // Adding to our greeting storage 
        idToGreeting[greetingId] = CreateGreeting(
            greetingId,
            greetingDataCID,
            msg.sender,
            timestamp,
            0 // recieved greetings
        );

        // emit event
        emit NewGreetingCreated(
            greetingId,
            greetingDataCID,
            msg.sender,
            timestamp 
        );
    }

    // Send Greeting To a User
    function sendGreeting(bytes32 greetingId) external {
        CreateGreeting storage GreetingCard = idToGreeting[greetingId];

        require(msg.sender != GreetingCard.greetingOwner, "You cannot greet yourself.");

        GreetingCard.recieved += 1;

        emit RecievedGreeting(greetingId, msg.sender);
    }

}