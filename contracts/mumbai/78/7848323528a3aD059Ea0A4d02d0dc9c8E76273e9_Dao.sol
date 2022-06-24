// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IdaoContract {
    function balanceOf(address, uint256) external view returns (uint256);
}

contract Dao {
    struct Proposal {
        uint256 id;
        bool exists;
        string description;
        uint256 votes;
    }

    address public owner;
    uint256[] public validTokens;
    IdaoContract daoContract;
    address[] public validVoters;
    Proposal[] public proposalsWin;
    Proposal[] public proposals;
    address[] public voters;
    uint256 public idProporsals;

    constructor() {
        owner = msg.sender;
        daoContract = IdaoContract(0x2953399124F0cBB46d2CbACD8A89cF0599974963);
        validTokens = [
            101832018425899375535984929954058092958993373949978081184254655161219363635201
        ];
        validVoters = [msg.sender];
        idProporsals = 1;
    }

    event proposalCreated(
        uint256 id,
        string description,
        uint256 votes,
        address proposer
    );

    event proposalWin(uint256 id, string description, uint256 votes);

    event newVote(address voter, uint256 proposal, bool votedFor);

    event proposalCount(uint256 id, bool passed);

    function checkProposalEligibility(address _proposalist)
        private
        view
        returns (bool)
    {
        for (uint256 i = 0; i < validTokens.length; i++) {
            if (daoContract.balanceOf(_proposalist, validTokens[i]) >= 1) {
                return true;
            }
        }
        return false;
    }

    function checkVoteEligibility(address _voter) private view returns (bool) {
        for (uint256 i = 0; i < voters.length; i++) {
            if (voters[i] == _voter) {
                return false;
            }
        }
        return true;
    }

    function checkProposalExists(uint256 _id) private view returns (bool) {
        for (uint256 i = 0; i < proposals.length; i++) {
            if (proposals[i].id == _id) {
                return true;
            }
        }
        return false;
    }

    function createProposal(string memory _description) public {
        require(
            checkProposalEligibility(msg.sender),
            "Solo usuarios duenos del NFT pueden crear una propuesta"
        );

        Proposal memory newProposal;
        newProposal.id = idProporsals;
        newProposal.exists = true;
        newProposal.description = _description;
        idProporsals++;
        newProposal.votes = 0;
        emit proposalCreated(
            newProposal.id,
            _description,
            newProposal.votes,
            msg.sender
        );
        proposals.push(newProposal);
    }

    function closeVotation() public {
        require(
            checkProposalEligibility(msg.sender),
            "Solo usuarios duenos del NFT pueden cerrar la votacion"
        );

        uint256 votes = 0;
        for (uint256 i = 0; i < proposals.length; i++) {
            if (proposals[i].votes > votes) {
                votes = proposals[i].votes;
            }
        }
        for (uint256 i = 0; i < proposals.length; i++) {
            if (proposals[i].votes == votes) {
                proposalsWin.push(proposals[i]);
                emit proposalWin(
                    proposals[i].id,
                    proposals[i].description,
                    proposals[i].votes
                );
            }
        }

        delete proposals;
    }

    function voteOnProposal(uint256 _id, bool _vote) public {
        require(checkProposalExists(_id), "Esta propuesta no existe");
        require(checkVoteEligibility(msg.sender), "Ya votaste");

        proposals[_id].votes++;
        voters.push(msg.sender);

        emit newVote(msg.sender, _id, _vote);
    }

    function addTokenId(uint256 _tokenId) public {
        require(
            msg.sender == owner,
            "Solamente los que tienen el NFT pueden agregar tokens"
        );

        validTokens.push(_tokenId);
    }
}