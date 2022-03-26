/**
 *Submitted for verification at polygonscan.com on 2022-03-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract Votation {
    /**
     * @notice The admin count
     */
    uint adminCount = 1;

    /**
     * @notice Proposal structure
     * @param result This proposal result
     * @param quorum If this proposal should need full quorum
     * @param votes Amount of votes
     * @param action Action to execute (in bytes)
     */
    struct Proposal {
        uint72 result;
        uint72 quorum;
        uint144 votes;
        address to;
        bytes action;
    }

    /**
     * @notice The proposal should have 70% of the admins approval
     */
    uint8 constant SEMI_QUORUM = 0;

    /**
     * @notice The proposal should have 100% of the admins approval
     */
    uint8 constant FULL_QUORUM = 1;

    /**
     * @notice Flag to identify finished proposals
     */
    uint8 constant FINISHED    = 1;

    /**
     * @notice Flag to identify if an admin has voted
     */
    uint8 constant VOTED       = 1;

    /**
     * @notice Counter of proposals
     */
    uint144 CURRENT_ID         = 0;

    /**
     * @notice Mapping to save proposal structures
     */
    mapping(uint144 => Proposal) public proposals;

    /**
     * @notice Mapping saving if an admin has votes 
     */
    mapping(address => mapping(uint144 => uint144)) public hasVoted;

    /**
     * @notice Event for when a proposal is created
     */
    event ProposalCreated(address indexed authority_, uint144 id_);

    /**
     * @notice Event for when an admin has voted
     */
    event ProposalVoted(address indexed authority_, uint144 id_);

    /**
     * @notice Function to create proposals
     * @param action_ The data to execute
     * @param quorum_ The quorum needed
     * @dev only admins can create a proposal
     */
    function createProposal(bytes memory action_, uint8 quorum_, address to_) public {
        require((quorum_ == 0) || (quorum_ == 1));
        adminCount <= 3 ? 
        proposals[CURRENT_ID] = Proposal(0, 1, 0, to_, action_) :
        proposals[CURRENT_ID] = Proposal(0, quorum_, 0, to_, action_);
        emit ProposalCreated(msg.sender, CURRENT_ID);
        CURRENT_ID++;
    }

    /**
     * @notice Function to vote a proposal
     * @param proposal_ Id of the proposal to vote
     * @dev only admins can vote
     */
    function vote(uint144 proposal_) public {
        require(hasVoted[msg.sender][proposal_] != VOTED);
        hasVoted[msg.sender][proposal_] = VOTED;
        Proposal storage proposal = proposals[proposal_];
        require(proposal.result != FINISHED);
        if (proposal.quorum == FULL_QUORUM) {
            if ( (proposal.votes + 1) <= adminCount) {
                proposal.votes++;
                if (proposal.votes == adminCount) {
                    proposal.result = FINISHED;
                    proposalFinished(proposal_);
                } 
            } else proposal.votes++;
        } else {
            if ((proposal.votes + 1) <= getQuorum(adminCount)) {
                proposal.votes++;
                if (proposal.votes == getQuorum(adminCount)) {
                    proposal.result = FINISHED;
                    proposalFinished(proposal_);
                }
            } else proposal.votes++;
        }
        emit ProposalVoted(msg.sender, proposal_);
    }

    /**
     * @notice Funcion called when the proposal is finished
     * @param proposal_ Id of the proposal finished
     * @dev Parametrizar address objetivo
     */
    function proposalFinished(uint144 proposal_) internal returns (bool) {
        bytes memory data_ = proposals[proposal_].action;
        address to_ = proposals[proposal_].to;
        uint256 dataLength_ = data_.length;
        bool result;
        assembly {
            let position := mload(0x40)
            let data := add(data_, 32)
            result := call(
                gas(),
                to_,
                0,
                data,
                dataLength_,
                position,
                0
            )
        }
        return result;
    }

    /**
     * @notice Returns the 70% aprox of the amount given
     * @param number_ Amount given to calculate
     * @return The 75% of the param number
     */
    function getQuorum(uint number_) internal pure returns (uint) {
        if ((number_ == 0) || (number_ == 1)) return number_;
        uint percent = ((number_ / 2) + ((number_ / 2) / 2));
        return (percent + 1) > (number_ / 2) ? percent : percent + 1;
    }
}