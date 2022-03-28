// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IERC20.sol";
import "../interfaces/IUniswapV2Swap.sol";
import "./interfaces/IKyberDMM.sol";
import "../interfaces/IKyberLiquidity.sol";

/**
 * @title KyberLiquidityBridge
 * @author DeFi Basket
 *
 * @notice Add/remove liquidity using the Kyber DMM contract in Polygon.
 *
 * @dev This contract swaps ERC20 tokens to ERC20 tokens. Please notice that there are no payable functions.
 *
 */

contract KyberLiquidityBridge is IKyberLiquidity {
    IKyberDMM constant router = IKyberDMM(0x546C79662E028B661dFB4767664d0273184E4dD1);

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
        address poolAddress,
        uint256[] calldata percentages,
        uint256[] calldata minAmounts,
        uint256[2] calldata vReserveRatioBounds
    ) external override {

        uint256 amountA = IERC20(tokens[0]).balanceOf(address(this)) * percentages[0] / 100000;
        uint256 amountB = IERC20(tokens[1]).balanceOf(address(this)) * percentages[1] / 100000;

        // Approve 0 first as a few ERC20 tokens are requiring this pattern.
        IERC20(tokens[0]).approve(address(router), 0);
        IERC20(tokens[0]).approve(address(router), amountA);

        IERC20(tokens[1]).approve(address(router), 0);
        IERC20(tokens[1]).approve(address(router), amountB);

        // Receive addLiquidityETH output in a array to avoid stack too deep error
        uint256[3] memory routerOutputs;

        // [amountToken, amountETH, liquidity]
        (routerOutputs[0], routerOutputs[1], routerOutputs[2]) = router.addLiquidity(
            tokens[0], //        address tokenA,
            tokens[1], //        address tokenB,
            poolAddress, //      address pool
            amountA, //        uint amountADesired,
            amountB, //        uint amountBDesired,
            minAmounts[0], //        uint amountAMin,
            minAmounts[1], //        uint amountBMin,
            vReserveRatioBounds,   // uint256[2] vReserveRatioBounds,
            address(this), //  address to,
            block.timestamp + 100000  //   uint deadline
        );

        // Prepare arguments for emitting event
        uint[] memory amountTokensArray = new uint[](2);
        amountTokensArray[0] = routerOutputs[0];
        amountTokensArray[1] = routerOutputs[1];

        emit DEFIBASKET_KYBER_ADD_LIQUIDITY(amountTokensArray, routerOutputs[2]);
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
        address poolAddress,
        uint256 percentage,
        uint256[] calldata minAmounts
    ) external override {
        uint256 liquidity = IERC20(poolAddress).balanceOf(address(this)) * percentage / 100000;

        // Approve 0 first as a few ERC20 tokens are requiring this pattern.
        IERC20(poolAddress).approve(address(router), 0);
        IERC20(poolAddress).approve(address(router), liquidity);

        uint[] memory amountTokensArray = new uint[](2);

        (amountTokensArray[0], amountTokensArray[1])= router.removeLiquidity(
            tokens[0], // tokenA
            tokens[1], // tokenB
            poolAddress, // pool
            liquidity, // liquidity,
            minAmounts[0], // amountAMin
            minAmounts[1], // amountBMin
            address(this), // address to,
            block.timestamp + 100000  // uint deadline
        );

        emit DEFIBASKET_KYBER_REMOVE_LIQUIDITY(amountTokensArray, poolAddress, liquidity);
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

interface IUniswapV2Swap {
    event DEFIBASKET_UNISWAPV2_SWAP(
        uint256[] amounts
    );

    function swapTokenToToken(
        uint256 amountInPercentage,
        uint256 amountOutMin,
        address[] calldata path
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

interface IKyberDMM {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata poolsPath,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        address pool,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256[2] calldata vReserveRatioBounds,
        address to,
        uint256 deadline
    ) external
    returns (
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        address pool,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external
    returns (
        uint256 amountA,
        uint256 amountB
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

interface IKyberLiquidity {
    event DEFIBASKET_KYBER_ADD_LIQUIDITY(
        uint256[] amountIn,
        uint256 liquidity
    );

    event DEFIBASKET_KYBER_REMOVE_LIQUIDITY(
        uint256[] amountOut,
        address poolAddress,
        uint256 liquidity
    );

    function addLiquidity(
        address[] calldata tokens,
        address poolAddress,
        uint256[] calldata percentages,
        uint256[] calldata minAmounts,
        uint256[2] calldata vReserveRatioBounds
    )  external;

    function removeLiquidity(
        address[] calldata tokens,
        address poolAddress,
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