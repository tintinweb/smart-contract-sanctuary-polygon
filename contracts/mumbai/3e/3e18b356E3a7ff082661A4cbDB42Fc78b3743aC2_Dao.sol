// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

interface IdaoContract {
        function balanceOf(address, uint256) external view returns (uint256);
    }

    contract Dao {
        address public owner;
        uint nextProposal;
        uint[] public  validTokens;
        IdaoContract daoContract;


    constructor(){
        owner = msg.sender;
        nextProposal=1;
        daoContract = IdaoContract(0x2953399124F0cBB46d2CbACD8A89cF0599974963);
        validTokens=[34885103611559094078416375598166902696017567311370712658413208238551126245396];
    } 

    struct proposal {

        uint id;
        bool exists;
        string description;
         uint deadline;
         uint votesUp;
         uint votesDown;
         address[] canVote;
         uint maxVotes;
         mapping(address => bool) voteStatus;
         bool countConducted;
         bool passed;

    }
        // make the proposals public
        mapping(uint => proposal) public Proposals;

        event proposalCreated(
            uint id,
            string description,
            uint maxVotes,
            address proposer
        );
        event newVote(
            uint votesUp,
            uint votesDown,
            address voter,
            uint proposal,
            bool votedFor
        );
        event proposalCount(
            uint id,
            bool passed
        );

        function checkProposalEligibility(address _proposalist) private view returns (bool){
            for (uint i = 0; i < validTokens.length; i++) {
                if(daoContract.balanceOf(_proposalist,validTokens[i]) >= 1){
                        return true;
                }
            }
            return false;
        }

        function checkVoteEligibility(uint _id, address _voter) private view returns (bool){
            for (uint i = 0; i < Proposals[_id].canVote.length; i++) {
                if(Proposals[_id].canVote[i] == _voter){
                    return true;
                }
            }
            return false;
        }

        function createProposal(string memory _description,address[] memory _canVote) public {
            require(checkProposalEligibility(msg.sender), "Only NFT holders can put forth Proposals");
                proposal storage newProposal = Proposals[nextProposal];
                newProposal.id = nextProposal;
                newProposal.description = _description;
                newProposal.deadline= block.number + 100;
                newProposal.canVote =_canVote;
                newProposal.maxVotes = _canVote.length;

                emit proposalCreated(nextProposal, _description, _canVote.length, msg.sender);
                nextProposal++;
        }
        function voteOnProposal(uint _id, bool _vote) public {
            require(Proposals[_id].exists, "This Proposal does not exist");
            require(checkVoteEligibility(_id, msg.sender), "You can not vote on this Proposal");
            require(!Proposals[_id].voteStatus[msg.sender], "You have already voted on this Proposal");
            require(block.number <= Proposals[_id].deadline, "The deadline has passed for this Proposal");

            proposal storage p = Proposals[_id];

            if(_vote){
                p.votesUp++;
            } else{
                p.votesDown++;
            }

            p.voteStatus[msg.sender] = true;

            emit newVote(p.votesUp, p.votesDown, msg.sender, _id, _vote );
        }
        function countVotes(uint _id) public {
            require(msg.sender == owner, "Only Owner Can Count Votes");
            require(Proposals[_id].exists, "This Proposal does not exist");
            require(block.number > Proposals[_id].deadline, "Voting has not concluded");
            require(!Proposals[_id].countConducted, "Count already conducted");
            //
            proposal storage p = Proposals[_id];
            if(Proposals[_id].votesDown < Proposals[_id].votesUp ){
                p.passed = true;
            }
            p.countConducted = true;

            emit proposalCount(_id, p.passed);

        }

        function addTokenId(uint _tokenid) public {
           require(msg.sender == owner, "Only Owner Can Add Tokens");
            validTokens.push(_tokenid);
        }

    }