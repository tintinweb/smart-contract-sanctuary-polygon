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

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
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
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StellarToken is IERC20 {
    string public name = "StellarToken";
    string public symbol = "STLLER";
    uint256 public decimals = 18;
    uint256 public totalSupply = 6900000000 * 10**decimals; // 6.9 billion tokens
    
    uint256 private maxSellLimit = totalSupply / 100; // 1% of the total supply
    
    uint256 private burnTaxPercent = 3; // Initial burn tax percentage
    uint256 private burnTaxThreshold1 = 69000000 * 10**decimals; // Threshold for 2% burn tax
    uint256 private burnTaxThreshold2 = 6900000 * 10**decimals; // Threshold for 1% sell tax
    
    uint256 private devLockDuration = 365 days;
    uint256 private lastAutoBurnTimestamp;

    //uint256 private stakeLockDuration = 28 days; // Stake lock duration
    uint256 private stakeLockDuration = 5 minutes; //ONLY TEST
    //uint256 private stakeSuperSpecialLockDuration = 21 days; // Stake lock duration
    uint256 private stakeSuperSpecialLockDuration = 3 minutes; //ONLY TEST

    uint256 private stakeRewardPercent = 7; // Stake reward percentage
    uint256 private stakeBurnPercent = 2; // Stake burn percentage
    uint256 private totalStakedAmount;
    
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

    // Address of the Uniswap Router
    address private constant UNISWAP_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address private uniswapPair;

    // Address of the token you want to swap
    address private TOKEN_ADDRESS;
    address private MATIC_ADDRESS;
    
    struct Stake {
        uint256 amount;
        uint256 releaseTimestamp;
    }
    
    mapping(address => Stake) private stakes;
    
    event AutoBurn(uint256 amount);
    event StakeTokens(address indexed staker, uint256 amount, uint256 releaseTimestamp);
    event UnstakeTokens(address indexed staker, uint256 amount);
    event Burn(address indexed _from, uint256 _value);
    event ForceUnstakeBurn(address indexed _from, uint256 _value);
    event RewardAdded(address indexed user, uint256 amount);
    event TokensSwapped(address indexed fromToken, address indexed toToken, address indexed sender, uint256 amountIn, uint256 amountOut);
    event StakeEnabled();
    event BurnFlagReset(bool newBurnFlag);
    event CompoundRewards(address indexed recipient, uint256 amount);

    IUniswapV2Router02 private uniswapRouter;
    
    constructor() {
        devWallet = 0xE7Dcd230B5A1647F1F68C0D48Bacf0FA8f184f90;
        marketingWallet = 0x8a06B97d744fF433E7576755455c50272286713D;
        nullAddress = address(0);
        TOKEN_ADDRESS = address(this);
        MATIC_ADDRESS = 0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0;
        uniswapRouter = IUniswapV2Router02(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);

        // Initialize the last auto burn timestamp to the current block timestamp
        lastAutoBurnTimestamp = block.timestamp;
        
        // Allocate 3% of the total supply to the dev wallet
        uint256 devAllocation = totalSupply * 4 / 100;
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

    modifier onlyOnceEvery30Days() {
        require(block.timestamp >= lastAutoBurnTimestamp + 5 minutes, "Auto burn can only be called once every 30 days");
        _;
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
        _transfer(msg.sender, to, value);
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
        _transfer(from, to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) private {
        require(!reentrancyGuard, "Reentrant call detected");
        reentrancyGuard = true;

        if (from == devWallet && lockTimestamps[devWallet] + devLockDuration > block.timestamp) {
            require(false, "Dev wallet locked");
        }

        //TODO - Improve this anti-whale
        //require(value <= maxSellLimit, "Exceeds maximum sell limit");
        
        uint256 burnTax = calculateBurnTax(value);
        balances[nullAddress] += burnTax;
        emit Burn(nullAddress, burnTax);
        
        balances[from] -= value;
        balances[to] += value - burnTax;
        emit Transfer(from, to, value - burnTax);        

        // Reentrancy guard release
        reentrancyGuard = false;
    }    
    
    function calculateBurnTax(uint256 value) private returns (uint256) {
        // Check if total supply is below burnTaxThreshold1
        // If so, set burnTaxPercent to 2%
        if (totalSupply <= burnTaxThreshold1) {
            burnTaxPercent = 2;
        }
        // Check if total supply is below burnTaxThreshold2
        // If so, set burnTaxPercent to 1%
        else if (totalSupply <= burnTaxThreshold2) {
            burnTaxPercent = 1;
        }
        
        uint256 burnTax = value * burnTaxPercent / 100;
        
        return burnTax;
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

    function approveInternal(address spender, uint256 value) internal returns (bool) {
        require(spender != address(0), "Invalid spender");
        require(spender != msg.sender, "Cannot approve own address");
        
        allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function allowance(address owner, address spender) external view returns (uint256) {
        return allowances[owner][spender];
    }
    
    function getRemainingDevLockTime() external view returns (uint256, uint256, uint256, uint256) {
        uint256 lockTimestamp = lockTimestamps[devWallet];
        uint256 unlockTimestamp = lockTimestamp;
        uint256 remainingTime = unlockTimestamp > block.timestamp ? unlockTimestamp - block.timestamp : 0;

        uint256 daysRemaining = remainingTime / 1 days;
        uint256 hoursRemaining = (remainingTime % 1 days) / 1 hours;
        uint256 minutesRemaining = (remainingTime % 1 hours) / 1 minutes;
        uint256 secondsRemaining = (remainingTime % 1 minutes) / 1 seconds;

        return (daysRemaining, hoursRemaining, minutesRemaining, secondsRemaining);
    }
    
    function autoBurn() external onlyDev onlyOnceEvery30Days {
        require(totalSupply > 69000000 * 10**decimals, "Total supply limit not reached");
        
        uint256 burnAmount = balances[address(this)] / 100; // 1% of the contract balance

        require(burnAmount > 0, "No tokens available for burning");

        totalSupply -= burnAmount;
        balances[address(this)] -= burnAmount;
        
        emit AutoBurn(burnAmount);

         // Update the last auto burn timestamp
        lastAutoBurnTimestamp = block.timestamp;
    }

    function enableStaking() external onlyDev {
        require(!stakingEnabled, "Staking is already enabled");
        stakingEnabled = true;
        emit StakeEnabled();
    }
        
    function stakeTokens(uint256 amount) external {
        require(stakingEnabled, "Staking is not enabled");
        require(amount > 0, "Invalid stake amount");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        // Calculate the maximum stake amount (1% of circulating supply)
        uint256 maxStakeAmount = (totalSupply * 1) / 100;

        require(amount <= maxStakeAmount, "Stake amount exceeds limit");

        uint256 releaseTimestamp = 0;
        //if user has a very very special nft level 6
        //stake instead of being 28 days becomes 21 days
        if (nftLevels[msg.sender] == 6) {
            releaseTimestamp = block.timestamp + stakeSuperSpecialLockDuration;
        } else {
            releaseTimestamp = block.timestamp + stakeLockDuration;
        }

        // Deduct the tokens from the sender's balance
        balances[msg.sender] -= amount;

        totalStakedAmount += amount;

        // Remove the staked tokens from circulation
        totalSupply -= amount;

        // Stake the tokens
        stakes[msg.sender] = Stake(amount, releaseTimestamp);

        emit Transfer(msg.sender, address(0), amount);
        emit StakeTokens(msg.sender, amount, releaseTimestamp);
    }

    function unstakeRewardsOnly() external {
        Stake storage stake = stakes[msg.sender];
        require(stake.amount > 0, "No stakes found");
        require(block.timestamp >= stake.releaseTimestamp, "Stake is still locked");

        uint256 reward = stake.amount * stakeRewardPercent / 100;

        // Apply NFT level boost if available
        if (nftLevels[msg.sender] > 0 && nftLevels[msg.sender] <= 5) {
            uint256 boostPercentage = nftLevels[msg.sender] * 1; // 1% increase per NFT level
            uint256 boostReward = stake.amount * boostPercentage / 100;
            reward += boostReward;
        }

        if (nftLevels[msg.sender] == 6) {
            uint256 boostPercentage = 7; // 7% increase per NFT level
            uint256 boostReward = reward * boostPercentage / 100;
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

        // Add the rewards to the sender's balance
        balances[msg.sender] += reward;

        // Reset the release timestamp for the stake
        if (nftLevels[msg.sender] == 6) {
            stake.releaseTimestamp = block.timestamp + stakeSuperSpecialLockDuration;
        } else {
            stake.releaseTimestamp = block.timestamp + stakeLockDuration;
        }

        emit RewardAdded(msg.sender, reward);
    }

    function compoundRewards() external {
        Stake storage stake = stakes[msg.sender];
        require(stake.amount > 0, "No stakes found");
        require(block.timestamp >= stake.releaseTimestamp, "Stake is still locked");

        uint256 reward = stake.amount * stakeRewardPercent / 100;

        // Apply NFT level boost if available
        if (nftLevels[msg.sender] > 0 && nftLevels[msg.sender] <= 5) {
            uint256 boostPercentage = nftLevels[msg.sender] * 1; // 1% increase per NFT level
            uint256 boostReward = reward * boostPercentage / 100;
            reward += boostReward;
        }

        if (nftLevels[msg.sender] == 6) {
            uint256 boostPercentage = 7; // 7% increase per NFT level
            uint256 boostReward = reward * boostPercentage / 100;
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

        // Remove the compounded rewards from circulation
        totalSupply -= reward;
        totalStakedAmount += reward;

        // Add the rewards to the sender's stake
        stake.amount += reward;

        // Reset the release timestamp for the stake
        if (nftLevels[msg.sender] == 6) {
            stake.releaseTimestamp = block.timestamp + stakeSuperSpecialLockDuration;
        } else {
            stake.releaseTimestamp = block.timestamp + stakeLockDuration;
        }

        emit CompoundRewards(msg.sender, reward);
        emit Transfer(address(0), address(this), reward);
    }

    function unstakeTokens() external {
        Stake memory stake = stakes[msg.sender];
        require(stake.amount > 0, "No stakes found");
        require(block.timestamp >= stake.releaseTimestamp, "Stake is still locked");

        uint256 reward = stake.amount * stakeRewardPercent / 100;
        uint256 burnAmount = stake.amount * stakeBurnPercent / 100;
        uint256 unstakeAmount = stake.amount;

        // Deduct the burn amount from the rewards
        reward -= burnAmount;

        // Apply NFT level boost if available
        if (nftLevels[msg.sender] > 0 && nftLevels[msg.sender] <= 5) {
            uint256 boostPercentage = nftLevels[msg.sender] * 1; // 1% increase per NFT level
            uint256 boostReward = unstakeAmount * boostPercentage / 100;
            reward += boostReward;
        }

        if (nftLevels[msg.sender] == 6) {
            uint256 boostPercentage = 7; // 7% increase per NFT level
            uint256 boostReward = reward * boostPercentage / 100;
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
        totalStakedAmount -= stake.amount;

        // Burn the tax
        totalSupply -= burnAmount;

        // Reset the stake
        delete stakes[msg.sender];

        emit UnstakeTokens(msg.sender, stake.amount);
        emit Transfer(address(0), msg.sender, unstakeAmount);
        emit RewardAdded(msg.sender, reward);
        emit Burn(address(this), burnAmount);
    }

    function forceUnstakeTokens() external {
        Stake memory stake = stakes[msg.sender];
        require(stake.amount > 0, "No stakes found");

        uint256 unstakeAmount = stake.amount;
        uint256 burnAmount = unstakeAmount * 30 / 100; // 30% burn tax

        // Deduct the burn amount from the staked amount
        unstakeAmount -= burnAmount;

        // Burn the tax
        totalSupply -= burnAmount;

        // Add the staked tokens back to circulation
        totalSupply += unstakeAmount;

        // Transfer the unstaked tokens to the sender
        balances[msg.sender] += unstakeAmount;

        // Reset the stake
        delete stakes[msg.sender];

        emit UnstakeTokens(msg.sender, stake.amount);
        emit Transfer(address(0), msg.sender, unstakeAmount);
        emit ForceUnstakeBurn(address(this), burnAmount);
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

    function setNFTContract(address _nftContract) external onlyDev {
        nftContract = _nftContract;
    }

    function setNFTLevel(address account, uint256 level) external onlyNFTContract {
        // Set the NFT level for a specific address
        require(level >= 0 && level <= 6, "Invalid NFT level");
        nftLevels[account] = level;
    }

    function clearNFTLevel(address account) external onlyNFTContract {
        // Check if the address has an existing NFT level
        require(nftLevels[account] != 0, "No NFT level set for the address");

        // Clear the NFT level for the specified address
        delete nftLevels[account];
    }    

    function burnTokens(uint256 amount) external {
        require(amount > 0, "Invalid amount");
        require(amount <= balances[msg.sender], "Insufficient balance");

        balances[msg.sender] -= amount;
        totalSupply -= amount;

        emit Transfer(msg.sender, address(0), amount);
        emit Burn(msg.sender, amount);
    }

    function getTotalStakedAmount() external view returns (uint256) {
        return totalStakedAmount;
    }

    function createPair() external onlyDev {
        require(uniswapPair == address(0), "Pair already created");

        // Create the Uniswap V2 Factory instance
        IUniswapV2Factory uniswapFactory = IUniswapV2Factory(UNISWAP_FACTORY);

        // Create the pair using the Uniswap V2 Factory
        uniswapPair = uniswapFactory.createPair(address(this), MATIC_ADDRESS);
    }

    function addLiquidity(uint256 tokenAmount, uint256 maticAmount) external onlyDev() {
        // Approve the router to spend your token
        approveInternal(address(uniswapRouter), tokenAmount);

        // Add liquidity to the Uniswap pair
        uniswapRouter.addLiquidityETH{value: maticAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    function removeLiquidity(uint256 lpAmount) external onlyDev {
        // Get the Uniswap pair address
        address pairAddress = IUniswapV2Factory(uniswapRouter.factory()).getPair(address(this), uniswapRouter.WETH());

        // Approve the router to spend your LP tokens
        IUniswapV2Pair(pairAddress).approve(address(uniswapRouter), lpAmount);

        // Remove liquidity from the Uniswap pair
        uniswapRouter.removeLiquidityETHSupportingFeeOnTransferTokens(
            address(this),
            lpAmount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    function getLPTokenBalance() external view onlyDev returns (uint256) {
        // Get the Uniswap pair address
        address pairAddress = IUniswapV2Factory(uniswapRouter.factory()).getPair(address(this), uniswapRouter.WETH());

        // Get the LP token balance
        return IERC20(pairAddress).balanceOf(address(this));
    }
}