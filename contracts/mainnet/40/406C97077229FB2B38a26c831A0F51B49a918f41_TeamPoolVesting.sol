// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BEP20.sol";

/**
 * Math operations with safety checks that throw on overflows.
 */

contract TeamPoolVesting {

    using SafeMath for uint256;

    /**
     * Address of wccoin.
     */
    BEP20 public wccoin;

    /**
     * Address for receiving tokens.
     */
    address public withdrawAddress;

    /**
     * Tokens vesting stage structure with vesting date and tokens allowed to unlock.
     */
    struct VestingStage {
        uint256 date;
        uint256 tokensUnlockedPercentage;
    }

    /**
     * Array for storing all vesting stages with structure defined above.
     */
    VestingStage[100] public stages;

    /**
     * Starting timestamp of the first stage of vesting (19 June 2018).
     * Will be used as a starting point for all dates calculations.
     */
    uint256 public vestingStartTimestamp = 1716233153;

    /**
     * Total amount of tokens sent.
     */
    uint256 public initialTokensBalance;

    /**
     * Amount of tokens already sent.
     */
    uint256 public tokensSent;

    /**
     * Event raised on each successful withdraw.
     */
    event Withdraw(uint256 amount, uint256 timestamp);

    /**
     * Could be called only from withdraw address.
     */
    modifier onlyWithdrawAddress () {
        require(msg.sender == withdrawAddress);
        _;
    }

    /**
     * We are filling vesting stages array right when the contract is deployed.
     *
     * @param token Address of wccoin that will be locked on contract.
     * @param withdraw Address of tokens receiver when it is unlocked.
     */
    constructor (BEP20 token, address withdraw) {
        wccoin = token;
        withdrawAddress = withdraw;
        initVestingStages();
    }
    

    /**
     * Calculate tokens amount that is sent to withdrawAddress.
     * 
     */
    function getAvailableTokensToWithdraw () public view returns (uint256 tokensToSend) {
        uint256 tokensUnlockedPercentage = getTokensUnlockedPercentage();
        // In the case of stuck tokens we allow the withdrawal of them all after vesting period ends.
        if (tokensUnlockedPercentage >= 100) {
            tokensToSend = wccoin.balanceOf(address(this));
        } else {
            tokensToSend = getTokensAmountAllowedToWithdraw(tokensUnlockedPercentage);
        }
    }

    /**
     * Get detailed info about stage. 
     * Provides ability to get attributes of every stage from external callers, ie Web3, truffle tests, etc.
     *
     * @param index Vesting stage number. Ordered by ascending date and starting from zero.
     *
     */
    function getStageAttributes (uint8 index) public view returns (uint256 date, uint256 tokensUnlockedPercentage) {
        return (stages[index].date, stages[index].tokensUnlockedPercentage);
    }

    /**
     * Setup array with vesting stages dates and percents.
     */
    function initVestingStages () internal {
        
        uint256 daysCount = 30 days;

        stages[0].date = vestingStartTimestamp;
        stages[0].tokensUnlockedPercentage = 1;

        for(uint256 i = 1; i < 100; i++){
            stages[i].tokensUnlockedPercentage = 1;
            stages[i].date = vestingStartTimestamp + daysCount;
            daysCount += 30 days;
        }
        
    }

    /**
     * Main method for withdraw tokens from vesting.
     */
    function withdrawTokens () onlyWithdrawAddress external {
        // Setting initial tokens balance on a first withdraw.
        if (initialTokensBalance == 0) {
            setInitialTokensBalance();
        }
        uint256 tokensToSend = getAvailableTokensToWithdraw();
        sendTokens(tokensToSend);
    }

    /**
     * Set initial tokens balance when making the first withdrawal.
     */
    function setInitialTokensBalance () private {
        initialTokensBalance = wccoin.balanceOf(address(this));
    }

    /**
     * Send tokens to withdrawAddress
     * 
     * @param tokensToSend Amount of tokens will be sent.
     */
    function sendTokens (uint256 tokensToSend) private {
        if (tokensToSend > 0) {
            // Updating tokens sent counter
            tokensSent = tokensSent.add(tokensToSend);
            // Sending allowed tokens amount
            wccoin.transfer(withdrawAddress, tokensToSend);
            // Raising event
            emit Withdraw(tokensToSend, block.timestamp);
        }
    }

    /**
     * Calculate tokens available for withdrawal.
     *
     * @param tokensUnlockedPercentage Percent of tokens that are allowed to be sent.
     *
     * @return Amount of tokens that can be sent according to provided percentage.
     */
    function getTokensAmountAllowedToWithdraw (uint256 tokensUnlockedPercentage) private view returns (uint256) {
        uint256 totalTokensAllowedToWithdraw = initialTokensBalance.mul(tokensUnlockedPercentage).div(100);
        uint256 unsentTokensAmount = totalTokensAllowedToWithdraw.sub(tokensSent);
        return unsentTokensAmount;
    }

    /**
     * Get tokens unlocked percentage on current stage.
     * 
     * @return Percent of tokens allowed to be sent.
     */
    function getTokensUnlockedPercentage () private view returns (uint256) {
        uint256 allowedPercent;
        
        for (uint8 i = 0; i < stages.length; i++) {
            if (block.timestamp >= stages[i].date) {
                allowedPercent = stages[i].tokensUnlockedPercentage;
            }
        }
        
        return allowedPercent;
    }
}