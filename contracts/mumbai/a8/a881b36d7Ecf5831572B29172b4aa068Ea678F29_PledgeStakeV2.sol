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
    uint256 private constant constDiv = 10000;
    uint256 private constant ROUND_DURATION = 60 seconds;
    uint256 private constant TOTAL_ROUNDS = 12;
    uint256 private constant DIRECT_REWARD_PERCENTAGE = 600;
    uint256[12] private roundRewardPercentages = [300, 400, 500, 600, 700, 800, 900, 1000, 1100, 1200, 1200, 1300];
    uint256 private constant LEVEL_COUNT = 11;
    uint256[11] private levelPercentage = [0, 2500, 1000, 500, 500, 500, 500, 300, 300, 500, 1000];
    uint256 public totalUsers;
    address public defaultReferrer;
    uint256 public nextStakeId;

    struct StakeInfo {
        uint256 amount;
        uint256 startTime;
        uint256 roundNumber;
        bool unstaked;
    }
    mapping(address => StakeInfo[]) public stakes;
    mapping(address => uint256[]) public stakeIds;
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
    }
    // Define mapping to store user data
    mapping(address => UserInfo) public userInfo;
    mapping(address => mapping(uint256 => address[])) public teamUsers;
    // Define struct for reward data
    struct RewardInfo {
        uint256 directRewards;
        uint256 roundRewards;
        uint256 levelRewards;
        uint256 unstakeAmount;
        uint256 totalRewards;
        uint256 withdrawnRewards;
        uint256 availableRewards;
    }
    mapping(address => RewardInfo) public rewardInfo;
    event Register(address indexed user, address indexed referral);
    event Stake(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    constructor(address _pledge, address _defaultReferrer) {
        Pledge = IERC20(_pledge);
        defaultReferrer = _defaultReferrer;
    }

    // Function to register a user with a referrer
    function register(address _referrer) external {
        require(_referrer != address(0), "Invalid referrer address");
        require(userInfo[_referrer].totalStake > 0 || _referrer == defaultReferrer,"Invalid referrer");
        UserInfo storage user = userInfo[msg.sender];
        require(userInfo[msg.sender].referrer == address(0), "User already registered");
        user.referrer = _referrer;
        user.startTime = block.timestamp;
        _updateTeamCount(msg.sender);
        totalUsers = totalUsers.add(1);
        emit Register(msg.sender, _referrer);
    }

    // Function to stake tokens
    function stakePledge(uint256 _amount) external {
        Pledge.transferFrom(msg.sender, address(this), _amount);
        _stake(msg.sender, _amount);
        emit Stake(msg.sender, _amount);
    }

    function _stake(address _user, uint256 _amount) private {
        require(_amount > 0, "Amount must be greater than zero");
        UserInfo storage user = userInfo[_user];
        require(user.referrer != address(0), "User not registered");
        // Add stake to user's stake history
        StakeInfo memory newStake = StakeInfo(_amount, block.timestamp, 0, false);
        stakes[_user].push(newStake);
        stakeIds[_user].push(stakes[_user].length - 1);
        stakers.push(_user);
        user.totalStake = user.totalStake.add(_amount);
        // Calculate direct reward for referrer
        address referrer = user.referrer;
        uint256 directReward = _amount.mul(DIRECT_REWARD_PERCENTAGE).div(constDiv);
            UserInfo storage referrerInfo = userInfo[referrer];
            referrerInfo.totalDirectStake = referrerInfo.totalDirectStake.add(_amount);
            // Referral Count Update
            referrerInfo.totalReferrals = referrerInfo.totalReferrals.add(1);
            rewardInfo[referrer].directRewards = rewardInfo[referrer].directRewards.add(directReward);
            rewardInfo[referrer].totalRewards = rewardInfo[referrer].totalRewards.add(directReward);
            rewardInfo[referrer].availableRewards = rewardInfo[referrer].availableRewards.add(directReward);      
        // _updateRewards(_user);
        
        _updateRewardLimit(_user);
        _updateReferInfo(msg.sender, _amount);
        _updateLevel(msg.sender);
        _updateRewards(_user); // Call the _updateRewards
        emit Stake(_user, _amount);
    }
    // Update Team Count
    function _updateTeamCount(address _user) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for (uint256 i = 0; upline != address(0) && i < LEVEL_COUNT; i++) {
            userInfo[upline].teamCount = userInfo[upline].teamCount.add(1);
            teamUsers[upline][i].push(_user);
            _updateLevel(upline);
            if (upline == defaultReferrer) break;
            upline = userInfo[upline].referrer;
        }
    }

    // Update refer info
    function _updateReferInfo(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for (uint256 i = 0; upline != address(0) && i < LEVEL_COUNT; i++) {
            userInfo[upline].totalTeamStake = userInfo[upline]
                .totalTeamStake
                .add(_amount);
            _updateLevel(upline);
            if (upline == defaultReferrer) break;
            upline = userInfo[upline].referrer;
        }
    }

    // Update level of user
    function _updateLevel(address _user) private {
        UserInfo storage user = userInfo[_user];
        uint256 levelNow = _getLevelNow(_user);
        user.level = levelNow;
    }

    // Calculate round reward for a stake
    function _updateRewards(address _user) private {
        UserInfo storage user = userInfo[_user];
        require(user.totalStake > 0, "No stakes available");
        for (uint256 i = 0; i < stakeIds[_user].length; i++) {
            StakeInfo storage stake = stakes[_user][stakeIds[_user][i]];
            if (!stake.unstaked && stake.roundNumber < TOTAL_ROUNDS) {
                uint256 currentRound = stake.roundNumber;
                while (currentRound < TOTAL_ROUNDS) {
                    uint256 roundEndTime = stake.startTime.add(ROUND_DURATION.mul(currentRound + 1));
                    if (block.timestamp >= roundEndTime) {
                        uint256 roundRewardPercentage = roundRewardPercentages[currentRound];
                        uint256 roundReward = stake.amount.mul(roundRewardPercentage).div(constDiv);
                        
                        // Update round rewards
                        rewardInfo[_user].roundRewards = rewardInfo[_user].roundRewards.add(roundReward);
                        rewardInfo[_user].totalRewards = rewardInfo[_user].totalRewards.add(roundReward);
                        rewardInfo[_user].availableRewards = rewardInfo[_user].availableRewards.add(roundReward);
                        
                        // Increase round number
                        stake.roundNumber = currentRound.add(1);
                        
                        // Update level rewards
                        for (uint256 k = 0; k < LEVEL_COUNT; k++) {
                            address upline = userInfo[_user].referrer;
                            uint256 uplineLevel = userInfo[upline].level;
                            if (upline == address(0)) {
                                break;
                            } else if ((upline == defaultReferrer || uplineLevel >= k) && userInfo[upline].totalStake > 0) {
                                if (k < levelPercentage.length) {
                                    uint256 levelRewardPercentage = levelPercentage[k];
                                    uint256 levelReward = roundReward.mul(levelRewardPercentage).div(constDiv);
                                    rewardInfo[upline].levelRewards = rewardInfo[upline].levelRewards.add(levelReward);
                                    rewardInfo[upline].totalRewards = rewardInfo[upline].totalRewards.add(levelReward);
                                    rewardInfo[upline].availableRewards = rewardInfo[upline].availableRewards.add(levelReward);
                                }
                            }
                            upline = userInfo[upline].referrer;
                            uplineLevel = userInfo[upline].level;
                        }
                        
                        currentRound++;
                    } else {
                        break;
                    }
                }
            }
        }
    }
    // Get the level of the user
    function _getLevelNow(address _user) private view returns (uint256) {
        uint256 totalReferrals = userInfo[_user].totalReferrals;
        return
            totalReferrals == 0? 0 : ( totalReferrals >= 2 && totalReferrals <= 10 ? totalReferrals - 1 : (totalReferrals == 12 ? 10 : userInfo[_user].level));
    }

    // Get the reward limit based on direct referrals
    function calculateRewardLimit(address _user) public view returns (uint256) {
        uint256 totalReferrals = userInfo[_user].totalReferrals;
        return userInfo[_user].totalStake.mul(totalReferrals >= 2 ? 3 : 2);
    }

    function _updateRewardLimit(address _user) private {
        UserInfo storage user = userInfo[_user];
        user.rewardLimit = calculateRewardLimit(_user);
    }
    // Update rewrds for all users
    function updateAllRewards() external {
        for (uint i = 0; i < stakers.length; i++) {
            _updateRewards(stakers[i]);
        }
    }

}