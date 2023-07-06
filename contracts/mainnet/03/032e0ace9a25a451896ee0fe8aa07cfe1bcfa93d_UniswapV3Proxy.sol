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

interface IClaimable {
    /**
     * @dev Emitted when a token type `id` are claimed by `claimant`
     */
    event Claim(address claimant, uint256 collectibleID);

    /**
     * @dev Claims an NFT on behalf of a user
     *
     * @param claimant The claimant address
     * @param faucet The faucet we use to send collectible id `collectibleID` to `claimant`
     * @param collectibleID The collectible ID `claimant` has claimed
     *
     * Requirements:
     *
     * - `claimant` can not have already claimed `collectibleID`
     */
    function claim(
        address claimant,
        address faucet,
        uint256 collectibleID
    ) external;

    /**
     * @dev Determines whether or not `claimant` can claim a token type `id`
     *
     * @param claimant The claimant address
     * @param collectibleID The collectible ID `claimant` want to claim
     *
     * @return claimStatus Whether or not `claimant` is able to claim `id`
     */
    function availableToClaim(
        address claimant,
        uint256 collectibleID
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IClaimable.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWMATIC {
    function withdraw(uint wad) external;
}

contract UniswapV3Proxy {
    event TransferTokensIn(address sender, uint256 amount);
    event ApproveProxy(address protocol, uint256 amount);
    event Swap(
        address swapper,
        address fromToken,
        address toToken,
        uint256 amountIn,
        uint256 amountOut
    );
    event WithdrawBaseToken(address baseToken, uint256 amount);
    event ClaimUserJourneyNft(address claimant, uint256 tokenId);

    ISwapRouter public immutable swapRouter;
    IWMATIC public wmatic;

    constructor(ISwapRouter _swapRouter, address _wmaticAddress) {
        swapRouter = _swapRouter;
        wmatic = IWMATIC(_wmaticAddress);
    }

    // todo lend and claim nft
    // todo batch swap brz to usdc and send

    /**
     * @dev Proxy to Uniswap V3's exactInputSingle function, which runs the exchange and withdraws MATIC if requested
     *
     * @param _tokenIn The swap token
     * @param _tokenOut The swapped token
     * @param _fee The Uniswap pool fee level
     * @param _amountIn The amount to swap
     * @param _amountOutMinimum The minimum amount of swapped tokens
     * @param _sqrtPriceLimitX96 See Uniswap's defn
     *
     * @return success whether or not the transaction succeeded
     */
    function swapAndClaimNft(
        address _tokenIn,
        address _tokenOut,
        address _collectionAddress,
        address _faucetWalletAddress,
        address _revenueWalletAddress,
        uint24 _fee,
        uint256 _amountIn,
        uint256 _amountOutMinimum,
        uint256 _claimableTokenId,
        uint160 _sqrtPriceLimitX96,
        uint256 _tipAmount
    ) external returns (bool success) {
        // todo calculate uniswap metadata onchain

        // If the user requests greater than their max balance, use just their max balance
        uint256 amountIn = _amountIn;
        uint256 maxBalance = IERC20(_tokenIn).balanceOf(msg.sender);
        if (maxBalance > _amountIn) {
            amountIn = maxBalance;
        }

        // Transfer tokens into contract
        require(
            IERC20(_tokenIn).allowance(msg.sender, address(this)) >= amountIn,
            "Insufficient allowance to transfer tokens in"
        );
        require(
            IERC20(_tokenIn).transferFrom(msg.sender, address(this), amountIn),
            "Failed to transfer tokens into proxy"
        );
        emit TransferTokensIn(msg.sender, amountIn);

        // Handle tip
        if (_tipAmount > 0) {
            // Approve token contract to take tokens from contract
            require(
                IERC20(_tokenIn).approve(_tokenIn, _tipAmount),
                "Failed to approve tip transfer out"
            );

            // Transfer tip out
            require(
                IERC20(_tokenIn).transferFrom(
                    address(this),
                    _revenueWalletAddress,
                    _tipAmount
                ),
                "Failed to process revenue"
            );

            // Update amount to swap
            amountIn = amountIn - _tipAmount;
        }

        // Approve swap router to take tokens from contract
        require(
            IERC20(_tokenIn).approve(address(swapRouter), amountIn),
            "Failed to approve proxy on SwapRouter"
        );
        emit ApproveProxy(address(swapRouter), amountIn);

        // Execute swap
        uint256 amountOut = swap(
            _tokenIn,
            _tokenOut,
            _fee,
            amountIn,
            _amountOutMinimum,
            _sqrtPriceLimitX96
        );

        // If you sent MATIC, withdraw the WMATIC that resulted from this transaction
        // Note: event is emitted in called function
        withdraw(amountIn);

        // Approve ERC20 to transfer back to user
        IERC20(_tokenOut).approve(_tokenOut, amountOut);
        emit ApproveProxy(_tokenOut, amountOut);

        // Transfer received ERC20 back to user
        // Note: ERC20 transfers get emitted, I believe
        IERC20(_tokenOut).transfer(msg.sender, amountOut);

        // If you need to claim a user journey NFT, claim the user journey NFT
        IClaimable collection = IClaimable(_collectionAddress);
        if (collection.availableToClaim(msg.sender, _claimableTokenId)) {
            collection.claim(
                msg.sender,
                _faucetWalletAddress,
                _claimableTokenId
            );
            emit ClaimUserJourneyNft(msg.sender, _claimableTokenId);
        }

        return true;
    }

    /**
     * Swaps on Uniswap
     *
     * @param _tokenIn inbound token
     * @param _tokenOut outbound token
     * @param _fee fee tier
     * @param _amountOutMinimum minimum expected amount receied
     * @param _sqrtPriceLimitX96 price
     *
     * @return amountOut amount actually received
     */
    function swap(
        address _tokenIn,
        address _tokenOut,
        uint24 _fee,
        uint256 _amountIn,
        uint256 _amountOutMinimum,
        uint160 _sqrtPriceLimitX96
    ) private returns (uint256) {
        uint256 amountOut = swapRouter.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: _tokenIn,
                tokenOut: _tokenOut,
                fee: _fee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: _amountIn,
                amountOutMinimum: _amountOutMinimum,
                sqrtPriceLimitX96: _sqrtPriceLimitX96
            })
        );
        emit Swap(msg.sender, _tokenIn, _tokenOut, _amountIn, amountOut);
        return amountOut;
    }

    /**
     * @dev withdraws WMATIC into MATIC for the user
     *
     * @param _amount the amount to withdraw
     */
    function withdraw(uint256 _amount) private {
        if (msg.value > 0) {
            wmatic.withdraw(_amount);
            emit WithdrawBaseToken(msg.sender, _amount);
        }
        return;
    }
}