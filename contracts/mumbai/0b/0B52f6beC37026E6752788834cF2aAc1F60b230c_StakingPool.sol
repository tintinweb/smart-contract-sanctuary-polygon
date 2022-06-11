// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/SafeCast.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//import "hardhat/console.sol"; // uncomment if you need to use console.log() to debug

/**
 * - Token holders can stake their tokens (`StakingPool.stake()`) for 2-week, 3-month, 6-month
 *   and 12-month periods.
 * - Stakeholders earn rewards on all tokens they have in the staking contract. Longer lockup
 *   periods grant higher reward rates:
 *   - 2-week lockup - base rate
 *   - 3-month lockup - `1.5x` base rate
 *   - 6-month lockup - `2x` base rate
 *   - 12-month lockup - `4x` base rate
 * - Stakeholders can claim any rewards earned on their staked tokens at any time. In most cases this
 *   will be done as part of `restake()` or `withdraw()` by setting the `_claim` arg to `true`,
 *   it's cheaper and easier to claim and do something with the rewards in one go than it is to do
 *   so separately. It's also possible to claim rewards via `claimRewards()`, but it's mostly
 *   just used for testing the claim logic.
 * - When rewards are claimed they are credited to the stakeholder's **unlocked balance**.
 *   The unlocked balance earns rewards at the base rate.
 * - Stakeholders can `restake()` or `withdraw() any tokens from their **unlocked balance** at any time.
 * - The number of active stakes a stakeholder can have at any one time is limited to ensure that
 *   reward claims don't require an excessive amounts of gas. The current limit is 10.
 * - Stakeholders can increase their total stake without creating new individual stakes by amending
 *   an existing stake via `amend()`. If there are multiple existing stakes with the same
 *   lockup period then the most recently created one will be amended. When a stake is amended its
 *   lockup expiry time can either remain unchanged, or it can be extended (though the owner can
 *   force the latter option by setting `_features.forceExtendOnAmend` to `true`).
 * - Staking data will be imported via `batchImportAccounts()`.
 */
contract StakingPool is Ownable {
    using SafeMath for uint256;
    using SafeCast for uint256;

    event AccountOpened(address indexed stakeholder);
    event AccountClosed(address indexed stakeholder);
    event Staked(address indexed stakeholder, uint256 amount, uint8 period, uint256 expiresOn);
    event Unstaked(address indexed stakeholder, uint256 amount, uint8 period, uint256 expiredOn);
    event Withdrawn(address indexed stakeholder, uint256 amount);
    event RewardsClaimed(address indexed stakeholder, uint256 rewards);
    event FeaturesChanged(
        bool importEnabled,
        bool stakingEnabled,
        bool amendEnabled,
        bool withdrawEnabled,
        bool rewardsEnabled,
        bool forceExtendOnAmend
    );

    uint256 public constant REWARDS_RATE_PRECISION = 1e18;
    uint256 public constant TOKEN_DECIMAL_PRECISION = 1e18; // == 1 whole LOOM token
    uint256 private constant _MAX_UINT256 = ~uint256(0);

    uint256[4] public LOCKUP_PERIOD = [
        1209600, // 2 weeks == 14 days
        7884000, // 3 months == 91.25 days
        15768000, // 6 months == 182.5 days
        31536000 // 1 year == 365 days
    ];
    uint16[4] public BONUS_NUMERATOR = [100, 150, 200, 400]; // == x1, x1.5, x2, x4
    uint16 public constant BONUS_DENOMINATOR = 100;

    struct Stake {
        uint8 period;
        uint64 unlockOn; // timestamp indicating expiration of lockup period
        uint128 amount; // whole token amount (no fractional part)
    }

    struct UnpackedStake {
        uint8 period;
        uint256 unlockOn; // timestamp indicating expiration of lockup period
        uint256 amount; // 18 decimal precision
    }

    struct Stakeholder {
        uint256 lastClaimedAt; // last time rewards were claimed
        // unlocked balance that can be withdrawn at any time, earns rewards at the base rate,
        // 18 decimal precision
        uint256 balance;
        Stake[] stakes; // unsorted
    }

    struct UnpackedStakeholder {
        uint256 lastClaimedAt;
        uint256 balance;
        UnpackedStake[] stakes;
    }

    struct ExportedAccount {
        uint128 balance; // whole token amount (no fractional part)
        Stake[] stakes;
    }

    mapping(address => Stakeholder) private _stakeholderMap;

    IERC20 public stakingToken;
    // total amount currently staked (including the unlocked balance of all stakeholders)
    uint256 public totalStaked;
    // total rewards claimed by all stakeholder to date
    uint256 public totalRewardsClaimed;
    // number of stakeholders with non-zero balance or some staked amount
    uint256 public numStakeholders;
    // annual reward rate with 18 decimal precision
    uint256 public annualBaseRewardsRate;
    // max number of stakes a stakeholder can have at any point in time
    // setting this to zero disables the limit enforcement
    uint256 public maxStakesPerAccount;

    // the time from which rewards will begin accumulating on imported stakes
    uint64 public migrationStartTime;

    struct Features {
        bool importEnabled;
        bool stakingEnabled;
        bool amendEnabled;
        bool withdrawEnabled;
        bool rewardsEnabled;
        bool forceExtendOnAmend;
    }
    Features private _features;

    struct Stats {
        uint256 totalStaked;
        uint256 totalRewardsClaimed;
        uint256 numStakeholders;
        uint256 annualBaseRewardsRate;
    }

    /**
     * @dev Reverts if the msg.sender isn't an existing stakeholder.
     */
    modifier onlyStakeholder() {
        Stakeholder storage _stakeholder = _stakeholderMap[msg.sender];
        require(
            _stakeholder.balance != 0 || _stakeholder.stakes.length != 0,
            "SP: account doesn't exist"
        );
        _;
    }

    /**
     * @dev Reverts if the staking feature is disabled.
     */
    modifier whenStakingEnabled() {
        require(_features.stakingEnabled, "SP: staking disabled");
        _;
    }

    /**
     * @dev Reverts if the amend feature is disabled.
     */
    modifier whenAmendEnabled() {
        require(_features.amendEnabled, "SP: amend disabled");
        _;
    }

    /**
     * @dev Reverts if the withdraw feature is disabled.
     */
    modifier whenWithdrawEnabled() {
        require(_features.withdrawEnabled, "SP: withdraw disabled");
        _;
    }

    constructor(
        address _token,
        uint256 _rewardsRate,
        uint64 _migrationStartTime
    ) {
        stakingToken = IERC20(_token);
        annualBaseRewardsRate = _rewardsRate;
        migrationStartTime = _migrationStartTime;
        _features.importEnabled = true;
        maxStakesPerAccount = 10;
    }

    function getStats() public view returns (Stats memory stats) {
        stats.totalStaked = totalStaked;
        stats.totalRewardsClaimed = totalRewardsClaimed;
        stats.numStakeholders = numStakeholders;
        stats.annualBaseRewardsRate = annualBaseRewardsRate;
    }

    function getStakeholder(address _stakeholder)
        public
        view
        returns (UnpackedStakeholder memory holder)
    {
        Stakeholder storage account = _stakeholderMap[_stakeholder];
        holder.lastClaimedAt = account.lastClaimedAt;
        holder.balance = account.balance;
        holder.stakes = new UnpackedStake[](account.stakes.length);
        for (uint256 i = 0; i < account.stakes.length; i++) {
            holder.stakes[i] = _unpackStake(account.stakes[i]);
        }
    }

    function getFeatures() public view returns (Features memory) {
        return _features;
    }

    function setFeatures(Features calldata _f) external onlyOwner {
        _features = _f;
        emit FeaturesChanged(
            _f.importEnabled,
            _f.stakingEnabled,
            _f.amendEnabled,
            _f.withdrawEnabled,
            _f.rewardsEnabled,
            _f.forceExtendOnAmend
        );
    }

    function setBaseRewardsRate(uint256 _rate) external onlyOwner {
        // TODO: basic validation
        annualBaseRewardsRate = _rate;
    }

    function setMaxStakesPerAccount(uint256 _maxStakes) external onlyOwner {
        maxStakesPerAccount = _maxStakes;
    }

    /**
     * @notice Stake the given amount of tokens from an Ethereum account.
     * @dev The caller must approve the StakingPool contract to transfer the amount being staked
     *      (via ERC20.approve on the stakingToken) before this function is called.
     */
    function stake(uint256 _amount, uint8 _period) external whenStakingEnabled {
        // Since the fractional part of the amount will be discarded make sure that the amount is
        // at least 1 LOOM, otherwise there'll be literally nothing left to stake.
        require(_amount >= TOKEN_DECIMAL_PRECISION, "StakingPool: amount too small");
        require(_period < 4, "StakingPool: invalid lockup period");

        Stakeholder storage stakeholder = _stakeholderMap[msg.sender];
        bool isNewStakeholder = stakeholder.balance == 0 && stakeholder.stakes.length == 0;

        require(
            (maxStakesPerAccount == 0) || (stakeholder.stakes.length < maxStakesPerAccount),
            "SP: account has too many stakes"
        );

        // drop the fractional part
        uint256 stakeAmount = _amount.div(TOKEN_DECIMAL_PRECISION).mul(TOKEN_DECIMAL_PRECISION);
        _addStake(stakeholder.stakes, stakeAmount, _period);

        totalStaked = totalStaked.add(stakeAmount);

        if (isNewStakeholder) {
            numStakeholders++;
            stakeholder.lastClaimedAt = block.timestamp;
            emit AccountOpened(msg.sender);
        }

        require(
            stakingToken.transferFrom(msg.sender, address(this), stakeAmount),
            "StakingPool: failed to stake due to failed token transfer"
        );
    }

    /**
     * @notice Restake the given amount of tokens from the unlocked balance.
     * @param _amount Amount of tokens to restake, or _MAX_UINT256 to restake the entire unlocked balance.
     * @param _period Period tokens should be restaked for.
     * @param _claim Set to `true` in order to claim rewards before tokens are restaked, this makes
     *               it possible to claim & restake in one go (cheaper than doing so separately).
     */
    function restake(
        uint256 _amount,
        uint8 _period,
        bool _claim
    ) external whenStakingEnabled onlyStakeholder {
        if (_claim) {
            _claimRewards();
        }

        Stakeholder storage stakeholder = _stakeholderMap[msg.sender];
        require(
            (maxStakesPerAccount == 0) || (stakeholder.stakes.length < maxStakesPerAccount),
            "SP: account has too many stakes"
        );

        if (_amount == _MAX_UINT256) {
            _amount = stakeholder.balance;
        } else {
            require(
                _amount <= stakeholder.balance,
                "StakingPool: amount exceeds available balance"
            );
        }
        // Since the fractional part of the amount will be discarded make sure that the amount is
        // at least 1 LOOM, otherwise there'll be literally nothing left to stake.
        require(_amount >= TOKEN_DECIMAL_PRECISION, "StakingPool: amount too small");

        // drop the fractional part
        uint256 stakeAmount = _amount.div(TOKEN_DECIMAL_PRECISION).mul(TOKEN_DECIMAL_PRECISION);
        _addStake(stakeholder.stakes, stakeAmount, _period);

        stakeholder.balance = stakeholder.balance.sub(stakeAmount);
        // NOTE: totalStaked doesn't change since it includes the unlocked balance from which the
        //       stake amount comes from.
    }

    /**
     * @notice Increase the amount of the most recently created stake (matching the given lockup
     *         period), and optionally extend its lockup period. If no such stake exists yet this
     *         function will revert.
     *
     *         The amount by which the stake is increased can either come from the stakeholder's
     *         Ethereum wallet, or their unlocked balance, or both.
     *
     *         Rewards will be automatically claimed before the stake is updated.
     *
     *         If a 3-month stake is amended one month later with `_extend == true` then its unlock
     *         time will be updated to 3 months out, so the stakeholder will have to wait another
     *         3 months for their stake to be unlocked instead of just 2 months.
     *
     * @param _amountFromWallet Amount to add to the stake from the Ethereum wallet, if zero then
     *                          only the unlocked balance will be used.
     * @param _amountFromBalance Amount to add to the stake from the unlocked balance,
     *                           or _MAX_UINT256 to add the entire unlocked balance.
     * @param _extend If `true` then the amended stake's unlock time will be extended, otherwise the
     *                original unlock time will remain unchanged.
     */
    function amend(
        uint256 _amountFromWallet,
        uint256 _amountFromBalance,
        uint8 _period,
        bool _extend
    ) external whenAmendEnabled onlyStakeholder {
        require(_extend || !_features.forceExtendOnAmend, "SP: must extend lockup");

        // After a stake is amended its total amount will be X + Y, where X is the original amount,
        // and Y is the amount added by _amendStake(). The currently pending rewards must be
        // distributed before updating the existing stake in order to ensure that amount Y only
        // starts earning rewards from this point on (rather than retroactively).
        Stakeholder storage stakeholder = _stakeholderMap[msg.sender];
        if (stakeholder.lastClaimedAt != block.timestamp) {
            _claimRewards();
        }

        if (_amountFromBalance == _MAX_UINT256) {
            _amountFromBalance = stakeholder.balance;
        } else {
            require(
                _amountFromBalance <= stakeholder.balance,
                "SP: amount exceeds available balance"
            );
        }

        uint256 stakeAmount =
            _amountFromWallet.add(_amountFromBalance).div(TOKEN_DECIMAL_PRECISION).mul(
                TOKEN_DECIMAL_PRECISION
            ); // drop the fractional part

        require(stakeAmount >= TOKEN_DECIMAL_PRECISION, "SP: amount too small");

        _amendStake(stakeholder.stakes, stakeAmount, _period, _extend);

        stakeholder.balance = stakeholder.balance.sub(stakeAmount.sub(_amountFromWallet));

        if (_amountFromWallet > 0) {
            totalStaked = totalStaked.add(_amountFromWallet);

            require(
                stakingToken.transferFrom(msg.sender, address(this), _amountFromWallet),
                "SP: token transfer failed"
            );
        }
    }

    /**
     * @dev Withdraws the given amount of tokens from the caller's unlocked staking balance.
     * @param _amount Amount of tokens to withdraw, or _MAX_UINT256 to withdraw the entire unlocked balance.
     * @param _claim Set to `true` in order to claim rewards before tokens are withdrawn, this makes
     *               it possible to claim & withdraw in one go (cheaper than doing so separately).
     */
    function withdraw(uint256 _amount, bool _claim) external whenWithdrawEnabled onlyStakeholder {
        require(_amount > 0, "SP: invalid amount");

        if (_claim) {
            _claimRewards();
        }

        Stakeholder storage stakeholder = _stakeholderMap[msg.sender];
        require(stakeholder.balance > 0, "StakingPool: nothing to withdraw");

        if (_amount == _MAX_UINT256) {
            _amount = stakeholder.balance;
        } else {
            require(
                _amount <= stakeholder.balance,
                "StakingPool: amount exceeds available balance"
            );
        }

        totalStaked = totalStaked.sub(_amount);
        stakeholder.balance = stakeholder.balance.sub(_amount);

        if (stakeholder.balance == 0 && stakeholder.stakes.length == 0) {
            numStakeholders--;
            delete _stakeholderMap[msg.sender];
            emit AccountClosed(msg.sender);
        }

        require(
            stakingToken.transfer(msg.sender, _amount),
            "StakingPool: withdraw failed due to failed token transfer"
        );

        emit Withdrawn(msg.sender, _amount);
    }

    /**
     * @notice Computes the rewards earned by the caller for their stake and credits them to the
     *         caller's unlocked balance, any stakes whose lockup period has expired will be removed
     *         and their amounts will be credited to the unlocked balance.
     *
     *         NOTE: Both restake() and withdraw() can claim rewards, which is more gas
     *         efficient because stakeholders can claim & restake, or claim & withdraw all in one tx.
     */
    function claimRewards() external onlyStakeholder {
        _claimRewards();
    }

    /**
     * @notice Computes the rewards earned by a stakeholder on their staked amounts since the last claim.
     * @param _stakeholder Address of the stakeholder.
     * @param _asAt Timestamp representing the end of the period for which rewards should be computed.
     * @return rewardsEarned Amount of tokens earned by the caller for staking since the last claim.
     * @return stakeUnlocked Total amount currently staked in expired lockups (that will be released
     *         next time rewards are claimed).
     */
    function pendingRewards(address _stakeholder, uint256 _asAt)
        external
        view
        returns (uint256 rewardsEarned, uint256 stakeUnlocked)
    {
        Stakeholder storage stakeholder = _stakeholderMap[_stakeholder];
        for (uint256 i = 0; i < stakeholder.stakes.length; i++) {
            UnpackedStake memory stk = _unpackStake(stakeholder.stakes[i]);
            // if the stake was created after the last rewards claim it should only earn rewards
            // from the time it was created
            uint256 bonusStart =
                Math.max(stakeholder.lastClaimedAt, stk.unlockOn.sub(LOCKUP_PERIOD[stk.period]));
            uint256 bonusEnd = Math.min(_asAt, stk.unlockOn);
            require(bonusEnd >= bonusStart, "StakingPool: invalid bonus period");
            rewardsEarned = rewardsEarned.add(
                stk.amount
                    .mul(BONUS_NUMERATOR[stk.period]).div(BONUS_DENOMINATOR)
                    .mul(annualBaseRewardsRate).div(REWARDS_RATE_PRECISION)
                    .mul(bonusEnd.sub(bonusStart)).div(365 days)
            );

            // after the initial stake lockup period has expired the staked amount should earn
            // rewards at the base rate
            if (_asAt > stk.unlockOn) {
                rewardsEarned = rewardsEarned.add(
                    stk.amount
                        .mul(annualBaseRewardsRate).div(REWARDS_RATE_PRECISION)
                        .mul(_asAt.sub(stk.unlockOn)).div(365 days)
                );
            }

            if (_asAt >= stk.unlockOn) {
                stakeUnlocked = stakeUnlocked.add(stk.amount);
            }
        }

        // the unlocked balance should earn rewards at the base rate
        if (_asAt > stakeholder.lastClaimedAt) {
            rewardsEarned = rewardsEarned.add(
                stakeholder.balance
                    .mul(annualBaseRewardsRate).div(REWARDS_RATE_PRECISION)
                    .mul(_asAt.sub(stakeholder.lastClaimedAt)).div(365 days)
            );
        }
    }

    /**
     * @dev Computes and claims rewards earned by the msg.sender since the last claim time.
     */
    function _claimRewards() private {
        require(_features.rewardsEnabled, "StakingPool: rewards disabled");

        Stakeholder storage stakeholder = _stakeholderMap[msg.sender];
        uint256 rewardsEarned;
        uint256 stakeUnlocked;
        if (stakeholder.stakes.length > 0) {
            // iterate through the stakes back to front, this ensures any swap & pop only shifts
            // stakes that have been iterated through already, so the loop processes every stake
            uint256 lastIdx = stakeholder.stakes.length - 1;
            for (int256 i = int256(lastIdx); i >= 0; i--) {
                uint256 curIdx = uint256(i);
                UnpackedStake memory stk = _unpackStake(stakeholder.stakes[curIdx]);
                // if the stake was created after the last rewards claim it should only earn rewards
                // from the time it was created
                uint256 bonusStart =
                    Math.max(
                        stakeholder.lastClaimedAt,
                        stk.unlockOn.sub(LOCKUP_PERIOD[stk.period])
                    );
                uint256 bonusEnd = Math.min(block.timestamp, stk.unlockOn);
                require(bonusEnd >= bonusStart, "StakingPool: invalid bonus period");
                rewardsEarned = rewardsEarned.add(
                    stk.amount
                        .mul(BONUS_NUMERATOR[stk.period]).div(BONUS_DENOMINATOR)
                        .mul(annualBaseRewardsRate).div(REWARDS_RATE_PRECISION)
                        .mul(bonusEnd.sub(bonusStart)).div(365 days)
                );

                // after the initial stake lockup period has expired the staked amount should earn
                // rewards at the base rate
                if (block.timestamp > stk.unlockOn) {
                    rewardsEarned = rewardsEarned.add(
                        stk.amount
                            .mul(annualBaseRewardsRate).div(REWARDS_RATE_PRECISION)
                            .mul(block.timestamp.sub(stk.unlockOn)).div(365 days)
                    );
                }

                // remove any stake whose original lockup period has expired
                if (block.timestamp >= stk.unlockOn) {
                    stakeUnlocked = stakeUnlocked.add(stk.amount);

                    emit Unstaked(msg.sender, stk.amount, stk.period, stk.unlockOn);

                    // swap & pop
                    if (curIdx < lastIdx) {
                        stakeholder.stakes[curIdx] = stakeholder.stakes[lastIdx];
                    }
                    stakeholder.stakes.pop();
                    lastIdx--;
                }
            }
        }

        // the unlocked balance should earn rewards at the base rate
        uint256 unlockedBalance = stakeholder.balance;
        if (block.timestamp > stakeholder.lastClaimedAt) {
            rewardsEarned = rewardsEarned.add(
                unlockedBalance
                    .mul(annualBaseRewardsRate).div(REWARDS_RATE_PRECISION)
                    .mul(block.timestamp.sub(stakeholder.lastClaimedAt)).div(365 days)
            );
        }

        if (rewardsEarned > 0) {
            unlockedBalance = unlockedBalance.add(rewardsEarned);
            totalStaked = totalStaked.add(rewardsEarned);
            totalRewardsClaimed = totalRewardsClaimed.add(rewardsEarned);

            emit RewardsClaimed(msg.sender, rewardsEarned);
        }

        stakeholder.balance = unlockedBalance.add(stakeUnlocked);
        stakeholder.lastClaimedAt = block.timestamp;
    }

    function _unpackStake(Stake storage _packedStake)
        private
        view
        returns (UnpackedStake memory stk)
    {
        stk.period = _packedStake.period;
        stk.unlockOn = _packedStake.unlockOn;
        stk.amount = uint256(_packedStake.amount).mul(TOKEN_DECIMAL_PRECISION);
    }

    function _addStake(
        Stake[] storage _stakes,
        uint256 _amount,
        uint8 _period
    ) private {
        uint256 unlockOn = block.timestamp.add(LOCKUP_PERIOD[_period]);
        Stake memory stk;
        stk.period = _period;
        stk.unlockOn = unlockOn.toUint64();
        stk.amount = _amount.div(TOKEN_DECIMAL_PRECISION).toUint128(); // discard fractional part
        _stakes.push(stk);

        emit Staked(msg.sender, _amount, _period, unlockOn);
    }

    function _amendStake(
        Stake[] storage _stakes,
        uint256 _amount,
        uint8 _period,
        bool _extend
    ) private {
        Stake storage stk = _findMostRecentStake(_stakes, _period);
        uint256 unlockOn = stk.unlockOn;
        uint256 oldAmount = uint256(stk.amount).mul(TOKEN_DECIMAL_PRECISION);
        uint256 newAmount = oldAmount.add(_amount);

        emit Unstaked(msg.sender, oldAmount, _period, unlockOn);

        stk.amount = newAmount.div(TOKEN_DECIMAL_PRECISION).toUint128();
        if (_extend) {
            unlockOn = block.timestamp.add(LOCKUP_PERIOD[_period]);
            stk.unlockOn = unlockOn.toUint64();
        }

        emit Staked(msg.sender, newAmount, _period, unlockOn);
    }

    function _findMostRecentStake(Stake[] storage _stakes, uint8 _period)
        private
        view
        returns (Stake storage)
    {
        uint64 maxUnlockTime;
        uint256 stakeIdx;
        for (uint256 i = 0; i < _stakes.length; i++) {
            if (
                (_stakes[i].period == _period) &&
                (_stakes[i].unlockOn > block.timestamp) && // ignore expired lockups
                (_stakes[i].unlockOn > maxUnlockTime)
            ) {
                maxUnlockTime = _stakes[i].unlockOn;
                stakeIdx = i + 1;
            }
        }

        require(stakeIdx != 0, "SP: stake not found");
        return _stakes[stakeIdx - 1];
    }

    function batchImportAccounts(
        address[] calldata _stakeholders,
        ExportedAccount[] calldata _accounts
    ) external onlyOwner {
        require(
            _stakeholders.length == _accounts.length,
            "StakingPool: mismatched array lengths on import"
        );
        require(_features.importEnabled, "StakingPool: import not allowed");

        uint256 importedStakeTotal;
        for (uint256 i = 0; i < _stakeholders.length; i++) {
            ExportedAccount calldata account = _accounts[i];
            Stakeholder storage stakeholder = _stakeholderMap[_stakeholders[i]];
            require(
                stakeholder.balance == 0 && stakeholder.stakes.length == 0,
                "StakingPool: account already exists"
            );

            stakeholder.balance = uint256(account.balance).mul(TOKEN_DECIMAL_PRECISION);
            stakeholder.lastClaimedAt = migrationStartTime;

            importedStakeTotal = importedStakeTotal.add(stakeholder.balance);
            for (uint256 j = 0; j < account.stakes.length; j++) {
                Stake memory stk;
                stk.period = account.stakes[j].period;
                stk.unlockOn = account.stakes[j].unlockOn;
                stk.amount = account.stakes[j].amount;
                stakeholder.stakes.push(stk);
                importedStakeTotal = importedStakeTotal.add(
                    uint256(stk.amount).mul(TOKEN_DECIMAL_PRECISION)
                );
            }
        }
        numStakeholders += _stakeholders.length;
        totalStaked = totalStaked.add(importedStakeTotal);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     *
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
     *
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
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}