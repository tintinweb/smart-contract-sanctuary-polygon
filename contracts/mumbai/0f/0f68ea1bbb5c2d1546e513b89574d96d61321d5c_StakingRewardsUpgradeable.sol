// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../lootboxUpgradeables/ILootBoxUpgradeable.sol";
import "./IPancakeV2Router.sol";

contract StakingRewardsUpgradeable is
    Initializable,
    ReentrancyGuardUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable
{
    IERC20 public rewardsToken;
    IERC20 public stakingToken;
    IERC20 public pair;
    IERC20 public USDC;
    IPancakeV2Router internal _router;
    uint256 public periodFinish;
    uint256 public rewardsDuration;
    PoolData public flexiblePool;
    PoolData public lockedPool;
    ILootBoxUpgradeable public lootBox;
    // total rewards stored in contract
    uint256 private rewardTokens;
    // minimum amount of locked stake amount in USDC
    uint256 public minimumLockedStake;

    /**
     * @dev Stake weight is proportional to deposit amount and time locked, precisely
     *      "deposit amount wei multiplied by (fraction of the year locked)"
     * @dev In case of flexible stake, stake weight is proportional to the amount staked
     * @dev To avoid significant precision loss due to multiplication by "fraction of the year" [0, 1],
     *      weight is stored multiplied by 1e6 constant, as an integer
     */
    uint256 internal constant WEIGHT_MULTIPLIER = 1e6;
    /**
     * @dev Rewards per weight are stored multiplied by 1e12, as integers.
     */
    uint256 internal constant REWARD_PER_WEIGHT_MULTIPLIER = 1e12;

    // keeps track of stakers staked in locked staking pool
    mapping(address => User) public lockedStakingUsers;
    // keeps track of stakers staked in flexible staking pool
    mapping(address => User) public flexibleStakingUsers;
    // keeps track of all the rewards of users
    mapping(address => uint256) public rewards;

    struct PoolData {
        uint256 totalLockedTokens;
        uint256 totalLockedWeight;
        uint256 yieldRewardsPerWeight;
        uint256 lastUpdatedTime;
        uint256 rewardsRate;
    }

    struct Deposit {
        uint256 tokenAmount;
        uint256 weight;
        uint256 lockedFrom;
        uint256 lockedUntil;
        uint256 lootBoxesClaimed;
    }

    struct User {
        // @dev Total staked amount
        uint256 tokenAmount;
        // @dev Total weight
        uint256 totalWeight;
        // @dev Auxiliary variable for yield calculation
        uint256 subYieldRewards;
        // @dev An array of holder's deposits
        Deposit[] deposits;
    }

    function initialize(
        address _rewardsToken,
        address _stakingToken,
        ILootBoxUpgradeable _lootBox,
        IERC20 _pair,
        IERC20 _USDC
    ) public initializer {
        __ReentrancyGuard_init();
        __AccessControl_init();
        __Pausable_init();

        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
        lootBox = _lootBox;
        pair = _pair;
        USDC = _USDC;

        // setting rewards duration to 3 years
        rewardsDuration = 30 days * 12 * 3;

        flexiblePool.lastUpdatedTime = block.timestamp;
        lockedPool.lastUpdatedTime = block.timestamp;

        periodFinish = block.timestamp + rewardsDuration;

        flexiblePool.rewardsRate = 100000000000000000 / rewardsDuration;
        lockedPool.rewardsRate = 200000000000000000 / rewardsDuration;

        _router = IPancakeV2Router(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff); // mumbai: 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /* ========== VIEWS ========== */

    /**
     * @notice Calculates current yield rewards value available for user
     *
     * @return calculated yield reward value for the staker
     */
    function pendingYieldRewards() external view returns (uint256) {
        // get references to the user's flexible and locked pool stakes
        User memory flexibleStake = flexibleStakingUsers[msg.sender];
        User memory lockedStake = lockedStakingUsers[msg.sender];

        // the user must have stakes in at least one of the pools
        require(
            flexibleStake.tokenAmount > 0 || lockedStake.tokenAmount > 0,
            "stake amount is 0"
        );

        uint256 pendingRewards;
        uint256 secondsPassed;
        uint256 newLockedRewardsPerWeight;
        uint256 newFlexibleRewardsPerWeight;
        uint256 poolIskRewards;
        // if user has stakes in flexible pool, calculate pending rewards
        if (flexibleStake.tokenAmount > 0) {
            if (block.timestamp > flexiblePool.lastUpdatedTime) {
                secondsPassed = block.timestamp > periodFinish
                    ? periodFinish - flexiblePool.lastUpdatedTime
                    : block.timestamp - flexiblePool.lastUpdatedTime;

                // calculate rewards accumulated for flexible pool
                poolIskRewards = secondsPassed * flexiblePool.rewardsRate;

                // recalculated value for `yieldRewardsPerWeight` for flexible pools
                newFlexibleRewardsPerWeight =
                    rewardToWeight(
                        poolIskRewards,
                        flexiblePool.totalLockedWeight
                    ) +
                    flexiblePool.yieldRewardsPerWeight;
            } else {
                // if smart contract state is up to date, we don't recalculate
                newFlexibleRewardsPerWeight = flexiblePool
                    .yieldRewardsPerWeight;
            }

            pendingRewards +=
                weightToReward(
                    flexibleStake.totalWeight,
                    newFlexibleRewardsPerWeight
                ) -
                flexibleStake.subYieldRewards;
        }

        // if user has stakes in locked pool, calculate pending rewards
        if (lockedStake.tokenAmount > 0) {
            if (block.timestamp > lockedPool.lastUpdatedTime) {
                secondsPassed = block.timestamp > periodFinish
                    ? periodFinish - lockedPool.lastUpdatedTime
                    : block.timestamp - lockedPool.lastUpdatedTime;
                // calculate rewards accumulated for locked pool

                poolIskRewards = secondsPassed * lockedPool.rewardsRate;

                // recalculated value for `yieldRewardsPerWeight` for flexible pools
                newLockedRewardsPerWeight =
                    rewardToWeight(
                        poolIskRewards,
                        lockedPool.totalLockedWeight
                    ) +
                    lockedPool.yieldRewardsPerWeight;
            } else {
                // if smart contract state is up to date, we don't recalculate
                newLockedRewardsPerWeight = lockedPool.yieldRewardsPerWeight;
            }

            pendingRewards +=
                weightToReward(
                    lockedStake.totalWeight,
                    newLockedRewardsPerWeight
                ) -
                lockedStake.subYieldRewards;
        }

        return pendingRewards;
    }

    /**
     * @dev Similar to public pendingYieldRewards, but performs calculations based on
     *      current smart contract state only, not taking into account any additional
     *      time which might have passed
     *
     * @return pending calculated yield reward value for the user
     */
    function _pendingYieldRewards()
        internal
        view
        returns (
            uint256 pending,
            bool,
            bool
        )
    {
        // read user data structure into memory
        User memory flexibleStake = flexibleStakingUsers[msg.sender];
        User memory lockedStake = lockedStakingUsers[msg.sender];

        if (flexibleStake.tokenAmount > 0) {
            pending +=
                weightToReward(
                    flexibleStake.totalWeight,
                    flexiblePool.yieldRewardsPerWeight
                ) -
                flexibleStake.subYieldRewards;
        }
        if (lockedStake.tokenAmount > 0) {
            pending +=
                weightToReward(
                    lockedStake.totalWeight,
                    lockedPool.yieldRewardsPerWeight
                ) -
                lockedStake.subYieldRewards;
        }

        // return pending rewards and also booleans representing user's stakes in both pools
        return (
            pending,
            flexibleStake.tokenAmount > 0,
            lockedStake.tokenAmount > 0
        );
    }

    function getPoolLastUpdateTime(bool isFlexible)
        external
        view
        returns (uint256)
    {
        if (isFlexible) {
            return flexiblePool.lastUpdatedTime;
        } else {
            return lockedPool.lastUpdatedTime;
        }
    }

    function getPoolYieldRewardsPerWeight(bool isFlexible)
        external
        view
        returns (uint256)
    {
        if (isFlexible) {
            return
                flexiblePool.yieldRewardsPerWeight /
                REWARD_PER_WEIGHT_MULTIPLIER;
        } else {
            return
                lockedPool.yieldRewardsPerWeight / REWARD_PER_WEIGHT_MULTIPLIER;
        }
    }

    function getTotalStakesWeight(bool isFlexible)
        external
        view
        returns (uint256)
    {
        if (isFlexible) {
            return flexiblePool.totalLockedWeight;
        } else {
            return lockedPool.totalLockedWeight;
        }
    }

    /**
     * @return reward rate for locked pool
     */
    function getLockedPoolRewardRate() public view returns (uint256) {
        return lockedPool.rewardsRate;
    }

    /**
     * @return reward rate for flexible pool
     */
    function getFlexiblePoolRewardRate() public view returns (uint256) {
        return flexiblePool.rewardsRate;
    }

    function pendingLootBoxes(uint256 _depositId)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        User memory lockedStaker = lockedStakingUsers[msg.sender];
        Deposit memory lockedDeposit = lockedStaker.deposits[_depositId];
        require(lockedDeposit.weight > 0, "deposit does not exist");

        // calculate pending loot boxes
        (
            uint256 commonLootBoxes,
            uint256 rareLootBoxes,
            uint256 epicLootBoxes
        ) = _pendingLootBoxes(lockedDeposit);

        return (commonLootBoxes, rareLootBoxes, epicLootBoxes);
    }

    function _pendingLootBoxes(Deposit memory lockedDeposit)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 claimTill;
        if (block.timestamp > lockedDeposit.lockedUntil) {
            claimTill = lockedDeposit.lockedUntil;
        } else {
            claimTill = block.timestamp;
        }

        // total number of months passed since deposit was made
        uint256 monthsPassed = (claimTill - lockedDeposit.lockedFrom) / 30 days;
        uint256 positionInOrder;
        // counters
        uint256 common;
        uint256 rare;
        uint256 epic;

        for (
            uint256 i = 1;
            i <= monthsPassed - lockedDeposit.lootBoxesClaimed;
            i++
        ) {
            // calculate tier according to order: c c r r e e c c r r e e
            positionInOrder = (lockedDeposit.lootBoxesClaimed + i) % 6;
            if (positionInOrder > 4 || positionInOrder == 0) {
                // epic
                epic++;
            } else if (positionInOrder >= 3) {
                // rare
                rare++;
            } else {
                // common
                common++;
            }
        }

        return (common, rare, epic);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @dev Used for staking locked pool stakes
     * @param _amount amount of tokens to stake
     */
    function stakeInLocked(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Cannot stake 0 tokens");
        // uint256 totalLPTokens = pair.totalSupply();
        uint256 USDCBalanceOf = USDC.balanceOf(address(pair));
        uint256 IsekaiBalanceOf = rewardsToken.balanceOf(address(pair));

        // convert IsekaiCoin to USDC
        address[] memory tokens = new address[](2);
        tokens[0] = address(rewardsToken);
        tokens[1] = address(USDC);
        uint256[] memory amountsOut = _router.getAmountsOut(
            1000000000, // 1 IsekaiCoin
            tokens
        );
        uint256 totalLiquidity = (IsekaiBalanceOf * amountsOut[1]) +
            USDCBalanceOf;

        // value of LP tokens being staked
        uint256 usdValueOfStake = (_amount * totalLiquidity) /
            pair.totalSupply();
        require(
            usdValueOfStake > minimumLockedStake,
            "minimum stake requirement unmet"
        );
        // amount needs to be at least 5 if user is staking in locked pool so 20% penalty can be deducted

        // update current yield rewards per weight
        _sync();

        // get a link to user data struct, we will write to it later
        User storage user = lockedStakingUsers[msg.sender];
        // process current pending rewards if any
        if (user.tokenAmount > 0) {
            _processRewards();
        }

        uint256 previousBalance = stakingToken.balanceOf(address(this));
        // transfer `_amount`
        stakingToken.transferFrom(address(msg.sender), address(this), _amount);
        // read new balance, usually this is just the difference `previousBalance - _amount`
        uint256 newBalance = stakingToken.balanceOf(address(this));
        // calculate real amount taking into account deflation
        uint256 addedAmount = newBalance - previousBalance;

        // set the `lockFrom` and `lockUntil` taking into account that
        // locked staking means that staking period is fixed at 365 days
        // flexible staking means that the lockedUntil value provided by user is used
        uint256 lockFrom = block.timestamp;
        // considering 1 month = 30 days
        uint256 lockUntil = lockFrom + 360 days;
        require(lockUntil <= periodFinish, "locked staking has ended");

        uint256 stakeWeight = (((lockUntil - lockFrom) * WEIGHT_MULTIPLIER) /
            360 days) * addedAmount;

        // makes sure stakeWeight is valid
        assert(stakeWeight > 0);

        // create and save the deposit (append it to deposits array)
        Deposit memory deposit = Deposit({
            tokenAmount: addedAmount,
            weight: stakeWeight,
            lockedFrom: lockFrom,
            lockedUntil: lockUntil,
            lootBoxesClaimed: 0
        });

        // deposit ID is an index of the deposit in `deposits` array
        user.deposits.push(deposit);
        // update user record
        user.tokenAmount += addedAmount;
        user.totalWeight += stakeWeight;
        user.subYieldRewards = weightToReward(
            user.totalWeight,
            lockedPool.yieldRewardsPerWeight
        );

        // update global variables
        lockedPool.totalLockedTokens += addedAmount;
        lockedPool.totalLockedWeight += stakeWeight;

        emit StakedInLock(address(msg.sender), addedAmount);
        emit UpdateLockedStake(lockedPool.totalLockedTokens, block.timestamp);
    }

    /**
     * @dev Used for staking flexible pool stakes
     * @param _amount amount of tokens to stake
     */
    function stakeInFlexible(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Cannot stake 0 tokens");
        require(
            periodFinish - block.timestamp >= 1 weeks,
            "staking period has ended for flexible pool"
        );
        // update current yield rewards per weight
        _sync();

        // get a link to user data struct, we will write to it later
        User storage user = flexibleStakingUsers[msg.sender];

        // process current pending rewards if any
        if (user.tokenAmount > 0) {
            _processRewards();
        }

        uint256 previousBalance = stakingToken.balanceOf(address(this));
        // transfer `_amount`
        stakingToken.transferFrom(address(msg.sender), address(this), _amount);
        // read new balance, this is just the difference `previousBalance - _amount`
        uint256 newBalance = stakingToken.balanceOf(address(this));
        // calculate real amount taking into account deflation
        uint256 addedAmount = newBalance - previousBalance;

        uint256 stakeWeight = WEIGHT_MULTIPLIER * addedAmount;

        // makes sure stakeWeight is valid
        assert(stakeWeight > 0);

        // create and save the deposit (append it to deposits array)
        // lockFrom and lockUntil are 0 because stake is flexible
        Deposit memory deposit = Deposit({
            tokenAmount: addedAmount,
            weight: stakeWeight,
            lockedFrom: 0,
            lockedUntil: 0,
            lootBoxesClaimed: 0 // this will stay zero since it is a flexible stake
        });

        // deposit ID is an index of the deposit in `deposits` array
        user.deposits.push(deposit);
        // update user record
        user.tokenAmount += addedAmount;
        user.totalWeight += stakeWeight;
        user.subYieldRewards = weightToReward(
            user.totalWeight,
            flexiblePool.yieldRewardsPerWeight
        );

        // update global variables
        flexiblePool.totalLockedTokens += addedAmount;
        flexiblePool.totalLockedWeight += stakeWeight;

        emit StakedInFlexible(msg.sender, _amount);
        emit UpdateFlexibleStake(
            flexiblePool.totalLockedTokens,
            block.timestamp
        );
    }

    /**
     * @dev returns USDC value of total amount staked in both pools
     */
    function getTotalStakeAmount() external view returns (uint256) {
        return (lockedPool.totalLockedTokens + flexiblePool.totalLockedTokens);
    }

    /**
     * @dev Used for unstaking flexible pool stakes
     *
     * @param _depositId deposit ID to unstake from, zero-indexed
     * @param _amount amount of tokens to unstake
     */
    function unstakeFlexible(uint256 _depositId, uint256 _amount) external {
        // get a link to user data struct, we will write to it later
        User storage user = flexibleStakingUsers[msg.sender];
        // get a link to the corresponding deposit, we may write to it later
        Deposit storage stakeDeposit = user.deposits[_depositId];

        // verify an amount is set
        require(_amount > 0, "zero amount");
        // verify available balance
        require(stakeDeposit.tokenAmount >= _amount, "amount exceeds stake");

        // update smart contract state
        _sync();
        // and process current pending rewards if any
        _processRewards();

        // recalculate deposit weight
        uint256 previousWeight = stakeDeposit.weight;
        uint256 newWeight = (stakeDeposit.tokenAmount - _amount) *
            WEIGHT_MULTIPLIER;

        // update the deposit, or remove it if its depleted
        if (stakeDeposit.tokenAmount - _amount == 0) {
            user.deposits[_depositId] = user.deposits[user.deposits.length - 1];
            user.deposits.pop();
        } else {
            stakeDeposit.tokenAmount -= _amount;
            stakeDeposit.weight = newWeight;
        }

        // update user record
        user.tokenAmount -= _amount;
        user.totalWeight = user.totalWeight - previousWeight + newWeight;
        user.subYieldRewards = weightToReward(
            user.totalWeight,
            flexiblePool.yieldRewardsPerWeight
        );

        // update global variables
        flexiblePool.totalLockedWeight =
            flexiblePool.totalLockedWeight -
            previousWeight +
            newWeight;
        flexiblePool.totalLockedTokens -= _amount;

        stakingToken.transfer(msg.sender, _amount);

        // emit an event
        emit UpdateFlexibleStake(
            flexiblePool.totalLockedTokens,
            block.timestamp
        );
        emit UnstakedFlexible(msg.sender, _amount);
    }

    /**
     * @dev Used for unstaking locked pool stakes
     * @param _depositId deposit ID to unstake from, zero-indexed
     */
    function unstakeLocked(uint256 _depositId) external {
        // get a link to user data struct, we will write to it later
        User storage user = lockedStakingUsers[msg.sender];
        // get a link to the corresponding deposit, we may write to it later
        Deposit memory stakeDeposit = user.deposits[_depositId];

        // if staker deposit doesn't exist this check will fail
        require(stakeDeposit.tokenAmount > 0, "empty deposit");

        // update smart contract state
        _sync();
        // and process current pending rewards if any
        _processRewards();
        // claim any unclaimed loot boxes
        claimLootBoxes(_depositId);

        // remove deposit
        user.deposits[_depositId] = user.deposits[user.deposits.length - 1];
        user.deposits.pop();

        // update user record
        user.tokenAmount -= stakeDeposit.tokenAmount;
        user.totalWeight = user.totalWeight - stakeDeposit.weight;
        user.subYieldRewards = weightToReward(
            user.totalWeight,
            lockedPool.yieldRewardsPerWeight
        );

        // update global variables
        lockedPool.totalLockedWeight =
            lockedPool.totalLockedWeight -
            stakeDeposit.weight;

        uint256 unstakedTokens = block.timestamp < stakeDeposit.lockedUntil
            ? ((stakeDeposit.tokenAmount * 8000) / 10000)
            : stakeDeposit.tokenAmount;

        lockedPool.totalLockedTokens -= unstakedTokens;

        stakingToken.transfer(msg.sender, unstakedTokens);

        // emit an event
        emit UnstakedLocked(msg.sender, unstakedTokens);
        emit UpdateLockedStake(lockedPool.totalLockedTokens, block.timestamp);
    }

    /**
     * @notice Service function to calculate and process pending yield rewards to the sender
     *
     * @dev Can be executed by anyone at any time, but has an effect only when
     *      executed by deposit holder and when at least one second / block passes from the
     *      previous reward processing
     * @dev Executed internally when staking and unstaking, executes sync() under the hood
     *      before making further calculations and payouts
     * @dev When timing conditions are not met (executed too frequently, or after factory
     *      end block), function doesn't throw and exits silently
     */
    function processRewards() external {
        _sync();
        // delegate call to an internal function
        _processRewards();
    }

    /**
     * @dev Used internally, mostly by children implementations, see processRewards()
     *
     * @return pendingYield the rewards calculated and added to user's rewards
     */
    function _processRewards() internal virtual returns (uint256 pendingYield) {
        bool hasFlexibleStakes;
        bool hasLockedStakes;
        // calculate pending yield rewards, this value will be returned
        (
            pendingYield,
            hasFlexibleStakes,
            hasLockedStakes
        ) = _pendingYieldRewards();
        // if pending yield is zero - just return silently
        if (pendingYield == 0) return 0;
        // add up user's rewards
        rewards[msg.sender] += pendingYield;
        // update user's subYieldRewards variable
        if (hasLockedStakes) {
            lockedStakingUsers[msg.sender].subYieldRewards = weightToReward(
                lockedStakingUsers[msg.sender].totalWeight,
                lockedPool.yieldRewardsPerWeight
            );
        }
        if (hasFlexibleStakes) {
            flexibleStakingUsers[msg.sender].subYieldRewards = weightToReward(
                flexibleStakingUsers[msg.sender].totalWeight,
                flexiblePool.yieldRewardsPerWeight
            );
        }

        // emit an event
        // emit YieldClaimed(msg.sender, _staker, _useSILV, pendingYield);
    }

    /**
     * @dev Used to claim loot boxes for a locked pool staker
     */
    function claimLootBoxes(uint256 _depositId) public {
        User memory lockedStaker = lockedStakingUsers[msg.sender];
        require(lockedStaker.tokenAmount > 0, "empty deposit");
        Deposit memory lockedDeposit = lockedStaker.deposits[_depositId];

        // if all loot boxes have been claimed, return silenty
        if (lockedDeposit.lootBoxesClaimed >= 12) {
            return;
        }

        // calculate pending loot boxes
        (
            uint256 commonLootBoxes,
            uint256 rareLootBoxes,
            uint256 epicLootBoxes
        ) = _pendingLootBoxes(lockedDeposit);

        uint256 totalLootBoxes = commonLootBoxes +
            rareLootBoxes +
            epicLootBoxes;
        // mint loot boxes
        if (commonLootBoxes > 0) {
            lootBox.mintLootBox(msg.sender, 1, commonLootBoxes);
        }
        if (rareLootBoxes > 0) {
            lootBox.mintLootBox(msg.sender, 2, rareLootBoxes);
        }
        if (epicLootBoxes > 0) {
            lootBox.mintLootBox(msg.sender, 3, epicLootBoxes);
        }

        // update loot boxes claimed
        lockedStakingUsers[msg.sender]
            .deposits[_depositId]
            .lootBoxesClaimed += totalLootBoxes;
    }

    /**
     * @dev Converts stake weight to
     *      Isekaicoin reward value, applying the 10^12 division on weight
     *
     * @param _weight stake weight
     * @param rewardPerWeight Isekaicoin reward per weight
     * @return reward value normalized to 10^12
     */
    function weightToReward(uint256 _weight, uint256 rewardPerWeight)
        public
        pure
        returns (uint256)
    {
        // apply the formula and return
        return (_weight * rewardPerWeight) / REWARD_PER_WEIGHT_MULTIPLIER;
    }

    /**
     * @dev Converts reward Isekaicoin value to stake weight,
     *      applying the 10^12 multiplication on the reward
     *      - OR -
     * @dev Converts reward Isekaicoin value to reward/weight if stake weight is supplied as second
     *      function parameter instead of reward/weight
     *
     * @param reward yield reward
     * @param rewardPerWeight reward/weight (or stake weight)
     * @return stake weight (or reward/weight)
     */
    function rewardToWeight(uint256 reward, uint256 rewardPerWeight)
        public
        pure
        returns (uint256)
    {
        // apply the reverse formula and return
        return (reward * REWARD_PER_WEIGHT_MULTIPLIER) / rewardPerWeight;
    }

    /**
     * @dev used to withdraw processed rewards of a user
     *
     * @return rewards withdrawn
     */
    function withdrawRewards() external returns (uint256) {
        uint256 rewardsProcessed = rewards[msg.sender];
        require(rewardsProcessed > 0, "no rewards to withdraw");
        // udpdate reward token amount
        rewardTokens -= rewardsProcessed;
        rewards[msg.sender] = 0;
        rewardsToken.transfer(address(msg.sender), rewardsProcessed);

        emit Withdrawn(msg.sender, rewardsProcessed);
        return rewardsProcessed;
    }

    /**
     * @dev Used internally, mostly by children implementations, see sync()
     *
     * @dev Updates smart contract state (`yieldRewardsPerWeight`, `lastUpdatedTime`),
     */
    function _sync() internal {
        // sync both pools
        _syncPool(true);
        _syncPool(false);
        // emit an event
        // emit Synchronized(msg.sender, yieldRewardsPerWeight, lastUpdatedTime);
    }

    function _syncPool(bool isFlexible) internal {
        PoolData memory pool = isFlexible ? flexiblePool : lockedPool;
        uint256 totalStakingWeight = isFlexible
            ? flexiblePool.totalLockedWeight
            : lockedPool.totalLockedWeight;

        // if staking period has finished, return
        if (pool.lastUpdatedTime >= periodFinish) {
            return;
        }

        // to calculate the reward we need to know how many seconds have passed, and reward per second (reward rate)
        uint256 secondsPassed = block.timestamp > periodFinish
            ? periodFinish - pool.lastUpdatedTime
            : block.timestamp - pool.lastUpdatedTime;
        // update lastUpdatedTime
        pool.lastUpdatedTime = block.timestamp > periodFinish
            ? periodFinish
            : block.timestamp;

        // if locking weight is zero - just exit
        if (totalStakingWeight > 0) {
            // calculate the reward
            uint256 iskReward = secondsPassed * pool.rewardsRate;

            // update rewards per weight and `lastUpdatedTime`
            pool.yieldRewardsPerWeight += rewardToWeight(
                iskReward,
                totalStakingWeight
            );

            if (isFlexible) {
                flexiblePool.lastUpdatedTime = pool.lastUpdatedTime;
                flexiblePool.yieldRewardsPerWeight = pool.yieldRewardsPerWeight;
            } else {
                lockedPool.lastUpdatedTime = pool.lastUpdatedTime;
                lockedPool.yieldRewardsPerWeight = pool.yieldRewardsPerWeight;
            }
        }
        // if staking weight is 0, just update last updated time
        else {
            if (isFlexible) {
                flexiblePool.lastUpdatedTime = pool.lastUpdatedTime;
            } else {
                lockedPool.lastUpdatedTime = pool.lastUpdatedTime;
            }
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setMinimumLockedStake(uint256 _amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        minimumLockedStake = _amount;
    }

    /**
     * @dev used to add rewards to the contract
     */
    function addRewards(uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            rewardTokens + _amount <= 300000000000000000,
            "reward token limit exceeded"
        );
        rewardTokens += _amount;
        rewardsToken.transferFrom(address(msg.sender), address(this), _amount);

        emit RewardAdded(_amount);
    }

    // Added to support recovering LP Rewards from contract
    function recoverRewards(uint256 tokenAmount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(tokenAmount <= rewardTokens, "not enough rewards available");
        rewardsToken.transfer(address(msg.sender), tokenAmount);
        emit Recovered(tokenAmount);
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event StakedInLock(address indexed user, uint256 amount);
    event UpdateLockedStake(uint256 totalStake, uint256 timestamp);
    event StakedInFlexible(address indexed user, uint256 amount);
    event UpdateFlexibleStake(uint256 totalStake, uint256 timestamp);
    event UnstakedFlexible(address indexed staker, uint256 amount);
    event UnstakedLocked(address indexed staker, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Recovered(uint256 amount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface ILootBoxUpgradeable is IERC1155Upgradeable {
    function mintLootBox(
        address _to,
        uint8 _tier,
        uint256 _amount
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPancakeV2Router {
    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
library StringsUpgradeable {
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

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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