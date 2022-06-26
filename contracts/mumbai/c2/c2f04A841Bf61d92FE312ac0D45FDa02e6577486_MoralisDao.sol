// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

// 0xc2f04A841Bf61d92FE312ac0D45FDa02e6577486

interface daoInterface {
    function balanceOf(address,uint256) external view returns (uint256);
}

contract MoralisDao{

    address public owner;
    uint256 nextProposal;           // next proposal id
    uint256[] public validTokens;   // list of valid tokens
    daoInterface daoContract;

    constructor(){
        owner = msg.sender;
        nextProposal = 1;
        validTokens = [67841412279532801837515543174226035610057961491298794127114430528654986444801]; // holds the token with this ID
        daoContract = daoInterface(0x2953399124F0cBB46d2CbACD8A89cF0599974963);                        // use the ERC721 deploying contract from OpenSea
    }

    struct proposal {
        uint256 proposalId;
        bool exists;
        string description; 
        address proposer; 
        uint256 votesUp;
        uint256 votesDown;
        uint deadline;
        address[] canVote;                       // list of addresses that can vote on this proposal
        uint256 maxVotes;                        // total people who can vote on this proposal
        mapping(address => bool) voteStatus;     // mapping of address to vote status
        bool countConducted;                    // if the proposal has been counted
        bool approved; 
    }

    mapping(uint256 => proposal) public Proposals;
    event proposalCreated(
        uint256 indexed proposalId,
        string description,
        address proposer,
        uint256 maxVotes
    );

    event newVote(
        uint256 votesUp,
        uint256 votesDown,
        address indexed voter,
        uint256 proposal,
        bool votedFor
    );

    event proposalCount(
        uint256 proposalId,
        bool approved
    );


    function checkProposalEligibility(address _creator) private view returns (bool){
        for (uint256 i = 0; i < validTokens.length; i++){
            if (daoContract.balanceOf(_creator,validTokens[i]) >= 1){
                return true;
            }
        }
        return false;
    }

    function checkVoteEligibility(uint _proposalId, address _voter) private view returns (bool){
        for (uint256 i =0; i < Proposals[_proposalId].canVote.length ; i++){
            if (Proposals[_proposalId].canVote[i] == _voter){
                return true;
            }
        }
        return false;
    }

    function createProposal(string memory _description, address[] memory _canVote ) public {
        require(checkProposalEligibility(msg.sender),"Only NFT holders can create proposals.");

        proposal storage newProposal = Proposals[nextProposal];
        newProposal.proposalId = nextProposal;
        newProposal.description = _description;
        newProposal.proposer = msg.sender;
        newProposal.exists = true;
        newProposal.votesUp = 0;
        newProposal.votesDown = 0;
        newProposal.deadline = block.timestamp + 3600;
        newProposal.canVote = _canVote;
        newProposal.maxVotes = _canVote.length;

        emit proposalCreated(nextProposal,_description,msg.sender,_canVote.length);
        nextProposal++;
    }

    function voteOnProposal(uint _proposalId, bool _vote) public {
        require(Proposals[_proposalId].exists,"Proposal does not exist.");
        require(checkVoteEligibility(_proposalId,msg.sender),"You are not eligible to vote on this proposal.");
        require(!Proposals[_proposalId].voteStatus[msg.sender],"You have already voted.");
        require(Proposals[_proposalId].deadline >= block.timestamp,"Deadline for voting has passed.");

        proposal storage currentProposal = Proposals[_proposalId];
        if (_vote){
            Proposals[_proposalId].votesUp++;
        } else {
            Proposals[_proposalId].votesDown++;
        }

        currentProposal.voteStatus[msg.sender] = true;

        emit newVote(currentProposal.votesUp,currentProposal.votesDown,msg.sender,_proposalId,_vote);
    }

    function countVotes(uint _proposalId) public {
        require(msg.sender == owner,"Only the owner can count votes.");
        require(Proposals[_proposalId].exists,"Proposal does not exist.");
        require(Proposals[_proposalId].deadline < block.timestamp,"Voting is going on currently.");
        require(!Proposals[_proposalId].countConducted,"Votes have already been counted.");

        proposal storage currentProposal = Proposals[_proposalId];
        if (currentProposal.votesUp > currentProposal.votesDown){
            currentProposal.approved = true;
        } else {
            currentProposal.approved = false;
        }
        currentProposal.countConducted = true;
        emit proposalCount(_proposalId,currentProposal.approved);
    }

    function addTokenId(uint256 _tokenId) public {
        require(msg.sender == owner,"Only the owner can add token IDs.");
        validTokens.push(_tokenId);
    }
}