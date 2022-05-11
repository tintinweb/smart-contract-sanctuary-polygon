// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../libraries/FarmStorage.sol";

contract FarmInit {
  function init(
    address rewardToken,
    uint256 startBlock,
    uint256 decayPeriod
  ) external {
    FarmStorage.Layout storage s = FarmStorage.layout();
    s.rewardToken = IERC20(rewardToken);
    s.startBlock = startBlock;
    s.decayPeriod = decayPeriod;
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