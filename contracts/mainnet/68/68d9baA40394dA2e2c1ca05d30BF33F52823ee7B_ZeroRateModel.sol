//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
  * @title 0VIX's IInterestRateModel Interface
  * @author 0VIX
  */
interface IInterestRateModel {
    /// @notice Indicator that this is an InterestRateModel contract (for inspection)
    function isInterestRateModel() external view returns(bool);

    /**
      * @notice Calculates the current borrow interest rate per timestmp
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @return The borrow rate per timestmp (as a percentage, and scaled by 1e18)
      */
    function getBorrowRate(uint cash, uint borrows, uint reserves) external view returns (uint);

    /**
      * @notice Calculates the current supply interest rate per timestmp
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @param reserveFactorMantissa The current reserve factor the market has
      * @return The supply rate per timestmp (as a percentage, and scaled by 1e18)
      */
    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) external view returns (uint);

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./interfaces/IInterestRateModel.sol";

/**
 * @title 0VIX's ZeroRateModel Contract
 * @author 0VIX
 */
contract ZeroRateModel is IInterestRateModel {
    bool public constant override isInterestRateModel = true;
    uint256 public constant timestampsPerYear = 31536000;
    /**
     * @notice borrow APR at Optimal utilization point (10%)
     */
    uint256 internal constant borrowAPRAtOptUtil = 0.1e18;
    /**
     * @notice optimal utilization point (80%)
     */
    uint256 internal constant optUtil = 0.8e18;
    /**
     * @notice borrow APR at 100% utilization (31,8%)
     */
    uint256 internal constant maxBorrowAPR = 0.318e18;

    /**
     * @notice The utilization point at which the curved multiplier is applied
     */
    uint256 internal constant kink = 0.6e18;

    uint256 internal constant paramA = 0.125e18; //  0.1/0.8
    uint256 internal constant paramB = 0.193e18; // 0.318 - (0.1 / 0.8)

    /**
     * @notice Calculates the utilization rate of the market: `borrows / (cash + borrows - reserves)`
     * @param cash The amount of cash in the market
     * @param borrows The amount of borrows in the market
     * @param reserves The amount of reserves in the market (currently unused)
     * @return The utilization rate as a mantissa between [0, 1e18]
     */
    function utilizationRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) public pure returns (uint256) {
        // Utilization rate is 0 when there are no borrows
        if (borrows == 0) {
            return 0;
        }

        return (borrows * 1e18) / (cash + borrows - reserves);
    }

    /**
     * @notice Calculates the current borrow rate per timestmp, with the error code expected by the market
     * @param cash The amount of cash in the market
     * @param borrows The amount of borrows in the market
     * @param reserves The amount of reserves in the market
     * @return borrowAPR The borrow rate percentage per timestmp as a mantissa (scaled by 1e18)
     */
    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) public pure override returns (uint256 borrowAPR) {
        borrowAPR = 0;
    }

    /**
     * @notice Calculates the current supply rate per timestmp
     * @param cash The amount of cash in the market
     * @param borrows The amount of borrows in the market
     * @param reserves The amount of reserves in the market
     * @param reserveFactorMantissa The current reserve factor for the market
     * @return supplyRate The supply rate percentage per timestmp as a mantissa (scaled by 1e18)
     */
    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactorMantissa
    ) public pure override returns (uint256 supplyRate) {
        uint256 oneMinusReserveFactor = uint256(1e18) - reserveFactorMantissa;
        uint256 borrowRate = getBorrowRate(cash, borrows, reserves);
        uint256 rateToPool = (borrowRate * oneMinusReserveFactor) / 1e18;
        supplyRate =
            (utilizationRate(cash, borrows, reserves) * rateToPool) /
            1e18;
    }
}