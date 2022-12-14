// SPDX-License-Identifier: MIT
// Creator: andreitoma8
pragma solidity ^0.8.4;

import "SafeCast.sol";
import "SignedMath.sol";
import "SignedSafeMath.sol";
import "ERC20.sol";
import "ERC20Burnable.sol";
import "ReentrancyGuard.sol";
import "IERC20Metadata.sol";

contract FluidCoin is ERC20, ERC20Burnable, ReentrancyGuard {
    // Staker info
    struct Staker {
        // The staked tokens of the Staker
        uint256 staked;
        // Last time of details update for Deposit
        uint256 timeOfLastUpdate;
        uint256 timeOfLastDeposit;
        // Calculated, but unclaimed rewards. These are calculated each time
        // a user writes to the contract.
        int256 unclaimedRewards;
    }

    // Define break even point in seconds between the time where a
    // positive/negative rate is used
    uint256 public breakEven = 3*24*3600; // three days

    // Define negative and positive rewards as percent per year
    int256 public annualRateNegative = 1;
    int256 public annualRatePositive = 5;

    // Minimum amount to stake
    uint256 public cubmtsWaterOnEarth = 14 * 10**8;
    uint256 public minStake = 1 * 10**decimals();

    // Compounding frequency limit in seconds
    uint256 public compoundFreq = 14400;  // 4 hours

    // Mapping of address to Staker info
    mapping(address => Staker) internal stakers;

    // Constructor function
    constructor()
        ERC20("FluidCoin", "flc") {
        // Mint initial amount of FLC tokens
        _mint(msg.sender, cubmtsWaterOnEarth * 10**decimals());
    }

    // If address has no Staker struct, initiate one. If address already was a stake,
    // calculate the rewards and add them to unclaimedRewards, reset the last time of
    // deposit and then add _amount to the already staked amount.
    // Burns the amount staked.
    function stake(uint256 _amount) external nonReentrant {
        require(
            _amount >= minStake,
            "Amount smaller than minimimum stake"
        );
        require(
            balanceOf(msg.sender) >= _amount,
            "Can't stake more than you own"
        );
        // If nothing is staked currently
        if (stakers[msg.sender].staked == 0) {
            stakers[msg.sender].staked = _amount;
            stakers[msg.sender].timeOfLastUpdate = block.timestamp;
            stakers[msg.sender].timeOfLastDeposit = block.timestamp;
            stakers[msg.sender].unclaimedRewards = 0;
        // If something is already staked, add rewards to unclaimed rewards
        } else {
            int256 rewards = calculateRewards(msg.sender);
            stakers[msg.sender].staked += _amount;
            stakers[msg.sender].timeOfLastUpdate = block.timestamp;
            stakers[msg.sender].timeOfLastDeposit = block.timestamp;
            stakers[msg.sender].unclaimedRewards += rewards;
        }
        // Burn staked amount from balance
        _burn(msg.sender, _amount);
    }

    // Compound the rewards and reset the last time of update for stake info
    function stakeRewards() external nonReentrant {
        require(
            stakers[msg.sender].staked > 0,
            "You have no deposit"
        );
        require(
            compoundRewardsTimer(msg.sender) == 0,
            "Tried to compound rewards too soon"
        );
        int256 rewards = calculateRewards(msg.sender) + stakers[msg.sender].unclaimedRewards;
        stakers[msg.sender].unclaimedRewards = 0;
        stakers[msg.sender].staked = safeAdd(stakers[msg.sender].staked, rewards);
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        stakers[msg.sender].timeOfLastDeposit = block.timestamp;
    }

    // Mints rewards for msg.sender
    function claimRewards() external nonReentrant {
        int256 rewards = calculateRewards(msg.sender) + stakers[msg.sender].unclaimedRewards;
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;

        uint256 absRewards = SignedMath.abs(rewards);

        // If reward is positive, just mint
        if(rewards > 0) {
            _mint(msg.sender, absRewards);
        // If reward is negative, reduce deposited stake amount (if necessary)
        // and burn from balance 
        } else {
            uint256 balance = balanceOf(msg.sender);
            // If balance is not sufficient, mint remaining part to avoid an error while burning
            if(balance < absRewards) {
                uint256 mintAmount = absRewards - balance;
                _mint(msg.sender, mintAmount);

                // If staked amount is NOT sufficient to compensate negative rewards,
                // just set it to zero
                if(mintAmount > stakers[msg.sender].staked) {
                    stakers[msg.sender].staked = 0;
                // If staked amount is sufficient to compensate negative rewards,
                //remove it from staked amount
                } else {
                    stakers[msg.sender].staked -= mintAmount;
                }
            }
            _burn(msg.sender, absRewards);
        }
        stakers[msg.sender].unclaimedRewards = 0;
    }

    // Unstake specified amount of staked tokens and mint them to the msg.sender
    // NOTE The function only adds rewards to unclaimed rewards and is not actually
    //      claiming rewards. 'claim' needs to be called in addition to 'unstake'.
    function unstake(uint256 _amount) public nonReentrant {
        require(
            stakers[msg.sender].staked >= _amount,
            "Can't unstake more than you have"
        );
        stakers[msg.sender].unclaimedRewards += calculateRewards(msg.sender);
        stakers[msg.sender].staked -= _amount;
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        _mint(msg.sender, _amount);
    }

    // Unstake whole deposited stake and rewards
    function unstakeAll() external {
        uint256 _amount = stakers[msg.sender].staked;
        unstake(_amount);
    }

    // Function useful for front-end that returns user stake and rewards by address
    function getStakeInfo(address _user)
        public
        view
        returns (uint256 _stake, int256 _rewards)
    {
        _stake = stakers[_user].staked;
        _rewards = calculateRewards(_user) + stakers[msg.sender].unclaimedRewards;
        return (_stake, _rewards);
    }

    // Utility function that returns the timer for restaking rewards
    function compoundRewardsTimer(address _user)
        public
        view
        returns (uint256 _timer)
    {
        if (stakers[_user].timeOfLastUpdate + compoundFreq <= block.timestamp) {
            return 0;
        } else {
            return
                (stakers[_user].timeOfLastUpdate + compoundFreq) -
                block.timestamp;
        }
    }

    // Calculate the rewards since the last update
    function calculateRewards(address _staker)
        internal
        view
        returns (int256 rewards)
    {
        // Name used variables
        uint256 claimTimestamp = block.timestamp;
        // NOTE: It is assumed that we claim at the time of calling the function, although this might not necessarily be the case,
        // e.g. when called by getStakeInfo(). The term claim is used here as this refers to the models and documentation.
        uint256 lastUpdateTimestamp = stakers[_staker].timeOfLastUpdate;
        uint256 stakedTimestemp = stakers[_staker].timeOfLastDeposit;
        uint256 stakedAmount = stakers[_staker].staked;

        // Compute helper variables
        uint256 breakEvenTimestemp = stakedTimestemp + breakEven;
        int256 distLastUpdateBreakEven = SafeCast.toInt256(breakEvenTimestemp) - SafeCast.toInt256(lastUpdateTimestamp);
        int256 distClaimBreakEven = SafeCast.toInt256(breakEvenTimestemp) - SafeCast.toInt256(claimTimestamp);

        // Calculate times where positive and/or negative rates are applied
        int256 timePositiveRate = 0;
        int256 timeNegativeRate = 0;
        // If lastUpdate and now are both before breakEven, only apply positive rate
        if (distLastUpdateBreakEven > 0 && distClaimBreakEven >= 0) {
            timePositiveRate = SafeCast.toInt256(claimTimestamp) - SafeCast.toInt256(lastUpdateTimestamp);
        // If lastUpdate and now are both after breakEven, only apply negative rate
        } else if (distLastUpdateBreakEven <= 0 && distClaimBreakEven < 0) {
            timeNegativeRate = SafeCast.toInt256(claimTimestamp) - SafeCast.toInt256(lastUpdateTimestamp);
        // If lastUpdate is before breakEven and now is after breakEven, apply both rates
        } else if (distLastUpdateBreakEven > 0 && distClaimBreakEven < 0) {
            timePositiveRate = SafeCast.toInt256(breakEvenTimestemp) - SafeCast.toInt256(lastUpdateTimestamp);
            timeNegativeRate = SafeCast.toInt256(claimTimestamp) - SafeCast.toInt256(breakEvenTimestemp);
        // If last update, break even and claim are at the same timestep
        } else if (distLastUpdateBreakEven == 0 && distClaimBreakEven == 0) {
            // It's a valid case, but nothing to do, just keep zeros
        // In all other cases, something was illocial and we need to stop the transaction
        } else {
            require(
                false,
                "Invalid state: reward calculation not possible."
            );
        }

        // Calculate earnings and losses
        // timePositiveRate/3600 equals an hourly positive rate
        // annualRatePositive/100/365/24 equals an hourly percentage
        // Devide everything by: 3600*100*365*24 = 3153600000
        int256 earnings = SafeCast.toInt256(stakedAmount) * timePositiveRate * annualRatePositive / 3153600000;
        int256 losses = SafeCast.toInt256(stakedAmount) * timeNegativeRate * annualRateNegative / 3153600000;

        // Return final reward (NOTE this may be negative)
        return earnings - losses;
    }

    function safeAdd(uint256 a, int256 b) private pure returns (uint256 result) {
        uint256 absB = SignedMath.abs(b);
        if(b > 0) {
            return a + absB;
        } else if(absB > a) {
            return 0;
        } else {
            return a - absB;
        }
    }
}