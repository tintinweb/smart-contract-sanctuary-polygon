// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Ballot {
    // Struct Voter
    struct Voter{
        uint vote;      // Right to vote
        uint weight;
        bool voted;
    }

    // Struct Proposal
    struct Proposal{
        bytes32 name;        // Name of proposla
        uint voteCount;     // Number of accumulated votes
    }

    uint public proposalsLength;
    address public chairperson;
    
    Proposal[] public proposals;

    mapping(address => Voter) public voters;


    constructor(bytes32[] memory prosposalNames) {

        // Select the chair person
        chairperson = msg.sender;

        // Add 1 to chair person weight
        voters[chairperson].weight = 1;

        // Add the proposals names
        for(uint i=0; i < prosposalNames.length; i++){
            proposals.push(Proposal({
                name: prosposalNames[i],
                voteCount: 0
            }));
        }
        proposalsLength = prosposalNames.length;
    }

    // function authenticate voter
    function giveRightToVote(address voter) public {
        require(msg.sender == chairperson,
            'Only the chairperson can give access to vote');
        // require voter hasn't voted yet
        require(!voters[voter].voted,
            'The voter has already voted');
        require(voters[voter].weight == 0);
        
        voters[voter].weight = 1;
    }

    // function for voting
    function vote(uint proposal) public {        
        Voter storage sender = voters[msg.sender];

        require(sender.weight != 0, 'Has no right to vote');
        require(!sender.voted, 'The voter has already voted');

        sender.voted = true;
        sender.vote = proposal;

        proposals[proposal].voteCount = proposals[proposal].voteCount + sender.weight;
    }

    //function for showing results
    function winningProposal() public view returns (uint winningProposal_) {
        uint winningVoteCount = 0;

        for(uint i=0; i < proposals.length; i++){
            if(proposals[i].voteCount > winningVoteCount){
                winningVoteCount = proposals[i].voteCount;
                winningProposal_ = i;
            }
        }
        return winningProposal_;
    }

    //function for picking the winner
    function winningName() public  view returns (bytes32 winningName_){
        winningName_ =  proposals[winningProposal()].name;

        return winningName_;
    }

}