// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// bankonator

struct Stake {
    uint256 stakedAmount;
    uint256 lastStakedTime;
    uint256 totalEarned;

    // uint256 staked;
    // uint256 lastStakedTime;
    // uint256 lastUnStakedTime;
    // uint256 oldClaimableAmount;
    // uint256 lastClaimedAmount;
    // uint256 lastClaimedTime;
    // uint256 rewardPeriod;
    // uint256 totalEarned;
}

struct MembershipLevel {
    uint256 threshold;
    uint256 APY;
}

contract BankOnatorStaking is Ownable {
    using SafeMath for uint256;
    uint256 constant DIVIDER = 1000;
    uint256 constant DECIMAL = 7;
    uint256 constant APYBASE = 31449600; // in seconds = 364 days

    uint256 public rewardPeriod = 604800;
    uint256 public rewardMembers;

    MembershipLevel[] public membershipLevels;
    uint256 public levelsCount = 0;

    IERC20 _token;
    address locker;
    mapping(address => Stake) private _stakes;

    event MembershipAdded(
        uint256 threshold,
        uint256 apy,
        uint256 newLevelsCount
    );
    event MembershipRemoved(uint256 index, uint256 newLevelsCount);
    event Staked(address fromUser, uint256 amount);
    event Claimed(address byUser, uint256 reward);
    event Unstaked(address byUser, uint256 amount);

    constructor(address token) {
        addMembership(750000000 * 10 ** DECIMAL, 50);
        addMembership(1500000000 * 10 ** DECIMAL, 60);
        addMembership(3000000000 * 10 ** DECIMAL, 80);
        addMembership(5000000000 * 10 ** DECIMAL, 100);
        addMembership(8500000000 * 10 ** DECIMAL, 120);
        setToken(token);
    }

    /**
     * @dev change staking token
     */
    function setToken(address token) public onlyOwner {
        _token = IERC20(token);
    }

    /**
     * @dev change locker address
     */
    function setLocker(address _locker) external onlyOwner {
        locker = _locker;
    }

    function stake(uint256 tokens) external {
        require(tokens > 0, "You need to stake token greater than 0");
        // require(
        //     membershipLevels[0].threshold <=
        //         tokens + _stakes[msg.sender].staked,
        //     "Insufficient tokens for staking."
        // );
        _token.transferFrom(msg.sender, locker, tokens);

        // if (_stakes[msg.sender].staked != 0) {
        //     uint256 totalStaked = _stakes[msg.sender].staked;
        //     _stakes[msg.sender].oldClaimableAmount = _stakes[msg.sender]
        //         .oldClaimableAmount
        //         .add(
        //             calculateReward(
        //                 getAPY(totalStaked),
        //                 _stakes[msg.sender].lastStakedTime,
        //                 totalStaked
        //             )
        //         );
        // } else rewardMembers++;

        // _stakes[msg.sender].lastStakedTime = block.timestamp;
        _stakes[msg.sender].stakedAmount = _stakes[msg.sender].stakedAmount.add(
            tokens
        );

        emit Staked(msg.sender, tokens);
    }

    function unstake(uint256 unstakeAmount) external {
        require(unstakeAmount > 0, "Unstake Amount must be greater than 0");
        require(
            unstakeAmount <= _stakes[msg.sender].stakedAmount,
            "Unstake amount exceeds total staked amount"
        );

        // uint256 resultingUnstakeAmt = _stakes[msg.sender].staked -
        //     unstakeAmount;

        // require(
        //     resultingUnstakeAmt == 0 ||
        //         resultingUnstakeAmt >= membershipLevels[0].threshold,
        //     "By unstaking this amount of tokens you are falling under the minimum threshold level to stake tokens. Either unstake all or unstake less tokens."
        // );

        // _token.transferFrom(locker, msg.sender, unstakeAmount);
        // uint256 totalStaked = _stakes[msg.sender].staked;
        // _stakes[msg.sender].oldClaimableAmount = _stakes[msg.sender]
        //     .oldClaimableAmount
        //     .add(
        //         calculateReward(
        //             getAPY(totalStaked),
        //             _stakes[msg.sender].lastStakedTime,
        //             totalStaked
        //         )
        //     );
        _stakes[msg.sender].stakedAmount = _stakes[msg.sender].stakedAmount.sub(
            unstakeAmount
        );
        // _stakes[msg.sender].lastUnStakedTime = block.timestamp;
        // _stakes[msg.sender].lastStakedTime = block.timestamp;
        // _stakes[msg.sender].rewardPeriod = rewardPeriod;
        // if (_stakes[msg.sender].staked == 0) {
        //     delete _stakes[msg.sender];
        // }
        emit Unstaked(msg.sender, unstakeAmount);
    }

    /**
     * @dev Change Reward Period
     */
    // function changeRewardPeriod(uint256 newPeriod) external onlyOwner {
    //     require(newPeriod > 0, "Reward Period cannot be 0");
    //     rewardPeriod = newPeriod;
    // }

    // function getStakeInfo(address user)
    //     external
    //     view
    //     returns (
    //         uint256,
    //         uint256,
    //         uint256,
    //         uint256
    //     )
    // {
    //     return (
    //         _stakes[user].staked,
    //         getAPY(_stakes[user].staked),
    //         _stakes[user].lastClaimedTime,
    //         _stakes[user].rewardPeriod
    //     );
    // }

    /**
     *  @dev Returns TimeClaimable Date inform of timestamp ie {Addition Between {Greater Between lastStakedTime | lastClaimedTime | lastUnStakedTime} And userRewardPeriod}
     */
    // function nextClaimableDate(address user) public view returns (uint256) {
    //     uint256 lastStakedTime = _stakes[user].lastStakedTime;
    //     uint256 lastClaimedTime = _stakes[user].lastClaimedTime;
    //     uint256 lastUnStakedTime = _stakes[user].lastUnStakedTime;

    //     return
    //         (
    //             (lastStakedTime > lastClaimedTime &&
    //                 lastStakedTime > lastUnStakedTime)
    //                 ? lastStakedTime
    //                 : (
    //                     lastClaimedTime > lastUnStakedTime
    //                         ? lastClaimedTime
    //                         : lastUnStakedTime
    //                 )
    //         ) + _stakes[user].rewardPeriod;
    // }

    /** @dev Check if user can claim or not.
     * Returns true if currenttime is greater than addition of last interaction time
     * ie {Greater number between lastStakedTime, lastUnStakedTime, and lastClaimedTime} and RewardPeriod
     */
    // function canClaim(address user) public view returns (bool) {
    //     return block.timestamp > nextClaimableDate(user) ? true : false;
    // }

    /**
     * @dev Transfer Total reward earned by user after last interaction
     * ie(lastStaked | lastClaimed | lastUnStaked)
     */
    // function claim() public returns (bool) {
    //     require(
    //         canClaim(msg.sender),
    //         "Please wait for the next reward period to claim"
    //     );

    //     uint256 totalClaimableAmount = _stakes[msg.sender]
    //         .oldClaimableAmount
    //         .add(getTotalRewards(msg.sender));
    //     _stakes[msg.sender].totalEarned = _stakes[msg.sender].totalEarned.add(
    //         totalClaimableAmount
    //     );
    //     _token.transferFrom(locker, msg.sender, totalClaimableAmount);
    //     _stakes[msg.sender].lastStakedTime = block.timestamp;
    //     _stakes[msg.sender].oldClaimableAmount = 0;
    //     _stakes[msg.sender].rewardPeriod = rewardPeriod;
    //     _stakes[msg.sender].lastClaimedTime = block.timestamp;
    //     _stakes[msg.sender].lastClaimedAmount = totalClaimableAmount;

    //     emit Claimed(msg.sender, totalClaimableAmount);
    //     return true;
    // }

    /**
     * @dev Last Reward Amount Claimed By User
     * @param {address} Address of user
     * @return {number} Total amount of token claimed
     */
    function getTotalEarned(address user) public view returns (uint256) {
        return _stakes[user].totalEarned;
    }

    /**
     * @dev Last Claimed Amount By User
     * @param {address} Address of user
     * @return {number} Total amount of token claimed previously
     */
    // function getLastClaimedAmount(address user) public view returns (uint256) {
    //     return _stakes[user].lastClaimedAmount;
    // }

    /**
     * @dev GetNext Claimable Amount for User
     * @param {address} Address of user
     * @return {number} Total amount of token claimable token in 7 decimals
     */
    // function getNextClaimableReward(address user)
    //     public
    //     view
    //     returns (uint256)
    // {
    //     return _stakes[user].oldClaimableAmount.add(getTotalRewards(user));
    // }

    /**
     * @dev Emergency WithDraw from Admin of particular user
     * @param {address} Address of user to be unstaked with reward.
     * Note On Emergency WithDraw it will unstake all amount for particular user along claimable amount and delete user from userlist
     */
    // function emergency_withdraw(address userAddress)
    //     external
    //     onlyOwner
    //     returns (bool)
    // {
    //     uint256 totalClaimableAmount = _stakes[userAddress]
    //         .oldClaimableAmount
    //         .add(getTotalRewards(msg.sender));

    //     uint256 unstakeAmount = _stakes[userAddress].staked;

    //     _token.transferFrom(
    //         locker,
    //         userAddress,
    //         totalClaimableAmount + unstakeAmount
    //     );

    //     delete _stakes[userAddress];
    //     // Decreases number of total active rewardMembers
    //     rewardMembers--;
    //     emit Claimed(userAddress, totalClaimableAmount);
    //     emit Unstaked(userAddress, unstakeAmount);
    //     return true;
    // }

    /**
     * @dev get userdetails from staking contract based on address given
     * @param {address} address of user to get stake details
     * @return {list of integer} Returns list values of user based on address given. {
     * value 1: Total staked amount
     * value 2: Timestamp of last staked
     * value 3: TimeStamp of last unstaked
     * value 4: Reserved Claimable Amount. Note Intially value of oldClaimable amount is set to zero.
     * Value 5: When users stake or unstake we will save reward for previous period on oldClaimableAmount and will reset once the user claims it
     * value 6: LastClaimedAmount
     * value 7: RewardPeriod for user
     * value 8: Total Claimed Amount }
     */
    // function getUserDetails(address userAddress)
    //     public
    //     view
    //     returns (
    //         uint256,
    //         uint256,
    //         uint256,
    //         uint256,
    //         uint256,
    //         uint256,
    //         uint256,
    //         uint256
    //     )
    // {
    //     Stake storage user = _stakes[userAddress];
    //     return (
    //         user.staked,
    //         user.lastStakedTime,
    //         user.lastUnStakedTime,
    //         user.oldClaimableAmount,
    //         user.lastClaimedAmount,
    //         user.lastClaimedTime,
    //         user.rewardPeriod,
    //         user.totalEarned
    //     );
    // }

    /**
     * @dev Calculates the user's reward for the current period. Current period is based on last interaction (Claim, Stake, Unstake).
     * @param {address} Address of user to calculate reward.
     */

    // function getTotalRewards(address user) public view returns (uint256) {
    //     require(levelsCount > 0, "No membership levels exist");
    //     uint256 lastStakedTime = _stakes[user].lastStakedTime;
    //     uint256 totalStaked = _stakes[user].staked;
    //     uint256 APY = getAPY(totalStaked);

    //     return calculateReward(APY, lastStakedTime, totalStaked);
    // }
    /**
     * @dev Calculates the APY a user will receive based on the amount of tokens staked.
     * @param {Token Amount} token amount determines the APY
     */

    // function getAPY(uint256 tokens) public view returns (uint256) {
    //     require(levelsCount > 0, "No membership levels exist");

    //      for (uint256 i = levelsCount - 1; i >= 0; i--) {
    //     if (tokens >= membershipLevels[i].threshold)
    //     return membershipLevels[i].APY;
    //     }
    //     return 0;

    // }
    /**
     * @dev Calculates the APY a specific user will receive based on the amount of tokens staked.
     * @param {Address} Takes in a wallet address to check the amount of tokens staked.
     */
    // function currentAPY(address userAddress) public view returns (uint256) {
    //     uint256 tokens = _stakes[userAddress].staked;
    //     require(levelsCount > 0, "No membership levels exist");

    //     for (uint256 i = levelsCount - 1; i >= 0; i--) {
    //     if (tokens >= membershipLevels[i].threshold)
    //     return membershipLevels[i].APY;
    //     }
    //     return 0;
    // }

    // function calculateReward(
    //     uint256 APY,
    //     uint256 lastStakedTime,
    //     uint256 tokens
    // ) public view returns (uint256) {
    //     uint256 currentTime = block.timestamp;
    //     uint256 timeElapsed = currentTime - lastStakedTime;
    //     if (lastStakedTime == 0) return 0;
    //     return (timeElapsed * tokens * APY) / DIVIDER / APYBASE;
    // }

    // function changeMembershipAPY(uint256 index, uint256 newAPY)
    //     external
    //     onlyOwner
    // {
    //     require(index <= levelsCount - 1, "Wrong membership id");
    //     if (index > 0)
    //         require(
    //             membershipLevels[index - 1].APY < newAPY,
    //             "Cannot be lower than previous level"
    //         );
    //     if (index < levelsCount - 1)
    //         require(
    //             membershipLevels[index + 1].APY > newAPY,
    //             "Cannot be higher than next level"
    //         );
    //     membershipLevels[index].APY = newAPY;
    // }

    // function changeMembershipThreshold(uint256 index, uint256 newThreshold)
    //     external
    //     onlyOwner
    // {
    //     require(index <= levelsCount - 1, "Wrong membership id");
    //     if (index > 0)
    //         require(
    //             membershipLevels[index - 1].threshold < newThreshold,
    //             "Cannot be lower than previous level"
    //         );
    //     if (index < levelsCount - 1)
    //         require(
    //             membershipLevels[index + 1].threshold > newThreshold,
    //             "Cannot be higher than next level"
    //         );
    //     membershipLevels[index].threshold = newThreshold;
    // }

    /**
     * @dev add membership
     * @param threshold in uint256
     * @param APY in uint256
     */
    function addMembership(uint256 threshold, uint256 APY) public onlyOwner {
        require(
            threshold > 0 && APY > 0,
            "Threshold and APY should be larger than zero"
        );
        if (levelsCount == 0) {
            membershipLevels.push(MembershipLevel(threshold, APY));
        } else {
            require(
                membershipLevels[levelsCount - 1].threshold < threshold,
                "New threshold must be larger than the last"
            );
            require(
                membershipLevels[levelsCount - 1].APY < APY,
                "New APY must be larger than the last"
            );
            membershipLevels.push(MembershipLevel(threshold, APY));
        }
        levelsCount++;
        emit MembershipAdded(threshold, APY, levelsCount);
    }

    // function removeMembership(uint256 index) external onlyOwner {
    //     require(levelsCount > 0, "Nothing to remove");
    //     require(index <= levelsCount - 1, "Wrong index");

    //     for (uint256 i = index; i < levelsCount - 1; i++) {
    //         membershipLevels[i] = membershipLevels[i + 1];
    //     }
    //     delete membershipLevels[levelsCount - 1];
    //     levelsCount--;
    //     emit MembershipRemoved(index, levelsCount);
    // }
}