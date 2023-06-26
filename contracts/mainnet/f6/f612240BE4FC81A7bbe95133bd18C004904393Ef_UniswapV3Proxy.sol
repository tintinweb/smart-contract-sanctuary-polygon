// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWMATIC {
    function withdraw(uint wad) external;
}

contract UniswapV3Proxy {
    event Log(string message);

    ISwapRouter public immutable swapRouter;
    IWMATIC public wmatic;

    constructor(ISwapRouter _swapRouter, address _wmaticAddress) {
        swapRouter = _swapRouter;
        wmatic = IWMATIC(_wmaticAddress);
    }

    function swapExactInputSingleHop(
        address tokenIn,
        address tokenOut,
        address swapRouterAddress,
        uint24 poolFee,
        uint amountIn
    ) public returns (bool) {
        try IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn) {
            emit Log("Success transfer");
        } catch Error(string memory reason) {
            emit Log(reason);
            return false;
        }

        try IERC20(tokenIn).approve(address(swapRouter), amountIn) {
            emit Log("Success approve");
        } catch Error(string memory reason) {
            emit Log(reason);
            return false;
        }

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp + 300,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        try ISwapRouter(swapRouterAddress).exactInputSingle(params) {
            emit Log("Success!");
        } catch Error(string memory reason) {
            emit Log(reason);
            return false;
        }

        return true;
    }

    /**
    * @dev Proxy to Uniswap V3's exactInputSingle function, which runs the exchange and withdraws MATIC if requested
    *
    * @param _tokenIn The swap token
    * @param _tokenOut The swapped token
    * @param _fee The Uniswap pool fee level
    * @param _amountIn The amount to swap
    * @param _amountOutMinimum The minimum amount of swapped tokens
    @ @param _sqrtPriceLimitX96 See Uniswap's defn
    */
    function exactInputSingleWithWithdrawal(
        address _tokenIn,
        address _tokenOut,
        uint24 _fee,
        uint256 _amountIn,
        uint256 _amountOutMinimum,
        uint160 _sqrtPriceLimitX96
    ) external returns (uint amountOut) {
        // Pull this token into the proxy
        require(
            IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn),
            "Failed to pull in tokens"
        );

        require(
            IERC20(_tokenIn).approve(address(swapRouter), _amountIn),
            "Failed to approve Router"
        );

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: _tokenIn,
                tokenOut: _tokenOut,
                fee: _fee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: _amountIn,
                amountOutMinimum: _amountOutMinimum,
                sqrtPriceLimitX96: _sqrtPriceLimitX96
            });

        swapRouter.exactInputSingle(params);
    }

    /**
     * @dev Proxy to Uniswap V3's exactInput function, which runs the exchange and withdraws MATIC if requested
     *
     * @param _path The token swap path
     * @param _recipient The receiver of the swapped tokens
     * @param _amountIn The amount to swap
     * @param _amountOutMinimum The minimum amount of swapped tokens
     */
    function exactInputWithWithdrawal(
        bytes memory _path,
        address _recipient,
        uint256 _amountIn,
        uint256 _amountOutMinimum
    ) external {
        ISwapRouter.ExactInputParams memory params = ISwapRouter
            .ExactInputParams({
                path: _path,
                recipient: _recipient,
                deadline: block.timestamp + 5 minutes, // todo we can change this
                amountIn: _amountIn,
                amountOutMinimum: _amountOutMinimum
            });

        swapRouter.exactInput(params);

        // If you sent MATIC, withdraw the WMATIC that resulted from this transaction
        // withdraw(_amountIn);
        return;
    }

    /**
     * @dev withdraws WMATIC into MATIC for the user
     *
     * @param _amount the amount to withdraw
     */
    function withdraw(uint256 _amount) private {
        if (msg.value > 0) {
            wmatic.withdraw(_amount);
        }
        return;
    }
}