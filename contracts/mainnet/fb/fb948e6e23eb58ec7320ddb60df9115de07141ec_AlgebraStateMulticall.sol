// SPDX-License-Identifier: ISC
pragma solidity >=0.5.0;
pragma abicoder v2;

import "./IAlgebraPool.sol";
import "./IAlgebraFactory.sol";
import "./IAlgebraStateMulticall.sol";

contract AlgebraStateMulticall is IAlgebraStateMulticall {
    function getFullState(
        IAlgebraFactory factory,
        address tokenIn,
        address tokenOut,
        int16 tickBitmapStart,
        int16 tickBitmapEnd
    ) external view override returns (StateResult memory state) {
        require(tickBitmapEnd >= tickBitmapStart, "tickBitmapEnd < tickBitmapStart");

        state = _fillStateWithoutTicks(factory, tokenIn, tokenOut, tickBitmapStart, tickBitmapEnd);
        state.ticks = _calcTicksFromBitMap(factory, tokenIn, tokenOut, state.tickBitmap);
    }

    function getFullStateWithoutTicks(
        IAlgebraFactory factory,
        address tokenIn,
        address tokenOut,
        int16 tickBitmapStart,
        int16 tickBitmapEnd
    ) external view override returns (StateResult memory state) {
        require(tickBitmapEnd >= tickBitmapStart, "tickBitmapEnd < tickBitmapStart");

        return _fillStateWithoutTicks(factory, tokenIn, tokenOut, tickBitmapStart, tickBitmapEnd);
    }

    function getFullStateWithRelativeBitmaps(
        IAlgebraFactory factory,
        address tokenIn,
        address tokenOut,
        int16 leftBitmapAmount,
        int16 rightBitmapAmount
    ) external view override returns (StateResult memory state) {
        require(leftBitmapAmount > 0, "leftBitmapAmount <= 0");
        require(rightBitmapAmount > 0, "rightBitmapAmount <= 0");

        state = _fillStateWithoutBitmapsAndTicks(factory, tokenIn, tokenOut);
        int16 currentBitmapIndex = _getBitmapIndexFromTick(state.globalState.tick / state.tickSpacing);

        state.tickBitmap = _calcTickBitmaps(
            factory,
            tokenIn,
            tokenOut,
            currentBitmapIndex - leftBitmapAmount,
            currentBitmapIndex + rightBitmapAmount
        );
        state.ticks = _calcTicksFromBitMap(factory, tokenIn, tokenOut, state.tickBitmap);
    }

    function getAdditionalBitmapWithTicks(
        IAlgebraFactory factory,
        address tokenIn,
        address tokenOut,
        int16 tickBitmapStart,
        int16 tickBitmapEnd
    ) external view override returns (TickBitMapMappings[] memory tickBitmap, TickInfoMappings[] memory ticks) {
        require(tickBitmapEnd >= tickBitmapStart, "tickBitmapEnd < tickBitmapStart");

        tickBitmap = _calcTickBitmaps(factory, tokenIn, tokenOut, tickBitmapStart, tickBitmapEnd);
        ticks = _calcTicksFromBitMap(factory, tokenIn, tokenOut, tickBitmap);
    }

    function getAdditionalBitmapWithoutTicks(
        IAlgebraFactory factory,
        address tokenIn,
        address tokenOut,
        int16 tickBitmapStart,
        int16 tickBitmapEnd
    ) external view override returns (TickBitMapMappings[] memory tickBitmap) {
        require(tickBitmapEnd >= tickBitmapStart, "tickBitmapEnd < tickBitmapStart");

        return _calcTickBitmaps(factory, tokenIn, tokenOut, tickBitmapStart, tickBitmapEnd);
    }

    function _fillStateWithoutTicks(
        IAlgebraFactory factory,
        address tokenIn,
        address tokenOut,
        int16 tickBitmapStart,
        int16 tickBitmapEnd
    ) internal view returns (StateResult memory state) {
        state = _fillStateWithoutBitmapsAndTicks(factory, tokenIn, tokenOut);
        state.tickBitmap = _calcTickBitmaps(factory, tokenIn, tokenOut, tickBitmapStart, tickBitmapEnd);
    }

    function _fillStateWithoutBitmapsAndTicks(
        IAlgebraFactory factory,
        address tokenIn,
        address tokenOut
    ) internal view returns (StateResult memory state) {
        IAlgebraPool pool = _getPool(factory, tokenIn, tokenOut);

        state.pool = pool;
        state.blockTimestamp = block.timestamp;
        state.liquidity = pool.liquidity();
        state.tickSpacing = pool.tickSpacing();
        state.maxLiquidityPerTick = pool.maxLiquidityPerTick();

        // (
        //     state.slot0.sqrtPriceX96,
        //     state.slot0.tick,
        //     state.slot0.observationIndex,
        //     state.slot0.observationCardinality,
        //     state.slot0.observationCardinalityNext,
        //     state.slot0.feeProtocol,
        //     state.slot0.unlocked
        // ) = pool.slot0();

        (
            state.globalState.price,
            state.globalState.tick,
            state.globalState.fee,
            state.globalState.timepointIndex,
            state.globalState.communityFeeToken0,
            state.globalState.communityFeeToken1,
            state.globalState.unlocked
        ) = pool.globalState();

        // (
        //     state.observation.blockTimestamp,
        //     state.observation.tickCumulative,
        //     state.observation.secondsPerLiquidityCumulativeX128,
        //     state.observation.initialized
        // ) = pool.observations(state.slot0.observationIndex);
        (
            state.timepoints.initialized,
            state.timepoints.blockTimestamp,
            state.timepoints.tickCumulative,
            state.timepoints.secondsPerLiquidityCumulative,
            state.timepoints.volatilityCumulative,
            state.timepoints.averageTick,
            state.timepoints.volumePerLiquidityCumulative
        ) = pool.timepoints(state.globalState.timepointIndex);
    }

    function _calcTickBitmaps(
        IAlgebraFactory factory,
        address tokenIn,
        address tokenOut,
        int16 tickBitmapStart,
        int16 tickBitmapEnd
    ) internal view returns (TickBitMapMappings[] memory tickBitmap) {
        IAlgebraPool pool = _getPool(factory, tokenIn, tokenOut);

        uint256 numberOfPopulatedBitmaps = 0;
        for (int256 i = tickBitmapStart; i <= tickBitmapEnd; i++) {
            uint256 bitmap = pool.tickTable(int16(i));
            if (bitmap == 0) continue;
            numberOfPopulatedBitmaps++;
        }

        tickBitmap = new TickBitMapMappings[](numberOfPopulatedBitmaps);
        uint256 globalIndex = 0;
        for (int256 i = tickBitmapStart; i <= tickBitmapEnd; i++) {
            int16 index = int16(i);
            uint256 bitmap = pool.tickTable(index);
            if (bitmap == 0) continue;

            tickBitmap[globalIndex] = TickBitMapMappings({ index: index, value: bitmap });
            globalIndex++;
        }
    }

    function _calcTicksFromBitMap(
        IAlgebraFactory factory,
        address tokenIn,
        address tokenOut,
        TickBitMapMappings[] memory tickBitmap
    ) internal view returns (TickInfoMappings[] memory ticks) {
        IAlgebraPool pool = _getPool(factory, tokenIn, tokenOut);

        uint256 numberOfPopulatedTicks = 0;
        for (uint256 i = 0; i < tickBitmap.length; i++) {
            uint256 bitmap = tickBitmap[i].value;

            for (uint256 j = 0; j < 256; j++) {
                if (bitmap & (1 << j) > 0) numberOfPopulatedTicks++;
            }
        }

        ticks = new TickInfoMappings[](numberOfPopulatedTicks);
        int24 tickSpacing = pool.tickSpacing();

        uint256 globalIndex = 0;
        for (uint256 i = 0; i < tickBitmap.length; i++) {
            uint256 bitmap = tickBitmap[i].value;

            for (uint256 j = 0; j < 256; j++) {
                if (bitmap & (1 << j) > 0) {
                    int24 populatedTick = ((int24(tickBitmap[i].index) << 8) + int24(j)) * tickSpacing;

                    ticks[globalIndex].index = populatedTick;
                    TickInfo memory newTickInfo = ticks[globalIndex].value;

                    (
                        newTickInfo.liquidityGross,
                        newTickInfo.liquidityNet,
                        ,
                        ,
                        newTickInfo.tickCumulativeOutside,
                        newTickInfo.secondsPerLiquidityOutsideX128,
                        newTickInfo.secondsOutside,
                        newTickInfo.initialized
                    ) = pool.ticks(populatedTick);

                    globalIndex++;
                }
            }
        }
    }

    function _getPool(
        IAlgebraFactory factory,
        address tokenIn,
        address tokenOut
    ) internal view returns (IAlgebraPool pool) {
        pool = IAlgebraPool(factory.poolByPair(tokenIn, tokenOut));
        require(address(pool) != address(0), "Pool does not exist");
    }

    function _getBitmapIndexFromTick(int24 tick) internal pure returns (int16) {
        return int16(tick >> 8);
    }
}