// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Owned.sol";


contract StakingRewards is Owned{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== CONSTRUCTOR ========== */
    constructor() Owned(msg.sender) {}

    /* ========== Staking Pools ========== */
    struct Pool{
        IERC20 rewardsToken;
        IERC20 stakingToken;
        uint256 periodFinish;
        uint256 rewardRate;
        uint256 rewardsDuration;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
        uint256 totalSupply;
    } 
    uint256 public totalPools;
    mapping (uint256 => Pool) private pools;
    function getTotalPools() external view returns (uint256) {
        return totalPools;
    }
    function getPools(uint256 id) external view returns (Pool memory) {
        return pools[id];
    }
    function addPool(address _rewardsToken,address _stakingToken,uint256 _rewardDuration) external onlyOwner{
        pools[totalPools].rewardsToken = IERC20(_rewardsToken);
        pools[totalPools].stakingToken = IERC20(_stakingToken);
        pools[totalPools].rewardsDuration = _rewardDuration;
        totalPools++;
    } 


    /* ========== USER STATE VARIABLES ========== */
    mapping (uint256 => mapping(address => uint256)) public userRewardPerTokenPaid;
    mapping (uint256 => mapping(address => uint256)) public rewards;
    mapping (uint256 => mapping(address => uint256)) private userBalances;

    /* ========== VIEWS ========== */
    function totalSupply(uint256 id) external view returns (uint256) {
        return pools[id].totalSupply;
    }
    function balanceOf(uint256 id,address account) external view returns (uint256) {
        return userBalances[id][account];
    }
    function lastTimeRewardApplicable(uint256 id) public view returns (uint256) {
        return block.timestamp < pools[id].periodFinish ? block.timestamp : pools[id].periodFinish;
    }
    function rewardPerToken(uint256 id) public view returns (uint256) {
        if (pools[id].totalSupply == 0) {
            return pools[id].rewardPerTokenStored;
        }
        return
        pools[id].rewardPerTokenStored.add(
            lastTimeRewardApplicable(id).sub(pools[id].lastUpdateTime).mul(pools[id].rewardRate).mul(1e18).div(pools[id].totalSupply)
        );
    }
    function earned(uint256 id,address account) public view returns (uint256) {
        return userBalances[id][account].mul(rewardPerToken(id).sub(userRewardPerTokenPaid[id][account])).div(1e18).add(rewards[id][account]);
    }
    function getRewardForDuration(uint256 id) external view returns (uint256) {
        return pools[id].rewardRate.mul(pools[id].rewardsDuration);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    function stake(uint256 id,uint256 amount) external updateReward(id,msg.sender) {
        require(amount > 0, "Cannot stake 0");
        
        pools[id].totalSupply = pools[id].totalSupply.add(amount);
        userBalances[id][msg.sender] = userBalances[id][msg.sender].add(amount);
        pools[id].stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(id,msg.sender, amount);
    }
    function withdraw(uint256 id,uint256 amount) public updateReward(id,msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        pools[id].totalSupply = pools[id].totalSupply.sub(amount);
        userBalances[id][msg.sender] = userBalances[id][msg.sender].sub(amount);
        pools[id].stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(id,msg.sender, amount);
    }
    function getReward(uint256 id) public updateReward(id,msg.sender) {
        uint256 reward = rewards[id][msg.sender];
        if (reward > 0) {
            rewards[id][msg.sender] = 0;
            pools[id].rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(id,msg.sender, reward);
        }
    }
    function exit(uint256 id) external {
        withdraw(id,userBalances[id][msg.sender]);
        getReward(id);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */
    function notifyRewardAmount(uint256 id,uint256 reward) external updateReward(id,address(0)) onlyOwner{
        if (block.timestamp >= pools[id].periodFinish) {
            pools[id].rewardRate = reward.div(pools[id].rewardsDuration);
        } else {
            uint256 remaining = pools[id].periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(pools[id].rewardRate);
            pools[id].rewardRate = reward.add(leftover).div(pools[id].rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance = pools[id].rewardsToken.balanceOf(address(this));
        require(pools[id].rewardRate <= balance.div(pools[id].rewardsDuration), "Provided reward too high");

        pools[id].lastUpdateTime = block.timestamp;
        pools[id].periodFinish = block.timestamp.add(pools[id].rewardsDuration);
        emit RewardAdded(id,reward);
    }
    // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
    function recoverERC20(uint256 id,address tokenAddress, uint256 tokenAmount) external onlyOwner{
        require(tokenAddress != address(pools[id].stakingToken), "Cannot withdraw the staking token");
        IERC20(tokenAddress).safeTransfer(owner, tokenAmount);
        emit Recovered(id,tokenAddress, tokenAmount);
    }
    function setRewardsDuration(uint256 id,uint256 _rewardsDuration) external onlyOwner{
        require(
            block.timestamp > pools[id].periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        pools[id].rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(id,pools[id].rewardsDuration);
    }

    /* ========== MODIFIERS ========== */
    modifier updateReward(uint256 id,address account) {
        pools[id].rewardPerTokenStored = rewardPerToken(id);
        pools[id].lastUpdateTime = lastTimeRewardApplicable(id);
        if (account != address(0)) {
            rewards[id][account] = earned(id,account);
            userRewardPerTokenPaid[id][account] = pools[id].rewardPerTokenStored;
        }
        _;
    }

    /* ========== EVENTS ========== */
    event RewardAdded(uint256 id,uint256 reward);
    event Staked(uint256 id,address indexed user, uint256 amount);
    event Withdrawn(uint256 id,address indexed user, uint256 amount);
    event RewardPaid(uint256 id,address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 id,uint256 newDuration);
    event Recovered(uint256 id,address token, uint256 amount);
}