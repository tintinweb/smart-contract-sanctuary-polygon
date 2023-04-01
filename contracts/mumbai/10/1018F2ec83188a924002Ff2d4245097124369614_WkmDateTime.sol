// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

library WkmDateTime {
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    int256 constant OFFSET19700101 = 2440588;

    function getDaysInMonth(uint256 year, uint256 month) public pure returns (uint256 daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = isLeapYear(year) ? 29 : 28;
        }
    }

    function isLeapYear(uint256 year) public pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }

    function addYears(
        uint256 timestamp,
        uint256 _years,
        int timeZoneOffset
    ) public pure returns (uint256 newTimestamp) {
        uint timestampWithoutOffset = resetTimezoneOffSet(timestamp, timeZoneOffset);
        (uint256 year, uint256 month, uint256 day) = daysToDate(timestampWithoutOffset / SECONDS_PER_DAY);
        year += _years;
        uint256 daysInMonth = getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        uint newTimestampWithoutOffset = daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            (timestampWithoutOffset % SECONDS_PER_DAY);
        newTimestamp = setTimezoneOffSet(newTimestampWithoutOffset, timeZoneOffset);
        require(newTimestamp >= timestamp);
    }

    function daysToDate(uint256 _days) public pure returns (uint256 year, uint256 month, uint256 day) {
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

    function daysFromDate(uint256 year, uint256 month, uint256 day) public pure returns (uint256 _days) {
        require(year >= 1970);
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

    function dailyCompareTo(uint256 date1, uint256 date2) public pure returns (int256 comparisonResult) {
        uint256 date1AtMidnight = date1 - (date1 % 1 days);
        uint256 date2AtMidnight = date2 - (date2 % 1 days);

        if (date1AtMidnight > date2AtMidnight) {
            comparisonResult = 1;
        } else if (date1AtMidnight < date2AtMidnight) {
            comparisonResult = -1;
        } else {
            comparisonResult = 0;
        }
    }

    function setDateAtMidday(uint256 date, int timeZoneOffset) public pure returns (uint256 dateAtMidday) {
        dateAtMidday = setDateAtMidnight(date, timeZoneOffset) + 43200 seconds; // 43200 seconds = 12h00m00s
    }

    function setDateAtMidnight(uint256 date, int timeZoneOffset) public pure returns (uint256 dateAtMidnight) {
        uint256 dateWithResetedOffset = resetTimezoneOffSet(date, timeZoneOffset);
        uint256 totalSecondsInDay = dateWithResetedOffset % 1 days;
        dateAtMidnight = setTimezoneOffSet(dateWithResetedOffset, timeZoneOffset) - totalSecondsInDay;
    }

    function setDateAt23h59m59s(uint256 date, int timeZoneOffset) public pure returns (uint256 dateAt23h59m59s) {
        dateAt23h59m59s = setDateAtMidnight(date, timeZoneOffset) + 86399 seconds; // 86399 seconds = 23h59m59s
    }

    function setTimezoneOffSet(uint date, int timeZoneOffset) public pure returns (uint256 dateWithOffSet) {
        if (timeZoneOffset >= 0) {
            dateWithOffSet = date - uint(timeZoneOffset) * 3600 seconds;
        } else {
            dateWithOffSet = date + uint(-timeZoneOffset) * 3600 seconds;
        }
    }

    function resetTimezoneOffSet(uint date, int timeZoneOffset) public pure returns (uint256 dateWithoutOffSet) {
        if (timeZoneOffset >= 0) {
            dateWithoutOffSet = date + uint(timeZoneOffset) * 3600 seconds;
        } else {
            dateWithoutOffSet = date - uint(-timeZoneOffset) * 3600 seconds;
        }
    }
}