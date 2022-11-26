/**
 *Submitted for verification at polygonscan.com on 2022-11-25
*/

// SPDX-License-Identifier: NONE
pragma solidity 0.8.7;

interface IERC20 {
    function transfer(address _to, uint256 _amount) external;
    function transferFrom(address _from, address _to, uint256 _amount) external;
}

/**
 *
 * @author Bhupesh Dubey
*/
contract Stake {

    event Staked(address indexed account, uint256 indexed amount, uint256 indexed period);
    event Unstaked(address indexed account, uint256 indexed amount);
    event RewardsClaimed(address indexed account, uint256 indexed reward);

    struct StakingData {
        address account;
        uint8 rewardsActive;
        uint256 stakedAmount;
        uint256 rewardAmount;
        uint256 stakingEndsAt;
    }

    // minimum staking duration is 1 minute
    uint256 public constant MINIMUM_STAKING_DURATION = 60;

    // maximum staking duration is 30 minutes
    uint256 public constant MAXIMUM_STAKING_DURATION = 1800; 

    // reward ERC 20 token
    address public immutable rewardToken;

    // staking ERC 20 token
    address public immutable stakingToken;

    // mapping that contains all staked data of each user
    mapping(address => StakingData[]) public stakeList;

    /**
     *
     * @notice initializes staking and reward token contract address
       @param _stakingToken staking token contract address
       @param _rewardToken reward token contract address
    */
    constructor(address _stakingToken, address _rewardToken) {
        require(_stakingToken != address(0) && _rewardToken != address(0));
        stakingToken = _stakingToken;
        rewardToken = _rewardToken;
    }

    /**
     *
     * @notice stakes the zetta token of user
       @param _amount amount of zetta tokens to stake
       @param _stakingDuration duration for staking
    */
    function stake(uint256 _amount, uint256 _stakingDuration) external {  
        require(
            _amount != 0 && 
            _stakingDuration >= MINIMUM_STAKING_DURATION && 
            _stakingDuration <= MAXIMUM_STAKING_DURATION
        );
        uint256 rewards = calculateRewards(_amount, _stakingDuration);
        StakingData memory data = StakingData(
            msg.sender, 0, _amount, rewards, block.timestamp + _stakingDuration
        );
        stakeList[msg.sender].push(data);
        IERC20(stakingToken).transferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _amount, _stakingDuration);
    }

    /**
     *
     * @notice unstakes the zetta token of user
       @param _id id of the staked entry of user
    */
    function unstake(uint256 _id) external {
        StakingData[] memory userData = stakeList[msg.sender];
        require(
            _id > 0 && 
            _id <= userData.length && 
            userData[_id-1].rewardsActive == 0 
            && userData[_id-1].stakingEndsAt <= block.timestamp
        );
        IERC20(stakingToken).transfer(msg.sender, userData[_id-1].stakedAmount);
        stakeList[msg.sender][_id-1].rewardsActive = 1;
        emit Unstaked(msg.sender, userData[_id-1].stakedAmount);
    }

    /**
     *
     * @notice transfers claimed rewards (Alpha tokesn) to the user
       @param _id id of the staked entry of user
    */
    function claimRewards(uint256 _id) external {
        StakingData[] memory userData = stakeList[msg.sender];
        require(
            _id > 0 && 
            _id <= userData.length && 
            userData[_id-1].rewardsActive == 1
        );
        IERC20(rewardToken).transferFrom(rewardToken, msg.sender, userData[_id-1].rewardAmount);
        stakeList[msg.sender][_id-1] = stakeList[msg.sender][userData.length-1];
        stakeList[msg.sender].pop();
        emit RewardsClaimed(msg.sender, userData[_id-1].rewardAmount);
    }

    /**
     *
     * @notice calculates the reward for ceratin amount for provided time period of staking
       @param _amount amount to be staked 
       @param _period time period for staking
    */
    function calculateRewards(uint256 _amount, uint256 _period) private pure returns(uint256) {
        return (_amount * (MAXIMUM_STAKING_DURATION + _period)) / MAXIMUM_STAKING_DURATION;
    }

    /**
     *
     * @notice returns entire details of staked tokens by the user
    */
    function getUserStakedData() external view returns(StakingData[] memory){
        return stakeList[msg.sender];
    }

}