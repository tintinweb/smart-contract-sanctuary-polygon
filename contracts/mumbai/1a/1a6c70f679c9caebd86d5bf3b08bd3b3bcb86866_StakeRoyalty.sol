// SPDX-License-Identifier: MIT

/** NatSpec
/// @title STAKE ROYALTY: AN ERC20 STAKING CONTRACT //////////////////
/// @notice KING(OBA) token holders stake KING(OBA) to earn PRINCE(OBALOLA) as rewards
/// @notice Staking and Reward Tokens are deployed on Polygon Mumbai testnet
/// @dev Tokens must be approved before thy can be staked
/// KING(OBA) CA: 0xafAa57C68aD8ecB79E7F792f2B5683817B42467D
/// PRINCE(OBALOLA) CA: 0xE7F5BB6EB75ce069a7135f5322965Edf3da354c1


*/


pragma solidity 0.8.15;

import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./PoolManager.sol";

contract StakeRoyalty is ReentrancyGuard {
    using SafeERC20 for IERC20;
    using PoolManager for PoolManager.PoolState;

    PoolManager.PoolState private _state;

    uint256 private _totalStake;
    mapping (address => uint256) private _userRewardPerTokenPaid;
    mapping (address => uint256) private _rewards;
    mapping (address => uint256) private _balances;

    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardToken;

    constructor(address distributor, IERC20 stakingToken_, IERC20 rewardToken_, uint64 duration) {
        stakingToken = stakingToken_;
        rewardToken = rewardToken_;
        _state.rewardsDuration = duration * 1 days;
        _state.distributor = uint160(distributor);
    }

    /* ========== VIEWS ========== */

    function totalAmountStaked() external view returns (uint256)
    {
        return _totalStake;
    }

    function balanceOf(address account) external view returns (uint256)
    {
        return _balances[account];
    }

    function getOwner() external view returns (address)
    {
        return address(_state.distributor);
    }

    function lastTimeRewardApplicable() external view returns (uint256)
    {
        return _state.lastTimeRewardApplicable();
    }

    function rewardPerToken() external view returns (uint256)
    {
        return _state.rewardPerToken(_totalStake);
    }

    function getRewardForDuration() external view returns (uint256)
    {
        return _state.getRewardForDuration();
    }

    function earned(address account) public view returns (uint256)
    {
        return _balances[account] * (
            _state.rewardPerToken(_totalStake) - _userRewardPerTokenPaid[account]
        ) / 1e18 + _rewards[account];
    }

    /* ========== MUTATIONS ========== */

    function stake(uint256 amount) external payable nonReentrant updateReward(msg.sender)
    {
        require(amount > 0, "Must be greater than zero");

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        _totalStake += amount;
        _balances[msg.sender] += amount;

        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public payable nonReentrant updateReward(msg.sender)
    {
        require(amount > 0, "Must be greater than zero");

        _totalStake -= amount;
        _balances[msg.sender] -= amount;
        stakingToken.safeTransfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public payable nonReentrant updateReward(msg.sender)
    {
        uint256 reward = _rewards[msg.sender];

        if (reward > 0) {
            _rewards[msg.sender] = 0;
            rewardToken.safeTransfer(msg.sender, reward);

            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() external payable
    {
        _state.updateReward(_totalStake);

        uint256 balance = _balances[msg.sender];
        uint256 reward = earned(msg.sender);

        _userRewardPerTokenPaid[msg.sender] = _state.rewardPerTokenStored;
        _balances[msg.sender] -= balance;
        _rewards[msg.sender] = 0;
        _totalStake -= balance;

        _state.updateReward(_totalStake);

        if (stakingToken == rewardToken) {
            stakingToken.safeTransfer(msg.sender, balance + reward);
        } else {
            stakingToken.safeTransfer(msg.sender, balance);
            rewardToken.safeTransfer(msg.sender, reward);
        }

        emit Withdrawn(msg.sender, balance);
        emit RewardPaid(msg.sender, reward);
    }

    /* ========== PROTECTED ========== */
    function setDistributor(address newDistributor) external payable onlyDistributor
    {
        require(newDistributor != address(0), "Cannot set to zero addr");
        _state.distributor = uint160(newDistributor);
    }

    function depositRewardTokens(uint256 amount) external payable onlyDistributor
    {
        require(amount > 0, "Must be greater than zero");

        rewardToken.safeTransferFrom(msg.sender, address(this), amount);

        notifyRewardAmount(amount);
    }

    function notifyRewardAmount(uint256 reward) public payable updateReward(address(0)) onlyDistributor
    {
        uint256 duration = _state.rewardsDuration;

        if (block.timestamp >= _state.periodFinish) {
            _state.rewardRate = reward / duration;
        } else {
            uint256 remaining = _state.periodFinish - block.timestamp;
            uint256 leftover = remaining * _state.rewardRate;
            _state.rewardRate = (reward + leftover) / duration;
        }

        uint256 balance = rewardToken.balanceOf(address(this));

        if (rewardToken == stakingToken) {
            balance -= _totalStake;
        }

        require(_state.rewardRate <= balance / duration, "Reward too high");

        _state.lastUpdateTime = uint64(block.timestamp);
        _state.periodFinish = uint64(block.timestamp + duration);

        emit RewardAdded(reward);
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        _state.updateReward(_totalStake);

        if (account != address(0)) {
            _rewards[account] = earned(account);
            _userRewardPerTokenPaid[account] = _state.rewardPerTokenStored;
        }
        _;
    }

    // modifier nonReentrant() {
    //     require(_state.mutex == 1, "Nonreentrant");
    //     _state.mutex = 2;
    //     _;
    //     _state.mutex = 1;
    // }

    modifier onlyDistributor() {
        require(msg.sender == address(_state.distributor), "Not distributor");
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event DistributorUpdated(address indexed newDistributor);
}