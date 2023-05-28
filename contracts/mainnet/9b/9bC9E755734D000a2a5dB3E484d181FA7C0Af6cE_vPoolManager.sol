// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.18;

import './types.sol';
import './libraries/vSwapLibrary.sol';
import './libraries/PoolAddress.sol';
import './interfaces/IvPairFactory.sol';
import './interfaces/IvPair.sol';
import './interfaces/IvPoolManager.sol';

contract vPoolManager is IvPoolManager {
    struct VBalancesWithBlock {
        uint112 balance0;
        uint112 balance1;
        uint32 blockLastUpdated;
    }

    mapping(address => mapping(address => VBalancesWithBlock)) vPoolsBalancesCache;

    address public immutable pairFactory;

    constructor(address _pairFactory) {
        pairFactory = _pairFactory;
    }

    function getVirtualPool(
        address jkPair,
        address ikPair
    ) public view override returns (VirtualPoolModel memory vPool) {
        VBalancesWithBlock memory vBalancesWithBlock = vPoolsBalancesCache[
            jkPair
        ][ikPair];
        vPool = vSwapLibrary.getVirtualPool(jkPair, ikPair);
        if (block.number == vBalancesWithBlock.blockLastUpdated) {
            (vPool.balance0, vPool.balance1) = (
                vBalancesWithBlock.balance0,
                vBalancesWithBlock.balance1
            );
            _reduceBalances(vPool);
        }
    }

    function getVirtualPools(
        address token0,
        address token1
    ) external view override returns (VirtualPoolModel[] memory vPools) {
        uint256 allPairsLength = IvPairFactory(pairFactory).allPairsLength();
        uint256 vPoolsNumber;
        address jk0;
        address jk1;
        address jkPair;
        for (uint256 i = 0; i < allPairsLength; ++i) {
            jkPair = IvPairFactory(pairFactory).allPairs(i);
            (jk0, jk1) = IvPair(jkPair).getTokens();
            if (
                (jk0 == token1 || jk1 == token1) &&
                jk0 != token0 &&
                jk1 != token0 &&
                IvPair(jkPair).allowListMap(token0) &&
                IvPairFactory(pairFactory).pairs(
                    token0,
                    jk0 == token1 ? jk1 : jk0
                ) !=
                address(0)
            ) {
                ++vPoolsNumber;
            }
        }
        vPools = new VirtualPoolModel[](vPoolsNumber);
        address ikPair;
        for (uint256 i = 0; i < allPairsLength; ++i) {
            jkPair = IvPairFactory(pairFactory).allPairs(i);
            (jk0, jk1) = IvPair(jkPair).getTokens();
            if (
                (jk0 == token1 || jk1 == token1) &&
                jk0 != token0 &&
                jk1 != token0 &&
                IvPair(jkPair).allowListMap(token0)
            ) {
                ikPair = IvPairFactory(pairFactory).pairs(
                    token0,
                    jk0 == token1 ? jk1 : jk0
                );
                if (ikPair != address(0)) {
                    vPools[--vPoolsNumber] = getVirtualPool(jkPair, ikPair);
                }
            }
        }
    }

    function updateVirtualPoolBalances(
        address jkPair,
        address ikPair,
        uint256 balance0,
        uint256 balance1
    ) external override {
        (address token0, address token1) = IvPair(msg.sender).getTokens();
        require(
            msg.sender ==
                PoolAddress.computeAddress(pairFactory, token0, token1),
            'Only pools'
        );
        vPoolsBalancesCache[jkPair][ikPair] = VBalancesWithBlock(
            uint112(balance0),
            uint112(balance1),
            uint32(block.number)
        );
    }

    function _reduceBalances(VirtualPoolModel memory vPool) private view {
        (uint256 ikBalance0, uint256 ikBalance1) = IvPair(vPool.ikPair)
            .getBalances();

        if (vPool.token0 == IvPair(vPool.ikPair).token1())
            (ikBalance0, ikBalance1) = (ikBalance1, ikBalance0);

        (uint256 jkBalance0, uint256 jkBalance1) = IvPair(vPool.jkPair)
            .getBalances();

        if (vPool.token1 == IvPair(vPool.jkPair).token1())
            (jkBalance0, jkBalance1) = (jkBalance1, jkBalance0);

        // Make sure vPool balances are less or equal than real pool balances
        if (vPool.balance0 >= ikBalance0) {
            vPool.balance1 = (vPool.balance1 * ikBalance0) / vPool.balance0;
            vPool.balance0 = ikBalance0;
        }
        if (vPool.balance1 >= jkBalance0) {
            vPool.balance0 = (vPool.balance0 * jkBalance0) / vPool.balance1;
            vPool.balance1 = jkBalance0;
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.18;

struct MaxTradeAmountParams {
    uint256 fee;
    uint256 balance0;
    uint256 balance1;
    uint256 vBalance0;
    uint256 vBalance1;
    uint256 reserveRatioFactor;
    uint256 priceFeeFactor;
    uint256 maxReserveRatio;
    uint256 reserves;
    uint256 reservesBaseValueSum;
}

struct VirtualPoolModel {
    uint24 fee;
    address token0;
    address token1;
    uint256 balance0;
    uint256 balance1;
    address commonToken;
    address jkPair;
    address ikPair;
}

struct VirtualPoolTokens {
    address jk0;
    address jk1;
    address ik0;
    address ik1;
}

struct ExchangeReserveCallbackParams {
    address jkPair1;
    address ikPair1;
    address jkPair2;
    address ikPair2;
    address caller;
    uint256 flashAmountOut;
}

struct SwapCallbackData {
    address caller;
    uint256 tokenInMax;
    uint ETHValue;
    address jkPool;
}

struct PoolCreationDefaults {
    address factory;
    address token0;
    address token1;
    uint16 fee;
    uint16 vFee;
    uint24 maxAllowListCount;
    uint256 maxReserveRatio;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.18;

import '@openzeppelin/contracts/utils/math/Math.sol';
import '@openzeppelin/contracts/utils/math/SafeCast.sol';
import '../types.sol';
import '../interfaces/IvPair.sol';

library vSwapLibrary {
    uint24 internal constant PRICE_FEE_FACTOR = 10 ** 3;

    //find common token and assign to ikToken1 and jkToken1
    function findCommonToken(
        address ikToken0,
        address ikToken1,
        address jkToken0,
        address jkToken1
    ) internal pure returns (VirtualPoolTokens memory vPoolTokens) {
        (
            vPoolTokens.ik0,
            vPoolTokens.ik1,
            vPoolTokens.jk0,
            vPoolTokens.jk1
        ) = (ikToken0 == jkToken0)
            ? (ikToken1, ikToken0, jkToken1, jkToken0)
            : (ikToken0 == jkToken1)
            ? (ikToken1, ikToken0, jkToken0, jkToken1)
            : (ikToken1 == jkToken0)
            ? (ikToken0, ikToken1, jkToken1, jkToken0)
            : (ikToken0, ikToken1, jkToken0, jkToken1); //default
    }

    function calculateVPool(
        uint256 ikTokenABalance,
        uint256 ikTokenBBalance,
        uint256 jkTokenABalance,
        uint256 jkTokenBBalance
    ) internal pure returns (VirtualPoolModel memory vPool) {
        vPool.balance0 =
            (ikTokenABalance * Math.min(ikTokenBBalance, jkTokenBBalance)) /
            Math.max(ikTokenBBalance, 1);

        vPool.balance1 =
            (jkTokenABalance * Math.min(ikTokenBBalance, jkTokenBBalance)) /
            Math.max(jkTokenBBalance, 1);
    }

    function getAmountIn(
        uint256 amountOut,
        uint256 pairBalanceIn,
        uint256 pairBalanceOut,
        uint256 fee
    ) internal pure returns (uint256 amountIn) {
        uint256 numerator = (pairBalanceIn * amountOut) * PRICE_FEE_FACTOR;
        uint256 denominator = (pairBalanceOut - amountOut) * fee;
        amountIn = (numerator / denominator) + 1;
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 pairBalanceIn,
        uint256 pairBalanceOut,
        uint256 fee
    ) internal pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn * fee;
        uint256 numerator = amountInWithFee * pairBalanceOut;
        uint256 denominator = (pairBalanceIn * PRICE_FEE_FACTOR) +
            amountInWithFee;
        amountOut = numerator / denominator;
    }

    function quote(
        uint256 amountA,
        uint256 balanceA,
        uint256 balanceB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, 'VSWAP: INSUFFICIENT_AMOUNT');
        require(balanceA > 0 && balanceB > 0, 'VSWAP: INSUFFICIENT_LIQUIDITY');
        amountB = (amountA * balanceB) / balanceA;
    }

    function sortBalances(
        address tokenIn,
        address baseToken,
        uint256 pairBalance0,
        uint256 pairBalance1
    ) internal pure returns (uint256 _balance0, uint256 _balance1) {
        (_balance0, _balance1) = baseToken == tokenIn
            ? (pairBalance0, pairBalance1)
            : (pairBalance1, pairBalance0);
    }

    function getVirtualPool(
        address jkPair,
        address ikPair
    ) internal view returns (VirtualPoolModel memory vPool) {
        (address jk0, address jk1) = IvPair(jkPair).getTokens();
        (address ik0, address ik1) = IvPair(ikPair).getTokens();

        VirtualPoolTokens memory vPoolTokens = findCommonToken(
            ik0,
            ik1,
            jk0,
            jk1
        );

        require(
            (vPoolTokens.ik0 != vPoolTokens.jk0) &&
                (vPoolTokens.ik1 == vPoolTokens.jk1),
            'VSWAP: INVALID_VPOOL'
        );

        (uint256 ikBalance0, uint256 ikBalance1, ) = IvPair(ikPair)
            .getLastBalances();

        (uint256 jkBalance0, uint256 jkBalance1) = IvPair(jkPair).getBalances();

        vPool = calculateVPool(
            vPoolTokens.ik0 == ik0 ? ikBalance0 : ikBalance1,
            vPoolTokens.ik0 == ik0 ? ikBalance1 : ikBalance0,
            vPoolTokens.jk0 == jk0 ? jkBalance0 : jkBalance1,
            vPoolTokens.jk0 == jk0 ? jkBalance1 : jkBalance0
        );

        vPool.token0 = vPoolTokens.ik0;
        vPool.token1 = vPoolTokens.jk0;
        vPool.commonToken = vPoolTokens.ik1;

        vPool.fee = IvPair(jkPair).vFee();

        vPool.jkPair = jkPair;
        vPool.ikPair = ikPair;
    }

    /** @dev The function is used to calculate maximum virtual trade amount for
     * swapReserveToNative. The maximum amount that can be traded is such that
     * after the swap reserveRatio will be equal to maxReserveRatio:
     *
     * (reserveBaseValueSum + newReserveBaseValue(vPool.token0)) * reserveRatioFactor / (2 * balance0) = maxReserveRatio,
     * where balance0 is the balance of token0 after the swap (i.e. oldBalance0 + amountOut),
     *       reserveBaseValueSum is SUM(reserveBaseValue[i]) without reserveBaseValue(vPool.token0)
     *       newReserveBaseValue(vPool.token0) is reserveBaseValue(vPool.token0) after the swap
     *
     * amountOut can be expressed through amountIn:
     * amountOut = (amountIn * fee * vBalance1) / (amountIn * fee + vBalance0 * priceFeeFactor)
     *
     * reserveBaseValue(vPool.token0) can be expessed as:
     * if vPool.token1 == token0:
     *     reserveBaseValue(vPool.token0) = reserves[vPool.token0] * vBalance1 / vBalance0
     * else:
     *     reserveBaseValue(vPool.token0) = (reserves[vPool.token0] * vBalance1 * balance0) / (vBalance0 * balance1)
     *
     * Given all that we have two equations for finding maxAmountIn:
     * if vPool.token1 == token0:
     *     Ax^2 + Bx + C = 0,
     *     where A = fee * reserveRatioFactor * vBalance1,
     *           B = vBalance0 * (-2 * balance0 * fee * maxReserveRatio + vBalance1 *
     *              (2 * fee * maxReserveRatio + priceFeeFactor * reserveRatioFactor) +
     *              fee * reserveRatioFactor * reservesBaseValueSum) +
     *              fee * reserves * reserveRatioFactor * vBalance1,
     *           C = -priceFeeFactor * balance0 * (2 * balance0 * maxReserveRatio * vBalance0 -
     *              reserveRatioFactor * (reserves * vBalance1 + reservesBaseValueSum * vBalance0));
     * if vPool.token1 == token1:
     *     x = balance1 * vBalance0 * (2 * balance0 * maxReserveRatio - reserveRatioFactor * reservesBaseValueSum) /
     *          (balance0 * reserveRatioFactor * vBalance1)
     *
     * In the first case, we solve quadratic equation using Newton method.
     */
    function getMaxVirtualTradeAmountRtoN(
        VirtualPoolModel memory vPool
    ) internal view returns (uint256) {
        // The function works if and only if the following constraints are
        // satisfied:
        //      1. all balances are positive and less than or equal to 10^32
        //      2. reserves are non-negative and less than or equal to 10^32
        //      3. 0 < vBalance1 <= balance0 (or balance1 depending on trade)
        //      4. priceFeeFactor == 10^3
        //      5. reserveRatioFactor == 10^5
        //      6. 0 < fee <= priceFeeFactor
        //      7. 0 < maxReserveRatio <= reserveRatioFactor
        //      8. reserveBaseValueSum <= 2 * balance0 * maxReserveRatio (see
        //          reserve ratio formula in vPair.calculateReserveRatio())
        MaxTradeAmountParams memory params;

        params.fee = uint256(vPool.fee);
        params.balance0 = IvPair(vPool.jkPair).pairBalance0();
        params.balance1 = IvPair(vPool.jkPair).pairBalance1();
        params.vBalance0 = vPool.balance0;
        params.vBalance1 = vPool.balance1;
        params.reserveRatioFactor = IvPair(vPool.jkPair).reserveRatioFactor();
        params.priceFeeFactor = uint256(PRICE_FEE_FACTOR);
        params.maxReserveRatio = IvPair(vPool.jkPair).maxReserveRatio();
        params.reserves = IvPair(vPool.jkPair).reserves(vPool.token0);
        params.reservesBaseValueSum =
            IvPair(vPool.jkPair).reservesBaseValueSum() -
            IvPair(vPool.jkPair).reservesBaseValue(vPool.token0);

        require(
            params.balance0 > 0 && params.balance0 <= 10 ** 32,
            'invalid balance0'
        );
        require(
            params.balance1 > 0 && params.balance1 <= 10 ** 32,
            'invalid balance1'
        );
        require(
            params.vBalance0 > 0 && params.vBalance0 <= 10 ** 32,
            'invalid vBalance0'
        );
        require(
            params.vBalance1 > 0 && params.vBalance1 <= 10 ** 32,
            'invalid vBalance1'
        );
        require(params.priceFeeFactor == 10 ** 3, 'invalid priceFeeFactor');
        require(
            params.reserveRatioFactor == 10 ** 5,
            'invalid reserveRatioFactor'
        );
        require(
            params.fee > 0 && params.fee <= params.priceFeeFactor,
            'invalid fee'
        );
        require(
            params.maxReserveRatio > 0 &&
                params.maxReserveRatio <= params.reserveRatioFactor,
            'invalid maxReserveRatio'
        );

        // reserves are full, the answer is 0
        if (
            params.reservesBaseValueSum >
            2 * params.balance0 * params.maxReserveRatio
        ) return 0;

        int256 maxAmountIn;
        if (IvPair(vPool.jkPair).token0() == vPool.token1) {
            require(params.vBalance1 <= params.balance0, 'invalid vBalance1');
            unchecked {
                // a = R * v1 <= 10^5 * v1 = 10^5 * v1 <= 10^37
                uint256 a = params.vBalance1 * params.reserveRatioFactor;
                // b = v0 * (-2 * b0 * M + v1 * (2 * M + R * F / f) + R * s) + r * R * v1 <=
                //  <= v0 * (-2 * b0 * M + b0 * (2 * M + 10^8) + 10^5 * s) + 10^5 * r * v1 =
                //   = v0 * (10^8 * b0 + 10^5 * s) + 10^5 * r * v1 =
                //   = 10^5 * (v0 * (10^3 * b0 + s) + r * v1) <=
                //  <= 10^5 * (v0 * (10^3 * b0 + 2 * b0 * M) + r * v1) <=
                //  <= 10^5 * (v0 * (10^3 * b0 + 2 * 10^5 * b0) + r * v1) =
                //   = 10^5 * (v0 * b0 * (2 * 10^5 + 10^3) + r * v1) <=
                //  <= 10^5 * (10^64 * 2 * 10^5 + 10^64) <= 2 * 10^74
                int256 b = int256(params.vBalance0) *
                    (-2 *
                        int256(params.balance0 * params.maxReserveRatio) +
                        int256(
                            params.vBalance1 *
                                (2 *
                                    params.maxReserveRatio +
                                    (params.priceFeeFactor *
                                        params.reserveRatioFactor) /
                                    params.fee) +
                                params.reserveRatioFactor *
                                params.reservesBaseValueSum
                        )) +
                    int256(
                        params.reserves *
                            params.reserveRatioFactor *
                            params.vBalance1
                    );
                // we split C into c1 * c2 to fit in uint256
                // c1 = F * v0 / f <= 10^3 * v0 <= 10^35
                uint256 c1 = (params.priceFeeFactor * params.vBalance0) /
                    params.fee;
                // c2 = 2 * b0 * M * v0 - R * (r * v1 + s * v0) <=
                //   <= [r and s can be zero] <=
                //   <= 2 * 10^5 * b0 * v0 - 0 <= 2 * 10^69
                //
                // -c2 = R * (r * v1 + s * v0) - 2 * b0 * M * v0 <=
                //    <= 10^5 * (r * v1 + 2 * b0 * M * v0) - 2 * b0 * M * v0 =
                //     = 10^5 * r * v1 + 2 * b0 * M * v0 * (10^5 - 1) <=
                //    <= 10^5 * 10^32 * 10^32 + 2 * 10^32 * 10^5 * 10^32 * 10^5 <=
                //    <= 10^69 + 2 * 10^74 <= 2 * 10^74
                //
                // |c2| <= 2 * 10^74
                int256 c2 = 2 *
                    int256(
                        params.balance0 *
                            params.maxReserveRatio *
                            params.vBalance0
                    ) -
                    int256(
                        params.reserveRatioFactor *
                            (params.reserves *
                                params.vBalance1 +
                                params.reservesBaseValueSum *
                                params.vBalance0)
                    );

                (bool negativeC, uint256 uc2) = (
                    c2 < 0 ? (false, uint256(-c2)) : (true, uint256(c2))
                );

                // according to Newton's method:
                // x_{n+1} = x_n - f(x_n) / f'(x_n) =
                //         = x_n - (Ax_n^2 + Bx_n + c1 * c2) / (2Ax_n + B) =
                //         = (2Ax_n^2 + Bx_n - Ax_n^2 - Bx_n - c1 * c2) / (2Ax_n + B) =
                //         = (Ax_n^2 - c1 * c2) / (2Ax_n + B) =
                //         = Ax_n^2 / (2Ax_n + B) - c1 * c2 / (2Ax_n + B)
                // initial approximation: maxAmountIn always <= vb0
                maxAmountIn = int256(params.vBalance0);
                // derivative = 2 * a * x + b =
                //    = 2 * R * f * v1 * x + v0 * (-2 * b0 * f * M + v1 * (2 * f * M + R * F) + f * R * s) + f * r * R * v1 <=
                //   <= 2 * 10^40 * 10^32 + 2 * 10^76 <= 2 * 10^76
                int256 derivative = int256(2 * a) * maxAmountIn + b;

                (bool negativeDerivative, uint256 uDerivative) = (
                    derivative < 0
                        ? (true, uint256(-derivative))
                        : (false, uint256(derivative))
                );

                // maxAmountIn * maxAmountIn <= vb0 * vb0 <= 10^64
                maxAmountIn = (
                    negativeC
                        ? SafeCast.toInt256(
                            Math.mulDiv(
                                a,
                                uint256(maxAmountIn * maxAmountIn),
                                uDerivative
                            )
                        ) + SafeCast.toInt256(Math.mulDiv(c1, uc2, uDerivative))
                        : SafeCast.toInt256(
                            Math.mulDiv(
                                a,
                                uint256(maxAmountIn * maxAmountIn),
                                uDerivative
                            )
                        ) - SafeCast.toInt256(Math.mulDiv(c1, uc2, uDerivative))
                );

                if (negativeDerivative) maxAmountIn = -maxAmountIn;

                derivative = int256(2 * a) * maxAmountIn + b;

                (negativeDerivative, uDerivative) = (
                    derivative < 0
                        ? (true, uint256(-derivative))
                        : (false, uint256(derivative))
                );

                maxAmountIn = (
                    negativeC
                        ? SafeCast.toInt256(
                            Math.mulDiv(
                                a,
                                uint256(maxAmountIn * maxAmountIn),
                                uDerivative
                            )
                        ) + SafeCast.toInt256(Math.mulDiv(c1, uc2, uDerivative))
                        : SafeCast.toInt256(
                            Math.mulDiv(
                                a,
                                uint256(maxAmountIn * maxAmountIn),
                                uDerivative
                            )
                        ) - SafeCast.toInt256(Math.mulDiv(c1, uc2, uDerivative))
                );

                if (negativeDerivative) maxAmountIn = -maxAmountIn;

                derivative = int256(2 * a) * maxAmountIn + b;

                (negativeDerivative, uDerivative) = (
                    derivative < 0
                        ? (true, uint256(-derivative))
                        : (false, uint256(derivative))
                );

                maxAmountIn = (
                    negativeC
                        ? SafeCast.toInt256(
                            Math.mulDiv(
                                a,
                                uint256(maxAmountIn * maxAmountIn),
                                uDerivative
                            )
                        ) + SafeCast.toInt256(Math.mulDiv(c1, uc2, uDerivative))
                        : SafeCast.toInt256(
                            Math.mulDiv(
                                a,
                                uint256(maxAmountIn * maxAmountIn),
                                uDerivative
                            )
                        ) - SafeCast.toInt256(Math.mulDiv(c1, uc2, uDerivative))
                );

                if (negativeDerivative) maxAmountIn = -maxAmountIn;

                derivative = int256(2 * a) * maxAmountIn + b;

                (negativeDerivative, uDerivative) = (
                    derivative < 0
                        ? (true, uint256(-derivative))
                        : (false, uint256(derivative))
                );

                maxAmountIn = (
                    negativeC
                        ? SafeCast.toInt256(
                            Math.mulDiv(
                                a,
                                uint256(maxAmountIn * maxAmountIn),
                                uDerivative
                            )
                        ) + SafeCast.toInt256(Math.mulDiv(c1, uc2, uDerivative))
                        : SafeCast.toInt256(
                            Math.mulDiv(
                                a,
                                uint256(maxAmountIn * maxAmountIn),
                                uDerivative
                            )
                        ) - SafeCast.toInt256(Math.mulDiv(c1, uc2, uDerivative))
                );

                if (negativeDerivative) maxAmountIn = -maxAmountIn;

                derivative = int256(2 * a) * maxAmountIn + b;

                (negativeDerivative, uDerivative) = (
                    derivative < 0
                        ? (true, uint256(-derivative))
                        : (false, uint256(derivative))
                );

                maxAmountIn = (
                    negativeC
                        ? SafeCast.toInt256(
                            Math.mulDiv(
                                a,
                                uint256(maxAmountIn * maxAmountIn),
                                uDerivative
                            )
                        ) + SafeCast.toInt256(Math.mulDiv(c1, uc2, uDerivative))
                        : SafeCast.toInt256(
                            Math.mulDiv(
                                a,
                                uint256(maxAmountIn * maxAmountIn),
                                uDerivative
                            )
                        ) - SafeCast.toInt256(Math.mulDiv(c1, uc2, uDerivative))
                );

                if (negativeDerivative) maxAmountIn = -maxAmountIn;

                derivative = int256(2 * a) * maxAmountIn + b;

                (negativeDerivative, uDerivative) = (
                    derivative < 0
                        ? (true, uint256(-derivative))
                        : (false, uint256(derivative))
                );

                maxAmountIn = (
                    negativeC
                        ? SafeCast.toInt256(
                            Math.mulDiv(
                                a,
                                uint256(maxAmountIn * maxAmountIn),
                                uDerivative
                            )
                        ) + SafeCast.toInt256(Math.mulDiv(c1, uc2, uDerivative))
                        : SafeCast.toInt256(
                            Math.mulDiv(
                                a,
                                uint256(maxAmountIn * maxAmountIn),
                                uDerivative
                            )
                        ) - SafeCast.toInt256(Math.mulDiv(c1, uc2, uDerivative))
                );

                if (negativeDerivative) maxAmountIn = -maxAmountIn;

                derivative = int256(2 * a) * maxAmountIn + b;

                (negativeDerivative, uDerivative) = (
                    derivative < 0
                        ? (true, uint256(-derivative))
                        : (false, uint256(derivative))
                );

                maxAmountIn = (
                    negativeC
                        ? SafeCast.toInt256(
                            Math.mulDiv(
                                a,
                                uint256(maxAmountIn * maxAmountIn),
                                uDerivative
                            )
                        ) + SafeCast.toInt256(Math.mulDiv(c1, uc2, uDerivative))
                        : SafeCast.toInt256(
                            Math.mulDiv(
                                a,
                                uint256(maxAmountIn * maxAmountIn),
                                uDerivative
                            )
                        ) - SafeCast.toInt256(Math.mulDiv(c1, uc2, uDerivative))
                );

                if (negativeDerivative) maxAmountIn = -maxAmountIn;
            }
        } else {
            unchecked {
                require(
                    params.vBalance1 <= params.balance1,
                    'invalid vBalance1'
                );
                maxAmountIn =
                    SafeCast.toInt256(
                        Math.mulDiv(
                            params.balance1 * params.vBalance0,
                            2 *
                                params.balance0 *
                                params.maxReserveRatio -
                                params.reserveRatioFactor *
                                params.reservesBaseValueSum,
                            params.balance0 *
                                params.reserveRatioFactor *
                                params.vBalance1
                        )
                    ) -
                    SafeCast.toInt256(params.reserves);
            }
        }
        assert(maxAmountIn >= 0);
        return uint256(maxAmountIn);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.18;

interface IvPairFactory {
    event PairCreated(
        address poolAddress,
        address factory,
        address token0,
        address token1,
        uint16 fee,
        uint16 vFee,
        uint256 maxReserveRatio
    );

    event DefaultAllowListChanged(address[] allowList);

    event FactoryNewAdmin(address newAdmin);
    event FactoryNewPendingAdmin(address newPendingAdmin);

    event FactoryNewEmergencyAdmin(address newEmergencyAdmin);
    event FactoryNewPendingEmergencyAdmin(address newPendingEmergencyAdmin);

    event ExchangeReserveAddressChanged(address newExchangeReserve);

    event FactoryVPoolManagerChanged(address newVPoolManager);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address);

    function pairs(
        address tokenA,
        address tokenB
    ) external view returns (address);

    function setDefaultAllowList(address[] calldata _defaultAllowList) external;

    function allPairs(uint256 index) external view returns (address);

    function allPairsLength() external view returns (uint256);

    function vPoolManager() external view returns (address);

    function admin() external view returns (address);

    function emergencyAdmin() external view returns (address);

    function pendingEmergencyAdmin() external view returns (address);

    function setPendingEmergencyAdmin(address newEmergencyAdmin) external;

    function acceptEmergencyAdmin() external;

    function pendingAdmin() external view returns (address);

    function setPendingAdmin(address newAdmin) external;

    function setVPoolManagerAddress(address _vPoolManager) external;

    function acceptAdmin() external;

    function exchangeReserves() external view returns (address);

    function setExchangeReservesAddress(address _exchangeReserves) external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.18;

/// @title Provides functions for deriving a pool address from the factory and token
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH =
        0x65ffb27441c0bb5e52a13f52402816c94fe488be5e72d7625e84bb21ea1d0b66;

    function orderAddresses(
        address tokenA,
        address tokenB
    ) internal pure returns (address token0, address token1) {
        return (tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA));
    }

    function getSalt(
        address tokenA,
        address tokenB
    ) internal pure returns (bytes32 salt) {
        (address token0, address token1) = orderAddresses(tokenA, tokenB);
        salt = keccak256(abi.encode(token0, token1));
    }

    function computeAddress(
        address factory,
        address token0,
        address token1
    ) internal pure returns (address pool) {
        bytes32 _salt = getSalt(token0, token1);

        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            factory,
                            _salt,
                            POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.18;

import '../types.sol';

interface IvPoolManager {
    function pairFactory() external view returns (address);

    function getVirtualPool(
        address jkPair,
        address ikPair
    ) external view returns (VirtualPoolModel memory vPool);

    function getVirtualPools(
        address token0,
        address token1
    ) external view returns (VirtualPoolModel[] memory vPools);

    function updateVirtualPoolBalances(
        address jkPair,
        address ikPair,
        uint256 balance0,
        uint256 balance1
    ) external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.18;

import '../types.sol';

interface IvPair {
    event TestEvent(
        VirtualPoolModel vPool,
        uint256 amountIn,
        uint256 maxTradeAmount
    );

    event Mint(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        uint lpTokens,
        uint poolLPTokens
    );

    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to,
        uint256 totalSupply
    );

    event Swap(
        address indexed sender,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        address indexed to
    );

    event SwapReserve(
        address indexed sender,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        address ikPool,
        address indexed to
    );

    event AllowListChanged(address[] tokens);

    event Sync(uint112 balance0, uint112 balance1);

    event ReserveSync(address asset, uint256 balance, uint256 rRatio);

    event FeeChanged(uint16 fee, uint16 vFee);

    event ReserveThresholdChanged(uint256 newThreshold);

    event AllowListCountChanged(uint24 _maxAllowListCount);

    event EmergencyDiscountChanged(uint256 _newEmergencyDiscount);

    event ReserveRatioWarningThresholdChanged(
        uint256 _newReserveRatioWarningThreshold
    );

    function fee() external view returns (uint16);

    function vFee() external view returns (uint16);

    function setFee(uint16 _fee, uint16 _vFee) external;

    function swapNative(
        uint256 amountOut,
        address tokenOut,
        address to,
        bytes calldata data
    ) external returns (uint256 _amountIn);

    function swapReserveToNative(
        uint256 amountOut,
        address ikPair,
        address to,
        bytes calldata data
    ) external returns (uint256 _amountIn);

    function swapNativeToReserve(
        uint256 amountOut,
        address ikPair,
        address to,
        uint256 incentivesLimitPct,
        bytes calldata data
    ) external returns (address _token, uint256 _leftovers);

    function mint(address to) external returns (uint256 liquidity);

    function burn(
        address to
    ) external returns (uint256 amount0, uint256 amount1);

    function setAllowList(address[] memory _allowList) external;

    function setMaxAllowListCount(uint24 _maxAllowListCount) external;

    function allowListMap(address _token) external view returns (bool allowed);

    function calculateReserveRatio() external view returns (uint256 rRatio);

    function setMaxReserveThreshold(uint256 threshold) external;

    function setReserveRatioWarningThreshold(uint256 threshold) external;

    function setEmergencyDiscount(uint256 discount) external;

    function token0() external view returns (address);

    function token1() external view returns (address);

    function pairBalance0() external view returns (uint112);

    function pairBalance1() external view returns (uint112);

    function maxAllowListCount() external view returns (uint24);

    function maxReserveRatio() external view returns (uint256);

    function getBalances() external view returns (uint112, uint112);

    function getLastBalances()
        external
        view
        returns (
            uint112 _lastBalance0,
            uint112 _lastBalance1,
            uint32 _blockNumber
        );

    function getTokens() external view returns (address, address);

    function reservesBaseValue(
        address reserveAddress
    ) external view returns (uint256);

    function reserves(address reserveAddress) external view returns (uint256);

    function reservesBaseValueSum() external view returns (uint256);

    function reserveRatioFactor() external pure returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}