// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Saverse {
    address[] members; // An array that holds a list of thrifting members' addresses
    uint256[] contributions; // An array to keep track of contributions made by each member
    uint256 currentRound; // Index of the member who can withdraw total contributions in a given round

// @author - Adeola David Adelakun
    
    address public contractOwner;

    constructor() {
        contractOwner = msg.sender;
    }
// function to allow contract owner add members
    function setMembers(address[] memory _members) public {
        require(msg.sender == contractOwner, "Only contract owner can update members list");
        require(_members.length > 0, "At least one member required");
        require(_members.length <= 10, "Maximum of 10 members allowed");
        members = _members;
    }
// Function to allow members to contribute funds
    function contribute() public payable {
        require(msg.value > 0, "Your contribution must be greater than zero");
        require(isMember(msg.sender), "You are not a registered member for this round");
        contributions[getIndex(msg.sender)] += msg.value;
    }
// Function to allow the current member to withdraw the total contributions for the current round
    function withdraw() public {
        require(isMember(msg.sender), "You are not a registered member for this round");
        require(getIndex(msg.sender) == currentRound, "It is not your turn to withdraw");
        uint256 total = getTotalContributions();
        require(total > 0, "No funds available for withdrawal");
        currentRound = (currentRound + 1) % members.length;
        payable(msg.sender).transfer(total);
    }
// Function to start a new round of contributions
    function startNewRound() public {
        require(getTotalContributions() == 0, "All contributions must be withdrawn before starting a new round");
        currentRound = 0;
    }
// Function to get the total contributions for the current round
    function getTotalContributions() public view returns (uint256) {
        uint256 total = 0;
        for (uint i = 0; i < members.length; i++) {
            total += contributions[i];
        }
        return total;
    }
// Function to check if an address is a registered member in a particular round
    function isMember(address _address) private view returns (bool) {
        for (uint i = 0; i < members.length; i++) {
            if (members[i] == _address) {
                return true;
            }
        }
        return false;
    }
// Function to get the index of a member in the registered members array
    function getIndex(address _address) private view returns (uint256) {
        for (uint i = 0; i < members.length; i++) {
            if (members[i] == _address) {
                return i;
            }
        }
        revert("You are not a registered member for this round");
    }
}
/**
* @author - Adeola David Adelakun
* @Email - [email protected]
*/