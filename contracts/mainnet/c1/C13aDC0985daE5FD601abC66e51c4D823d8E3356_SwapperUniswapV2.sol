// SPDX-License-Identifier: MIT
// Copyright (C) 2023 Soccerverse Ltd

pragma solidity ^0.8.19;

import "./SwapProvider.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";

/**
 * @dev This implements the SwapProvider based on a Uniswap v2 DEX.  The swap
 * data encodes the fixed routing path.
 */
contract SwapperUniswapV2 is SwapProvider
{

  /**
   * @dev The address of the Uniswap router we use.  We use Router01 here
   * since we only need the interface, and the calls we use are included
   * in that already.  The implementation will be set upon deployment, and
   * can point to the latest router.
   */
  IUniswapV2Router01 public immutable router;

  constructor (IERC20 wc, IUniswapV2Router01 r)
    SwapProvider (wc)
  {
    router = r;
  }

  /**
   * @dev Encodes a given swap path into a "data" argument that can be passed
   * to the other functions.  Note that the path contains only the intermediate
   * tokens, not the input or output (and may be empty if a direct pair
   * exists).  This is in contrast to the "path" argument for Uniswap.
   */
  function encodePath (address[] calldata path)
      public pure returns (bytes memory)
  {
    return abi.encode (path);
  }

  /**
   * @dev Helper method that takes an encoded path with intermediate pairs
   * as well as input and output tokens and fills in the full path argument
   * as used by Uniswap.
   */
  function getFullPath (IERC20 inputToken, IERC20 outputToken,
                        bytes calldata data)
      private pure returns (address[] memory res)
  {
    address[] memory intermediate = abi.decode (data, (address[]));
    res = new address[] (intermediate.length + 2);
    res[0] = address (inputToken);
    for (uint i = 0; i < intermediate.length; ++i)
      res[i + 1] = intermediate[i];
    res[intermediate.length + 1] = address (outputToken);
  }

  function quoteExactOutput (IERC20 inputToken, uint outputAmount,
                             bytes calldata data)
      public view override returns (uint)
  {
    address[] memory path = getFullPath (inputToken, wchi, data);
    uint[] memory amounts = router.getAmountsIn (outputAmount, path);
    return amounts[0];
  }

  function quoteExactInput (uint inputAmount, IERC20 outputToken,
                            bytes calldata data)
      public view override returns (uint)
  {
    address[] memory path = getFullPath (wchi, outputToken, data);
    uint[] memory amounts = router.getAmountsOut (inputAmount, path);
    return amounts[amounts.length - 1];
  }

  function swapExactOutput (IERC20 inputToken, uint outputAmount,
                            bytes calldata data) public override
  {
    /* Note that the AutoConvert contract itself enforces a maximum slippage,
       so we can call into Uniswap without any limit.  */
    address[] memory path = getFullPath (inputToken, wchi, data);
    router.swapTokensForExactTokens (outputAmount, type (uint256).max, path,
                                     address (this), block.timestamp);
  }

  function swapExactInput (uint inputAmount, IERC20 outputToken,
                           bytes calldata data) public override
  {
    /* Note that the AutoConvert contract itself enforces a maximum slippage,
       so we can call into Uniswap without any limit.  */
    address[] memory path = getFullPath (wchi, outputToken, data);
    router.swapExactTokensForTokens (inputAmount, 0, path,
                                     address (this), block.timestamp);
  }

}

// SPDX-License-Identifier: MIT
// Copyright (C) 2023 Soccerverse Ltd

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev This is the interface of a provider for swapping between tokens,
 * as used by Democrit's auto-convert feature.  It can be implemented based
 * on an on-chain DEX such as Uniswap v2 or v3.
 *
 * All methods accept an implementation-specific "data" argument, which
 * can contain other data required, such as swap paths.
 *
 * Token swaps are done from / to the contract's balance.  Democrit will
 * directly move tokens from the user's wallet to this contract, and the
 * contract has a method to withdraw tokens from its own balance onwards
 * after the swap, which Democrit will use.
 */
abstract contract SwapProvider
{

  /** @dev The WCHI token used.  */
  IERC20 public immutable wchi;

  constructor (IERC20 wc)
  {
    wchi = wc;
  }

  /**
   * @dev Transfers tokens owned by this contract.  This is a method
   * that Democrit will use to distribute the swap output.  It can be
   * called by anyone, as this contract is not expected to hold tokens
   * "long term".  Any balances it receives will be distributed by
   * Democrit right away in the same transaction.
   */
  function transferToken (IERC20 token, uint amount, address receiver) public
  {
    require (token.transfer (receiver, amount), "token transfer failed");
  }

  /**
   * @dev Returns the expected amount of input token required to get
   * the provided output amount in WCHI.
   */
  function quoteExactOutput (IERC20 inputToken, uint outputAmount,
                             bytes calldata data)
      public view virtual returns (uint);

  /**
   * @dev Returns the expected amount of output token if the provided
   * input amount of WCHI is swapped.
   */
  function quoteExactInput (uint inputAmount, IERC20 outputToken,
                            bytes calldata data)
      public view virtual returns (uint);

  /**
   * @dev Performs a swap of input tokens to exact output WCHI tokens.
   */
  function swapExactOutput (IERC20 inputToken, uint outputAmount,
                            bytes calldata data) public virtual;

  /**
   * @dev Performs a swap of an exact input of WCHI to the desired output.
   */
  function swapExactInput (uint inputAmount, IERC20 outputToken,
                           bytes calldata data) public virtual;

}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
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