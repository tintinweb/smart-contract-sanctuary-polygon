/**
 *Submitted for verification at polygonscan.com on 2023-05-30
*/

//SPDX-License-Identifier:MIT

pragma solidity >=0.7.0 <0.9.0;

/*

Functions Of the Voting Dapp

1. Accept Proposals, name and number for tracking.

2. Allow members to vote and exercise voting ability. (Keep track of voting, check if voters are authenticated to vote.)

3. There will be an authority that will serve as an authentication to vote.

*/

contract PowerArk {
    struct Voter {
        uint vote;       // The selected vote by the voter
        bool anyvotes;   // To indicate whether the voter has cast any votes
        uint value;      // To serve as an authenticator for a wallet to vote
    }

    struct Proposal {
        bytes32 name;    // Name of the proposal.
        uint voteCount;  // Number of votes the proposal has received.
    }

    Proposal[] public proposals;         // Array to store all the proposals.
    mapping(address => Voter) public voters;  // Mapping the connected wallet address to a voter.
    address public authenticator;        // Data type to make deployer's address the authenticator.

    constructor(bytes32[] memory proposalNames) {
        authenticator = msg.sender;  // Set the deployer's address as the authenticator.
        voters[authenticator].value = 1;  // Set the authenticator's value to 1 to indicate authentication.

        // Loop through the proposalNames array and add proposals to the proposals array
        for (uint i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }

    // Function to authenticate votes
    function giveRightToVote(address voter) public {
        require(msg.sender == authenticator, 'Only the authenticator gives access to vote');
        
        // Require the voter hasn't voted yet
        require(!voters[voter].anyvotes, 'The voter has voted already');
        require(voters[voter].value == 0);

        // Assigning voting right to the voter
        voters[voter].value = 1;
    }

    // Function for voting
    function vote(uint proposal) public {
        // Get the voter's information from the storage
        Voter storage sender = voters[msg.sender];

        require(sender.value != 0, 'Has no right to vote'); // Check if the voter has the right to vote
        require(!sender.anyvotes, 'Already voted'); // Check if voter has voted

        sender.anyvotes = true;
        sender.vote = proposal;

        proposals[proposal].voteCount += sender.value;
    }

    // Function to show the winning proposal by index
    function winningProposal() public view returns (uint winningProposal_) {
        uint winningVoteCount = 0;
        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > winningVoteCount) {
                winningVoteCount = proposals[i].voteCount;
                winningProposal_ = i;
            }
        }
    }

    // Function to show the name of the winning proposal
    function winningName() public view returns (bytes32 winningName_) {
        winningName_ = proposals[winningProposal()].name;
    }
}