/**
 *Submitted for verification at polygonscan.com on 2023-06-02
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: AS/staking.sol



pragma solidity ^0.8.4;


contract TokenStaking {

    // The FIL token contract
    IERC20 public filToken;

    // Struct to represent a single staking commitment
    struct StakingCommitment {
        uint256 stakedAmount; // The amount of FIL tokens being staked
        uint256 stakingPeriod;  // The length of the staking period, in months
        uint256 startTime;  // The start time of the staking period, in seconds since epoch
        uint256 endTime;    // The end time of the staking period, in seconds since epoch
        bool isExtended;   // Whether the staking period has been extended 
    }

    // Array to hold all staking commitments .. 
    // The list of staking commitments made by users
    StakingCommitment[] public commitments;


    // Mapping to keep track of each user's staked amount
    // The amount of FIL tokens staked by each user
    mapping(address => uint256) public stakedAmounts;

    // The total amount of FIL tokens staked by all users
    uint256 public totalStakedAmount;

    // Reward percentages for fixed staking periods
    uint256 public constant REWARD_PERCENTAGE_12_MONTHS = 500; // 50/1000 = 5%
    uint256 public constant REWARD_PERCENTAGE_18_MONTHS = 850; // 85/1000 = 8.5%

    // Reward percentages for flexible staking periods
    uint256 public constant REWARD_PERCENTAGE_6_MONTHS = 250; // 25/1000 = 2.5%
    uint256 public constant REWARD_PERCENTAGE_8_MONTHS = 350; // 35/1000 = 3.5%

    // Extension reward percentage
    uint256 public constant EXTENSION_REWARD_PERCENTAGE = 100; // 10/1000 = 1%

    // Events
    event Staked(address indexed staker, uint256 amount, uint256 stakingPeriod);
    event ExtendedLockPeriod(address indexed staker, uint256 commitmentIndex);
    event Withdrawn(address indexed staker, uint256 stakedAmount, uint256 reward);

   
    // Constructor that sets the address of the token being staked
    // @dev Constructor for the Token Staking contract.
    // @param _filToken Address of the FIL token contract being staked.
    constructor(address _filToken) {
        filToken = IERC20(_filToken);
    }

    /// @notice Allows a user to stake a specified amount of FIL tokens for a specified period of time
    /// @param _amount  The amount of FIL tokens the user wishes to stake.
    /// @param _stakingPeriod  The duration of the staking period, which must be one of four values: 6, 8, 12, or 18.
    function stake(uint256 _amount, uint256 _stakingPeriod) public {
        // Validating staking period
        require(_stakingPeriod == 6 || _stakingPeriod == 8 || _stakingPeriod == 12 || _stakingPeriod == 18, "Invalid staking period");
        
        // Validating minimum stake
        require(_amount >= getMinimumStake(_stakingPeriod), "Amount below minimum stake for this staking period");

        // Getting the current time
        uint256 startTime = block.timestamp;
        // Calculating the end time of the staking period
        uint256 endTime = block.timestamp + (_stakingPeriod * 30 days);

        // Creating a new staking commitment
        StakingCommitment memory commitment = StakingCommitment(_amount, _stakingPeriod, startTime, endTime, false); 

        // Adding the commitment to the list of commitments
        commitments.push(commitment);   

        // Transferring the FIL tokens from the user to the staking contract
        filToken.transferFrom(msg.sender, address(this), _amount);  

        // Updating the user's staked amount
        stakedAmounts[msg.sender] += _amount;   

        // Updating the total staked amount
        totalStakedAmount += _amount;   

        // Emitting a Staked event to indicate that the tokens have been staked for a period of time
        emit Staked(msg.sender, _amount, _stakingPeriod);

    }

    /// @notice Allows a user to extend the lock period of a staking commitment by 3 months
    /// @param _commitmentIndex The index of the commitment to extend
    function extendLockPeriod(uint256 _commitmentIndex) public {
        // Validating commitment index
        require(_commitmentIndex >= 0 && _commitmentIndex < commitments.length, "Invalid commitment index");
        // Validating commitment end time
        require(commitments[_commitmentIndex].endTime <= block.timestamp, "Cannot extend lock period before initial staking period ends");
        // Validating that commitment has not already been extended
        require(!commitments[_commitmentIndex].isExtended, "Commitment already extended");

        // Marking the commitment as extended
        commitments[_commitmentIndex].isExtended = true;

        // Extending the staking period by 3 months
        commitments[_commitmentIndex].endTime += (3 * 30 days);

        // Updating the user's staked amount
        stakedAmounts[msg.sender] += commitments[_commitmentIndex].stakedAmount;

        // Updating the total staked amount
        totalStakedAmount += commitments[_commitmentIndex].stakedAmount;

        // Transferring the FIL tokens from the user to the staking contract
        filToken.transferFrom(msg.sender, address(this), commitments[_commitmentIndex].stakedAmount);

        // Emitting an event to indicate that the lock period has been extended
        emit ExtendedLockPeriod(msg.sender, _commitmentIndex);

    }


    /// @notice Allows a user to withdraw their staked tokens and earned rewards
    /// @param _commitmentIndex The index of the commitment to withdraw from
    function withdraw(uint256 _commitmentIndex) public {
        // Validating commitment index
        require(_commitmentIndex >= 0 && _commitmentIndex < commitments.length, "Invalid commitment index");
        // Validating commitment end time
        require(block.timestamp >= commitments[_commitmentIndex].endTime, "Cannot withdraw before staking period ends");

        // Getting the staked amount of the commitment
        uint256 stakedAmount = commitments[_commitmentIndex].stakedAmount;

        // Calculating the reward amount for the commitment
        uint256 reward = calculateReward(_commitmentIndex);

        // Removing the commitment from the list
        commitments[_commitmentIndex] = commitments[commitments.length - 1];     
        commitments.pop();

        // Updating the user's staked amount
        stakedAmounts[msg.sender] -= stakedAmount;

        // Updating the total staked amount
        totalStakedAmount -= stakedAmount;

        // Transferring the staked amount and reward back to the user
        filToken.transfer(msg.sender, stakedAmount + reward);

        // Emitting an event to notify listeners that a withdrawal has been made
        emit Withdrawn(msg.sender, stakedAmount, reward);
    }

    
    /// @notice Calculates the reward for a given staking commitment
    /// @dev This function is read-only, so it does not modify the contract state
    /// @param _commitmentIndex The index of the commitment to calculate the reward for
    /// @return A uint256 value representing the reward for the given commitment
    function calculateReward(uint256 _commitmentIndex) public view returns (uint256) {
        // Validating commitment index
        require(_commitmentIndex >= 0 && _commitmentIndex < commitments.length, "Invalid commitment index");

        // Getting the staked amount of the commitment
        uint256 stakedAmount = commitments[_commitmentIndex].stakedAmount;

        // Getting the staking period of the commitment
        uint256 stakingPeriod = commitments[_commitmentIndex].stakingPeriod;
        
        // Selecting the reward percentage based on the staking period
        uint256 rewardPercentage;
        
        if (stakingPeriod == 6) {
            rewardPercentage = REWARD_PERCENTAGE_6_MONTHS;
        } else if (stakingPeriod == 8) {
            rewardPercentage = REWARD_PERCENTAGE_8_MONTHS;
        } else if (stakingPeriod == 12) {
            rewardPercentage = REWARD_PERCENTAGE_12_MONTHS;
        } else if (stakingPeriod == 18) {
            rewardPercentage = REWARD_PERCENTAGE_18_MONTHS;
        }

        // Calculating the reward based on the staked amount and reward percentage
        uint256 reward = stakedAmount * rewardPercentage / 100;

        // Adding an extension reward if the staking commitment has been extended
        if (commitments[_commitmentIndex].isExtended) {
            reward += stakedAmount * EXTENSION_REWARD_PERCENTAGE / 100;
        }
        // Returning the calculated reward
        return reward;
    }


    /// @notice Returns the minimum stake required for a given staking period
    /// @dev This function is read-only, so it does not modify the contract state
    /// @param _stakingPeriod An integer representing the staking period in months
    /// @return A uint256 value representing the required minimum stake for the given staking period
    function getMinimumStake(uint256 _stakingPeriod) public pure returns (uint256) {
        if (_stakingPeriod == 6) {
            return 100 * 10 ** 18; // 100 FIL
        } else if (_stakingPeriod == 8) {
            return 250 * 10 ** 18; // 250 FIL
        } else {
            return 0;
        }
    }


    /// @notice Returns the token balance of the Staking contract
    /// @dev This function is read-only, so it does not modify the contract state
    /// @return A uint256 value representing the token balance of the Staking contract
    function getTokenBalance() public view returns (uint256) {
        return filToken.balanceOf(address(this));
    }


    /// @notice Returns the address of the token contract used by the Staking contract
    /// @dev This function is read-only, so it does not modify the contract state
    /// @return An address value representing the address of the token contract
    function getTokenAddress() public view returns (address) {
        return address(filToken);
    }

    


    /// @notice Returns the number of staking commitments that have been made in the contract
    /// @dev This function is read-only, so it does not modify the contract state
    /// @return A uint256 value representing the number of staking commitments made in the contract
    function getStakingCommitmentsCount() public view returns (uint256) {
        return commitments.length;
    }


    /// @notice Returns the amount of tokens that a specific staker has staked in the contract
    /// @dev This function is read-only, so it does not modify the contract state
    /// @param _staker The address of the staker to check
    /// @return A uint256 value representing the staked amount for the given staker
    function getStakedAmount(address _staker) public view returns (uint256) {
        return stakedAmounts[_staker];
    }


    /// @notice Returns the total amount of tokens that have been staked in the contract
    /// @dev This function is read-only, so it does not modify the contract state
    /// @return A uint256 value representing the total staked amount
    function getTotalStakedAmount() public view returns (uint256) {
        return totalStakedAmount;
    }

}