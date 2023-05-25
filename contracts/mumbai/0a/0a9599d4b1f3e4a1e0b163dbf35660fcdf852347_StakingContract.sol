/**
 *Submitted for verification at polygonscan.com on 2023-05-24
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

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
    using SafeMath for uint256;

    IERC20 private token;
    uint256 private constant MIN_STAKE_AMOUNT = 50;
    uint256 private constant REWARD_CAP_WITHOUT_REFERRALS = 200;
    uint256 private constant REWARD_CAP_WITH_REFERRALS = 300;
    uint256 private constant STAKE_DURATION = 360 days;

    struct Stake {
        uint256 amount;
        uint256 startTime;
    }

    struct User {
        Stake[] stakes;
        address[] referrals;
        uint256 rewardBalance;
        uint256 lastClaimTime;
    }

    mapping(address => User) private users;

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
    }

    function stakeTokens(uint256 _amount) external {
        require(_amount >= MIN_STAKE_AMOUNT, "Minimum stake amount not met");

        token.transferFrom(msg.sender, address(this), _amount);
        users[msg.sender].stakes.push(Stake(_amount, block.timestamp));
    }

    function claimRewards() external payable {
    User storage user = users[msg.sender];
    require(user.stakes.length > 0, "No stakes found");

    uint256 totalRewards = calculateTotalRewards(msg.sender);
    require(totalRewards > 0, "No rewards to claim");

    uint256 maxRewardCap = REWARD_CAP_WITHOUT_REFERRALS;
    if (user.referrals.length >= 2) {
        maxRewardCap = REWARD_CAP_WITH_REFERRALS;
    }

    uint256 claimedRewards = user.rewardBalance;
    uint256 remainingRewards = totalRewards;
    if (claimedRewards.add(totalRewards) > maxRewardCap.mul(user.stakes[0].amount).div(100)) {
        remainingRewards = maxRewardCap.mul(user.stakes[0].amount).div(100).sub(claimedRewards);
        user.stakes[0].amount = 0;
        user.stakes[0].startTime = block.timestamp;
    } else {
        user.stakes[0].startTime = block.timestamp;
    }

    user.rewardBalance = user.rewardBalance.add(remainingRewards);
    user.lastClaimTime = block.timestamp;

    token.transfer(msg.sender, remainingRewards);
}


function calculateTotalRewards(address _user) private view returns (uint256) {
    User storage user = users[_user];
    uint256 totalRewards = 0;

    for (uint256 i = 0; i < user.stakes.length; i++) {
        Stake storage stake = user.stakes[i];

        if (block.timestamp >= stake.startTime.add(STAKE_DURATION)) {
            totalRewards = totalRewards.add(getRewardForStake(stake.amount, STAKE_DURATION));
        } else {
            uint256 rewardPeriods = (block.timestamp.sub(stake.startTime)).div(30 days);
            for (uint256 j = 0; j < rewardPeriods; j++) {
                uint256 rewardDuration = stake.startTime.add((j + 1) * 30 days);
                if (rewardDuration <= block.timestamp) {
                    totalRewards = totalRewards.add(getRewardForStake(stake.amount, rewardDuration.sub(stake.startTime)));
                } else {
                    break;
                }
            }
        }
    }

    return totalRewards;
}




    function getRewardForStake(uint256 _amount, uint256 _duration) private pure returns (uint256) {
        if (_duration <= 30 days) {
            return _amount.mul(4).div(100);
        } else if (_duration <= 60 days) {
            return _amount.mul(5).div(100);
        } else if (_duration <= 150 days) {
            return _amount.mul(6).div(100);
        } else if (_duration <= 330 days) {
            return _amount.mul(7).div(100);
        } else {
            return _amount.mul(8).div(100);
        }
    }

    function referUser(address _referral) external {
        require(msg.sender != _referral, "Cannot refer yourself");
        require(users[_referral].stakes.length > 0, "Referral has no stakes");

        users[msg.sender].referrals.push(_referral);

        uint256 referralReward = users[_referral].stakes[0].amount.mul(6).div(100);
        users[_referral].rewardBalance = users[_referral].rewardBalance.add(referralReward);
    }

    function getLevelReward(address _user, uint256 _level) private view returns (uint256) {
        if (_level == 1) {
            return calculateTotalRewards(_user).mul(25).div(100);
        } else if (_level == 2) {
            return calculateTotalRewards(_user).mul(10).div(100);
        } else if (_level >= 3 && _level <= 5) {
            return calculateTotalRewards(_user).mul(5).div(100);
        } else if (_level >= 6 && _level <= 7) {
            return calculateTotalRewards(_user).mul(3).div(100);
        } else if (_level >= 8 && _level <= 9) {
            return calculateTotalRewards(_user).mul(5).div(100);
        } else if (_level == 10) {
            return calculateTotalRewards(_user).mul(10).div(100);
        } else {
            return 0;
        }
    }

    function claimLevelRewards(uint256 _level) external {
        require(_level >= 1 && _level <= 10, "Invalid level");
        require(users[msg.sender].referrals.length >= _level, "Not enough referrals for the level");

        uint256 levelReward = getLevelReward(msg.sender, _level);
        require(levelReward > 0, "No level rewards to claim");

        users[msg.sender].rewardBalance = users[msg.sender].rewardBalance.add(levelReward);
        token.transfer(msg.sender, levelReward);
    }

    function getUserStakes(address _user) external view returns (Stake[] memory) {
        return users[_user].stakes;
    }

    function getUserReferrals(address _user) external view returns (address[] memory) {
        return users[_user].referrals;
    }

    function getUserRewardBalance(address _user) external view returns (uint256) {
        return users[_user].rewardBalance;
    }

    function getUserLastClaimTime(address _user) external view returns (uint256) {
        return users[_user].lastClaimTime;
    }
}