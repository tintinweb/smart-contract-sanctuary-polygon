/**
 *Submitted for verification at polygonscan.com on 2023-06-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract VotingSystem {
    struct Vote {
        string partyName;
        address voter;
    }

    uint256 public totalVotes;
    mapping(address => bool) public hasVoted;
    mapping(address => string) public partyVotes;

    constructor() {
        totalVotes = 0;
    }

    function mintVote(string memory _partyName) public {
        require(!hasVoted[msg.sender], "You have already minted your vote.");

        hasVoted[msg.sender] = true;
        totalVotes++;

        partyVotes[msg.sender] = _partyName;
    }

    function getPartyVoteCount(address _voterAddress) public view returns (string memory) {
        require(hasVoted[_voterAddress], "Voter has not minted their vote.");

        return partyVotes[_voterAddress];
    }
}