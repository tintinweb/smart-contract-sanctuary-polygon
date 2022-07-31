//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import {Constants} from "./Constants.sol";
import {AggregatedBalanceLib} from "./AggregatedBalanceLib.sol";
import {StakeholderLib} from "./StakeholderLib.sol";
import {RewardPeriodLib} from "./RewardPeriodLib.sol";

/**
 * @title A staking contract for Goka tokens
 * @author Kasper De Blieck ([email protected])
 * This contract allows Goka token owners to stake their funds.
 * Staking funds will be periodically rewarded.
 */
contract GokaStaking is Ownable {

    using SafeMath for uint;
    using StakeholderLib for StakeholderLib.Stakeholder;
    using RewardPeriodLib for RewardPeriodLib.RewardPeriod[];
    using AggregatedBalanceLib for AggregatedBalanceLib.AggregatedBalance[];

    /**
    Emits when a config field is updated
    @param field_ of the field
    @param value_ new value of the field
     */
    event ConfigUpdate(string field_, uint value_);
    /**
    Emits when new address stakes
    @param stakeholder_ address of the stakeholder
    @param stake_ new amount of staked tokens
     */
    event Staking(address indexed stakeholder_, uint stake_);
    /**
    Emits when stakeholder claims rewards
    @param stakeholder_ address of the stakeholder
    @param reward_ reward claimed
    @param numberOfPeriods_ number of periods rewarded
     */
    event Rewarding(address indexed stakeholder_, uint reward_, uint numberOfPeriods_);
    /**
     Emits when a stakeholder requested a withdrawal
     @param stakeholder_ address of the stakeholder
     @param amount_ amount of tokens withdrawn from the contract
     @param releaseDate_ timestamp when cooldown is over for the user
     @param id_ the technical ID of the withdrawal, to be used in the withdraw function
     */
    event InitiateWithdraw(address stakeholder_, uint amount_, uint releaseDate_, uint id_);
    /**
     Emits when a stakeholder finalizes a withdrawal
     @param stakeholder_ address of the stakeholder
     @param amount_ amount of tokens sent to the stakeholder
     @param fee_ fee paid for early withdrawal
     @param id_ the technical ID of the withdrawal, to be used in the withdraw function
     */
    event Withdraw(address stakeholder_, uint amount_, uint fee_, uint id_);
    /**
     Emits when a new staker enters the contract by staking or existing stakeholder leaves by withdrawing
     @param stakeholder_ address of the stakeholder
     @param active_ yes if the staker becomes active, false if inactive
     */
    event Active(address stakeholder_, bool active_);

    // Keeps track of user information by mapping the stakeholder address to his state
    mapping(address => StakeholderLib.Stakeholder) public stakeholders;

    // Keeps track of the different reward intervals, sequentially
    RewardPeriodLib.RewardPeriod[] public rewardPeriods;

    // Keep track of the aggregated balances in the contract, index equals weight
    AggregatedBalanceLib.AggregatedBalance[] public aggregatedBalances;

    // Address used to verify users updating weight
    address public signatureAddress;

    IERC20 public stakingToken;

    uint public startDate; // Used to calculate how many periods have passed
    uint public maxNumberOfPeriods; // Used to cap the end date in the reward calculation
    uint public cooldown; // Length between withdrawal request and withdrawal without fee is possible
    uint public earlyWithdrawalFee; // Fee penalising early withdrawal, percentage times Constants.decimalPrecision
    uint public currentExtraRewardMultiplier;
    /**
     Sets a number of initial state variables
     */
    constructor(
                uint maxNumberOfPeriods_, // Used to cap the end date in the reward calculation
                uint extraRewardMultiplier_,
                uint cooldown_,
                uint earlyWithdrawalFee_,
                address signatureAddress_,
                address stakingTokenAddress) {

        // Set global variables
        maxNumberOfPeriods = maxNumberOfPeriods_;
        cooldown = cooldown_;
        earlyWithdrawalFee = earlyWithdrawalFee_;
        signatureAddress = signatureAddress_;

        stakingToken = IERC20(stakingTokenAddress);
        startDate = block.timestamp;

        // Initialise the first reward period in the sequence
        currentExtraRewardMultiplier = extraRewardMultiplier_;
        rewardPeriods.addNewPeriod(extraRewardMultiplier_, 0);

        // Initialize aggregatedBalances
        AggregatedBalanceLib.AggregatedBalance memory newBalance;
        aggregatedBalances.push(newBalance);
    }

    function maxWeight() public view returns(uint){return aggregatedBalances.length > 0 ? aggregatedBalances.length - 1 : 0;}
    function latestRewardPeriod() public view returns(uint){return rewardPeriods.length - 1;}
    function rewardPeriodDuration() public pure returns(uint){return Constants.rewardPeriodDuration;}
    function periodsForExtraReward() public pure returns(uint){return Constants.periodsForExtraReward;}

    /**
     * Function to call when a new reward period is entered.
     * The function will increment the maxRewardPeriod field,
     * making the state of previous period immutable.
     * The state will use the state of the last period as start for the current period.
     * The total staking balance is updated with:
     * - stake added in previous period
     * - rewards earned in previous period
     * - locked tokens, if they are unlocked.
     * @param endPeriod the last period the function should handle.
     *  cannot exceed the current period.
     */
    function handleNewPeriod(uint endPeriod) public {
        // Don't update passed current period
        if(currentPeriod() < endPeriod ){
            endPeriod = currentPeriod();
        }
        // Close previous periods if in the past and create a new one
        while(latestRewardPeriod() < endPeriod ){

            rewardPeriods[latestRewardPeriod()].rewardPerPeriod = calculateRewardPerPeriod();

            aggregatedBalances.updateBalances(
                rewardPeriods[latestRewardPeriod()].rewardPerPeriod,
                rewardPeriods[latestRewardPeriod()].extraRewardMultiplier,
                (((latestRewardPeriod()) % Constants.periodsForExtraReward == 0)
                || (latestRewardPeriod()) == maxNumberOfPeriods));

            uint totalWeightedStake = aggregatedBalances.calculateTotalWeightedStake(1);

            rewardPeriods.addNewPeriod(
                currentExtraRewardMultiplier,
                totalWeightedStake); 
        }
    }

    /** Calculate reward for previous period when balance is known
    If no stakingbalance is present, rewardPerPeriod will stay 0
    @return rewardPerPeriod the reward per period based on current token balans
    */
    function calculateRewardPerPeriod() public view returns(uint rewardPerPeriod){

        uint totalStaked = aggregatedBalances.sumOfAllBalances();
        uint balance = stakingToken.balanceOf(address(this));

        if((aggregatedBalances.calculateTotalWeightedStake(0) > 0)
            && balance > totalStaked){
            rewardPerPeriod = (balance - totalStaked)
                * Constants.decimalPrecision
                / ((maxNumberOfPeriods - latestRewardPeriod())
                    * (rewardPeriods[latestRewardPeriod()].extraRewardMultiplier
                        + Constants.decimalPrecision));
        } else {
            rewardPerPeriod = 0;
        }

        
    }

    /**
     * Increase the stake of the sender by a value.
     * @param weight_ The new weight.
     * @param signature A signature proving the sender
     *  is allowed to update his weight.
     */
    function increaseWeight(uint weight_, bytes memory signature) public{
        // Close previous period if in the past and create a new one, else update the latest one.
        handleNewPeriod(currentPeriod());

        address sender = _msgSender();

        // Verify the stakeholder was allowed to update stake
        require(signatureAddress == _recoverSigner(sender, weight_, signature),
            "Invalid sig");

        StakeholderLib.Stakeholder storage stakeholder = stakeholders[sender];
        require(weight_ > stakeholder.weight, "No weight increase");

        // Update balance distributions with new weight
        if(stakeholder.isActive()){

            handleNewPeriod(currentPeriod());
            // Update the total weighted amounts.
            aggregatedBalances.moveToDifferentWeight(
                stakeholder.weight,
                weight_,
                stakeholder.stakingBalance,
                stakeholder.newStake,
                stakeholder.lockedRewards
            );
        }

        // Finally, set the new weight
        stakeholder.weight = weight_;
    }

    /**
     * Update the stake of a list of stakeholders as owner.
     * @param stakeholders_ The stakeholders
     * @param weights_ The new weights.
     *  is allowed to update his weight.
     */
    function updateWeightBatch(address[] memory stakeholders_, uint[] memory weights_) public onlyOwner{

        require(stakeholders_.length == weights_.length, "Length mismatch");

        // Close previous period if in the past and create a new one, else update the latest one.
        claimRewardsAsOwner(stakeholders_);

        for(uint i = 0; i < stakeholders_.length; i++){

            StakeholderLib.Stakeholder storage stakeholder = stakeholders[stakeholders_[i]];
            if(weights_[i] == stakeholder.weight){continue;}

            // Update balance distributions with new weight
            aggregatedBalances.moveToDifferentWeight(
                stakeholder.weight,
                weights_[i],
                stakeholder.stakingBalance,
                stakeholder.newStake,
                stakeholder.lockedRewards
            );

            // Finally, set the new weight
            stakeholder.weight = weights_[i];

        }
    }

    /**
     * Increase the stake of the sender by a value.
     * @param amount The amount to stake
     */
    function stake(uint amount) public {
        // Close previous period if in the past and create a new one, else update the latest one.
        handleNewPeriod(currentPeriod());
        address sender = _msgSender();

        require(amount > 0, "Amount not positive");
        require(stakingToken.allowance(sender, address(this)) >= amount,
             "Token transfer not approved");


        // Update the stakeholders state
        StakeholderLib.Stakeholder storage stakeholder = stakeholders[sender];

        // Handle new staker
        if(!stakeholder.isActive()){
            aggregatedBalances.handleMaxWeightIncrease(stakeholder.weight);
            aggregatedBalances[stakeholder.weight].weightCounts++;
            stakeholder.startDate = block.timestamp;
            stakeholder.lastClaimed = currentPeriod();
            emit Active(sender, true);
        }

        // Claim previous rewards with old staked value
        handleRewards(currentPeriod(), false, sender);

        // The current period will calculate rewards with the old stake.
        // Afterwards, newStake will be added to stake and calculation uses updated balance
        stakeholder.newStake += amount;

        // Update the totals
        aggregatedBalances[stakeholder.weight].totalNewStake += amount;
        
        // Transfer the tokens for staking
        stakingToken.transferFrom(sender, address(this), amount);
        emit Staking(sender, amount);
    }

    /**
     Request to withdrawal funds from the contract.
     The funds will not be regarded as stake anymore: no rewards can be earned on this balance.
     Rewards earned by staking are withdrawn first, they will be withdrawn immediatelly
     after calling this function.
     No cooldown or fee applies on earned rewards.
     For The initial staked balance, the funds are not withdrawn directly.
     They can be claimed with `withdrawFunds` after the cooldown period has passed for free,
     or earlier by paying a fee.
     @dev the request will set the releaseDate for the stakeholder to `cooldown` time in the future,
      and the releaseAmount to the amount requested for withdrawal.
     @param amount The amount to withdraw, capped by the total stake + owed rewards.
     @param instant If set to true, the `withdrawFunds` function will be called at the end of the request.
      No second transaction is needed, but the full `earlyWithdrawalFee` needs to be paid.
     @param claimRewardsFirst a boolean flag: should be set to true if you want to claim your rewards.
      If set to false, all owed rewards will be dropped. Build in for safety, funds can be withdrawn
      even when the reward calculations encounters a breaking bug.
     */
    function requestWithdrawal(uint amount, bool instant, bool claimRewardsFirst) public {
        address sender = _msgSender();
        StakeholderLib.Stakeholder storage stakeholder = stakeholders[sender];

        // If there is no cooldown, there is no need to have 2 separate function calls
        if(cooldown == 0){
            instant = true;
        }

        // Claim rewards with current stake
        // Can be skipped as failsafe in case claiming rewards fails,
        // but REWARDS ARE LOST.
        if (claimRewardsFirst){
            handleNewPeriod(currentPeriod());
            handleRewards(currentPeriod(), false, sender);
        } else {
            stakeholder.lastClaimed = currentPeriod();
        }

        require(stakeholder.isActive(), "Nothing was staked");

        // Define distribution of balances to lower.
        // First, withdraw from rewards (without cooldown)
        // If the amount exceeds this value, withdraw also from the new stake (with cooldown).
        // If the amount exceeds this value, withdraw also from the staking balance (with cooldown).
        // If the amount exceeds total balance, cap at the sum of the values
        uint toWithdrawFromRewards = (stakeholder.claimedRewards >= amount ? amount : stakeholder.claimedRewards);
        amount -= toWithdrawFromRewards;
        uint toWithdrawFromNewStake = (stakeholder.newStake >= amount ? amount : stakeholder.newStake );
        amount -= toWithdrawFromNewStake;
        uint toWithdrawFromStakingBalance = (stakeholder.stakingBalance >= amount ? amount : stakeholder.stakingBalance);
        amount -= toWithdrawFromStakingBalance;
        
        // Adjust stakeholder balance
        stakeholder.newStake -= toWithdrawFromNewStake;
        stakeholder.stakingBalance -= toWithdrawFromStakingBalance;
        stakeholder.claimedRewards -= toWithdrawFromRewards;

        // Adjust total balance
        aggregatedBalances[stakeholder.weight].totalNewStake -= toWithdrawFromNewStake;
        aggregatedBalances[stakeholder.weight].totalStakingBalance -= (toWithdrawFromStakingBalance + toWithdrawFromRewards);

         // Handle withdrawing staked values (with cooldown)
        // and rewards (without cooldown)
        uint[2] memory amounts = [toWithdrawFromRewards, (toWithdrawFromNewStake+toWithdrawFromStakingBalance)];
        uint[2] memory cooldowns = [0, cooldown];
        bool[2] memory instantFlags = [true, instant];

        for(uint i=0;i<2;i++){

            if(amounts[i] > 0){
                // Add the new withdrawal for the user
                stakeholder.withdrawals.push(
                    StakeholderLib.Withdrawal(block.timestamp + cooldowns[i],
                    amounts[i],
                    false)
                );
                // Emit event including the ID
                emit InitiateWithdraw(
                    sender,
                    amounts[i],
                    block.timestamp + cooldowns[i],
                    stakeholder.withdrawals.length-1
                    );
                // If instant withdrawal is needed, trigger withdrawFunds
                if(instantFlags[i]){
                    withdrawFunds(stakeholder.withdrawals.length-1);
                }
            }
        }


        // If no stake is left in any way,
        // treat the staker as leaving
        if(!stakeholder.isActive()){
            stakeholder.startDate = 0;
            aggregatedBalances[stakeholder.weight].weightCounts--;
            // Check if maxWeight decreased
            aggregatedBalances.handleMaxWeightDecrease();
            emit Active(sender, false);
        }

    }

    function getWithdrawalLength(address stakeholderAddress) public view returns(uint length){
        return stakeholders[stakeholderAddress].withdrawals.length;
    }

    function getWithdrawal(uint index, address stakeholderAddress) public view returns(uint releaseDate, uint releaseAmount, bool withdrawn){
        return (stakeholders[stakeholderAddress].withdrawals[index].releaseDate,
                stakeholders[stakeholderAddress].withdrawals[index].releaseAmount,
                stakeholders[stakeholderAddress].withdrawals[index].withdrawn);
    }

    /**
     * Withdraw staked funds from the contract.
     * Can only be triggered after `requestWithdrawal` has been called.
     * If funds are withdrawn before the cooldown period has passed,
     * a fee will fee deducted. Withdrawing the funds when triggering
     * `requestWithdrawal` will result in a fee equal to `earlyWithdrawalFee`.
     * Waiting until the cooldown period has passed results in no fee.
     * Withdrawing at any other moment between these two periods in time
     * results in a fee that lineairy decreases with time.
     */
    function withdrawFunds(uint withdrawalId) public {
        address sender = _msgSender();
        StakeholderLib.Stakeholder storage stakeholder = stakeholders[sender];

        require(stakeholder.withdrawals.length > withdrawalId,
            "No withdraw request");

        StakeholderLib.Withdrawal memory withdrawal = stakeholder.withdrawals[withdrawalId];
        require(!withdrawal.withdrawn, "Request already handled");

        // Calculate time passed since withdraw request to calculate fee
        uint timeToEnd = withdrawal.releaseDate >= block.timestamp ? (withdrawal.releaseDate - block.timestamp) : 0;
        uint fee = (cooldown > 0) ? withdrawal.releaseAmount * timeToEnd * earlyWithdrawalFee / (cooldown * Constants.decimalPrecision * 100) : 0;

        // Mark the request as handled (before sending rewards to avoid reentrancy)
        stakeholder.withdrawals[withdrawalId].withdrawn = true;

        // Transfer reduced amount to the staker, fee stays in contract
        stakingToken.transfer(sender, withdrawal.releaseAmount - fee);
        emit Withdraw(sender, withdrawal.releaseAmount, fee, withdrawalId);

    }

    /**
     * Function to claim the rewards earned by staking for the sender.
     * @dev Calls `handleRewards` for the sender
     * @param endPeriod The periods to claim rewards for.
     * @param withdraw if true, send the rewards to the stakeholder.
     *  if false, add the rewards to the staking balance of the stakeholder.
     */
    function claimRewards(uint endPeriod, bool withdraw) public {
        // If necessary, close the current latest period and create a new latest.
        handleNewPeriod(endPeriod);
        address stakeholderAddress = _msgSender();
        handleRewards(endPeriod, withdraw, stakeholderAddress);
    }

    /**
     * Function to claim the rewards for a list of stakers as owner.
     * No funds are withdrawn, only staking balances are updated.
     * @dev Calls `handleRewards` in a loop for the stakers defined
     * @param stakeholders_ list of stakeholders to claim rewards for
     */
    function claimRewardsAsOwner(address[] memory stakeholders_) public onlyOwner{
        // If necessary, close the current latest period and create a new latest.
        handleNewPeriod(currentPeriod());
        for(uint i = 0; i < stakeholders_.length; i++){
            handleRewards(currentPeriod(), false, stakeholders_[i]);
        }
    }

    /**
     * Function to claim the rewards earned by staking for an address.
     * @dev uses calculateRewards to get the amount owed
     * @param endPeriod The periods to claim rewards for.
     * @param withdraw if true, send the rewards to the stakeholder.
     *  if false, add the rewards to the staking balance of the stakeholder.
     * @param stakeholderAddress address to claim rewards for
     */
    function handleRewards(uint endPeriod, bool withdraw, address stakeholderAddress) private {

        StakeholderLib.Stakeholder storage stakeholder = stakeholders[stakeholderAddress];

        if(currentPeriod() < endPeriod){
            endPeriod = currentPeriod();
        }
        // Number of periods for which rewards will be paid
        // Current period is not in the interval as it is not finished.
        uint n = (endPeriod > stakeholder.lastClaimed) ?
            endPeriod - stakeholder.lastClaimed : 0;

        // If no potental stake is present or no time passed since last claim,
        // new rewards do not need to be calculated.
        if (!stakeholder.isActive() || n == 0){
                return;
        }

        // Calculate the rewards and new stakeholder state
        (uint reward, StakeholderLib.Stakeholder memory newStakeholder) = calculateRewards(stakeholderAddress, endPeriod);
        stakeholder.lastClaimed = endPeriod;

        // Update stakeholder values
        stakeholder.stakingBalance = newStakeholder.stakingBalance;
        stakeholder.newStake = newStakeholder.newStake;
        stakeholder.lockedRewards = newStakeholder.lockedRewards;

        // Update last claimed and reward definition to use in next calculation

        // If the stakeholder wants to withdraw the rewards,
        // send the funds to his wallet. Else, update stakingbalance.
        if (withdraw){
            aggregatedBalances[stakeholder.weight].totalStakingBalance -= reward;
            // If no stake is left in any way,
            // treat the staker as leaving
            if(!stakeholder.isActive()){
                stakeholder.startDate = 0;
                aggregatedBalances[stakeholder.weight].weightCounts--;
                // Check if maxWeight decreased
                aggregatedBalances.handleMaxWeightDecrease();
                emit Active(stakeholderAddress, false);
            }
            stakingToken.transfer(_msgSender(), reward);
            
            // Add the new withdrawal for the user
            stakeholder.withdrawals.push(
                StakeholderLib.Withdrawal(block.timestamp,
                reward,
                true)
            );
            
            emit Withdraw(stakeholderAddress, reward, 0, stakeholder.withdrawals.length-1);

        } else {
            stakeholder.claimedRewards += reward;
        }

        emit Rewarding(stakeholderAddress, reward, n);

    }

    /*
     * Calculate the rewards owed to a stakeholder.
     * The interest will be calculated based on:
     *  - The reward to divide in this period
     *  - The the relative stake of the stakeholder (taking previous rewards in account)
     *  - The time the stakeholder has been staking.
     * The formula of compounding interest is applied, meaning rewards on rewards are calculated.
     * @param stakeholderAddress The address to calculate rewards for
     * @param endPeriod The rewards will be calculated until this period.
     * @return reward The rewards of the stakeholder for previous periods that can be claimed instantly.
     * @return lockedRewards The additional locked rewards for this period
     * @return stakeholder The new object containing stakeholder state
     */
    function calculateRewards(address stakeholderAddress, uint endPeriod) public view returns(uint reward, StakeholderLib.Stakeholder memory stakeholder) {

        stakeholder = stakeholders[stakeholderAddress];

        // Number of periods for which rewards will be paid
        // lastClaimed is included, currentPeriod not.
        uint n = (endPeriod > stakeholder.lastClaimed) ?
            endPeriod - stakeholder.lastClaimed : 0;

        // If no stake is present or no time passed since last claim, 0 can be returned.
        if (!stakeholder.isActive() || n == 0){
                return (0, stakeholder);
        }

        // Loop over all following intervals to calculate the rewards for following periods.
        AggregatedBalanceLib.AggregatedBalance[] memory simulationBalances = aggregatedBalances;
        RewardPeriodLib.RewardPeriod memory simulationRewardPeriod;

        // Loop over over all periods.
        // Start is last claimed date,
        // end is capped by the smallest of:
        // - the endPeriod function parameter
        // - the max number of periods for which rewards are distributed
        uint endOfLoop = (endPeriod > (maxNumberOfPeriods+1) ? (maxNumberOfPeriods+1) : endPeriod);

        for (uint p = stakeholder.lastClaimed;
            p < endOfLoop;
            p++) {

            // If p is smaller than the latest reward period registered,
            // calculate the rewards based on state
            if(p <= latestRewardPeriod()){
                simulationRewardPeriod = rewardPeriods[p];
            }

            if(p == latestRewardPeriod()){
                // Calculate the reward per period at this moment as estimation for simulations
                // This value will only be set AFTER the period is over, so will not yet be available.
                simulationRewardPeriod.rewardPerPeriod = calculateRewardPerPeriod();

            }            
            
            // If p is bigger, simulate the behaviour of `handleNewPeriod`
            // and `_totalStakingBalance` with the current state of the last period.
            // This part is never used in `claimRewards` as the state is updated first
            // but it is needed when directly calling this function to:
            // - calculating current rewards before anyone triggered `handleNewPeriod`
            // - forecasting expected returns with a period in the future
            
            if(p >= latestRewardPeriod()){
                // Add rewards of last period

                // Initialize first simulation
                simulationRewardPeriod.totalWeightedStakingBalance = simulationBalances.calculateTotalWeightedStakeMemory(1);

                simulationBalances = simulationBalances.updateBalancesMemory(
                    simulationRewardPeriod.rewardPerPeriod,
                    simulationRewardPeriod.extraRewardMultiplier,
                    ((p % Constants.periodsForExtraReward == 0) || p == maxNumberOfPeriods));

            }

            // No reward is provided anymore
            if(p == maxNumberOfPeriods){
                simulationRewardPeriod.rewardPerPeriod = 0;

            }   
            // Update the new stake with new rewards if applicable
            if(simulationRewardPeriod.totalWeightedStakingBalance > 0){
                
                (uint newReward, uint lockedRewards) = stakeholder.calculateRewards(
                    simulationRewardPeriod.rewardPerPeriod,
                    simulationRewardPeriod.totalWeightedStakingBalance,
                    simulationRewardPeriod.extraRewardMultiplier,
                    ((p % Constants.periodsForExtraReward == 0) || p == maxNumberOfPeriods));

                reward += newReward;
                stakeholder.claimedRewards += newReward;
                stakeholder.lockedRewards = lockedRewards;
            }

            // After rewarding last period with old stake, add new to balance
            if(stakeholder.newStake > 0){
                stakeholder.stakingBalance += stakeholder.newStake;
                stakeholder.newStake = 0;
            }

        }

        return (reward, stakeholder);

    }


    /**
     * Checks if the signature is created out of the contract address, sender and new weight,
     * signed by the private key of the signerAddress
     * @param sender the address of the message sender
     * @param weight amount of tokens to mint
     * @param signature a signature of the contract address, senderAddress and tokensId.
     *   Should be signed by the private key of signerAddress.
     */
    function _recoverSigner(address sender, uint weight, bytes memory signature) private view returns (address){
        return ECDSA.recover(ECDSA.toEthSignedMessageHash(keccak256(abi.encode(address(this), sender, weight))) , signature);
    }

    /**
     * Owner function to transfer the staking token from the contract
     * address to the contract owner.
     * The amount cannot exceed the amount staked by the stakeholders,
     * making sure the funds of stakeholders stay in the contract.
     * Unclaimed rewards and locked rewards cannot be withdrawn either.
     * @param amount the amount to withraw as owner
     */
    function withdrawRemainingFunds(uint amount) public onlyOwner{

        uint remainingFunds = stakingToken.balanceOf(address(this)) - aggregatedBalances.sumOfAllBalances();
        // Make sure the staked amounts rewards are never withdrawn
        if(amount > remainingFunds){
                amount = remainingFunds;
        }

        stakingToken.transfer(owner(), amount);
    }

    /**
     * Update the address used to verify signatures
     * @param value the new address to use for verification
     */
    function updateSignatureAddress(address value) public onlyOwner {
        signatureAddress = value;
    }

    /**
     * @param value the new end date after which rewards will stop
     */
    function updateMaxNumberOfPeriods(uint value) public onlyOwner {
        maxNumberOfPeriods = value;
        emit ConfigUpdate('Max number of periods', value);
    }

    /**
     * Updates the cooldown period.
     * @param value The new cooldown per period
     */
    function updateCoolDownPeriod(uint value) public onlyOwner{
        cooldown = value;
        emit ConfigUpdate('Cooldown', value);
    }

    /**
     * Updates the early withdraw fee.
     * @param value The new fee
     */
    function updateEarlyWithdrawalFee(uint value) public onlyOwner{
        earlyWithdrawalFee = value;
        emit ConfigUpdate('Withdraw fee', value);
    }

    /**
     * Updates the extra reward multiplier, starting instantly.
     * Take into account this value will be divided by Constants.decimalPrecision
     * in order to allow multipliers < 1 up to 0.000001.
     * @param value The new reward per period
     */
    function updateExtraRewardMultiplier(uint value) public onlyOwner{
        handleNewPeriod(currentPeriod());
        currentExtraRewardMultiplier = value;
        emit ConfigUpdate('Extra reward multiplier', value);
    }

    /**
     * Calculates how many reward periods passed since the start.
     * @return period the current period
     */
    function currentPeriod() public view returns(uint period){
        period = (block.timestamp - startDate) / Constants.rewardPeriodDuration;
        if(period > (maxNumberOfPeriods+1)){
            period = maxNumberOfPeriods+1;
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Constants {
    uint constant public decimalPrecision = 10**6;
    uint constant public periodsForExtraReward = 182;
    uint constant public rewardPeriodDuration = 86400;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {Constants} from "./Constants.sol";
import {Calculations} from "./Calculations.sol";

library AggregatedBalanceLib {

    using SafeMath for uint;

    /** @return RewardPeriod Struct containing the state of each reward period.*/
    struct AggregatedBalance {
        uint totalStakingBalance; // Total staking balance
        uint totalNewStake; // Tokens staked in this period to be added in the next one.
        uint totalLockedRewards; // Total amount of locked rewards
        uint weightCounts; // counts of stakers per weight
    }

    function calculateTotalWeightedStake(
        AggregatedBalance[] storage balances,
        uint weightExponent)
        internal view returns(uint sum){
        for(uint i = 0; i < balances.length; i++){
            sum += balances[i].totalStakingBalance * (i+1) ** weightExponent;
        }
    }

    function calculateTotalWeightedStakeMemory(
        AggregatedBalance[] memory balances,
        uint weightExponent)
        internal pure returns(uint sum){
        for(uint i = 0; i < balances.length; i++){
            sum += balances[i].totalStakingBalance * (i+1) ** weightExponent;
        }
    }

    function sumOfAllBalances(
        AggregatedBalance[] storage balances
        )
        internal view returns(uint sum){
        for(uint i = 0; i < balances.length; i++){
            sum += (balances[i].totalStakingBalance
                    + balances[i].totalNewStake
                    + balances[i].totalLockedRewards);
        }
    }

    function updateBalances(AggregatedBalance[] storage balances,
        uint reward,
        uint extraRewardMultiplier,
        bool releaseLockedTokens
        ) internal {

        uint totalWeightedStake = calculateTotalWeightedStake(balances, 1);

        for(uint i = 0; i< balances.length;i++){

            (uint updatedStake, uint updatedLockedRewards) =
                Calculations.calculateRewards(
                    balances[i].totalStakingBalance,
                    balances[i].totalLockedRewards,
                    i,
                    reward,
                    totalWeightedStake,
                    extraRewardMultiplier,
                    releaseLockedTokens
                );

            // Update balances
            balances[i].totalStakingBalance += updatedStake
                + balances[i].totalNewStake;
            balances[i].totalNewStake = 0;
            balances[i].totalLockedRewards = updatedLockedRewards;
        }
    }


    function updateBalancesMemory(AggregatedBalance[] memory balances,
        uint reward,
        uint extraRewardMultiplier,
        bool releaseLockedTokens
        ) internal pure returns(AggregatedBalance[] memory){

        uint totalWeightedStake = calculateTotalWeightedStakeMemory(balances, 1);

        for(uint i = 0; i< balances.length;i++){
            
            balances[i].totalStakingBalance += balances[i].totalNewStake;
            
            (uint updatedStake, uint updatedLockedRewards) =
                Calculations.calculateRewards(
                    balances[i].totalStakingBalance,
                    balances[i].totalLockedRewards,
                    i,
                    reward,
                    totalWeightedStake,
                    extraRewardMultiplier,
                    releaseLockedTokens
                );

            // Update balances
            balances[i].totalStakingBalance += updatedStake;
            balances[i].totalNewStake = 0;
            balances[i].totalLockedRewards = updatedLockedRewards;
        }

        return balances;
    }

    function moveToDifferentWeight(
        AggregatedBalance[] storage balances,
        uint oldWeight,
        uint newWeight,
        uint stake,
        uint newStake,
        uint lockedRewards)
        internal {

            // Check if new weight is already in the list
            handleMaxWeightIncrease(balances, newWeight);

            // Adjust staking balance
            balances[oldWeight].totalStakingBalance -= stake;
            balances[newWeight].totalStakingBalance += stake;

            // Adjust total new stake
            balances[oldWeight].totalNewStake -= newStake;
            balances[newWeight].totalNewStake += newStake;

            // Move locked rewards so they will be added to the correct total stake
            balances[oldWeight].totalLockedRewards -= lockedRewards;
            balances[newWeight].totalLockedRewards += lockedRewards;

            balances[oldWeight].weightCounts--;
            balances[newWeight].weightCounts++;

            // Check if the list with balances can be truncated
            handleMaxWeightDecrease(balances);

    }

    /** @notice Extends the list of balances when a new weight is present
    * @dev Initialize new object and push to list
    * @param balances an array containing aggregated balances
    * @param newWeight the new length of the array
    */
    function handleMaxWeightIncrease(
        AggregatedBalance[] storage balances,
        uint newWeight) internal {
        while(newWeight >= balances.length){
            AggregatedBalance memory newBalance;
            balances.push(newBalance);
        }
    }

    /**
     * Truncate the list of balances by deleting slots without information.
    * @param balances an array containing aggregated balances
     */
    function handleMaxWeightDecrease(
        AggregatedBalance[] storage balances,
        uint numberOfIterations
    ) internal {
        // If length is already 0, return
        if(balances.length == 0){return;}

        // Truncate empty values from the array
        uint maxWeight = balances.length;
        while (balances[balances.length-1].weightCounts == 0
            && balances[balances.length-1].totalStakingBalance == 0
            && balances[balances.length-1].totalNewStake == 0
            && balances[balances.length-1].totalLockedRewards == 0
            && ((maxWeight - balances.length) < numberOfIterations)){
                maxWeight--;
                balances.pop();
        }
    }

    function handleMaxWeightDecrease(
        AggregatedBalance[] storage balances) internal {
        handleMaxWeightDecrease(balances, balances.length);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import {Constants} from "./Constants.sol";
import {Calculations} from "./Calculations.sol";

/**
 * @title A staking contract for Goka tokens
 * @author Kasper De Blieck ([email protected])
 * This contract allows Goka token owners to stake their funds.
 * Staking funds will reward a periodic compounded interest.
 */
library StakeholderLib {

    using SafeMath for uint;

    /** @return Stakeholder Struct containing the state of each stakeholder */
    struct Stakeholder {
        uint stakingBalance; // Staking balance of the stakeholder
        uint weight; // The weight of the staker
        uint startDate; // The date the staker joined
        uint lastClaimed; // The date the stakeholder claimed the last rewards
        uint newStake; // Will be used to update the stake of the user in the next period
        uint claimedRewards; // Rewards already claimed
        uint lockedRewards; // Extra reward claimable after additional time has passed
        Withdrawal[] withdrawals; // Amount to be released at the release date
    }

    struct Withdrawal{
        uint releaseDate; // Date on which the stakeholder is able to withdraw the staked funds
        uint releaseAmount; // Amount to be released at the release date
        bool withdrawn; // Defines if the amount was withdrawn already
    }


    /**
     * Checks if a stakeholder is still active
     * Active stakeholders have at least one of following things:
     * - positive staking balance
     * - positive new stake to be added next period
     * - positive locked tokens that can come in circulation
     * @return active true if stakeholder holds active balance
     */
    // function isActive(Stakeholder storage stakeholder) internal view returns(bool active) {
    //     return (stakeholder.stakingBalance > 0
    //         || stakeholder.newStake > 0
    //         || stakeholder.claimedRewards > 0
    //         || stakeholder.lockedRewards > 0);
    // }

    function isActive(Stakeholder memory stakeholder) internal pure returns(bool active) {
        return (
            stakeholder.stakingBalance > 0
            || stakeholder.newStake > 0
            || stakeholder.claimedRewards > 0
            || stakeholder.lockedRewards > 0
        );
    }

    /*
     * Calculate the rewards owed to a stakeholder.
     * The interest will be calculated based on:
     *  - The reward to divide in this period
     *  - The the relative stake of the stakeholder (taking previous rewards in account)
     *  - The time the stakeholder has been staking.
     * The formula of compounding interest is applied, meaning rewards on rewards are calculated.
     * @param stakeholderAddress The address to calculate rewards for
     * @param endPeriod The rewards will be calculated until this period.
     * @return reward The rewards of the stakeholder for previous periods that can be claimed instantly.
     * @return lockedRewards The additional locked rewards for this period
     * @return stakeholder The new object containing stakeholder state
     */
    function calculateRewards(Stakeholder memory stakeholder,
        uint totalReward,
        uint totalWeightedStake,
        uint extraRewardMultiplier,
        bool releaseLockedTokens)
        internal pure returns(uint, uint) {

        return Calculations.calculateRewards(
            stakeholder.stakingBalance + stakeholder.claimedRewards,
            stakeholder.lockedRewards,
            stakeholder.weight,
            totalReward,
            totalWeightedStake,
            extraRewardMultiplier,
            releaseLockedTokens
        );
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {Constants} from "./Constants.sol";

/**
 * @title A staking contract for Goka tokens
 * @author Kasper De Blieck ([email protected])
 * This contract allows Goka token owners to stake their funds.
 * Staking funds will reward a periodic compounded interest.
 */
library RewardPeriodLib {

    /** @return RewardPeriod Struct containing the state of each reward period.*/
    struct RewardPeriod {
        uint rewardPerPeriod; // amount to distribute over stakeholders
        uint extraRewardMultiplier; // Used to calculate the extra reward on each reward (will be divided by decimalPrecision)
        uint totalWeightedStakingBalance; // Sum of total weighted staking balance, only available after period has ended
    }


    /*
     * Function to call when a new reward period is entered.
     * The function will increment the maxRewardPeriod field,
     * making the state of previous period immutable.
     * The state will use the state of the last period as start for the current period.
     * The total staking balance is updated with:
     * - stake added in previous period
     * - rewards earned in previous period
     * - locked tokens, if they are unlocked.
     * @param endPeriod the last period the function should handle.
     *  cannot exceed the current period.
     */
    function addNewPeriod(
        RewardPeriod[] storage rewardPeriods,
        uint extraRewardMultiplier,
        uint totalWeightedStakingBalance
        ) internal {

        // Update the rewards for the period to close - exclude 
        RewardPeriod memory nextRewardPeriod = RewardPeriod(
            0,
            extraRewardMultiplier,
            totalWeightedStakingBalance
        );
        
        rewardPeriods.push(nextRewardPeriod);
    }

}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {Constants} from "./Constants.sol";

library Calculations {

    using SafeMath for uint;

    function calculateRewards(
        uint stakingBalance,
        uint lockedRewards,
        uint weight,
        uint totalReward,
        uint totalWeightedStake,
        uint extraRewardMultiplier,
        bool releaseLockedTokens)
        internal pure returns (uint, uint){

        uint newReward = 0;

        // Calculate reward as:
        // the totalReward * (stake*weight) / totalWeightedStake.
        // Formula is adjusted so the fraction stays > 1
        if(totalWeightedStake > 0 && stakingBalance > 0){
            newReward = (totalReward * (weight+1) + totalWeightedStake)
                * stakingBalance / totalWeightedStake
                - stakingBalance;
        }

        // Release tokens if necessary, otherwise increase locked token balance
        if(releaseLockedTokens){
            newReward += lockedRewards
                    + (newReward 
                    * extraRewardMultiplier 
                    / (Constants.decimalPrecision));
            lockedRewards = 0;
        } else {
            lockedRewards += (newReward * extraRewardMultiplier
                / (Constants.decimalPrecision));
        }

        return (newReward, lockedRewards);

    }

}