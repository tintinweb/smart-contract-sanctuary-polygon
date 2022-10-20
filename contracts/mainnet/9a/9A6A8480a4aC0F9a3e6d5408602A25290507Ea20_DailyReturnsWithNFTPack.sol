// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./utils/DailyReturnsStructs.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DailyReturns} from "./DailyReturns.sol";
import {YoloRegistry} from "../../core/YoloRegistry.sol";
import {NFTTracker} from "../../core/NFTTracker.sol";
import {YoloNFTPack} from "../../tokens/YoloNFTPack.sol";
import {USDC_TOKEN, YOLO_NFT_PACK, NFT_TRACKER} from "../../utils/constants.sol";
import {ZAA_NFTTracker, ZAA_YoloNFTPack} from "../../utils/errors.sol";

/**
 * @title DailyReturnsWithNFTPack
 * @author Garen Vartanian (@cryptokiddies)
 * @notice Bespoke {DailyReturns} child contract to handle YOLO NFT checks for platform participation.
 * @dev Be aware of interactions with {DailyReturnsWithNft} as well as using new {NFTTracker} contract to enhance participation tracking.
 */
contract DailyReturnsWithNFTPack is DailyReturns {
    YoloNFTPack yoloNFTPackContract;
    NFTTracker nftTrackerContract;

    /**
     * @dev See {DailyReturns}.
     **/
    constructor(
        address gameAdmin_,
        address registryContractAddress_,
        bytes32 gamePair_,
        uint256 gameLength_,
        uint256 gameType_,
        uint256 roundIndex_,
        uint256 maxStartDelay_
    )
        DailyReturns(
            gameAdmin_,
            registryContractAddress_,
            gamePair_,
            gameLength_,
            gameType_,
            roundIndex_,
            maxStartDelay_
        )
    {
        YoloRegistry yoloRegistryContract = YoloRegistry(
            registryContractAddress_
        );

        address yoloNftAddress = yoloRegistryContract.getContractAddress(
            YOLO_NFT_PACK
        );

        if (yoloNftAddress == address(0)) revert ZAA_YoloNFTPack();

        yoloNFTPackContract = YoloNFTPack(yoloNftAddress);

        address nftTrackerAddress = yoloRegistryContract.getContractAddress(
            NFT_TRACKER
        );

        if (nftTrackerAddress == address(0)) revert ZAA_NFTTracker();

        nftTrackerContract = NFTTracker(nftTrackerAddress);
    }

    /**
     * @notice Bid in USDC token within a prediction round. Tracks participation, if user holds yolo SFT/NFT.
     * @dev Will call base {DailyReturns} after {YoloNFTPack} check. Will call {NFTTracker} after successful bid. Yolo S|NFT ownership is optional.
     * @param amount Amount of bid in USDC token.
     * @param level The bucket bid is placed in.
     * @param bidRound Round value.
     **/
    function bid(
        uint96 amount,
        Levels level,
        uint72 bidRound
    ) public override {
        super.bid(amount, level, bidRound);

        uint256 tokenId = yoloNFTPackContract.usersTokens(msg.sender);

        if (tokenId > 0) {
            nftTrackerContract.updateTracking(
                tokenId,
                uint192(amount),
                GAME_ID,
                bidRound
            );
        }
    }
}

pragma solidity 0.8.13;

enum Levels {
    One,
    Two,
    Three,
    Four,
    Five
}

enum Strikes {
    Low,
    MidBelow,
    MidAbove,
    High
}

struct BidInfo {
    uint96 amount; // amount (in USDC initially)
    Levels level; // bid levels from 1 to 5
    uint72 bidRound; // round in which bid was made
    uint72 next; // next linked list item key
}

struct BidManager {
    uint72 headIdx;
    uint128 unsettledBidCount;
}

struct RoundPool {
    uint96[5] totalUserAmounts;
    uint96[5] liquidities;
}

// TODO: do we include the level value or just settlement price to impute level from
struct RoundData {
    uint64 startTime;
    uint16 lpFeeRate; // b.p. out of 10,000 - rate set at start of round
    uint128 strikePrice;
    int32[4] levelStrikeBPDeltas; // in basis points
    uint128 settlementPrice;
    uint128 fees;
}

struct SettlementData {
    Levels winningLevel;
    uint56 usersWinAmt;
    uint56 liquidityWin;
    uint56 usersLoseAmt;
    uint56 liquidityLose;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

import {YoloRegistry} from "../../core/YoloRegistry.sol";
import {RegistrySatellite} from "../../core/RegistrySatellite.sol";
import {LiquidityPool} from "../../core/LiquidityPool.sol";
import {YoloWallet} from "../../core/YoloWallet.sol";
import {IDailyReturns} from "./IDailyReturns.sol";
import "./utils/DailyReturnsStructs.sol";
import {DailyReturnsEvents} from "./utils/DailyReturnsEvents.sol";

import {GAME_ADMIN_ROLE, MARKET_MAKER_ROLE, USDC_TOKEN, YOLO_WALLET, LIQUIDITY_POOL, FEE_RATE_MIN, USDC_DECIMALS_FACTOR, STANDARD_FEE_RATE} from "../../utils/constants.sol";
import {ZAA_USDCToken, ZAA_gameAdmin, ZAA_YoloWallet, ZAA_LiquidityPool} from "../../utils/errors.sol";

// import "hardhat/console.sol";

/**
 * @title DailyReturns
 * @author Garen Vartanian (@cryptokiddies)
 * @notice A 5 level daily prediction market for a given market quoted in USD, `GAME_PAIR`, and 24 hours denoted in seconds, `GAME_LENGTH`.  The `gameType` is `002`. Uniquely identified by `GAME_ID`.
 * @dev This is the meat of the Yolo game contracts and manages game round starts and settlements, and handles bids executed by users.
 */
contract DailyReturns is
    RegistrySatellite,
    IDailyReturns,
    Pausable,
    DailyReturnsEvents
{
    using SafeERC20 for IERC20;

    uint256 constant BASIS_FACTOR = 10000;
    uint256 constant EXTANT_BIDS_LIMIT = 100;
    uint256 constant MIN_BID_AMOUNT = 5 * USDC_DECIMALS_FACTOR;

    uint256 immutable MAX_START_DELAY;
    uint256 immutable GAME_LENGTH;
    bytes32 immutable GAME_PAIR;
    bytes32 public immutable GAME_ID;
    address public immutable lpAddress; // {LiquidityPool} contract address

    uint256 bidNonce;
    uint256 public marketLimit; // local copy of marketLimit from {LiquidityPool} for gas efficiency
    uint256 public roundIndex; // index denoting current round number
    uint256 public lpFeeRate; // fee in basis points earned per round to liquidity providers

    IERC20 public immutable stablecoinTokenContract; // get this address from registry
    YoloWallet public immutable yoloWalletContract;

    mapping(uint256 => RoundData) roundDatas; // General round data for a round
    mapping(uint256 => RoundPool) roundPools; // Pool by round
    mapping(uint256 => SettlementData) public settlementDatas; // General round data for a round
    mapping(uint256 => BidInfo) public allBids; // nonce to `BidInfo`
    mapping(address => BidManager) public bidsManager; // latest key in a user's `allBids` linked list

    /**
     * @dev If this is coming from {GameFactory}, arguments are passed in from there. Starts in paused state.
     */
    constructor(
        address gameAdmin_,
        address registryContractAddress_,
        bytes32 gamePair_,
        uint256 gameLength_,
        uint256 gameType_,
        uint256 roundIndex_,
        uint256 maxStartDelay_
    ) RegistrySatellite(registryContractAddress_) {
        if (gameAdmin_ == address(0)) revert ZAA_gameAdmin();

        address stablecoinTokenAddress = YoloRegistry(registryContractAddress_)
            .getContractAddress(USDC_TOKEN);

        if (stablecoinTokenAddress == address(0)) revert ZAA_USDCToken();

        stablecoinTokenContract = IERC20(stablecoinTokenAddress);

        address yoloWalletAddress = YoloRegistry(registryContractAddress_)
            .getContractAddress(YOLO_WALLET);

        if (yoloWalletAddress == address(0)) revert ZAA_YoloWallet();

        yoloWalletContract = YoloWallet(yoloWalletAddress);

        lpAddress = YoloRegistry(registryContractAddress_).getContractAddress(
            LIQUIDITY_POOL
        );

        if (lpAddress == address(0)) revert ZAA_LiquidityPool();

        lpFeeRate = STANDARD_FEE_RATE;
        roundIndex = roundIndex_;

        // should be about 2 days (in seconds)
        MAX_START_DELAY = maxStartDelay_;

        GAME_PAIR = gamePair_;
        GAME_LENGTH = gameLength_;
        // note encoding is NOT packed, though same result with bytes32 and uint256 types
        GAME_ID = keccak256(abi.encode(gamePair_, gameLength_, gameType_));

        _grantRole(GAME_ADMIN_ROLE, gameAdmin_);
        _grantRole(DEFAULT_ADMIN_ROLE, gameAdmin_);

        _pause();
    }

    function getRoundPool(uint256 roundIdx)
        external
        view
        returns (RoundPool memory)
    {
        return roundPools[roundIdx];
    }

    function getRoundData(uint256 roundIdx)
        external
        view
        returns (RoundData memory)
    {
        return roundDatas[roundIdx];
    }

    function getUnclaimedRoundsLength(address user)
        external
        view
        returns (uint256 unclaimedRoundsLength)
    {
        unclaimedRoundsLength = bidsManager[user].unsettledBidCount;
    }

    function calculateExpectedReturns(address user)
        external
        view
        returns (
            uint256[] memory roundsClaimed,
            uint256[] memory roundPayoutAmounts
        )
    {
        BidManager memory bidManager = bidsManager[user];
        uint256 headIdx = bidManager.headIdx;

        if (headIdx > 0) {
            uint256 cursor = headIdx;

            roundsClaimed = new uint256[](bidManager.unsettledBidCount);
            roundPayoutAmounts = new uint256[](bidManager.unsettledBidCount);

            uint256 i = bidManager.unsettledBidCount;

            while (cursor > 0) {
                --i;
                uint256 userRound;

                BidInfo memory bidInfo = allBids[cursor];
                userRound = bidInfo.bidRound;

                SettlementData memory settlementData = settlementDatas[
                    userRound
                ];

                if (
                    userRound < roundIndex ||
                    (userRound == roundIndex &&
                        settlementData.usersWinAmt +
                            settlementData.usersLoseAmt >
                        0)
                ) {
                    uint256 payoutAmount = _calculatePayout(
                        userRound,
                        settlementData,
                        bidInfo
                    );

                    if (payoutAmount > 0) {
                        roundsClaimed[i] = userRound;
                        roundPayoutAmounts[i] = payoutAmount;
                    }
                }
                cursor = bidInfo.next;
            }
        }
    }

    /**
     * @dev Calls Open zeppelin internal pause from {Pausable} to stop bidding.
     */
    function pause() external onlyAuthorized(GAME_ADMIN_ROLE) {
        _pause();

        yoloRegistryContract.setGameInactive();
    }

    /**
     * @dev Calls Open zeppelin internal unpause from {Pausable} to restart bidding.
     */
    function unpause() external onlyAuthorized(GAME_ADMIN_ROLE) {
        _unpause();

        yoloRegistryContract.setGameActive();
    }

    /**
     * @notice Sets fresh fee in basis points earned by liquidity providers in each round.
     * @dev In addition to a fee floor, `FEE_RATE_MIN`, a fee ceiling, `FEE_MAX`, can provide add'l validation
     * @param newFee The new fee in basis points
     **/
    function updateLpFee(uint256 newFee)
        external
        override
        onlyAuthorized(GAME_ADMIN_ROLE)
    {
        require(
            newFee >= yoloRegistryContract.globalParameters(FEE_RATE_MIN),
            "fee must be within bounds"
        );

        lpFeeRate = newFee;

        emit FeeUpdate(newFee);
    }

    /**
     * @notice Grab market limit periodically from {LiquidityPool} to save on external call costs
     * @dev This is called in sync with market limit changes in {LiquidityPool}.
     **/
    function acquireMarketLimit() external onlyAuthorized(GAME_ADMIN_ROLE) {
        marketLimit = LiquidityPool(lpAddress).marketLimit();
    }

    /**
     * @notice Bids in specified round with USDC token for bots only
     * @dev This function bypasses balance checks in `bidInYolo` function. Underflow will revert in reduction
     TODO: remove bid round checks to save gas and have special recover function in case bid round is a past round or is fat fingered far in advance
     **/
    function makeMarketBid(uint256 bidRound, uint96[5] calldata amounts)
        external
        override
        onlyAuthorized(MARKET_MAKER_ROLE)
        whenNotPaused
    {
        if (bidRound <= roundIndex) revert MBStale();
        if (roundDatas[bidRound].startTime == 0)
            revert MBRoundParamsNotYetSpecified();

        uint256 combinedAmount = amounts[0] +
            amounts[1] +
            amounts[2] +
            amounts[3] +
            amounts[4];

        if (combinedAmount > marketLimit) revert MBAmountExceedsLimit();

        address lpAddr = lpAddress;

        yoloWalletContract.gameReduceUserBalance(lpAddr, combinedAmount);

        RoundPool storage roundPool = roundPools[bidRound];
        // 5 buckets for dailies
        for (uint256 i; i <= uint256(type(Levels).max); i++) {
            if (amounts[i] > 0) {
                roundPool.liquidities[i] += amounts[i];
            }
        }

        emit LiquidityProvision(bidRound, msg.sender, lpAddr, amounts);
    }

    /**
     * @param nextStartTime The start time in UNIX seconds.
     * @param nextStrikeBPDeltas The next round deltas in basis points relative to the start price.
     */
    function setNextRoundParams(
        uint64 nextStartTime,
        int32[4] calldata nextStrikeBPDeltas
    ) external onlyAuthorized(GAME_ADMIN_ROLE) {
        if (nextStartTime == 0) revert SPStartTimeZA();

        uint64 currentStartTime = roundDatas[roundIndex].startTime;

        if (nextStartTime < currentStartTime + GAME_LENGTH)
            revert SPMinStartDurationViolation();
        if (nextStartTime > block.timestamp + MAX_START_DELAY)
            revert SPStartTimeOffsetGTAllowed();

        bool hasZero;

        for (uint256 i; i <= uint256(type(Strikes).max); i++) {
            int32 strikeBPDelta = nextStrikeBPDeltas[i];

            if (strikeBPDelta == 0) {
                if (!hasZero) {
                    hasZero = true;
                } else {
                    revert SPStrikeBPMultipleZeroes();
                }
            }
            if (
                strikeBPDelta > int32(uint32(BASIS_FACTOR)) ||
                strikeBPDelta < -1 * (int32((uint32(BASIS_FACTOR))))
            ) revert SPStrikeBPDeltaOutsideBounds();
        }

        uint256 nextRoundIdx = roundIndex + 1;
        RoundData storage nextRoundData = roundDatas[nextRoundIdx];

        // TODO: do we allow a one hour grace period to reassign?
        if (nextRoundData.startTime != 0)
            revert SPNextRoundParamsReassignment();

        nextRoundData.startTime = nextStartTime;
        nextRoundData.levelStrikeBPDeltas = nextStrikeBPDeltas;

        emit RoundParams(roundIndex, nextStartTime, nextStrikeBPDeltas);
    }

    /**
     * @notice Bid in specified round with USDC token within a prediction round. There is a minimum bid amount.
     * @dev There is a streamlined approach where tokens are transferred from the user's USDC token contract balance, if there is insufficient balance in the user's platform token balance. Currently a public function to expose to super call from child contract.
     * @param amount Amount of bid in USDC token.
     * @param level Which of the 5 bickets bid has been placed.
     * @param bidRound Round value.
     **/
    function bid(
        uint96 amount,
        Levels level,
        uint72 bidRound // later rounds
    ) public virtual override whenNotPaused {
        if (bidRound <= roundIndex) revert BidLate();
        if (roundDatas[bidRound].startTime == 0)
            revert BidRoundParamsNotYetSpecified();
        if (amount < MIN_BID_AMOUNT) revert BidMinAmountRequired();

        address sender = msg.sender;
        uint256 userBalance = yoloWalletContract.balances(sender);

        if (amount <= userBalance) {
            yoloWalletContract.gameReduceUserBalance(sender, amount);
        } else {
            uint256 shortfall;

            unchecked {
                shortfall = amount - userBalance;
            }

            if (userBalance > 0) {
                yoloWalletContract.gameReduceUserBalance(sender, userBalance);
            }

            stablecoinTokenContract.safeTransferFrom(
                sender,
                address(yoloWalletContract),
                shortfall
            );
        }

        _bid(amount, level, bidRound);
    }

    /**
     * @notice End current live round, passing in settlement price to compare with strike price. Payout winning bidders and liquidity provider fees. Then starts a round, meaning the round is "live" and cannot accept further bids.
     * @dev Game admin (`GAME_ADMIN_ROLE` or `DEFAULT_ADMIN_ROLE`) can call this method to lock in a round. The `roundIndex` provides the index number value for each round. Critical to keep `processingRoundIndex` and `newRoundIndex` sorted and pass these values to save ~1000 gas on every call rather than read state. Nb: Should start round 1 immediately on deploy so as to not circumvent PRSettlementTimeNotReached check.
     * @param settlementPrice The asset settlement price.
     
     **/
    function processRound(uint128 settlementPrice)
        public
        override
        onlyAuthorized(GAME_ADMIN_ROLE)
    {
        if (settlementPrice == 0) revert PRSettlementPriceIsZero();

        // nb: critical - correct index values
        uint256 processingRoundIndex = roundIndex;

        RoundData storage currentRoundData = roundDatas[processingRoundIndex];

        if (block.timestamp < currentRoundData.startTime + GAME_LENGTH)
            revert PRSettlementTimeNotReached();
        if (currentRoundData.settlementPrice != 0) revert PRRedundantCall();

        currentRoundData.settlementPrice = settlementPrice;

        _processFees(currentRoundData, settlementPrice, processingRoundIndex);
    }

    function startRound(uint128 strikePrice)
        public
        override
        onlyAuthorized(GAME_ADMIN_ROLE)
    {
        if (strikePrice == 0) revert SRStrikePriceZA();

        uint256 newRoundIndex;
        unchecked {
            newRoundIndex = ++roundIndex;
        }

        if (roundDatas[newRoundIndex - 1].settlementPrice == 0)
            revert SRUnprocessedRound();

        RoundData storage newRoundData = roundDatas[newRoundIndex];

        if (newRoundData.startTime == 0) revert SRStartTimeZeroValue();

        _startRound(newRoundData, newRoundIndex, strikePrice);
    }

    function processAndStartRound(uint128 settlementPrice, uint128 strikePrice)
        external
        override
        onlyAuthorized(GAME_ADMIN_ROLE)
    {
        processRound(settlementPrice);
        startRound(strikePrice);
    }

    /**
    @dev note that `userNonces` must be memory - critical for correct behavior. Only `userNoncesStorage` is a storage pointer.
     */
    function claimReturns() external {
        BidManager storage bidManager = bidsManager[msg.sender];
        uint72 headIdx = bidManager.headIdx;

        // also means unsettledBidCount should be zero
        require(headIdx != 0, "no pending claims");

        uint256 bound = bidManager.unsettledBidCount < EXTANT_BIDS_LIMIT
            ? bidManager.unsettledBidCount
            : EXTANT_BIDS_LIMIT;

        // console.log("bound %s", bound);

        uint256 payoutSum;
        uint256 settlementCount;
        uint256 unsettledBidKey;
        uint72 cursor = headIdx;

        // TODO: get winning length method or use event tracking?
        uint256[] memory roundsClaimed = new uint256[](bound);
        uint256[] memory roundPayoutAmounts = new uint256[](bound);

        for (uint256 i; i < bound; i++) {
            BidInfo memory bidInfo = allBids[cursor];
            uint256 userRound = bidInfo.bidRound;

            // console.log("userRound %s", userRound);
            // console.log("bid info next %s", bidInfo.next);

            SettlementData memory settlementData = settlementDatas[userRound];

            if (
                userRound < roundIndex ||
                (userRound == roundIndex &&
                    settlementData.usersWinAmt + settlementData.usersLoseAmt >
                    0)
            ) {
                uint256 payoutAmount = _calculatePayout(
                    userRound,
                    settlementData,
                    bidInfo
                );

                roundsClaimed[i] = userRound;
                roundPayoutAmounts[i] = payoutAmount;
                payoutSum += payoutAmount;

                ++settlementCount;
                cursor = bidInfo.next;
                // console.log("settled. cursor %s", cursor);
            } else {
                if (unsettledBidKey != 0) {
                    allBids[unsettledBidKey].next = cursor;
                } else {
                    bidManager.headIdx = cursor;
                }

                unsettledBidKey = cursor;
                cursor = bidInfo.next;
                // console.log("unsettled round hit. cursor %s", cursor);
            }
        }

        if (unsettledBidKey == 0 && bound < EXTANT_BIDS_LIMIT) {
            bidManager.headIdx = 0;
        } else if (unsettledBidKey == 0 && bound == EXTANT_BIDS_LIMIT) {
            bidManager.headIdx = cursor;
        } else if (bound < EXTANT_BIDS_LIMIT) {
            allBids[unsettledBidKey].next = 0;
        } else if (bound == EXTANT_BIDS_LIMIT) {
            allBids[unsettledBidKey].next = cursor;
        }

        bidManager.unsettledBidCount -= uint128(settlementCount);
        // console.log("payout sum %s", payoutSum);

        yoloWalletContract.gameUpdateUserBalance(msg.sender, payoutSum);

        emit UserClaims(msg.sender, roundsClaimed, roundPayoutAmounts);
    }

    function _calculatePayout(
        uint256 roundIdx,
        SettlementData memory settlementData,
        BidInfo memory bidInfo
    ) private view returns (uint256 payoutAmount) {
        uint256 userLevel = uint256(bidInfo.level);
        uint256 winLevel = uint256(settlementData.winningLevel);
        uint256 usersWinAmt = settlementData.usersWinAmt;
        uint256 usersLoseAmt = settlementData.usersLoseAmt;
        uint256 liquidityWin = settlementData.liquidityWin;
        uint256 liquidityLose = settlementData.liquidityLose;
        uint256 totalWin = usersWinAmt + liquidityWin;
        uint256 totalLose = usersLoseAmt + liquidityLose;

        if (_shouldProcessFees(usersLoseAmt, usersWinAmt, totalLose)) {
            if (userLevel == winLevel) {
                uint256 payoutFactor = BASIS_FACTOR -
                    roundDatas[roundIdx].lpFeeRate;

                payoutAmount =
                    (((bidInfo.amount * totalLose) /
                        totalWin +
                        bidInfo.amount) * payoutFactor) /
                    BASIS_FACTOR;
            }
        } else {
            payoutAmount = bidInfo.amount;
        }
    }

    // TODO: this private function feels a little thin, consider a refactor
    function _startRound(
        RoundData storage startingRoundData,
        uint256 newRoundIndex,
        uint128 strikePrice
    ) private {
        // should remove since check happens in external func
        // if (currentRoundData.startTime == 0) revert RoundParamsMissing();

        uint16 lpFeeRateU16 = uint16(lpFeeRate);
        startingRoundData.lpFeeRate = lpFeeRateU16;
        startingRoundData.strikePrice = strikePrice;

        emit RoundStarted(newRoundIndex, strikePrice, lpFeeRateU16);
    }

    function _bid(
        uint96 amount,
        Levels level,
        uint72 bidRound // later rounds
    ) private {
        BidManager storage bidManager = bidsManager[msg.sender];
        RoundPool storage roundPool = roundPools[bidRound];

        BidInfo memory newBid = BidInfo({
            amount: amount,
            level: level,
            bidRound: bidRound,
            next: bidManager.headIdx
        });

        // console.log("amount %s", amount);
        // console.log("sender %s", msg.sender);
        // console.log("bidRound %s", bidRound);

        allBids[++bidNonce] = newBid;
        bidManager.headIdx = uint72(bidNonce);
        ++bidManager.unsettledBidCount;

        // note: safety based on minimum bid amount and round offset limits
        unchecked {
            roundPool.totalUserAmounts[uint256(level)] += amount;
        }

        emit BidMade(bidRound, msg.sender, amount, level);
    }

    /**
     * @dev  Game admin (`GAME_ADMIN_ROLE`) can call this method to lock in a round. The fee can be set as a state variable instead of constant. This fee can be validated against min and max boundaries. Note that `currentRoundData` is storage pointer in invoking function, but memory instance in this `_processFees` because of good gas savings. This is intentional.
     */
    function _processFees(
        RoundData memory currentRoundData,
        uint256 settlementPrice,
        uint256 processingRoundIndex
    ) private {
        RoundPool memory roundPool = roundPools[processingRoundIndex];

        uint256 usersWinAmt;
        uint256 usersLoseAmt;
        uint256 liquidityWin;
        uint256 liquidityLose;
        uint256 totalWin;
        uint256 totalLose;
        uint256 winningLevel = uint256(type(Levels).max);

        // check if settlement is in level above boundary - if none match, it's 0 level
        for (
            uint256 strikeIndex;
            strikeIndex <= uint256(type(Strikes).max);
            strikeIndex++
        ) {
            uint256 boundaryPrice = (uint256(
                currentRoundData.levelStrikeBPDeltas[strikeIndex] +
                    int256(BASIS_FACTOR)
            ) * currentRoundData.strikePrice) / BASIS_FACTOR;

            if (settlementPrice < boundaryPrice) {
                winningLevel = strikeIndex;
                break;
            }
        }

        for (uint256 level; level <= uint256(type(Levels).max); level++) {
            if (level != winningLevel) {
                usersLoseAmt += roundPool.totalUserAmounts[level];
                liquidityLose += roundPool.liquidities[level];
            }
        }

        totalLose = usersLoseAmt + liquidityLose;
        usersWinAmt = roundPool.totalUserAmounts[winningLevel];
        liquidityWin = roundPool.liquidities[winningLevel];
        totalWin = usersWinAmt + liquidityWin;

        SettlementData storage settlementData = settlementDatas[
            processingRoundIndex
        ];
        settlementData.winningLevel = Levels(winningLevel);
        settlementData.usersWinAmt = uint56(usersWinAmt);
        settlementData.usersLoseAmt = uint56(usersLoseAmt);
        settlementData.liquidityWin = uint56(liquidityWin);
        settlementData.liquidityLose = uint56(liquidityLose);

        uint256 fees;
        uint256 returnAmount;

        if (_shouldProcessFees(usersLoseAmt, usersWinAmt, totalLose)) {
            uint256 payoutFactor = BASIS_FACTOR - currentRoundData.lpFeeRate;

            // get fees from global params contract
            fees =
                ((totalWin + totalLose) * currentRoundData.lpFeeRate) /
                BASIS_FACTOR;

            // nb not stored
            currentRoundData.fees = uint64(fees);

            if (liquidityWin != 0) {
                returnAmount =
                    (((liquidityWin * totalLose) / totalWin + liquidityWin) *
                        payoutFactor) /
                    BASIS_FACTOR;
            }
        } else {
            returnAmount = liquidityWin + liquidityLose;
        }

        yoloWalletContract.returnLiquidity(lpAddress, returnAmount, fees);

        emit RoundSettled(
            processingRoundIndex,
            currentRoundData,
            settlementData
        );
    }

    function _shouldProcessFees(
        uint256 usersLoseAmt,
        uint256 usersWinAmt,
        uint256 totalLose
    ) private pure returns (bool) {
        return (usersLoseAmt != 0) || (usersWinAmt != 0 && totalLose != 0);
    }
}

pragma solidity 0.8.13;

import {CoreCommon} from "./CoreCommon.sol";
import {ADMIN_ROLE} from "../utils/constants.sol";

/**
 * @title YoloRegistry
 * @author Garen Vartanian (@cryptokiddies)
 * @dev Controller contract which keeps track of critical yolo contracts info, including latest contract addresses and versions, and access control, incl. multisignature calls
 * review access control of satellites to simplify process. also review contract address management in line with contract version and instance deprecation pattern
 *
 */
contract YoloRegistry is CoreCommon {
    /**
     * @dev ContractDetails struct handles information for recognized contracts in the Yolo ecosystem.
     */
    struct ContractDetails {
        address contractAddress;
        uint48 version;
        uint48 latestVersion;
    }

    struct ContractArchiveDetails {
        bytes32 identifier;
        uint48 version;
    }

    bytes32 constant EMPTY_BYTES_HASH =
        0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    // recognized contracts in the Yolo ecosystem
    mapping(bytes32 => ContractDetails) contractRegistry;
    // game instances preapproved for factory minting
    mapping(address => bool) public registeredGames;
    // values used by system, e.g., min (or max) fee required in game/market
    mapping(bytes32 => uint256) public globalParameters;
    // game paused state statuses
    mapping(address => bool) public activeGames;
    // all contracts including those that have been rescinded or replaced mapped to their respective version numbers
    mapping(address => ContractArchiveDetails) public contractsArchive;

    event ContractRegistry(
        bytes32 indexed identifier,
        address indexed newAddress,
        address indexed oldAddress,
        uint96 newVersion
    );

    event ContractAddressRegistryRemoval(
        bytes32 indexed indentifier,
        address indexed rescindedAddress,
        uint96 version
    );

    event GameApproval(address indexed gameAddress, bool hasApproval);

    event GlobalParameterAssignment(bytes32 indexed paramName, uint256 value);

    modifier onlyGameContract() {
        require(registeredGames[msg.sender], "only game can set");
        _;
    }

    /**
     * @dev Note: Most critical role. Only give to the most trusted managers as they can revoke or destroy all control setting random values to management fields in AccessControl role mappings
     */
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Used mainly by satellite contract constructors to grab registered addresses.
     */
    function getContractAddress(bytes32 identifier)
        public
        view
        returns (address)
    {
        return contractRegistry[identifier].contractAddress;
    }

    /**
     * @dev No internal uses at the moment. Necessary for handling migrations.
     */
    function getContractVersion(bytes32 identifier)
        public
        view
        returns (uint96)
    {
        return contractRegistry[identifier].version;
    }

    /**
     * @notice Setting registered contracts (described above).
     * @dev This is for contracts OTHER THAN {GameInstance} types; game factory should call `setApprovedGame`
     **/
    function setContract(bytes32 identifier, ContractDetails calldata newData)
        external
        onlyAdmin
    {
        bytes32 codehash = newData.contractAddress.codehash;

        require(
            codehash != EMPTY_BYTES_HASH && codehash != 0,
            "addr must be contract"
        );

        ContractDetails storage oldRegister = contractRegistry[identifier];

        require(!registeredGames[newData.contractAddress], "is game contract");

        ContractArchiveDetails memory contractArchive = contractsArchive[
            newData.contractAddress
        ];

        if (contractArchive.identifier != bytes32(0)) {
            require(
                identifier == contractArchive.identifier,
                "reinstating identifier mismatch"
            );

            require(
                newData.version == contractArchive.version,
                "reinstating version mismatch"
            );
        } else {
            require(
                newData.version == oldRegister.latestVersion + 1,
                "new version val must be 1 g.t."
            );

            oldRegister.latestVersion += 1;

            contractsArchive[newData.contractAddress] = ContractArchiveDetails(
                identifier,
                newData.version
            );
        }

        address oldAddress = oldRegister.contractAddress;

        oldRegister.contractAddress = newData.contractAddress;
        oldRegister.version = newData.version;

        emit ContractRegistry(
            identifier,
            newData.contractAddress,
            oldAddress,
            newData.version
        );
    }

    /**
     * @notice Removing a registered contract address.
     * @dev The contract, though unregistered, is maintained in the `contractsArchive` mapping.
     **/
    function removeContractAddress(bytes32 identifier) external onlyAdmin {
        ContractDetails storage registryStorage = contractRegistry[identifier];
        ContractDetails memory oldRegister = registryStorage;

        require(
            oldRegister.contractAddress != address(0),
            "identifier is not registered"
        );

        registryStorage.contractAddress = address(0);
        registryStorage.version = 0;

        emit ContractAddressRegistryRemoval(
            identifier,
            oldRegister.contractAddress,
            oldRegister.version
        );
    }

    /**
     * @notice Use this to preapprove factory games with create2 and a nonce salt: keccak hash of `abi.encodePacked(gameId, gameLength)`. `gameId` is itself a hash of the game pair, e.g. "ETH_USD"
     * @dev Can use EXTCODEHASH opcode whitelisting in future iterations. (Its usage forces redesigns for factory-spawned game contracts with immutable vars, given that their initialized values end up in the deployed bytecode.)
     **/
    function setApprovedGame(address gameAddress, bool hasApproval)
        external
        onlyAdmin
    {
        registeredGames[gameAddress] = hasApproval;

        emit GameApproval(gameAddress, hasApproval);
    }

    function setGameActive() external onlyGameContract {
        activeGames[msg.sender] = true;
    }

    function setGameInactive() external onlyGameContract {
        activeGames[msg.sender] = false;
    }

    /**
     * @notice Values used by system, e.g., min (or max) fee required in game/market. Good for setting boundary values and flags.
     * @dev For a bool, substitute 0 and 1 for false and true, respectively.
     **/
    function setGlobalParameters(bytes32 paramName, uint256 value)
        external
        onlyAdmin
    {
        globalParameters[paramName] = value;

        emit GlobalParameterAssignment(paramName, value);
    }
}

pragma solidity 0.8.13;

import {RegistrySatellite} from "./RegistrySatellite.sol";
import {BiddersRewards} from "../accessory/BiddersRewards.sol";
import {YoloNFTPack} from "../tokens/YoloNFTPack.sol";
import {SplitBitId} from "../utils/SplitBitId.sol";
import {ADMIN_ROLE, MINTER_ROLE, BIDDERS_REWARDS, YOLO_NFT_PACK} from "../utils/constants.sol";
import {ZAA_BiddersRewards, ZAA_YoloNFTPack} from "../utils/errors.sol";

/**
 * @title NFTTracker
 * @author Garen Vartanian (@cryptokiddies)
 * @author Yogesh Srihari
 * @notice Tracks bids made by participants in order to calculate future token rewards.
 * @dev Make sure the tracker only counts one point per round (aside from adding all amounts cumulatively), as multiple bids in same round will game the incentive mechanism.
 */
contract NFTTracker is RegistrySatellite {
    struct NftData {
        uint64 roundCount;
        uint192 cumulativeBidAmount;
        mapping(bytes32 => mapping(uint256 => bool)) hasUserBid;
    }

    struct LevelTracking {
        uint64 totalRoundCount;
        uint192 totalCumulativeBidAmount;
    }

    struct LevelRequirement {
        uint64 roundCountThreshold;
        uint192 cumulativeAmountThreshold;
        uint256 nextLevelId;
        uint256 prevLevelId;
    }

    using SplitBitId for uint256;

    /**
     * key The nft id of the token that is tracked
     * @notice Tracking activity for calculating token's total participation.
     * @dev The param is Yolo NFT token index. Public function will return `roundCount` and `cumulativeBidAmount`. Nested noniterables, i.e., `hasUserBid` are not returned with generic struct getter.
     * @return roundCount cumulativeBidAmount Struct `roundCount` and `cumulativeBidAmount` fields.
     **/
    mapping(uint256 => NftData) public nftTrackingMap;

    /**
     * key The SFT/NFT basetype id.
     * @notice Provides thresholds required to upgrade token and points to next level token id.
     * @dev The struct `LevelRequirement` is a quasi linked list.
     * @return roundCountThreshold cumulativeAmountThreshold nextLevelId prevLevelId.
     **/
    mapping(uint256 => LevelRequirement) public levelRequirements;

    /**
     * key The SFT/NFT basetype id.
     * @notice Tracks total round bid count and cumulative amounts within a SFT/NFT tier.
     * @dev compact uint types are sufficient for tracking tokens.
     * @return totalRoundCount totalCumulativeBidAmount.
     **/
    mapping(uint256 => LevelTracking) public levelTrackingMap;

    // TODO: move to rewards contract?
    /**
     * key The SFT/NFT basetype id.
     * @notice Provides level rewards multiplier weightings for {BiddersRewards}
     * @dev SFT/NFT ids to rewards multipler.
     * @return totalRoundCount totalCumulativeBidAmount.
     **/
    mapping(uint256 => uint256) public rewardsMultipliers;

    // List of NftLevels to iterate over in rewards
    uint256[] public nftLevelIds;

    BiddersRewards biddersRewardsContract;
    YoloNFTPack yoloNFTPackContract;

    // TODO: track and emit game id?
    event BidTracking(
        uint256 indexed tokenIndex,
        uint64 roundCount,
        uint192 cumulativeAmount
    );

    event LevelSet(
        uint256 indexed baseId,
        uint64 roundCountThreshold,
        uint192 cumulativeAmountThreshold
    );

    event UserIncentiveModification(
        uint256 indexed tokenBase,
        uint16 multiplier
    );

    error MultiplierBelow100();

    constructor(address registryAddress_) RegistrySatellite(registryAddress_) {}

    function getNFTLevelIdsLength() public view returns (uint256) {
        return nftLevelIds.length;
    }

    /**
     * @notice Returns a range of the `nftLevels` list of SFT/NFT level basetypes.
     * @dev Use `getNFTLevelIdsLength` to retrieve array length.
     **/
    function getNFTLevelsListRange(uint256 startIndex, uint256 length)
        public
        view
        returns (uint256[] memory nftLevels)
    {
        require(
            startIndex + length <= nftLevelIds.length,
            "range out of array bounds"
        );

        require(length > 0, "length must be g.t. 0");

        nftLevels = new uint256[](length);

        for (uint256 i; i < length; i++) {
            nftLevels[i] = nftLevelIds[i + startIndex];
        }

        return nftLevels;
    }

    /**
     * @notice Set {BiddersRewards} instance.
     * @dev  `upgradeToken` checks for nonzero address, then calls `biddersRewardsContract.harvestBeforeUpgrade` call. This should always point to the latest active rewards contract. Give {BiddersRewardsFactory} privelages `ADMIN_ROLE` to call `setBiddersRewardsContract`.
     **/
    function setBiddersRewardsContract(address biddersRewardsAddress)
        external
        onlyAuthorized(ADMIN_ROLE)
    {
        if (biddersRewardsAddress == address(0)) revert ZAA_BiddersRewards();

        biddersRewardsContract = BiddersRewards(biddersRewardsAddress);

        emit AddressSet(BIDDERS_REWARDS, biddersRewardsAddress);
    }

    /**
     * @notice Remove {BiddersRewards} instance address. Called when rewards schedule has concluded.
     * @dev Give {BiddersRewardsFactory} privelages with `ADMIN_ROLE`
     **/
    function removeBiddersRewardsContract()
        external
        onlyAuthorized(ADMIN_ROLE)
    {
        biddersRewardsContract = BiddersRewards(address(0));

        emit AddressSet(BIDDERS_REWARDS, address(0));
    }

    /**
     * @notice Set {YoloNFTPack} instance.
     * @dev Required currently for `updateTracking` functionality to work due to `biddersRewardsContract.updatePool` call.
     **/
    function setYoloNFTPackContract() external onlyAuthorized(ADMIN_ROLE) {
        address yoloNFTPackAddress = yoloRegistryContract.getContractAddress(
            YOLO_NFT_PACK
        );

        if (yoloNFTPackAddress == address(0)) revert ZAA_YoloNFTPack();

        yoloNFTPackContract = YoloNFTPack(yoloNFTPackAddress);

        emit AddressSet(YOLO_NFT_PACK, yoloNFTPackAddress);
    }

    /**
     * @notice Track user activity for calculating token rewards.
     * @dev Bid count should be incremented only once per round. Since blockchain cannot check ownership history internally, cannot batch call this later. Must be on bid.
     * @param tokenIndex Yolo NFT token index.
     * @param amount Amount bid.
     * @param gameId Game pair (by extension, game instance) in which bid occurs.
     * @param bidRound Bid round of game instance.
     **/
    function updateTracking(
        uint256 tokenIndex,
        uint192 amount,
        bytes32 gameId,
        uint256 bidRound
    ) external onlyGameContract {
        require(
            (tokenIndex.isSemiFungibleItem() || tokenIndex.isNonFungibleItem()),
            "incorrect token id encoding"
        );

        NftData storage nftTracking = nftTrackingMap[tokenIndex];
        mapping(uint256 => bool) storage hasUserBid = nftTracking.hasUserBid[
            gameId
        ];

        uint256 tokenBase;
        uint256 newRoundBid;

        tokenBase = tokenIndex.getBaseType();

        LevelTracking storage levelTracker = levelTrackingMap[tokenBase];

        nftTracking.cumulativeBidAmount += amount;
        levelTracker.totalCumulativeBidAmount += amount;

        if (hasUserBid[bidRound] == false) {
            newRoundBid = 1;
            nftTracking.roundCount++;
            hasUserBid[bidRound] = true;
            levelTracker.totalRoundCount += 1;
        }

        if (address(biddersRewardsContract) != address(0)) {
            biddersRewardsContract.updateTracking(
                tokenIndex,
                newRoundBid,
                amount
            );
        }

        emit BidTracking(
            tokenIndex,
            nftTracking.roundCount,
            nftTracking.cumulativeBidAmount
        );
    }

    /**
     * @notice This call sets thresholds for levels, which dictates when SFT/NFT can be upgraded.
     * @dev No need to delete indexes as entire set must be totaled in rewards contract. This quasi linked list approach can be expanded in the future to add or delete intermediate levels. Otherwise, enumerable set pattern can also be sufficient.
     **/
    function setLevelRequirement(
        uint256 baseIndex,
        uint64 roundCountThreshold,
        uint192 cumulativeAmountThreshold,
        uint16 multiplier
    ) external onlyAuthorized(MINTER_ROLE) {
        require(
            baseIndex.isSemiFungibleBaseType() ||
                baseIndex.isNonFungibleBaseType(),
            "incorrect token base encoding"
        );

        if (address(yoloNFTPackContract) == address(0))
            revert ZAA_YoloNFTPack();

        require(
            yoloNFTPackContract.typeBirthCertificates(baseIndex) == true,
            "base type does not exist"
        );

        LevelRequirement storage currentLevel = levelRequirements[baseIndex];

        uint256 prevLevelId;
        LevelRequirement memory prevLevel;

        if (currentLevel.roundCountThreshold == 0) {
            uint256 levelIdsLength;

            levelIdsLength = nftLevelIds.length;

            if (levelIdsLength > 0) {
                prevLevelId = nftLevelIds[nftLevelIds.length - 1];
                currentLevel.prevLevelId = prevLevelId;
                levelRequirements[prevLevelId].nextLevelId = baseIndex;
            }

            nftLevelIds.push(baseIndex);
        } else {
            prevLevelId = currentLevel.prevLevelId;
        }

        prevLevel = levelRequirements[prevLevelId];

        require(
            roundCountThreshold > prevLevel.roundCountThreshold &&
                cumulativeAmountThreshold > prevLevel.cumulativeAmountThreshold,
            "new thresholds must be greater than lower level"
        );

        if (multiplier < 100) revert MultiplierBelow100();

        require(
            multiplier > rewardsMultipliers[prevLevelId],
            "mult must be g.t. prevLevel"
        );

        if (currentLevel.nextLevelId > 0) {
            LevelRequirement memory nextLevel = levelRequirements[
                currentLevel.nextLevelId
            ];

            require(
                roundCountThreshold < nextLevel.roundCountThreshold &&
                    cumulativeAmountThreshold <
                    nextLevel.cumulativeAmountThreshold,
                "new thresholds must be less than next level"
            );

            require(
                multiplier < rewardsMultipliers[currentLevel.nextLevelId],
                "mult must be l.t. nextLevel"
            );
        }

        rewardsMultipliers[baseIndex] = multiplier;
        currentLevel.roundCountThreshold = roundCountThreshold;
        currentLevel.cumulativeAmountThreshold = cumulativeAmountThreshold;
        // note: manual next levels should bot be set - discuss with team design logic
        // dont do this: currentLevel.nextLevelId = nextLevelId;
        // difficulty is if NFT must be swapped for SFT level then SOL

        emit LevelSet(
            baseIndex,
            roundCountThreshold,
            cumulativeAmountThreshold
        );
    }

    /**
     * @notice multiplier in smallish integer
     * @dev uint16 calldata more expensive, but handles overflow check and required for struct fields
     */
    function modifyUserIncentives(uint256 baseIndex, uint16 multiplier)
        external
        onlyAuthorized(MINTER_ROLE)
    {
        require(
            baseIndex.isSemiFungibleBaseType() ||
                baseIndex.isNonFungibleBaseType(),
            "incorrect token base encoding"
        );

        LevelRequirement memory currentLevel = levelRequirements[baseIndex];

        require(currentLevel.roundCountThreshold != 0, "level does not exist");

        if (multiplier < 100) revert MultiplierBelow100();

        require(
            multiplier > rewardsMultipliers[currentLevel.prevLevelId],
            "mult must be g.t. prevLevel"
        );

        if (currentLevel.nextLevelId > 0) {
            require(
                multiplier < rewardsMultipliers[currentLevel.nextLevelId],
                "mult must be l.t. nextLevel"
            );
        }

        rewardsMultipliers[baseIndex] = multiplier;

        emit UserIncentiveModification(baseIndex, multiplier);
    }
}

pragma solidity 0.8.13;

import {AccessControlEnumerable} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import {YoloRegistry} from "../core/YoloRegistry.sol";
import {RegistrySatellite} from "../core/RegistrySatellite.sol";
import {ERC1155SemiFungible} from "./extensions/ERC1155SemiFungible.sol";
import {NFTTracker} from "../core/NFTTracker.sol";
import {BiddersRewardsFactory} from "../accessory/BiddersRewardsFactory.sol";
import {BiddersRewards} from "../accessory/BiddersRewards.sol";
import {SplitBitId} from "../utils/SplitBitId.sol";
import {NFT_TRACKER, ADMIN_ROLE, MINTER_ROLE, BIDDERS_REWARDS_FACTORY} from "../utils/constants.sol";

/**
 * @dev {YoloNFTPack} is a wrapper around custom Yolo ERC1155 extensions with functions for creating participation tokens for members and allowing them to upgrade their token based on criteria.
 */
contract YoloNFTPack is RegistrySatellite, ERC1155SemiFungible {
    // tracker data
    // struct NftData {
    //     uint64 roundCount;
    //     uint192 cumulativeBidAmount;
    //     mapping(bytes32 => mapping(uint256 => bool)) hasUserBid;
    // }

    using SplitBitId for uint256;

    uint256 immutable BASE_SFT_ID =
        SplitBitId.TYPE_SEMI_BIT | (uint256(1) << 128);

    NFTTracker nftTrackerContract;
    BiddersRewardsFactory biddersRewardsFactoryContract;

    event TokenUpgrade(
        uint256 indexed prevBaseType,
        address sender,
        uint256 indexed newBaseType
    );

    /**
     * @dev Give {BiddersRewardsFactory} privelages `ADMIN_ROLE` to call `setBiddersRewardsContract` .
     */
    constructor(address yoloRegistryAddress_)
        RegistrySatellite(yoloRegistryAddress_)
        ERC1155SemiFungible()
    {
        address nftTrackerAddress = YoloRegistry(yoloRegistryAddress_)
            .getContractAddress(NFT_TRACKER);

        require(
            nftTrackerAddress != address(0),
            "nftTracker addr cannot be zero"
        );

        nftTrackerContract = NFTTracker(nftTrackerAddress);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155SemiFungible, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Set {NFTTracker} instance.
     * @dev Required in order for `upgradeToken` functionality to work.
     **/
    function setNFTTrackerContract() external onlyAuthorized(ADMIN_ROLE) {
        address nftTrackerAddress = yoloRegistryContract.getContractAddress(
            NFT_TRACKER
        );

        require(
            nftTrackerAddress != address(0),
            "tracker address cannot be zero"
        );

        nftTrackerContract = NFTTracker(nftTrackerAddress);

        emit AddressSet(NFT_TRACKER, nftTrackerAddress);
    }

    /**
     * @notice Set {BiddersRewardsFactory} instance address.
     * @dev  `upgradeToken` checks for nonzero address, then calls `biddersRewardsContract.harvestBeforeUpgrade` call. This should always point to the latest active rewards contract. Give {BiddersRewardsFactory} privelages with `ADMIN_ROLE`
     **/
    function setBiddersRewardsFactoryContract(
        address biddersRewardsFactoryAddress
    ) external onlyAuthorized(ADMIN_ROLE) {
        require(
            biddersRewardsFactoryAddress != address(0),
            "rewards address cannot be zero"
        );

        biddersRewardsFactoryContract = BiddersRewardsFactory(
            biddersRewardsFactoryAddress
        );

        emit AddressSet(BIDDERS_REWARDS_FACTORY, biddersRewardsFactoryAddress);
    }

    /**
     * @notice Remove {BiddersRewardsFactory} instance address. Called when rewards schedule has concluded.
     * @dev Give {BiddersRewardsFactory} privelages with `ADMIN_ROLE`
     **/
    function removeBiddersRewardsFactoryContract()
        external
        onlyAuthorized(ADMIN_ROLE)
    {
        biddersRewardsFactoryContract = BiddersRewardsFactory(address(0));

        emit AddressSet(BIDDERS_REWARDS_FACTORY, address(0));
    }

    /**
     * @notice User can call in order to create a participation tracking SFT for rewards program.
     * @dev This is an unrestricted call to mint the base SFT. The base type must be initialized with a single call to `createBaseType` passing `isSFT` as true.
     **/
    function mintBaseSFT(address to) external onlyAuthorized(MINTER_ROLE) {
        _mintNFT(to, BASE_SFT_ID, EMPTY_STR);
    }

    /**
     * @notice User can upgrade after upgrade criteria met to receive boosted portion rewards disbursements. Round bid count and cumulative bid amounts used as metrics.
     * @dev note: user MUST harvest old rewards from previous epoch/cycle biddrs rewards contracts before `upgradeToken` is called, as their old token is burned on upgrade. Dependencies: {NFTTracker} with optional {BiddersRewardsFactory}. If for some reason, `nextLevelId` is improperly encoded, call will revert. Functionality does not break - once next level is fixed, can be called again.
     * @param id Token id.
     **/
    function upgradeToken(uint256 id) external {
        uint64 bidThreshold;
        uint192 cumulativeBidThreshold;
        uint256 nextLevelId;
        uint256 baseType;
        address sender;

        sender = msg.sender;

        require(id == usersTokens[sender], "not token owner");

        baseType = id.getBaseType();

        (
            bidThreshold,
            cumulativeBidThreshold,
            nextLevelId,

        ) = nftTrackerContract.levelRequirements(baseType);

        require(
            bidThreshold > 0 && cumulativeBidThreshold > 0 && nextLevelId > 0,
            "next level requirements not set"
        );

        uint64 roundCount;
        uint192 cumulativeBidAmount;

        (roundCount, cumulativeBidAmount) = nftTrackerContract.nftTrackingMap(
            id
        );

        require(
            roundCount >= bidThreshold &&
                cumulativeBidAmount >= cumulativeBidThreshold,
            "threshold requirements not met"
        );

        burn(sender, id, UNITY);

        // should we retrieve a URI if available or too gassy?
        if (
            nextLevelId.isSemiFungibleBaseType() ||
            nextLevelId.isNonFungibleBaseType()
        ) {
            _mintNFT(sender, nextLevelId, EMPTY_STR);
        } else {
            revert("improper nextLevelId encoding");
        }

        uint256 index = maxIndexes[nextLevelId];
        uint256 newTokenId = nextLevelId | index;

        // if rewards contract is updated, harvest on old rewards contract called to get rewards on old id BEFORE upgrading
        if (address(biddersRewardsFactoryContract) != address(0)) {
            uint256 rewardsAddressesLength = biddersRewardsFactoryContract
                .getRewardsAddressesLength();

            if (rewardsAddressesLength > 1) {
                address previousRewardsContract = biddersRewardsFactoryContract
                    .rewardsAddresses(rewardsAddressesLength - 2);

                BiddersRewards(previousRewardsContract).harvestOnUpgrade(
                    msg.sender,
                    id
                );
            }

            if (rewardsAddressesLength > 0) {
                BiddersRewards(
                    biddersRewardsFactoryContract.rewardsAddresses(
                        rewardsAddressesLength - 1
                    )
                ).bumpDuringUpgrade(id, newTokenId);
            }
        }

        emit TokenUpgrade(baseType, sender, nextLevelId);
    }
}

// contract names
bytes32 constant USDC_TOKEN = keccak256("USDC_TOKEN");
bytes32 constant YOLO_NFT = keccak256("YOLO_NFT");
bytes32 constant YOLO_SHARES = keccak256("YOLO_SHARES");
bytes32 constant YOLO_WALLET = keccak256("YOLO_WALLET");
bytes32 constant LIQUIDITY_POOL = keccak256("LIQUIDITY_POOL");
// bytes32 constant BETA_NFT_TRACKER = keccak256("BETA_NFT_TRACKER");
bytes32 constant NFT_TRACKER = keccak256("NFT_TRACKER");
bytes32 constant YOLO_NFT_PACK = keccak256("YOLO_NFT_PACK");
bytes32 constant BIDDERS_REWARDS = keccak256("BIDDERS_REWARDS");
bytes32 constant BIDDERS_REWARDS_FACTORY = keccak256("BIDDERS_REWARDS_FACTORY");
bytes32 constant LIQUIDITY_REWARDS = keccak256("LIQUIDITY_REWARDS");
bytes32 constant GAME_FACTORY = keccak256("GAME_FACTORY");

// game pairs
bytes32 constant ETH_USD = keccak256("ETH_USD");
bytes32 constant TSLA_USD = keccak256("TSLA_USD");
bytes32 constant DOGE_USD = keccak256("DOGE_USD");

// access control roles
bytes32 constant GAME_ADMIN_ROLE = keccak256("GAME_ADMIN_ROLE");
bytes32 constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");
bytes32 constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
bytes32 constant REWARDER_ROLE = keccak256("REWARDER_ROLE");
bytes32 constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
bytes32 constant MARKET_MAKER_ROLE = keccak256("MARKET_MAKER_ROLE");

// assets config
uint256 constant USDC_DECIMALS_FACTOR = 10**6;

// global parameters
bytes32 constant FEE_RATE_MIN = keccak256("FEE_RATE_MIN"); // in basis points
bytes32 constant FEE_RATE_MAX = keccak256("FEE_RATE_MAX"); // basis points

// Token Names and Symbols
string constant LIQUIDITY_POOL_TOKENS_NAME = "Yolo Liquidity Provider Shares";
string constant LIQUIDITY_POOL_TOKENS_SYMBOL = "BYLP";

// Common numeric values
uint256 constant STANDARD_FEE_RATE = 300;

pragma solidity 0.8.13;

/// @dev ZAA meaning Zero Address Assignment. {YLPToken} same as {LiquidityPool}.
error ZAA_YoloRegistry();
error ZAA_NFTTracker();
error ZAA_YoloNFTPack();
error ZAA_LiquidityPool();
error ZAA_MinterRole();
error ZAA_USDCToken();
error ZAA_YLPToken();
error ZAA_YoloWallet();
error ZAA_BiddersRewards();
error ZAA_BiddersRewardsFactory();

error ZAA_rewardsAdmin();
error ZAA_receiver();
error ZAA_treasuryAddress();
error ZAA_gameAdmin();

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

pragma solidity 0.8.13;

import {CoreCommon} from "./CoreCommon.sol";
import {YoloRegistry} from "./YoloRegistry.sol";
import {ADMIN_ROLE} from "../utils/constants.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {ZAA_YoloRegistry} from "../utils/errors.sol";

/**
 * @title RegistrySatellite
 * @author Garen Vartanian (@cryptokiddies)
 * @dev Base contract for all Yolo contracts that depend on {YoloRegistry} for references on other contracts (particularly their active addresses), supported assets (and their token addresses if applicable), registered game contracts, and master admins
 */
abstract contract RegistrySatellite is CoreCommon {
    // TODO: make `yoloRegistryContract` a constant hard-coded value after registry deployment

    YoloRegistry public immutable yoloRegistryContract;

    constructor(address yoloRegistryAddress_) {
        if (yoloRegistryAddress_ == address(0)) revert ZAA_YoloRegistry();

        yoloRegistryContract = YoloRegistry(yoloRegistryAddress_);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    event AddressSet(
        bytes32 indexed contractIdentifier,
        address indexed contractAddress
    );

    /**
     * @notice Check for authorization on local contract and fallback to {YoloRegistry} for additional checks.
     * @dev !!! should we simplify and replace access control on satellite contracts to simple owner address role, i.e., replace first check `hasRole(role, msg.sender)` with `msg.sender == owner`? Or do we move all role checks into registry contract?
     * @param role Role key to check authorization on.
     **/
    modifier onlyAuthorized(bytes32 role) {
        _checkAuthorization(role);
        _;
    }

    function _checkAuthorization(bytes32 role) internal view {
        if (
            !hasRole(role, msg.sender) &&
            !yoloRegistryContract.hasRole(role, msg.sender)
        ) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(msg.sender), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @notice Check for authorization on {GameInstance} contract registered in {YoloRegistry}.
     * @dev important to audit security on this call
     **/
    modifier onlyGameContract() {
        require(
            yoloRegistryContract.registeredGames(msg.sender),
            "caller isnt approved game cntrct"
        );
        _;
    }
}

pragma solidity 0.8.13;

import {AccessControlEnumerable} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ILiquidityPool} from "./ILiquidityPool.sol";
import {RegistrySatellite, YoloRegistry, CoreCommon} from "./RegistrySatellite.sol";
import {YoloShareTokens} from "../tokens/YoloShareTokens.sol";
import {YoloWallet} from "./YoloWallet.sol";
import {IYoloGame} from "../game/IYoloGame.sol";
import {USDC_TOKEN, YOLO_SHARES, YOLO_WALLET, ADMIN_ROLE, USDC_DECIMALS_FACTOR} from "../utils/constants.sol";
import {ZAA_USDCToken, ZAA_YoloWallet} from "../utils/errors.sol";

// import "hardhat/console.sol";

/**
 * @title LiquidityPool
 * @author Garen Vartanian (@cryptokiddies)
 * @author Yogesh Srihari(@yogeshgo05)
 * @dev :
 *  - grant a minter role to this contract from admin that allows for token minting
 *  - ability for holders to burn (destroy) their tokens
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} via {RegistrySatellite} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 */
contract LiquidityPool is ILiquidityPool, YoloShareTokens, RegistrySatellite {
    using SafeERC20 for IERC20;

    uint256 constant TWO_THOUSAND_TOKENS = 2000 * USDC_DECIMALS_FACTOR;

    // immutable because if either contract changes, a new LP cntct should be deployed anyway, so token migration can commence in clear, sequential steps
    IERC20 public immutable stablecoinTokenContract;
    YoloWallet public immutable walletContract;

    uint256 public protectionFactor;
    uint256 public marketLimit;
    uint256 public minimumDepositAmount;

    event MarketLimitUpdate(uint256 newLimitValue);

    error TotalSharesExceeded();
    error BurnRequirementNotMet();
    error DepositMinimumShortfall(
        uint256 cumulativeDepositAmount,
        uint256 minimumDepositAmount
    );

    modifier whenNotLPBalance() {
        require(totalSupply() == 0, "LP tokens are in circulation");
        _;
    }

    modifier whenLPBalance() {
        require(totalSupply() != 0, "must mint initial LP tokens");
        _;
    }

    modifier gtMinimumDepositBalance(uint256 depositAmount) {
        uint256 totalSupply = totalSupply();

        uint256 previousBalance = totalSupply > 0
            ? (balanceOf(msg.sender) * walletContract.balances(address(this))) /
                totalSupply
            : 0;

        uint256 cumulativeDepositAmount = depositAmount + previousBalance;

        if (cumulativeDepositAmount < minimumDepositAmount) {
            revert DepositMinimumShortfall(
                cumulativeDepositAmount,
                minimumDepositAmount
            );
        }
        _;
    }

    constructor(address registryContractAddress_)
        RegistrySatellite(registryContractAddress_)
    {
        YoloRegistry yoloRegistryContract = YoloRegistry(
            registryContractAddress_
        );

        address usdcTokenAddress = yoloRegistryContract.getContractAddress(
            USDC_TOKEN
        );

        if (usdcTokenAddress == address(0)) revert ZAA_USDCToken();

        address yoloWalletAddress = yoloRegistryContract.getContractAddress(
            YOLO_WALLET
        );

        if (yoloWalletAddress == address(0)) revert ZAA_YoloWallet();

        stablecoinTokenContract = IERC20(usdcTokenAddress);
        walletContract = YoloWallet(yoloWalletAddress);

        protectionFactor = 1000;
        minimumDepositAmount = 400 * USDC_DECIMALS_FACTOR;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlEnumerable, YoloShareTokens)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Check how many USDC tokens can be redeemed in exchange for burning LP shares. If burn value is greater than total share amount, call will fail.
     * @param burnAmount Amount of LP share to burn for USDC withdrawal.
     **/
    function getTokensRedeemed(uint256 burnAmount)
        external
        view
        returns (uint256 tokenTransferAmount)
    {
        uint256 sharesTotalSupply = totalSupply();
        if (burnAmount > sharesTotalSupply) {
            revert TotalSharesExceeded();
        }

        tokenTransferAmount =
            (burnAmount * walletContract.balances(address(this))) /
            sharesTotalSupply;
    }

    /**
     * @notice Sets `protectionFactor` value as part of additional guard layer on higher frequency `marketLimit` adjustments. See: `setMarketLimit` below.
     * @dev This value should float between ~500-20000 and updated only on big pool swings.
     * @param newFactor Simple factor to denominate acceptable marketLimit value in `setMarketLimit`.
     **/
    function setProtectionFactor(uint256 newFactor)
        external
        onlyAuthorized(ADMIN_ROLE)
    {
        protectionFactor = newFactor;
    }

    /**
     * @notice Sets `minimumDepositAmount` value regulatory mechanism on liquidity provision.
     * @dev This value should be denominated with 6 decimal places per USDC contract.
     * @param newMinimum Minimum USDC maintenance amount for liquidity provision.
     **/
    function setMinimumDepositAmount(uint256 newMinimum)
        external
        onlyAuthorized(ADMIN_ROLE)
    {
        minimumDepositAmount = newMinimum;
    }

    /**
     * @notice Mints initial LP shares if none exist.
     * @dev Contract will be in paused state as expected. Minting initial shares will add to contract USDC token balance
     * and unpause contract state. IF a minimum amount of 1000 is transferred from LP mint to zero address as guard against "donation" dilution gaming of LP contract, it is intended to prevent LP token dominance by transferring a bunch of USDC token after initial LP minting. If not, LP should be minted 1:1 with USDC token deposit amount. There is a slim possibility this is called more than once, in which case the caller will inherit USDC token dust.
     * @param initialAmount Amount of USDC deposited when no shares exist.
     **/
    function mintInitialShares(uint256 initialAmount)
        external
        whenNotLPBalance
        gtMinimumDepositBalance(initialAmount)
    {
        address sender = msg.sender;

        stablecoinTokenContract.safeTransferFrom(
            sender,
            address(walletContract),
            initialAmount
        );

        uint256 adjustmentFactor = 10**decimals() / USDC_DECIMALS_FACTOR;

        _mint(sender, initialAmount * adjustmentFactor);

        walletContract.updateLiquidityPoolBalance(initialAmount);
    }

    /**
     * @notice Mints LP shares on USDC token deposit.
     * @dev Contract must be in unpaused state. note: an issue addressed by Uniswap V2 whitepaper is dilution attack (dumping large amounts of token to LP contract directly via token contract), which is mitigated by subtracting and transferring 1000 wei of share tokens on initial mint to zero address. Not likely necessary.
     * @param depositAmount Amount of USDC deposited to contract.
     **/
    function mintLpShares(uint256 depositAmount)
        external
        whenLPBalance
        gtMinimumDepositBalance(depositAmount)
    {
        address sender = msg.sender;

        stablecoinTokenContract.safeTransferFrom(
            sender,
            address(walletContract),
            depositAmount
        );

        // should be 1:1 with current implementation
        uint256 newShareAmount = (totalSupply() * depositAmount) /
            walletContract.balances(address(this));

        _mint(sender, newShareAmount);

        walletContract.updateLiquidityPoolBalance(depositAmount);
    }

    /**
     * @notice Burns LP shares in exchange for share of pool USDC tokens. If provider balance remaining in pool is less than current `minimumDepositAmount`, then all LP tokens must be burned for redemption.
     * @dev  Will require share token approval from sender to contract to burn. Redemption amount check is to prevent minimum deposit circumvention.
     * @param burnAmount Amount of LP share to burn for USDC withdrawal.
     **/
    function burnLpShares(uint256 burnAmount) external {
        address sender = msg.sender;
        // !!! must call supply before burn
        uint256 sharesTotalSupply = totalSupply();
        uint256 senderTotalLP = balanceOf(sender);

        uint256 tokenTransferAmount = (burnAmount *
            walletContract.balances(address(this))) / sharesTotalSupply;

        if (burnAmount != senderTotalLP) {
            uint256 currentAccount = (senderTotalLP *
                walletContract.balances(address(this))) / sharesTotalSupply;

            if (currentAccount - tokenTransferAmount < minimumDepositAmount) {
                revert BurnRequirementNotMet();
            }
        }

        _burn(sender, burnAmount);

        // transfer comes from {YoloWallet} contract
        walletContract.reduceLiquidityPoolBalance(sender, tokenTransferAmount);
    }

    /**
     * @notice Set a market limit based on a small fraction of total USDC token balance and no more than 2,000 USDC tokens.
     * @dev  Query `marketLimit` regularly to adjust.
     * @param newLimitValue
     **/
    function setMarketLimit(uint256 newLimitValue)
        external
        onlyAuthorized(ADMIN_ROLE)
    {
        require(
            newLimitValue < TWO_THOUSAND_TOKENS &&
                newLimitValue <
                walletContract.balances(address(this)) / protectionFactor,
            "new limit val exceeds constraint"
        );

        marketLimit = newLimitValue;

        emit MarketLimitUpdate(newLimitValue);
    }
}

pragma solidity 0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {YoloRegistry} from "./YoloRegistry.sol";
import {RegistrySatellite} from "./RegistrySatellite.sol";
import {LiquidityPool} from "./LiquidityPool.sol";

import {LIQUIDITY_POOL, USDC_TOKEN, ADMIN_ROLE} from "../utils/constants.sol";
import {ZAA_USDCToken, ZAA_treasuryAddress, ZAA_LiquidityPool} from "../utils/errors.sol";

/**
 * @title YoloWallet
 * @author Garen Vartanian (@cryptokiddies)
 * @dev Important contract as it pools both user and liquidity pool (market maker) USDC token deposits into Yolo market system. Also maps addresses to usernames.
 */
contract YoloWallet is RegistrySatellite {
    using SafeERC20 for IERC20;

    uint256 constant BASIS_FEE_FACTOR = 10000;

    uint256 treasuryFeeBP;
    address lpAddress;
    address treasuryAddress;

    IERC20 stablecoinTokenContract;

    mapping(address => uint256) public balances; // balances in USDC
    // TODO: username struct bytes 31 & bool
    mapping(address => bytes32) public userNames;
    mapping(bytes32 => bool) public userNameChecks;

    event UsernameSet(
        bytes32 indexed previousUsername,
        address indexed sender,
        bytes32 indexed newUsername
    );
    event LiquidityReturn(address lpAddress, uint256 amount);
    event LiquidityReturnWithSplit(
        address lpAddress,
        uint256 lpAmount,
        address treasuryAddress,
        uint256 treasuryAmount,
        uint256 treasuryFeeBP
    );
    event TreasurySplitUpdate(
        address indexed treasuryAddress,
        uint256 newSplit
    );
    event TreasuryAddressUpdate(address indexed treasuryAddress);

    error CallerNotLPContract();

    constructor(address registryContractAddress_)
        RegistrySatellite(registryContractAddress_)
    {
        YoloRegistry registryContract = YoloRegistry(registryContractAddress_);

        address stablecoinTokenContractAddress = registryContract
            .getContractAddress(USDC_TOKEN);

        if (stablecoinTokenContractAddress == address(0))
            revert ZAA_USDCToken();

        stablecoinTokenContract = IERC20(stablecoinTokenContractAddress);
    }

    function setTreasuryAddress(address newTreasuryAddress)
        external
        onlyAuthorized(ADMIN_ROLE)
    {
        if (newTreasuryAddress == address(0)) revert ZAA_treasuryAddress();

        treasuryAddress = newTreasuryAddress;

        emit TreasuryAddressUpdate(newTreasuryAddress);
    }

    function removeTreasuryAddress() external onlyAuthorized(ADMIN_ROLE) {
        treasuryAddress = address(0);

        emit TreasuryAddressUpdate(address(0));
    }

    function setTreasurySplit(uint256 newBasisPoints)
        external
        onlyAuthorized(ADMIN_ROLE)
    {
        require(
            newBasisPoints < BASIS_FEE_FACTOR / 4,
            "must be l.t. quarter lp fee"
        );
        treasuryFeeBP = newBasisPoints;

        emit TreasurySplitUpdate(treasuryAddress, newBasisPoints);
    }

    /**
     * @notice Set a 32 ascii character username. Can only set a name that has not been claimed by another user. Cannot set to 0x00 aka "null".
     * @dev Can set name of sender address. If the name already exists, revert. If the user had a previous name, remove that exclusive claim.
     * @param userName New username.
     **/
    function setUserNames(bytes32 userName) external {
        address sender = msg.sender;

        require(userName != bytes32(0), "username cannot be null value");

        require(userNameChecks[userName] == false, "username already exists");

        bytes32 previousUsername = userNames[sender];

        if (previousUsername != bytes32(0)) {
            userNameChecks[previousUsername] = false;
        }

        userNames[sender] = userName;
        userNameChecks[userName] = true;

        emit UsernameSet(previousUsername, sender, userName);
    }

    /**
     * @notice Set {LiquidityPool} address.
     * @dev Required before any liquidity can be deposited with mint functions in {LiquidityPool}. Can make it a one-time call for absolute security.
     **/
    function setLiquidityPool() external onlyAuthorized(ADMIN_ROLE) {
        address lpAddr = yoloRegistryContract.getContractAddress(
            LIQUIDITY_POOL
        );

        if (lpAddr == address(0)) {
            revert ZAA_LiquidityPool();
        }

        lpAddress = lpAddr;

        _grantRole(LIQUIDITY_POOL, lpAddr);
    }

    /**
     * @notice {LiquidityPool} invoked function to increase liquidity pool wallet balance.
     * @dev This will not work unless `setMarketMakerRole` is called first.
     * @param amount The amount of USDC token to increase the liquidity pool account by.
     **/
    function updateLiquidityPoolBalance(uint256 amount)
        external
        onlyAuthorized(LIQUIDITY_POOL)
    {
        if (lpAddress == address(0)) {
            revert ZAA_LiquidityPool();
        }

        balances[lpAddress] += amount;
    }

    /**
     * @notice {LiquidityPool} invoked function to decrease liquidity pool wallet balance when providers burn YLP tokens in exchange for USDC tokens transfer.
     * @param amount The amount of USDC token to increase the liquidity pool account by.
     **/
    function reduceLiquidityPoolBalance(address receiver, uint256 amount)
        external
        onlyAuthorized(LIQUIDITY_POOL)
    {
        if (lpAddress == address(0)) revert ZAA_LiquidityPool();

        if (msg.sender != lpAddress) revert CallerNotLPContract();

        balances[lpAddress] -= amount;

        stablecoinTokenContract.safeTransfer(receiver, amount);
    }

    // TODO: adjust modifiers or design to allow a `SPECIAL_MIGRATOR_ROLE` to migrate tokens and user balances to future versions of {YoloWallet} contract. "Migration debt" mapping pattern.
    /**
     * @notice Game invoked internal transaction to batch update user balances, intended mainly for game settlements.
     * @dev should avoid loss altogether and try to reduce user balances on every user action instead. Additionally a try catch to handle balances that go below zero, as that is a serious error state.
     * @param user User address.
     * @param amount Amount to increase user balances by.
     **/
    /// @custom:scribble #if_succeeds balances[user] >= old(balances[user]);
    function gameUpdateUserBalance(address user, uint256 amount)
        external
        onlyGameContract
    {
        balances[user] += amount;
    }

    /**
     * @notice Game invoked internal transaction to update single user balance, mainly during game bids.
     * @dev Critical audits and reviews of this function (and contract) required.
     * @param user User addresses.
     * @param amount Updated balance amounts. Typically to reduce balane by bid amount.
     **/
    /// @custom:scribble #if_succeeds balances[user] <= old(balances[user]);
    function gameReduceUserBalance(address user, uint256 amount)
        external
        onlyGameContract
    {
        balances[user] -= amount;
    }

    /**
     * @notice Game invoked internal call to transfer USDC ({IERC20}) balance from the game to {LiquidityPool} address as fees.
     * @dev Critical audits and reviews of this function (and contract) required.
     * @param recipient Pool address.
     * @param lpReturn Amount of funds returned from settlement minus fees.
     * @param fees Fees drawn during round settlement.
     **/
    function returnLiquidity(
        address recipient,
        uint256 lpReturn,
        uint256 fees
    ) external onlyGameContract {
        uint256 splitFee = treasuryFeeBP;
        address treasuryAddr = treasuryAddress;

        if (splitFee > 0 && treasuryAddress != address(0)) {
            uint256 lpAmount = (fees * (BASIS_FEE_FACTOR - splitFee)) /
                BASIS_FEE_FACTOR +
                lpReturn;
            uint256 treasuryAmount = (fees * splitFee) / BASIS_FEE_FACTOR;

            balances[recipient] += lpAmount;
            balances[treasuryAddr] += treasuryAmount;
            emit LiquidityReturnWithSplit(
                recipient,
                lpAmount,
                treasuryAddr,
                treasuryAmount,
                splitFee
            );
        } else {
            uint256 lpAmount = lpReturn + fees;
            balances[recipient] += lpAmount;
            emit LiquidityReturn(recipient, lpAmount);
        }
    }

    /**
     * @notice Users call to withdraw USDC ({IERC20}) tokens from the {YoloWallet} contract to user's sender address.
     * @dev Critical audits and reviews of this function (and contract) required.
     * @param amount Amount of token transfer to sender.
     **/
    function withdraw(uint256 amount) external {
        address sender = msg.sender;

        require(amount > 0, "amount must be greater than 0");
        require(amount <= balances[sender], "withdraw amount exceeds balance");

        balances[sender] -= amount;

        stablecoinTokenContract.safeTransfer(sender, amount);
    }

    /**
     * @notice Auxiliary function to deposit USDC ({IERC20}) tokens to the {YoloWallet} contract from user's sender address.
     * @dev Useful for testing. Not a useful call for user as game instance will auto transfer any shortfall in funds directly.
     * @param amount Amount of token transfer to sender.
     **/
    function deposit(uint256 amount) external {
        address sender = msg.sender;
        require(amount > 0, "amount must be greater than 0");

        stablecoinTokenContract.safeTransferFrom(sender, address(this), amount);

        balances[sender] += amount;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./utils/DailyReturnsStructs.sol";

interface IDailyReturns {
    error MBStale(); // market bid
    error MBRoundParamsNotYetSpecified();
    error MBAmountExceedsLimit();
    error BidRoundParamsNotYetSpecified();
    error BidLate();
    error BidMinAmountRequired();
    error SPStartTimeZA();
    error SPStrikeBPMultipleZeroes();
    error SPMinStartDurationViolation();
    error SPStartTimeOffsetGTAllowed();
    error SPStrikeBPDeltaOutsideBounds();
    error SPNextRoundParamsReassignment();
    error PRSettlementPriceIsZero();
    error PRSettlementTimeNotReached();
    error PRRedundantCall();
    error SRStrikePriceZA();
    error SRStartTimeZeroValue();
    error SRUnprocessedRound();
    error SRStrikePriceDeltaIsZero();
    error RoundParamsMissing();

    function updateLpFee(uint256 newFee) external;

    function bid(
        uint96 amount,
        Levels level, // five levels
        uint72 bidRound
    ) external;

    function makeMarketBid(uint256 bidRound, uint96[5] calldata amounts)
        external;

    function processRound(uint128 settlementPrice) external;

    function startRound(uint128 strikePrice) external;

    function processAndStartRound(uint128 settlementPrice, uint128 strikePrice)
        external;
}

pragma solidity 0.8.13;

import "./DailyReturnsStructs.sol";

abstract contract DailyReturnsEvents {
    /**
     * @dev Set after settling previous round for the future round (not the current round).
     */
    event RoundParams(
        uint256 indexed roundIndex,
        uint112 startTime,
        int32[4] strikeBPDeltas
    );

    /**
     * @dev Currently emitted simultaneously with `RoundSettled` in same block as coupled.
     */
    event RoundStarted(
        uint256 indexed roundIndex,
        uint128 strikePrice,
        uint16 feeRate
    );

    /**
     * @dev Important log emitted after round is ended and processed with `RoundData` and `winningAmounts`. Combined with `FeeUpdate` event, accounts for all value processed in a round.
     */
    event RoundSettled(
        uint256 indexed roundIndex,
        RoundData finalGameInfo,
        SettlementData settlementData
    );

    event UserClaims(
        address indexed user,
        uint256[] winningRounds,
        uint256[] winningAmounts
    );

    /**
     * @dev Emitted when the bidder/user calls a game {bid**} method.
     * `gameId` gives the exact game,
     * `isUp` indicates whether bid is up or down in binary type markets
     */
    event BidMade(
        uint256 indexed roundIndex,
        address indexed bidder,
        uint96 amount,
        Levels level
    );

    /**
     * @dev Liquidity provided on behalf of the {LiquidityPool} to a {GameInstance}
     */
    event LiquidityProvision(
        uint256 indexed bidRound,
        address provider,
        address lpContractAddress,
        uint96[5] levelAmounts
    );

    /**
     * @dev Anytime a {GameInstance} instance has its round fee updated (in basis points).
     */
    event FeeUpdate(uint256 newFee);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity 0.8.13;

import {AccessControlEnumerable} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import {ADMIN_ROLE} from "../utils/constants.sol";

/**
 * @title CoreCommon
 * @author Garen Vartanian (@cryptokiddies)
 * @dev pulling in {CoreCommon} will also bring in {AccessControlEnumerable},
 * {AccessControl}, {ERC165} and {Context} contracts/libraries. {ERC165} will support IAccessControl and IERC165 interfaces.
 */
abstract contract CoreCommon is AccessControlEnumerable {
    /**
     * @notice used to restrict critical method calls to admin only
     * @dev consider removing `ADMIN_ROLE` altogether, although it may be useful in near future for assigning roles.
     */
    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
                hasRole(ADMIN_ROLE, msg.sender),
            "Must have admin role to invoke"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity 0.8.13;

interface ILiquidityPool {
    // **** restricted ****
    function setProtectionFactor(uint256 newFactor) external;

    function setMarketLimit(uint256 newLimitValue) external;

    // ********

    function mintInitialShares(uint256 initialAmount) external;

    function mintLpShares(uint256 depositAmount) external;

    function burnLpShares(uint256 burnAmount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import {ERC20Burnable, ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Pausable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import {LIQUIDITY_POOL_TOKENS_NAME, LIQUIDITY_POOL_TOKENS_SYMBOL, MINTER_ROLE, PAUSER_ROLE} from "../utils/constants.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This abstract contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles.
 */
abstract contract YoloShareTokens is AccessControlEnumerable, ERC20Pausable {
    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    constructor()
        ERC20(LIQUIDITY_POOL_TOKENS_NAME, LIQUIDITY_POOL_TOKENS_SYMBOL)
    {
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC20).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements: the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(
            hasRole(PAUSER_ROLE, msg.sender),
            "ERC20PresetMinterPauser: must have pauser role to pause"
        );
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(
            hasRole(PAUSER_ROLE, msg.sender),
            "ERC20PresetMinterPauser: must have pauser role to unpause"
        );
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

interface IYoloGame {
    function updateLpFee(uint256 newFee) external;

    function bidInYolo(
        uint96 amount,
        bool isUp,
        uint72 bidRound
    ) external;

    function makeMarketBid(uint256 bidRound, uint128[2] calldata amounts)
        external;

    function processRound(
        uint112 startTime,
        uint128 settlementPrice,
        uint128 nextStrikePrice
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

pragma solidity 0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {BiddersRewardsFactory} from "./BiddersRewardsFactory.sol";
import {YoloRegistry} from "../core/YoloRegistry.sol";
import {NFTTracker} from "../core/NFTTracker.sol";
import {RegistrySatellite} from "../core/RegistrySatellite.sol";
import {YoloNFTPack} from "../tokens/YoloNFTPack.sol";
import {SplitBitId} from "../utils/SplitBitId.sol";
import {USDC_TOKEN, NFT_TRACKER, YOLO_NFT_PACK, BIDDERS_REWARDS_FACTORY, REWARDER_ROLE, USDC_DECIMALS_FACTOR} from "../utils/constants.sol";
import {ZAA_USDCToken, ZAA_receiver} from "../utils/errors.sol";

// import "hardhat/console.sol";
// import "../utils/LogBinary.sol";

/**
 * @title BiddersRewards
 * @author Garen Vartanian (@cryptokiddies)
 * @notice Reward participants vis-a-vis NFT linked data on bid count and cumulative amount bid, i.e., ids are linked to the users' NFT, not user addresses. Reward amount is based on nft tranche that nft base id is linked to. "Participation units" are measured by weighting bid count and amounts.
 * @dev SFT/NFT tranches are determined via bit masking upper bits for base type. Funds are split among tranches based on reward multiplier normalization at end of ~30 days. {BiddersRewardsFactory} is config controller, which switches the {NFTTracker} & {YoloNFTPack} to point to the new rewards contract synchronously. Funding is more straightforward as directly called on this contract for admin actions like funding and releasing.
 */
contract BiddersRewards is RegistrySatellite {
    // TODO: reduce type sizes - can go to 128 on all, lower on some
    struct LevelPoolInfo {
        uint128 reward;
        uint128 totalPaidOut;
    }

    struct NftData {
        uint64 roundCount;
        uint192 cumulativeBidAmount;
    }

    struct LevelTracking {
        uint64 totalRoundCount;
        uint192 totalCumulativeBidAmount;
    }

    using SplitBitId for uint256;
    using SafeERC20 for IERC20;
    // using LogBinary for uint256;

    // absolute max fund amount at one time - 2.5M tokens
    uint256 constant MAX_FUND_LIMIT = 1.5 * 10**5 * USDC_DECIMALS_FACTOR;

    uint256 public immutable startTime;
    uint256 public immutable epoch;

    // Maximum allowable fund amount, sanity check
    uint256 maxFundAmount;
    // process funds amongst levels
    bool public isReleased;
    bool public hasFunding;
    // divide weights out in denominator - integer truncation should not be concern as rewards multiplier covers USDC decimals
    uint256 public countWeight = 5 * USDC_DECIMALS_FACTOR; // add 10**6 factor to balance token factor (USDC)

    // Address of the USDC ERC20 Token contract.
    IERC20 stablecoinTokenContract;
    NFTTracker nftTrackerContract;
    YoloNFTPack yoloNFTPackContract;
    BiddersRewardsFactory rewardsFactoryContract;

    /**
     * key The nft id of the token that is tracked
     * @notice Token activity for calculating this epoch's token mapped USDC token rewards.
     * @dev The param is Yolo NFT token index. Public function will return `roundCount` and `cumulativeBidAmount`.
     * @return roundCount cumulativeBidAmount Struct `roundCount` and `cumulativeBidAmount` fields.
     **/
    mapping(uint256 => NftData) public epochTokenTracker;

    /**
     * key The SFT/NFT basetype id.
     * @notice Tracks total round bid count and cumulative amounts within a SFT/NFT tier.
     * @dev compact uint types are sufficient for tracking tokens.
     * @return totalRoundCount totalCumulativeBidAmount.
     **/
    mapping(uint256 => LevelTracking) public levelTrackingMap;

    mapping(uint256 => LevelPoolInfo) public poolInfos;
    // nftId returns rewardDebt
    mapping(uint256 => bool) public harvestLogs;

    event RewardsBidTracking(
        uint256 indexed tokenIndex,
        uint256 newRoundBid,
        uint192 amount
    );

    event FundRelease(uint256 indexed epoch, address caller);

    event RedundantReleaseRequest(uint256 indexed epoch, address caller);

    event Funding(address indexed admin, uint256 amount);

    event Harvest(
        address indexed caller,
        address indexed recipient,
        uint256 indexed tokenId,
        uint256 amount
    );

    event MaxFundSet(uint256 newMaxFundAmount);
    event NewCountWeight(uint256 newCountWeight);

    error CallerNotNFTPack();
    error CallerNotNFTTracker();
    error SetCountAfterRelease();

    constructor(
        address rewardsAdmin_,
        address registryContractAddress_,
        uint256 epoch_,
        NFTTracker trackerInstance_,
        YoloNFTPack nftPackInstance_
    ) RegistrySatellite(registryContractAddress_) {
        YoloRegistry registryContract = YoloRegistry(registryContractAddress_);

        address stablecoinTokenContractAddress = registryContract
            .getContractAddress(USDC_TOKEN);

        if (stablecoinTokenContractAddress == address(0))
            revert ZAA_USDCToken();

        require(
            msg.sender ==
                registryContract.getContractAddress(BIDDERS_REWARDS_FACTORY),
            "sender must be rewards factory"
        );

        rewardsFactoryContract = BiddersRewardsFactory(msg.sender);
        stablecoinTokenContract = IERC20(stablecoinTokenContractAddress);
        nftTrackerContract = trackerInstance_;
        yoloNFTPackContract = nftPackInstance_;

        _grantRole(REWARDER_ROLE, rewardsAdmin_);
        _grantRole(YOLO_NFT_PACK, address(nftPackInstance_));
        _grantRole(NFT_TRACKER, address(trackerInstance_));

        startTime = block.timestamp;
        epoch = epoch_;
    }

    function getUserPendingReward(uint256 id)
        external
        view
        returns (uint256 pendingReward)
    {
        uint256 participationWeight = getUserParticipationWeight(id);

        if (!harvestLogs[id]) {
            uint256 totalLevelWeighting = getTotalLevelWeighting(
                id.getBaseType()
            );
            uint256 latestYOLOInLevel = getLatestLevelReward(id);

            pendingReward =
                (participationWeight * latestYOLOInLevel) /
                totalLevelWeighting;
        } else {
            pendingReward = 0;
        }
    }

    function getUserParticipationWeight(uint256 _nftId)
        public
        view
        returns (uint256)
    {
        uint64 roundCount;
        uint192 cumulativeAmount;

        (roundCount, cumulativeAmount) = _getNFTStats(_nftId);

        return roundCount * countWeight + cumulativeAmount;
    }

    function getLatestLevelReward(uint256 id)
        public
        view
        returns (uint256 levelYoloReward)
    {
        uint256 baseType = id.getBaseType();

        uint256 yoloReward = stablecoinTokenContract.balanceOf(address(this));
        uint256 multiplier = nftTrackerContract.rewardsMultipliers(baseType);

        uint256 totalLevelWeighting = getTotalLevelWeighting(baseType);
        uint256 allLevelsWeighting = getCombinedLevelsWeighting();

        levelYoloReward =
            (yoloReward * totalLevelWeighting * multiplier) /
            allLevelsWeighting;
    }

    function getTotalLevelWeighting(uint256 baseType)
        public
        view
        returns (uint256 totalLevelWeighting)
    {
        (
            uint256 totalRoundCount,
            uint256 totalCumulativeBidAmount
        ) = getLevelCountAndAmount(baseType);

        if (totalRoundCount > 0) {
            totalLevelWeighting =
                totalRoundCount *
                countWeight +
                totalCumulativeBidAmount;
        }
    }

    function getLevelCountAndAmount(uint256 baseType)
        public
        view
        returns (uint256 totalRoundCount, uint256 totalCumulativeBidAmount)
    {
        require(
            baseType.isSemiFungibleBaseType() ||
                baseType.isNonFungibleBaseType(),
            "improper encoding for base type"
        );

        LevelTracking memory levelTracking = levelTrackingMap[baseType];

        totalRoundCount = levelTracking.totalRoundCount;
        totalCumulativeBidAmount = levelTracking.totalCumulativeBidAmount;
    }

    function getCombinedLevelsWeighting()
        public
        view
        returns (uint256 weightedMultiplierSum)
    {
        uint256 nftLevelIdsListLength = nftTrackerContract
            .getNFTLevelIdsLength();
        uint256[] memory nftLevelIdsList;

        require(nftLevelIdsListLength > 0, "no NFT levels exist");

        // repeated calls to previously accessed external contracts should be cheaper
        nftLevelIdsList = nftTrackerContract.getNFTLevelsListRange(
            0,
            nftLevelIdsListLength
        );

        uint256 nftLevelId;
        uint256 rewardsMultiplier;

        for (uint256 i; i < nftLevelIdsListLength; i++) {
            nftLevelId = nftLevelIdsList[i];

            LevelTracking memory levelTracking = levelTrackingMap[nftLevelId];

            uint64 totalRoundCount = levelTracking.totalRoundCount;
            uint192 totalCumulativeBidAmount = levelTracking
                .totalCumulativeBidAmount;

            rewardsMultiplier = nftTrackerContract.rewardsMultipliers(
                nftLevelId
            );

            require(rewardsMultiplier > 0, "set all rewards multipliers");

            uint256 levelWeighting = rewardsMultiplier *
                (totalRoundCount * countWeight + totalCumulativeBidAmount);

            weightedMultiplierSum += levelWeighting;
        }
    }

    function _getNFTStats(uint256 id)
        private
        view
        returns (uint64 roundCount, uint192 cumulativeBidAmount)
    {
        NftData memory tracking = epochTokenTracker[id];
        roundCount = tracking.roundCount;
        cumulativeBidAmount = tracking.cumulativeBidAmount;
    }

    function setCountWeight(uint256 newCountWeight)
        external
        onlyAuthorized(REWARDER_ROLE)
    {
        if (isReleased == true) revert SetCountAfterRelease();

        countWeight = newCountWeight;

        emit NewCountWeight(newCountWeight);
    }

    function setMaxFundAmount(uint256 newMaxFundAmount)
        external
        onlyAuthorized(REWARDER_ROLE)
    {
        require(newMaxFundAmount <= MAX_FUND_LIMIT, "new max exceeds limit");
        maxFundAmount = newMaxFundAmount;

        emit MaxFundSet(newMaxFundAmount);
    }

    // sanity check with maxFundAmount
    function fund(uint256 amount) external onlyAuthorized(REWARDER_ROLE) {
        require(amount <= maxFundAmount, "amount exceeds max allowable");
        require(!isReleased, "rewards previously processed");

        stablecoinTokenContract.safeTransferFrom(
            address(msg.sender),
            address(this),
            amount
        );

        hasFunding = true;
        // console.log(
        //     "token balance: %s",
        //     stablecoinTokenContract.balanceOf(address(this))
        // );

        emit Funding(msg.sender, amount);
    }

    // note: care to keep level list small - alternate approach, have each level processed individually on first harvest call by basetype holder
    function releaseFunds() external {
        if (isReleased == true) {
            emit RedundantReleaseRequest(epoch, msg.sender);
            return;
        }

        require(
            msg.sender == address(rewardsFactoryContract) ||
                block.timestamp > startTime + 30 days,
            "factory call or seasoned 30 days"
        );

        // get nft levels list and grab highest level for the highest multiplier and THEN require best reward per block lower than amount sent

        uint256 nftLevelIdsListLength = nftTrackerContract
            .getNFTLevelIdsLength();
        uint256[] memory levelWeightings = new uint256[](nftLevelIdsListLength);
        uint256[] memory nftLevelIdsList;
        uint256 weightingSum;

        require(nftLevelIdsListLength > 0, "no NFT levels exist");

        // repeated calls to previously accessed external contracts should be cheaper
        nftLevelIdsList = nftTrackerContract.getNFTLevelsListRange(
            0,
            nftLevelIdsListLength
        );

        for (uint256 i = 0; i < nftLevelIdsListLength; i++) {
            uint256 nftLevelId;
            uint256 rewardsMultiplier;

            nftLevelId = nftLevelIdsList[i];
            rewardsMultiplier = nftTrackerContract.rewardsMultipliers(
                nftLevelId
            );

            require(rewardsMultiplier > 0, "set all rewards multipliers");

            LevelTracking memory levelTracking = levelTrackingMap[nftLevelId];

            uint64 totalRoundCount = levelTracking.totalRoundCount;
            uint192 totalCumulativeBidAmount = levelTracking
                .totalCumulativeBidAmount;

            uint256 levelWeighting = rewardsMultiplier *
                (totalRoundCount * countWeight + totalCumulativeBidAmount);

            levelWeightings[i] = levelWeighting;

            weightingSum += levelWeighting;

            // console.log(
            //     "multiplier %s",
            //     nftTrackerContract.rewardsMultipliers(nftLevelId)
            // );
            // console.log("bid count total %s", totalRoundCount);
            // console.log("multiplier sum %s", weightingSum);
        }

        uint256 totalRewardsBalance = stablecoinTokenContract.balanceOf(
            address(this)
        );

        for (uint256 i; i < nftLevelIdsListLength; i++) {
            // do rewards proportions per level
            // will throw panic code is no users have bid
            // note: reward should have correct token decimal factor for division for this expression to be acceptable
            poolInfos[nftLevelIdsList[i]].reward = uint128(
                (totalRewardsBalance * levelWeightings[i]) / weightingSum
            );
        }

        // console.log(
        //     "token balance: %s",
        //     stablecoinTokenContract.balanceOf(address(this))
        // );
        // console.log("total reward per block: %s", totalRewardsBalance);

        isReleased = true;

        emit FundRelease(epoch, msg.sender);
    }

    /**
     * @notice Only for this rewards epoch, track user activity for calculating USDC token rewards.
     * @dev Bid count should be incremented only once per round. Since blockchain cannot check ownership history internally, cannot batch call this later. Must be on bid. Bypass tracking if rewards distribution already calculated to prevent unlikely but undesired edge case.
     * @param tokenIndex Yolo NFT token index.
     * @param amount Amount bid in USDC.
     * @param newRoundBid Bid round of game instance.
     **/
    function updateTracking(
        uint256 tokenIndex,
        uint256 newRoundBid,
        uint192 amount
    ) external onlyAuthorized(NFT_TRACKER) {
        if (msg.sender != address(nftTrackerContract))
            revert CallerNotNFTTracker();

        // TODO: add unit test for isReleased and token encoding
        if (isReleased == true) {
            return;
        }

        require(
            tokenIndex.isSemiFungibleItem() || tokenIndex.isNonFungibleItem(),
            "invalid token encoding"
        );

        NftData storage nftTracking = epochTokenTracker[tokenIndex];

        uint256 tokenBase = tokenIndex.getBaseType();

        LevelTracking storage levelTracker = levelTrackingMap[tokenBase];

        nftTracking.cumulativeBidAmount += amount;
        levelTracker.totalCumulativeBidAmount += amount;

        if (newRoundBid == 1) {
            nftTracking.roundCount++;
            levelTracker.totalRoundCount++;
        }

        emit RewardsBidTracking(tokenIndex, newRoundBid, amount);
    }

    /// @dev not using recursion to support multiple level advances, kiss
    function bumpDuringUpgrade(uint256 oldTokenId, uint256 newTokenId)
        external
        onlyAuthorized(YOLO_NFT_PACK)
    {
        if (msg.sender != address(yoloNFTPackContract))
            revert CallerNotNFTPack();

        NftData storage oldNftTracking = epochTokenTracker[oldTokenId];
        NftData storage newNftTracking = epochTokenTracker[newTokenId];
        LevelTracking storage oldLevelTracking = levelTrackingMap[
            oldTokenId.getBaseType()
        ];
        LevelTracking storage newLevelTracking = levelTrackingMap[
            newTokenId.getBaseType()
        ];

        uint64 roundCount = oldNftTracking.roundCount;
        uint192 cumulativeBidAmount = oldNftTracking.cumulativeBidAmount;

        oldNftTracking.roundCount = 0;
        oldNftTracking.cumulativeBidAmount = 0;

        oldLevelTracking.totalRoundCount -= roundCount;
        oldLevelTracking.totalCumulativeBidAmount -= cumulativeBidAmount;

        newNftTracking.roundCount = roundCount;
        newNftTracking.cumulativeBidAmount = cumulativeBidAmount;

        newLevelTracking.totalRoundCount += roundCount;
        newLevelTracking.totalCumulativeBidAmount += cumulativeBidAmount;
    }

    // cant allow operators to call this
    function harvest(address to) public {
        require(isReleased == true, "funds must be processed");
        if (to == address(0)) revert ZAA_receiver();

        uint256 tokenId;
        uint256 userParticipationUnits;

        tokenId = yoloNFTPackContract.usersTokens(msg.sender);

        userParticipationUnits = getUserParticipationWeight(tokenId);

        require(userParticipationUnits > 0, "no participation units on token");
        require(!harvestLogs[tokenId], "has harvested this epoch");

        LevelPoolInfo storage levelPoolInfo = poolInfos[tokenId.getBaseType()];

        require(levelPoolInfo.reward > 0, "no rewards to harvest");

        _harvest(to, tokenId, userParticipationUnits, levelPoolInfo);
    }

    function harvestOnUpgrade(address user, uint256 tokenId)
        external
        onlyAuthorized(YOLO_NFT_PACK)
    {
        // TODO: make sure factory is used to control releasing or breaks upgrade
        if (msg.sender != address(yoloNFTPackContract))
            revert CallerNotNFTPack();

        require(isReleased == true, "funds must be processed");

        uint256 userParticipationUnits;

        userParticipationUnits = getUserParticipationWeight(tokenId);
        // console.log("user participation: %s", userParticipationUnits);

        LevelPoolInfo storage levelPoolInfo = poolInfos[tokenId.getBaseType()];

        if (
            userParticipationUnits > 0 &&
            !harvestLogs[tokenId] &&
            levelPoolInfo.reward > 0
        ) {
            _harvest(user, tokenId, userParticipationUnits, levelPoolInfo);
        }
    }

    // keep args uint256, don't need to mask and encode
    function _harvest(
        address to,
        uint256 tokenId,
        uint256 userParticipationUnits,
        LevelPoolInfo storage levelPoolInfo
    ) private {
        // roundCount * countWeight + cumulativeBidAmount;

        uint256 totalLevelUnits = getTotalLevelWeighting(tokenId.getBaseType());

        uint256 rewardsYolo = (userParticipationUnits * levelPoolInfo.reward) /
            totalLevelUnits;

        harvestLogs[tokenId] = true;

        stablecoinTokenContract.safeTransfer(to, rewardsYolo);
        levelPoolInfo.totalPaidOut += uint128(rewardsYolo);
        emit Harvest(msg.sender, to, tokenId, rewardsYolo);
    }

    function recoverFunds(address receiver)
        external
        onlyAuthorized(REWARDER_ROLE)
    {
        require(
            block.timestamp > startTime + 60 days,
            "requires 60 days post deployment"
        );

        if (receiver == address(0)) revert ZAA_receiver();

        stablecoinTokenContract.safeTransfer(
            receiver,
            stablecoinTokenContract.balanceOf(address(this))
        );
    }
}

pragma solidity 0.8.13;

library SplitBitId {
    // Store the type in the upper 128 bits..
    uint256 constant TYPE_MASK = type(uint256).max << 128;

    // ..and the non-fungible index in the lower 128
    uint256 constant NF_INDEX_MASK = type(uint128).max;

    // The top bit is a flag to tell if this is a NFT.
    uint256 constant TYPE_NF_BIT = 1 << 255;

    // Flag as 1100...00 for SFT.
    uint256 constant TYPE_SEMI_BIT = uint256(3) << 254;

    // note: use SEMI_BIT bitwise mask and then compare to NF_BIT
    function isNonFungible(uint256 _id) internal pure returns (bool) {
        return _id & TYPE_SEMI_BIT == TYPE_NF_BIT;
    }

    function isSemiFungible(uint256 _id) internal pure returns (bool) {
        return _id & TYPE_SEMI_BIT == TYPE_SEMI_BIT;
    }

    // note: operate with SEMI_BIT as mask but compare to NF_BIT
    function isNonFungibleItem(uint256 _id) internal pure returns (bool) {
        // A base type has the NF bit but does have an index.
        return
            (_id & TYPE_SEMI_BIT == TYPE_NF_BIT) && (_id & NF_INDEX_MASK != 0);
    }

    // note: operate with SEMI_BIT but compare to NF_BIT
    function isNonFungibleBaseType(uint256 _id) internal pure returns (bool) {
        // A base type has the NF bit but does not have an index.
        return
            (_id & TYPE_SEMI_BIT == TYPE_NF_BIT) && (_id & NF_INDEX_MASK == 0);
    }

    function isSemiFungibleItem(uint256 _id) internal pure returns (bool) {
        // A base type has the Semi bit but does have an index.
        return
            (_id & TYPE_SEMI_BIT == TYPE_SEMI_BIT) &&
            (_id & NF_INDEX_MASK != 0);
    }

    function isSemiFungibleBaseType(uint256 _id) internal pure returns (bool) {
        // A base type has the Semi bit but does not have an index.
        return
            (_id & TYPE_SEMI_BIT == TYPE_SEMI_BIT) &&
            (_id & NF_INDEX_MASK == 0);
    }

    function getNonFungibleIndex(uint256 _id) internal pure returns (uint256) {
        return _id & NF_INDEX_MASK;
    }

    function getBaseType(uint256 _id) internal pure returns (uint256) {
        return _id & TYPE_MASK;
    }

    function encodeNewNonFungibleBaseType(uint256 _rawNonce)
        internal
        pure
        returns (uint256)
    {
        return (_rawNonce << 128) | TYPE_NF_BIT;
    }

    function encodeNewSemiFungibleBaseType(uint256 _rawNonce)
        internal
        pure
        returns (uint256)
    {
        return (_rawNonce << 128) | TYPE_SEMI_BIT;
    }
}

pragma solidity 0.8.13;

import {YoloRegistry} from "../core/YoloRegistry.sol";
import {RegistrySatellite} from "../core/RegistrySatellite.sol";
import {BiddersRewards} from "./BiddersRewards.sol";
import {NFTTracker} from "../core/NFTTracker.sol";
import {YoloNFTPack} from "../tokens/YoloNFTPack.sol";
import {ADMIN_ROLE} from "../utils/constants.sol";
import {YOLO_NFT_PACK, NFT_TRACKER} from "../utils/constants.sol";
import {ZAA_NFTTracker, ZAA_YoloNFTPack, ZAA_rewardsAdmin} from "../utils/errors.sol";

contract BiddersRewardsFactory is RegistrySatellite {
    bool _hasStarted;
    uint256 public epoch;

    address[] public rewardsAddresses;

    event BiddersRewardsCreation(
        uint256 indexed epoch,
        address newRewardsAddress
    );

    constructor(address registryContractAddress_)
        RegistrySatellite(registryContractAddress_)
    {}

    /**
     * @notice Get `rewardsAddresses` array length.
     * @return uint256 length.
     **/
    function getRewardsAddressesLength() public view returns (uint256) {
        return rewardsAddresses.length;
    }

    function rotateRewardsContracts(address rewardsAdmin)
        external
        onlyAuthorized(ADMIN_ROLE)
    {
        if (rewardsAdmin == address(0)) revert ZAA_rewardsAdmin();

        address nftTrackerContractAddress = yoloRegistryContract
            .getContractAddress(NFT_TRACKER);

        if (nftTrackerContractAddress == address(0)) revert ZAA_NFTTracker();

        NFTTracker nftTrackerContract = NFTTracker(nftTrackerContractAddress);

        address yoloNftPackContractAddress = yoloRegistryContract
            .getContractAddress(YOLO_NFT_PACK);

        if (yoloNftPackContractAddress == address(0)) revert ZAA_YoloNFTPack();

        YoloNFTPack yoloNFTPackContract = YoloNFTPack(
            yoloNftPackContractAddress
        );

        address newRewardsAddress = address(
            new BiddersRewards(
                rewardsAdmin,
                address(yoloRegistryContract),
                ++epoch,
                nftTrackerContract,
                yoloNFTPackContract
            )
        );

        if (_hasStarted == true) {
            BiddersRewards priorRewardsContract = BiddersRewards(
                rewardsAddresses[getRewardsAddressesLength() - 1]
            );

            require(
                priorRewardsContract.hasFunding(),
                "prior cntct requires funds"
            );

            priorRewardsContract.releaseFunds();
        }

        rewardsAddresses.push(newRewardsAddress);

        nftTrackerContract.setBiddersRewardsContract(newRewardsAddress);

        if (_hasStarted == false) {
            _hasStarted = true;
        }

        emit BiddersRewardsCreation(epoch, newRewardsAddress);
    }

    function endRewards() external onlyAuthorized(ADMIN_ROLE) {
        require(_hasStarted == true, "rewards not started");

        address nftTrackerContractAddress = yoloRegistryContract
            .getContractAddress(NFT_TRACKER);

        if (nftTrackerContractAddress == address(0)) revert ZAA_NFTTracker();

        NFTTracker nftTrackerContract = NFTTracker(nftTrackerContractAddress);

        address yoloNftPackContractAddress = yoloRegistryContract
            .getContractAddress(YOLO_NFT_PACK);

        if (yoloNftPackContractAddress == address(0)) revert ZAA_YoloNFTPack();

        YoloNFTPack yoloNFTPackContract = YoloNFTPack(
            yoloNftPackContractAddress
        );

        BiddersRewards(rewardsAddresses[getRewardsAddressesLength() - 1])
            .releaseFunds();

        _hasStarted = false;

        nftTrackerContract.removeBiddersRewardsContract();
        yoloNFTPackContract.removeBiddersRewardsFactoryContract();
    }
}

pragma solidity 0.8.13;

import {AccessControlEnumerable} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ERC1155Pausable} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import {ERC1155Burnable} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

import {RegistrySatellite} from "../../core/RegistrySatellite.sol";
import {ERC1155DynamicURI} from "./ERC1155DynamicURI.sol";
import {SplitBitId} from "../../utils/SplitBitId.sol";
import {MINTER_ROLE, PAUSER_ROLE} from "../../utils/constants.sol";

// import {LogBinary} from "../../utils/LogBinary.sol";
// import "hardhat/console.sol";

/**
 * @title ERC1155SemiFungible
 * @author Garen Vartanian (@cryptokiddies)
 * @notice Each address can only have one at most of each token. Credit @JamesTherien github @ enjin/erc-1155 for split bit.
 * @dev Modification of {ERC1155MixedFungible} to provide semi-fungible (SFT) and NFT support in split bit compact form w/max balance of 1 per address. SFT base types will all share the same metadata uri.
 */
abstract contract ERC1155SemiFungible is
    RegistrySatellite,
    ERC1155Burnable,
    ERC1155Pausable,
    ERC1155DynamicURI
{
    struct BasetypeManagement {
        uint128 balance;
        uint128 maxCapacity;
    }

    // Use a split bit implementation.
    using SplitBitId for uint256;
    // using LogBinary for uint256;

    bytes constant EMPTY_BYTES = "";
    // for minting NFT/SFT
    uint256 constant UNITY = 1;

    // Should be typed smaller than 127 to work with SEMI_BIT but should be far scarcer in practice
    uint120 private _nftNonce;
    uint120 private _semiFtNonce;

    mapping(uint256 => address) private _nftOwners;

    // TODO: discuss necessity of type existence checking, validation vs efficiency tradeoff
    mapping(uint256 => bool) public typeBirthCertificates;
    // gets token id for provided address; inverse of _nftOwners
    mapping(address => uint256) public usersTokens;
    // gets number of SFT/NFTs belonging to base type
    mapping(uint256 => uint120) public maxIndexes;
    // total balance by nft level
    mapping(uint256 => BasetypeManagement) public basetypesManagement;

    event TokenLevelMaxCapSetting(uint256 indexed basetype, uint256 maxCap);

    constructor() {
        grantRole(MINTER_ROLE, msg.sender);
        grantRole(PAUSER_ROLE, msg.sender);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC1155, ERC1155DynamicURI)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Get owner address of SFT/NFT by ID.
     * @dev User should only have total balance of one token on contract for this logic to function properly.
     * @param id Token id.
     **/
    function ownerOf(uint256 id) public view returns (address) {
        return _nftOwners[id];
    }

    /**
     * @notice Return the `uri` for a unique NFT or for a SFT set.
     * @dev {ERC1155DynamicURI} defines custom logic for setting `uri` based on token classification of SFT vs NFT, which is determined by token id encoding.
     * @param id Token id.
     **/
    function uri(uint256 id)
        public
        view
        override(ERC1155DynamicURI, ERC1155)
        returns (string memory)
    {
        return ERC1155DynamicURI.uri(id);
    }

    /**
     * @notice Get owner address of SFT/NFT by ID.
     * @dev User should only have total balance of one token on contract for this logic to function properly.
     * @param id Token id.
     **/
    function balanceOf(address owner, uint256 id)
        public
        view
        override
        returns (uint256)
    {
        require(owner != address(0), "balance query for the zero address");
        return _nftOwners[id] == owner ? UNITY : 0;
    }

    /**
     * @notice Get owner balances of SFT/NFT by IDs.
     * @dev Each user should only have a total balance of one token on contract, i.e., one address can't have more than one token id mapped to it.
     * @param owners Token owner addresses.
     * @param ids Token ids sequentially mapped to owners array.
     **/
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        override
        returns (uint256[] memory)
    {
        require(owners.length == ids.length);

        uint256[] memory balances_ = new uint256[](owners.length);

        for (uint256 i; i < owners.length; ++i) {
            address owner = owners[i];

            require(owner != address(0), "balance query for the zero address");

            uint256 id = ids[i];

            balances_[i] = _nftOwners[id] == owner ? UNITY : 0;
        }

        return balances_;
    }

    /**
     * @dev Pauses all token transfers and mints. Caller must have the `PAUSER_ROLE`.
     */
    function pause() public {
        require(
            hasRole(PAUSER_ROLE, msg.sender),
            "must have pauser role to pause"
        );
        _pause();
    }

    /**
     * @dev Unpauses all token transfers and mints. Caller must have the `PAUSER_ROLE`.
     */
    function unpause() public {
        require(
            hasRole(PAUSER_ROLE, msg.sender),
            "must have pauser role to unpause"
        );
        _unpause();
    }

    /**
     * @notice Create the basetype to whitelist a new group of NFTs or SFTs.
     * @dev A boolean value sets basetype encoding to NFT/SFT with bit flags. Stores the basetype in the upper 128 bits.
     * @param isSFT True value sets basetype encoding to SFT.
     **/
    function createBaseType(bool isSFT) external onlyAuthorized(MINTER_ROLE) {
        uint256 baseType;

        if (isSFT) {
            baseType = (uint256(++_semiFtNonce)).encodeNewSemiFungibleBaseType();
            // console.log("Binary %s", (baseType).u256ToBinaryStr());
        } else {
            baseType = (uint256(++_nftNonce)).encodeNewNonFungibleBaseType();
        }

        typeBirthCertificates[baseType] = true;

        // emit a Transfer event with Create semantic to help with discovery.
        emit TransferSingle(
            msg.sender,
            address(0x0),
            address(0x0),
            baseType,
            0
        );
    }

    /**
     * @notice Unrestricted function to transfer token from address to another.
     * @dev Note: Must be hard coded to transfer one amount of token. Remove `amount` and `data` arg allocations as unused. Makes validation check on `msg.sender` or `_operatorApprovals` in ERC1155 parent contract.
     * @param from Sender's address.
     * @param to Receiver's address.
     * @param id Token id.
     **/
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256,
        bytes calldata
    ) public override {
        if (id.isSemiFungible() || id.isNonFungible()) {
            require(usersTokens[to] == 0, "receiver already has a token");

            _nftOwners[id] = to;
            usersTokens[from] = 0;
            usersTokens[to] = id;
        }

        // note: has transfer one (`UNITY`) amount
        super.safeTransferFrom(from, to, id, UNITY, EMPTY_BYTES);
    }

    /**
     * @notice Unrestricted function to transfer token from address to another.
     * @dev Note: Must be hard coded to transfer one amount of token. Only one id can be passed into `ids` because each user can only own one token. Remove `amounts` and `data` arg allocations as unused. Create singleton `amounts` array in memory. Makes validation check on `msg.sender` or `_operatorApprovals` in ERC1155 parent contract.
     * @param from Sender's address.
     * @param to Receiver's address.
     * @param ids Token id.
     **/
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata,
        bytes calldata
    ) public override {
        require(ids.length == UNITY, "ids length must be one");

        uint256 id = ids[0];

        if (id.isSemiFungible() || id.isNonFungible()) {
            // more kludge
            require(usersTokens[to] == 0, "receiver already has a token");

            _nftOwners[id] = to;
            usersTokens[from] = 0;
            usersTokens[to] = id;
        }

        uint256[] memory singletonAmounts = new uint256[](UNITY);
        singletonAmounts[0] = UNITY;

        super.safeBatchTransferFrom(
            from,
            to,
            ids,
            singletonAmounts,
            EMPTY_BYTES
        );
    }

    /**
     * @notice Unrestricted function to burn own token. Not recommended.
     * @dev Makes validation check on `msg.sender` or `_operatorApprovals` in ERC1155 parent contract.
     * @param account Burner's address.
     * @param id Token id.
     **/
    function burn(
        address account,
        uint256 id,
        uint256
    ) public override {
        usersTokens[account] = 0;
        _nftOwners[id] = address(0);

        uint256 baseType = id.getBaseType();

        super.burn(account, id, UNITY);

        --basetypesManagement[baseType].balance;
    }

    /**
     * @notice Set the `uri` for a token id, if the privelage has not been revoked.
     * @dev `newUri` should point to metadata json. The setting is possible until the privelage is revoked, by a one time call to `revokeSetURI` on a per id basis. Only `MINTER_ROLE` should be authorized. Other validation occurs in {ERC1155DynamicURI}.
     * @param id SFT basetype or NFT id only.
     * @param newUri SFT group or NFT `uri` value.
     **/
    function setURI(uint256 id, string memory newUri)
        external
        onlyAuthorized(MINTER_ROLE)
    {
        _setURI(id, newUri);
    }

    /**
     * @notice Set the maxCapacity value to prevent minting more than allowed for a given token level.
     * @param basetype SFT basetype or NFT id only.
     * @param maxCap Maximum balance for level.
     **/
    function setTokenLevelMaxCap(uint256 basetype, uint128 maxCap)
        external
        onlyAuthorized(MINTER_ROLE)
    {
        require(
            basetype.isSemiFungibleBaseType() ||
                basetype.isNonFungibleBaseType(),
            "improper id base type encoding"
        );

        basetypesManagement[basetype].maxCapacity = maxCap;

        emit TokenLevelMaxCapSetting(basetype, maxCap);
    }

    /**
     * @notice Revoke ability to change URI once it has a proper ipfs uri.
     * @dev Validation check occurs on internal function calls.
     * @param id Token id.
     **/
    function revokeSetURI(uint256 id) external onlyAuthorized(MINTER_ROLE) {
        _revokeSetURI(id);
    }

    /**
     * @dev Invoked by restricted `mintSFT` and `mintNFT`, as well as derived contract dependencies in and to {YoloNFTPack}. Invoked from `mintBaseSFT` and `upgradeToken` calls.
     * @param to Receiver address.
     * @param baseType NFT basetype to mint.
     * @param newURI URI of new NFT if available.
     **/
    function _mintNFT(
        address to,
        uint256 baseType,
        string memory newURI
    ) internal {
        require(
            baseType.isSemiFungibleBaseType() ||
                baseType.isNonFungibleBaseType(),
            "improper id base type encoding"
        );

        require(
            typeBirthCertificates[baseType] == true,
            "base type not yet created"
        );

        require(usersTokens[to] == 0, "receiver already has a token");

        uint128 newBalance = ++basetypesManagement[baseType].balance;

        require(
            newBalance <= basetypesManagement[baseType].maxCapacity,
            "mint exceeds token level cap"
        );

        // increment maxIndexes first, THEN assign index
        uint256 index = ++maxIndexes[baseType];

        uint256 id = baseType | index;

        _nftOwners[id] = to;
        usersTokens[to] = id;

        super._mint(to, id, UNITY, EMPTY_BYTES);
        if (bytes(newURI).length > 0) {
            _setURI(id, newURI);
        }
    }

    /**
     * @dev Passes call to parent {ERC1155DynamicURI}.
     * @param id Token id.
     * @param newUri New metadata uri.
     **/
    function _setURI(uint256 id, string memory newUri) internal override {
        ERC1155DynamicURI._setURI(id, newUri);
    }

    /**
     * @notice Check if token exists and pass call to {ERC1155DynamicURI}.
     * @dev Validation check on `_nftOwners` mapping.
     * @param id Token id.
     **/
    function _revokeSetURI(uint256 id) internal override {
        require(_nftOwners[id] != address(0), "no revoke on nonexistant token");

        ERC1155DynamicURI._revokeSetURI(id);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Pausable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Disable burnBatch as not specified in IERC1155.
     */
    function burnBatch(
        address,
        uint256[] memory,
        uint256[] memory
    ) public pure override {
        revert("burnBatch disabled");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC1155 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Pausable is ERC1155, Pausable {
    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        require(!paused(), "ERC1155Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Burnable is ERC1155 {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }
}

pragma solidity 0.8.13;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import {RegistrySatellite} from "../../core/RegistrySatellite.sol";
import {SplitBitId} from "../../utils/SplitBitId.sol";
import {MINTER_ROLE} from "../../utils/constants.sol";

/**
 * @dev This is a bypass for {IERC1155MetadataURI} with custom `setURI` quasi function overload for dynamic id-specific URIs, in order to provide long term support for IPFS CIDs. Since IPFS folders require all file content determined at creation, it isn't trivial or economical to add more files post creation, i.e. it isn't possible to set a base URI and add additional files later without reconstituting all file contents inside a new IPFS folder.
 */
abstract contract ERC1155DynamicURI is RegistrySatellite, ERC1155 {
    using SplitBitId for uint256;

    string constant EMPTY_STR = "";

    mapping(uint256 => string) private _uris;
    mapping(uint256 => bool) private _isSetURIRevoked;

    // from IERC1155
    // event URI(string value, uint256 indexed id);

    event SetURIRevocation(uint256 indexed id);

    modifier uriStartsWithIPFS(string memory where) {
        bytes memory whatBytes = bytes("ipfs://");
        bytes memory whereBytes = bytes(where);

        require(whereBytes.length >= uint256(53), "must be CID v0 or greater"); // ipfs:// + base 58 (length 46)

        bool found = true;

        for (uint256 i; i < 7; i++) {
            if (whereBytes[i] != whatBytes[i]) {
                found = false;
                break;
            }
        }

        require(found, "uri prefix must be: ipfs://");

        _;
    }

    constructor() ERC1155(EMPTY_STR) {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC1155)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Return the `uri` for a unique NFT or for a SFT set.
     * @dev {ERC1155DynamicURI} defines custom logic for setting `uri` based on token classification of SFT vs NFT, which is determined by token id encoding. SFTs of the same level/group/class share a basetype and thus `uri`.
     * @param id Token id.
     **/
    function uri(uint256 id)
        public
        view
        virtual
        override
        returns (string memory _uri)
    {
        if (id.isSemiFungible()) {
            uint256 baseType = id.getBaseType();
            _uri = _uris[baseType];
        } else {
            _uri = _uris[id];
        }
    }

    /**
     * @notice Set the `uri` for a token id, if the privelage has not been revoked.
     * @dev `newUri` should point to metadata json. The setting is possible until the privelage is revoked, by a one time call to `revokeSetURI` on a per id basis. Revoke should be called after an IPFS uri has been pinned.
     * @param id Token id.
     * @param newUri SFT group or NFT `uri` value.
     **/
    function _setURI(uint256 id, string memory newUri) internal virtual {
        require(_isSetURIRevoked[id] == false, "setter role revoked for id");

        require(
            id.isSemiFungibleBaseType() || id.isNonFungibleItem(),
            "must be SFT basetype or NFT"
        );

        _uris[id] = newUri;

        emit URI(newUri, id);
    }

    /**
     * @dev Revoke the setURI call privelage once
     * the ipfs-ish metadata URI is set.
     * Requirements: the caller must have the `MINTER_ROLE`.
     */
    function _revokeSetURI(uint256 id)
        internal
        virtual
        onlyAuthorized(MINTER_ROLE)
        uriStartsWithIPFS(uri(id))
    {
        require(_isSetURIRevoked[id] == false, "setURI on id already revoked");

        _isSetURIRevoked[id] = true;

        emit SetURIRevocation(id);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}