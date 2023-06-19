// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract PledgeStakeV2 {
    using SafeMath for uint256;

    // Declare variables
    IERC20 public Pledge;
    uint256 private constant roundDuration = 100 seconds;
    uint256 private constant totalRounds = 12;
    uint256 private constant directRewardPercentage = 6;
    uint256[12] private roundRewardPercentages = [3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 12, 13];
    uint256 private constant levelCount = 10;
    uint256[10] private levelPercentage = [25, 10, 5, 5, 5, 5, 3, 3, 5, 10];
    uint256 public totalUsers;
    address public defaultReferrer;

    // Define struct for stake data
    struct StakeInfo {
        uint256 amount;
        uint256 startTime;
        bool unstaked;
    }
    mapping(address => StakeInfo[]) public stakes;
    address[] public stakers;

    // Define struct for user data
    struct UserInfo {
        address referrer;
        uint256 totalReferrals;
        uint256 startTime;
        uint256 totalStake;
        uint256 level;
        uint256 teamCount;
        uint256 rewardLimit;
        uint256 totalDirectStake;
        uint256 totalTeamStake;
        uint256 totalIncome;
    }
    // Define mapping to store user data
    mapping(address => UserInfo) public userInfo;
    mapping(address => mapping(uint256 => address[])) public teamUsers;
    mapping(address => uint256) public lastProcessedStakeIndex;

    // Define struct for reward data
    struct RewardInfo {
        uint256 directRewards;
        uint256 roundRewards;
        uint256 levelRewards;
        uint256 UnstakeAmount;
        uint256 totalRewards;
        uint256 withdrawnRewards;
        uint256 availableRewards;
    }
    mapping(address => RewardInfo) public rewards;

    event Register(address indexed user, address indexed referral);
    event Staked(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 withdrawable);
    event Withdrawn(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event UserDeleted(address indexed user);

    constructor(address _pledge, address _defaultReferrer) {
        Pledge = IERC20(_pledge);
        defaultReferrer = _defaultReferrer;
    }

    // Function to register a user with a referrer
    function register(address _referrer) external {
        require(_referrer != address(0), "Invalid referrer address");
        require(userInfo[_referrer].totalStake > 0 || _referrer == defaultReferrer, "Invalid referrer");
        UserInfo storage user = userInfo[msg.sender];
        require(userInfo[msg.sender].referrer == address(0), "User already registered");
        user.referrer = _referrer;
        user.startTime = block.timestamp;
        _updateTeamCount(msg.sender);
        totalUsers = totalUsers.add(1);
        emit Register(msg.sender, _referrer);
    }

    // Function to stake tokens
    function stake(uint256 _amount) external {
        Pledge.transferFrom(msg.sender, address(this), _amount);
        _updateStakeData(msg.sender, _amount);
        _updateStakerList(msg.sender);
        emit Staked(msg.sender, _amount);
    }

    // Function to unstake tokens
    function unstake(uint256 _stakeIndex) external {
        StakeInfo[] storage userStakes = stakes[msg.sender];
        require(_stakeIndex < userStakes.length, "Invalid stake index");
        StakeInfo storage userStake = userStakes[_stakeIndex];
        require(!userStake.unstaked, "Stake already withdrawn");
        uint256 unstakeAmount = userStake.amount;
        userStake.unstaked = true;
        rewards[msg.sender].UnstakeAmount = rewards[msg.sender].UnstakeAmount.add(unstakeAmount);
        emit Unstaked(msg.sender, unstakeAmount);
    }

    // Function to withdraw available rewards
    function withdraw() external {
        uint256 withdrawableAmount = rewards[msg.sender].availableRewards;
        require(withdrawableAmount > 0, "No rewards available for withdrawal");
        rewards[msg.sender].withdrawnRewards = rewards[msg.sender].withdrawnRewards.add(withdrawableAmount);
        rewards[msg.sender].availableRewards = 0;
        Pledge.transfer(msg.sender, withdrawableAmount);
        emit Withdrawn(msg.sender, withdrawableAmount);
    }

    // Internal function to update stake data
    function _updateStakeData(address _user, uint256 _amount) internal {
        stakes[_user].push(StakeInfo({
            amount: _amount,
            startTime: block.timestamp,
            unstaked: false
        }));
        UserInfo storage user = userInfo[_user];
        user.totalStake = user.totalStake.add(_amount);
        rewards[_user].availableRewards = rewards[_user].availableRewards.add(_amount.mul(directRewardPercentage).div(100));
        _updateRoundRewards(_user, _amount);
        _updateLevelRewards(_user, _amount);
    }

    // Internal function to update the staker list
    function _updateStakerList(address _staker) internal {
        if (userInfo[_staker].referrer != address(0)) {
            stakers.push(_staker);
        }
    }

    // Internal function to update the team count of a user and their uplines
    function _updateTeamCount(address _user) internal {
        address referrer = userInfo[_user].referrer;
        uint256 userLevel = userInfo[_user].level;

        while (referrer != address(0) && userLevel < levelCount) {
            userInfo[referrer].teamCount = userInfo[referrer].teamCount.add(1);
            teamUsers[referrer][userLevel].push(_user);
            userLevel = userLevel.add(1);
            referrer = userInfo[referrer].referrer;
        }
    }

    // Internal function to update the round rewards of a user and their uplines
    function _updateRoundRewards(address _user, uint256 _amount) internal {
        address referrer = userInfo[_user].referrer;
        uint256 userLevel = userInfo[_user].level;

        for (uint256 round = 0; round < totalRounds; round++) {
            if (referrer == address(0)) {
                break;
            }
            uint256 rewardPercentage = roundRewardPercentages[round];
            uint256 rewardAmount = _amount.mul(rewardPercentage).div(100);
            rewards[referrer].roundRewards = rewards[referrer].roundRewards.add(rewardAmount);
            referrer = userInfo[referrer].referrer;
            userLevel = userInfo[referrer].level;
        }
    }

    // Internal function to update the level rewards of a user and their uplines
    function _updateLevelRewards(address _user, uint256 _amount) internal {
        address referrer = userInfo[_user].referrer;
        uint256 userLevel = userInfo[_user].level;

        for (uint256 level = 0; level < userLevel; level++) {
            if (referrer == address(0)) {
                break;
            }
            uint256 rewardPercentage = levelPercentage[level];
            uint256 rewardAmount = _amount.mul(rewardPercentage).div(100);
            rewards[referrer].levelRewards = rewards[referrer].levelRewards.add(rewardAmount);
            referrer = userInfo[referrer].referrer;
            userLevel = userInfo[referrer].level;
        }
    }

    // Function to get the total stake amount of a user
    function getUserTotalStake(address _user) external view returns (uint256) {
        return userInfo[_user].totalStake;
    }

    // Function to get the total team count of a user
    function getUserTotalTeamCount(address _user) external view returns (uint256) {
        return userInfo[_user].teamCount;
    }

    // Function to get the total income of a user
    function getUserTotalIncome(address _user) external view returns (uint256) {
        return userInfo[_user].totalIncome;
    }

    // Function to get the total referrals of a user
    function getUserTotalReferrals(address _user) external view returns (uint256) {
        return userInfo[_user].totalReferrals;
    }

    // Function to get the available rewards of a user
    function getUserAvailableRewards(address _user) external view returns (uint256) {
        return rewards[_user].availableRewards;
    }

    // Function to get the withdrawn rewards of a user
    function getUserWithdrawnRewards(address _user) external view returns (uint256) {
        return rewards[_user].withdrawnRewards;
    }
}