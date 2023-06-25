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

interface IWMATIC {
    function withdraw(uint wad) external;
}

contract UniswapV3Proxy {
    ISwapRouter public immutable swapRouter;
    IWMATIC public wmatic;

    constructor(ISwapRouter _swapRouter, address _wmaticAddress) {
        swapRouter = _swapRouter;
        wmatic = IWMATIC(_wmaticAddress);
    }

    /**
    * @dev Proxy to Uniswap V3's exactInputSingle function, which runs the exchange and withdraws MATIC if requested
    *
    * @param _tokenIn The swap token
    * @param _tokenOut The swapped token
    * @param _fee The Uniswap pool fee level
    * @param _recipient The receiver of the swapped tokens
    * @param _amountIn The amount to swap
    * @param _amountOutMinimum The minimum amount of swapped tokens
    @ @param _sqrtPriceLimitX96 See Uniswap's defn
    */
    function exactInputSingleWithWithdrawal(
        address _tokenIn,
        address _tokenOut,
        uint24 _fee,
        address _recipient,
        uint256 _amountIn,
        uint256 _amountOutMinimum,
        uint160 _sqrtPriceLimitX96
    ) external {
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: _tokenIn,
                tokenOut: _tokenOut,
                fee: _fee,
                recipient: _recipient,
                deadline: block.timestamp + 20 minutes, // todo we can change this
                amountIn: _amountIn,
                amountOutMinimum: _amountOutMinimum,
                sqrtPriceLimitX96: _sqrtPriceLimitX96
            });

        swapRouter.exactInputSingle(params);

        // If you sent MATIC, withdraw the WMATIC that resulted from this transaction
        // withdraw(_amountIn);
        return;
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