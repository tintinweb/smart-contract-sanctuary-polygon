// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
/**
 * @notice This is a deprecated interface. Please use AutomationCompatibleInterface directly.
 */
pragma solidity ^0.8.0;
import {AutomationCompatibleInterface as KeeperCompatibleInterface} from "./AutomationCompatibleInterface.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

error MultiVote__OnlyOwner();
error MultiVote__AlreadyVoted();
error MultiVote__AlreadyPermittedToVote();
error MultiVote__NoRightToVote();
error MultiVote__VotingAlreadyStarted();
error MultiVote__VotingClosed();
error MultiVote__UpkeepIsFalse();

/**@title MultiVote contract
 * @author Agnick
 * @notice This contract is for decentralized voting
 * @dev Using Chainlink keepers
 */
contract MultiVote is KeeperCompatibleInterface {
    /* Type declarations */
    enum VotingStates {
        OPEN,
        CLOSED
    }

    struct Voter {
        uint256 vote;
        bool voted;
        uint256 weight;
    }

    struct Proposal {
        bytes32 name;
        uint256 voteCount;
    }

    /* State Variables */
    VotingStates private s_votingState;
    Proposal[] private s_proposals;
    address[] private s_votersKey;
    mapping(address => Voter) private s_voters; // key: address, value: Voter
    address private immutable i_owner;
    uint256 private s_interval;
    uint256 private s_lastTimeStamp;

    /* Events */
    event ProposionCreated(bytes32[] indexed proposalNames, uint256 indexed interval);
    event WinnerPicked(bytes32 indexed name, uint256 indexed winningVoteCount);

    /* Modifiers */
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert MultiVote__OnlyOwner();
        }
        _;
    }

    modifier notVoted(address voter) {
        if (s_voters[voter].voted) {
            revert MultiVote__AlreadyVoted();
        }
        _;
    }

    modifier notPermitted(address voter) {
        if (s_voters[voter].weight == 1) {
            revert MultiVote__AlreadyPermittedToVote();
        }
        _;
    }

    modifier isPermitted(address voter) {
        if (s_voters[voter].weight == 0) {
            revert MultiVote__NoRightToVote();
        }
        _;
    }

    /* Constructor */
    constructor() {
        i_owner = msg.sender;
        s_voters[i_owner].weight = 1;
        s_votingState = VotingStates.CLOSED;
    }

    /* Functions */
    function giveRightToVote(address voter) public onlyOwner notVoted(voter) notPermitted(voter) {
        s_voters[voter].weight = 1;
        s_votersKey.push(voter);
    }

    function vote(uint256 proposal) public notVoted(msg.sender) isPermitted(msg.sender) {
        if (s_votingState == VotingStates.CLOSED) {
            revert MultiVote__VotingClosed();
        }
        Voter storage sender = s_voters[msg.sender];
        sender.voted = true;
        sender.vote = proposal;
        s_proposals[proposal].voteCount += sender.weight;
    }

    function createProposal(bytes32[] memory proposalNames, uint256 interval) public onlyOwner {
        if (s_votingState == VotingStates.OPEN) {
            revert MultiVote__VotingAlreadyStarted();
        }
        s_votingState = VotingStates.OPEN;
        s_lastTimeStamp = block.timestamp;
        s_interval = interval;
        for (uint256 i = 0; i < proposalNames.length; i++) {
            s_proposals.push(Proposal({name: proposalNames[i], voteCount: 0}));
        }
        emit ProposionCreated(proposalNames, interval);
    }

    /**
     * @notice This is the function that the Chainlink Keeper nodes call.
     * @notice they look for `upkeepNeeded` to return True.
     * @dev the following should be true for this to return true:
     * @dev 1. The voting is open,
     * @dev 2. The time interval has passed between voting runs.
     * @return upkeepNeeded variable.
     */
    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        bool isOpen = (s_votingState == VotingStates.OPEN);
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > s_interval);
        upkeepNeeded = (isOpen && timePassed);
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert MultiVote__UpkeepIsFalse();
        }
        s_votingState = VotingStates.CLOSED;
        s_interval = 0;
        s_lastTimeStamp = 0;
        uint256 proposal = winningProposal();
        bytes32 name = winningName();
        for (uint256 i = 0; i < s_votersKey.length; i++) {
            delete s_voters[s_votersKey[i]];
        }
        delete s_votersKey;
        delete s_proposals;
        emit WinnerPicked(name, proposal);
    }

    function winningProposal() public view returns (uint256 winningProposal_) {
        uint256 winningVoteCount = 0;
        for (uint256 i = 0; i < s_proposals.length; i++) {
            if (s_proposals[i].voteCount > winningVoteCount) {
                winningVoteCount = s_proposals[i].voteCount;
                winningProposal_ = i;
            }
        }
    }

    function winningName() public view returns (bytes32 winningName_) {
        winningName_ = s_proposals[winningProposal()].name;
    }

    function getVotingState() public view returns (VotingStates) {
        return s_votingState;
    }

    function getVoterByAddress(address voter) public view returns (Voter memory) {
        return s_voters[voter];
    }

    function getProposals() public view returns (Proposal[] memory) {
        return s_proposals;
    }
}