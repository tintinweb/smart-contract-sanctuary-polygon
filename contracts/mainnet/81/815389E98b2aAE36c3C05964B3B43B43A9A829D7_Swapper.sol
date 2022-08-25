//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol';
import '@uniswap/v3-periphery/contracts/interfaces/IPeripheryImmutableState.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../interfaces/ISwapper.sol';
import '../libraries/KedrConstants.sol';
import '../libraries/KedrLib.sol';

contract Swapper is ISwapper {
    mapping(address => uint8) public routerTypes; // router to ROUTER_TYPE
    address[] internal routers; // list of supported routers
    address[] internal routeTokens; // list of tokens to build composite routes if there is no direct pair
    address public defaultRouter; // default router to be used when don't want to spend gas to find best router
    address public uniswapV3quoter; // can be empty if no V3 routers are used
    uint24 internal FEE_500 = 500;
    uint24 internal FEE_3000 = 3000;
    uint24 internal FEE_10000 = 10000;

    constructor(
        address[] memory _routers,
        uint8[] memory _routerTypes,
        address _defaultRouter,
        address _uniswapV3quoter
    ) {
        require(_routers.length == _routerTypes.length, 'INVALID_ROUTERS_DATA');
        routers = _routers;
        for (uint256 i; i < _routers.length; ++i) {
            uint8 _type = _routerTypes[i];
            require(_type > 0 && _type <= 3, 'UNSUPPORTED_ROUTER_TYPE');
            routerTypes[_routers[i]] = _type;
        }
        require(routerTypes[_defaultRouter] > 0, 'INVALID DEFAULT_ROUTER');
        defaultRouter = _defaultRouter;
        uniswapV3quoter = _uniswapV3quoter;
    }

    function swap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amount,
        address _recipient
    ) external payable override returns (uint256) {
        require(_amount > 0, 'ZERO_AMOUNT');
        (address router, uint8 routerType) = getBestRouter(_tokenIn, _tokenOut);
        bool isNativeIn = KedrLib.isNative(_tokenIn);
        bool isNativeOut = KedrLib.isNative(_tokenOut);

        uint256 balanceBefore;
        if (!isNativeIn) {
            TransferHelper.safeTransferFrom(_tokenIn, msg.sender, address(this), _amount);
            TransferHelper.safeApprove(_tokenIn, router, _amount);
        }

        balanceBefore = isNativeOut ? address(_recipient).balance : IERC20(_tokenOut).balanceOf(_recipient);

        if (routerType == KedrConstants._ROUTER_TYPE_BALANCER) {
            _balancerSwap(router, _tokenIn, _tokenOut, _amount, _recipient);
        } else if (routerType == KedrConstants._ROUTER_TYPE_V2) {
            _v2swap(router, getAddressRoute(router, routerType, _tokenIn, _tokenOut), _amount, _recipient, isNativeIn, isNativeOut);
        } else if (routerType == KedrConstants._ROUTER_TYPE_V3) {
            _v3swap(router, getBytesRoute(router, routerType, _tokenIn, _tokenOut), _amount, _recipient);
        } else {
            revert('UNSUPPORTED_ROUTER_TYPE');
        }
        return isNativeOut? address(_recipient).balance - balanceBefore : IERC20(_tokenOut).balanceOf(_recipient) - balanceBefore;
    }

    function getAmountOut(
        address _tokenIn,
        address _tokenOut,
        uint256 _amount
    ) public override returns (uint256) {
        if (_tokenIn == _tokenOut) return _amount;

        (address router, uint8 routerType) = getBestRouter(_tokenIn, _tokenOut);

        if (routerType == KedrConstants._ROUTER_TYPE_BALANCER) {
            // todo: future work
            return _amount;
        } else if (routerType == KedrConstants._ROUTER_TYPE_V2) {
            uint256[] memory amounts = IUniswapV2Router02(router).getAmountsOut(
                _amount,
                getAddressRoute(router, routerType, _tokenIn, _tokenOut)
            );
            return amounts[amounts.length - 1]; // last item
        } else if (routerType == KedrConstants._ROUTER_TYPE_V3) {
            return IQuoter(uniswapV3quoter).quoteExactInput(getBytesRoute(router, routerType, _tokenIn, _tokenOut), _amount);
        } else {
            return 0;
        }
    }

    function getAmountIn(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountOut
    ) public override returns (uint256) {
        if (_tokenIn == _tokenOut) return _amountOut;

        (address router, uint8 routerType) = getBestRouter(_tokenIn, _tokenOut);

        if (routerType == KedrConstants._ROUTER_TYPE_BALANCER) {
            // todo: future work
            return _amountOut;
        } else if (routerType == KedrConstants._ROUTER_TYPE_V2) {
            uint256[] memory amounts = IUniswapV2Router02(router).getAmountsIn(
                _amountOut,
                getAddressRoute(router, routerType, _tokenIn, _tokenOut)
            );
            return amounts[0]; // first item
        } else if (routerType == KedrConstants._ROUTER_TYPE_V3) {
            return IQuoter(uniswapV3quoter).quoteExactOutput(getBytesRoute(router, routerType, _tokenIn, _tokenOut), _amountOut);
        } else {
            return 0;
        }
    }

    function getAddressRoute(
        address router,
        uint8 routerType,
        address tokenIn,
        address tokenOut
    ) internal view returns (address[] memory route) {
        if (routerType == KedrConstants._ROUTER_TYPE_BALANCER) {
            route = _getBalancerRoute(router, tokenIn, tokenOut);
        } else if (routerType == KedrConstants._ROUTER_TYPE_V2) {
            route = _getV2Route(router, tokenIn, tokenOut);
        } else {
            address[] memory _route;
            route = _route;
        }
    }

    function getBytesRoute(
        address router,
        uint8 routerType,
        address tokenIn,
        address tokenOut
    ) internal view returns (bytes memory route) {
        if (routerType == KedrConstants._ROUTER_TYPE_V3) {
            route = _getV3Route(router, tokenIn, tokenOut);
        } else {
            route = bytes('');
        }
    }

    function getBestRouter(address tokenIn, address tokenOut) internal view returns (address router, uint8 routerType) {
        router = defaultRouter;
        routerType = routerTypes[router];
    }

    function _getBalancerRoute(
        address router,
        address tokenIn,
        address tokenOut
    ) internal pure returns (address[] memory) {
        // todo: future work
        address[] memory route;
        route[0] = tokenIn;
        route[1] = tokenOut;
        return route;
    }

    function _getV2Route(
        address router,
        address tokenIn,
        address tokenOut
    ) internal view returns (address[] memory) {
        address factory = IUniswapV2Router02(router).factory();
        address WETH = IUniswapV2Router02(router).WETH();

        if (KedrLib.isNative(tokenIn)) tokenIn = WETH;
        if (KedrLib.isNative(tokenOut)) tokenOut = WETH;

        if (IUniswapV2Factory(factory).getPair(tokenIn, tokenOut) != address(0)) {
            address[] memory route = new address[](2);
            route[0] = tokenIn;
            route[1] = tokenOut;
            return route;
        } else {
            address[] memory tokens = routeTokens; // gas saving
            address middleToken;
            for (uint256 i; i < tokens.length; ++i) {
                if (
                    IUniswapV2Factory(factory).getPair(tokenIn, tokens[i]) != address(0) &&
                    IUniswapV2Factory(factory).getPair(tokens[i], tokenOut) != address(0)
                ) {
                    middleToken = tokens[i];
                    break;
                }
            }
            require(middleToken != address(0), 'CANT_FIND_ROUTE');
            address[] memory route = new address[](3);
            route[0] = tokenIn;
            route[1] = middleToken;
            route[2] = tokenOut;
            return route;
        }
    }

    function _getV3Route(
        address router,
        address tokenIn,
        address tokenOut
    ) internal view returns (bytes memory route) {
        address factory = IPeripheryImmutableState(router).factory();
        address WETH = IPeripheryImmutableState(router).WETH9();

        if (KedrLib.isNative(tokenIn)) tokenIn = WETH;
        if (KedrLib.isNative(tokenOut)) tokenOut = WETH;

        (route, ) = _checkEveryFeeForV3Pool(factory, tokenIn, tokenOut);

        if (route.length == 0) {
            // finding multi-hop route:
            address[] memory tokens = routeTokens; // gas saving

            for (uint256 i; i < tokens.length; ++i) {
                (bytes memory firstHop, uint24 firstFeeTier) = _checkEveryFeeForV3Pool(factory, tokenIn, tokens[i]);
                if (firstHop.length > 0) {
                    (bytes memory secondHop, uint24 secondFeeTier) = _checkEveryFeeForV3Pool(factory, tokens[i], tokenOut);
                    if (secondHop.length > 0) {
                        route = abi.encodePacked(tokenIn, firstFeeTier, tokens[i], secondFeeTier, tokenOut);
                        break;
                    }
                }
            }
        }
    }

    function _checkEveryFeeForV3Pool(
        address factory,
        address tokenIn,
        address tokenOut
    ) internal view returns (bytes memory route, uint24 fee) {
        IUniswapV3Factory Factory = IUniswapV3Factory(factory);

        if (Factory.getPool(tokenIn, tokenOut, FEE_500) != address(0)) {
            route = abi.encodePacked(tokenIn, FEE_500, tokenOut);
            fee = FEE_500;
        } else if (Factory.getPool(tokenIn, tokenOut, FEE_3000) != address(0)) {
            route = abi.encodePacked(tokenIn, FEE_3000, tokenOut);
            fee = FEE_3000;
        } else if (Factory.getPool(tokenIn, tokenOut, FEE_3000) != address(0)) {
            route = abi.encodePacked(tokenIn, FEE_10000, tokenOut);
            fee = FEE_10000;
        } else {
            route = bytes('');
        }
    }

    function _v2swap(
        address _router,
        address[] memory route,
        uint256 _amount,
        address _recipient,
        bool isNativeIn,
        bool isNativeOut
    ) internal returns (uint256) {
        uint256[] memory amounts;
        uint256 deadline = block.timestamp;
        if (isNativeIn) {
            amounts = IUniswapV2Router02(_router).swapExactETHForTokens{value: msg.value}(1, route, _recipient, deadline);
        } else if (isNativeOut) {
            amounts = IUniswapV2Router02(_router).swapExactTokensForETH(
                _amount,
                1, // todo: think about general control of max slippage if need
                route,
                _recipient,
                deadline
            );
        } else {
            amounts = IUniswapV2Router02(_router).swapExactTokensForTokens(
                _amount,
                1, // todo: think about general control of max slippage if need
                route,
                _recipient,
                deadline
            );
        }
        return amounts[amounts.length - 1];
    }

    function _v3swap(
        address _router,
        bytes memory path,
        uint256 amountIn,
        address recipient
    ) internal {
        uint256 deadline = block.timestamp;
        uint256 amountOutMinimum = 1;
        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams(path, recipient, deadline, amountIn, amountOutMinimum);
        ISwapRouter(_router).exactInput{value: msg.value}(params);
    }

    function _balancerSwap(
        address _router,
        address _tokenIn,
        address _tokenOut,
        uint256 _amount,
        address _recipient
    ) internal {
        // future work
    }
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
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Quoter Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IQuoter {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    function quoteExactInput(bytes memory path, uint256 amountIn) external returns (uint256 amountOut);

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountIn The desired input amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee. Path must be provided in reverse order
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    function quoteExactOutput(bytes memory path, uint256 amountOut) external returns (uint256 amountIn);

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountOut The desired output amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryImmutableState {
    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

pragma solidity >=0.6.2;

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

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
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

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

interface ISwapper {
    function swap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amount,
        address _recipient
    ) external payable returns (uint256);

    function getAmountOut(
        address _tokenIn,
        address _tokenOut,
        uint256 _amount
    ) external returns (uint256);

    function getAmountIn(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountOut
    ) external returns (uint256);
}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

library KedrConstants {
    uint16 internal constant _FEE_DENOMINATOR = 10000;
    uint16 internal constant _DEFAULT_FEE_NUMERATOR = 10000; // 0% fee by default
    uint16 internal constant _MAX_ENTRY_FEE = 1000; // 10%
    uint16 internal constant _MAX_SUCCESS_FEE = 500; // 5%

    uint8 internal constant _ROUTER_TYPE_BALANCER = 1; 
    uint8 internal constant _ROUTER_TYPE_V2 = 2;
    uint8 internal constant _ROUTER_TYPE_V3 = 3;

    uint8 internal constant _INACCURACY = 5; // max permissible innacuracy in the calculation of swaps
}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';

library KedrLib {
    /**
     * @dev deploys new contract using create2 with check of deployment
     */
    function deploy(bytes memory bytecode) external returns (address _contract) {
        assembly {
            _contract := create2(0, add(bytecode, 32), mload(bytecode), '')
            if iszero(extcodesize(_contract)) {
                revert(0, 0)
            }
        }
        return _contract;
    }

    function isNative(address token) internal pure returns (bool) {
        return token == address(0);
    }

    function uniTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (isNative(token)) {
            TransferHelper.safeTransferETH(to, amount);
        } else {
            TransferHelper.safeTransferFrom(token, from, to, amount);
        }
    }

    function uniTransfer(
        address token,
        address to,
        uint256 amount
    ) internal {
        if (isNative(token)) {
            TransferHelper.safeTransferETH(to, amount);
        } else {
            TransferHelper.safeTransfer(token, to, amount);
        }
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