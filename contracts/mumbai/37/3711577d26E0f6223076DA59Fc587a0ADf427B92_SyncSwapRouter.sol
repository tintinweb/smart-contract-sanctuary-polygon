// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import './SyncSwapRouterInternal.sol';

import '../../interfaces/IWETH.sol';
import '../../interfaces/protocol/ISyncSwapRouter.sol';
import '../../interfaces/protocol/ISyncPSM.sol';
import '../../interfaces/protocol/core/ISyncSwapFactory.sol';

import '../../libraries/protocol/SyncSwapLibrary.sol';
import '../../libraries/token/ERC20/utils/TransferHelper.sol';

import '../../protocol/farm/SyncSwapFarm.sol';

contract SyncSwapRouter is ISyncSwapRouter, SyncSwapRouterInternal {

    address public immutable override factory;
    address public immutable override WETH;

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

    mapping(address => mapping(address => bool)) public override isPairIndexed;
    mapping(address => address[]) public override indexedPairs;

    function indexedPairsOf(address account) external view override returns (address[] memory) {
        return indexedPairs[account];
    }

    function indexedPairsRange(address account, uint256 start, uint256 counts) external view override returns (address[] memory) {
        require(counts != 0, "Counts must greater than zero");

        address[] memory pairs = indexedPairs[account];
        require(start + counts <= pairs.length, "Out of bound");

        address[] memory result = new address[](counts);
        for (uint256 i = 0; i < counts; i++) {
            result[i] = pairs[start + i];
        }
        return result;
    }

    function indexedPairsLengthOf(address account) external view override returns (uint256) {
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
        pair = SyncSwapLibrary.pairFor(_factory, tokenA, tokenB);
        if (pair == address(0)) {
            // create the pair if it doesn't exist yet
            pair = ISyncSwapFactory(_factory).createPair(tokenA, tokenB);

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
    ) external override ensureNotExpired(deadline) returns (uint amountAInActual, uint amountBInActual, uint liquidity) {
        address pair;
        (pair, amountAInActual, amountBInActual) = _addLiquidity(tokenA, tokenB, amountAInExpected, amountBInExpected, amountAInMin, amountBInMin);

        // transfer tokens of (optimal) input amounts to the pair
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountAInActual);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountBInActual);

        // mint the liquidity tokens for sender
        liquidity = ISyncSwapPair(pair).mint(to);

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
    ) external override payable ensureNotExpired(deadline) returns (uint amountTokenInActual, uint amountETHInActual, uint liquidity) {
        address pair;
        (pair, amountTokenInActual, amountETHInActual) = _addLiquidity(token, WETH, amountTokenInExpected, msg.value, amountTokenInMin, amountETHInMin);

        // transfer tokens of (optimal) input amounts to the pair
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountTokenInActual);
        IWETH(WETH).deposit{value: amountETHInActual}();
        assert(IWETH(WETH).transfer(pair, amountETHInActual));

        // mint the liquidity tokens for sender
        liquidity = ISyncSwapPair(pair).mint(to);

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
    ) public override ensureNotExpired(deadline) returns (uint amountAOut, uint amountBOut) {
        address pair = SyncSwapLibrary.pairFor(factory, tokenA, tokenB);
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
    ) public override ensureNotExpired(deadline) returns (uint amountToken, uint amountETH) {
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

    function _permit(
        address tokenA,
        address tokenB,
        bool approveMax,
        uint liquidity,
        uint deadline,
        uint8 v, bytes32 r, bytes32 s
    ) internal returns (address) {
        address pair = SyncSwapLibrary.pairFor(factory, tokenA, tokenB);
        uint256 value = approveMax ? type(uint).max : liquidity;
        ISyncSwapPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        return pair;
    }

    function _removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAOutMin,
        uint amountBOutMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v, bytes32 r, bytes32 s
    ) internal returns (uint amountAOut, uint amountBOut) {
        address pair = _permit(tokenA, tokenB, approveMax, liquidity, deadline, v, r, s);

        (amountAOut, amountBOut) = _burnLiquidity(
            pair, tokenA, tokenB, liquidity, amountAOutMin, amountBOutMin, to
        );
    }

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAOutMin,
        uint amountBOutMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external override returns (uint amountAOut, uint amountBOut) {
        // wrapped to avoid stack too deep errors
        (amountAOut, amountBOut) = _removeLiquidityWithPermit(tokenA, tokenB, liquidity, amountAOutMin, amountBOutMin, to, deadline, approveMax, v, r, s);
    }

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external override returns (uint amountToken, uint amountETH) {
        _permit(token, WETH, approveMax, liquidity, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public override ensureNotExpired(deadline) returns (uint amountETH) {
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

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external override returns (uint amountETH) {
        _permit(token, WETH, approveMax, liquidity, deadline, v, r, s);

        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            token, liquidity, amountTokenMin, amountETHMin, to, deadline
        );
    }

    /*//////////////////////////////////////////////////////////////
        Swap
    //////////////////////////////////////////////////////////////*/

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external override ensureNotExpired(deadline) returns (uint[] memory amounts) {
        amounts = SyncSwapLibrary.getAmountsOutUnchecked(factory, amountIn, path); // will fail below if path is invalid
        // make sure the final output amount not smaller than the minimum
        require(amounts[amounts.length - 1] >= amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');

        address tokenIn = path[0];
        address initialPair = SyncSwapLibrary.pairFor(factory, tokenIn, path[1]);
        TransferHelper.safeTransferFrom(tokenIn, msg.sender, initialPair, amounts[0]);
        _swapCached(factory, initialPair, amounts, path, to);
    }

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external override payable ensureNotExpired(deadline) returns (uint[] memory amounts) {
        address tokenIn = path[0];
        require(tokenIn == WETH, 'INVALID_PATH');
        amounts = SyncSwapLibrary.getAmountsOutUnchecked(factory, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');

        uint256 amountIn = amounts[0];
        IWETH(WETH).deposit{value: amountIn}();

        address initialPair = SyncSwapLibrary.pairFor(factory, tokenIn, path[1]);
        assert(IWETH(WETH).transfer(initialPair, amountIn));

        _swapCached(factory, initialPair, amounts, path, to);
    }

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensureNotExpired(deadline) returns (uint[] memory amounts) {
        require(path[path.length - 1] == WETH, 'INVALID_PATH');
        amounts = SyncSwapLibrary.getAmountsOutUnchecked(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');

        address tokenIn = path[0];
        address initialPair = SyncSwapLibrary.pairFor(factory, tokenIn, path[1]);
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
    ) external override ensureNotExpired(deadline) returns (uint[] memory amounts) {
        amounts = SyncSwapLibrary.getAmountsInUnchecked(factory, amountOut, path); // will fail below if path is invalid
        // make sure the final input amount not bigger than the maximum
        require(amounts[0] <= amountInMax, 'EXCESSIVE_INPUT_AMOUNT');

        address tokenIn = path[0];
        address initialPair = SyncSwapLibrary.pairFor(factory, tokenIn, path[1]);
        TransferHelper.safeTransferFrom(tokenIn, msg.sender, initialPair, amounts[0]);
        _swapCached(factory, initialPair, amounts, path, to);
    }

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override payable ensureNotExpired(deadline) returns (uint[] memory amounts) {
        address tokenIn = path[0];
        require(tokenIn == WETH, 'INVALID_PATH');
        amounts = SyncSwapLibrary.getAmountsInUnchecked(factory, amountOut, path);

        uint256 amountIn = amounts[0];
        require(amountIn <= msg.value, 'EXCESSIVE_INPUT_AMOUNT');

        IWETH(WETH).deposit{value: amountIn}();
        address initialPair = SyncSwapLibrary.pairFor(factory, tokenIn, path[1]);
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
    ) external virtual override ensureNotExpired(deadline) returns (uint[] memory amounts) {
        require(path[path.length - 1] == WETH, 'INVALID_PATH');
        amounts = SyncSwapLibrary.getAmountsInUnchecked(factory, amountOut, path);

        uint256 amountIn = amounts[0];
        require(amountIn <= amountInMax, 'EXCESSIVE_INPUT_AMOUNT');

        address tokenIn = path[0];
        address initialPair = SyncSwapLibrary.pairFor(factory, tokenIn, path[1]);
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

            ISyncSwapPair pair = ISyncSwapPair(i == 0 ? initialPair : SyncSwapLibrary.pairFor(factory, input, output));
            uint amountInput;
            uint amountOutput;

            { // scope to avoid stack too deep errors
                (uint reserve0, uint reserve1, uint16 swapFee) = pair.getReservesAndParameters();
                (uint reserveIn, uint reserveOut) = input < output ? (reserve0, reserve1) : (reserve1, reserve0);
                amountInput = IERC20(input).balanceOf(address(pair)) - reserveIn;
                amountOutput = SyncSwapLibrary.getAmountOut(amountInput, reserveIn, reserveOut, swapFee);
            }

            address to = i < path.length - 2 ? SyncSwapLibrary.pairFor(factory, output, path[i + 2]) : _to;

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
    ) external override ensureNotExpired(deadline) {
        address tokenIn = path[0];
        address initialPair = SyncSwapLibrary.pairFor(factory, tokenIn, path[1]);
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
    ) external override payable ensureNotExpired(deadline) {
        address tokenIn = path[0];
        require(tokenIn == WETH, 'INVALID_PATH');

        uint amountIn = msg.value;
        IWETH(WETH).deposit{value: amountIn}();
        address initialPair = SyncSwapLibrary.pairFor(factory, tokenIn, path[1]);
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
    ) external override ensureNotExpired(deadline) {
        require(path[path.length - 1] == WETH, 'INVALID_PATH');

        address tokenIn = path[0];
        address initialPair = SyncSwapLibrary.pairFor(factory, tokenIn, path[1]);
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

    function quote(uint amountA, uint reserveA, uint reserveB) external pure override returns (uint amountB) {
        return SyncSwapLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external view override returns (uint amountOut) {
        return SyncSwapLibrary.getAmountOut(amountIn, reserveIn, reserveOut, ISyncSwapFactory(factory).swapFee());
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external view override returns (uint amountIn) {
        return SyncSwapLibrary.getAmountIn(amountOut, reserveIn, reserveOut, ISyncSwapFactory(factory).swapFee());
    }

    function getAmountsOut(uint amountIn, address[] calldata path) external view override returns (uint[] memory amounts) {
        return SyncSwapLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] calldata path) external view override returns (uint[] memory amounts) {
        return SyncSwapLibrary.getAmountsIn(factory, amountOut, path);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import '../../interfaces/protocol/core/ISyncSwapPair.sol';

import '../../libraries/protocol/SyncSwapLibrary.sol';
import '../../libraries/token/ERC20/utils/TransferHelper.sol';

abstract contract SyncSwapRouterInternal {

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
        (uint reserve0, uint reserve1) = ISyncSwapPair(pair).getReservesSimple();
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
        ISyncSwapPair(pair).transferFrom(msg.sender, pair, liquidity);
        (uint amount0, uint amount1) = ISyncSwapPair(pair).burn(to);

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
            address currentTo = i < path.length - 2 ? SyncSwapLibrary.pairFor(_factory, output, path[i + 2]) : to;

            // perfrom the swap, ingredient tokens have already transferred by the
            // last sub swap with `to` or its caller function.
            address pair = i == 0 ? initialPair : SyncSwapLibrary.pairFor(_factory, input, output); // use initial pair;
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
                nextPair = SyncSwapLibrary.pairFor(_factory, output, path[i + 2]); // cache `to` as `nextPair` for the next sub swap.

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
            ISyncSwapPair(pair).swapFor1(amountOut, to);
        } else {
            ISyncSwapPair(pair).swapFor0(amountOut, to);
        }
    }
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
 * @dev Interface for the balance functions from the ERC20 standard.
 */
interface IERC20Balance {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
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

import "./uniswap/IUniswapV2Factory.sol";

/// @dev SyncSwap factory interface with full Uniswap V2 compatibility
interface ISyncSwapFactory is IUniswapV2Factory {
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

import "./uniswap/IUniswapV2Pair.sol";

/// @dev SyncSwap pair interface with full Uniswap V2 compatibility
interface ISyncSwapPair is IUniswapV2Pair {
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

import '../../../ERC20/IERC20.sol';
import '../../../ERC20/IERC20Metadata.sol';
import '../../../ERC20/IERC20Permit.sol';

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

interface ISyncPSM {
    function FEE_PRECISION() external view returns (uint256);
    function swapFeeRate() external view returns (uint256);

    function getWithdrawFee(address account, address asset, uint256 amount) external view returns (uint256);
    function getWithdrawOut(address account, address asset, uint256 amount) external view returns (uint256);
    function getSwapFee(uint256 amountOut) external view returns (uint256 fee);
    function getSwapOut(address assetIn, address assetOut, uint256 amountIn) external view returns (uint256 amountOut);

    function deposit(address asset, uint256 assetAmount, address to) external;
    function withdraw(address asset, uint256 nativeAmount, address to) external returns (uint256 amountOut);
    function swap(address assetIn, address assetOut, uint256 amountIn, address to) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import './uniswap/IUniswapV2Router02.sol';

interface ISyncSwapRouter is IUniswapV2Router02 {
    function isPairIndexed(address account, address pair) external view returns (bool);
    function indexedPairs(address account, uint256) external view returns (address);
    function indexedPairsOf(address account) external view returns (address[] memory);
    function indexedPairsRange(address account, uint256 start, uint256 counts) external view returns (address[] memory);
    function indexedPairsLengthOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external view returns (address);
    function WETH() external view returns (address);

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
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external view returns (uint amountOut); // pure -> view
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external view returns (uint amountIn); // pure -> view
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: AGPL-3.0-or-later

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

// SPDX-License-Identifier: AGPL-3.0-or-later
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import '../utils/math/Math.sol';
import '../../interfaces/protocol/core/ISyncSwapPair.sol';
import '../../interfaces/protocol/core/ISyncSwapFactory.sol';

library SyncSwapLibrary {
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
        return ISyncSwapFactory(factory).getPair(tokenA, tokenB);
    }

    /**
     * @dev Fetches pair with given tokens, returns its reserves in the given order.
     */
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint112 reserveA, uint112 reserveB, uint16 swapFee) {
        address pair = pairFor(factory, tokenA, tokenB);
        if (pair != address(0)) {
            (uint112 reserve0, uint112 reserve1, uint16 _swapFee) = ISyncSwapPair(pair).getReservesAndParameters();
            (reserveA, reserveB) = tokenA < tokenB ? (reserve0, reserve1) : (reserve1, reserve0);
            swapFee = _swapFee;
        }
    }

    /**
     * @dev Fetches reserves with given pair in the given order.
     */
    function getReservesWithPair(address pair, address tokenA, address tokenB) internal view returns (uint112 reserveA, uint112 reserveB, uint16 swapFee) {
        (uint112 reserve0, uint112 reserve1, uint16 _swapFee) = ISyncSwapPair(pair).getReservesAndParameters();
        (reserveA, reserveB) = tokenA < tokenB ? (reserve0, reserve1) : (reserve1, reserve0);
        swapFee = _swapFee;
    }

    /**
     * @dev Fetches pair with given tokens, returns pair address and its reserves in the given order if exists. 
     */
    function getPairAndReserves(address factory, address tokenA, address tokenB) internal view returns (address pair, uint112 reserveA, uint112 reserveB, uint16 swapFee) {
        pair = pairFor(factory, tokenA, tokenB);
        if (pair != address(0)) { // return empty values if pair not exists
            (uint112 reserve0, uint112 reserve1, uint16 _swapFee) = ISyncSwapPair(pair).getReservesAndParameters();
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import '../../../interfaces/ERC20/IERC20Metadata.sol';
import '../../../interfaces/ERC20/IERC20Balance.sol';

/**
 * @dev A readonly (dummy) implementation of ERC20 standard.
 */
abstract contract ERC20Readonly is IERC20Metadata, IERC20Balance {
    /// @dev The name of token
    string public override name;

    /// @dev The symbol of token
    string public override symbol;

    /// @dev The decimals of token
    uint8 public override decimals;

    /// @dev The current total supply
    uint256 public _totalSupply;

    /// @dev The balances for accounts
    mapping (address => uint256) private _balances;

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /// @dev Set name, symbol and decimals for token
    function _setMetadata(string memory _name, string memory _symbol, uint8 _decimals) internal {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /// @dev Increase balance for `account`, will update `totalSupply` consequently
    function _increaseBalance(address account, uint256 value) internal {
        _totalSupply += value;
        _balances[account] += value;
    }

    /// @dev Decrease balance for `account`, will update `totalSupply` consequently
    function _decreaseBalance(address account, uint256 value) internal {
        _totalSupply -= value;
        _balances[account] -= value;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import '../../../../interfaces/ERC20/IERC20.sol';

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'SafeERC20::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'SafeERC20::transferFrom: transferFrom failed'
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x095ea7b3, spender, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'SafeERC20::safeApprove: approve failed'
        );
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

import '../../libraries/security/ReentrancyGuard.sol';
import '../../libraries/access/Ownable.sol';
import '../../interfaces/ERC20/IERC20.sol';

import '../../libraries/token/ERC20/ERC20Readonly.sol';
import '../../libraries/token/ERC20/utils/SafeERC20.sol';
import '../../interfaces/ERC20/IERC20Metadata.sol';

import '../../libraries/utils/math/Math.sol';

contract SyncSwapFarm is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
        CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @dev Precision for float numbers
    uint256 public constant PRECISION = 1e18;

    /// @dev Maximum allowed amount of reward tokens, to limit gas use
    uint256 public constant MAXIMUM_REWARD_TOKENS = 5;

    /// @dev Grace period between every enter time update.
    uint256 public constant ENTER_TIME_GRACE_PERIOD = 10 minutes;

    /*//////////////////////////////////////////////////////////////
        Pool Data
    //////////////////////////////////////////////////////////////*/

    /// @dev Share token to stake
    address public shareToken;

    /// @dev Withdraw cooldown in seconds (could be zero)
    uint256 public withdrawCooldown = 7 days;

    /// @dev Fee rate of early withdraw
    uint256 public earlyWithdrawFeeRate = 1e16; // 1%

    /// @dev Recipient of early withdraw fee
    address public feeRecipient; // zero address indicates not enabled

    /// @dev Amount of total staked share token in this pool
    uint256 public totalShare;

    /*//////////////////////////////////////////////////////////////
        Reward Token Data
    //////////////////////////////////////////////////////////////*/

    struct RewardTokenData {
        /// @dev Whether it is a reward token.
        bool isRewardToken;

        /// @dev Reward emissions per second (rate) of this reward tokem
        uint256 rewardPerSecond;

        /// @dev Start time of this reward emission (inclusive, applicable for reward)
        uint256 startTime;

        /// @dev End time of this reward emission (inclusive, applicable for reward)
        uint256 endTime;

        /// @dev Accumulated reward per share for this reward token
        uint256 accRewardPerShare; // INCREASE ONLY

        /// @dev Timestamp of last update
        uint256 lastUpdate;
    }

    /// @dev Data of reward tokens, support multiple reward tokens
    mapping(address => RewardTokenData) public rewardTokenData; // token -> data

    /// @dev Added reward tokens for this pool
    address[] public rewardTokens;

    /// @dev Helper to access length of reward tokens array
    function rewardTokensLength() public view returns (uint256) {
        return rewardTokens.length;
    }

    /*//////////////////////////////////////////////////////////////
        User Data
    //////////////////////////////////////////////////////////////*/

    /// @dev User enter time, useful when early withdraw fee is enabled
    mapping(address => uint256) public enterTime; // user -> enterTime

    /// @dev Amount of user staked share token
    mapping(address => uint256) public userShare; // user -> share

    struct UserRewardData {
        /// @dev Accrued rewards in this reward token available for claiming
        uint256 accruedRewards;

        /// @dev Reward debt per share for this reward token
        uint256 debtRewardPerShare;
    }

    /// @dev User data of each reward token
    mapping(address => mapping(address => UserRewardData)) public userRewardData; // token -> user -> data

    /*//////////////////////////////////////////////////////////////
        EVENTS
    //////////////////////////////////////////////////////////////*/

    event Stake(address indexed from, uint256 amount, address indexed onBehalf);
    event Withdraw(address indexed account, uint256 amount, address indexed to);
    event Harvest(address indexed account, address rewardToken, uint256 rewardAmount, address indexed to);

    event AddRewardToken(address indexed rewardToken);
    event SetRewardParams(address indexed rewardToken, uint256 rewardPerSecond, uint256 startTime, uint256 endTime);
    event UpdateRewardPerShare(address indexed rewardToken, uint256 lastUpdateTime, uint256 totalShare, uint256 accRewardPerShare);

    constructor(address _shareToken, address _feeRecipient) {
        require(_shareToken != address(0), "Invalid share token");
        shareToken = _shareToken;
        feeRecipient = _feeRecipient;
    }

    /*//////////////////////////////////////////////////////////////
        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Returns last time the reward is applicable, a time between start time and end time.
     */
    function _lastTimeRewardApplicable(RewardTokenData memory tokenData) internal view returns (uint256) {
        return Math.max(tokenData.startTime, Math.min(block.timestamp, tokenData.endTime));
    }

    /**
     * @dev Returns first time the reward is applicable, a time between start time and end time.
     */
    function _firstTimeRewardApplicable(RewardTokenData memory tokenData) internal pure returns (uint256) {
        return Math.min(tokenData.endTime, Math.max(tokenData.lastUpdate, tokenData.startTime));
    }

    /**
     * @dev Returns pending `rewardPerShare` for a reward.
     *
     * Pending `rewardPerShare` is accumulated `rewardPerShare` that has not been
     * write into stroage since last update.
     *
     * It will returns zero when:
     * - The token is not a reward (anymore).
     * - The reward emission rate is zero.
     * - The reward emission is not started or was ended.
     * - The elapsed time since last update is zero.
     * - There is no share token staked.
     */
    function _pendingRewardPerShare(RewardTokenData memory rewardData, uint256 _totalShare) internal view returns (uint256) {
        if (
            rewardData.rewardPerSecond == 0 ||
            rewardData.lastUpdate == block.timestamp ||
            _totalShare == 0
        ) {
            return 0;
        }

        uint256 lastTimeRewardApplicable = _lastTimeRewardApplicable(rewardData);
        uint256 firstTimeRewardApplicable = _firstTimeRewardApplicable(rewardData);
        if (lastTimeRewardApplicable <= firstTimeRewardApplicable) {
            return 0;
        }

        uint256 elapsedSeconds = lastTimeRewardApplicable - firstTimeRewardApplicable;
        uint256 pendingRewards = elapsedSeconds * rewardData.rewardPerSecond;
        uint256 pendingRewardPerShare = pendingRewards * PRECISION / _totalShare;

        // Revert if rounded to zero to prevent reward loss.
        require(pendingRewardPerShare != 0, "No pending reward to accumulate");
        return pendingRewardPerShare;
    }

    /**
     * @dev Returns latest `rewardPerShare` for given reward.
     *
     * Note that it may includes pending `rewardPerShare` that has not been written
     * into the storage and thus can be used to PREVIEW ONLY.
     */
    function _latestRewardPerShare(RewardTokenData memory rewardData, uint256 _totalShare) internal view returns (uint256) {
        return rewardData.accRewardPerShare + _pendingRewardPerShare(rewardData, _totalShare);
    }

    /**
     * @dev Returns pending rewards for given account and reward.
     */
    function _pendingRewards(uint256 rewardPerShare, uint256 debtRewardPerShare, uint256 _userShare) internal pure returns (uint256) {
        if (rewardPerShare > debtRewardPerShare) {
            return (rewardPerShare - debtRewardPerShare) * _userShare / PRECISION;
        }
        return 0;
    }

    /*//////////////////////////////////////////////////////////////
        VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Returns data for all reward tokens.
     */
    function allRewardTokenData() external view returns (RewardTokenData[] memory data) {
        uint256 _len = rewardTokensLength();
        data = new RewardTokenData[](_len);

        for (uint256 i = 0; i < _len; ) {
            data[i] = rewardTokenData[rewardTokens[i]];
            unchecked { i++; }
        }
    }

    /**
     * @dev Returns user data for all reward tokens.
     */
    function allUserRewardData(address account) external view returns (UserRewardData[] memory data) {
        uint256 _len = rewardTokensLength();
        data = new UserRewardData[](_len);

        for (uint256 i = 0; i < _len; ) {
            data[i] = userRewardData[rewardTokens[i]][account];
            unchecked { i++; }
        }
    }

    /**
     * @dev see {availableRewardOf}
     */
    function _availableRewardOf(address account, address token, uint256 _totalShare, uint256 _userShare) internal view returns (uint256) {
        UserRewardData memory user = userRewardData[token][account];
        uint256 pendingRewards = _userShare == 0 ? 0 : _pendingRewards(
            _latestRewardPerShare(rewardTokenData[token], _totalShare),
            user.debtRewardPerShare,
            _userShare
        );
        return user.accruedRewards + pendingRewards;
    }

    /**
     * @dev Returns how many rewards is claimable for the given account.
     *
     * This is useful for frontend to show available rewards.
     */
    function availableRewardOf(address account, address token) external view returns (uint256) {
        return _availableRewardOf(account, token, totalShare, userShare[account]);
    }

    /**
     * @dev see {availableRewardOf}.
     */
    function allAvailableRewardsOf(address account) external view returns (uint256[] memory availableRewards) {
        uint256 _len = rewardTokensLength();
        uint256 _totalShare = totalShare;
        uint256 _userShare = userShare[account];
        availableRewards = new uint256[](_len);

        for (uint256 i = 0; i < _len; ) {
            availableRewards[i] = _availableRewardOf(account, rewardTokens[i], _totalShare, _userShare);
            unchecked { i++; }
        }
    }

    /**
     * @dev Returns the first time which is possible to withdraw without fee.
     */
    function firstTimeFreeWithdrawOf(address account) external view returns (uint256) {
        if (feeRecipient == address(0)) {
            return block.timestamp;
        }

        uint256 sinceLastEnter = block.timestamp - enterTime[account];
        uint256 _withdrawCooldown = withdrawCooldown;
        uint256 remaining = sinceLastEnter < _withdrawCooldown ? withdrawCooldown - sinceLastEnter : 0;

        return block.timestamp + remaining;
    }

    /*//////////////////////////////////////////////////////////////
        Update Reward Per Share
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Updates `rewardPerShare` for given reward token with its `totalShare`.
     *
     * MUST update SINGLE reward token before made changes to:
     * - `rewardPerSecond`
     * - `startTime`
     * - `endTime`
     *
     * MUST update ALL reward tokens before made changes to:
     * - `totalShare`
     */
    function _updateRewardPerShare(address token, uint256 _totalShare) internal returns (uint256 updatedRewardPerShare) {
        RewardTokenData memory rewardData = rewardTokenData[token];

        uint256 pendingRewardPerShare = _pendingRewardPerShare(rewardData, _totalShare);
        updatedRewardPerShare = rewardData.accRewardPerShare + pendingRewardPerShare;

        if (pendingRewardPerShare != 0) {
            rewardTokenData[token].accRewardPerShare = updatedRewardPerShare;
        }

        rewardTokenData[token].lastUpdate = block.timestamp;
        emit UpdateRewardPerShare(token, rewardData.lastUpdate, _totalShare, updatedRewardPerShare);

        return updatedRewardPerShare;
    }

    /*//////////////////////////////////////////////////////////////
        Accrue Rewards
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Updates `accruedRewards` for given account and reward token.
     *
     * Note this will use accumulated `rewardPerShare` in the storage,
     * which does not includes the pending `rewardPerShare`.
     *
     * Should call {updateRewardPerShare} first to update `rewardPerShare`
     * to include pending `rewardPerShare`.
     *
     * MUST accrue ALL rewards before made changes to:
     * - `userShare`
     *
     * MUST update SINGLE reward token before made changes to:
     * - `rewardPerSecond`
     * - `startTime`
     * - `endTime`
     *
     * MUST update ALL reward tokens before made changes to:
     * - `totalShare`
     */
    function _accrueReward(address account, address token, uint256 _rewardPerShare, uint256 _userShare) internal {
        UserRewardData memory user = userRewardData[token][account];
        uint256 pendingRewards = _userShare == 0 ? 0 : _pendingRewards(
            _rewardPerShare,
            user.debtRewardPerShare,
            _userShare
        );

        if (pendingRewards != 0) {
            userRewardData[token][account].accruedRewards += pendingRewards;
        }
        userRewardData[token][account].debtRewardPerShare = _rewardPerShare;
    }

    /**
     * @dev Updates `rewardPerShare` for all reward tokens,
     * and `accruedRewards` for given account and all reward tokens.
     *
     * MUST accrue ALL rewards before made changes to:
     * - `userShare`
     *
     * MUST update SINGLE reward token before made changes to:
     * - `rewardPerSecond`
     * - `startTime`
     * - `endTime`
     *
     * MUST update ALL reward tokens before made changes to:
     * - `totalShare`
     */
    function _updateAndAccrueAllRewards(address account) internal {
        uint256 _len = rewardTokensLength();
        uint256 _totalShare = totalShare;
        uint256 _userShare = userShare[account];

        for (uint256 i = 0; i < _len; ) {
            address token = rewardTokens[i];
            uint256 _rewardPerShare = _updateRewardPerShare(token, _totalShare);
            _accrueReward(account, token, _rewardPerShare, _userShare);
            unchecked { i++; }
        }
    }

    /*//////////////////////////////////////////////////////////////
        Reward Management
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Set cooldown for early withdraw.
     */
    function setWithdrawCooldown(uint256 newCooldown) external onlyOwner {
        require(newCooldown != 0, "Invalid cooldown");
        withdrawCooldown = newCooldown;
    }

    /**
     * @dev Set fee rate for early withdraw. Cannot exceeds precision.
     */
    function setEarlyWithdrawFeeRate(uint256 newFeeRate) external onlyOwner {
        require(newFeeRate != 0 && newFeeRate <= PRECISION, "Invalid fee rate");
        earlyWithdrawFeeRate = newFeeRate;
    }

    /**
     * @dev Set recipient for early withdraw fee.
     *
     * The zero address indicates early withdraw fee is not enabled.
     */
    function setFeeRecipient(address newRecipient) external onlyOwner {
        feeRecipient = newRecipient;
    }

    /**
     * @dev Returns remaining rewards that expected be distributed from current time to end time.
     */
    function _remainingRewards(uint256 rewardPerSecond, uint256 startTime, uint256 endTime) internal view returns (uint256) {
        if (rewardPerSecond == 0 || startTime == 0 || endTime == 0) {
            return 0;
        }

        uint256 firstTimeRewardApplicable = Math.min(endTime, Math.max(block.timestamp, startTime));
        return (endTime - firstTimeRewardApplicable) * rewardPerSecond;
    }

    function _isRewardBalanceSufficient(address token, uint256 rewardPerSecond, uint256 startTime, uint256 endTime) internal view returns (bool) {
        uint256 rewardsRequire = _remainingRewards(rewardPerSecond, startTime, endTime);
        if (rewardsRequire == 0) {
            return true;
        }

        uint256 rewardTokenBalance = IERC20(token).balanceOf(address(this));
        uint256 rewardsBalance = token == shareToken ? rewardTokenBalance - totalShare : rewardTokenBalance;

        return rewardsBalance >= rewardsRequire;
    }

    /**
     * @dev Add a new reward token.
     *
     * Be careful to add a reward token because it's impossible to remove it!
     */
    function addRewardToken(address token) external onlyOwner {
        require(token != address(0), "Invalid reward token");
        require(!rewardTokenData[token].isRewardToken, "Token is already reward");
        require(rewardTokensLength() < MAXIMUM_REWARD_TOKENS, "Too many reward tokens");

        rewardTokens.push(token);
        rewardTokenData[token].isRewardToken = true;

        emit AddRewardToken(token);
    }

    /**
     * @dev Set reward params for given reward token.
     *
     * Requires there is sufficient balance to pay the rewards.
     */
    function setRewardParams(address token, uint256 newRewardPerSecond, uint256 newStartTime, uint256 newEndTime) external onlyOwner {
        RewardTokenData memory data = rewardTokenData[token];
        require(data.isRewardToken, "Token is not reward");
        require(newStartTime < newEndTime, "Start must earlier than end");

        // MUST update reward before made changes.
        _updateRewardPerShare(token, totalShare);

        // Configure reward emission rate
        rewardTokenData[token].rewardPerSecond = newRewardPerSecond;

        // Configure start time
        if (newStartTime != data.startTime) {
            require(newStartTime > block.timestamp, "Invalid start time");
            rewardTokenData[token].startTime = newStartTime;
        }

        // Configure End time
        if (newEndTime != data.endTime) {
            require(newEndTime > block.timestamp, "Invalid end time");
            rewardTokenData[token].endTime = newEndTime;
        }

        require(newStartTime != 0 && newEndTime != 0, "Reward time not set");
        require(_isRewardBalanceSufficient(token, newRewardPerSecond, newStartTime, newEndTime), "Insufficient reward balance");

        emit SetRewardParams(token, newRewardPerSecond, newStartTime, newEndTime);
    }

    /**
     * @dev Reclaim tokens that are not in use safely.
     */
    function reclaimToken(address token, address to) external onlyOwner {
        require(to != address(0), "Invalid to");

        uint256 amount = IERC20(token).balanceOf(address(this));

        RewardTokenData memory rewardData = rewardTokenData[token];
        // Remove remaining rewards from amount if it's a reward token.
        if (rewardData.isRewardToken) {
            amount -= _remainingRewards(
                rewardData.rewardPerSecond, rewardData.startTime, rewardData.endTime
            );
        }

        // Remove user funds from amount if it's share token.
        if (token == shareToken) {
            amount -= totalShare;
        }

        require(amount != 0, "No available token to reclaim");
        IERC20(token).safeTransfer(to, amount);
    }

    /**
     * @dev Transfer tokens other than user funds to recipient.
     *
     * Be careful when use this to transfer funds as it may break reward emissions!
     */
    function transferToken(address token, uint256 amount, address to) external onlyOwner {
        require(to != address(0), "Invalid to");

        if (token != shareToken) {
            IERC20(token).safeTransfer(to, amount);
        } else {
            uint256 maximum = IERC20(token).balanceOf(address(this)) - totalShare;
            uint256 spendable = Math.min(maximum, amount);
            require(spendable != 0, "No available token to transfer");
            IERC20(token).safeTransfer(to, spendable);
        }
    }

    /*//////////////////////////////////////////////////////////////
        Stake
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Updates enter time for given account based on weight of increased share.
     *
     * This is helpful for small share increases. For example, if user share
     * increased by 1%, it will adds only 1% of elapsed duration on his enter time.
     *
     * It won't update if less than `ENTER_TIME_GRACE_PERIOD` seconds since
     * last enter time update.
     *
     * It will use current time as enter time if:
     * - The user has never staked before.
     * - The new share is more than whole previous share.
     */
    function _updateEnterTimeWeighted(address account, uint256 newShare) internal {
        uint256 previousEnterTime = enterTime[account];

        if (previousEnterTime != 0) {
            uint256 sinceLastEnter = block.timestamp - previousEnterTime;
            if (sinceLastEnter < ENTER_TIME_GRACE_PERIOD) {
                return;
            }

            uint256 previousShare = userShare[account];
            if (previousShare != 0 && newShare < previousShare) {
                uint256 shareWeight = newShare * PRECISION / previousShare;
                uint256 durationWeighted = sinceLastEnter * shareWeight / PRECISION;
                enterTime[account] += durationWeighted;
                return;
            }
        }

        enterTime[account] = block.timestamp;
    }

    /**
     * @dev See {stake}.
     */
    function _stake(address from, uint256 amount, address onBehalf) internal {
        amount = _safeTransferFrom(shareToken, from, amount);

        if (feeRecipient != address(0)) {
            _updateEnterTimeWeighted(onBehalf, amount);
        }

        totalShare += amount;
        userShare[onBehalf] += amount;

        emit Stake(from, amount, onBehalf);
    }

    /**
     * @dev Stake share token in given amount.
     */
    function stake(uint256 amount, address onBehalf) external nonReentrant {
        require(amount != 0, "Cannot stake zero");

        // MUST update and accure ALL rewards because `totalShare` and `userShare` will changes.
        _updateAndAccrueAllRewards(onBehalf);
        _stake(msg.sender, amount, onBehalf);
    }

    /*//////////////////////////////////////////////////////////////
        Withdraw
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See {withdraw}.
     */
    function _withdraw(address account, address token, uint256 amount, address to) internal {
        require(to != address(0), "Invalid to");

        totalShare -= amount;
        userShare[account] -= amount;

        // Charge early withdraw fee if possible.
        address _feeRecipient = feeRecipient;
        if (_feeRecipient != address(0)) {
            uint256 sinceLastStake = block.timestamp - enterTime[account];
            // If user staked before fee enabling, `enterTime` will be zero
            // thus won't met the condition.
            if (sinceLastStake < withdrawCooldown) {
                uint256 fee = amount * earlyWithdrawFeeRate / PRECISION;
                if (fee != 0) {
                    amount -= fee;
                    IERC20(token).safeTransfer(_feeRecipient, fee);
                }
            }
        }

        IERC20(token).safeTransfer(to, amount);
        emit Withdraw(account, amount, to);
    }

    /**
     * @dev Withdraw staked share token in given amount.
     */
    function withdraw(uint256 amount, address to) external nonReentrant {
        require(amount != 0, "Cannot withdraw zero");

        // MUST update and accure ALL rewards because `totalShare` and `userShare` will changes.
        _updateAndAccrueAllRewards(msg.sender);
        _withdraw(msg.sender, shareToken, amount, to);
    }

    /**
     * @dev Withdraw all staked share token without accuring rewards. EMERGENCY ONLY.
     *
     * This will discard pending rewards since last accrual.
     */
    function emergencyWithdraw(address to) external nonReentrant {
        _withdraw(msg.sender, shareToken, userShare[msg.sender], to);
    }

    /*//////////////////////////////////////////////////////////////
        Harvest
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See {harvest}.
     */
    function _harvest(address account, address to) internal {
        require(to != address(0), "Invalid to");

        uint256 _len = rewardTokensLength();
        uint256 _totalShare = totalShare;
        uint256 _userShare = userShare[account];

        for (uint256 i = 0; i < _len; ) {
            address token = rewardTokens[i];
            uint256 _rewardPerShare = _updateRewardPerShare(token, _totalShare);
            _accrueReward(account, token, _rewardPerShare, _userShare);

            uint256 accruedRewards = userRewardData[token][account].accruedRewards;
            if (accruedRewards != 0) {
                userRewardData[token][account].accruedRewards = 0;
                IERC20(token).safeTransfer(to, accruedRewards);
                emit Harvest(account, token, accruedRewards, to);
            }

            unchecked { i++; }
        }
    }

    /**
     * @dev Update, accrue and send all rewards for given account.
     */
    function harvest(address account, address to) external nonReentrant {
        require(account == msg.sender || to == account, "No permission to set recipient");
        _harvest(account, to);
    }

    /**
     * @dev Harvest and withdraw staked share token in given amount.
     *
     * See {harvest} and {withdraw}.
     */
    function harvestAndWithdraw(uint256 amount, address to) external nonReentrant {
        require(amount != 0, "Cannot withdraw zero");

        _harvest(msg.sender, to);
        _withdraw(msg.sender, shareToken, amount, to);
    }

    /*//////////////////////////////////////////////////////////////
        MISC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Transfer given token from given address to current contract, supports fee-on-transfer.
     */
    function _safeTransferFrom(address token, address from, uint256 amount) internal returns (uint256) {
        uint256 before = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransferFrom(from, address(this), amount);
        return IERC20(token).balanceOf(address(this)) - before;
    }
}