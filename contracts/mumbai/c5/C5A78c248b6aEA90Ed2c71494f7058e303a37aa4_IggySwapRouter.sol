// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IUniswapV2Factory {
  function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Pair {
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IUniswapV2Router02 {
  function WETH() external pure returns (address);
  function factory() external pure returns (address);
  function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB, uint liquidity);

  function addLiquidityETH(
    address token,
    uint amountTokenDesired,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB);

  function removeLiquidityETH(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external returns (uint amountToken, uint amountETH);

  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);
}

interface IWETH {
  function deposit() external payable;
  function withdraw(uint) external;
}

/// @title Iggy swap router contract
/// @author Tempe Techie
/// @notice Contract that helps an Iggy frontend to swap tokens (custom because it's specific to a particular frontend)
contract IggySwapRouter is Ownable {
  using SafeERC20 for IERC20;

  address public frontendAddress; // address of a DAO/community which runs the frontend
  address public iggyAddress;
  address public routerAddress; // DEX router address
  address public feeChangerAddress; // a special role that is allowed to change fees and share amounts
  address public immutable wethAddress;

  uint256 public constant MAX_BPS = 10_000;
  uint256 public swapFee = 80; // 0.8% default fee
  uint256 public referrerShare = 1000; // 10% share of the swap fee
  uint256 public frontendShare = 5000; // 50% share of the swap fee (after referrer share is deducted)

  // MODIFIERS
  modifier onlyFeeChanger() {
    require(msg.sender == feeChangerAddress, "IggySwap: Sender is not the Fee Changer");
    _;
  }

  // CONSTRUCTOR
  constructor(
    address _frontendAddress,
    address _iggyAddress,
    address _routerAddress
  ) {
    frontendAddress = _frontendAddress;
    iggyAddress = _iggyAddress;
    routerAddress = _routerAddress;
    feeChangerAddress = msg.sender;
    wethAddress = IUniswapV2Router02(_routerAddress).WETH();
  }

  // RECEIVE
  receive() external payable {}

  // READ PUBLIC/EXTERNAL

  /// @notice Preview the amount of tokens that would be received for a given swap
  function getAmountsOut(
    uint amountIn, 
    address[] memory path
  ) public view returns (uint[] memory amounts) {
    amounts = _getTokensAmountOut(amountIn, path);
    amounts[amounts.length - 1] = amounts[amounts.length - 1] - _getFeeAmount(amounts[amounts.length - 1]); // deduce swap fee from amount out
  }

  /// @notice Get LP (pair) token address for a given pair of tokens
  function getLpTokenAddress(address tokenA, address tokenB) external view returns (address) {
    if (tokenA == address(0)) {
      tokenA = wethAddress;
    }

    if (tokenB == address(0)) {
      tokenB = wethAddress;
    }

    return IUniswapV2Factory(IUniswapV2Router02(routerAddress).factory()).getPair(tokenA, tokenB);
  }

  /// @notice Calculates the price impact of a swap (in bips)
  function getPriceImpact(
    address tokenIn, 
    address tokenOut, 
    uint amountIn
  ) external view returns (uint) {
    if (tokenIn == address(0)) {
      tokenIn = wethAddress;
    }

    if (tokenOut == address(0)) {
      tokenOut = wethAddress;
    }

    if (tokenIn == tokenOut) {
      return 0;
    }

    // get factory address from router
    address factoryAddress = IUniswapV2Router02(routerAddress).factory();

    // get reserves for both tokens (reserve is a token total amount in a pool)
    (uint reserveIn, uint reserveOut) = _getReserves(factoryAddress, tokenIn, tokenOut);

    uint k = reserveIn * reserveOut; // calculate a constant k (x * y = k, standard Uniswap V2 formula)

    // calculate the amount of tokens user would receive if they swapped
    uint newReserveOut = k / (reserveIn + amountIn);

    uint amountOut = reserveOut - newReserveOut;

    return (amountOut * MAX_BPS) / newReserveOut; // return price impact in bips
  }
  
  // WRITE PUBLIC/EXTERNAL

  /// @notice Add liquidity to a pool (both tokens must be ERC-20 tokens)
  function addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB, uint liquidity) {
    // transfer tokens to this contract
    IERC20(tokenA).safeTransferFrom(msg.sender, address(this), amountADesired);
    IERC20(tokenB).safeTransferFrom(msg.sender, address(this), amountBDesired);

    // approve tokens to be spent by router
    IERC20(tokenA).approve(routerAddress, amountADesired);
    IERC20(tokenB).approve(routerAddress, amountBDesired);

    // add liquidity
    (amountA, amountB, liquidity) = IUniswapV2Router02(routerAddress).addLiquidity(
      tokenA,
      tokenB,
      amountADesired,
      amountBDesired,
      amountAMin,
      amountBMin,
      to,
      deadline
    );
  }

  function addLiquidityETH(
    address token,
    uint amountTokenDesired,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external payable returns (uint amountToken, uint amountETH, uint liquidity) {
    // transfer tokens to this contract
    IERC20(token).safeTransferFrom(msg.sender, address(this), amountTokenDesired);

    // approve tokens to be spent by router
    IERC20(token).approve(routerAddress, amountTokenDesired);

    // add liquidity
    (amountToken, amountETH, liquidity) = IUniswapV2Router02(routerAddress).addLiquidityETH{value: msg.value}(
      token,
      amountTokenDesired,
      amountTokenMin,
      amountETHMin,
      to,
      deadline
    );
  }

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB) {
    // get factory address from router
    address factoryAddress = IUniswapV2Router02(routerAddress).factory();

    // get LP token address
    address pair = IUniswapV2Factory(factoryAddress).getPair(tokenA, tokenB);

    // transfer liquidity tokens to this contract
    IERC20(pair).safeTransferFrom(msg.sender, address(this), liquidity);

    // approve tokens to be spent by router
    IERC20(pair).approve(routerAddress, liquidity);

    // remove liquidity
    (amountA, amountB) = IUniswapV2Router02(routerAddress).removeLiquidity(
      tokenA,
      tokenB,
      liquidity,
      amountAMin,
      amountBMin,
      to,
      deadline
    );
  }

  function removeLiquidityETH(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external returns (uint amountToken, uint amountETH) {
    // get factory address from router
    address factoryAddress = IUniswapV2Router02(routerAddress).factory();

    // get LP token address
    address pair = IUniswapV2Factory(factoryAddress).getPair(token, wethAddress);

    // transfer liquidity tokens to this contract
    IERC20(pair).safeTransferFrom(msg.sender, address(this), liquidity);

    // approve tokens to be spent by router
    IERC20(pair).approve(routerAddress, liquidity);

    // remove liquidity
    (amountToken, amountETH) = IUniswapV2Router02(routerAddress).removeLiquidityETH(
      token,
      liquidity,
      amountTokenMin,
      amountETHMin,
      to,
      deadline
    );
  }

  /// @notice Swap exact ERC-20 tokens for ERC-20 tokens
  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin, // amount out deducted by slippage
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts) {
    IERC20(path[0]).safeTransferFrom(msg.sender, address(this), amountIn); // send user's tokens to this contract

    amounts = _swap(amountIn, amountOutMin, path, to, deadline, address(0), false); // no referrer
  }

  /// @notice Swap exact ERC-20 tokens for ERC-20 tokens (with referrer)
  function swapExactTokensForTokensWithReferrer(
    uint amountIn,
    uint amountOutMin, // amount out deducted by slippage
    address[] calldata path,
    address to,
    uint deadline,
    address referrer
  ) external returns (uint[] memory amounts) {
    IERC20(path[0]).safeTransferFrom(msg.sender, address(this), amountIn); // send user's tokens to this contract

    amounts = _swap(amountIn, amountOutMin, path, to, deadline, referrer, false);
  }

  /// @notice Swap exact ERC-20 tokens for ETH
  function swapExactTokensForETH(
    uint amountIn, 
    uint amountOutMin, 
    address[] memory path, 
    address to, 
    uint deadline
  ) external returns (uint[] memory amounts) {
    IERC20(path[0]).safeTransferFrom(msg.sender, address(this), amountIn); // send user's tokens to this contract

    if (path[path.length - 1] == address(0)) {
      path[path.length - 1] = wethAddress;
    }

    amounts = _swap(amountIn, amountOutMin, path, to, deadline, address(0), true); // no referrer
  }

  /// @notice Swap exact ERC-20 tokens for ETH (with referrer)
  function swapExactTokensForETHWithReferrer(
    uint amountIn, 
    uint amountOutMin, 
    address[] memory path, 
    address to, 
    uint deadline,
    address referrer
  ) external returns (uint[] memory amounts) {
    IERC20(path[0]).safeTransferFrom(msg.sender, address(this), amountIn); // send user's tokens to this contract

    if (path[path.length - 1] == address(0)) {
      path[path.length - 1] = wethAddress;
    }

    amounts = _swap(amountIn, amountOutMin, path, to, deadline, referrer, true);
  }

  /// @notice Swap exact ETH for ERC-20 tokens
  function swapExactETHForTokens(
    uint amountOutMin, 
    address[] memory path, 
    address to, 
    uint deadline
  ) external payable returns (uint[] memory amounts) {
    require(msg.value > 0, "IggySwap: Native coin amount is zero");

    IWETH(wethAddress).deposit{value: msg.value}(); // convert ETH to WETH

    if (path[0] == address(0)) {
      path[0] = wethAddress;
    }

    amounts = _swap(msg.value, amountOutMin, path, to, deadline, address(0), false); // no referrer
  }

  /// @notice Swap exact ETH for ERC-20 tokens (with referrer)
  function swapExactETHForTokensWithReferrer(
    uint amountOutMin, 
    address[] memory path, 
    address to, 
    uint deadline,
    address referrer
  ) external payable returns (uint[] memory amounts) {
    require(msg.value > 0, "IggySwap: Native coin amount is zero");

    IWETH(wethAddress).deposit{value: msg.value}(); // convert ETH to WETH

    if (path[0] == address(0)) {
      path[0] = wethAddress;
    }

    amounts = _swap(msg.value, amountOutMin, path, to, deadline, referrer, false);
  }

  // FEE CHANGER
  function changeFeeChangerAddress(address _newFeeChangerAddress) external onlyFeeChanger {
    feeChangerAddress = _newFeeChangerAddress;
  }

  function changeReferrerShare(uint256 _newReferrerShare) external onlyFeeChanger {
    require(_newReferrerShare <= MAX_BPS, "IggySwap: Referrer share is greater than MAX_BPS");
    referrerShare = _newReferrerShare;
  }

  function changeFrontendShare(uint256 _newFrontendShare) external onlyFeeChanger {
    require(_newFrontendShare <= MAX_BPS, "IggySwap: Frontend share is greater than MAX_BPS");
    frontendShare = _newFrontendShare;
  }

  function changeSwapFee(uint256 _newSwapFee) external onlyFeeChanger {
    require(_newSwapFee <= MAX_BPS, "IggySwap: Swap fee is greater than MAX_BPS");
    swapFee = _newSwapFee;
  }

  // FRONTEND OWNER

  /// @notice Change frontend address
  function changeFrontendAddress(address _newFrontendAddress) external {
    require(msg.sender == frontendAddress, "IggySwap: Sender is not the frontend owner");
    frontendAddress = _newFrontendAddress;
  }

  // IGGY

  /// @notice Change Iggy address
  function changeIggyAddress(address _newIggyAddress) external {
    require(msg.sender == iggyAddress, "IggySwap: Sender is not Iggy");
    iggyAddress = _newIggyAddress;
  }

  // OWNER

  /// @notice Change router address
  function changeRouterAddress(address _newRouterAddress) external onlyOwner {
    routerAddress = _newRouterAddress;
  }

  /// @notice Recover any ERC-20 token mistakenly sent to this contract address
  function recoverERC20(address tokenAddress_, uint256 tokenAmount_, address recipient_) external onlyOwner {
    IERC20(tokenAddress_).safeTransfer(recipient_, tokenAmount_);
  }

  /// @notice Recover native coins from contract
  function recoverETH() external onlyOwner {
    (bool success, ) = payable(owner()).call{value: address(this).balance}("");
    require(success, "Failed to recover native coins from contract");
  }

  // INTERNAL - READ
  function _getFeeAmount(uint _amount) internal view returns (uint) {
    return (_amount * swapFee) / MAX_BPS;
  }

  // fetches and sorts the reserves for a pair
  function _getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
    (address token0,) = _sortTokens(tokenA, tokenB);
    address pair = IUniswapV2Factory(factory).getPair(tokenA, tokenB);
    (uint reserve0, uint reserve1,) = IUniswapV2Pair(pair).getReserves();
    (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
  }

  function _getTokensAmountOut(
    uint amountIn, 
    address[] memory path
  ) internal view returns(uint[] memory amounts) {
    if (path[0] == address(0)) {
      path[0] = wethAddress;
    }

    if (path[path.length - 1] == address(0)) {
      path[path.length - 1] = wethAddress;
    }

    return IUniswapV2Router02(routerAddress).getAmountsOut(amountIn, path);
  }

  function _sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
    require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
  }

  // INTERNAL - WRITE
  function _swap(
    uint amountIn,
    uint amountOutMin, // amount out deducted by slippage
    address[] memory path,
    address to,
    uint deadline,
    address referrer,
    bool convertToNative
  ) internal  returns (uint[] memory amounts) {
    IERC20(path[0]).approve(routerAddress, amountIn); // approve router to spend tokens

    // make the swap via router
    amounts = IUniswapV2Router02(routerAddress).swapExactTokensForTokens(
      amountIn,
      amountOutMin,
      path,
      address(this), // initially the receiver is this contract (tokens will be later transferred to the recipient and to fee receivers)
      deadline
    );

    uint256 _amountOut = amounts[amounts.length - 1]; // total amount out (including fee)
    uint256 _feeAmount = _getFeeAmount(_amountOut); // swap fee amount

    require((_amountOut - _feeAmount) >= amountOutMin, "IggySwap: Amount out is less than the minimum amount out");

    address tokenOut = path[path.length - 1]; // receiving token address

    // transfer tokens to the recipient (deduct the fee)
    if (convertToNative && tokenOut == wethAddress) {
      IWETH(tokenOut).withdraw(_amountOut - _feeAmount);
      (bool sentWeth, ) = payable(to).call{value: (_amountOut - _feeAmount)}("");
      require(sentWeth, "Failed to send native coins to the recipient");
    } else {
      IERC20(tokenOut).safeTransfer(to, (_amountOut - _feeAmount));
    }

    // if there's a referrer, send them a share of the fee
    if (referrer != address(0) && referrerShare > 0) {
      uint256 referrerShareAmount = (_feeAmount * referrerShare) / MAX_BPS;
      IERC20(tokenOut).safeTransfer(referrer, referrerShareAmount);
      _feeAmount -= referrerShareAmount; // deduct referrer's share from the fee
    }

    // calculate frontend and iggy fee share amounts
    uint256 frontendShareAmount = (_feeAmount * frontendShare) / MAX_BPS;
    uint256 iggyShareAmount = (_feeAmount * (MAX_BPS - frontendShare)) / MAX_BPS;

    // transfer tokens to fee receivers
    IERC20(tokenOut).safeTransfer(frontendAddress, frontendShareAmount); // send part of the fee to the frontend operator
    IERC20(tokenOut).safeTransfer(iggyAddress, iggyShareAmount); // send part of the fee to iggy
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0-rc.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0-rc.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0-rc.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
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
// OpenZeppelin Contracts (last updated v4.9.0-rc.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0-rc.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}