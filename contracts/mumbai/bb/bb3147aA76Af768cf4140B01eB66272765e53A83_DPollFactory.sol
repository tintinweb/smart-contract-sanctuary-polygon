// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "./DPoll.sol";

contract DPollFactory {
    event pollCreated(address indexed dpoll_address, address indexed creator);

    //addresses array of the polls
    address[] pollsList;

    // Function to create a new instance of the poll contract
    function createPoll(
        string memory title,
        string memory description,
        string[] memory options,
        address[] memory eligbleVoters,
        uint256 duration
    ) public {
        address newPoll = address(
            new DPoll(
                title,
                description,
                options,
                eligbleVoters,
                block.timestamp,
                duration,
                address(msg.sender)
            )
        );
        pollsList.push(newPoll);
        emit pollCreated(newPoll, msg.sender);
    }

    // Retrieve the number of Polls
    function getNumOfPolls() public view returns (uint256) {
        return pollsList.length;
    }

    //Returns all the Polls' addresses
    function getAllPolls() public view returns (address[] memory) {
        return pollsList;
    }
}