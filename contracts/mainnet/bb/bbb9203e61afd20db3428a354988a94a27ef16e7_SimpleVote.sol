/**
 *Submitted for verification at polygonscan.com on 2023-05-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleVote {
    struct Project {
        string name;
        address payable addr;
        uint256 targetFunding;
    }

    Project public project;
    address public owner;
    uint256 public yesVotes;
    uint256 public noVotes;
    mapping(address => bool) hasVoted;
    bool public votingClosed;

    // initialize the instance of the Project
    constructor(string memory _name, address payable _addr, uint256 _targetFunding) {
        project = Project(_name, _addr, _targetFunding);
    }

    function deposit() public payable {} 

    function vote(bool isYes) public {
        require(!votingClosed);
        require(!hasVoted[msg.sender], "you cannot vote more than once");

        if (isYes) {
            yesVotes++;
        } else {
            noVotes++;
        }

        hasVoted[msg.sender] = true;
    }

    function closeVoting() public {
        require(msg.sender == owner, "nope");
        votingClosed = true;
    }

    function releaseFunds() public {
        require(msg.sender == owner, "");
        require(votingClosed);
        require(yesVotes > noVotes);
        require(address(this).balance > project.targetFunding);

         (bool success, ) = project.addr.call{value: address(this).balance}("");
         require(success, "");
    }
}