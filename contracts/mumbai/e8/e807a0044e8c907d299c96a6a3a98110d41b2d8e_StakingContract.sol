/**
 *Submitted for verification at polygonscan.com on 2023-05-25
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

// File: plgstake.sol


pragma solidity ^0.8.0;


contract StakingContract {
    struct User {
        uint256 stakedAmount;
        uint256 startTime;
        uint256 lastRoundCompleted;
        uint256 totalReward;
        uint256 availableWithdrawal;
        address referrer;
        mapping(address => uint256) referralRewards;
        mapping(uint256 => uint256) levelReferralRewards;
    }

    IERC20 private token;
    uint256 private constant STAKING_DURATION = 30 days;
    uint256 private constant STAKING_ROUNDS = 12;
    uint256 private constant MIN_STAKE_AMOUNT = 50;

    mapping(address => User) private users;

    constructor(address _token) {
        token = IERC20(_token);
    }

    function stake(uint256 _amount, address _referrer) external {
        require(_amount >= MIN_STAKE_AMOUNT, "Minimum stake amount not met");

        User storage user = users[msg.sender];
        require(user.stakedAmount == 0, "User has already staked");

        token.transferFrom(msg.sender, address(this), _amount);

        user.stakedAmount = _amount;
        user.startTime = block.timestamp;
        user.lastRoundCompleted = 0;
        user.referrer = _referrer;
    }

    function completeRound() external {
        User storage user = users[msg.sender];
        require(user.stakedAmount > 0, "User has not staked");

        uint256 currentRound = getCurrentRound();
        require(user.lastRoundCompleted < currentRound, "Round already completed");

        for (uint256 round = user.lastRoundCompleted + 1; round <= currentRound; round++) {
            uint256 rewardPercentage = getRewardPercentage(round);
            uint256 rewardAmount = (user.stakedAmount * rewardPercentage) / 100;

            // Update user's total reward
            user.totalReward += rewardAmount;

            // Update user's available withdrawal
            user.availableWithdrawal += rewardAmount;
        }

        // Update user's last completed round
        user.lastRoundCompleted = currentRound;
    }

    function withdrawReward() external {
        User storage user = users[msg.sender];
        require(user.availableWithdrawal > 0, "No available rewards to withdraw");

        uint256 withdrawalAmount = user.availableWithdrawal;
        user.availableWithdrawal = 0;

        token.transfer(msg.sender, withdrawalAmount);
    }

    function getRewardPercentage(uint256 _round) private pure returns (uint256) {
        require(_round <= STAKING_ROUNDS, "Invalid round");

        if (_round == 1) {
            return 3;
        } else if (_round == 2) {
            return 4;
        } else if (_round == 3) {
            return 5;
        } else if (_round >= 4 && _round <= 11) {
            return 6 + (_round - 4);
        } else if (_round == 12) {
            return 13;
        }

        revert("Invalid round");
    }

    function getCurrentRound() private view returns (uint256) {
        uint256 elapsedTime = block.timestamp - users[msg.sender].startTime;
        return (elapsedTime / STAKING_DURATION) + 1;
    }
}