// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenStaking_testing {
    struct User {
        uint256[10] amountStaked; // Array to store the amount staked by the user in each pool
        uint256[10] stakingPool; // Array to store the pool number in which the user has staked
        uint256[10] rewardPoints; // Array to store the accumulated reward points of the user in each pool
        uint256[10] unclaimedReward; // Array to store the unclaimed reward of the user in each pool
        uint256[10] lastClaimedTimestamp; // Array to store the timestamp of the last reward claim of the user in each pool
        uint256[10] lastDepositTimestamp; // Array to store the timestamp of the last deposit made by the user in each pool
    }
    mapping(address => User) private users;

    struct StakingPool {
        uint256 apr; // Annual percentage rate of the pool
        uint256 stakeTime; // Duration of the stake in seconds
        uint256 penaltyPercentage; // Penalty percentage applied if unstaked before lock time
        uint256 claimTime; // Time interval between reward claims in seconds
        uint256 stakeMin; // Minimum amount that can be staked in the pool
        uint256 stakeMax; // Maximum amount that can be staked in the pool
        uint256 stakeLimit; // Maximum total amount that can be staked in the pool
        uint256 stakedNow; // Total amount currently staked in the pool
        uint256 totalStaked; // Total amount staked in the pool since its creation
        uint256 totalRewardClaimed; // Total reward claimed from the pool
        uint256 rewardPool; // Total reward pool of the pool
        uint256 undistributedReward; // Undistributed reward remaining in the pool
    }
        //Staking Pool
        StakingPool[5] public stakingPools; // Array to store the staking pools
        uint256 public registerTime; // Start time of the staking registration period
        uint256 public endRegisterTime; // End time of the staking registration period
        uint256 public immutable deployTime; // Deployment time of the contract
        uint256 public totalReward; // Total reward across all staking pools
        address public immutable factoryAddress; // Address of the factory contract
        address public immutable stakeToken; // Address of the staking token
    modifier onlyFactory() {
        require(factoryAddress == msg.sender, "only factory can Interact");
        _;
    }

    constructor(
        address _stakeToken,
        uint256 _registerTime,
        uint256 _endRegisterTime,
        uint256[] memory _apr,
        uint256[] memory _stakeTime,
        uint256[] memory _penaltyPercentage,
        uint256[] memory _claimTime,
        uint256[] memory _stakeMin,
        uint256[] memory _stakeMax,
        uint256[] memory _stakeLimit
    ) {
    // Check that all arrays have the same length
        require(
            _apr.length == _stakeTime.length &&
            _stakeTime.length == _penaltyPercentage.length &&
            _penaltyPercentage.length == _claimTime.length &&
            _claimTime.length == _stakeMin.length &&
            _stakeMin.length == _stakeMax.length &&
            _stakeMax.length == _stakeLimit.length,
            "require same length of array"
        );

        // Check the number of staking pools does not exceed the maximum limit
        require(_apr.length <= 5, "Maximum 5 staking pools allowed");

        // Check that the registration time and end registration time fall within a valid range
        require(
            block.timestamp + 60 <= _registerTime && _registerTime <= block.timestamp + 30 * 60,
            "register time and end time must be in the range of 1 and 30 days from now!"
        );

        // Check that the end registration time falls within a valid range based on the registration time
        require(
            _registerTime + 60 * 2 <= _endRegisterTime && _endRegisterTime <= _registerTime + 10 * 60,
            "end Register time must be in the range of 2 and 10 days from the register Time!"
            );

        stakeToken = _stakeToken;
        factoryAddress = msg.sender;
        deployTime = block.timestamp;
        registerTime = _registerTime;
        endRegisterTime = _endRegisterTime;

        // Iterate over the arrays to create staking pools
        for (uint256 i = 0; i < _apr.length; i++) {
            // Calculate the initial reward pool based on APR, stake limit, stake time, and scaling factors
            uint256 _rewardPool = _apr[i] * _stakeLimit[i] * _stakeTime[i] / (365*60*10000);

            // Create a new StakingPool struct with the provided parameters
            StakingPool memory pool = StakingPool({
                apr: _apr[i],
                stakeTime: _stakeTime[i],
                penaltyPercentage: _penaltyPercentage[i],
                claimTime: _claimTime[i],
                stakeMin: _stakeMin[i],
                stakeMax: _stakeMax[i],
                stakeLimit: _stakeLimit[i],
                stakedNow: 0,
                totalStaked: 0,
                totalRewardClaimed: 0,
                rewardPool: _rewardPool,
                undistributedReward: _rewardPool
            });

            // Add the new pool to the stakingPools array
            stakingPools[i] = pool;

            // Increase the total reward by the reward pool of the current pool
            totalReward += stakingPools[i].rewardPool;
        }
    }

    function changeStakeInfo(
        uint256 _registerTime,
        uint256 _endRegisterTime,
        uint256[] memory _apr,
        uint256[] memory _stakeTime,
        uint256[] memory _penaltyPercentage,
        uint256[] memory _claimTime,
        uint256[] memory _stakeMin,
        uint256[] memory _stakeMax,
        uint256[] memory _stakeLimit
    ) external onlyFactory {
        // Check that all arrays have the same length
        require(
            _apr.length == _stakeTime.length &&
            _stakeTime.length == _penaltyPercentage.length &&
            _penaltyPercentage.length == _claimTime.length &&
            _claimTime.length == _stakeMin.length &&
            _stakeMin.length == _stakeMax.length &&
            _stakeMax.length == _stakeLimit.length,
            "Require same length of array"
        );

        // Check the number of staking pools does not exceed the maximum limit
        require(_apr.length <= 5, "Maximum 10 staking pools allowed");

        // Check that the registration time and end registration time fall within valid ranges
        require(
            block.timestamp + 60 <= _registerTime && _registerTime <= deployTime + 30 * 60,
            "register time must be in the range of 1 and 30 days from now!"
        );
        require(
            _registerTime + 60 * 2 <= _endRegisterTime && _endRegisterTime <= _registerTime + 10 * 60,
            "end Register time must be in the range of 2 and 10 days from the register Time!"
        );

        // Update registration and end registration times
        registerTime = _registerTime;
        endRegisterTime = _endRegisterTime;

        // Clear existing staking pools
        uint256 length = stakingPools.length;
        for (uint256 i = 0; i < length; i++) {
            delete stakingPools[i];
        }

        // Reset totalReward to zero and store the previous totalReward
        uint256 prevTotalReward = totalReward;
        totalReward = 0;

        // Create new staking pools
        for (uint256 i = 0; i < _apr.length; i++) {
            // Calculate the reward pool for the new staking pool based on the provided parameters
            uint256 _rewardPool = _apr[i] * _stakeLimit[i] * _stakeTime[i] / (365*60*10000);

            // Create a new StakingPool struct with the provided parameters
            StakingPool memory pool = StakingPool({
                apr: _apr[i],
                stakeTime: _stakeTime[i],
                penaltyPercentage: _penaltyPercentage[i],
                claimTime: _claimTime[i],
                stakeMin: _stakeMin[i],
                stakeMax: _stakeMax[i],
                stakeLimit: _stakeLimit[i],
                stakedNow: 0,
                totalStaked: 0,
                totalRewardClaimed: 0,
                rewardPool: _rewardPool,
                undistributedReward: _rewardPool
            });

            // Add the new pool to the stakingPools array
            stakingPools[i] = pool;

            // Increase the total reward by the reward pool of the current pool
            totalReward += pool.rewardPool;
        }

        // If the previous totalReward is greater than the current totalReward, approve the difference amount
        if (prevTotalReward > totalReward) {
            require(IERC20(stakeToken).approve(factoryAddress, prevTotalReward - totalReward));
        }
    }

    function stakeInfo(address _user) public view returns (User memory) {
        // Retrieve the User struct associated with the given user address
        User storage user = users[_user];
        return user;
    }

    function checkReward(uint256 _poolNumber, address _user) public view returns (uint256) {
        // Retrieve the User struct associated with the given user address
        User storage user = users[_user];

        // Calculate the time elapsed since the last claimed timestamp for the specified pool
        uint256 timeElapsed = (block.timestamp - user.lastClaimedTimestamp[_poolNumber]);

        // Retrieve the reward rate (APR) for the specified pool
        uint256 rewardRate = stakingPools[user.stakingPool[_poolNumber]].apr;

        // Calculate the reward based on the staked amount, reward rate, time elapsed, and a conversion factor
        uint256 reward = user.amountStaked[_poolNumber] * rewardRate * timeElapsed * (365*60*10000);

        // Add any unclaimed reward to the calculated reward
        reward += user.unclaimedReward[_poolNumber];

        // If the calculated reward exceeds the user's reward points, limit it to the reward points
        if (reward >= user.rewardPoints[_poolNumber]) {
            reward = user.rewardPoints[_poolNumber];
        }
        return reward;
    }

    function calculateRewardPoints(uint256 _poolNumber, bool _unstake, address _user) public view returns (uint256) {
        // Retrieve the User struct associated with the given user address
        User storage user = users[_user];

        // Calculate the time elapsed since the last claimed timestamp for the specified pool
        uint256 timeElapsed = (block.timestamp - user.lastClaimedTimestamp[_poolNumber]);

        // Retrieve the reward rate (APR) for the specified pool
        uint256 rewardRate = stakingPools[user.stakingPool[_poolNumber]].apr;

        // Calculate the reward based on the staked amount, reward rate, time elapsed, and a conversion factor
        uint256 reward = user.amountStaked[_poolNumber] * rewardRate * timeElapsed / (365*60*10000);

        // Add any unclaimed reward to the calculated reward
        reward += user.unclaimedReward[_poolNumber];

        // If it's not an unstake calculation, calculate additional rewards based on the claim time and adjust the reward
        if (!_unstake) {
            uint256 timeReward = user.amountStaked[_poolNumber] * rewardRate * stakingPools[user.stakingPool[_poolNumber]].claimTime / (365*60*10000);
            uint256 rewardCount = reward / timeReward;
            reward = timeReward * rewardCount;
        }

        // If the calculated reward exceeds the user's reward points, limit it to the reward points
        if (reward >= user.rewardPoints[_poolNumber]) {
            reward = user.rewardPoints[_poolNumber];
        }
    return reward;
    }


    function stake(uint256 _amount, uint256 _stakingPool) external {
        // Check if the registration period is active
        require(block.timestamp <= endRegisterTime && registerTime <= block.timestamp, "Registration not started or already ended!");

        // Retrieve the User struct associated with the sender's address
        User storage user = users[msg.sender];

        uint256 _poolNumber;
        // Find an available pool slot for the user
        for (uint256 i = 0; i < 10; i++) {
            if (user.amountStaked[i] == 0) {
                _poolNumber = i;
                break;
            }
        }

        // Check if the specified staking pool is initialized
        require(_stakingPool < stakingPools.length, "Pool not initialized");

        // Check if the staked amount is within the allowed range
        require(_amount >= stakingPools[_stakingPool].stakeMin, "Amount must be greater than the minimum staking amount");
        require(_amount <= stakingPools[_stakingPool].stakeMax, "Amount must be lower than the maximum staking amount");

        // Update total staked amount and staked amount for the specified pool
        require(stakingPools[_stakingPool].totalStaked + _amount <= stakingPools[_stakingPool].stakeLimit, "Exceeded staking limit, please lower your staking amount");
        stakingPools[_stakingPool].totalStaked += _amount;
        stakingPools[_stakingPool].stakedNow += _amount;

        // Transfer tokens from the user to the contract
        require(IERC20(stakeToken).transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

        // Add the staked amount to the user's balance and update timestamps
        user.stakingPool[_poolNumber] = _stakingPool;
        user.amountStaked[_poolNumber] += _amount;
        user.lastDepositTimestamp[_poolNumber] = block.timestamp;
        user.lastClaimedTimestamp[_poolNumber] = block.timestamp;

        // Calculate reward points based on the staked amount, APR, and stake time
        uint256 rewardPoints = (_amount * stakingPools[_stakingPool].apr * stakingPools[_stakingPool].stakeTime) / (365*60*10000);
        user.rewardPoints[_poolNumber] += rewardPoints;
        user.unclaimedReward[_poolNumber] = 0;
        stakingPools[_stakingPool].undistributedReward -= rewardPoints;
    }

    function unstake(uint256 _poolNumber) external {
        // Retrieve the User struct associated with the sender's address
        User storage user = users[msg.sender];
        uint256 _stakingPool = user.stakingPool[_poolNumber];

        // Check if the user has a staked balance
        require(user.amountStaked[_poolNumber] > 0, "No staked balance");

        // Calculate penalty if unstaked before the lock time
        uint256 penalty = 0;
        if (block.timestamp <= user.lastDepositTimestamp[_poolNumber] + stakingPools[_stakingPool].stakeTime) {
            penalty = (user.amountStaked[_poolNumber] * stakingPools[_stakingPool].penaltyPercentage) / 10000;
        }

        // Calculate reward points and update total reward points for the staking pool
        uint256 rewardPoints = calculateRewardPoints(_poolNumber, true, msg.sender);
        stakingPools[_stakingPool].totalRewardClaimed += rewardPoints;
        stakingPools[_stakingPool].undistributedReward += user.rewardPoints[_poolNumber] - rewardPoints;
        user.rewardPoints[_poolNumber] = 0;

        // Calculate the amount to unstake (minus penalty) and transfer it to the user
        uint256 amountToUnstake = user.amountStaked[_poolNumber] - penalty;
        stakingPools[_stakingPool].stakedNow -= user.amountStaked[_poolNumber];
        user.amountStaked[_poolNumber] = 0;

        uint256 amountClaim = amountToUnstake + rewardPoints;
        require(IERC20(stakeToken).transfer(msg.sender, amountClaim), "Token transfer failed");

        // Transfer penalty tokens to the contract owner
        if (penalty > 0) {
            require(IERC20(stakeToken).transfer(address(this), penalty), "Token transfer failed");
            stakingPools[_stakingPool].undistributedReward += penalty;
        }

        // Update the user's staking pool and timestamps
        user.stakingPool[_poolNumber] = 0;
        user.lastClaimedTimestamp[_poolNumber] = 0;
        user.lastDepositTimestamp[_poolNumber] = 0;
    }


    function claimReward(uint256 _poolNumber) external {
        // Retrieve the User struct associated with the sender's address
        User storage user = users[msg.sender];
        uint256 _stakingPool = user.stakingPool[_poolNumber];

        // Check if the user has a staked balance and available reward points
        require(user.amountStaked[_poolNumber] > 0, "No staked balance");
        require(user.rewardPoints[_poolNumber] > 0, "No available rewards, please unstake your tokens");

        // Calculate the available reward and limited reward based on the staking pool and user's reward points
        uint256 totalRewardAvailable = checkReward(_poolNumber, msg.sender);
        uint256 rewardLimited = calculateRewardPoints(_poolNumber, false, msg.sender);
        uint256 rewardRate = stakingPools[user.stakingPool[_poolNumber]].apr;
        uint256 periodReward = (user.amountStaked[_poolNumber] * rewardRate * stakingPools[user.stakingPool[_poolNumber]].claimTime) / (365*60*10000);
        uint256 allocatedReward;

        // Check if it's within the claim hour or after the claim period
        if ((block.timestamp - user.lastDepositTimestamp[_poolNumber]) <= (stakingPools[user.stakingPool[_poolNumber]].stakeTime - stakingPools[user.stakingPool[_poolNumber]].claimTime)) {
            require(rewardLimited >= periodReward, "Please wait until the claim hour");
            allocatedReward = rewardLimited;
        } else {
            allocatedReward = totalRewardAvailable;
            if (rewardLimited >= periodReward) {
                allocatedReward = rewardLimited;
            } else {
                require(allocatedReward == user.rewardPoints[_poolNumber], "Please wait until the time ends to claim your last staked reward");
        }
    }

    // Update total reward claimed, user's reward points, and unclaimed rewards
    stakingPools[_stakingPool].totalRewardClaimed += allocatedReward;
    user.rewardPoints[_poolNumber] -= allocatedReward;
    user.unclaimedReward[_poolNumber] = totalRewardAvailable - allocatedReward;

    // Transfer the allocated reward tokens to the user
    require(IERC20(stakeToken).transfer(msg.sender, allocatedReward), "Token transfer failed");

    // Update the last claimed timestamp
    user.lastClaimedTimestamp[_poolNumber] = block.timestamp;
}

    function withdrawUndistributedReward() external onlyFactory() returns (uint256) {
        uint256 undistributedReward;

        // Iterate over the staking pools to calculate the total undistributed reward
        for (uint256 i = 0; i <= 5; i++) {
            if (stakingPools[i].rewardPool == 0) {
                break;
            }
            undistributedReward += stakingPools[i].undistributedReward;
        }

        // Approve the transfer of undistributed reward tokens to the factory address
        require(IERC20(stakeToken).approve(factoryAddress, undistributedReward));

    return undistributedReward;
    }
}