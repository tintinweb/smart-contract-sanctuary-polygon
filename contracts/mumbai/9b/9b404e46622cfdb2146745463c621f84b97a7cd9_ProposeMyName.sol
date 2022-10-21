// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Proposer} from "./Proposer.sol";

// Make a proposal to change the contract name.
contract ProposeMyName is Proposer {
    event NameChangeProposed(string newName, uint256 proposalID);
    event NameChangeImplemented(string newName, uint256 proposalID);

    string private s_myName = "Jimmy";

    constructor(
        address linkToken,
        uint256 minVotingBalanceJuels,
        uint256 proposalDelay
    ) Proposer(linkToken, minVotingBalanceJuels, proposalDelay) {}

    // Propose a name change.
    function proposeNameChange(string calldata newName) external onlyOwner {
        // Create the proposal.
        uint256 proposalID = createProposal(abi.encode(newName));

        // Notify any watchers of the proposal.
        emit NameChangeProposed(newName, proposalID);
    }

    // Implement an approved name change.
    function implementNameChange(uint256 proposalID)
        external
        onlyOwner
        upgradesEnabled
        proposalIsValid(proposalID)
    {
        // Implement the approved change.
        Proposal storage proposal = s_proposalMapping[proposalID];
        s_myName = abi.decode(proposal.item, (string));

        // Notify any watchers of the implementation.
        emit ConfigChangedProposed(s_proposalsConfig, proposalID);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LinkTokenInterface} from "./interfaces/LinkTokenInterface.sol";
import {ConfirmedOwnerWithProposal} from "./ConfirmedOwnerWithProposal.sol";

/**
 * The Proposer contract enables checks to be levied against the owner of a contract via community token ownership. Proposals can accompany any sensitive setter function,
 * such that a change to a contract must be approved by the token holders of a given community before it can be implemented. An example of this implementation
 * can be found in this contract's proposeConfigChange and implementConfigChange functions, whereby the Proposer contract owner can change the config of the contract
 * after a proposal is created and approved.
 *
 * The voting pattern of this contract requires a flat rate of LINK to vote. Beyond the minimum requirement to vote,
 * the amount of LINK an address owns has no effect on its voting power, i.e 1m LINK = 1 vote, 10 LINK = 1 vote.
 *
 * The pattern prevents a large holder of LINK from unfairly brute-forcing proposals. Additionally, a large token holder that wanted to split their stake into
 * many smaller ones to gain votes would spend a large amount of gas doing so, making sybil attacks difficult.
 *
 * The contract also requires an approved proposal in order to update its configuration, as to prevent a bad owner from sabotaging the contract.
 *
 * Once proposals are turned off in this contract, they cannot be turned back on.
 */
contract Proposer is ConfirmedOwnerWithProposal {
    event ConfigChangedProposed(
        ProposalsConfig proposedConfig,
        uint256 proposalID
    );
    event ConfigChangesImplemented(
        ProposalsConfig proposedConfig,
        uint256 proposalID
    );

    error ProposalIsNotMostRecent();
    error ProposalWasNotApproved();
    error ProposalIsNotReady();
    error ProposalsAreDisbaled();
    error InsufficientFundsToVote();
    error AlreadyVoted();

    LinkTokenInterface immutable LINK;

    struct Proposal {
        uint256 proposalID; // The ID of the proposal
        uint256 proposalBlock; // The block at which the upgrade was proposed.
        uint256 votesFor; // Votes in favor of the upgrade.
        uint256 votesAgainst; // Votes in opposition of the upgrade.
        mapping(address => bool) votersMapping; // The directory of voters that have voted.
        bytes item; // The encoded item to be implemented.
    }

    struct ProposalsConfig {
        uint256 proposalDelay; // Time lock for an upgrade.
        uint256 minVotingBalanceJuels; // The minimum balance of LINK in Juels a user should have to vote.
        bool proposalsEnabled; // Determines if proposals are still enabled.
    }

    uint256 proposalNonce; // The incrementing proposal ID.
    mapping(uint256 => Proposal) internal s_proposalMapping; // The directory for upgrade proposals.
    ProposalsConfig s_proposalsConfig; // The configuration for proposals.

    // Assign the LINK token and instantiate a default config.
    constructor(
        address linkToken,
        uint256 minVotingBalanceJuels,
        uint256 proposalDelay
    ) ConfirmedOwnerWithProposal(msg.sender, address(0)) {
        LINK = LinkTokenInterface(linkToken);
        s_proposalsConfig = ProposalsConfig({
            proposalsEnabled: true,
            minVotingBalanceJuels: minVotingBalanceJuels,
            proposalDelay: proposalDelay
        });
    }

    function createProposal(bytes memory encodedItem)
        internal
        returns (uint256 proposalID)
    {
        proposalNonce++;

        // Create the proposal. The proposal struct contains a nested mapping,
        // so it cannot be constrcuted.
        Proposal storage proposal = s_proposalMapping[proposalNonce];
        proposal.proposalID = proposalNonce;
        proposal.proposalBlock = block.number;
        proposal.item = encodedItem;

        return proposalNonce;
    }

    // Vote on a proposal. The voter can only vote once, and must have at least the minimum balance required to vote.
    function voteOnProposal(uint256 proposalID, bool approve) external {
        if (
            LINK.balanceOf(msg.sender) < s_proposalsConfig.minVotingBalanceJuels
        ) {
            revert InsufficientFundsToVote();
        }
        Proposal storage proposal = s_proposalMapping[proposalID];
        if (proposal.votersMapping[msg.sender]) {
            revert AlreadyVoted();
        }
        if (approve) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
    }

    // Retrieves the encoded item for a given proposal.
    function getItemForProposal(uint256 proposalID)
        internal
        view
        returns (bytes memory)
    {
        return s_proposalMapping[proposalID].item;
    }

    modifier proposalIsValid(uint256 proposalID) {
        // Proposals cannot be implemented out-of-order.
        if (proposalID != proposalNonce) {
            revert ProposalIsNotMostRecent();
        }

        // Proposals must be older than the proposalDelay config,
        // and they must be approved.
        Proposal storage proposal = s_proposalMapping[proposalNonce];
        if (
            proposal.proposalBlock + s_proposalsConfig.proposalDelay <
            block.number
        ) {
            revert ProposalIsNotReady();
        }
        if (proposal.votesFor <= proposal.votesAgainst) {
            revert ProposalIsNotReady();
        }
        _;
    }

    modifier upgradesEnabled() {
        if (!s_proposalsConfig.proposalsEnabled) {
            revert ProposalsAreDisbaled();
        }
        _;
    }

    // Propose a change to the configuration of the Proposal contract. This affects the delay before a proposal can be approved,
    // and the minimum Juel balance required to vote, and if proposals are still enabled.
    function proposeConfigChange(ProposalsConfig calldata proposalsConfig)
        external
        onlyOwner
    {
        // Once upgrades have been disabled, they can not be re-enabled.
        bool proposalsEnabled = s_proposalsConfig.proposalsEnabled &&
            proposalsConfig.proposalsEnabled;

        // Construct the proposed configuration.
        ProposalsConfig memory config = ProposalsConfig({
            proposalsEnabled: proposalsEnabled,
            proposalDelay: proposalsConfig.proposalDelay,
            minVotingBalanceJuels: proposalsConfig.minVotingBalanceJuels
        });

        // Create the proposal.
        uint256 proposalID = createProposal(abi.encode(config));

        // Notify any watchers of the proposal.
        emit ConfigChangedProposed(config, proposalID);
    }

    // Implement an approved change to the configuration of the Proposal contract.
    function implementConfigChange(uint256 proposalID)
        external
        onlyOwner
        upgradesEnabled
        proposalIsValid(proposalID)
    {
        // Implement the approved config.
        Proposal storage proposal = s_proposalMapping[proposalID];
        s_proposalsConfig = abi.decode(proposal.item, (ProposalsConfig));

        // Notify any watchers of the implementation.
        emit ConfigChangedProposed(s_proposalsConfig, proposalID);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
    function allowance(address owner, address spender)
        external
        view
        returns (uint256 remaining);

    function approve(address spender, uint256 value)
        external
        returns (bool success);

    function balanceOf(address owner) external view returns (uint256 balance);

    function decimals() external view returns (uint8 decimalPlaces);

    function decreaseApproval(address spender, uint256 addedValue)
        external
        returns (bool success);

    function increaseApproval(address spender, uint256 subtractedValue)
        external;

    function name() external view returns (string memory tokenName);

    function symbol() external view returns (string memory tokenSymbol);

    function totalSupply() external view returns (uint256 totalTokensIssued);

    function transfer(address to, uint256 value)
        external
        returns (bool success);

    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
    address private s_owner;
    address private s_pendingOwner;

    event OwnershipTransferRequested(address indexed from, address indexed to);
    event OwnershipTransferred(address indexed from, address indexed to);

    constructor(address newOwner, address pendingOwner) {
        require(newOwner != address(0), "Cannot set owner to zero");

        s_owner = newOwner;
        if (pendingOwner != address(0)) {
            _transferOwnership(pendingOwner);
        }
    }

    /**
     * @notice Allows an owner to begin transferring ownership to a new address,
     * pending.
     */
    function transferOwnership(address to) public override onlyOwner {
        _transferOwnership(to);
    }

    /**
     * @notice Allows an ownership transfer to be completed by the recipient.
     */
    function acceptOwnership() external override {
        require(msg.sender == s_pendingOwner, "Must be proposed owner");

        address oldOwner = s_owner;
        s_owner = msg.sender;
        s_pendingOwner = address(0);

        emit OwnershipTransferred(oldOwner, msg.sender);
    }

    /**
     * @notice Get the current owner
     */
    function owner() public view override returns (address) {
        return s_owner;
    }

    /**
     * @notice validate, transfer ownership, and emit relevant events
     */
    function _transferOwnership(address to) private {
        require(to != msg.sender, "Cannot transfer to self");

        s_pendingOwner = to;

        emit OwnershipTransferRequested(s_owner, to);
    }

    /**
     * @notice validate access
     */
    function _validateOwnership() internal view {
        require(msg.sender == s_owner, "Only callable by owner");
    }

    /**
     * @notice Reverts if called by anyone other than the contract owner.
     */
    modifier onlyOwner() {
        _validateOwnership();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
    function owner() external returns (address);

    function transferOwnership(address recipient) external;

    function acceptOwnership() external;
}