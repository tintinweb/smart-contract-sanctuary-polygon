// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.14;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IAave {
  function repay(address,uint256,uint256,address) external returns (uint256);
}

interface IRewardsOnlyGauge {

  struct Reward {
    address token;
    address distributor;
    uint256 period_finish;
    uint256 rate;
    uint256 last_update;
    uint256 integral;
  }
  function rewards_receiver(address) external returns (address);
  function reward_data(address) external returns (Reward memory);
}

interface ChildChainGaugeRewardHelper {
    function claimRewardsFromGauge(IRewardsOnlyGauge gauge, address user) external;
}

interface IAavePool {
  function scaledBalanceOf(address) external returns (uint256);
}

contract BALHelper {
  address public constant HELPER = 0xaEb406b0E430BF5Ea2Dc0B9Fe62E4E53f74B3a33;
  address public constant BAL = 0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3;
  address public constant AAVE = 0x794a61358D6845594F94dc1DB02A252b5b4814aD;
  address public constant BALDEBT = 0xA8669021776Bc142DfcA87c21b4A52595bCbB40a;

  address public operator;
  bool lock = false;
  mapping (address => mapping (address => bool)) executors;

  constructor(address _operator) {  
    operator = _operator;
    IERC20(BAL).approve(AAVE, type(uint).max);
  }

  function rescue(address token, uint amount) external {
    require(msg.sender == operator);
    IERC20(token).transfer(operator, amount);
  }

  function setExecutorAllowed(address executor, bool allowed) external {
    executors[msg.sender][executor] = allowed;
  }

  function execute(address gauge, address owner) external {
    require(!lock);
    lock = true;
    require(executors[owner][msg.sender]);
    // BAL must be reward for gauge
    IRewardsOnlyGauge.Reward memory rewardData = IRewardsOnlyGauge(gauge).reward_data(BAL);
    require(rewardData.distributor != address(0));
    // receiver must be the owner
    require(IRewardsOnlyGauge(gauge).rewards_receiver(owner) == address(0));
    uint mybalance = IERC20(BAL).balanceOf(address(this));
    uint balance = IERC20(BAL).balanceOf(owner);
    ChildChainGaugeRewardHelper(HELPER).claimRewardsFromGauge(IRewardsOnlyGauge(gauge), owner);
    uint rewarded = IERC20(BAL).balanceOf(owner) - balance;
    uint debt = IAavePool(BALDEBT).scaledBalanceOf(owner);
    if (debt == 0) return;
    if (debt < rewarded) { rewarded = debt; }
    IERC20(BAL).transferFrom(owner, address(this), rewarded);
    IAave(AAVE).repay(BAL, rewarded, 2, owner);
    require(IERC20(BAL).balanceOf(address(this)) == mybalance);
    require(IERC20(BAL).balanceOf(address(owner)) == balance);
    lock = false;
  }


}