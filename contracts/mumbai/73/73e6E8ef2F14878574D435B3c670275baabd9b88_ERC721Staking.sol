// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/******************************************************************************\
* Staking for xxx NFT project www.???.com
* Contract written by Ian Cherkowski https://twitter.com/IanCherkowski
* Thanks to StakingRewards contract by Synthetix.
* Allows NFT to be staked to earn rewards.
* Rewards can be only redeemed for items from the NFT team. There is no ERC20 token.
/******************************************************************************/

import "./IERC721.sol";
import "./ERC721Holder.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Address.sol";

contract ERC721Staking is ERC721Holder, ReentrancyGuard, Ownable, Pausable {

    /* ========== STATE VARIABLES ========== */

    IERC721 public stakingToken;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public rewardsDuration;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public totalSupply;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public balances;
    mapping(uint256 => address) public stakedAssets;
 
    struct redeemStruct {
        address account;
        uint256 amount;
        uint256 spent;
    }
    redeemStruct[] public redeemList;

    //To begin staking:
    // run notifyRewardAmount to set the total rewards to be paid out     
    // run unpause

    constructor() {
        stakingToken = IERC721(0xd401DC86F8D99E57B48fE9EE804c4C05461aA386);
        rewardsDuration = 86400 * 100; //in seconds
        _pause();
    }

    // shows block when the reward period ends
    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    // reward rate per token, declines as more NFT are staked
    function rewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
                (((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18) / totalSupply);
    }

    // how much earned for 1 address
    function earned(address account) public view returns (uint256) {
        return
            ((balances[account] *
                (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) +
                    rewards[account];
    }

    // total reward to be paid out
    function getRewardForDuration() external view returns (uint256) {
        return rewardRate * rewardsDuration;
    }

    // returns how many redeems are left to claim
    function getRedeemCount() external view returns (uint256) {
        return redeemList.length;
    }

    // updates the amount of rewards earned so they can be redeemed
    function updateMyReward() public nonReentrant {        
        // update the current reward balance
        updateReward(msg.sender);
    }

    /// @notice Stakes user's NFTs
    /// @param tokenIds The tokenIds of the NFTs which will be staked
    function stake(uint256[] memory tokenIds) external nonReentrant whenNotPaused {
        require(tokenIds.length != 0, "Staking: No tokenIds provided");
        require(Address.isContract(msg.sender) == false, "Staking: No contracts");

        uint256 amount;
        for (uint256 i = 0; i < tokenIds.length; i += 1) {
            require(stakingToken.ownerOf(tokenIds[i]) == msg.sender, "Staking: not owner of NFT");

            require(stakingToken.isApprovedForAll(msg.sender, address(this)) == true, 
                "Staking: First must setApprovalForAll in the NFT to this contract");

            // Transfer user's NFTs to the staking contract
            stakingToken.transferFrom(msg.sender, address(this), tokenIds[i]);
            // Increment the amount which will be staked
            amount += 1;
            // Save who is the staker/depositor of the token
            stakedAssets[tokenIds[i]] = msg.sender;
        }

        totalSupply += amount;
        balances[msg.sender] += amount;
        emit Staked(msg.sender, amount, tokenIds);
    }
 
    /// @notice Withdraws staked user's NFTs
    /// @param tokenIds The tokenIds of the NFTs which will be withdrawn
    function withdraw(uint256[] memory tokenIds) external nonReentrant {
        require(tokenIds.length != 0, "Staking: No tokenIds provided");
        require(Address.isContract(msg.sender) == false, "Staking: No contracts");

        // update the current reward balance
        updateReward(msg.sender);

        uint256 amount;
        for (uint256 i = 0; i < tokenIds.length; i += 1) {
            // Check if the user who withdraws is the owner
            require(
                stakedAssets[tokenIds[i]] == msg.sender,
                "Staking: Not the staker of the token"
            );
            // Transfer NFTs back to the owner
            stakingToken.safeTransferFrom(address(this), msg.sender, tokenIds[i]);
            // Increment the amount which will be withdrawn
            amount += 1;
            // Cleanup stakedAssets for the current tokenId
            stakedAssets[tokenIds[i]] = address(0);
        }
        totalSupply -= amount;
        balances[msg.sender] -= amount;

        emit Withdrawn(msg.sender, amount, tokenIds);
    }

    // NFT owners can redeem their rewards
    function redeemReward(uint256 _amount) external nonReentrant {
        uint256 found = 0;
        bool exist = false;

        // update the current reward balance
        updateReward(msg.sender);

        require(_amount <= rewards[msg.sender], "Staking: More than reward balance");
        require(Address.isContract(msg.sender) == false, "Staking: No contracts");

        // redeeem whole balance
        if (_amount == 0) {
            _amount = rewards[msg.sender];
        }

        rewards[msg.sender] -= _amount;

        for (uint256 i = 0; i < redeemList.length; i += 1) {
            if (redeemList[i].account == msg.sender) {
                found = i;
                exist = true;
            }
        }
 
        if (exist == false) {
            redeemList.push(redeemStruct(msg.sender, _amount, 0));
        } else {
            redeemList[found].amount += _amount;
        }
    }

    //calculate rewards for 1 address
    function updateReward(address account) internal {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0) && Address.isContract(account) == false) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
    }

    // NFT project can claim redeemed balance to be used for items awarded to the NFT owners
    function useRedeem(uint256 _amount, address account) external onlyOwner {
        uint256 found = 0;
        bool exist = false;

        for (uint256 i = 0; i < redeemList.length; i += 1) {
            if (redeemList[i].account == account) {
                found = i;
                exist = true;
            }
        }
        require(exist == true, "Staking: Account has not redeemed");
        require(_amount <= redeemList[found].amount, "Staking: More than redeem balance");

        //redeem whole balance
        if (_amount == 0) {
            _amount = redeemList[found].amount;
        }

        redeemList[found].amount -= _amount;
        redeemList[found].spent += _amount;
    }

    /// @notice Calculates and sets the reward rate
    /// @param reward is the total amount of the reward which will be distributed during the entire period
    // reward is in gwei so add 18 zeros
    function notifyRewardAmount(uint256 reward) external onlyOwner {
        require(rewardsDuration > 0, "Stake: fix duration of 0");

        updateReward(address(0));

        if (block.timestamp >= periodFinish) {
            rewardRate = reward / rewardsDuration;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (reward + leftover) / rewardsDuration;
        }

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + rewardsDuration;
        emit RewardAdded(reward);
    }

    // After reward period has finished then can set new reward period in seconds.
    // 1 day = 86400 Seconds
    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(_rewardsDuration > 0, "Stake: fix duration of 0");
        require(
            block.timestamp > periodFinish,
            "Staking: Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    // pause staking
    function pause() external onlyOwner {
        _pause();
    }

    // unpause staking
    function unpause() external onlyOwner {
        require(rewardRate > 0, "Staking: Reward is 0, use notifyRewardAmount");
        require(rewardsDuration > 0, "Staking: Duration is 0, use setRewardsDuration");
        _unpause();
    }


    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount, uint256[] tokenIds);
    event Withdrawn(address indexed user, uint256 amount, uint256[] tokenIds);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
}