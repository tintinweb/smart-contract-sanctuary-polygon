// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IERC20.sol";
import "../interfaces/IUniswapV2Liquidity.sol";

/**
 * @title SushiLiquidityBridge
 * @author DeFi Basket
 *
 * @notice Swaps using the Sushi contract in Polygon.
 *
 * @dev This contract adds or removes liquidity from Sushi through 2 functions:
 *
 * 1. addLiquidity works with 2 ERC20 tokens
 * 2. removeLiquidity works with 2 ERC20 tokens
 *
 */
contract SushiLiquidityBridge is IUniswapV2Liquidity {

    address constant public routerAddress = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    address constant public factoryAddress = 0xc35DADB65012eC5796536bD9864eD8773aBc74C4;
    IUniswapV2Router02 constant _uniswapRouter = IUniswapV2Router02(routerAddress);
    IUniswapV2Factory constant _uniswapFactory = IUniswapV2Factory(factoryAddress);


    /**
      * @notice Adds liquidity from 2 ERC20 tokens
      *
      * @dev Wraps add liquidity and generate the necessary events to communicate with DeFi Basket's UI and back-end.
      *
      * @param tokens List of two - token that will have liquidity added to pool
      * @param percentages List of two - percentages of the balance of ERC20 tokens that will be added to the pool
      * @param minAmounts List of two - minimum amounts of the ERC20 tokens required to add liquidity
      */
    function addLiquidity(
        address[] calldata tokens,
        uint256[] calldata percentages,
        uint256[] calldata minAmounts
    ) external override {

        uint256 amountA = IERC20(tokens[0]).balanceOf(address(this)) * percentages[0] / 100000;
        uint256 amountB = IERC20(tokens[1]).balanceOf(address(this)) * percentages[1] / 100000;

        // Approve 0 first as a few ERC20 tokens are requiring this pattern.
        IERC20(tokens[0]).approve(routerAddress, 0);
        IERC20(tokens[0]).approve(routerAddress, amountA);

        IERC20(tokens[1]).approve(routerAddress, 0);
        IERC20(tokens[1]).approve(routerAddress, amountB);

        // Receive addLiquidityETH output in a array to avoid stack too deep error
        uint256[3] memory routerOutputs;

        // [amountToken, amountETH, liquidity]
        (routerOutputs[0], routerOutputs[1], routerOutputs[2]) = _uniswapRouter.addLiquidity(
            tokens[0], //        address tokenA,
            tokens[1], //        address tokenB,
            amountA, //        uint amountADesired,
            amountB, //        uint amountBDesired,
            minAmounts[0], //        uint amountAMin,
            minAmounts[1], //        uint amountBMin,
            address(this), //  address to,
            block.timestamp + 100000  //   uint deadline
        );

        // Prepare arguments for emitting event
        uint[] memory amountTokensArray = new uint[](2);
        amountTokensArray[0] = routerOutputs[0];
        amountTokensArray[1] = routerOutputs[1];

        address assetOut = _uniswapFactory.getPair(tokens[0], tokens[1]);

        emit DEFIBASKET_UNISWAPV2_ADD_LIQUIDITY(amountTokensArray, assetOut, routerOutputs[2]);
    }

    /**
      * @notice Removes liquidity from 2 ERC20 tokens
      *
      * @dev Wraps remove liquidity and generate the necessary events to communicate with DeFi Basket's UI and
      * back-end.
      *
      * @param tokens List of two - token that will have liquidity removed from pool
      * @param percentage Percentage of LP token to be removed from pool
      * @param minAmounts List of two - minimum amounts of the ERC20 tokens required to remove liquidity
      */
    function removeLiquidity(
        address[] calldata tokens,
        uint256 percentage,
        uint256[] calldata minAmounts
    ) external override {
        address lpToken = _uniswapFactory.getPair(tokens[0], tokens[1]);
        uint256 liquidity = IERC20(lpToken).balanceOf(address(this)) * percentage / 100000;

        // Approve 0 first as a few ERC20 tokens are requiring this pattern.
        IERC20(lpToken).approve(routerAddress, 0);
        IERC20(lpToken).approve(routerAddress, liquidity);

        uint[] memory amountTokensArray = new uint[](2);
        // [amountToken, amountETH, liquidity]
        (amountTokensArray[0], amountTokensArray[1]) =  _uniswapRouter.removeLiquidity(
            tokens[0], // tokenA
            tokens[1], // tokenB
            liquidity, // liquidity,
            minAmounts[0], // amountAMin
            minAmounts[1], // amountBMin
            address(this), // address to,
            block.timestamp + 100000  // uint deadline
        );

        emit DEFIBASKET_UNISWAPV2_REMOVE_LIQUIDITY(amountTokensArray, lpToken, liquidity);
    }
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

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

interface IUniswapV2Liquidity {
    event DEFIBASKET_UNISWAPV2_ADD_LIQUIDITY(
        uint256[] amountIn,
        address lpToken,
        uint256 liquidity
    );

    event DEFIBASKET_UNISWAPV2_REMOVE_LIQUIDITY(
        uint256[] amountOut,
        address lpToken,
        uint256 liquidity
    );

    function addLiquidity(
        address[] calldata tokens,
        uint256[] calldata percentages,
        uint256[] calldata minAmounts
    ) external;

    function removeLiquidity(
        address[] calldata tokens,
        uint256 percentage,
        uint256[] calldata minAmounts
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