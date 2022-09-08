/**
 *Submitted for verification at polygonscan.com on 2022-09-07
*/

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.12;

error RoundStateIncorrect(uint tournamentId, RoundState expected, RoundState actual);
error ReentrancePrevented(address attacker);
error TaxTooHigh(uint attemptedTax);
error TaxManOnly(address notTaxMan);
error OnlyOwner(address notOwner, address owner);
error TooEarlyToConfirm(uint tournamentId, uint roundId, uint currentRoundId);
error TournamentNotStarted(uint tournamentId);
error MustConfirmPreviousRound(uint tournamentId, uint roundId);
error MustOwnIdentityToVote(uint tournamentId, uint voterId, address voter, address owner);
error CanOnlyVoteOncePerRound(uint tournamentId, uint voterId);
error MismatchedArrayLengths(uint a, uint b);
error TournamentNeedsFunding(uint tournamentId, uint assets, uint liabilities);
error MustPayToVote(uint tournamentId, uint cost, uint paid);
error SpentTooManyVoiceCredits(uint tournamentId, uint spent);
error NothingToWithdraw(uint tournamentId, uint voterId);
error RoundAlreadyChallenged(uint tournamentId, uint roundId);
error RedundantChallenge(uint tournamentId, uint roundId);
error ChallengePeriodPassed(uint tournamentId, uint roundId);
error ChallengePeriodNotPassed(uint tournamentId, uint roundId);
error ChallengeDepositNotMet(uint tournamentId, uint roundId);
error RoundAlreadyConfirmed(uint tournamentId, uint roundId);
error MustAddressChallenger(uint tournamentId, uint roundId);
error WinnerUnchallenged(uint tournamentId, uint roundId);
error BadWinnerIndex(uint tournamentId, uint index);
error WinnerAlreadyProposed(uint tournamentId);
error RoundNotReadyToConfirm(uint tournamentId, uint roundId);
error FeedNotSet(uint tournamentId, bytes32 key);
error StartPricesAlreadySet(uint tournamentId, uint roundId);
error OracleNotSet(uint tournamentId);
error SetPricesFirst(uint tournamentId);

/**
    Votes are a mapping from choices to weights, plus a metadataHash, which references an arbitrary bit of metadata
    stored on IPFS. The meaning of these choices is not stored on chain, only the index. For example, if  the choices
    are ["BTC", "ETH", "DASH"],  and the user  wants to put 3 votes on BTC, 5 votes on ETH and 4 on DASH, then this
    will be recorded as weights[1]  = 3; weights[2]  = 5; weights[3] = 4; The choices are indexed starting on 1 to
    prevent confusion caused by empty votes.
**/
struct Vote {
    bytes32 metadataHash;
    uint[] choices;
    mapping(uint => uint) weights;
}

enum RoundState {
    UNDEFINED,
    VOTING,
    MARKET,
    CHALLENGE,
    COMPLETE
}

enum KeeperAction {
    CONFIRM,
    GET_STARTING_PRICES,
    GET_FINAL_PRICES
}

/**
    Rounds occur with some frequency and represent a complete cycle of prediction->resolution. Each round has an id,
    which represents it's location in a linear sequence of rounds of the same type. It stores a mapping of voter
    ids to votes and records the winning option when the round is resolved.
**/
struct Round {
    uint roundId;
    uint finalWinnerIndex;
    uint proposedWinnerIndex;
    uint challengeWinnerIndex;
    bool confirmed;
    address challenger;
    bytes32 challengeEvidence;
    bytes32 confirmationEvidence;
    int[] startingPrices;
    int[] proposedFinalPrices;
    int[] finalPrices;
    bytes32[] tickerSymbols;
    address[] priceFeeds;
    uint roundRewardTokens;
    uint voteCostTokens;
    mapping (uint => Vote) votes;
    mapping (uint => uint) voteTotals;
}

/**
    A tournament is a linear sequence of rounds of the same type. Tournaments are identified by an integer that
    increases sequentially with each tournament. Tournaments also have hash for storing off-chain metadata about the
    tournament. A tournament has a set wavelength and phase, called roundLengthSeconds and startDate, respectively. Each
    tournament also has it's own set of voice credits, which is a mapping from address to balance. The rounds
    mapping takes a round id and spits out a Round struct. The roundRewardTokens attribute describes how much Token to be
    distributed to the voters each round.
**/
struct Tournament {
    uint tournamentId;
    uint startTime;
    uint votingPeriodLengthSeconds;
    uint marketPeriodLengthSeconds;
    uint challengePeriodLengthSeconds;
    uint roundRewardTokens;
    uint voteCostTokens;
    uint rewardFunding;
    uint rewardsOwed;
    uint voiceUBI;   // number of voice credits available to spend each round
    uint roundToConfirm;
    uint tax;
    uint voteTokensAccumulated;
    IERC20 voteToken;
    IERC20 rewardToken;
    IERC721 identity;
    Oracle oracle;
    address owner;
    address taxMan;
    mapping (uint => Round) rounds;
    mapping (uint => uint) lastRoundVoted;
    mapping (uint => uint) lastRoundSynced;
    mapping (uint => uint) tokensWon;
}

struct Oracle {
    uint challengeDepositCostTokens;
    IERC20 challengeToken;
    bytes32[] currentTickerSymbols;
    address[] currentPriceFeeds;
}


library OracleLib {

    int constant public PRECISION = 1000000;

    function getLivePrices(Tournament storage tournament) public view returns (int[] memory) {
        Oracle storage oracle = tournament.oracle;
        uint arrayLength = oracle.currentTickerSymbols.length;
        int[] memory pricesLocal = new int[](arrayLength);
        for (uint i; i < arrayLength; ++i) {

            address feedAddr = oracle.currentPriceFeeds[i];
            if (feedAddr == address(0)) {
                revert FeedNotSet(tournament.tournamentId, oracle.currentTickerSymbols[i]);
            }
            AggregatorV3Interface chainlink = AggregatorV3Interface(feedAddr);
            (,int256 priceNow,,,) = chainlink.latestRoundData();
            pricesLocal[i] = priceNow;
        }
        return pricesLocal;
    }

    function getWinner(Tournament storage tournament) public view returns (uint) {
        int256 maxPriceDiff = -1 * PRECISION;
        uint winnerIndex;
        Round storage round = tournament.rounds[tournament.roundToConfirm];
        Oracle storage oracle = tournament.oracle;
        uint arrayLength = oracle.currentTickerSymbols.length;
        for (uint i; i < arrayLength; ++i) {
            bytes32 key = round.tickerSymbols[i];
            int priceBefore = round.startingPrices[i];
            int256 priceDiff = ((round.proposedFinalPrices[i] - priceBefore) * PRECISION) / priceBefore;
            if (priceDiff > maxPriceDiff) {
                maxPriceDiff = priceDiff;
                // 1 based indexing
                winnerIndex = i + 1;
            }
        }
        return winnerIndex;
    }

    // this computes the id of the current round for a given tournament, starting with round 1 on the startTime
    function getCurrentRoundId(Tournament storage tournament) public view returns (uint) {
        uint startTime = tournament.startTime;
        uint roundLengthSeconds = tournament.votingPeriodLengthSeconds + tournament.marketPeriodLengthSeconds + tournament.challengePeriodLengthSeconds;
        if (block.timestamp >= startTime) {
            return 1 + ((block.timestamp - startTime) / roundLengthSeconds);
        } else {
            return 0;
        }
    }

}


interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

interface KeeperCompatibleInterface {

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
  function checkUpkeep(
    bytes calldata checkData
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData
    );
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
  function performUpkeep(
    bytes calldata performData
  ) external;
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

contract PermissionlessMarkets is KeeperCompatibleInterface {
    using OracleLib for Tournament;

    uint public immutable MAX_TAX = 100;
    uint public globalTaxPerCapita;
    address public taxMan;
    uint public numTournaments; // a counter to know what index to assign to new tournaments

    mapping (uint => Tournament) tournaments; // mapping from tournament id to tournament struct
    mapping (uint => mapping (uint => uint[])) votesByVoterId;

    // events for consumption by off chain systems
    event VoteOccurred(uint indexed tournamentId, uint indexed roundId, uint indexed voterId, uint[] choices, uint[] weights, bytes32 metadata);
    event RoundConfirmed(uint indexed tournamentId, uint roundId, uint winningChoice);
    event TournamentCreated(address indexed rewardToken, address indexed voteToken, uint tournamentId, uint startTime, uint votingPeriodLengthSeconds, uint marketPeriodLengthSeconds, uint roundRewardTokens, uint voiceUBI);

    // winner events
    event WinnerProposed(uint indexed tournamentId, uint indexed roundId, uint winnerIndex, int[] prices);
    event WinnerConfirmed(uint indexed tournamentId, uint indexed roundId, int[] prices);

    // challenger events
    event ChallengeMade(uint indexed tournamentId, uint indexed roundId, address indexed challenger, uint claimedWinner, bytes32 evidence);
    event ChallengerSlashed(uint indexed tournamentId, uint indexed roundId, address indexed challenger, uint slashAmount, bytes32 evidence);
    event ChallengerVindicated(uint indexed tournamentId, uint indexed roundId, address indexed challenger, bytes32 evidence);


    uint private unlocked = 1;
    modifier lock() {
        if (unlocked != 1) {
            revert ReentrancePrevented(msg.sender);
        }
        unlocked = 0;
        _;
        unlocked = 1;
    }

    modifier stateRequired(uint tournamentId, RoundState expected) {
        RoundState actual = getCurrentRoundState(tournamentId);
        if (actual != expected) {
            revert RoundStateIncorrect(tournamentId, expected, actual);
        }
        _;
    }

    constructor(address _taxMan, uint _globalTaxPerCapita) {
        if (_globalTaxPerCapita > MAX_TAX) {
            revert TaxTooHigh(_globalTaxPerCapita);
        }
        globalTaxPerCapita = _globalTaxPerCapita;
        taxMan = _taxMan;
    }

    function setTax(uint newTax, address newTaxMan) external {
        if (msg.sender != taxMan) {
            revert TaxManOnly(msg.sender);
        }
        if (newTax > MAX_TAX) {
            revert TaxTooHigh(newTax);
        }
        globalTaxPerCapita = newTax;
        taxMan = newTaxMan;
    }


    // this function creates a new tournament type, only management can call it
    function createTournament(
        uint startTime,
        uint votingPeriodLengthSeconds,
        uint marketPeriodLengthSeconds,
        uint challengePeriodLengthSeconds,
        uint roundRewardTokens,
        uint voteCostTokens,
        uint voiceUBI,
        address owner,
        address rewardToken,
        address voteToken,
        address identity) external {
        {
            Tournament storage tournament = tournaments[++numTournaments];
            tournament.startTime = startTime == 0 ? block.timestamp : startTime;
            tournament.tournamentId = numTournaments;
            tournament.votingPeriodLengthSeconds = votingPeriodLengthSeconds;
            tournament.marketPeriodLengthSeconds = marketPeriodLengthSeconds;
            tournament.challengePeriodLengthSeconds = challengePeriodLengthSeconds;
            tournament.roundRewardTokens = roundRewardTokens;
            tournament.voiceUBI = voiceUBI;
            tournament.voteCostTokens = voteCostTokens;
            tournament.owner = owner;
            tournament.rewardToken = IERC20(rewardToken);
            tournament.voteToken = IERC20(voteToken);
            tournament.identity = IERC721(identity);
            tournament.tax = globalTaxPerCapita;
            tournament.taxMan = taxMan;
            tournament.roundToConfirm = 1;
        }
        emit TournamentCreated(rewardToken, voteToken, numTournaments, startTime, votingPeriodLengthSeconds, marketPeriodLengthSeconds, roundRewardTokens, voiceUBI);
    }

    function setOracle(
        uint tournamentId,
        uint challengeDepositCostTokens,
        address challengeToken,
        bytes32[] calldata tickerSymbols,
        address[] calldata priceFeeds) external {
        Tournament storage tournament = tournaments[tournamentId];
        if (msg.sender != tournament.owner) {
            revert OnlyOwner(msg.sender, tournament.owner);
        }

        RoundState state = getCurrentRoundState(tournamentId);
        if (state != RoundState.CHALLENGE && state != RoundState.UNDEFINED) {
            revert RoundStateIncorrect(tournamentId, RoundState.CHALLENGE, state);
        }

        Round storage round = tournament.rounds[tournament.roundToConfirm];
        if (state != RoundState.UNDEFINED) {
            if (round.proposedFinalPrices.length == 0 || round.startingPrices.length == 0) {
                revert SetPricesFirst(tournamentId);
            }
        }

        Oracle storage oracle = tournament.oracle;
        oracle.challengeDepositCostTokens = challengeDepositCostTokens;
        oracle.challengeToken = IERC20(challengeToken);
        oracle.currentTickerSymbols = tickerSymbols;
        oracle.currentPriceFeeds = priceFeeds;
    }

    function setCostRewards(
        uint tournamentId,
        uint roundRewardTokens,
        uint voteCostTokens) external {
        Tournament storage tournament = tournaments[tournamentId];
        if (msg.sender != tournament.owner) {
            revert OnlyOwner(msg.sender, tournament.owner);
        }

        RoundState state = getCurrentRoundState(tournamentId);
        if (state != RoundState.CHALLENGE && state != RoundState.UNDEFINED) {
            revert RoundStateIncorrect(tournamentId, RoundState.CHALLENGE, state);
        }

        Round storage round = tournament.rounds[tournament.roundToConfirm];
        if (state != RoundState.UNDEFINED) {
            if (round.proposedFinalPrices.length == 0 || round.startingPrices.length == 0) {
                revert SetPricesFirst(tournamentId);
            }
        }
        tournament.roundRewardTokens = roundRewardTokens;
        tournament.voteCostTokens = voteCostTokens;
    }

    // this is called by an identity that wishes to vote on a given tournament, with the choices and weights
    function vote(
        uint voterId,
        uint tournamentId,
        uint[] memory choices,
        uint[] memory weights,
        uint votePayment,
        bytes32 hash
    ) external stateRequired(tournamentId, RoundState.VOTING) {
        Tournament storage tournament = tournaments[tournamentId];
        uint roundId = tournament.getCurrentRoundId();
        Round storage currentRound = tournament.rounds[roundId];
        // scoping to limit stack depth
        {
            if (tournament.oracle.currentTickerSymbols.length == 0) {
                revert OracleNotSet(tournamentId);
            }

            if (currentRound.roundId == 0) {
                currentRound.roundId = roundId;
                currentRound.roundRewardTokens = tournament.roundRewardTokens;
                currentRound.voteCostTokens = tournament.voteCostTokens;
            }

            if (currentRound.tickerSymbols.length == 0) {
                currentRound.tickerSymbols = tournament.oracle.currentTickerSymbols;
                currentRound.priceFeeds = tournament.oracle.currentPriceFeeds;
            }

            uint lastRoundVoted = tournament.lastRoundVoted[voterId];
            if (roundId != 1 && tournament.rounds[roundId - 1].confirmed == false) {
                revert MustConfirmPreviousRound(tournamentId, roundId);
            }

            address voter = tournament.identity.ownerOf(voterId);
            if (voter != msg.sender) {
                revert MustOwnIdentityToVote(tournamentId, voterId, msg.sender, voter);
            }
            if (roundId == lastRoundVoted) {
                revert CanOnlyVoteOncePerRound(tournamentId, voterId);
            }
            if (choices.length != weights.length) {
                revert MismatchedArrayLengths(choices.length, weights.length);
            }
            // look at assets - liabilities to assess whether tournament is funded enough to allow voting
            uint liabilities = tournament.rewardsOwed + tournament.roundRewardTokens;
            if (tournament.rewardFunding < liabilities) {
                revert TournamentNeedsFunding(tournamentId, tournament.rewardFunding, liabilities);
            }

            uint transferred = transferPossiblyMalicious(tournament.voteToken, msg.sender, address(this), votePayment);
            tournament.voteTokensAccumulated += transferred;
            if (transferred < tournament.voteCostTokens) {
                revert MustPayToVote(tournamentId, tournament.voteCostTokens, transferred);
            }
        }

        // check if lastRoundVoted was possibly synced by a withdrawal first
        maybeUpdateAccount(voterId, tournamentId);

        // do this after updating account
        tournament.lastRoundVoted[voterId] = roundId;

        {
            Vote storage currentVote = currentRound.votes[voterId];
            currentVote.metadataHash = hash;
            currentVote.choices = choices;
            uint sum;

            for (uint i = 0; i < weights.length; i++) {
                currentRound.voteTotals[choices[i]] += weights[i];
                currentVote.weights[choices[i]] = weights[i];
                sum += (weights[i] * weights[i]);
            }
            if (sum > tournament.voiceUBI) {
                revert SpentTooManyVoiceCredits(tournamentId, sum);
            }
        }
        votesByVoterId[voterId][tournamentId].push(roundId);

        emit VoteOccurred(tournamentId, roundId, voterId, choices, weights, hash);
    }

    function fundTournament(uint tournamentId, uint amount) external {
        Tournament storage tournament = tournaments[numTournaments];
        uint transferred = transferPossiblyMalicious(tournament.rewardToken, msg.sender, address(this), amount);
        tournament.rewardFunding += transferred;
    }

    function withdrawFees(uint tournamentId) external {
        Tournament storage tournament = tournaments[numTournaments];
        uint tax = tournament.voteTokensAccumulated * tournament.tax / 1000;
        uint toOwner = tournament.voteTokensAccumulated - tax;
        uint transferred1 = transferPossiblyMalicious(tournament.voteToken, address(this), tournament.taxMan, tax);
        uint transferred2 = transferPossiblyMalicious(tournament.voteToken, address(this), tournament.owner, toOwner);
        tournament.voteTokensAccumulated -= (transferred1 + transferred2);
    }

/**
====================================== Winner ==========================================================
**/

    function setStartPrices(uint tournamentId) public {
        Tournament storage tournament = tournaments[tournamentId];
        Round storage round = tournament.rounds[tournament.roundToConfirm];
        if (round.startingPrices.length > 0) {
            revert StartPricesAlreadySet(tournamentId, round.roundId);
        }
        // in case ticker symbols changed and no one voted
        if (round.tickerSymbols.length == 0) {
            round.tickerSymbols = tournament.oracle.currentTickerSymbols;
            round.priceFeeds = tournament.oracle.currentPriceFeeds;
        }

        RoundState state = getRoundState(tournamentId, tournament.roundToConfirm);
        if (state < RoundState.MARKET) {
            revert RoundStateIncorrect(tournamentId, RoundState.MARKET, state);
        }

        round.startingPrices = tournament.getLivePrices();
    }

    function setFinalPrices(uint tournamentId) public {
        Tournament storage tournament = tournaments[tournamentId];
        Round storage round = tournament.rounds[tournament.roundToConfirm];
        if (round.proposedWinnerIndex > 0) {
            revert WinnerAlreadyProposed(tournamentId);
        }

        RoundState state = getRoundState(tournamentId, tournament.roundToConfirm);
        if (state < RoundState.CHALLENGE) {
            revert RoundStateIncorrect(tournamentId, RoundState.CHALLENGE, state);
        }
        // just in case no one voted, so the round id hasn't been set yet
        if (round.roundId == 0) {
            round.roundId = tournament.roundToConfirm;
            round.roundRewardTokens = tournament.roundRewardTokens;
            round.voteCostTokens = tournament.voteCostTokens;
        }
        round.proposedFinalPrices = tournament.getLivePrices();
        round.proposedWinnerIndex = tournament.getWinner();
        emit WinnerProposed(tournamentId, tournament.roundToConfirm, round.proposedWinnerIndex, round.finalPrices);
    }

    function withdrawWinnings(uint tournamentId, uint voterId) external {
        Tournament storage tournament = tournaments[tournamentId];

        maybeUpdateAccount(voterId, tournamentId);

        uint winnings = tournament.tokensWon[voterId];
        if (winnings == 0) {
            revert NothingToWithdraw(tournamentId, voterId);
        }

        address owner = tournament.identity.ownerOf(voterId);
        uint diff = transferPossiblyMalicious(tournament.rewardToken, address(this), owner, winnings);

        tournament.tokensWon[voterId] -= diff;
        tournament.rewardsOwed -= diff;
        tournament.rewardFunding -= diff;
    }

    function challengeWinner(
        uint tournamentId,
        uint claimedWinner,
        bytes32 evidence,
        uint challengeDeposit) external stateRequired(tournamentId, RoundState.CHALLENGE) {
        Tournament storage tournament = tournaments[tournamentId];
        Round storage round = tournament.rounds[tournament.roundToConfirm];
        Oracle storage oracle = tournament.oracle;

        if (round.challenger != address(0)) {
            revert RoundAlreadyChallenged(tournamentId, round.roundId);
        }
        if (claimedWinner == round.proposedWinnerIndex) {
            revert RedundantChallenge(tournamentId, round.roundId);
        }

        round.challenger = msg.sender;
        round.challengeWinnerIndex = claimedWinner;
        round.challengeEvidence = evidence;

        uint diff = transferPossiblyMalicious(oracle.challengeToken, msg.sender, address(this), challengeDeposit);
        if (diff < oracle.challengeDepositCostTokens) {
            revert ChallengeDepositNotMet(tournamentId, round.roundId);
        }

        emit ChallengeMade(tournamentId, round.roundId, msg.sender, claimedWinner, evidence);
    }

    function confirmWinnerUnchallenged(uint tournamentId) public {
        Tournament storage tournament = tournaments[tournamentId];
        Round storage round = tournament.rounds[tournament.roundToConfirm];
        if (round.challenger != address(0)) {
            revert MustAddressChallenger(tournamentId, round.roundId);
        }
        round.finalPrices = round.proposedFinalPrices;

        confirmWinnerInternal(tournamentId, round.proposedWinnerIndex);
    }

    function confirmWinnerChallenged(uint tournamentId, uint chosenWinnerIndex, int[] memory localPrices, bytes32 evidence) external {
        Tournament storage tournament = tournaments[tournamentId];
        if (msg.sender != tournament.owner) {
            revert OnlyOwner(msg.sender, tournament.owner);
        }

        Round storage round = tournament.rounds[tournament.roundToConfirm];
        Oracle storage oracle = tournament.oracle;
        if (round.challenger == address(0)) {
            revert WinnerUnchallenged(tournamentId, round.roundId);
        }
        if (chosenWinnerIndex == 0 || chosenWinnerIndex > oracle.currentTickerSymbols.length) {
            revert BadWinnerIndex(tournamentId, chosenWinnerIndex);
        }
        if (localPrices.length != oracle.currentTickerSymbols.length) {
            revert MismatchedArrayLengths(localPrices.length, oracle.currentTickerSymbols.length);
        }

        // set official winner
        round.confirmationEvidence = evidence;
        round.finalPrices = localPrices;

        confirmWinnerInternal(tournamentId, chosenWinnerIndex);


        // if challenger failed, slash their deposit
        if (chosenWinnerIndex != round.challengeWinnerIndex) {
            // ignore return value here because it's irrelevant
            transferPossiblyMalicious(oracle.challengeToken, address(this), address(0), oracle.challengeDepositCostTokens);
            emit ChallengerSlashed(tournamentId, round.roundId, round.challenger, oracle.challengeDepositCostTokens, evidence);
        // else send it back to them
        } else {
            transferPossiblyMalicious(oracle.challengeToken, address(this), round.challenger, oracle.challengeDepositCostTokens);
            emit ChallengerVindicated(tournamentId, round.roundId, round.challenger, evidence);
        }
    }

/**
====================================== INTERNALS ==========================================================
**/

    function confirmWinnerInternal(uint tournamentId, uint winnerIndex) internal {
        Tournament storage tournament = tournaments[tournamentId];
        Round storage round = tournament.rounds[tournament.roundToConfirm];
        if (round.confirmed) {
            revert RoundAlreadyConfirmed(tournament.tournamentId, tournament.roundToConfirm);
        }
        if (getRoundState(tournamentId, tournament.roundToConfirm) != RoundState.COMPLETE) {
            revert ChallengePeriodNotPassed(tournamentId, tournament.roundToConfirm);
        }
        if (round.finalPrices.length == 0 || round.startingPrices.length == 0) {
            revert SetPricesFirst(tournamentId);
        }

        tournament.roundToConfirm = tournament.getCurrentRoundId();

        round.finalWinnerIndex = winnerIndex;
        round.confirmed = true;

        emit WinnerConfirmed(tournamentId, round.roundId, round.finalPrices);
    }


    function maybeUpdateAccount(uint voterId, uint tournamentId) internal {
        Tournament storage tournament = tournaments[tournamentId];
        uint lastRoundVoted = tournament.lastRoundVoted[voterId];
        // if the lastRoundVoted hasn't been synced yet...then sync it first
        if (tournament.lastRoundSynced[voterId] < lastRoundVoted && tournament.rounds[lastRoundVoted].confirmed) {
            uint rewards = getRoundBonus(voterId, tournamentId, lastRoundVoted);
            tournament.tokensWon[voterId] += rewards;
            tournament.rewardsOwed += rewards;
            tournament.lastRoundSynced[voterId] = lastRoundVoted;
        }
    }

    /// @notice Transfer tokens on an untrusted token contract
    /// @dev This function is internal, since it transfers tokens to and from this contract
    /// @dev If neither from nor to is address(this) then this function is a no-op and returns 0
    /// @param token token contract to be transferred
    /// @param from address from which tokens will be transferred
    /// @param to address to which tokens will be transferred
    /// @param amount amount of tokens to be transferred
    /// @return the actual amount of tokens transferred
    function transferPossiblyMalicious(
        IERC20 token,
        address from,
        address to,
        uint amount) internal lock returns (uint) {
        uint diff;
        if (from == address(this)) {
            uint balanceBefore = token.balanceOf(address(this));
            token.transfer(to, amount);
            uint balanceAfter = token.balanceOf(address(this));
            diff = balanceBefore - balanceAfter;
        } else {
            uint balanceBefore = token.balanceOf(to);
            token.transferFrom(from, to, amount);
            uint balanceAfter = token.balanceOf(to);
            diff = balanceAfter - balanceBefore;
        }

        // return the actual amount transferred
        return diff;
    }


/**
====================================== GETTERS ==========================================================
**/
    function getTournament(uint tournamentId) external view
        returns (uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint) {
        Tournament storage t = tournaments[tournamentId];
        return (
            t.tournamentId, t.startTime, t.votingPeriodLengthSeconds,
            t.marketPeriodLengthSeconds, t.challengePeriodLengthSeconds,
            t.roundRewardTokens, t.voteCostTokens, t.rewardFunding,
            t.rewardsOwed, t.voiceUBI, t.roundToConfirm);
    }

    function getTournamentAddresses(uint tournamentId) external view
        returns (address, address, address, address, address) {
        Tournament storage t = tournaments[tournamentId];
        return (
            address(t.voteToken), address(t.rewardToken),
            address(t.identity), t.owner, t.taxMan
        );
    }

    function getRoundDetails(uint tournamentId, uint roundId) external view
        returns (uint, uint, uint, address, bytes32, bytes32,
                int[] memory, int[] memory, int[] memory, bytes32[] memory, address[] memory) {
        Round storage r = tournaments[tournamentId].rounds[roundId];
        return (
            r.finalWinnerIndex, r.proposedWinnerIndex,
            r.challengeWinnerIndex, r.challenger, r.challengeEvidence,
            r.confirmationEvidence, r.startingPrices, r.proposedFinalPrices,
            r.finalPrices, r.tickerSymbols, r.priceFeeds);
    }

    function getRoundDetails2(uint tournamentId, uint roundId) external view
        returns (uint, uint) {
        Round storage r = tournaments[tournamentId].rounds[roundId];
        return (r.roundRewardTokens, r.voteCostTokens);
    }

    function getOracle(uint tournamentId) external view returns (uint, address, bytes32[] memory, address[] memory) {
        Oracle storage o = tournaments[tournamentId].oracle;
        return (o.challengeDepositCostTokens, address(o.challengeToken),
            o.currentTickerSymbols, o.currentPriceFeeds);
    }

    function getRound(uint tournamentId, uint roundId) external view returns (uint[2] memory) {
        Round storage round = tournaments[tournamentId].rounds[roundId];
        return [round.roundId, round.finalWinnerIndex];
    }

    function getRoundStartTime(uint tournamentId, uint roundId) public view returns (uint) {
        if (roundId == 0) {
            return 0;
        }
        Tournament storage tournament = tournaments[tournamentId];
        uint roundLengthSeconds = tournament.votingPeriodLengthSeconds + tournament.marketPeriodLengthSeconds + tournament.challengePeriodLengthSeconds;
        return tournament.startTime + ((roundId - 1) * roundLengthSeconds);
    }

    function getCurrentRoundId(uint tournamentId) external view returns (uint) {
        Tournament storage tournament = tournaments[tournamentId];
        return tournament.getCurrentRoundId();
    }

    function getCurrentRoundState(uint tournamentId) public view returns (RoundState) {
        Tournament storage tournament = tournaments[tournamentId];
        return getRoundState(tournamentId, tournament.getCurrentRoundId());
    }

    function getRoundState(uint tournamentId, uint roundId) public view returns (RoundState) {
        Tournament storage tournament = tournaments[tournamentId];

        uint roundStartTime = getRoundStartTime(tournamentId, roundId);

        if (roundId == 0 || block.timestamp < roundStartTime) {
            return RoundState.UNDEFINED;
        }

        uint elapsed = block.timestamp - roundStartTime;
        uint roundLengthSeconds = tournament.votingPeriodLengthSeconds + tournament.marketPeriodLengthSeconds + tournament.challengePeriodLengthSeconds;

        if (elapsed < tournament.votingPeriodLengthSeconds) {
            return RoundState.VOTING;
        } else if (elapsed < tournament.votingPeriodLengthSeconds + tournament.marketPeriodLengthSeconds) {
            return RoundState.MARKET;
        } else if (elapsed < roundLengthSeconds) {
            return RoundState.CHALLENGE;
        } else {
            return RoundState.COMPLETE;
        }
    }

    function getLastRoundVoted(uint tournamentId, uint voterId) external view returns (uint) {
        return tournaments[tournamentId].lastRoundVoted[voterId];
    }

    function getVote(uint tournamentId, uint roundId, uint voterId) external view returns (bytes32, uint[] memory, uint[] memory) {
        Vote storage votee = tournaments[tournamentId].rounds[roundId].votes[voterId];
        uint [] memory weights = new uint[](votee.choices.length);
        for (uint i; i < votee.choices.length; ++i) {
            weights[i] = votee.weights[votee.choices[i]];
        }

        return (votee.metadataHash, votee.choices, weights);
    }

    function getVoteTotals(uint tournamentId, uint roundId, uint option) external view returns (uint) {
        return tournaments[tournamentId].rounds[roundId].voteTotals[option];
    }

    function getTokensWon(uint tournamentId, uint voterId) external view returns (uint) {
        Tournament storage tournament = tournaments[tournamentId];
        uint lastRoundVoted = tournament.lastRoundVoted[voterId];
        uint rewards;
        // if the lastRoundVoted hasn't been synced yet...then sync it first
        if (tournament.lastRoundSynced[voterId] < lastRoundVoted && tournament.rounds[lastRoundVoted].confirmed) {
            rewards = getRoundBonus(voterId, tournamentId, lastRoundVoted);
        }

        return tournaments[tournamentId].tokensWon[voterId] + rewards;
    }

    function getVotesByVoterID(uint voterId, uint tournamentId) external view returns (uint[] memory) {
        return votesByVoterId[voterId][tournamentId];
    }

    function getRoundResults(uint voterId, uint tournamentId, uint roundId) public view returns (uint, uint) {
        Tournament storage tournament = tournaments[tournamentId];
        Round storage round = tournament.rounds[roundId];
        Vote storage thisVote = round.votes[voterId];
        return (thisVote.weights[round.finalWinnerIndex], round.voteTotals[round.finalWinnerIndex]);
    }

    function getRoundBonus(uint voterId, uint tournamentId, uint roundId) public view returns (uint) {
        Tournament storage tournament = tournaments[tournamentId];
        Round storage round = tournament.rounds[roundId];
        (uint voteWeight, uint totalVotes) = getRoundResults(voterId, tournamentId, roundId);
        uint tokenBonus = 0;
        // if this is the first round voterId has voted in, totalVotes will be 0
        if (totalVotes > 0) {
            tokenBonus = (round.roundRewardTokens * voteWeight) / totalVotes;
        }
        return tokenBonus;
    }

    function getLivePrices(uint tournamentId) external view returns (int[] memory) {
        Tournament storage tournament = tournaments[tournamentId];
        return tournament.getLivePrices();
    }

/**
====================================== KEEPERS ==========================================================
**/
    function checkUpkeep(bytes calldata tournamentIdBytes) external view override returns (bool upkeepNeeded, bytes memory performData) {
        uint tournamentId = abi.decode(tournamentIdBytes, (uint));
        Tournament storage tournament = tournaments[tournamentId];
        Round storage roundToConfirm = tournament.rounds[tournament.roundToConfirm];
        RoundState state = getRoundState(tournamentId, tournament.roundToConfirm);
//        uint currentRoundId = tournament.getCurrentRoundId();
//        Round storage currentRound = tournament.rounds[currentRoundId];
//        RoundState state = getCurrentRoundState(tournamentId);
        if (state > RoundState.VOTING && roundToConfirm.startingPrices.length == 0) {
            upkeepNeeded = true;
            performData = abi.encode(KeeperAction.GET_STARTING_PRICES, tournamentId);
        } else if (state > RoundState.MARKET && roundToConfirm.proposedFinalPrices.length == 0) {
            upkeepNeeded = true;
            performData = abi.encode(KeeperAction.GET_FINAL_PRICES, tournamentId);
        } else if (state > RoundState.CHALLENGE && tournament.rounds[tournament.roundToConfirm].challenger == address(0)) {
            upkeepNeeded = true;
            performData = abi.encode(KeeperAction.CONFIRM, tournamentId);
        }
    }

    function performUpkeep(bytes calldata performData) external override {
        (KeeperAction action, uint tournamentId) = abi.decode(performData, (KeeperAction, uint));
        Tournament storage tournament = tournaments[tournamentId];
        if (action == KeeperAction.CONFIRM) {
            confirmWinnerUnchallenged(tournamentId);
        } else if (action == KeeperAction.GET_STARTING_PRICES) {
            setStartPrices(tournamentId);
        } else if (action == KeeperAction.GET_FINAL_PRICES) {
            setFinalPrices(tournamentId);
        }
    }
}