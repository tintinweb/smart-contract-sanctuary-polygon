/**
 *Submitted for verification at polygonscan.com on 2023-04-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }
    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }
    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}


interface IERC721 {
    function balanceOf(address _owner) external view returns (uint256);
}

contract SamuraiDAO is ReentrancyGuard {
    struct Proposal {
        string title;
        string proposal;
        address proposalOwner;
        uint32 yesVote;
        uint32 noVote;
        address[] supporter;
        address[] opponent;
        bool status;
    }

    // Variables
    uint32 public proposalCount;
    address public erc721Contract;
    address public owner;

    //mappings
    mapping (uint32 => Proposal) public proposals;
    mapping (uint32 => mapping (address => uint32)) votedPower;
    mapping (uint32 => mapping(address => bool)) hasVoted;

    constructor() {
        owner = msg.sender;
    }

    // Events
    event CreateProposal(uint32 indexed id, address indexed proposalOwner, string title, string proposal);
    event VoteForProposal(uint32 indexed id, address indexed voter, bool vote);
    event EndedProposal(uint32 indexed _id, bool status);

    function setDefaultCollection(address _collection) public onlyOwner {
        erc721Contract = _collection;
    }
    function changeProposalStatus(uint32 _id, bool status) public onlyOwner {
        proposals[_id].status = status;
        emit EndedProposal(_id, status);
    } 

    // New Proposal
    function submitProposal(string memory _title, string memory _proposal) public {
        //Require
        require(getNFTBalance(msg.sender) > 0, "You must own at least one NFT to submit a proposal");
         ++proposalCount;
        require(proposals[proposalCount].status == false);

       
        proposals[proposalCount] = Proposal(_title, _proposal, msg.sender, 0, 0, new address[](0), new address[](0), true);
        emit CreateProposal(proposalCount, msg.sender, _title, _proposal);
    }

    //CheckNFT
    function getNFTBalance(address _owner) public view returns (uint256) {
        return IERC721(erc721Contract).balanceOf(_owner);
    }

    // New Vote
    function voteForProposal(uint32 _id, bool _vote) public nonReentrant {
        // Require
        require(proposals[_id].status == true, "Proposal is not active");
        require(hasVoted[_id][msg.sender] == false, "You already voted for this proposal");
        hasVoted[_id][msg.sender] = true;

        uint256 votingPower = getNFTBalance(msg.sender);
        if (_vote) {
            proposals[_id].yesVote += uint32(votingPower);
            proposals[_id].supporter.push(msg.sender);
        } else {
            proposals[_id].noVote += uint32(votingPower);
            proposals[_id].opponent.push(msg.sender);
        }
        votedPower[_id][msg.sender] = uint32(votingPower);
        emit VoteForProposal(_id, msg.sender, _vote);
    }

    // Views
    function getProposalStatus(uint32 _id) public view returns (bool) {
        return proposals[_id].status;
    }

    function getProposalVotes(uint32 _id) public view returns (uint32, uint32) {
        return (proposals[_id].yesVote, proposals[_id].noVote);
    }

    function getSupporters(uint32 _id) public view returns (address[] memory) {
        return proposals[_id].supporter;
    }

    function getOpponents(uint32 _id) public view returns (address[] memory) {
        return proposals[_id].opponent;
    }

    function getVotingPower(uint32 _id, address _voter) public view returns (uint) {
    return votedPower[_id][_voter];
    }

    // Modifier for Admin
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
}