// SPDX-License-Identifier: Unlicensed
// Copyright © 2022 DeSure Inc

pragma solidity ^0.8.13;

import "./interfaces/IDesureDateTimeUtils.sol";

contract DesureDateTimeUtilsHour is IDesureDateTimeUtils {
    /*
     *  Basic utility to understand what is the current month number from the EPOCH
     *  TODO put what have inspired this
     */

    uint256 internal constant START_HOUR_DAY_MONTH_YEAR = 1671753600;//2022-12-23 00:00

    function isLeapYear(uint16 year) public pure returns (bool) {
        return true;
    }

    function leapYearsBefore(uint16 year) public pure returns (uint16) {
        return 0;
    }

    function getDaysInMonth(uint8 month, uint16 year) public pure returns (uint8) {
        return 0;
    }

    function getMonthYear(uint256 timestamp) public pure returns (uint16) {
        //This code for simulate by hour
        return uint16((timestamp - START_HOUR_DAY_MONTH_YEAR) / 3600);
    }

    function getYear(uint256 timestamp) public pure returns (uint16) {
        return 0;
    }

    function getCurrentMonthYear() view public returns (uint16)
    {
        return getMonthYear(block.timestamp);
    }

    function getNextMonthYear() view external returns (uint16)
    {
        return getCurrentMonthYear() + 1;
    }
}

// SPDX-License-Identifier: Unlicensed
// Copyright © 2022 DeSure Inc

pragma solidity ^0.8.13;

interface IDesureDateTimeUtils {
    function isLeapYear(uint16 year) pure external returns (bool);

    function leapYearsBefore(uint16 year) pure external returns (uint16);

    function getDaysInMonth(uint8 month, uint16 year) pure external returns (uint8);

    function getMonthYear(uint256 timestamp) pure external returns (uint16);

    function getYear(uint256 timestamp) pure external returns (uint16);

    function getCurrentMonthYear() view external returns (uint16);

    function getNextMonthYear() view external returns (uint16);

}