/**
 *Submitted for verification at polygonscan.com on 2022-12-07
*/

// SPDX-License-Identifier: MIT OR Apache-2.0

// File: @uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol


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

// File: contracts/interfaces/ISwapRouter.sol


pragma solidity >=0.7.5;
pragma abicoder v2;


/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// that may remain in the router after the swap.
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// that may remain in the router after the swap.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}
// File: contracts/interfaces/IIssuance.sol



pragma solidity ^0.8.0;

interface IIssuance {
    function getRequiredComponentUnitsForIssue(
        address _setToken,
        uint256 _quantity
    ) external view returns (address[] memory, uint256[] memory);

    function issue(
        address _setToken,
        uint256 _quantity,
        address _to
    ) external;

    function redeem(
        address _setToken,
        uint256 _quantity,
        address _to
    ) external;
}

// File: contracts/interfaces/IScheduler.sol



pragma solidity ^0.8.0;

interface IScheduler {

    function isOperator(address account) external view returns (bool);

    function isAdmin(address account) external view returns(bool);

    function getWorkerRetirementDate(address worker) external view returns(uint256);

}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// File: contracts/Staking.sol



pragma solidity ^0.8.0;






contract PenxStaking {
    IERC20 PENX;
    IERC20 PXLT;
    IERC20 USDC;
    ISwapRouter router;
    IScheduler scheduler;
    IIssuance issuanceModule;
    bool isPaused = true;
    address WETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;

    uint256 secondsInDay = 86400;

    uint256 public withdrawFee = 500;

    uint256 accumulatedSetFee;

    address[] workerArray;
    mapping(address => WorkerInfo) public workerAddressToInfo;
    struct WorkerInfo {
        uint256 stakedSet;
        uint256 accruedPENX;
        uint256 stakingStart;
    }

    uint256 coefficient = 11000;

    event Withdraw(
        address account,
        uint256 PENX,
        uint256 PXLT,
        uint256 swappedFor,
        bool hasFee
    );

    modifier isNotPaused() {
        require(!isPaused);
        _;
    }

    constructor(
        IERC20 _PENX,
        IERC20 _PXLT,
        IERC20 _USDC,
        IScheduler _scheduler,
        ISwapRouter _router,
        IIssuance _issuance
    ) {
        PENX = _PENX;
        PXLT = _PXLT;
        USDC = _USDC;
        scheduler = _scheduler;
        router = _router;
        issuanceModule = _issuance;
    }

    function addWorker(address worker, uint256 setAmount)
        internal
        returns (bool isNew)
    {
        WorkerInfo storage info = workerAddressToInfo[worker];
        info.stakedSet += setAmount;
        if (info.stakingStart == 0) {
            info.stakingStart = block.timestamp;
            isNew = true;
        }
    }

    function addSchedules(address[] memory workers, uint256[] memory amounts)
        public
    {
        require(scheduler.isOperator(msg.sender), "Caller is not an operator");
        require(workers.length == amounts.length, "Incorrect arrays length");
        uint256 totalAmount;
        for (uint256 i = 0; i < workers.length; ) {
            if (addWorker(workers[i], amounts[i])) {
                workerArray.push(workers[i]);
            }
            totalAmount += amounts[i];
            unchecked {
                i++;
            }
        }
        PXLT.transferFrom(msg.sender, address(this), totalAmount);
    }

    function increaseStakes() public {
        require(scheduler.isOperator(msg.sender), "Caller is not an operator");
        for (uint256 i = 0; i < workerArray.length; ) {
            WorkerInfo storage info = workerAddressToInfo[workerArray[i]];
            if (
                info.stakedSet > 0 &&
                scheduler.getWorkerRetirementDate(workerArray[i]) >=
                block.timestamp
            ) {
                uint256 totalSupply = PXLT.totalSupply();
                updateWorkerStake(info, totalSupply);
            }
            unchecked {
                i++;
            }
        }
    }

    function withdrawPENX(uint256 amount, address to) public {
        require(scheduler.isAdmin(msg.sender),"Restricted function");
        PENX.transfer(to, amount);
    }

    function updateWorkerStake(WorkerInfo storage info, uint256 totalSupply)
        internal
    {
        uint256 secondsPassed = block.timestamp - info.stakingStart;
        uint256 leftoverSeconds = secondsPassed % secondsInDay;
        uint256 daysPassedSinceDeposit = (secondsPassed - leftoverSeconds) /
            secondsInDay;
        uint256 PENXtoAdd = (((info.stakedSet * sqrt(daysPassedSinceDeposit)) /
            (totalSupply / 1e18)) * coefficient) / 10000;
        info.accruedPENX += PENXtoAdd;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function withdrawPension() public {
        WorkerInfo storage info = workerAddressToInfo[msg.sender];
        require(info.stakedSet > 0, "Nothing to collect");

        bool hasFee;
        if (scheduler.getWorkerRetirementDate(msg.sender) < block.timestamp) {
            hasFee = true;
        }

        if (hasFee) {
            uint256 setFee = (info.stakedSet / 10000) * withdrawFee;
            uint256 penxFee = (info.accruedPENX / 10000) * withdrawFee;
            info.stakedSet -= setFee;
            accumulatedSetFee += setFee;
            info.accruedPENX -= penxFee;
        }

        uint256 swappedFor = _redeemAndSendPXLT(info.stakedSet);
        PENX.transfer(msg.sender, info.accruedPENX);
        emit Withdraw(
            msg.sender,
            info.accruedPENX,
            info.stakedSet,
            swappedFor,
            hasFee
        );
        delete workerAddressToInfo[msg.sender];
    }

    function _redeemAndSendPXLT(uint256 setAmount) internal returns(uint256) {
        (address[] memory components, ) = issuanceModule
            .getRequiredComponentUnitsForIssue(address(PXLT), setAmount);
        issuanceModule.redeem(address(PXLT), setAmount, address(this));
        uint256 totalUSDC;
        for (uint256 i = 0; i < components.length; i++) {
            uint256 redeemedAmount = IERC20(components[i]).balanceOf(address(this));
            IERC20(components[i]).approve(address(router), redeemedAmount);
            uint256 amountOut;
            if(components[i] == WETH) {
                amountOut = _directSwap(redeemedAmount);
            } else {
                amountOut = _hopSwap(redeemedAmount, components[i]);
            }
            totalUSDC += amountOut;
        }
        USDC.transfer(msg.sender, totalUSDC);
        return totalUSDC;
    }

    function _directSwap(uint256 amountIn) internal returns(uint256 amountOut) {
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
                .ExactInputSingleParams({
                    tokenIn: WETH,
                    tokenOut: address(USDC),
                    fee: 500,
                    recipient: address(this),
                    amountIn: amountIn,
                    amountOutMinimum: 1,
                    sqrtPriceLimitX96: 0
                });
        amountOut = router.exactInputSingle(params);
    }

    function _hopSwap(uint256 amountIn, address component) internal returns(uint256 amountOut) {
        uint24 feeWETH = 500;
        uint24 feeDEFI = 10000;
        ISwapRouter.ExactInputParams memory params =
            ISwapRouter.ExactInputParams({
                path: abi.encodePacked(component, feeDEFI, WETH, feeWETH, address(USDC)),
                recipient: address(this),
                amountIn: amountIn,
                amountOutMinimum: 0
            });
        amountOut = router.exactInput(params);
    }

    function changeScheduler(address _scheduler) public {
        require(scheduler.isAdmin(msg.sender), "Restricted method");
        scheduler = IScheduler(_scheduler);
    }

    function withdrawAccumulatedFee() public {
        require(scheduler.isAdmin(msg.sender), "Restricted method");
        PXLT.transferFrom(address(this), msg.sender, accumulatedSetFee);
    }

    function changeStakingCoefficient(uint256 _coefficient) public {
        require(scheduler.isAdmin(msg.sender), "Restricted method");
        coefficient = _coefficient;
    }
}