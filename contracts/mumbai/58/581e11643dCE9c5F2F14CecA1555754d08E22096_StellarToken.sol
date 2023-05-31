// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StellarToken is IERC20 {
    string public name = "StellarToken";
    string public symbol = "STLLER";
    uint256 public decimals = 18;
    uint256 public totalSupply = 6900000000 * 10**decimals; // 6.9 billion tokens
    
    uint256 private maxSellLimit = totalSupply / 100; // 1% of the total supply
    
    uint256 private sellTaxPercent = 7; // Initial sell tax percentage
    uint256 private sellTaxThreshold1 = 69000000 * 10**decimals; // Threshold for 5% sell tax
    uint256 private sellTaxThreshold2 = 6900000 * 10**decimals; // Threshold for 2% sell tax
    
    //uint256 private devLockDuration = 365 days;
    uint256 private devLockDuration = 5 minutes; //ONLY TEST

    //uint256 private stakeLockDuration = 28 days; // Stake lock duration
    uint256 private stakeLockDuration = 5 minutes; //ONLY TEST

    uint256 private stakeRewardPercent = 7; // Stake reward percentage
    uint256 private stakeBurnPercent = 2; // Stake burn percentage
    
    address private devWallet;
    address private marketingWallet;
    address private nullAddress;
    address public nftContract; // Address of the contract
    
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    mapping(address => uint256) private lockTimestamps;
    mapping(address => uint256) public nftLevels; // Mapping to track NFT levels
    
    bool private reentrancyGuard; // Reentrancy guard
    bool private burnFlag; // Flag to control burn availability

    uint256 private constant YEAR_SECONDS = 31536000;
    uint256 private constant DAY_SECONDS = 86400;
    uint256 private constant LEAP_YEAR_SECONDS = 31622400;

    bool private stakingEnabled = false;

    // Address of the QuickSwap Router
    address private constant QUICKSWAP_ROUTER = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;

    // Address of the token you want to swap
    address private TOKEN_ADDRESS;

    // Address of the MATIC token
    address private constant MATIC_TOKEN = 0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0;
    
    struct Stake {
        uint256 amount;
        uint256 releaseTimestamp;
    }
    
    mapping(address => Stake) private stakes;
    
    //event Transfer(address indexed from, address indexed to, uint256 value);
    //event Approval(address indexed owner, address indexed spender, uint256 value);
    event AutoBurn(uint256 amount);
    event StakeTokens(address indexed staker, uint256 amount, uint256 releaseTimestamp);
    event UnstakeTokens(address indexed staker, uint256 amount);
    event Burn(address indexed _from, uint256 _value);
    event RewardAdded(address indexed user, uint256 amount);

     // QuickSwap Router instance
    IUniswapV2Router02 private quickswapRouter;
    
    constructor() {
        devWallet = 0xE7Dcd230B5A1647F1F68C0D48Bacf0FA8f184f90;
        marketingWallet = 0x8a06B97d744fF433E7576755455c50272286713D;
        nullAddress = address(0);
        quickswapRouter = IUniswapV2Router02(QUICKSWAP_ROUTER);
        TOKEN_ADDRESS = address(this);
        
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

    modifier onlyNFTContract() {
        require(msg.sender == nftContract, "Caller is not the NFT contract");
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
            
            uint256 sellTax = calculateSellTax(value);
            balances[nullAddress] += sellTax;
            emit Transfer(from, nullAddress, sellTax);
            
            balances[from] -= value;
            balances[to] += value - sellTax;
            emit Transfer(from, to, value - sellTax);
        } else {
            // Skip tax calculation for buy transactions
            balances[from] -= value;
            balances[to] += value;
            emit Transfer(from, to, value);
        }

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
        uint256 unstakeAmount = stake.amount;

        // Deduct the burn amount from the rewards
        reward -= burnAmount;

        // Apply NFT level boost if available
        if (nftLevels[msg.sender] > 0 && nftLevels[msg.sender] <= 5) {
            uint256 boostPercentage = nftLevels[msg.sender] * 1; // 1% increase per NFT level
            uint256 boostReward = unstakeAmount * boostPercentage / 100;
            reward += boostReward;
        }

        // Check if the contract has enough balance to pay rewards
        if (reward > balances[address(this)]) {
            // If contract balance is below the rewards amount, it will mint new tokens in order to pay for it
            // This is the only time tokens might be minted
            uint256 shortage = reward - balances[address(this)];
            totalSupply += shortage;
            balances[address(this)] += shortage;
        }

        // Add the staked tokens from circulation
        totalSupply += unstakeAmount;

        // Add the rewards to the sender's balance
        balances[msg.sender] += reward;

        // Transfer the unstaked tokens to the sender
        balances[msg.sender] += unstakeAmount;

        // Burn the tax
        totalSupply -= burnAmount;

        // Reset the stake
        delete stakes[msg.sender];

        emit UnstakeTokens(msg.sender, stake.amount);
        emit Transfer(address(0), msg.sender, unstakeAmount);
        emit RewardAdded(msg.sender, reward);
    }    

    function getStakedAmountAndTimeRemaining(address account) public view returns (uint256, uint256, uint256, uint256, uint256) {
        Stake memory stake = stakes[account];
        require(stake.amount > 0, "No stakes found");

        uint256 releaseTimestamp = stake.releaseTimestamp;
        uint256 currentTimestamp = block.timestamp;

        uint256 timeRemaining = 0;
        if (currentTimestamp < releaseTimestamp) {
            timeRemaining = releaseTimestamp - currentTimestamp;
        }

        uint256 daysRemaining = timeRemaining / DAY_SECONDS;
        timeRemaining -= daysRemaining * DAY_SECONDS;

        uint256 hoursRemaining = timeRemaining / 3600;
        timeRemaining -= hoursRemaining * 3600;

        uint256 minutesRemaining = timeRemaining / 60;
        uint256 secondsRemaining = timeRemaining - minutesRemaining * 60;

        return (stake.amount, daysRemaining, hoursRemaining, minutesRemaining, secondsRemaining);
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

    //NFT Functions
    function setNFTContract(address _nftContract) external onlyDev {
        nftContract = _nftContract;
    }

    // Set the level of an NFT for a specific address
    // Only the contract address can call this function
    // Parameters:
    // - account: The address for which to set the NFT level
    // - level: The NFT level to set for the address
    function setNFTLevel(address account, uint256 level) external onlyNFTContract {
        // Set the NFT level for a specific address
        require(level >= 0 && level <= 5, "Invalid NFT level");
        nftLevels[account] = level;
    }

    // Clear the level of an NFT for a specific address
    // Only the contract address can call this function
    // Parameters:
    // - account: The address for which to clear the NFT level
    function clearNFTLevel(address account) external onlyNFTContract {
        // Check if the address has an existing NFT level
        require(nftLevels[account] != 0, "No NFT level set for the address");

        // Clear the NFT level for the specified address
        delete nftLevels[account];
    }

    /**
    * @dev Burns a specified amount of tokens from the specified account.
    * @param account The address from which the tokens will be burned.
    * @param amount The amount of tokens to be burned.
    *
    * Requirements:
    * - The amount must be greater than 0.
    * - The account must have a sufficient balance of tokens to burn.
    */
    function burnTokensInternal(address account, uint256 amount) private {
        require(amount > 0, "Invalid burn amount");
        require(amount <= balances[account], "Insufficient balance");

        // Subtract the burned amount from the account balance
        balances[account] -= amount;
        
        // Subtract the burned amount from the total supply
        totalSupply -= amount;

        // Emit a transfer event to reflect the token burn
        emit Transfer(account, address(0), amount);

        // Emit a burn event
        emit Burn(account, amount);
    }

    function burnTokens(uint256 amount) external {
        require(amount > 0, "Invalid amount");
        require(amount <= balances[msg.sender], "Insufficient balance");

        balances[msg.sender] -= amount;
        totalSupply -= amount;

        emit Transfer(msg.sender, address(0), amount);
        emit Burn(msg.sender, amount);
    }

    function swapTokens(uint256 amountIn, uint256 amountOutMin) external {
        // Check if the transaction is a sell transaction
        if (msg.sender == address(quickswapRouter) && amountIn > 0) {
            // Calculate the sell tax amount
            uint256 sellTaxAmount = calculateSellTax(amountIn);

            // Deduct the sell tax from the amount
            uint256 amountAfterTax = amountIn - sellTaxAmount;

            // Burn the sell tax amount
            burnTokensInternal(msg.sender, sellTaxAmount);

            // Approve QuickSwap Router to spend the token
            IERC20(TOKEN_ADDRESS).approve(QUICKSWAP_ROUTER, amountAfterTax);

            // Create the path array for the swap
            address[] memory path = new address[](2);
            path[0] = TOKEN_ADDRESS;
            path[1] = MATIC_TOKEN;

            // Perform the swap
            quickswapRouter.swapExactTokensForTokens(
                amountAfterTax,
                amountOutMin,
                path,
                address(this),
                block.timestamp + 600
            );
        } else {
            // No tax applied for other transactions
            // Perform the swap without any tax
            IERC20(TOKEN_ADDRESS).approve(QUICKSWAP_ROUTER, amountIn);

            address[] memory path = new address[](2);
            path[0] = TOKEN_ADDRESS;
            path[1] = MATIC_TOKEN;

            quickswapRouter.swapExactTokensForTokens(
                amountIn,
                amountOutMin,
                path,
                address(this),
                block.timestamp + 600
            );
        }
    }

}