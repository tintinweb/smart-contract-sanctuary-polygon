/**
 *Submitted for verification at polygonscan.com on 2023-03-09
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract BrainStormersStaking {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public lastUpdateTime;
    mapping(address => uint256) public rewards;

    uint256 public totalStaked;
    uint256 public rewardRate;
    uint256 public minWithdrawalAmount;
    address public stakingToken;
    address public rewardToken;
    address public projectOwner;

    event Staked(address indexed staker, uint256 amount, uint256 timestamp);
    event Withdrawn(address indexed staker, uint256 amount, uint256 timestamp);
    event RewardClaimed(
        address indexed staker,
        uint256 amount,
        uint256 timestamp
    );

    error AMOUNT_STAKED_SHOULD_NOT_BE_ZERO();
    error ONLY_OWNER_CAN_CALL_THIS_FUNCTION();
    error BAL_IS_LESS_THAN_MINIMAL();
    error NO_BAL_TO_CLAIM();

    constructor(
        uint256 _rewardRate,
        uint256 _minWithdrawalAmount,
        address _projectOwner,
        address _stakingToken,
        address _rewardToken
    ) {
        rewardRate = _rewardRate;
        minWithdrawalAmount = _minWithdrawalAmount;
        stakingToken = _stakingToken;
        projectOwner = _projectOwner;
        rewardToken = _rewardToken;
    }

    function stake(uint256 _amount) external {
        if (_amount == 0) revert AMOUNT_STAKED_SHOULD_NOT_BE_ZERO();
        uint256 existingBalance = balances[msg.sender];
        if (existingBalance > 0) {
            uint256 reward = getReward(msg.sender);
            rewards[msg.sender] = reward;
        } else {
            lastUpdateTime[msg.sender] = block.timestamp;
        }

        IERC20(stakingToken).transferFrom(msg.sender, address(this), _amount);
        balances[msg.sender] += _amount;
        totalStaked += _amount;

        emit Staked(msg.sender, _amount, block.timestamp);
    }

    function withdraw() external {
        uint256 amount = balances[msg.sender];
        if (amount == 0) revert NO_BAL_TO_CLAIM();

        balances[msg.sender] = 0;
        lastUpdateTime[msg.sender] = 0;
        rewards[msg.sender] = 0;
        totalStaked -= amount;

        IERC20(stakingToken).transfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount, block.timestamp);
    }

    function claimReward() external {
        uint256 reward = getReward(msg.sender);
        if (reward < minWithdrawalAmount) revert BAL_IS_LESS_THAN_MINIMAL();

        rewards[msg.sender] = 0;
        lastUpdateTime[msg.sender] = block.timestamp;
        IERC20(rewardToken).transfer(msg.sender, reward);

        emit RewardClaimed(msg.sender, reward, block.timestamp);
    }

    function getReward(address _address) public view returns (uint256) {
        uint256 timeSinceLastUpdate = block.timestamp -
            lastUpdateTime[_address];
        uint256 reward = (balances[_address] *
            timeSinceLastUpdate *
            rewardRate) / 1e18;

        return rewards[_address] + reward;
    }

    function updateRewardRate(uint256 _newRewardRate) external {
        if (msg.sender != projectOwner)
            revert ONLY_OWNER_CAN_CALL_THIS_FUNCTION();
        rewardRate = _newRewardRate;
    }

    function getStakingToken() external view returns (address) {
        return stakingToken;
    }

    function getRewardToken() external view returns (address) {
        return rewardToken;
    }
}