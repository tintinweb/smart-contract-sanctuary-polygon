//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

contract Dao {
    // for everyone to see who the owner of this contract is
    address public owner;
    // keep track of next proposal by id, is unique initial will be 1
    uint256 nextProposal;
    //  tokens that will allow users to be voter of the dao also can make vote and proposals
    uint256[] public validTokens;

    IDaoContract daoContract;

    constructor() {
        // who ever deployed the smart contract will be the owner of the smart contract
        owner = msg.sender;
        // initialized as 1, whenever a new proposal is created, we'll increase the value of the next proposal
        nextProposal = 1;
        // we're using balance of function of another smart contract(i.e deployed) within our smart contract, this is the contract address from
        // our nft store front
        daoContract = IDaoContract(0x2953399124F0cBB46d2CbACD8A89cF0599974963);
        // this is to make sure that whenever a new proposal is made or a new vote is casted, we want to make sure that
        // the user contains this token in their wallet
        validTokens = [
            101962849989457910687999018588796642736140338095183378891960299308312822808577
        ];
    }

    struct proposal {
        uint256 id;
        bool exists; // if the proposal exists or not
        string description;
        uint256 deadline;
        uint256 votesUp;
        uint256 votesDown;
        address[] canVote; //valid tokens that can vote on this proposal
        uint256 maxVotes; // will be length of canVote
        mapping(address => bool) voteStatus; // address => bool, address is the address of the voter, bool is whether or not the voter has voted
        bool countConducted; // if the proposal has been counted or not , owner can count the proposal
        bool passed; // if the proposal has passed or not
    }

    mapping(uint256 => proposal) public Proposals;

    // event to keep track of the creation of a new proposal
    /**
     * @param id is the id of the proposal,
     * @param description is the description of the proposal,
     * @param maxVotes is the maximum number of votes that can be casted on this proposal,
     * @param proposer is the address of the proposer,
     */
    event proposalCreated(
        uint256 id,
        string description,
        uint256 maxVotes,
        address proposer
    );

    // event to keep track of the vote on a proposal
    /**
     * @param votesUp emits current number of votes up,
     * @param votesDown emits current number of votes down,,
     * @param voter is for the most recent vote, who made the most recent vote,
     * @param proposal on what proposal they made the vote on,
     * @param votedFor did the users vote for or against the proposal,
     */
    event newVote(
        uint256 votesUp,
        uint256 votesDown,
        address voter,
        uint256 proposal,
        bool votedFor
    );

    /**
     * @param id is the id of the proposal,
     * @param passed whether or not the proposal has passed or not,
     */

    event proposalCount(uint256 id, bool passed);

    // function to check if user owns the right nft's to vote on this proposal
    /**
     * @param proposer wallet that is trying to make the proposal,
     */
    function checkProposalEligibility(address proposer)
        private
        view
        returns (bool)
    {
        for (uint256 i = 0; i < validTokens.length; i++) {
            if (daoContract.balanceOf(proposer, validTokens[i]) > 0) {
                return true;
            }
        }
        return false;
    }

    // checking if the voter can vote on the specific proposal
    /**
     * @param _id is the id of the proposal
     * @param _voter is the address of the voter who is trying to vote on the proposal
     */
    function checkVoteEligibility(uint256 _id, address _voter)
        public
        view
        returns (bool)
    {
        // looping through the proposal and checking against the canVote array to see if
        //  the voter can vote on the proposal

        for (uint256 i = 0; i < Proposals[_id].canVote.length; i++) {
            if (Proposals[_id].canVote[i] == _voter) {
                return true;
            }
        }
        return false;
    }

    /** 
    This is where we create a new proposal,
    * @param _description is the description of the proposal,
    * @param _canVote is the array of addresses that can vote on the proposal,
    */
    function createProposal(
        string memory _description,
        address[] memory _canVote
    ) public {
        require(
            checkProposalEligibility(msg.sender),
            "Only NFT holders can put forth the proposal"
        );

        proposal storage newProposal = Proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.description = _description;
        newProposal.exists = true;
        newProposal.deadline = block.number + 100; //current place in block number + 100
        newProposal.canVote = _canVote;
        newProposal.maxVotes = _canVote.length;

        emit proposalCreated(
            nextProposal,
            _description,
            _canVote.length,
            msg.sender
        );
        nextProposal++;
    }

    /**
        Vote on a proposal,
    * @param _id is the id of the proposal,
    * @param _vote true means we're voting for the proposal, false means we're voting against the proposal,
    */
    function voteOnProposal(uint256 _id, bool _vote) public {
        require(
            checkVoteEligibility(_id, msg.sender),
            "You can't vote on this proposal"
        );
        require(Proposals[_id].exists, "Proposal does not exist");
        require(Proposals[_id].deadline > block.number, "Proposal has passed");
        require(
            !Proposals[_id].voteStatus[msg.sender],
            "You have already voted on this proposal"
        );

        proposal storage p = Proposals[_id];
        if (_vote) {
            p.votesUp++;
        } else {
            p.votesDown++;
        }
        p.voteStatus[msg.sender] = true;

        emit newVote(p.votesUp, p.votesDown, msg.sender, _id, _vote);
    }

    function countVotes(uint256 _id) public {
        //only the owner can count the votes
        require(msg.sender == owner, "Only the owner can count the votes");
        // check if vote was concluded or not
        require(
            block.number > Proposals[_id].deadline,
            "Voting has not concluded"
        );
        // check if the proposal exists
        require(Proposals[_id].exists, "This proposal doesn't exist");
        //check if the count has already been conducted in the proposal
        require(!Proposals[_id].countConducted, "Count already conducted");

        proposal storage p = Proposals[_id];

        if (Proposals[_id].votesDown < Proposals[_id].votesUp) {
            p.passed = true;
        }

        p.countConducted = true;

        emit proposalCount(_id, p.passed);
    }

    // add new tokens that will be eligible for this dao

    function addToken(uint256 _tokenId) public {
        require(msg.sender == owner, "Only the owner can add new tokens");
        validTokens.push(_tokenId);
    }
}

interface IDaoContract {
    // takes in the address of the wallet and tokenId as the parameter and
    //  returns the balance of the the token in that address
    function balanceOf(address, uint256) external view returns (uint256);
}