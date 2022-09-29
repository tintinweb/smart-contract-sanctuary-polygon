/**
 *Submitted for verification at polygonscan.com on 2022-09-28
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

contract CalculateReward {

    function getReward(uint stakedamount_,
        uint stakedStartTime_,

        uint stakedEndTime_,
    uint unstakeTime_,
        uint8 tenure_,
        uint8 apr_
        
        )
        public
        pure
        returns (uint256 rewardClaimable_, uint256 penalty_,uint earnedAmount_)
    {
        // Data memory s = stakeStatus[account].stakeDetails[_stakeID];

        (uint256 denominatorAPR, uint256 lockedDays, uint256 lockedMonths) = (
            100,
            0,
            0
        );
        if (unstakeTime_ < stakedEndTime_) {
           { lockedDays = (unstakeTime_ - stakedStartTime_) / 86400; }// March 27, 2024.-  25 sep,2022 = 18 months(47340000) / 86400 seconds  = 547 days 
            lockedMonths = diffMonths(stakedStartTime_, unstakeTime_); 
        } else {
            lockedDays = uint256(tenure_) * 365; // 3 * 365 = 1095 days
            lockedMonths = diffMonths(stakedStartTime_, unstakeTime_); 
        }
        uint256 earnedAmount = (stakedamount_ * lockedDays * uint256(apr_)) /
            (365 * denominatorAPR);

        (uint256 rewardClaimable, uint256 penalty) = getPenalty(
            lockedMonths,
            earnedAmount
        );

        return (rewardClaimable, penalty,earnedAmount);
    }

    function getPenalty(uint256 _months, uint256 _earnedAmount)
        internal
        pure
        returns (uint256, uint256)
    {
        uint256 deduction;
        if (_months < 6) {
            deduction = (_earnedAmount * 75) / 100;
            return (uint256(_earnedAmount - deduction), deduction);
        } else if (_months >= 6 && _months <= 12) {
            deduction = (_earnedAmount * 50) / 100;
            return (uint256(_earnedAmount - deduction), deduction);
        } else if (_months >= 13 && _months <= 19) {
            deduction = (_earnedAmount * 25) / 100;
            return (uint256(_earnedAmount - deduction), deduction);
        } else {
            return (_earnedAmount, 0);
        }
    }

    function diffMonths(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256 _months)
    {
        if (fromTimestamp >= toTimestamp) revert();
        (uint256 fromYear, uint256 fromMonth, ) = timeHelper(
            fromTimestamp / 86400
        );
        (uint256 toYear, uint256 toMonth, ) = timeHelper(toTimestamp / 86400);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }

    function timeHelper(uint256 _days)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        int256 __days = int256(_days);

        int256 L = __days + 68569 + 2440588;
        int256 N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int256 _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int256 _month = (80 * L) / 2447;
        int256 _day = L - (2447 * _month) / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint256(_year);
        month = uint256(_month);
        day = uint256(_day);
    }
}

// 1664370594
// 1695882863
// 1677566063
// 
// ----- 3yrs

// 1740724464

// stakedamount_:102
// stakedStartTime_:1664370594
// stakedEndTime_:1740724464
// unstakeTime_:1740724465
// tenure_:3
// apr_: 11