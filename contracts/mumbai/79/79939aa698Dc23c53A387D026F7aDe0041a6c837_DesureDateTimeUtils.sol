// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.9;

import "./interfaces/IDesureDateTimeUtils.sol";

contract DesureDateTimeUtils is IDesureDateTimeUtils {
    /*
     *  Basic utility to understand what is the current month number from the EPOCH
     *  TODO put what have inspired this
     */

    uint256 constant DAY_IN_SECONDS = 86400;
    uint256 constant YEAR_IN_SECONDS = 31536000;
    uint256 constant LEAP_YEAR_IN_SECONDS = 31622400;
    uint16 constant START_MONTH_YEAR = 2022 * 12 + 9;

    uint16 public constant ORIGIN_YEAR = 1970;

    function isLeapYear(uint16 year) public pure returns (bool) {
        if (year % 400 == 0) {
            return true;
        }
        if (year % 100 == 0) {
            return false;
        }
        if (year % 4 == 0) {
            return true;
        }
        return false;
    }

    function leapYearsBefore(uint16 year) public pure returns (uint16) {
        year -= 1;
        return year / 4 - year / 100 + year / 400;
    }

    function getDaysInMonth(uint8 month, uint16 year) public pure returns (uint8) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            return 31;
        }
        else if (month == 4 || month == 6 || month == 9 || month == 11) {
            return 30;
        }
        else if (isLeapYear(year)) {
            return 29;
        }
        else {
            return 28;
        }
    }

    function getMonthYear(uint256 timestamp) public pure returns (uint16) {
        uint256 secondsAccountedFor = 0;
        uint8 i;
        uint16 result;
        uint16 numLeapYears;

        uint16 curr_year = getYear(timestamp);
        result = uint16(curr_year * 12);

        numLeapYears = leapYearsBefore(curr_year) - leapYearsBefore(ORIGIN_YEAR);
        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
        secondsAccountedFor += YEAR_IN_SECONDS * (curr_year - ORIGIN_YEAR - numLeapYears);

        uint secondsInMonth;
        for (i = 1; i <= 12; i++) {
            secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, curr_year);
            if (secondsInMonth + secondsAccountedFor > timestamp) {
                result += i;
                break;
            }
            secondsAccountedFor += secondsInMonth;
        }
        return result;
    }

    function getYear(uint256 timestamp) public pure returns (uint16) {
        uint256 secondsAccountedFor = 0;
        uint16 year;
        uint16 numLeapYears;

        year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);

        numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
        secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

        while (secondsAccountedFor > timestamp) {
            if (isLeapYear(uint16(year - 1))) {
                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
            }
            else {
                secondsAccountedFor -= YEAR_IN_SECONDS;
            }
            year -= 1;
        }
        return year;
    }

    function getCurrentMonthYear() view public returns (uint16)
    {
        return getMonthYear(block.timestamp) - START_MONTH_YEAR;
    }

    function getNextMonthYear() view external returns (uint16)
    {
        return getCurrentMonthYear() + 1;
    }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.9;

interface IDesureDateTimeUtils {
    function isLeapYear(uint16 year) pure external returns (bool);

    function leapYearsBefore(uint16 year) pure external returns (uint16);

    function getDaysInMonth(uint8 month, uint16 year) pure external returns (uint8);

    function getMonthYear(uint256 timestamp) pure external returns (uint16);

    function getYear(uint256 timestamp) pure external returns (uint16);

    function getCurrentMonthYear() view external returns (uint16);

    function getNextMonthYear() view external returns (uint16);

}