// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StellarToken {
    string public name = "StellarToken";
    string public symbol = "STLLER";
    uint256 public decimals = 18;
    uint256 public totalSupply = 6900000000 * 10**decimals; // 6.9 billion tokens
    
    uint256 private maxSellLimit = totalSupply / 100; // 1% of the total supply
    
    uint256 private sellTaxPercent = 7; // Initial sell tax percentage
    uint256 private sellTaxThreshold1 = 69000000 * 10**decimals; // Threshold for 5% sell tax
    uint256 private sellTaxThreshold2 = 6900000 * 10**decimals; // Threshold for 2% sell tax
    
    uint256 private devLockDuration = 365 days;
    uint256 private stakeLockDuration = 28 days; // Stake lock duration
    uint256 private stakeRewardPercent = 7; // Stake reward percentage
    uint256 private stakeBurnPercent = 2; // Stake burn percentage
    
    address private devWallet;
    address private marketingWallet;
    address private nullAddress;
    
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    mapping(address => uint256) private lockTimestamps;
    
    bool private reentrancyGuard; // Reentrancy guard
    bool private burnFlag; // Flag to control burn availability

    uint256 private constant YEAR_SECONDS = 31536000;
    uint256 private constant DAY_SECONDS = 86400;
    uint256 private constant LEAP_YEAR_SECONDS = 31622400;

    bool private stakingEnabled = false;
    
    struct Stake {
        uint256 amount;
        uint256 releaseTimestamp;
    }
    
    mapping(address => Stake) private stakes;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event AutoBurn(uint256 amount);
    event StakeTokens(address indexed staker, uint256 amount, uint256 releaseTimestamp);
    event UnstakeTokens(address indexed staker, uint256 amount);
    
    constructor() {
        devWallet = 0xE7Dcd230B5A1647F1F68C0D48Bacf0FA8f184f90;
        marketingWallet = 0x8a06B97d744fF433E7576755455c50272286713D;
        nullAddress = address(0);
        
        // Allocate 5% of the total supply to the dev wallet
        uint256 devAllocation = totalSupply * 5 / 100;
        balances[devWallet] = devAllocation;
        emit Transfer(address(0), devWallet, devAllocation);
        lockTimestamps[devWallet] = block.timestamp + devLockDuration;
        
        // Allocate 10% of the total supply to the marketing wallet
        uint256 marketingAllocation = totalSupply * 10 / 100;
        balances[marketingWallet] = marketingAllocation;
        emit Transfer(address(0), marketingWallet, marketingAllocation);
        
        // Allocate remaining tokens to the contract
        uint256 remainingTokens = totalSupply - devAllocation - marketingAllocation;
        balances[address(this)] = remainingTokens;
        emit Transfer(address(0), address(this), remainingTokens);
    }
    
    modifier onlyDev() {
        require(msg.sender == devWallet, "Only the dev wallet can call this function");
        _;
    }
    
    function transfer(address to, uint256 value) external returns (bool) {
        require(value <= balances[msg.sender], "Insufficient balance");
        require(to != address(0), "Invalid recipient");
        require(to != address(this), "Cannot transfer to contract address");
        
        // Perform the transfer
        _transfer(msg.sender, to, value, true);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(value <= balances[from], "Insufficient balance");
        require(value <= allowances[from][msg.sender], "Allowance exceeded");
        require(to != address(0), "Invalid recipient");
        require(to != address(this), "Cannot transfer to contract address");
        
        // Decrease the allowance
        allowances[from][msg.sender] -= value;
        
        // Perform the transfer
        _transfer(from, to, value, false);
        return true;
    }

    function _transfer(address from, address to, uint256 value, bool isSell) private {
        require(!reentrancyGuard, "Reentrant call detected");
        reentrancyGuard = true;

        if (isSell && from == devWallet && lockTimestamps[devWallet] + devLockDuration > block.timestamp) {
            require(false, "Dev wallet locked");
        }

        if (isSell) {
            require(value <= maxSellLimit, "Exceeds maximum sell limit");
        }
        
        uint256 sellTax = 0;
        
        //only apply tax on sells 
        if (isSell) {
            sellTax = calculateSellTax(value);
            balances[nullAddress] += sellTax;
            emit Transfer(from, nullAddress, sellTax);
        }
        
        balances[from] -= value;
        balances[to] += value - sellTax;
        
        emit Transfer(from, to, value - sellTax);
        
        // Reentrancy guard release
        reentrancyGuard = false;
    }
    
    // Calculate the sell tax based on the value
    // The tax percentage decreases as the total supply reaches certain thresholds
    // Returns the calculated sell tax amount
    function calculateSellTax(uint256 value) private returns (uint256) {
        // Check if total supply is below sellTaxThreshold1
        // If so, set sellTaxPercent to 5%
        if (totalSupply <= sellTaxThreshold1) {
            sellTaxPercent = 4;
        }
        // Check if total supply is below sellTaxThreshold2
        // If so, set sellTaxPercent to 2%
        else if (totalSupply <= sellTaxThreshold2) {
            sellTaxPercent = 2;
        }
        
        uint256 sellTax = value * sellTaxPercent / 100;
        
        return sellTax;
    }
    
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
    
    function approve(address spender, uint256 value) external returns (bool) {
        require(spender != address(0), "Invalid spender");
        require(spender != msg.sender, "Cannot approve own address");
        
        allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function allowance(address owner, address spender) external view returns (uint256) {
        return allowances[owner][spender];
    }
    
    function getRemainingDevLockTime() external view onlyDev returns (uint256) {
        uint256 lockTimestamp = lockTimestamps[devWallet];
        uint256 unlockTimestamp = lockTimestamp + devLockDuration;
        uint256 remainingTime = unlockTimestamp > block.timestamp ? unlockTimestamp - block.timestamp : 0;
        return remainingTime;
    }
    
    // Perform an automatic burn
    // Can only be called by the dev address
    // Can only be called on the first day of the month
    function autoBurn() external onlyDev {
        require(!burnFlag, "Auto burn already occurred this month");
        require(totalSupply > 69000000 * 10**decimals, "Total supply limit not reached");
        require(isFirstDayOfMonth(), "Auto burn can only be called on the first day of the month");
        
        uint256 burnAmount = balances[address(this)] / 100; // 1% of the contract balance
        totalSupply -= burnAmount;
        balances[address(this)] -= burnAmount;
        
        emit AutoBurn(burnAmount);
        burnFlag = true;
    }

    // Reset the burnFlag to false
    // Can only be called by the dev address
    // Cannot be called on the first day of the month
    function resetBurnFlag() external onlyDev {
        require(!isFirstDayOfMonth(), "Cannot reset burn flag on the first day of the month");
        burnFlag = false;
    }    
        
    function stakeTokens(uint256 amount) external {
        require(stakingEnabled, "Staking is not enabled");
        require(amount > 0, "Invalid stake amount");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        // Calculate the maximum stake amount (1% of circulating supply)
        uint256 maxStakeAmount = (totalSupply * 1) / 100;

        require(amount <= maxStakeAmount, "Stake amount exceeds limit");

        uint256 releaseTimestamp = block.timestamp + stakeLockDuration;

        // Deduct the tokens from the sender's balance
        balances[msg.sender] -= amount;

        // Remove the staked tokens from circulation
        totalSupply -= amount;

        // Stake the tokens
        stakes[msg.sender] = Stake(amount, releaseTimestamp);

        emit Transfer(msg.sender, address(0), amount);
        emit StakeTokens(msg.sender, amount, releaseTimestamp);
    }

    //Only Dev can call it and after it has been enabled cant be disabled
    function enableStaking() external onlyDev {
        require(!stakingEnabled, "Staking is already enabled");
        stakingEnabled = true;
    }
    
    function unstakeTokens() external {
        Stake memory stake = stakes[msg.sender];
        require(stake.amount > 0, "No stakes found");
        require(block.timestamp >= stake.releaseTimestamp, "Stake is still locked");
        
        uint256 reward = stake.amount * stakeRewardPercent / 100;
        uint256 burnAmount = reward * stakeBurnPercent / 100;
        uint256 unstakeAmount = stake.amount - burnAmount;
        
        // Check if the contract has enough balance to pay rewards
        if (reward > balances[address(this)]) {
            //If contract balance is below the rewards amount, it will mint new tokens in order to pay for it
            //this is the only time tokens might be minted
            uint256 shortage = reward - balances[address(this)];
            totalSupply += shortage;
            balances[address(this)] += shortage;
        }
        
        // Remove the staked tokens from circulation
        totalSupply += unstakeAmount;
        
        // Transfer the unstaked tokens to the sender
        balances[msg.sender] += unstakeAmount;
        
        // Burn the reward
        totalSupply -= burnAmount;
        
        // Reset the stake
        delete stakes[msg.sender];
        
        emit UnstakeTokens(msg.sender, stake.amount);
        emit Transfer(address(0), msg.sender, unstakeAmount);
    }

    function getTimeUntilUnstake(address account) public view returns (uint256) {
        require(stakes[account].amount > 0, "No stakes found");

        uint256 releaseTimestamp = stakes[account].releaseTimestamp;
        uint256 currentTimestamp = block.timestamp;

        if (currentTimestamp >= releaseTimestamp) {
            return 0; // Already eligible for unstaking
        } else {
            return releaseTimestamp - currentTimestamp;
        }
    }
    
    function isFirstDayOfMonth() private view returns (bool) {
        (uint256 year, uint256 month, uint256 day) = getDateTime(block.timestamp);
        return day == 1;
    }
    
    function getDateTime(uint256 timestamp) private pure returns (uint256 year, uint256 month, uint256 day) {
        uint256 secondsAccountedFor = 0;
        uint256 buf;
        uint256 i;

        // Year
        year = getYear(timestamp);
        buf = leapYearsBefore(year) - leapYearsBefore(1970);
        secondsAccountedFor += LEAP_YEAR_SECONDS * buf;
        secondsAccountedFor += YEAR_SECONDS * (year - 1970 - buf);

        // Month
        uint256 secondsInMonth;
        for (i = 1; i <= 12; i++) {
            secondsInMonth = DAY_SECONDS * getDaysInMonth(i, year);
            if (secondsInMonth + secondsAccountedFor > timestamp) {
                month = i;
                break;
            }
            secondsAccountedFor += secondsInMonth;
        }

        // Day
        uint256 dayTemp = (timestamp - secondsAccountedFor) / DAY_SECONDS + 1;
        day = dayTemp;
    }

    function getDaysInMonth(uint256 month, uint256 year) private pure returns (uint256) {
        bool leapYear = isLeapYear(year);

        if (
            month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12
        ) {
            return 31;
        } else if (month == 2) {
            if (leapYear) {
                return 29;
            } else {
                return 28;
            }
        } else {
            return 30;
        }
    }

    function getMonth(uint256 timestamp) private pure returns (uint256) {
        uint256 year = getYear(timestamp);
        uint256 secondsInYear = isLeapYear(year) ? LEAP_YEAR_SECONDS : YEAR_SECONDS;
        uint256 secondsInMonth = secondsInYear / 12;
        uint256 month = (timestamp % secondsInYear) / secondsInMonth + 1;
        return month;
    }
    
    function getYear(uint256 timestamp) private pure returns (uint256) {
        uint256 secondsAccountedFor = 0;
        uint256 year;
        uint256 numLeapYears;
    
        // Year
        year = 1970 + timestamp / (365 days);
        numLeapYears = leapYearsBefore(year) - leapYearsBefore(1970);
    
        secondsAccountedFor = (year - 1970) * (365 days) + numLeapYears * (366 days);
    
        while (secondsAccountedFor > timestamp) {
            if (isLeapYear(year - 1)) {
                secondsAccountedFor -= (366 days);
            } else {
                secondsAccountedFor -= (365 days);
            }
            year -= 1;
        }
        return year;
    }
    
    function leapYearsBefore(uint256 year) private pure returns (uint256) {
        year -= 1;
        return year / 4 - year / 100 + year / 400;
    }
    
    function isLeapYear(uint256 year) private pure returns (bool) {
        if (year % 4 != 0) {
            return false;
        }
        if (year % 100 != 0) {
            return true;
        }
        if (year % 400 != 0) {
            return false;
        }
        return true;
    }

    //temp function MUST be removed after tests
    function selfDestruct() external {
        require(msg.sender == devWallet, "Only the dev can call this function");
        selfdestruct(payable(devWallet));
    }

    /**
    * @dev Allows the dev wallet to withdraw a specific amount of funds.
    * @param amount The amount to be withdrawn from the dev wallet.
    */
    function withdrawDevFunds(uint256 amount) external onlyDev {
        require(amount <= balances[devWallet], "Insufficient balance");

        // Check if the dev wallet is locked
        if (lockTimestamps[devWallet] + devLockDuration > block.timestamp) {
            require(false, "Dev wallet locked");
        }

        // Calculate the sell tax on the withdrawal amount
        uint256 sellTax = calculateSellTax(amount);

        // Deduct the withdrawal amount and sell tax from the dev wallet
        balances[devWallet] -= amount + sellTax;

        // Transfer the specified amount to the caller
        balances[msg.sender] += amount;

        // Add the sell tax to the burn address
        balances[nullAddress] += sellTax;

        // Emit transfer events
        emit Transfer(devWallet, msg.sender, amount);
        emit Transfer(devWallet, nullAddress, sellTax);
    }

}