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

// SPDX-License-Identifier: None
pragma solidity ^0.8.17;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IRouterV2} from "./interfaces/IRouterV2.sol";
import {IOps} from "./interfaces/IOps.sol";
import {IPineCore} from "./interfaces/IPineCore.sol";

contract Handler {
    address public ROUTER_ADDRESS;
    IOps immutable gelatoOps;
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor(address _ops, address router_address) {
        gelatoOps = IOps(_ops);
        ROUTER_ADDRESS = router_address;
    }

    receive() external payable {
        require(
            msg.sender == ROUTER_ADDRESS,
            "can receive eth only from router"
        );
    }

    function getAmountsOutETH(
        uint256 amountFeeToken,
        bytes calldata _data
    ) external view returns (uint256) {
        // Decode data
        (
        uint96 deadline,
        ,
        address[] memory pathNativeSwap,
        ,
        uint32[] memory feeNativeSwap,

        ) = abi.decode(
            _data,
            (uint96, uint256, address[], address[], uint32[], uint32[])
        );

        // Check order validity
        if (block.timestamp > deadline) revert("deadline passed");

        // Check if input FeeToken amount is sufficient to cover fees
        return
        IRouterV2(ROUTER_ADDRESS).getAmountsOut(
            amountFeeToken,
            pathNativeSwap,
            feeNativeSwap
        )[pathNativeSwap.length - 1];
    }

    function getAmountsOutTokenB(
        uint256 amountTokenA,
        bytes calldata _data
    ) external view returns (uint256) {
        // Decode data
        (
        uint96 deadline,
        ,
        ,
        address[] memory pathTokenSwap,
        ,
        uint32[] memory feeTokenSwap
        ) = abi.decode(
            _data,
            (uint96, uint256, address[], address[], uint32[], uint32[])
        );

        // Check order validity
        if (block.timestamp > deadline) revert("deadline passed");

        // Check if sufficient tokenB will be returned
        return
        IRouterV2(ROUTER_ADDRESS).getAmountsOut(
            amountTokenA,
            pathTokenSwap,
            feeTokenSwap
        )[1];
    }

    function _transfer(uint256 _fee, address _feeToken) internal {
        if (_feeToken == ETH) {
            (bool success, ) = address(gelatoOps).call{value: _fee}("");
            require(success, "_transfer: ETH transfer failed");
        } else {
            IERC20(_feeToken).transfer(address(gelatoOps), _fee);
        }
    }

    function _getFeeDetails()
    internal
    view
    returns (uint256 fee, address feeToken)
    {
        (fee, feeToken) = gelatoOps.getFeeDetails();
    }

    function getFeeTokenAmountRequired(
        bytes calldata _data
    ) external returns (uint256) {
        (
        ,
        ,
        address[] memory pathNativeSwap,
        ,
        uint32[] memory feeNativeSwap,

        ) = abi.decode(
            _data,
            (uint96, uint256, address[], address[], uint32[], uint32[])
        );

        (uint256 nativeFee, ) = _getFeeDetails();

        uint256[] memory feeTokenAmountFromNativeFee = IRouterV2(ROUTER_ADDRESS)
        .getAmountsIn(nativeFee, pathNativeSwap, feeNativeSwap);
        return feeTokenAmountFromNativeFee[0];
    }

    // Checker
    function canExecuteLimitOrder(
        uint256 amountFeeToken,
        uint256 amountTokenA,
        bytes calldata _data
    ) external view returns (bool) {
        // Decode data
        (
        uint96 deadline,
        uint256 minReturn,
        address[] memory pathNativeSwap,
        address[] memory pathTokenSwap,
        uint32[] memory feeNativeSwap,
        uint32[] memory feeTokenSwap
        ) = abi.decode(
            _data,
            (uint96, uint256, address[], address[], uint32[], uint32[])
        );

        // Check order validity
        if (block.timestamp > deadline) revert("deadline passed");

        // Check if sufficient tokenB will be returned
        require(
            (
            IRouterV2(ROUTER_ADDRESS).getAmountsOut(
                amountTokenA,
                pathTokenSwap,
                feeTokenSwap
            )
            )[pathTokenSwap.length - 1] >= minReturn,
            "insufficient token B returned"
        );

        // Check if input FeeToken amount is sufficient to cover fees
        (uint256 FEES, ) = _getFeeDetails();
        require(
            (
            IRouterV2(ROUTER_ADDRESS).getAmountsOut(
                amountFeeToken,
                pathNativeSwap,
                feeNativeSwap
            )
            )[pathNativeSwap.length - 1] >= FEES,
            "insufficient ETH returned"
        );

        return true;
    }

    // executor
    function executeLimitOrder(
        uint256 amountFeeToken,
        uint256 amountTokenA,
        address _owner,
        bytes memory _data
    ) external returns (uint256) {
        uint256 minReturn;
        address[] memory pathNativeSwap;
        address[] memory pathTokenSwap;
        uint32[] memory feeNativeSwap;
        uint32[] memory feeTokenSwap;

        // Decode data
        (
            uint96 deadline,
            uint256 _minReturn,
            address[] memory _pathNativeSwap,
            address[] memory _pathTokenSwap,
            uint32[] memory _feeNativeSwap,
            uint32[] memory _feeTokenSwap
        ) = abi.decode(
                _data,
                (uint96, uint256, address[], address[], uint32[], uint32[])
        );

        minReturn = _minReturn;
        pathNativeSwap = _pathNativeSwap;
        pathTokenSwap = _pathTokenSwap;
        feeNativeSwap = _feeNativeSwap;
        feeTokenSwap = _feeTokenSwap;

        // todo check for native
        // approve tokenA to router
        IERC20(pathTokenSwap[0]).approve(ROUTER_ADDRESS, amountTokenA);
        // approve feeToken to router
        IERC20(pathNativeSwap[0]).approve(ROUTER_ADDRESS, amountFeeToken);

        // calculate feeToken amount from native fee
        uint256[] memory feeTokenAmountFromNativeFee;

        {
            // get tx fee
            (uint256 FEES, address feeToken) = _getFeeDetails();
            // todo add this check back
//            require(FEES > 0, "fee is 0");
            FEES = 300000000000000000; // 0.3

            feeTokenAmountFromNativeFee = IRouterV2(ROUTER_ADDRESS).getAmountsIn(
                FEES,
                pathNativeSwap,
                feeNativeSwap
            );

            require(
                amountFeeToken >= feeTokenAmountFromNativeFee[0],
                "insufficient feeToken amount"
            );

            require(
                IERC20(pathNativeSwap[0]).balanceOf(address(this)) >=
                    amountFeeToken,
                "insufficient balance of feeToken in handler"
            );

            // call swap tokenA to native token
            IRouterV2(ROUTER_ADDRESS).swapTokensForExactNative(
                FEES,
                feeTokenAmountFromNativeFee[0],
                pathNativeSwap,
                feeNativeSwap,
                address(this),
                deadline
            );

            (bool success, ) = gelatoOps.gelato().call{value: FEES}("");
            require(success, "_transfer: ETH transfer failed");
        }

        IERC20(pathNativeSwap[0]).transfer(
            _owner,
            amountFeeToken - feeTokenAmountFromNativeFee[0]
        );

        uint256 balanceBefore = IERC20(pathTokenSwap[pathTokenSwap.length - 1]).balanceOf(_owner);

        // call swap tokenA to tokenB
        //uint256[] memory amounts =
        IRouterV2(ROUTER_ADDRESS)
            .swapExactTokensForTokens(
                amountTokenA,
                minReturn,
                pathTokenSwap,
                feeTokenSwap,
                _owner,
                deadline
            );

//        require(
//            amounts[pathTokenSwap.length - 1] >= minReturn,
//            "token B returned is lower than minReturn"
//        );
        uint256 bought = IERC20(pathTokenSwap[pathTokenSwap.length - 1]).balanceOf(_owner) - (balanceBefore);

        require(
            bought >= minReturn,
            "RouterV2: INSUFFICIENT_OUTPUT_AMOUNT"
        );

        // reset approvals
        IERC20(pathTokenSwap[0]).approve(ROUTER_ADDRESS, 0);
        IERC20(pathNativeSwap[0]).approve(ROUTER_ADDRESS, 0);

        return bought;
    }

    // Checker for stop loss
    function canExecuteStopLoss(
        uint256 amountFeeToken,
        uint256 amountTokenA,
        bytes calldata _data
    ) external view returns (bool) {
        // Decode data
        (
        uint96 deadline,
        uint256 minReturn,
        uint256 lossTargetTknB,
        address[] memory pathNativeSwap,
        address[] memory pathTokenSwap,
        uint32[] memory feeNativeSwap,
        uint32[] memory feeTokenSwap
        ) = abi.decode(
            _data,
            (
            uint96,
            uint256,
            uint256,
            address[],
            address[],
            uint32[],
            uint32[]
            )
        );

        // Check order validity
        if (block.timestamp > deadline) revert("deadline passed");

        // Check if sufficient tokenB will be returned
        uint256[] memory tokenBOut = IRouterV2(ROUTER_ADDRESS).getAmountsOut(
            amountTokenA,
            pathTokenSwap,
            feeTokenSwap
        );

        require(
            tokenBOut[pathTokenSwap.length - 1] <= lossTargetTknB,
            "token B not below loss target"
        );

        require(
            tokenBOut[pathTokenSwap.length - 1] >= minReturn,
            "token B below min return"
        );

        // Check if input FeeToken amount is sufficient to cover fees
        (uint256 FEES, ) = _getFeeDetails();
        require(
            (
            IRouterV2(ROUTER_ADDRESS).getAmountsOut(
                amountFeeToken,
                pathNativeSwap,
                feeNativeSwap
            )
            )[pathNativeSwap.length - 1] >= FEES,
            "insufficient ETH returned"
        );

        return true;
    }

    // todo maybe reentrancy guard
    // stop loss executor
    function executeStopLoss(
        uint256 amountFeeToken,
        uint256 amountTokenA,
        address _owner,
        bytes memory _data
    ) external returns (uint256) {
        // Decode data
        (
        uint96 deadline,
        uint256 minReturn,
        uint256 lossTargetTknB,
        address[] memory pathNativeSwap,
        address[] memory pathTokenSwap,
        uint32[] memory feeNativeSwap,
        uint32[] memory feeTokenSwap
        ) = abi.decode(
            _data,
            (
            uint96,
            uint256,
            uint256,
            address[],
            address[],
            uint32[],
            uint32[]
            )
        );

        // Check if lower than stoploss tokenB will be returned
        require(
            (
            IRouterV2(ROUTER_ADDRESS).getAmountsOut(
                amountTokenA,
                pathTokenSwap,
                feeTokenSwap
            )
            )[pathTokenSwap.length - 1] <= lossTargetTknB,
            "stop loss for tokenB not reached"
        );

        // approve tokenA to router
        IERC20(pathTokenSwap[0]).approve(ROUTER_ADDRESS, amountTokenA);
        // approve feeToken to router
        IERC20(pathNativeSwap[0]).approve(ROUTER_ADDRESS, amountFeeToken);

        // calculate feeToken amount from native fee
        uint256[] memory feeTokenAmountFromNativeFee;

        {
            (uint256 FEES, address feeToken) = _getFeeDetails();
            require(FEES > 0, "fee is 0");

            feeTokenAmountFromNativeFee = IRouterV2(ROUTER_ADDRESS).getAmountsIn(
                FEES,
                pathNativeSwap,
                feeNativeSwap
            );

            require(
                amountFeeToken >= feeTokenAmountFromNativeFee[0],
                "insufficient feeToken amount"
            );

            require(
                IERC20(pathNativeSwap[0]).balanceOf(address(this)) >=
                amountFeeToken,
                "insufficient balance of feeToken in handler"
            );

            // call swap tokenA to native token
            IRouterV2(ROUTER_ADDRESS).swapTokensForExactNative(
                FEES,
                feeTokenAmountFromNativeFee[0],
                pathNativeSwap,
                feeNativeSwap,
                address(this),
                deadline
            );

            (bool success, ) = gelatoOps.gelato().call{value: FEES}("");
            require(success, "_transfer: ETH transfer failed");
        }

        IERC20(pathNativeSwap[0]).transfer(
            _owner,
            amountFeeToken - feeTokenAmountFromNativeFee[0]
        );

        uint256 balanceBefore = IERC20(pathTokenSwap[pathTokenSwap.length - 1]).balanceOf(_owner);

        // call swap tokenA to tokenB
//        uint256[] memory amounts =
        IRouterV2(ROUTER_ADDRESS)
        .swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountTokenA,
            minReturn,
            pathTokenSwap,
            feeTokenSwap,
            _owner,
            deadline
        );

        uint256 bought = IERC20(pathTokenSwap[pathTokenSwap.length - 1]).balanceOf(_owner) - (balanceBefore);

        require(
            bought >= minReturn,
            "RouterV2: INSUFFICIENT_OUTPUT_AMOUNT"
        );

        // reset approvals
        IERC20(pathTokenSwap[0]).approve(ROUTER_ADDRESS, 0);
        IERC20(pathNativeSwap[0]).approve(ROUTER_ADDRESS, 0);

        return bought;
    }
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.17;

enum Module {
    RESOLVER,
    TIME,
    PROXY,
    SINGLE_EXEC
}

struct ModuleData {
    Module[] modules;
    bytes[] args;
}

interface IOps {
    function createTask(
        address execAddress,
        bytes calldata execDataOrSelector,
        ModuleData calldata moduleData,
        address feeToken
    ) external returns (bytes32 taskId);

    function cancelTask(bytes32 taskId) external;

    function getFeeDetails() external view returns (uint256, address);

    function gelato() external view returns (address payable);

    function taskTreasury() external view returns (ITaskTreasuryUpgradable);
}

interface ITaskTreasuryUpgradable {
    function depositFunds(
        address receiver,
        address token,
        uint256 amount
    ) external payable;

    function withdrawFunds(
        address payable receiver,
        address token,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.17;

interface IPineCore {
    function depositTokens(
        uint256 _amountWelle,
        uint256 _amountTokenA,
        address _module,
        address _tokenA,
        address payable _owner,
        address _witness,
        bytes calldata _data
    ) external;

    function withdrawTokens(
        address _module,
        address _tokenA,
        address payable _owner,
        address _witness,
        bytes calldata _data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRouter {
    function factory() external view returns (address);

    function WNative() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint32 fee,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
    external
    returns (
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    function addLiquidityNative(
        address token,
        uint32 fee,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountNativeMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountNative, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint32 fee,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityNative(
        address token,
        uint32 fee,
        uint liquidity,
        uint amountTokenMin,
        uint amountNativeMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountNative);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint32[] calldata feePath,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        uint32[] calldata feePath,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactNativeForTokens(uint amountOutMin, address[] calldata path, uint32[] calldata feePath, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function swapTokensForExactNative(uint amountOut, uint amountInMax, address[] calldata path, uint32[] calldata feePath, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function quoteByTokens(
        uint256 amountA,
        address tokenA,
        address tokenB,
        uint32 fee
    ) external view returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint32 fee
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint32 fee
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] memory path, uint32[] calldata feePath)
    external
    view
    returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] memory path, uint32[] calldata feePath)
    external
    view
    returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IRouter.sol';

interface IRouterV2 is IRouter {
    // Identical to removeLiquidityNative, but succeeds for tokens that take a fee on transfer.
    function removeLiquidityNativeSupportingFeeOnTransferTokens(
        address token,
        uint32 fee,
        uint liquidity,
        uint amountTokenMin,
        uint amountNativeMin,
        address to,
        uint deadline
    ) external returns (uint amountNative);
    // Identical to swapExactTokensForTokens, but succeeds for tokens that take a fee on transfer.
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        uint32[] calldata feePath,
        address to,
        uint deadline
    ) external;

    // Identical to swapExactNativeForTokens, but succeeds for tokens that take a fee on transfer.
    function swapExactNativeForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        uint32[] calldata feePath,
        address to,
        uint deadline
    ) external payable;

    // Identical to swapExactTokensForNative, but succeeds for tokens that take a fee on transfer.
    function swapExactTokensForNativeSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        uint32[] calldata feePath,
        address to,
        uint deadline
    ) external;
}