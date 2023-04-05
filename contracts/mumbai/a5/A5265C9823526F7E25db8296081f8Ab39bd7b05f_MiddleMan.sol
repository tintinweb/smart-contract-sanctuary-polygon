// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    
}

interface IUniswapV2Router01 {
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
}

contract MiddleMan is Ownable {

    ISwapRouter public immutable uniswapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IUniswapV2Router01 public immutable sushiswapRouter = IUniswapV2Router01(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
    IERC20 public immutable feth = IERC20(0xC97727ba966F6C52580121862dF2771A1Ca0F28a);
    IERC20 public immutable stbl = IERC20(0x9622F58d9745bAfaeABB7712a69DcdBdcF72e188);

    address public profitsRecipient;

    bool public startingBalancesSet = false; 
    uint256 public fethStartingBalance;
    uint256 public stblStartingBalance;

    function setProfitsRecipient(address _to) external onlyOwner() {
        require(_to != address(0));
        profitsRecipient = _to;
    }

    /*
    *   Sets the token starting balances so we can keep track of the profits
    */
    function setStartingBalances() external onlyOwner() {
        require(!startingBalancesSet, "Starting balances are already set");
        fethStartingBalance = feth.balanceOf(address(this));
        stblStartingBalance = stbl.balanceOf(address(this));
        startingBalancesSet = true;
    }

    /*
    *   Withdraws the profits to profitsRecipient
    */
    function withdrawProfits() external onlyOwner() {
        uint256 fethBalance = feth.balanceOf(address(this));
        uint256 stblBalance = stbl.balanceOf(address(this));

        require(fethBalance > fethStartingBalance, "No FETH profits yet");
        require(stblBalance > stblStartingBalance, "No STBL profits yet");

        bool fethSuccess = feth.transfer
        (
            profitsRecipient, 
            fethBalance - fethStartingBalance
        );
        require(fethSuccess, "FETH token transfer failed");

        bool stblSuccess = stbl.transfer
        (
            profitsRecipient, 
            stblBalance - stblStartingBalance
        );
        require(stblSuccess, "STBL token transfer failed");
    }

    function arbitrage() external onlyOwner() {
        // Will call both swap function
        // Order to be determined

    }

    function swapOnUni(uint256 side) external {
        // Setting at 0 for simplicity
        uint256 amtOutMin = 0;
        uint160 priceLimit = 0;

        address tknIn;
        address tknOut;

        if (side == 0) {
            tknIn = address(feth);
            tknOut = address(stbl);
            feth.approve(address(uniswapRouter), 1000000000000000);
        } else if (side == 1) {
            tknIn = address(stbl);
            tknOut = address(feth);
            stbl.approve(address(uniswapRouter), 1000000000000000);
        } else {
            revert();
        }

        // Create the params that will be used to execute the swap
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: tknIn,
                tokenOut: tknOut,
                fee: 3000,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: 1000000000000000,
                amountOutMinimum: amtOutMin,
                sqrtPriceLimitX96: priceLimit
            });

        // The call to `exactInputSingle` executes the swap.
        uint256 amountOut = uniswapRouter.exactInputSingle(params);

    }

    function swapOnSushi(uint256 side) private {
        // 0 means we sell our FETH, so path is FETH -> STBL
        // 1 means we sell our STBL, so path is STBL -> FETH
        address[] memory path = new address[](2);
        uint256 amountIn;
        uint256 amountOutMin;

        if (side == 0) {
            path[0] = address(feth);
            path[1] = address(stbl);
            feth.approve(address(sushiswapRouter), 1000000000000000);
            amountIn = 1000000000000000;
            amountOutMin = 1;

        } else if (side == 1) {
            path[0] = address(stbl);
            path[1] = address(feth);
            stbl.approve(address(sushiswapRouter), 1000000000000000);
            amountIn = 1000000000000000;
            amountOutMin = 1;

        } else {
            revert();
        }

        // Unix timestamp after which the tx will revert
        uint256 deadline = block.timestamp;

        // Sell
        sushiswapRouter.swapExactTokensForTokens
        (
            amountIn, 
            amountOutMin, 
            path, 
            address(this),
            deadline
        );
        

    }
}