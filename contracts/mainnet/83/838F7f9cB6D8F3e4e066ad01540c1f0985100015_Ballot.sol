// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Ballot {
    struct Proposal {
        bytes32 name;
        uint256 voteCount;
    }

    address public admin;

    mapping(address => bool) public voters;

    Proposal[] public proposals;

    event Vote(uint256 proposal, address account);

    constructor(bytes32[] memory proposalNames) {
        admin = msg.sender;

        for (uint256 i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({name: proposalNames[i], voteCount: 0}));
        }
    }

    function vote(uint256 proposal, address account) external {
        require(!voters[account], "The voter already voted");

        voters[account] = true;
        proposals[proposal].voteCount += 1;

        emit Vote(proposal, account);
    }

    function winningProposal() public view returns (uint256 winningProposal_) {
        uint256 winningVoteCount = 0;
        for (uint256 p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    function winnerName() external view returns (bytes32 winnerName_) {
        winnerName_ = proposals[winningProposal()].name;
    }
}