// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./GenericMinerV2.sol";
import "./interfaces/IVotingMinerV2.sol";
import "../../governance/interfaces/IGovernanceAddressProvider.sol";
import "../../governance/interfaces/IVotingEscrow.sol";

contract VotingMinerV2 is IVotingMinerV2, GenericMinerV2 {
  using SafeMath for uint256;

  constructor(IGovernanceAddressProvider _addresses, BoostConfig memory _boostConfig)
    public
    GenericMinerV2(_addresses, _boostConfig)
  {}

  /**
    Releases the outstanding MIMO balance to the user
    @param _user the address of the user for which the MIMO tokens will be released
  */
  function releaseMIMO(address _user) external {
    UserInfo memory _userInfo = _users[_user];
    _refresh();

    uint256 pendingMIMO = _pendingMIMO(_userInfo.stakeWithBoost, _userInfo.accAmountPerShare);
    uint256 pendingPAR = _pendingPAR(_userInfo.stakeWithBoost, _userInfo.accParAmountPerShare);

    if (_userInfo.stakeWithBoost > 0) {
      _mimoBalanceTracker = _mimoBalanceTracker.sub(pendingMIMO);
      _parBalanceTracker = _parBalanceTracker.sub(pendingPAR);
    }

    _syncStake(_user, _userInfo);

    _userInfo.accAmountPerShare = _accMimoAmountPerShare;
    _userInfo.accParAmountPerShare = _accParAmountPerShare;

    _updateBoost(_user, _userInfo);

    if (pendingMIMO > 0) {
      require(_a.mimo().transfer(_user, pendingMIMO), "LM100");
    }
    if (pendingPAR > 0) {
      require(_par.transfer(_user, pendingPAR), "LM100");
    }
  }

  /**
    Updates user stake based on current user baseDebt
    @dev this method is for upgradability purposes from an older VotingMiner to a newer one so the user doesn't have to call releaseMIMO() to set their stake in this VotingMiner
    @param _user address of the user
  */
  function syncStake(address _user) public override {
    UserInfo memory _userInfo = _users[_user];
    _syncStake(_user, _userInfo);
    _updateBoost(_user, _userInfo);
  }

  /**
    Updates user stake based on current user baseDebt
    @dev internal function to perform stake sync with VotingEscrow for both upgradability and relaseMIMO logic
    @param _user address of the user
  */
  function _syncStake(address _user, UserInfo memory _userInfo) internal {
    uint256 votingPower = _a.votingEscrow().balanceOf(_user);
    _totalStake = _totalStake.add(votingPower).sub(_userInfo.stake);
    _userInfo.stake = votingPower;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        require(b > 0, errorMessage);
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IGenericMinerV2.sol";
import "../../libraries/WadRayMath.sol";
import "../../libraries/ABDKMath64x64.sol";

/*
    GenericMiner is based on ERC2917. https://github.com/gnufoo/ERC2917-Proposal

    The Objective of GenericMiner is to implement a decentralized staking mechanism, which calculates _users' share
    by accumulating stake * time. And calculates _users revenue from anytime t0 to t1 by the formula below:

        user_accumulated_stake(time1) - user_accumulated_stake(time0)
       _____________________________________________________________________________  * (gross_stake(t1) - gross_stake(t0))
       total_accumulated_stake(time1) - total_accumulated_stake(time0)

    The boost feature reuses the same principle and applies a multiplier to the stake.

    The boost multiplier formula is the following : a + b / (c + e^-((veMIMO / d) - e))
*/

contract GenericMinerV2 is IGenericMinerV2 {
  using ABDKMath64x64 for int128;
  using ABDKMath64x64 for uint256;
  using SafeMath for uint256;
  using WadRayMath for uint256;

  IERC20 internal immutable _par;
  IGovernanceAddressProvider internal immutable _a;

  BoostConfig internal _boostConfig;

  mapping(address => UserInfo) internal _users;

  uint256 internal _totalStake;
  uint256 internal _totalStakeWithBoost;

  uint256 internal _mimoBalanceTracker;
  uint256 internal _accMimoAmountPerShare;

  uint256 internal _parBalanceTracker;
  uint256 internal _accParAmountPerShare;

  modifier onlyManager {
    require(_a.parallel().controller().hasRole(_a.parallel().controller().MANAGER_ROLE(), msg.sender), "LM010");
    _;
  }

  constructor(IGovernanceAddressProvider _addresses, BoostConfig memory boostConfig) public {
    require(address(_addresses) != address(0), "LM000");
    _a = _addresses;
    _par = IERC20(_addresses.parallel().stablex());
    require(boostConfig.a >= 1 && boostConfig.d > 0 && boostConfig.maxBoost >= 1, "LM004");
    _boostConfig = boostConfig;

    emit BoostConfigSet(_boostConfig);
  }

  /**
    Sets new boost config
    @dev can only be called by protocol manager
    @param newBoostConfig contains all boost multiplier parameters, see {IGenericMinerV2 - BoostConfig}
   */
  function setBoostConfig(BoostConfig memory newBoostConfig) external onlyManager {
    require(newBoostConfig.a >= 1 && newBoostConfig.d > 0 && newBoostConfig.maxBoost >= 1, "LM004");
    _boostConfig = newBoostConfig;

    emit BoostConfigSet(_boostConfig);
  }

  /**
    Releases outstanding rewards balances to the user
    @param _user the address of the user for which the reward tokens will be released
  */
  function releaseRewards(address _user) public virtual override {
    UserInfo memory _userInfo = _users[_user];
    _releaseRewards(_user, _userInfo);
    _userInfo.accAmountPerShare = _accMimoAmountPerShare;
    _userInfo.accParAmountPerShare = _accParAmountPerShare;
    _updateBoost(_user, _userInfo);
  }

  /**
    Reapplies the boost of the user, useful if a whale's vMIMO has decreased but their boost is still the original value
  */
  function updateBoost(address _user) public {
    UserInfo memory userInfo = _users[_user];
    _updateBoost(_user, userInfo);
  }

  /**
    Returns the number of tokens a user has staked
    @param _user the address of the user
    @return number of staked tokens
  */
  function stake(address _user) public view override returns (uint256) {
    return _users[_user].stake;
  }

  /**
    Returns the number of tokens a user has staked with the boost
    @param _user the address of the user
    @return number of staked tokens with boost
  */
  function stakeWithBoost(address _user) public view override returns (uint256) {
    return _users[_user].stakeWithBoost;
  }

  /**
    Returns the number of tokens a user can claim via `releaseMIMO`
    @param _user the address of the user
    @return number of MIMO tokens that the user can claim
  */
  function pendingMIMO(address _user) public view override returns (uint256) {
    UserInfo memory _userInfo = _users[_user];
    return _pendingMIMO(_userInfo.stakeWithBoost, _userInfo.accAmountPerShare);
  }

  /**
    Returns the number of PAR tokens the user has earned as a reward
    @param _user the address of the user
    @return number of PAR tokens that will be sent automatically when staking/unstaking
  */
  function pendingPAR(address _user) public view override returns (uint256) {
    UserInfo memory _userInfo = _users[_user];
    return _pendingPAR(_userInfo.stakeWithBoost, _userInfo.accParAmountPerShare);
  }

  function par() public view override returns (IERC20) {
    return _par;
  }

  function a() public view override returns (IGovernanceAddressProvider) {
    return _a;
  }

  function boostConfig() public view override returns (BoostConfig memory) {
    return _boostConfig;
  }

  function totalStake() public view override returns (uint256) {
    return _totalStake;
  }

  function totalStakeWithBoost() public view override returns (uint256) {
    return _totalStakeWithBoost;
  }

  /**
    Returns the userInfo stored of a user
    @param _user the address of the user
    @return `struct UserInfo {
      uint256 stake;
      uint256 stakeWithBoost;
      uint256 accAmountPerShare;
      uint256 accParAmountPerShare;
    }`
  **/
  function userInfo(address _user) public view override returns (UserInfo memory) {
    return _users[_user];
  }

  /**
    Refreshes the global state and subsequently increases a user's stake
    This is an internal call and meant to be called within derivative contracts
    @param user the address of the user
    @param value the amount by which the stake will be increased
  */
  function _increaseStake(address user, uint256 value) internal {
    require(value > 0, "LM101");
    UserInfo memory _userInfo = _users[user];

    _releaseRewards(user, _userInfo);
    _totalStake = _totalStake.add(value);
    _userInfo.stake = _userInfo.stake.add(value);
    _userInfo.accAmountPerShare = _accMimoAmountPerShare;
    _userInfo.accParAmountPerShare = _accParAmountPerShare;
    _updateBoost(user, _userInfo);

    emit StakeIncreased(user, value);
  }

  /**
    Refreshes the global state and subsequently decreases the stake a user has
    This is an internal call and meant to be called within derivative contracts
    @param user the address of the user
    @param value the amount by which the stake will be reduced
  */
  function _decreaseStake(address user, uint256 value) internal {
    require(value > 0, "LM101");
    UserInfo memory _userInfo = _users[user];
    require(_userInfo.stake >= value, "LM102");

    _releaseRewards(user, _userInfo);
    _totalStake = _totalStake.sub(value);
    _userInfo.stake = _userInfo.stake.sub(value);
    _userInfo.accAmountPerShare = _accMimoAmountPerShare;
    _userInfo.accParAmountPerShare = _accParAmountPerShare;
    _updateBoost(user, _userInfo);

    emit StakeDecreased(user, value);
  }

  function _releaseRewards(address _user, UserInfo memory _userInfo) internal {
    uint256 pendingMIMO = _pendingMIMO(_userInfo.stakeWithBoost, _userInfo.accAmountPerShare);
    uint256 pendingPAR = _pendingPAR(_userInfo.stakeWithBoost, _userInfo.accParAmountPerShare);
    _refresh();

    if (_userInfo.stakeWithBoost > 0) {
      _mimoBalanceTracker = _mimoBalanceTracker.sub(pendingMIMO);
      _parBalanceTracker = _parBalanceTracker.sub(pendingPAR);
    }

    if (pendingMIMO > 0) {
      require(_a.mimo().transfer(_user, pendingMIMO), "LM100");
    }
    if (pendingPAR > 0) {
      require(_par.transfer(_user, pendingPAR), "LM100");
    }
  }

  /**
    Updates the internal state variables based on user's veMIMO hodlings
    @param _user the address of the user
   */
  function _updateBoost(address _user, UserInfo memory _userInfo) internal {
    // if user had a boost already, first remove it from the totalStakeWithBoost
    if (_userInfo.stakeWithBoost > 0) {
      _totalStakeWithBoost = _totalStakeWithBoost.sub(_userInfo.stakeWithBoost);
    }
    uint256 multiplier = _getBoostMultiplier(_user);
    _userInfo.stakeWithBoost = _userInfo.stake.wadMul(multiplier);
    _totalStakeWithBoost = _totalStakeWithBoost.add(_userInfo.stakeWithBoost);
    _users[_user] = _userInfo;
  }

  /**
    Refreshes the global state and subsequently updates a user's stake
    This is an internal call and meant to be called within derivative contracts
    @param user the address of the user
    @param stake the new amount of stake for the user
  */
  function _updateStake(address user, uint256 stake) internal returns (bool) {
    uint256 oldStake = _users[user].stake;
    if (stake > oldStake) {
      _increaseStake(user, stake.sub(oldStake));
    }
    if (stake < oldStake) {
      _decreaseStake(user, oldStake.sub(stake));
    }
  }

  /**
    Updates the internal state variables after accounting for newly received MIMO and PAR reward tokens
  */
  function _refresh() internal {
    if (_totalStake == 0) {
      return;
    }
    uint256 currentMimoBalance = _a.mimo().balanceOf(address(this));
    uint256 currentParBalance = _par.balanceOf(address(this));
    uint256 mimoReward = currentMimoBalance.sub(_mimoBalanceTracker);
    uint256 parReward = currentParBalance.sub(_parBalanceTracker);

    _mimoBalanceTracker = currentMimoBalance;
    _accMimoAmountPerShare = _accMimoAmountPerShare.add(mimoReward.rayDiv(_totalStakeWithBoost));
    _parBalanceTracker = currentParBalance;
    _accParAmountPerShare = _accParAmountPerShare.add(parReward.rayDiv(_totalStakeWithBoost));
  }

  /**
    Returns the number of tokens a user can claim via `releaseMIMO`
    @return number of MIMO tokens that the user can claim
  */
  function _pendingMIMO(uint256 _userStakeWithBoost, uint256 _userAccAmountPerShare) internal view returns (uint256) {
    if (_totalStakeWithBoost == 0) {
      return 0;
    }
    uint256 currentBalance = _a.mimo().balanceOf(address(this));
    uint256 reward = currentBalance.sub(_mimoBalanceTracker);
    uint256 accMimoAmountPerShare = _accMimoAmountPerShare.add(reward.rayDiv(_totalStakeWithBoost));
    return _userStakeWithBoost.rayMul(accMimoAmountPerShare.sub(_userAccAmountPerShare));
  }

  /**
    Returns the number of PAR tokens the user has earned as a reward
    @return number of PAR tokens that will be sent automatically when staking/unstaking
  */
  function _pendingPAR(uint256 _userStakeWithBoost, uint256 _userAccParAmountPerShare) internal view returns (uint256) {
    if (_totalStakeWithBoost == 0) {
      return 0;
    }
    uint256 currentBalance = _par.balanceOf(address(this));
    uint256 reward = currentBalance.sub(_parBalanceTracker);
    uint256 accParAmountPerShare = _accParAmountPerShare.add(reward.rayDiv(_totalStakeWithBoost));

    return _userStakeWithBoost.rayMul(accParAmountPerShare.sub(_userAccParAmountPerShare));
  }

  /**
    Returns the boost multiplier the user is eligible for
    @param _user the address of the user
    @return the boost multiplier based on the user's veMIMO per the boost formula : a + b / (c + e^-((veMIMO / d) - e))
   */
  function _getBoostMultiplier(address _user) internal view returns (uint256) {
    uint256 veMIMO = _a.votingEscrow().balanceOf(_user);

    if (veMIMO == 0) return 1e18;

    // Convert boostConfig variables to signed 64.64-bit fixed point numbers
    int128 a = ABDKMath64x64.fromUInt(_boostConfig.a);
    int128 b = ABDKMath64x64.fromUInt(_boostConfig.b);
    int128 c = ABDKMath64x64.fromUInt(_boostConfig.c);
    int128 e = ABDKMath64x64.fromUInt(_boostConfig.e);
    int128 DECIMALS = ABDKMath64x64.fromUInt(1e18);

    int128 e1 = veMIMO.divu(_boostConfig.d); // x/25000
    int128 e2 = e1.sub(e); // x/25000 - 6
    int128 e3 = e2.neg(); // -(x/25000 - 6)
    int128 e4 = e3.exp(); // e^-(x/25000 - 6)
    int128 e5 = e4.add(c); // 1 + e^-(x/25000 - 6)
    int128 e6 = b.div(e5).add(a); // 1 + 3/(1 + e^-(x/25000 - 6))
    uint64 e7 = e6.mul(DECIMALS).toUInt(); // convert back to uint64
    uint256 multiplier = uint256(e7); // convert to uint256

    require(multiplier >= 1e18 && multiplier <= _boostConfig.maxBoost, "LM103");

    return multiplier;
  }
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

interface IVotingMinerV2 {
  function syncStake(address user) external;
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity >=0.6.12;

import "./IGovernorAlpha.sol";
import "./ITimelock.sol";
import "./IVotingEscrow.sol";
import "../../interfaces/IAccessController.sol";
import "../../interfaces/IAddressProvider.sol";
import "../../liquidityMining/interfaces/IMIMO.sol";
import "../../liquidityMining/interfaces/IDebtNotifier.sol";

interface IGovernanceAddressProvider {
  function setParallelAddressProvider(IAddressProvider _parallel) external;

  function setMIMO(IMIMO _mimo) external;

  function setDebtNotifier(IDebtNotifier _debtNotifier) external;

  function setGovernorAlpha(IGovernorAlpha _governorAlpha) external;

  function setTimelock(ITimelock _timelock) external;

  function setVotingEscrow(IVotingEscrow _votingEscrow) external;

  function controller() external view returns (IAccessController);

  function parallel() external view returns (IAddressProvider);

  function mimo() external view returns (IMIMO);

  function debtNotifier() external view returns (IDebtNotifier);

  function governorAlpha() external view returns (IGovernorAlpha);

  function timelock() external view returns (ITimelock);

  function votingEscrow() external view returns (IVotingEscrow);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.6.12;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../../liquidityMining/interfaces/IGenericMiner.sol';

interface IVotingEscrow {
  enum LockAction { CREATE_LOCK, INCREASE_LOCK_AMOUNT, INCREASE_LOCK_TIME }

  struct LockedBalance {
    uint256 amount;
    uint256 end;
  }

  /** Shared Events */
  event Deposit(address indexed provider, uint256 value, uint256 locktime, LockAction indexed action, uint256 ts);
  event Withdraw(address indexed provider, uint256 value, uint256 ts);
  event Expired();

  function createLock(uint256 _value, uint256 _unlockTime) external;

  function increaseLockAmount(uint256 _value) external;

  function increaseLockLength(uint256 _unlockTime) external;

  function withdraw() external;

  function expireContract() external;

  function setMiner(IGenericMiner _miner) external;

  function setMinimumLockTime(uint256 _minimumLockTime) external;

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint256);

  function balanceOf(address _owner) external view returns (uint256);

  function balanceOfAt(address _owner, uint256 _blockTime) external view returns (uint256);

  function stakingToken() external view returns (IERC20);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../../interfaces/IAddressProvider.sol";
import "../../../governance/interfaces/IGovernanceAddressProvider.sol";

interface IGenericMinerV2 {
  struct UserInfo {
    uint256 stake;
    uint256 stakeWithBoost;
    uint256 accAmountPerShare;
    uint256 accParAmountPerShare;
  }

  struct BoostConfig {
    uint256 a;
    uint256 b;
    uint256 c;
    uint256 d;
    uint256 e;
    uint256 maxBoost;
  }

  /// @dev This emit when a users' productivity has changed
  /// It emits with the user's address and the the value after the change.
  event StakeIncreased(address indexed user, uint256 stake);

  /// @dev This emit when a users' productivity has changed
  /// It emits with the user's address and the the value after the change.
  event StakeDecreased(address indexed user, uint256 stake);

  event BoostConfigSet(BoostConfig);

  function releaseRewards(address _user) external;

  function stake(address _user) external view returns (uint256);

  function stakeWithBoost(address _user) external view returns (uint256);

  // Read only
  function a() external view returns (IGovernanceAddressProvider);

  function pendingMIMO(address _user) external view returns (uint256);

  function pendingPAR(address _user) external view returns (uint256);

  function par() external view returns (IERC20);

  function boostConfig() external view returns (BoostConfig memory);

  function totalStake() external view returns (uint256);

  function totalStakeWithBoost() external view returns (uint256);

  function userInfo(address _user) external view returns (UserInfo memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

/******************
@title WadRayMath library
@author Aave
@dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 */

library WadRayMath {
  using SafeMath for uint256;

  uint256 internal constant _WAD = 1e18;
  uint256 internal constant _HALF_WAD = _WAD / 2;

  uint256 internal constant _RAY = 1e27;
  uint256 internal constant _HALF_RAY = _RAY / 2;

  uint256 internal constant _WAD_RAY_RATIO = 1e9;

  function ray() internal pure returns (uint256) {
    return _RAY;
  }

  function wad() internal pure returns (uint256) {
    return _WAD;
  }

  function halfRay() internal pure returns (uint256) {
    return _HALF_RAY;
  }

  function halfWad() internal pure returns (uint256) {
    return _HALF_WAD;
  }

  function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
    return _HALF_WAD.add(a.mul(b)).div(_WAD);
  }

  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 halfB = b / 2;

    return halfB.add(a.mul(_WAD)).div(b);
  }

  function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
    return _HALF_RAY.add(a.mul(b)).div(_RAY);
  }

  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 halfB = b / 2;

    return halfB.add(a.mul(_RAY)).div(b);
  }

  function rayToWad(uint256 a) internal pure returns (uint256) {
    uint256 halfRatio = _WAD_RAY_RATIO / 2;

    return halfRatio.add(a).div(_WAD_RAY_RATIO);
  }

  function wadToRay(uint256 a) internal pure returns (uint256) {
    return a.mul(_WAD_RAY_RATIO);
  }

  /**
   * @dev calculates x^n, in ray. The code uses the ModExp precompile
   * @param x base
   * @param n exponent
   * @return z = x^n, in ray
   */
  function rayPow(uint256 x, uint256 n) internal pure returns (uint256 z) {
    z = n % 2 != 0 ? x : _RAY;

    for (n /= 2; n != 0; n /= 2) {
      x = rayMul(x, x);

      if (n % 2 != 0) {
        z = rayMul(z, x);
      }
    }
  }
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity 0.6.12;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
  /*
   * Minimum value signed 64.64-bit fixed point number may have.
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /*
   * Maximum value signed 64.64-bit fixed point number may have.
   */
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Convert signed 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromInt(int256 x) internal pure returns (int128) {
    require(x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
    return int128(x << 64);
  }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt(int128 x) internal pure returns (int64) {
    return int64(x >> 64);
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt(uint256 x) internal pure returns (int128) {
    require(x <= 0x7FFFFFFFFFFFFFFF);
    return int128(x << 64);
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt(int128 x) internal pure returns (uint64) {
    require(x >= 0);
    return uint64(x >> 64);
  }

  /**
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128(int256 x) internal pure returns (int128) {
    int256 result = x >> 64;
    require(result >= MIN_64x64 && result <= MAX_64x64);
    return int128(result);
  }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128(int128 x) internal pure returns (int256) {
    return int256(x) << 64;
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add(int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) + y;
    require(result >= MIN_64x64 && result <= MAX_64x64);
    return int128(result);
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub(int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) - y;
    require(result >= MIN_64x64 && result <= MAX_64x64);
    return int128(result);
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul(int128 x, int128 y) internal pure returns (int128) {
    int256 result = (int256(x) * y) >> 64;
    require(result >= MIN_64x64 && result <= MAX_64x64);
    return int128(result);
  }

  /**
   * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
   * number and y is signed 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
  function muli(int128 x, int256 y) internal pure returns (int256) {
    if (x == MIN_64x64) {
      require(
        y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
          y <= 0x1000000000000000000000000000000000000000000000000
      );
      return -y << 63;
    } else {
      bool negativeResult = false;
      if (x < 0) {
        x = -x;
        negativeResult = true;
      }
      if (y < 0) {
        y = -y; // We rely on overflow behavior here
        negativeResult = !negativeResult;
      }
      uint256 absoluteResult = mulu(x, uint256(y));
      if (negativeResult) {
        require(absoluteResult <= 0x8000000000000000000000000000000000000000000000000000000000000000);
        return -int256(absoluteResult); // We rely on overflow behavior here
      } else {
        require(absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int256(absoluteResult);
      }
    }
  }

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu(int128 x, uint256 y) internal pure returns (uint256) {
    if (y == 0) return 0;

    require(x >= 0);

    uint256 lo = (uint256(x) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
    uint256 hi = uint256(x) * (y >> 128);

    require(hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    hi <<= 64;

    require(hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
    return hi + lo;
  }

  /**
   * Calculate x / y rounding towards zero.  Revert on overflow or when y is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function div(int128 x, int128 y) internal pure returns (int128) {
    require(y != 0);
    int256 result = (int256(x) << 64) / y;
    require(result >= MIN_64x64 && result <= MAX_64x64);
    return int128(result);
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are signed 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divi(int256 x, int256 y) internal pure returns (int128) {
    require(y != 0);

    bool negativeResult = false;
    if (x < 0) {
      x = -x; // We rely on overflow behavior here
      negativeResult = true;
    }
    if (y < 0) {
      y = -y; // We rely on overflow behavior here
      negativeResult = !negativeResult;
    }
    uint128 absoluteResult = divuu(uint256(x), uint256(y));
    if (negativeResult) {
      require(absoluteResult <= 0x80000000000000000000000000000000);
      return -int128(absoluteResult); // We rely on overflow behavior here
    } else {
      require(absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return int128(absoluteResult); // We rely on overflow behavior here
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu(uint256 x, uint256 y) internal pure returns (int128) {
    require(y != 0);
    uint128 result = divuu(x, y);
    require(result <= uint128(MAX_64x64));
    return int128(result);
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg(int128 x) internal pure returns (int128) {
    require(x != MIN_64x64);
    return -x;
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs(int128 x) internal pure returns (int128) {
    require(x != MIN_64x64);
    return x < 0 ? -x : x;
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv(int128 x) internal pure returns (int128) {
    require(x != 0);
    int256 result = int256(0x100000000000000000000000000000000) / x;
    require(result >= MIN_64x64 && result <= MAX_64x64);
    return int128(result);
  }

  /**
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg(int128 x, int128 y) internal pure returns (int128) {
    return int128((int256(x) + int256(y)) >> 1);
  }

  /**
   * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
   * Revert on overflow or in case x * y is negative.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function gavg(int128 x, int128 y) internal pure returns (int128) {
    int256 m = int256(x) * int256(y);
    require(m >= 0);
    require(m < 0x4000000000000000000000000000000000000000000000000000000000000000);
    return int128(sqrtu(uint256(m)));
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
  function pow(int128 x, uint256 y) internal pure returns (int128) {
    bool negative = x < 0 && y & 1 == 1;

    uint256 absX = uint128(x < 0 ? -x : x);
    uint256 absResult;
    absResult = 0x100000000000000000000000000000000;

    if (absX <= 0x10000000000000000) {
      absX <<= 63;
      while (y != 0) {
        if (y & 0x1 != 0) {
          absResult = (absResult * absX) >> 127;
        }
        absX = (absX * absX) >> 127;

        if (y & 0x2 != 0) {
          absResult = (absResult * absX) >> 127;
        }
        absX = (absX * absX) >> 127;

        if (y & 0x4 != 0) {
          absResult = (absResult * absX) >> 127;
        }
        absX = (absX * absX) >> 127;

        if (y & 0x8 != 0) {
          absResult = (absResult * absX) >> 127;
        }
        absX = (absX * absX) >> 127;

        y >>= 4;
      }

      absResult >>= 64;
    } else {
      uint256 absXShift = 63;
      if (absX < 0x1000000000000000000000000) {
        absX <<= 32;
        absXShift -= 32;
      }
      if (absX < 0x10000000000000000000000000000) {
        absX <<= 16;
        absXShift -= 16;
      }
      if (absX < 0x1000000000000000000000000000000) {
        absX <<= 8;
        absXShift -= 8;
      }
      if (absX < 0x10000000000000000000000000000000) {
        absX <<= 4;
        absXShift -= 4;
      }
      if (absX < 0x40000000000000000000000000000000) {
        absX <<= 2;
        absXShift -= 2;
      }
      if (absX < 0x80000000000000000000000000000000) {
        absX <<= 1;
        absXShift -= 1;
      }

      uint256 resultShift = 0;
      while (y != 0) {
        require(absXShift < 64);

        if (y & 0x1 != 0) {
          absResult = (absResult * absX) >> 127;
          resultShift += absXShift;
          if (absResult > 0x100000000000000000000000000000000) {
            absResult >>= 1;
            resultShift += 1;
          }
        }
        absX = (absX * absX) >> 127;
        absXShift <<= 1;
        if (absX >= 0x100000000000000000000000000000000) {
          absX >>= 1;
          absXShift += 1;
        }

        y >>= 1;
      }

      require(resultShift < 64);
      absResult >>= 64 - resultShift;
    }
    int256 result = negative ? -int256(absResult) : int256(absResult);
    require(result >= MIN_64x64 && result <= MAX_64x64);
    return int128(result);
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt(int128 x) internal pure returns (int128) {
    require(x >= 0);
    return int128(sqrtu(uint256(x) << 64));
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2(int128 x) internal pure returns (int128) {
    require(x > 0);

    int256 msb = 0;
    int256 xc = x;
    if (xc >= 0x10000000000000000) {
      xc >>= 64;
      msb += 64;
    }
    if (xc >= 0x100000000) {
      xc >>= 32;
      msb += 32;
    }
    if (xc >= 0x10000) {
      xc >>= 16;
      msb += 16;
    }
    if (xc >= 0x100) {
      xc >>= 8;
      msb += 8;
    }
    if (xc >= 0x10) {
      xc >>= 4;
      msb += 4;
    }
    if (xc >= 0x4) {
      xc >>= 2;
      msb += 2;
    }
    if (xc >= 0x2) msb += 1; // No need to shift xc anymore

    int256 result = (msb - 64) << 64;
    uint256 ux = uint256(x) << uint256(127 - msb);
    for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
      ux *= ux;
      uint256 b = ux >> 255;
      ux >>= 127 + b;
      result += bit * int256(b);
    }

    return int128(result);
  }

  /**
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln(int128 x) internal pure returns (int128) {
    require(x > 0);

    return int128((uint256(log_2(x)) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF) >> 128);
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2(int128 x) internal pure returns (int128) {
    require(x < 0x400000000000000000); // Overflow

    if (x < -0x400000000000000000) return 0; // Underflow

    uint256 result = 0x80000000000000000000000000000000;

    if (x & 0x8000000000000000 > 0) result = (result * 0x16A09E667F3BCC908B2FB1366EA957D3E) >> 128;
    if (x & 0x4000000000000000 > 0) result = (result * 0x1306FE0A31B7152DE8D5A46305C85EDEC) >> 128;
    if (x & 0x2000000000000000 > 0) result = (result * 0x1172B83C7D517ADCDF7C8C50EB14A791F) >> 128;
    if (x & 0x1000000000000000 > 0) result = (result * 0x10B5586CF9890F6298B92B71842A98363) >> 128;
    if (x & 0x800000000000000 > 0) result = (result * 0x1059B0D31585743AE7C548EB68CA417FD) >> 128;
    if (x & 0x400000000000000 > 0) result = (result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8) >> 128;
    if (x & 0x200000000000000 > 0) result = (result * 0x10163DA9FB33356D84A66AE336DCDFA3F) >> 128;
    if (x & 0x100000000000000 > 0) result = (result * 0x100B1AFA5ABCBED6129AB13EC11DC9543) >> 128;
    if (x & 0x80000000000000 > 0) result = (result * 0x10058C86DA1C09EA1FF19D294CF2F679B) >> 128;
    if (x & 0x40000000000000 > 0) result = (result * 0x1002C605E2E8CEC506D21BFC89A23A00F) >> 128;
    if (x & 0x20000000000000 > 0) result = (result * 0x100162F3904051FA128BCA9C55C31E5DF) >> 128;
    if (x & 0x10000000000000 > 0) result = (result * 0x1000B175EFFDC76BA38E31671CA939725) >> 128;
    if (x & 0x8000000000000 > 0) result = (result * 0x100058BA01FB9F96D6CACD4B180917C3D) >> 128;
    if (x & 0x4000000000000 > 0) result = (result * 0x10002C5CC37DA9491D0985C348C68E7B3) >> 128;
    if (x & 0x2000000000000 > 0) result = (result * 0x1000162E525EE054754457D5995292026) >> 128;
    if (x & 0x1000000000000 > 0) result = (result * 0x10000B17255775C040618BF4A4ADE83FC) >> 128;
    if (x & 0x800000000000 > 0) result = (result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB) >> 128;
    if (x & 0x400000000000 > 0) result = (result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9) >> 128;
    if (x & 0x200000000000 > 0) result = (result * 0x10000162E43F4F831060E02D839A9D16D) >> 128;
    if (x & 0x100000000000 > 0) result = (result * 0x100000B1721BCFC99D9F890EA06911763) >> 128;
    if (x & 0x80000000000 > 0) result = (result * 0x10000058B90CF1E6D97F9CA14DBCC1628) >> 128;
    if (x & 0x40000000000 > 0) result = (result * 0x1000002C5C863B73F016468F6BAC5CA2B) >> 128;
    if (x & 0x20000000000 > 0) result = (result * 0x100000162E430E5A18F6119E3C02282A5) >> 128;
    if (x & 0x10000000000 > 0) result = (result * 0x1000000B1721835514B86E6D96EFD1BFE) >> 128;
    if (x & 0x8000000000 > 0) result = (result * 0x100000058B90C0B48C6BE5DF846C5B2EF) >> 128;
    if (x & 0x4000000000 > 0) result = (result * 0x10000002C5C8601CC6B9E94213C72737A) >> 128;
    if (x & 0x2000000000 > 0) result = (result * 0x1000000162E42FFF037DF38AA2B219F06) >> 128;
    if (x & 0x1000000000 > 0) result = (result * 0x10000000B17217FBA9C739AA5819F44F9) >> 128;
    if (x & 0x800000000 > 0) result = (result * 0x1000000058B90BFCDEE5ACD3C1CEDC823) >> 128;
    if (x & 0x400000000 > 0) result = (result * 0x100000002C5C85FE31F35A6A30DA1BE50) >> 128;
    if (x & 0x200000000 > 0) result = (result * 0x10000000162E42FF0999CE3541B9FFFCF) >> 128;
    if (x & 0x100000000 > 0) result = (result * 0x100000000B17217F80F4EF5AADDA45554) >> 128;
    if (x & 0x80000000 > 0) result = (result * 0x10000000058B90BFBF8479BD5A81B51AD) >> 128;
    if (x & 0x40000000 > 0) result = (result * 0x1000000002C5C85FDF84BD62AE30A74CC) >> 128;
    if (x & 0x20000000 > 0) result = (result * 0x100000000162E42FEFB2FED257559BDAA) >> 128;
    if (x & 0x10000000 > 0) result = (result * 0x1000000000B17217F7D5A7716BBA4A9AE) >> 128;
    if (x & 0x8000000 > 0) result = (result * 0x100000000058B90BFBE9DDBAC5E109CCE) >> 128;
    if (x & 0x4000000 > 0) result = (result * 0x10000000002C5C85FDF4B15DE6F17EB0D) >> 128;
    if (x & 0x2000000 > 0) result = (result * 0x1000000000162E42FEFA494F1478FDE05) >> 128;
    if (x & 0x1000000 > 0) result = (result * 0x10000000000B17217F7D20CF927C8E94C) >> 128;
    if (x & 0x800000 > 0) result = (result * 0x1000000000058B90BFBE8F71CB4E4B33D) >> 128;
    if (x & 0x400000 > 0) result = (result * 0x100000000002C5C85FDF477B662B26945) >> 128;
    if (x & 0x200000 > 0) result = (result * 0x10000000000162E42FEFA3AE53369388C) >> 128;
    if (x & 0x100000 > 0) result = (result * 0x100000000000B17217F7D1D351A389D40) >> 128;
    if (x & 0x80000 > 0) result = (result * 0x10000000000058B90BFBE8E8B2D3D4EDE) >> 128;
    if (x & 0x40000 > 0) result = (result * 0x1000000000002C5C85FDF4741BEA6E77E) >> 128;
    if (x & 0x20000 > 0) result = (result * 0x100000000000162E42FEFA39FE95583C2) >> 128;
    if (x & 0x10000 > 0) result = (result * 0x1000000000000B17217F7D1CFB72B45E1) >> 128;
    if (x & 0x8000 > 0) result = (result * 0x100000000000058B90BFBE8E7CC35C3F0) >> 128;
    if (x & 0x4000 > 0) result = (result * 0x10000000000002C5C85FDF473E242EA38) >> 128;
    if (x & 0x2000 > 0) result = (result * 0x1000000000000162E42FEFA39F02B772C) >> 128;
    if (x & 0x1000 > 0) result = (result * 0x10000000000000B17217F7D1CF7D83C1A) >> 128;
    if (x & 0x800 > 0) result = (result * 0x1000000000000058B90BFBE8E7BDCBE2E) >> 128;
    if (x & 0x400 > 0) result = (result * 0x100000000000002C5C85FDF473DEA871F) >> 128;
    if (x & 0x200 > 0) result = (result * 0x10000000000000162E42FEFA39EF44D91) >> 128;
    if (x & 0x100 > 0) result = (result * 0x100000000000000B17217F7D1CF79E949) >> 128;
    if (x & 0x80 > 0) result = (result * 0x10000000000000058B90BFBE8E7BCE544) >> 128;
    if (x & 0x40 > 0) result = (result * 0x1000000000000002C5C85FDF473DE6ECA) >> 128;
    if (x & 0x20 > 0) result = (result * 0x100000000000000162E42FEFA39EF366F) >> 128;
    if (x & 0x10 > 0) result = (result * 0x1000000000000000B17217F7D1CF79AFA) >> 128;
    if (x & 0x8 > 0) result = (result * 0x100000000000000058B90BFBE8E7BCD6D) >> 128;
    if (x & 0x4 > 0) result = (result * 0x10000000000000002C5C85FDF473DE6B2) >> 128;
    if (x & 0x2 > 0) result = (result * 0x1000000000000000162E42FEFA39EF358) >> 128;
    if (x & 0x1 > 0) result = (result * 0x10000000000000000B17217F7D1CF79AB) >> 128;

    result >>= uint256(63 - (x >> 64));
    require(result <= uint256(MAX_64x64));

    return int128(result);
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp(int128 x) internal pure returns (int128) {
    require(x < 0x400000000000000000); // Overflow

    if (x < -0x400000000000000000) return 0; // Underflow

    return exp_2(int128((int256(x) * 0x171547652B82FE1777D0FFDA0D23A7D12) >> 128));
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu(uint256 x, uint256 y) private pure returns (uint128) {
    require(y != 0);

    uint256 result;

    if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) result = (x << 64) / y;
    else {
      uint256 msb = 192;
      uint256 xc = x >> 192;
      if (xc >= 0x100000000) {
        xc >>= 32;
        msb += 32;
      }
      if (xc >= 0x10000) {
        xc >>= 16;
        msb += 16;
      }
      if (xc >= 0x100) {
        xc >>= 8;
        msb += 8;
      }
      if (xc >= 0x10) {
        xc >>= 4;
        msb += 4;
      }
      if (xc >= 0x4) {
        xc >>= 2;
        msb += 2;
      }
      if (xc >= 0x2) msb += 1; // No need to shift xc anymore

      result = (x << (255 - msb)) / (((y - 1) >> (msb - 191)) + 1);
      require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

      uint256 hi = result * (y >> 128);
      uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

      uint256 xh = x >> 192;
      uint256 xl = x << 64;

      if (xl < lo) xh -= 1;
      xl -= lo; // We rely on overflow behavior here
      lo = hi << 128;
      if (xl < lo) xh -= 1;
      xl -= lo; // We rely on overflow behavior here

      assert(xh == hi >> 128);

      result += xl / y;
    }

    require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    return uint128(result);
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu(uint256 x) private pure returns (uint128) {
    if (x == 0) return 0;
    else {
      uint256 xx = x;
      uint256 r = 1;
      if (xx >= 0x100000000000000000000000000000000) {
        xx >>= 128;
        r <<= 64;
      }
      if (xx >= 0x10000000000000000) {
        xx >>= 64;
        r <<= 32;
      }
      if (xx >= 0x100000000) {
        xx >>= 32;
        r <<= 16;
      }
      if (xx >= 0x10000) {
        xx >>= 16;
        r <<= 8;
      }
      if (xx >= 0x100) {
        xx >>= 8;
        r <<= 4;
      }
      if (xx >= 0x10) {
        xx >>= 4;
        r <<= 2;
      }
      if (xx >= 0x8) {
        r <<= 1;
      }
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1; // Seven iterations should be enough
      uint256 r1 = x / r;
      return uint128(r < r1 ? r : r1);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "./IAccessController.sol";
import "./IConfigProvider.sol";
import "./ISTABLEX.sol";
import "./IPriceFeed.sol";
import "./IRatesManager.sol";
import "./ILiquidationManager.sol";
import "./IVaultsCore.sol";
import "./IVaultsDataProvider.sol";
import "./IFeeDistributor.sol";

interface IAddressProvider {
  function setAccessController(IAccessController _controller) external;

  function setConfigProvider(IConfigProvider _config) external;

  function setVaultsCore(IVaultsCore _core) external;

  function setStableX(ISTABLEX _stablex) external;

  function setRatesManager(IRatesManager _ratesManager) external;

  function setPriceFeed(IPriceFeed _priceFeed) external;

  function setLiquidationManager(ILiquidationManager _liquidationManager) external;

  function setVaultsDataProvider(IVaultsDataProvider _vaultsData) external;

  function setFeeDistributor(IFeeDistributor _feeDistributor) external;

  function controller() external view returns (IAccessController);

  function config() external view returns (IConfigProvider);

  function core() external view returns (IVaultsCore);

  function stablex() external view returns (ISTABLEX);

  function ratesManager() external view returns (IRatesManager);

  function priceFeed() external view returns (IPriceFeed);

  function liquidationManager() external view returns (ILiquidationManager);

  function vaultsData() external view returns (IVaultsDataProvider);

  function feeDistributor() external view returns (IFeeDistributor);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IAccessController {
  event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
  event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
  event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

  function grantRole(bytes32 role, address account) external;

  function revokeRole(bytes32 role, address account) external;

  function renounceRole(bytes32 role, address account) external;

  function MANAGER_ROLE() external view returns (bytes32);

  function MINTER_ROLE() external view returns (bytes32);

  function hasRole(bytes32 role, address account) external view returns (bool);

  function getRoleMemberCount(bytes32 role) external view returns (uint256);

  function getRoleMember(bytes32 role, uint256 index) external view returns (address);

  function getRoleAdmin(bytes32 role) external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "../interfaces/IAddressProvider.sol";

interface IConfigProvider {
  struct CollateralConfig {
    address collateralType;
    uint256 debtLimit;
    uint256 liquidationRatio;
    uint256 minCollateralRatio;
    uint256 borrowRate;
    uint256 originationFee;
    uint256 liquidationBonus;
    uint256 liquidationFee;
  }

  event CollateralUpdated(
    address indexed collateralType,
    uint256 debtLimit,
    uint256 liquidationRatio,
    uint256 minCollateralRatio,
    uint256 borrowRate,
    uint256 originationFee,
    uint256 liquidationBonus,
    uint256 liquidationFee
  );
  event CollateralRemoved(address indexed collateralType);

  function setCollateralConfig(
    address _collateralType,
    uint256 _debtLimit,
    uint256 _liquidationRatio,
    uint256 _minCollateralRatio,
    uint256 _borrowRate,
    uint256 _originationFee,
    uint256 _liquidationBonus,
    uint256 _liquidationFee
  ) external;

  function removeCollateral(address _collateralType) external;

  function setCollateralDebtLimit(address _collateralType, uint256 _debtLimit) external;

  function setCollateralLiquidationRatio(address _collateralType, uint256 _liquidationRatio) external;

  function setCollateralMinCollateralRatio(address _collateralType, uint256 _minCollateralRatio) external;

  function setCollateralBorrowRate(address _collateralType, uint256 _borrowRate) external;

  function setCollateralOriginationFee(address _collateralType, uint256 _originationFee) external;

  function setCollateralLiquidationBonus(address _collateralType, uint256 _liquidationBonus) external;

  function setCollateralLiquidationFee(address _collateralType, uint256 _liquidationFee) external;

  function setMinVotingPeriod(uint256 _minVotingPeriod) external;

  function setMaxVotingPeriod(uint256 _maxVotingPeriod) external;

  function setVotingQuorum(uint256 _votingQuorum) external;

  function setProposalThreshold(uint256 _proposalThreshold) external;

  function a() external view returns (IAddressProvider);

  function collateralConfigs(uint256 _id) external view returns (CollateralConfig memory);

  function collateralIds(address _collateralType) external view returns (uint256);

  function numCollateralConfigs() external view returns (uint256);

  function minVotingPeriod() external view returns (uint256);

  function maxVotingPeriod() external view returns (uint256);

  function votingQuorum() external view returns (uint256);

  function proposalThreshold() external view returns (uint256);

  function collateralDebtLimit(address _collateralType) external view returns (uint256);

  function collateralLiquidationRatio(address _collateralType) external view returns (uint256);

  function collateralMinCollateralRatio(address _collateralType) external view returns (uint256);

  function collateralBorrowRate(address _collateralType) external view returns (uint256);

  function collateralOriginationFee(address _collateralType) external view returns (uint256);

  function collateralLiquidationBonus(address _collateralType) external view returns (uint256);

  function collateralLiquidationFee(address _collateralType) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IAddressProvider.sol";

interface ISTABLEX is IERC20 {
  function mint(address account, uint256 amount) external;

  function burn(address account, uint256 amount) external;

  function a() external view returns (IAddressProvider);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../chainlink/AggregatorV3Interface.sol";
import "../interfaces/IAddressProvider.sol";

interface IPriceFeed {
  event OracleUpdated(address indexed asset, address oracle, address sender);
  event EurOracleUpdated(address oracle, address sender);

  function setAssetOracle(address _asset, address _oracle) external;

  function setEurOracle(address _oracle) external;

  function a() external view returns (IAddressProvider);

  function assetOracles(address _asset) external view returns (AggregatorV3Interface);

  function eurOracle() external view returns (AggregatorV3Interface);

  function getAssetPrice(address _asset) external view returns (uint256);

  function convertFrom(address _asset, uint256 _amount) external view returns (uint256);

  function convertTo(address _asset, uint256 _amount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "../interfaces/IAddressProvider.sol";

interface IRatesManager {
  function a() external view returns (IAddressProvider);

  //current annualized borrow rate
  function annualizedBorrowRate(uint256 _currentBorrowRate) external pure returns (uint256);

  //uses current cumulative rate to calculate totalDebt based on baseDebt at time T0
  function calculateDebt(uint256 _baseDebt, uint256 _cumulativeRate) external pure returns (uint256);

  //uses current cumulative rate to calculate baseDebt at time T0
  function calculateBaseDebt(uint256 _debt, uint256 _cumulativeRate) external pure returns (uint256);

  //calculate a new cumulative rate
  function calculateCumulativeRate(
    uint256 _borrowRate,
    uint256 _cumulativeRate,
    uint256 _timeElapsed
  ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "../interfaces/IAddressProvider.sol";

interface ILiquidationManager {
  function a() external view returns (IAddressProvider);

  function calculateHealthFactor(
    uint256 _collateralValue,
    uint256 _vaultDebt,
    uint256 _minRatio
  ) external view returns (uint256 healthFactor);

  function liquidationBonus(address _collateralType, uint256 _amount) external view returns (uint256 bonus);

  function applyLiquidationDiscount(address _collateralType, uint256 _amount)
    external
    view
    returns (uint256 discountedAmount);

  function isHealthy(
    uint256 _collateralValue,
    uint256 _vaultDebt,
    uint256 _minRatio
  ) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;
import "../interfaces/IAddressProvider.sol";
import "../interfaces/IVaultsCoreState.sol";
import "../interfaces/IWETH.sol";
import "../liquidityMining/interfaces/IDebtNotifier.sol";

interface IVaultsCore {
  event Opened(uint256 indexed vaultId, address indexed collateralType, address indexed owner);
  event Deposited(uint256 indexed vaultId, uint256 amount, address indexed sender);
  event Withdrawn(uint256 indexed vaultId, uint256 amount, address indexed sender);
  event Borrowed(uint256 indexed vaultId, uint256 amount, address indexed sender);
  event Repaid(uint256 indexed vaultId, uint256 amount, address indexed sender);
  event Liquidated(
    uint256 indexed vaultId,
    uint256 debtRepaid,
    uint256 collateralLiquidated,
    address indexed owner,
    address indexed sender
  );

  event InsurancePaid(uint256 indexed vaultId, uint256 insuranceAmount, address indexed sender);

  function deposit(address _collateralType, uint256 _amount) external;

  function depositETH() external payable;

  function depositByVaultId(uint256 _vaultId, uint256 _amount) external;

  function depositETHByVaultId(uint256 _vaultId) external payable;

  function depositAndBorrow(
    address _collateralType,
    uint256 _depositAmount,
    uint256 _borrowAmount
  ) external;

  function depositETHAndBorrow(uint256 _borrowAmount) external payable;

  function withdraw(uint256 _vaultId, uint256 _amount) external;

  function withdrawETH(uint256 _vaultId, uint256 _amount) external;

  function borrow(uint256 _vaultId, uint256 _amount) external;

  function repayAll(uint256 _vaultId) external;

  function repay(uint256 _vaultId, uint256 _amount) external;

  function liquidate(uint256 _vaultId) external;

  function liquidatePartial(uint256 _vaultId, uint256 _amount) external;

  function upgrade(address payable _newVaultsCore) external;

  function acceptUpgrade(address payable _oldVaultsCore) external;

  function setDebtNotifier(IDebtNotifier _debtNotifier) external;

  //Read only
  function a() external view returns (IAddressProvider);

  function WETH() external view returns (IWETH);

  function debtNotifier() external view returns (IDebtNotifier);

  function state() external view returns (IVaultsCoreState);

  function cumulativeRates(address _collateralType) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;
import "../interfaces/IAddressProvider.sol";

interface IVaultsDataProvider {
  struct Vault {
    // borrowedType support USDX / PAR
    address collateralType;
    address owner;
    uint256 collateralBalance;
    uint256 baseDebt;
    uint256 createdAt;
  }

  //Write
  function createVault(address _collateralType, address _owner) external returns (uint256);

  function setCollateralBalance(uint256 _id, uint256 _balance) external;

  function setBaseDebt(uint256 _id, uint256 _newBaseDebt) external;

  // Read
  function a() external view returns (IAddressProvider);

  function baseDebt(address _collateralType) external view returns (uint256);

  function vaultCount() external view returns (uint256);

  function vaults(uint256 _id) external view returns (Vault memory);

  function vaultOwner(uint256 _id) external view returns (address);

  function vaultCollateralType(uint256 _id) external view returns (address);

  function vaultCollateralBalance(uint256 _id) external view returns (uint256);

  function vaultBaseDebt(uint256 _id) external view returns (uint256);

  function vaultId(address _collateralType, address _owner) external view returns (uint256);

  function vaultExists(uint256 _id) external view returns (bool);

  function vaultDebt(uint256 _vaultId) external view returns (uint256);

  function debt() external view returns (uint256);

  function collateralDebt(address _collateralType) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../interfaces/IAddressProvider.sol";

interface IFeeDistributor {
  event PayeeAdded(address indexed account, uint256 shares);
  event FeeReleased(uint256 income, uint256 releasedAt);

  function release() external;

  function changePayees(address[] memory _payees, uint256[] memory _shares) external;

  function a() external view returns (IAddressProvider);

  function lastReleasedAt() external view returns (uint256);

  function getPayees() external view returns (address[] memory);

  function totalShares() external view returns (uint256);

  function shares(address payee) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;
import "./IAddressProvider.sol";
import "../v1/interfaces/IVaultsCoreV1.sol";

interface IVaultsCoreState {
  event CumulativeRateUpdated(address indexed collateralType, uint256 elapsedTime, uint256 newCumulativeRate); //cumulative interest rate from deployment time T0

  function initializeRates(address _collateralType) external;

  function refresh() external;

  function refreshCollateral(address collateralType) external;

  function syncState(IVaultsCoreState _stateAddress) external;

  function syncStateFromV1(IVaultsCoreV1 _core) external;

  //Read only
  function a() external view returns (IAddressProvider);

  function availableIncome() external view returns (uint256);

  function cumulativeRates(address _collateralType) external view returns (uint256);

  function lastRefresh(address _collateralType) external view returns (uint256);

  function synced() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

interface IWETH {
  function deposit() external payable;

  function transfer(address to, uint256 value) external returns (bool);

  function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "../../governance/interfaces/IGovernanceAddressProvider.sol";
import "./ISupplyMiner.sol";

interface IDebtNotifier {
  function debtChanged(uint256 _vaultId) external;

  function setCollateralSupplyMiner(address collateral, ISupplyMiner supplyMiner) external;

  function a() external view returns (IGovernanceAddressProvider);

  function collateralSupplyMinerMapping(address collateral) external view returns (ISupplyMiner);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;
import './IAddressProviderV1.sol';

interface IVaultsCoreV1 {
  event Opened(uint256 indexed vaultId, address indexed collateralType, address indexed owner);
  event Deposited(uint256 indexed vaultId, uint256 amount, address indexed sender);
  event Withdrawn(uint256 indexed vaultId, uint256 amount, address indexed sender);
  event Borrowed(uint256 indexed vaultId, uint256 amount, address indexed sender);
  event Repaid(uint256 indexed vaultId, uint256 amount, address indexed sender);
  event Liquidated(
    uint256 indexed vaultId,
    uint256 debtRepaid,
    uint256 collateralLiquidated,
    address indexed owner,
    address indexed sender
  );

  event CumulativeRateUpdated(address indexed collateralType, uint256 elapsedTime, uint256 newCumulativeRate); //cumulative interest rate from deployment time T0

  event InsurancePaid(uint256 indexed vaultId, uint256 insuranceAmount, address indexed sender);

  function deposit(address _collateralType, uint256 _amount) external;

  function withdraw(uint256 _vaultId, uint256 _amount) external;

  function withdrawAll(uint256 _vaultId) external;

  function borrow(uint256 _vaultId, uint256 _amount) external;

  function repayAll(uint256 _vaultId) external;

  function repay(uint256 _vaultId, uint256 _amount) external;

  function liquidate(uint256 _vaultId) external;

  //Refresh
  function initializeRates(address _collateralType) external;

  function refresh() external;

  function refreshCollateral(address collateralType) external;

  //upgrade
  function upgrade(address _newVaultsCore) external;

  //Read only

  function a() external view returns (IAddressProviderV1);

  function availableIncome() external view returns (uint256);

  function cumulativeRates(address _collateralType) external view returns (uint256);

  function lastRefresh(address _collateralType) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import './IConfigProviderV1.sol';
import './ILiquidationManagerV1.sol';
import './IVaultsCoreV1.sol';
import '../../interfaces/IVaultsCore.sol';
import '../../interfaces/IAccessController.sol';
import '../../interfaces/ISTABLEX.sol';
import '../../interfaces/IPriceFeed.sol';
import '../../interfaces/IRatesManager.sol';
import '../../interfaces/IVaultsDataProvider.sol';
import '../../interfaces/IFeeDistributor.sol';

interface IAddressProviderV1 {
  function setAccessController(IAccessController _controller) external;

  function setConfigProvider(IConfigProviderV1 _config) external;

  function setVaultsCore(IVaultsCoreV1 _core) external;

  function setStableX(ISTABLEX _stablex) external;

  function setRatesManager(IRatesManager _ratesManager) external;

  function setPriceFeed(IPriceFeed _priceFeed) external;

  function setLiquidationManager(ILiquidationManagerV1 _liquidationManager) external;

  function setVaultsDataProvider(IVaultsDataProvider _vaultsData) external;

  function setFeeDistributor(IFeeDistributor _feeDistributor) external;

  function controller() external view returns (IAccessController);

  function config() external view returns (IConfigProviderV1);

  function core() external view returns (IVaultsCoreV1);

  function stablex() external view returns (ISTABLEX);

  function ratesManager() external view returns (IRatesManager);

  function priceFeed() external view returns (IPriceFeed);

  function liquidationManager() external view returns (ILiquidationManagerV1);

  function vaultsData() external view returns (IVaultsDataProvider);

  function feeDistributor() external view returns (IFeeDistributor);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import './IAddressProviderV1.sol';

interface IConfigProviderV1 {
  struct CollateralConfig {
    address collateralType;
    uint256 debtLimit;
    uint256 minCollateralRatio;
    uint256 borrowRate;
    uint256 originationFee;
  }

  event CollateralUpdated(
    address indexed collateralType,
    uint256 debtLimit,
    uint256 minCollateralRatio,
    uint256 borrowRate,
    uint256 originationFee
  );
  event CollateralRemoved(address indexed collateralType);

  function setCollateralConfig(
    address _collateralType,
    uint256 _debtLimit,
    uint256 _minCollateralRatio,
    uint256 _borrowRate,
    uint256 _originationFee
  ) external;

  function removeCollateral(address _collateralType) external;

  function setCollateralDebtLimit(address _collateralType, uint256 _debtLimit) external;

  function setCollateralMinCollateralRatio(address _collateralType, uint256 _minCollateralRatio) external;

  function setCollateralBorrowRate(address _collateralType, uint256 _borrowRate) external;

  function setCollateralOriginationFee(address _collateralType, uint256 _originationFee) external;

  function setLiquidationBonus(uint256 _bonus) external;

  function a() external view returns (IAddressProviderV1);

  function collateralConfigs(uint256 _id) external view returns (CollateralConfig memory);

  function collateralIds(address _collateralType) external view returns (uint256);

  function numCollateralConfigs() external view returns (uint256);

  function liquidationBonus() external view returns (uint256);

  function collateralDebtLimit(address _collateralType) external view returns (uint256);

  function collateralMinCollateralRatio(address _collateralType) external view returns (uint256);

  function collateralBorrowRate(address _collateralType) external view returns (uint256);

  function collateralOriginationFee(address _collateralType) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import './IAddressProviderV1.sol';

interface ILiquidationManagerV1 {
  function a() external view returns (IAddressProviderV1);

  function calculateHealthFactor(
    address _collateralType,
    uint256 _collateralValue,
    uint256 _vaultDebt
  ) external view returns (uint256 healthFactor);

  function liquidationBonus(uint256 _amount) external view returns (uint256 bonus);

  function applyLiquidationDiscount(uint256 _amount) external view returns (uint256 discountedAmount);

  function isHealthy(
    address _collateralType,
    uint256 _collateralValue,
    uint256 _vaultDebt
  ) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

interface ISupplyMiner {
  function baseDebtChanged(address user, uint256 newBaseDebt) external;
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

interface IGovernorAlpha {
  /// @notice Possible states that a proposal may be in
  enum ProposalState { Active, Canceled, Defeated, Succeeded, Queued, Expired, Executed }

  struct Proposal {
    // Unique id for looking up a proposal
    uint256 id;
    // Creator of the proposal
    address proposer;
    // The timestamp that the proposal will be available for execution, set once the vote succeeds
    uint256 eta;
    // the ordered list of target addresses for calls to be made
    address[] targets;
    // The ordered list of values (i.e. msg.value) to be passed to the calls to be made
    uint256[] values;
    // The ordered list of function signatures to be called
    string[] signatures;
    // The ordered list of calldata to be passed to each call
    bytes[] calldatas;
    // The timestamp at which voting begins: holders must delegate their votes prior to this timestamp
    uint256 startTime;
    // The timestamp at which voting ends: votes must be cast prior to this timestamp
    uint256 endTime;
    // Current number of votes in favor of this proposal
    uint256 forVotes;
    // Current number of votes in opposition to this proposal
    uint256 againstVotes;
    // Flag marking whether the proposal has been canceled
    bool canceled;
    // Flag marking whether the proposal has been executed
    bool executed;
    // Receipts of ballots for the entire set of voters
    mapping(address => Receipt) receipts;
  }

  /// @notice Ballot receipt record for a voter
  struct Receipt {
    // Whether or not a vote has been cast
    bool hasVoted;
    // Whether or not the voter supports the proposal
    bool support;
    // The number of votes the voter had, which were cast
    uint256 votes;
  }

  /// @notice An event emitted when a new proposal is created
  event ProposalCreated(
    uint256 id,
    address proposer,
    address[] targets,
    uint256[] values,
    string[] signatures,
    bytes[] calldatas,
    uint256 startTime,
    uint256 endTime,
    string description
  );

  /// @notice An event emitted when a vote has been cast on a proposal
  event VoteCast(address voter, uint256 proposalId, bool support, uint256 votes);

  /// @notice An event emitted when a proposal has been canceled
  event ProposalCanceled(uint256 id);

  /// @notice An event emitted when a proposal has been queued in the Timelock
  event ProposalQueued(uint256 id, uint256 eta);

  /// @notice An event emitted when a proposal has been executed in the Timelock
  event ProposalExecuted(uint256 id);

  function propose(
    address[] memory targets,
    uint256[] memory values,
    string[] memory signatures,
    bytes[] memory calldatas,
    string memory description,
    uint256 endTime
  ) external returns (uint256);

  function queue(uint256 proposalId) external;

  function execute(uint256 proposalId) external payable;

  function cancel(uint256 proposalId) external;

  function castVote(uint256 proposalId, bool support) external;

  function getActions(uint256 proposalId)
    external
    view
    returns (
      address[] memory targets,
      uint256[] memory values,
      string[] memory signatures,
      bytes[] memory calldatas
    );

  function getReceipt(uint256 proposalId, address voter) external view returns (Receipt memory);

  function state(uint256 proposalId) external view returns (ProposalState);

  function quorumVotes() external view returns (uint256);

  function proposalThreshold() external view returns (uint256);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.6.12;

interface ITimelock {
  event NewAdmin(address indexed newAdmin);
  event NewPendingAdmin(address indexed newPendingAdmin);
  event NewDelay(uint256 indexed newDelay);
  event CancelTransaction(
    bytes32 indexed txHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 eta
  );
  event ExecuteTransaction(
    bytes32 indexed txHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 eta
  );
  event QueueTransaction(
    bytes32 indexed txHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 eta
  );

  function acceptAdmin() external;

  function queueTransaction(
    address target,
    uint256 value,
    string calldata signature,
    bytes calldata data,
    uint256 eta
  ) external returns (bytes32);

  function cancelTransaction(
    address target,
    uint256 value,
    string calldata signature,
    bytes calldata data,
    uint256 eta
  ) external;

  function executeTransaction(
    address target,
    uint256 value,
    string calldata signature,
    bytes calldata data,
    uint256 eta
  ) external payable returns (bytes memory);

  function delay() external view returns (uint256);

  function GRACE_PERIOD() external view returns (uint256);

  function queuedTransactions(bytes32 hash) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMIMO is IERC20 {
  function burn(address account, uint256 amount) external;

  function mint(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "../../interfaces/IAddressProvider.sol";
import "../../governance/interfaces/IGovernanceAddressProvider.sol";

interface IGenericMiner {
  struct UserInfo {
    uint256 stake;
    uint256 accAmountPerShare; // User's accAmountPerShare
  }

  /// @dev This emit when a users' productivity has changed
  /// It emits with the user's address and the the value after the change.
  event StakeIncreased(address indexed user, uint256 stake);

  /// @dev This emit when a users' productivity has changed
  /// It emits with the user's address and the the value after the change.
  event StakeDecreased(address indexed user, uint256 stake);

  function releaseMIMO(address _user) external;

  function a() external view returns (IGovernanceAddressProvider);

  function stake(address _user) external view returns (uint256);

  function pendingMIMO(address _user) external view returns (uint256);

  function totalStake() external view returns (uint256);

  function userInfo(address _user) external view returns (UserInfo memory);
}