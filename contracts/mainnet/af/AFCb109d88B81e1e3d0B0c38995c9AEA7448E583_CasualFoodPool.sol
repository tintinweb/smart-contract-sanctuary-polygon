// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./StakingRewardPool.sol";

contract CasualFoodPool is StakingRewardPool {
  constructor(address _rewardToken, address _lpToken) StakingRewardPool(_rewardToken, _lpToken) {
    rewardToken = IERC20(_rewardToken);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Wallet is Ownable {
  using SafeMath for uint256;

  event Deposited(address indexed user, uint256 amount);
  event Withdrawn(address indexed user, uint256 amount);

  IERC20 internal foodTokenLP;

  mapping(address => uint256) public balances; // lp token balances
  address[] internal usersArray; // lp user array
  mapping(address => bool) internal users; // lp user map

  constructor(address _foodTokenLPTokenAddress) {
    foodTokenLP = IERC20(_foodTokenLPTokenAddress);
  }

  function getBalance() external view returns (uint256) {
    return balances[msg.sender];
  }

  function deposit(uint256 amount) public {
    require(amount > 0, "Invalid amount");
    require(foodTokenLP.allowance(msg.sender, address(this)) >= amount, "Insufficient allowance");

    balances[msg.sender] = balances[msg.sender].add(amount);
    if (!users[msg.sender]) {
      users[msg.sender] = true;
      usersArray.push(msg.sender);
    }
    foodTokenLP.transferFrom(msg.sender, address(this), amount);

    emit Deposited(msg.sender, amount);
  }

  function withdraw(uint256 amount) public {
    require(balances[msg.sender] >= amount, "Insufficient token balance");

    balances[msg.sender] = balances[msg.sender].sub(amount);
    foodTokenLP.transfer(msg.sender, amount);

    emit Withdrawn(msg.sender, amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./StakingPool.sol";

/**
 * Pool contract to distribute reward tokens among LP token stakers proportionally to the amount and duration of the their stakes.
 * The owner can setup multiple reward periods each one with a pre-allocated amount of reward tokens to be distributed.
 * Users are free to add and remove tokens to their stake at any time.
 * Users can also claim their pending reward at any time.

 * The pool implements an efficient O(1) algo to distribute the rewards based on this paper:
 * https://uploads-ssl.webflow.com/5ad71ffeb79acc67c8bcdaba/5ad8d1193a40977462982470_scalable-reward-distribution-paper.pdf
 */
contract StakingRewardPool is StakingPool {
  using SafeMath for uint256;

  event RewardPeriodCreated(uint id, uint256 reward, uint from, uint to);
  event RewardPaid(address indexed user, uint256 reward);
  event Claimed(address indexed user, uint periodId, uint reward);

  struct RewardPeriod {
    uint id; // index + 1 in rewardPeriods array
    uint reward; // Amount to distribute over the entire period
    uint from; // Block timestamp
    uint to; // Block timestamp
    uint lastUpdated; // When the totalStakedWeight was last updated (after last stake was ended)
    uint totalStaked; // Sum of all active stake deposits
    uint rewardPerTokenStaked; // Sum of all rewards distributed divided all active stakes: SUM(reward/totalStaked)
    uint totalRewardsPaid; // Sum of all rewards paid in claims
  }

  struct UserInfo {
    uint userRewardPerTokenStaked;
    uint pendingRewards;
    uint rewardsPaid;
  }

  struct RewardsStats {
    // user stats
    uint claimableRewards;
    uint rewardsPaid;
    // general stats
    uint rewardRate;
    uint totalRewardsPaid;
  }

  IERC20 internal rewardToken;
  RewardPeriod[] public rewardPeriods;
  uint rewardPeriodsCount = 0;
  uint constant rewardPrecision = 1e9;
  mapping(address => mapping(uint => UserInfo)) userInfos;

  constructor(address _rewardToken, address _lpToken) StakingPool(_rewardToken, _lpToken) {
    rewardToken = IERC20(_rewardToken);
  }

  function newRewardPeriod(uint reward, uint from, uint to) public onlyDao {
    require(reward > 0, "Invalid reward period amount");
    require(to > from && to > block.timestamp, "Invalid reward period interval");
    uint previousTotalStaked = rewardPeriods.length == 0 ? 0 : rewardPeriods[rewardPeriods.length - 1].totalStaked;
    require(rewardPeriods.length == 0 || from > rewardPeriods[rewardPeriods.length - 1].to, "Invalid period start time");

    rewardPeriods.push(RewardPeriod(rewardPeriods.length + 1, reward, from, to, block.timestamp, previousTotalStaked, 0, 0));
    rewardPeriodsCount = rewardPeriods.length;

    rewardToken.transferFrom(dao, address(this), reward);

    emit RewardPeriodCreated(rewardPeriodsCount, reward, from, to);
  }

  function getRewardPeriodsCount() public view returns (uint) {
    return rewardPeriodsCount;
  }

  function deleteRewardPeriod(uint index) public onlyDao {
    require(rewardPeriods.length > index, "Invalid reward phase index");
    for (uint i = index; i < rewardPeriods.length - 1; i++) {
      rewardPeriods[i] = rewardPeriods[i + 1];
    }
    rewardPeriods.pop();
    rewardPeriodsCount = rewardPeriods.length;
  }

  function getCurrentRewardPeriodId() public view returns (uint) {
    if (rewardPeriodsCount == 0) return 0;
    return rewardPeriods[rewardPeriodsCount - 1].id;
  }

  function rewardBalance() public view returns (uint) {
    return rewardToken.balanceOf(address(this));
  }

  function depositReward(uint amount) external onlyDao returns(bool success) {
    return rewardToken.transferFrom(dao, address(this), amount);
  }

  function withdrawReward(uint amount) external onlyDao returns(bool success) {
    return rewardToken.transfer(payable(dao), amount);
  }

  function startStake(uint amount) public override whenNotPaused {
    uint periodId = getCurrentRewardPeriodId();
    require(periodId > 0, "No active reward period found");

    update();
    super.startStake(amount);

    // update total tokens staked
    RewardPeriod storage period = rewardPeriods[periodId - 1];
    period.totalStaked = period.totalStaked.add(amount);
  }

  function endStake(uint amount) public override whenNotPaused {
    uint periodId = getCurrentRewardPeriodId();
    require(periodId > 0, "No active reward period found");
    update();
    super.endStake(amount);

    // update total tokens staked
    RewardPeriod storage period = rewardPeriods[periodId - 1];
    period.totalStaked = period.totalStaked.sub(amount);

    claim();
  }

  /**
   * Calculate total period reward to be distributed since period.lastUpdated
   */
  function calculatePeriodRewardPerToken(RewardPeriod memory period) view internal returns (uint) {
    uint rate = rewardRate(period);
    uint timestamp = block.timestamp > period.to ? period.to : block.timestamp; // We don't pay out after period.to
    uint deltaTime = timestamp.sub(period.lastUpdated);
    uint reward = deltaTime.mul(rate);

    uint newRewardPerTokenStaked = period.rewardPerTokenStaked;
    if (period.totalStaked != 0) {
      newRewardPerTokenStaked = period.rewardPerTokenStaked.add(
        reward.mul(rewardPrecision).div(period.totalStaked)
      );
    }

    return newRewardPerTokenStaked;
  }


  /**
   * Calculate user reward 
   */
  function calculateUserReward(uint periodId, uint periodRewardPerToken) internal view returns (uint) {
    if (periodRewardPerToken == 0) return 0;

    uint staked = stakes[msg.sender];
    UserInfo memory userInfo = userInfos[msg.sender][periodId];
    uint reward = staked.mul(
      periodRewardPerToken.sub(userInfo.userRewardPerTokenStaked)
    ).div(rewardPrecision);

    return reward;
  }

  function claimableReward() view public returns (uint pending) {
    (pending,) = getClaimStats();
  }

  function getClaimStats() view public returns (uint, uint) {
    uint pending = 0;
    uint paid = 0;

    for (uint i = 0; i < rewardPeriods.length; i++) {
      RewardPeriod memory period = rewardPeriods[i];
      uint periodRewardPerToken = calculatePeriodRewardPerToken(period);
      uint reward = calculateUserReward(period.id, periodRewardPerToken);

      UserInfo memory userInfo = userInfos[msg.sender][period.id];
      pending = pending.add(userInfo.pendingRewards.add(reward));
      paid = paid.add(userInfo.rewardsPaid);
    }

    return (pending, paid);
  }

  function claimReward() public whenNotPaused {
    update();
    claim();
  }

  function claim() internal {
    uint total = 0;

    for (uint i = 0; i < rewardPeriods.length; i++) {
      RewardPeriod storage period = rewardPeriods[i];
      UserInfo storage userInfo = userInfos[msg.sender][period.id];
      uint rewards = userInfo.pendingRewards;
      if (rewards != 0) {
        userInfo.pendingRewards = 0;
        userInfo.rewardsPaid = userInfo.rewardsPaid.add(rewards);
        period.totalRewardsPaid = period.totalRewardsPaid.add(rewards);
        total = total.add(rewards);
        emit Claimed(msg.sender, period.id, rewards);
      }
    }

    if (total != 0) {
      payReward(msg.sender, total);
    }
  }

  function getRewardsStats() public view returns (RewardsStats memory) {
    uint periodId = getCurrentRewardPeriodId();
    RewardsStats memory stats = RewardsStats(0, 0, 0, 0);

    // reward period stats
    if (periodId > 0) {
      RewardPeriod memory period = rewardPeriods[periodId - 1];
      stats.rewardRate = rewardRate(period);
      stats.totalRewardsPaid = period.totalRewardsPaid;
    }

    // user stats
    (stats.claimableRewards, stats.rewardsPaid) = getClaimStats();

    return stats;
  }

  function rewardRate(RewardPeriod memory period) internal pure returns (uint) {
    uint duration = period.to.sub(period.from);
    return period.reward.div(duration);
  }

  function payReward(address account, uint reward) internal {
    rewardToken.transfer(account, reward);
    emit RewardPaid(account, reward);
  }

  /**
   * Calculate rewards for all periods
   */
  function update() internal {
    for (uint i = 0; i < rewardPeriods.length; i++) {
      RewardPeriod storage period = rewardPeriods[i];
      uint periodRewardPerToken = calculatePeriodRewardPerToken(period);

      // update pending rewards since rewardPerTokenStaked was updated
      uint reward = calculateUserReward(period.id, periodRewardPerToken);
      UserInfo storage userInfo = userInfos[msg.sender][period.id];
      userInfo.pendingRewards = userInfo.pendingRewards.add(reward);
      userInfo.userRewardPerTokenStaked = periodRewardPerToken;

      require(periodRewardPerToken >= period.rewardPerTokenStaked, "Reward distribution should be monotonically increasing");

      period.rewardPerTokenStaked = periodRewardPerToken;
      period.lastUpdated = block.timestamp > period.to ? period.to : block.timestamp;
    }
  }

  function reset() public override onlyDao {
    for (uint i = 0; i < rewardPeriods.length; i++) {
      delete rewardPeriods[i];
    }
    rewardPeriodsCount = 0;
    for (uint i = 0; i < usersArray.length; i++) {
      for (uint j = 0; j < rewardPeriods.length; j++) {
        delete userInfos[usersArray[i]][rewardPeriods[j].id];
      }
    }
    // return leftover rewards to owner
    uint leftover = rewardBalance();
    rewardToken.transfer(msg.sender, leftover);
    super.reset();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/security/Pausable.sol";
import "./Wallet.sol";
import "./DOWable.sol";

contract StakingPool is Wallet, Pausable, DOWable {
  using SafeMath for uint256;

  event Staked(address indexed user, uint amount);
  event UnStaked(address indexed user, uint256 amount);

  address[] public stakers; // addresses that have active stakes
  mapping(address => uint) public stakes;
  uint public totalStakes;

  constructor(address _rewardToken, address _lpToken) Wallet(_lpToken) {}

  function startStake(uint amount) virtual public {
    require(amount > 0, "Invalid amount");
    require(balances[msg.sender] >= amount, "Insufficient token balance");

    balances[msg.sender] = balances[msg.sender].sub(amount);
    stakes[msg.sender] = stakes[msg.sender].add(amount);
    totalStakes = totalStakes.add(amount);

    emit Staked(msg.sender, amount);
  }


  function endStake(uint amount) virtual public whenNotPaused {
    require(stakes[msg.sender] >= amount, "Insufficient token balance");

    balances[msg.sender] = balances[msg.sender].add(amount);
    stakes[msg.sender] = stakes[msg.sender].sub(amount);
    totalStakes = totalStakes.sub(amount);

    emit UnStaked(msg.sender, amount);
  }

  function getStakedBalance() public view returns (uint) {
    return stakes[msg.sender];
  }

  function depositAndStartStake(uint256 amount) public whenNotPaused {
    deposit(amount);
    startStake(amount);
  }

  function endStakeAndWithdraw(uint amount) public whenNotPaused {
    endStake(amount);
    withdraw(amount);
  }

  function pause() external onlyDao {
    _pause();
  }

  function unpause() external onlyDao {
    _unpause();
  }

  /**
   * Reset user balances and stakes
   */
  function reset() public virtual onlyDao {
    for (uint i = 0; i < usersArray.length; i++) {
      balances[usersArray[i]] = 0;
      stakes[usersArray[i]] = 0;
    }
    totalStakes = 0;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract DOWable is Ownable {
  address dao;

  /**
   * @dev Throws if called by any account other than the DAO wallet.
   */
  function isDao() internal view {
    require(msg.sender == dao, "Only DAO can execute");
  }

  /**
   * @dev Throws if called by any account other than the DAO wallet.
   */
  modifier onlyDao() {
    isDao();
    _;
  }

  function setDao(address _dao) external onlyOwner {
    dao = _dao;
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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