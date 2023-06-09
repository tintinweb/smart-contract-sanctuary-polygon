/**
 *Submitted for verification at polygonscan.com on 2023-06-08
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

// File: plg_n.sol


pragma solidity ^0.8.0;



contract PledgeStakeV2 {
    using SafeMath for uint256;

    // Staking token details
    IERC20 public Pledge;

    // Round rewards details
    uint256[] public roundRewards;
    uint256 public roundDuration;
    uint256 public totalRounds;

    // Referral rewards details
    uint256 public referralRewardPercentage;

    // Level rewards details
    uint256[] public levelRewards;
    uint256[] public levelUserRequirements;

    // Staking details
    struct Stake {
        uint256 amount;
        uint256 startTime;
    }

    mapping(address => Stake[]) public stakes;
    mapping(address => address) public referrals;

    // Rewards details
    struct Rewards {
        uint256 roundRewards;
        uint256 referralRewards;
        uint256 levelRewards;
    }

    mapping(address => Rewards) public rewards;

    // Withdrawable details
    mapping(address => uint256) public withdrawable;
    mapping(address => uint256) public totalWithdrawn;

    struct User {
        address referrer;
        uint256 totalReferrals;
        uint256 totalStaked;
        uint256 totalUnstaked;
        uint256 teamCount;
        bool exists;
    }

    mapping(address => User) public users;

    address public defaultReferral;
    uint256 public startTime;
    uint256 public totalUser;
    event Register(address user, address referral);
    event Staked(address user, uint256 amount);
    // event for withdraw withdrawable
    event Withdraw(address user, uint256 withdrawable);
    // event for unstake a stake
    event Unstake(address user, uint256 amount);
    constructor( address _pledge, address _defaultReferral) { 
        Pledge = IERC20(_pledge);
        defaultReferral = _defaultReferral;
        startTime = block.timestamp;
        totalUser = 0;

        // Set the hardcoded values
        roundRewards = [3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 12, 13];
        roundDuration = 300;
        totalRounds = roundRewards.length;
        referralRewardPercentage = 6;
        levelRewards = [25, 10, 5, 5, 5, 3, 3, 5, 5, 10];
        levelUserRequirements = [2, 3, 4, 5, 6, 7, 8, 9, 10, 12];
    }

    function register(address _referral) external {
        require(users[_referral].totalStaked > 0 || _referral == defaultReferral, "Invalid referral address");
        User storage user = users[msg.sender];
        require(user.referrer == address(0), "Referrer already set");
        user.referrer = _referral;
        users[_referral].totalReferrals++;
        totalUser++;
        emit Register(msg.sender, _referral);
    }

    function stake(uint256 _amount) external {
        require(_amount > 0, "Invalid stake amount");

        Pledge.transferFrom(msg.sender, address(this), _amount);

        _stake(msg.sender, _amount);
    }

    function _stake(address _user, uint256 _amount) internal {
        stakes[_user].push(Stake(_amount, block.timestamp));

        users[_user].totalStaked = users[_user].totalStaked.add(_amount);

        // Calculate and update referral rewards
        address referral = referrals[_user];
        if (referral != address(0)) {
            uint256 referralReward = _amount.mul(referralRewardPercentage).div(100);
            rewards[referral].referralRewards = rewards[referral].referralRewards.add(referralReward);
            withdrawable[referral] = withdrawable[referral].add(referralReward);
        }
    }

    function updateLevel(address _user) internal {
        uint256 userStakesLength = stakes[_user].length;
        uint256 userReferralCount = 0;

        for (uint256 i = 0; i < userStakesLength; i++) {
            address referral = referrals[_user];

            if (referral != address(0) && users[referral].totalStaked > 0) {
                userReferralCount++;
            }

            _user = referral;
        }

        for (uint256 i = 0; i < levelRewards.length; i++) {
            if (userReferralCount >= levelUserRequirements[i]) {
                rewards[_user].levelRewards = rewards[_user].levelRewards.add(levelRewards[i]);
                withdrawable[_user] = withdrawable[_user].add(levelRewards[i]);
            }
        }
    }

    function calculateRoundReward(address _user, uint256 _stakeIndex) internal view returns (uint256) {
        require(_stakeIndex < stakes[_user].length, "Invalid stake index");

        Stake storage userStake = stakes[_user][_stakeIndex];
        uint256 timePassed = block.timestamp.sub(userStake.startTime);

        if (timePassed >= roundDuration.mul(totalRounds)) {
            return userStake.amount.mul(roundRewards[totalRounds.sub(1)]).div(100);
        }

        uint256 currentRound = timePassed.div(roundDuration);
        return userStake.amount.mul(roundRewards[currentRound]).div(100);
    }

    function withdraw() external {
        require(withdrawable[msg.sender] > 0, "No withdrawable amount");

        uint256 amount = withdrawable[msg.sender];
        withdrawable[msg.sender] = 0;
        totalWithdrawn[msg.sender] = totalWithdrawn[msg.sender].add(amount);

        Pledge.transfer(msg.sender, amount);
    }

    function unstake(uint256 _stakeIndex) external {
        require(_stakeIndex < stakes[msg.sender].length, "Invalid stake index");

        Stake storage userStake = stakes[msg.sender][_stakeIndex];
        require(block.timestamp.sub(userStake.startTime) >= roundDuration, "Cannot unstake before round 1 completion");

        uint256 roundReward = calculateRoundReward(msg.sender, _stakeIndex);
        uint256 totalAmountStaked = users[msg.sender].totalStaked.add(rewards[msg.sender].roundRewards).add(rewards[msg.sender].referralRewards).add(rewards[msg.sender].levelRewards);

        if (referrals[msg.sender] != address(0) && users[referrals[msg.sender]].totalStaked >= 2) {
            // User has referred 2 or more directs who have staked
            uint256 rewardCap = users[msg.sender].totalStaked.mul(3);
            if (totalAmountStaked > rewardCap) {
                roundReward = rewardCap.sub(totalAmountStaked);
            }
        } else {
            // User has referred less than 2 directs
            uint256 rewardCap = users[msg.sender].totalStaked.mul(2);
            if (totalAmountStaked > rewardCap) {
                roundReward = rewardCap.sub(totalAmountStaked);
            }
        }

        rewards[msg.sender].roundRewards = rewards[msg.sender].roundRewards.add(roundReward);
        withdrawable[msg.sender] = withdrawable[msg.sender].add(roundReward);

        users[msg.sender].totalUnstaked = users[msg.sender].totalUnstaked.add(userStake.amount);

        delete stakes[msg.sender][_stakeIndex];

        if (users[msg.sender].totalStaked == users[msg.sender].totalUnstaked) {
            delete users[msg.sender];
            delete referrals[msg.sender];
        }
    }
}