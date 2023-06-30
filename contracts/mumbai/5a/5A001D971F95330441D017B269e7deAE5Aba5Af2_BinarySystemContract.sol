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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

interface ISTX {
    function burn(uint256 amount) external;
}

contract BinarySystemContract is Ownable {
    event ActivateEvent(
        address sender,
        address parent,
        uint256 burnAmount,
        string record
    );

    event PurchaseEvent(
        address sender,
        address parent,
        uint256 star,
        uint256 burnAmount,
        string record
    );

    ISwapRouter public immutable swapRouter;

    // Declare public variables
    address public usdtToken;
    address public stxToken;
    address public adminA;
    address public adminB;
    address public adminC;
    address public adminD;
    address public adminE;
    address public pool;

    uint public registerContractPercent = 0;
    uint public repurchaseContractPercent = 0;

    uint24 private poolFee = 3000;

    // Constructor
    constructor(
        address _usdtToken,
        address _stxToken,
        address _adminA,
        address _adminB,
        address _adminC,
        address _adminD,
        address _adminE,
        address _pool,
        ISwapRouter _swapRouter
    ) {
        usdtToken = _usdtToken;
        stxToken = _stxToken;
        adminA = _adminA;
        adminB = _adminB;
        adminC = _adminC;
        adminD = _adminD;
        adminE = _adminE;
        pool = _pool;
        swapRouter = _swapRouter;
    }

    function activate(address parent, string memory record) external {
        require(
            IERC20(usdtToken).balanceOf(msg.sender) >= 110000000,
            "Amount is not enough!"
        );

        uint contractAmount = 5000000 +
            (45000000 * registerContractPercent) /
            100;
        uint adminAAmount = 5000000 +
            (45000000 * (100 - registerContractPercent)) /
            100;

        IERC20(usdtToken).transferFrom(msg.sender, parent, 50000000);
        IERC20(usdtToken).transferFrom(
            msg.sender,
            address(this),
            contractAmount
        );

        IERC20(usdtToken).transferFrom(msg.sender, adminA, adminAAmount);
        IERC20(usdtToken).transferFrom(msg.sender, adminB, 5000000);
        // BBAB
        uint256 amountIn = 5000000;
        TransferHelper.safeApprove(usdtToken, address(swapRouter), amountIn);
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: usdtToken,
                tokenOut: stxToken,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        uint outAmount = swapRouter.exactInputSingle(params);
        ISTX(stxToken).burn(outAmount);
        // Log
        emit ActivateEvent(msg.sender, parent, outAmount, record);
    }

    function repurchase(
        uint star,
        address parent,
        string memory record
    ) external {
        uint purchaseAmount = 0;

        if (star == 1) purchaseAmount = 110000000;
        else if (star == 2) purchaseAmount = 330000000;
        else if (star == 3) purchaseAmount = 550000000;
        else if (star == 4) purchaseAmount = 1100000000;
        else if (star == 5) purchaseAmount = 3300000000;
        else if (star == 6) purchaseAmount = 5500000000;

        require(purchaseAmount > 0, "Star is not validated!");
        require(
            IERC20(usdtToken).balanceOf(msg.sender) >= purchaseAmount,
            "Amount is not enough"
        );

        IERC20(usdtToken).transferFrom(msg.sender, parent, purchaseAmount / 11);
        IERC20(usdtToken).transferFrom(
            msg.sender,
            address(this),
            (purchaseAmount *
                5 +
                (purchaseAmount * 75 * repurchaseContractPercent) /
                100) / 110
        );

        if (repurchaseContractPercent != 100) {
            IERC20(usdtToken).transferFrom(
                msg.sender,
                adminA,
                ((purchaseAmount * 75 * (100 - repurchaseContractPercent)) /
                    100) / 110
            );
        }

        IERC20(usdtToken).transferFrom(
            msg.sender,
            adminC,
            (purchaseAmount * 15) / 110
        );
        IERC20(usdtToken).transferFrom(
            msg.sender,
            adminD,
            (purchaseAmount * 5) / 110
        );
        // BBAB
        uint256 amountIn = (purchaseAmount * 5) / 110;
        TransferHelper.safeApprove(usdtToken, address(swapRouter), amountIn);
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: usdtToken,
                tokenOut: stxToken,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        uint outAmount = swapRouter.exactInputSingle(params);
        ISTX(stxToken).burn(outAmount);
        // Log
        emit PurchaseEvent(msg.sender, parent, star, outAmount, record);
    }

    function runUnilevelBonus(uint256 count) external onlyOwner {
        require(count > 0, "Count should be bigger than zero");
        require(
            IERC20(usdtToken).balanceOf(address(this)) >= 10000000 * count,
            "Amount is not enough!"
        );

        IERC20(usdtToken).transfer(adminE, 5000000 * count);
        // BBAB
        uint256 amountIn = 5000000 * count;
        TransferHelper.safeApprove(usdtToken, address(swapRouter), amountIn);
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: usdtToken,
                tokenOut: stxToken,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        uint outAmount = swapRouter.exactInputSingle(params);
        ISTX(stxToken).burn(outAmount);
    }

    function withdrawTokenFromContract(
        address token,
        uint256 amount,
        address receiver
    ) external onlyOwner {
        require(
            IERC20(token).balanceOf(address(this)) >= amount,
            "token amount is not enough!"
        );
        IERC20(token).transfer(receiver, amount);
    }

    function setRegisterContractPercent(uint percent) external onlyOwner {
        require(percent <= 100, "should be less than 100!");
        registerContractPercent = percent;
    }

    function setRepurchaseContractPercent(uint percent) external onlyOwner {
        require(percent <= 100, "should be less than 100!");
        repurchaseContractPercent = percent;
    }

    function getSTXPrice() external view returns (uint256) {
        uint usdtAmountOfPool = IERC20(usdtToken).balanceOf(pool);
        uint stxAmountOfPool = IERC20(stxToken).balanceOf(pool);

        uint stxPrice = (usdtAmountOfPool * 100000 * 1000000000000) /
            stxAmountOfPool;
        return stxPrice;
    }
}