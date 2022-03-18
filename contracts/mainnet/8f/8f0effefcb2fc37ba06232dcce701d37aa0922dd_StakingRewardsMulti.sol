// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Math.sol";
import "./SafeMath.sol";
import "./IERC20Metadata.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./Ownable.sol";

// Inheritance
import "./IStakingRewards.sol";


// https://docs.synthetix.io/contracts/source/contracts/stakingrewards
contract StakingRewardsMulti is ReentrancyGuard, Pausable, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20Metadata;

    /* ========== STATE VARIABLES ========== */

    IERC20Metadata[] public rewardsTokens;
    IERC20Metadata public stakingToken;
    uint256 public periodFinish = 0;
    uint256[] public rewardRates;
    uint256 public rewardsDuration = 4 weeks;
    uint256 public lastUpdateTime;
    uint256[] public rewardsPerTokenStored;

    mapping(address => mapping (uint256 => uint256)) public userRewardPerTokenPaid;
    mapping(address => mapping (uint256 => uint256)) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        IERC20Metadata[] memory _rewardsTokens,
        IERC20Metadata _stakingToken
    ) Ownable() {
        rewardsTokens = _rewardsTokens;
        stakingToken = IERC20Metadata(_stakingToken);

        rewardRates = new uint256[](_rewardsTokens.length);
        rewardsPerTokenStored = new uint256[](_rewardsTokens.length);
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardsPerToken() public view returns (uint256[] memory) {
        if (_totalSupply == 0) {
            return rewardsPerTokenStored;
        }

        uint256[] memory r = new uint256[](rewardsTokens.length);
        for (uint256 i = 0; i < r.length; i++) {
            r[i] = rewardsPerTokenStored[i].add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRates[i]).mul(1e18).div(_totalSupply)
            );
        }

        return r;
    }

    function earned(address account) public view returns (uint256[] memory) {
        uint256[] memory r = rewardsPerToken();

        for (uint256 i = 0; i < r.length; i++) {
            r[i] = _balances[account].mul(r[i].sub(userRewardPerTokenPaid[account][i])).div(1e18).add(rewards[account][i]);
        }

        return r;
    }

    function getRewardForDuration() external view returns (uint256[] memory) {
        uint256[] memory r = new uint256[](rewardsTokens.length);

        for (uint256 i = 0; i < r.length; i++) {
            r[i] = rewardRates[i].mul(rewardsDuration);
        }

        return r;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 amount) external nonReentrant whenNotPaused updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward;

        for (uint256 i = 0; i < rewardsTokens.length; i++) {
            reward = rewards[msg.sender][i];
            if (rewardsTokens[i].decimals() < 18) {
                uint256 normalization = 10**(uint256(18).sub(uint256(rewardsTokens[i].decimals())));
                reward = reward.div(normalization);
            }
            if (reward > 0) {
                rewards[msg.sender][i] = 0;
                rewardsTokens[i].safeTransfer(msg.sender, reward);
                emit RewardPaid(address(rewardsTokens[i]), msg.sender, reward);
            }
        }
    }

    function exit() external {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256[] calldata _rewards) external onlyOwner updateReward(address(0)) {
        assert(_rewards.length == rewardsTokens.length);

        uint256 normalization;
        uint256[] memory reward = _rewards;
        for (uint256 i = 0; i < rewardsTokens.length; i++) {
            uint256 balance = rewardsTokens[i].balanceOf(address(this));
            if (rewardsTokens[i].decimals() < 18) {
                normalization = 10**(uint256(18).sub(uint256(rewardsTokens[i].decimals())));
                reward[i] = _rewards[i].mul(normalization);
                balance = balance.mul(normalization);
            }
            // Ensure the provided reward amount is not more than the balance in the contract.
            // This keeps the reward rate in the right range, preventing overflows due to
            // very high values of rewardRate in the earned and rewardsPerToken functions;
            // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
            require(rewardRates[i] <= balance.div(rewardsDuration), "Provided reward too high");
        }
         
        if (block.timestamp >= periodFinish) {
            for (uint256 i = 0; i < rewardsTokens.length; i++) {
                rewardRates[i] = reward[i].div(rewardsDuration);
            }
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);

            uint256 leftover;
            for (uint256 i = 0; i < rewardsTokens.length; i++) {
                leftover = remaining.mul(rewardRates[i]);
                rewardRates[i] = reward[i].add(leftover).div(rewardsDuration);
            }
        }

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAddress != address(stakingToken), "Cannot withdraw the staking token");
        IERC20Metadata(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(
            block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardsPerTokenStored = rewardsPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            uint256[] memory accountEarned = earned(account);
            for (uint256 i = 0; i < rewardsTokens.length; i++) {
                rewards[account][i] = accountEarned[i];
                userRewardPerTokenPaid[account][i] = rewardsPerTokenStored[i];
            }
        }
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256[] reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed token, address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);
}