/**
 *Submitted for verification at polygonscan.com on 2022-12-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
pragma abicoder v2;

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract Ballot {
   
    struct Voter {
        uint weight; // weight is accumulated by delegation
        bool voted;  // if true, that person already voted
        uint vote;   // index of the voted proposal
    }

    struct Candidate {
        string name;   // candidate name 
        uint voteCount; // number of accumulated votes
    }

    address public chairperson;

    mapping(address => Voter) public voters;

    Candidate[] public candidates;
    
    enum State { Created, Voting, Ended } // State of voting period
    
    State public state;

    constructor(string[] memory candidateNames) {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;
        state = State.Created;
        
        for (uint i = 0; i < candidateNames.length; i++) {
            candidates.push(Candidate({
                name: candidateNames[i],
                voteCount: 0
            }));
        }
    }
    
    // MODIFIERS
    modifier onlySmartContractOwner() {
        require(
            msg.sender == chairperson,
            "Only chairperson can start and end the voting"
        );
        _;
    }
    
    modifier CreatedState() {
        require(state == State.Created, "it must be in Started");
        _;
    }
    
    modifier VotingState() {
        require(state == State.Voting, "it must be in Voting Period");
        _;
    }
    
    modifier EndedState() {
        require(state == State.Ended, "it must be in Ended Period");
        _;
    }
    function getCandidatesLength() external view returns (uint256) {
        return candidates.length;
    }
    
    function addCandidates(string[] memory candidateNames) 
        public 
        EndedState
    {
        state = State.Created;
        for (uint i = 0; i < candidateNames.length; i++) {
            candidates.push(Candidate({
                name: candidateNames[i],
                voteCount: 0
            }));
        }
    }
    
    // to start the voting period
    function startVote() 
        public
        onlySmartContractOwner
        CreatedState
    {
        state = State.Voting;
    }
    
    /*    
     * to end the voting period
     * can only end if the state in Voting period
    */
    function endVote() 
        public 
        onlySmartContractOwner
        VotingState
    {
        state = State.Ended;
    }
    
    
    /** 
     * @dev Give 'voter' the right to vote on this ballot. May only be called by 'chairperson'.
     * @param voter address of voter
     */
    function giveRightToVote(address voter) public {
        require(
            msg.sender == chairperson,
            "Only chairperson can give right to vote."
        );
        require(
            !voters[voter].voted,
            "The voter already voted."
        );
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
    }

    /**
     * @dev Give your vote (including votes delegated to you) to candidate 'candidates[candidate].name'.
     * @param candidate index of candidate in the candidates array
     */
    function vote(uint candidate) 
        public
        VotingState
    {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = candidate;

        // If 'candidate' is out of the range of the array,
        // this will throw automatically and revert all
        // changes.
        candidates[candidate].voteCount += sender.weight;
    }

    function winningCandidate() 
        public
        EndedState
        view
        returns (string memory winnerName_)
    {
        uint winningVoteCount = 0;
        for (uint p = 0; p < candidates.length; p++) {
            if (candidates[p].voteCount > winningVoteCount) {
                winningVoteCount = candidates[p].voteCount;
                winnerName_ = candidates[p].name;
            }
        }
    }
}