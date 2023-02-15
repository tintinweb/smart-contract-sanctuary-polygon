/**
 *Submitted for verification at polygonscan.com on 2023-02-15
*/

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


contract XMetricVoter {
    enum VoteType {
        None,
        Yes,
        No
    }
    enum ProposalStatus {
        None,
        Accepted,
        Rejected
    }

    struct Proposal {
        mapping(VoteType => uint256) voteCounts;
        bytes32 contentHash;
        address submitter;
        uint64 deadline;
        ProposalStatus status;
    }
    struct Vote {
        VoteType voteType;
        uint256 amount;
    }

    error InsufficientBalance(uint256 requiredBalance, uint256 actualBalance);
    error InvalidVoteType();
    error AlreadyVotedFor(VoteType voteType, uint256 amount);
    error VotingEnded(
        uint256 votingDeadlineTimestamp,
        uint256 currentTimestamp
    );
    error InvalidProposalId(uint32 proposalId);

    event ProposalSubmitted(uint32 indexed proposalId);
    event VoteSubmitted(
        uint32 indexed proposalId,
        address indexed voter,
        VoteType voteType,
        uint256 amount
    );
    event VoteUpdated(
        uint32 indexed proposalId,
        address indexed voter,
        VoteType previousVoteType,
        VoteType currentVoteType,
        uint256 previousAmount,
        uint256 currentAmount
    );

    IERC20 public immutable xMETRIC;

    uint32 public proposalCount;

    uint256 public MinimumSubmissionBalance;
    uint64 public MaximumVotingDuration;

    uint8 public QorumPercentage;

    mapping(uint32 => Proposal) public Proposals;
    mapping(uint32 => mapping(address => Vote)) public Votes;

    constructor(
        IERC20 xmetric,
        uint256 minimumSubmissionBalance,
        uint64 maximumVotingDuration,
        uint8 quorumPercentage
    ) {
        require(quorumPercentage >= 1 && quorumPercentage <= 100);

        xMETRIC = xmetric;
        MinimumSubmissionBalance = minimumSubmissionBalance;
        MaximumVotingDuration = maximumVotingDuration;
        QorumPercentage = quorumPercentage;
    }

    modifier requireBalance(uint256 requiredBalance) {
        uint256 actualBalance = xMETRIC.balanceOf(msg.sender);

        if (actualBalance < requiredBalance) {
            revert InsufficientBalance(requiredBalance, actualBalance);
        }
        _;
    }

    function getProposalVotes(uint32 proposalId, VoteType voteType)
        external
        view
        returns (uint256)
    {
        return Proposals[proposalId].voteCounts[voteType];
    }

    function submitProposal(bytes32 contentHash)
        external
        requireBalance(MinimumSubmissionBalance)
        returns (uint32)
    {
        proposalCount += 1;

        Proposals[proposalCount].contentHash = contentHash;
        Proposals[proposalCount].submitter = msg.sender;
        Proposals[proposalCount].deadline =
            uint64(block.timestamp) +
            MaximumVotingDuration;
        Proposals[proposalCount].status = ProposalStatus.None;

        emit ProposalSubmitted(proposalCount);
        return proposalCount;
    }

    function submitVote(uint32 proposalId, VoteType voteType)
        external
        requireBalance(1)
    {
        if (voteType == VoteType.None) {
            revert InvalidVoteType();
        }
        if (block.timestamp > Proposals[proposalId].deadline) {
            revert VotingEnded(Proposals[proposalId].deadline, block.timestamp);
        }
        if (proposalId == 0 || proposalId > proposalCount) {
            revert InvalidProposalId(proposalId);
        }

        Vote memory previousVote = Votes[proposalId][msg.sender];
        uint256 currentBalance = xMETRIC.balanceOf(msg.sender);

        if (
            previousVote.voteType == voteType &&
            currentBalance == previousVote.amount
        ) {
            revert AlreadyVotedFor(voteType, currentBalance);
        }

        Proposals[proposalId].voteCounts[voteType] += currentBalance;
        Proposals[proposalId].voteCounts[previousVote.voteType] -= previousVote
            .amount;

        Votes[proposalId][msg.sender] = Vote({
            voteType: voteType,
            amount: currentBalance
        });

        uint256 minimumVotes = (xMETRIC.totalSupply() * QorumPercentage) / 100;
        uint256 yesVotes = Proposals[proposalId].voteCounts[VoteType.Yes];
        uint256 noVotes = Proposals[proposalId].voteCounts[VoteType.No];

        if ((yesVotes + noVotes) >= minimumVotes) {
            if (yesVotes > noVotes) {
                Proposals[proposalId].status = ProposalStatus.Accepted;
            } else {
                Proposals[proposalId].status = ProposalStatus.Rejected;
            }
        } else {
            Proposals[proposalId].status = ProposalStatus.None;
        }

        if (previousVote.voteType == VoteType.None) {
            emit VoteSubmitted(
                proposalId,
                msg.sender,
                voteType,
                currentBalance
            );
        } else {
            emit VoteUpdated(
                proposalId,
                msg.sender,
                previousVote.voteType,
                voteType,
                previousVote.amount,
                currentBalance
            );
        }
    }
}