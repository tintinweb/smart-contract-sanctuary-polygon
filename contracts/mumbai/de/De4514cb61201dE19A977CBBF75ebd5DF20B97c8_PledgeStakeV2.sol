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
    address public defaultReferrer;
    uint256 private constant roundDuration = 300 seconds;
    uint256 private constant maxNumOfRounds = 12;
    uint256 private constant directRewardPercentage = 6;
    uint256[] private roundRewardPercentages = [3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 12, 13];
    uint256 private constant levelCount = 10;
    uint256[] private levelRewards = [25, 10, 5, 5, 5, 3, 3, 5, 5, 10];
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
        address[] referrals;
        uint256 totalReferrals;
        uint256[] referralStakes;
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
        uint256 totalRewards;
        uint256 withdrawnRewards;
        uint256 availableRewards;
    }
    mapping(address => RewardInfo) public rewards;
    mapping(address => address[]) public referrals;
    event Register(address indexed user, address indexed referrer);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event UserDeleted(address indexed user);

     constructor(address _pledge, address _defaultReferrer) {
        Pledge = IERC20(_pledge);
        defaultReferrer = _defaultReferrer;
    }
     // Function to register a user with a referrer
    function register(address _referral) external {
        require(_referral != address(0), "Invalid referrer address");
        require(userInfo[_referral].totalStake > 0 || _referral == defaultReferrer, "Invalid referrer");
        UserInfo storage user = userInfo[msg.sender];
        require(userInfo[msg.sender].referrer == address(0), "User already registered");
        user.referrer = _referral;
        user.startTime = block.timestamp;
        _updateTeamCount(msg.sender);
         emit Register(msg.sender, _referral);
    }
    function _updateTeamCount(address _user)  private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for (uint256 i = 0; i < levelCount; i++) {
            if (upline != address(0)) {
                userInfo[upline].teamCount = userInfo[upline].teamCount.add(1);
                teamUsers[upline][i].push(_user);
                _updateLevel(upline);
                if(upline == defaultReferrer) break;
                upline = userInfo[upline].referrer;
            } else {
                break;
            }
    
        }
    }
    function _updateReferInfo(address _user, uint256 _amount)  private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for(uint256 i = 0; i < levelCount; i++) {
            if(upline != address(0)) {
                userInfo[upline].totalTeamStake = userInfo[upline].totalTeamStake.add(_amount);
                _updateLevel(upline);
                if(upline == defaultReferrer) break;
                upline = userInfo[upline].referrer;
            } else {
                break;
            }
        }
    }
    function _updateLevel(address _user) private {
        UserInfo storage user = userInfo[_user];
        uint256 levelNow = _getLevelNow(_user);
        if(levelNow > user.level) {
            user.level = levelNow;
        }
    }
    function _getLevelNow(address _user) private view returns(uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 levelNow = 0;
        uint256 referredUsers = user.referrals.length;
        uint256 stakedUsers = 0;
        
        for (uint256 i = 0; i < referredUsers; i++) {
            if (userInfo[user.referrals[i]].totalStake > 0) {
                stakedUsers++;
            }
        }
        
        if (stakedUsers >= 2) {
            levelNow = 1;
        }
        if (stakedUsers >= 3) {
            levelNow = 2;
        }
        if (stakedUsers >= 4) {
            levelNow = 3;
        }
        if (stakedUsers >= 5) {
            levelNow = 4;
        }
        if (stakedUsers >= 6) {
            levelNow = 5;
        }
        if (stakedUsers >= 7) {
            levelNow = 6;
        }
        if (stakedUsers >= 8) {
            levelNow = 7;
        }
        if (stakedUsers >= 9) {
            levelNow = 8;
        }
        if (stakedUsers >= 10) {
            levelNow = 9;
        }
        if (stakedUsers >= 12) {
            levelNow = 10;
        }
        
        return levelNow;
    }        
     // Function to stake an amount
    function stake(uint256 _amount) external {
        Pledge.transferFrom(msg.sender, address(this), _amount);
        require(_amount > 0, "Amount must be greater than zero");
        _stake(msg.sender, _amount);
        emit Staked(msg.sender, _amount);
    }
    function _stake(address _user, uint256 _amount) internal {
    require(_amount > 0, "Amount must be greater than zero");
    UserInfo storage user = userInfo[_user];
    require(user.referrer != address(0), "User not registered");
     // Calculate direct reward for referrer
    address referrer = user.referrer;
    uint256 directReward = _amount * directRewardPercentage / 100;
    if (referrer != address(0)) {
        UserInfo storage referrerInfo = userInfo[referrer];
        referrerInfo.totalDirectStake = referrerInfo.totalDirectStake.add(_amount);
        rewards[referrer].directRewards = rewards[referrer].directRewards.add(directReward);
    }
     // Add stake to user's stake history
    StakeInfo memory newStake = StakeInfo({
        amount: _amount,
        startTime: block.timestamp,
        unstaked: false
    });
    stakes[_user].push(newStake);
     // Update user's total stake
    user.totalStake = user.totalStake.add(_amount);
     emit Staked(_user, _amount);
}
     function unstake(uint256 _index) external {
        UserInfo storage user = userInfo[msg.sender];
        require(user.totalStake > 0, "No stakes available");
        require(_index < stakes[msg.sender].length, "Invalid stake index");
        require(!stakes[msg.sender][_index].unstaked, "Stake already unstaked");
         uint256 stakeAmount = stakes[msg.sender][_index].amount;
        uint256 totalAmount = stakeAmount;
        require(totalAmount <= user.rewardLimit, "Unstake amount exceeds reward limit");
         // Calculate the round number based on the stake's duration
        uint256 roundNumber = (block.timestamp - stakes[msg.sender][_index].startTime) / roundDuration;
        require(roundNumber >= 1, "Stake has not completed round 1");
         user.rewardLimit = user.rewardLimit.sub(totalAmount);
        user.totalStake = user.totalStake.sub(stakeAmount);
        stakes[msg.sender][_index].unstaked = true;
         Pledge.transfer(msg.sender, totalAmount);
         emit Unstaked(msg.sender, stakeAmount);
         if (user.totalStake == 0 && stakes[msg.sender].length == 0) {
            delete userInfo[msg.sender];
            emit UserDeleted(msg.sender);
        }
    }
     function calculateRoundReward(address _user, uint256 _amount) internal view returns (uint256) {

    }
     function calculateLevelReward(address _user) internal view returns (uint256) {
        
    }
     function withdraw() external {
        
    }
     function getDirectReferrals(address _user) internal view returns (address[] memory) {
        return referrals[_user];
    }

     function getUserStake(address _user) external view returns (uint256) {
        return userInfo[_user].totalStake;
    }
     function getUserStakeCount(address _user) external view returns (uint256) {
        return stakes[_user].length;
    }
     function getUserStakeAtIndex(address _user, uint256 _index) external view returns (uint256, uint256) {
        require(_index < stakes[_user].length, "Invalid index");
         StakeInfo storage userStake = stakes[_user][_index];
         return (userStake.amount, userStake.startTime);
    }
}