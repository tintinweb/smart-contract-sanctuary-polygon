/**
 *Submitted for verification at polygonscan.com on 2023-03-31
*/

/** 
 *  SourceUnit: /Users/twy/Projects/union-contracts/contracts/governance/Governor.sol
*/
            
pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

interface IGovernor {
    /// @notice Ballot receipt record for a voter
    struct Receipt {
        /// @notice Whether or not a vote has been cast
        bool hasVoted;
        /// @notice Whether or not the voter supports the proposal
        uint8 support;
        /// @notice The number of votes the voter had, which were cast
        uint256 votes;
        string reason;
    }

    /// @notice Possible states that a proposal may be in
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    /// @notice An event emitted when a new proposal is created
    event ProposalCreated(
        uint256 id,
        address proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startBlock,
        uint256 endBlock,
        string description
    );

    event UnionTokenSet(address oldUnionToken, address newUnionToken);

    event TimelockSet(address oldTimelock, address newTimelock);

    event VotingDelaySet(uint256 oldVotingDelay, uint256 newVotingDelay);

    event VotingPeriodSet(uint256 oldVotingPeriod, uint256 newVotingPeriod);

    event ProposalThresholdSet(uint256 oldProposalThreshold, uint256 newProposalThreshold);

    /// @notice An event emitted when a vote has been cast on a proposal
    event VoteCast(address voter, uint256 proposalId, uint8 support, uint256 votes, string reason);

    /// @notice An event emitted when a proposal has been canceled
    event ProposalCanceled(uint256 id);

    /// @notice An event emitted when a proposal has been queued in the Timelock
    event ProposalQueued(uint256 id, uint256 eta);

    /// @notice An event emitted when a proposal has been executed in the Timelock
    event ProposalExecuted(uint256 id);

    /// @notice Emitted when pendingAdmin is changed
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /// @notice Emitted when pendingAdmin is accepted, which means admin is updated
    event NewAdmin(address oldAdmin, address newAdmin);

    function proposalCount() external returns (uint256);

    function setVotingPeriod(uint256 votingPeriod_) external;

    function propose(
        address[] calldata targets,
        uint256[] calldata values,
        string[] calldata signatures,
        bytes[] calldata calldatas,
        string calldata description
    ) external returns (uint256);

    function queue(uint256 proposalId) external;

    function execute(uint256 proposalId) external payable;

    function cancel(uint256 proposalId) external;

    function getActions(uint256 proposalId)
        external
        view
        returns (
            address[] memory,
            uint256[] memory,
            string[] memory,
            bytes[] memory
        );

    function getReceipt(uint256 proposalId, address voter) external view returns (Receipt memory);

    function state(uint256 proposalId) external view returns (ProposalState);

    function castVote(uint256 proposalId, uint8 support) external;

    function castVoteWithReason(
        uint256 proposalId,
        uint8 support,
        string calldata reason
    ) external;

    function castVoteBySig(
        uint256 proposalId,
        uint8 support,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}




/** 
 *  SourceUnit: /Users/twy/Projects/union-contracts/contracts/governance/Governor.sol
*/
            
pragma solidity 0.5.16;

/**
 * @title UnionToken Interface
 * @dev Mint and distribute UnionTokens.
 */
interface IUnionToken {
    //An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    //An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     *  @dev Get total supply
     *  @return Total supply
     */
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function mint(address account, uint256 amount) external returns (bool);

    /**
     *  @dev Determine the prior number of votes for an account as of a block number. Block number must be a finalized block or else this function will revert to prevent misinformation.
     *  @param account The address of the account to check
     *  @param blockNumber The block number to get the vote balance at
     *  @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint256);

    /**
     *  @dev Allows to spend owner's Union tokens by the specified spender.
     *  The function can be called by anyone, but requires having allowance parameters
     *  signed by the owner according to EIP712.
     *  @param owner The owner's address, cannot be zero address.
     *  @param spender The spender's address, cannot be zero address.
     *  @param value The allowance amount, in wei.
     *  @param deadline The allowance expiration date (unix timestamp in UTC).
     *  @param v A final byte of signature (ECDSA component).
     *  @param r The first 32 bytes of signature (ECDSA component).
     *  @param s The second 32 bytes of signature (ECDSA component).
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function burnFrom(address account, uint256 amount) external;
}




/** 
 *  SourceUnit: /Users/twy/Projects/union-contracts/contracts/governance/Governor.sol
*/
            
pragma solidity 0.5.16;

interface ITimelock {
    event NewAdmin(address indexed newAdmin);
    event NewPendingAdmin(address indexed newPendingAdmin);
    event NewDelay(uint256 indexed newDelay);
    event CancelTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );
    event ExecuteTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );
    event QueueTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );

    function delay() external view returns (uint256);

    function GRACE_PERIOD() external view returns (uint256);

    function acceptAdmin() external;

    function queuedTransactions(bytes32 hash) external view returns (bool);

    function queueTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta
    ) external returns (bytes32);

    function cancelTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta
    ) external;

    function executeTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta
    ) external payable returns (bytes memory);
}




/** 
 *  SourceUnit: /Users/twy/Projects/union-contracts/contracts/governance/Governor.sol
*/
            
pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}




/** 
 *  SourceUnit: /Users/twy/Projects/union-contracts/contracts/governance/Governor.sol
*/
            
pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


/** 
 *  SourceUnit: /Users/twy/Projects/union-contracts/contracts/governance/Governor.sol
*/


contract Governor is IGovernor, Initializable {
    using SafeMath for uint256;

    //The name of this contract
    string public constant name = "Union Governor";

    /// @notice The minimum setable proposal threshold
    uint256 public constant MIN_PROPOSAL_THRESHOLD = 50000e18; // 50,000 Union

    /// @notice The maximum setable proposal threshold
    uint256 public constant MAX_PROPOSAL_THRESHOLD = 100000e18; //100,000 Union

    /// @notice The minimum setable voting period
    uint256 public constant MIN_VOTING_PERIOD = 5760; // About 24 hours

    /// @notice The max setable voting period
    // uint256 public constant MAX_VOTING_PERIOD = 80640; // About 2 weeks on ethreum
    uint256 public constant MAX_VOTING_PERIOD = 604800; // About 2 weeks on polygon

    /// @notice The min setable voting delay
    uint256 public constant MIN_VOTING_DELAY = 1;

    /// @notice The max setable voting delay
    uint256 public constant MAX_VOTING_DELAY = 40320; // About 1 week

    /// @notice The maximum number of actions that can be included in a proposal
    uint256 public constant proposalMaxOperations = 10; // 10 actions

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the ballot struct used by the contract
    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,uint8 support)");

    //The delay before voting on a proposal may take place, once proposed
    uint256 public votingDelay;

    //The duration of voting on a proposal, in blocks
    uint256 public votingPeriod;

    //The total number of proposals
    uint256 public proposalCount;

    uint256 public proposalThreshold;

    struct Proposal {
        /// @notice Unique id for looking up a proposal
        uint256 id;
        /// @notice Creator of the proposal
        address proposer;
        /// @notice The timestamp that the proposal will be available for execution, set once the vote succeeds
        uint256 eta;
        /// @notice the ordered list of target addresses for calls to be made
        address[] targets;
        /// @notice The ordered list of values (i.e. msg.value) to be passed to the calls to be made
        uint256[] values;
        /// @notice The ordered list of function signatures to be called
        string[] signatures;
        /// @notice The ordered list of calldata to be passed to each call
        bytes[] calldatas;
        /// @notice The block at which voting begins: holders must delegate their votes prior to this block
        uint256 startBlock;
        /// @notice The block at which voting ends: votes must be cast prior to this block
        uint256 endBlock;
        /// @notice Current number of votes in favor of this proposal
        uint256 forVotes;
        /// @notice Current number of votes in opposition to this proposal
        uint256 againstVotes;
        /// @notice Current number of votes in abstain to this proposal
        uint256 abstainVotes;
        /// @notice Flag marking whether the proposal has been canceled
        bool canceled;
        /// @notice Flag marking whether the proposal has been executed
        bool executed;
        /// @notice Receipts of ballots for the entire set of voters
        mapping(address => Receipt) receipts;
    }

    /// @notice The official record of all proposals ever proposed
    mapping(uint256 => Proposal) public proposals;

    /// @notice The latest proposal for each proposer
    mapping(address => uint256) public latestProposalIds;

    address public unionToken;

    address public timelock;

    address public pendingAdmin;

    address public admin;

    /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
    function quorumVotes() public view returns (uint256) {
        return IUnionToken(unionToken).totalSupply().mul(4e16).div(1e18);
    } // 4% of UnionToken totalSupply

    function initialize(
        address _unionToken,
        address _timelock,
        uint256 _votingPeriod,
        uint256 _votingDelay,
        uint256 _proposalThreshold
    ) public initializer {
        require(_timelock != address(0), "Governor: invalid timelock address");
        require(_unionToken != address(0), "Governor: invalid unionToken address");
        require(
            _votingPeriod >= MIN_VOTING_PERIOD && _votingPeriod <= MAX_VOTING_PERIOD,
            "Governor: invalid voting period"
        );
        require(_votingDelay >= MIN_VOTING_DELAY && _votingDelay <= MAX_VOTING_DELAY, "Governor: invalid voting delay");
        require(
            _proposalThreshold >= MIN_PROPOSAL_THRESHOLD && _proposalThreshold <= MAX_PROPOSAL_THRESHOLD,
            "Governor: invalid proposal threshold"
        );

        admin = msg.sender;
        timelock = _timelock;
        unionToken = _unionToken;
        votingPeriod = _votingPeriod;
        votingDelay = _votingDelay;
        proposalThreshold = _proposalThreshold;
    }

    /*
     * @notice Set voting delay
     * @param votingDelay_ New delay
     */
    function setVotingDelay(uint256 votingDelay_) external {
        require(msg.sender == admin, "Governor: admin only");
        require(votingDelay_ >= MIN_VOTING_DELAY && votingDelay_ <= MAX_VOTING_DELAY, "Governor: invalid voting delay");
        uint256 oldVotingDelay = votingDelay;
        votingDelay = votingDelay_;

        emit VotingDelaySet(oldVotingDelay, votingDelay);
    }

    /*
     * @notice Set voting period
     * @param votingPeriod_ New period
     */
    function setVotingPeriod(uint256 votingPeriod_) external {
        require(msg.sender == admin, "Governor: admin only");
        require(
            votingPeriod_ >= MIN_VOTING_PERIOD && votingPeriod_ <= MAX_VOTING_PERIOD,
            "Governor: invalid voting period"
        );
        uint256 oldVotingPeriod = votingPeriod;
        votingPeriod = votingPeriod_;

        emit VotingPeriodSet(oldVotingPeriod, votingPeriod);
    }

    /*
     * @notice Set proposal threshold
     * @param proposalThereshold_ New threshold
     */
    function setProposalThreshold(uint256 proposalThereshold_) external {
        require(msg.sender == admin, "Governor: admin only");
        require(
            proposalThereshold_ >= MIN_PROPOSAL_THRESHOLD && proposalThereshold_ <= MAX_PROPOSAL_THRESHOLD,
            "Governor: new threshold below min"
        );
        uint256 oldProposalThreshold = proposalThreshold;
        proposalThreshold = proposalThereshold_;

        emit ProposalThresholdSet(oldProposalThreshold, proposalThreshold);
    }

    /*
     * @notice Create a proposal
     * @param targets Proposal execution target address
     * @param values Eth required for proposal execution
     * @param signatures The name of the method called
     * @param calldatas Call parameters
     * @param description Proposal notes
     * @return Proposal id
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) public returns (uint256) {
        require(
            IUnionToken(unionToken).getPriorVotes(msg.sender, block.number.sub(1)) > proposalThreshold,
            "Governor: proposer votes below proposal threshold"
        );

        require(
            targets.length == values.length &&
                targets.length == signatures.length &&
                targets.length == calldatas.length,
            "Governor: proposal function information parity mismatch"
        );
        require(targets.length != 0, "Governor: must provide actions");
        require(targets.length <= proposalMaxOperations, "Governor: too many actions");

        uint256 latestProposalId = latestProposalIds[msg.sender];
        if (latestProposalId != 0) {
            ProposalState proposersLatestProposalState = state(latestProposalId);
            require(
                proposersLatestProposalState != ProposalState.Active,
                "Governor: one live proposal per proposer, found an already active proposal"
            );
            require(
                proposersLatestProposalState != ProposalState.Pending,
                "Governor: one live proposal per proposer, found an already pending proposal"
            );
        }

        uint256 startBlock = block.number.add(votingDelay);
        uint256 endBlock = startBlock.add(votingPeriod);

        proposalCount++;
        Proposal memory newProposal = Proposal({
            id: proposalCount,
            proposer: msg.sender,
            eta: 0,
            targets: targets,
            values: values,
            signatures: signatures,
            calldatas: calldatas,
            startBlock: startBlock,
            endBlock: endBlock,
            forVotes: 0,
            againstVotes: 0,
            abstainVotes: 0,
            canceled: false,
            executed: false
        });

        proposals[newProposal.id] = newProposal;
        latestProposalIds[newProposal.proposer] = newProposal.id;

        emit ProposalCreated(
            newProposal.id,
            msg.sender,
            targets,
            values,
            signatures,
            calldatas,
            startBlock,
            endBlock,
            description
        );
        return newProposal.id;
    }

    /*
     * @notice Queues a proposal of state succeeded
     * @param proposalId The id of the proposal to execute
     */
    function queue(uint256 proposalId) public {
        require(
            state(proposalId) == ProposalState.Succeeded,
            "Governor: proposal can only be queued if it is succeeded"
        );
        Proposal storage proposal = proposals[proposalId];
        uint256 eta = block.timestamp.add(ITimelock(timelock).delay());
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            _queueOrRevert(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], eta);
        }
        proposal.eta = eta;
        emit ProposalQueued(proposalId, eta);
    }

    function _queueOrRevert(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) internal {
        require(
            !ITimelock(timelock).queuedTransactions(keccak256(abi.encode(target, value, signature, data, eta))),
            "Governor: proposal action already queued at eta"
        );
        ITimelock(timelock).queueTransaction(target, value, signature, data, eta);
    }

    /*
     * @notice Executes a queued proposal if eta has passed
     * @param proposalId The id of the proposal to execute
     */
    function execute(uint256 proposalId) public payable {
        require(state(proposalId) == ProposalState.Queued, "Governor: proposal can only be executed if it is queued");
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            ITimelock(timelock).executeTransaction.value(proposal.values[i])(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.eta
            );
        }
        emit ProposalExecuted(proposalId);
    }

    /*
     * @notice Cancel a proposal if proposal not executed and caller is
     * @param proposalId The id of the proposal to execute
     */
    function cancel(uint256 proposalId) public {
        ProposalState state = state(proposalId);
        require(state != ProposalState.Executed, "Governor: cannot cancel executed proposal");

        Proposal storage proposal = proposals[proposalId];
        require(
            msg.sender == proposal.proposer ||
                IUnionToken(unionToken).getPriorVotes(proposal.proposer, block.number.sub(1)) < proposalThreshold,
            "Governor: proposer above threshold"
        );

        proposal.canceled = true;
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            ITimelock(timelock).cancelTransaction(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.eta
            );
        }

        emit ProposalCanceled(proposalId);
    }

    /*
     * @notice Gets actions of a proposal
     * @param proposalId the id of the proposal
     * @return Targets, values, signatures, and calldatas of the proposal actions
     */
    function getActions(uint256 proposalId)
        public
        view
        returns (
            address[] memory targets,
            uint256[] memory values,
            string[] memory signatures,
            bytes[] memory calldatas
        )
    {
        Proposal storage p = proposals[proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    /**
     * @notice Gets the receipt for a voter on a given proposal
     * @param proposalId the id of proposal
     * @param voter The address of the voter
     * @return The voting receipt
     */
    function getReceipt(uint256 proposalId, address voter) public view returns (Receipt memory) {
        return proposals[proposalId].receipts[voter];
    }

    /**
     * @notice Gets the state of a proposal
     * @param proposalId The id of the proposal
     * @return Proposal state
     */
    function state(uint256 proposalId) public view returns (ProposalState) {
        require(proposalCount >= proposalId && proposalId > 0, "Governor: invalid proposal id");
        Proposal storage proposal = proposals[proposalId];
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < quorumVotes()) {
            return ProposalState.Defeated;
        } else if (proposal.eta == 0) {
            return ProposalState.Succeeded;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp >= proposal.eta.add(ITimelock(timelock).GRACE_PERIOD())) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }

    /**
     * @notice Cast a vote for a proposal
     * @param proposalId The id of the proposal to vote on
     * @param support The support value for the vote. 0=against, 1=for, 2=abstain
     */
    function castVote(uint256 proposalId, uint8 support) external {
        return _castVote(msg.sender, proposalId, support, "");
    }

    /**
     * @notice Cast a vote for a proposal
     * @param proposalId The id of the proposal to vote on
     * @param support The support value for the vote. 0=against, 1=for, 2=abstain
     * @param reason A string giving a reason for the user's vote. If not needed, should be an empty string.
     */
    function castVoteWithReason(
        uint256 proposalId,
        uint8 support,
        string calldata reason
    ) external {
        return _castVote(msg.sender, proposalId, support, reason);
    }

    function castVoteBySig(
        uint256 proposalId,
        uint8 support,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        bytes32 domainSeparator = keccak256(
            abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this))
        );
        bytes32 structHash = keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert("Governor: invalid signature 's' value");
        }

        if (v != 27 && v != 28) {
            revert("Governor: invalid signature 'v' value");
        }
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "Governor: invalid signature");
        return _castVote(signatory, proposalId, support, "");
    }

    function _castVote(
        address voter,
        uint256 proposalId,
        uint8 support,
        string memory reason
    ) internal {
        require(state(proposalId) == ProposalState.Active, "Governor: voting is closed");
        require(support <= 2, "Governor: invalid vote type");
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[voter];
        require(receipt.hasVoted == false, "Governor: voter already voted");
        uint256 votes = IUnionToken(unionToken).getPriorVotes(voter, proposal.startBlock);

        if (support == 0) {
            proposal.againstVotes = proposal.againstVotes.add(votes);
        } else if (support == 1) {
            proposal.forVotes = proposal.forVotes.add(votes);
        } else if (support == 2) {
            proposal.abstainVotes = proposal.abstainVotes.add(votes);
        }

        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;

        if (bytes(reason).length != 0) {
            receipt.reason = reason;
        }

        emit VoteCast(voter, proposalId, support, votes, reason);
    }

    /**
     * @notice Begins transfer of admin rights. The newPendingAdmin must call `acceptAdmin` to finalize the transfer.
     * @dev Admin function to begin change of admin. The newPendingAdmin must call `acceptAdmin` to finalize the transfer.
     * @param newPendingAdmin New pending admin.
     */
    function setPendingAdmin(address newPendingAdmin) external {
        // Check caller = admin
        require(msg.sender == admin, "Governor: admin only");

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    /**
     * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
     * @dev Admin function for pending admin to accept role and update admin
     */
    function acceptAdmin() external {
        // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
        require(msg.sender == pendingAdmin && msg.sender != address(0), "Governor: pending admin only");

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }

    /**
     * @notice Initiate the Governor contract
     * @dev Admin only. Sets initial proposal id which initiates the contract, ensuring a continuous proposal id count
     * @param governorOld The address for the Governor to continue the proposal id count from
     */
    function initiate(address governorOld) external {
        require(msg.sender == admin, "Governor: admin only");
        require(proposalCount == 0, "Governor: can only initiate once");
        proposalCount = IGovernor(governorOld).proposalCount();
        ITimelock(timelock).acceptAdmin();
    }

    function getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}