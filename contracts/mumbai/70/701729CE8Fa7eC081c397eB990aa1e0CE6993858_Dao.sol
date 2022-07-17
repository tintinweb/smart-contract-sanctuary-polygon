// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


interface IdaoContract {
    function balanceOf(address, uint256) external view returns (uint256);
}

contract Dao {

    address public owner;
    uint256 nextProposal;
    uint256[] public validTokens;
    IdaoContract daoContract;

    constructor(){
        owner = msg.sender;
        nextProposal = 1;
        daoContract = IdaoContract(0x2953399124F0cBB46d2CbACD8A89cF0599974963);
        validTokens = [55545274373765616018452051810791388759545058092209646232400696391735529439233];
    }

    struct proposal{
        uint256 id;
        bool exists;
        string description;
        uint deadline;
        uint256 votesUp;
        uint256 votesDown;
        address[] canVote;
        uint256 maxVotes;
        mapping(address => bool) voteStatus;
        bool countConducted;
        bool passed;
    }

    mapping(uint256 => proposal) public Proposals;

    event proposalCreated(
        uint256 id,
        string description,
        uint256 maxVotes,
        address proposer
    );

    event newVote(
        uint256 votesUp,
        uint256 votesDown,
        address voter,
        uint256 proposal,
        bool votedFor
    );

    event proposalCount(
        uint256 id,
        bool passed
    );

//  the 1st two functions will be private because they will only be applicable for THIS smart contract ( private functions )
    function checkProposalEligibility(address _proposallist) private view returns (
        bool
    ){
        for(uint i = 0; i < validTokens.length; i++){
            //checks to see if the wallet trying to make a proposal has the approved "valid tokens"
            if(daoContract.balanceOf(_proposallist, validTokens[i]) >= 1){
                return true;
            }
        }
        return false;
    }

    function checkVoteEligibility(uint256 _id, address _voter) private view returns (
        bool
    ){
        for (uint256 i = 0; i < Proposals[_id].canVote.length; i++) {
            if (Proposals[_id].canVote[i] == _voter) {
                return true;
            }
        }
        return false;
    }


    //these next functions will be PUBLIC

    //this function allows for proposals to be saved in the Proposals[] which can be a public function called by anyone
    function createProposal(string memory _description, address[] memory _canVote) public {
        require(checkProposalEligibility(msg.sender), "Only NFT holders can put forth Proposals");

        proposal storage newProposal = Proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.exists = true;
        newProposal.description = _description;
        //each proposal will last 100 blocks
        newProposal.deadline = block.number + 100;
        newProposal.canVote = _canVote;
        newProposal.maxVotes = _canVote.length;


        emit proposalCreated(nextProposal, _description, _canVote.length, msg.sender);
        nextProposal++;


    }
    // everything above is important because it lets us create a proposal, that only people with an NFT can vote on
    // the key to the DAO is restricting who can vote on the Proposal

    // next we will focus on the voting function, not on the limiting who can interact with the contract.
    function voteOnProposal(uint256 _id, bool _vote) public {
        require(Proposals[_id].exists, "This Proposal does not exist");
        require(checkVoteEligibility(_id, msg.sender), "You cannot vote on this Proposal");
        require(!Proposals[_id].voteStatus[msg.sender], "You have already voted on this Proposal");
        require(block.number <= Proposals[_id].deadline, "The deadline has passed for this Proposal");


        proposal storage p = Proposals[_id];

        if(_vote) {
            p.votesUp++;
        }else{
            p.votesDown++;
        }

        p.voteStatus[msg.sender] = true;
        
        emit newVote(p.votesUp, p.votesDown, msg.sender, _id, _vote);


    }

    function countVotes(uint256 _id) public {
        require(msg.sender == owner, "Only Owner can count Votes");
        require(Proposals[_id].exists, "This Proposal does not currently exists");
        require(block.number > Proposals[_id].deadline, "Voting has not concluded");
        require(!Proposals[_id].countConducted, "Count already conducted");

        proposal storage p = Proposals[_id];

        if(Proposals[_id].votesDown < Proposals[_id].votesUp){
            p.passed = true;
        }

        p.countConducted = true;

        emit proposalCount(_id, p.passed);
    }


    function addTokenId(uint256 _tokenId) public {
        require(msg.sender == owner, "Only Owner can add Tokens");

        validTokens.push(_tokenId);
    }




}