// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity  ^0.8.9;


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
        validTokens = [70443521971595338911662868339344984774442334809195668828319811414023171211274]; 
    }

    struct proposal {
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

    mapping(uint256 => proposal) public proposals;

    event ProposalCreated(
        uint256 id,
        string description,
        uint256 maxVotes,
        address proposer);
    
    event NewVote(uint256 votesUp, uint256 votesDown, address voter, uint256 proposal, bool votedFor);

    event ProposalCount(uint256 id, bool passed);


    function checkProposalEligibility(address _proposalist) private view returns (
        bool
        ){
        for(uint i = 0; i < validTokens.length; i++){
            if(daoContract.balanceOf(_proposalist, validTokens[i]) >= 1){
                return true;
            }
        }
        return false;
    }

    function checkVoteEligibility(uint256 _id, address _voter ) private view returns (bool ) {
        for(uint256 i=0; i< proposals[_id].canVote.length; i++){
                if(proposals[_id].canVote[i] == _voter){
                    return true;
                }
        }

        return false;
    }

    function createProposal(string memory _description, address[] memory _canVote) public {
        require(checkProposalEligibility(msg.sender), "Only NFT holders can create proposal");

        proposal storage newProposal = proposals[nextProposal]; 
        newProposal.id = nextProposal;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.number + 100;
        newProposal.canVote = _canVote;
        newProposal.maxVotes = _canVote.length;

        emit ProposalCreated(nextProposal, _description, _canVote.length, msg.sender);
        nextProposal++;

    }

    function voteOnProposal(uint256 _id, bool _vote) public {
        require(proposals[_id].exists, "The proposal does not exists");
        require(checkVoteEligibility(_id, msg.sender), "You can not vote on this proposal");
        require(!proposals[_id].voteStatus[msg.sender], "You have already voted this proposal");
        require(block.number <= proposals[_id].deadline, "The deadline has passed for this proposal");

        proposal storage p = proposals[_id];

        if(_vote) {
            p.votesUp++;
        } else {
            p.votesDown++;
        }
        p.voteStatus[msg.sender] = true;

        emit NewVote(p.votesUp, p.votesDown, msg.sender, _id, _vote);
    }

    function countVotes(uint256 _id) public {
        require(msg.sender == owner, "Only Owner can count votes");
        require(proposals[_id].exists, "The proposal does not exists");
        require(block.number > proposals[_id].deadline, "Voting has not concluded");
        require(!proposals[_id].countConducted, "Count already conducted");

        proposal storage p = proposals[_id];

        if(proposals[_id].votesDown < proposals[_id].votesUp){
            p.passed = true;
        }

        p.countConducted = true;

        
        emit ProposalCount(_id, p.passed);

    }

    function addTokenId(uint256 _tokenId) public {
        require(msg.sender == owner, "Only Owner can Add tokens");
        validTokens.push(_tokenId);

    }

    
}