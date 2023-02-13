/**
 *Submitted for verification at polygonscan.com on 2023-02-13
*/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: https://github.com/RollaProject/solidity-datetime/blob/master/contracts/DateTime.sol


pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// DateTime Library v2.0
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
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library DateTime {
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant SECONDS_PER_HOUR = 60 * 60;
    uint256 constant SECONDS_PER_MINUTE = 60;
    int256 constant OFFSET19700101 = 2440588;

    uint256 constant DOW_MON = 1;
    uint256 constant DOW_TUE = 2;
    uint256 constant DOW_WED = 3;
    uint256 constant DOW_THU = 4;
    uint256 constant DOW_FRI = 5;
    uint256 constant DOW_SAT = 6;
    uint256 constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint256 year, uint256 month, uint256 day) internal pure returns (uint256 _days) {
        require(year >= 1970);
        int256 _year = int256(year);
        int256 _month = int256(month);
        int256 _day = int256(day);

        int256 __days = _day - 32075 + (1461 * (_year + 4800 + (_month - 14) / 12)) / 4
            + (367 * (_month - 2 - ((_month - 14) / 12) * 12)) / 12
            - (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) / 4 - OFFSET19700101;

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
    function _daysToDate(uint256 _days) internal pure returns (uint256 year, uint256 month, uint256 day) {
        unchecked {
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
    }

    function timestampFromDate(uint256 year, uint256 month, uint256 day) internal pure returns (uint256 timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }

    function timestampFromDateTime(
        uint256 year,
        uint256 month,
        uint256 day,
        uint256 hour,
        uint256 minute,
        uint256 second
    )
        internal
        pure
        returns (uint256 timestamp)
    {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR
            + minute * SECONDS_PER_MINUTE + second;
    }

    function timestampToDate(uint256 timestamp) internal pure returns (uint256 year, uint256 month, uint256 day) {
        unchecked {
            (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        }
    }

    function timestampToDateTime(uint256 timestamp)
        internal
        pure
        returns (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second)
    {
        unchecked {
            (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
            uint256 secs = timestamp % SECONDS_PER_DAY;
            hour = secs / SECONDS_PER_HOUR;
            secs = secs % SECONDS_PER_HOUR;
            minute = secs / SECONDS_PER_MINUTE;
            second = secs % SECONDS_PER_MINUTE;
        }
    }

    function isValidDate(uint256 year, uint256 month, uint256 day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint256 daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }

    function isValidDateTime(uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second)
        internal
        pure
        returns (bool valid)
    {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }

    function isLeapYear(uint256 timestamp) internal pure returns (bool leapYear) {
        (uint256 year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }

    function _isLeapYear(uint256 year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }

    function isWeekDay(uint256 timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }

    function isWeekEnd(uint256 timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }

    function getDaysInMonth(uint256 timestamp) internal pure returns (uint256 daysInMonth) {
        (uint256 year, uint256 month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }

    function _getDaysInMonth(uint256 year, uint256 month) internal pure returns (uint256 daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }

    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint256 timestamp) internal pure returns (uint256 dayOfWeek) {
        uint256 _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = ((_days + 3) % 7) + 1;
    }

    function getYear(uint256 timestamp) internal pure returns (uint256 year) {
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getMonth(uint256 timestamp) internal pure returns (uint256 month) {
        (, month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getDay(uint256 timestamp) internal pure returns (uint256 day) {
        (,, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getHour(uint256 timestamp) internal pure returns (uint256 hour) {
        uint256 secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }

    function getMinute(uint256 timestamp) internal pure returns (uint256 minute) {
        uint256 secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }

    function getSecond(uint256 timestamp) internal pure returns (uint256 second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint256 timestamp, uint256 _years) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addMonths(uint256 timestamp, uint256 _months) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = ((month - 1) % 12) + 1;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }

    function addHours(uint256 timestamp, uint256 _hours) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }

    function addMinutes(uint256 timestamp, uint256 _minutes) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }

    function addSeconds(uint256 timestamp, uint256 _seconds) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint256 timestamp, uint256 _years) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    function subMonths(uint256 timestamp, uint256 _months) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint256 yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = (yearMonth % 12) + 1;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    function subDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }

    function subHours(uint256 timestamp, uint256 _hours) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }

    function subMinutes(uint256 timestamp, uint256 _minutes) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }

    function subSeconds(uint256 timestamp, uint256 _seconds) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _years) {
        require(fromTimestamp <= toTimestamp);
        (uint256 fromYear,,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint256 toYear,,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }

    function diffMonths(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _months) {
        require(fromTimestamp <= toTimestamp);
        (uint256 fromYear, uint256 fromMonth,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint256 toYear, uint256 toMonth,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }

    function diffDays(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }

    function diffHours(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }

    function diffMinutes(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }

    function diffSeconds(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}

// File: https://github.com/RollaProject/solidity-datetime/blob/master/contracts/DateTimeContract.sol


pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// DateTime Library v2.0 - Contract Instance
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/DateTime
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
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018.
//
// GNU Lesser General Public License 3.0
// https://www.gnu.org/licenses/lgpl-3.0.en.html
// ----------------------------------------------------------------------------


contract DateTimeContract {
    uint256 public constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 public constant SECONDS_PER_HOUR = 60 * 60;
    uint256 public constant SECONDS_PER_MINUTE = 60;
    int256 public constant OFFSET19700101 = 2440588;

    uint256 public constant DOW_MON = 1;
    uint256 public constant DOW_TUE = 2;
    uint256 public constant DOW_WED = 3;
    uint256 public constant DOW_THU = 4;
    uint256 public constant DOW_FRI = 5;
    uint256 public constant DOW_SAT = 6;
    uint256 public constant DOW_SUN = 7;

    function _now() public view returns (uint256 timestamp) {
        timestamp = block.timestamp;
    }

    function _nowDateTime()
        public
        view
        returns (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second)
    {
        (year, month, day, hour, minute, second) = DateTime.timestampToDateTime(block.timestamp);
    }

    function _daysFromDate(uint256 year, uint256 month, uint256 day) public pure returns (uint256 _days) {
        return DateTime._daysFromDate(year, month, day);
    }

    function _daysToDate(uint256 _days) public pure returns (uint256 year, uint256 month, uint256 day) {
        return DateTime._daysToDate(_days);
    }

    function timestampFromDate(uint256 year, uint256 month, uint256 day) public pure returns (uint256 timestamp) {
        return DateTime.timestampFromDate(year, month, day);
    }

    function timestampFromDateTime(
        uint256 year,
        uint256 month,
        uint256 day,
        uint256 hour,
        uint256 minute,
        uint256 second
    )
        public
        pure
        returns (uint256 timestamp)
    {
        return DateTime.timestampFromDateTime(year, month, day, hour, minute, second);
    }

    function timestampToDate(uint256 timestamp) public pure returns (uint256 year, uint256 month, uint256 day) {
        (year, month, day) = DateTime.timestampToDate(timestamp);
    }

    function timestampToDateTime(uint256 timestamp)
        public
        pure
        returns (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second)
    {
        (year, month, day, hour, minute, second) = DateTime.timestampToDateTime(timestamp);
    }

    function isValidDate(uint256 year, uint256 month, uint256 day) public pure returns (bool valid) {
        valid = DateTime.isValidDate(year, month, day);
    }

    function isValidDateTime(uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second)
        public
        pure
        returns (bool valid)
    {
        valid = DateTime.isValidDateTime(year, month, day, hour, minute, second);
    }

    function isLeapYear(uint256 timestamp) public pure returns (bool leapYear) {
        leapYear = DateTime.isLeapYear(timestamp);
    }

    function _isLeapYear(uint256 year) public pure returns (bool leapYear) {
        leapYear = DateTime._isLeapYear(year);
    }

    function isWeekDay(uint256 timestamp) public pure returns (bool weekDay) {
        weekDay = DateTime.isWeekDay(timestamp);
    }

    function isWeekEnd(uint256 timestamp) public pure returns (bool weekEnd) {
        weekEnd = DateTime.isWeekEnd(timestamp);
    }

    function getDaysInMonth(uint256 timestamp) public pure returns (uint256 daysInMonth) {
        daysInMonth = DateTime.getDaysInMonth(timestamp);
    }

    function _getDaysInMonth(uint256 year, uint256 month) public pure returns (uint256 daysInMonth) {
        daysInMonth = DateTime._getDaysInMonth(year, month);
    }

    function getDayOfWeek(uint256 timestamp) public pure returns (uint256 dayOfWeek) {
        dayOfWeek = DateTime.getDayOfWeek(timestamp);
    }

    function getYear(uint256 timestamp) public pure returns (uint256 year) {
        year = DateTime.getYear(timestamp);
    }

    function getMonth(uint256 timestamp) public pure returns (uint256 month) {
        month = DateTime.getMonth(timestamp);
    }

    function getDay(uint256 timestamp) public pure returns (uint256 day) {
        day = DateTime.getDay(timestamp);
    }

    function getHour(uint256 timestamp) public pure returns (uint256 hour) {
        hour = DateTime.getHour(timestamp);
    }

    function getMinute(uint256 timestamp) public pure returns (uint256 minute) {
        minute = DateTime.getMinute(timestamp);
    }

    function getSecond(uint256 timestamp) public pure returns (uint256 second) {
        second = DateTime.getSecond(timestamp);
    }

    function addYears(uint256 timestamp, uint256 _years) public pure returns (uint256 newTimestamp) {
        newTimestamp = DateTime.addYears(timestamp, _years);
    }

    function addMonths(uint256 timestamp, uint256 _months) public pure returns (uint256 newTimestamp) {
        newTimestamp = DateTime.addMonths(timestamp, _months);
    }

    function addDays(uint256 timestamp, uint256 _days) public pure returns (uint256 newTimestamp) {
        newTimestamp = DateTime.addDays(timestamp, _days);
    }

    function addHours(uint256 timestamp, uint256 _hours) public pure returns (uint256 newTimestamp) {
        newTimestamp = DateTime.addHours(timestamp, _hours);
    }

    function addMinutes(uint256 timestamp, uint256 _minutes) public pure returns (uint256 newTimestamp) {
        newTimestamp = DateTime.addMinutes(timestamp, _minutes);
    }

    function addSeconds(uint256 timestamp, uint256 _seconds) public pure returns (uint256 newTimestamp) {
        newTimestamp = DateTime.addSeconds(timestamp, _seconds);
    }

    function subYears(uint256 timestamp, uint256 _years) public pure returns (uint256 newTimestamp) {
        newTimestamp = DateTime.subYears(timestamp, _years);
    }

    function subMonths(uint256 timestamp, uint256 _months) public pure returns (uint256 newTimestamp) {
        newTimestamp = DateTime.subMonths(timestamp, _months);
    }

    function subDays(uint256 timestamp, uint256 _days) public pure returns (uint256 newTimestamp) {
        newTimestamp = DateTime.subDays(timestamp, _days);
    }

    function subHours(uint256 timestamp, uint256 _hours) public pure returns (uint256 newTimestamp) {
        newTimestamp = DateTime.subHours(timestamp, _hours);
    }

    function subMinutes(uint256 timestamp, uint256 _minutes) public pure returns (uint256 newTimestamp) {
        newTimestamp = DateTime.subMinutes(timestamp, _minutes);
    }

    function subSeconds(uint256 timestamp, uint256 _seconds) public pure returns (uint256 newTimestamp) {
        newTimestamp = DateTime.subSeconds(timestamp, _seconds);
    }

    function diffYears(uint256 fromTimestamp, uint256 toTimestamp) public pure returns (uint256 _years) {
        _years = DateTime.diffYears(fromTimestamp, toTimestamp);
    }

    function diffMonths(uint256 fromTimestamp, uint256 toTimestamp) public pure returns (uint256 _months) {
        _months = DateTime.diffMonths(fromTimestamp, toTimestamp);
    }

    function diffDays(uint256 fromTimestamp, uint256 toTimestamp) public pure returns (uint256 _days) {
        _days = DateTime.diffDays(fromTimestamp, toTimestamp);
    }

    function diffHours(uint256 fromTimestamp, uint256 toTimestamp) public pure returns (uint256 _hours) {
        _hours = DateTime.diffHours(fromTimestamp, toTimestamp);
    }

    function diffMinutes(uint256 fromTimestamp, uint256 toTimestamp) public pure returns (uint256 _minutes) {
        _minutes = DateTime.diffMinutes(fromTimestamp, toTimestamp);
    }

    function diffSeconds(uint256 fromTimestamp, uint256 toTimestamp) public pure returns (uint256 _seconds) {
        _seconds = DateTime.diffSeconds(fromTimestamp, toTimestamp);
    }
}

// File: main.sol


pragma solidity ^0.8.10;



contract NonOrd is Ownable {
    DateTimeContract internal dateTime;

    mapping(address => uint256) pendingFunds;
    mapping(address => uint256) withdrawable;
    Order[] public orders;

    uint256 offerCooldownInMinutes = 10; // 10mins
    uint256 feeRateInPercentage = 0; // 0%
    bool maintainceMode = false;

    enum OrderStatus {
        available,
        pending,
        confirmed,
        finish,
        cancelled
    }

    struct Order {
        uint256 id;
        uint256 price;
        string inscriptionId;
        string txid;
        string label;
        string sellerBtc;
        string buyerBtc;
        address seller;
        address buyer;
        uint256 createTimestamp;
        uint256 updateTimestamp;
        OrderStatus status;
        mapping(address => OrderOffer) offers;
    }

    struct OrderOffer {
        uint256 price;
        string buyerBtc;
        uint256 expireTimestamp;
        uint256 createTimestamp;
    }

    modifier onlySeller(uint256 orderId) {
        require(
            msg.sender == orders[orderId].seller,
            "You are not order owner."
        );
        _;
    }

    modifier onlyBuyer(uint256 orderId) {
        require(
            msg.sender == orders[orderId].buyer,
            "You are not order buyer."
        );
        _;
    }

    modifier controlable() {
        require(maintainceMode == false, "maintaince.");
        _;
    }

    // 賣家上架
    function createOrder(
        uint256 price,
        string calldata inscriptionId,
        string calldata label,
        string calldata sellerBtc
    ) external controlable {
        uint256 idx = orders.length;
        orders.push();

        Order storage newOrder = orders[idx];

        newOrder.id = idx;
        newOrder.price = price;
        newOrder.inscriptionId = inscriptionId;
        newOrder.label = label;
        newOrder.sellerBtc = sellerBtc;
        newOrder.seller = msg.sender;
        newOrder.createTimestamp = block.timestamp;
        newOrder.updateTimestamp = block.timestamp;
        newOrder.status = OrderStatus.available;
    }

    // 賣家可對訂單修改價格
    function updateOrder(uint256 price, uint256 orderId)
        external
        onlySeller(orderId)
        controlable
    {
        require(
            orders[orderId].status == OrderStatus.available,
            "order unavailable"
        );
        orders[orderId].price = price;
        orders[orderId].updateTimestamp = block.timestamp;
    }

    // 買家可對訂單給出報價，每10分鐘內只能提交 1 次報價，下次報價會覆蓋舊的報價。
    function createOffer(
        uint256 price,
        string calldata buyerBtc,
        uint256 expireTime,
        uint256 orderId
    ) external payable controlable {
        require(
            orders[orderId].status == OrderStatus.available,
            "order unavailable"
        );
        // require(
        //     dateTime.diffMinutes(
        //         orders[orderId].createTimestamp,
        //         block.timestamp
        //     ) >= offerCooldownInMinutes,
        //     "offer in cooldown"
        // );
        require(msg.value == price, "No enough funds");
        require(msg.sender != orders[orderId].seller, "error");

        if (orders[orderId].offers[msg.sender].price > 0) {
            pendingFunds[msg.sender] -= orders[orderId]
                .offers[msg.sender]
                .price;
        }

        orders[orderId].offers[msg.sender] = OrderOffer({
            price: price,
            buyerBtc: buyerBtc,
            expireTimestamp: block.timestamp + expireTime,
            createTimestamp: block.timestamp
        });

        pendingFunds[msg.sender] += price;
    }

    // 賣家接受報價，進入 confirm 流程
    function acceptOffer(uint256 orderId, address offerAddr)
        external
        controlable
    {
        require(
            orders[orderId].status == OrderStatus.available,
            "order unavailable"
        );
        require(
            orders[orderId].offers[offerAddr].expireTimestamp < block.timestamp,
            "offer expired."
        );

        orders[orderId].buyer = offerAddr;
        orders[orderId].status = OrderStatus.pending;
        orders[orderId].buyerBtc = orders[orderId].offers[offerAddr].buyerBtc;
        orders[orderId].updateTimestamp = block.timestamp;
    }

    function cancelOffer(uint256 orderId) external {
        require(
            orders[orderId].status == OrderStatus.available,
            "order unavailable"
        );

        delete orders[orderId].offers[msg.sender];
    }

    // 買家直接下單
    function buy(uint256 orderId, string calldata buyerBtc)
        external
        payable
        controlable
    {
        require(
            orders[orderId].status == OrderStatus.available,
            "order unavailable"
        );
        orders[orderId].buyer = msg.sender;
        orders[orderId].status = OrderStatus.pending;
        orders[orderId].buyerBtc = buyerBtc;
        orders[orderId].updateTimestamp = block.timestamp;

        require(msg.value == orders[orderId].price, "No enough funds");
    }

    // 賣家已確認發送銘文
    function confirm(uint256 orderId, string calldata txid)
        external
        onlySeller(orderId)
    {
        require(
            orders[orderId].status == OrderStatus.pending,
            "invalid order status"
        );
        orders[orderId].status = OrderStatus.confirmed;
        orders[orderId].txid = txid;
        orders[orderId].updateTimestamp = block.timestamp;
    }

    // 買家已確認接收銘文，將付款給賣家
    function finish(uint256 orderId) external onlyBuyer(orderId) {
        require(
            orders[orderId].status == OrderStatus.confirmed,
            "invalid order status"
        );
        orders[orderId].status = OrderStatus.finish;
        orders[orderId].updateTimestamp = block.timestamp;

        withdrawable[orders[orderId].seller] += orders[orderId].price;
    }

    // 取消訂單
    function cancel(uint256 orderId) external {}

    // 緊急取消訂單
    function emergencyCancel(uint256 orderId) external onlyOwner {}

    // 檢查鎖定資金
    function checkPendingFunds() external {}

    // 檢查可提取收益
    function checkWithdrawFunds() external {}

    // 提取收益
    function withdraw() external {
        uint256 amount = withdrawable[msg.sender];
        withdrawable[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }


    // function getOrders(address addr, bool isBuy)
    //     external
    //     view
    //     returns (Order[] memory)
    // {
    //     uint256 count;

    //     for (uint256 i = 0; i < orders.length; i++) {
    //         address orderAddr = isBuy ? orders[i].buyer : orders[i].seller;
    //         if (orderAddr == addr) {
    //             count++;
    //         }
    //     }

    //     Order[] memory result = new Order[](count);
    //     uint256 j;

    //     for (uint256 i = 0; i < orders.length; i++) {
    //         address orderAddr = isBuy ? orders[i].buyer : orders[i].seller;
    //         if (orderAddr == addr) {
    //             result[j] = orders[i];
    //             j++;
    //         }
    //     }

    //     return result;
    // }
}