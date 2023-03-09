/**
 *Submitted for verification at polygonscan.com on 2023-03-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract GiveawayExtractor {
    uint256 public nonce = 0;

    function extractWinnersNoRepetition(
        string[] memory partecipants,
        uint256 winnersNumber
    ) public returns (string[] memory) {

        require(partecipants.length >= winnersNumber, "Not enough partecipants to extract");

        string[] memory winners = new string[](winnersNumber);
        string[] memory currentPartecipants = partecipants;

        for (uint256 i = 0; i < winnersNumber; i++) {
            uint256 index = getRandom(currentPartecipants.length - i);
            string memory partecipantName = partecipants[index];
            string memory winner = currentPartecipants[
                randomInRange(partecipantName, currentPartecipants.length)
            ];
            winners[i] = winner;

            currentPartecipants[index] = currentPartecipants[currentPartecipants.length-i-1];
            delete currentPartecipants[currentPartecipants.length-i-1];
        }

        return winners;
    }

    function randomInRange(
        string memory partecipantUsername,
        uint256 partecipants
    ) public returns (uint256) {
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    nonce,
                    msg.sender,
                    block.timestamp,
                    partecipantUsername
                )
            )
        ) % partecipants;
        nonce = nonce + 1;
        return randomNumber;
    }

    function getRandom(uint256 max) public returns (uint256) {
        uint256 randomNumber = uint256(
            keccak256(abi.encodePacked(nonce, msg.sender, block.timestamp))
        ) % max;
        nonce = nonce + 1;
        return randomNumber;
    }
}