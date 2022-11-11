pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (staking/StaxRewardsDistributor.sol)

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "../interfaces/staking/IStaxStaking.sol";
import "../interfaces/staking/IStaxInvestmentManager.sol";
import "../interfaces/staking/IStaxRewardsDistributor.sol";

import "../common/access/Operators.sol";
import "../common/CommonEventsAndErrors.sol";

/// @title STAX Rewards Distributor
/// @notice Track and distribute rewards to staking contract on a periodic basis.
/// @dev Operators (eg msig, keepers) will have the right to set manual reward rates.
contract StaxRewardsDistributor is IStaxRewardsDistributor, Ownable, Operators, Pausable {
    using SafeERC20 for IERC20;

    /// @notice The staking contract which will receive new reward distributions
    IStaxStaking public staking;

    /// @notice The upstream investment manager contract responsible for 
    /// distributing harvested rewards, as well as providing accurate claimable amounts which
    /// STAX is due as of 'now'.
    /// All harvestable (ie accrued) upstream rewards are eligable for distribution to
    /// users via the staking contract, even if they haven't actually been harvested from upstream yet.
    IStaxInvestmentManager public investmentManager;

    /// @notice The base reward tokens determined by the upstream investment.
    /// @dev This is effectively immutable. They are pulled from the upstream investment
    /// on construction and cannot be updated later.
    address[] public baseRewardTokens;

    /// @notice The full set of reward tokens that are distributed - from the upstream investment manager
    /// and also any extra reward tokens
    /// @dev The first elements in the list are the baseRewardTokens, and any extras are for manual
    /// reward rate distributions
    address[] public rewardTokens;

    /// @notice The timestamp of the most recent distribution which was made
    uint256 public latestDistributionTime;

    /// @notice Manual reward rates (rewards per second) which will be distributed to the staking contract
    /// These may be supplemental rewards to boost APR for tokens already harvested from the upstream rewards manager
    /// Or separate token addresses.
    mapping(address => uint256) public manualRewardRates;

    /// @notice Track the cumulative rewards per token which were harvested from the upstream 
    /// investment manager
    mapping(address => uint256) public cumulativeRewardsHarvested;

    /// @notice Track the cumulative rewards per token which have already been distributed to the 
    /// downstream staking contract
    mapping(address => uint256) public cumulativeRewardsDistributed;

    /// @notice Any distributions which have been awarded to staking,
    /// but haven't yet been actually paid/transferred to the staking contract.
    /// @dev Effectively an IOU to staking, which is paid the next time rewards are harvested from upstream.
    mapping(uint256 => uint256) public outstandingDistributionAmts;

    /// @dev The distributor can provide an average rate of rewards per second which was actually distributed
    /// over a historic time period. That average is 'reset' to a new start time every `secsUntilRefresh` seconds.
    /// For example, the average rate of rewards over the last 7 full days (plus if we're half way through today)
    ///    secsUntilRefresh = 1 day
    ///    numAveragePeriods = 8  (7 full days + a partially complete period for today)
    ///
    /// The average rate calculation is the total distributions over the period
    /// (actually paid up to the last distribution and also pending from the last distribution until 'now')
    /// over the the duration over the last `numAveragePeriods`.
    struct AverageDistributionConfig {
        uint128 secsUntilRefresh;
        uint128 numAveragePeriods; 
    }
    AverageDistributionConfig public averageDistributionConfig;

    struct AverageDistributionData {
        /// @dev The unix time for when we expect this average period to end.
        /// Note It will only actually end the next time that distribute() is called
        /// and where block.timestamp is greater than this target end time.
        /// At which point the *new* targetEndTime will be block.timestamp + averageDistributionConfig.secsUntilRefresh
        uint128 targetEndTime;

        /// @dev The index of the average periods which is being used for the currently accruing rewards.
        /// Note: The index starts from 1 (not 0), and when incremented above `numAveragePeriod` it wraps
        /// (modulo) back to 1.
        /// This is so we can re-use the same slots in the below maps.
        uint128 currentlyAccruingIndex;

        /// @dev For each token that we have distributed rewards,
        /// track the total distributions for each of the `numAveragePeriods`
        /// token address => (averagePeriodIndex => amount)
        mapping(address => mapping(uint256 => uint256)) cumulativeAmountsPerToken;

        /// @dev For each of the `numAveragePeriods` track the start time of that period
        /// such that when we roll into a new period we can update the start
        /// time of the overall averaging time. (eg the full 7 days + up to `now` intraday)
        mapping(uint256 => uint256) startTimes;
    }
    AverageDistributionData public averageDistributionData;

    event RewardsDistributed(address indexed staking, uint256[] distributionAmounts, bool newAveragePeriod);
    event RewardsHarvested(address indexed investmentManager, uint256[] amounts);
    
    event RewardTokenAdded(address indexed token);
    event RewardTokenRemoved(address indexed token);
    event StakingSet(address indexed staking);
    event InvestmentManagerSet(address indexed investmentManager);
    event ManualRewardRatesSet(address indexed token, uint256 rate);
    event HarvestRateLimitSecsSet(uint256 secs);

    error MismatchedTokens();
    error OnlyStaking(address caller);
    error RewardTokenStillActive(address rewardToken);
    error RewardTokenAlreadyExists(address rewardToken);

    /// @param _investmentManager The upstream investment manager which we harvest rewards from, using a standard contract interface.
    /// @param _secsUntilAverageRefresh The number of seconds that is targeted to refresh the historic average calcs, eg daily
    /// @param _historicAverageDuration The time horizon that we are averaging over, eg 7 days
    /// @dev The number of average periods created will be `(_historicAverageDuration/_secsUntilAverageRefresh)+1`
    /// Such that we also have a bucket for the currently accruing (not yet complete) period.
    constructor(address _investmentManager, uint256 _secsUntilAverageRefresh, uint256 _historicAverageDuration) {
        investmentManager = IStaxInvestmentManager(_investmentManager);

        // Fill the rewardTokens from whatever we expect from the upstream investment manager.
        baseRewardTokens = investmentManager.rewardTokensList();
        for (; rewardTokens.length < baseRewardTokens.length;) {
            rewardTokens.push(baseRewardTokens[rewardTokens.length]);
        }

        // Need to be an exact multiple to get even contiguous average periods
        // eg refresh every 1 days, average over 7 days: ok  (7*86400 % 1*86400 = 0)
        // eg refresh every hour, average over 1 days: ok  (1*86400 % 1*60*60 = 0)
        // eg refresh every 2 days, average over 7 days: bad  (7*86400 % 2%86400 != 0)
        // eg refresh every 14 days, average over 7 days: bad  (7*86400 % 14%86400 != 0)
        if (_secsUntilAverageRefresh == 0 || _historicAverageDuration % _secsUntilAverageRefresh > 0) {
            revert CommonEventsAndErrors.InvalidParam();
        }

        // Add an average period for the 'currently accruing' period.
        // So num periods = (historicWindowDuration / historicWindowFrequency) + 1
        averageDistributionConfig = AverageDistributionConfig({
            secsUntilRefresh: uint128(_secsUntilAverageRefresh),
            numAveragePeriods: uint128(_historicAverageDuration / _secsUntilAverageRefresh) + 1
        });
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function addOperator(address _address) external override onlyOwner {
        _addOperator(_address);
    }

    function removeOperator(address _address) external override onlyOwner {
        _removeOperator(_address);
    }

    /// @notice Set the staking contract, which has permissions to distribute rewards.
    function setStaking(address _staking) external onlyOwner {
        staking = IStaxStaking(_staking);
        emit StakingSet(_staking);
    }

    /// @notice Set the upstream investment manager contract - where the upstream rewards are distributed from.
    function setInvestmentManager(address _investmentManager) external onlyOwner {
        investmentManager = IStaxInvestmentManager(_investmentManager);
        emit InvestmentManagerSet(_investmentManager);
    }
    
    /// @notice Add an extra reward token, to be used for future rewards.
    /// @dev No rewards for this token will be distributed until manual reward rates are set.
    function addExtraRewardToken(address _rewardToken) external onlyOwner {
        // Check this new token isn't already existing.
        for (uint256 i; i<rewardTokens.length; ++i) {
            if (rewardTokens[i] == _rewardToken) revert RewardTokenAlreadyExists(_rewardToken);
        }

        rewardTokens.push(_rewardToken);
        emit RewardTokenAdded(_rewardToken);
    }

    /// @notice Remove an extra reward token. 
    /// Not strictly required to be called, as the reward rate can just be set to 0 and no new
    /// rewards will be distributed.
    /// However over time gas can be saved because of less iterations over reward tokens.
    function removeExtraRewardToken(address _rewardToken) external onlyOwner {
        // Can't remove if this token still has pending rewards
        if (manualRewardRates[_rewardToken] > 0) revert RewardTokenStillActive(_rewardToken);

        for (uint256 index; index < rewardTokens.length; ++index) {
            if (rewardTokens[index] == _rewardToken) {
                // Can't remove a base reward token.
                if (index < baseRewardTokens.length) {
                    revert RewardTokenStillActive(_rewardToken);
                }

                // Switch the one to to delete with the end one
                // Then pop it off the list
                // So this changes the order of rewardTokens, but that's inconsequential.
                if (index < rewardTokens.length-1) {
                    rewardTokens[index] = rewardTokens[rewardTokens.length-1];
                }
                rewardTokens.pop();
                emit RewardTokenRemoved(_rewardToken);
                return;
            }
        }
    }

    /// @notice Set the manual reward rate for a given extra token.
    /// @dev Ensure there is enough funding for the reward token before setting the rate
    function setManualRewardRates(address _rewardToken, uint256 _rate) external onlyOperators {
        // Update rewards a final time to ensure staking has the latest distribution, before updating the rates.
        staking.updateRewards(address(0), false);
        manualRewardRates[_rewardToken] = _rate;
        emit ManualRewardRatesSet(_rewardToken, _rate);
    }

    /// @notice The list of all base reward tokens from the upstream investment manager
    /// and any extra manual reward tokens.
    function allRewardTokens() external view override returns (address[] memory) {
        return rewardTokens;
    }

    /// @notice A particular distribution period's cumulative amount
    function averageDistributionAmounts(address _tokenAddr, uint256 _index) external view returns (uint256) {
        return averageDistributionData.cumulativeAmountsPerToken[_tokenAddr][_index];
    }

    /// @notice A particular distribution period's unix start time
    function averageDistributionStartTimes(uint256 _index) external view returns (uint256) {
        return averageDistributionData.startTimes[_index];
    }

    /// @notice The current averaging start time used when calculating the latestActualRewardRates()
    function averagingStartTime() public view returns (uint256) {
        // We start averaging from the period after the current one because we've wrapped around (modulo)
        return averageDistributionData.startTimes[(averageDistributionData.currentlyAccruingIndex % averageDistributionConfig.numAveragePeriods) + 1];
    }

    /// @notice The projected reward rates 'as of now', driven from the upstream investment manager.
    /// These may fluctuate block-to-block as external events happen
    /// (eg they change emissions, STAX's dilution of upstream rewards change, etc)
    /// @dev The reward rate represents STAX's total rewards per second across all of it's stakers.
    function projectedRewardRates() external view override returns (uint256[] memory amounts) {
        amounts = new uint256[](rewardTokens.length);

        // First pull the upstream investment manager projected reward rates
        uint256[] memory investmentManagerRewardRates = investmentManager.projectedRewardRates();
        if (investmentManagerRewardRates.length != baseRewardTokens.length) revert MismatchedTokens();

        // Add on any extra manual reward rates.
        // This may be a boost to existing rewards, or for an extra token.
        for (uint256 i; i < rewardTokens.length; ++i) {
            amounts[i] += (i < investmentManagerRewardRates.length)
                ? investmentManagerRewardRates[i] + manualRewardRates[rewardTokens[i]]
                : manualRewardRates[rewardTokens[i]];
        }
    }

    /// @notice The average reward rate for the distributions over the last `numAveragePeriods` + anything
    /// accrued upstream but not yet distributed.
    function latestActualRewardRates() external override view returns (uint256[] memory amounts) {
        amounts = new uint256[](rewardTokens.length);

        // Use the next window's start time as the start of total accrual
        uint256 _averagingStartTime = averageDistributionData.startTimes[(averageDistributionData.currentlyAccruingIndex % averageDistributionConfig.numAveragePeriods) + 1];
        uint256 timeDelta = block.timestamp - _averagingStartTime;
        if (timeDelta == 0 || _averagingStartTime == 0) {
            return amounts;
        }

        // Pull any accrued rewards up to now. This includes upstream investment rewards + any accrued manual rewards.
        (uint256[] memory accruedRewards, ) = _pendingRewards();

        address tokenAddr;
        uint256 amt;
        for (uint256 i; i < rewardTokens.length; ++i) {
            tokenAddr = rewardTokens[i];
            amt = accruedRewards[i];

            // Index starts at 1 for the average periods
            for (uint256 j=1; j <= averageDistributionConfig.numAveragePeriods; ++j) {
                amt += averageDistributionData.cumulativeAmountsPerToken[tokenAddr][j];
            }
            amounts[i] = amt / timeDelta;
        }
    }

    /// @notice What are the total accrued rewards 'as of now' ready to be distributed.
    /// This includes both the upstream rewards plus any manual reward rates which have accrued up to now.
    function pendingRewards() public view override returns (uint256[] memory amounts) {
        (amounts, ) = _pendingRewards();
    }

    /// @dev What are the current pending/claimable rewards up to this block, from the last distribution.
    function _pendingRewards() internal view returns (
        uint256[] memory totalPendingAmounts, 
        uint256[] memory manualPendingAmounts
    ) {
        totalPendingAmounts = new uint256[](rewardTokens.length);
        manualPendingAmounts = new uint256[](rewardTokens.length);

        if (latestDistributionTime == 0 || block.timestamp == latestDistributionTime) {
            return (totalPendingAmounts, manualPendingAmounts);
        }
        
        // Current claimable amount from the upstream investment manager (accrued between when we last harvested and now)
        uint256[] memory harvestableRewards = investmentManager.harvestableRewards();
        if (harvestableRewards.length != baseRewardTokens.length) revert MismatchedTokens();

        uint256 timeDelta = block.timestamp - latestDistributionTime;
        address tokenAddr;
        uint256 manualReward;
        uint256 totalHarvestableReward;
        unchecked {
            for (uint256 idx; idx < rewardTokens.length; ++idx) {
                tokenAddr = rewardTokens[idx];

                // Any manual reward amounts from the last distribution until now.
                manualReward = manualRewardRates[tokenAddr] * timeDelta;
                manualPendingAmounts[idx] = manualReward;

                // If this token is a base token, then it's both what we can harvest from upstream
                // otherwise just the manual amount
                totalHarvestableReward = (idx < baseRewardTokens.length) 
                    ? harvestableRewards[idx] + manualReward
                    : manualReward;

                // pending rewards
                //   == (total cumulative upstream rewards) - (total cumulative rewards distributed)
                //   == (cumulativeRewardsHarvested + harvestableReward + manualReward) - (cumulativeRewardsDistributed)                
                totalPendingAmounts[idx] = (
                    cumulativeRewardsHarvested[tokenAddr] +
                    totalHarvestableReward -
                    cumulativeRewardsDistributed[tokenAddr]
                );
            }
        }
    }

    /// @notice Distribute any pending rewards to the staking contract.
    /// If this distributor doesn't have enough tokens in the contract for that amount, this transfer
    /// will fail - it will need topping up.
    /// A topup can happen either by harvesting from the upstream investment manager, or 
    /// by token transfer to this contract.
    function distribute(bool forceHarvest) external override whenNotPaused returns (
        uint256[] memory distributionAmounts, bool rewardsHarvested
    )  {
        if (msg.sender != address(staking)) revert OnlyStaking(msg.sender);

        // Staking can force a harvest to occur
        if (forceHarvest) {
            rewardsHarvested = true;
            harvestRewards(false);
        }

        // Get the pending amounts to be distributed.
        uint256[] memory manualPendingAmounts;
        (distributionAmounts, manualPendingAmounts) = _pendingRewards();
        latestDistributionTime = block.timestamp;
        uint128 windowIndexToAddInto = averageDistributionData.currentlyAccruingIndex;

        // Update the window if this crosses into the next period.
        bool newAveragePeriod;
        if (block.timestamp > averageDistributionData.targetEndTime) {
            // At startup initialize the start times on all 
            // The very first time we distribute, we need to set the period start times
            if (averageDistributionData.targetEndTime == 0) {
                for (uint256 i=1; i<=averageDistributionConfig.numAveragePeriods; ++i) {
                    averageDistributionData.startTimes[i] = block.timestamp;
                }
            }

            averageDistributionData.currentlyAccruingIndex = (windowIndexToAddInto % averageDistributionConfig.numAveragePeriods) + 1;
            
            // The next window's target end time is based off 'block.timestamp', so 
            // if we don't distribute at exactly the same frequency each time (eg keeper's delay / tx fail, etc)
            // then the actual window length may be larger than the ideal window length.
            averageDistributionData.targetEndTime = uint128(block.timestamp) + averageDistributionConfig.secsUntilRefresh;
            averageDistributionData.startTimes[averageDistributionData.currentlyAccruingIndex] = block.timestamp;
            newAveragePeriod = true;
        }

        // Update the cumulative distribution state.
        address tokenAddr;
        unchecked { 
            for (uint256 i; i < rewardTokens.length; ++i) {
                if (distributionAmounts[i] > 0) {
                    tokenAddr = rewardTokens[i];

                    // Add to the total rewards distributed.
                    cumulativeRewardsDistributed[tokenAddr] += distributionAmounts[i];

                    // Since manual rewards aren't explicitly harvested as a separate step
                    // We add into the cumulativeRewardsHarvested when they're distributed.
                    if (manualPendingAmounts[i] > 0) {
                        cumulativeRewardsHarvested[tokenAddr] += manualPendingAmounts[i];
                    }

                    // Add into the current window's cumulative amount.
                    averageDistributionData.cumulativeAmountsPerToken[tokenAddr][windowIndexToAddInto] += distributionAmounts[i];

                    // Clear out the next window
                    if (newAveragePeriod) {
                        averageDistributionData.cumulativeAmountsPerToken[tokenAddr][averageDistributionData.currentlyAccruingIndex] = 0;
                    }

                    outstandingDistributionAmts[i] += distributionAmounts[i];
                }
            }
        }

        // Transfer the outstanding distribution amounts to staking
        transferOutstandingDistributions();
        emit RewardsDistributed(address(staking), distributionAmounts, newAveragePeriod);
    }

    /// @notice Transfer any outstanding balances which are have been deemed distributed, to the staking contract.
    /// @dev For each reward token, transfers the max(token.balanceOf(this), oustandingDistribution) to staking
    function transferOutstandingDistributions() public whenNotPaused {
        uint256 balance;
        uint256 transferAmt;
        for (uint256 i; i < rewardTokens.length; ++i) {
            if (outstandingDistributionAmts[i] > 0) {
                // Transfer the max(balance, oustanding) to staking
                balance = IERC20(rewardTokens[i]).balanceOf(address(this));
                transferAmt = outstandingDistributionAmts[i] > balance ? balance : outstandingDistributionAmts[i];

                if (transferAmt > 0) {
                    outstandingDistributionAmts[i] -= transferAmt;
                    IERC20(rewardTokens[i]).safeTransfer(address(staking), transferAmt);
                }
            }
        }
    }

    /// @notice Harvest any upstream rewards from the upstream investment manager.
    function harvestRewards(bool _transferOutstandingDistributions) public whenNotPaused {
        uint256[] memory upstreamRewardAmounts = investmentManager.harvestRewards();
        if (upstreamRewardAmounts.length != baseRewardTokens.length) revert MismatchedTokens();

        // Update the cumulative rewards harvested for any upstream investment manager rewards.
        unchecked { 
            for (uint256 i; i < baseRewardTokens.length; ++i) {
                cumulativeRewardsHarvested[baseRewardTokens[i]] += upstreamRewardAmounts[i];
            }
        }

        if (_transferOutstandingDistributions) {
            transferOutstandingDistributions();
        }

        emit RewardsHarvested(address(investmentManager), upstreamRewardAmounts);
    }

    /// @notice Owner can recover non-reward tokens
    function recoverToken(address _token, address _to, uint256 _amount) external onlyOwner {
        for (uint256 i; i < rewardTokens.length; i++) {
            if (_token == rewardTokens[i]) revert CommonEventsAndErrors.InvalidToken(_token);
        }
        IERC20(_token).safeTransfer(_to, _amount);
        emit CommonEventsAndErrors.TokenRecovered(_to, _token, _amount);
    }
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (common/CommonEventsAndErrors.sol)

/// @notice A collection of common errors thrown within the STAX contracts
library CommonEventsAndErrors {
    error InsufficientBalance(address token, uint256 required, uint256 balance);
    error InvalidToken(address token);
    error InvalidParam();
    error InvalidAddress(address addr);
    error OnlyOwner(address caller);
    error OnlyOwnerOrOperators(address caller);
    error InvalidAmount(address token, uint256 amount);
    error ExpectedNonZero();

    event TokenRecovered(address indexed to, address indexed token, uint256 amount);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/staking/IStaxStaking.sol)

import "./IStaxRewardsDistributor.sol";

interface IStaxStaking {
    function stakeFor(address _for, uint256 _amount) external;
    function updateRewards(address _addr, bool _forceHarvest) external returns (bool rewardsHarvested);
    function distributor() external view returns (IStaxRewardsDistributor);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/staking/IStaxInvestmentManager.sol)

interface IStaxInvestmentManager {
    function rewardTokensList() external view returns (address[] memory tokens);
    function harvestRewards() external returns (uint256[] memory amounts);
    function harvestableRewards() external view returns (uint256[] memory amounts);
    function projectedRewardRates() external view returns (uint256[] memory amounts);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (common/access/Operators.sol)

/// @notice Inherit to add an Operator role which multiple addreses can be granted.
/// @dev Derived classes to implement addOperator() and removeOperator()
abstract contract Operators {
    /// @notice A set of addresses which are approved to run operations.
    mapping(address => bool) public operators;

    event AddedOperator(address indexed account);
    event RemovedOperator(address indexed account);

    error OnlyOperators(address caller);

    function _addOperator(address _account) internal {
        operators[_account] = true;
        emit AddedOperator(_account);
    }

    /// @notice Grant `_account` the operator role
    /// @dev Derived classes to implement and add protection on who can call
    function addOperator(address _account) external virtual;

    function _removeOperator(address _account) internal {
        delete operators[_account];
        emit RemovedOperator(_account);
    }

    /// @notice Revoke the operator role from `_account`
    /// @dev Derived classes to implement and add protection on who can call
    function removeOperator(address _account) external virtual;

    modifier onlyOperators() {
        if (!operators[msg.sender]) revert OnlyOperators(msg.sender);
        _;
    }
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/staking/IStaxRewardsDistributor.sol)

interface IStaxRewardsDistributor {
    function allRewardTokens() external view returns (address[] memory);
    function harvestRewards(bool _transferOutstandingDistributions) external;
    function pendingRewards() external view returns (uint256[] memory pendingAmounts);
    function distribute(bool forceHarvest) external returns (
        uint256[] memory distributedAmounts, 
        bool rewardsHarvested
    );
    function projectedRewardRates() external view returns (uint256[] memory amounts);
    function latestActualRewardRates() external view returns (uint256[] memory amounts);
    function setStaking(address _staking) external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
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

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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