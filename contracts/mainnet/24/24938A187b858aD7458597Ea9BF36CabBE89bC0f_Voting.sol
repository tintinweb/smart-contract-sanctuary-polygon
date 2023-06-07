// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Voting {
    struct Voter {
        bool voted;
        bool vote;
    }

    mapping(address => Voter) public voters;
    string public question;
    uint public yesCount;
    uint public noCount;

    constructor(string memory _question) {
        question = _question;
    }

    function vote(bool _vote) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = _vote;

        if (_vote) {
            yesCount += 1;
        } else {
            noCount += 1;
        }
    }

    function result() public view returns (string memory) {
        require(yesCount + noCount > 0, "No votes yet.");
        if (yesCount > noCount) {
            return "Yes wins!";
        } else if (noCount > yesCount) {
            return "No wins!";
        } else {
            return "It's a tie!";
        }
    }
}