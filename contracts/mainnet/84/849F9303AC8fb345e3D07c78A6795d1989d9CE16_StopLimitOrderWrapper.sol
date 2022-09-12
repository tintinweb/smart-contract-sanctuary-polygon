//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../interfaces/IStopLimitOrder.sol";
import "../interfaces/IBentoBoxV1.sol";
import "../interfaces/IUniswapV2Router02.sol";
import "../interfaces/IERC20.sol";

contract StopLimitOrderWrapper{
    IBentoBoxV1 public immutable bentoBox;
    address payable public immutable registry;
    address public immutable gasFeeForwarder;
    IStopLimitOrder public immutable stopLimitOrderContract;
    address public immutable WETH;
    IUniswapV2Router02 immutable uni;

    uint256 internal constant MAX_UINT = type(uint256).max;
    uint256 public constant DEADLINE = 2429913600;

    constructor(
        address payable registry_,
        address gasFeeForwarder_,
        address bentoBox_,
        address stopLimitOrderContract_,
        address WETH_,
        address uni_
    ) {
        require(registry_ != address(0), "Invalid registry");
        require(gasFeeForwarder_ != address(0), "Invalid gasForwarder");
        require(bentoBox_ != address(0), "Invalid BentoBox");
        require(stopLimitOrderContract_ != address(0), "Invalid stopLimitOrder");
        require(WETH_ != address(0), "Invalid WETH");
        require(uni_ != address(0), "Invalid uni-router");

        registry = registry_;
        gasFeeForwarder = gasFeeForwarder_;
        bentoBox = IBentoBoxV1(bentoBox_);

        stopLimitOrderContract = IStopLimitOrder(stopLimitOrderContract_);
        WETH = WETH_;
        uni = IUniswapV2Router02(uni_);
    }

    function fillOrder(
        uint256 feeAmount,
        OrderArgs memory order,
        address tokenIn,
        address tokenOut, 
        address receiver, 
        bytes calldata data
    ) external gasFeeForwarderVerified {
        stopLimitOrderContract.fillOrder(
            order,
            tokenIn,
            tokenOut,
            receiver,
            data
        );

        /// @dev stopLimitOrder charges fee by tokenOut
        uint256 _feeReceivedAsShare = bentoBox.balanceOf(tokenOut, address(this));
        uint256 _feeReceivedAmount = bentoBox.toAmount(tokenOut, _feeReceivedAsShare, false);

        if (tokenOut == WETH) {
            require(_feeReceivedAmount >= feeAmount, "Insufficient Fee");

            bentoBox.withdraw(
                address(0), // USE_ETHEREUM
                address(this),
                registry,   // transfer to registry
                feeAmount,  // amount
                0 // share
            );

            /// @dev transfer residue amount to maker
            _feeReceivedAsShare = bentoBox.balanceOf(WETH, address(this));
            if (_feeReceivedAsShare > 0) {
                bentoBox.transfer(
                    WETH,
                    address(this),
                    order.maker,
                    _feeReceivedAsShare
                );
            }
        } else {
            bentoBox.withdraw(
                tokenOut,
                address(this),
                address(this),
                0,
                _feeReceivedAsShare
            );

            /// @dev swap tokenOut to ETH, and transfer to registry
            IERC20 _tokenOut = IERC20(tokenOut);
            if (_tokenOut.allowance(address(this), address(uni)) < _feeReceivedAmount) {
                _tokenOut.approve(address(uni), MAX_UINT);
            }
            address[] memory routePath = new address[](2);
            routePath[0] = tokenOut;
            routePath[1] = WETH;
            uni.swapTokensForExactETH(
                feeAmount, // amountOut
                _feeReceivedAmount, // amountInMax
                routePath, // path
                registry, // to
                DEADLINE // deadline
            );

            /// @dev deposit residue amount of tokenOut into bentoBox again, and transfer to maker
            uint256 leftTokenOut = _tokenOut.balanceOf(address(this));
            if (leftTokenOut > 0) {
                if (_tokenOut.allowance(address(this), address(bentoBox)) < leftTokenOut) {
                    _tokenOut.approve(address(bentoBox), MAX_UINT);
                }
                bentoBox.deposit(
                    tokenOut,
                    address(this),
                    order.maker,
                    leftTokenOut,
                    0
                );
            }
        }
    }

    modifier gasFeeForwarderVerified() {
        require(msg.sender == gasFeeForwarder, "StopLimitOrderWrapper: no gasFF");
        _;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IChainLinkPriceOracle.sol";

struct OrderArgs {
    address maker; 
    uint256 amountIn; 
    uint256 amountOut; 
    address recipient; 
    uint256 startTime;
    uint256 endTime;
    uint256 stopPrice;
    IChainLinkPriceOracle oracleAddress;
    bytes oracleData;
    uint256 amountToFill;
    uint8 v; 
    bytes32 r;
    bytes32 s;
}
interface IStopLimitOrder {
    function fillOrder(
            OrderArgs memory order,
            address tokenIn,
            address tokenOut, 
            address receiver, 
            bytes calldata data) 
    external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

interface IBentoBoxV1 {
    struct Rebase {
        uint128 elastic;
        uint128 base;
    }

    function balanceOf(address, address) external view returns (uint256);

    function toAmount(
        address token,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount);

    function toShare(
        address token,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);

    function totals(address) external view returns (Rebase memory totals_);

    function transfer(
        address token,
        address from,
        address to,
        uint256 share
    ) external;

    function deposit(
        address token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external payable returns (uint256 amountOut, uint256 shareOut);

    function withdraw(
        address token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IChainLinkPriceOracle {
    /// @notice Get the latest exchange rate.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function get(bytes calldata data) external returns (bool success, uint256 rate);

    /// @notice Check the last exchange rate without any state changes.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function peek(bytes calldata data) external view returns (bool success, uint256 rate);

    /// @notice Check the current spot exchange rate without any state changes. For oracles like TWAP this will be different from peek().
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return rate The rate of the requested asset / pair / pool.
    function peekSpot(bytes calldata data) external view returns (uint256 rate);

    /// @notice Returns a human readable (short) name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable symbol name about this oracle.
    function symbol(bytes calldata data) external view returns (string memory);

    /// @notice Returns a human readable name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable name about this oracle.
    function name(bytes calldata data) external view returns (string memory);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

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