//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./StackTreasury.sol";

contract StackExchange is Ownable {
  uint constant private INIT_SHARES = 2e12;
  uint constant private OFFSET = 1e20;
  uint constant private BASE_PERCENT = 1e6;
  uint constant private SWAP_FEE = 50000;
  uint constant private EXCAHNGE_FEE = 100000;
  uint constant public PRICE_DECIMALS = 1e18;

  struct Pool {
    uint shares;
    uint baseReserve;
    uint tokenReserve;
    uint8 tokenDecimals;
    uint rewards;
    uint buyStack;
    uint sellStack;
    uint8 boostMultiplier;
  }

  struct PoolUser {
    uint shares;
    uint claimed;
    uint pending;
  }

  struct Order {
    address account;
    address token;
    uint baseReserve;
    uint tokenReserve;
    uint nextSell;
    uint nextBuy;
    uint sellPrice;
    uint buyPrice;
  }

  address public baseToken;
  uint8 public baseDecimals;
  uint public exchangeFees;

  address public rewardToken;
  uint public boostRewards;

  address[] public pools;
  Order[] public orders;
  mapping (address => Pool) public poolMap;
  mapping (address => mapping (address => PoolUser)) private poolUserMap;
  mapping (address => uint[]) public userOrders;

  constructor(address _baseToken, address _rewardToken) {
    baseToken = _baseToken;
    baseDecimals = IERC20Metadata(baseToken).decimals();
    rewardToken = _rewardToken;
    Order memory nullOrder;
    orders.push(nullOrder);
  }

  function poolsLength() external view returns (uint) {
    return pools.length;
  }

  function getPoolInfo(uint32 index) external view returns (address token, string memory symbol, string memory name, uint8 decimals, uint baseReserve, uint tokenReserve, uint shares) {
    token = pools[index];
    Pool memory pool = poolMap[token];
    symbol = IERC20Metadata(token).symbol();
    name = IERC20Metadata(token).name();
    decimals = pool.tokenDecimals;
    baseReserve = pool.baseReserve;
    tokenReserve = pool.tokenReserve;
    shares = pool.shares;
  }

  function getUserPoolInfo(address token, address account) external view returns (uint shares, uint rewards) {
    Pool memory pool = poolMap[token];
    PoolUser memory poolUser = poolUserMap[token][account];
    shares = poolUser.shares;
    rewards = poolUser.pending + (((poolUser.shares * pool.rewards) / OFFSET) - poolUser.claimed);
  }

  function getUserOrders(address account) external view returns(uint[] memory) {
    return userOrders[account];
  }

  function getOrderInfo(uint orderID) external view returns(address token, string memory symbol, string memory name, uint8 decimals, uint sellPrice, uint buyPrice, uint baseReserve, uint tokenReserve) {
    Order memory order = orders[orderID];
    token = order.token;
    symbol = IERC20Metadata(token).symbol();
    name = IERC20Metadata(token).name();
    decimals = IERC20Metadata(token).decimals();
    sellPrice = order.sellPrice;
    buyPrice = order.buyPrice;
    baseReserve = order.baseReserve;
    tokenReserve = order.tokenReserve;
  }

  function addLiquidity(address token, uint baseAmount, uint tokenAmount) external {
    require(token != baseToken && token != address(0), "BAD_ADDRESS");

    Pool storage pool = poolMap[token];
    PoolUser storage poolUser = poolUserMap[token][address(msg.sender)];
    claimPool(pool.rewards, poolUser);

    require(baseAmount > 0 || tokenAmount > 0, "INVALID_AMOUNT");

    uint shares = 0;
    if (pool.shares == 0) {
      pool.tokenDecimals = IERC20Metadata(token).decimals();
      shares = baseAmount * INIT_SHARES;
      pools.push(token);
    }
    else {
      shares = baseAmount * pool.shares / pool.baseReserve;
      shares += tokenAmount * pool.shares / pool.tokenReserve;
    }

    poolUser.shares += shares;
    pool.shares += shares;
    pool.baseReserve += baseAmount;
    pool.tokenReserve += tokenAmount;

    if (!IERC20(baseToken).transferFrom(address(msg.sender), address(this), baseAmount)) {
      revert("BASE_TRANSFER_FAILED");
    }
    if (!IERC20(token).transferFrom(address(msg.sender), address(this), tokenAmount)) {
      revert("TOKEN_TRANSFER_FAILED");
    }
  }

  function removeLiquidity(address token, uint shares) external {
    Pool storage pool = poolMap[token];
    PoolUser storage poolUser = poolUserMap[token][address(msg.sender)];

    require(pool.baseReserve > 0, "POOL_NOT_FOUND");
    require(shares > 0 && shares < poolUser.shares, "INVALID_SHARES");
    claimPool(pool.rewards, poolUser);

    uint baseValue = pool.baseReserve * shares / pool.shares;
    uint tokenValue = IERC20(token).balanceOf(address(this)) * shares / pool.shares;
    pool.shares -= shares;
    poolUser.shares -= shares;

    if (!IERC20(baseToken).transfer(_msgSender(), baseValue)) {
      revert("BASE_TRANSFER_FAILED");
    }
    if (!IERC20(token).transfer(_msgSender(), tokenValue)) {
      revert("TOKEN_TRANSFER_FAILED");
    }
  }

  function createOrder(address token, uint baseAmount, uint tokenAmount, uint sellPrice, uint buyPrice, uint16 depth) external {
    require(buyPrice > 0 || sellPrice > 0, "INVALID_PRICE");
    Pool storage pool = poolMap[token];
    require(pool.shares > 0, "POOL_NOT_FOUND");
   
    if (baseAmount > 0) SafeERC20.safeTransferFrom(IERC20(baseToken), msg.sender, address(this), baseAmount);
    if (tokenAmount > 0) SafeERC20.safeTransferFrom(IERC20(token), msg.sender, address(this), tokenAmount);

    Order memory order;
    order.account = msg.sender;
    order.token = token;
    order.baseReserve = baseAmount;
    order.tokenReserve = tokenAmount;
    order.sellPrice = sellPrice;
    order.buyPrice = buyPrice;

    if (sellPrice > 0) {
      if (pool.sellStack == 0) {
        pool.sellStack = orders.length;
      }
      else {
        uint orderID = pool.sellStack;
        for (uint16 i = 0; true; i++) {
          if (sellPrice < orders[orderID].sellPrice) {
            order.nextSell = orderID;
            pool.sellStack = orders.length;
            break;
          }
          if (orders[orderID].nextSell == 0) {
            orders[orderID].nextSell = orders.length;
            break;
          }
          orderID = orders[orderID].nextSell;
          if (i >= depth) {
            revert("SELL_DEPTH_REACHED");
          }
        }
      }
    }
    if (buyPrice > 0) {
      if (pool.buyStack == 0) {
        pool.buyStack = orders.length;
      }
      else {
        uint orderID = pool.buyStack;
        for (uint16 i = 0; true; i++) {
          if (buyPrice > orders[orderID].buyPrice) {
            order.nextBuy = orderID;
            pool.buyStack = orders.length;
            break;
          }
          if (orders[orderID].nextBuy == 0) {
            orders[orderID].nextBuy = orders.length;
            break;
          }
          orderID = orders[orderID].nextBuy;
          if (i >= depth) {
            revert("BUY_DEPTH_REACHED");
          }
        }
      }
    }
    userOrders[msg.sender].push(orders.length);
    orders.push(order);
  }

  function swap(address sellToken, address buyToken, address receiver, uint sellAmount) external {
    require(sellToken != buyToken, "SELL_EQUAlS_BUY");
    require(sellAmount > 0, "INVALID_AMOUNT");

    if (receiver == address(0)) {
      receiver = address(msg.sender);
    }

    SafeERC20.safeTransferFrom(IERC20(sellToken), address(msg.sender), address(this), sellAmount);

    uint amount = 0;  
    if (sellToken == baseToken) {
      amount = sellAmount;
    }
    else {
      Pool storage pool = poolMap[sellToken];
      require(pool.tokenReserve > 0 && pool.baseReserve > 0 && pool.shares > 0, "SELL_POOL_NOT_FOUND");

      uint swapAmount;
      do {
        do {
          swapAmount = sellAmount;
          if (pool.buyStack == 0) break;
          int next = int(sqrt((pool.tokenReserve * pool.baseReserve * PRICE_DECIMALS * baseDecimals) / orders[pool.buyStack].buyPrice / pool.tokenDecimals));
          next -= int(pool.tokenReserve);
          if (next > 0) {
            if (uint(next) < sellAmount) swapAmount = uint(next);
            break;
          }
          else {
            Order storage order = orders[pool.buyStack];
            swapAmount = (order.baseReserve * PRICE_DECIMALS) / order.buyPrice;
            if (sellAmount > swapAmount) {
              order.tokenReserve += swapAmount;
              sellAmount -= swapAmount;
              amount += order.baseReserve;
              order.baseReserve = 0;
              pool.buyStack = order.nextBuy;
            }
            else {
              order.tokenReserve += sellAmount;
              uint amountOut = (sellAmount * order.buyPrice) / PRICE_DECIMALS;
              order.baseReserve -= amountOut;
              amount += amountOut;
              sellAmount = 0;
            }
          }
        } while (sellAmount > 0);
        if (sellAmount == 0) break;
        uint baseBuy = pool.baseReserve - ((pool.tokenReserve * pool.baseReserve) / (pool.tokenReserve + swapAmount));
        pool.tokenReserve += swapAmount;
        sellAmount -= swapAmount;
        pool.baseReserve -= baseBuy;
        amount += baseBuy;
        swapAmount = sellAmount;
      } while (sellAmount > 0);

      amount = deductExchangeFee(amount);
      amount = deductSwapFee(pool, amount);
    }

    if (buyToken != baseToken) {
      Pool storage pool = poolMap[buyToken];
      require(pool.tokenReserve > 0 && pool.baseReserve > 0 && pool.shares > 0, "BUY_POOL_NOT_FOUND");

      amount = deductExchangeFee(amount);
      amount = deductSwapFee(pool, amount);

      uint buyAmount = amount;
      uint swapAmount;
      amount = 0;

      do {
        do {
          swapAmount = buyAmount;
          if (pool.sellStack == 0) break;
          int next = int(sqrt((pool.tokenReserve * pool.baseReserve * orders[pool.sellStack].sellPrice * pool.tokenDecimals) / PRICE_DECIMALS / baseDecimals));
          next -= int(pool.baseReserve);
          if (next > 0) {
            if (uint(next) < buyAmount) swapAmount = uint(next);
            break;
          }
          else {
            Order storage order = orders[pool.sellStack];
            swapAmount = (order.tokenReserve * order.sellPrice) / PRICE_DECIMALS;
            if (buyAmount > swapAmount) {
              order.baseReserve += swapAmount;
              buyAmount -= swapAmount;
              amount += order.tokenReserve;
              order.tokenReserve = 0;
              pool.sellStack = order.nextSell;
            }
            else {
              order.baseReserve += buyAmount;
              uint amountOut = (buyAmount * PRICE_DECIMALS) / order.sellPrice;
              order.tokenReserve -= amountOut;
              amount += amountOut;
              buyAmount = 0;
            }
          }
        }
        while (buyAmount > 0);
        if (buyAmount == 0) break;

        uint tokenBuy = pool.tokenReserve - ((pool.baseReserve * pool.tokenReserve) / (pool.baseReserve + swapAmount));
        pool.baseReserve += swapAmount;
        buyAmount -= swapAmount;
        pool.tokenReserve -= tokenBuy;
        amount += tokenBuy;
        swapAmount = buyAmount;
      } while (buyAmount > 0);
    }
    SafeERC20.safeTransfer(IERC20(buyToken), address(msg.sender), amount);
  }

  function harvest(address[] calldata tokens) external {
    uint pending = 0;

    for (uint i = 0; i < tokens.length; i++) {
      PoolUser storage poolUser = poolUserMap[tokens[i]][address(msg.sender)];
      claimPool(poolMap[tokens[i]].rewards, poolUser);
      pending += poolUser.pending;
      poolUser.pending = 0;
    }

    if (pending > 0) {
      SafeERC20.safeTransfer(IERC20(rewardToken), address(msg.sender), pending);
    }
  }

  function deductExchangeFee(uint amount) private returns (uint) {
    uint exchangeFee = amount * EXCAHNGE_FEE / BASE_PERCENT;
    exchangeFees += exchangeFee;
    return amount - exchangeFee;
  }

  function deductSwapFee(Pool storage pool, uint amount) private returns (uint) {
    uint swapFee = amount * SWAP_FEE / BASE_PERCENT;
    if (swapFee > 0) {
      Pool storage rewardPool = poolMap[rewardToken];
      uint reward = rewardPool.tokenReserve - ((rewardPool.tokenReserve * rewardPool.baseReserve) / (rewardPool.baseReserve + swapFee));
      rewardPool.baseReserve += swapFee;
      rewardPool.tokenReserve -= reward;
      if (pool.boostMultiplier > 0) {
        if (((reward * pool.boostMultiplier) / BASE_PERCENT) <= boostRewards) {
          reward = (pool.boostMultiplier * reward) / BASE_PERCENT;
        }
      }
      pool.rewards += (reward * OFFSET) / pool.shares;
    }
    return amount - swapFee;
  }

  function claimPool(uint poolRewards, PoolUser storage poolUser) private {
    if (((poolUser.shares * poolRewards) / OFFSET) > poolUser.claimed) {
      poolUser.pending += (((poolUser.shares * poolRewards) / OFFSET) - poolUser.claimed);
    }
    poolUser.claimed = poolRewards;
  }

  function sqrt(uint x) private pure returns (uint y) {
    uint z = (x + 1) / 2;
    y = x;
    while (z < y) {
      y = z;
      z = (x / z + z) / 2;
    }
  }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract StackTreasury is Ownable {
  
    function ownerWithdraw(address token, address recipient, uint256 amount) external onlyOwner {
        if (!IERC20(token).transfer(recipient, amount)) {
          revert("Failed Treasury Transfer");
        }
    }

    function ownerApprove(address token, address spender, uint256 amount) external onlyOwner {
        if (!IERC20(token).approve(spender, amount)) {
          revert("Failed Treasury Approve");
        }
    }
}

// SPDX-License-Identifier: MIT

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

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}