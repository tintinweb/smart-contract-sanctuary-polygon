// SPDX-License-Identifier: UNLICENSED
// solhint-disable-next-line compiler-fixed, compiler-gt-0_8
pragma solidity ^0.8.0;

import "./interfaces/IErc20Min.sol";
import "./interfaces/ITotalStaked.sol";
import "./actions/StakingMsgProcessor.sol";
import "./interfaces/IRewardAdviser.sol";
import "./utils/Claimable.sol";
import "./utils/ImmutableOwnable.sol";
import "./utils/NonReentrant.sol";
import "./utils/Utils.sol";

/**
 * @title StakeRewardController
 * @notice It accounts for and sends staking rewards to stakers
 * @dev It acts as the "RewardAdviser" for the "RewardMaster". The later calls
 * this contract to process messages from the "Staking" contract.
 * On Polygon, it replaces the "StakeRewardAdviser" and, together with the
 * "RewardTreasury", the "MaticRewardPool".
 * It simulates "advices" of the "StakeRewardAdviser" to the "RewardMaster":
 * - for stakes created before the replacement (aka "old" stakes), it returns
 * modified "advices" with "old" amounts of rewards ("shares"), but with the
 * address of the REWARD_TREASURY as the recipient of rewards; so the latest
 * gets "old" rewards, which the "RewardMaster" pays on "advices";
 * - for "new" stakes, it returns "advices" with zero rewards (zero "shares").
 * It acts as a "spender" from the "RewardTreasury", calling `transferFrom` to
 * send "new" rewards to stakers, both under "old" and "new" stakes.
 */
contract StakeRewardController is
    ImmutableOwnable,
    StakingMsgProcessor,
    Utils,
    Claimable,
    NonReentrant,
    IRewardAdviser
{
    /**
     * ARPT (Arpt, arpt) stands for "Accumulated amount of Rewards Per staked Token".
     *
     * Staking reward is calculated on redemption of a stake (action == UNSTAKE),
     * when we know `stakedAt`, `claimedAt` and `amount` of the stake.
     *
     * The amount to reward on every stake unstaked we compute as follows.
     *   appreciation = newArpt - arptHistory[stakedAt]      // See (2) and (3)
     *   rewardAmount = amount * appreciation                               (1)
     *
     * Each time when a stake is created (on "STAKE") or redeemed (on "UNSTAKE"),
     * we calculate and saves params as follows.
     *   timeNow = action == STAKE ? stakedAt : claimedAt
     *   rewardAdded = (timeNow - rewardUpdatedOn) * REWARD_PER_SECOND
     *   rewardPerTokenAdded = rewardAdded / totalStaked;
     *   newArpt = accumRewardPerToken + rewardPerTokenAdded                (2)
     *   accumRewardPerToken = newArpt
     *   storage rewardUpdatedOn = timeNow
     *   totalStaked = totalStaked + (action == STAKE ? +amount : -amount)
     *   if (action == STAKE) {
     *     arptHistory[timeNow] = newArpt                                   (3)
     *   }
     *
     * (Scaling omitted in formulas above for clarity)
     */

    // solhint-disable var-name-mixedcase

    /// @notice The ERC20 token to pay rewards in
    address public immutable REWARD_TOKEN;

    /// @notice Staking contract instance that handles stakes
    address public immutable STAKING;

    /// @notice Account that approves this contract as a spender of {REWARD_TOKEN} it holds
    address public immutable REWARD_TREASURY;

    /// @notice RewardMaster instance authorized to call `getRewardAdvice` on this contract
    address public immutable REWARD_MASTER;

    /// @notice Account authorized to initialize initial historical data
    address private immutable HISTORY_PROVIDER;

    // Params named with "sc" prefix are scaled (up) with this factor
    uint256 private constant SCALE = 1e9;

    /// @notice (UNIX) Time when reward accrual starts
    uint256 public immutable REWARDING_START;
    /// @notice (UNIX) Time when reward accrual ends
    uint256 public immutable REWARDING_END;
    /// @notice Total amount of allocated rewards (with 18 decimals)
    uint256 public constant REWARD_AMOUNT = 2e24; // 2M tokens

    /// @dev Minimum amount of `totalStaked` when rewards accrued
    uint256 private constant MIN_TOTAL_STAKE_REWARDED = 100e18;
    /// @dev Value for zero scARPT (`0` means "undefined")
    uint256 private constant ZERO_SC_ARPT = 1;

    /// @dev Period when rewards are accrued
    uint256 private constant REWARDING_DURATION = 56 days;
    /// @dev Amount of rewards accrued to the reward pool every second (scaled)
    uint256 private constant sc_REWARD_PER_SECOND =
        (REWARD_AMOUNT * SCALE) / REWARDING_DURATION;

    bytes4 private constant STAKE_TYPE = 0x4ab0941a; // bytes4(keccak256("classic"))
    bytes4 private immutable STAKE;
    bytes4 private immutable UNSTAKE;

    // "shares" for "old" stakes are scaled (down) with this factor
    uint256 private constant OLD_SHARE_FACTOR = 1e6;

    // solhint-enable var-name-mixedcase

    /// @notice (UNIX) Time when history of "old" stakes was generated
    uint32 public prefilledHistoryEnd;
    /// @notice (UNIX) Time when this contract started processing of stakes
    uint32 public activeSince;

    /// @notice Total amount of outstanding stakes this contract is aware of
    uint96 public totalStaked;

    /// @notice (UNIX) Timestamp when rewards accrued for the last time
    uint32 public rewardUpdatedOn;
    /// @notice Amounts of rewards accrued till the `rewardUpdatedOn`
    uint96 public totalRewardAccrued;

    /// @notice "Accumulated amount of Rewards Per staked Token" (scaled)
    /// computed at the `rewardUpdatedOn` time
    uint256 public scAccumRewardPerToken;

    /// @notice Mapping from `stakedAt` to "Accumulated Reward amount Per Token staked" (scaled)
    /// @dev We pre-populate "old" stakes data, then "STAKE" calls append new stakes
    mapping(uint256 => uint256) public scArptHistory;

    /// @dev Emitted when new reward amount counted in `totalRewardAccrued`
    event RewardAdded(
        uint256 reward,
        uint256 _totalRewardAccrued,
        uint256 newScArpt
    );
    /// @dev Emitted when reward paid to a staker
    event RewardPaid(address indexed staker, uint256 reward);
    /// @dev Emitted when stake history gets initialized
    event HistoryInitialized(
        uint256 historyEnd,
        uint256 _totalStaked,
        uint256 scArpt
    );
    /// @dev Emitted on activation of this contract
    event Activated(uint256 _activeSince, uint256 _totalStaked, uint256 scArpt);

    constructor(
        address _owner,
        address token,
        address stakingContract,
        address rewardTreasury,
        address rewardMaster,
        address historyProvider,
        uint256 rewardingStart
    ) ImmutableOwnable(_owner) {
        STAKE = _encodeStakeActionType(STAKE_TYPE);
        UNSTAKE = _encodeUnstakeActionType(STAKE_TYPE);

        require(
            token != address(0) &&
                stakingContract != address(0) &&
                rewardTreasury != address(0) &&
                rewardMaster != address(0) &&
                historyProvider != address(0),
            "SRC: E1"
        );

        REWARD_TOKEN = token;
        STAKING = stakingContract;
        REWARD_TREASURY = rewardTreasury;
        REWARD_MASTER = rewardMaster;
        HISTORY_PROVIDER = historyProvider;

        REWARDING_START = rewardingStart;
        uint256 rewardingEnd = rewardingStart + REWARDING_DURATION;
        require(rewardingEnd > timeNow(), "SRC: E2");

        REWARDING_END = rewardingEnd;
    }

    /// @notice If historical data has been initialized
    function isInitialized() public view returns (bool) {
        return prefilledHistoryEnd != 0;
    }

    /// @notice If the contract is active (i.e. processes new stakes)
    function isActive() public view returns (bool) {
        return activeSince != 0;
    }

    function getRewardAdvice(bytes4 action, bytes memory message)
        external
        override
        returns (Advice memory)
    {
        require(msg.sender == REWARD_MASTER, "SRC: unauthorized");
        require(isActive(), "SRC: not yet active");

        (
            address staker,
            uint96 stakeAmount,
            ,
            uint32 stakedAt,
            ,
            ,

        ) = _unpackStakingActionMsg(message);

        require(staker != address(0), "SRC: unexpected zero staker");
        require(stakeAmount != 0, "SRC: unexpected zero amount");
        require(stakedAt != 0, "SRC: unexpected zero stakedAt");

        // we ignore `claimedAt` from the `message` as the deployed version of
        // the Staking contract never sets it in messages (it's a bug)
        uint32 claimedAt = action == UNSTAKE ? safe32TimeNow() : 0;

        if (stakedAt < activeSince) {
            require(action == UNSTAKE, "SRC: invalid 'old' action");
            _countUnstakeAndPayReward(staker, stakeAmount, stakedAt, claimedAt);
            return _getUnstakeModifiedAdvice(staker, stakeAmount);
        }

        if (action == STAKE) {
            _countNewStake(stakeAmount, stakedAt);
            return _getStakeVoidAdvice(staker);
        }

        if (action == UNSTAKE) {
            _countUnstakeAndPayReward(staker, stakeAmount, stakedAt, claimedAt);
            return _getUnstakeVoidAdvice(staker);
        }

        revert("SRC: unsupported action");
    }

    /// @notice It returns "Accumulated amount of Rewards Per staked Token" for given time.
    /// If zero value as the time provided, the current network time assumed.
    function getScArptAt(uint32 timestamp)
        external
        view
        returns (uint256 scArpt)
    {
        // first, try to use historical data
        scArpt = _getHistoricalArpt(timestamp);
        if (scArpt != 0) return scArpt;

        {
            // then use the latest updated value, if applicable
            uint32 _lastUpdatedOn = rewardUpdatedOn;
            uint256 _lastScArpt = scAccumRewardPerToken;
            if (timestamp == _lastUpdatedOn) return _lastScArpt;

            // finally use extrapolation, unless data from the past requested
            uint32 _timeNow = safe32TimeNow();
            bool isForNow = timestamp == 0 || timestamp == _timeNow;
            bool isForFuture = timestamp > _timeNow;
            if (isForNow || isForFuture) {
                uint32 till = isForNow ? _timeNow : timestamp;
                (scArpt, ) = _computeRewardsAddition(
                    _lastUpdatedOn,
                    till,
                    _lastScArpt,
                    totalStaked
                );
            }
        }
        require(scArpt != 0, "SRC: no data for requested time");

        return scArpt;
    }

    /// @notice It initializes historical data (for "old" stakes).
    /// Only HISTORY_PROVIDER may call, and only if the history has not been finalized.
    /// @dev If `historyEnd` is 0, may be called again (gets finalized otherwise).
    /// ATTN: None of the "old" stake MUST be repaid by the historyEnd !!!
    function saveHistoricalData(
        uint96[] calldata amounts,
        uint32[] calldata stakedAtDates,
        uint32 historyEnd
    ) external {
        require(!isInitialized(), "SRC: already initialized");
        require(msg.sender == HISTORY_PROVIDER, "SRC: unauthorized");
        require(
            amounts.length == stakedAtDates.length,
            "SRC: unmatched length"
        );

        uint32 lastDate = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            uint32 stakedAt = stakedAtDates[i];
            uint96 amount = amounts[i];
            require(
                stakedAt != 0 && stakedAt >= lastDate,
                "SRC: wrong history order"
            );
            require(amount != 0, "SRC: unexpected zero amount");

            _countNewStake(amount, stakedAt);

            lastDate = stakedAt;
        }

        if (historyEnd != 0) {
            require(
                historyEnd >= rewardUpdatedOn && historyEnd <= safe32TimeNow(),
                "SRC: wrong historyEnd"
            );
            prefilledHistoryEnd = historyEnd;
            emit HistoryInitialized(
                historyEnd,
                totalStaked,
                scAccumRewardPerToken
            );
        }
    }

    /// @notice It sets this contract as "active"
    /// which assumes the contract started receiving data on new stakes
    /// @dev Owner only may calls
    function setActive() external onlyOwner {
        require(!isActive(), "SRC: already active");
        require(isInitialized(), "SRC: yet uninitialized");

        uint32 _timeNow = safe32TimeNow();
        activeSince = _timeNow;

        // Call to a trusted contract - no reentrancy guard needed
        uint256 actualTotalStaked = ITotalStaked(STAKING).totalStaked();
        uint256 savedTotalStaked = uint256(totalStaked);

        if (actualTotalStaked > savedTotalStaked) {
            // new stakes have been created since historical data finalization
            uint256 increase = actualTotalStaked - savedTotalStaked;
            // it roughly adjusts totals by counting an equivalent "stake"
            _countNewStake(safe96(increase), _timeNow);
        } else if (savedTotalStaked > actualTotalStaked) {
            // some "old" stakes was repaid after historical data finalization.
            // it results in inaccurate rewarding and shall be avoided.
            // the next line can decrease (but not exclude) inaccuracies.
            totalStaked = safe96(actualTotalStaked);
        }

        emit Activated(_timeNow, actualTotalStaked, scAccumRewardPerToken);
    }

    /// @notice Withdraws accidentally sent token from this contract
    /// @dev May be only called by the {OWNER}
    function claimErc20(
        address claimedToken,
        address to,
        uint256 amount
    ) external onlyOwner nonReentrant {
        _claimErc20(claimedToken, to, amount);
    }

    /// Private and internal functions follow

    function _countNewStake(uint96 stakeAmount, uint32 stakedAt) internal {
        uint256 scArpt = _updateRewardPoolParams(stakedAt);
        if (scArptHistory[stakedAt] == 0) {
            // if not registered yet for this time (i.e. block)
            scArptHistory[stakedAt] = scArpt != 0 ? scArpt : ZERO_SC_ARPT;
        }
        totalStaked = safe96(uint256(totalStaked) + uint256(stakeAmount));
    }

    function _countUnstakeAndPayReward(
        address staker,
        uint96 stakeAmount,
        uint32 stakedAt,
        uint32 claimedAt
    ) internal {
        uint256 startScArpt = _getHistoricalArpt(stakedAt);
        require(startScArpt != 0, "SRC: unknown ARPT for stakedAt");

        uint256 endScArpt = _updateRewardPoolParams(claimedAt);
        uint256 reward = _countReward(stakeAmount, startScArpt, endScArpt);

        totalStaked = safe96(uint256(totalStaked) - uint256(stakeAmount));

        if (reward != 0) {
            // trusted contract - nether reentrancy guard nor safeTransfer required
            require(
                IErc20Min(REWARD_TOKEN).transferFrom(
                    REWARD_TREASURY,
                    staker,
                    reward
                ),
                "SRC: Internal transfer failed"
            );
            emit RewardPaid(staker, reward);
        }
    }

    function _updateRewardPoolParams(uint32 actionTime)
        internal
        returns (uint256 newScArpt)
    {
        uint96 _totalStaked = totalStaked;
        newScArpt = scAccumRewardPerToken;

        if (_totalStaked < MIN_TOTAL_STAKE_REWARDED) {
            // Too small amount is staked for reward accruals
            return newScArpt;
        }

        uint32 prevActionTime = rewardUpdatedOn;
        if (prevActionTime >= actionTime) return newScArpt;

        uint256 rewardAdded;
        (newScArpt, rewardAdded) = _computeRewardsAddition(
            prevActionTime,
            actionTime,
            newScArpt,
            totalStaked
        );
        scAccumRewardPerToken = newScArpt;
        uint96 _totalRewardAccrued = safe96(
            uint256(totalRewardAccrued) + rewardAdded
        );
        totalRewardAccrued = _totalRewardAccrued;
        rewardUpdatedOn = actionTime;

        emit RewardAdded(rewardAdded, _totalRewardAccrued, newScArpt);
    }

    function _computeRewardsAddition(
        uint32 fromTime,
        uint32 tillTime,
        uint256 fromScArpt,
        uint256 _totalStaked
    ) internal view returns (uint256 newScArpt, uint256 rewardAdded) {
        if (fromTime >= REWARDING_END || tillTime <= REWARDING_START)
            return (fromScArpt, 0);

        uint256 from = fromTime >= REWARDING_START ? fromTime : REWARDING_START;
        uint256 till = tillTime <= REWARDING_END ? tillTime : REWARDING_END;
        uint256 scRewardAdded = (till - from) * sc_REWARD_PER_SECOND;

        rewardAdded = scRewardAdded / SCALE;
        newScArpt = fromScArpt + scRewardAdded / _totalStaked;
    }

    function _getHistoricalArpt(uint32 stakedAt)
        internal
        view
        returns (uint256 scArpt)
    {
        scArpt = scArptHistory[stakedAt];
        if (scArpt > 0) return scArpt;

        // Stake created within a period this contract has no stake data for ?
        bool isBlindPeriodStake = stakedAt > prefilledHistoryEnd &&
            stakedAt < activeSince;
        if (isBlindPeriodStake) {
            // approximate
            scArpt = scArptHistory[activeSince];
        }
    }

    function _countReward(
        uint96 stakeAmount,
        uint256 startScArpt,
        uint256 endScArpt
    ) internal pure returns (uint256 reward) {
        reward = ((endScArpt - startScArpt) * uint256(stakeAmount)) / SCALE;
    }

    function _getStakeVoidAdvice(address staker)
        internal
        view
        returns (Advice memory advice)
    {
        advice = _getEmptyAdvice();
        advice.createSharesFor = staker;
    }

    function _getUnstakeVoidAdvice(address staker)
        internal
        view
        returns (Advice memory advice)
    {
        advice = _getEmptyAdvice();
        advice.redeemSharesFrom = staker;
    }

    function _getUnstakeModifiedAdvice(address staker, uint96 amount)
        internal
        view
        returns (Advice memory advice)
    {
        advice = _getEmptyAdvice();
        advice.redeemSharesFrom = staker;
        advice.sharesToRedeem = safe96(uint256(amount) / OLD_SHARE_FACTOR);
    }

    function _getEmptyAdvice() internal view returns (Advice memory advice) {
        advice = Advice(
            address(0), // createSharesFor
            0, // sharesToCreate
            address(0), // redeemSharesFrom
            0, // sharesToRedeem
            REWARD_TREASURY // sendRewardTo
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
// solhint-disable var-name-mixedcase
// solhint-disable-next-line compiler-fixed, compiler-gt-0_8
pragma solidity ^0.8.0;

import "./interfaces/IStakingTypes.sol";
import "./Staking.sol";
import "./StakeRewardController.sol";

contract StakesReporter is IStakingTypes {
    Staking public immutable STAKING;
    StakeRewardController public immutable STAKE_REWARD_CONTROLLER;

    uint256 private constant SCALE = 1e9;

    constructor(address _staking, address _stakeRewardController) {
        require(
            _staking != address(0) && _stakeRewardController != address(0),
            "StakesReporter: Zero address passed"
        );

        STAKING = Staking(_staking);
        STAKE_REWARD_CONTROLLER = StakeRewardController(_stakeRewardController);
    }

    function getStakesInfo(address _account)
        external
        view
        returns (Stake[] memory stakes, uint256[] memory unclaimedRewards)
    {
        stakes = STAKING.accountStakes(_account);

        uint256[] memory unclaimedRewardsArray = new uint256[](stakes.length);

        for (uint256 i = 0; i < stakes.length; i++) {
            if (stakes[i].claimedAt == 0) {
                unclaimedRewardsArray[i] = getUnclaimedRewards(
                    STAKE_REWARD_CONTROLLER.getScArptAt(stakes[i].stakedAt),
                    STAKE_REWARD_CONTROLLER.getScArptAt(uint32(0)),
                    stakes[i].amount
                );
            }
        }

        unclaimedRewards = unclaimedRewardsArray;
    }

    function getStakeInfo(address _account, uint256 _stakeID)
        external
        view
        returns (Stake memory stake, uint256 unclaimedRewards)
    {
        (
            uint32 id,
            bytes4 stakeType,
            uint32 stakedAt,
            uint32 lockedTill,
            uint32 claimedAt,
            uint96 amount,
            address delegatee
        ) = STAKING.stakes(_account, _stakeID);

        stake = Stake(
            id,
            stakeType,
            stakedAt,
            lockedTill,
            claimedAt,
            amount,
            delegatee
        );

        if (claimedAt == 0)
            unclaimedRewards = getUnclaimedRewards(
                STAKE_REWARD_CONTROLLER.getScArptAt(stakedAt),
                STAKE_REWARD_CONTROLLER.getScArptAt(uint32(0)),
                amount
            );
    }

    function getUnclaimedRewards(
        uint256 _scArptFrom,
        uint256 _scArptTill,
        uint96 amount
    ) public pure returns (uint256) {
        return ((_scArptTill - _scArptFrom) * amount) / SCALE;
    }
}

// SPDX-License-Identifier: UNLICENSED
// solhint-disable-next-line compiler-fixed, compiler-gt-0_8
pragma solidity ^0.8.0;

import "./actions/StakingMsgProcessor.sol";
import "./interfaces/IActionMsgReceiver.sol";
import "./interfaces/IErc20Min.sol";
import "./interfaces/IStakingTypes.sol";
import "./interfaces/IVotingPower.sol";
import "./utils/ImmutableOwnable.sol";
import "./utils/Utils.sol";

/**
 * @title Staking
 * @notice It lets users stake $ZKP token for governance voting and rewards.
 * @dev At request of smart contracts and off-chain requesters, it computes
 * user "voting power" on the basis of tokens users stake.
 * It acts as the "ActionOracle" for the "RewardMaster": if stake terms presume
 * rewarding, it sends "messages" on stakes made and stakes claimed to the
 * "RewardMaster" contract which rewards stakers.
 * It supports multiple types of stakes (terms), which the owner may add or
 * remove without contract code upgrades.
 */
contract Staking is
    ImmutableOwnable,
    Utils,
    StakingMsgProcessor,
    IStakingTypes,
    IVotingPower
{
    // solhint-disable var-name-mixedcase
    /// @notice Staking token
    IErc20Min public immutable TOKEN;

    /// @dev Block the contract deployed in
    uint256 public immutable START_BLOCK;

    /// @notice RewardMaster contract instance
    IActionMsgReceiver public immutable REWARD_MASTER;

    // solhint-enable var-name-mixedcase

    // Scale for min/max limits
    uint256 private constant SCALE = 1e18;

    /// @notice Total token amount staked
    /// @dev Staking token is deemed to have max total supply of 1e27
    uint96 public totalStaked = 0;

    /// @dev Mapping from stake type to terms
    mapping(bytes4 => Terms) public terms;

    /// @dev Mapping from the staker address to stakes of the staker
    mapping(address => Stake[]) public stakes;

    // Special address to store global state
    address private constant GLOBAL_ACCOUNT = address(0);

    /// @dev Voting power integrants for each account
    // special case: GLOBAL_ACCOUNT for total voting power
    mapping(address => Power) public power;

    /// @dev Snapshots of each account
    // special case: GLOBAL_ACCOUNT for global snapshots
    mapping(address => Snapshot[]) private snapshots;

    /// @dev Emitted on a new stake made
    event StakeCreated(
        address indexed account,
        uint256 indexed stakeID,
        uint256 amount,
        bytes4 stakeType,
        uint256 lockedTill
    );

    /// @dev Emitted on a stake claimed (i.e. "unstaked")
    event StakeClaimed(address indexed account, uint256 indexed stakeID);

    /// @dev Voting power delegated
    event Delegation(
        address indexed owner,
        address indexed from,
        address indexed to,
        uint256 stakeID,
        uint256 amount
    );

    /// @dev New terms (for the given stake type) added
    event TermsAdded(bytes4 stakeType);

    /// @dev Terms (for the given stake type) are disabled
    event TermsDisabled(bytes4 stakeType);

    /// @dev Call to REWARD_MASTER reverted
    event RewardMasterRevert(address staker, uint256 stakeID);

    /**
     * @notice Sets staking token, owner and
     * @param stakingToken - Address of the {ZKPToken} contract
     * @param rewardMaster - Address of the {RewardMaster} contract
     * @param owner - Address of the owner account
     */
    constructor(
        address stakingToken,
        address rewardMaster,
        address owner
    ) ImmutableOwnable(owner) {
        require(
            stakingToken != address(0) && rewardMaster != address(0),
            "Staking:C1"
        );
        TOKEN = IErc20Min(stakingToken);
        REWARD_MASTER = IActionMsgReceiver(rewardMaster);
        START_BLOCK = blockNow();
    }

    /**
     * @notice Stakes tokens
     * @dev This contract should be approve()'d for amount
     * @param amount - Amount to stake
     * @param stakeType - Type of the stake
     * @param data - Arbitrary data for "RewardMaster" (zero, if inapplicable)
     * @return stake ID
     */
    function stake(
        uint256 amount,
        bytes4 stakeType,
        bytes calldata data
    ) public returns (uint256) {
        return _createStake(msg.sender, amount, stakeType, data);
    }

    /**
     * @notice Approves this contract to transfer `amount` tokens from the `msg.sender`
     * and stakes these tokens. Only the owner of tokens (i.e. the staker) may call.
     * @dev This contract does not need to be approve()'d in advance - see EIP-2612
     * @param owner - The owner of tokens being staked (i.e. the `msg.sender`)
     * @param amount - Amount to stake
     * @param v - "v" param of the signature from `owner` for "permit"
     * @param r - "r" param of the signature from `owner` for "permit"
     * @param s - "s" param of the signature from `owner` for "permit"
     * @param stakeType - Type of the stake
     * @param data - Arbitrary data for "RewardMaster" (zero, if inapplicable)
     * @return stake ID
     */
    function permitAndStake(
        address owner,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes4 stakeType,
        bytes calldata data
    ) external returns (uint256) {
        require(owner == msg.sender, "Staking: owner must be msg.sender");
        TOKEN.permit(owner, address(this), amount, deadline, v, r, s);
        return _createStake(owner, amount, stakeType, data);
    }

    /**
     * @notice Claims staked token
     * @param stakeID - ID of the stake to claim
     * @param data - Arbitrary data for "RewardMaster" (zero, if inapplicable)
     * @param _isForced - Do not revert if "RewardMaster" fails
     */
    function unstake(
        uint256 stakeID,
        bytes calldata data,
        bool _isForced
    ) external stakeExist(msg.sender, stakeID) {
        Stake memory _stake = stakes[msg.sender][stakeID];

        require(_stake.claimedAt == 0, "Staking: Stake claimed");
        require(_stake.lockedTill < safe32TimeNow(), "Staking: Stake locked");

        if (_stake.delegatee != address(0)) {
            _undelegatePower(_stake.delegatee, msg.sender, _stake.amount);
        }
        _removePower(msg.sender, _stake.amount);

        stakes[msg.sender][stakeID].claimedAt = safe32TimeNow();

        totalStaked = safe96(uint256(totalStaked) - uint256(_stake.amount));

        emit StakeClaimed(msg.sender, stakeID);

        // known contract - reentrancy guard and `safeTransfer` unneeded
        require(
            TOKEN.transfer(msg.sender, _stake.amount),
            "Staking: transfer failed"
        );

        Terms memory _terms = terms[_stake.stakeType];
        if (_terms.isRewarded) {
            _sendUnstakedMsg(msg.sender, _stake, data, _isForced);
        }
    }

    /**
     * @notice Updates vote delegation
     * @param stakeID - ID of the stake to delegate votes uber
     * @param to - address to delegate to
     */
    function delegate(uint256 stakeID, address to)
        public
        stakeExist(msg.sender, stakeID)
    {
        require(
            to != GLOBAL_ACCOUNT,
            "Staking: Can't delegate to GLOBAL_ACCOUNT"
        );

        Stake memory s = stakes[msg.sender][stakeID];
        require(s.claimedAt == 0, "Staking: Stake claimed");
        require(s.delegatee != to, "Staking: Already delegated");

        if (s.delegatee == address(0)) {
            _delegatePower(msg.sender, to, s.amount);
        } else {
            if (to == msg.sender) {
                _undelegatePower(s.delegatee, msg.sender, s.amount);
            } else {
                _reDelegatePower(s.delegatee, to, s.amount);
            }
        }

        emit Delegation(msg.sender, s.delegatee, to, stakeID, s.amount);

        stakes[msg.sender][stakeID].delegatee = to;
    }

    /**
     * @notice Delegates voting power of stake back to self
     * @param stakeID - ID of the stake to delegate votes back to self
     */
    function undelegate(uint256 stakeID) external {
        delegate(stakeID, msg.sender);
    }

    /// @notice Returns number of stakes of given _account
    function stakesNum(address _account) external view returns (uint256) {
        return stakes[_account].length;
    }

    /// @notice Returns stakes of given account
    function accountStakes(address _account)
        external
        view
        returns (Stake[] memory)
    {
        Stake[] memory _stakes = stakes[_account];
        return _stakes;
    }

    /// @inheritdoc IVotingPower
    function totalVotingPower() external view override returns (uint256) {
        Power memory _power = power[GLOBAL_ACCOUNT];
        return _power.own + _power.delegated;
    }

    /// @inheritdoc IVotingPower
    function totalPower() external view override returns (Power memory) {
        return power[GLOBAL_ACCOUNT];
    }

    /// @inheritdoc IVotingPower
    function latestGlobalsSnapshotBlock()
        public
        view
        override
        returns (uint256)
    {
        return latestSnapshotBlock(GLOBAL_ACCOUNT);
    }

    /// @inheritdoc IVotingPower
    function latestSnapshotBlock(address _account)
        public
        view
        override
        returns (uint256)
    {
        if (snapshots[_account].length == 0) return 0;

        return snapshots[_account][snapshots[_account].length - 1].beforeBlock;
    }

    /// @inheritdoc IVotingPower
    function globalsSnapshotLength() external view override returns (uint256) {
        return snapshots[GLOBAL_ACCOUNT].length;
    }

    /// @inheritdoc IVotingPower
    function snapshotLength(address _account)
        external
        view
        override
        returns (uint256)
    {
        return snapshots[_account].length;
    }

    /// @inheritdoc IVotingPower
    function globalsSnapshot(uint256 _index)
        external
        view
        override
        returns (Snapshot memory)
    {
        return snapshots[GLOBAL_ACCOUNT][_index];
    }

    /// @inheritdoc IVotingPower
    function snapshot(address _account, uint256 _index)
        external
        view
        override
        returns (Snapshot memory)
    {
        return snapshots[_account][_index];
    }

    /// @inheritdoc IVotingPower
    function globalSnapshotAt(uint256 blockNum, uint256 hint)
        external
        view
        override
        returns (Snapshot memory)
    {
        return _snapshotAt(GLOBAL_ACCOUNT, blockNum, hint);
    }

    /// @inheritdoc IVotingPower
    function snapshotAt(
        address _account,
        uint256 blockNum,
        uint256 hint
    ) external view override returns (Snapshot memory) {
        return _snapshotAt(_account, blockNum, hint);
    }

    /// Only for the owner functions

    /// @notice Adds a new stake type with given terms
    /// @dev May be only called by the {OWNER}
    function addTerms(bytes4 stakeType, Terms memory _terms)
        external
        onlyOwner
        nonZeroStakeType(stakeType)
    {
        Terms memory existingTerms = terms[stakeType];
        require(!_isDefinedTerms(existingTerms), "Staking:E1");
        require(_terms.isEnabled, "Staking:E2");

        uint256 _now = timeNow();

        if (_terms.allowedTill != 0) {
            require(_terms.allowedTill > _now, "Staking:E3");
            require(_terms.allowedTill > _terms.allowedSince, "Staking:E4");
        }

        if (_terms.maxAmountScaled != 0) {
            require(
                _terms.maxAmountScaled > _terms.minAmountScaled,
                "Staking:E5"
            );
        }

        // only one of three "lock time" parameters must be non-zero
        if (_terms.lockedTill != 0) {
            require(
                _terms.exactLockPeriod == 0 && _terms.minLockPeriod == 0,
                "Staking:E6"
            );
            require(
                _terms.lockedTill > _now &&
                    _terms.lockedTill >= _terms.allowedTill,
                "Staking:E7"
            );
        } else {
            require(
                // one of two params must be non-zero
                (_terms.exactLockPeriod == 0) != (_terms.minLockPeriod == 0),
                "Staking:E8"
            );
        }

        terms[stakeType] = _terms;
        emit TermsAdded(stakeType);
    }

    function disableTerms(bytes4 stakeType)
        external
        onlyOwner
        nonZeroStakeType(stakeType)
    {
        Terms memory _terms = terms[stakeType];
        require(_isDefinedTerms(terms[stakeType]), "Staking:E9");
        require(_terms.isEnabled, "Staking:EA");

        terms[stakeType].isEnabled = false;
        emit TermsDisabled(stakeType);
    }

    /// Internal and private functions follow

    function _createStake(
        address staker,
        uint256 amount,
        bytes4 stakeType,
        bytes calldata data
    ) internal nonZeroStakeType(stakeType) returns (uint256) {
        Terms memory _terms = terms[stakeType];
        require(_terms.isEnabled, "Staking: Terms unknown or disabled");

        require(amount > 0, "Staking: Amount not set");
        uint256 _totalStake = amount + uint256(totalStaked);
        require(_totalStake < 2**96, "Staking: Too big amount");

        require(
            _terms.minAmountScaled == 0 ||
                amount >= SCALE * _terms.minAmountScaled,
            "Staking: Too small amount"
        );
        require(
            _terms.maxAmountScaled == 0 ||
                amount <= SCALE * _terms.maxAmountScaled,
            "Staking: Too large amount"
        );

        uint32 _now = safe32TimeNow();
        require(
            _terms.allowedSince == 0 || _now >= _terms.allowedSince,
            "Staking: Not yet allowed"
        );
        require(
            _terms.allowedTill == 0 || _terms.allowedTill > _now,
            "Staking: Not allowed anymore"
        );

        // known contract - reentrancy guard and `safeTransferFrom` unneeded
        require(
            TOKEN.transferFrom(staker, address(this), amount),
            "Staking: transferFrom failed"
        );

        uint256 stakeID = stakes[staker].length;

        uint32 lockedTill = _terms.lockedTill;
        if (lockedTill == 0) {
            uint256 period = _terms.exactLockPeriod == 0
                ? _terms.minLockPeriod
                : _terms.exactLockPeriod;
            lockedTill = safe32(period + _now);
        }

        Stake memory _stake = Stake(
            uint32(stakeID), // overflow risk ignored
            stakeType,
            _now, // stakedAt
            lockedTill,
            0, // claimedAt
            uint96(amount),
            address(0) // no delegatee
        );
        stakes[staker].push(_stake);

        totalStaked = uint96(_totalStake);
        _addPower(staker, amount);

        emit StakeCreated(staker, stakeID, amount, stakeType, lockedTill);

        if (_terms.isRewarded) {
            _sendStakedMsg(staker, _stake, data);
        }
        return stakeID;
    }

    function _addPower(address to, uint256 amount) private {
        _takeSnapshot(GLOBAL_ACCOUNT);
        _takeSnapshot(to);
        power[GLOBAL_ACCOUNT].own += uint96(amount);
        power[to].own += uint96(amount);
    }

    function _removePower(address from, uint256 amount) private {
        _takeSnapshot(GLOBAL_ACCOUNT);
        _takeSnapshot(from);
        power[GLOBAL_ACCOUNT].own -= uint96(amount);
        power[from].own -= uint96(amount);
    }

    function _delegatePower(
        address from,
        address to,
        uint256 amount
    ) private {
        _takeSnapshot(GLOBAL_ACCOUNT);
        _takeSnapshot(to);
        _takeSnapshot(from);
        power[GLOBAL_ACCOUNT].own -= uint96(amount);
        power[from].own -= uint96(amount);
        power[GLOBAL_ACCOUNT].delegated += uint96(amount);
        power[to].delegated += uint96(amount);
    }

    function _reDelegatePower(
        address from,
        address to,
        uint256 amount
    ) private {
        _takeSnapshot(to);
        _takeSnapshot(from);
        power[from].delegated -= uint96(amount);
        power[to].delegated += uint96(amount);
    }

    function _undelegatePower(
        address from,
        address to,
        uint256 amount
    ) private {
        power[GLOBAL_ACCOUNT].delegated -= uint96(amount);
        power[from].delegated -= uint96(amount);
        power[GLOBAL_ACCOUNT].own += uint96(amount);
        power[to].own += uint96(amount);
    }

    function _takeSnapshot(address _account) internal {
        uint32 curBlockNum = safe32BlockNow();
        if (latestSnapshotBlock(_account) < curBlockNum) {
            // make new snapshot as the latest one taken before current block
            snapshots[_account].push(
                Snapshot(
                    curBlockNum,
                    power[_account].own,
                    power[_account].delegated
                )
            );
        }
    }

    function _snapshotAt(
        address _account,
        uint256 blockNum,
        uint256 hint
    ) internal view returns (Snapshot memory) {
        _sanitizeBlockNum(blockNum);

        Snapshot[] storage snapshotsInfo = snapshots[_account];

        if (
            // hint is correct?
            hint <= snapshotsInfo.length &&
            (hint == 0 || snapshotsInfo[hint - 1].beforeBlock < blockNum) &&
            (hint == snapshotsInfo.length ||
                snapshotsInfo[hint].beforeBlock >= blockNum)
        ) {
            // yes, return the hinted snapshot
            if (hint < snapshotsInfo.length) {
                return snapshotsInfo[hint];
            } else {
                return
                    Snapshot(
                        uint32(blockNum),
                        power[_account].own,
                        power[_account].delegated
                    );
            }
        }
        // no, fall back to binary search
        else return _snapshotAt(_account, blockNum);
    }

    function _snapshotAt(address _account, uint256 blockNum)
        internal
        view
        returns (Snapshot memory)
    {
        _sanitizeBlockNum(blockNum);

        // https://en.wikipedia.org/wiki/Binary_search_algorithm
        Snapshot[] storage snapshotsInfo = snapshots[_account];
        uint256 index;
        uint256 low = 0;
        uint256 high = snapshotsInfo.length;

        while (low < high) {
            uint256 mid = (low + high) / 2;

            if (snapshotsInfo[mid].beforeBlock > blockNum) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // `low` is the exclusive upper bound. Find the inclusive upper bounds and set to index
        if (low > 0 && snapshotsInfo[low - 1].beforeBlock == blockNum) {
            return snapshotsInfo[low - 1];
        } else {
            index = low;
        }

        // If index is equal to snapshot array length, then no update made after the requested blockNum.
        // This means the latest value is the right one.
        if (index == snapshotsInfo.length) {
            return
                Snapshot(
                    uint32(blockNum),
                    uint96(power[_account].own),
                    uint96(power[_account].delegated)
                );
        } else {
            return snapshotsInfo[index];
        }
    }

    function _sanitizeBlockNum(uint256 blockNum) private view {
        require(blockNum <= safe32BlockNow(), "Staking: Too big block number");
    }

    function _isDefinedTerms(Terms memory _terms) internal pure returns (bool) {
        return
            (_terms.minLockPeriod != 0) ||
            (_terms.exactLockPeriod != 0) ||
            (_terms.lockedTill != 0);
    }

    function _sendStakedMsg(
        address staker,
        Stake memory _stake,
        bytes calldata data
    ) internal {
        bytes4 action = _encodeStakeActionType(_stake.stakeType);
        bytes memory message = _packStakingActionMsg(staker, _stake, data);
        // known contract - reentrancy guard unneeded
        // solhint-disable-next-line no-empty-blocks
        try REWARD_MASTER.onAction(action, message) {} catch {
            revert("Staking: onStake msg failed");
        }
    }

    function _sendUnstakedMsg(
        address staker,
        Stake memory _stake,
        bytes calldata data,
        bool _isForced
    ) internal {
        bytes4 action = _encodeUnstakeActionType(_stake.stakeType);
        bytes memory message = _packStakingActionMsg(staker, _stake, data);
        // known contract - reentrancy guard unneeded
        // solhint-disable-next-line no-empty-blocks
        try REWARD_MASTER.onAction(action, message) {} catch {
            emit RewardMasterRevert(staker, _stake.id);
            // REWARD_MASTER must be unable to revert forced calls
            require(_isForced, "Staking: REWARD_MASTER reverts");
        }
    }

    modifier stakeExist(address staker, uint256 stakeID) {
        require(
            stakes[staker].length > stakeID,
            "Staking: Stake doesn't exist"
        );
        _;
    }

    modifier nonZeroStakeType(bytes4 stakeType) {
        require(stakeType != bytes4(0), "Staking: Invalid stake type 0");
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
// solhint-disable-next-line compiler-fixed, compiler-gt-0_8
pragma solidity ^0.8.0;

import "../interfaces/IStakingTypes.sol";

abstract contract StakingMsgProcessor {
    bytes4 internal constant STAKE_ACTION = bytes4(keccak256("stake"));
    bytes4 internal constant UNSTAKE_ACTION = bytes4(keccak256("unstake"));

    function _encodeStakeActionType(bytes4 stakeType)
        internal
        pure
        returns (bytes4)
    {
        return bytes4(keccak256(abi.encodePacked(STAKE_ACTION, stakeType)));
    }

    function _encodeUnstakeActionType(bytes4 stakeType)
        internal
        pure
        returns (bytes4)
    {
        return bytes4(keccak256(abi.encodePacked(UNSTAKE_ACTION, stakeType)));
    }

    function _packStakingActionMsg(
        address staker,
        IStakingTypes.Stake memory stake,
        bytes calldata data
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                staker, // address
                stake.amount, // uint96
                stake.id, // uint32
                stake.stakedAt, // uint32
                stake.lockedTill, // uint32
                stake.claimedAt, // uint32
                data // bytes
            );
    }

    // For efficiency we use "packed" (rather than "ABI") encoding.
    // It results in shorter data, but requires custom unpack function.
    function _unpackStakingActionMsg(bytes memory message)
        internal
        pure
        returns (
            address staker,
            uint96 amount,
            uint32 id,
            uint32 stakedAt,
            uint32 lockedTill,
            uint32 claimedAt,
            bytes memory data
        )
    {
        // staker, amount, id and 3 timestamps occupy exactly 48 bytes
        // (`data` may be of zero length)
        require(message.length >= 48, "SMP: unexpected msg length");

        uint256 stakerAndAmount;
        uint256 idAndStamps;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // the 1st word (32 bytes) contains the `message.length`
            // we need the (entire) 2nd word ..
            stakerAndAmount := mload(add(message, 0x20))
            // .. and (16 bytes of) the 3rd word
            idAndStamps := mload(add(message, 0x40))
        }

        staker = address(uint160(stakerAndAmount >> 96));
        amount = uint96(stakerAndAmount & 0xFFFFFFFFFFFFFFFFFFFFFFFF);

        id = uint32((idAndStamps >> 224) & 0xFFFFFFFF);
        stakedAt = uint32((idAndStamps >> 192) & 0xFFFFFFFF);
        lockedTill = uint32((idAndStamps >> 160) & 0xFFFFFFFF);
        claimedAt = uint32((idAndStamps >> 128) & 0xFFFFFFFF);

        uint256 dataLength = message.length - 48;
        data = new bytes(dataLength);
        for (uint256 i = 0; i < dataLength; i++) {
            data[i] = message[i + 48];
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IActionMsgReceiver {
    function onAction(bytes4 action, bytes memory message) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IErc20Min {
    /// @dev ERC-20 `balanceOf`
    function balanceOf(address account) external view returns (uint256);

    /// @dev ERC-20 `transfer`
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /// @dev ERC-20 `transferFrom`
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /// @dev EIP-2612 `permit`
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRewardAdviser {
    struct Advice {
        // advice on new "shares" (in the reward pool) to create
        address createSharesFor;
        uint96 sharesToCreate;
        // advice on "shares" to redeem
        address redeemSharesFrom;
        uint96 sharesToRedeem;
        // advice on address the reward against redeemed shares to send to
        address sendRewardTo;
    }

    function getRewardAdvice(bytes4 action, bytes memory message)
        external
        returns (Advice memory);
}

// SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-fixed, compiler-gt-0_8
pragma solidity ^0.8.0;

interface IStakingTypes {
    // Stake type terms
    struct Terms {
        // if stakes of this kind allowed
        bool isEnabled;
        // if messages on stakes to be sent to the {RewardMaster}
        bool isRewarded;
        // limit on the minimum amount staked, no limit if zero
        uint32 minAmountScaled;
        // limit on the maximum amount staked, no limit if zero
        uint32 maxAmountScaled;
        // Stakes not accepted before this time, has no effect if zero
        uint32 allowedSince;
        // Stakes not accepted after this time, has no effect if zero
        uint32 allowedTill;
        // One (at least) of the following three params must be non-zero
        // if non-zero, overrides both `exactLockPeriod` and `minLockPeriod`
        uint32 lockedTill;
        // ignored if non-zero `lockedTill` defined, overrides `minLockPeriod`
        uint32 exactLockPeriod;
        // has effect only if both `lockedTill` and `exactLockPeriod` are zero
        uint32 minLockPeriod;
    }

    struct Stake {
        // index in the `Stake[]` array of `stakes`
        uint32 id;
        // defines Terms
        bytes4 stakeType;
        // time this stake was created at
        uint32 stakedAt;
        // time this stake can be claimed at
        uint32 lockedTill;
        // time this stake was claimed at (unclaimed if 0)
        uint32 claimedAt;
        // amount of tokens on this stake (assumed to be less 1e27)
        uint96 amount;
        // address stake voting power is delegated to
        address delegatee;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev Interface to call `totalStaked` on the Staking contract
interface ITotalStaked {
    function totalStaked() external returns (uint96);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IStaking
interface IVotingPower {
    struct Snapshot {
        uint32 beforeBlock;
        uint96 ownPower;
        uint96 delegatedPower;
    }

    /// @dev Voting power integrants
    struct Power {
        uint96 own; // voting power that remains after delegating to others
        uint96 delegated; // voting power delegated by others
    }

    /// @notice Returns total voting power staked
    /// @dev "own" and "delegated" voting power summed up
    function totalVotingPower() external view returns (uint256);

    /// @notice Returns total "own" and total "delegated" voting power separately
    /// @dev Useful, if "own" and "delegated" voting power treated differently
    function totalPower() external view returns (Power memory);

    /// @notice Returns global snapshot for given block
    /// @param blockNum - block number to get state at
    /// @param hint - off-chain computed index of the required snapshot
    function globalSnapshotAt(uint256 blockNum, uint256 hint)
        external
        view
        returns (Snapshot memory);

    /// @notice Returns snapshot on given block for given account
    /// @param _account - account to get snapshot for
    /// @param blockNum - block number to get state at
    /// @param hint - off-chain computed index of the required snapshot
    function snapshotAt(
        address _account,
        uint256 blockNum,
        uint256 hint
    ) external view returns (Snapshot memory);

    /// @dev Returns block number of the latest global snapshot
    function latestGlobalsSnapshotBlock() external view returns (uint256);

    /// @dev Returns block number of the given account latest snapshot
    function latestSnapshotBlock(address _account)
        external
        view
        returns (uint256);

    /// @dev Returns number of global snapshots
    function globalsSnapshotLength() external view returns (uint256);

    /// @dev Returns number of snapshots for given account
    function snapshotLength(address _account) external view returns (uint256);

    /// @dev Returns global snapshot at given index
    function globalsSnapshot(uint256 _index)
        external
        view
        returns (Snapshot memory);

    /// @dev Returns snapshot at given index for given account
    function snapshot(address _account, uint256 _index)
        external
        view
        returns (Snapshot memory);
}

// SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-fixed, compiler-gt-0_8
pragma solidity ^0.8.0;

/**
 * @title Claimable
 * @notice It withdraws accidentally sent tokens from this contract.
 */
contract Claimable {
    bytes4 private constant SELECTOR_TRANSFER =
        bytes4(keccak256(bytes("transfer(address,uint256)")));

    /// @dev Withdraws ERC20 tokens from this contract
    /// (take care of reentrancy attack risk mitigation)
    function _claimErc20(
        address token,
        address to,
        uint256 amount
    ) internal {
        // solhint-disable avoid-low-level-calls
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(SELECTOR_TRANSFER, to, amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "claimErc20: TRANSFER_FAILED"
        );
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-fixed, compiler-gt-0_8
pragma solidity ^0.8.0;

/// @title Staking
abstract contract ImmutableOwnable {
    /// @notice The owner who has privileged rights
    // solhint-disable-next-line var-name-mixedcase
    address public immutable OWNER;

    /// @dev Throws if called by any account other than the {OWNER}.
    modifier onlyOwner() {
        require(OWNER == msg.sender, "ImmOwn: unauthorized");
        _;
    }

    constructor(address _owner) {
        require(_owner != address(0), "ImmOwn: zero owner address");
        OWNER = _owner;
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-fixed, compiler-gt-0_8
pragma solidity ^0.8.0;

/**
 * @title NonReentrant
 * @notice It provides reentrancy guard.
 * The code borrowed from openzeppelin-contracts.
 * Unlike original, this version requires neither `constructor` no `init` call.
 */
abstract contract NonReentrant {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _reentrancyStatus;

    modifier nonReentrant() {
        // Being called right after deployment, when _reentrancyStatus is 0 ,
        // it does not revert (which is expected behaviour)
        require(_reentrancyStatus != _ENTERED, "claimErc20: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _reentrancyStatus = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _reentrancyStatus = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-fixed, compiler-gt-0_8
pragma solidity ^0.8.0;

abstract contract Utils {
    function safe32(uint256 n) internal pure returns (uint32) {
        require(n < 2**32, "UNSAFE32");
        return uint32(n);
    }

    function safe96(uint256 n) internal pure returns (uint96) {
        require(n < 2**96, "UNSAFE96");
        return uint96(n);
    }

    function safe128(uint256 n) internal pure returns (uint128) {
        require(n < 2**128, "UNSAFE128");
        return uint128(n);
    }

    function safe160(uint256 n) internal pure returns (uint160) {
        require(n < 2**160, "UNSAFE160");
        return uint160(n);
    }

    function safe32TimeNow() internal view returns (uint32) {
        return safe32(timeNow());
    }

    function safe32BlockNow() internal view returns (uint32) {
        return safe32(blockNow());
    }

    /// @dev Returns the current block timestamp (added to ease testing)
    function timeNow() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /// @dev Returns the current block number (added to ease testing)
    function blockNow() internal view virtual returns (uint256) {
        return block.number;
    }
}