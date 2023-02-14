/**
 *Submitted for verification at polygonscan.com on 2023-02-13
*/

pragma solidity ^0.8.0;

contract DAO {
    address public owner;
    mapping(address => bool) public members;
    uint256 public memberCount = 0;
    uint256 public proposalCount = 0;

    struct Proposal {
        string title;
        string description;
        address proposer;
        uint256 voteCount;
        bool isClosed;
        bool approved;
        mapping(address => bool) voters;
    }

    mapping(uint256 => Proposal) public proposals;

    constructor() {
        owner = msg.sender;
    }

    event NewProposal(uint256 proposalID, address proposer);
    event MembershipApplied(address applicant);
    event MembershipApproved(address member);
    event ApproveProposal(uint256 proposalID);
    event RejectProposal(uint256 proposalID);
    event VotingClosed(uint256 proposalID, uint256 voteCount);

    function applyForMembership() public {
        require(!members[msg.sender], "You are already a member.");
        emit MembershipApplied(msg.sender);
    }

    function approveMembership(address applicant) public {
        require(msg.sender == owner, "Only the owner can approve membership.");
        require(!members[applicant], "Membership already approved");
        members[applicant] = true;
        memberCount++;
        emit MembershipApproved(applicant);
    }

    function createProposal(string memory title, string memory description)
        public
    {
        require(
            members[msg.sender],
            "You must be a member to create a proposal."
        );
        proposals[proposalCount].title = title;
        proposals[proposalCount].description = description;
        proposals[proposalCount].proposer = msg.sender;
        proposals[proposalCount].voteCount = 0;
        proposals[proposalCount].isClosed = false;
        proposalCount++;
        emit NewProposal(proposalCount, msg.sender);
    }

    function voteForProposal(uint256 proposalID) public {
        require(
            proposalID >= 0 && proposalID < proposalCount,
            "Invalid proposal ID"
        );
        require(members[msg.sender], "You must be a member to vote.");
        Proposal storage proposal = proposals[proposalID];
        require(!proposal.isClosed, "Voting is closed for this proposal.");
        require(
            !proposal.voters[msg.sender],
            "You have already voted for this proposal."
        );
        proposal.voteCount++;
        proposal.voters[msg.sender] = true;
    }

    function closeVoting(uint256 proposalID) public {
        require(
            msg.sender == owner,
            "Only the owner can close the voting process."
        );
        require(
            proposalID >= 0 && proposalID < proposalCount,
            "Invalid proposal ID"
        );
        Proposal storage proposal = proposals[proposalID];
        if (proposals[proposalID].voteCount > memberCount / 2) {
            proposal.isClosed = true;
            emit ApproveProposal(proposalID);
        } else {
            emit RejectProposal(proposalID);
        }
        emit VotingClosed(proposalID, proposal.voteCount);
    }
}