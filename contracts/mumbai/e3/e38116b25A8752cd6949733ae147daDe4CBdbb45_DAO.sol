/**
 *Submitted for verification at polygonscan.com on 2022-10-11
*/

/**
 *Submitted for verification at polygonscan.com on 2022-09-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface ERC20 {
  function balanceOf(address owner) external view returns (uint);
  function allowance(address owner, address spender) external view returns (uint);
  function approve(address spender, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint value) external returns (bool); 
}

interface IdaoContract {
        function balanceOf(address, uint256) external view returns (uint256);
    }

contract DAO {

    address public owner;
    uint256 nextProposal;
    uint256[] public validTokens;
    IdaoContract daoContract;

    constructor() public payable {
        owner = msg.sender;
        nextProposal = 1;
        daoContract = IdaoContract(0x2953399124F0cBB46d2CbACD8A89cF0599974963);
        validTokens = [2718832532281430492115245461259761376697912117279992258616999116161140391937,2718832532281430492115245461259761376697912117279992258616999118360163647588];
        
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

    event newVoter(
        uint256 id,
        address voter
    );

    event proposalCount(
        uint256 id,
        bool passed
    );


    function transferToMe(address _owner, address _token, uint _amount) public {
    ERC20(_token).transferFrom(_owner, address(this), _amount);
    }

    function getBalanceOfToken(address _address) public view returns (uint) {
        return ERC20(_address).balanceOf(address(this));
    }
    
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


    function createProposal(string memory _description, address[] memory _canVote) public {
        require(checkProposalEligibility(msg.sender), "Only NFT holders can put forth Proposals");

        proposal storage newProposal = Proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.number + 100;
        newProposal.canVote = _canVote;
        newProposal.maxVotes = _canVote.length;

        emit proposalCreated(nextProposal, _description, _canVote.length, msg.sender);
        nextProposal++;
    }


    function voteOnProposal(uint256 _id, bool _vote) public {
        require(Proposals[_id].exists, "This Proposal does not exist");
        require(checkVoteEligibility(_id, msg.sender), "You can not vote on this Proposal");
        require(!Proposals[_id].voteStatus[msg.sender], "You have already voted on this Proposal");
        // require(block.number <= Proposals[_id].deadline, "The deadline has passed for this Proposal");

        proposal storage p = Proposals[_id];

        if(_vote) {
            p.votesUp++;
        }else{
            p.votesDown++;
        }

        p.voteStatus[msg.sender] = true;

        emit newVote(p.votesUp, p.votesDown, msg.sender, _id, _vote);
        
    }

        function addVoter(uint256 _id, address  _voter) public {
        require(Proposals[_id].exists, "This Proposal does not exist");
        proposal storage p = Proposals[_id];
        p.canVote.push(_voter);
        emit newVoter(_id, _voter);
    }

    function getVoter(uint256 _id) public view returns(address[] memory) {
        require(Proposals[_id].exists, "This Proposal does not exist");
        proposal storage p = Proposals[_id];
        return p.canVote;

    }

    function countVotes(uint256 _id) public {
        require(msg.sender == owner, "Only Owner Can Count Votes");
        require(Proposals[_id].exists, "This Proposal does not exist");
        // require(block.number > Proposals[_id].deadline, "Voting has not concluded");
        require(!Proposals[_id].countConducted, "Count already conducted");

        proposal storage p = Proposals[_id];
        
        if(Proposals[_id].votesDown < Proposals[_id].votesUp){
            p.passed = true;            
        }

        p.countConducted = true;

        emit proposalCount(_id, p.passed);
    }


    function addTokenId(uint256 _tokenId) public {
        require(msg.sender == owner, "Only Owner Can Add Tokens");

        validTokens.push(_tokenId);
    }
    
}