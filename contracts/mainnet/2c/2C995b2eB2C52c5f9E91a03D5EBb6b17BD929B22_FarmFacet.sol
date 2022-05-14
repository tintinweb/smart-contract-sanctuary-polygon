// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../libraries/LibFarm.sol";
import "../abstract/ReentrancyGuard.sol";
import "../abstract/Ownable.sol";

contract FarmFacet is Ownable, ReentrancyGuard {
  // Add a new lp to the pool. Can only be called by the owner.
  // DO NOT add the same LP token more than once. Rewards will be messed up if you do.
  function add(
    uint256 _allocPoint,
    IERC20 _lpToken,
    bool _withUpdate
  ) external onlyOwner {
    LibFarm.add(_allocPoint, _lpToken, _withUpdate);
  }

  // Update the given pool's ERC20 allocation point. Can only be called by the owner.
  function set(
    uint256 _pid,
    uint256 _allocPoint,
    bool _withUpdate
  ) external onlyOwner {
    LibFarm.set(_pid, _allocPoint, _withUpdate);
  }

  // Update reward variables for all pools. Be careful of gas spending!
  function massUpdatePools() external {
    LibFarm.massUpdatePools();
  }

  // Update reward variables of the given pool to be up-to-date.
  function updatePool(uint256 _pid) external {
    LibFarm.updatePool(_pid);
  }

  // Deposit LP tokens to Farm for ERC20 allocation.
  function deposit(uint256 _pid, uint256 _amount)
    external
    nonReentrant
  {
    LibFarm.deposit(_pid, _amount);
  }

  // Withdraw LP tokens from Farm.
  function withdraw(uint256 _pid, uint256 _amount)
    external
    nonReentrant
  {
    LibFarm.withdraw(_pid, _amount);
  }

  // Harvest rewards
  function harvest(uint256 _pid) external nonReentrant {
    LibFarm.updatePoolAndHarvest(msg.sender, _pid);
  }

  // Batch harvest rewards
  function batchHarvest(uint256[] memory _pids)
    external
    nonReentrant
  {
    for (uint256 i = 0; i < _pids.length; ++i) {
      LibFarm.updatePoolAndHarvest(msg.sender, _pids[i]);
    }
  }

  // Withdraw without caring about rewards. EMERGENCY ONLY.
  function emergencyWithdraw(uint256 _pid) external nonReentrant {
    LibFarm.emergencyWithdraw(_pid);
  }

  //////////////////////////////////////////////////////////////////////////////
  // GETTERS
  //////////////////////////////////////////////////////////////////////////////

  // Storage pointer helper
  function s() private pure returns (FarmStorage.Layout storage fs) {
    return FarmStorage.layout();
  }

  // Number of LP pools
  function poolLength() external view returns (uint256) {
    return s().poolInfo.length;
  }

  // View function to see deposited LP for a user.
  function deposited(uint256 _pid, address _user)
    external
    view
    returns (uint256)
  {
    return s().userInfo[_pid][_user].amount;
  }

  // View function to see pending ERC20s for a user.
  function pending(uint256 _pid, address _user)
    public
    view
    returns (uint256)
  {
    PoolInfo storage pool = s().poolInfo[_pid];
    UserInfo storage user = s().userInfo[_pid][_user];
    uint256 accERC20PerShare = pool.accERC20PerShare;
    uint256 lpSupply = pool.lpToken.balanceOf(address(this));

    if (block.number > pool.lastRewardBlock && lpSupply != 0) {
      uint256 nrOfBlocks = block.number - pool.lastRewardBlock;
      uint256 erc20Reward = (LibFarm.sumRewardPerBlock(
        pool.lastRewardBlock,
        nrOfBlocks
      ) * pool.allocPoint) / s().totalAllocPoint;
      accERC20PerShare =
        ((accERC20PerShare + erc20Reward) * 1e12) /
        lpSupply;
    }

    return (user.amount * accERC20PerShare) / 1e12 - user.rewardDebt;
  }

  // View function for total reward the farm has yet to pay out.
  function totalPending()
    external
    view
    returns (uint256 totalPending_)
  {
    uint256 _startBlock = s().startBlock;
    if (block.number <= _startBlock) {
      return 0;
    }

    totalPending_ =
      LibFarm.sumRewardPerBlock(
        _startBlock,
        block.number - _startBlock
      ) -
      s().paidOut;
  }

  struct UserInfoOutput {
    IERC20 lpToken; // LP Token of the pool
    uint256 allocPoint;
    uint256 amount; // Amount user has deposited
    uint256 pending; // Amount of reward pending for this lp token pool
  }

  function allUserInfo(address _user)
    external
    view
    returns (UserInfoOutput[] memory)
  {
    UserInfoOutput[] memory userInfo_ = new UserInfoOutput[](
      s().poolInfo.length
    );
    for (uint256 i = 0; i < s().poolInfo.length; i++) {
      userInfo_[i] = UserInfoOutput({
        lpToken: s().poolInfo[i].lpToken,
        allocPoint: s().poolInfo[i].allocPoint,
        amount: s().userInfo[i][_user].amount,
        pending: pending(i, _user)
      });
    }
    return userInfo_;
  }

  function rewardToken() external view returns (IERC20) {
    return s().rewardToken;
  }

  function paidOut() external view returns (uint256) {
    return s().paidOut;
  }

  // Returns the reward per block for the specified year. 0 is the first year
  function rewardPerBlock(uint256 year)
    external
    pure
    returns (uint256)
  {
    return LibFarm.rewardPerBlock(year);
  }

  function poolInfo(uint256 _pid)
    external
    view
    returns (PoolInfo memory pi)
  {
    return s().poolInfo[_pid];
  }

  function poolTokens(address _token) external view returns (bool) {
    return s().poolTokens[_token];
  }

  function userInfo(uint256 _pid, address _user)
    external
    view
    returns (UserInfo memory ui)
  {
    return s().userInfo[_pid][_user];
  }

  function totalAllocPoint() external view returns (uint256) {
    return s().totalAllocPoint;
  }

  function startBlock() external view returns (uint256) {
    return s().startBlock;
  }

  function decayPeriod() external view returns (uint256) {
    return s().decayPeriod;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { FarmStorage, PoolInfo, UserInfo } from "./FarmStorage.sol";

// Farm distributes the ERC20 rewards based on staked LP to each user.
//
// Forked from https://github.com/SashimiProject/sashimiswap/blob/master/contracts/MasterChef.sol
// Modified for diamonds and decay rate support
library LibFarm {
  using SafeERC20 for IERC20;

  event Deposit(
    address indexed user,
    uint256 indexed pid,
    uint256 amount
  );
  event Withdraw(
    address indexed user,
    uint256 indexed pid,
    uint256 amount
  );
  event EmergencyWithdraw(
    address indexed user,
    uint256 indexed pid,
    uint256 amount
  );
  event Harvest(address indexed user, uint256 amount);

  // Helper getter function for a predefined set of rewards for 30 years
  function rewardPerBlock(uint256 period)
    internal
    pure
    returns (uint256)
  {
    // assumes 13,870,000 blocks per year to distribute a total of 1 trillion GLTR
    uint256[30] memory _rewardPerBlock = [
      uint256(7_209_805_335_256 gwei), // cast to force array to be uint256 (compiler issue)
      6_039_405_905_650 gwei,
      5_059_002_566_246 gwei,
      4_237_752_415_572 gwei,
      3_549_819_416_085 gwei,
      2_973_561_607_920 gwei,
      2_490_850_265_800 gwei,
      2_086_499_580_203 gwei,
      1_747_788_920_901 gwei,
      1_747_788_920_901 gwei,
      1_747_788_920_901 gwei,
      1_747_788_920_901 gwei,
      1_747_788_920_901 gwei,
      1_747_788_920_901 gwei,
      1_747_788_920_901 gwei,
      1_747_788_920_901 gwei,
      1_747_788_920_901 gwei,
      1_747_788_920_901 gwei,
      1_747_788_920_901 gwei,
      1_747_788_920_901 gwei,
      1_747_788_920_901 gwei,
      1_747_788_920_901 gwei,
      1_747_788_920_901 gwei,
      1_747_788_920_901 gwei,
      1_747_788_920_901 gwei,
      1_747_788_920_901 gwei,
      1_747_788_920_901 gwei,
      1_747_788_920_901 gwei,
      1_747_788_920_901 gwei,
      1_747_788_920_901 gwei
    ];
    // Rewards should be zero after rewards are exhausted
    if (period >= _rewardPerBlock.length) {
      return 0;
    } else {
      return _rewardPerBlock[period];
    }
  }

  /// @notice Sums up the rewards for a specified number of blocks from the last reward block
  /// @param lastRewardBlock The block number of the last reward block to calculate from
  /// @param nrOfBlocks The number of blocks to calculate rewards for
  function sumRewardPerBlock(
    uint256 lastRewardBlock,
    uint256 nrOfBlocks
  ) internal view returns (uint256 totalReward) {
    uint256 decayPeriod = s().decayPeriod;

    // Blocks passed from the start block to the last reward block
    uint256 blocksPassedToLastRewardSinceStart = lastRewardBlock -
      s().startBlock;
    // Total amount of blocks left in the current period
    uint256 blocksLeftInCurrentPeriod = decayPeriod -
      (blocksPassedToLastRewardSinceStart % decayPeriod);
    // The period of the last reward block
    uint256 currentPeriod = blocksPassedToLastRewardSinceStart /
      decayPeriod;

    // Add min(current period, nrOfBlocks) * rewardPerBlock to total reward
    totalReward +=
      rewardPerBlock(currentPeriod) *
      (
        nrOfBlocks < blocksLeftInCurrentPeriod
          ? nrOfBlocks
          : blocksLeftInCurrentPeriod
      );

    // This block should be skipped and reward should be returned if the first period is the last one
    if (nrOfBlocks > blocksLeftInCurrentPeriod) {
      // We account for rewards being distributed for the first period
      ++currentPeriod;
      nrOfBlocks -= blocksLeftInCurrentPeriod;
      // Add to total rewards for each period that nrOfBlocks fills
      while (nrOfBlocks >= decayPeriod) {
        totalReward += rewardPerBlock(currentPeriod) * decayPeriod;
        nrOfBlocks -= decayPeriod;
        ++currentPeriod;
      }
      // Add the final rewards
      totalReward += rewardPerBlock(currentPeriod) * nrOfBlocks;
    }
  }

  function s() private pure returns (FarmStorage.Layout storage fs) {
    return FarmStorage.layout();
  }

  // Add a new lp to the pool. Can only be called by the owner.
  // DO NOT add the same LP token more than once. Rewards will be messed up if you do.
  function add(
    uint256 _allocPoint,
    IERC20 _lpToken,
    bool _withUpdate
  ) internal {
    require(
      !s().poolTokens[address(_lpToken)],
      "add: LP token already added"
    );
    s().poolTokens[address(_lpToken)] = true;
    if (_withUpdate) {
      massUpdatePools();
    }
    uint256 lastRewardBlock = block.number > s().startBlock
      ? block.number
      : s().startBlock;
    s().totalAllocPoint += _allocPoint;
    s().poolInfo.push(
      PoolInfo({
        lpToken: _lpToken,
        allocPoint: _allocPoint,
        lastRewardBlock: lastRewardBlock,
        accERC20PerShare: 0
      })
    );
  }

  // Update the given pool's ERC20 allocation point. Can only be called by the owner.
  function set(
    uint256 _pid,
    uint256 _allocPoint,
    bool _withUpdate
  ) internal {
    require(
      s().poolTokens[address(s().poolInfo[_pid].lpToken)],
      "set: LP token not added"
    );
    if (_withUpdate) {
      massUpdatePools();
    }
    s().totalAllocPoint =
      s().totalAllocPoint -
      s().poolInfo[_pid].allocPoint +
      _allocPoint;
    s().poolInfo[_pid].allocPoint = _allocPoint;
  }

  // Update reward variables for all pools. Be careful of gas spending!
  function massUpdatePools() internal {
    uint256 length = s().poolInfo.length;
    for (uint256 pid = 0; pid < length; ) {
      updatePool(pid);
      unchecked {
        ++pid;
      }
    }
  }

  // Update reward variables of the given pool to be up-to-date.
  function updatePool(uint256 _pid) internal {
    PoolInfo storage pool = s().poolInfo[_pid];

    if (block.number <= pool.lastRewardBlock) {
      return;
    }
    uint256 lpSupply = pool.lpToken.balanceOf(address(this));
    if (lpSupply == 0) {
      pool.lastRewardBlock = block.number;
      return;
    }

    uint256 nrOfBlocks = block.number - pool.lastRewardBlock;
    uint256 erc20Reward = (sumRewardPerBlock(
      pool.lastRewardBlock,
      nrOfBlocks
    ) * pool.allocPoint) / s().totalAllocPoint;

    pool.accERC20PerShare =
      ((pool.accERC20PerShare + erc20Reward) * 1e12) /
      lpSupply;
    pool.lastRewardBlock = block.number;
  }

  // Deposit LP tokens to Farm for ERC20 allocation.
  function deposit(uint256 _pid, uint256 _amount) internal {
    PoolInfo storage pool = s().poolInfo[_pid];
    UserInfo storage user = s().userInfo[_pid][msg.sender];

    updatePoolAndHarvest(msg.sender, _pid);

    if (_amount > 0) {
      pool.lpToken.safeTransferFrom(
        address(msg.sender),
        address(this),
        _amount
      );
      user.amount = user.amount + _amount;
    }
    emit Deposit(msg.sender, _pid, _amount);
  }

  // Withdraw LP tokens from Farm.
  function withdraw(uint256 _pid, uint256 _amount) internal {
    PoolInfo storage pool = s().poolInfo[_pid];
    UserInfo storage user = s().userInfo[_pid][msg.sender];
    require(
      user.amount >= _amount,
      "withdraw: can't withdraw more than deposit"
    );

    updatePoolAndHarvest(msg.sender, _pid);

    user.amount = user.amount - _amount;
    pool.lpToken.safeTransfer(address(msg.sender), _amount);
    emit Withdraw(msg.sender, _pid, _amount);
  }

  // Withdraw without caring about rewards. EMERGENCY ONLY.
  function emergencyWithdraw(uint256 _pid) internal {
    PoolInfo storage pool = s().poolInfo[_pid];
    UserInfo storage user = s().userInfo[_pid][msg.sender];
    pool.lpToken.safeTransfer(address(msg.sender), user.amount);
    emit EmergencyWithdraw(msg.sender, _pid, user.amount);
    user.amount = 0;
    user.rewardDebt = 0;
  }

  // Updates the pool and harvests reward tokens
  function updatePoolAndHarvest(address _to, uint256 _pid) internal {
    PoolInfo storage pool = s().poolInfo[_pid];
    UserInfo storage user = s().userInfo[_pid][_to];
    updatePool(_pid);

    uint256 userReward = (user.amount * pool.accERC20PerShare) / 1e12;

    if (user.amount > 0) {
      uint256 pendingAmount = userReward - user.rewardDebt;
      s().rewardToken.transfer(_to, pendingAmount);
      s().paidOut += pendingAmount;
      emit Harvest(_to, pendingAmount);
    }
    user.rewardDebt = userReward;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ReentrancyGuardStorage } from "../libraries/ReentrancyGuardStorage.sol";

/**
 * @title Utility contract for preventing reentrancy attacks
 */
abstract contract ReentrancyGuard {
  modifier nonReentrant() {
    ReentrancyGuardStorage.Layout storage l = ReentrancyGuardStorage
      .layout();
    require(l.status != 2, "ReentrancyGuard: reentrant call");
    l.status = 2;
    _;
    l.status = 1;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../diamond/libraries/LibDiamond.sol";

/**
 * @title Utility contract for preventing reentrancy attacks
 */
abstract contract Ownable {
  modifier onlyOwner() {
    LibDiamond.enforceIsContractOwner();
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct UserInfo {
  uint256 amount; // How many LP tokens the user has provided.
  uint256 rewardDebt; // Reward debt.
}

// Info of each pool.
struct PoolInfo {
  IERC20 lpToken; // Address of LP token contract.
  uint256 allocPoint; // How many allocation points assigned to this pool. ERC20s to distribute per block.
  uint256 lastRewardBlock; // Last block number that ERC20s distribution occurs.
  uint256 accERC20PerShare; // Accumulated ERC20s per share, times 1e12.
}

library FarmStorage {
  struct Layout {
    IERC20 rewardToken; // Address of the ERC20 Token contract.
    uint256 totalRewards; // Amount of rewards to be distributed over the lifetime of the contract
    uint256 paidOut; // The total amount of ERC20 that's paid out as reward.
    PoolInfo[] poolInfo; // Info of each pool.
    mapping(address => bool) poolTokens; // Keep track of which LP tokens are assigned to a pool
    mapping(uint256 => mapping(address => UserInfo)) userInfo; // Info of each user that stakes LP tokens.
    uint256 totalAllocPoint; // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 startBlock; // The block number when farming starts.
    uint256 decayPeriod; // # of blocks after which rewards decay.
  }

  bytes32 internal constant STORAGE_SLOT =
    keccak256("aavegotchi.gax.storage.Farm");

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ReentrancyGuardStorage {
  struct Layout {
    uint256 status;
  }

  bytes32 internal constant STORAGE_SLOT =
    keccak256("solidstate.contracts.storage.ReentrancyGuard");

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndSelectorPosition {
        address facetAddress;
        uint16 selectorPosition;
    }

    struct DiamondStorage {
        // function selector => facet address and selector position in selectors array
        mapping(bytes4 => FacetAddressAndSelectorPosition) facetAddressAndSelectorPosition;
        bytes4[] selectors;
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        uint16 selectorCount = uint16(ds.selectors.length);
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Add facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            require(
                oldFacetAddress == address(0),
                "LibDiamondCut: Can't add function that already exists"
            );
            ds.facetAddressAndSelectorPosition[selector] = FacetAddressAndSelectorPosition(
                _facetAddress,
                selectorCount
            );
            ds.selectors.push(selector);
            selectorCount++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Replace facet can't be address(0)");
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Replace facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            // can't replace immutable functions -- functions defined directly in the diamond
            require(
                oldFacetAddress != address(this),
                "LibDiamondCut: Can't replace immutable function"
            );
            require(
                oldFacetAddress != _facetAddress,
                "LibDiamondCut: Can't replace function with same function"
            );
            require(
                oldFacetAddress != address(0),
                "LibDiamondCut: Can't replace function that doesn't exist"
            );
            // replace old facet address
            ds.facetAddressAndSelectorPosition[selector].facetAddress = _facetAddress;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        require(
            _facetAddress == address(0),
            "LibDiamondCut: Remove facet address must be address(0)"
        );
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            FacetAddressAndSelectorPosition memory oldFacetAddressAndSelectorPosition = ds
            .facetAddressAndSelectorPosition[selector];
            require(
                oldFacetAddressAndSelectorPosition.facetAddress != address(0),
                "LibDiamondCut: Can't remove function that doesn't exist"
            );
            // can't remove immutable functions -- functions defined directly in the diamond
            require(
                oldFacetAddressAndSelectorPosition.facetAddress != address(this),
                "LibDiamondCut: Can't remove immutable function."
            );
            // replace selector with last selector
            selectorCount--;
            if (oldFacetAddressAndSelectorPosition.selectorPosition != selectorCount) {
                bytes4 lastSelector = ds.selectors[selectorCount];
                ds.selectors[oldFacetAddressAndSelectorPosition.selectorPosition] = lastSelector;
                ds
                .facetAddressAndSelectorPosition[lastSelector]
                .selectorPosition = oldFacetAddressAndSelectorPosition.selectorPosition;
            }
            // delete last selector
            ds.selectors.pop();
            delete ds.facetAddressAndSelectorPosition[selector];
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(
                _calldata.length == 0,
                "LibDiamondCut: _init is address(0) but_calldata is not empty"
            );
        } else {
            require(
                _calldata.length > 0,
                "LibDiamondCut: _calldata is empty but _init is not address(0)"
            );
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}