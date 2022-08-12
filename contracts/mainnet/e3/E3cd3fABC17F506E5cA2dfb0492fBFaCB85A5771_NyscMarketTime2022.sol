// SPDX-License-Identifier: BSD-4-Clause

pragma solidity ^0.8.13;

import "../Libs/DateTimeLibrary.sol";
import "../Interface/IMarketTime.sol";

contract NyscMarketTime2022 is IMarketTime {
    struct Date {
        uint256 day;
        uint256 month;
        uint256 year;
    }

    // Always set the Offset wrt UTC time
    uint256 public dayLightSavingEndEpoch = 1667714400; // EST
    uint256 public startTimeOffsetEDT; // 48600
    uint256 public endTimeOffsetEDT; // 72000
    uint256 public startTimeOffsetEST;
    uint256 public endTimeOffsetEST;

    // Mapping of a holidays
    // day => month => year => true/false [true -> it's a holiday, false -> not a holiday]
    mapping(uint256 => mapping(uint256 => mapping(uint256 => bool))) public holidays;

    constructor(uint256 _startTimeOffset, uint256 _endTimeOffset) {
        startTimeOffsetEDT = _startTimeOffset;
        endTimeOffsetEDT = _endTimeOffset;
        startTimeOffsetEST = startTimeOffsetEDT + 1 hours;
        endTimeOffsetEST = endTimeOffsetEDT + 1 hours;
    }

    function addHolidays(Date[] memory dateArr) public {
        for (uint256 i = 0; i < dateArr.length; i++) {
            holidays[dateArr[i].day][dateArr[i].month][dateArr[i].year] = true;
        }
    }

    function removeHolidays(Date memory date) public {
        holidays[date.day][date.month][date.year] = false;
    }

    function setOffsets(uint256 first, uint256 second) public {
        startTimeOffsetEDT = first;
        endTimeOffsetEDT = second;
        startTimeOffsetEST = first + 1 hours;
        endTimeOffsetEST = second + 1 hours;
    }

    function getMarketActiveTime(uint256 timestamp)
        external
        view
        override
        returns (uint256 startTimestamp, uint256 endTimestamp)
    {
        (uint256 day, uint256 month, uint256 year, ) = DateTimeLibrary.getAll(timestamp);
        if (!holidays[day][month][year]) {
            uint256 dayEpoch = DateTimeLibrary.startTimestampOfDay(day, month, year);
            if (timestamp <= dayLightSavingEndEpoch) {
                startTimestamp = dayEpoch + startTimeOffsetEDT;
                endTimestamp = dayEpoch + endTimeOffsetEDT;
            } else {
                startTimestamp = dayEpoch + startTimeOffsetEST;
                endTimestamp = dayEpoch + endTimeOffsetEST;
            }
            // Exception
            if (day == 24 && month == 11 && year == 2022) {
                endTimestamp = dayEpoch + 64800;
            }
        }
    }
}

// SPDX-License-Identifier: BSD-4-Clause

pragma solidity ^0.8.13;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.

library DateTimeLibrary {
    uint256 public constant SECONDS_PER_DAY = 24 * 60 * 60;
    int256 public constant OFFSET19700101 = 2440588;
    uint256 public constant WEEK_OFFSET = 345600;
    uint256 public constant DOW_FRI = 5;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   https://aa.usno.navy.mil/faq/JD_formula.html
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (uint256 _days) {
        require(year >= 1970, "Year not in range");
        int256 _year = int256(year);
        int256 _month = int256(month);
        int256 _day = int256(day);

        int256 __days = _day -
            32075 +
            (1461 * (_year + 4800 + (_month - 14) / 12)) /
            4 +
            (367 * (_month - 2 - ((_month - 14) / 12) * 12)) /
            12 -
            (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) /
            4 -
            OFFSET19700101;

        _days = uint256(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint256 _days)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        int256 __days = int256(_days);

        int256 L = __days + 68569 + OFFSET19700101;
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

    function timestampToDay(uint256 timestamp) internal pure returns (uint256 today) {
        uint256 year;
        uint256 month;
        uint256 day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        today = _daysFromDate(year, month, day);
    }

    function getMonth(uint256 timestamp) internal pure returns (uint256 month) {
        (, month, ) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getYear(uint256 timestamp) internal pure returns (uint256 year) {
        (year, , ) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getWeek(uint256 timestamp) internal pure returns (uint256 week) {
        week = ((timestamp + WEEK_OFFSET) / SECONDS_PER_DAY) / 7;
    }

    function getDayOfWeek(uint256 timestamp) internal pure returns (uint256 dayOfWeek) {
        uint256 _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = ((_days + 3) % 7) + 1;
    }

    function isWeekDay(uint256 timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }

    function startTimestampOfDay(
        uint256 day,
        uint256 month,
        uint256 year
    ) internal pure returns (uint256 timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }

    function getAll(uint256 timestamp)
        internal
        pure
        returns (
            uint256 day,
            uint256 month,
            uint256 year,
            uint256 week
        )
    {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        week = getWeek(timestamp);
    }
}

// SPDX-License-Identifier: BSD-4-Clause

pragma solidity ^0.8.13;

interface IMarketTime {
    function getMarketActiveTime(uint256 timestamp)
        external
        view
        returns (uint256 startTimestamp, uint256 endTimestamp);
}