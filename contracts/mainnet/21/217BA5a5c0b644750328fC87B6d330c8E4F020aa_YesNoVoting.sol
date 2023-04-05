// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract YesNoVoting {
    uint public yesVotes = 0;
    uint public noVotes = 0;
    bool public votingClosed = false;

    function voteYes() public {
        require(!votingClosed, "Voting is closed.");
        yesVotes++;
    }

    function voteNo() public {
        require(!votingClosed, "Voting is closed.");
        noVotes++;
    }

    function closeVoting() public {
        require(!votingClosed, "Voting is already closed.");
        votingClosed = true;
    }
}