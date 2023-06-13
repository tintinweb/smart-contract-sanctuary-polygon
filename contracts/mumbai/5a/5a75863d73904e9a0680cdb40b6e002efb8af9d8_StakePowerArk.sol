//SPDX-License-Identifier: MIT

//stake token//
// Power Ark: https://goerli.etherscan.io/token/0x876f70195907B0C3491E9BCaE31EEC9D06901B90?a=0xe9b34e87386b5fa5e611c947730d88e773d2dbb0
// Reward Token//
// Power Ark 2.0: https://goerli.etherscan.io/token/0x51613223C559adcB03Fcf0002FC39a66624E8Cca?a=0xe9b34e87386b5fa5e611c947730d88e773d2dbb0


////////////// PROJECT OVERVIEW //////////////
// 1. We'll be relying on libraries to build our project
// 2. Importing Libraries
// 3. Create a Staking Contract
// 4. Create Reward Token and Stake Token

// Import Our Libraries
import "./Math.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./PoolManager.sol";

// Staking Token: 0x4a80d746D2142673DB0062bD6A510e35b9D8fcEd 
// Rewards Token: 0x56d80512C2Aa66e4599c509F45283657649f0EF0


pragma solidity ^0.8.0;

contract StakePowerArk  is ReentrancyGuard {

    using SafeERC20 for IERC20;
    using PoolManager for  PoolManager.PoolState;

    // declare the necessary variabless
    PoolManager.PoolState private _stake;

    uint256 private _totalStake;
    mapping (address => uint256) private _userRewardPerTokenPaid;
    mapping (address => uint256) private _rewards;
    mapping (address => uint256) private _balances;

    

    // inherit the ERC20 interface
    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardToken;

    // Build our constructor
    constructor (address _distributor, IERC20 stakingToken_, IERC20 rewardToken_, uint64 _duration) {
        _stake.distributor = uint160(_distributor);
        stakingToken = stakingToken_;
        rewardToken = rewardToken_;
        _stake.rewardsDuration = _duration * 1 days;
    }


    // Create Modifiers
    // 1. onlyDistributor
    modifier  onlyDistributor() {
        require(msg.sender == address(_stake.distributor), "Not Distributor");
        _;


    }
    // 2. updateRewards
    modifier updateRewards(address account) {
        _stake.updateReward(_totalStake);
        
        if(account != address(0)) {
            _rewards[account] = earned(account);
            _userRewardPerTokenPaid[account] = _stake.rewardPerTokenStored;
            _;
        }
    }



    // functions to read our contract
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

    function earned(address account) public view returns(uint256) {
        return _balances[account] * (_stake.rewardPerToken(_totalStake) - _userRewardPerTokenPaid[account]) / 1e18 + _rewards[account];
    }    
    // build our writeable functions
    /**
    stake|claim|withdraw|deposit|rewardstoken
    */
    function stake(uint256 amount) external payable nonReentrant updateRewards(msg.sender) {
        require (amount > 0,"Stake must be greater than 0");
        
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        _totalStake += amount;
        _balances[msg.sender] += amount;

        // Emit an Event
        emit Staked(msg.sender, amount);
    }

    function getReward() public payable nonReentrant updateRewards(msg.sender) {
        uint256 reward = _rewards[msg.sender];

        if (reward > 0)  {
            _rewards[msg.sender] = 0;
            rewardToken.safeTransfer(msg.sender, reward);

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
            stakingToken.safeTransfer(msg.sender, balance);
        }
        else {
            stakingToken.safeTransfer(msg.sender, balance);
            rewardToken.safeTransfer(msg.sender, reward);
        }

        emit Withdrawn(msg.sender, balance);
        emit RewardPaid(msg.sender, reward);
    }
    // create protected functions for reward distributor
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
    // emit some events
    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event DistributorUpdated(address indexed newDistributor);


}