/**
 *Submitted for verification at polygonscan.com on 2022-07-17
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

library PercentCalculator {
    uint32 constant MAX_PERCENT = 100_00000;

    function getQuantityByTotalAndPercent(uint256 totalCount, uint256 percent)
        public
        pure
        returns (uint256)
    {
        if (percent == 0) return 0;
        require(percent <= MAX_PERCENT, "Incorrect percent");
        return (totalCount * percent) / MAX_PERCENT;
    }

    function getNextStepPercent(uint256 value, uint256 minBidPrice)
        public
        pure
        returns (uint256)
    {
        return ((value * MAX_PERCENT) / minBidPrice) - MAX_PERCENT;
    }
}