//SPDX-License-Identifier: MIT

// OPHIR WORKSHOP 2
// Live Link: https://staking-ophir.vercel.app/

/// @title STAKEBOREDOM DECENTRALISED VOTING DAPP by Ophir Institute

///////////////// PROJECT RESOURCES ///////////////// 
// Contracts Verified at:
// Stake Contract https://mumbai.polygonscan.com/address/0x2eaab956079e8cd97947c2d39a47d5374c83df6b#code
// Stake Token (BoredPepe): https://mumbai.polygonscan.com/token/0xe2a28aac42cf71ba802fc6bb715189b0a89b348a#code
// Reward Token (HappyPepe): https://mumbai.polygonscan.com/token/0x1c2ab209995c1e2b45f67f85611bfeb2c6590538
/////////////////////////////////////////////////////


///////////////// PROJECT OVERVIEW /////////////////
// 1. Brainstorming on what Libraries to Use to Build our App: 
// ** Math/Address/SafeERC20/IERC20/Reentrancy
// 2. Import Libraries (2 methods)
// 3. Create and  Deploy a Stake Token (BoredPepe) and a Reward Token (Happy Pepe)
// 4. Build our Staking Contract
// 4a. StakingLibrary Tour
// 4b. Build our Main Contract
// 5. Lastly Deploy and verify our contracts {multi-file verification}
/////////////////////////////////////////////////////

///////////////// Import our Libraries /////////////////
// import "@openzeppelin/contracts/utils/math/Math.sol";
import "./Math.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./PoolManager.sol";

// Staking Token: 0x86786b72179AAdb67fE1Ba26D9C9d5e9A6f022FC
// Reward Token:  0x7f1b2adca6267ea30f9b209976a5e7b2d7d84b12

pragma solidity ^0.8.0;

contract StakeBoredom is ReentrancyGuard {

    using SafeERC20 for IERC20;
    using PoolManager for PoolManager.PoolState;

    // STEP 1: Declare the necessary Variables
    PoolManager.PoolState private _stake;

    uint256 private _totalStake; // Total amount of BPP Tokens Staked
    mapping (address => uint256) private _userRewardPerTokenPaid;
    mapping (address => uint256) private _rewards;
    mapping (address => uint256) private _balances;

    // STEP 2:  Inherit the ERC20 Interface
    IERC20 public immutable stakingToken; // CONSTANTS or immutable
    IERC20 public immutable rewardToken;


    // STEP 3: Build our Constructor
    constructor (address _distributor, IERC20 stakingToken_, IERC20 rewardToken_, uint64 _duration) {
        stakingToken = stakingToken_;
        rewardToken = rewardToken_;
        _stake.distributor = uint160(_distributor);
        _stake.rewardsDuration = _duration * 1 days;
    }

    ///////////////////// MODIFIERS /////////////////////
    // STEP 4: Create some modifiers
    // 1. onlyDistributor
    modifier onlyDistributor() {
        require(msg.sender == address(_stake.distributor), "Not Distributor");
        _;
    }

    // 2. updateRewards
    modifier updateRewards(address account) {
        _stake.updateReward(_totalStake);

        if(account != address(0)) {
            _rewards[account] = earned(account);
            _userRewardPerTokenPaid[account] = _stake.rewardPerTokenStored;
        }
        _;
    }
    /////////////////////////////////////////////////////

    ///////////////////// VIEWS /////////////////////
    // STEP 5:  Create some functions to read the contract
    function totalAmountStaked() external view returns(uint256) {
        return _totalStake;
    }

    function balanceOf(address account) external view returns(uint256) {
        return _balances[account];
    }

    function getOwner() external view returns (address)
    {
        return address(_stake.distributor);
    }

    function lastTimeRewardApplicable() external view returns (uint256)
    {
        return _stake.lastTimeRewardApplicable();
    }

    function rewardPerToken() external view returns (uint256)
    {
        return _stake.rewardPerToken(_totalStake);
    }

    function getRewardForDuration() external view returns (uint256)
    {
        return _stake.getRewardForDuration();
    }

    function earned(address account) public view returns(uint256) 
    {
        return _balances[account] * (_stake.rewardPerToken(_totalStake) - _userRewardPerTokenPaid[account]) / 1e18 + _rewards[account];
    }

    /////////////////// MUTATIONS //////////////////////////////
    // STEP 6: Build our writable functions
    /** 
    ** Stake | Claim - getReward | Withdraw - exit 
    */
    function stake(uint256 amount) external payable nonReentrant updateRewards(msg.sender){
        require (amount > 0, "Stake must be greater than zero");

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        _totalStake += amount;
        _balances[msg.sender] += amount;

        // Emit an Event
        emit Staked(msg.sender, amount);
    }

    function getReward() public payable nonReentrant updateRewards(msg.sender){
        uint256 reward = _rewards[msg.sender];

        if (reward > 0) {
            _rewards[msg.sender] = 0;
            rewardToken.safeTransfer(msg.sender, reward);
            // rewardToken.transfer(msg.sender, reward); // DON'T DO THIS!!!!!!!!!

            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() external payable nonReentrant {
        _stake.updateReward(_totalStake);

        uint256 balance = _balances[msg.sender];
        uint256 reward = earned(msg.sender);

        _userRewardPerTokenPaid[msg.sender] = _stake.rewardPerTokenStored;
        _balances[msg.sender] -= balance;
        _rewards[msg.sender] = 0;
        _totalStake -= balance;

        _stake.updateReward(_totalStake);

        if (stakingToken == rewardToken) {
            stakingToken.safeTransfer(msg.sender, balance + reward);
        }
        else {
            stakingToken.safeTransfer(msg.sender, balance);
            rewardToken.safeTransfer(msg.sender, reward);
        }

        emit Withdrawn(msg.sender, balance);
        emit RewardPaid(msg.sender, reward);
    }

    //////////////////// PROTECTED FUNCTIONS ///////////////////////////////////
    // STEP 7: Add protected functions for reward distributor
    function setDistributor(address newDistributor) external payable onlyDistributor
    {
        require(newDistributor != address(0), "Cannot set to zero addr");
        _stake.distributor = uint160(newDistributor);
    }

    function depositRewardTokens(uint256 amount) external payable onlyDistributor
    {
        require(amount > 0, "Must be greater than zero");

        rewardToken.safeTransferFrom(msg.sender, address(this), amount);

        notifyRewardAmount(amount);
    }

    function notifyRewardAmount(uint256 reward) public payable updateRewards(address(0)) onlyDistributor
    {
        uint256 duration = _stake.rewardsDuration;

        if (block.timestamp >= _stake.periodFinish) {
            _stake.rewardRate = reward / duration;
        } else {
            uint256 remaining = _stake.periodFinish - block.timestamp;
            uint256 leftover = remaining * _stake.rewardRate;
            _stake.rewardRate = (reward + leftover) / duration;
        }

        uint256 balance = rewardToken.balanceOf(address(this));

        if (rewardToken == stakingToken) {
            balance -= _totalStake;
        }

        require(_stake.rewardRate <= balance / duration, "Reward too high");

        _stake.lastUpdateTime = uint64(block.timestamp);
        _stake.periodFinish = uint64(block.timestamp + duration);

        emit RewardAdded(reward);
    }

    
    /* ========== EVENTS ========== */
    // STEP 8: Emit some events
    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event DistributorUpdated(address indexed newDistributor);

}