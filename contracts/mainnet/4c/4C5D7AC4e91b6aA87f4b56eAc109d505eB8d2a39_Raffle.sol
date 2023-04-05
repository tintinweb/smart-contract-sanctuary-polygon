/**
 *Submitted for verification at polygonscan.com on 2023-04-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Raffle {
    address public owner;

    struct RaffleData {
        string[] participants;
        string[] winners;
        bool isDrawn;
    }

    mapping(uint256 => RaffleData) public allRaffles;

    event ParticipantsAdded(uint256 raffleId, string[] participants);
    event WinnersSelected(uint256 raffleId, string[] winningStrings);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    function addParticipants(uint256 raffleId, string[] memory participants) public onlyOwner {
        require(!allRaffles[raffleId].isDrawn, "This raffle has already been drawn");
        require(participants.length <= 50, "Cannot add more than 50 participants at once");

        for (uint256 i = 0; i < participants.length; i++) {
            allRaffles[raffleId].participants.push(participants[i]);
        }

        emit ParticipantsAdded(raffleId, participants);
    }

    function drawRaffle(uint256 raffleId, uint256 count) public onlyOwner {
        require(allRaffles[raffleId].participants.length > 0, "No participants in this raffle");
        require(!allRaffles[raffleId].isDrawn, "This raffle has already been drawn");
        require(count <= 10, "Cannot select more than 10 winners at once");
        require(allRaffles[raffleId].participants.length >= count, "Not enough elements in the list");

        allRaffles[raffleId].isDrawn = true;

        string[] memory randomStrings = new string[](count);
        bool[] memory usedIndexes = new bool[](allRaffles[raffleId].participants.length);

        for (uint256 i = 0; i < count; i++) {
            uint256 randomIndex = uint256(keccak256(abi.encodePacked(block.timestamp, i))) % allRaffles[raffleId].participants.length;

            while (usedIndexes[randomIndex]) {
                randomIndex = (randomIndex + 1) % allRaffles[raffleId].participants.length;
            }

            usedIndexes[randomIndex] = true;
            randomStrings[i] = allRaffles[raffleId].participants[randomIndex];
            allRaffles[raffleId].winners.push(randomStrings[i]);
        }

        emit WinnersSelected(raffleId, randomStrings);
    }

    function getParticipants(uint256 raffleId) public view returns (string[] memory) {
        return allRaffles[raffleId].participants;
    }

    function getWinners(uint256 raffleId) public view returns (string[] memory) {
        require(allRaffles[raffleId].isDrawn, "The raffle has not been drawn yet");
        return allRaffles[raffleId].winners;
    }
}