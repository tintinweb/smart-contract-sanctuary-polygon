/**
 *Submitted for verification at polygonscan.com on 2023-06-08
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;
pragma abicoder v2;
interface IAlgebraPoolState {
    function globalState()
    external
    view
    returns (
        uint160 price,
        int24 tick,
        uint16 fee,
        uint16 timepointIndex,
        uint8 communityFeeToken0,
        uint8 communityFeeToken1,
        bool unlocked
    );
    function tickTable(int16 wordPosition) external view returns (uint256);
    function liquidity() external view returns (uint128);
    function ticks(int24 tick)external view returns (
        uint128 liquidityTotal,
        int128 liquidityDelta,
        uint256 outerFeeGrowth0Token,
        uint256 outerFeeGrowth1Token,
        int56 outerTickCumulative,
        uint160 outerSecondsPerLiquidity,
        uint32 outerSecondsSpent,
        bool initialized
    );
}
library Constants {
    int24 internal constant TICK_SPACING = 60;
    int24 internal constant MIN_TICK = -887272;
    int24 internal constant MAX_TICK = -MIN_TICK;
}

contract MytradeDefiPoolQueryQick{

    /// @notice get position of single 1-bit
    /// @dev it is assumed that word contains exactly one 1-bit, otherwise the result will be incorrect
    /// @param word The word containing only one 1-bit
    function getSingleSignificantBit(uint256 word) internal pure returns (uint8 singleBitPos) {
        assembly {
            singleBitPos := iszero(and(word, 0x5555555555555555555555555555555555555555555555555555555555555555))
            singleBitPos := or(singleBitPos, shl(7, iszero(and(word, 0x00000000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))))
            singleBitPos := or(singleBitPos, shl(6, iszero(and(word, 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF))))
            singleBitPos := or(singleBitPos, shl(5, iszero(and(word, 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF))))
            singleBitPos := or(singleBitPos, shl(4, iszero(and(word, 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF))))
            singleBitPos := or(singleBitPos, shl(3, iszero(and(word, 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF))))
            singleBitPos := or(singleBitPos, shl(2, iszero(and(word, 0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F))))
            singleBitPos := or(singleBitPos, shl(1, iszero(and(word, 0x3333333333333333333333333333333333333333333333333333333333333333))))
        }
    }

    /// @notice get position of most significant 1-bit (leftmost)
    /// @dev it is assumed that before the call, a check will be made that the argument (word) is not equal to zero
    /// @param word The word containing at least one 1-bit
    function getMostSignificantBit(uint256 word) internal pure returns (uint8 mostBitPos) {
        assembly {
            word := or(word, shr(1, word))
            word := or(word, shr(2, word))
            word := or(word, shr(4, word))
            word := or(word, shr(8, word))
            word := or(word, shr(16, word))
            word := or(word, shr(32, word))
            word := or(word, shr(64, word))
            word := or(word, shr(128, word))
            word := sub(word, shr(1, word))
        }
        return (getSingleSignificantBit(word));
    }
    function nextTickInTheSameRowTrue(
        address poolAddr,
        int24 tick
    ) internal view returns (int24 nextTick, bool initialized) {
        {
            int24 tickSpacing = Constants.TICK_SPACING;
            // compress and round towards negative infinity if negative
            assembly {
                tick := sub(sdiv(tick, tickSpacing), and(slt(tick, 0), not(iszero(smod(tick, tickSpacing)))))
            }
        }

        // unpacking not made into a separate function for gas and contract size savings
        int16 rowNumber;
        uint8 bitNumber;
        assembly {
            bitNumber := and(tick, 0xFF)
            rowNumber := shr(8, tick)
        }

        uint256 _row = IAlgebraPoolState(poolAddr).tickTable(rowNumber) << (255 - bitNumber); // all the 1s at or to the right of the current bitNumber

        if (_row != 0) {
            tick -= int24(255 - getMostSignificantBit(_row));
            return (uncompressAndBoundTick(tick), true);
        } else {
            tick -= int24(bitNumber);
            return (uncompressAndBoundTick(tick), false);
        }
    }
    function nextTickInTheSameRowFalse(
        address poolAddr,
        int24 tick
    ) internal view returns (int24 nextTick, bool initialized) {
        {
            int24 tickSpacing = Constants.TICK_SPACING;
            // compress and round towards negative infinity if negative
            assembly {
                tick := sub(sdiv(tick, tickSpacing), and(slt(tick, 0), not(iszero(smod(tick, tickSpacing)))))
            }
        }
        // start from the word of the next tick, since the current tick state doesn't matter
        tick += 1;
        int16 rowNumber;
        uint8 bitNumber;
        assembly {
            bitNumber := and(tick, 0xFF)
            rowNumber := shr(8, tick)
        }

        // all the 1s at or to the left of the bitNumber
        uint256 _row = IAlgebraPoolState(poolAddr).tickTable(rowNumber) >> (bitNumber);

        if (_row != 0) {
            tick += int24(getSingleSignificantBit(-_row & _row)); // least significant bit
            return (uncompressAndBoundTick(tick), true);
        } else {
            tick += int24(255 - bitNumber);
            return (uncompressAndBoundTick(tick), false);
        }
    }

    function uncompressAndBoundTick(int24 tick) private pure returns (int24 boundedTick) {
        boundedTick = tick * Constants.TICK_SPACING;
        if (boundedTick < Constants.MIN_TICK) {
            boundedTick = Constants.MIN_TICK;
        } else if (boundedTick > Constants.MAX_TICK) {
            boundedTick = Constants.MAX_TICK;
        }
    }
    function getSwapSigleFalse(
        address poolAddr,
        uint stepLength
    ) public view returns (bytes memory data ) {
        (
        uint160 price,
        int24 tick,
        uint16 fee,,,,
        )=IAlgebraPoolState(poolAddr).globalState();
        uint128 liquidity=IAlgebraPoolState(poolAddr).liquidity();
        data=abi.encodePacked(price,fee,liquidity);
        (int24 tickNext,bool initialized)=nextTickInTheSameRowFalse(poolAddr,tick);
        int128 liquidityDelta;
        if(initialized){
            (,liquidityDelta,,,,,,)=IAlgebraPoolState(poolAddr).ticks(tickNext);
        }
        data=abi.encodePacked(data,tickNext,liquidityDelta);
        for (uint index;index<stepLength;++index) {
            tick=tickNext;
            (tickNext,initialized)=nextTickInTheSameRowFalse(poolAddr,tick);
            if(tickNext==tick){
                break;
            }
            if(initialized){
                (,liquidityDelta,,,,,,)=IAlgebraPoolState(poolAddr).ticks(tickNext);
            }else{
                liquidityDelta=0;
            }
            data=abi.encodePacked(data,tickNext,liquidityDelta);
        }
    }
    function getSwapSigleFalse(
        address poolAddr,
        int24 tickNext,
        uint stepLength
    ) public view returns (bytes memory data ) {
        int24 tick;
        bool initialized;
        int128 liquidityDelta;
        for (uint index;index<stepLength;++index) {
            tick=tickNext;
            (tickNext,initialized)=nextTickInTheSameRowFalse(poolAddr,tick);
            if(tickNext==tick){
                break;
            }
            if(initialized){
                (,liquidityDelta,,,,,,)=IAlgebraPoolState(poolAddr).ticks(tickNext);
            }else{
                liquidityDelta=0;
            }
            data=abi.encodePacked(data,tickNext,liquidityDelta);
        }
    }
    function getSwapSigleTrue(
        address poolAddr,
        uint stepLength
    ) public view returns (bytes memory data ) {
        (
        uint160 price,
        int24 tick,
        uint16 fee,,,,
        )=IAlgebraPoolState(poolAddr).globalState();
        uint128 liquidity=IAlgebraPoolState(poolAddr).liquidity();
        data=abi.encodePacked(price,fee,liquidity);
        (int24 tickNext,bool initialized)=nextTickInTheSameRowTrue(poolAddr,tick);
        int128 liquidityDelta;
        if(initialized){
            (,liquidityDelta,,,,,,)=IAlgebraPoolState(poolAddr).ticks(tickNext);
        }
        data=abi.encodePacked(data,tickNext,liquidityDelta);
        for (uint index;index<stepLength;++index) {
            tick=tickNext-1;
            (tickNext,initialized)=nextTickInTheSameRowTrue(poolAddr,tick);
            if(tickNext==tick-1){
                break;
            }
            if(initialized){
                (,liquidityDelta,,,,,,)=IAlgebraPoolState(poolAddr).ticks(tickNext);
            }else{
                liquidityDelta=0;
            }
            data=abi.encodePacked(data,tickNext,liquidityDelta);
        }
    }
    function getSwapSigleTrue(
        address poolAddr,
        int24 tickNext,
        uint stepLength
    ) public view returns (bytes memory data ) {
        int24 tick;
        bool initialized;
        int128 liquidityDelta;
        for (uint index;index<stepLength;++index) {
            tick=tickNext-1;
            (tickNext,initialized)=nextTickInTheSameRowTrue(poolAddr,tick);
            if(tickNext==tick-1){
                break;
            }
            if(initialized){
                (,liquidityDelta,,,,,,)=IAlgebraPoolState(poolAddr).ticks(tickNext);
            }else{
                liquidityDelta=0;
            }
            data=abi.encodePacked(data,tickNext,liquidityDelta);
        }
    }
    function getSwapSigleTrues(
        address[] memory pools,
        uint[] memory stepLengths
    ) public view returns (bytes[] memory datas ) {
        uint len=pools.length;
        datas=new bytes[](len);
        for(uint i;i<len;++i){
            datas[i]=getSwapSigleTrue(pools[i],stepLengths[i]);
        }
    }
    function getSwapSigleFalses(
        address[] memory pools,
        uint[] memory stepLengths
    ) public view returns (bytes[] memory datas ) {
        uint len=pools.length;
        datas=new bytes[](len);
        for(uint i;i<len;++i){
            datas[i]=getSwapSigleFalse(pools[i],stepLengths[i]);
        }
    }
}