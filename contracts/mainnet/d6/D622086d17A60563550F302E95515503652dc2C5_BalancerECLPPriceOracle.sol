// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "BalancerLPSharePricing.sol";
import "BaseBalancerPriceOracle.sol";

import "TypeConversion.sol";

import "IECLP.sol";

contract BalancerECLPPriceOracle is BaseBalancerPriceOracle {
    using TypeConversion for DataTypes.PricedToken[];
    using TypeConversion for IECLP.DerivedParams;
    using FixedPoint for uint256;

    function getInvariantDivSupply(IMinimalPoolView pool) internal view override returns (uint256) {
        // Temporary workaround. To be removed (so the base class's version is used) in the mainnet deployment.
        uint256 invariant = pool.getLastInvariant();
        uint256 totalSupply = pool.totalSupply();
        return invariant.divDown(totalSupply);
    }

    /// @inheritdoc BaseVaultPriceOracle
    function getPoolTokenPriceUSD(
        IGyroVault vault,
        DataTypes.PricedToken[] memory underlyingPricedTokens
    ) public view override returns (uint256) {
        IECLP pool = IECLP(vault.underlying());
        (IECLP.Params memory params, IECLP.DerivedParams memory derivedParams) = pool
            .getECLPParams();
        return
            BalancerLPSharePricing.priceBptECLP(
                params,
                derivedParams.downscaleDerivedParams(),
                getInvariantDivSupply(pool),
                underlyingPricedTokens.pluckPrices()
            );
    }
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "SafeCast.sol";

import "FixedPoint.sol";
import "SignedFixedPoint.sol";

import "IECLP.sol";

library BalancerLPSharePricing {
    using FixedPoint for uint256;
    using SignedFixedPoint for int256;
    using SafeCast for uint256;
    using SafeCast for int256;

    uint256 internal constant ONEHALF = 0.5e18;

    /** @dev Calculates the value of Balancer pool tokens (BPT) that use constant product invariant
     *  @param weights = weights of underlying assets
     *  @param underlyingPrices = prices of underlying assets, in same order as weights
     *  @param invariantDivSupply = value of the pool invariant / supply of BPT
     *  This calculation is robust to price manipulation within the Balancer pool */
    function priceBptCPMM(
        uint256[] memory weights,
        uint256 invariantDivSupply,
        uint256[] memory underlyingPrices
    ) internal pure returns (uint256 bptPrice) {
        /**********************************************************************************************
        //                        L   n               w_i                               //
        //            bptPrice = ---  Π   (p_i / w_i)^                                  //
        //                        S   i=1                                               //
        **********************************************************************************************/
        uint256 prod = FixedPoint.ONE;
        for (uint256 i = 0; i < weights.length; i++) {
            prod = prod.mulDown(
                FixedPoint.powDown(underlyingPrices[i].divDown(weights[i]), weights[i])
            );
            bptPrice = invariantDivSupply.mulDown(prod);
        }
    }

    /** @dev Efficiently calculates the value of Balancer pool tokens (BPT) for two asset pools with constant product invariant
     *  @param weights = weights of underlying assets
     *  @param underlyingPrices = prices of underlying assets, in same order as weights
     *  @param invariantDivSupply = value of the pool invariant / supply of BPT
     *  This calculation is robust to price manipulation within the Balancer pool
     *  However, numerical imprecision may occur with extremely large or small prices */
    function priceBptTwoAssetCPMM(
        uint256[] memory weights,
        uint256 invariantDivSupply,
        uint256[] memory underlyingPrices
    ) internal pure returns (uint256 bptPrice) {
        /**********************************************************************************************
        //                        L                        w_0                                       //
        //            bptPrice = --- (  w_1 p_0 / w_0 p_1 )^   (p_1 / w_1)                           //
        //                        S                                                                  //
        **********************************************************************************************/
        // firstTerm is invariantDivSupply

        require(weights.length == 2, Errors.INVALID_NUMBER_WEIGHTS);

        (uint256 i, uint256 j) = weights[1].mulDown(underlyingPrices[0]) >
            weights[0].mulDown(underlyingPrices[1])
            ? (1, 0)
            : (0, 1);

        uint256 secondTerm = FixedPoint.powDown(
            underlyingPrices[i].mulDown(weights[j]).divDown(
                weights[i].mulDown(underlyingPrices[j])
            ),
            weights[i]
        );

        uint256 thirdTerm = underlyingPrices[j].divDown(weights[j]);

        bptPrice = invariantDivSupply.mulDown(secondTerm).mulDown(thirdTerm);
    }

    /** @dev Calculates value of BPT for constant product invariant with equal weights
     *  Compared to general CPMM, everything can be grouped into one fractional power to save gas
     *  Note: loss of precision arises when multiple prices are too low (e.g., < 1e-5). This pricing formula
     *  should not be relied on precisely in such extremes */
    function priceBptCPMMEqualWeights(
        uint256 weight,
        uint256 invariantDivSupply,
        uint256[] memory underlyingPrices
    ) internal pure returns (uint256 bptPrice) {
        /**********************************************************************************************
        //                        L     n             w                                 //
        //            bptPrice = ---  ( Π   p_i / w )^                                  //
        //                        S     i=1                                             //
        **********************************************************************************************/
        uint256 prod = FixedPoint.ONE;
        for (uint256 i = 0; i < underlyingPrices.length; i++) {
            prod = prod.mulDown(underlyingPrices[i].divDown(weight));
        }
        prod = FixedPoint.powDown(prod, weight);
        bptPrice = invariantDivSupply.mulDown(prod);
    }

    /** @dev Calculates the value of BPT for 2CLP pools
     *  these are constant product invariant 2-pools with 1/2 weights and virtual reserves
     *  @param sqrtAlpha = sqrt of lower price bound
     *  @param sqrtBeta = sqrt of upper price bound
     *  @param invariantDivSupply = value of the pool invariant / supply of BPT
     *  This calculation is robust to price manipulation within the Balancer pool */
    function priceBpt2CLP(
        uint256 sqrtAlpha,
        uint256 sqrtBeta,
        uint256 invariantDivSupply,
        uint256[] memory underlyingPrices
    ) internal pure returns (uint256 bptPrice) {
        /**********************************************************************************************
        // When alpha < p_x/p_y < beta:                                                 //
        //                 L                 1/2               1/2              1/2     //
        //     bptPrice = ---  ( 2 (p_x p_y)^     - p_x / beta^     - p_y alpha^    )   //
        //                 S                                                            //
        // When p_x/p_y < alpha: bptPrice = L/S * p_x (1/sqrt(alpha) - 1/sqrt(beta))    //
        // When p_x/p_y > beta: bptPrice = L/S * p_y (sqrt(beta) - sqrt(alpha))         //
        **********************************************************************************************/
        (uint256 px, uint256 py) = (underlyingPrices[0], underlyingPrices[1]);
        uint256 one = FixedPoint.ONE;
        if (px.divDown(py) <= sqrtAlpha.mulUp(sqrtAlpha)) {
            bptPrice = invariantDivSupply.mulDown(px).mulDown(
                one.divDown(sqrtAlpha) - one.divUp(sqrtBeta)
            );
        } else if (px.divUp(py) >= sqrtBeta.mulDown(sqrtBeta)) {
            bptPrice = invariantDivSupply.mulDown(py).mulDown(sqrtBeta - sqrtAlpha);
        } else {
            uint256 sqrPxPy = 2 * FixedPoint.powDown(px.mulDown(py), ONEHALF);
            bptPrice = sqrPxPy - px.divUp(sqrtBeta) - py.mulUp(sqrtAlpha);
            bptPrice = invariantDivSupply.mulDown(bptPrice);
        }
    }

    /** @dev Calculates the value of BPT for 3CLP pools
     *  these are constant product invariant 3-pools with 1/3 weights and virtual reserves
     *  virtual reserves are chosen such that alpha = lower price bound and 1/alpha = upper price bound
     *  @param cbrtAlpha = cube root of alpha (lower price bound)
     *  @param invariantDivSupply = value of the pool invariant / supply of BPT
     *  @param underlyingPrices = array of three prices for the
     *  This calculation is robust to price manipulation within the Balancer pool.
     *  The calculation includes a kind of no-arbitrage equilibrium computation, see the Gyroscope Oracles document, p. 7. */
    function priceBpt3CLP(
        uint256 cbrtAlpha,
        uint256 invariantDivSupply,
        uint256[] memory underlyingPrices
    ) internal pure returns (uint256 bptPrice) {
        require(underlyingPrices.length == 3, Errors.INVALID_ARGUMENT);
        uint256 pXZPool;
        uint256 pYZPool;
        {
            uint256 alpha = cbrtAlpha.mulDown(cbrtAlpha).mulDown(cbrtAlpha);
            uint256 pXZ = underlyingPrices[0].divDown(underlyingPrices[2]);
            uint256 pYZ = underlyingPrices[1].divDown(underlyingPrices[2]);
            (pXZPool, pYZPool) = relativeEquilibriumPrices3CLP(alpha, pXZ, pYZ);
        }

        uint256 cbrtPxzPyzPool = pXZPool.mulDown(pYZPool);
        cbrtPxzPyzPool = FixedPoint.powDown(cbrtPxzPyzPool, FixedPoint.ONE / 3);

        // term = helper variable that will be re-used below to avoid stack-too-deep.
        uint256 term = underlyingPrices[0].divDown(pXZPool);
        term += underlyingPrices[1].divDown(pYZPool);
        term += underlyingPrices[2];

        bptPrice = cbrtPxzPyzPool.mulDown(term);

        term = (underlyingPrices[0] + underlyingPrices[1] + underlyingPrices[2]).mulUp(cbrtAlpha);
        bptPrice = bptPrice - term;
        bptPrice = bptPrice.mulDown(invariantDivSupply);
    }

    /** @dev Compute the unique price vector of a 3CLP pool that is in equilibrium with an external market with the given relative prices.
        See Gyroscope Oracles document, Section 4.3.
        @param alpha = lower price bound
        @param pXZ = relative price of asset x denoted in units of z of the external market
        @param pYZ = relative price of asset y denoted in units of z of the external market
        @return relative prices of x and y, respectively, denoted in units of z, of a pool in equilibrium with (pXZ, pYZ).
     */
    function relativeEquilibriumPrices3CLP(
        uint256 alpha,
        uint256 pXZ,
        uint256 pYZ
    ) internal pure returns (uint256, uint256) {
        // NOTE: Rounding directions are less critical here b/c all functions are continuous and we don't take any roots where the radicand can become negative.
        // SOMEDAY this should be reviewed so that we round in a way most favorable to us I guess?
        uint256 alphaInv = FixedPoint.ONE.divDown(alpha);
        if (pYZ < alpha.mulDown(pXZ).mulDown(pXZ)) {
            if (pYZ < alpha) return (FixedPoint.ONE, alpha);
            else if (pYZ > alphaInv) return (alphaInv, alphaInv);
            else {
                uint256 pXPool = alphaInv.mulDown(pYZ).powDown(ONEHALF);
                return (pXPool, pYZ);
            }
        } else if (pXZ < alpha.mulDown(pYZ).mulDown(pYZ)) {
            if (pXZ < alpha) return (alpha, FixedPoint.ONE);
            else if (pXZ > alphaInv) return (alphaInv, alphaInv);
            else {
                uint256 pYPool = alphaInv.mulDown(pXZ).powDown(ONEHALF);
                return (pXZ, pYPool);
            }
        } else if (pXZ.mulDown(pYZ) < alpha) {
            if (pXZ < alpha.mulDown(pYZ)) return (alpha, FixedPoint.ONE);
            else if (pXZ > alphaInv.mulDown(pYZ)) return (FixedPoint.ONE, alpha);
            else {
                // SOMEDAY Gas optimization: sqrtAlpha could be made immutable in the pool and passed as a parameter.
                uint256 sqrtAlpha = alpha.powDown(ONEHALF);
                uint256 sqrtPXY = pXZ.divDown(pYZ).powDown(ONEHALF);
                return (sqrtAlpha.mulDown(sqrtPXY), sqrtAlpha.divDown(sqrtPXY));
            }
        } else {
            return (pXZ, pYZ);
        }
    }

    /** @dev Calculates the value of BPT for constant ellipse (ECLP) pools of two assets
     *  @param params = ECLP pool parameters
     *  @param derivedParams = (tau(alpha), tau(beta))
     *  @param invariantDivSupply = value of the pool invariant / supply of BPT
     *  This calculation is robust to price manipulation within the Balancer pool */
    function priceBptECLP(
        IECLP.Params memory params,
        IECLP.DerivedParams memory derivedParams,
        uint256 invariantDivSupply,
        uint256[] memory underlyingPrices
    ) internal pure returns (uint256 bptPrice) {
        /**********************************************************************************************
        // When alpha < p_x/p_y < beta:                                                              //
        //                L   / / e_x A^{-1} tau(beta) \     -1     / p_x \  \   / p_x \             //
        //   bptPrice =  --- | |                        | - A^  tau|  ---- |  | |       |            //
        //                S   \ \ e_y A^{-1} tau(alpha) /           \ p_y  /  /  \ p_y  /            //
        // When p_x/p_y < alpha:                                                                     //
        //      bptPrice = L/S * p_x ( e_x A^{-1} tau(beta) - e_x A^{-1} tau(alpha) )                //
        // When p_x/p_y > beta:                                                                      //
        //      bptPrice = L/S * p_y (e_y A^{-1} tau(alpha) - e_y A^{-1} tau(beta) )                 //
        **********************************************************************************************/
        (int256 px, int256 py) = (underlyingPrices[0].toInt256(), underlyingPrices[1].toInt256());
        int256 pxIny = px.divDownMag(py);
        if (pxIny < params.alpha) {
            int256 bP = (mulAinv(params, derivedParams.tauBeta).x -
                mulAinv(params, derivedParams.tauAlpha).x);
            bptPrice = (bP.mulDownMag(px)).toUint256().mulDown(invariantDivSupply);
        } else if (pxIny > params.beta) {
            int256 bP = (mulAinv(params, derivedParams.tauAlpha).y -
                mulAinv(params, derivedParams.tauBeta).y);
            bptPrice = (bP.mulDownMag(py)).toUint256().mulDown(invariantDivSupply);
        } else {
            IECLP.Vector2 memory vec = mulAinv(params, tau(params, pxIny));
            vec.x = mulAinv(params, derivedParams.tauBeta).x - vec.x;
            vec.y = mulAinv(params, derivedParams.tauAlpha).y - vec.y;
            bptPrice = scalarProdDown(IECLP.Vector2(px, py), vec).toUint256().mulDown(
                invariantDivSupply
            );
        }
    }

    ///////////////////////////////////////////////////////////////////////////////////////
    // The following functions and structs copied over from ECLP math library
    // Can't easily inherit because of different Solidity versions

    // Scalar product of IECLP.Vector2 objects
    function scalarProdDown(IECLP.Vector2 memory t1, IECLP.Vector2 memory t2)
        internal
        pure
        returns (int256 ret)
    {
        ret = t1.x.mulDownMag(t2.x) + t1.y.mulDownMag(t2.y);
    }

    /** @dev Calculate A^{-1}t where A^{-1} is given in Section 2.2
     *  This is rotating and scaling the circle into the ellipse */

    function mulAinv(IECLP.Params memory params, IECLP.Vector2 memory t)
        internal
        pure
        returns (IECLP.Vector2 memory tp)
    {
        tp.x = t.x.mulDownMag(params.lambda).mulDownMag(params.c) + t.y.mulDownMag(params.s);
        tp.y = -t.x.mulDownMag(params.lambda).mulDownMag(params.s) + t.y.mulDownMag(params.c);
    }

    /** @dev Calculate A t where A is given in Section 2.2
     *  This is reversing rotation and scaling of the ellipse (mapping back to circle) */

    function mulA(IECLP.Params memory params, IECLP.Vector2 memory tp)
        internal
        pure
        returns (IECLP.Vector2 memory t)
    {
        t.x =
            params.c.mulDownMag(tp.x).divDownMag(params.lambda) -
            params.s.mulDownMag(tp.y).divDownMag(params.lambda);
        t.y = params.s.mulDownMag(tp.x) + params.c.mulDownMag(tp.y);
    }

    /** @dev Given price px on the transformed ellipse, get the untransformed price pxc on the circle
     *  px = price of asset x in terms of asset y */
    function zeta(IECLP.Params memory params, int256 px) internal pure returns (int256 pxc) {
        IECLP.Vector2 memory nd = mulA(params, IECLP.Vector2(-SignedFixedPoint.ONE, px));
        return -nd.y.divDownMag(nd.x);
    }

    /** @dev Given price px on the transformed ellipse, maps to the corresponding point on the untransformed normalized circle
     *  px = price of asset x in terms of asset y */
    function tau(IECLP.Params memory params, int256 px)
        internal
        pure
        returns (IECLP.Vector2 memory tpp)
    {
        return eta(zeta(params, px));
    }

    /** @dev Given price on a circle, gives the normalized corresponding point on the circle centered at the origin
     *  pxc = price of asset x in terms of asset y (measured on the circle)
     *  Notice that the eta function does not depend on Params */
    function eta(int256 pxc) internal pure returns (IECLP.Vector2 memory tpp) {
        int256 z = FixedPoint
            .powDown(FixedPoint.ONE + (pxc.mulDownMag(pxc).toUint256()), ONEHALF)
            .toInt256();
        tpp = eta(pxc, z);
    }

    /** @dev Calculates eta in more efficient way if the square root is known and input as second arg */
    function eta(int256 pxc, int256 z) internal pure returns (IECLP.Vector2 memory tpp) {
        tpp.x = pxc.divDownMag(z);
        tpp.y = SignedFixedPoint.ONE.divDownMag(z);
    }
}

// SPDX-License-Identifier: MIT

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
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
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
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
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
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
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
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
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
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
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
     * - input must fit into 8 bits.
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
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
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
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
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
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
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
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
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
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
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
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.


pragma solidity ^0.8.4;

import "LogExpMath.sol";
import "Errors.sol";

/* solhint-disable private-vars-leading-underscore */

library FixedPoint {
    uint256 internal constant ONE = 1e18; // 18 decimal places
    uint256 internal constant MAX_POW_RELATIVE_ERROR = 10000; // 10^(-14)

    // Minimum base for the power function when the exponent is 'free' (larger than ONE).
    uint256 internal constant MIN_POW_BASE_FREE_EXPONENT = 0.7e18;

    function absSub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a - b : b - a;
    }

    function mulDown(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 product = a * b;

        return product / ONE;
    }

    function mulUp(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 product = a * b;

        if (product == 0) {
            return 0;
        } else {
            // The traditional divUp formula is:
            // divUp(x, y) := (x + y - 1) / y
            // To avoid intermediate overflow in the addition, we distribute the division and get:
            // divUp(x, y) := (x - 1) / y + 1
            // Note that this requires x != 0, which we already tested for.

            return ((product - 1) / ONE) + 1;
        }
    }

    function squareUp(uint256 a) internal pure returns (uint256) {
        return mulUp(a, a);
    }

    function squareDown(uint256 a) internal pure returns (uint256) {
        return mulDown(a, a);
    }

    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, Errors.ZERO_DIVISION);

        if (a == 0) {
            return 0;
        } else {
            uint256 aInflated = a * ONE;

            return aInflated / b;
        }
    }

    function divUp(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, Errors.ZERO_DIVISION);

        if (a == 0) {
            return 0;
        } else {
            uint256 aInflated = a * ONE;

            // The traditional divUp formula is:
            // divUp(x, y) := (x + y - 1) / y
            // To avoid intermediate overflow in the addition, we distribute the division and get:
            // divUp(x, y) := (x - 1) / y + 1
            // Note that this requires x != 0, which we already tested for.

            unchecked {
                return ((aInflated - 1) / b) + 1;
            }
        }
    }

    /**
     * @dev Returns x^y, assuming both are fixed point numbers, rounding down. The result is guaranteed to not be above
     * the true value (that is, the error function expected - actual is always positive).
     */
    function powDown(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 raw = LogExpMath.pow(x, y);
        uint256 maxError = mulUp(raw, MAX_POW_RELATIVE_ERROR) + 1;

        if (raw < maxError) {
            return 0;
        } else {
            return raw - maxError;
        }
    }

    /**
     * @dev Returns x^y, assuming both are fixed point numbers, rounding up. The result is guaranteed to not be below
     * the true value (that is, the error function expected - actual is always negative).
     */
    function powUp(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 raw = LogExpMath.pow(x, y);
        uint256 maxError = mulUp(raw, MAX_POW_RELATIVE_ERROR) + 1;

        return raw + maxError;
    }

    /**
     * @dev Returns the complement of a value (1 - x), capped to 0 if x is larger than 1.
     *
     * Useful when computing the complement for values with some level of relative error, as it strips this error and
     * prevents intermediate negative values.
     */
    function complement(uint256 x) internal pure returns (uint256) {
        return (x < ONE) ? (ONE - x) : 0;
    }

    /**
     * @dev returns the minimum between x and y
     */
    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? x : y;
    }

    /**
     * @dev returns the maximum between x and y
     */
    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        return x > y ? x : y;
    }

    /**
     * @notice This is taken from the Balancer V1 code base.
     * Computes a**b where a is a scaled fixed-point number and b is an integer
     * The computation is performed in O(log n)
     */
    function intPowDown(uint256 base, uint256 exp) internal pure returns (uint256) {
        uint256 result = FixedPoint.ONE;
        while (exp > 0) {
            if (exp % 2 == 1) {
                result = mulDown(result, base);
            }
            exp /= 2;
            base = mulDown(base, base);
        }
        return result;
    }
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.


pragma solidity ^0.8.4;

import "Errors.sol";

/* solhint-disable */

/**
 * @dev Exponentiation and logarithm functions for 18 decimal fixed point numbers (both base and exponent/argument).
 *
 * Exponentiation and logarithm with arbitrary bases (x^y and log_x(y)) are implemented by conversion to natural
 * exponentiation and logarithm (where the base is Euler's number).
 *
 * @author Fernando Martinelli - @fernandomartinelli
 * @author Sergio Yuhjtman - @sergioyuhjtman
 * @author Daniel Fernandez - @dmf7z
 */
library LogExpMath {
    // All fixed point multiplications and divisions are inlined. This means we need to divide by ONE when multiplying
    // two numbers, and multiply by ONE when dividing them.

    // All arguments and return values are 18 decimal fixed point numbers.
    int256 constant ONE_18 = 1e18;

    // Internally, intermediate values are computed with higher precision as 20 decimal fixed point numbers, and in the
    // case of ln36, 36 decimals.
    int256 constant ONE_20 = 1e20;
    int256 constant ONE_36 = 1e36;

    // The domain of natural exponentiation is bound by the word size and number of decimals used.
    //
    // Because internally the result will be stored using 20 decimals, the largest possible result is
    // (2^255 - 1) / 10^20, which makes the largest exponent ln((2^255 - 1) / 10^20) = 130.700829182905140221.
    // The smallest possible result is 10^(-18), which makes largest negative argument
    // ln(10^(-18)) = -41.446531673892822312.
    // We use 130.0 and -41.0 to have some safety margin.
    int256 constant MAX_NATURAL_EXPONENT = 130e18;
    int256 constant MIN_NATURAL_EXPONENT = -41e18;

    // Bounds for ln_36's argument. Both ln(0.9) and ln(1.1) can be represented with 36 decimal places in a fixed point
    // 256 bit integer.
    int256 constant LN_36_LOWER_BOUND = ONE_18 - 1e17;
    int256 constant LN_36_UPPER_BOUND = ONE_18 + 1e17;

    uint256 constant MILD_EXPONENT_BOUND = 2**254 / uint256(ONE_20);

    // 18 decimal constants
    int256 constant x0 = 128000000000000000000; // 2ˆ7
    int256 constant a0 = 38877084059945950922200000000000000000000000000000000000; // eˆ(x0) (no decimals)
    int256 constant x1 = 64000000000000000000; // 2ˆ6
    int256 constant a1 = 6235149080811616882910000000; // eˆ(x1) (no decimals)

    // 20 decimal constants
    int256 constant x2 = 3200000000000000000000; // 2ˆ5
    int256 constant a2 = 7896296018268069516100000000000000; // eˆ(x2)
    int256 constant x3 = 1600000000000000000000; // 2ˆ4
    int256 constant a3 = 888611052050787263676000000; // eˆ(x3)
    int256 constant x4 = 800000000000000000000; // 2ˆ3
    int256 constant a4 = 298095798704172827474000; // eˆ(x4)
    int256 constant x5 = 400000000000000000000; // 2ˆ2
    int256 constant a5 = 5459815003314423907810; // eˆ(x5)
    int256 constant x6 = 200000000000000000000; // 2ˆ1
    int256 constant a6 = 738905609893065022723; // eˆ(x6)
    int256 constant x7 = 100000000000000000000; // 2ˆ0
    int256 constant a7 = 271828182845904523536; // eˆ(x7)
    int256 constant x8 = 50000000000000000000; // 2ˆ-1
    int256 constant a8 = 164872127070012814685; // eˆ(x8)
    int256 constant x9 = 25000000000000000000; // 2ˆ-2
    int256 constant a9 = 128402541668774148407; // eˆ(x9)
    int256 constant x10 = 12500000000000000000; // 2ˆ-3
    int256 constant a10 = 113314845306682631683; // eˆ(x10)
    int256 constant x11 = 6250000000000000000; // 2ˆ-4
    int256 constant a11 = 106449445891785942956; // eˆ(x11)

    /**
     * @dev Exponentiation (x^y) with unsigned 18 decimal fixed point base and exponent.
     *
     * Reverts if ln(x) * y is smaller than `MIN_NATURAL_EXPONENT`, or larger than `MAX_NATURAL_EXPONENT`.
     */
    function pow(uint256 x, uint256 y) internal pure returns (uint256) {
        unchecked {
            if (y == 0) {
                // We solve the 0^0 indetermination by making it equal one.
                return uint256(ONE_18);
            }

            if (x == 0) {
                return 0;
            }

            // Instead of computing x^y directly, we instead rely on the properties of logarithms and exponentiation to
            // arrive at that result. In particular, exp(ln(x)) = x, and ln(x^y) = y * ln(x). This means
            // x^y = exp(y * ln(x)).

            // The ln function takes a signed value, so we need to make sure x fits in the signed 256 bit range.
            require(x < 2**255, Errors.X_OUT_OF_BOUNDS);
            int256 x_int256 = int256(x);

            // We will compute y * ln(x) in a single step. Depending on the value of x, we can either use ln or ln_36. In
            // both cases, we leave the division by ONE_18 (due to fixed point multiplication) to the end.

            // This prevents y * ln(x) from overflowing, and at the same time guarantees y fits in the signed 256 bit range.
            require(y < MILD_EXPONENT_BOUND, Errors.Y_OUT_OF_BOUNDS);
            int256 y_int256 = int256(y);

            int256 logx_times_y;
            if (LN_36_LOWER_BOUND < x_int256 && x_int256 < LN_36_UPPER_BOUND) {
                int256 ln_36_x = _ln_36(x_int256);

                // ln_36_x has 36 decimal places, so multiplying by y_int256 isn't as straightforward, since we can't just
                // bring y_int256 to 36 decimal places, as it might overflow. Instead, we perform two 18 decimal
                // multiplications and add the results: one with the first 18 decimals of ln_36_x, and one with the
                // (downscaled) last 18 decimals.
                logx_times_y = ((ln_36_x / ONE_18) *
                    y_int256 +
                    ((ln_36_x % ONE_18) * y_int256) /
                    ONE_18);
            } else {
                logx_times_y = _ln(x_int256) * y_int256;
            }
            logx_times_y /= ONE_18;

            // Finally, we compute exp(y * ln(x)) to arrive at x^y
            require(
                MIN_NATURAL_EXPONENT <= logx_times_y && logx_times_y <= MAX_NATURAL_EXPONENT,
                Errors.PRODUCT_OUT_OF_BOUNDS
            );

            return uint256(exp(logx_times_y));
        }
    }

    /**
     * @dev Natural exponentiation (e^x) with signed 18 decimal fixed point exponent.
     *
     * Reverts if `x` is smaller than MIN_NATURAL_EXPONENT, or larger than `MAX_NATURAL_EXPONENT`.
     */
    function exp(int256 x) internal pure returns (int256) {
        require(x >= MIN_NATURAL_EXPONENT && x <= MAX_NATURAL_EXPONENT, Errors.INVALID_EXPONENT);
        unchecked {
            if (x < 0) {
                // We only handle positive exponents: e^(-x) is computed as 1 / e^x. We can safely make x positive since it
                // fits in the signed 256 bit range (as it is larger than MIN_NATURAL_EXPONENT).
                // Fixed point division requires multiplying by ONE_18.
                return ((ONE_18 * ONE_18) / exp(-x));
            }

            // First, we use the fact that e^(x+y) = e^x * e^y to decompose x into a sum of powers of two, which we call x_n,
            // where x_n == 2^(7 - n), and e^x_n = a_n has been precomputed. We choose the first x_n, x0, to equal 2^7
            // because all larger powers are larger than MAX_NATURAL_EXPONENT, and therefore not present in the
            // decomposition.
            // At the end of this process we will have the product of all e^x_n = a_n that apply, and the remainder of this
            // decomposition, which will be lower than the smallest x_n.
            // exp(x) = k_0 * a_0 * k_1 * a_1 * ... + k_n * a_n * exp(remainder), where each k_n equals either 0 or 1.
            // We mutate x by subtracting x_n, making it the remainder of the decomposition.

            // The first two a_n (e^(2^7) and e^(2^6)) are too large if stored as 18 decimal numbers, and could cause
            // intermediate overflows. Instead we store them as plain integers, with 0 decimals.
            // Additionally, x0 + x1 is larger than MAX_NATURAL_EXPONENT, which means they will not both be present in the
            // decomposition.

            // For each x_n, we test if that term is present in the decomposition (if x is larger than it), and if so deduct
            // it and compute the accumulated product.

            int256 firstAN;
            if (x >= x0) {
                x -= x0;
                firstAN = a0;
            } else if (x >= x1) {
                x -= x1;
                firstAN = a1;
            } else {
                firstAN = 1; // One with no decimal places
            }

            // We now transform x into a 20 decimal fixed point number, to have enhanced precision when computing the
            // smaller terms.
            x *= 100;

            // `product` is the accumulated product of all a_n (except a0 and a1), which starts at 20 decimal fixed point
            // one. Recall that fixed point multiplication requires dividing by ONE_20.
            int256 product = ONE_20;

            if (x >= x2) {
                x -= x2;
                product = (product * a2) / ONE_20;
            }
            if (x >= x3) {
                x -= x3;
                product = (product * a3) / ONE_20;
            }
            if (x >= x4) {
                x -= x4;
                product = (product * a4) / ONE_20;
            }
            if (x >= x5) {
                x -= x5;
                product = (product * a5) / ONE_20;
            }
            if (x >= x6) {
                x -= x6;
                product = (product * a6) / ONE_20;
            }
            if (x >= x7) {
                x -= x7;
                product = (product * a7) / ONE_20;
            }
            if (x >= x8) {
                x -= x8;
                product = (product * a8) / ONE_20;
            }
            if (x >= x9) {
                x -= x9;
                product = (product * a9) / ONE_20;
            }

            // x10 and x11 are unnecessary here since we have high enough precision already.

            // Now we need to compute e^x, where x is small (in particular, it is smaller than x9). We use the Taylor series
            // expansion for e^x: 1 + x + (x^2 / 2!) + (x^3 / 3!) + ... + (x^n / n!).

            int256 seriesSum = ONE_20; // The initial one in the sum, with 20 decimal places.
            int256 term; // Each term in the sum, where the nth term is (x^n / n!).

            // The first term is simply x.
            term = x;
            seriesSum += term;

            // Each term (x^n / n!) equals the previous one times x, divided by n. Since x is a fixed point number,
            // multiplying by it requires dividing by ONE_20, but dividing by the non-fixed point n values does not.

            term = ((term * x) / ONE_20) / 2;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 3;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 4;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 5;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 6;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 7;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 8;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 9;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 10;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 11;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 12;
            seriesSum += term;

            // 12 Taylor terms are sufficient for 18 decimal precision.

            // We now have the first a_n (with no decimals), and the product of all other a_n present, and the Taylor
            // approximation of the exponentiation of the remainder (both with 20 decimals). All that remains is to multiply
            // all three (one 20 decimal fixed point multiplication, dividing by ONE_20, and one integer multiplication),
            // and then drop two digits to return an 18 decimal value.

            return (((product * seriesSum) / ONE_20) * firstAN) / 100;
        }
    }

    /**
     * @dev Logarithm (log(arg, base), with signed 18 decimal fixed point base and argument.
     */
    function log(int256 arg, int256 base) internal pure returns (int256) {
        unchecked {
            // This performs a simple base change: log(arg, base) = ln(arg) / ln(base).

            // Both logBase and logArg are computed as 36 decimal fixed point numbers, either by using ln_36, or by
            // upscaling.

            int256 logBase;
            if (LN_36_LOWER_BOUND < base && base < LN_36_UPPER_BOUND) {
                logBase = _ln_36(base);
            } else {
                logBase = _ln(base) * ONE_18;
            }

            int256 logArg;
            if (LN_36_LOWER_BOUND < arg && arg < LN_36_UPPER_BOUND) {
                logArg = _ln_36(arg);
            } else {
                logArg = _ln(arg) * ONE_18;
            }

            // When dividing, we multiply by ONE_18 to arrive at a result with 18 decimal places
            return (logArg * ONE_18) / logBase;
        }
    }

    /**
     * @dev Natural logarithm (ln(a)) with signed 18 decimal fixed point argument.
     */
    function ln(int256 a) internal pure returns (int256) {
        unchecked {
            // The real natural logarithm is not defined for negative numbers or zero.
            require(a > 0, Errors.OUT_OF_BOUNDS);
            if (LN_36_LOWER_BOUND < a && a < LN_36_UPPER_BOUND) {
                return _ln_36(a) / ONE_18;
            } else {
                return _ln(a);
            }
        }
    }

    /**
     * @dev Internal natural logarithm (ln(a)) with signed 18 decimal fixed point argument.
     */
    function _ln(int256 a) private pure returns (int256) {
        unchecked {
            if (a < ONE_18) {
                // Since ln(a^k) = k * ln(a), we can compute ln(a) as ln(a) = ln((1/a)^(-1)) = - ln((1/a)). If a is less
                // than one, 1/a will be greater than one, and this if statement will not be entered in the recursive call.
                // Fixed point division requires multiplying by ONE_18.
                return (-_ln((ONE_18 * ONE_18) / a));
            }

            // First, we use the fact that ln^(a * b) = ln(a) + ln(b) to decompose ln(a) into a sum of powers of two, which
            // we call x_n, where x_n == 2^(7 - n), which are the natural logarithm of precomputed quantities a_n (that is,
            // ln(a_n) = x_n). We choose the first x_n, x0, to equal 2^7 because the exponential of all larger powers cannot
            // be represented as 18 fixed point decimal numbers in 256 bits, and are therefore larger than a.
            // At the end of this process we will have the sum of all x_n = ln(a_n) that apply, and the remainder of this
            // decomposition, which will be lower than the smallest a_n.
            // ln(a) = k_0 * x_0 + k_1 * x_1 + ... + k_n * x_n + ln(remainder), where each k_n equals either 0 or 1.
            // We mutate a by subtracting a_n, making it the remainder of the decomposition.

            // For reasons related to how `exp` works, the first two a_n (e^(2^7) and e^(2^6)) are not stored as fixed point
            // numbers with 18 decimals, but instead as plain integers with 0 decimals, so we need to multiply them by
            // ONE_18 to convert them to fixed point.
            // For each a_n, we test if that term is present in the decomposition (if a is larger than it), and if so divide
            // by it and compute the accumulated sum.

            int256 sum = 0;
            if (a >= a0 * ONE_18) {
                a /= a0; // Integer, not fixed point division
                sum += x0;
            }

            if (a >= a1 * ONE_18) {
                a /= a1; // Integer, not fixed point division
                sum += x1;
            }

            // All other a_n and x_n are stored as 20 digit fixed point numbers, so we convert the sum and a to this format.
            sum *= 100;
            a *= 100;

            // Because further a_n are  20 digit fixed point numbers, we multiply by ONE_20 when dividing by them.

            if (a >= a2) {
                a = (a * ONE_20) / a2;
                sum += x2;
            }

            if (a >= a3) {
                a = (a * ONE_20) / a3;
                sum += x3;
            }

            if (a >= a4) {
                a = (a * ONE_20) / a4;
                sum += x4;
            }

            if (a >= a5) {
                a = (a * ONE_20) / a5;
                sum += x5;
            }

            if (a >= a6) {
                a = (a * ONE_20) / a6;
                sum += x6;
            }

            if (a >= a7) {
                a = (a * ONE_20) / a7;
                sum += x7;
            }

            if (a >= a8) {
                a = (a * ONE_20) / a8;
                sum += x8;
            }

            if (a >= a9) {
                a = (a * ONE_20) / a9;
                sum += x9;
            }

            if (a >= a10) {
                a = (a * ONE_20) / a10;
                sum += x10;
            }

            if (a >= a11) {
                a = (a * ONE_20) / a11;
                sum += x11;
            }

            // a is now a small number (smaller than a_11, which roughly equals 1.06). This means we can use a Taylor series
            // that converges rapidly for values of `a` close to one - the same one used in ln_36.
            // Let z = (a - 1) / (a + 1).
            // ln(a) = 2 * (z + z^3 / 3 + z^5 / 5 + z^7 / 7 + ... + z^(2 * n + 1) / (2 * n + 1))

            // Recall that 20 digit fixed point division requires multiplying by ONE_20, and multiplication requires
            // division by ONE_20.
            int256 z = ((a - ONE_20) * ONE_20) / (a + ONE_20);
            int256 z_squared = (z * z) / ONE_20;

            // num is the numerator of the series: the z^(2 * n + 1) term
            int256 num = z;

            // seriesSum holds the accumulated sum of each term in the series, starting with the initial z
            int256 seriesSum = num;

            // In each step, the numerator is multiplied by z^2
            num = (num * z_squared) / ONE_20;
            seriesSum += num / 3;

            num = (num * z_squared) / ONE_20;
            seriesSum += num / 5;

            num = (num * z_squared) / ONE_20;
            seriesSum += num / 7;

            num = (num * z_squared) / ONE_20;
            seriesSum += num / 9;

            num = (num * z_squared) / ONE_20;
            seriesSum += num / 11;

            // 6 Taylor terms are sufficient for 36 decimal precision.

            // Finally, we multiply by 2 (non fixed point) to compute ln(remainder)
            seriesSum *= 2;

            // We now have the sum of all x_n present, and the Taylor approximation of the logarithm of the remainder (both
            // with 20 decimals). All that remains is to sum these two, and then drop two digits to return a 18 decimal
            // value.

            return (sum + seriesSum) / 100;
        }
    }

    /**
     * @dev Intrnal high precision (36 decimal places) natural logarithm (ln(x)) with signed 18 decimal fixed point argument,
     * for x close to one.
     *
     * Should only be used if x is between LN_36_LOWER_BOUND and LN_36_UPPER_BOUND.
     */
    function _ln_36(int256 x) private pure returns (int256) {
        unchecked {
            // Since ln(1) = 0, a value of x close to one will yield a very small result, which makes using 36 digits
            // worthwhile.

            // First, we transform x to a 36 digit fixed point value.
            x *= ONE_18;

            // We will use the following Taylor expansion, which converges very rapidly. Let z = (x - 1) / (x + 1).
            // ln(x) = 2 * (z + z^3 / 3 + z^5 / 5 + z^7 / 7 + ... + z^(2 * n + 1) / (2 * n + 1))

            // Recall that 36 digit fixed point division requires multiplying by ONE_36, and multiplication requires
            // division by ONE_36.
            int256 z = ((x - ONE_36) * ONE_36) / (x + ONE_36);
            int256 z_squared = (z * z) / ONE_36;

            // num is the numerator of the series: the z^(2 * n + 1) term
            int256 num = z;

            // seriesSum holds the accumulated sum of each term in the series, starting with the initial z
            int256 seriesSum = num;

            // In each step, the numerator is multiplied by z^2
            num = (num * z_squared) / ONE_36;
            seriesSum += num / 3;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 5;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 7;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 9;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 11;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 13;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 15;

            // 8 Taylor terms are sufficient for 36 decimal precision.

            // All that remains is multiplying by 2 (non fixed point).
            return seriesSum * 2;
        }
    }

    function sqrt(uint256 x) internal pure returns (uint256) {
        return pow(x, uint256(ONE_18) / 2);
    }
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

/// @notice Defines different errors emitted by Gyroscope contracts
library Errors {
    string public constant TOKEN_AND_AMOUNTS_LENGTH_DIFFER = "1";
    string public constant TOO_MUCH_SLIPPAGE = "2";
    string public constant EXCHANGER_NOT_FOUND = "3";
    string public constant POOL_IDS_NOT_FOUND = "4";
    string public constant WOULD_UNBALANCE_GYROSCOPE = "5";
    string public constant VAULT_ALREADY_EXISTS = "6";
    string public constant VAULT_NOT_FOUND = "7";

    string public constant X_OUT_OF_BOUNDS = "20";
    string public constant Y_OUT_OF_BOUNDS = "21";
    string public constant PRODUCT_OUT_OF_BOUNDS = "22";
    string public constant INVALID_EXPONENT = "23";
    string public constant OUT_OF_BOUNDS = "24";
    string public constant ZERO_DIVISION = "25";
    string public constant ADD_OVERFLOW = "26";
    string public constant SUB_OVERFLOW = "27";
    string public constant MUL_OVERFLOW = "28";
    string public constant DIV_INTERNAL = "29";

    // User errors
    string public constant NOT_AUTHORIZED = "30";
    string public constant INVALID_ARGUMENT = "31";
    string public constant KEY_NOT_FOUND = "32";
    string public constant KEY_FROZEN = "33";
    string public constant INSUFFICIENT_BALANCE = "34";
    string public constant INVALID_ASSET = "35";

    // Oracle related errors
    string public constant ASSET_NOT_SUPPORTED = "40";
    string public constant STALE_PRICE = "41";
    string public constant NEGATIVE_PRICE = "42";
    string public constant INVALID_MESSAGE = "43";
    string public constant TOO_MUCH_VOLATILITY = "44";
    string public constant WETH_ADDRESS_NOT_FIRST = "44";
    string public constant ROOT_PRICE_NOT_GROUNDED = "45";
    string public constant NOT_ENOUGH_TWAPS = "46";
    string public constant ZERO_PRICE_TWAP = "47";
    string public constant INVALID_NUMBER_WEIGHTS = "48";

    //Vault safety check related errors
    string public constant A_VAULT_HAS_ALL_STABLECOINS_OFF_PEG = "51";
    string public constant NOT_SAFE_TO_MINT = "52";
    string public constant NOT_SAFE_TO_REDEEM = "53";
    string public constant AMOUNT_AND_PRICE_LENGTH_DIFFER = "54";
    string public constant TOKEN_PRICES_TOO_SMALL = "55";
    string public constant TRYING_TO_REDEEM_MORE_THAN_VAULT_CONTAINS = "56";
    string public constant CALLER_NOT_MOTHERBOARD = "57";
    string public constant CALLER_NOT_RESERVE_MANAGER = "58";

    string public constant VAULT_FLOW_TOO_HIGH = "60";
    string public constant OPERATION_SUCCEEDS_BUT_SAFETY_MODE_ACTIVATED = "61";
    string public constant ORACLE_GUARDIAN_TIME_LIMIT = "62";
    string public constant NOT_ENOUGH_FLOW_DATA = "63";
    string public constant SUPPLY_CAP_EXCEEDED = "64";
    string public constant SAFETY_MODE_ACTIVATED = "65";

    // misc errors
    string public constant REDEEM_AMOUNT_BUG = "100";
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.


pragma solidity ^0.8.4;

import "FixedPoint.sol";
import "Errors.sol";

/* solhint-disable private-vars-leading-underscore */

/* solhint-disable private-vars-leading-underscore */

/// @dev Signed fixed point operations based on Balancer's FixedPoint library.
/// Note: The `{mul,div}{Up,Down}Mag()` functions do *not* round up or down, respectively,
/// in a signed fashion (like ceil and floor operations), but *in absolute value* or in *magnitude*, i.e.,
/// towards 0. This is useful in some applications.
library SignedFixedPoint {
    int256 internal constant ONE = 1e18; // 18 decimal places
    int256 internal constant MAX_POW_RELATIVE_ERROR = 10000; // 10^(-14)

    // Minimum base for the power function when the exponent is 'free' (larger than ONE).
    int256 internal constant MIN_POW_BASE_FREE_EXPONENT = 0.7e18;

    /// @dev This rounds towards 0, i.e., down *in absolute value*!
    function mulDownMag(int256 a, int256 b) internal pure returns (int256) {
        int256 product = a * b;
        require(a == 0 || product / a == b, Errors.MUL_OVERFLOW);

        return product / ONE;
    }

    /// @dev This rounds away from 0, i.e., up *in absolute value*!
    function mulUpMag(int256 a, int256 b) internal pure returns (int256) {
        int256 product = a * b;
        require(a == 0 || product / a == b, Errors.MUL_OVERFLOW);

        // If product > 0, the result should be ceil(p/ONE) = floor((p-1)/ONE) + 1, where floor() is implicit. If
        // product < 0, the result should be floor(p/ONE) = ceil((p+1)/ONE) - 1, where ceil() is implicit.
        // Addition for signed numbers: Case selection so we round away from 0, not always up.
        if (product > 0) return ((product - 1) / ONE) + 1;
        else if (product < 0) return ((product + 1) / ONE) - 1;
        // product == 0
        else return 0;
    }

    /// @dev Rounds towards 0, i.e., down in absolute value.
    function divDownMag(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, Errors.ZERO_DIVISION);

        if (a == 0) {
            return 0;
        } else {
            int256 aInflated = a * ONE;
            require(aInflated / a == ONE, Errors.DIV_INTERNAL); // mul overflow

            return aInflated / b;
        }
    }

    /// @dev Rounds away from 0, i.e., up in absolute value.
    function divUpMag(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, Errors.ZERO_DIVISION);

        if (b < 0) {
            // Required so the below is correct.
            b = -b;
            a = -a;
        }

        if (a == 0) {
            return 0;
        } else {
            int256 aInflated = a * ONE;
            require(aInflated / a == ONE, Errors.DIV_INTERNAL); // mul overflow

            if (aInflated > 0) return ((aInflated - 1) / b) + 1;
            else return ((aInflated + 1) / b) - 1;
        }
    }

    // TODO not implementing the pow functions right now b/c it's annoying and slightly ill-defined, and we prob don't need them.

    /**
     * @dev Returns x^y, assuming both are fixed point numbers, rounding down. The result is guaranteed to not be above
     * the true value (that is, the error function expected - actual is always positive).
     * x must be non-negative! y can be negative.
     */
    // function powDown(int256 x, int256 y) internal pure returns (int256) {
    //     _require(x >= 0, Errors.X_OUT_OF_BOUNDS);
    //     if (y > 0) {
    //         uint256 uret = FixedPoint.powDown(uint256(x), uint256(y));
    //     } else {
    //         // TODO does this cost a lot of precision compared to a direct implementation (which we don't have)?
    //         return ONE.divDown(FixedPoint.powUp(uint256(x), uint256(-y)));
    //     }
    // }

    /**
     * @dev Returns x^y, assuming both are fixed point numbers, rounding up. The result is guaranteed to not be below
     * the true value (that is, the error function expected - actual is always negative).
     * x must be non-negative! y can be negative.
     */
    // function powUp(int256 x, int256 y) internal pure returns (int256) {
    //     _require(x >= 0, Errors.X_OUT_OF_BOUNDS);
    //     if (y > 0)
    //         return FixedPoint.powUp(x, y);
    //     else
    //         // TODO does this cost a lot of precision compared to a direct implementation (which we don't have)?
    //         return ONE.divUp(FixedPoint.powDown(x, -y));
    // }

    /**
     * @dev Returns the complement of a value (1 - x), capped to 0 if x is larger than 1.
     *
     * Useful when computing the complement for values with some level of relative error, as it strips this error and
     * prevents intermediate negative values.
     */
    function complement(int256 x) internal pure returns (int256) {
        if (x >= ONE || x <= 0) return 0;
        return ONE - x;
    }
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "IMinimalPoolView.sol";

interface IECLP is IMinimalPoolView {
    struct Vector2 {
        int256 x;
        int256 y;
    }

    // Note that all t values (not tp or tpp) could consist of uint's, as could all Params. But it's complicated to
    // convert all the time, so we make them all signed. We also store all intermediate values signed. An exception are
    // the functions that are used by the contract b/c there the values are stored unsigned.
    struct Params {
        // Price bounds (lower and upper). 0 < alpha < beta
        int256 alpha;
        int256 beta;
        // Rotation vector:
        // phi in (-90 degrees, 0] is the implicit rotation vector. It's stored as a point:
        int256 c; // c = cos(-phi) >= 0. rounded to 18 decimals
        int256 s; //  s = sin(-phi) >= 0. rounded to 18 decimals
        // Invariant: c^2 + s^2 == 1, i.e., the point (c, s) is normalized.
        // due to rounding, this may not = 1. The term dSq in DerivedParams corrects for this in extra precision

        // Stretching factor:
        int256 lambda; // lambda >= 1 where lambda == 1 is the circle.
    }

    // terms in this struct are stored in extra precision (38 decimals) with final decimal rounded down
    struct DerivedParams {
        Vector2 tauAlpha;
        Vector2 tauBeta;
        int256 u; // from (A chi)_y = lambda * u + v
        int256 v; // from (A chi)_y = lambda * u + v
        int256 w; // from (A chi)_x = w / lambda + z
        int256 z; // from (A chi)_x = w / lambda + z
        int256 dSq; // error in c^2 + s^2 = dSq, used to correct errors in c, s, tau, u,v,w,z calculations
        //int256 dAlpha; // normalization constant for tau(alpha)
        //int256 dBeta; // normalization constant for tau(beta)
    }

    function getECLPParams() external view returns (Params memory params, DerivedParams memory d);
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

interface IMinimalPoolView {
    function getInvariant() external view returns (uint256);

    function getLastInvariant() external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "BalancerLPSharePricing.sol";
import "BaseVaultPriceOracle.sol";

import "TypeConversion.sol";

import "IMinimalPoolView.sol";

abstract contract BaseBalancerPriceOracle is BaseVaultPriceOracle {
    using TypeConversion for DataTypes.PricedToken[];
    using FixedPoint for uint256;

    function getInvariantDivSupply(IMinimalPoolView pool) internal view virtual returns (uint256) {
        uint256 invariant = pool.getInvariant();
        uint256 totalSupply = pool.totalSupply();
        return invariant.divDown(totalSupply);
    }
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "IVaultPriceOracle.sol";

import "FixedPoint.sol";

abstract contract BaseVaultPriceOracle is IVaultPriceOracle {
    using FixedPoint for uint256;

    /// @inheritdoc IVaultPriceOracle
    function getPriceUSD(IGyroVault vault, DataTypes.PricedToken[] memory underlyingPricedTokens)
        external
        view
        returns (uint256)
    {
        uint256 poolTokenPriceUSD = getPoolTokenPriceUSD(vault, underlyingPricedTokens);
        return poolTokenPriceUSD.mulDown(vault.exchangeRate());
    }

    /// @notice returns the price of the underlying pool token (e.g. BPT token)
    /// rather than the price of the vault token itself
    function getPoolTokenPriceUSD(
        IGyroVault vaultAddress,
        DataTypes.PricedToken[] memory underlyingPricedTokens
    ) public view virtual returns (uint256);
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "DataTypes.sol";

import "IGyroVault.sol";

interface IVaultPriceOracle {
    /// @notice Quotes the USD price of `vault` tokens
    /// The quoted price is always scaled with 18 decimals regardless of the
    /// source used for the oracle.
    /// @param vault the vault of which the price is to be quoted
    /// @return the USD price of the vault token
    function getPriceUSD(IGyroVault vault, DataTypes.PricedToken[] memory underlyingPricedTokens)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

/// @notice Contains the data structures to express token routing
library DataTypes {
    /// @notice Contains a token and the amount associated with it
    struct MonetaryAmount {
        address tokenAddress;
        uint256 amount;
    }

    /// @notice Contains a token and the price associated with it
    struct PricedToken {
        address tokenAddress;
        bool isStable;
        uint256 price;
    }

    /// @notice A route from/to a token to a vault
    /// This is used to determine in which vault the token should be deposited
    /// or from which vault it should be withdrawn
    struct TokenToVaultMapping {
        address inputToken;
        address vault;
    }

    /// @notice Asset used to mint
    struct MintAsset {
        address inputToken;
        uint256 inputAmount;
        address destinationVault;
    }

    /// @notice Asset to redeem
    struct RedeemAsset {
        address outputToken;
        uint256 minOutputAmount;
        uint256 valueRatio;
        address originVault;
    }

    /// @notice Persisted metadata about the vault
    struct PersistedVaultMetadata {
        uint256 initialPrice;
        uint256 initialWeight;
        uint256 shortFlowMemory;
        uint256 shortFlowThreshold;
    }

    /// @notice Directional (in or out) flow data for the vaults
    struct DirectionalFlowData {
        uint128 shortFlow;
        uint64 lastSafetyBlock;
        uint64 lastSeenBlock;
    }

    /// @notice Bidirectional vault flow data
    struct FlowData {
        DirectionalFlowData inFlow;
        DirectionalFlowData outFlow;
    }

    /// @notice Vault flow direction
    enum Direction {
        In,
        Out,
        Both
    }

    /// @notice Vault address and direction for Oracle Guardian
    struct GuardedVaults {
        address vaultAddress;
        Direction direction;
    }

    /// @notice Vault with metadata
    struct VaultInfo {
        address vault;
        uint8 decimals;
        address underlying;
        uint256 price;
        PersistedVaultMetadata persistedMetadata;
        uint256 reserveBalance;
        uint256 currentWeight;
        uint256 idealWeight;
        PricedToken[] pricedTokens;
    }

    /// @notice Vault metadata
    struct VaultMetadata {
        address vault;
        uint256 idealWeight;
        uint256 currentWeight;
        uint256 resultingWeight;
        uint256 price;
        bool allStablecoinsOnPeg;
        bool atLeastOnePriceLargeEnough;
        bool vaultWithinEpsilon;
        PricedToken[] pricedTokens;
    }

    /// @notice Metadata to contain vaults metadata
    struct Metadata {
        VaultMetadata[] vaultMetadata;
        bool allVaultsWithinEpsilon;
        bool allStablecoinsAllVaultsOnPeg;
        bool allVaultsUsingLargeEnoughPrices;
        bool mint;
    }

    /// @notice Mint or redeem order struct
    struct Order {
        VaultWithAmount[] vaultsWithAmount;
        bool mint;
    }

    /// @notice Vault info with associated amount for order operation
    struct VaultWithAmount {
        VaultInfo vaultInfo;
        uint256 amount;
    }

    /// @notice state of the reserve (i.e., all the vaults)
    struct ReserveState {
        uint256 totalUSDValue;
        VaultInfo[] vaults;
    }
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "Vaults.sol";

import "IERC20Metadata.sol";

/// @notice A vault is one of the component of the reserve and has a one-to-one
/// mapping to an underlying pool (e.g. Balancer pool, Curve pool, Uniswap pool...)
/// It is itself an ERC-20 token that is used to track the ownership of the LP tokens
/// deposited in the vault
/// A vault can be associated with a strategy to generate yield on the deposited funds
interface IGyroVault is IERC20Metadata {
    /// @return The type of the vault
    function vaultType() external view returns (Vaults.Type);

    /// @return The token associated with this vault
    /// This can be any type of token but will likely be an LP token in practice
    function underlying() external view returns (address);

    /// @return The token associated with this vault
    /// In the case of an LP token, this will be the underlying tokens
    /// associated to it (e.g. [ETH, DAI] for a ETH/DAI pool LP token or [USDC] for aUSDC)
    /// In most cases, the tokens returned will not be LP tokens
    function getTokens() external view returns (IERC20[] memory);

    /// @return The total amount of underlying tokens in the vault
    function totalUnderlying() external view returns (uint256);

    /// @return The exchange rate between an underlying tokens and the token of this vault
    function exchangeRate() external view returns (uint256);

    /// @notice Deposits `underlyingAmount` of LP token supported
    /// and sends back the received vault tokens
    /// @param underlyingAmount the amount of underlying to deposit
    /// @return vaultTokenAmount the amount of vault token sent back
    function deposit(uint256 underlyingAmount, uint256 minVaultTokensOut)
        external
        returns (uint256 vaultTokenAmount);

    /// @notice Simlar to `deposit(uint256 underlyingAmount)` but credits the tokens
    /// to `beneficiary` instead of `msg.sender`
    function depositFor(
        address beneficiary,
        uint256 underlyingAmount,
        uint256 minVaultTokensOut
    ) external returns (uint256 vaultTokenAmount);

    /// @notice Dry-run version of deposit
    function dryDeposit(uint256 underlyingAmount, uint256 minVaultTokensOut)
        external
        view
        returns (uint256 vaultTokenAmount, string memory error);

    /// @notice Withdraws `vaultTokenAmount` of LP token supported
    /// and burns the vault tokens
    /// @param vaultTokenAmount the amount of vault token to withdraw
    /// @return underlyingAmount the amount of LP token sent back
    function withdraw(uint256 vaultTokenAmount, uint256 minUnderlyingOut)
        external
        returns (uint256 underlyingAmount);

    /// @notice Dry-run version of `withdraw`
    function dryWithdraw(uint256 vaultTokenAmount, uint256 minUnderlyingOut)
        external
        view
        returns (uint256 underlyingAmount, string memory error);

    /// @return The address of the current strategy used by the vault
    function strategy() external view returns (address);

    /// @notice Sets the address of the strategy to use for this vault
    /// This will be used through governance
    /// @param strategyAddress the address of the strategy contract that should follow the `IStrategy` interface
    function setStrategy(address strategyAddress) external;

    /// @return the block at which the vault has been deployed
    function deployedAt() external view returns (uint256);
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

library Vaults {
    enum Type {
        GENERIC,
        BALANCER_CPMM,
        BALANCER_2CLP,
        BALANCER_3CLP,
        BALANCER_ECLP
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "DataTypes.sol";
import "IECLP.sol";

library TypeConversion {
    function pluckPrices(DataTypes.PricedToken[] memory pricedTokens)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory prices = new uint256[](pricedTokens.length);
        for (uint256 i = 0; i < pricedTokens.length; i++) {
            prices[i] = pricedTokens[i].price;
        }
        return prices;
    }

    function downscaleVector(IECLP.Vector2 memory v) internal pure returns (IECLP.Vector2 memory) {
        return IECLP.Vector2(v.x / 1e20, v.y / 1e20);
    }

    function downscaleDerivedParams(IECLP.DerivedParams memory params)
        internal
        pure
        returns (IECLP.DerivedParams memory)
    {
        return
            IECLP.DerivedParams(
                downscaleVector(params.tauAlpha),
                downscaleVector(params.tauBeta),
                // the following variables are not used in the price calculation
                params.u,
                params.v,
                params.w,
                params.z,
                params.dSq
            );
    }
}