// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import './Math.sol';
import './ICosoSwapPair.sol';
import './ICosoSwapFactory.sol';

library CosoSwapLibrary {
    /**
     * @dev Sort token addresses to ascending order.
     */
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'ZERO_ADDRESS');
    }

    /**
     * @dev Fetches pair address with given tokens.
     *
     * It will fetches from the storage instead of calculation with CREATE2,
     * because the limitation of zkSync 2.0.
     *
     * Note it will returns `address(0)` for non-exist pairs.
     * Consider reuse the pair address to avoid multiple storage accesses.
     */
    function pairFor(address factory, address tokenA, address tokenB) internal view returns (address pair) {
        return ICosoSwapFactory(factory).getPair(tokenA, tokenB);
    }

    /**
     * @dev Fetches pair with given tokens, returns its reserves in the given order.
     */
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint112 reserveA, uint112 reserveB, uint16 swapFee) {
        address pair = pairFor(factory, tokenA, tokenB);
        if (pair != address(0)) {
            (uint112 reserve0, uint112 reserve1, uint16 _swapFee) = ICosoSwapPair(pair).getReservesAndParameters();
            (reserveA, reserveB) = tokenA < tokenB ? (reserve0, reserve1) : (reserve1, reserve0);
            swapFee = _swapFee;
        }
    }

    /**
     * @dev Fetches reserves with given pair in the given order.
     */
    function getReservesWithPair(address pair, address tokenA, address tokenB) internal view returns (uint112 reserveA, uint112 reserveB, uint16 swapFee) {
        (uint112 reserve0, uint112 reserve1, uint16 _swapFee) = ICosoSwapPair(pair).getReservesAndParameters();
        (reserveA, reserveB) = tokenA < tokenB ? (reserve0, reserve1) : (reserve1, reserve0);
        swapFee = _swapFee;
    }

    /**
     * @dev Fetches pair with given tokens, returns pair address and its reserves in the given order if exists.
     */
    function getPairAndReserves(address factory, address tokenA, address tokenB) internal view returns (address pair, uint112 reserveA, uint112 reserveB, uint16 swapFee) {
        pair = pairFor(factory, tokenA, tokenB);
        if (pair != address(0)) { // return empty values if pair not exists
            (uint112 reserve0, uint112 reserve1, uint16 _swapFee) = ICosoSwapPair(pair).getReservesAndParameters();
            (reserveA, reserveB) = tokenA < tokenB ? (reserve0, reserve1) : (reserve1, reserve0);
            swapFee = _swapFee;
        }
    }

    /**
     * @dev Returns an equivalent amount of the other asset.
     */
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'INSUFFICIENT_LIQUIDITY');
        amountB = amountA * reserveB / reserveA;
    }

    /**
     * @dev Returns the maximum amount of the output asset.
     */
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint swapFee) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'INSUFFICIENT_LIQUIDITY');
        uint amountInAfterFee = amountIn * (10000 - swapFee);
        uint numerator = amountInAfterFee * reserveOut;
        uint denominator = (reserveIn * 10000) + amountInAfterFee;
        amountOut = numerator / denominator;
    }

    /**
     * @dev Returns a required amount of the input asset.
     */
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint swapFee) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn * amountOut * 10000;
        uint denominator = (reserveOut - amountOut) * (10000 - swapFee);
        amountIn = (numerator / denominator) + 1;
    }

    /**
     * @dev Performs chained `getAmountOut` calculations on any number of pairs
     */
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'INVALID_PATH');
        amounts = getAmountsOutUnchecked(factory, amountIn, path);
    }

    /**
     * @dev {getAmountsOut} without path length checks
     */
    function getAmountsOutUnchecked(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        amounts = new uint[](path.length);
        amounts[0] = amountIn;

        for (uint i; i < path.length - 1; ) {
            (uint112 reserveIn, uint112 reserveOut, uint16 swapFee) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut, swapFee);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Performs chained getAmountIn calculations on any number of pairs
     */
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'INVALID_PATH');
        amounts = getAmountsInUnchecked(factory, amountOut, path);
    }

    /**
     * @dev {getAmountsIn} without path length checks
     */
    function getAmountsInUnchecked(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;

        for (uint i = path.length - 1; i > 0; ) {
            (uint112 reserveIn, uint112 reserveOut, uint16 swapFee) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut, swapFee);

            unchecked {
                --i;
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import './CosoSwapRouterInternal.sol';
import './IWETH.sol';
import './ICosoSwapFactory.sol';
import './CosoSwapLibrary.sol';
import './TransferHelper.sol';

contract CosoSwapRouter is CosoSwapRouterInternal {

    address public factory;
    address public WETH;

    constructor(address _factory, address _WETH) {
        factory = _factory;
        WETH = _WETH;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    /*//////////////////////////////////////////////////////////////
        Pair Index
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(address => bool)) public isPairIndexed;
    mapping(address => address[]) public indexedPairs;

    function indexedPairsOf(address account) external view returns (address[] memory) {
        return indexedPairs[account];
    }

    function indexedPairsRange(address account, uint256 start, uint256 counts) external view returns (address[] memory) {
        require(counts != 0, "Counts must greater than zero");

        address[] memory pairs = indexedPairs[account];
        require(start + counts <= pairs.length, "Out of bound");

        address[] memory result = new address[](counts);
        for (uint256 i = 0; i < counts; i++) {
            result[i] = pairs[start + i];
        }
        return result;
    }

    function indexedPairsLengthOf(address account) external view returns (uint256) {
        return indexedPairs[account].length;
    }

    /*//////////////////////////////////////////////////////////////
        Add Liquidity
    //////////////////////////////////////////////////////////////*/

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountAInExpected,
        uint amountBInExpected,
        uint amountAInMin,
        uint amountBInMin
    ) internal virtual returns (address pair, uint amountAInActual, uint amountBInActual) {
        address _factory = factory;
        pair = CosoSwapLibrary.pairFor(_factory, tokenA, tokenB);
        if (pair == address(0)) {
            // create the pair if it doesn't exist yet
            pair = ICosoSwapFactory(_factory).createPair(tokenA, tokenB);

            // input amounts are desired amounts for the first time
            (amountAInActual, amountBInActual) = (amountAInExpected, amountBInExpected);
        } else {
            // ensure optimal input amounts
            (amountAInActual, amountBInActual) = _getOptimalAmountsInForAddLiquidity(
                pair, tokenA, tokenB, amountAInExpected, amountBInExpected, amountAInMin, amountBInMin
            );
        }
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountAInExpected,
        uint amountBInExpected,
        uint amountAInMin,
        uint amountBInMin,
        address to,
        uint deadline
    ) external ensureNotExpired(deadline) returns (uint amountAInActual, uint amountBInActual, uint liquidity) {
        address pair;
        (pair, amountAInActual, amountBInActual) = _addLiquidity(tokenA, tokenB, amountAInExpected, amountBInExpected, amountAInMin, amountBInMin);

        // transfer tokens of (optimal) input amounts to the pair
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountAInActual);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountBInActual);

        // mint the liquidity tokens for sender
        liquidity = ICosoSwapPair(pair).mint(to);

        // index the pair for search
        if (!isPairIndexed[to][pair]) {
            isPairIndexed[to][pair] = true;
            indexedPairs[to].push(pair);
        }
    }

    function addLiquidityETH(
        address token,
        uint amountTokenInExpected,
        uint amountTokenInMin,
        uint amountETHInMin,
        address to,
        uint deadline
    ) external payable ensureNotExpired(deadline) returns (uint amountTokenInActual, uint amountETHInActual, uint liquidity) {
        address pair;
        (pair, amountTokenInActual, amountETHInActual) = _addLiquidity(token, WETH, amountTokenInExpected, msg.value, amountTokenInMin, amountETHInMin);

        // transfer tokens of (optimal) input amounts to the pair
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountTokenInActual);
        IWETH(WETH).deposit{value: amountETHInActual}();
        assert(IWETH(WETH).transfer(pair, amountETHInActual));

        // mint the liquidity tokens for sender
        liquidity = ICosoSwapPair(pair).mint(to);

        // refund dust eth, if any
        if (msg.value > amountETHInActual) {
            TransferHelper.safeTransferETH(msg.sender, msg.value - amountETHInActual);
        }

        // index the pair for search
        if (!isPairIndexed[to][pair]) {
            isPairIndexed[to][pair] = true;
            indexedPairs[to].push(pair);
        }
    }

    /*//////////////////////////////////////////////////////////////
        Remove Liquidity
    //////////////////////////////////////////////////////////////*/

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAOutMin,
        uint amountBOutMin,
        address to,
        uint deadline
    ) public ensureNotExpired(deadline) returns (uint amountAOut, uint amountBOut) {
        address pair = CosoSwapLibrary.pairFor(factory, tokenA, tokenB);
        (amountAOut, amountBOut) = _burnLiquidity(
            pair, tokenA, tokenB, liquidity, amountAOutMin, amountBOutMin, to
        );
    }

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public ensureNotExpired(deadline) returns (uint amountToken, uint amountETH) {
        (amountToken, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

//    function _permit(
//        address tokenA,
//        address tokenB,
//        bool approveMax,
//        uint liquidity,
//        uint deadline,
//        uint8 v, bytes32 r, bytes32 s
//    ) internal returns (address) {
//        address pair = CosoSwapLibrary.pairFor(factory, tokenA, tokenB);
//        uint256 value = approveMax ? type(uint).max : liquidity;
//        ICosoSwapPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
//        return pair;
//    }
//
//    function _removeLiquidityWithPermit(
//        address tokenA,
//        address tokenB,
//        uint liquidity,
//        uint amountAOutMin,
//        uint amountBOutMin,
//        address to,
//        uint deadline,
//        bool approveMax,
//        uint8 v, bytes32 r, bytes32 s
//    ) internal returns (uint amountAOut, uint amountBOut) {
//        address pair = _permit(tokenA, tokenB, approveMax, liquidity, deadline, v, r, s);
//
//        (amountAOut, amountBOut) = _burnLiquidity(
//            pair, tokenA, tokenB, liquidity, amountAOutMin, amountBOutMin, to
//        );
//    }

//    function removeLiquidityWithPermit(
//        address tokenA,
//        address tokenB,
//        uint liquidity,
//        uint amountAOutMin,
//        uint amountBOutMin,
//        address to,
//        uint deadline,
//        bool approveMax, uint8 v, bytes32 r, bytes32 s
//    ) external returns (uint amountAOut, uint amountBOut) {
//        // wrapped to avoid stack too deep errors
//        (amountAOut, amountBOut) = _removeLiquidityWithPermit(tokenA, tokenB, liquidity, amountAOutMin, amountBOutMin, to, deadline, approveMax, v, r, s);
//    }

//    function removeLiquidityETHWithPermit(
//        address token,
//        uint liquidity,
//        uint amountTokenMin,
//        uint amountETHMin,
//        address to,
//        uint deadline,
//        bool approveMax, uint8 v, bytes32 r, bytes32 s
//    ) external returns (uint amountToken, uint amountETH) {
//        _permit(token, WETH, approveMax, liquidity, deadline, v, r, s);
//        (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
//    }

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public ensureNotExpired(deadline) returns (uint amountETH) {
        (, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

//    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
//        address token,
//        uint liquidity,
//        uint amountTokenMin,
//        uint amountETHMin,
//        address to,
//        uint deadline,
//        bool approveMax, uint8 v, bytes32 r, bytes32 s
//    ) external returns (uint amountETH) {
//        _permit(token, WETH, approveMax, liquidity, deadline, v, r, s);
//
//        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
//            token, liquidity, amountTokenMin, amountETHMin, to, deadline
//        );
//    }

    /*//////////////////////////////////////////////////////////////
        Swap
    //////////////////////////////////////////////////////////////*/

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external ensureNotExpired(deadline) returns (uint[] memory amounts) {
        amounts = CosoSwapLibrary.getAmountsOutUnchecked(factory, amountIn, path); // will fail below if path is invalid
        // make sure the final output amount not smaller than the minimum
        require(amounts[amounts.length - 1] >= amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');

        address tokenIn = path[0];
        address initialPair = CosoSwapLibrary.pairFor(factory, tokenIn, path[1]);
        TransferHelper.safeTransferFrom(tokenIn, msg.sender, initialPair, amounts[0]);
        _swapCached(factory, initialPair, amounts, path, to);
    }

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable ensureNotExpired(deadline) returns (uint[] memory amounts) {
        address tokenIn = path[0];
        require(tokenIn == WETH, 'INVALID_PATH');
        amounts = CosoSwapLibrary.getAmountsOutUnchecked(factory, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');

        uint256 amountIn = amounts[0];
        IWETH(WETH).deposit{value: amountIn}();

        address initialPair = CosoSwapLibrary.pairFor(factory, tokenIn, path[1]);
        assert(IWETH(WETH).transfer(initialPair, amountIn));

        _swapCached(factory, initialPair, amounts, path, to);
    }

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual ensureNotExpired(deadline) returns (uint[] memory amounts) {
        require(path[path.length - 1] == WETH, 'INVALID_PATH');
        amounts = CosoSwapLibrary.getAmountsOutUnchecked(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');

        address tokenIn = path[0];
        address initialPair = CosoSwapLibrary.pairFor(factory, tokenIn, path[1]);
        TransferHelper.safeTransferFrom(tokenIn, msg.sender, initialPair, amounts[0]);
        _swapCached(factory, initialPair, amounts, path, address(this));

        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external ensureNotExpired(deadline) returns (uint[] memory amounts) {
        amounts = CosoSwapLibrary.getAmountsInUnchecked(factory, amountOut, path); // will fail below if path is invalid
        // make sure the final input amount not bigger than the maximum
        require(amounts[0] <= amountInMax, 'EXCESSIVE_INPUT_AMOUNT');

        address tokenIn = path[0];
        address initialPair = CosoSwapLibrary.pairFor(factory, tokenIn, path[1]);
        TransferHelper.safeTransferFrom(tokenIn, msg.sender, initialPair, amounts[0]);
        _swapCached(factory, initialPair, amounts, path, to);
    }

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual payable ensureNotExpired(deadline) returns (uint[] memory amounts) {
        address tokenIn = path[0];
        require(tokenIn == WETH, 'INVALID_PATH');
        amounts = CosoSwapLibrary.getAmountsInUnchecked(factory, amountOut, path);

        uint256 amountIn = amounts[0];
        require(amountIn <= msg.value, 'EXCESSIVE_INPUT_AMOUNT');

        IWETH(WETH).deposit{value: amountIn}();
        address initialPair = CosoSwapLibrary.pairFor(factory, tokenIn, path[1]);
        assert(IWETH(WETH).transfer(initialPair, amountIn));
        _swapCached(factory, initialPair, amounts, path, to);

        // refund dust eth, if any
        if (msg.value > amountIn) {
            TransferHelper.safeTransferETH(msg.sender, msg.value - amountIn);
        }
    }

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual ensureNotExpired(deadline) returns (uint[] memory amounts) {
        require(path[path.length - 1] == WETH, 'INVALID_PATH');
        amounts = CosoSwapLibrary.getAmountsInUnchecked(factory, amountOut, path);

        uint256 amountIn = amounts[0];
        require(amountIn <= amountInMax, 'EXCESSIVE_INPUT_AMOUNT');

        address tokenIn = path[0];
        address initialPair = CosoSwapLibrary.pairFor(factory, tokenIn, path[1]);
        TransferHelper.safeTransferFrom(tokenIn, msg.sender, initialPair, amountIn);
        _swapCached(factory, initialPair, amounts, path, address(this));

        uint256 _amountOut = amounts[amounts.length - 1];
        IWETH(WETH).withdraw(_amountOut);
        TransferHelper.safeTransferETH(to, _amountOut);
    }

    /*//////////////////////////////////////////////////////////////
        Swap (fee-on-transfer)
    //////////////////////////////////////////////////////////////*/

    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address initialPair, address[] calldata path, address _to) internal virtual {
        for (uint i; i < path.length - 1; ) {
            (address input, address output) = (path[i], path[i + 1]);

            ICosoSwapPair pair = ICosoSwapPair(i == 0 ? initialPair : CosoSwapLibrary.pairFor(factory, input, output));
            uint amountInput;
            uint amountOutput;

            { // scope to avoid stack too deep errors
                (uint reserve0, uint reserve1, uint16 swapFee) = pair.getReservesAndParameters();
                (uint reserveIn, uint reserveOut) = input < output ? (reserve0, reserve1) : (reserve1, reserve0);
                amountInput = IERC20(input).balanceOf(address(pair)) - reserveIn;
                amountOutput = CosoSwapLibrary.getAmountOut(amountInput, reserveIn, reserveOut, swapFee);
            }

            address to = i < path.length - 2 ? CosoSwapLibrary.pairFor(factory, output, path[i + 2]) : _to;

            if (input < output) { // whether input token is `token0`
                pair.swapFor1(amountOutput, to);
            } else {
                pair.swapFor0(amountOutput, to);
            }

            unchecked {
                ++i;
            }
        }
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external ensureNotExpired(deadline) {
        address tokenIn = path[0];
        address initialPair = CosoSwapLibrary.pairFor(factory, tokenIn, path[1]);
        TransferHelper.safeTransferFrom(
            tokenIn, msg.sender, initialPair, amountIn
        );

        address tokenOut = path[path.length - 1];
        uint balanceBefore = IERC20(tokenOut).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(initialPair, path, to);

        require(
            IERC20(tokenOut).balanceOf(to) - balanceBefore >= amountOutMin,
            'INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable ensureNotExpired(deadline) {
        address tokenIn = path[0];
        require(tokenIn == WETH, 'INVALID_PATH');

        uint amountIn = msg.value;
        IWETH(WETH).deposit{value: amountIn}();
        address initialPair = CosoSwapLibrary.pairFor(factory, tokenIn, path[1]);
        assert(IWETH(WETH).transfer(initialPair, amountIn));

        address tokenOut = path[path.length - 1];
        uint balanceBefore = IERC20(tokenOut).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(initialPair, path, to);

        require(
            IERC20(tokenOut).balanceOf(to) - balanceBefore >= amountOutMin,
            'INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external ensureNotExpired(deadline) {
        require(path[path.length - 1] == WETH, 'INVALID_PATH');

        address tokenIn = path[0];
        address initialPair = CosoSwapLibrary.pairFor(factory, tokenIn, path[1]);
        TransferHelper.safeTransferFrom(
            tokenIn, msg.sender, initialPair, amountIn
        );
        _swapSupportingFeeOnTransferTokens(initialPair, path, address(this));

        uint amountOut = IERC20(WETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');

        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    /*//////////////////////////////////////////////////////////////
        VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB) {
        return CosoSwapLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external view returns (uint amountOut) {
        return CosoSwapLibrary.getAmountOut(amountIn, reserveIn, reserveOut, ICosoSwapFactory(factory).swapFee());
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external view returns (uint amountIn) {
        return CosoSwapLibrary.getAmountIn(amountOut, reserveIn, reserveOut, ICosoSwapFactory(factory).swapFee());
    }

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts) {
        return CosoSwapLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts) {
        return CosoSwapLibrary.getAmountsIn(factory, amountOut, path);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import './ICosoSwapPair.sol';

import './CosoSwapLibrary.sol';
import './TransferHelper.sol';

abstract contract CosoSwapRouterInternal {

    /*//////////////////////////////////////////////////////////////
        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    modifier ensureNotExpired(uint deadline) {
        require(block.timestamp <= deadline, 'EXPIRED');
        _;
    }

    // uncheck the reserves
    function _quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA != 0, 'INSUFFICIENT_AMOUNT');
        //require(reserveA != 0 && reserveB != 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY'); // already checked in caller context
        amountB = amountA * reserveB / reserveA;
    }

    // uncheck identical addresses and zero address
    function _getReserves(address pair, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (uint reserve0, uint reserve1) = ICosoSwapPair(pair).getReservesSimple();
        // no need to check identical addresses and zero address, as it was checked when pair creation
        (reserveA, reserveB) = tokenA < tokenB ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    /*//////////////////////////////////////////////////////////////
        Add Liquidity
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Return the optimal amounts of input tokens for adding liquidity.
     *
     * @param pair The pair address of `token A` and `token B`.
     * @param tokenA The address of `token A`.
     * @param tokenB The address of `token B`.
     * @param amountAInExpected The expected (desired) input amount of `token A`.
     * @param amountBInExpected The expected (desired) input amount of `token B`.
     * @param amountAInMin The minimum allowed input amount of `token A`.
     * @param amountBInMin The minimum allowed input amount of `token B`.
     *
     * Return uint256 values indicating the (possibly optimal) input amounts of tokens.
     *
     * The execution will revert if the optimal amounts are smaller than the minimum.
     *
     * NOTE: Optimal amounts are the same as expected if it's the first time
     * to add liquidity for the pair (reserves are 0).
     *
     * Requirements:
     *
     * - `tokenA` is not the same with `tokenB`.
     * - `tokenA` and `tokenB` are not zero addresses.
     * - `amountAInExpected` and `amountBInExpected` are not zero.
     */
    function _getOptimalAmountsInForAddLiquidity(
        address pair,
        address tokenA,
        address tokenB,
        uint amountAInExpected,
        uint amountBInExpected,
        uint amountAInMin,
        uint amountBInMin
    ) internal view returns (uint amountAIn, uint amountBIn) {
         (uint reserveA, uint reserveB) = _getReserves(pair, tokenA, tokenB);

        if (reserveA == 0 && reserveB == 0) {
            // the first time of adding liquidity
            (amountAIn, amountBIn) = (amountAInExpected, amountBInExpected);
        } else {
            uint amountBInOptimal = _quote(amountAInExpected, reserveA, reserveB);

            // checks if trading price of B are the same or have increased
            if (amountBInOptimal <= amountBInExpected) {
                // may found a better (smaller) B amount, compare with the minimum
                require(amountBInOptimal >= amountBInMin, 'INSUFFICIENT_B_AMOUNT');
                (amountAIn, amountBIn) = (amountAInExpected, amountBInOptimal);
            } else {
                uint amountAInOptimal = _quote(amountBInExpected, reserveB, reserveA);
                // always true as price of B are the same or can only
                // decreasing (price of A have increased) in above checking
                //assert(amountAInOptimal <= amountAInExpected);

                // may found a better (smaller) A amount, compare with the minimum
                // this could happend if trading price of A have increased
                require(amountAInOptimal >= amountAInMin, 'INSUFFICIENT_A_AMOUNT');
                (amountAIn, amountBIn) = (amountAInOptimal, amountBInExpected);
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
        Remove Liquidity
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Return the output amounts of tokens by removeing liquidity.
     *
     * @param tokenA The address of `token A`.
     * @param tokenB The address of `token B`.
     * @param liquidity The amount of liquidity tokens to burn.
     * @param amountAOutMin The minimum allowed output amount of `token A`.
     * @param amountBOutMin The minimum allowed output amount of `token B`.
     *
     * Return uint256 values indicating the actual output amounts of tokens.
     *
     * The execution will revert if the output amounts are smaller than the minimum.
     *
     * NOTE: Liquidity tokens must have enough allowances before calling.
     *
     * Emits an {Burn} event for the pair after successfully removal.
     */
    function _burnLiquidity(
        address pair,
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAOutMin,
        uint amountBOutMin,
        address to
    ) internal returns (uint amountAOut, uint amountBOut) {
        // send liquidity tokens to the pair and burn it atomically
        ICosoSwapPair(pair).transferFrom(msg.sender, pair, liquidity);
        (uint amount0, uint amount1) = ICosoSwapPair(pair).burn(to);

        // no need to check identical addresses and zero address, as it was checked when pair creation
        (amountAOut, amountBOut) = tokenA < tokenB ? (amount0, amount1) : (amount1, amount0);
        require(amountAOut >= amountAOutMin, 'INSUFFICIENT_A_AMOUNT');
        require(amountBOut >= amountBOutMin, 'INSUFFICIENT_B_AMOUNT');
    }

    /*//////////////////////////////////////////////////////////////
        Swap
    //////////////////////////////////////////////////////////////*/

    // requires the initial amount to have already been sent to the first pair
    /*
    function _swap(address initialPair, uint[] memory amounts, address[] memory path, address to) internal { // not in use
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);

            uint amountOut = amounts[i + 1]; // output amount of current sub swap.
            // no need to check identical addresses and zero address, as it was checked when pair creation.
            (uint amount0Out, uint amount1Out) = input < output ? (uint(0), amountOut) : (amountOut, uint(0));

            // calculate whether the to address is the next pair or the sender (destination):
            // path[i] = `input`, path[i + 1] = `output`, path[i + 2] = `next to output`
            // while the next pair is comprised of `output` nad `next to output`.
            address currentTo = i < path.length - 2 ? CosoSwapLibrary.pairFor(_factory, output, path[i + 2]) : to;

            // perfrom the swap, ingredient tokens have already transferred by the
            // last sub swap with `to` or its caller function.
            address pair = i == 0 ? initialPair : CosoSwapLibrary.pairFor(_factory, input, output); // use initial pair;
            ILiquidityPair(pair).swap(amount0Out, amount1Out, currentTo, new bytes(0));
        }
    }
    */

    // requires the initial amount to have already been sent to the first pair
    function _swapCached(address _factory, address initialPair, uint[] memory amounts, address[] calldata path, address to) internal {
        // cache next pair, this can save `path.length - 1` storage accessing pair addresses.
        address nextPair = initialPair;

        for (uint i; i < path.length - 1; ) {
            (address input, address output) = (path[i], path[i + 1]);
            uint amountOut = amounts[i + 1]; // output amount of current sub swap.

            // calculate whether the `to` address is the next pair or the sender (destination):
            // path[i] = `input`, path[i + 1] = `output`, path[i + 2] = `next to output`
            // while the next pair is comprised of `output` nad `next to output`.
            if (i < path.length - 2) {
                // `to` is a next pair
                address pair = nextPair;
                nextPair = CosoSwapLibrary.pairFor(_factory, output, path[i + 2]); // cache `to` as `nextPair` for the next sub swap.

                // perfrom the swap, ingredient tokens have already transferred by the
                // last sub swap with `to` or its caller function.
                _swapSingle(pair, amountOut, input, output, nextPair);
            } else {
                // finally, `to` is the sender

                // perfrom the swap, ingredient tokens have already transferred by the
                // last sub swap with `to` or its caller function.
                _swapSingle(nextPair, amountOut, input, output, to);
            }

            unchecked {
                ++i;
            }
        }
    }

    function _swapSingle(address pair, uint amountOut, address tokenIn, address tokenOut, address to) internal {
        if (tokenIn < tokenOut) { // whether input token is `token0`
            ICosoSwapPair(pair).swapFor1(amountOut, to);
        } else {
            ICosoSwapPair(pair).swapFor0(amountOut, to);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./IUniswapV2Factory.sol";

/// @dev SyncSwap factory interface with full Uniswap V2 compatibility
interface ICosoSwapFactory is IUniswapV2Factory {
    function isPair(address pair) external view returns (bool);
    function acceptFeeToSetter() external;

    function swapFee() external view returns (uint16);
    function setSwapFee(uint16 newFee) external;

    function protocolFeeFactor() external view returns (uint8);
    function setProtocolFeeFactor(uint8 newFactor) external;

    function setSwapFeeOverride(address pair, uint16 swapFeeOverride) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./IUniswapV2Pair.sol";

/// @dev SyncSwap pair interface with full Uniswap V2 compatibility
interface ICosoSwapPair is IUniswapV2Pair {
    function getPrincipal(address account) external view returns (uint112 principal0, uint112 principal1, uint32 timeLastUpdate);
    function swapFor0(uint amount0Out, address to) external; // support simple swap
    function swapFor1(uint amount1Out, address to) external; // support simple swap

    function getReservesAndParameters() external view returns (uint112 reserve0, uint112 reserve1, uint16 swapFee);
    function getReservesSimple() external view returns (uint112, uint112);

    function swapFeeOverride() external view returns (uint16);
    function setSwapFeeOverride(uint16 newSwapFeeOverride) external;
    function getSwapFee() external view returns (uint16);
}

// SPDX-License-Identifier: AGPL-3.0-or-later

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

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Metadata {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /**
     * @dev Returns the permit typehash
     */
    // solhint-disable-next-line func-name-mixedcase
    function PERMIT_TYPEHASH() external pure returns (bytes32);
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.5.0;

/// @dev Uniswap V2 factory interface
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

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.5.0;

import './IERC20.sol';
import './IERC20Metadata.sol';
import './IERC20Permit.sol';

/// @dev Uniswap V2 pair interface
interface IUniswapV2Pair is IERC20, IERC20Metadata, IERC20Permit {
    //event Approval(address indexed owner, address indexed spender, uint value); // IERC20
    //event Transfer(address indexed from, address indexed to, uint value); // IERC20

    //function name() external pure returns (string memory); // IERC20Metadata
    //function symbol() external pure returns (string memory); // IERC20Metadata
    //function decimals() external pure returns (uint8); // IERC20Metadata
    //function totalSupply() external view returns (uint); // IERC20
    //function balanceOf(address owner) external view returns (uint); // IERC20
    //function allowance(address owner, address spender) external view returns (uint); // IERC20

    //function approve(address spender, uint value) external returns (bool); // IERC20
    //function transfer(address to, uint value) external returns (bool); // IERC20
    //function transferFrom(address from, address to, uint value) external returns (bool); // IERC20

    //function DOMAIN_SEPARATOR() external view returns (bytes32); // IERC20Permit
    //function PERMIT_TYPEHASH() external pure returns (bytes32); // IERC20Permit
    //function nonces(address owner) external view returns (uint); // IERC20Permit

    //function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external; // IERC20Permit

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    //function MINIMUM_LIQUIDITY() external pure returns (uint); // UNUSED
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    //function initialize(address, address) external; // UNUSED
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function balanceOf(address guy) external returns (uint);
    function approve(address guy, uint wad) external returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

/**
 * @dev A library for performing various math operations.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @notice Calculates the square root of x, rounding down.
     * @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
     * @param x The uint256 number for which to calculate the square root.
     * @return result The result as an uint256.
     *
     * See https://github.com/paulrberg/prb-math/blob/701b1badb9a0951f27e344602726ead71f138b1a/contracts/PRBMath.sol#L599
     */
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the least power of two that is greater than or equal to sqrt(x).
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

/// @dev Helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}