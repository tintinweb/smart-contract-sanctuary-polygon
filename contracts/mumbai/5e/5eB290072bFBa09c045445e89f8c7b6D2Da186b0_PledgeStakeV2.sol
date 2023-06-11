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
    uint256 private constant numOfRounds = 12;
    uint256[] private roundRewardPercentages = [3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 12, 13];
    uint256 private constant levelCount = 10;
    uint256[] private levelRewards = [25, 10, 5, 5, 5, 3, 3, 5, 5, 10];
     // Define struct for user data
    struct UserInfo {
        address referrer;
        uint256 totalStake;
        uint256 startTime;
        uint256 rewardLimit;
    }
     // Define mapping to store user data
    mapping(address => UserInfo) public userInfo;
     // Define struct for stake data
    struct StakeInfo {
        uint256 amount;
        uint256 startTime;
        bool unstaked;
    }
     mapping(address => StakeInfo[]) public stakes;
     // Define struct for reward data
    struct RewardInfo {
        uint256 directRewards;
        uint256 roundRewards;
        uint256 levelRewards;
        uint256 withdrawable;
        uint256 withdrawn;
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
    function register(address _referrer) external {
        require(_referrer != address(0), "Invalid referrer address");
        require(userInfo[_referrer].totalStake > 0 || _referrer == defaultReferrer, "Invalid referrer");
        require(userInfo[msg.sender].referrer == address(0), "User already registered");
         UserInfo storage user = userInfo[msg.sender];
        user.referrer = _referrer;
        user.startTime = block.timestamp;
        user.rewardLimit = 0;
         referrals[_referrer].push(msg.sender);
         emit Register(msg.sender, _referrer);
    }
     // Function to stake an amount
    function stake(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than zero");
        _stake(msg.sender, _amount);
    }
     function _stake(address _user, uint256 _amount) internal {
        require(_amount > 0, "Amount must be greater than zero");
         Pledge.transferFrom(_user, address(this), _amount);
         StakeInfo memory newStake = StakeInfo({
            amount: _amount,
            startTime: block.timestamp,
            unstaked: false
        });
         stakes[_user].push(newStake);
        userInfo[_user].totalStake = userInfo[_user].totalStake.add(_amount);
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
     function calculateDirectReward(address _user) internal view returns (uint256) {
        uint256 directRewardPercentage = 6;
        address[] memory directs = referrals[_user];
        uint256 totalDirectReward = 0;
         for (uint256 i = 0; i < directs.length; i++) {
            StakeInfo[] memory userStakes = stakes[directs[i]];
             for (uint256 j = 0; j < userStakes.length; j++) {
                StakeInfo memory userStake = userStakes[j];
                uint256 stakeAmount = userStake.amount;
                uint256 directReward = stakeAmount.mul(directRewardPercentage).div(100);
                totalDirectReward = totalDirectReward.add(directReward);
            }
        }
         return totalDirectReward;
    }
     function calculateRoundReward(address _user) internal view returns (uint256) {
        uint256 totalRoundReward = 0;
        StakeInfo[] storage userStakes = stakes[_user];
         for (uint256 i = 0; i < userStakes.length; i++) {
            StakeInfo storage userStake = userStakes[i];
             if (userStake.unstaked) {
                continue;
            }
             uint256 stakeAmount = userStake.amount;
            uint256 startTime = userStake.startTime;
            uint256 currentTime = block.timestamp;
            uint256 elapsedTime = currentTime.sub(startTime);
            uint256 currentRound = elapsedTime.div(roundDuration).add(1);
             if (currentRound <= numOfRounds) {
                uint256 roundRewardPercentage;
                 if (currentRound <= roundRewardPercentages.length) {
                    roundRewardPercentage = roundRewardPercentages[currentRound - 1];
                } else {
                    roundRewardPercentage = roundRewardPercentages[roundRewardPercentages.length - 1];
                }
                 uint256 roundRewards = stakeAmount.mul(roundRewardPercentage).div(100);
                totalRoundReward = totalRoundReward.add(roundRewards);
            }
        }
         return totalRoundReward;
    }
     function calculateLevelReward(address _user) internal view returns (uint256) {
        uint256 roundReward = rewards[_user].roundRewards;
        uint256[] memory levelRewardsResult = new uint256[](levelCount);
        address[] memory directs = getDirectReferrals(_user);
         // Calculate level rewards for each level
        for (uint256 i = 0; i < levelCount; i++) {
            uint256 requiredUsers = i + 2;
            uint256 rewardPercentage = levelRewards[i];
             // Check if the required number of users is met on level 1
            uint256 levelReward =
                requiredUsers <= directs.length ? roundReward : 0;
             levelRewardsResult[i] = (levelReward * rewardPercentage) / 100;
        }
         uint256 totalLevelReward = 0;
         for (uint256 i = 0; i < levelRewardsResult.length; i++) {
            totalLevelReward = totalLevelReward.add(levelRewardsResult[i]);
        }
         return totalLevelReward;
    }
     function withdraw() external {
        UserInfo storage user = userInfo[msg.sender];
        require(user.totalStake > 0, "No stakes available");
         // Get direct referrals
        address[] memory directs = getDirectReferrals(msg.sender);
         // Calculate direct rewards
        uint256 directReward = calculateDirectReward(msg.sender);
         // Calculate round rewards
        uint256 roundReward = calculateRoundReward(msg.sender);
         // Calculate level rewards
        uint256 levelReward = calculateLevelReward(msg.sender);
         // Calculate total rewards
        uint256 totalReward = directReward.add(roundReward).add(levelReward);
         // Apply capping on total rewards
        uint256 maximumEarningsCap;
         if (directs.length < 2) {
            maximumEarningsCap = user.totalStake.mul(2);
        } else if (directs.length >= 2 && userInfo[directs[0]].totalStake > 0 && userInfo[directs[1]].totalStake > 0) {
            maximumEarningsCap = user.totalStake.mul(3);
        }
         // Apply capping on total rewards
        if (totalReward > maximumEarningsCap) {
            totalReward = maximumEarningsCap;
        }
         // Transfer the total reward amount to the user
        Pledge.transfer(msg.sender, totalReward);
         emit Withdrawn(msg.sender, totalReward);
    }
     function getDirectReferrals(address _user) internal view returns (address[] memory) {
        return referrals[_user];
    }
     function getUserReferrer(address _user) external view returns (address) {
        return userInfo[_user].referrer;
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
     function getUserTotalRewards(address _user) external view returns (uint256) {
        uint256 roundRewards = calculateRoundReward(_user);
        uint256 levelRewardsAmount = calculateLevelReward(_user);
        uint256 directRewards = calculateDirectReward(_user);
         return roundRewards.add(levelRewardsAmount).add(directRewards);
    }
}