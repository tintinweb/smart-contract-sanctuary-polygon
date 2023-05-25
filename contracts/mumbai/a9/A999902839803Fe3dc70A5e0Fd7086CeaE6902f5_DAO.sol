// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IdaoContract {
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract DAO {
    address private i_owner;
    uint256 private nextProposal;
    uint private ongoingProposal;
    uint private proposalPassed;
    uint256[] public validTokens;
    IdaoContract daoContract;

    struct Proposal {
        address proposer;
        uint256 id;
        bool exists;
        string description;
        uint256 deadline;
        uint256 votesUp;
        uint256 votesDown;
        address[] canVotes;
        uint256 maxVotes;
        mapping(address => bool) voteStatus;
        bool countConducted;
        bool passed;
    }

    mapping(uint256 => Proposal) public Proposals;
    mapping(address => bool) public isValid;

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
        bool votesFor
    );

    event proposalCount(uint256 id, bool passed);

    constructor() {
        i_owner = msg.sender;
        nextProposal = 1;
        ongoingProposal = 0;
        proposalPassed = 0;
        daoContract = IdaoContract(0x1811E1c046650856A8bf7dd34233e665Cb17f529);
        addTokenId(0);
    }

    function checkProposalEligibility(
        address _proposalist
    ) private view returns (bool) {
        return isValid[_proposalist];
    }

    function checkVoteEligibility(
        uint256 _id,
        address _voter
    ) private view returns (bool) {
        for (uint256 i = 0; i < Proposals[_id].canVotes.length; i++) {
            if (Proposals[_id].canVotes[i] == _voter) {
                return true;
            }
        }
        return false;
    }

    function createProposal(
        string memory _description,
        address[] memory _canVote
    ) public {
        require(
            checkProposalEligibility(msg.sender),
            "Only NFT holders can put forth Proposals"
        );

        Proposal storage newProposal = Proposals[nextProposal];
        newProposal.proposer = msg.sender;
        newProposal.id = nextProposal;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.number + 100;
        newProposal.canVotes = _canVote;
        newProposal.maxVotes = _canVote.length;

        emit proposalCreated(
            nextProposal,
            _description,
            _canVote.length,
            msg.sender
        );
        nextProposal++;
        ongoingProposal++;
    }

    function voteOnProposal(uint256 _id, bool _vote) public {
        require(Proposals[_id].exists, "This Proposal doesn't exist");
        require(
            checkVoteEligibility(_id, msg.sender),
            "You can't vote on this Proposal"
        );
        require(
            !Proposals[_id].voteStatus[msg.sender],
            "You have already voted on this Proposal"
        );
        require(
            block.number <= Proposals[_id].deadline,
            "The deadline has passed for this Proposal"
        );

        Proposal storage p = Proposals[_id];
        if (_vote) {
            p.votesUp++;
        } else {
            p.votesDown++;
        }
        p.voteStatus[msg.sender] = true;

        emit newVote(p.votesUp, p.votesDown, msg.sender, _id, _vote);
    }

    function countVotes(uint256 _id) public {
        require(msg.sender == i_owner, "Only Owner Can Cast Votes");
        require(Proposals[_id].exists, "This Proposal does not exist");
        require(
            block.number > Proposals[_id].deadline,
            "Voting has not concluded"
        );
        require(!Proposals[_id].countConducted, "Count already conducted");

        Proposal storage p = Proposals[_id];

        if (Proposals[_id].votesDown < Proposals[_id].votesUp) {
            p.passed = true;
            proposalPassed++;
        }

        p.countConducted = true;
        ongoingProposal--;

        emit proposalCount(_id, p.passed);
    }

    function addTokenId(uint256 _tokenId) public {
        require(msg.sender == i_owner, "Only Owner Can Add Token");

        validTokens.push(_tokenId);
        isValid[daoContract.ownerOf(_tokenId)] = true;
    }

    function changeOwner(address _newOwner) public {
        require(msg.sender == i_owner, "Only owner can change owner");
        i_owner = _newOwner;
    }

    function owner(uint256) public view returns (address) {
        return i_owner;
    }

    function getProposalCount() public view returns (uint) {
        return nextProposal - 1;
    }

    function getMemberCount() public view returns (uint) {
        return validTokens.length;
    }

    function getOngoingProposalCount() public view returns (uint) {
        return ongoingProposal;
    }

    function getProposalPassedCount() public view returns (uint) {
        return proposalPassed;
    }

    function getVoteStatus(
        uint256 _id
    ) public view returns (address[] memory, bool[] memory) {
        require(Proposals[_id].exists, "This Proposal doesn't exist");

        uint256 length = Proposals[_id].canVotes.length;
        address[] memory addresses = new address[](length);
        bool[] memory statuses = new bool[](length);

        for (uint256 i = 0; i < length; i++) {
            addresses[i] = Proposals[_id].canVotes[i];
            statuses[i] = Proposals[_id].voteStatus[Proposals[_id].canVotes[i]];
        }

        return (addresses, statuses);
    }
}