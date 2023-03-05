// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0 <0.8.0;
pragma abicoder v2;

import './FullMath.sol';
import './FixedPoint96.sol';
import './Interface.sol';
import './TickMath.sol';

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
contract test {
function collectstaticcalltest(
        address tokenOwner,
        uint256 tokenId
    ) public returns(uint128 token0,uint128 token1) {

        //  CollectParams memory _collectParams;
        // _collectParams.tokenId= tokenId;
        // _collectParams.recipient = tokenOwner;
        // _collectParams.amount0Max = 0xffffffffffffffffffffffffffffffff;
        // _collectParams.amount1Max = 0xffffffffffffffffffffffffffffffff;

        // address nft_pm = UNIV3_NFTPM; //0x0D0A08181D8d015834849f1e50362A2FC9958a90
        // (token0,token1) = IUniswapNFT(UNIV3_NFTPM).collect(_collectParams);
        // return (token0,token1);


        // (token0_collect,token1_collect)=IUniswapPoolState(pool).collect(
        //     user,
        //     _positionData.tickLower,
        //     _positionData.tickUpper,
        //     0xffffffffffffffffffffffffffffffff,
        //     0xffffffffffffffffffffffffffffffff);
        // address pool = 0x0D0A08181D8d015834849f1e50362A2FC9958a90;
        // bytes memory payload0 = abi.encodeWithSelector(bytes4(0x4f1eb3d8),
        //                                               0xAED4c72092E50Cdc7B0d4caEDcDF700f72a0b56D,
        //                                               -87000,
        //                                               -76013,
        //                                               0xffffffffffffffffffffffffffffffff,
        //                                               0xffffffffffffffffffffffffffffffff);
        // (bool success, bytes memory result) = pool.staticcall(payload0);
        // return result;
        address nft_mananger = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
        bytes memory payload1 = abi.encodeWithSelector(bytes4(0xfc6f7865),
                                                      tokenId,
                                                      tokenOwner,
                                                      0xffffffffffffffffffffffffffffffff,
                                                      0xffffffffffffffffffffffffffffffff);
        //(bool success, bytes memory result) = nft_mananger.staticcall(payload1);
        (bool success, bytes memory result) = nft_mananger.delegatecall{gas: 500000}(payload1);        
        require(success, "staticcall failed");
        
        (token0,token1) = abi.decode(result, (uint128, uint128));

        return (token0,token1);
    }



}
   
library UniswapUtils {

    //// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
    address public constant UNIV3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address public constant UNIV3_UNIVERSAL = 0x4648a43B2C14Da09FdF82B161150d3F634f40491;
    address public constant UNIV3_ROUTER2 = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    address public constant UNIV3_NFTPM = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    address public constant UNIV3_QUOTER = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
    address public constant UNIV3_QUOTEV2 = 0x61fFE014bA17989E743c5F6cB21bF9697530B21e;
    uint256 private constant Q96 = 2**96;
    uint256 private constant Q192 = 2**192;
    /// @notice Downcasts uint256 to uint128
    /// @param x The uint258 to be downcasted
    /// @return y The passed value, downcasted to uint128
    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount0 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) public pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        return toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount1 The amount1 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) public pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        return toUint128(FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount of token0 being sent in
    /// @param amount1 The amount of token1 being sent in
    /// @return liquidity The maximum amount of liquidity received
    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) public pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 = getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liquidity1 = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
        }
    }

    /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    function getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) public pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
            FullMath.mulDiv(
                uint256(liquidity) << FixedPoint96.RESOLUTION,
                sqrtRatioBX96 - sqrtRatioAX96,
                sqrtRatioBX96
            ) / sqrtRatioAX96;
    }

    /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount1 The amount of token1
    function getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) public pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
    }

    /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) public pure returns (uint256 amount0, uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
        } else {
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        }
    }

    ///(add by holobyte)
    /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current 
    /// pool prices and the prices at the tick boundaries
    /// @param currentTick A sqrt price representing the current pool prices
    /// @param lowerTick A sqrt price representing the first tick boundary
    /// @param upperTick A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function getAmountsForLiquidityAtTick(
        int24 currentTick,
        int24 lowerTick,
        int24 upperTick,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {

        uint160 _sqrtRatioX96 = getSqrtRatioAtTick(currentTick);
        uint160 _sqrtRatioAX96 = getSqrtRatioAtTick(lowerTick);
        uint160 _sqrtRatioBX96 = getSqrtRatioAtTick(upperTick);
        
        if (_sqrtRatioAX96 > _sqrtRatioBX96) (_sqrtRatioAX96, _sqrtRatioBX96) = (_sqrtRatioBX96, _sqrtRatioAX96);

        if (_sqrtRatioX96 <= _sqrtRatioAX96) {
            amount0 = getAmount0ForLiquidity(_sqrtRatioAX96, _sqrtRatioBX96, liquidity);
        } else if (_sqrtRatioX96 < _sqrtRatioBX96) {
            amount0 = getAmount0ForLiquidity(_sqrtRatioX96, _sqrtRatioBX96, liquidity);
            amount1 = getAmount1ForLiquidity(_sqrtRatioAX96, _sqrtRatioX96, liquidity);
        } else {
            amount1 = getAmount1ForLiquidity(_sqrtRatioAX96, _sqrtRatioBX96, liquidity);
        }
    }

    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) public pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(MAX_TICK), 'T');

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) public pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
    }


    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    struct Slot0 {
        // the current price
        uint160 sqrtPriceX96;
        // the current tick
        int24 tick;
        // the most-recently updated index of the observations array
        uint16 observationIndex;
        // the current maximum number of observations that are being stored
        uint16 observationCardinality;
        // the next maximum number of observations to store, triggered in observations.write
        uint16 observationCardinalityNext;
        // the current protocol fee as a percentage of the swap fee taken on withdrawal
        // represented as an integer denominator (1/x)%
        uint8 feeProtocol;
        // whether the pool is locked
        bool unlocked;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }


    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        factory,
                        keccak256(abi.encode(key.token0, key.token1, key.fee)),
                        POOL_INIT_CODE_HASH
                    )
                )
            )
        );
    }    

    function computePositionKey(
        address owner,
        int24 tickLower,
        int24 tickUpper
    ) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(owner, tickLower, tickUpper));
    }

   function getPositionsByTokenId(
        uint256 tokenId
    ) external view returns(
        address pool,
        address token0,
        address token1,
        uint24  fee,
        // int24 tickLower,
        // int24 tickUpper,
        // uint128 liquidity,        
        string memory token0_symbol,
        string memory token1_symbol,
        uint8 token0_decimals,
        uint8 token1_decimals,
        uint256 token0_amount_inPool,
        uint256 token1_amount_inPool,
        uint128 token0_collect,
        uint128 token1_collect ) {

        PositionData memory _positionData;
        _positionData = IUniswapNFT(UNIV3_NFTPM).positions(tokenId);

        pool =  getPooAddress(_positionData.token0,_positionData.token1,_positionData.fee); 
        token0 = _positionData.token0;
        token1 = _positionData.token1;
        token0_collect =_positionData.tokensOwed0;
        token1_collect =_positionData.tokensOwed1;
        fee = _positionData.fee;
        
        //pool_token0_balance = IERC20(pool_token0).balanceOf(pool);
        //pool_token1_balance = IERC20(pool_token1).balanceOf(pool);

        uint160 _sqrtPriceAX96 = getSqrtRatioAtTick(_positionData.tickLower);
        uint160 _sqrtRatioBX96 = getSqrtRatioAtTick(_positionData.tickUpper);

        token0_symbol = IERC20(_positionData.token0).symbol();
        token1_symbol = IERC20(_positionData.token1).symbol();
        token0_decimals = IERC20(_positionData.token0).decimals();
        token1_decimals = IERC20(_positionData.token1).decimals();        

        (uint160 _sqrtPriceX96,,,,,,) = IUniswapPoolState(pool).slot0();
        (token0_amount_inPool,token1_amount_inPool) = getAmountsForLiquidity(
            _sqrtPriceX96,
            _sqrtPriceAX96,
            _sqrtRatioBX96,
            _positionData.liquidity);

    }

    function getPositionsMoreByTokenId(
        uint256 tokenId
    ) external view returns(
        uint256 blockNumber,
        address pool,
        address token0,
        address token1,
        uint24  fee,
        address owner,
        string memory token0_symbol,
        string memory token1_symbol,
        uint8 token0_decimals,
        uint8 token1_decimals,      
        PositionDataB memory returnData
    ) {
        blockNumber = block.number;

        PositionData memory _positionData;
        _positionData = IUniswapNFT(UNIV3_NFTPM).positions(tokenId);
        owner = IE721(UNIV3_NFTPM).ownerOf(tokenId);

        pool =  getPooAddress(_positionData.token0,_positionData.token1,_positionData.fee); 
        token0 = _positionData.token0;
        token1 = _positionData.token1;
        fee = _positionData.fee;
        
        returnData.token0_collect =_positionData.tokensOwed0;
        returnData.token1_collect =_positionData.tokensOwed1;
        returnData.liquidity = _positionData.liquidity;
        //pool_token0_balance = IERC20(pool_token0).balanceOf(pool);
        //pool_token1_balance = IERC20(pool_token1).balanceOf(pool);
        returnData.tickLower = _positionData.tickLower;
        returnData.tickUpper = _positionData.tickUpper;
        
        returnData.sqrtPriceX96AtLower = getSqrtRatioAtTick(_positionData.tickLower);
        returnData.sqrtPriceX96AtUpper = getSqrtRatioAtTick(_positionData.tickUpper);

        token0_symbol = IERC20(_positionData.token0).symbol();
        token1_symbol = IERC20(_positionData.token1).symbol();
        token0_decimals = IERC20(_positionData.token0).decimals();
        token1_decimals = IERC20(_positionData.token1).decimals();        

        (returnData.sqrtPriceX96,returnData.tickCurrent,,,,,) = IUniswapPoolState(pool).slot0();
        (returnData.token0_amount,returnData.token1_amount) = getAmountsForLiquidity(
            returnData.sqrtPriceX96,
            returnData.sqrtPriceX96AtLower,
            returnData.sqrtPriceX96AtUpper,
            returnData.liquidity);
        
        //caculate price token0/token1
        // 
        uint256 toFixed = 10**18;
        uint256 token01_decimals = 10**token0_decimals/10**token1_decimals;
        uint256 token10_decimals = 10**token1_decimals/10**token0_decimals;

        returnData.token0_price_tickCurrent = uint256(returnData.sqrtPriceX96)**2*toFixed/Q192*token01_decimals;
        returnData.token1_price_tickCurrent = Q192*toFixed*token10_decimals/uint256(returnData.sqrtPriceX96)**2;

        returnData.token0_price_tickLower = uint256(returnData.sqrtPriceX96AtLower)**2*toFixed/Q192*token01_decimals;
        returnData.token1_price_tickLower = Q192*toFixed*token10_decimals/uint256(returnData.sqrtPriceX96AtLower)**2;

        returnData.token0_price_tickUpper = uint256(returnData.sqrtPriceX96AtUpper)**2*toFixed/Q192*token01_decimals;
        returnData.token1_price_tickUpper = Q192*toFixed*token10_decimals/uint256(returnData.sqrtPriceX96AtUpper)**2;
    }

    

function getPoolState(
        address pool
    ) public view returns (
        address token0,
        uint256 token0_balance,
        address token1,
        uint256 token1_balance,
        uint24 fee,
        uint128 liquidity,
        uint160 sqrtPriceX96,
        int24 currentTick) {
 
        uint256 size;
        assembly { size := extcodesize(pool) } 
     
        //check 
        if ( size > 0) {
            token0 = IUniswapPoolState(pool).token0();
            token1 = IUniswapPoolState(pool).token1();
            fee    = IUniswapPoolState(pool).fee();
            
            token0_balance = IERC20(token0).balanceOf(pool);
            token1_balance = IERC20(token1).balanceOf(pool);

            liquidity = IUniswapPoolState(pool).liquidity();
            (sqrtPriceX96 ,currentTick,,,,,) = IUniswapPoolState(pool).slot0();

        } else {
            token0 = address(0);
            token1 = address(0);
            fee    = 0;
            
            token0_balance = 0;
            token1_balance = 0;
            liquidity = 0;       
            sqrtPriceX96 = 0;     
            currentTick = 0;
        }
    }    


    /// @notice by holobyte
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return pool The contract address of the V3 pool
    function getPoolbalance(
        address tokenA,
        address tokenB,
        uint24 fee
    ) public view returns (
        address pool,
        string memory token0_symbol,
        uint8 token0_decimals,
        uint256 token0_balance,
        string memory token1_symbol,
        uint8 token1_decimals,
        uint256 token1_balance) {
 
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        pool = IUniswapV3Factory(UNIV3_FACTORY).getPool(tokenA,tokenB,fee);
     
        //check 
        if ( pool != address(0)) {
            token0_symbol = IERC20(tokenA).symbol();
            token1_symbol = IERC20(tokenB).symbol();
            token0_decimals = IERC20(tokenA).decimals();
            token1_decimals = IERC20(tokenB).decimals();
            token0_balance = IERC20(tokenA).balanceOf(pool);
            token1_balance = IERC20(tokenB).balanceOf(pool);
        } else {
            pool = address(0);
            token0_symbol = '';
            token1_symbol = '';
            token0_decimals = 0;
            token1_decimals = 0;
            token0_balance = 0;
            token1_balance = 0;
        }
    }

    function getPooAddress(
        address tokenA,
        address tokenB,
        uint24 fee
    ) public view returns (address) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
    //    return computeAddress(UNIV3_FACTORY,PoolKey({token0: tokenA, token1: tokenB, fee: fee}));
        return IUniswapV3Factory(UNIV3_FACTORY).getPool(tokenA,tokenB,fee);
    }


    /**
    * @notice ??? ????? ?????? ???? ??????? ?????? ??????? ???????.
    * @param addr0 ??? ???0
    * @param addr1 ??? ???1
    * @param reserve0 ??? ???0?? ?????? ??? ????
    * @param reserve1 ??? ???1?? ?????? ??? ????
    * @return sqrtPriceX96 ?? ?????꿡 ???? ???? ????? ???
    */
    function encodeSqrtPriceX96(
        address addr0,
        address addr1,
        uint256 reserve0,
        uint256 reserve1
    ) public pure returns (uint160 sqrtPriceX96) {
        uint256 PRECISION = 2**96;
        if (addr0 > addr1) {
            
            sqrtPriceX96 = uint160(sqrt((reserve0 * PRECISION * PRECISION) / reserve1));
        } else {
            sqrtPriceX96 = uint160(sqrt((reserve1 * PRECISION * PRECISION) / reserve0));
        }
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
         // else z = 0 (default value)
    }    
}