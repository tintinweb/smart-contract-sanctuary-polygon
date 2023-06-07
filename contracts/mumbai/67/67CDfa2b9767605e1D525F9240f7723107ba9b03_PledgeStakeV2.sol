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
// Solidity version
pragma solidity ^0.8.0;
//openzeppelin imports
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// Contract Name: PledgeStakeV2
contract PledgeStakeV2 {
    using SafeMath for uint256;

    IERC20 public Pledge;
    // Days in a round
    uint256 constant private daysPerRound = 30;
    // Total rounds for a Stake are 12
    uint256 constant private totalRounds = 12;
    // Stake will be locked for 30 days for Unstaking
    uint256 constant lockPerStakeTime = 30 days;
    // Direct reward for referrer is 6%
    uint256 private constant directPercents = 600;
    // Level depth for level calculation
    uint256 constant private levelDepth = 10;
    // Round reward percent for each round
    uint256[12] private roundPercents = [300, 400, 500, 600, 700, 800, 900, 1000, 1100, 1200, 1200, 1300];
    // Level reward percent for each level
    uint256[10] private levelPercents = [2500, 1000, 500, 500, 500, 300, 300, 500, 500, 1000];
    // Minumum direct refer to achive level
    uint256[10] private minDirectForLevel = [2, 3, 4, 5, 6, 7, 8, 9, 10, 12];
    // Reward capping without referrals
    uint256 constant private rewardCapNoRef = 20000;
    // Reward capping with referrals
    uint256 constant private rewardCapWithRef = 30000;
    // Default refer address
    address public defaultRefer;
    // Start time of contract
    uint256 public startTime;
    // Last distribute time
    uint256 public lastDistribute;
    // Total user
    uint256 public totalUser;
    // struct for stake info
    struct StakeInfo {
        uint256 amount;
        uint256 start;
        uint256 unlock;
        bool isUnlocked;
    }
    // mapping for stake info
    mapping (address => StakeInfo[]) public stakeInfos;
    address[] public users;
    // struct for user info
    struct UserInfo {
        address referrer;
        uint256 direct;
        uint256 level;
        uint256 totalStake;
        uint256 teamCount;
    }
    // mapping for user info
    mapping (address => UserInfo) public userInfos;
    // mapping for team users
    mapping (address => mapping (uint256 => address[])) public teamUsers;
    // struct for reward info
    struct RewardInfo {
        uint256 roundRewards;
        uint256 directRewards;
        uint256 levelRewards;
        uint256 totalRewards;
    }
    // mapping for reward info
    mapping (address => RewardInfo[]) public rewardInfos;
    // mapping for round rewards
    mapping(address => mapping(uint256 => uint256)) public roundRewards;
    // mapping for direct rewards
    mapping(address => mapping(uint256 => uint256)) public directRewards;
    // mapping for level rewards
    mapping(address => mapping(uint256 => uint256)) public levelRewards;
    // mapping for total rewards
    mapping(address => mapping(uint256 => uint256)) public totalRewards;
    //event for register
    event Register(address user, address referral);
    // event for stake
    event Stake(address user, uint256 amount);
    // event for withdraw withdrawable
    event Withdraw(address user, uint256 withdrawable);
    // event for unstake a stake
    event Unstake(address user, uint256 amount);

    // constructor for contract to set pledge token, default refer, start time and total user
    constructor(address _pledge, address _defaultRefer) {
        Pledge = IERC20(_pledge);
        defaultRefer = _defaultRefer;
        startTime = block.timestamp;
        totalUser = 0;
    }
    // function to register a user
    function register(address _referral) external {
        require(userInfos[_referral].totalStake > 0 || _referral == defaultRefer, "invalid refer");
        UserInfo storage user = userInfos[msg.sender];
        require(user.referrer == address(0), "referrer bonded");
        user.referrer = _referral;
        userInfos[_referral].teamCount++;
        totalUser++;
        emit Register(msg.sender, _referral);
    }
    // function to update team count
    function _updateTeamCount(address _user) private {
        UserInfo storage user = userInfos[_user];
        address upline = user.referrer;
        for (uint256 i = 0; i < levelDepth; i++) {
            if (upline != address(0)) {
                userInfos[upline].teamCount++;
                teamUsers[upline][i].push(_user);
                _updateLevel(upline);
                if (upline == defaultRefer) break;
                upline = userInfos[upline].referrer;
            } else {
                break;
            }
        }
    }
    // function to update referral info
    function _updateReferInfo(address _user, uint256 _amount) private {
        UserInfo storage user = userInfos[_user];
        address upline = user.referrer;
        for (uint256 i = 0; i < levelDepth; i++) {
            if (upline != address(0)) {
                userInfos[upline].totalStake += _amount;
                _updateLevel(upline);
                if (upline == defaultRefer) break;
                upline = userInfos[upline].referrer;
            } else {
                break;
            }
        }
    }

    // function to update level of a user
    function _updateLevel(address _user) private {
        UserInfo storage user = userInfos[_user];
        uint256 levelNow = _calLevelNow(_user);
        if (levelNow > user.level) {
            user.level = levelNow;
        }
    }

    // function to calculate level of a user
    function _calLevelNow(address _user) private view returns (uint256) {
        UserInfo storage user = userInfos[_user];
        uint256 directs = user.direct;
        uint256 level = 0;
        for (uint256 i = 0; i < minDirectForLevel.length; i++) {
            if (directs >= minDirectForLevel[i]) {
                level = i + 1;
            } else {
                break;
            }
        }
        return level;
    }
    // external function to create a new stake
    function stake(uint256 _amount) external {
        Pledge.transferFrom(msg.sender, address(this), _amount);
        _stake(msg.sender, _amount);
        emit Stake(msg.sender, _amount);
    }

    // private function to handle a new stake
    function _stake(address _user, uint256 _amount) private {
        require(_amount > 0, "Invalid amount");
        StakeInfo memory newStake = StakeInfo({
            amount: _amount,
            start: block.timestamp,
            unlock: block.timestamp + lockPerStakeTime,
            isUnlocked: false
        });
        stakeInfos[_user].push(newStake);
        userInfos[_user].totalStake += _amount;
        _updateReferInfo(_user, _amount);
        _updateRewardInfo(_user, _amount);
    }

    // private function to update reward info
    function _updateRewardInfo(address _user, uint256 _amount) private {
  
    }
    // function private view to get current round of a stake
    function getCurrentRound() private view returns (uint256) {
        return (block.timestamp.sub(startTime) / (daysPerRound * 1 days)) % totalRounds;
    }

    // function private view to calculate direct reward
    function _calculateDirectReward(uint256 _amount) private pure returns (uint256) {
        return _amount.mul(directPercents).div(10000);
    }

    // function private view to calculate round reward
    function _calculateRoundReward(uint256 _amount, uint256 _round) private view returns (uint256) {
        uint256 roundPercent = roundPercents[_round];
        return _amount.mul(roundPercent).div(10000);
    }


    // function private view to calculate level reward
    function _calculateLevelReward(uint256 _amount, uint256 _level) private view returns (uint256) {
        uint256 levelPercent = levelPercents[_level];
        return _amount.mul(levelPercent).div(10000);
    }


    // function private veiw to 
    function _updateRoundRewards(address _user, uint256 _round, uint256 _amount) private {
    }

    function _updateDirectRewards(address _referrer, uint256 _amount) private {
    }

    function _updateLevelRewards(address _referrer, uint256 _amount) private {
    }

    function distributeRewards(address _user, uint256 _amount) private {
    }

    function unstake(uint256 _index) external {
        
    }

    function _calculateRewardLimit(uint256 _stakeAmount, uint256 _directs) private pure returns (uint256) {
    }

    function withdraw() external {
    }
}