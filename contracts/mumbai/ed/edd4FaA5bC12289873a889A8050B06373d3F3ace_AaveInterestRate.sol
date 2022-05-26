/**
 *Submitted for verification at polygonscan.com on 2022-05-25
*/

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IInterestRateModel {
    /**
     * @notice Calculates the current borrow interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserves The total amount of reserves the market has
     * @return The borrow rate per block (as a percentage, and scaled by 1e18)
     */
    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) external view returns (uint256);

    /**
     * @notice Calculates the current supply interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserves The total amount of reserves the market has
     * @param reserveFactorMantissa The current reserve factor the market has
     * @return The supply rate per block (as a percentage, and scaled by 1e18)
     */
    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactorMantissa
    ) external view returns (uint256);
}

/// math.sol -- mixin for inline numerical wizardry

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

/**
 * @title Fixed point WAD\RAY math contract
 * @notice Implements the fixed point arithmetic operations for WAD numbers (18 decimals) and RAY (27 decimals)
 * @dev Wad functions have a [w] prefix: wmul, wdiv. Ray functions have a [r] prefix: rmul, rdiv, rpow.
 * @author https://github.com/dapphub/ds-math
 **/

contract DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }

    function imin(int256 x, int256 y) internal pure returns (int256 z) {
        return x <= y ? x : y;
    }

    function imax(int256 x, int256 y) internal pure returns (int256 z) {
        return x >= y ? x : y;
    }

    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;

    //rounds to zero if x*y < WAD / 2
    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    //rounds to zero if x*y < WAD / 2
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    //rounds to zero if x*y < WAD / 2
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    //rounds to zero if x*y < RAY / 2
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

/**
 * @title AaveInterestRate contract
 * @notice Implements the calculation of the interest rates depending on the reserve state
 * @dev The model of interest rate is based on 2 slopes, one before the `OPTIMAL_UTILIZATION_RATE`
 * point of utilization and another from that one to 100%
 * @author Aave
 **/
contract AaveInterestRate is IInterestRateModel, DSMath {
    /**
     * @dev this constant represents the utilization rate at which the pool aims to obtain most competitive borrow rates.
     * Expressed in ray
     **/
    uint256 public immutable OPTIMAL_UTILIZATION_RATE;

    uint256 public immutable BLOCKS_PER_YEAR;
    /**
     * @dev This constant represents the excess utilization rate above the optimal. It's always equal to
     * 1-optimal utilization rate. Added as a constant here for gas optimizations.
     * Expressed in ray
     **/

    uint256 public immutable EXCESS_UTILIZATION_RATE;

    // Base variable borrow rate when Utilization rate = 0. Expressed in ray
    uint256 internal immutable _baseVariableBorrowRate;

    // Slope of the variable interest curve when utilization rate > 0 and <= OPTIMAL_UTILIZATION_RATE. Expressed in ray
    uint256 internal immutable _variableRateSlope1;

    // Slope of the variable interest curve when utilization rate > OPTIMAL_UTILIZATION_RATE. Expressed in ray
    uint256 internal immutable _variableRateSlope2;

    constructor(
        uint256 optimalUtilizationRate,
        uint256 baseVariableBorrowRate_,
        uint256 variableRateSlope1_,
        uint256 variableRateSlope2_,
        uint256 blocksPerYear
    ) {
        OPTIMAL_UTILIZATION_RATE = optimalUtilizationRate;
        EXCESS_UTILIZATION_RATE = RAY - (optimalUtilizationRate);
        _baseVariableBorrowRate = baseVariableBorrowRate_;
        _variableRateSlope1 = variableRateSlope1_;
        _variableRateSlope2 = variableRateSlope2_;
        BLOCKS_PER_YEAR = blocksPerYear;
    }

    function variableRateSlope1() external view returns (uint256) {
        return _variableRateSlope1;
    }

    function variableRateSlope2() external view returns (uint256) {
        return _variableRateSlope2;
    }

    function baseVariableBorrowRate() external view returns (uint256) {
        return _baseVariableBorrowRate;
    }

    function getMaxVariableBorrowRate() external view returns (uint256) {
        return
            _baseVariableBorrowRate + _variableRateSlope1 + _variableRateSlope2;
    }

    struct CalcInterestRatesLocalVars {
        uint256 currentVariableBorrowRate;
        uint256 currentLiquidityRate;
        uint256 utilizationRate;
    }

    /**
     * @dev Calculates the interest rates depending on the reserve's state and configurations.
     * @param availableLiquidity The liquidity available in the corresponding nToken
     * @param totalVariableDebt The total borrowed from the reserve at a variable rate
     * @param reserveFactor The reserve portion of the interest that goes to the treasury of the market
     * @return supplyRate The liquidity rate
     * @return borrowRate the variable borrow rate
     **/
    function calculateInterestRates(
        uint256 availableLiquidity,
        uint256 totalVariableDebt,
        uint256 reserveFactor
    ) public view returns (uint256 supplyRate, uint256 borrowRate) {
        CalcInterestRatesLocalVars memory vars;

        vars.utilizationRate = totalVariableDebt == 0
            ? 0
            : rdiv(totalVariableDebt, availableLiquidity + (totalVariableDebt));

        if (vars.utilizationRate > OPTIMAL_UTILIZATION_RATE) {
            uint256 excessUtilizationRateRatio = rdiv(
                vars.utilizationRate - (OPTIMAL_UTILIZATION_RATE),
                EXCESS_UTILIZATION_RATE
            );

            vars.currentVariableBorrowRate =
                _baseVariableBorrowRate +
                (_variableRateSlope1) +
                (rmul(_variableRateSlope2, excessUtilizationRateRatio));
        } else {
            vars.currentVariableBorrowRate =
                _baseVariableBorrowRate +
                rdiv(
                    rmul(vars.utilizationRate, _variableRateSlope1),
                    OPTIMAL_UTILIZATION_RATE
                );
        }

        vars.currentLiquidityRate = rmul(
            vars.currentVariableBorrowRate,
            RAY - reserveFactor * 1e9
        );

        return (
            vars.currentLiquidityRate / 1e9 / BLOCKS_PER_YEAR,
            vars.currentVariableBorrowRate / 1e9 / BLOCKS_PER_YEAR
        );
    }

    /**
     * @notice Calculates the current borrow interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @return rate The borrow rate per block (as a percentage, and scaled by 1e18)
     */
    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256
    ) external view override returns (uint256 rate) {
        (, rate) = calculateInterestRates(cash, borrows, 0);
    }

    /**
     * @notice Calculates the current supply interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserveFactor The current reserve factor the market has
     * @return rate The supply rate per block (as a percentage, and scaled by 1e18)
     */
    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256,
        uint256 reserveFactor
    ) external view override returns (uint256 rate) {
        (rate, ) = calculateInterestRates(cash, borrows, reserveFactor);
    }
}