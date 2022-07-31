//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./uniswap/v3/ISwapRouter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Arbitrage is Ownable {
    struct Swap {
        address tokenIn;
        address tokenOut;
        uint24[] fees;
        address[] routers;
        uint256[] splitPercentage;
        address spender;
        address swapTarget;
        bytes swapCallData;
    }

    struct FlashCallbackData {
        address me;
        address flashLoanPool;
        uint256 loanAmount;
        Swap[] swaps;
    }

    function dodoFlashLoan(
        address _flashLoanPool,
        uint256 _loanAmount,
        Swap[] memory _swaps
    ) external onlyOwner {
        bytes memory data = abi.encode(
            FlashCallbackData({
                me: msg.sender,
                flashLoanPool: _flashLoanPool,
                loanAmount: _loanAmount,
                swaps: _swaps
            })
        );

        address loanToken = _swaps[0].tokenIn;

        IDODO(_flashLoanPool).flashLoan(
            IDODO(_flashLoanPool)._BASE_TOKEN_() == loanToken ? _loanAmount : 0,
            IDODO(_flashLoanPool)._BASE_TOKEN_() == loanToken ? 0 : _loanAmount,
            address(this),
            data
        );
    }

    function _flashLoanCallBack(
        address,
        uint256,
        uint256,
        bytes calldata data
    ) internal {
        FlashCallbackData memory decoded = abi.decode(
            data,
            (FlashCallbackData)
        );

        IERC20 loanToken = IERC20(decoded.swaps[0].tokenIn);

        require(
            loanToken.balanceOf(address(this)) >= decoded.loanAmount,
            "Failed to borrow loan token"
        );

        for (uint8 i = 0; i < decoded.swaps.length; i++) {
            uint256 balance = IERC20(decoded.swaps[i].tokenIn).balanceOf(
                address(this)
            );

            bool success = zrxFillQuote(
                decoded.swaps[i].tokenIn,
                decoded.swaps[i].spender,
                payable(decoded.swaps[i].swapTarget),
                decoded.swaps[i].swapCallData
            );

            if (success) {
                continue;
            }

            for (uint8 j = 0; j < decoded.swaps[i].routers.length; j++) {
                if (j != decoded.swaps[i].routers.length - 1) {
                    if (decoded.swaps[i].fees[j] == 0) {
                        uniswapV2(
                            decoded.swaps[i].routers[j],
                            decoded.swaps[i].tokenIn,
                            decoded.swaps[i].tokenOut,
                            (balance * decoded.swaps[i].splitPercentage[j]) /
                                100000000
                        );
                    } else {
                        uniswapV3(
                            decoded.swaps[i].routers[j],
                            decoded.swaps[i].tokenIn,
                            decoded.swaps[i].tokenOut,
                            (balance * decoded.swaps[i].splitPercentage[j]) /
                                100000000,
                            decoded.swaps[i].fees[j]
                        );
                    }
                } else {
                    if (decoded.swaps[i].fees[j] == 0) {
                        uniswapV2(
                            decoded.swaps[i].routers[j],
                            decoded.swaps[i].tokenIn,
                            decoded.swaps[i].tokenOut,
                            IERC20(decoded.swaps[i].tokenIn).balanceOf(
                                address(this)
                            )
                        );
                    } else {
                        uniswapV3(
                            decoded.swaps[i].routers[j],
                            decoded.swaps[i].tokenIn,
                            decoded.swaps[i].tokenOut,
                            IERC20(decoded.swaps[i].tokenIn).balanceOf(
                                address(this)
                            ),
                            decoded.swaps[i].fees[j]
                        );
                    }
                }
            }
        }

        require(
            loanToken.balanceOf(address(this)) >= decoded.loanAmount,
            "Not enough amount to return loan"
        );

        loanToken.transfer(decoded.flashLoanPool, decoded.loanAmount);

        for (uint8 i = 0; i < decoded.swaps.length; i++) {
            IERC20 token = IERC20(decoded.swaps[i].tokenIn);
            if (token.balanceOf(address(this)) > 0) {
                token.transfer(decoded.me, token.balanceOf(address(this)));
            }
        }
    }

    function zrxFillQuote(
        address tokenIn,
        address spender,
        address payable swapTarget,
        bytes memory swapCallData
    ) internal returns (bool) {
        IERC20(tokenIn).approve(
            spender,
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        );

        (bool success, ) = swapTarget.call{value: msg.value}(swapCallData);

        if (success) {
            payable(address(this)).transfer(address(this).balance);
            return true;
        }

        return false;
    }

    receive() external payable {}

    function uniswapV2(
        address _router,
        address _tokenIn,
        address _tokenOut,
        uint256 _amount
    ) private {
        IERC20(_tokenIn).approve(_router, _amount);
        address[] memory path;
        path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
        uint256 deadline = block.timestamp;
        IUniswapV2Router(_router).swapExactTokensForTokens(
            _amount,
            1,
            path,
            address(this),
            deadline
        );
    }

    function uniswapV3(
        address _router,
        address _token1,
        address _token2,
        uint256 _amount,
        uint24 _fee
    ) internal returns (uint256 amountOut) {
        ISwapRouter swapRouter = ISwapRouter(_router);
        IERC20(_token1).approve(address(swapRouter), _amount);

        amountOut = swapRouter.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: _token1,
                tokenOut: _token2,
                fee: _fee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: _amount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
        );
    }

    function getBalance(address _tokenContractAddress)
        external
        view
        returns (uint256)
    {
        uint256 balance = IERC20(_tokenContractAddress).balanceOf(
            address(this)
        );
        return balance;
    }

    function recoverNative() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function recoverTokens(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function DVMFlashLoanCall(
        address sender,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata data
    ) external {
        _flashLoanCallBack(sender, baseAmount, quoteAmount, data);
    }

    function DPPFlashLoanCall(
        address sender,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata data
    ) external {
        _flashLoanCallBack(sender, baseAmount, quoteAmount, data);
    }

    function DSPFlashLoanCall(
        address sender,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata data
    ) external {
        _flashLoanCallBack(sender, baseAmount, quoteAmount, data);
    }
}

interface IDODO {
    function flashLoan(
        uint256 baseAmount,
        uint256 quoteAmount,
        address assetTo,
        bytes memory data
    ) external;

    function _BASE_TOKEN_() external view returns (address);
}

interface IUniswapV2Router {
    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import './IUniswapV3SwapCallback.sol';

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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