// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

/// @title ERC20 Staking Contract
/// @notice This contract allows for stake ERC20 tokens and receive ERC20 tokens as rewards
/// @dev This contract allows for updating the duration of reward period at any given moment.

contract StakingRewards is ReentrancyGuard {
    // ============= VARIABLES ============
    // Contract address of the staked token
    IERC20 public immutable stakingToken;
    // Contract address of the rewards token
    IERC20 public immutable rewardsToken;
    // Address of the owner of the contract
    address public owner;
    // Duration of rewards to be paid out (in seconds)
    uint public duration;
    // Timestamp of when the rewards finish
    uint public finishAt;
    // Minimum of last updated time and reward finish time
    uint public updatedAt;
    // Reward to be paid out per second
    uint public rewardRate;
    // Sum of (reward rate * dt * 1e18 / total supply)
    uint public rewardPerTokenStored;
    // Total staked
    uint public totalSupply;
    // Max amount that people can stake
    uint public MAX_AMOUNT_STAKE;
    // The maximum amount of tokens in the staking pool
    uint public MAX_NUM_OF_TOKENS_IN_POOL;
    // Addresses of stakers
    address[] private stakers;

    // ============= MAPPINGS ============
    // User address => rewardPerTokenStored
    mapping(address => uint) public userRewardPerTokenPaid;
    // User address => rewards to be claimed
    mapping(address => uint) public rewards;
    // User address => staked amount
    mapping(address => uint) public balanceOf;
    // User address => exists
    mapping(address => bool) public userStaked;

    /// @param _stakingToken - address of the staking token
    /// @param _rewardToken - address of the reward token
    constructor(address _stakingToken, address _rewardToken) {
        owner = msg.sender;
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardToken);
    }

    // ============= MODIFIERS ============

    modifier onlyOwner() {
        require(msg.sender == owner, "not authorized");
        _;
    }

    /// @notice Modifier that updates rewardPerTokenStored and userRewardPerTokenPaid
    /// @param _account - address of the account that we wish to update rewards for

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();

        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }

        _;
    }

    // ============= MAIN FUNCTIONS ============

    /// @notice Function that allows to calculate rewardPerTokenStored

    function rewardPerToken() public view returns (uint) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }

        return
            rewardPerTokenStored +
            (rewardRate * (lastTimeRewardApplicable() - updatedAt) * 1e18) /
            totalSupply;
    }

    /// @notice Function that allows users to stake their tokens
    /// @param _amount - amount of tokens to stake in WEI
    /// @dev remember to approve the token first from the frontend
    /// @dev when users stake tokens updateReward modifier is fired for them
    function stake(
        uint _amount
    ) external nonReentrant updateReward(msg.sender) {
        require(_amount > 0, "amount = 0");
        require(
            balanceOf[msg.sender] + _amount <= MAX_AMOUNT_STAKE,
            "Too much staked!"
        );
        require(
            totalSupply + _amount <= MAX_NUM_OF_TOKENS_IN_POOL,
            "Maximum number of tokens staked has been reached!"
        );
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        balanceOf[msg.sender] += _amount;
        if (!userStaked[msg.sender]) {
            stakers.push(msg.sender);
            userStaked[msg.sender] = true;
        }
        totalSupply += _amount;
    }

    /// @notice Function that allows users to withdraw their tokens
    /// @param _amount - amount of tokens to withdraw in WEI
    /// @dev when users withdraw tokens updateReward modifier is fired for them
    function withdraw(
        uint _amount
    ) external nonReentrant updateReward(msg.sender) {
        require(_amount > 0, "amount = 0");
        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        bool success = stakingToken.transfer(msg.sender, _amount);
        require(success, "Withdraw failed");
    }

    /// @notice Function that allows users to withdraw their winnings
    /// @dev when users withdraw rewards updateReward modifier is fired for them
    function withdrawReward() external nonReentrant updateReward(msg.sender) {
        uint reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            bool success = rewardsToken.transfer(msg.sender, reward);
            require(success, "Withdraw reward failed");
        }
    }

    /// @notice Function that allows the owner to specify the rewards and duration for the next reward period
    /// @param _amount - amount of tokens that will be given out as rewards during the given period
    /// @param _duration - duration of the next reward period in seconds
    /// @dev this function is a modified version of the Synthetix ERC20 Staking implementation - it allows
    /// @dev the owner to change the duration before the last one ends - keep in mind in the next period it will give out
    /// @dev the _amount + remaining rewards from the last period that were not given out
    function notifyRewardAmount(
        uint _amount,
        uint _duration
    ) external onlyOwner updateReward(address(0)) {
        uint tokenBalance = getTokensDepositedForRewards();
        require(tokenBalance >= _amount, "not enough funds in contract");
        if (duration == 0) {
            duration = _duration;
        }
        if (block.timestamp >= finishAt) {
            rewardRate = _amount / _duration;
        } else {
            uint remainingRewards = (finishAt - block.timestamp) * rewardRate;
            rewardRate = (_amount + remainingRewards) / duration;
        }

        require(rewardRate > 0, "reward rate = 0");
        require(
            rewardRate * duration <= rewardsToken.balanceOf(address(this)),
            "reward amount > balance"
        );

        duration = _duration;
        finishAt = block.timestamp + duration;
        updatedAt = block.timestamp;
    }

    /// @notice Function that allows the owner to change the user staking limit
    /// @param _amount - the maximum amount a person can stake at once in WEI
    function changeStakeLimit(uint _amount) public onlyOwner {
        MAX_AMOUNT_STAKE = _amount;
    }

    /// @notice Function that allows the owner to change the pool staking limit
    /// @param _amount - the maximum amount of tokens that the whole staking pool can stake in WEI
    function changePoolLimit(uint _amount) public onlyOwner {
        MAX_NUM_OF_TOKENS_IN_POOL = _amount;
    }

    /// @notice Function that allows the owner to return ERC20 tokens that were sent to the contract by accident
    /// @param _tokenAddress - ERC20 address of the token
    /// @param _tokenAmount - amount of tokens
    function recoverERC20(
        address _tokenAddress,
        uint256 _tokenAmount
    ) external onlyOwner {
        require(
            _tokenAddress != address(stakingToken),
            "Cannot withdraw the staking token"
        );
        IERC20(_tokenAddress).transfer(owner, _tokenAmount);
    }

    // ============= UTILITY FUNCTIONS ============

    function _min(uint x, uint y) private pure returns (uint) {
        return x <= y ? x : y;
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        return _min(finishAt, block.timestamp);
    }

    // ============= GETTER FUNCTIONS ============

    function getRewardRate() public view returns (uint) {
        return rewardRate;
    }

    function getTotalSupply() public view returns (uint) {
        return totalSupply;
    }

    function secondsLeftTillNewRewards() public view returns (uint) {
        return finishAt < block.timestamp ? 0 : finishAt - block.timestamp;
    }

    function earned(address _account) public view returns (uint) {
        return
            ((balanceOf[_account] *
                (rewardPerToken() - userRewardPerTokenPaid[_account])) / 1e18) +
            rewards[_account];
    }

    /// @notice This function does not take unclaimed rewards under consideration

    function getTokensDepositedForRewards() public view returns (uint) {
        uint balance = stakingToken.balanceOf(address(this));
        uint sumOfRewards = getTokensEarnedByStakers();
        return balance - totalSupply - sumOfRewards;
    }

    function getTokensEarnedByStakers() public view returns (uint) {
        uint sum;
        for (uint i = 0; i < stakers.length; i++) {
            uint earnedAmount = earned(stakers[i]);
            sum += earnedAmount;
        }
        return sum;
    }

    function getStakeLimit() public view returns (uint) {
        return MAX_AMOUNT_STAKE;
    }

    function getPoolLimit() public view returns (uint) {
        return MAX_NUM_OF_TOKENS_IN_POOL;
    }

    function getDuration() public view returns (uint) {
        return duration;
    }

    function getFinishAt() public view returns (uint) {
        return finishAt;
    }

    function getUpdatedAt() public view returns (uint) {
        return updatedAt;
    }
}