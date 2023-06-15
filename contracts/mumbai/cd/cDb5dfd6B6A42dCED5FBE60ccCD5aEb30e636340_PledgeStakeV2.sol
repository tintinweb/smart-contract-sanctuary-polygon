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
    uint256 private constant roundDuration = 300 seconds;
    uint256 private constant maxNumOfRounds = 12;
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
    }
    // Define mapping to store user data
    mapping(address => UserInfo) public userInfo;
    mapping(address => mapping(uint256 => address[])) public teamUsers;
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
        require(userInfo[_referrer].totalStake > 0 || _referrer == defaultReferrer,"Invalid referrer");
        UserInfo storage user = userInfo[msg.sender];
        require(userInfo[msg.sender].referrer == address(0),"User already registered");
        user.referrer = _referrer;
        user.startTime = block.timestamp;
        _updateTeamCount(msg.sender);
        totalUsers = totalUsers.add(1);
        emit Register(msg.sender, _referrer);
    }

    // Function to stake tokens
    function stake(uint256 _amount) external {
        Pledge.transferFrom(msg.sender, address(this), _amount);
        _stake(msg.sender, _amount);
    }

    function _stake(address _user, uint256 _amount) private {
        require(_amount > 0, "Amount must be greater than zero");
        UserInfo storage user = userInfo[_user];
        require(user.referrer != address(0), "User not registered");
        // Calculate direct reward for referrer
        address referrer = user.referrer;
        uint256 directReward = (_amount * directRewardPercentage) / 100;
        if (referrer != address(0)) {
            UserInfo storage referrerInfo = userInfo[referrer];
            referrerInfo.totalDirectStake = referrerInfo.totalDirectStake.add(
                _amount
            );
            //Referral Count Update
            referrerInfo.totalReferrals = referrerInfo.totalReferrals.add(1);
            rewards[referrer].directRewards = rewards[referrer].directRewards.add(directReward);
            rewards[referrer].totalRewards = rewards[referrer].totalRewards.add(directReward);
            rewards[referrer].availableRewards = rewards[referrer].availableRewards.add(directReward);
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
        _updateReferInfo(msg.sender, _amount);
        _updateRewards(msg.sender, _amount);
        _updateLevel(msg.sender);
        emit Staked(_user, _amount);
    }
    // Calculate Round Rewards
    function _calRoundRewards(address _user, uint256 _amount) private view returns(uint256){
        StakeInfo[] storage userStakes = stakes[_user];
        StakeInfo storage userStake = userStakes[userStakes.length - 1];
        uint256 stakeStartTime = userStake.startTime;
        uint256 roundRewards = 0;
        uint256 round = (block.timestamp.sub(stakeStartTime)).div(roundDuration);
        uint256 roundEndTime = stakeStartTime.add(roundDuration.mul(round.add(1)));
        if (round < maxNumOfRounds && block.timestamp >= roundEndTime) {
            roundRewards = (_amount * roundRewardPercentages[round]) / 100;
        }
        return roundRewards;
    }
    function _updateTeamCount(address _user) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for (uint256 i = 0; upline != address(0) && i < levelCount; i++) {
            userInfo[upline].teamCount = userInfo[upline].teamCount.add(1);
            teamUsers[upline][i].push(_user);
            _updateLevel(upline);
            if (upline == defaultReferrer) break;
            upline = userInfo[upline].referrer;
        }
    }
    function _updateReferInfo(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for (uint256 i = 0; upline != address(0) && i < levelCount; i++) {
            userInfo[upline].totalTeamStake = userInfo[upline].totalTeamStake.add(_amount);
            _updateLevel(upline);
            if (upline == defaultReferrer) break;
            upline = userInfo[upline].referrer;
        }
    }
    function _updateLevel(address _user) private{
        UserInfo storage user = userInfo[_user];
        uint256 levelNow = _getLevelNow(_user);
        user.level = levelNow;
        }
    function _updateRewards(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        while (upline != address(0) && userInfo[upline].totalReferrals >= 2) {
            uint256 level = userInfo[upline].level;
            uint256 levelReward = (_calRoundRewards(_user, _amount) * levelPercentage[level - 1]) / 100;
            rewards[upline].levelRewards = rewards[upline].levelRewards.add(levelReward);
            rewards[upline].totalRewards = rewards[upline].totalRewards.add(levelReward);
            rewards[upline].availableRewards = rewards[upline].availableRewards.add(levelReward);
            if (upline == defaultReferrer) break;
            upline = userInfo[upline].referrer;
        }
        // update Round Rewards
        rewards[_user].roundRewards = rewards[_user].roundRewards.add(_calRoundRewards(_user, _amount));
        rewards[_user].totalRewards = rewards[_user].totalRewards.add(_calRoundRewards(_user, _amount));
        rewards[_user].availableRewards = rewards[_user].availableRewards.add(_calRoundRewards(_user, _amount));
    }

    // Function to withdraw rewards
    function withdraw() external {
        
        uint256 directRewards = rewards[msg.sender].directRewards;
        uint256 roundRewards = rewards[msg.sender].roundRewards;
        uint256 levelRewards = rewards[msg.sender].levelRewards;
        uint256 UnstakeAmount = rewards[msg.sender].UnstakeAmount;

        uint256 totalRewards = directRewards.add(roundRewards).add(levelRewards).add(UnstakeAmount);
        uint256 withdrawnRewards = rewards[msg.sender].withdrawnRewards;

        uint256 withdrawable = totalRewards.sub(withdrawnRewards);
        require(withdrawable > 0, "No rewards available for withdrawal");
        // Apply reward limit based on direct referrals
        uint256 rewardLimit = calculateRewardLimit(msg.sender);
        require(withdrawable <= rewardLimit, "Exceeded reward limit");

        rewards[msg.sender].withdrawnRewards = withdrawnRewards.add(withdrawable);
        rewards[msg.sender].availableRewards = rewards[msg.sender].availableRewards.sub(withdrawable);
        Pledge.transfer(msg.sender, withdrawable);
        emit Withdrawn(msg.sender, withdrawable);
    }

    function _getLevelNow(address _user) private view returns (uint256) {
        uint256 totalReferrals = userInfo[_user].totalReferrals;
        if(totalReferrals == 0){
            return 0;
        }
        else if(totalReferrals >= 2 && totalReferrals <= 10){
            return totalReferrals - 1;
        }
        else if(totalReferrals == 12){
            return 10;
        }
        return userInfo[_user].level;
    }

    function unstake(uint256 _index) external {
        UserInfo storage user = userInfo[msg.sender];
        require(user.totalStake > 0, "No stakes available");
        require(_index < stakes[msg.sender].length, "Invalid stake index");
        require(!stakes[msg.sender][_index].unstaked, "Stake already unstaked");
        uint256 stakeAmount = stakes[msg.sender][_index].amount;
        uint256 roundNumber = (block.timestamp -
        stakes[msg.sender][_index].startTime) / roundDuration;
        require(roundNumber >= 1, "Stake has not completed round 1");
        // Update rewards
        stakes[msg.sender][_index].unstaked = true;
        user.totalStake = user.totalStake.sub(stakeAmount);
        // Add the unstaked amount to withdrawable rewards
        rewards[msg.sender].availableRewards = rewards[msg.sender].availableRewards.add(stakeAmount);
        emit Unstaked(msg.sender, stakeAmount);
    }
    function calculateRewardLimit(address _user) private view returns (uint256) {
        uint256 totalReferrals = userInfo[_user].totalReferrals;
        if (totalReferrals >= 2) {
            return userInfo[_user].totalStake.mul(3);
        } else {
            return userInfo[_user].totalStake.mul(2);
        }
    }

}