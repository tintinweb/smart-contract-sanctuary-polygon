// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.9;

import "./interfaces/IDesureDateTimeUtils.sol";

contract DesureDateTimeUtils is IDesureDateTimeUtils {
    /*
     *  Basic utility to understand what is the current month number from the EPOCH
     *  TODO put what have inspired this
     */
    struct _DateTime {
        uint16 year;
        uint8 month;
        uint8 day;
        uint16 day_of_year;
        uint8 hour;
        uint8 minute;
        uint8 second;
        uint8 weekday;
    }

    uint256 constant DAY_IN_SECONDS = 86400;
    uint256 constant YEAR_IN_SECONDS = 31536000;
    uint256 constant LEAP_YEAR_IN_SECONDS = 31622400;
    uint16 internal constant START_MONTH_YEAR = 2022 * 12 + 9;
    uint16 internal constant START_DAY_MONTH_YEAR = 19307;//2022-11-11

    uint constant HOUR_IN_SECONDS = 3600;
    uint constant MINUTE_IN_SECONDS = 60;
    uint16 constant ORIGIN_YEAR = 1970;


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

    //// For Test Simulate
    function getNumberDay(uint256 timestamp) public pure returns (uint16) {
        uint256 secondsAccountedFor = 0;
        uint16 i;
        uint16 result;
        uint16 numLeapYears;
        uint16 curr_year = getYear(timestamp);

        numLeapYears = leapYearsBefore(curr_year) - leapYearsBefore(ORIGIN_YEAR);
        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
        secondsAccountedFor += YEAR_IN_SECONDS * (curr_year - ORIGIN_YEAR - numLeapYears);
        result = uint16(secondsAccountedFor / DAY_IN_SECONDS);

        uint256 secondsCount = 0;
        for (i = 1; i <= (isLeapYear(curr_year) ? 366: 365); i++) {//TODO check isLeapYear and 366
            secondsCount = uint(DAY_IN_SECONDS * i);
            if (secondsCount + secondsAccountedFor > timestamp) {
                result += i;
                break;
            }
        }
        return result;
    }

    function getNumberDayEmulate() view public returns (uint)
    {
        return getNumberDay(block.timestamp) - START_DAY_MONTH_YEAR;
    }

    function getCurrentMonthYearEmulate() view public returns (uint)
    {
        return getDayOfYear(block.timestamp);
    }

    function getCurrentMonthYearEmulateStart() view public returns (uint)
    {
        // Start point from 11.11.2022
        return getDayOfYear(toTimestamp(2022, 11, 11, 0, 0, 0));
    }

    function getMonth(uint timestamp) public pure returns (uint8) {
        return parseTimestamp(timestamp).month;
    }

    function getDay(uint timestamp) public pure returns (uint8) {
        return parseTimestamp(timestamp).day;
    }

    function getDayOfYear(uint timestamp) public pure returns (uint16) {
        return parseTimestamp(timestamp).day_of_year;
    }

    function getHour(uint timestamp) public pure returns (uint8) {
        return uint8((timestamp / 60 / 60) % 24);
    }

    function getMinute(uint timestamp) public pure returns (uint8) {
        return uint8((timestamp / 60) % 60);
    }

    function getSecond(uint timestamp) public pure returns (uint8) {
        return uint8(timestamp % 60);
    }

    function getWeekday(uint timestamp) public pure returns (uint8) {
        return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) public pure returns (uint timestamp) {
        uint16 i;

        // Year
        for (i = ORIGIN_YEAR; i < year; i++) {
            if (isLeapYear(i)) {
                timestamp += LEAP_YEAR_IN_SECONDS;
            }
            else {
                timestamp += YEAR_IN_SECONDS;
            }
        }

        // Month
        uint8[12] memory monthDayCounts;
        monthDayCounts[0] = 31;
        if (isLeapYear(year)) {
            monthDayCounts[1] = 29;
        }
        else {
            monthDayCounts[1] = 28;
        }
        monthDayCounts[2] = 31;
        monthDayCounts[3] = 30;
        monthDayCounts[4] = 31;
        monthDayCounts[5] = 30;
        monthDayCounts[6] = 31;
        monthDayCounts[7] = 31;
        monthDayCounts[8] = 30;
        monthDayCounts[9] = 31;
        monthDayCounts[10] = 30;
        monthDayCounts[11] = 31;

        for (i = 1; i < month; i++) {
            timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
        }

        // Day
        timestamp += DAY_IN_SECONDS * (day - 1);

        // Hour
        timestamp += HOUR_IN_SECONDS * (hour);

        // Minute
        timestamp += MINUTE_IN_SECONDS * (minute);

        // Second
        timestamp += second;

        return timestamp;
    }

    function parseTimestamp(uint timestamp) internal pure returns (_DateTime memory dt) {
        uint secondsAccountedFor = 0;
        uint buf;
        uint8 i;
        uint16 countDays = 0;

        // Year
        dt.year = getYear(timestamp);
        buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
        secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

        // Month
        uint secondsInMonth;
        for (i = 1; i <= 12; i++) {
            secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
            if (secondsInMonth + secondsAccountedFor > timestamp) {
                dt.month = i;
                break;
            }
            secondsAccountedFor += secondsInMonth;
            countDays += uint16(getDaysInMonth(i, dt.year));
        }

        // Day
        for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
            if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                dt.day = i;
                dt.day_of_year = countDays + uint16(dt.day);
                break;
            }
            secondsAccountedFor += DAY_IN_SECONDS;
        }

        // Hour
        dt.hour = getHour(timestamp);

        // Minute
        dt.minute = getMinute(timestamp);

        // Second
        dt.second = getSecond(timestamp);

        // Day of week.
        dt.weekday = getWeekday(timestamp);
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