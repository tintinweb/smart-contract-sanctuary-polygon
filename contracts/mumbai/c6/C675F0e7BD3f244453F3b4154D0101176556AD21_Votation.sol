/**
 *Submitted for verification at polygonscan.com on 2022-07-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

/**
 * @notice This interface is used to certify that an address can vote
 */
interface IRoles {
    /**
     * @notice Ask if the address is superAdmin
     * @param superAdmin_ the superAdmin ?
     * @return true if superAdmin, false otherwise
     */
    function isSuperAdmin(address superAdmin_) external view returns (bool);

    /**
     * @notice Returns if the 'admin' given is admin
     * @param user_ The admin
     * @return true if admin, false otherwise
     */
    function isAdmin(address user_) external view returns (bool);

    /**
     * @notice Gets the amount of admins
     * @return The amount of admins
     */
    function getAdminCount() external view returns (uint256);
}

/**
 * @notice Votation module
 */
contract Votation {
    /**
     * @notice The roles contract address
     */
    IRoles rolesContract;

    /**
     * @notice Proposal structure
     * @param result This proposal result
     * @param quorum If this proposal should need full quorum
     * @param votesInFavor Amount of votes in favor
     * @param votesAgainst Amount of votes against
     * @param to Address where the code is executed
     * @param action Action to execute (in bytes)
     */
    struct Proposal {
        uint72 result;
        uint72 quorum;
        uint144 votesInFavor;
        uint144 votesAgainst;
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
    uint256 public CURRENT_ID;

    /**
     * @notice Deployer of the contract
     */
    address deployer;

    /**
     * @notice Mapping to save proposal structures
     */
    mapping(uint256 => Proposal) public proposals;

    /**
     * @notice Mapping saving if an admin has votes 
     */
    mapping(address => mapping(uint144 => uint144)) public hasVoted;

    /**
     * @notice Event for when a proposal is created
     */
    event ProposalCreated(address indexed authority_, uint256 id_);

    /**
     * @notice Event for when an admin has voted
     */
    event ProposalVoted(address indexed authority_, uint256 id_);

    /**
     * @notice Event for when an proposal is executed
     */
    event ProposalExecuted(uint256 id_);

    /**
     * @notice Event for when the contract is changed
     */
    event ContractChanged(address indexed newContract_);

    /**
     * @notice Requires the msg.sender to be admin
     */
    modifier onlyAdmin {
        require(rolesContract.isAdmin(msg.sender), 'Voting:Only admins');
        _;
    }

    /**
     * @notice Builder 
     */
    constructor () {
        deployer = msg.sender;
    }

    /**
     * @notice Function to create proposals
     * @param action_ The data to execute
     * @param quorum_ The quorum needed
     * @dev only admins can create a proposal
     */
    function createProposal(bytes memory action_, uint8 quorum_, address to_) public onlyAdmin {
        require((quorum_ == 0) || (quorum_ == 1), 'Voting:Invalid quorum');
        rolesContract.getAdminCount() <= 3 ? 
        proposals[CURRENT_ID] = Proposal(0, 1, 0, 0, to_, action_) :
        proposals[CURRENT_ID] = Proposal(0, quorum_, 0, 0, to_, action_);
        emit ProposalCreated(msg.sender, CURRENT_ID);
        CURRENT_ID++;
    }

    /**
     * @notice Function to vote a proposal
     * @param proposal_ Id of the proposal to vote
     * @dev only admins can vote
     */
    function voteInFavor(uint144 proposal_) public onlyAdmin {
        require(proposal_ < CURRENT_ID);
        require(hasVoted[msg.sender][proposal_] != VOTED);
        hasVoted[msg.sender][proposal_] = VOTED;
        Proposal storage proposal = proposals[proposal_];
        require(proposal.result != FINISHED);
        proposal.votesInFavor++;
        if (proposal.quorum == FULL_QUORUM) {
            if (proposal.votesInFavor == rolesContract.getAdminCount()) {
                proposal.result = FINISHED;
                proposalFinished(proposal_);
            }
        } else {
            if (proposal.votesInFavor >= getQuorum(rolesContract.getAdminCount())) {
                proposal.result = FINISHED;
                proposalFinished(proposal_);
            }
        }
        emit ProposalVoted(msg.sender, proposal_);
    }

    /**
     * @notice Funtion to vote against a proposal
     * @param proposal_ Id of the proposal to vote
     * @dev Only admins
     */
    function voteAgainst(uint144 proposal_) public onlyAdmin {
        require(proposal_ < CURRENT_ID);
        require(hasVoted[msg.sender][proposal_] != VOTED);
        hasVoted[msg.sender][proposal_] = VOTED;
        Proposal storage proposal = proposals[proposal_];
        require(proposal.result != FINISHED);
        proposal.votesAgainst++;
        if (proposal.quorum == FULL_QUORUM) {
            if (proposal.votesAgainst >= rolesContract.getAdminCount()) {
                proposal.result = FINISHED;
            }
        } else {
            if (proposal.votesAgainst >= getQuorum(rolesContract.getAdminCount())) {
                proposal.result = FINISHED;
            }
        }
        emit ProposalVoted(msg.sender, proposal_);
    }    

    /**
     * @notice Funcion called when the proposal is finished
     * @param proposal_ Id of the proposal finished
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
        emit ProposalExecuted(proposal_);
        return result;
    }

    /**
     * @notice Returns the 70% aprox of the amount given
     * @param number_ Amount given to calculate
     * @return The 75% of the param number
     */
    function getQuorum(uint number_) public pure returns (uint) {
        if ((number_ == 0) || (number_ == 1)) return number_;
        uint percent = ((number_ / 2) + ((number_ / 2) / 2));
        return (percent + 1) > (number_ / 2) ? percent : percent + 1;
    }

    /**
     * @notice Changes the roles contract (from where )
     * @param newContract_ The address of the contract
     */
    function setLogicContract(address newContract_) public {
        if (msg.sender != deployer) revert();
        rolesContract = IRoles(newContract_);
        emit ContractChanged(newContract_);
        deployer = address(0);
    }

}