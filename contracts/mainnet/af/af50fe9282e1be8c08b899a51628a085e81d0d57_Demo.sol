/**
 *Submitted for verification at polygonscan.com on 2022-09-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Demo {
    struct User {
        bool voted;
        bool yes;
    }

    uint public yesVotes;
    uint public noVotes;

    uint private quorum;

    mapping(address => User) users;

    constructor(uint neededQuorum) {
        quorum = neededQuorum;
    }

    function vote(bool yes) external {
        require(! users[msg.sender].voted);

        users[msg.sender].voted = true;
        users[msg.sender].yes = yes;

        updateVotes(yes);
    }

    function updateVotes(bool yes) internal {
        if (yes) yesVotes++;
        else noVotes++;
    }

    function getResults() public view returns(bool quorumReached, bool yes) {
        yes = (yesVotes >= noVotes);

        uint totalVotes = yesVotes + noVotes;

        quorumReached = (totalVotes >= quorum);
    }

    event WhaleVote(address whale, bool yes);
    function paidVote(bool yes) payable external {
        require(msg.value == 1 ether);
        updateVotes(yes);

        emit WhaleVote(msg.sender, yes);
    }    
}