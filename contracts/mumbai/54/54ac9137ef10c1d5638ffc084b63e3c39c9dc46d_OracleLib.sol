/**
 *Submitted for verification at polygonscan.com on 2022-07-22
*/

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.12;


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