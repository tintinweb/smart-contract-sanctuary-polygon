// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;

import "./interfaces/IFinancialParams.sol";
import "./interfaces/IRevenueSplitCalculator.sol";

contract RevenueSplitCalculator is IRevenueSplitCalculator {

    /* =====================================================
                          CONSTANTS
    ===================================================== */

    /// Constant to denominate the percentages in
    uint256 constant public ONE_HUNDRED_PERCENT = 10_000;
 

    /* =====================================================
                          FUNCTIONS
    ===================================================== */
    
    function getProfitRates(FinancialParams memory params, uint256 amount)
        public
        pure
        override
        returns (FinancialParams memory, uint256)
    {
        // If there are `cityCosts` to cover
        if (params.cityCosts > 0) {
            // If the `amount` is less than those costs
            if (amount < params.cityCosts) {
                // Subtract `amount` from `cityCosts`
                params.cityCosts -= amount;
                // Zero amount
                amount = 0;

                return (params, amount);
            }
            // If the `amount` is more than those costs
            else if (amount > params.cityCosts) {
                // Subtract `cityCosts` from amount
                amount -= params.cityCosts;
                // Zero `cityCosts`
                params.cityCosts = 0;
            }
        }

        
        // If there are `globalCosts` to cover
        if (params.globalCosts > 0) {
            // If the `amount` is less than those costs
            if (amount < params.globalCosts) {
                // Subtract `amount` from `globalCosts`
                params.globalCosts -= amount;
                // Zero amount
                amount = 0;
                
                return (params, amount);
            }
            // If the `amount` is more than those costs
            else if (amount > params.globalCosts) {
                // Subtract `globalCosts` from amount
                amount -= params.globalCosts;
                // Zero `globalCosts`
                params.globalCosts = 0;
            }
        }

        // Calculate current Dao Profit Rate (DPR), based on where current profit for Lease compared to the effective target
        //                                   profit
        // currentDPR = DPR  * 100% * —————————————————————
        //                             target * hurdleRate
        if (params.profit * ONE_HUNDRED_PERCENT < params.target * params.hurdleRate) {
            params.daoProfitRate = params.daoProfitRate * ONE_HUNDRED_PERCENT * params.profit / (params.target * params.hurdleRate);
        }

        // Add amount to profit
        params.profit += amount;

        // Calculate amount going to DAO
        uint256 amountToDao = amount * params.daoProfitRate / ONE_HUNDRED_PERCENT;

        // Store the amount that goes to Expense Wallet in target
        params.target = amount - amountToDao;

        return (params, amountToDao);
    }
}

// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;
interface IFinancialParams {
    struct FinancialParams {
        /// global operation cost to be collected before spliting profit to DAO
        uint256 globalCosts;
        /// cityCosts to be collected before spliting profit to DAO
        uint256 cityCosts;
        /// final rate for spliting profit once profit of a lease reaches target
        uint256 hurdleRate;
        /// current rate for spliting profit
        uint256 daoProfitRate;
        /// target profit for each lease
        uint256 target;
        /// accumulative profit for each lease
        uint256 profit;
    }
}

// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;

import "./IFinancialParams.sol";

interface IRevenueSplitCalculator is IFinancialParams {


    function getProfitRates(FinancialParams memory params, uint256 amount) external returns (FinancialParams memory, uint256 );

}